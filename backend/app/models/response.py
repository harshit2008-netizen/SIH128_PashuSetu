"""Alerts, lab samples, advisories, risk scores and weather.

The tables exist from the first migration; their endpoints arrive in later
phases (alerts: Phase 7, samples and advisories: Phase 8, risk: Phase 10).
"""

import uuid
from datetime import date, datetime

from geoalchemy2 import Geometry
from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import SRID, Entity, point_column


class Alert(Entity):
    __tablename__ = "alerts"

    type: Mapped[str] = mapped_column(String(16))  # cluster / spike / zoonotic / mortality
    syndrome: Mapped[str | None] = mapped_column(String(48))
    disease: Mapped[str | None] = mapped_column(String(32))
    severity: Mapped[str] = mapped_column(String(16))
    status: Mapped[str] = mapped_column(String(16), default="open", index=True)
    area = mapped_column(Geometry("POLYGON", srid=SRID), nullable=True)
    center = point_column()
    case_ids: Mapped[list[uuid.UUID]] = mapped_column(ARRAY(UUID(as_uuid=True)), default=list)
    explanation: Mapped[dict] = mapped_column(JSONB, default=dict)
    block_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("blocks.id"))
    district_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("districts.id"))
    acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    acknowledged_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    # One Health webhook (P2): set only after the human health system accepted the alert.
    one_health_notified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    one_health_attempts: Mapped[int] = mapped_column(Integer, default=0, server_default="0")


class LabSample(Entity):
    __tablename__ = "lab_samples"

    case_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("cases.id"), index=True)
    qr_code: Mapped[str] = mapped_column(String(16), unique=True)  # e.g. PS-S-7F3K2Q
    sample_type: Mapped[str] = mapped_column(String(32))
    status: Mapped[str] = mapped_column(String(16), default="requested")
    requested_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    collected_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    received_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    result: Mapped[str | None] = mapped_column(String(16))
    result_disease: Mapped[str | None] = mapped_column(String(32))
    result_note: Mapped[str | None] = mapped_column(Text)
    collected_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    received_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    resulted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Advisory(Entity):
    __tablename__ = "advisories"

    template_id: Mapped[str] = mapped_column(String(48))
    language: Mapped[str | None] = mapped_column(String(2))
    rendered_text: Mapped[dict] = mapped_column(JSONB)  # {en, hi, mr}
    target_center = point_column()
    radius_km: Mapped[float] = mapped_column(Float)
    disease: Mapped[str | None] = mapped_column(String(32))
    sent_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class AdvisoryRecipient(Entity):
    __tablename__ = "advisory_recipients"

    advisory_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("advisories.id"), index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), index=True)
    channel: Mapped[str] = mapped_column(String(8), default="inapp")
    delivered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class RiskScore(Entity):
    __tablename__ = "risk_scores"

    block_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("blocks.id"), index=True)
    disease: Mapped[str] = mapped_column(String(32))
    for_date: Mapped[date] = mapped_column(Date)
    score: Mapped[float] = mapped_column(Float)
    level: Mapped[str] = mapped_column(String(8))
    factors: Mapped[dict] = mapped_column(JSONB)


class WeatherCache(Entity):
    __tablename__ = "weather_cache"

    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    date: Mapped[date] = mapped_column(Date)
    temp_max: Mapped[float | None] = mapped_column(Float)
    temp_min: Mapped[float | None] = mapped_column(Float)
    humidity_mean: Mapped[float | None] = mapped_column(Float)
    precip_mm: Mapped[float | None] = mapped_column(Float)
    source: Mapped[str] = mapped_column(String(16))
    days_ahead: Mapped[int] = mapped_column(Integer, default=0)
