"""RF second opinion on the server (spec 11.5): 0.8 * current + 0.2 * forest, only when the model exists."""

from unittest.mock import patch

from app.core.shared_loader import get_shared_data
from app.services.triage.fusion import evaluate_with_fusion
from app.services.triage.rule_engine import TriageInput
from app.services.triage.second_opinion import load_model, rf_probabilities
from tests.helpers import report_payload

DATA = get_shared_data()
LSD_COW = TriageInput(species="cattle", symptoms=frozenset({"skin_nodules", "fever", "enlarged_lymph_nodes"}),
                      sick_count=1, report_month=8)


def test_model_is_present_and_reports_its_limits(client):
    assert load_model() is not None
    meta = client.get("/api/v1/meta/engine").json()
    assert meta["second_opinion"]["model_version"] == "rf_v1"
    assert any("re-learns" in line for line in meta["second_opinion"]["limitations"])


def test_server_score_is_80_percent_rules_and_20_percent_forest():
    rules_only = evaluate_with_fusion(DATA, LSD_COW)
    server = evaluate_with_fusion(DATA, LSD_COW, second_opinion=True)
    p_lsd = rf_probabilities(load_model(), LSD_COW)["lsd"]
    lsd = next(c for c in server["candidates"] if c["disease_id"] == "lsd")
    rules_lsd = rules_only["candidates"][0]["score"]
    assert abs(lsd["score"] - (0.8 * rules_lsd + 0.2 * p_lsd)) <= 0.001
    assert lsd["sources"]["rules"] == rules_lsd and "rf" in lsd["sources"]
    assert server["engine_version"] == "rules-1+rf_v1"
    assert server["candidates"][0]["disease_id"] == "lsd"


def test_photo_then_forest_both_show_in_the_sources():
    server = evaluate_with_fusion(DATA, LSD_COW, image_p_lsd=0.9, second_opinion=True)
    assert server["engine_version"] == "rules-1+lsd_v1+rf_v1"
    assert set(server["candidates"][0]["sources"]) == {"rules", "image", "rf"}


def test_without_the_model_file_the_server_uses_rules_and_photo_only():
    with patch("app.services.triage.fusion.load_model", return_value=None):
        result = evaluate_with_fusion(DATA, LSD_COW, second_opinion=True)
    assert result == evaluate_with_fusion(DATA, LSD_COW)


def test_reports_get_the_second_opinion(client, as_role):
    body = client.post("/api/v1/reports", json=report_payload(), headers=as_role("pashu_sevak")).json()
    assert body["triage"]["engine_version"].endswith("+rf_v1")
    assert body["triage"]["candidates"][0]["disease_id"] == "lsd"
