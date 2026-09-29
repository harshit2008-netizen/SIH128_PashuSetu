"""Shared columns for every table: UUID id, created_at, updated_at."""

import uuid
from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.db import Base

# All geometry uses SRID 4326 (plain lat/lng), as the spec requires.
SRID = 4326


def point_column(nullable: bool = False):
    return mapped_column(Geometry("POINT", srid=SRID, spatial_index=True), nullable=nullable)


class Entity(Base):
    __abstract__ = True

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
