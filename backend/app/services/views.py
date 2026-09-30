"""Case summaries (lists) and case detail (one case, with its timeline)."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Block, Case, CaseEvent, CaseReport, LabSample, Report, User, Village
from app.models.reports import CASE_STATUSES
from app.services.cases import latest_triage
from app.services.geo_utils import point_latlng
from app.services.reports import report_out


def person(db: Session, user_id) -> dict | None:
    if user_id is None:
        return None
    user = db.get(User, user_id)
    return {"id": user.id, "name": user.name, "role": user.role, "phone": user.phone}


def case_summary(db: Session, case: Case) -> dict:
    report = db.get(Report, case.report_id)
    village = db.get(Village, report.village_id)
    block = db.get(Block, case.block_id)
    triage = latest_triage(db, report.id)
    return {
        "id": case.id, "status": case.status, "severity": case.severity,
        "suspected_disease": case.suspected_disease, "confirmed_disease": case.confirmed_disease,
        "primary_syndrome": triage.primary_syndrome if triage else None,
        "zoonotic_flag": triage.zoonotic_flag if triage else False,
        "species": report.species, "symptoms": report.symptoms,
        "sick_count": report.sick_count, "dead_count": report.dead_count,
        "village": {"id": village.id, "code": village.code, "name": village.name},
        "block": {"id": block.id, "code": block.code, "name": block.name},
        "location": point_latlng(case.location),
        "assigned_vet": person(db, case.assigned_vet_id),
        "escalation_level": case.escalation_level,
        "acknowledged_at": case.acknowledged_at, "resolved_at": case.resolved_at,
        "created_at": case.created_at, "updated_at": case.updated_at,
    }


def case_reports(db: Session, case: Case) -> list[Report]:
    follow_up_ids = select(CaseReport.report_id).where(CaseReport.case_id == case.id)
    return db.scalars(select(Report).where((Report.id == case.report_id) | Report.id.in_(follow_up_ids))
                      .order_by(Report.created_on_device_at)).all()


def timeline(db: Session, case: Case) -> list[dict]:
    events = db.scalars(select(CaseEvent).where(CaseEvent.case_id == case.id)).all()
    # Steps taken in one action share a timestamp (e.g. a vet requesting a
    # sample on an unassigned case is assigned first): break ties by lifecycle order.
    events = sorted(events, key=lambda e: (e.created_at, CASE_STATUSES.index(e.to_status)))
    return [{"from_status": e.from_status, "to_status": e.to_status, "note": e.note,
             "actor": person(db, e.actor_user_id), "at": e.created_at} for e in events]


def samples(db: Session, case: Case) -> list[dict]:
    rows = db.scalars(select(LabSample).where(LabSample.case_id == case.id).order_by(LabSample.created_at)).all()
    return [{"id": s.id, "qr_code": s.qr_code, "sample_type": s.sample_type, "status": s.status,
             "result": s.result, "result_disease": s.result_disease} for s in rows]


def case_detail(db: Session, case: Case) -> dict:
    reports = case_reports(db, case)
    first = next(r for r in reports if r.id == case.report_id)
    triage = latest_triage(db, first.id)
    return {
        **case_summary(db, case),
        "reporter": person(db, first.reporter_user_id),
        "reports": [report_out(r) for r in reports],
        "triage": {**triage.result, "triage_mismatch": triage.triage_mismatch} if triage else None,
        "timeline": timeline(db, case),
        "samples": samples(db, case),
    }
