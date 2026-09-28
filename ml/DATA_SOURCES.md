# Data sources

Every external dataset or API used by PashuSetu, with its licence and what we used it for.
Add a row before using any new source.

| Source | URL | Licence | What we used | Size / count | Retrieved |
|---|---|---|---|---|---|
| OpenStreetMap (via Overpass API) | https://www.openstreetmap.org, https://overpass-api.de | ODbL 1.0. Attribution "© OpenStreetMap contributors" is required wherever the data is shown | Pune district taluka boundaries (admin_level 6) and `place=village` nodes inside them: names (English + Marathi) and coordinates for `shared/geo/demo_district.json` | 13 talukas, about 5 villages each (Junnar 8) | 2026-09-29, by `backend/scripts/geocode_villages.py` |

## Notes

- Village selection is automatic and repeatable (see the script docstring). No coordinates were typed in by hand.
- OSM maps rural Pune sparsely, so some well-known villages are missing. We only used villages that exist in OSM with both an English and a Marathi name.
- The map screen (Phase 8) must show the OSM attribution.
- The LSD image dataset (Phase 6) will be added here with its licence before training.
