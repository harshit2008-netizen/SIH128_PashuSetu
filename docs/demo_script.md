# Demo script (5 minutes)

This is spec Section 14 with everything P0 built: tap or voice input, the on-phone LSD photo model, offline outbox,
outbreak detection, the lab loop and advisories.

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

1. **Offline report with voice.** Sevak (Hindi): Settings > "Simulate no signal" on. Tap Report, choose गाय, then
   "बोलकर बताएं" and say: *"गाय के शरीर पर गांठें हैं, बुखार है, दो गाय बीमार हैं"*. The sheet shows what it heard
   (lumps on the skin, fever, 2 sick) as tiles that can be unticked; tap "ये जोड़ें". Voice never sends on its own.
   The first time, Android asks for the microphone: answer "While using the app".
2. **Photo + on-device AI.** Upload an LSD photo (or take one of a printed photo). Under the photo: "looks like lumpy skin
   disease, suspected only". Send: the result says "Suspected: Lumpy skin disease", Urgent, with a Photo chip and
   "Photo: N% like lumpy skin disease", plus "This is not a diagnosis. A vet or lab must confirm."
   The sync pill says it is waiting to send.
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
8. **Honesty.** Settings > About the AI: the three layers in plain words, the photo model's real test results
   (from the model card written by the Kaggle run) and its known limits. Engine version rules-1+lsd_v1.

## Extra (P1) if there is time

9. **Risk.** Officer: bottom sheet > Risk. Blocks ranked by the rule-based risk estimate for LSD, circles on the map,
   each with "Why: season 37%, weather 30%" and nearby cases and vaccination coverage. Tap HS to compare.
10. **Escalation.** Leave a new urgent case untouched for 5 minutes (demo SLA): it shows "Escalated" in the case list
    and "No response in time: sent to the block vet" on the case. After 10 minutes it goes to the district officer.
11. **Vaccination.** Sevak: home > "All animals and vaccines" > a herd > "Vaccinated today" > a vaccine.
    The next due date updates for every animal in the herd.

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
