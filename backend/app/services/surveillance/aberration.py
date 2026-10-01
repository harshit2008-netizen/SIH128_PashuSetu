"""Spike detection with EARS C2, per block per syndrome per day (spec 8.5).

Clustering finds reports close together on the map. A spike is the other
shape of an outbreak: more reports than usual in one block today, even if
they are spread out. C2 compares today's count with the 7 days from t-9 to
t-3 (two guard days, so the start of a rise does not hide in its own baseline):

    C2 = (today - mean) / max(std, 0.5)        flag when C2 >= 3 and today >= 3

Runs daily at 06:00 IST and right after each new report.
"""

import statistics
import uuid
from collections import defaultdict
from datetime import UTC, date, datetime, time, timedelta

from geoalchemy2.shape import from_shape
from shapely.geometry import Point
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.shared_loader import SharedData
from app.models import Alert, Block
from app.models.base import SRID
from app.services.geo_utils import make_point
from app.services.surveillance.alerting import (
    IST,
    OPEN_ALERT_STATUSES,
    RecentReport,
    district_of,
    localized_fill,
    most_common_disease,
    recent_reports,
    syndrome_labels,
)
from app.services.surveillance.clustering import centroid

BASELINE_DAYS = range(3, 10)  # t-3 .. t-9
MIN_SIGMA = 0.5
C2_THRESHOLD = 3.0
MIN_TODAY = 3
SPIKE_AREA_DEGREES = 0.03  # ~3 km circle around today's reports, so it shows on the map


def c2_score(today: int, baseline: list[int]) -> tuple[float, float, float]:
    """(C2, baseline mean, sigma). Sample standard deviation, floored at 0.5."""
    mean = statistics.fmean(baseline)
    sigma = max(statistics.stdev(baseline) if len(baseline) > 1 else 0.0, MIN_SIGMA)
    return (today - mean) / sigma, mean, sigma


def is_spike(today: int, baseline: list[int]) -> bool:
    score, _, _ = c2_score(today, baseline)
    return score >= C2_THRESHOLD and today >= MIN_TODAY


def ist_day(at: datetime) -> date:
    return at.astimezone(IST).date()


def _open_cluster_blocks(db: Session, syndrome: str) -> set[uuid.UUID]:
    """Blocks that already have an open cluster alert for this syndrome: one alert per outbreak is enough."""
    return set(db.scalars(select(Alert.block_id).where(
        Alert.type == "cluster", Alert.syndrome == syndrome, Alert.status.in_(OPEN_ALERT_STATUSES))))


def _upsert_spike(db: Session, data: SharedData, syndrome: str, block: Block, day: date,
                  members: list[RecentReport], baseline_mean: float, score: float) -> Alert:
    centre = centroid([m.at for m in members])
    labels = syndrome_labels(data, syndrome)
    summary = localized_fill(data.alert_texts["spike"], {
        lang: {"today": len(members), "syndrome": labels[lang], "baseline": f"{baseline_mean:.1f}",
               "block": block.name.get(lang) or block.name["en"]}
        for lang in labels})
    explanation = {
        "today": len(members), "baseline_mean": round(baseline_mean, 1), "c2": round(score, 1),
        "day": day.isoformat(), "block": block.name["en"], "reports": len(members),
        "villages": len({m.village_id for m in members}),
        "village_names": sorted({m.village_name["en"] for m in members}), "summary": summary,
    }
    fields = {
        "disease": most_common_disease(members), "severity": "urgent",
        "area": from_shape(Point(centre.lng, centre.lat).buffer(SPIKE_AREA_DEGREES), srid=SRID),
        "center": make_point(centre.lat, centre.lng),
        "case_ids": sorted({m.case_id for m in members}, key=str),
        "explanation": explanation, "block_id": block.id, "district_id": district_of(db, block.id),
    }
    existing = next((a for a in db.scalars(select(Alert).where(
        Alert.type == "spike", Alert.syndrome == syndrome, Alert.block_id == block.id,
        Alert.status.in_(OPEN_ALERT_STATUSES))) if a.explanation.get("day") == day.isoformat()), None)
    if existing is None:
        alert = Alert(type="spike", syndrome=syndrome, status="open", **fields)
        db.add(alert)
        return alert
    for name, value in fields.items():  # more reports came in today: update, never duplicate
        setattr(existing, name, value)
    existing.updated_at = datetime.now(UTC)
    return existing


def run_spikes(db: Session, data: SharedData, day: date | None = None,
               syndromes: list[str] | None = None) -> list[Alert]:
    day = day or ist_day(datetime.now(UTC))
    since = datetime.combine(day - timedelta(days=max(BASELINE_DAYS)), time.min, tzinfo=IST)
    wanted = syndromes or [s["id"] for s in data.syndromes]
    alerts = []
    for syndrome in wanted:
        if syndrome == "general":
            continue  # fever / not eating alone is too common to mean an outbreak
        by_block_day: dict[uuid.UUID, dict[date, list[RecentReport]]] = defaultdict(lambda: defaultdict(list))
        for report in recent_reports(db, since, syndrome):
            by_block_day[report.block_id][ist_day(report.sent_at)].append(report)
        clustered = _open_cluster_blocks(db, syndrome)
        for block_id, days in by_block_day.items():
            today = days.get(day, [])
            baseline = [len(days.get(day - timedelta(days=k), [])) for k in BASELINE_DAYS]
            if block_id in clustered or not is_spike(len(today), baseline):
                continue
            score, mean, _ = c2_score(len(today), baseline)
            alerts.append(_upsert_spike(db, data, syndrome, db.get(Block, block_id), day, today, mean, score))
    db.flush()
    return alerts
