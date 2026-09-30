"""Drive demo scenarios through the real API (spec 8.7).

Run from the repo root:
    make simulate SCENARIO=lsd_outbreak SPEED=5
or from backend/:
    uv run python -m scripts.simulator --scenario lsd_outbreak --speed 5
    uv run python -m scripts.simulator --scenario anthrax_single
    uv run python -m scripts.simulator --scenario hs_monsoon
    uv run python -m scripts.simulator --scenario background --days 60
    uv run python -m scripts.simulator --reset            # wipe reports, cases, alerts

It logs in as the seeded pashu sevak and posts reports exactly like the
phone does, so triage, cases, clustering and alerts all run for real.
Reports are back-dated to spread an outbreak over several days; --speed is
the real pause in seconds between posts, so the audience sees them arrive.
"""

import argparse
import json
import random
import time
import urllib.error
import urllib.request
import uuid
from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import text

from app.core.db import SessionLocal
from app.core.shared_loader import get_shared_data

IST = ZoneInfo("Asia/Kolkata")
SEVAK_PHONE = "9000000002"
OFFICER_PHONE = "9000000005"
DEMO_OTP = "123456"

# Tables holding activity; users, herds, animals, vaccinations and geography stay.
ACTIVITY_TABLES = ["advisory_recipients", "advisories", "alerts", "lab_samples", "case_events",
                   "case_reports", "triage_results", "cases", "reports"]


class Api:
    def __init__(self, base_url: str):
        self.base = base_url.rstrip("/") + "/api/v1"
        self.token: str | None = None

    def call(self, method: str, path: str, body: dict | None = None):
        request = urllib.request.Request(
            self.base + path, method=method, data=json.dumps(body).encode() if body is not None else None,
            headers={"Content-Type": "application/json",
                     **({"Authorization": f"Bearer {self.token}"} if self.token else {})})
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            raise SystemExit(f"{method} {path} failed: {error.code} {error.read().decode()}") from error
        except urllib.error.URLError as error:
            raise SystemExit(f"Cannot reach the API at {self.base} ({error.reason}). Is `make api` running?") from error

    def login(self, phone: str) -> "Api":
        self.token = self.call("POST", "/auth/otp/verify", {"phone": phone, "otp": DEMO_OTP})["access_token"]
        return self


def villages_by_code() -> dict[str, dict]:
    geo = get_shared_data().geo
    return {v["code"]: {**v, "block": b["name"]["en"]} for b in geo["blocks"] for v in b["villages"]}


def near(village: dict, rng: random.Random, km: float = 0.3) -> dict:
    # Reports come from farms around the village, not all from one pin. The
    # demo villages are ~1.2 km apart, so the spread stays small enough that
    # each report still belongs to its own village.
    return {"lat": round(village["lat"] + rng.uniform(-km, km) * 0.009, 6),
            "lng": round(village["lng"] + rng.uniform(-km, km) * 0.0095, 6)}


def report(village: dict, rng: random.Random, species: str, symptoms: list[str], sick: int, dead: int,
           days_ago: float, total: int | None = None) -> dict:
    sent = datetime.now(UTC) - timedelta(days=days_ago)
    return {
        "client_uuid": str(uuid.uuid4()), "location": near(village, rng), "species": species,
        "symptoms": symptoms, "sick_count": sick, "dead_count": dead, "total_at_risk": total,
        "onset_date": (sent.astimezone(IST).date() - timedelta(days=1)).isoformat(),
        "created_on_device_at": sent.astimezone(IST).isoformat(timespec="seconds"), "channel": "app",
    }


# ---------- scenarios: each returns the list of reports to post, in order ----------

def lsd_outbreak(rng: random.Random, _: argparse.Namespace) -> list[dict]:
    """Starts in one village and spreads to 2 neighbours over 4 calendar days (6 reports)."""
    villages = villages_by_code()
    cluster = [villages[code] for code in get_shared_data().geo["demo_cluster_villages"][:3]]
    extras = ["fever", "enlarged_lymph_nodes", "limb_oedema", "drop_in_milk", "anorexia", "nasal_discharge"]
    plan = [(0, 3.0), (0, 2.9), (1, 2.0), (0, 1.1), (2, 0.9), (1, 0.05)]  # (village index, days ago)
    reports = []
    for village_index, days_ago in plan:
        # Not every report has every sign; lumps are the common thread.
        signs = ["skin_nodules", *rng.sample(extras, k=rng.randint(1, 3))]
        species = "cattle" if rng.random() < 0.75 else "buffalo"
        reports.append(report(cluster[village_index], rng, species, sorted(set(signs)), rng.randint(1, 3), 0,
                              days_ago, total=rng.randint(6, 15)))
    return reports


