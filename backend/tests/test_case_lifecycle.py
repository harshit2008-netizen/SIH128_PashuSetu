from sqlalchemy import select

from app.models import User
from app.models.reports import CASE_STATUSES
from app.services.cases import ALLOWED_TRANSITIONS
from tests.helpers import report_payload


def new_case(client, as_role) -> str:
    return client.post("/api/v1/reports", json=report_payload(), headers=as_role("pashu_sevak")).json()["case_id"]


def test_every_status_has_a_rule():
    assert set(ALLOWED_TRANSITIONS) == set(CASE_STATUSES)
    assert all(targets <= set(CASE_STATUSES) for targets in ALLOWED_TRANSITIONS.values())


def test_full_path_writes_an_event_for_every_step(client, as_role):
    case_id = new_case(client, as_role)
    vet = as_role("vet")
    assigned = client.post(f"/api/v1/cases/{case_id}/assign", json={}, headers=vet).json()
    assert assigned["status"] == "vet_assigned"
    assert assigned["acknowledged_at"] is not None
    assert assigned["assigned_vet"]["name"] == "Dr. Anil Deshmukh"

    client.post(f"/api/v1/cases/{case_id}/transition", json={"to_status": "under_treatment"}, headers=vet)
    done = client.post(f"/api/v1/cases/{case_id}/transition",
                       json={"to_status": "resolved", "note": "Recovered"}, headers=vet).json()
    assert done["status"] == "resolved" and done["resolved_at"] is not None
    steps = [e["to_status"] for e in done["timeline"]]
    assert steps == ["reported", "triaged", "vet_assigned", "under_treatment", "resolved"]
    assert done["timeline"][-1]["actor"]["role"] == "vet"


def test_cannot_skip_steps(client, as_role):
    case_id = new_case(client, as_role)
    response = client.post(f"/api/v1/cases/{case_id}/transition", json={"to_status": "resolved"},
                           headers=as_role("vet"))
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "transition_not_allowed"


def test_lab_statuses_cannot_be_set_by_hand(client, as_role):
    case_id = new_case(client, as_role)
    response = client.post(f"/api/v1/cases/{case_id}/transition", json={"to_status": "lab_result"},
                           headers=as_role("vet"))
    assert response.status_code == 422


def test_closed_case_stays_closed(client, as_role):
    case_id = new_case(client, as_role)
    vet = as_role("vet")
    client.post(f"/api/v1/cases/{case_id}/transition", json={"to_status": "closed_ruled_out"}, headers=vet)
    reopen = client.post(f"/api/v1/cases/{case_id}/transition", json={"to_status": "under_treatment"}, headers=vet)
    assert reopen.status_code == 409


def test_vet_from_another_block_cannot_see_the_case(client, as_role, db):
    from tests.conftest import login

    other_vet = db.scalar(select(User).where(User.role == "vet", User.phone != "9000000003"))
    headers = login(client, other_vet.phone)
    response = client.get(f"/api/v1/cases/{new_case(client, as_role)}", headers=headers)
    assert response.status_code == 404


def test_officer_assigns_a_named_vet(client, as_role, db):
    case_id = new_case(client, as_role)
    officer = as_role("district_officer")
    missing = client.post(f"/api/v1/cases/{case_id}/assign", json={}, headers=officer)
    assert missing.status_code == 422
    vet = db.scalar(select(User).where(User.phone == "9000000003"))
    assigned = client.post(f"/api/v1/cases/{case_id}/assign", json={"vet_id": str(vet.id)}, headers=officer).json()
    assert assigned["status"] == "vet_assigned"


def test_case_queue_puts_emergencies_first(client, as_role):
    client.post("/api/v1/reports", headers=as_role("pashu_sevak"), json=report_payload(
        symptoms=["sudden_death", "bleeding_from_orifices"], sick_count=0, dead_count=1, total_at_risk=5))
    queue = client.get("/api/v1/cases", params={"status": "triaged"}, headers=as_role("vet")).json()
    ranks = [{"emergency": 0, "urgent": 1, "routine": 2}[c["severity"]] for c in queue]
    assert queue[0]["severity"] == "emergency" and ranks == sorted(ranks)


def test_queue_hides_closed_cases_by_default(client, as_role):
    open_queue = client.get("/api/v1/cases", headers=as_role("district_officer")).json()
    assert all(c["status"] not in ("resolved", "closed_ruled_out") for c in open_queue)
    everything = client.get("/api/v1/cases", params={"include_closed": True},
                            headers=as_role("district_officer")).json()
    assert len(everything) > len(open_queue)
