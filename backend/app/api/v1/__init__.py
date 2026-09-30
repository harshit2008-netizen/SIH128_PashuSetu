from fastapi import APIRouter

from app.api.v1 import advisories, alerts, auth, cases, dashboard, geo, labs, meta, reports, triage

api_router = APIRouter(prefix="/api/v1")
for module in (auth, reports, triage, cases, labs, alerts, advisories, dashboard, geo, meta):
    api_router.include_router(module.router)
