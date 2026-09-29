"""Seed the demo world (spec 8.10).

Run from the repo root:  make seed      (or: cd backend && uv run python -m scripts.seed)

What it creates, from shared/geo/demo_district.json and fixed random choices:
- Pune district, 13 talukas (blocks), 68 villages
- one demo user per role (phones 9000000001-5), a vet for every other block,
  and 40 farmers spread across villages so advisories have recipients
- ~60 herds and ~250 animals with 12-digit ear tags
- vaccinations with deliberately uneven coverage per block (30%-85%)
- 60 days of background reports through the real report service, with no
  active outbreak cluster at seed time

It wipes every app table first, and all ids and random choices are fixed,
so running it twice gives the same state. Weather cache seeding comes with
the risk score (Phase 10), which is the only feature that uses it.
"""

import random
import uuid
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import text
from sqlalchemy.orm import Session

import app.models  # noqa: F401  (registers tables)
from app.core.db import Base, SessionLocal
from app.core.shared_loader import SharedData, get_shared_data
from app.models import Animal, Block, District, Herd, User, Vaccination, Village
from app.schemas.reports import ReportIn
from app.services.cases import assign_vet, change_status
from app.services.geo_utils import make_point
from app.services.reports import ingest_report
from app.services.triage.rule_engine import TriageInput, evaluate

NAMESPACE = uuid.UUID("7d3c1b2a-5e4f-4a6b-9c8d-0e1f2a3b4c5d")
IST = ZoneInfo("Asia/Kolkata")
HISTORY_DAYS = 60
QUIET_WINDOW_DAYS = 14          # the clustering window: keep it free of clusters
OLD_REPORTS = 48
RECENT_REPORTS = 6
FARMER_COUNT = 40

DEMO_USERS = [
    # role, phone, name, language
    ("farmer", "9000000001", "Ramesh Gaikwad", "hi"),
    ("pashu_sevak", "9000000002", "Sunita Pawar", "hi"),
    ("vet", "9000000003", "Dr. Anil Deshmukh", "en"),
    ("lab", "9000000004", "Priya Kulkarni", "en"),
    ("district_officer", "9000000005", "Dr. Meera Joshi", "en"),
]
DEMO_BLOCK = "junnar"
FIRST_NAMES = ["Sanjay", "Vitthal", "Rahul", "Ganesh", "Dattatray", "Santosh", "Bhausaheb", "Nitin", "Suresh",
               "Balasaheb", "Anita", "Savita", "Mangal", "Shobha", "Kavita", "Manisha", "Sunil", "Prakash",
               "Dnyaneshwar", "Tukaram"]
SURNAMES = ["Shinde", "Jadhav", "Kale", "Bhosale", "Kadam", "Waghmare", "Gawade", "Thorat", "Salunkhe",
            "Kharat", "Dhumal", "Borate", "Gaikwad", "Mane", "Ghule", "Lokhande"]
VET_NAMES = ["Dr. Vijay Patil", "Dr. Snehal Kamble", "Dr. Rajesh More", "Dr. Pooja Sawant", "Dr. Amol Chavan",
             "Dr. Kiran Nikam", "Dr. Swati Pingale", "Dr. Mahesh Kokate", "Dr. Rupali Zende",
             "Dr. Sachin Darade", "Dr. Varsha Holkar", "Dr. Hemant Bankar"]
COW_NAMES = ["Gauri", "Laxmi", "Kapila", "Nandini", "Ganga", "Radha", "Sundari", "Heera", "Tulsi", "Shyama"]
BUFFALO_NAMES = ["Moti", "Rani", "Kali", "Champa", "Bijli", "Sheru"]
BREEDS = {"cattle": ["Gir", "Sahiwal", "HF cross", "Khillar", "Dangi", "Red Kandhari", "Jersey cross"],
          "buffalo": ["Murrah", "Pandharpuri", "Jafarabadi"],
          "goat": ["Osmanabadi", "Sangamneri", "Berari"]}


def sid(*parts: object) -> uuid.UUID:
    """Stable id, so a re-seed gives every row the same id."""
    return uuid.uuid5(NAMESPACE, ":".join(str(p) for p in parts))


def wipe(db: Session) -> None:
    tables = ", ".join(t.name for t in Base.metadata.sorted_tables)
    db.execute(text(f"TRUNCATE TABLE {tables} RESTART IDENTITY CASCADE"))


