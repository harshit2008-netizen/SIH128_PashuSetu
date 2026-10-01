"""Random Forest "second opinion" on symptoms (spec 11.5, P2).

Run with the BACKEND's environment, so the saved model loads with the same
scikit-learn version the API uses:
    cd backend && uv run python ../ml/src/symptom_rf.py

Honest note: there is no public, licensed, labelled dataset of Indian livestock
symptom reports, so the training data is generated from our own rule files
(key signs present ~85% of the time, supporting signs ~50%, unrelated signs
~5%, realistic counts). The forest therefore mostly re-learns the rules. Its
value is smoothing odd sign combinations the weighted rules score poorly;
the server gives it only 20% of the final score. No Kaggle tabular data is
mixed in: the datasets we looked at use different, unmapped symptom names.

Writes backend/app/ml_models/symptom_rf.joblib and symptom_rf_metrics.json.
"""

import json
import random
from datetime import UTC, datetime
from pathlib import Path

import joblib
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, f1_score
from sklearn.model_selection import StratifiedKFold, cross_val_predict

REPO = Path(__file__).resolve().parents[2]
SHARED = REPO / "shared"
OUT = REPO / "backend" / "app" / "ml_models"
SEED = 42
CASES_PER_DISEASE = 1000
KEY_SIGN_WEIGHT = 4  # rule weight from which a sign counts as "key" (same as missing_key_signs)
P_KEY, P_SUPPORT, P_NOISE = 0.85, 0.5, 0.05
MODEL_VERSION = "rf_v1"


def load_shared() -> tuple[list[str], list[str], dict, dict]:
    def read(path):
        return json.loads((SHARED / path).read_text(encoding="utf-8"))

    symptoms_file = read("symptoms.json")
    symptoms = sorted(s["id"] for s in symptoms_file["symptoms"])
    species = sorted(s["id"] for s in symptoms_file["species"])
    signs_by_species = {sp: [s["id"] for s in symptoms_file["symptoms"] if sp in s["species"]] for sp in species}
    rules = {rid: read(f"disease_rules/{rid}.json") for rid in read("triage_config.json")["rule_ids"]}
    return symptoms, species, signs_by_species, rules


def features(symptoms: list[str], species: list[str], present: set[str], animal: str, sick: int, dead: int,
             total: int) -> list[float]:
    """Signs (0/1), species (one-hot), share of the herd dead, share sick. Same order as the server builds."""
    herd = max(total, 1)
    return ([1.0 if s in present else 0.0 for s in symptoms] + [1.0 if animal == sp else 0.0 for sp in species]
            + [min(dead / herd, 1.0), min(sick / herd, 1.0)])


def synth_case(rule: dict, signs_by_species: dict, rng: random.Random) -> tuple[str, set[str], int, int, int]:
    animal = rng.choice(rule["species"])
    weights = rule["signs"]
    present = {s for s, w in weights.items() if rng.random() < (P_KEY if w >= KEY_SIGN_WEIGHT else P_SUPPORT)}
    present |= {s for s in signs_by_species[animal] if s not in weights and rng.random() < P_NOISE}
    present &= set(signs_by_species[animal])
    if not present:  # a report always has at least one sign
        present = {max(weights, key=weights.get)}
    bird = animal == "poultry"
    total = rng.randint(50, 500) if bird else rng.randint(2, 20)
    sick = rng.randint(1, max(1, total // (5 if bird else 3)))
    # Diseases that kill (anthrax, bird flu, HS) usually come with deaths.
    dead = rng.randint(1, max(1, sick)) if rule["mortality_weight"] > 0 and rng.random() < 0.8 else 0
    return animal, present, sick, dead, total


def main() -> None:
    rng = random.Random(SEED)
    symptoms, species, signs_by_species, rules = load_shared()
    X, y = [], []
    for rid in sorted(rules):
        for _ in range(CASES_PER_DISEASE):
            animal, present, sick, dead, total = synth_case(rules[rid], signs_by_species, rng)
            X.append(features(symptoms, species, present, animal, sick, dead, total))
            y.append(rid)
    X, y = np.array(X), np.array(y)

    # min_samples_leaf=3 drops leaves that memorise single synthetic cases; it also keeps the file small.
    model = RandomForestClassifier(n_estimators=300, class_weight="balanced", min_samples_leaf=3,
                                   random_state=SEED, n_jobs=-1)
    folds = StratifiedKFold(n_splits=5, shuffle=True, random_state=SEED)
    predicted = cross_val_predict(model, X, y, cv=folds)
    model.fit(X, y)

    OUT.mkdir(parents=True, exist_ok=True)
    joblib.dump({"model": model, "symptoms": symptoms, "species": species, "version": MODEL_VERSION},
                OUT / "symptom_rf.joblib", compress=3)
    metrics = {
        "model_version": MODEL_VERSION,
        "created_at": datetime.now(UTC).isoformat(timespec="seconds"),
        "training_data": "synthetic, generated from shared/disease_rules (see ml/src/symptom_rf.py)",
        "cases": int(len(y)), "classes": sorted(rules),
        "cv_5fold": {"accuracy": round(float(accuracy_score(y, predicted)), 4),
                     "macro_f1": round(float(f1_score(y, predicted, average="macro")), 4),
                     "per_class": classification_report(y, predicted, output_dict=True, zero_division=0)},
        "limitations": [
            "Trained on data generated from our own rules, so it largely re-learns them.",
            "Cross-validation scores say how well it learned the synthetic data, not how well it diagnoses real animals.",
            "Used only on the server, with 20% weight, as a second opinion.",
        ],
    }
    (OUT / "symptom_rf_metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    print(f"rf_v1: {len(y)} synthetic cases, 5-fold accuracy {metrics['cv_5fold']['accuracy']}, "
          f"macro F1 {metrics['cv_5fold']['macro_f1']}")


if __name__ == "__main__":
    main()