def anthrax_single(rng: random.Random, _: argparse.Namespace) -> list[dict]:
    """One sudden death with bleeding, far from the LSD demo area."""
    village = villages_by_code()[_first_village_in("shirur")]
    return [report(village, rng, "cattle",
                   ["absence_of_rigor_mortis", "bleeding_from_orifices", "sudden_death"], 0, 1, 0.05, total=8)]


def hs_monsoon(rng: random.Random, _: argparse.Namespace) -> list[dict]:
    """Scattered throat-swelling cases in buffalo across low-lying Bhima-basin talukas."""
    villages = [villages_by_code()[_first_village_in(block)] for block in ("daund", "indapur", "haveli", "baramati")]
    return [report(v, rng, "buffalo", sorted({"throat_swelling", "fever", *rng.sample(
        ["difficulty_breathing", "excessive_salivation", "nasal_discharge"], k=rng.randint(1, 2))}),
                   rng.randint(1, 2), 0, days_ago, total=rng.randint(4, 10))
            for v, days_ago in zip(villages, (5.5, 3.2, 2.1, 0.6))]


def background(rng: random.Random, args: argparse.Namespace) -> list[dict]:
    """Low-rate noise across all villages and signs, spread over --days."""
    data = get_shared_data()
    villages = list(villages_by_code().values())
    reports = []
    for day in range(args.days):
        if rng.random() > 0.6:
            continue
        village = rng.choice(villages)
        species = rng.choice(["cattle", "cattle", "buffalo", "goat"])
        shown = [s for s, v in data.symptoms.items() if species in v["species"]]
        reports.append(report(village, rng, species, rng.sample(shown, k=rng.randint(1, 2)), 1, 0,
                              day + rng.random(), total=rng.randint(3, 12)))
    return sorted(reports, key=lambda r: r["created_on_device_at"])


def _first_village_in(block_code: str) -> str:
    block = next(b for b in get_shared_data().geo["blocks"] if b["code"] == block_code)
    return block["villages"][0]["code"]


SCENARIOS = {"lsd_outbreak": lsd_outbreak, "anthrax_single": anthrax_single,
             "hs_monsoon": hs_monsoon, "background": background}


def reset() -> None:
    with SessionLocal() as db:
        db.execute(text(f"TRUNCATE TABLE {', '.join(ACTIVITY_TABLES)} RESTART IDENTITY CASCADE"))
        db.commit()
    print("Reset: reports, cases, alerts, samples and advisories wiped; users and geography kept.")


def disease_label(triage: dict) -> str:
    candidates = triage.get("candidates") or []
    if not candidates or candidates[0]["score"] < 0.4:
        return "unclear"
    return f"{candidates[0]['disease_id'].upper()}-like"


def run(args: argparse.Namespace) -> None:
    rng = random.Random(args.seed)
    api = Api(args.base_url).login(SEVAK_PHONE)
    reports = SCENARIOS[args.scenario](rng, args)
    started = time.monotonic()
    print(f"Scenario {args.scenario}: posting {len(reports)} reports as the pashu sevak ({SEVAK_PHONE})")
    for index, payload in enumerate(reports):
        if index and args.speed:
            time.sleep(args.speed)
        result = api.call("POST", "/reports", payload)
        village = api.call("GET", f"/geo/villages?near={payload['location']['lat']},{payload['location']['lng']}&limit=1")[0]
        triage = result["triage"]
        print(f"[t+{time.monotonic() - started:4.0f}s] report {disease_label(triage):<12} {village['name']['en']:<22} "
              f"sick={payload['sick_count']} dead={payload['dead_count']} -> case #{result['case_id'][:6]} "
              f"({triage['severity']})")
    officer = Api(args.base_url).login(OFFICER_PHONE)
    alerts = officer.call("GET", "/alerts")
    print(f"\nOpen alerts in the district: {len(alerts)}")
    for alert in alerts:
        print(f"  [{alert['severity']:<9}] {alert['type']:<9} {alert['explanation']['summary']['en']}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--scenario", choices=sorted(SCENARIOS))
    parser.add_argument("--speed", type=float, default=2, help="seconds to wait between reports (0 = no wait)")
    parser.add_argument("--days", type=int, default=60, help="background: how many days back to spread reports")
    parser.add_argument("--reset", action="store_true", help="wipe reports, cases and alerts first")
    parser.add_argument("--seed", type=int, default=7, help="random seed, for a repeatable run")
    # 127.0.0.1, not localhost: on Windows "localhost" tries IPv6 first and waits ~2 s per request.
    parser.add_argument("--base-url", default="http://127.0.0.1:8000")
    args = parser.parse_args()
    if not args.reset and not args.scenario:
        parser.error("give --scenario, --reset, or both")
    if args.reset:
        reset()
    if args.scenario:
        run(args)


if __name__ == "__main__":
    main()
