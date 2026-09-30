"""Create, update and merge alerts (spec 8.4).

- cluster: 3+ reports of the same syndrome within 5 km in 14 days (DBSCAN).
  Runs per syndrome, so an unknown disease with, say, mouth blisters still
  forms a cluster. Re-runs update the same alert instead of adding a new one.
- zoonotic: any single report whose triage flags a disease that spreads to people.
- mortality: one report with 2+ dead mammals or 10+ dead birds.
"""

import uuid
from collections import Counter
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

from geoalchemy2.shape import from_shape, to_shape
from sqlalchemy import any_, func, select, text
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.shared_loader import SharedData
from app.models import Alert, Block, Case, Report, TriageResult, Village
from app.models.base import SRID
from app.services.geo_utils import make_point, point_latlng
from app.services.surveillance.clustering import LatLng, area_around, centroid, find_clusters, haversine_km
from app.services.triage.rule_engine import higher_severity

IST = ZoneInfo("Asia/Kolkata")
OPEN_ALERT_STATUSES = ("open", "acknowledged")
TOP_SIGNS = 2


@dataclass(frozen=True)
class RecentReport:
    report_id: uuid.UUID
    case_id: uuid.UUID
    at: LatLng
    village_id: uuid.UUID
    village_name: dict
    block_id: uuid.UUID
    sent_at: datetime
    symptoms: list[str]
    severity: str
    disease: str | None
    zoonotic: bool


# Each report belongs to one case: the one it opened, or the one it followed up.
_CASE_OF_REPORT = text("""
    SELECT r.id AS report_id, coalesce(c.id, cr.case_id) AS case_id
    FROM reports r
    LEFT JOIN cases c ON c.report_id = r.id
    LEFT JOIN case_reports cr ON cr.report_id = r.id
    WHERE r.created_on_device_at >= :since
""")


def recent_reports(db: Session, since: datetime, syndrome: str) -> list[RecentReport]:
    case_of = {row.report_id: row.case_id for row in db.execute(_CASE_OF_REPORT, {"since": since})}
    rows = db.execute(
        select(Report, TriageResult, Village)
        .join(TriageResult, TriageResult.report_id == Report.id)
        .join(Village, Village.id == Report.village_id)
        .where(Report.created_on_device_at >= since, TriageResult.primary_syndrome == syndrome)
    ).all()
    cases = {c.id: c for c in db.scalars(select(Case).where(Case.id.in_(set(case_of.values()))))}
    result = []
    for report, triage, village in rows:
        case = cases.get(case_of.get(report.id))
        if case is None:
            continue
        point = point_latlng(report.location)
        result.append(RecentReport(
            report_id=report.id, case_id=case.id, at=LatLng(point["lat"], point["lng"]),
            village_id=village.id, village_name=village.name, block_id=village.block_id,
            sent_at=report.created_on_device_at, symptoms=report.symptoms, severity=case.severity,
            disease=case.suspected_disease, zoonotic=triage.zoonotic_flag))
    return result


def syndrome_labels(data: SharedData, syndrome: str) -> dict:
    label = next(s["label"] for s in data.syndromes if s["id"] == syndrome)
    return {"en": label["en"].lower(), "hi": label["hi"], "mr": label["mr"]}


def localized_fill(template: dict, per_language: dict[str, dict]) -> dict:
    """Fill a {en, hi, mr} template with values that differ per language."""
    return {lang: text_.format(**per_language[lang]) for lang, text_ in template.items()}


def explain_cluster(data: SharedData, syndrome: str, members: list[RecentReport]) -> dict:
    points = [m.at for m in members]
    centre = centroid(points)
    days = {m.sent_at.astimezone(IST).date() for m in members}
    span_days = (max(days) - min(days)).days + 1
    villages = {m.village_id: m.village_name for m in members}
    signs = Counter(s for m in members for s in m.symptoms if s in data.symptoms
                    and data.symptoms[s]["syndrome"] == syndrome)
    labels = syndrome_labels(data, syndrome)
    key = "cluster_one_village" if len(villages) == 1 else "cluster_many_villages"
    period_key = "period_one_day" if span_days == 1 else "period_many_days"
    period = {lang: t.format(days=span_days) for lang, t in data.alert_texts[period_key].items()}
    values = {"reports": len(members), "villages": len(villages)}
    return {
        "reports": len(members),
        "villages": len(villages),
        "village_names": sorted(v["en"] for v in villages.values()),
        "span_days": span_days,
        "radius_km": round(max(haversine_km(centre, p) for p in points), 1),
        "top_signs": [s for s, _ in signs.most_common(TOP_SIGNS)],
        "summary": localized_fill(data.alert_texts[key],
                                  {lang: {**values, "syndrome": labels[lang], "period": period[lang]}
                                   for lang in labels}),
    }


def most_common_disease(members: list[RecentReport]) -> str | None:
    """The cluster's disease only when at least half its reports agree on it."""
    counts = Counter(m.disease for m in members if m.disease)
    if not counts:
        return None
    disease, count = counts.most_common(1)[0]
    return disease if count * 2 >= len(members) else None


def cluster_severity(members: list[RecentReport]) -> str:
    severity = "routine"
    for m in members:
        severity = higher_severity(severity, m.severity)
    return "emergency" if any(m.zoonotic for m in members) else severity


