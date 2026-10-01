"""SLA escalation (spec 8.6), with the demo-mode SLAs (urgent: 5 minutes)."""

from datetime import UTC, datetime, timedelta

from sqlalchemy import select

from app.models import Case, CaseEvent
from app.services.escalation import run_escalation, sla
from tests.helpers import report_payload


def new_case(client, as_role, db) -> Case:
    body = client.post("/api/v1/reports", json=report_payload(created_on_device_at=datetime.now(UTC).isoformat()),
                       headers=as_role("pashu_sevak")).json()
    return db.get(Case, body["case_id"])


def test_demo_slas_are_minutes():
    assert sla("emergency") == timedelta(minutes=2)
    assert sla("urgent") == timedelta(minutes=5)
    assert sla("routine") == timedelta(minutes=15)


def test_unanswered_case_climbs_one_level_per_sla_then_stops(client, as_role, db):
    case = new_case(client, as_role, db)
    assert case.severity == "urgent" and case.escalation_level == 0
    start = case.created_at
    assert case not in run_escalation(db, start + timedelta(minutes=4))
    assert case in run_escalation(db, start + timedelta(minutes=6)) and case.escalation_level == 1
    assert case not in run_escalation(db, start + timedelta(minutes=7))  # same level until the next SLA
    assert case in run_escalation(db, start + timedelta(minutes=11)) and case.escalation_level == 2
    assert case not in run_escalation(db, start + timedelta(hours=5))  # district is the top
    notes = db.scalars(select(CaseEvent.note).where(CaseEvent.case_id == case.id, CaseEvent.note.like("escalation:%"))
                       .order_by(CaseEvent.created_at)).all()
    assert notes == ["escalation:1", "escalation:2"]
    db.rollback()


def test_a_case_a_vet_has_answered_is_not_escalated(client, as_role, db):
    case = new_case(client, as_role, db)
    client.post(f"/api/v1/cases/{case.id}/assign", json={}, headers=as_role("vet"))
    db.refresh(case)
    assert case.acknowledged_at is not None
    assert case not in run_escalation(db, case.created_at + timedelta(hours=1))
    db.rollback()
