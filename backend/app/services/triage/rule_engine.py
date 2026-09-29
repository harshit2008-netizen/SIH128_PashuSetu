"""Rule-based triage (spec Sections 7.6-7.7).

This file must stay step-for-step identical to the Dart engine in
mobile/lib/features/triage/engine/rule_engine.dart: same order of
arithmetic, same rounding, same tie-breaks. Both run the golden vectors in
shared/triage_test_vectors.json, so any drift fails a test.

The result is a *suspected* disease list, never a diagnosis.
"""

import math
from dataclasses import dataclass, field

from app.core.shared_loader import SharedData

SEVERITY_ORDER = ["routine", "urgent", "emergency"]


@dataclass(frozen=True)
class TriageInput:
    species: str
    symptoms: frozenset[str] = field(default_factory=frozenset)
    sick_count: int = 0
    dead_count: int = 0
    total_at_risk: int | None = None
    report_month: int = 1

    @property
    def herd_size(self) -> int:
        # Spec default when the reporter did not give a herd size.
        if self.total_at_risk is None:
            return self.sick_count + self.dead_count + 1
        return self.total_at_risk


def round3(value: float) -> float:
    # Round half up; Python's round() uses banker's rounding, which Dart does not.
    return math.floor(value * 1000 + 0.5) / 1000


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def higher_severity(a: str, b: str) -> str:
    return a if SEVERITY_ORDER.index(a) >= SEVERITY_ORDER.index(b) else b


def sort_signs(sign_ids: list[str], weights: dict[str, int]) -> list[str]:
    # Heaviest sign first; ties by id so both engines give the same order.
    return sorted(sign_ids, key=lambda s: (-weights[s], s))


def confidence_label(score: float, config: dict) -> str:
    if score >= config["confidence"]["high"]:
        return "high"
    if score >= config["confidence"]["moderate"]:
        return "moderate"
    return "low"


def score_rule(rule: dict, report: TriageInput, config: dict) -> dict:
    signs = rule["signs"]
    present = report.symptoms
    total_weight = sum(signs.values())
    present_weight = sum(weight for sign, weight in signs.items() if sign in present)
    score = present_weight / total_weight

    required_met = all(any(sign in present for sign in group) for group in rule["required"])
    if not required_met:
        score = score * rule["gate_fail_multiplier"]
    if report.report_month in rule["season"]["high_risk_months"]:
        score = score * rule["season"]["boost"]
    death_rate = min(report.dead_count / max(report.herd_size, 1), 1)
    score = score + death_rate * rule["mortality_weight"]
    score = round3(clamp01(score))

    return {
        "disease_id": rule["id"],
        "score": score,
        "confidence": confidence_label(score, config),
        "matched_signs": sort_signs([s for s in signs if s in present], signs),
        "missing_key_signs": sort_signs([s for s in signs if signs[s] >= 4 and s not in present], signs),
        "required_signs_met": required_met,
        "sources": {"rules": score},
    }


def score_all_rules(data: SharedData, report: TriageInput) -> list[dict]:
    """Every rule for this species with a score above zero, best first."""
    candidates = [
        score_rule(rule, report, data.triage_config)
        for rule in data.rules_in_order
        if report.species in rule["species"]
    ]
    candidates = [c for c in candidates if c["score"] > 0]
    return sorted(candidates, key=lambda c: (-c["score"], c["disease_id"]))


def primary_syndrome(data: SharedData, symptoms: frozenset[str]) -> str:
    totals = {}
    for syndrome in data.syndromes:
        weight = sum(w for symptom, w in syndrome["symptoms"].items() if symptom in symptoms)
        if weight > 0:
            totals[syndrome["id"]] = weight
    # 'general' (fever, not eating) only counts when nothing more specific is present.
    specific = {k: v for k, v in totals.items() if k != "general"}
    pool = specific or totals
    if not pool:
        return "general"
    return min(pool, key=lambda k: (-pool[k], k))


