"""District officer / vet dashboard: KPIs and map data (spec 10.7)."""

import statistics
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, Query
from geoalchemy2.shape import to_shape
from shapely.geometry import mapping
from sqlalchemy import exists, func, select
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.security import RESPONDERS, require_roles
from app.models import Alert, Animal, Block, Case, Herd, LabSample, Report, User, Vaccination, Village
from app.services.access import visible_cases
from app.services.cases import CLOSED_STATUSES
from app.services.geo_utils import point_latlng

router = APIRouter(tags=["dashboard"])

KPI_RESPONSE_DAYS = 7
PENDING_SAMPLE_STATUSES = ("requested", "collected", "received")


def visible_alerts(user: User):
    query = select(Alert).where(Alert.status != "closed")
    if user.role == "vet":
        return query.where(Alert.block_id == user.block_id)
    return query.where(Alert.district_id == user.district_id)


def median_minutes_to_first_response(db: Session, user: User) -> tuple[int | None, int]:
    """Report sent -> first vet/officer action, last 7 days: the problem
    statement's "reduced reporting time" outcome, measured."""
    since = datetime.now(UTC) - timedelta(days=KPI_RESPONSE_DAYS)
    rows = db.execute(visible_cases(user).with_only_columns(Report.created_on_device_at, Case.acknowledged_at)
                      .join(Report, Report.id == Case.report_id)
                      .where(Case.acknowledged_at.is_not(None), Case.acknowledged_at >= since)).all()
    minutes = [(acked - sent).total_seconds() / 60 for sent, acked in rows]
    return (round(statistics.median(minutes)) if minutes else None), len(minutes)


def vaccination_coverage(db: Session, user: User) -> float | None:
    """Share of the district's animals with at least one vaccination still valid today."""
    today = datetime.now(UTC).date()
    animals = (select(Animal.id).join(Herd, Animal.herd_id == Herd.id).join(Village, Herd.village_id == Village.id)
               .join(Block, Village.block_id == Block.id).where(Block.district_id == user.district_id))
    total = db.scalar(select(func.count()).select_from(animals.subquery()))
    if not total:
        return None
    valid = exists().where(Vaccination.animal_id == Animal.id, Vaccination.next_due_on >= today)
    return round(db.scalar(select(func.count()).select_from(animals.where(valid).subquery())) / total, 3)


@router.get("/dashboard/summary")
def summary(user: User = Depends(require_roles(*RESPONDERS)), db: Session = Depends(get_db)):
    """Open cases by severity, active alerts, median minutes to first response, samples pending."""
    open_cases = db.scalars(visible_cases(user).where(Case.status.not_in(CLOSED_STATUSES))).all()
    median, counted = median_minutes_to_first_response(db, user)
    visible_ids = visible_cases(user).with_only_columns(Case.id)
    return {
        "open_cases": len(open_cases),
        "open_by_severity": {s: sum(1 for c in open_cases if c.severity == s) for s in ("emergency", "urgent", "routine")},
        "unassigned": sum(1 for c in open_cases if c.assigned_vet_id is None),
        # Nobody responded within the SLA (spec 8.6): these land on the officer's list first.
        "escalated": sum(1 for c in open_cases if c.escalation_level > 0),
        "vaccination_coverage": vaccination_coverage(db, user),
        "active_alerts": db.scalar(select(func.count()).select_from(visible_alerts(user).subquery())),
        "median_minutes_to_first_response": median,
        "responses_counted": counted,
        "samples_pending": db.scalar(select(func.count(LabSample.id)).where(
            LabSample.case_id.in_(visible_ids), LabSample.status.in_(PENDING_SAMPLE_STATUSES))),
    }


@router.get("/dashboard/map")
def map_data(days: int = Query(14, ge=1, le=90), user: User = Depends(require_roles(*RESPONDERS)),
             db: Session = Depends(get_db)):
    """GeoJSON FeatureCollection: recent or open cases as points, open alerts as polygons."""
    since = datetime.now(UTC) - timedelta(days=days)
    rows = db.execute(visible_cases(user).add_columns(Village).join(Report, Report.id == Case.report_id)
                      .join(Village, Village.id == Report.village_id)
                      .where((Case.created_at >= since) | Case.status.not_in(CLOSED_STATUSES))).all()
    features = [{
        "type": "Feature", "geometry": mapping(to_shape(case.location)),
        "properties": {"kind": "case", "id": str(case.id), "severity": case.severity, "status": case.status,
                       "disease": case.suspected_disease, "village": village.name,
                       "created_at": case.created_at.isoformat()}}
        for case, village in rows]
    for alert in db.scalars(visible_alerts(user)).all():
        if alert.area is not None:
            features.append({
                "type": "Feature", "geometry": mapping(to_shape(alert.area)),
                "properties": {"kind": "alert", "id": str(alert.id), "type": alert.type,
                               "severity": alert.severity, "status": alert.status, "disease": alert.disease,
                               "center": point_latlng(alert.center), "summary": alert.explanation.get("summary")}})
    blocks = db.scalars(select(Block).where(Block.district_id == user.district_id)).all()
    points = [point_latlng(b.centroid) for b in blocks]
    bounds = None
    if points:
        bounds = {"south": min(p["lat"] for p in points), "north": max(p["lat"] for p in points),
                  "west": min(p["lng"] for p in points), "east": max(p["lng"] for p in points)}
    return {"type": "FeatureCollection", "features": features, "bounds": bounds}