def seed_geography(db: Session, data: SharedData) -> dict[str, Village]:
    geo = data.geo
    district = District(id=sid("district", geo["district"]["code"]), code=geo["district"]["code"],
                        name=geo["district"]["name"],
                        centroid=make_point(geo["district"]["centroid"]["lat"], geo["district"]["centroid"]["lng"]))
    db.add(district)
    db.flush()  # parents first: there are no ORM relationships to order inserts
    villages = {}
    for block_data in geo["blocks"]:
        centre = block_data["hq"] or block_data["centroid"]
        block = Block(id=sid("block", block_data["code"]), code=block_data["code"], name=block_data["name"],
                      district_id=district.id, centroid=make_point(centre["lat"], centre["lng"]))
        db.add(block)
        db.flush()
        for v in block_data["villages"]:
            village = Village(id=sid("village", v["code"]), code=v["code"], name=v["name"], block_id=block.id,
                              centroid=make_point(v["lat"], v["lng"]))
            db.add(village)
            villages[v["code"]] = village
    db.flush()
    return villages


def seed_users(db: Session, data: SharedData, villages: dict[str, Village], rng: random.Random) -> dict:
    district_id = sid("district", data.geo["district"]["code"])
    demo_village = villages[data.geo["demo_cluster_villages"][0]]
    demo_block_id = sid("block", DEMO_BLOCK)
    users = {}
    for role, phone, name, language in DEMO_USERS:
        users[role] = User(
            id=sid("user", phone), phone=phone, name=name, role=role, language=language,
            district_id=district_id,
            village_id=demo_village.id if role in ("farmer", "pashu_sevak") else None,
            block_id=demo_block_id if role in ("farmer", "pashu_sevak", "vet") else None)
    other_blocks = [b["code"] for b in data.geo["blocks"] if b["code"] != DEMO_BLOCK]
    users["block_vets"] = {DEMO_BLOCK: users["vet"]}
    for index, (block_code, name) in enumerate(zip(other_blocks, VET_NAMES)):
        phone = f"90000003{index + 10:02d}"
        users["block_vets"][block_code] = User(
            id=sid("user", phone), phone=phone, name=name, role="vet", language="en",
            district_id=district_id, block_id=sid("block", block_code))
    village_list = sorted(villages.values(), key=lambda v: v.code)
    users["farmers"] = [users["farmer"]]
    for index in range(FARMER_COUNT):
        village = village_list[(index * 7) % len(village_list)]  # spread over all talukas
        phone = f"9000001{index:03d}"
        users["farmers"].append(User(
            id=sid("user", phone), phone=phone, name=f"{rng.choice(FIRST_NAMES)} {rng.choice(SURNAMES)}",
            role="farmer", language=rng.choice(["mr", "mr", "mr", "hi", "hi"]), district_id=district_id,
            block_id=village.block_id, village_id=village.id))
    db.add_all([u for key, u in users.items() if key not in ("block_vets", "farmers")])
    db.flush()
    db.add_all([u for code, u in users["block_vets"].items() if code != DEMO_BLOCK])
    db.add_all(users["farmers"][1:])
    db.flush()
    return users


def jitter(village: Village, rng: random.Random, km: float = 1.2) -> tuple[float, float]:
    from app.services.geo_utils import point_latlng
    centre = point_latlng(village.centroid)
    # ~0.009 degrees of latitude per km: herds sit around the village, not on one pin.
    return (centre["lat"] + rng.uniform(-km, km) * 0.009, centre["lng"] + rng.uniform(-km, km) * 0.0095)


def ear_tag(rng: random.Random, used: set[str]) -> str:
    while True:
        tag = str(rng.randint(10**11, 10**12 - 1))
        if tag not in used:
            used.add(tag)
            return tag


