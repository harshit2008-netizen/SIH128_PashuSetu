"""Advisories to everyone within a radius (spec 8.9).

Recipients are farmers and pashu sevaks whose village lies within the
radius. Each gets the text in their own language. The only channel built is
the in-app inbox; SMS / IVR are not configured, so nothing claims they were sent.
"""

from datetime import UTC, datetime

from geoalchemy2 import Geography
from sqlalchemy import cast, func, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.errors import AppError
from app.core.shared_loader import SharedData
from app.models import Advisory, AdvisoryRecipient, User, Village
from app.services.geo_utils import make_point

LANGUAGES = ("en", "hi", "mr")
MAX_RADIUS_KM = 50


def recipients_within(db: Session, lat: float, lng: float, radius_km: float) -> list[tuple[User, Village]]:
    if not 0 < radius_km <= MAX_RADIUS_KM:
        raise AppError(422, "bad_radius", f"Radius must be between 0 and {MAX_RADIUS_KM} km.")
    within = func.ST_DWithin(cast(Village.centroid, Geography), cast(make_point(lat, lng), Geography),
                             radius_km * 1000)
    return db.execute(select(User, Village).join(Village, User.village_id == Village.id)
                      .where(User.role.in_(("farmer", "pashu_sevak")), within)).all()


def render(data: SharedData, template_id: str, variables: dict) -> dict:
    template = data.advisory_templates.get(template_id)
    if template is None:
        raise AppError(422, "unknown_template", "That advisory template does not exist.")
    values = {"helpline": get_settings().helpline_number, **variables}
    missing = [p for p in template["placeholders"] if p not in values]
    if missing:
        raise AppError(422, "missing_values", f"Fill in: {', '.join(missing)}.")
    rendered = {}
    for lang in LANGUAGES:
        # Place names can differ per language ({"village": {"en": .., "hi": ..}}).
        localized = {k: (v.get(lang) or v.get("en")) if isinstance(v, dict) else v for k, v in values.items()}
        rendered[lang] = template["text"][lang].format(**localized)
    return rendered


def preview(db: Session, data: SharedData, template_id: str, lat: float, lng: float, radius_km: float,
            variables: dict) -> dict:
    people = recipients_within(db, lat, lng, radius_km)
    return {"farmers": len(people), "villages": len({v.id for _, v in people}),
            "text": render(data, template_id, variables)}


def send(db: Session, data: SharedData, sender: User, template_id: str, lat: float, lng: float, radius_km: float,
         disease: str | None, variables: dict) -> tuple[Advisory, int, int]:
    text = render(data, template_id, variables)
    people = recipients_within(db, lat, lng, radius_km)
    now = datetime.now(UTC)
    advisory = Advisory(template_id=template_id, language=None, rendered_text=text,
                        target_center=make_point(lat, lng), radius_km=radius_km,
                        disease=disease or data.advisory_templates[template_id].get("disease"),
                        sent_by=sender.id, sent_at=now)
    db.add(advisory)
    db.flush()
    db.add_all([AdvisoryRecipient(advisory_id=advisory.id, user_id=user.id, channel="inapp", delivered_at=now)
                for user, _ in people])
    return advisory, len(people), len({v.id for _, v in people})
