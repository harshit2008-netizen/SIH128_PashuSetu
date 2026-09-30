"""Write each vector's exact Python engine output into its "golden" block.

Run from backend/:  uv run python -m scripts.update_triage_goldens

Why: the spec's "expect" checks are loose (top disease, severity). The golden
block pins every score to 3 decimals so the Dart engine can be proven
identical to this one. Only run this after an intentional rule change, then
review the diff of shared/triage_test_vectors.json line by line. This script
never touches "expect"; if an "expect" check fails, fix the rules or report
it, do not edit the vector to make it pass.
"""

import json

from app.core.config import SHARED_DIR
from app.core.shared_loader import load_shared_data
from app.services.triage.fusion import evaluate_with_fusion
from app.services.triage.rule_engine import TriageInput, evaluate

VECTORS_PATH = SHARED_DIR / "triage_test_vectors.json"


def to_input(raw: dict) -> TriageInput:
    return TriageInput(
        species=raw["species"],
        symptoms=frozenset(raw["symptoms"]),
        sick_count=raw["sick_count"],
        dead_count=raw["dead_count"],
        total_at_risk=raw["total_at_risk"],
        report_month=raw["report_month"],
    )


def run_vector(data, raw: dict) -> dict:
    """Rules only, or rules + photo fusion when the vector gives a photo probability."""
    if "image_p_lsd" in raw:
        return evaluate_with_fusion(data, to_input(raw), raw["image_p_lsd"])
    return evaluate(data, to_input(raw))


def golden_for(result: dict) -> dict:
    golden = {
        "candidates": [[c["disease_id"], c["score"]] for c in result["candidates"]],
        "primary_syndrome": result["primary_syndrome"],
        "severity": result["severity"],
        "zoonotic_flag": result["zoonotic_flag"],
        "unknown_syndrome": result["unknown_syndrome"],
        "actions": result["actions"],
        "has_safety_note": result["safety_note"] is not None,
    }
    if "photo" in result:  # only fusion runs have it
        golden["engine_version"] = result["engine_version"]
        golden["sources"] = [[c["disease_id"], c["sources"]] for c in result["candidates"] if "image" in c["sources"]]
        golden["photo"] = result["photo"]
    return golden


def compact(value) -> str:
    return json.dumps(value, ensure_ascii=False)


def render(document: dict) -> str:
    # One line per field keeps the file readable and diffs small.
    lines = ["{", f'  "version": {document["version"]},', f'  "note": {compact(document["note"])},',
             '  "vectors": [']
    for index, vector in enumerate(document["vectors"]):
        fields = [f'      "{key}": {compact(value)}' for key, value in vector.items()]
        comma = "," if index < len(document["vectors"]) - 1 else ""
        lines += ["    {", ",\n".join(fields), "    }" + comma]
    lines += ["  ]", "}"]
    return "\n".join(lines) + "\n"


def main() -> None:
    data = load_shared_data()
    document = json.loads(VECTORS_PATH.read_text(encoding="utf-8"))
    for vector in document["vectors"]:
        vector["golden"] = golden_for(run_vector(data, vector["input"]))
    VECTORS_PATH.write_text(render(document), encoding="utf-8", newline="\n")
    print(f"Updated golden blocks for {len(document['vectors'])} vectors in {VECTORS_PATH}")


if __name__ == "__main__":
    main()
