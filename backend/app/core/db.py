"""Database engine and the per-request session dependency."""

from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import get_settings

# pool_pre_ping: the laptop DB may restart during a demo; stale connections
# are detected and replaced instead of failing the next request.
# connect_timeout: fail fast when the DB is down so /health answers quickly.
engine = create_engine(
    get_settings().database_url,
    pool_pre_ping=True,
    connect_args={"connect_timeout": 3},
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    """Parent class for all SQLAlchemy models (added in Phase 2)."""


def get_db() -> Iterator[Session]:
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
