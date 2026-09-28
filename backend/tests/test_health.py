from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_has_expected_shape():
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"status", "db", "scheduler", "demo_mode"}
    assert body["status"] in {"ok", "degraded"}


def test_health_reports_database_ok_when_postgis_is_up():
    # Needs `make up` first; this is the Phase 0 "done when" check.
    body = client.get("/health").json()
    assert body["db"].startswith("ok (PostGIS"), body["db"]
    assert body["status"] == "ok"
