from fastapi import APIRouter

from app.api.v1 import alerts, auth, cases, geo, meta, reports, triage

api_router = APIRouter(prefix="/api/v1")
for module in (auth, reports, triage, cases, alerts, geo, meta):
    api_router.include_router(module.router)
