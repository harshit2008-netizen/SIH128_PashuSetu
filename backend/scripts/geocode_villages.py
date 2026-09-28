"""Build shared/geo/demo_district.json from real OpenStreetMap data.

Run from backend/:  uv run python -m scripts.geocode_villages

Why a script: the spec forbids real village names with made-up coordinates.
Instead of guessing village names, we ask the OSM Overpass API for the
village nodes that really lie inside each taluka boundary, then pick a few
per taluka with a fixed, repeatable rule. Coordinates always come from OSM.
Devanagari names come from OSM (name:mr) when mapped; OSM rarely has them
for rural Pune, so otherwise we use our own spelling from
DEVANAGARI_FALLBACK, marked name_source "transliterated". All names stay
flagged for native review.

Add --refresh to download again instead of using backend/.cache.

Selection rule:
- Junnar: the tightest real group of villages (all within a few km) so the
  LSD outbreak demo can form a real 5 km DBSCAN cluster, plus a few villages
  spread across the taluka.
- Other talukas: villages at least MIN_SPACING_KM apart, so background noise
  reports do not form accidental clusters at seed time.
"""

import json
import math
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import date

from app.core.config import BACKEND_DIR, SHARED_DIR

CACHE_PATH = BACKEND_DIR / ".cache" / "osm_pune_talukas.json"

# Devanagari spellings for villages that have no name:mr in OSM. Written by
# us from the English name, so each is marked name_source "transliterated"
# and must be checked by a Marathi speaker.
DEVANAGARI_FALLBACK: dict[str, str] = {
    "Ambegaon": "आंबेगाव", "Ambeghar": "आंबेघर", "Babhulsar Budruk": "बाभुळसर बुद्रुक",
    "Boratwadi": "बोराटवाडी", "Dadndavarchiwadi": "दांडावरचीवाडी", "Dalaj No. 3": "डाळज नं. ३",
    "Gar": "गार", "Garewadi": "गारेवाडी", "Ghodegaon": "घोडेगाव", "Gudhe": "गुढे",
    "Gunjavane": "गुंजवणे", "Inamgaon": "इनामगाव", "Karanavdi": "करनवडी", "Khairenagar": "खैरेनगर",
    "Khanu": "खानू", "Kolharwadi": "कोल्हारवाडी", "Kondhval": "कोंढवळ", "Kurkumb": "कुरकुंभ",
    "Late": "लाटे", "Nandur": "नांदूर", "Nimsakhar": "निमसाखर", "Nivi": "निवी",
    "Parwadi": "पारवडी", "Penjalwadi": "पेंजळवाडी", "Pole": "पोळे", "Rayri": "रायरी",
    "Reda": "रेडा", "Taleran": "तळेरान", "Tannu": "तन्नू", "Vasaiwadi": "वसईवाडी", "Yavat": "यवत",
}

# Public Overpass servers are often busy (HTTP 429/504), so try mirrors in turn.
OVERPASS_URLS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]
ATTEMPTS_PER_QUERY = 6
USER_AGENT = "PashuSetu-SIH2026-seed/0.1 (student hackathon demo data)"
SECONDS_BETWEEN_REQUESTS = 2.0

VILLAGES_PER_BLOCK = 5
MIN_SPACING_KM = 6.0
DEMO_CLUSTER_SIZE = 4           # seed village + its nearest neighbours
DEMO_CLUSTER_MAX_KM = 5.0       # every cluster village within this of the seed
JUNNAR_SPREAD_VILLAGES = 4

DISTRICT = {"code": "pune", "name": {"en": "Pune", "hi": "पुणे", "mr": "पुणे"}, "state": "Maharashtra"}

# OSM relation ids of the rural talukas of Pune district (admin_level 6).
# Pune City taluka is left out: it is urban and has almost no livestock.
# `hq` is the taluka headquarters as named in OSM.
BLOCKS = [
    {"code": "junnar", "osm_relation": 10351631, "en": "Junnar", "hq": "Junnar"},
    {"code": "ambegaon", "osm_relation": 10351630, "en": "Ambegaon", "hq": "Ghodegaon"},
    {"code": "khed", "osm_relation": 10351629, "en": "Khed", "hq": "Rajgurunagar"},
    {"code": "shirur", "osm_relation": 10351619, "en": "Shirur", "hq": "Shirur"},
    {"code": "maval", "osm_relation": 10351628, "en": "Maval", "hq": "Vadgaon"},
    {"code": "mulshi", "osm_relation": 10351625, "en": "Mulshi", "hq": "Paud"},
    {"code": "haveli", "osm_relation": 10351627, "en": "Haveli", "hq": None},
    {"code": "daund", "osm_relation": 10351620, "en": "Daund", "hq": "Daund"},
    {"code": "purandar", "osm_relation": 10351622, "en": "Purandar", "hq": "Saswad"},
    {"code": "velhe", "osm_relation": 10351624, "en": "Velhe", "hq": "Velhe"},
    {"code": "bhor", "osm_relation": 10351623, "en": "Bhor", "hq": "Bhor"},
    {"code": "baramati", "osm_relation": 10351621, "en": "Baramati", "hq": "Baramati"},
    {"code": "indapur", "osm_relation": 10351618, "en": "Indapur", "hq": "Indapur"},
]


