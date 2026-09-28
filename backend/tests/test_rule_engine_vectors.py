"""Golden triage vectors (spec 7.8). The Dart engine runs the same file."""

import json

import pytest

from app.core.config import SHARED_DIR
from app.core.shared_loader import load_shared_data
from app.services.triage.rule_engine import TriageInput, evaluate, primary_syndrome, round3
from scripts.update_triage_goldens import golden_for, to_input

DATA = load_shared_data()
VECTORS = json.loads((SHARED_DIR / "triage_test_vectors.json").read_text(encoding="utf-8"))["vectors"]


def candidate_ids(result: dict) -> list[str]:
    return [c["disease_id"] for c in result["candidates"]]


def check_expectations(result: dict, expect: dict) -> None:
    ids = candidate_ids(result)
    if "top" in expect:
        assert ids and ids[0] == expect["top"], f"top was {ids[:1]}"
    if "top_confidence" in expect:
        assert result["candidates"][0]["confidence"] == expect["top_confidence"]
    for key in ("severity", "zoonotic_flag", "unknown_syndrome"):
        if key in expect:
            assert result[key] == expect[key], f"{key} was {result[key]}"
    for disease in expect.get("in_top3", []):
        assert disease in ids
    for disease in expect.get("not_in_candidates", []):
        assert disease not in ids
    for higher, lower in expect.get("ranked_above", []):
        assert ids.index(higher) < ids.index(lower)
    for disease in expect.get("gated", []):
        candidate = next(c for c in result["candidates"] if c["disease_id"] == disease)
        assert candidate["required_signs_met"] is False


@pytest.mark.parametrize("vector", VECTORS, ids=[f"v{v['id']}" for v in VECTORS])
def test_vector_meets_spec_expectations(vector):
    check_expectations(evaluate(DATA, to_input(vector["input"])), vector["expect"])


@pytest.mark.parametrize("vector", VECTORS, ids=[f"v{v['id']}" for v in VECTORS])
def test_vector_matches_golden_output(vector):
    assert golden_for(evaluate(DATA, to_input(vector["input"]))) == vector["golden"]


def test_every_result_says_suspected_not_diagnosed():
    # The engine returns candidates and confidence words only; no "diagnosis" field exists.
    result = evaluate(DATA, to_input(VECTORS[0]["input"]))
    assert "diagnosis" not in json.dumps(result).lower()


def test_round_half_up_matches_dart():
    assert round3(0.71875) == 0.719
    assert round3(0.0005) == 0.001


def test_general_signs_only_count_when_nothing_else():
    assert primary_syndrome(DATA, frozenset({"fever", "skin_nodules"})) == "dermatological"
    assert primary_syndrome(DATA, frozenset({"fever"})) == "general"
    assert primary_syndrome(DATA, frozenset()) == "general"


def test_unknown_species_is_rejected():
    with pytest.raises(ValueError):
        evaluate(DATA, TriageInput(species="camel", symptoms=frozenset({"fever"})))


def test_given_herd_size_changes_mortality_term():
    small = evaluate(DATA, TriageInput("cattle", frozenset({"sudden_death"}), 0, 1, 2, 5))
    large = evaluate(DATA, TriageInput("cattle", frozenset({"sudden_death"}), 0, 1, 50, 5))
    assert small["candidates"][0]["score"] > large["candidates"][0]["score"]
