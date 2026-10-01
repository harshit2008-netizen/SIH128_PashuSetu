# PashuSetu architecture

Summarised from the project's build plan (Section 2), which is kept private.

```
 Farmer / Pashu-Sevak phone (Flutter)             Vet / Lab / District officer phone (same app, role-based)
 +-----------------------------------+            +------------------------------------------+
 | Report flow: tap, voice, photo    |            | Map dashboard, alerts, case queue        |
 | On-device triage:                 |            | Case detail + timeline, lab QR, advisories|
 |   rule engine (shared JSON rules) |            +--------------------+---------------------+
 |   LSD image model (TFLite)        |                                 |
 | Local DB (drift/SQLite) + outbox  |                                 | REST + JWT
 +-----------------+-----------------+                                 |
                   | sync when online (idempotent by client_uuid)      |
                   v                                                   v
 +-------------------------------------------------------------------------------------+
 | FastAPI backend: reports, cases, triage, alerts, labs, advisories, dashboard, sync   |
 | APScheduler jobs: DBSCAN clustering, EARS-C2 spikes, SLA escalation, block risk      |
 | Notifier: in-app inbox (P0); SMS / IVR / FCM adapters (P2)                           |
 +------------------------+-----------------------------------+------------------------+
                          v                                   v
                PostgreSQL 16 + PostGIS              Open-Meteo weather (cached)
```

## Key decisions

- Triage runs **on the phone first**, so a para-vet with no signal still gets an answer. The server re-runs it on sync and is authoritative.
- The server owns case status. The phone owns the content of its own reports.
- Every report carries a phone-generated `client_uuid`. The server upserts by it, so retries never duplicate.
- Outbreak detection groups reports by **syndrome**, not disease label, so unknown diseases still form clusters.
- Disease logic lives only in `shared/` JSON, loaded by both the Python and Dart engines.
