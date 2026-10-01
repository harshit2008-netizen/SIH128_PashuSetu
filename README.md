# पशुसेतु PashuSetu

Livestock health surveillance and early-warning Android app for Smart India Hackathon 2026.
Farmers and pashu sevaks report sick animals (tap, voice or photo, even offline). The phone gives a
*suspected* disease and what to do now. Officers see clusters on a map, assign vets, track lab samples
and send advisories in the farmer's language.

The build plan and all requirements are in [`PASHURAKSHAK_BUILD_SPEC.md`](PASHURAKSHAK_BUILD_SPEC.md). The spec calls the project "PashuRakshak", and we renamed it PashuSetu.

## Prerequisites

Git, Docker Desktop (with WSL2 on Windows), [uv](https://docs.astral.sh/uv/) (it installs Python 3.11 for you),
Flutter SDK (stable) + Android Studio, GNU make (Windows: `winget install ezwinports.make`), and an Android phone with USB debugging on.

## First-time setup (fresh laptop, 12 steps)

1. Install the prerequisites above. Start Docker Desktop once and accept its licence.
2. `flutter doctor`. Fix every red item, including `flutter doctor --android-licenses`.
3. Clone the repo and open Git Bash in it.
4. `make up`. This starts PostGIS on port 5433 and creates `.env` from `.env.example`.
5. `make migrate`, then `make seed` (demo district, villages, the five demo users, background cases).
6. `make api`. Open <http://127.0.0.1:8000/health>; it should show `"status": "ok"`. Leave this terminal open.
7. In a second terminal: `make demo-check`. Every step must print PASS.
8. Phone: turn on Developer options and USB debugging, plug it in, accept the "Allow USB debugging" prompt.
9. `adb reverse tcp:8000 tcp:8000`, so the phone reaches the laptop at 127.0.0.1:8000.
10. `make apk`, then `adb install -r mobile/build/app/outputs/flutter-apk/app-release.apk`
    (or `cd mobile && flutter run` for a debug build).
11. Open PashuSetu, choose a role, OTP `123456`. Logins are in [`docs/demo_script.md`](docs/demo_script.md).
12. Before a demo: `make reset-demo`, then follow the demo script.

## Starting and stopping

| When | Do |
|---|---|
| Start | Docker Desktop running, then `make up`, then `make api` |
| Phone reconnected | `adb reverse tcp:8000 tcp:8000` again |
| Stop the API | Ctrl+C in the `make api` terminal |
| Stop the database | `make down` (data stays in the Docker volume) |
| Wipe and reload demo data | `make reset-demo` |
| Code changed but the API still behaves the old way | Stop it (Ctrl+C) and run `make api` again: on Windows the auto-reload can hang half-way |

## Everyday commands

| Command | What it does |
|---|---|
| `make up` / `make down` | Start or stop the database |
| `make api` | Run the API with auto-reload (docs at `/docs`) |
| `make sync-shared` | Copy `shared/` into the app after editing it |
| `make simulate SCENARIO=lsd_outbreak SPEED=5` | Post a scripted outbreak through the API (also `anthrax_single`, `hs_monsoon`) |
| `make demo-check` | Reset the demo data and rehearse demo steps 3–8 through the API |
| `make test` | Backend and mobile tests |
| `make apk` | Build the release APK |

## Demo networking

Over USB, `adb reverse` is simplest. Without USB, the phone and laptop must be on the same hotspot; set the API URL in the developer options (tap App version 7 times in Settings) to the laptop's LAN IP (for example `http://192.168.43.10:8000`), and the emulator uses `http://10.0.2.2:8000`.
The animal husbandry helpline defaults to `1962`. Check it for the demo state and set `HELPLINE_NUMBER` in `.env`.