def overpass(query: str) -> dict:
    data = urllib.parse.urlencode({"data": query}).encode()
    for attempt in range(ATTEMPTS_PER_QUERY):
        url = OVERPASS_URLS[attempt % len(OVERPASS_URLS)]
        request = urllib.request.Request(url, data=data, headers={"User-Agent": USER_AGENT})
        try:
            with urllib.request.urlopen(request, timeout=960) as response:
                result = json.load(response)
            time.sleep(SECONDS_BETWEEN_REQUESTS)
            return result
        except (urllib.error.URLError, TimeoutError) as exc:
            wait = 5 * (attempt + 1)
            print(f"  {url} failed ({exc}); retrying in {wait}s")
            time.sleep(wait)
    raise SystemExit("All Overpass servers failed; try again later")


def fetch_all_blocks(refresh: bool) -> dict[int, tuple[dict, list[dict]]]:
    """Return {relation id: (taluka relation with center, its village/town nodes)}.

    One Overpass request covers all talukas (public servers are slow, so 13
    separate requests took far too long). The raw answer is cached in
    backend/.cache so reruns, e.g. after adding a Devanagari spelling, are
    instant and do not load the free servers again.
    """
    if CACHE_PATH.exists() and not refresh:
        raw = json.loads(CACHE_PATH.read_text(encoding="utf-8"))
    else:
        ids = ",".join(str(block["osm_relation"]) for block in BLOCKS)
        raw = overpass(f"""[out:json][timeout:900];
rel(id:{ids}); out tags center;
map_to_area->.talukas;
foreach.talukas->.t(
  .t out ids;
  node(area.t)["place"~"^(village|town)$"]["name"]; out;
);""")
        CACHE_PATH.parent.mkdir(exist_ok=True)
        CACHE_PATH.write_text(json.dumps(raw, ensure_ascii=False), encoding="utf-8", newline="\n")

    relations = {e["id"]: e for e in raw["elements"] if e["type"] == "relation"}
    nodes_by_relation: dict[int, list[dict]] = {rel_id: [] for rel_id in relations}
    current = None
    # Output order is: all relations, then each area followed by its nodes.
    for element in raw["elements"]:
        if element["type"] == "area":
            current = element["id"] - 3600000000
        elif element["type"] == "node" and current is not None:
            nodes_by_relation[current].append(element)
    return {rel_id: (relations[rel_id], nodes_by_relation[rel_id]) for rel_id in relations}


def haversine_km(a: dict, b: dict) -> float:
    lat1, lng1, lat2, lng2 = map(math.radians, (a["lat"], a["lng"], b["lat"], b["lng"]))
    h = (math.sin((lat2 - lat1) / 2) ** 2
         + math.cos(lat1) * math.cos(lat2) * math.sin((lng2 - lng1) / 2) ** 2)
    return 2 * 6371.0 * math.asin(math.sqrt(h))


def english_name(node: dict) -> str:
    tags = node["tags"]
    return tags.get("name:en") or tags["name"]


def to_place(node: dict, block_code: str) -> dict:
    tags = node["tags"]
    english = english_name(node)
    marathi = tags.get("name:mr") or DEVANAGARI_FALLBACK.get(english)
    return {
        "code": f"{block_code}_{re.sub(r'[^a-z0-9]+', '_', english.lower()).strip('_')}",
        "name": {"en": english, "hi": tags.get("name:hi") or marathi, "mr": marathi},
        "name_source": "osm" if tags.get("name:mr") else "transliterated",
        "lat": round(node["lat"], 5),
        "lng": round(node["lon"], 5),
        "osm": f"node/{node['id']}",
    }


def is_usable_village(node: dict) -> bool:
    # Needs a plain English name; Devanagari comes from OSM or DEVANAGARI_FALLBACK.
    return node["tags"].get("place") == "village" and english_name(node).isascii()


def pick_spread(candidates: list[dict], count: int, avoid: list[dict]) -> list[dict]:
    """Greedy pick in a fixed order, keeping MIN_SPACING_KM between villages.

    Villages whose Marathi name is in OSM come first, so fewer names depend
    on our own transliteration.
    """
    chosen: list[dict] = []
    for place in sorted(candidates, key=lambda p: (p["name_source"] != "osm", p["osm"])):
        if all(haversine_km(place, other) >= MIN_SPACING_KM for other in chosen + avoid):
            chosen.append(place)
        if len(chosen) == count:
            break
    return chosen


