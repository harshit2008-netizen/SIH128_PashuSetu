"""Outbreak detection (spec 8.4 and the testing table in section 12)."""

from datetime import UTC, datetime

import pytest
from shapely.geometry import Point
from sqlalchemy import func, select, text

from app.core.shared_loader import get_shared_data
from app.models import Alert
from app.services.surveillance.alerting import run_clustering
from app.services.surveillance.clustering import LatLng, area_around, find_clusters, haversine_km
from scripts.simulator import ACTIVITY_TABLES
from tests.helpers import report_payload

DATA = get_shared_data()
_GEO = {v["code"]: v for b in DATA.geo["blocks"] for v in b["villages"]}
CLUSTER_VILLAGES = [_GEO[code] for code in DATA.geo["demo_cluster_villages"]]
FAR_VILLAGES = [b["villages"][0] for b in DATA.geo["blocks"] if b["code"] in ("indapur", "bhor", "shirur")]


@pytest.fixture(autouse=True)
def no_activity(db):
    # Other test files leave reports behind; clustering tests need a clean slate.
    db.execute(text(f"TRUNCATE TABLE {', '.join(ACTIVITY_TABLES)} RESTART IDENTITY CASCADE"))
    db.commit()


def post(client, headers, village, **overrides):
    payload = report_payload(location={"lat": village["lat"], "lng": village["lng"]},
                             created_on_device_at=datetime.now(UTC).isoformat(), **overrides)
    response = client.post("/api/v1/reports", json=payload, headers=headers)
    assert response.status_code == 200, response.text
    return response.json()


def cluster_alerts(db):
    return db.scalars(select(Alert).where(Alert.type == "cluster")).all()


def test_dbscan_groups_near_points_and_ignores_far_ones():
    near = [LatLng(19.20, 73.87), LatLng(19.21, 73.88), LatLng(19.22, 73.87)]
    far = [LatLng(18.2, 74.9)]
    assert find_clusters(near + far, radius_km=5, min_reports=3) == [[0, 1, 2]]
    assert find_clusters(near[:2] + far, radius_km=5, min_reports=3) == []


def test_area_covers_every_report_with_a_margin():
    points = [LatLng(19.20, 73.87), LatLng(19.23, 73.90)]
    area = area_around(points)
    assert all(area.contains(Point(p.lng, p.lat)) for p in points)
    assert haversine_km(points[0], points[1]) < 5


def test_three_nearby_reports_make_one_alert_and_reruns_do_not_duplicate(client, as_role, db):
    headers = as_role("pashu_sevak")
    for village in CLUSTER_VILLAGES[:3]:
        post(client, headers, village)
    alerts = cluster_alerts(db)
    assert len(alerts) == 1
    alert = alerts[0]
    assert alert.syndrome == "dermatological" and alert.disease == "lsd"
    assert alert.explanation["reports"] == 3 and alert.explanation["villages"] == 3
    assert alert.explanation["summary"]["en"] == "3 reports of skin lumps and swelling in 3 villages within 1 day"

    run_clustering(db, DATA)
    run_clustering(db, DATA)
    db.commit()
    assert len(cluster_alerts(db)) == 1, "re-running must update, not duplicate"

    post(client, headers, CLUSTER_VILLAGES[3])
    db.expire_all()
    grown = cluster_alerts(db)
    assert len(grown) == 1 and grown[0].explanation["reports"] == 4


def test_far_apart_reports_make_no_alert(client, as_role, db):
    for village in FAR_VILLAGES:
        post(client, as_role("pashu_sevak"), village)
    assert cluster_alerts(db) == []


def test_general_signs_never_cluster(client, as_role, db):
    for village in CLUSTER_VILLAGES[:3]:
        post(client, as_role("pashu_sevak"), village, symptoms=["fever", "anorexia"])
    assert cluster_alerts(db) == []


def test_anthrax_death_raises_an_emergency_zoonotic_alert(client, as_role, db):
    post(client, as_role("pashu_sevak"), FAR_VILLAGES[0], symptoms=["sudden_death", "bleeding_from_orifices"],
         sick_count=0, dead_count=1, total_at_risk=5)
    alerts = db.scalars(select(Alert).where(Alert.type == "zoonotic")).all()
    assert len(alerts) == 1
    assert alerts[0].severity == "emergency" and alerts[0].disease == "anthrax"
    assert "Anthrax" in alerts[0].explanation["summary"]["en"]


def test_mass_poultry_deaths_raise_a_mortality_alert(client, as_role, db):
    post(client, as_role("pashu_sevak"), FAR_VILLAGES[1], species="poultry",
         symptoms=["sudden_high_mortality"], sick_count=5, dead_count=30, total_at_risk=200)
    assert db.scalar(select(func.count(Alert.id)).where(Alert.type == "mortality")) == 1


def test_alerts_api_lists_and_acknowledges(client, as_role):
    for village in CLUSTER_VILLAGES[:3]:
        post(client, as_role("pashu_sevak"), village)
    officer = as_role("district_officer")
    alerts = client.get("/api/v1/alerts", headers=officer).json()
    assert len(alerts) == 1 and alerts[0]["area"]["type"] == "Polygon"
    acked = client.post(f"/api/v1/alerts/{alerts[0]['id']}/acknowledge", headers=officer).json()
    assert acked["status"] == "acknowledged" and acked["acknowledged_by"]["role"] == "district_officer"
    assert client.get("/api/v1/alerts", headers=as_role("farmer")).status_code == 403
