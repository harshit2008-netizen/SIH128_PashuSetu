"""Block risk estimate per disease (spec 8.8): a transparent heuristic, not a model.

    risk = 0.30*season + 0.25*weather + 0.25*nearby + 0.20*immunity_gap   (clamped 0..1)

Each factor is 0..1 and is returned with its contribution, so the officer
sees why a block is high ("nearby cases 40%, humid weather 25%"). Weights,
cut-offs and the per-disease weather settings live in shared/risk_config.json.
"""

import math
import uuid
from datetime import UTC, date, datetime, time, timedelta

from sqlalchemy import Date, cast, delete, exists, func, select
from sqlalchemy.orm import Session

from app.core.shared_loader import SharedData
from app.models import Animal, Block, Case, Herd, RiskScore, Vaccination, Village
from app.services.geo_utils import point_latlng
from app.services.risk.weather import DayWeather, weather_window
from app.services.surveillance.alerting import IST


def season_factor(data: SharedData, disease: str, month: int) -> float:
    rule = data.rules[disease]
    return 1.0 if month in rule["season"]["high_risk_months"] else data.risk_config["season_outside"]


def weather_factor(data: SharedData, disease: str, days: list[DayWeather]) -> tuple[float, dict]:
    """(value, details). Only LSD and HS have a weather model; the rest are neutral and say so."""
    cfg = data.risk_config
    settings = cfg["weather"].get(disease)
    if settings is None:
        return cfg["neutral"], {"modelled": False}
    usable = [d for d in days if None not in (d.temp_max, d.temp_min, d.humidity_mean, d.precip_mm)]
    if not usable:
        return cfg["neutral"], {"modelled": True, "days": 0}
    rain = sum(d.precip_mm for d in usable)
    rain_part = min(rain / settings["rain_mm_full"], 1.0)
    humid = [d for d in usable if d.humidity_mean > settings["humidity_min"]]
    if disease == "lsd":
        warm_humid = [d for d in humid if settings["temp_min_c"] <= (d.temp_max + d.temp_min) / 2 <= settings["temp_max_c"]]
        value = len(warm_humid) / len(usable) * (0.5 + 0.5 * rain_part)
    else:  # hs: heavy rain and high humidity
        value = 0.5 * rain_part + 0.5 * len(humid) / len(usable)
    sources = sorted({d.source for d in usable})
    return round(value, 3), {"modelled": True, "days": len(usable), "rain_mm": round(rain, 1),
                             "humid_days": len(humid), "source": sources, "why": settings["why"]}


def nearby_factor(data: SharedData, cases: int) -> float:
    return 1 - math.exp(-cases / data.risk_config["nearby"]["scale"])


def count_nearby_cases(db: Session, data: SharedData, block: Block, disease: str, today: date) -> int:
    cfg = data.risk_config["nearby"]
    since = datetime.combine(today - timedelta(days=cfg["days"]), time.min, tzinfo=IST)
    # The centre comes from the database (a subquery), not as a Python geometry value.
    centre = select(Block.centroid).where(Block.id == block.id).scalar_subquery()
    return db.scalar(select(func.count(Case.id)).where(
        Case.suspected_disease == disease, Case.created_at >= since,
        func.ST_DWithin(func.Geography(Case.location), func.Geography(centre), cfg["radius_km"] * 1000)))


def vaccination_coverage(db: Session, data: SharedData, block: Block, disease: str, today: date) -> float | None:
    """Share of the block's animals that can catch the disease and are protected today.
    None when there is no vaccine on record for the disease or no such animals."""
    entry = data.vaccine_for(disease)
    if entry is None:
        return None
    vaccine = entry["id"]
    animals = (select(Animal.id).join(Herd, Animal.herd_id == Herd.id).join(Village, Herd.village_id == Village.id)
               .where(Village.block_id == block.id, Animal.species.in_(data.rules[disease]["species"])))
    total = db.scalar(select(func.count()).select_from(animals.subquery()))
    if not total:
        return None
    protected_now = exists().where(Vaccination.animal_id == Animal.id, Vaccination.vaccine == vaccine,
                                   Vaccination.given_on <= today, Vaccination.next_due_on >= today)
    protected = db.scalar(select(func.count()).select_from(animals.where(protected_now).subquery()))
    return protected / total


def level_for(data: SharedData, score: float) -> str:
    levels = data.risk_config["levels"]
    return "high" if score >= levels["high"] else "medium" if score >= levels["medium"] else "low"


def block_risk(db: Session, data: SharedData, block: Block, disease: str, today: date) -> dict:
    cfg = data.risk_config
    centre = point_latlng(block.centroid)
    days = weather_window(db, centre["lat"], centre["lng"], today, cfg["weather_days"]["past"], cfg["weather_days"]["forecast"])
    weather, weather_details = weather_factor(data, disease, days)
    cases = count_nearby_cases(db, data, block, disease, today)
    coverage = vaccination_coverage(db, data, block, disease, today)
    values = {
        "season": season_factor(data, disease, today.month),
        "weather": weather,
        "nearby": round(nearby_factor(data, cases), 3),
        "immunity_gap": cfg["neutral"] if coverage is None else round(1 - coverage, 3),
    }
    score = max(0.0, min(1.0, sum(cfg["weights"][k] * v for k, v in values.items())))
    factors = {k: {"value": v, "contribution": round(cfg["weights"][k] * v, 3)} for k, v in values.items()}
    factors["weather"].update(weather_details)
    factors["nearby"].update({"cases": cases, "radius_km": cfg["nearby"]["radius_km"], "days": cfg["nearby"]["days"]})
    factors["immunity_gap"]["coverage"] = None if coverage is None else round(coverage, 3)
    return {"block_id": block.id, "code": block.code, "name": block.name, "centroid": centre, "disease": disease,
            "score": round(score, 3), "level": level_for(data, score), "factors": factors}


def district_risk(db: Session, data: SharedData, district_id: uuid.UUID, disease: str,
                  today: date | None = None) -> list[dict]:
    """Every block of the district, highest risk first; also stored in risk_scores for history."""
    today = today or datetime.now(UTC).astimezone(IST).date()
    blocks = db.scalars(select(Block).where(Block.district_id == district_id).order_by(Block.code)).all()
    results = [block_risk(db, data, block, disease, today) for block in blocks]
    db.execute(delete(RiskScore).where(RiskScore.disease == disease, cast(RiskScore.for_date, Date) == today,
                                       RiskScore.block_id.in_([b.id for b in blocks])))
    for r in results:
        db.add(RiskScore(block_id=r["block_id"], disease=disease, for_date=today, score=r["score"], level=r["level"],
                         factors=r["factors"]))
    return sorted(results, key=lambda r: (-r["score"], r["code"]))
