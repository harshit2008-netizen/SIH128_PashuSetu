"""Block risk estimate per disease for the officer's map (spec 8.8)."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.errors import AppError
from app.core.security import require_roles
from app.core.shared_loader import get_shared_data
from app.models import User
from app.services.risk.risk_score import district_risk

router = APIRouter(tags=["risk"])


@router.get("/risk")
def risk(disease: str = Query("lsd", description="Disease id, e.g. lsd, hs, fmd"),
         user: User = Depends(require_roles("district_officer")), db: Session = Depends(get_db)):
    """Every block in the officer's district, highest risk first, each with its factor breakdown."""
    data = get_shared_data()
    if disease not in data.rules:
        raise AppError(422, "unknown_disease", f"Unknown disease: {disease}")
    blocks = district_risk(db, data, user.district_id, disease)
    db.commit()
    return {"label": data.risk_config["label"], "disease": disease, "weights": data.risk_config["weights"],
            "blocks": blocks}
