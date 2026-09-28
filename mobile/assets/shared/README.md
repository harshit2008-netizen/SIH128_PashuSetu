# shared/ — single source of truth

Disease logic lives here as JSON, and **both** the Python backend and the Flutter app load these same files.
Never hard-code symptoms, rules or advisory text in code.

| File / folder | What it holds | Filled in |
|---|---|---|
| `symptoms.json` | Symptom catalogue (en/hi/mr labels, species, syndrome, pictogram) | Phase 1 |
| `syndromes.json` | Symptom -> syndrome groups used for clustering | Phase 1 |
| `symptom_lexicon.json` | Voice phrases -> symptom ids | Phase 1 |
| `disease_rules/` | One rule file per disease + `_schema.json` | Phase 1 |
| `triage_test_vectors.json` | Golden cases both engines must pass | Phase 1 |
| `advisories/templates.json` | Advisory text with `{placeholders}` | Phase 1 |
| `geo/demo_district.json` | District, blocks, villages, coordinates | Phase 1 |

After editing anything here, run `make sync-shared` so the app gets the new copy.
Changes to `shared/` go in small PRs, and the whole team is told about them. Hindi/Marathi text stays flagged `needs_native_review` until a native speaker checks it.
