"""Engine and model information for the "About the AI" screen."""

import json

from fastapi import APIRouter

from app.core.config import REPO_ROOT
from app.core.shared_loader import get_shared_data
from app.services.triage.rule_engine import engine_version

router = APIRouter(tags=["meta"])

# Written by the real training run in Phase 6; until then there is no model to describe.
MODEL_CARD_PATH = REPO_ROOT / "mobile" / "assets" / "models" / "lsd_model_card.json"


@router.get("/meta/engine")
def engine():
    data = get_shared_data()
    model_card = json.loads(MODEL_CARD_PATH.read_text(encoding="utf-8")) if MODEL_CARD_PATH.exists() else None
    return {
        "engine_version": engine_version(data),
        "rules": [{"id": r["id"], "version": r["version"], "name": r["name"], "species": r["species"],
                   "notifiable": r["notifiable"], "zoonotic": r["zoonotic"], "source_note": r["source_note"]}
                  for r in data.rules_in_order],
        "image_model": model_card,
        "note": "Results are suspected diseases, not a diagnosis. A vet or lab must confirm.",
    }
