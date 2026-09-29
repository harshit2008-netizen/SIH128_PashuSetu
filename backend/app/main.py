"""PashuSetu FastAPI application entry point."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.api.v1 import api_router
from app.core.config import get_settings
from app.core.db import engine
from app.core.errors import install_error_handlers
from app.core.shared_loader import get_shared_data

settings = get_settings()

# Load and check shared/ now, so a broken rule file stops the server at start-up
# instead of failing the first report.
get_shared_data()

app = FastAPI(
    title="PashuSetu API",
    version="0.1.0",
    description="Livestock disease reporting, triage, surveillance and advisories. "
                "Log in with POST /api/v1/auth/otp/verify (demo OTP 123456), then press Authorize.",
)
install_error_handlers(app)
app.include_router(api_router)

# Open CORS only for the local demo; a real deployment must list its origins.
if settings.demo_mode:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_methods=["*"],
        allow_headers=["*"],
    )


def check_database() -> str:
    """Return "ok (PostGIS x.y)" or a short error, without raising."""
    try:
        with engine.connect() as conn:
            version = conn.execute(text("SELECT PostGIS_Lib_Version()")).scalar_one()
        return f"ok (PostGIS {version})"
    except SQLAlchemyError as exc:
        return f"error: {exc.__class__.__name__}"


@app.get("/health", tags=["meta"])
def health() -> dict:
    db_status = check_database()
    return {
        "status": "ok" if db_status.startswith("ok") else "degraded",
        "db": db_status,
        # Background jobs (clustering, escalation) arrive in Phase 7.
        "scheduler": "not_started",
        "demo_mode": settings.demo_mode,
    }
