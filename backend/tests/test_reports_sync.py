import uuid

from sqlalchemy import func, select

from app.models import Report
from tests.helpers import DEMO_VILLAGE, report_payload


def post_report(client, headers, **overrides):
    return client.post("/api/v1/reports", json=report_payload(**overrides), headers=headers)


def test_report_is_triaged_on_server_and_opens_a_case(client, as_role):
    response = post_report(client, as_role("pashu_sevak"))
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["status"] == "created"
    assert body["triage"]["candidates"][0]["disease_id"] == "lsd"
    assert body["triage"]["severity"] == "urgent"

    case = client.get(f"/api/v1/cases/{body['case_id']}", headers=as_role("vet")).json()
    assert case["status"] == "triaged"
    assert case["suspected_disease"] == "lsd"
    assert [e["to_status"] for e in case["timeline"]] == ["reported", "triaged"]


def test_same_client_uuid_twice_gives_one_report(client, as_role, db):
    payload = report_payload()
    first = client.post("/api/v1/reports", json=payload, headers=as_role("pashu_sevak")).json()
    second = client.post("/api/v1/reports", json=payload, headers=as_role("pashu_sevak")).json()
    assert second["status"] == "duplicate"
    assert second["report"]["id"] == first["report"]["id"]
    assert second["case_id"] == first["case_id"]
    count = db.scalar(select(func.count(Report.id)).where(Report.client_uuid == uuid.UUID(payload["client_uuid"])))
    assert count == 1


def test_sync_push_reports_each_item_separately(client, as_role):
    existing = report_payload()
    client.post("/api/v1/reports", json=existing, headers=as_role("pashu_sevak"))
    batch = [report_payload(), existing, report_payload(symptoms=["not_a_real_sign"])]
    results = client.post("/api/v1/sync/push", json={"reports": batch}, headers=as_role("pashu_sevak")).json()
    assert [r["status"] for r in results["results"]] == ["created", "duplicate", "error"]
    assert "Unknown sign" in results["results"][2]["message"]


def test_device_and_server_disagreement_is_flagged(client, as_role):
    body = post_report(client, as_role("pashu_sevak"),
                       device_triage={"engine_version": "rules-1", "top": "fmd", "score": 0.6}).json()
    assert body["triage"]["triage_mismatch"] is True


def test_nearest_village_is_used_when_none_is_given(client, as_role):
    body = post_report(client, as_role("pashu_sevak")).json()
    village = client.get("/api/v1/geo/villages", params={"near": f"{DEMO_VILLAGE['lat']},{DEMO_VILLAGE['lng']}"},
                         headers=as_role("pashu_sevak")).json()[0]
    assert body["report"]["village_id"] == village["id"]
    assert village["distance_km"] < 0.01


def test_follow_up_for_same_herd_joins_the_open_case(client, as_role, db):
    from app.models import Herd, User

    farmer = db.scalar(select(User).where(User.phone == "9000000001"))
    herd = db.scalar(select(Herd).where(Herd.owner_user_id == farmer.id).order_by(Herd.name))
    first = post_report(client, as_role("farmer"), herd_id=str(herd.id)).json()
    second = post_report(client, as_role("farmer"), herd_id=str(herd.id)).json()
    assert second["case_id"] == first["case_id"]
    case = client.get(f"/api/v1/cases/{first['case_id']}", headers=as_role("farmer")).json()
    assert len(case["reports"]) == 2
    assert case["timeline"][-1]["note"] == "Follow-up report"


def test_report_needs_a_sign_or_a_death(client, as_role):
    response = post_report(client, as_role("pashu_sevak"), symptoms=[], dead_count=0)
    assert response.status_code == 422
    assert response.json()["error"]["code"] == "invalid_request"


def test_photo_probability_is_fused_and_asks_about_lumps(client, as_role):
    body = post_report(client, as_role("pashu_sevak"), symptoms=["fever"],
                       device_triage={"top": "lsd", "score": 0.5, "image_p_lsd": 0.95}).json()
    lsd = next(c for c in body["triage"]["candidates"] if c["disease_id"] == "lsd")
    assert lsd["sources"]["image"] == 0.95
    assert body["triage"]["photo"]["ask_about_skin_nodules"] is True
    assert body["triage"]["engine_version"] == "rules-1+lsd_v1"


def test_photo_upload_and_type_check(client, as_role):
    headers = as_role("pashu_sevak")
    report_id = post_report(client, headers).json()["report"]["id"]
    jpeg = b"\xff\xd8\xff\xe0" + b"0" * 64
    ok = client.post(f"/api/v1/reports/{report_id}/photo", files={"photo": ("cow.jpg", jpeg, "image/jpeg")},
                     headers=headers)
    assert ok.status_code == 200 and ok.json()["has_photo"] is True
    wrong = client.post(f"/api/v1/reports/{report_id}/photo", files={"photo": ("a.txt", b"hi", "text/plain")},
                        headers=headers)
    assert wrong.status_code == 415


def test_only_the_reporter_can_add_a_photo(client, as_role):
    report_id = post_report(client, as_role("pashu_sevak")).json()["report"]["id"]
    response = client.post(f"/api/v1/reports/{report_id}/photo",
                           files={"photo": ("cow.jpg", b"\xff\xd8", "image/jpeg")}, headers=as_role("farmer"))
    assert response.status_code == 403


def test_sync_pull_returns_my_cases_and_due_vaccinations(client, as_role):
    post_report(client, as_role("farmer"))
    body = client.get("/api/v1/sync/pull", headers=as_role("farmer")).json()
    assert body["cases"], "the farmer's own case should come back"
    assert any(v["animal_name"] == "Gauri" and v["vaccine"] == "FMD" for v in body["vaccinations_due"])
    assert any(a["name"] == "Gauri" and len(a["ear_tag"]) == 12 for a in body["animals"])


def test_stateless_triage_endpoint(client, as_role):
    body = client.post("/api/v1/triage/evaluate", headers=as_role("vet"), json={
        "species": "cattle", "symptoms": ["sudden_death", "bleeding_from_orifices"], "dead_count": 1,
        "report_month": 5}).json()
    assert body["candidates"][0]["disease_id"] == "anthrax"
    assert body["severity"] == "emergency" and body["safety_note"] is not None
