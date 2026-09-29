"""Case lifecycle (spec Section 6): allowed status changes and the timeline.

Every change goes through change_status() so it always writes a case_events
row; the timeline in the app is built only from those rows.
"""

from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.models import Case, CaseEvent, CaseReport, Report, TriageResult, User
from app.services.triage.rule_engine import higher_severity

ALLOWED_TRANSITIONS: dict[str, set[str]] = {
    "reported": {"triaged"},
    "triaged": {"vet_assigned", "closed_ruled_out"},
    "vet_assigned": {"sample_requested", "under_treatment", "closed_ruled_out"},
    "sample_requested": {"sample_collected", "closed_ruled_out"},
    "sample_collected": {"lab_received"},
    "lab_received": {"lab_result"},
    "lab_result": {"under_treatment", "resolved", "closed_ruled_out"},
    "under_treatment": {"sample_requested", "resolved", "closed_ruled_out"},
    "resolved": set(),
    "closed_ruled_out": set(),
}
# Statuses a vet or officer may set directly with POST /cases/{id}/transition.
# The others belong to their own flows: assigning a vet, and the lab sample QR
# steps (Phase 8), so they always come with the data they need.
MANUAL_TARGETS = {"under_treatment", "resolved", "closed_ruled_out"}
CLOSED_STATUSES = {"resolved", "closed_ruled_out"}
RESPONDER_ROLES = {"vet", "district_officer"}
FOLLOW_UP_WINDOW = timedelta(days=7)
SYSTEM_NOTE_TRIAGED = "Triaged automatically"


def utcnow() -> datetime:
    return datetime.now(UTC)


def record_event(db: Session, case: Case, actor: User | None, from_status: str | None, to_status: str,
                 note: str | None, at: datetime) -> CaseEvent:
    event = CaseEvent(case_id=case.id, actor_user_id=actor.id if actor else None, from_status=from_status,
                      to_status=to_status, note=note, created_at=at, updated_at=at)
    db.add(event)
    return event


def mark_acknowledged(case: Case, actor: User | None, at: datetime) -> None:
    # First action by a vet or officer: feeds the "time to first response" KPI.
    if actor is not None and actor.role in RESPONDER_ROLES and case.acknowledged_at is None:
        case.acknowledged_at = at


def change_status(db: Session, case: Case, to_status: str, actor: User | None, note: str | None = None,
                  at: datetime | None = None) -> CaseEvent:
    at = at or utcnow()
    if to_status not in ALLOWED_TRANSITIONS.get(case.status, set()):
        raise AppError(409, "transition_not_allowed",
                       f"A case that is '{case.status}' cannot move to '{to_status}'.")
    from_status = case.status
    case.status = to_status
    case.updated_at = at
    if to_status in CLOSED_STATUSES:
        case.resolved_at = at
    mark_acknowledged(case, actor, at)
    return record_event(db, case, actor, from_status, to_status, note, at)


def assign_vet(db: Session, case: Case, vet: User, actor: User, at: datetime | None = None) -> None:
    at = at or utcnow()
    if vet.role != "vet":
        raise AppError(422, "not_a_vet", "Only a vet can be assigned to a case.")
    if case.status in CLOSED_STATUSES:
        raise AppError(409, "case_closed", "This case is already closed.")
    case.assigned_vet_id = vet.id
    note = f"Assigned to {vet.name}"
    if case.status == "triaged":
        change_status(db, case, "vet_assigned", actor, note, at)
    else:
        # Reassigning later in the lifecycle keeps the status, but still goes on the timeline.
        mark_acknowledged(case, actor, at)
        record_event(db, case, actor, case.status, case.status, note, at)


def suspected_disease(triage: dict, min_score: float) -> str | None:
    """Top candidate only when it is at least 'moderate'; otherwise no label."""
    candidates = triage["candidates"]
    if candidates and candidates[0]["score"] >= min_score:
        return candidates[0]["disease_id"]
    return None


def find_follow_up_case(db: Session, herd_id, disease: str | None, at: datetime) -> Case | None:
    if herd_id is None or disease is None:
        return None
    return db.scalar(
        select(Case)
        .where(Case.herd_id == herd_id, Case.suspected_disease == disease,
               Case.status.not_in(CLOSED_STATUSES), Case.created_at >= at - FOLLOW_UP_WINDOW)
        .order_by(Case.created_at.desc())
    )


def open_case_for_report(db: Session, report: Report, triage: dict, block_id, reporter: User,
                         min_score: float, at: datetime) -> Case:
    """One report opens one case, unless it follows up an open case for the same herd and disease."""
    disease = suspected_disease(triage, min_score)
    existing = find_follow_up_case(db, report.herd_id, disease, at)
    if existing is not None:
        existing.severity = higher_severity(existing.severity, triage["severity"])
        db.add(CaseReport(case_id=existing.id, report_id=report.id, created_at=at, updated_at=at))
        record_event(db, existing, reporter, existing.status, existing.status, "Follow-up report", at)
        return existing

    case = Case(report_id=report.id, status="reported", severity=triage["severity"],
                suspected_disease=disease, block_id=block_id, herd_id=report.herd_id,
                location=report.location, created_at=at, updated_at=at)
    db.add(case)
    db.flush()
    # "Reported" is when the farmer pressed send (maybe offline); "triaged" is
    # when the server received it. The gap shows up honestly on the timeline.
    record_event(db, case, reporter, None, "reported", None, min(report.created_on_device_at, at))
    change_status(db, case, "triaged", None, SYSTEM_NOTE_TRIAGED, at)
    return case


def case_for_report(db: Session, report_id) -> Case | None:
    case = db.scalar(select(Case).where(Case.report_id == report_id))
    if case is not None:
        return case
    link = db.scalar(select(CaseReport).where(CaseReport.report_id == report_id))
    return db.get(Case, link.case_id) if link else None


def latest_triage(db: Session, report_id) -> TriageResult | None:
    return db.scalar(select(TriageResult).where(TriageResult.report_id == report_id)
                     .order_by(TriageResult.created_at.desc()))
