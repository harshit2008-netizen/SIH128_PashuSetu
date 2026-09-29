"""Combine rule scores with the LSD photo model (spec 7.9).

The photo model runs on the phone (TFLite). The phone sends its LSD
probability inside `device_triage.image_p_lsd`; the server does not re-run
the image model, it re-runs the rules and applies the same fusion formula.
The Dart version arrives with the image model in Phase 6.
"""

from app.core.shared_loader import SharedData
from app.services.triage.rule_engine import (
    TriageInput,
    build_result,
    confidence_label,
    engine_version,
    round3,
    score_all_rules,
    score_rule,
    validate_input,
)

LSD = "lsd"
RULES_WEIGHT = 0.6
IMAGE_WEIGHT = 0.4
# "The photo looks like it has skin lumps" prompt, and "unclear photo" cut-off.
ASK_ABOUT_LUMPS_MIN_P = 0.80
CLEAR_PHOTO_MIN_P = 0.60


def image_applies(data: SharedData, report: TriageInput, image_p_lsd: float | None) -> bool:
    return image_p_lsd is not None and report.species in data.rules[LSD]["species"]


def fuse_lsd(data: SharedData, report: TriageInput, candidates: list[dict], image_p_lsd: float) -> list[dict]:
    """Replace the LSD candidate with 0.6 * rules + 0.4 * image, then re-rank."""
    lsd = score_rule(data.rules[LSD], report, data.triage_config)  # even if its rule score is 0
    fused = round3(RULES_WEIGHT * lsd["score"] + IMAGE_WEIGHT * image_p_lsd)
    lsd.update(score=fused, confidence=confidence_label(fused, data.triage_config),
               sources={"rules": lsd["score"], "image": round3(image_p_lsd)})
    others = [c for c in candidates if c["disease_id"] != LSD]
    ranked = [c for c in others + [lsd] if c["score"] > 0]
    return sorted(ranked, key=lambda c: (-c["score"], c["disease_id"]))


def evaluate_with_fusion(data: SharedData, report: TriageInput, image_p_lsd: float | None = None,
                         image_model: str = "lsd_v1") -> dict:
    validate_input(data, report)
    candidates = score_all_rules(data, report)
    version = engine_version(data)
    photo = None
    if image_applies(data, report, image_p_lsd):
        candidates = fuse_lsd(data, report, candidates, image_p_lsd)
        version = f"{version}+{image_model}"
        photo = {
            "p_lsd": round3(image_p_lsd),
            "unclear": max(image_p_lsd, 1 - image_p_lsd) < CLEAR_PHOTO_MIN_P,
            "ask_about_skin_nodules": image_p_lsd >= ASK_ABOUT_LUMPS_MIN_P
            and "skin_nodules" not in report.symptoms,
        }
    result = build_result(data, report, candidates, version)
    result["photo"] = photo
    return result
