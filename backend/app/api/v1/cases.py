"""Case queue, case detail, status changes and vet assignment."""

import uuid
from typing import Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy import case as sql_case
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.errors import AppError, forbidden, not_found
from app.core.security import ALL_ROLES, RESPONDERS, require_roles
from app.models import Case, User
from app.services.access import can_view_case, visible_cases
from app.services.cases import CLOSED_STATUSES, MANUAL_TARGETS, assign_vet, change_status
from app.services.views import case_detail, case_summary

router = APIRouter(tags=["cases"])

# Emergency first, then urgent, then routine; oldest first within each.
SEVERITY_RANK = sql_case({"emergency": 0, "urgent": 1, "routine": 2}, value=Case.severity)


class TransitionIn(BaseModel):
    to_status: Literal["under_treatment", "resolved", "closed_ruled_out"] = Field(
        description="Other statuses are set by their own actions: assign a vet, or the lab sample steps")
    note: str | None = Field(None, max_length=1000)


class AssignIn(BaseModel):
    vet_id: uuid.UUID | None = Field(None, description="Leave empty for 'Assign to me' (vets only)")


def load_case(db: Session, user: User, case_id: uuid.UUID) -> Case:
    case = db.get(Case, case_id)
    if case is None or not can_view_case(db, user, case):
        raise not_found("Case")
    return case


@router.get("/cases")
def list_cases(status: str | None = None, severity: str | None = None, block_id: uuid.UUID | None = None,
               disease: str | None = None, include_closed: bool = False, limit: int = Query(100, le=500),
               user: User = Depends(require_roles(*RESPONDERS)), db: Session = Depends(get_db)):
    """Case queue: vets see their block, district officers the whole district.

    Open cases only, unless `status` is given or `include_closed=true`.
    """
    query = visible_cases(user)
    if status:
        query = query.where(Case.status == status)
    elif not include_closed:
        query = query.where(Case.status.not_in(CLOSED_STATUSES))
    if severity:
        query = query.where(Case.severity == severity)
    if block_id:
        query = query.where(Case.block_id == block_id)
    if disease:
        query = query.where(Case.suspected_disease == disease)
    cases = db.scalars(query.order_by(SEVERITY_RANK, Case.created_at).limit(limit)).all()
    return [case_summary(db, c) for c in cases]


@router.get("/cases/{case_id}")
def get_case(case_id: uuid.UUID, user: User = Depends(require_roles(*ALL_ROLES)), db: Session = Depends(get_db)):
    """One case with its reports, triage breakdown, timeline and lab samples."""
    return case_detail(db, load_case(db, user, case_id))


@router.post("/cases/{case_id}/transition")
def transition_case(case_id: uuid.UUID, body: TransitionIn, user: User = Depends(require_roles(*RESPONDERS)),
                    db: Session = Depends(get_db)):
    case = load_case(db, user, case_id)
    if body.to_status not in MANUAL_TARGETS:
        raise AppError(422, "use_other_action", "Use the matching action for this status.")
    change_status(db, case, body.to_status, user, body.note)
    db.commit()
    return case_detail(db, case)


@router.post("/cases/{case_id}/assign")
def assign_case(case_id: uuid.UUID, body: AssignIn, user: User = Depends(require_roles(*RESPONDERS)),
                db: Session = Depends(get_db)):
    case = load_case(db, user, case_id)
    if body.vet_id is None:
        if user.role != "vet":
            raise AppError(422, "vet_required", "Choose which vet to assign.")
        vet = user
    else:
        vet = db.get(User, body.vet_id)
        if vet is None:
            raise not_found("Vet")
        if user.role == "vet" and vet.id != user.id:
            raise forbidden("A vet can only assign a case to themselves.")
    assign_vet(db, case, vet, user)
    db.commit()
    return case_detail(db, case)
