"""Reports by SMS (P2): parsed with the same lexicon as voice, filed as normal reports."""

import pytest

from app.core.config import get_settings
from tests.conftest import PHONES

TOKEN = {"X-Gateway-Token": "gw-secret"}


@pytest.fixture(autouse=True)
def sms_on(monkeypatch):
    monkeypatch.setattr(get_settings(), "sms_inbound_token", "gw-secret")


def sms(client, sender, text, message_id=None, headers=TOKEN):
    body = {"from": sender, "text": text, **({"message_id": message_id} if message_id else {})}
    return client.post("/api/v1/sms/inbound", json=body, headers=headers)


def test_a_hindi_sms_becomes_a_triaged_report_with_a_hindi_reply(client, as_role):
    response = sms(client, "+91" + PHONES["farmer"], "गाय के शरीर पर गांठें हैं, बुखार है, दो गाय बीमार हैं।", "gw-1")
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["status"] == "created"
    assert "लम्पी स्किन रोग" in body["reply"] and "1962" in body["reply"] and "निदान नहीं" in body["reply"]
    case = client.get(f"/api/v1/cases/{body['case_id']}", headers=as_role("vet")).json()
    report = case["reports"][0]
    assert case["suspected_disease"] == "lsd"
    assert report["channel"] == "sms" and report["sick_count"] == 2
    assert set(report["symptoms"]) == {"skin_nodules", "fever"}
    # The gateway retried the same message: no second report.
    again = sms(client, "+91" + PHONES["farmer"], "गाय के शरीर पर गांठें हैं, बुखार है, दो गाय बीमार हैं।", "gw-1").json()
    assert again["status"] == "duplicate" and again["case_id"] == body["case_id"]


def test_unclear_messages_get_a_helpful_reply_and_no_report(client):
    farmer = PHONES["farmer"]
    assert sms(client, farmer, "बुखार है").json()["status"] == "need_animal"
    assert sms(client, farmer, "गाय ठीक नहीं लग रही").json()["status"] == "need_signs"
    stranger = sms(client, "9999999999", "गाय को बुखार है").json()
    assert stranger["status"] == "not_registered" and "दर्ज नहीं" in stranger["reply"]


def test_only_the_configured_gateway_may_post(client, monkeypatch):
    assert sms(client, PHONES["farmer"], "गाय को बुखार है", headers={"X-Gateway-Token": "wrong"}).status_code == 401
    monkeypatch.setattr(get_settings(), "sms_inbound_token", "")
    assert sms(client, PHONES["farmer"], "गाय को बुखार है").status_code == 404
