"""Reports from farmers and pashu sevaks, and batch sync from the outbox."""

import uuid
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import BACKEND_DIR, get_settings
from app.core.db import get_db
from app.core.errors import AppError, forbidden, not_found
from app.core.security import REPORTERS, get_current_user, require_roles
from app.core.shared_loader import get_shared_data
from app.models import Advisory, AdvisoryRecipient, Animal, Case, Herd, Report, User, Vaccination, Village
from app.schemas.reports import ReportIn, ReportResult, SyncPushIn, SyncPushOut
from app.services.access import visible_cases
from app.services.cases import utcnow
from app.services.reports import ingest_report, report_result
from app.services.views import case_summary

router = APIRouter(tags=["reports"])

MAX_PHOTO_BYTES = 8 * 1024 * 1024
PHOTO_TYPES = {"image/jpeg": ".jpg", "image/png": ".png"}
VACCINATION_DUE_DAYS = 30
# Enough for a sevak's block; the full animal register is a P1 feature.
MAX_ANIMALS = 300


@router.post("/reports", response_model=ReportResult)
def create_report(body: ReportIn, user: User = Depends(require_roles(*REPORTERS)),
                  db: Session = Depends(get_db)):
    """Create a report, triage it on the server, and open (or follow up) a case.

    Sending the same `client_uuid` again returns the stored report with status "duplicate".
    """
    status, report, case = ingest_report(db, get_shared_data(), user, body)
    db.commit()
    return report_result(db, status, report, case)


def upload_dir():
    path = BACKEND_DIR / get_settings().upload_dir
    path.mkdir(parents=True, exist_ok=True)
    return path


@router.post("/reports/{report_id}/photo")
async def upload_photo(report_id: uuid.UUID, photo: UploadFile = File(...),
                       user: User = Depends(require_roles(*REPORTERS)), db: Session = Depends(get_db)):
    """Attach a photo. Separate from the report so a slow upload never blocks the report."""
    report = db.get(Report, report_id)
    if report is None:
        raise not_found("Report")
    if report.reporter_user_id != user.id:
        raise forbidden("Only the person who sent the report can add its photo.")
    if photo.content_type not in PHOTO_TYPES:
        raise AppError(415, "not_an_image", "Send a JPEG or PNG photo.")
    content = await photo.read()
    if len(content) > MAX_PHOTO_BYTES:
        raise AppError(413, "photo_too_large", "The photo is too large. The app should shrink it before sending.")
    file_name = f"{report.id}{PHOTO_TYPES[photo.content_type]}"
    (upload_dir() / file_name).write_bytes(content)
    report.photo_path = file_name
    db.commit()
    return {"report_id": report.id, "has_photo": True}


@router.post("/sync/push", response_model=SyncPushOut)
def sync_push(body: SyncPushIn, user: User = Depends(require_roles(*REPORTERS)), db: Session = Depends(get_db)):
    """Send up to 50 outbox reports. Each item succeeds or fails on its own."""
    data = get_shared_data()
    results = []
    for item in body.reports:
        try:
            with db.begin_nested():
                status, report, case = ingest_report(db, data, user, item)
            results.append({"client_uuid": item.client_uuid, "status": status,
                            "report_id": report.id, "case_id": case.id})
        except AppError as exc:
            results.append({"client_uuid": item.client_uuid, "status": "error", "message": exc.message})
    db.commit()
    return {"results": results}


def my_herds_filter(user: User):
    """Farmers see their own herds, pashu sevaks every herd in their block."""
    if user.role == "farmer":
        return Herd.owner_user_id == user.id
    if user.role == "pashu_sevak":
        return Herd.village_id.in_(select(Village.id).where(Village.block_id == user.block_id))
    return None


def my_animals(db: Session, user: User) -> list[dict]:
    herd_filter = my_herds_filter(user)
    if herd_filter is None:
        return []
    rows = db.execute(select(Animal, Herd).join(Herd, Animal.herd_id == Herd.id).where(herd_filter)
                      .order_by(Herd.name, Animal.name).limit(MAX_ANIMALS)).all()
    return [{"id": a.id, "ear_tag": a.ear_tag, "name": a.name, "species": a.species, "breed": a.breed,
             "sex": a.sex, "age_months": a.age_months, "herd_id": h.id, "herd_name": h.name} for a, h in rows]


def my_vaccinations_due(db: Session, user: User) -> list[dict]:
    herd_filter = my_herds_filter(user)
    if herd_filter is None:
        return []
    today = utcnow().date()
    rows = db.execute(
        select(Vaccination, Animal).join(Animal, Vaccination.animal_id == Animal.id)
        .join(Herd, Animal.herd_id == Herd.id).where(herd_filter)
        .where(Vaccination.next_due_on.between(today, today + timedelta(days=VACCINATION_DUE_DAYS)))
        .order_by(Vaccination.next_due_on)
    ).all()
    return [{"animal_id": a.id, "animal_name": a.name, "ear_tag": a.ear_tag, "species": a.species,
             "vaccine": v.vaccine, "due_on": v.next_due_on} for v, a in rows]


@router.get("/sync/pull")
def sync_pull(since: datetime | None = None, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Everything the phone caches: my cases, advisories, animals and vaccinations due.

    `since` limits cases and advisories to changes after that time; animals and
    vaccinations due always come in full (they are small).
    """
    server_time = utcnow()
    cases_query = visible_cases(user)
    if since is not None:
        cases_query = cases_query.where(Case.updated_at > since)
    cases = db.scalars(cases_query.order_by(Case.updated_at.desc()).limit(200)).all()

    advisories_query = (select(Advisory, AdvisoryRecipient)
                        .join(AdvisoryRecipient, AdvisoryRecipient.advisory_id == Advisory.id)
                        .where(AdvisoryRecipient.user_id == user.id))
    if since is not None:
        advisories_query = advisories_query.where(AdvisoryRecipient.created_at > since)
    advisories = db.execute(advisories_query.order_by(Advisory.sent_at.desc())).all()
    return {
        "server_time": server_time,
        "cases": [case_summary(db, c) for c in cases],
        "advisories": [{"id": a.id, "template_id": a.template_id, "disease": a.disease,
                        "text": a.rendered_text.get(user.language) or a.rendered_text.get("en"),
                        "sent_at": a.sent_at, "read_at": r.read_at} for a, r in advisories],
        "animals": my_animals(db, user),
        "vaccinations_due": my_vaccinations_due(db, user),
    }
