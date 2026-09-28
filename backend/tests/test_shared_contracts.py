"""Checks that the shared/ JSON contracts are valid and consistent."""

import copy
import filecmp
import math
import re

import pytest

from app.core.config import REPO_ROOT, SHARED_DIR
from app.core.shared_loader import (
    SharedDataError,
    find_reference_problems,
    load_shared_data,
    read_json,
    validate_rule_files,
)

DATA = load_shared_data()
LANGUAGES = ("en", "hi", "mr")
PLACEHOLDER = re.compile(r"\{(\w+)\}")


def test_all_contracts_load_and_cross_reference():
    assert find_reference_problems(DATA) == []
    assert set(DATA.rules) == {"lsd", "fmd", "hs", "anthrax", "ppr", "hpai"}
    assert len(DATA.symptoms) == 28


def test_schema_rejects_a_broken_rule():
    schema = read_json(SHARED_DIR / "disease_rules" / "_schema.json")
    broken = copy.deepcopy(DATA.rules["lsd"])
    broken["signs"]["skin_nodules"] = 7
    del broken["severity_floor"]
    with pytest.raises(SharedDataError):
        validate_rule_files([broken], schema)


def test_every_label_exists_in_all_languages():
    texts = [s["label"] for s in DATA.symptoms.values()] + [s["short_help"] for s in DATA.symptoms.values()]
    texts += [s["label"] for s in DATA.syndromes] + [a["text"] for a in DATA.actions.values()]
    texts += [t["text"] for t in DATA.advisory_templates.values()]
    for text in texts:
        assert all(text.get(lang) for lang in LANGUAGES), text


def test_advisory_placeholders_match_in_every_language():
    for template in DATA.advisory_templates.values():
        for lang in LANGUAGES:
            used = set(PLACEHOLDER.findall(template["text"][lang]))
            assert used == set(template["placeholders"]), (template["id"], lang)


def test_lexicon_covers_every_symptom_and_species_in_every_language():
    lexicon = DATA.lexicon
    assert set(lexicon["symptoms"]) == set(DATA.symptoms)
    assert set(lexicon["species"]) == set(DATA.species)
    for entry in list(lexicon["symptoms"].values()) + list(lexicon["species"].values()):
        assert all(entry[lang] for lang in LANGUAGES)


def haversine_km(a: dict, b: dict) -> float:
    lat1, lng1, lat2, lng2 = map(math.radians, (a["lat"], a["lng"], b["lat"], b["lng"]))
    h = (math.sin((lat2 - lat1) / 2) ** 2
         + math.cos(lat1) * math.cos(lat2) * math.sin((lng2 - lng1) / 2) ** 2)
    return 2 * 6371.0 * math.asin(math.sqrt(h))


def test_geography_is_real_osm_data_inside_pune_district():
    geo = DATA.geo
    assert geo["district"]["code"] == "pune"
    villages = [v for block in geo["blocks"] for v in block["villages"]]
    assert len(geo["blocks"]) == 13 and len(villages) >= 60
    codes = [v["code"] for v in villages]
    assert len(codes) == len(set(codes)), "village codes must be unique"
    for village in villages:
        assert 17.8 <= village["lat"] <= 19.5 and 73.2 <= village["lng"] <= 75.3, village
        assert village["osm"].startswith("node/"), "coordinates must come from an OSM node"
        assert all(village["name"][lang] for lang in LANGUAGES)


def test_demo_cluster_villages_fit_in_one_cluster_radius():
    by_code = {v["code"]: v for b in DATA.geo["blocks"] for v in b["villages"]}
    cluster = [by_code[code] for code in DATA.geo["demo_cluster_villages"]]
    assert len(cluster) >= 3
    radius_km = 5  # CLUSTER_RADIUS_KM default
    assert all(haversine_km(cluster[0], other) <= radius_km for other in cluster)


def test_mobile_copy_of_shared_is_up_to_date():
    # The app bundles mobile/assets/shared; a stale copy means the phone
    # would triage with old rules. Fix with `make sync-shared`.
    mobile_copy = REPO_ROOT / "mobile" / "assets" / "shared"
    for source in SHARED_DIR.rglob("*.json"):
        copy_path = mobile_copy / source.relative_to(SHARED_DIR)
        assert copy_path.exists() and filecmp.cmp(source, copy_path, shallow=False), (
            f"{copy_path} is stale; run `make sync-shared`")
