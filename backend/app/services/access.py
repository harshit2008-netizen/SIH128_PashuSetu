"""Who can see which cases.

- farmer / pashu sevak: cases opened or followed up by their own reports
- vet: cases in their block
- district officer and lab: cases in their district
"""

from sqlalchemy import Select, or_, select
from sqlalchemy.orm import Session

from app.models import Block, Case, CaseReport, Report, User


def visible_cases(user: User) -> Select:
    query = select(Case)
    if user.role in ("farmer", "pashu_sevak"):
        own_reports = select(Report.id).where(Report.reporter_user_id == user.id)
        followed_up = select(CaseReport.case_id).where(CaseReport.report_id.in_(own_reports))
        return query.where(or_(Case.report_id.in_(own_reports), Case.id.in_(followed_up)))
    if user.role == "vet":
        return query.where(Case.block_id == user.block_id)
    district_blocks = select(Block.id).where(Block.district_id == user.district_id)
    return query.where(Case.block_id.in_(district_blocks))


def can_view_case(db: Session, user: User, case: Case) -> bool:
    return db.scalar(visible_cases(user).where(Case.id == case.id)) is not None