def nearest_neighbours(seed: dict, candidates: list[dict], count: int) -> list[dict]:
    others = [p for p in candidates if p is not seed]
    return sorted(others, key=lambda p: (haversine_km(seed, p), p["osm"]))[:count]


def pick_demo_cluster(candidates: list[dict]) -> list[dict]:
    """The tightest real group of villages: seed + its nearest neighbours.

    OSM maps Junnar sparsely, so instead of naming a seed village we pick the
    one whose (DEMO_CLUSTER_SIZE - 1) nearest neighbours are closest.
    """
    def spread(seed: dict) -> float:
        farthest = nearest_neighbours(seed, candidates, DEMO_CLUSTER_SIZE - 1)[-1]
        return haversine_km(seed, farthest)

    seed = min(candidates, key=lambda p: (spread(p), p["osm"]))
    if spread(seed) > DEMO_CLUSTER_MAX_KM:
        raise SystemExit(f"No group of {DEMO_CLUSTER_SIZE} villages within {DEMO_CLUSTER_MAX_KM} km in Junnar")
    return [seed] + nearest_neighbours(seed, candidates, DEMO_CLUSTER_SIZE - 1)


def find_hq(nodes: list[dict], hq_name: str | None, block_code: str) -> dict | None:
    if hq_name is None:
        return None
    for node in nodes:
        if english_name(node).lower().startswith(hq_name.lower()):
            place = to_place(node, block_code)
            return {"name": place["name"], "lat": place["lat"], "lng": place["lng"], "osm": place["osm"]}
    return None


def build_block(block: dict, relation: dict, nodes: list[dict]) -> tuple[dict, list[str]]:
    candidates = [to_place(n, block["code"]) for n in nodes if is_usable_village(n)]
    demo_cluster: list[str] = []
    if block["code"] == "junnar":
        cluster = pick_demo_cluster(candidates)
        villages = cluster + pick_spread(candidates, JUNNAR_SPREAD_VILLAGES, avoid=cluster)
        demo_cluster = [p["code"] for p in cluster]
    else:
        villages = pick_spread(candidates, VILLAGES_PER_BLOCK, avoid=[])
    marathi = relation["tags"].get("name:mr", "").replace(" तालुका", "")
    center = relation["center"]
    print(f"{block['en']}: {len(candidates)} usable villages in OSM, kept {len(villages)}")
    return {
        "code": block["code"],
        "name": {"en": block["en"], "hi": marathi, "mr": marathi},
        "osm": f"relation/{block['osm_relation']}",
        "centroid": {"lat": round(center["lat"], 5), "lng": round(center["lon"], 5)},
        "hq": find_hq(nodes, block["hq"], block["code"]),
        "villages": villages,
    }, demo_cluster


def main() -> None:
    fetched = fetch_all_blocks(refresh="--refresh" in sys.argv)
    blocks, demo_cluster = [], []
    for block in BLOCKS:
        built, cluster = build_block(block, *fetched[block["osm_relation"]])
        blocks.append(built)
        demo_cluster += cluster

    # Never write a file with a missing label: every village needs Devanagari.
    unnamed = [v["name"]["en"] for b in blocks for v in b["villages"] if not v["name"]["mr"]]
    if unnamed:
        raise SystemExit("Add Devanagari spellings to DEVANAGARI_FALLBACK for: " + ", ".join(unnamed))

    centroids = [b["centroid"] for b in blocks]
    output = {
        "version": 1,
        "needs_native_review": True,
        "source": "OpenStreetMap via Overpass API: taluka boundaries (admin_level 6) and place=village nodes inside them",
        "licence": "Data (c) OpenStreetMap contributors, ODbL 1.0",
        "generated_by": "backend/scripts/geocode_villages.py",
        "generated_on": date.today().isoformat(),
        "district": {**DISTRICT, "centroid": {
            "lat": round(sum(c["lat"] for c in centroids) / len(centroids), 5),
            "lng": round(sum(c["lng"] for c in centroids) / len(centroids), 5)}},
        "demo_cluster_villages": demo_cluster,
        "blocks": blocks,
    }
    path = SHARED_DIR / "geo" / "demo_district.json"
    path.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Wrote {path}")

    junnar = blocks[0]["villages"]
    for i, a in enumerate(junnar):
        for b in junnar[i + 1:]:
            print(f"  {a['name']['en']:>16} - {b['name']['en']:<16} {haversine_km(a, b):5.1f} km")


if __name__ == "__main__":
    main()
