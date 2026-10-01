"""Daily weather from Open-Meteo (free, no key), cached in weather_cache.

The risk score needs the last 14 days and the next 7. Reads come from the
cache, so risk works with no internet during the demo; the seed fills the
cache (live data when online, plainly labelled `seeded` values when not).
"""

import json
import logging
import urllib.parse
import urllib.request
from dataclasses import dataclass
from datetime import date, timedelta

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Block, WeatherCache
from app.services.geo_utils import point_latlng

log = logging.getLogger("pashusetu.weather")
DAILY = "temperature_2m_max,temperature_2m_min,precipitation_sum,relative_humidity_2m_mean"


@dataclass(frozen=True)
class DayWeather:
    day: date
    temp_max: float | None
    temp_min: float | None
    humidity_mean: float | None
    precip_mm: float | None
    source: str


def cache_key(lat: float, lng: float) -> tuple[float, float]:
    """About 11 km cells: nearby villages share one weather series."""
    return round(lat, 1), round(lng, 1)


def fetch_open_meteo(lat: float, lng: float, past_days: int, forecast_days: int, timeout: float = 10) -> list[DayWeather]:
    query = urllib.parse.urlencode({"latitude": lat, "longitude": lng, "daily": DAILY, "past_days": past_days,
                                    "forecast_days": forecast_days, "timezone": "Asia/Kolkata"})
    with urllib.request.urlopen(f"{get_settings().open_meteo_base_url}?{query}", timeout=timeout) as response:
        daily = json.load(response)["daily"]
    return [DayWeather(date.fromisoformat(day), daily["temperature_2m_max"][i], daily["temperature_2m_min"][i],
                       daily["relative_humidity_2m_mean"][i], daily["precipitation_sum"][i], "open-meteo")
            for i, day in enumerate(daily["time"])]


def store(db: Session, lat: float, lng: float, days: list[DayWeather], today: date) -> None:
    key_lat, key_lng = cache_key(lat, lng)
    wanted = [d.day for d in days]
    db.execute(delete(WeatherCache).where(WeatherCache.lat == key_lat, WeatherCache.lng == key_lng,
                                          WeatherCache.date.in_(wanted)))
    for d in days:
        db.add(WeatherCache(lat=key_lat, lng=key_lng, date=d.day, temp_max=d.temp_max, temp_min=d.temp_min,
                            humidity_mean=d.humidity_mean, precip_mm=d.precip_mm, source=d.source,
                            days_ahead=max((d.day - today).days, 0)))


def cached(db: Session, lat: float, lng: float, start: date, end: date) -> list[DayWeather]:
    key_lat, key_lng = cache_key(lat, lng)
    rows = db.scalars(select(WeatherCache).where(
        WeatherCache.lat == key_lat, WeatherCache.lng == key_lng, WeatherCache.date.between(start, end))
        .order_by(WeatherCache.date)).all()
    return [DayWeather(r.date, r.temp_max, r.temp_min, r.humidity_mean, r.precip_mm, r.source) for r in rows]


def weather_window(db: Session, lat: float, lng: float, today: date, past_days: int, forecast_days: int,
                   fetch: bool = False) -> list[DayWeather]:
    """Last `past_days` and next `forecast_days` from the cache. Only the seed and the
    daily job pass `fetch=True`; requests never wait on the network (it may be absent
    at the demo). A failed fetch falls back to the cache."""
    start, end = today - timedelta(days=past_days), today + timedelta(days=forecast_days - 1)
    days = cached(db, lat, lng, start, end)
    if fetch:
        try:
            store(db, lat, lng, fetch_open_meteo(lat, lng, past_days, forecast_days), today)
            db.flush()
            days = cached(db, lat, lng, start, end)
        except (OSError, ValueError, KeyError) as error:  # no internet, timeout, odd reply
            log.warning("Open-Meteo unavailable (%s); using %d cached days", error, len(days))
    return days


def refresh_all_blocks(db: Session, today: date, past_days: int = 14, forecast_days: int = 7) -> int:
    """Daily job: fetch fresh weather for every block centroid. Returns how many blocks have a full window."""
    full = 0
    for block in db.scalars(select(Block)):
        centre = point_latlng(block.centroid)
        days = weather_window(db, centre["lat"], centre["lng"], today, past_days, forecast_days, fetch=True)
        full += len(days) == past_days + forecast_days
    return full
