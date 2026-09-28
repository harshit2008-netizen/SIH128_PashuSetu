# पशुसेतु PashuSetu

Livestock health surveillance and early-warning Android app for Smart India Hackathon 2026.
Farmers and pashu sevaks report sick animals (tap, voice or photo, even offline). The phone gives a
*suspected* disease and what to do now. Officers see clusters on a map, assign vets, track lab samples
and send advisories in the farmer's language.

The build plan and all requirements are in [`PASHURAKSHAK_BUILD_SPEC.md`](PASHURAKSHAK_BUILD_SPEC.md). The spec calls the project "PashuRakshak", and we renamed it PashuSetu.

## Prerequisites

Git, Docker Desktop (with WSL2 on Windows), [uv](https://docs.astral.sh/uv/) (it installs Python 3.11 for you),
Flutter SDK (stable) + Android Studio, GNU make (Windows: `winget install ezwinports.make`), and an Android phone with USB debugging on.

## First-time setup

1. Clone the repo and open a terminal in it.
2. `flutter doctor`. Fix every red item, including `flutter doctor --android-licenses`.
3. `make up`. This starts PostGIS on port 5433 and creates `.env` from `.env.example`.
4. `make api`. Open <http://localhost:8000/health>. It should show `"status": "ok"`.
5. `cd mobile && flutter run`, with the phone connected or an emulator running.

## Everyday commands

| Command | What it does |
|---|---|
| `make up` / `make down` | Start or stop the database |
| `make api` | Run the API with auto-reload (docs at `/docs`) |
| `make sync-shared` | Copy `shared/` into the app after editing it |
| `make test` | Backend and mobile tests |
| `make apk` | Build the release APK |

## Demo networking

The phone and laptop must be on the same hotspot. The app uses the laptop's LAN IP (for example `http://192.168.43.10:8000`), and the emulator uses `http://10.0.2.2:8000`.
The animal husbandry helpline defaults to `1962`. Check it for the demo state and set `HELPLINE_NUMBER` in `.env`.
