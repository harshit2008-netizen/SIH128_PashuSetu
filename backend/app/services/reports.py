"""Turning a report from the phone into a stored, triaged case.

Rules from the spec (8.3):
- Upsert by client_uuid: a retry returns the stored report as "duplicate".
- The server re-runs triage with the same rule files and is authoritative;
  if its top disease differs from the phone's, triage_mismatch is set.
"""

import uuid
from datetime import datetime
from zoneinfo import ZoneInfo

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.errors import AppError
from app.core.shared_loader import SharedData
from app.models import Block, Case, Herd, Report, TriageResult, User, Village
from app.schemas.reports import ReportIn
from app.services.cases import case_for_report, latest_triage, open_case_for_report, utcnow
from app.services.geo_utils import make_point, point_latlng
from app.services.surveillance.aberration import ist_day, run_spikes
from app.services.surveillance.alerting import on_new_report
from app.services.triage.fusion import evaluate_with_fusion
from app.services.triage.rule_engine import TriageInput

# Season boosts use the month in India, not UTC.
IST = ZoneInfo("Asia/Kolkata")


def nearest_village(db: Session, lat: float, lng: float) -> Village:
    village = db.scalar(select(Village).order_by(Village.centroid.ST_Distance(make_point(lat, lng))).limit(1))
    if village is None:
        raise AppError(503, "no_geography", "No villages are loaded yet. Run `make seed` on the laptop.")
    return village


def resolve_village(db: Session, payload: ReportIn) -> Village:
    if payload.village_id is None:
        return nearest_village(db, payload.location.lat, payload.location.lng)
    village = db.get(Village, payload.village_id)
    if village is None:
        raise AppError(422, "unknown_village", "That village is not in the list. Pick it again.")
    return village


def check_symptoms(data: SharedData, symptoms: list[str]) -> None:
    unknown = [s for s in symptoms if s not in data.symptoms]
    if unknown:
        raise AppError(422, "unknown_symptom", f"Unknown sign id: {', '.join(unknown)}. Update the app.")


def triage_input_for(report: Report) -> TriageInput:
    return TriageInput(
        species=report.species,
        symptoms=frozenset(report.symptoms),
        sick_count=report.sick_count,
        dead_count=report.dead_count,
        total_at_risk=report.total_at_risk,
        report_month=report.created_on_device_at.astimezone(IST).month,
    )


def run_server_triage(data: SharedData, report: Report) -> dict:
    device = report.device_triage or {}
    return evaluate_with_fusion(data, triage_input_for(report), device.get("image_p_lsd"),
                                device.get("image_model"))


def is_mismatch(device_triage: dict | None, server: dict) -> bool:
    device_top = (device_triage or {}).get("top")
    server_top = server["candidates"][0]["disease_id"] if server["candidates"] else None
    return device_triage is not None and device_top != server_top


def find_by_client_uuid(db: Session, client_uuid: uuid.UUID) -> Report | None:
    return db.scalar(select(Report).where(Report.client_uuid == client_uuid))


def build_report(payload: ReportIn, reporter: User, village: Village, received_at: datetime) -> Report:
    return Report(
        client_uuid=payload.client_uuid, reporter_user_id=reporter.id, herd_id=payload.herd_id,
        animal_id=payload.animal_id, village_id=village.id,
        location=make_point(payload.location.lat, payload.location.lng), species=payload.species,
        symptoms=list(dict.fromkeys(payload.symptoms)), sick_count=payload.sick_count,
        dead_count=payload.dead_count, total_at_risk=payload.total_at_risk, onset_date=payload.onset_date,
        voice_transcript=payload.voice_transcript, device_triage=payload.device_triage,
        created_on_device_at=payload.created_on_device_at, received_at=received_at, channel=payload.channel,
        created_at=received_at, updated_at=received_at,
    )


def ingest_report(db: Session, data: SharedData, reporter: User, payload: ReportIn,
                  received_at: datetime | None = None) -> tuple[str, Report, Case]:
    """Store one report (or return the existing one). Returns (status, report, case)."""
    existing = find_by_client_uuid(db, payload.client_uuid)
    if existing is not None:
        return "duplicate", existing, case_for_report(db, existing.id)

    received_at = received_at or utcnow()
    check_symptoms(data, payload.symptoms)
    if payload.herd_id is not None and db.get(Herd, payload.herd_id) is None:
        raise AppError(422, "unknown_herd", "That herd is not registered.")
    village = resolve_village(db, payload)
    report = build_report(payload, reporter, village, received_at)
    try:
        with db.begin_nested():  # a parallel retry with the same client_uuid lands here
            db.add(report)
            db.flush()
    except IntegrityError:
        existing = find_by_client_uuid(db, payload.client_uuid)
        return "duplicate", existing, case_for_report(db, existing.id)

    triage = run_server_triage(data, report)
    db.add(TriageResult(
        report_id=report.id, engine_version=triage["engine_version"], candidates=triage["candidates"],
        primary_syndrome=triage["primary_syndrome"], severity=triage["severity"],
        zoonotic_flag=triage["zoonotic_flag"], unknown_syndrome=triage["unknown_syndrome"],
        sources={c["disease_id"]: c["sources"] for c in triage["candidates"]},
        triage_mismatch=is_mismatch(payload.device_triage, triage), result=triage,
        created_at=received_at, updated_at=received_at,
    ))
    min_score = data.triage_config["actions"]["disease_actions_min_score"]
    case = open_case_for_report(db, report, triage, village.block_id, reporter, min_score, received_at)
    db.flush()
    on_new_report(db, data, report, triage, case)
    if triage["primary_syndrome"] != "general":
        # After clustering, so a spike is skipped where a cluster alert already covers it.
        run_spikes(db, data, ist_day(report.created_on_device_at), [triage["primary_syndrome"]])
    return "created", report, case


# ---------- serialisers shared by the routers ----------

def report_out(report: Report) -> dict:
    return {
        "id": report.id, "client_uuid": report.client_uuid, "village_id": report.village_id,
        "location": point_latlng(report.location), "species": report.species, "symptoms": report.symptoms,
        "sick_count": report.sick_count, "dead_count": report.dead_count,
        "total_at_risk": report.total_at_risk, "onset_date": report.onset_date,
        "voice_transcript": report.voice_transcript, "has_photo": report.photo_path is not None,
        "created_on_device_at": report.created_on_device_at, "received_at": report.received_at,
        "channel": report.channel,
    }


def triage_out(db: Session, report_id) -> dict:
    row = latest_triage(db, report_id)
    if row is None:
        return {}
    return {**row.result, "triage_mismatch": row.triage_mismatch}


def report_result(db: Session, status: str, report: Report, case: Case) -> dict:
    return {"status": status, "report": report_out(report), "triage": triage_out(db, report.id),
            "case_id": case.id}


def village_block_district(db: Session, village_id) -> tuple[Village, Block]:
    village = db.get(Village, village_id)
    return village, db.get(Block, village.block_id)


def count_reports(db: Session) -> int:
    return db.scalar(select(func.count(Report.id)))
