"""Rehearse the 5-minute demo (spec Section 14) through the real API.

Run from the repo root with `make api` running:
    make demo-check            # resets the demo data first, then checks every step

Each step prints PASS or FAIL with what it saw, so the team can confirm the
whole story works before presenting. It uses the same accounts and the same
simulator scenarios as the live demo; only the phone taps are replaced by
API calls.
"""

import json
import sys
import time
import urllib.error
import urllib.request
import uuid
from datetime import UTC, datetime

from app.core.shared_loader import get_shared_data
from scripts import simulator

BASE = "http://127.0.0.1:8000"
PHONES = {"farmer": "9000000001", "sevak": "9000000002", "vet": "9000000003", "lab": "9000000004",
          "officer": "9000000005"}


class Demo:
    def __init__(self):
        self.tokens = {}
        self.failures = 0

    def call(self, role: str | None, method: str, path: str, body=None):
        headers = {"Content-Type": "application/json"}
        if role:
            headers["Authorization"] = f"Bearer {self.token(role)}"
        request = urllib.request.Request(f"{BASE}/api/v1{path}", method=method,
                                         data=json.dumps(body).encode() if body is not None else None, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            raise RuntimeError(f"{method} {path} -> {error.code} {error.read().decode()[:200]}") from error

    def token(self, role: str) -> str:
        if role not in self.tokens:
            self.tokens[role] = self.call(None, "POST", "/auth/otp/verify",
                                          {"phone": PHONES[role], "otp": "123456"})["access_token"]
        return self.tokens[role]

    def check(self, step: str, ok: bool, detail: str) -> None:
        print(f"  [{'PASS' if ok else 'FAIL'}] {step}: {detail}")
        self.failures += 0 if ok else 1


def run() -> int:
    demo = Demo()
    data = get_shared_data()
    villages = {v["code"]: v for b in data.geo["blocks"] for v in b["villages"]}
    home = villages[data.geo["demo_cluster_villages"][0]]

    # 1-2. Pashu sevak reports an LSD-like cow while offline; the phone's triage is sent along.
    report = {"client_uuid": str(uuid.uuid4()), "location": {"lat": home["lat"], "lng": home["lng"]},
              "species": "cattle", "symptoms": ["skin_nodules", "fever"], "sick_count": 2, "dead_count": 0,
              "total_at_risk": 8, "voice_transcript": "गाय के शरीर पर गांठें हैं, बुखार है, दो गाय बीमार हैं",
              "device_triage": {"engine_version": "rules-1", "top": "lsd", "score": 0.503},
              "created_on_device_at": datetime.now(UTC).isoformat(), "channel": "app"}
    # 3. Sync: the outbox pushes it; a retry must not duplicate it.
    first = demo.call("sevak", "POST", "/sync/push", {"reports": [report]})["results"][0]
    again = demo.call("sevak", "POST", "/sync/push", {"reports": [report]})["results"][0]
    demo.check("3 sync", first["status"] == "created" and again["status"] == "duplicate",
               f"first {first['status']}, retry {again['status']}")
    case = demo.call("officer", "GET", f"/cases/{first['case_id']}")
    demo.check("3 case on officer side", case["suspected_disease"] == "lsd" and not case["triage"]["triage_mismatch"],
               f"suspected {case['suspected_disease']}, severity {case['severity']}, phone and server agree")

    # 4. Outbreak detection.
    simulator.run(type("Args", (), {"seed": 7, "scenario": "lsd_outbreak", "speed": 0, "days": 0,
                                    "base_url": BASE})())
    alerts = [a for a in demo.call("officer", "GET", "/alerts") if a["type"] == "cluster"]
    demo.check("4 cluster alert", len(alerts) == 1, alerts[0]["explanation"]["summary"]["en"] if alerts else "none")
    alert = alerts[0]

    # 5. Response: acknowledge, assign the vet, advisory to 10 km; farmer reads it in Hindi.
    acked = demo.call("officer", "POST", f"/alerts/{alert['id']}/acknowledge")
    demo.check("5 acknowledge", acked["status"] == "acknowledged", acked["status"])
    vet = next(v for v in demo.call("officer", "GET", "/vets") if v["phone"] == PHONES["vet"])
    target_case = alert["case_ids"][0]
    assigned = demo.call("officer", "POST", f"/cases/{target_case}/assign", {"vet_id": vet["id"]})
    demo.check("5 assign vet", assigned["assigned_vet"]["name"] == vet["name"], assigned["status"])
    village_en = alert["explanation"]["village_names"][0]
    village_names = next(v["name"] for v in villages.values() if v["name"]["en"] == village_en)
    sent = demo.call("officer", "POST", "/advisories", {
        "template_id": "lsd_nearby", "center": alert["center"], "radius_km": 10, "variables": {"village": village_names}})
    inbox = demo.call("farmer", "GET", "/advisories/inbox")
    demo.check("5 advisory", sent["farmers"] > 0 and inbox and village_names["hi"] in inbox[0]["text"],
               f"reached {sent['farmers']} farmers; farmer reads: {inbox[0]['text'][:45]}...")

    # 6. Lab loop.
    sample = demo.call("vet", "POST", f"/cases/{target_case}/samples", {"sample_type": "skin_scab"})
    code = sample["qr_code"]
    collected = demo.call("sevak", "POST", f"/samples/{code}/scan")
    received = demo.call("lab", "POST", f"/samples/{code}/scan")
    resulted = demo.call("lab", "POST", f"/samples/{code}/result", {"result": "positive", "disease": "lsd"})
    demo.check("6 lab loop", (collected["status"], received["status"], resulted["status"]) == ("collected", "received", "resulted"),
               f"{code}: collected -> received -> positive for {resulted['result_disease']}")
    timeline = [e["to_status"] for e in demo.call("vet", "GET", f"/cases/{target_case}")["timeline"]]
    demo.check("6 timeline", timeline[-4:] == ["sample_requested", "sample_collected", "lab_received", "lab_result"],
               " > ".join(timeline))
    summary = demo.call("officer", "GET", "/dashboard/summary")
    demo.check("6 KPI", summary["median_minutes_to_first_response"] is not None,
               f"median first response {summary['median_minutes_to_first_response']} min over {summary['responses_counted']} cases")

    # 7. One Health.
    simulator.run(type("Args", (), {"seed": 7, "scenario": "anthrax_single", "speed": 0, "days": 0,
                                    "base_url": BASE})())
    zoonotic = [a for a in demo.call("officer", "GET", "/alerts") if a["type"] == "zoonotic"]
    demo.check("7 zoonotic alert", len(zoonotic) == 1 and zoonotic[0]["severity"] == "emergency",
               zoonotic[0]["explanation"]["summary"]["en"] if zoonotic else "none")

    # 8. Honesty screen data.
    meta = demo.call(None, "GET", "/meta/engine")
    demo.check("8 about the AI", len(meta["rules"]) == 6 and meta["image_model"] is not None,
               f"{meta['engine_version']}, 6 rules, image model: {meta['image_model']['model_version'] if meta['image_model'] else 'not trained yet'}")
    return demo.failures


def main() -> None:
    started = time.monotonic()
    failures = run()
    print(f"\nDemo check finished in {time.monotonic() - started:.0f} s: "
          f"{'ALL STEPS PASS' if failures == 0 else f'{failures} step(s) FAILED'}")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
