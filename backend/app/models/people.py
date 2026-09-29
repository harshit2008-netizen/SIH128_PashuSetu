"""Users, herds, animals and vaccinations."""

import uuid
from datetime import date

from sqlalchemy import Date, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Entity, point_column

ROLES = ("farmer", "pashu_sevak", "vet", "lab", "district_officer")
LANGUAGES = ("en", "hi", "mr")


class User(Entity):
    __tablename__ = "users"

    phone: Mapped[str] = mapped_column(String(15), unique=True)
    name: Mapped[str] = mapped_column(String(120))
    role: Mapped[str] = mapped_column(String(32), index=True)
    language: Mapped[str] = mapped_column(String(2), default="hi")
    # Area: farmers have a village, sevaks and vets a block, everyone a district.
    village_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("villages.id"))
    block_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("blocks.id"))
    district_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("districts.id"))


class Herd(Entity):
    __tablename__ = "herds"

    owner_user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), index=True)
    village_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("villages.id"), index=True)
    location = point_column()
    name: Mapped[str] = mapped_column(String(120))


class Animal(Entity):
    __tablename__ = "animals"

    # 12-digit ear tag (INAPH style); optional because many animals are untagged.
    ear_tag: Mapped[str | None] = mapped_column(String(12), unique=True, nullable=True)
    herd_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("herds.id"), index=True)
    species: Mapped[str] = mapped_column(String(16))
    breed: Mapped[str | None] = mapped_column(String(64))
    sex: Mapped[str | None] = mapped_column(String(8))
    age_months: Mapped[int | None] = mapped_column(Integer)
    name: Mapped[str | None] = mapped_column(String(64))


class Vaccination(Entity):
    __tablename__ = "vaccinations"

    animal_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("animals.id"), index=True)
    herd_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("herds.id"), index=True)
    vaccine: Mapped[str] = mapped_column(String(32))
    given_on: Mapped[date] = mapped_column(Date)
    next_due_on: Mapped[date | None] = mapped_column(Date)
    given_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
