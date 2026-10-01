"""Engine and model information for the "About the AI" screen."""

import json

from fastapi import APIRouter

from app.core.config import REPO_ROOT
from app.core.shared_loader import get_shared_data
from app.services.triage.rule_engine import engine_version
from app.services.triage.second_opinion import METRICS_PATH

router = APIRouter(tags=["meta"])

# Written by the Kaggle training run (ml/README.md) and bundled in the app.
MODEL_CARD_PATH = REPO_ROOT / "mobile" / "assets" / "models" / "lsd_model_card.json"


@router.get("/meta/engine")
def engine():
    data = get_shared_data()
    model_card = json.loads(MODEL_CARD_PATH.read_text(encoding="utf-8")) if MODEL_CARD_PATH.exists() else None
    version = engine_version(data)
    return {
        # Same string the phone shows: "rules-1+lsd_v1" when the photo model is bundled (spec 10.6).
        "engine_version": f"{version}+{model_card['model_version']}" if model_card else version,
        "rules": [{"id": r["id"], "version": r["version"], "name": r["name"], "species": r["species"],
                   "notifiable": r["notifiable"], "zoonotic": r["zoonotic"], "source_note": r["source_note"]}
                  for r in data.rules_in_order],
        "image_model": model_card,
        # Server-only RF second opinion (P2); trained on rule-generated data, see its limitations.
        "second_opinion": json.loads(METRICS_PATH.read_text(encoding="utf-8")) if METRICS_PATH.exists() else None,
        "note": "Results are suspected diseases, not a diagnosis. A vet or lab must confirm.",
    }
