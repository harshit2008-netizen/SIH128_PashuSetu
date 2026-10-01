"""One Health webhook (P2): zoonotic alerts go to the human health department."""

import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

import pytest
from sqlalchemy import select, text

from app.core.config import get_settings
from app.core.shared_loader import get_shared_data
from app.models import Alert
from app.services.notifier.one_health import MAX_ATTEMPTS, send_pending, sign
from scripts.simulator import ACTIVITY_TABLES
from tests.helpers import report_payload

DATA = get_shared_data()
ANTHRAX = {"species": "cattle", "symptoms": ["sudden_death", "bleeding_from_orifices"], "sick_count": 0,
           "dead_count": 1, "total_at_risk": 6}


class Receiver(BaseHTTPRequestHandler):
    received: list = []
    status = 200

    def do_POST(self):  # noqa: N802 (http.server naming)
        body = self.rfile.read(int(self.headers["Content-Length"]))
        Receiver.received.append(({k.lower(): v for k, v in self.headers.items()}, body))  # names are case-insensitive
        self.send_response(Receiver.status)
        self.end_headers()

    def log_message(self, *args):
        pass


@pytest.fixture
def receiver(monkeypatch, db):
    db.execute(text(f"TRUNCATE TABLE {', '.join(ACTIVITY_TABLES)} RESTART IDENTITY CASCADE"))
    db.commit()
    Receiver.received, Receiver.status = [], 200
    server = HTTPServer(("127.0.0.1", 0), Receiver)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    monkeypatch.setattr(get_settings(), "one_health_webhook_url", f"http://127.0.0.1:{server.server_port}/alerts")
    monkeypatch.setattr(get_settings(), "one_health_webhook_secret", "s3cret")
    yield server
    server.shutdown()


def zoonotic_alert(client, as_role, db) -> Alert:
    client.post("/api/v1/reports", json=report_payload(**ANTHRAX), headers=as_role("pashu_sevak"))
    return db.scalar(select(Alert).where(Alert.type == "zoonotic"))


def test_zoonotic_alert_is_posted_once_with_a_signature(client, as_role, db, receiver):
    alert = zoonotic_alert(client, as_role, db)
    assert [a.id for a in send_pending(db, DATA)] == [alert.id]
    headers, body = Receiver.received[0]
    sent = json.loads(body)
    assert sent["event"] == "zoonotic_alert" and sent["suspected_disease"] == "anthrax"
    assert sent["status"] == "suspected, not confirmed by a lab"
    assert headers["x-pashusetu-signature"] == sign(body, "s3cret")
    assert alert.one_health_notified_at is not None
    assert send_pending(db, DATA) == [] and len(Receiver.received) == 1  # never sent twice
    db.commit()
    shown = client.get("/api/v1/alerts", headers=as_role("district_officer")).json()
    assert next(a for a in shown if a["id"] == str(alert.id))["one_health_notified_at"] is not None


def test_a_refusing_receiver_is_retried_then_given_up(client, as_role, db, receiver):
    Receiver.status = 500
    alert = zoonotic_alert(client, as_role, db)
    for _ in range(MAX_ATTEMPTS + 2):
        assert send_pending(db, DATA) == []
    assert alert.one_health_attempts == MAX_ATTEMPTS and alert.one_health_notified_at is None
    assert len(Receiver.received) == MAX_ATTEMPTS


def test_nothing_is_sent_when_no_webhook_is_configured(client, as_role, db, receiver, monkeypatch):
    monkeypatch.setattr(get_settings(), "one_health_webhook_url", "")
    zoonotic_alert(client, as_role, db)
    assert send_pending(db, DATA) == [] and Receiver.received == []
