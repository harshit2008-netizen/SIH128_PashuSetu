# Demo script (5 minutes)

This is spec Section 14 adapted to what is built today (Phases 0–4, 7, 8).
Steps 1–2 use tap input and the rule engine only: voice (Phase 5) and the LSD photo model (Phase 6) are not built yet.
Say so plainly if a judge asks. Never claim the photo is analysed.

## Before the judges arrive (10 min)

1. Laptop and phone on the same hotspot (the map tiles need internet; everything else works without it).
2. Start Docker Desktop, then run each of these from the repo root in Git Bash:
   ```
   make up
   make api            # leave this terminal open
   make demo-check     # new terminal: resets demo data and rehearses steps 3–8; all must PASS
   make reset-demo     # clean slate again for the live run
   ```
3. Phone over USB: `adb reverse tcp:8000 tcp:8000` (the app's default URL is http://127.0.0.1:8000).
   Without USB: Settings > tap "App version" 7 times > Developer options > API URL = the laptop's LAN IP, e.g. http://192.168.43.10:8000.
4. Phone A: log in as **Pashu sevak** and switch the language to Hindi. Phone B (or the second login on the same phone): **District officer**, English.

Demo logins (OTP is always `123456`):

| Role | Name | Phone |
|---|---|---|
| Farmer | Ramesh Gaikwad | 9000000001 |
| Pashu sevak | Sunita Pawar | 9000000002 |
| Vet | Dr. Anil Deshmukh | 9000000003 |
| Lab | Priya Kulkarni | 9000000004 |
| District officer | Dr. Meera Joshi | 9000000005 |

With one phone, switch roles with Settings > Change role (demo).

## Live steps

1. **Offline report.** Sevak: Settings > "Simulate no signal" on. Tap Report, choose cow, tap "Lumps on the skin" and "Fever", sick 2.
   Optionally attach a photo (camera or gallery); it is stored with the case, not analysed yet.
2. **On-device triage.** The result screen shows "Suspected: Lumpy skin disease", severity, why-chips and "Do this now" steps,
   plus the line "This is not a diagnosis. A vet or lab must confirm." The sync pill says it is waiting to send.
3. **Sync.** Turn "Simulate no signal" off. The pill changes to all sent. Officer: the case appears on the map within 10 s.
4. **Outbreak detection.** Laptop: `make simulate SCENARIO=lsd_outbreak SPEED=5`.
   Officer: pins appear in neighbouring villages, then an Urgent cluster alert:
   "6 reports of skin lumps and swelling in 3 villages over 4 days".
5. **Response.** Officer: open the alert > Acknowledge > open a case > Assign vet.
   Megaphone icon > template "LSD nearby" > radius 10 km > shows "Will reach N farmers" > Send.
   Farmer or sevak (Hindi): the advisory is in the inbox; tap Listen.
6. **Lab loop.** Vet: open the case > Request sample > the QR code (PS-S-XXXXXX) is shown.
   Sevak: Samples to collect > scan the QR (or type the code) > collected.
   Lab: Scan sample > received > Positive, Lumpy skin disease > Save result.
   Any role: the case timeline lists every step with times; the officer's "Median first response" KPI is filled.
7. **One Health.** Laptop: `make simulate SCENARIO=anthrax_single`. Officer: a red Emergency zoonotic alert
   with the human-safety note ("Do not open the carcass").
8. **Honesty.** Settings shows the triage engine version (rules-1). Explain the rule engine is transparent,
   the same rules run on the phone and the server (golden test vectors prove it), and the image model is next (Phase 6).

## Backups

- Phone disconnects: plug back in, run `adb reverse tcp:8000 tcp:8000` again.
- Something went wrong mid-demo: `make reset-demo` (about 5 s), log in again, restart from step 3.
- The camera permission prompt: answer "While using the app". Or type the sample code instead of scanning.
- Map tiles blank: no internet on the phone. Pins and alert areas still draw.
- Keep a screen recording of a full run on the laptop and play it if the live setup fails.

## Rehearsal log

| Date | Run | Result |
|---|---|---|
| 2026-09-30 | `make demo-check` x3 from `make reset-demo` | All steps PASS each time (sync no duplicate, cluster alert, acknowledge, assign, Hindi advisory, lab loop, timeline, KPI, zoonotic alert, meta) |
| 2026-09-30 | On the phone (Vivo V2443) | Officer dashboard, alert, acknowledge, advisory to 5 farmers, assign vet, sample QR, sevak Hindi inbox with Listen, lab scan by code and positive result |
