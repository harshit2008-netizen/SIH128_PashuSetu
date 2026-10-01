"""SLA escalation (spec 8.6): cases nobody has responded to move up a level.

SLA to first response: emergency 2 h, urgent 12 h, routine 72 h; in demo mode
2, 5 and 15 minutes, so escalation can be shown live. Level 1 = the block vet
should act, level 2 = the district officer. The clock starts when the server
received the case: a report that waited offline for a day still gives the
block vet one SLA before it goes to the district.

`escalation_level` is a separate field, not a status (spec 7), and each step
is a case event with the note "escalation:<level>", which the app shows in
the timeline in the user's language.
"""

from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Case
from app.services.cases import CLOSED_STATUSES, record_event

MAX_LEVEL = 2
ESCALATION_NOTE = "escalation:{level}"


def sla(severity: str) -> timedelta:
    s = get_settings()
    minutes = {
        "emergency": s.demo_sla_emergency_min if s.demo_mode else s.sla_emergency_min,
        "urgent": s.demo_sla_urgent_min if s.demo_mode else s.sla_urgent_min,
    }.get(severity, s.demo_sla_routine_min if s.demo_mode else s.sla_routine_min)
    return timedelta(minutes=minutes)


def run_escalation(db: Session, now: datetime | None = None) -> list[Case]:
    """One step at a time: a case goes to level 1 after one SLA, level 2 after two."""
    now = now or datetime.now(UTC)
    waiting = db.scalars(select(Case).where(
        Case.acknowledged_at.is_(None), Case.status.not_in(CLOSED_STATUSES), Case.escalation_level < MAX_LEVEL))
    escalated = []
    for case in waiting:
        if now - case.created_at < sla(case.severity) * (case.escalation_level + 1):
            continue
        case.escalation_level += 1
        case.updated_at = now
        record_event(db, case, None, case.status, case.status, ESCALATION_NOTE.format(level=case.escalation_level), now)
        escalated.append(case)
    db.flush()
    return escalated
