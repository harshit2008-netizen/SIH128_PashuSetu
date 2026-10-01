"""App settings, read from the repo-root .env file (see .env.example).

One Settings object is shared by the whole backend so every tunable number
(cluster radius, SLA minutes, ...) lives in one place and can be changed
without touching code.
"""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# backend/app/core/config.py -> repo root is three parents up from app/.
REPO_ROOT = Path(__file__).resolve().parents[3]
BACKEND_DIR = REPO_ROOT / "backend"
SHARED_DIR = REPO_ROOT / "shared"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=REPO_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    database_url: str = "postgresql+psycopg://pashu:pashu@localhost:5433/pashusetu"
    jwt_secret: str = "change-me-for-anything-real"
    demo_mode: bool = True
    demo_otp: str = "123456"
    demo_district: str = "pune"
    helpline_number: str = "1962"

    cluster_radius_km: float = 5
    cluster_min_reports: int = 3
    cluster_window_days: int = 14
    # Background jobs (APScheduler). Tests turn this off.
    scheduler_enabled: bool = True
    cluster_job_minutes: int = 5

    sla_emergency_min: int = 120
    sla_urgent_min: int = 720
    sla_routine_min: int = 4320
    demo_sla_emergency_min: int = 2
    demo_sla_urgent_min: int = 5
    demo_sla_routine_min: int = 15

    notifier_channels: str = "inapp"
    # One Health (P2): POST zoonotic alerts to the human health department. Off when empty.
    one_health_webhook_url: str = ""
    one_health_webhook_secret: str = ""  # if set, each POST carries an HMAC-SHA256 signature
    open_meteo_base_url: str = "https://api.open-meteo.com/v1/forecast"
    upload_dir: str = "./uploads"
    cors_origins: str = "*"

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
