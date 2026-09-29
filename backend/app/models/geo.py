"""District -> blocks (talukas) -> villages. Names are {en, hi, mr} JSON."""

import uuid

from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import SRID, Entity, point_column


class District(Entity):
    __tablename__ = "districts"

    code: Mapped[str] = mapped_column(String(64), unique=True)
    name: Mapped[dict] = mapped_column(JSONB)
    centroid = point_column()
    boundary = mapped_column(Geometry("MULTIPOLYGON", srid=SRID), nullable=True)


class Block(Entity):
    __tablename__ = "blocks"

    code: Mapped[str] = mapped_column(String(64), unique=True)
    name: Mapped[dict] = mapped_column(JSONB)
    district_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("districts.id"), index=True)
    centroid = point_column()
    boundary = mapped_column(Geometry("MULTIPOLYGON", srid=SRID), nullable=True)


class Village(Entity):
    __tablename__ = "villages"

    code: Mapped[str] = mapped_column(String(96), unique=True)
    name: Mapped[dict] = mapped_column(JSONB)
    block_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("blocks.id"), index=True)
    centroid = point_column()
    boundary = mapped_column(Geometry("MULTIPOLYGON", srid=SRID), nullable=True)
