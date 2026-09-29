"""Reports from the field, their triage results, and the cases they open."""

import uuid
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Entity, point_column

CASE_STATUSES = (
    "reported", "triaged", "vet_assigned", "sample_requested", "sample_collected",
    "lab_received", "lab_result", "under_treatment", "resolved", "closed_ruled_out",
)
SEVERITIES = ("routine", "urgent", "emergency")


class Report(Entity):
    __tablename__ = "reports"

    # Made on the phone; the server upserts by it so retries never duplicate.
    client_uuid: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), unique=True)
    reporter_user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), index=True)
    herd_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("herds.id"))
    animal_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("animals.id"))
    village_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("villages.id"), index=True)
    location = point_column()
    species: Mapped[str] = mapped_column(String(16))
    symptoms: Mapped[list[str]] = mapped_column(ARRAY(String(64)))
    sick_count: Mapped[int] = mapped_column(Integer, default=0)
    dead_count: Mapped[int] = mapped_column(Integer, default=0)
    total_at_risk: Mapped[int | None] = mapped_column(Integer)
    onset_date: Mapped[date | None] = mapped_column(Date)
    voice_transcript: Mapped[str | None] = mapped_column(Text)
    photo_path: Mapped[str | None] = mapped_column(String(255))
    device_triage: Mapped[dict | None] = mapped_column(JSONB)
    created_on_device_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    channel: Mapped[str] = mapped_column(String(8), default="app")


class TriageResult(Entity):
    __tablename__ = "triage_results"

    report_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("reports.id"), index=True)
    engine_version: Mapped[str] = mapped_column(String(32))
    candidates: Mapped[list] = mapped_column(JSONB)
    primary_syndrome: Mapped[str] = mapped_column(String(48), index=True)
    severity: Mapped[str] = mapped_column(String(16))
    zoonotic_flag: Mapped[bool] = mapped_column(Boolean, default=False)
    unknown_syndrome: Mapped[bool] = mapped_column(Boolean, default=False)
    sources: Mapped[dict] = mapped_column(JSONB)
    # True when the phone's top disease differs from the server's (debug aid for vets).
    triage_mismatch: Mapped[bool] = mapped_column(Boolean, default=False)
    result: Mapped[dict] = mapped_column(JSONB)


class Case(Entity):
    __tablename__ = "cases"

    report_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("reports.id"))
    status: Mapped[str] = mapped_column(String(24), index=True)
    severity: Mapped[str] = mapped_column(String(16), index=True)
    suspected_disease: Mapped[str | None] = mapped_column(String(32), index=True)
    confirmed_disease: Mapped[str | None] = mapped_column(String(32))
    assigned_vet_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    escalation_level: Mapped[int] = mapped_column(Integer, default=0)
    acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    block_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("blocks.id"), index=True)
    herd_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("herds.id"))
    location = point_column()


class CaseReport(Entity):
    """Links follow-up reports to an existing case (the first report is cases.report_id)."""

    __tablename__ = "case_reports"

    case_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("cases.id"), index=True)
    report_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("reports.id"), unique=True)


class CaseEvent(Entity):
    __tablename__ = "case_events"

    case_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("cases.id"), index=True)
    actor_user_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    from_status: Mapped[str | None] = mapped_column(String(24))
    to_status: Mapped[str] = mapped_column(String(24))
    note: Mapped[str | None] = mapped_column(Text)
