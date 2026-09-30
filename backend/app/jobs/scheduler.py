"""Background jobs inside the API process (APScheduler, no Redis needed).

Clustering also runs right after each new report; this timer catches
anything else (e.g. reports that age out of the 14-day window).
"""

import logging

from apscheduler.schedulers.background import BackgroundScheduler

from app.core.config import get_settings
from app.core.db import SessionLocal
from app.core.shared_loader import get_shared_data
from app.services.surveillance.alerting import run_clustering

log = logging.getLogger("pashusetu.jobs")
scheduler = BackgroundScheduler(timezone="Asia/Kolkata")


def clustering_job() -> None:
    with SessionLocal() as db:
        alerts = run_clustering(db, get_shared_data())
        db.commit()
    log.info("clustering job: %d cluster alerts open or updated", len(alerts))


def start_scheduler() -> None:
    settings = get_settings()
    if not settings.scheduler_enabled or scheduler.running:
        return
    scheduler.add_job(clustering_job, "interval", minutes=settings.cluster_job_minutes, id="clustering",
                      replace_existing=True)
    scheduler.start()


def stop_scheduler() -> None:
    if scheduler.running:
        scheduler.shutdown(wait=False)


def scheduler_status() -> str:
    return "running" if scheduler.running else "not_started"
