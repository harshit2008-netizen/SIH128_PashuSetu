# PashuSetu API

Live, clickable docs: run `make api`, then open <http://localhost:8000/docs>.
To try protected routes there, call `POST /api/v1/auth/otp/verify`, copy `access_token`, press **Authorize** and paste it.

All routes are under `/api/v1`, except `GET /health`. Errors always look like `{"error": {"code": "...", "message": "..."}}`.

## Demo logins (OTP is always `123456` in demo mode)

| Role | Phone | Name | Area |
|---|---|---|---|
| farmer | 9000000001 | Ramesh Gaikwad | Junnar demo village |
| pashu_sevak | 9000000002 | Sunita Pawar | Junnar block |
| vet | 9000000003 | Dr. Anil Deshmukh | Junnar block |
| lab | 9000000004 | Priya Kulkarni | Pune district |
| district_officer | 9000000005 | Dr. Meera Joshi | Pune district |

Every other block has its own vet (phones `9000000310` to `9000000321`), and 40 more farmers use phones `9000001000` to `9000001039`.

## Routes built so far (Phase 2)

| Route | Who | What |
|---|---|---|
| `GET /auth/demo-accounts` | anyone | The five demo accounts, for the role picker |
| `POST /auth/otp/request`, `POST /auth/otp/verify` | anyone | Demo OTP login, returns a JWT and the profile |
| `GET /me` | all | Profile with village / block / district |
| `POST /reports` | farmer, sevak | Create or upsert by `client_uuid`, triage on the server, open or follow up a case |
| `POST /reports/{id}/photo` | the reporter | JPEG/PNG photo, up to 8 MB |
| `POST /sync/push` | farmer, sevak | Up to 50 outbox reports; per item `created` / `duplicate` / `error` |
| `GET /sync/pull?since=` | all | My cases, my advisories, vaccinations due in 30 days |
| `POST /triage/evaluate` | all | Triage without saving |
| `GET /cases` | vet, officer | Open cases, emergency first. Filters: `status`, `severity`, `block_id`, `disease`, `include_closed` |
| `GET /cases/{id}` | who can see it | Detail with reports, triage, timeline, samples |
| `POST /cases/{id}/assign` | vet, officer | `{}` = assign to me (vet); officers pass `vet_id` |
| `POST /cases/{id}/transition` | vet, officer | `under_treatment`, `resolved` or `closed_ruled_out`, with an optional `note` |
| `GET /geo/villages?near=lat,lng` | all | Nearest villages with `distance_km`, or all villages |
| `GET /geo/blocks` | all | Talukas with their centre points |
| `GET /meta/engine` | anyone | Rule versions and the image model card (after Phase 6) |

Alerts arrive in Phase 7; lab samples, advisories and the dashboard in Phase 8.

## `POST /reports` example

```json
{
  "client_uuid": "0b7f7c1e-3f55-4f4e-9d5a-1a2b3c4d5e6f",
  "location": {"lat": 19.2, "lng": 73.87},
  "species": "cattle",
  "symptoms": ["skin_nodules", "fever"],
  "sick_count": 2, "dead_count": 0, "total_at_risk": 12,
  "voice_transcript": "गाय के शरीर पर गांठें हैं और बुखार है",
  "device_triage": {"engine_version": "rules-1", "top": "lsd", "score": 0.50},
  "created_on_device_at": "2026-09-28T09:41:00+05:30",
  "channel": "app"
}
```

Response (shortened):

```json
{
  "status": "created",
  "report": {"id": "...", "village_id": "...", "has_photo": false, "...": "..."},
  "triage": {
    "engine_version": "rules-1",
    "candidates": [{"disease_id": "lsd", "score": 0.503, "confidence": "moderate",
                    "matched_signs": ["skin_nodules", "fever"], "missing_key_signs": [],
                    "required_signs_met": true, "sources": {"rules": 0.503}}],
    "primary_syndrome": "dermatological", "severity": "urgent",
    "zoonotic_flag": false, "unknown_syndrome": false,
    "actions": ["isolate_animal", "vector_control", "call_vet"],
    "safety_note": null, "photo": null, "triage_mismatch": false
  },
  "case_id": "..."
}
```

- Leave out `village_id` and the server uses the nearest village to `location`.
- A photo-model probability in `device_triage.image_p_lsd` is fused with the rules: LSD = 0.6 × rules + 0.4 × photo.
