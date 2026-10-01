"""One Health webhook (spec 7.7, P2): tell the human health department about
suspected diseases that spread to people (anthrax, bird flu).

Off unless ONE_HEALTH_WEBHOOK_URL is set. The scheduler sends every zoonotic
alert not yet accepted, up to MAX_ATTEMPTS times; `one_health_notified_at` is
set only on a 2xx reply, so the app never claims a notification that did not
happen. With ONE_HEALTH_WEBHOOK_SECRET, each POST carries
X-PashuSetu-Signature: sha256=<hex HMAC of the body>, so the receiver can
check it came from us.
"""

import hashlib
import hmac
import json
import logging
import urllib.error
import urllib.request
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.shared_loader import SharedData
from app.models import Alert, Block, District
from app.services.geo_utils import point_latlng

log = logging.getLogger("pashusetu.one_health")
MAX_ATTEMPTS = 5
TIMEOUT_SECONDS = 10


def payload(db: Session, data: SharedData, alert: Alert) -> dict:
    block = db.get(Block, alert.block_id) if alert.block_id else None
    district = db.get(District, alert.district_id) if alert.district_id else None
    rule = data.rules.get(alert.disease or "")
    return {
        "event": "zoonotic_alert",
        "source": "PashuSetu",
        "alert_id": str(alert.id),
        "suspected_disease": alert.disease,
        "disease_name": rule["name"]["en"] if rule else None,
        "status": "suspected, not confirmed by a lab",
        "severity": alert.severity,
        "summary": alert.explanation.get("summary", {}).get("en"),
        "villages": alert.explanation.get("village_names", []),
        "block": block.name["en"] if block else None,
        "district": district.name["en"] if district else None,
        "location": point_latlng(alert.center) if alert.center is not None else None,
        "case_ids": [str(c) for c in alert.case_ids],
        "alert_created_at": alert.created_at.isoformat(),
    }


def sign(body: bytes, secret: str) -> str:
    return "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()


def post(url: str, body: bytes, secret: str) -> int:
    headers = {"Content-Type": "application/json", "User-Agent": "PashuSetu-OneHealth/1"}
    if secret:
        headers["X-PashuSetu-Signature"] = sign(body, secret)
    with urllib.request.urlopen(urllib.request.Request(url, data=body, headers=headers, method="POST"),
                                timeout=TIMEOUT_SECONDS) as response:
        return response.status


def send_pending(db: Session, data: SharedData) -> list[Alert]:
    """Send zoonotic alerts not yet accepted. Returns the ones accepted this run."""
    settings = get_settings()
    if not settings.one_health_webhook_url:
        return []
    pending = db.scalars(select(Alert).where(
        Alert.type == "zoonotic", Alert.one_health_notified_at.is_(None),
        Alert.one_health_attempts < MAX_ATTEMPTS).order_by(Alert.created_at)).all()
    sent = []
    for alert in pending:
        alert.one_health_attempts += 1
        body = json.dumps(payload(db, data, alert)).encode()
        try:
            status = post(settings.one_health_webhook_url, body, settings.one_health_webhook_secret)
        except (urllib.error.URLError, OSError) as error:  # includes HTTP 4xx/5xx (HTTPError)
            log.warning("One Health webhook failed for alert %s (attempt %d): %s",
                        alert.id, alert.one_health_attempts, error)
            continue
        if 200 <= status < 300:
            alert.one_health_notified_at = datetime.now(UTC)
            sent.append(alert)
    db.flush()
    return sent
