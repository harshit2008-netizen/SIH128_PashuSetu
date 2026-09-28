# Design notes and visual QA log

Design decisions, and what visual QA found and changed. See spec Section 9 (the "field instrument" look, with the ear tag as the signature element).

## Decisions

| Date | Decision | Why |
|---|---|---|
| 2026-09-28 | Project name **PashuSetu (पशुसेतु)** replaces "PashuRakshak" from the spec | Team decision. "Setu" means bridge, between farmers, vets and officers |
| 2026-09-28 | Fonts: Mukta (text) + Anek Devanagari (display), bundled TTFs | Both are OFL. Anek Devanagari covers Latin too (checked with fontTools), so we don't need Anek Latin |
| 2026-09-28 | Anek weight/width set via `FontVariation` | It ships as one variable font (wght 100–800, wdth 75–125). Numbers use wdth 90 for a slightly condensed look |
| 2026-09-28 | Devanagari styles force line height ≥ 1.5 | Matras get clipped at tighter line heights (spec 9.4) |

## Visual QA log

| Date | Screen | Issue found | Change |
|---|---|---|---|
| 2026-09-28 | Phase 0 setup screen (`screenshots/phase0_home.png`, Vivo V2443, 720×1608) | None. Limewash background, ink text, Anek display bold, Mukta body in Hindi and English, matras not clipped, no Roboto or purple | No change. The screen is replaced by role homes in Phase 3 |
