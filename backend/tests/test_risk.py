"""Block risk estimate (spec 8.8) and the seeded weather cache."""

import math
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import func, select, text

from app.core.shared_loader import get_shared_data
from app.models import WeatherCache
from app.services.risk.risk_score import level_for, nearby_factor, season_factor, weather_factor
from app.services.risk.weather import DayWeather
from scripts.simulator import ACTIVITY_TABLES
from tests.helpers import DEMO_VILLAGE, report_payload

DATA = get_shared_data()


def days(temp_max, temp_min, humidity, rain, n=21):
    start = date(2026, 8, 1)
    return [DayWeather(start + timedelta(days=i), temp_max, temp_min, humidity, rain, "test") for i in range(n)]


def test_lsd_weather_is_high_when_warm_humid_and_rainy_and_low_when_dry():
    wet, _ = weather_factor(DATA, "lsd", days(30, 22, 85, 3))
    dry, _ = weather_factor(DATA, "lsd", days(38, 24, 30, 0))
    assert wet == 1.0 and dry == 0.0


def test_hs_weather_needs_heavy_rain_and_humidity():
    monsoon, _ = weather_factor(DATA, "hs", days(28, 22, 90, 10))
    winter, _ = weather_factor(DATA, "hs", days(29, 12, 50, 0))
    assert monsoon == 1.0 and winter == 0.0


def test_diseases_without_a_weather_model_are_neutral_and_say_so():
    value, details = weather_factor(DATA, "anthrax", days(30, 22, 85, 3))
    assert value == 0.5 and details == {"modelled": False}
    value, details = weather_factor(DATA, "lsd", [])
    assert value == 0.5 and details["days"] == 0


def test_season_nearby_and_levels_follow_the_spec():
    assert season_factor(DATA, "lsd", 8) == 1.0 and season_factor(DATA, "lsd", 1) == 0.3
    assert nearby_factor(DATA, 0) == 0 and math.isclose(nearby_factor(DATA, 5), 1 - math.exp(-1))
    assert (level_for(DATA, 0.7), level_for(DATA, 0.4), level_for(DATA, 0.1)) == ("high", "medium", "low")


def test_seed_fills_21_days_of_weather_for_every_block(db):
    blocks = len(DATA.geo["blocks"])
    assert db.scalar(select(func.count(WeatherCache.id))) >= blocks * 21
    assert set(db.scalars(select(WeatherCache.source).distinct())) <= {"seeded", "open-meteo"}


@pytest.fixture
def no_activity(db):
    db.execute(text(f"TRUNCATE TABLE {', '.join(ACTIVITY_TABLES)} RESTART IDENTITY CASCADE"))
    db.commit()


def test_officer_sees_every_block_with_a_factor_breakdown(client, as_role, no_activity):
    response = client.get("/api/v1/risk", params={"disease": "lsd"}, headers=as_role("district_officer"))
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["label"]["en"] == "Risk estimate v1 (rule-based)"
    blocks = body["blocks"]
    assert len(blocks) == len(DATA.geo["blocks"])
    assert [b["score"] for b in blocks] == sorted((b["score"] for b in blocks), reverse=True)
    for b in blocks:
        contributions = sum(f["contribution"] for f in b["factors"].values())
        assert math.isclose(b["score"], round(contributions, 3), abs_tol=0.002)
        assert b["level"] == level_for(DATA, b["score"])
    # Seeded vaccination coverage is uneven (30-85%), so the immunity gap differs between blocks.
    gaps = {b["factors"]["immunity_gap"]["value"] for b in blocks}
    assert len(gaps) > 3


def test_nearby_lsd_cases_raise_that_blocks_risk(client, as_role, no_activity):
    def junnar(headers):
        body = client.get("/api/v1/risk", params={"disease": "lsd"}, headers=headers).json()
        return next(b for b in body["blocks"] if b["code"] == "junnar")

    officer = as_role("district_officer")
    before = junnar(officer)
    for _ in range(4):
        client.post("/api/v1/reports", json=report_payload(created_on_device_at=datetime.now(UTC).isoformat(),
                                                            location={"lat": DEMO_VILLAGE["lat"], "lng": DEMO_VILLAGE["lng"]}),
                    headers=as_role("pashu_sevak"))
    after = junnar(officer)
    assert after["factors"]["nearby"]["cases"] == before["factors"]["nearby"]["cases"] + 4
    assert after["score"] > before["score"]


def test_risk_is_for_officers_and_known_diseases(client, as_role):
    assert client.get("/api/v1/risk", headers=as_role("pashu_sevak")).status_code == 403
    assert client.get("/api/v1/risk", params={"disease": "flu"}, headers=as_role("district_officer")).status_code == 422
