from fastapi import APIRouter

from app.api.v1 import auth, cases, geo, meta, reports, triage

api_router = APIRouter(prefix="/api/v1")
for module in (auth, reports, triage, cases, geo, meta):
    api_router.include_router(module.router)
