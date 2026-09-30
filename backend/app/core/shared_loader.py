"""Load the shared/ JSON contracts once and check they are consistent.

shared/ is the single source of truth for disease logic; the Flutter app
reads the same files. Loading fails fast (at startup or in tests) if a rule
file breaks the schema or points at an id that does not exist, so a typo in
JSON can never silently change a triage result.
"""

import json
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

from app.core.config import SHARED_DIR


class SharedDataError(ValueError):
    """A shared/ file is invalid or refers to an unknown id."""


@dataclass(frozen=True)
class SharedData:
    species: dict[str, dict]
    symptoms: dict[str, dict]
    syndromes: list[dict]
    rules: dict[str, dict]
    triage_config: dict
    actions: dict[str, dict]
    advisory_templates: dict[str, dict]
    lexicon: dict
    geo: dict
    alert_texts: dict

    @property
    def rules_in_order(self) -> list[dict]:
        return [self.rules[rule_id] for rule_id in sorted(self.rules)]


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def validate_rule_files(rules: list[dict], schema: dict) -> None:
    validator = Draft202012Validator(schema)
    problems = [
        f"{rule.get('id', '?')}: {'/'.join(map(str, error.path)) or '(root)'}: {error.message}"
        for rule in rules
        for error in validator.iter_errors(rule)
    ]
    if problems:
        raise SharedDataError("Rule files break _schema.json:\n" + "\n".join(problems))


def find_reference_problems(data: SharedData) -> list[str]:
    """Return every id in the contracts that points at something missing."""
    problems = []
    syndrome_ids = {s["id"] for s in data.syndromes}
    for symptom in data.symptoms.values():
        if symptom["syndrome"] not in syndrome_ids:
            problems.append(f"symptom {symptom['id']}: unknown syndrome {symptom['syndrome']}")
        problems += [f"symptom {symptom['id']}: unknown species {s}"
                     for s in symptom["species"] if s not in data.species]
    for syndrome in data.syndromes:
        for symptom_id in syndrome["symptoms"]:
            if symptom_id not in data.symptoms:
                problems.append(f"syndrome {syndrome['id']}: unknown symptom {symptom_id}")
            elif data.symptoms[symptom_id]["syndrome"] != syndrome["id"]:
                problems.append(f"syndrome {syndrome['id']}: {symptom_id} is listed under "
                                f"{data.symptoms[symptom_id]['syndrome']} in symptoms.json")
    listed = {s for syndrome in data.syndromes for s in syndrome["symptoms"]}
    problems += [f"symptom {s} is in no syndrome" for s in data.symptoms if s not in listed]
    for rule in data.rules.values():
        problems += _rule_reference_problems(rule, data)
    config = data.triage_config["actions"]
    problems += [f"triage_config: unknown action {a}"
                 for a in config["low_confidence"] + config["unknown_syndrome"] if a not in data.actions]
    fusion = data.triage_config["fusion"]
    if fusion["disease"] not in data.rules:
        problems.append(f"triage_config.fusion: unknown disease {fusion['disease']}")
    if fusion["ask_sign"] not in data.symptoms:
        problems.append(f"triage_config.fusion: unknown sign {fusion['ask_sign']}")
    if abs(fusion["rules_weight"] + fusion["image_weight"] - 1) > 1e-9:
        problems.append("triage_config.fusion: rules_weight + image_weight must be 1")
    for symptom_id in data.lexicon["symptoms"]:
        if symptom_id not in data.symptoms:
            problems.append(f"lexicon: unknown symptom {symptom_id}")
    return problems


def _rule_reference_problems(rule: dict, data: SharedData) -> list[str]:
    rule_id = rule["id"]
    problems = [f"rule {rule_id}: unknown symptom {s}" for s in rule["signs"] if s not in data.symptoms]
    for group in rule["required"]:
        problems += [f"rule {rule_id}: required sign {s} has no weight in signs"
                     for s in group if s not in rule["signs"]]
    problems += [f"rule {rule_id}: unknown action {a}" for a in rule["actions"] if a not in data.actions]
    if rule["advisory_template"] not in data.advisory_templates:
        problems.append(f"rule {rule_id}: unknown advisory template {rule['advisory_template']}")
    # A sign nobody can tick for this disease's species would be dead weight.
    for symptom_id in rule["signs"]:
        symptom = data.symptoms.get(symptom_id)
        if symptom and not set(symptom["species"]) & set(rule["species"]):
            problems.append(f"rule {rule_id}: sign {symptom_id} is not shown for any of its species")
    return problems


def load_shared_data(shared_dir: Path = SHARED_DIR) -> SharedData:
    rules_dir = shared_dir / "disease_rules"
    config = read_json(shared_dir / "triage_config.json")
    rule_files = sorted(p.stem for p in rules_dir.glob("*.json") if not p.name.startswith("_"))
    if rule_files != sorted(config["rule_ids"]):
        raise SharedDataError(f"triage_config.rule_ids {config['rule_ids']} != rule files {rule_files}")
    rules = [read_json(rules_dir / f"{rule_id}.json") for rule_id in config["rule_ids"]]
    validate_rule_files(rules, read_json(rules_dir / "_schema.json"))

    symptoms_file = read_json(shared_dir / "symptoms.json")
    data = SharedData(
        species={s["id"]: s for s in symptoms_file["species"]},
        symptoms={s["id"]: s for s in symptoms_file["symptoms"]},
        syndromes=read_json(shared_dir / "syndromes.json")["syndromes"],
        rules={rule["id"]: rule for rule in rules},
        triage_config=config,
        actions={a["id"]: a for a in read_json(shared_dir / "actions.json")["actions"]},
        advisory_templates={t["id"]: t for t in read_json(shared_dir / "advisories" / "templates.json")["templates"]},
        lexicon=read_json(shared_dir / "symptom_lexicon.json"),
        geo=read_json(shared_dir / "geo" / "demo_district.json"),
        alert_texts=read_json(shared_dir / "alerts.json")["summaries"],
    )
    problems = find_reference_problems(data)
    if problems:
        raise SharedDataError("shared/ has broken references:\n" + "\n".join(problems))
    return data


@lru_cache
def get_shared_data() -> SharedData:
    return load_shared_data()
