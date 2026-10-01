"""Test setup: a separate pashusetu_test database, migrated and seeded once.

Tests never touch the demo database. The URL is switched before any app
module creates its engine, which is why this runs at import time.
"""

import os
import tempfile

from sqlalchemy import create_engine, text

from app.core.config import BACKEND_DIR, Settings, get_settings

TEST_DB_NAME = "pashusetu_test"
_base_url = Settings().database_url
_server_url = _base_url.rsplit("/", 1)[0]
os.environ["DATABASE_URL"] = f"{_server_url}/{TEST_DB_NAME}"
os.environ["UPLOAD_DIR"] = tempfile.mkdtemp(prefix="pashusetu-test-uploads-")
# Jobs run on their own timer; tests call clustering directly instead.
os.environ["SCHEDULER_ENABLED"] = "false"
get_settings.cache_clear()


def _create_test_database() -> None:
    admin = create_engine(f"{_server_url}/postgres", isolation_level="AUTOCOMMIT")
    with admin.connect() as conn:
        exists = conn.execute(text("SELECT 1 FROM pg_database WHERE datname = :n"), {"n": TEST_DB_NAME}).scalar()
        if not exists:
            conn.execute(text(f"CREATE DATABASE {TEST_DB_NAME}"))
    admin.dispose()
    test_engine = create_engine(os.environ["DATABASE_URL"], isolation_level="AUTOCOMMIT")
    with test_engine.connect() as conn:
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
    test_engine.dispose()


def _migrate() -> None:
    from alembic import command
    from alembic.config import Config

    config = Config(str(BACKEND_DIR / "alembic.ini"))
    config.set_main_option("script_location", str(BACKEND_DIR / "alembic"))
    command.upgrade(config, "head")


_create_test_database()
_migrate()

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.core.db import SessionLocal  # noqa: E402
from app.main import app  # noqa: E402
from scripts import seed  # noqa: E402

PHONES = {role: phone for role, phone, _, _ in seed.DEMO_USERS}


@pytest.fixture(scope="session", autouse=True)
def seeded_database():
    with SessionLocal() as db:
        seed.run(db, weather_online=False)  # tests never call Open-Meteo


@pytest.fixture
def db():
    with SessionLocal() as session:
        yield session


@pytest.fixture(scope="session")
def client():
    return TestClient(app)


def login(client: TestClient, phone: str) -> dict:
    response = client.post("/api/v1/auth/otp/verify", json={"phone": phone, "otp": "123456"})
    assert response.status_code == 200, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


@pytest.fixture(scope="session")
def as_role(client):
    """as_role("vet") -> auth headers for that demo account."""
    cache: dict[str, dict] = {}

    def headers(role: str) -> dict:
        if role not in cache:
            cache[role] = login(client, PHONES[role])
        return cache[role]

    return headers
