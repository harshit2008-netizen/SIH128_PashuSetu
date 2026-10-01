"""Spike detection with EARS C2 (spec 8.5)."""

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select, text

from app.core.shared_loader import get_shared_data
from app.models import Alert
from app.services.surveillance.aberration import c2_score, ist_day, is_spike, run_spikes
from scripts.simulator import ACTIVITY_TABLES
from tests.helpers import report_payload

DATA = get_shared_data()
_HAVELI = next(b for b in DATA.geo["blocks"] if b["code"] == "haveli")
# Three Haveli villages more than 30 km apart: a spike, but never a cluster.
SPREAD_OUT = [v for v in _HAVELI["villages"] if v["code"] in ("haveli_kalyan_gaon", "haveli_mamurdi", "haveli_loni_kalbhor")]
CLOSE_TOGETHER = [next(b for b in DATA.geo["blocks"] if b["code"] == "junnar")["villages"][0]] * 3


@pytest.fixture(autouse=True)
def no_activity(db):
    db.execute(text(f"TRUNCATE TABLE {', '.join(ACTIVITY_TABLES)} RESTART IDENTITY CASCADE"))
    db.commit()


def post(client, headers, village, when):
    payload = report_payload(location={"lat": village["lat"], "lng": village["lng"]},
                             created_on_device_at=when.isoformat())
    response = client.post("/api/v1/reports", json=payload, headers=headers)
    assert response.status_code == 200, response.text


def spikes(db):
    db.expire_all()
    return db.scalars(select(Alert).where(Alert.type == "spike")).all()


def test_c2_matches_the_spec_formula():
    score, mean, sigma = c2_score(7, [1, 0, 2, 1, 0, 1, 1])
    assert round(mean, 2) == 0.86 and round(sigma, 2) == 0.69 and round(score, 1) == 8.9
    assert c2_score(3, [0] * 7)[2] == 0.5  # flat baseline: sigma floored at 0.5


def test_three_today_on_a_quiet_baseline_is_a_spike_but_two_is_not():
    assert is_spike(3, [0] * 7)
    assert not is_spike(2, [0] * 7)  # C2 is 4, but fewer than 3 reports today
    assert not is_spike(4, [3, 4, 5, 3, 4, 5, 4])  # a normal day for a busy block


def test_spread_out_reports_in_one_block_raise_one_spike_alert(client, as_role, db):
    now = datetime.now(UTC)
    for village in SPREAD_OUT:
        post(client, as_role("pashu_sevak"), village, now)
    alerts = spikes(db)
    assert len(alerts) == 1
    alert = alerts[0]
    assert alert.explanation["today"] == 3 and alert.explanation["baseline_mean"] == 0.0
    assert alert.explanation["c2"] == 6.0 and alert.explanation["block"] == "Haveli"
    assert "usually about 0.0 a day" in alert.explanation["summary"]["en"]
    assert db.scalars(select(Alert).where(Alert.type == "cluster")).all() == []

    post(client, as_role("pashu_sevak"), SPREAD_OUT[0], now)  # a 4th report the same day
    alerts = spikes(db)
    assert len(alerts) == 1 and alerts[0].explanation["today"] == 4


def test_no_spike_where_a_cluster_alert_already_covers_the_outbreak(client, as_role, db):
    now = datetime.now(UTC)
    for village in CLOSE_TOGETHER:
        post(client, as_role("pashu_sevak"), village, now)
    assert len(db.scalars(select(Alert).where(Alert.type == "cluster")).all()) == 1
    assert spikes(db) == []


def test_reports_from_last_week_raise_the_baseline(client, as_role, db):
    now = datetime.now(UTC)
    for days_ago in (3, 4, 5, 6, 7, 8, 9):  # a steady 3 a day before today
        for village in SPREAD_OUT:
            post(client, as_role("pashu_sevak"), village, now - timedelta(days=days_ago))
    db.execute(text("DELETE FROM alerts"))
    db.commit()
    for village in SPREAD_OUT:
        post(client, as_role("pashu_sevak"), village, now)
    assert spikes(db) == []
    assert run_spikes(db, DATA, ist_day(now)) == []
