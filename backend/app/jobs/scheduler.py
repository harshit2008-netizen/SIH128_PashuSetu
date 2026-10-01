"""Background jobs inside the API process (APScheduler, no Redis needed).

Clustering and spikes also run right after each new report; the timers
catch the rest: reports ageing out of windows, the daily spike count,
SLA escalation every minute and the daily weather refresh.
"""

import logging
from datetime import UTC, datetime

from apscheduler.schedulers.background import BackgroundScheduler

from app.core.config import get_settings
from app.core.db import SessionLocal
from app.core.shared_loader import get_shared_data
from app.services.escalation import run_escalation
from app.services.risk.weather import refresh_all_blocks
from app.services.surveillance.aberration import run_spikes
from app.services.surveillance.alerting import IST, run_clustering

log = logging.getLogger("pashusetu.jobs")
scheduler = BackgroundScheduler(timezone="Asia/Kolkata")


def clustering_job() -> None:
    with SessionLocal() as db:
        alerts = run_clustering(db, get_shared_data())
        db.commit()
    log.info("clustering job: %d cluster alerts open or updated", len(alerts))


def spikes_job() -> None:
    with SessionLocal() as db:
        alerts = run_spikes(db, get_shared_data())
        db.commit()
    log.info("spike job: %d spike alerts open or updated", len(alerts))


def escalation_job() -> None:
    with SessionLocal() as db:
        cases = run_escalation(db)
        db.commit()
    if cases:
        log.info("escalation job: %d cases moved up a level", len(cases))


def weather_job() -> None:
    with SessionLocal() as db:
        full = refresh_all_blocks(db, datetime.now(UTC).astimezone(IST).date())
        db.commit()
    log.info("weather job: %d blocks with a full 21-day window", full)


def start_scheduler() -> None:
    settings = get_settings()
    if not settings.scheduler_enabled or scheduler.running:
        return
    scheduler.add_job(clustering_job, "interval", minutes=settings.cluster_job_minutes, id="clustering",
                      replace_existing=True)
    # EARS C2 counts whole days, so the daily run is early morning (spec 8.5).
    scheduler.add_job(spikes_job, "cron", hour=6, minute=0, id="spikes", replace_existing=True)
    scheduler.add_job(escalation_job, "interval", minutes=1, id="escalation", replace_existing=True)
    scheduler.add_job(weather_job, "cron", hour=5, minute=30, id="weather", replace_existing=True)
    scheduler.start()


def stop_scheduler() -> None:
    if scheduler.running:
        scheduler.shutdown(wait=False)


def scheduler_status() -> str:
    return "running" if scheduler.running else "not_started"