def is_unknown_syndrome(top_score: float, report: TriageInput, config: dict) -> bool:
    rule = config["unknown_syndrome"]
    looks_serious = report.sick_count >= rule["min_sick"] or report.dead_count >= rule["min_dead"]
    return top_score < rule["max_top_score"] and looks_serious


def severity_level(data: SharedData, report: TriageInput, top: dict | None, unknown: bool) -> str:
    cfg = data.triage_config["severity"]
    is_bird = data.species[report.species]["group"] == "bird"
    top_rule = data.rules[top["disease_id"]] if top else None
    top_score = top["score"] if top else 0.0

    many_dead = (report.dead_count >= cfg["emergency_min_dead_poultry"] if is_bird
                 else report.dead_count >= cfg["emergency_min_dead_mammal"])
    if (top_rule and top_rule["severity_floor"] == "emergency"
            and top_score >= cfg["emergency_floor_min_score"]) or many_dead:
        level = "emergency"
    elif ((top_rule and top_rule["notifiable"] and top_score >= cfg["urgent_notifiable_min_score"])
          or report.sick_count >= cfg["urgent_min_sick"] or report.dead_count >= cfg["urgent_min_dead"]):
        level = "urgent"
    else:
        level = "routine"

    if top_rule and top_score >= cfg["rule_floor_min_score"]:
        level = higher_severity(level, top_rule["severity_floor"])
    if unknown:
        level = higher_severity(level, "urgent")
    return level


def pick_actions(data: SharedData, top: dict | None, unknown: bool) -> list[str]:
    config = data.triage_config["actions"]
    if unknown:
        return list(config["unknown_syndrome"])
    if top and top["score"] >= config["disease_actions_min_score"]:
        return list(data.rules[top["disease_id"]]["actions"])
    return list(config["low_confidence"])


def pick_safety_note(data: SharedData, candidates: list[dict]) -> dict | None:
    min_score = data.triage_config["actions"]["safety_note_min_score"]
    for candidate in candidates:
        note = data.rules[candidate["disease_id"]]["safety_note"]
        if note and candidate["score"] >= min_score:
            return note
    return None


def engine_version(data: SharedData) -> str:
    return f"rules-{max(rule['version'] for rule in data.rules.values())}"


def validate_input(data: SharedData, report: TriageInput) -> None:
    if report.species not in data.species:
        raise ValueError(f"Unknown species: {report.species}")
    if not 1 <= report.report_month <= 12:
        raise ValueError(f"report_month must be 1-12, got {report.report_month}")
    if report.sick_count < 0 or report.dead_count < 0:
        raise ValueError("sick_count and dead_count must not be negative")


def evaluate(data: SharedData, report: TriageInput) -> dict:
    """Run triage for one report and return the shared response shape."""
    validate_input(data, report)
    return build_result(data, report, score_all_rules(data, report), engine_version(data))


def build_result(data: SharedData, report: TriageInput, all_candidates: list[dict], version: str) -> dict:
    """Severity, flags and actions from already-scored candidates (best first).

    Split out so fusion (rules + photo) can re-rank candidates and reuse it.
    """
    config = data.triage_config
    top = all_candidates[0] if all_candidates else None
    unknown = is_unknown_syndrome(top["score"] if top else 0.0, report, config)
    zoonotic = any(data.rules[c["disease_id"]]["zoonotic"] and c["score"] >= config["zoonotic_min_score"]
                   for c in all_candidates)
    return {
        "engine_version": version,
        "candidates": all_candidates[: config["max_candidates"]],
        "primary_syndrome": primary_syndrome(data, report.symptoms),
        "severity": severity_level(data, report, top, unknown),
        "zoonotic_flag": zoonotic,
        "unknown_syndrome": unknown,
        "actions": pick_actions(data, top, unknown),
        "safety_note": pick_safety_note(data, all_candidates),
    }
