"""Lab samples: request (vet), QR scan (sevak collects, lab receives), result (lab)."""

import uuid
from typing import Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.errors import not_found
from app.core.security import require_roles
from app.core.shared_loader import get_shared_data
from app.models import Block, Case, LabSample, User
from app.services.access import can_view_case
from app.services.samples import SAMPLE_TYPES, find_sample, record_result, request_sample, sample_out, scan_sample
from app.services.views import case_summary

router = APIRouter(tags=["labs"])


class SampleRequestIn(BaseModel):
    sample_type: Literal[SAMPLE_TYPES] = Field("skin_scab", description="What to collect")  # type: ignore[valid-type]


class ResultIn(BaseModel):
    result: Literal["positive", "negative", "inconclusive"]
    disease: str | None = Field(None, description="Required when positive, e.g. lsd")
    note: str | None = Field(None, max_length=1000)


def _with_case(db: Session, sample: LabSample) -> dict:
    return {**sample_out(sample), "case": case_summary(db, db.get(Case, sample.case_id))}


@router.post("/cases/{case_id}/samples")
def create_sample(case_id: uuid.UUID, body: SampleRequestIn, user: User = Depends(require_roles("vet", "pashu_sevak")),
                  db: Session = Depends(get_db)):
    """Request a lab sample; returns its QR code (e.g. PS-S-7F3K2Q)."""
    case = db.get(Case, case_id)
    if case is None or not can_view_case(db, user, case):
        raise not_found("Case")
    sample = request_sample(db, case, body.sample_type, user)
    db.commit()
    return _with_case(db, sample)


@router.post("/samples/{qr_code}/scan")
def scan(qr_code: str, user: User = Depends(require_roles("pashu_sevak", "lab")), db: Session = Depends(get_db)):
    """Pashu sevak: marks collected. Lab: marks received."""
    sample = scan_sample(db, find_sample(db, qr_code), user)
    db.commit()
    return _with_case(db, sample)


@router.post("/samples/{qr_code}/result")
def result(qr_code: str, body: ResultIn, user: User = Depends(require_roles("lab")), db: Session = Depends(get_db)):
    sample = record_result(db, find_sample(db, qr_code), body.result, body.disease, body.note, user,
                           set(get_shared_data().rules))
    db.commit()
    return _with_case(db, sample)


@router.get("/samples")
def list_samples(status: str | None = None, user: User = Depends(require_roles("pashu_sevak", "lab", "vet")),
                 db: Session = Depends(get_db)):
    """Sevak: samples to collect in their block. Lab: samples on the way or waiting for a result."""
    query = select(LabSample).join(Case, Case.id == LabSample.case_id)
    if user.role == "lab":
        district_blocks = select(Block.id).where(Block.district_id == user.district_id)
        query = query.where(Case.block_id.in_(district_blocks),
                            LabSample.status.in_((status,) if status else ("collected", "received")))
    else:
        query = query.where(Case.block_id == user.block_id,
                            LabSample.status.in_((status,) if status else ("requested",)))
    samples = db.scalars(query.order_by(LabSample.created_at)).all()
    return [_with_case(db, s) for s in samples]


@router.get("/vets")
def vets(user: User = Depends(require_roles("vet", "district_officer")), db: Session = Depends(get_db)):
    """Vets in the district, for the officer's 'Assign vet'."""
    rows = db.execute(select(User, Block).join(Block, User.block_id == Block.id)
                      .where(User.role == "vet", Block.district_id == user.district_id).order_by(Block.code)).all()
    return [{"id": v.id, "name": v.name, "phone": v.phone, "block": {"id": b.id, "code": b.code, "name": b.name}}
            for v, b in rows]