def district_of(db: Session, block_id) -> uuid.UUID | None:
    block = db.get(Block, block_id)
    return block.district_id if block else None


def upsert_cluster_alert(db: Session, data: SharedData, syndrome: str, members: list[RecentReport]) -> Alert:
    area = area_around([m.at for m in members])
    area_wkb = from_shape(area, srid=SRID)
    existing = db.scalar(
        select(Alert).where(Alert.type == "cluster", Alert.syndrome == syndrome,
                            Alert.status.in_(OPEN_ALERT_STATUSES),
                            func.ST_Intersects(Alert.area, area_wkb))
        .order_by(Alert.created_at))
    centre = centroid([m.at for m in members])
    block_id = Counter(m.block_id for m in members).most_common(1)[0][0]
    fields = {
        "disease": most_common_disease(members),
        "severity": cluster_severity(members),
        "area": area_wkb,
        "center": make_point(centre.lat, centre.lng),
        "case_ids": sorted({m.case_id for m in members}, key=str),
        "explanation": explain_cluster(data, syndrome, members),
        "block_id": block_id,
        "district_id": district_of(db, block_id),
    }
    if existing is None:
        alert = Alert(type="cluster", syndrome=syndrome, status="open", **fields)
        db.add(alert)
    else:
        # Same outbreak seen again (maybe bigger): update it, never duplicate it.
        alert = existing
        for name, value in fields.items():
            setattr(alert, name, value)
        alert.updated_at = datetime.now(UTC)
    return alert


def run_clustering(db: Session, data: SharedData, syndromes: list[str] | None = None,
                   now: datetime | None = None) -> list[Alert]:
    settings = get_settings()
    since = (now or datetime.now(UTC)) - timedelta(days=settings.cluster_window_days)
    wanted = syndromes or [s["id"] for s in data.syndromes]
    alerts = []
    for syndrome in wanted:
        if syndrome == "general":
            continue  # fever / not eating alone is too common to mean an outbreak
        reports = recent_reports(db, since, syndrome)
        for indices in find_clusters([r.at for r in reports], settings.cluster_radius_km,
                                     settings.cluster_min_reports):
            alerts.append(upsert_cluster_alert(db, data, syndrome, [reports[i] for i in indices]))
    db.flush()
    return alerts


def _single_report_alert(db: Session, kind: str, case: Case, report: Report, triage: dict,
                         severity: str, explanation: dict) -> Alert | None:
    # One alert of each kind per case, even if the same case gets follow-ups.
    exists = db.scalar(select(Alert.id).where(Alert.type == kind, case.id == any_(Alert.case_ids)))
    if exists is not None:
        return None
    area = to_shape(report.location).buffer(0.01)  # ~1 km circle so it shows on the map
    alert = Alert(type=kind, syndrome=triage["primary_syndrome"],
                  disease=case.suspected_disease, severity=severity, status="open",
                  area=from_shape(area, srid=SRID), center=report.location, case_ids=[case.id],
                  explanation=explanation, block_id=case.block_id, district_id=district_of(db, case.block_id))
    db.add(alert)
    return alert


def single_report_alerts(db: Session, data: SharedData, report: Report, triage: dict, case: Case) -> list[Alert]:
    village = db.get(Village, report.village_id)
    created = []
    if triage["zoonotic_flag"]:
        zoonotic = next((c for c in triage["candidates"] if data.rules[c["disease_id"]]["zoonotic"]), None)
        names = data.rules[zoonotic["disease_id"]]["name"] if zoonotic else {"en": "a disease", "hi": "बीमारी", "mr": "आजार"}
        summary = localized_fill(data.alert_texts["zoonotic"],
                                 {lang: {"disease": names[lang], "village": village.name.get(lang) or village.name["en"]}
                                  for lang in ("en", "hi", "mr")})
        created.append(_single_report_alert(db, "zoonotic", case, report, triage, "emergency", {
            "reports": 1, "villages": 1, "village_names": [village.name["en"]],
            "disease": zoonotic["disease_id"] if zoonotic else None, "summary": summary}))
    is_bird = data.species[report.species]["group"] == "bird"
    limits = data.triage_config["severity"]
    many_dead = report.dead_count >= (limits["emergency_min_dead_poultry"] if is_bird
                                      else limits["emergency_min_dead_mammal"])
    if many_dead:
        summary = localized_fill(data.alert_texts["mortality"],
                                 {lang: {"dead": report.dead_count, "village": village.name.get(lang) or village.name["en"]}
                                  for lang in ("en", "hi", "mr")})
        created.append(_single_report_alert(db, "mortality", case, report, triage, "emergency", {
            "reports": 1, "villages": 1, "village_names": [village.name["en"]], "dead": report.dead_count,
            "summary": summary}))
    return [a for a in created if a is not None]


def on_new_report(db: Session, data: SharedData, report: Report, triage: dict, case: Case) -> list[Alert]:
    """Right after a report is stored: single-report alerts, then clustering for
    its syndrome, so the demo alert appears within seconds (spec 8.3)."""
    alerts = single_report_alerts(db, data, report, triage, case)
    if triage["primary_syndrome"] != "general":
        alerts += run_clustering(db, data, [triage["primary_syndrome"]])
    return alerts
