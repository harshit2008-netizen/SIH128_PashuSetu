# backend/ — PashuSetu API (FastAPI + PostGIS)

- Python 3.11, dependencies managed by [uv](https://docs.astral.sh/uv/). `uv.lock` pins exact versions.
- Settings come from the repo-root `.env` (`app/core/config.py`).
- The code is laid out as follows:
  - `app/api/v1/`: routes (auth, reports and sync, triage, cases, geo, meta).
  - `app/services/`: logic. `reports.py` handles report ingest, `cases.py` the case lifecycle, `triage/` the rule engine and fusion, and `access.py` who can see which case.
  - `app/models/`: every table from spec 8.1. `alembic/versions/` holds their migration.
  - `scripts/`: `seed.py` builds the demo world, `geocode_villages.py` the OSM geography, `update_triage_goldens.py` refreshes the test goldens.
  - `tests/`: runs against a separate `pashusetu_test` database, so your demo data is never touched.

Run from the repo root:

```bash
make up      # PostGIS in Docker (host port 5433)
make seed    # migrate, then wipe and rebuild the demo data (same result every time)
make api     # http://0.0.0.0:8000, docs at /docs
make test-backend
```

API overview and demo logins: [../docs/api.md](../docs/api.md).
