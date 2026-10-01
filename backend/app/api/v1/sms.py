"""Reports by SMS (P2), for farmers without a smartphone.

An SMS gateway (any provider) forwards each incoming message here and sends
our `reply` back to the farmer. The text is read with the same lexicon parser
as voice input, then filed as a normal report (channel "sms"), so triage,
alerts and the officer's map treat it like any other report. Off unless
SMS_INBOUND_TOKEN is set; no SMS provider is bundled (spec: out of scope).
"""

import hmac
import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Header
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.db import get_db
from app.core.errors import AppError
from app.core.shared_loader import SharedData, get_shared_data
from app.models import Block, User, Village
from app.schemas.reports import ReportIn
from app.services.geo_utils import point_latlng
from app.services.reports import ingest_report
from app.services.triage.lexicon_parser import LexiconParser

router = APIRouter(tags=["sms"])
REPORTERS = ("farmer", "pashu_sevak")
SMS_NAMESPACE = uuid.UUID("5b0e7c1e-3f1a-4c55-9a43-2d7e1c9b6a10")


class SmsIn(BaseModel):
    sender: str = Field(alias="from", description="Sender's number, any format, e.g. +919000000001")
    text: str = Field(max_length=2000)
    message_id: str | None = Field(None, description="Gateway's id; a retry with the same id is not filed twice")


def reply(data: SharedData, key: str, language: str, **values) -> str:
    texts = data.sms["replies"][key]
    return (texts.get(language) or texts["en"]).format(**values)


def ten_digits(number: str) -> str:
    digits = "".join(ch for ch in number if ch.isdigit())
    return digits[-10:]


def home_location(db: Session, user: User) -> dict | None:
    if user.village_id:
        return point_latlng(db.get(Village, user.village_id).centroid)
    if user.block_id:
        return point_latlng(db.get(Block, user.block_id).centroid)
    return None


@router.post("/sms/inbound")
def inbound(body: SmsIn, x_gateway_token: str = Header(""), db: Session = Depends(get_db)):
    settings = get_settings()
    if not settings.sms_inbound_token:
        raise AppError(404, "sms_off", "Reporting by SMS is not switched on.")
    if not hmac.compare_digest(x_gateway_token, settings.sms_inbound_token):
        raise AppError(401, "bad_gateway_token", "Unknown SMS gateway.")
    data = get_shared_data()
    user = db.scalar(select(User).where(User.phone == ten_digits(body.sender), User.role.in_(REPORTERS)))
    if user is None:
        return {"status": "not_registered", "reply": reply(data, "not_registered", "hi")}
    language = user.language or "hi"
    heard = LexiconParser(data.lexicon, language).parse(body.text)
    if heard.species is None:
        return {"status": "need_animal", "reply": reply(data, "need_animal", language)}
    signs = [s for s in heard.symptoms if heard.species in data.symptoms[s]["species"]]
    if not signs and not heard.dead:
        return {"status": "need_signs", "reply": reply(data, "need_signs", language)}
    location = home_location(db, user)
    if location is None:
        return {"status": "not_registered", "reply": reply(data, "not_registered", language)}

    now = datetime.now(UTC)
    key = body.message_id or f"{body.sender}|{body.text}|{now.isoformat()}"
    sick = heard.sick if heard.sick is not None else (1 if signs else 0)
    dead = heard.dead or 0
    total = heard.total if heard.total is not None and heard.total >= sick + dead else None
    report = ReportIn(client_uuid=uuid.uuid5(SMS_NAMESPACE, key), location=location, species=heard.species,
                      symptoms=signs, sick_count=sick, dead_count=dead, total_at_risk=total,
                      voice_transcript=body.text, created_on_device_at=now, channel="sms")
    status, _, case = ingest_report(db, data, user, report)
    db.commit()

    top = case.suspected_disease
    helpline = settings.helpline_number
    if top is None:
        text = reply(data, "received_unclear", language, helpline=helpline)
    else:
        rule = data.rules[top]
        action = data.actions[rule["actions"][0]]["text"]
        text = reply(data, "received", language, disease=rule["name"].get(language) or rule["name"]["en"],
                     severity=data.sms["severity"][case.severity].get(language, case.severity),
                     action=action.get(language) or action["en"], helpline=helpline)
    return {"status": status, "case_id": case.id, "reply": text}
