# Demo-ready checklist (spec Section 18)

Status on 2026-09-30, after Phase 9. Ticked only where it was checked; the reason is given for every open item.

- [ ] **All P0 items in Section 1.1 work on the real phone.** Everything except voice input (Phase 5) and the LSD
  image model with the About the AI screen (Phase 6) works on the Vivo V2443 against the laptop backend.
- [x] **`make test` is green.** Backend 79 passed (vectors, sync, clustering, lifecycle, parity); Flutter analyze
  clean, 47 tests passed including goldens. The lexicon tests arrive with voice (Phase 5).
- [x] **Demo script ran 3 times in a row from `make reset-demo` without manual fixes.** `make demo-check` covers
  steps 3–8 through the API: 3/3 all PASS. Steps 1–2 (tap input, on-device rules) were checked on the phone.
- [x] **No Roboto, no default purple, nothing from the banned list (9.10).** Checked: no `fromSeed`, no gradients,
  no all-caps text. Screenshots are in `docs/screenshots/`, and the QA log is in `docs/design_notes.md`.
- [x] **Hindi/Marathi strings reviewed by a native speaker, or still flagged `needs_native_review`.** They are still flagged.
- [x] **Every triage result says "suspected" and shows the not-a-diagnosis line.**
- [ ] **Model metrics come from `ml/reports/lsd_metrics.json`, and the model card lists limitations.** No model is trained yet
  (Phase 6), so `ml/reports/` is empty and the app shows no model metrics at all.
- [ ] **`ml/DATA_SOURCES.md` lists every dataset with its licence.** The file exists; the LSD dataset entry is completed in Phase 6.
- [x] **README explains setup from a fresh laptop in under 15 steps.** It takes 12 steps.
- [ ] **Release APK built and a backup screen recording saved.** The APK is built (`app-release.apk`, 83 MB) and installed on the phone.
  The screen recording has to be made by the team (see `docs/demo_script.md`).
