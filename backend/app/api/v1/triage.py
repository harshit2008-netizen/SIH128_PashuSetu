"""Stateless triage: the same engine the reports use, without saving anything."""

from fastapi import APIRouter, Depends

from app.core.errors import AppError
from app.core.security import get_current_user
from app.core.shared_loader import get_shared_data
from app.models import User
from app.schemas.reports import TriageIn
from app.services.triage.fusion import evaluate_with_fusion
from app.services.triage.rule_engine import TriageInput

router = APIRouter(tags=["triage"])


@router.post("/triage/evaluate")
def evaluate(body: TriageIn, _: User = Depends(get_current_user)):
    """Suspected diseases for a set of signs. This is not a diagnosis; a vet or lab must confirm."""
    data = get_shared_data()
    unknown = [s for s in body.symptoms if s not in data.symptoms]
    if unknown:
        raise AppError(422, "unknown_symptom", f"Unknown sign id: {', '.join(unknown)}.")
    report = TriageInput(species=body.species, symptoms=frozenset(body.symptoms), sick_count=body.sick_count,
                         dead_count=body.dead_count, total_at_risk=body.total_at_risk,
                         report_month=body.report_month)
    return evaluate_with_fusion(data, report, body.image_p_lsd)
