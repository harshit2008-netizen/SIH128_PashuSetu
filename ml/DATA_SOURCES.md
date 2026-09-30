# Data sources

Every external dataset or API used by PashuSetu, with its licence and what we used it for.
Add a row before using any new source.

| Source | URL | Licence | What we used | Size / count | Retrieved |
|---|---|---|---|---|---|
| OpenStreetMap (via Overpass API) | https://www.openstreetmap.org, https://overpass-api.de | ODbL 1.0. Attribution "© OpenStreetMap contributors" is required wherever the data is shown | Pune district taluka boundaries (admin_level 6) and `place=village` nodes inside them: names (English + Marathi) and coordinates for `shared/geo/demo_district.json` | 13 talukas, about 5 villages each (Junnar 8) | 2026-09-29, by `backend/scripts/geocode_villages.py` |
| CowHealth-6K: Cow Disease Detection (Kaggle user drtawfikrrahman) | https://www.kaggle.com/datasets/drtawfikrrahman/cowhealth-6k-cow-disease-detection | CC0-1.0 (public domain) | LSD photo model (Phase 6): folders `Lumpycows-1`, `Lumpycows-2` = lsd; `Healthycows 1`, `Healthycows 2` = healthy. Foot-and-mouth and mastitis folders not used | 1,627 lsd + 1,806 healthy images read; 3,433 -> 2,657 after near-duplicate removal (see `reports/dataset_inspection.md`) | 2026-09-30, `kaggle datasets download` |

## Notes

- Village selection is automatic and repeatable (see the script docstring). No coordinates were typed in by hand.
- OSM maps rural Pune sparsely, so some well-known villages are missing. We only used villages that exist in OSM with both an English and a Marathi name.
- The map screen (Phase 8) must show the OSM attribution.
- CowHealth-6K says it collects images from public veterinary repositories and farms in Bangladesh. `Lumpycows-2` and part of
  `Healthycows 1` are Roboflow exports (augmented copies), which is why so many near-duplicates were removed.
- One file in `Lumpycows-2` is named as a foot-and-mouth photo and was dropped. 4 photos appeared under both labels and were dropped.
- Datasets we looked at but did not use: `warcoder/lumpy-skin-images-dataset` (CC BY 4.0, 324 lsd / 700 normal, smaller),
  `devang03mgr/cattle-diseases-datasets` (DbCL-1.0, largely contained in CowHealth-6K), `kaushalrimal619/lumpy-skin-disease-cow-images` (licence unknown).
