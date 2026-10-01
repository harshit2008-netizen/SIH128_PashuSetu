from fastapi import APIRouter

from app.api.v1 import advisories, alerts, animals, auth, cases, dashboard, geo, labs, meta, reports, risk, triage

api_router = APIRouter(prefix="/api/v1")
for module in (auth, reports, animals, triage, cases, labs, alerts, advisories, dashboard, risk, geo, meta):
    api_router.include_router(module.router)
