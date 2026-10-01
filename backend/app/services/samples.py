"""Lab samples with a QR code (spec 8.2): request -> collect -> receive -> result.

Each step moves the case along its lifecycle through change_status(), so the
case timeline shows every hand-over with who and when.
"""

import secrets
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.errors import AppError, not_found
from app.models import Case, LabSample, User
from app.services.cases import CLOSED_STATUSES, assign_vet, change_status

# No 0/O or 1/I: the code is also read out and typed by hand.
_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
QR_PREFIX = "PS-S-"
SAMPLE_TYPES = ("skin_scab", "blood", "nasal_swab", "oral_swab", "tissue", "carcass_swab", "other")
RESULTS = ("positive", "negative", "inconclusive")


def new_qr_code(db: Session) -> str:
    while True:
        code = QR_PREFIX + "".join(secrets.choice(_CODE_ALPHABET) for _ in range(6))
        if db.scalar(select(LabSample.id).where(LabSample.qr_code == code)) is None:
            return code


def request_sample(db: Session, case: Case, sample_type: str, actor: User) -> LabSample:
    if sample_type not in SAMPLE_TYPES:
        raise AppError(422, "unknown_sample_type", f"Sample type must be one of: {', '.join(SAMPLE_TYPES)}.")
    if case.status in CLOSED_STATUSES:
        raise AppError(409, "case_closed", "This case is already closed.")
    now = datetime.now(UTC)
    # A vet asking for a sample on an unassigned case is clearly taking it on.
    if case.status == "triaged" and actor.role == "vet":
        assign_vet(db, case, actor, actor, at=now)
    change_status(db, case, "sample_requested", actor, f"Sample requested: {sample_type.replace('_', ' ')}", at=now)
    sample = LabSample(case_id=case.id, qr_code=new_qr_code(db), sample_type=sample_type, status="requested",
                       requested_by=actor.id)
    db.add(sample)
    db.flush()
    return sample


def find_sample(db: Session, qr_code: str) -> LabSample:
    sample = db.scalar(select(LabSample).where(LabSample.qr_code == qr_code.strip().upper()))
    if sample is None:
        raise not_found("Sample")
    return sample


COLLECTOR_ROLES = {"pashu_sevak", "vet"}


def _collect(db: Session, case: Case, sample: LabSample, actor: User, now: datetime, note: str) -> None:
    sample.status, sample.collected_by, sample.collected_at = "collected", actor.id, now
    change_status(db, case, "sample_collected", actor, note, at=now)


def scan_sample(db: Session, sample: LabSample, actor: User) -> LabSample:
    """Pashu sevak or vet: marks it collected. Lab: marks it received.

    A sample can reach the lab without being scanned at collection (the vet
    took it, or the sevak forgot). The lab then records both steps at once,
    and the timeline says so, instead of refusing a sample that is in its hands.
    """
    case = db.get(Case, sample.case_id)
    now = datetime.now(UTC)
    if actor.role in COLLECTOR_ROLES:
        if sample.status != "requested":
            raise AppError(409, "already_collected", "This sample was already collected.")
        _collect(db, case, sample, actor, now, f"Sample {sample.qr_code} collected")
    elif actor.role == "lab":
        if sample.status == "requested":
            _collect(db, case, sample, actor, now, f"Sample {sample.qr_code} arrived without a collection scan")
        elif sample.status != "collected":
            raise AppError(409, "already_received", "This sample was already received.")
        sample.status, sample.received_by, sample.received_at = "received", actor.id, now
        change_status(db, case, "lab_received", actor, f"Sample {sample.qr_code} received at lab", at=now)
    return sample


def record_result(db: Session, sample: LabSample, result: str, disease: str | None, note: str | None,
                  actor: User, known_diseases: set[str]) -> LabSample:
    if sample.status != "received":
        raise AppError(409, "not_received", "Scan the sample as received before entering a result.")
    if result not in RESULTS:
        raise AppError(422, "bad_result", "Result must be positive, negative or inconclusive.")
    if result == "positive" and disease not in known_diseases:
        raise AppError(422, "disease_required", "Choose which disease the sample is positive for.")
    now = datetime.now(UTC)
    case = db.get(Case, sample.case_id)
    sample.status, sample.result, sample.result_note, sample.resulted_at = "resulted", result, note, now
    sample.result_disease = disease if result == "positive" else None
    if result == "positive":
        # A lab-confirmed case is also a labelled example for future models (data flywheel).
        case.confirmed_disease = disease
    change_status(db, case, "lab_result", actor,
                  f"Lab result: {result}" + (f" for {disease}" if result == "positive" else ""), at=now)
    return sample


def sample_out(sample: LabSample) -> dict:
    return {"id": sample.id, "case_id": sample.case_id, "qr_code": sample.qr_code, "sample_type": sample.sample_type,
            "status": sample.status, "result": sample.result, "result_disease": sample.result_disease,
            "result_note": sample.result_note, "created_at": sample.created_at, "collected_at": sample.collected_at,
            "received_at": sample.received_at, "resulted_at": sample.resulted_at}
