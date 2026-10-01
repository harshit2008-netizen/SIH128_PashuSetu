"""Random Forest second opinion, server only (spec 7.9, 11.5, P2).

    final(d) = 0.8 * current(d) + 0.2 * rf_p(d)

`current` is the rules score, already fused with the photo for LSD. The
forest is trained on data generated from the rules (ml/src/symptom_rf.py),
so it mostly agrees with them; it smooths odd sign combinations. It runs
only when app/ml_models/symptom_rf.joblib and its metrics file exist, and
only on the server, so the phone's rules-only result stays reproducible.
"""

from functools import lru_cache
from pathlib import Path

import joblib

from app.core.shared_loader import SharedData
from app.services.triage.rule_engine import TriageInput, confidence_label, round3, score_rule

MODEL_DIR = Path(__file__).resolve().parents[2] / "ml_models"
MODEL_PATH = MODEL_DIR / "symptom_rf.joblib"
METRICS_PATH = MODEL_DIR / "symptom_rf_metrics.json"


@lru_cache(maxsize=1)
def load_model() -> dict | None:
    if not (MODEL_PATH.exists() and METRICS_PATH.exists()):
        return None
    return joblib.load(MODEL_PATH)


def rf_probabilities(bundle: dict, report: TriageInput) -> dict[str, float]:
    """Same features as training: signs, species one-hot, share dead, share sick."""
    herd = max(report.total_at_risk or report.sick_count + report.dead_count + 1, 1)
    row = ([1.0 if s in report.symptoms else 0.0 for s in bundle["symptoms"]]
           + [1.0 if report.species == sp else 0.0 for sp in bundle["species"]]
           + [min(report.dead_count / herd, 1.0), min(report.sick_count / herd, 1.0)])
    probabilities = bundle["model"].predict_proba([row])[0]
    return {disease: float(p) for disease, p in zip(bundle["model"].classes_, probabilities, strict=True)}


def apply_second_opinion(data: SharedData, report: TriageInput, candidates: list[dict],
                         bundle: dict) -> list[dict]:
    """Every disease for this species gets 0.8 * its current score + 0.2 * the forest's probability."""
    weight = data.triage_config["fusion"]["second_opinion_weight"]
    rf = rf_probabilities(bundle, report)
    current = {c["disease_id"]: c for c in candidates}
    fused = []
    for rule in data.rules_in_order:
        if report.species not in rule["species"]:
            continue
        candidate = dict(current.get(rule["id"]) or score_rule(rule, report, data.triage_config))
        p = rf.get(rule["id"], 0.0)
        score = round3((1 - weight) * candidate["score"] + weight * p)
        candidate.update(score=score, confidence=confidence_label(score, data.triage_config),
                         sources={**candidate["sources"], "rf": round3(p)})
        if score > 0:
            fused.append(candidate)
    return sorted(fused, key=lambda c: (-c["score"], c["disease_id"]))
