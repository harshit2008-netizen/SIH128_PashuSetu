# backend/ — PashuSetu API (FastAPI + PostGIS)

- Python 3.11, dependencies managed by [uv](https://docs.astral.sh/uv/). `uv.lock` pins exact versions.
- Settings come from the repo-root `.env` (`app/core/config.py`). Copy `.env.example` to `.env`, or let `make up` do it.
- `app/main.py` is the FastAPI app. `GET /health` reports DB and PostGIS status.
- `app/api/v1/` holds the routes and `app/services/` the business logic (triage, surveillance, advisories).
- `alembic/` holds DB migrations (tables arrive in Phase 2).
- `scripts/` holds `seed.py` and `simulator.py` (Phases 2 and 7).

Run from the repo root:

```bash
make up     # start PostGIS in Docker (host port 5433)
make api    # API on http://0.0.0.0:8000, docs at /docs
make test-backend
```
