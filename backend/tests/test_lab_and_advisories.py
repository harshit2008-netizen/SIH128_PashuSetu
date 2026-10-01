"""Lab QR loop, advisories to a radius, and the dashboard (spec 8.2, 8.9, 10.7)."""

from app.core.shared_loader import get_shared_data
from tests.helpers import report_payload

DATA = get_shared_data()
_GEO = {v["code"]: v for b in DATA.geo["blocks"] for v in b["villages"]}
UCHCHHIL = _GEO[DATA.geo["demo_cluster_villages"][0]]


def new_case(client, as_role) -> str:
    return client.post("/api/v1/reports", json=report_payload(), headers=as_role("pashu_sevak")).json()["case_id"]


def test_full_lab_loop_writes_every_step_and_confirms_the_disease(client, as_role):
    case_id = new_case(client, as_role)
    sample = client.post(f"/api/v1/cases/{case_id}/samples", json={"sample_type": "skin_scab"},
                         headers=as_role("vet")).json()
    code = sample["qr_code"]
    assert code.startswith("PS-S-") and len(code) == 11 and sample["status"] == "requested"

    # The sevak sees it in "samples to collect", then scans it.
    to_collect = client.get("/api/v1/samples", headers=as_role("pashu_sevak")).json()
    assert code in [s["qr_code"] for s in to_collect]
    assert client.post(f"/api/v1/samples/{code}/scan", headers=as_role("pashu_sevak")).json()["status"] == "collected"
    assert client.post(f"/api/v1/samples/{code.lower()}/scan", headers=as_role("lab")).json()["status"] == "received"
    done = client.post(f"/api/v1/samples/{code}/result", headers=as_role("lab"),
                       json={"result": "positive", "disease": "lsd"}).json()
    assert done["status"] == "resulted" and done["result_disease"] == "lsd"

    case = client.get(f"/api/v1/cases/{case_id}", headers=as_role("vet")).json()
    assert case["confirmed_disease"] == "lsd" and case["status"] == "lab_result"
    assert [e["to_status"] for e in case["timeline"]] == [
        "reported", "triaged", "vet_assigned", "sample_requested", "sample_collected", "lab_received", "lab_result"]
    assert case["samples"][0]["result"] == "positive"


def test_lab_sees_a_requested_sample_and_can_receive_it_unscanned(client, as_role):
    case_id = new_case(client, as_role)
    code = client.post(f"/api/v1/cases/{case_id}/samples", json={}, headers=as_role("vet")).json()["qr_code"]
    waiting = {s["qr_code"]: s["status"] for s in client.get("/api/v1/samples", headers=as_role("lab")).json()}
    assert waiting[code] == "requested"  # the lab knows it is coming

    # It reaches the lab without a collection scan: both steps are recorded, and the timeline says so.
    received = client.post(f"/api/v1/samples/{code}/scan", headers=as_role("lab")).json()
    assert received["status"] == "received"
    timeline = client.get(f"/api/v1/cases/{case_id}", headers=as_role("vet")).json()["timeline"]
    assert [e["to_status"] for e in timeline][-2:] == ["sample_collected", "lab_received"]
    assert "without a collection scan" in timeline[-2]["note"]
    again = client.post(f"/api/v1/samples/{code}/scan", headers=as_role("lab"))
    assert again.status_code == 409 and again.json()["error"]["code"] == "already_received"


def test_vet_can_mark_collected_and_positive_needs_a_disease(client, as_role):
    case_id = new_case(client, as_role)
    code = client.post(f"/api/v1/cases/{case_id}/samples", json={}, headers=as_role("vet")).json()["qr_code"]
    assert client.post(f"/api/v1/samples/{code}/scan", headers=as_role("vet")).json()["status"] == "collected"
    client.post(f"/api/v1/samples/{code}/scan", headers=as_role("lab"))
    missing = client.post(f"/api/v1/samples/{code}/result", headers=as_role("lab"), json={"result": "positive"})
    assert missing.status_code == 422
    assert client.post(f"/api/v1/samples/{code}/result", headers=as_role("farmer"),
                       json={"result": "negative"}).status_code == 403


def test_advisory_reaches_farmers_in_radius_in_their_own_language(client, as_role):
    officer = as_role("district_officer")
    body = {"template_id": "lsd_nearby", "center": {"lat": UCHCHHIL["lat"], "lng": UCHCHHIL["lng"]},
            "radius_km": 10, "variables": {"village": UCHCHHIL["name"]}}
    preview = client.post("/api/v1/advisories/preview", json=body, headers=officer).json()
    assert preview["farmers"] >= 2, "demo farmer and sevak live in Uchchhil"
    assert "1962" in preview["text"]["en"] and UCHCHHIL["name"]["hi"] in preview["text"]["hi"]

    sent = client.post("/api/v1/advisories", json=body, headers=officer).json()
    assert sent["farmers"] == preview["farmers"] and sent["channels"] == ["inapp"]

    inbox = client.get("/api/v1/advisories/inbox", headers=as_role("farmer")).json()
    assert inbox[0]["text"].startswith(UCHCHHIL["name"]["hi"]), "the demo farmer reads Hindi"
    pulled = client.get("/api/v1/sync/pull", headers=as_role("farmer")).json()["advisories"]
    assert pulled and pulled[0]["id"] == inbox[0]["id"]


def test_advisory_template_needs_its_values(client, as_role):
    body = {"template_id": "lsd_nearby", "center": {"lat": 19.2, "lng": 73.9}, "radius_km": 5, "variables": {}}
    response = client.post("/api/v1/advisories/preview", json=body, headers=as_role("vet"))
    assert response.status_code == 422 and response.json()["error"]["code"] == "missing_values"


def test_dashboard_counts_and_map(client, as_role):
    case_id = new_case(client, as_role)
    client.post(f"/api/v1/cases/{case_id}/assign", json={}, headers=as_role("vet"))
    summary = client.get("/api/v1/dashboard/summary", headers=as_role("district_officer")).json()
    assert summary["open_cases"] >= 1 and summary["median_minutes_to_first_response"] is not None
    geo = client.get("/api/v1/dashboard/map", headers=as_role("district_officer")).json()
    assert geo["type"] == "FeatureCollection" and geo["bounds"]["north"] > geo["bounds"]["south"]
    assert any(f["properties"]["id"] == case_id for f in geo["features"])


def test_vet_list_for_assigning(client, as_role):
    vets = client.get("/api/v1/vets", headers=as_role("district_officer")).json()
    assert len(vets) == 13 and all(v["block"]["code"] for v in vets)
