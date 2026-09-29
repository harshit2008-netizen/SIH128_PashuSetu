"""Small builders for report payloads used across tests."""

import uuid
from datetime import UTC, datetime

from app.core.shared_loader import get_shared_data

# Centre of the Junnar demo cluster, from the shared geography.
_GEO = get_shared_data().geo
_JUNNAR = next(b for b in _GEO["blocks"] if b["code"] == "junnar")
DEMO_VILLAGE = next(v for v in _JUNNAR["villages"] if v["code"] == _GEO["demo_cluster_villages"][0])


def report_payload(**overrides) -> dict:
    payload = {
        "client_uuid": str(uuid.uuid4()),
        "location": {"lat": DEMO_VILLAGE["lat"], "lng": DEMO_VILLAGE["lng"]},
        "species": "cattle",
        "symptoms": ["skin_nodules", "fever", "enlarged_lymph_nodes"],
        "sick_count": 2,
        "dead_count": 0,
        "total_at_risk": 12,
        "created_on_device_at": datetime(2026, 9, 26, 9, 41, tzinfo=UTC).isoformat(),
        "channel": "app",
    }
    payload.update(overrides)
    return payload