def seed_herds(db: Session, users: dict, villages_by_id: dict, rng: random.Random) -> list[dict]:
    herds, used_tags = [], set()
    for farmer in users["farmers"]:
        herd_count = 2 if farmer is users["farmer"] or rng.random() < 0.45 else 1
        for number in range(herd_count):
            kind = "dairy" if number == 0 or rng.random() < 0.6 else rng.choice(["goat", "goat", "poultry"])
            village = villages_by_id[farmer.village_id]
            lat, lng = jitter(village, rng)
            surname = farmer.name.split()[-1]
            herd = Herd(id=sid("herd", farmer.phone, number), owner_user_id=farmer.id, village_id=village.id,
                        location=make_point(lat, lng),
                        name={"dairy": f"{surname} gotha", "goat": f"{surname} goats",
                              "poultry": f"{surname} poultry"}[kind])
            db.add(herd)
            db.flush()
            animals = []
            if kind == "dairy":
                for index in range(rng.randint(3, 6)):
                    species = "cattle" if rng.random() < 0.62 else "buffalo"
                    names = COW_NAMES if species == "cattle" else BUFFALO_NAMES
                    animals.append(Animal(
                        id=sid("animal", herd.id, index), herd_id=herd.id, species=species,
                        ear_tag=ear_tag(rng, used_tags), breed=rng.choice(BREEDS[species]),
                        sex="female" if rng.random() < 0.85 else "male",
                        age_months=rng.randint(10, 120), name=rng.choice(names)))
            elif kind == "goat":
                for index in range(rng.randint(4, 8)):
                    animals.append(Animal(
                        id=sid("animal", herd.id, index), herd_id=herd.id, species="goat",
                        ear_tag=ear_tag(rng, used_tags) if rng.random() < 0.5 else None,
                        breed=rng.choice(BREEDS["goat"]), sex=rng.choice(["female", "male"]),
                        age_months=rng.randint(4, 60)))
            # Poultry flocks are recorded as a herd without individual birds.
            db.add_all(animals)
            herds.append({"herd": herd, "kind": kind, "animals": animals, "owner": farmer, "village": village})
    # The demo farmer's first cow is "Gauri", with her FMD shot due soon (spec wireframe).
    demo_first = herds[0]["animals"][0]
    demo_first.species, demo_first.name, demo_first.breed = "cattle", "Gauri", "Gir"
    db.flush()
    return herds


def seed_vaccinations(db: Session, herds: list[dict], data: SharedData, users: dict, rng: random.Random,
                      today: date) -> None:
    block_codes = [b["code"] for b in data.geo["blocks"]]
    shuffled = block_codes[:]
    rng.shuffle(shuffled)
    # Coverage from 30% to 85%, spread across blocks so the risk view has contrast.
    coverage = {code: 0.30 + 0.55 * i / (len(shuffled) - 1) for i, code in enumerate(shuffled)}
    code_by_block_id = {sid("block", c): c for c in block_codes}
    count = 0
    for entry in herds:
        share = coverage[code_by_block_id[entry["village"].block_id]]
        for animal in entry["animals"]:
            for vaccine, species, interval_days in (("FMD", ("cattle", "buffalo"), 180),
                                                    ("HS", ("cattle", "buffalo"), 365),
                                                    ("LSD", ("cattle", "buffalo"), 365),
                                                    ("PPR", ("goat",), 1095)):
                if animal.species in species and rng.random() < share:
                    given = today - timedelta(days=rng.randint(15, interval_days - 5))
                    db.add(Vaccination(id=sid("vaccination", animal.id, vaccine), animal_id=animal.id,
                                       herd_id=animal.herd_id, vaccine=vaccine, given_on=given,
                                       next_due_on=given + timedelta(days=interval_days),
                                       given_by=users["pashu_sevak"].id))
                    count += 1
    gauri = herds[0]["animals"][0]
    db.add(Vaccination(id=sid("vaccination", gauri.id, "FMD-demo"), animal_id=gauri.id, herd_id=gauri.herd_id,
                       vaccine="FMD", given_on=today - timedelta(days=167), next_due_on=today + timedelta(days=13),
                       given_by=users["pashu_sevak"].id))
    db.flush()


def symptoms_for(entry: dict, data: SharedData, rng: random.Random) -> tuple[str, list[str]]:
    """Plausible background signs: mild general illness, or a partial disease picture."""
    species = rng.choice(entry["animals"]).species if entry["animals"] else "poultry"
    available = [s for s in data.symptoms.values() if species in s["species"]]
    general = [s["id"] for s in available if s["syndrome"] == "general"]
    # Anthrax and bird flu stay out of background noise: they are demo scenarios.
    rules = [r for r in data.rules_in_order if species in r["species"] and r["id"] not in ("anthrax", "hpai")]
    if not rules or rng.random() < 0.45:
        return species, rng.sample(general, k=min(len(general), rng.randint(1, 2)))
    rule = rng.choice(rules)
    chosen = {rng.choice(group) for group in rule["required"] if rng.random() < 0.8}
    shown = {s["id"] for s in available}
    chosen |= {s for s in rule["signs"] if s in shown and rng.random() < 0.35}
    return species, sorted(chosen or {rng.choice(general)})


