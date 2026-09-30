"""Outbreak alerts for vets and district officers."""

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends
from geoalchemy2.shape import to_shape
from shapely.geometry import mapping
from sqlalchemy import case as sql_case
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.errors import not_found
from app.core.security import RESPONDERS, require_roles
from app.models import Alert, Block, User
from app.services.geo_utils import point_latlng
from app.services.views import person

router = APIRouter(tags=["alerts"])

SEVERITY_RANK = sql_case({"emergency": 0, "urgent": 1, "routine": 2}, value=Alert.severity)


def alert_out(db: Session, alert: Alert) -> dict:
    block = db.get(Block, alert.block_id) if alert.block_id else None
    return {
        "id": alert.id, "type": alert.type, "syndrome": alert.syndrome, "disease": alert.disease,
        "severity": alert.severity, "status": alert.status,
        "area": mapping(to_shape(alert.area)) if alert.area is not None else None,  # GeoJSON
        "center": point_latlng(alert.center),
        "case_ids": alert.case_ids, "explanation": alert.explanation,
        "block": {"id": block.id, "code": block.code, "name": block.name} if block else None,
        "created_at": alert.created_at, "updated_at": alert.updated_at,
        "acknowledged_at": alert.acknowledged_at, "acknowledged_by": person(db, alert.acknowledged_by),
    }


def visible_alerts(user: User):
    query = select(Alert)
    if user.role == "vet":
        return query.where(Alert.block_id == user.block_id)
    return query.where(Alert.district_id == user.district_id)


@router.get("/alerts")
def list_alerts(status: str | None = None, type: str | None = None,
                user: User = Depends(require_roles(*RESPONDERS)), db: Session = Depends(get_db)):
    """Alerts with their area as GeoJSON, emergency first, newest first. Open and acknowledged by default."""
    query = visible_alerts(user)
    query = query.where(Alert.status == status) if status else query.where(Alert.status != "closed")
    if type:
        query = query.where(Alert.type == type)
    alerts = db.scalars(query.order_by(SEVERITY_RANK, Alert.created_at.desc())).all()
    return [alert_out(db, a) for a in alerts]


@router.post("/alerts/{alert_id}/acknowledge")
def acknowledge(alert_id: uuid.UUID, user: User = Depends(require_roles(*RESPONDERS)), db: Session = Depends(get_db)):
    alert = db.scalar(visible_alerts(user).where(Alert.id == alert_id))
    if alert is None:
        raise not_found("Alert")
    if alert.status == "open":
        alert.status = "acknowledged"
        alert.acknowledged_at = datetime.now(UTC)
        alert.acknowledged_by = user.id
        db.commit()
    return alert_out(db, alert)
