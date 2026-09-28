# shared/ — single source of truth

Disease logic lives here as JSON, and **both** the Python backend and the Flutter app load these same files.
Never hard-code symptoms, rules, thresholds or advisory text in code.

| File / folder | What it holds |
|---|---|
| `symptoms.json` | 6 species + 28 symptoms: en/hi/mr labels in farmer wording, one-line help, species, syndrome, pictogram name |
| `syndromes.json` | 8 syndromes with a weight per symptom; a report's primary syndrome drives clustering |
| `disease_rules/` | One case definition per disease (LSD, FMD, HS, anthrax, PPR, bird flu), plus `_schema.json` |
| `triage_config.json` | Engine thresholds: confidence levels, severity rules, unknown syndrome, fallback actions |
| `actions.json` | "Do this now" steps in en/hi/mr (`call: true` shows a Call button) |
| `triage_test_vectors.json` | Golden cases that both engines must pass exactly |
| `advisories/templates.json` | Advisory text with `{placeholders}` in en/hi/mr |
| `symptom_lexicon.json` | Spoken phrases, species words and number words for voice input |
| `geo/demo_district.json` | Pune district: 13 talukas and their villages, real OpenStreetMap coordinates (ODbL) |

After editing anything here:
1. Run `make sync-shared`, so the app gets the new copy. A backend test fails if you forget.
2. If you changed a rule on purpose, run `cd backend && uv run python -m scripts.update_triage_goldens`, then review the diff.
3. Run `make test`.

Changes to `shared/` go in small PRs, and the whole team is told about them. Hindi/Marathi text stays flagged `needs_native_review` until a native speaker checks it.
