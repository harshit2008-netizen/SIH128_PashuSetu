"""Advisories: vets and officers send, farmers and sevaks read."""

import uuid

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.errors import not_found
from app.core.security import REPORTERS, RESPONDERS, require_roles
from app.core.shared_loader import get_shared_data
from app.models import Advisory, AdvisoryRecipient, User
from app.schemas.common import LatLng
from app.services import advisory as advisory_service
from app.services.geo_utils import point_latlng
from app.services.views import person

router = APIRouter(tags=["advisories"])


class AdvisoryIn(BaseModel):
    template_id: str = Field(examples=["lsd_nearby"])
    center: LatLng
    radius_km: float = Field(10, gt=0, le=50)
    disease: str | None = None
    variables: dict = Field(default_factory=dict,
                            examples=[{"village": {"en": "Uchchhil", "hi": "उच्छिल", "mr": "उच्छिल"}}],
                            description="Values for the template's {placeholders}; {helpline} is filled in by the server")


def advisory_out(db: Session, advisory: Advisory, language: str | None = None, read_at=None) -> dict:
    text = advisory.rendered_text
    if language:
        text = advisory.rendered_text.get(language) or advisory.rendered_text["en"]
    return {
        "id": advisory.id, "template_id": advisory.template_id, "disease": advisory.disease, "text": text,
        "center": point_latlng(advisory.target_center), "radius_km": advisory.radius_km,
        "sent_by": person(db, advisory.sent_by), "sent_at": advisory.sent_at, "read_at": read_at,
    }


@router.post("/advisories/preview")
def preview(body: AdvisoryIn, _: User = Depends(require_roles(*RESPONDERS)), db: Session = Depends(get_db)):
    """How many farmers and villages it would reach, and the text in each language. Sends nothing."""
    return advisory_service.preview(db, get_shared_data(), body.template_id, body.center.lat, body.center.lng,
                                    body.radius_km, body.variables)


@router.post("/advisories")
def send(body: AdvisoryIn, user: User = Depends(require_roles(*RESPONDERS)), db: Session = Depends(get_db)):
    advisory, farmers, villages = advisory_service.send(
        db, get_shared_data(), user, body.template_id, body.center.lat, body.center.lng, body.radius_km,
        body.disease, body.variables)
    db.commit()
    # Only the in-app inbox exists; nothing claims an SMS or call went out.
    return {"advisory": advisory_out(db, advisory), "farmers": farmers, "villages": villages, "channels": ["inapp"]}


@router.get("/advisories/inbox")
def inbox(user: User = Depends(require_roles(*REPORTERS)), db: Session = Depends(get_db)):
    rows = db.execute(select(Advisory, AdvisoryRecipient)
                      .join(AdvisoryRecipient, AdvisoryRecipient.advisory_id == Advisory.id)
                      .where(AdvisoryRecipient.user_id == user.id).order_by(Advisory.sent_at.desc())).all()
    return [advisory_out(db, a, user.language, r.read_at) for a, r in rows]


@router.get("/advisories/{advisory_id}")
def get_one(advisory_id: uuid.UUID, _: User = Depends(require_roles(*RESPONDERS)), db: Session = Depends(get_db)):
    advisory = db.get(Advisory, advisory_id)
    if advisory is None:
        raise not_found("Advisory")
    return advisory_out(db, advisory)