def history_plan(herds: list[dict], data: SharedData, rng: random.Random, today: date) -> list[tuple]:
    """(days_ago, herd entry) pairs: many old reports, few recent ones in far-apart blocks."""
    plan = [(rng.randint(QUIET_WINDOW_DAYS + 1, HISTORY_DAYS), rng.choice(herds)) for _ in range(OLD_REPORTS)]
    recent_blocks, used_syndromes = set(), set()
    for entry in rng.sample(herds, len(herds)):
        block = entry["village"].block_id
        if block in recent_blocks or block == sid("block", DEMO_BLOCK):
            continue  # keep Junnar quiet for the live outbreak demo
        recent_blocks.add(block)
        plan.append((rng.randint(1, QUIET_WINDOW_DAYS), entry))
        if len(recent_blocks) == RECENT_REPORTS:
            break
    return sorted(plan, key=lambda item: -item[0])


def seed_history(db: Session, data: SharedData, herds: list[dict], users: dict, rng: random.Random,
                 today: date) -> int:
    count = 0
    for index, (days_ago, entry) in enumerate(history_plan(herds, data, rng, today)):
        species, symptoms = symptoms_for(entry, data, rng)
        local = datetime.combine(today - timedelta(days=days_ago), time(rng.randint(7, 18), rng.randint(0, 59)), IST)
        sent_at = local.astimezone(UTC)
        sick = rng.randint(1, 2)
        herd_size = max(len(entry["animals"]), sick + 1) if entry["animals"] else rng.randint(40, 200)
        device = evaluate(data, TriageInput(species, frozenset(symptoms), sick, 0, herd_size, local.month))
        lat, lng = jitter(entry["village"], rng, km=0.8)
        payload = ReportIn(
            client_uuid=sid("history-report", index), village_id=entry["village"].id,
            location={"lat": lat, "lng": lng}, species=species, symptoms=symptoms, sick_count=sick,
            dead_count=0, total_at_risk=herd_size, onset_date=local.date() - timedelta(days=rng.randint(0, 2)),
            herd_id=entry["herd"].id, created_on_device_at=sent_at,
            device_triage={"engine_version": device["engine_version"],
                           "top": device["candidates"][0]["disease_id"] if device["candidates"] else None,
                           "score": device["candidates"][0]["score"] if device["candidates"] else 0.0})
        _, _, case = ingest_report(db, data, entry["owner"], payload, received_at=sent_at + timedelta(minutes=3))
        progress_case(db, case, users, entry, rng, sent_at, days_ago)
        count += 1
    return count


def progress_case(db: Session, case, users: dict, entry: dict, rng: random.Random, sent_at: datetime,
                  days_ago: int) -> None:
    """Old cases were handled and closed; recent ones are still open, some waiting for a vet."""
    if case.status != "triaged":
        return  # a follow-up report on a case that is already moving
    block_code = next(c for c, v in users["block_vets"].items() if v.block_id == entry["village"].block_id)
    vet = users["block_vets"][block_code]
    if days_ago <= QUIET_WINDOW_DAYS and rng.random() < 0.5:
        return
    assigned_at = sent_at + timedelta(hours=rng.randint(2, 30))
    assign_vet(db, case, vet, vet, at=assigned_at)
    if days_ago <= QUIET_WINDOW_DAYS:
        return
    treated_at = assigned_at + timedelta(hours=rng.randint(3, 24))
    if case.suspected_disease is None and rng.random() < 0.5:
        change_status(db, case, "closed_ruled_out", vet, "Minor illness, no notifiable disease", treated_at)
        return
    change_status(db, case, "under_treatment", vet, "Treatment started", treated_at)
    change_status(db, case, "resolved", vet, "Animal recovered", treated_at + timedelta(days=rng.randint(3, 9)))


def run(db: Session, today: date | None = None) -> dict:
    today = today or datetime.now(IST).date()
    data = get_shared_data()
    rng = random.Random(42)
    wipe(db)
    villages = seed_geography(db, data)
    users = seed_users(db, data, villages, rng)
    herds = seed_herds(db, users, {v.id: v for v in villages.values()}, rng)
    seed_vaccinations(db, herds, data, users, rng, today)
    reports = seed_history(db, data, herds, users, rng, today)
    db.commit()
    return {"villages": len(villages), "farmers": len(users["farmers"]), "herds": len(herds),
            "animals": sum(len(h["animals"]) for h in herds), "history_reports": reports}


def main() -> None:
    with SessionLocal() as db:
        summary = run(db)
    print("Seeded: " + ", ".join(f"{k} {v}" for k, v in summary.items()))
    print("Demo logins (OTP 123456): " + ", ".join(f"{role} {phone}" for role, phone, _, _ in DEMO_USERS))


if __name__ == "__main__":
    main()
