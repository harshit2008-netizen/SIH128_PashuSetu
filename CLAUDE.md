# CLAUDE.md — PashuSetu working notes

**Source of truth:** `PASHURAKSHAK_BUILD_SPEC.md`. Read it fully before any phase.
**Rename:** the project is **PashuSetu (पशुसेतु)**. Wherever the spec says PashuRakshak / `pashurakshak`, use
PashuSetu / `pashusetu`: repo root = this folder, Android org `in.pashusetu`, DB `pashusetu`, QR prefix `PS-S-`.

## Working rules (spec Section 0)
- One phase at a time (spec Section 13). Run that phase's "Done when" checks, report pass/fail/left, commit `phase-N: <summary>`, then stop for review.
- P0 demo path first. No TODOs or placeholders in the demo path. No mock data shown as real.
- Model metrics only come from `ml/reports/*.json` produced by a real run.
- Disease logic lives only in `shared/*.json` and is loaded by both backend and app. Never hard-code it.
- The app says **"suspected"**, never "diagnosed". Every triage result shows: "This is not a diagnosis. A vet or lab must confirm."
- The team is new to this stack: clear names, short functions, comments explain *why*. Each important folder has a short README.
- On ambiguity or conflict, ask the human with short multiple-choice options.
- UI isn't done until it has been checked visually (spec 9.10). Log changes in `docs/design_notes.md`.

## Commands (repo root; Windows recipes run in Git Bash)
```
make up            # PostGIS in Docker, host port 5433 (creates .env from .env.example)
make api           # FastAPI on 0.0.0.0:8000, /health, /docs
make migrate       # alembic upgrade head
make sync-shared   # copy shared/ -> mobile/assets/shared/ (after every shared/ edit)
make test          # backend pytest + flutter test
make apk           # release APK
cd backend && uv run pytest
cd mobile && flutter analyze && flutter test && flutter run
```
`make seed` / `make reset-demo` wipe and rebuild the demo data. `make simulate SCENARIO=... SPEED=...` needs `make api` running.

## Machine notes (Harshit's Windows laptop)
- Flutter SDK is at `E:\dev\flutter` (on the user PATH). Python 3.11 is managed by uv (`backend/.python-version`).
- GNU make comes from winget `ezwinports.make`. The Makefile uses Git Bash via `GIT_BASH`.
- Docker Desktop needs WSL2 (installed, v2.7.14).
- The Android SDK path has a space, so Flutter points at the 8.3 short path: `flutter config --android-sdk C:\Users\[user]\AppData\Local\Android\Sdk`.
- Gradle fails with "Unable to establish loopback connection" unless `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=E:\dev\tmp` is set.
- The home network can't reach GitHub CDN IP 185.199.109.133, and Java doesn't fall back. If a Gradle/SDK download times out, fetch it with curl or `android sdk install <pkg>`.
- Android build: `kotlin.incremental=false` (E: project vs C: pub cache breaks incremental Kotlin). No
  permission_handler (needs compileSdk 37); photos use the camera app, so no CAMERA permission yet.
- Team phone for testing: Vivo V2443 (Android 16), adb id `[phone-id]`. Reach the laptop via `adb reverse tcp:8000 tcp:8000`
  (app default API URL is http://127.0.0.1:8000).

## Folder map
```
shared/    JSON contracts: symptoms, syndromes, lexicon, disease_rules/, test vectors, advisories/, geo/
backend/   FastAPI app (app/core, app/api/v1, app/services, app/models), alembic/, scripts/, tests/
mobile/    Flutter app: lib/core/theme (tokens, typography), lib/features/*, lib/widgets/, assets/
ml/        Kaggle training (kaggle/), helpers (src/), reports/ (real metrics); data/ + artifacts/ gitignored
docs/      architecture, api, demo_script, design_notes, screenshots/
```

## Conventions
- Backend: settings only via `app.core.config.get_settings()`. DB sessions via `app.core.db.get_db`.
- Error shape: `{"error": {"code", "message"}}`. Role check on every route.
- Mobile: colours, spacing and radii from `core/theme/tokens.dart`, text styles from `Theme.of(context).textTheme`.
  No `ColorScheme.fromSeed`, no Roboto, no emoji, no all-caps, no gradients (banned list: spec 9.10).
- `tagYellow` is only for ear tags, the app mark and the one Report action.
- UI strings live in `mobile/lib/l10n/*.arb` (en/hi/mr); `flutter gen-l10n` regenerates. Pictograms: `python tool/pictograms.py`.
- Goldens: `flutter test --update-goldens test/goldens` after an intended visual change; review the PNGs.
- Hindi/Marathi strings stay flagged `needs_native_review` until a native speaker checks them.
- Never print or commit the Kaggle token or `.env`.

## Triage engine notes (Phase 1 decisions)
- Thresholds live in `shared/triage_config.json`, action texts in `shared/actions.json`, and both engines read them.
- Candidates with score 0 are dropped; the top 3 are returned. A candidate carries `required_signs_met`.
- Primary syndrome = highest summed weight from `syndromes.json`. 'general' only counts when nothing else is present; ties go alphabetical.
- Rounding is half up (`floor(x*1000+0.5)/1000`) in both engines. Tie-breaks are by id.
- After an intentional rule change: `uv run python -m scripts.update_triage_goldens`, then review the diff. Never edit `expect`.
- Geography: `uv run python -m scripts.geocode_villages` (uses `backend/.cache`; `--refresh` downloads again from OSM).

## Phase status
- Phase 0 (scaffold): done, commit 865d1a2.
- Phase 1 (shared contracts + engines): done, commit ebb504f.
- Phase 2 (backend core): done, commit 51a9bc9.
- Phase 3 (mobile foundation + design system): done, commit 77fba74.
- Phase 4 (report flow + offline + on-device triage): done, commit ee2ef69.
- Phase 7 (surveillance + simulator): done, commit d61a7a7.
- Phase 8 (officer, lab, advisories): done, commit abd47b3.
- Phase 9 (demo hardening): demo script, `make demo-check`, README, checklist in `docs/demo_checklist.md`.
  Open items: Phases 5 (voice) and 6 (LSD image model), backup screen recording, native-speaker review.
