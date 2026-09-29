"""Generate the symptom and species pictograms (spec 9.6).

Run from mobile/:  python tool/pictograms.py

Why generated: 34 icons must share one style (48x48, 2px strokes, rounded
caps, affected part filled with indigoTint). Building them from shared parts
(cow body, cow head close-up, hen, udder, hoof) keeps them consistent, and a
change to a part updates every icon that uses it.

Strokes use currentColor so a selected tile can switch them to white; the
highlight fill stays indigoTint. Writes assets/pictograms/*.svg and
tool/pictograms_preview.html (open it to review every icon at once).
"""

from pathlib import Path

TINT = "#D9DEF0"
OUT = Path(__file__).resolve().parents[1] / "assets" / "pictograms"
STYLE = 'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"'


def svg(*parts: str) -> str:
    body = "\n  ".join(parts)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">\n'
            f'<g {STYLE}>\n  {body}\n</g>\n</svg>\n')


def tint(shape: str) -> str:
    """A highlighted area: indigo fill, thinner outline."""
    return shape.replace("<", f'<', 1).replace("/>", f' fill="{TINT}" stroke-width="1.5"/>', 1)


def dot(x: float, y: float, r: float = 1) -> str:
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="currentColor" stroke="none"/>'


def drop(x: float, y: float, size: float = 1.0) -> str:
    """A tear/drip drop hanging from (x, y)."""
    s = size
    return tint(f'<path d="M{x} {y} Q{x + 2.6 * s} {y + 3.6 * s} {x + 2.4 * s} {y + 4.6 * s} '
                f'A2.4 2.4 0 0 1 {x - 2.4 * s} {y + 4.6 * s} Q{x - 2.6 * s} {y + 3.6 * s} {x} {y} Z"/>')


# ---------- whole animals (side view, facing left) ----------

COW_LEGS = "M17 32 V42 M21 32 V42 M33 32 V42 M37 32 V42"
COW_BODY = "M14 18 H36 Q41 18 41 23 V28 Q41 32 37 32 H17 Q13 32 13 28 V21"
COW_HEAD = "M14 20 L10 16 Q7 14 5 17 L3 23 Q3 26 6 26 L10 25 L13 27"
COW_HORN = "M9 16 Q8 12 11 11"
COW_EAR = "M11 17 L14 15"
COW_TAIL = "M41 21 Q44 25 43 31 M42 31 L44 33"
UDDER = "M30 32 Q32 35.5 34 32"


def cow(legs: str = COW_LEGS, extra: tuple[str, ...] = ()) -> list[str]:
    return [f'<path d="{COW_BODY}"/>', f'<path d="{COW_HEAD}"/>', f'<path d="{COW_HORN}"/>',
            f'<path d="{COW_EAR}"/>', f'<path d="{legs}"/>', f'<path d="{COW_TAIL}"/>',
            f'<path d="{UDDER}"/>', dot(7, 19.5), *extra]


def buffalo() -> list[str]:
    # Heavier, lower body; head carried low; wide crescent horns swept back.
    return ['<path d="M15 16 H36 Q42 16 42 22 V29 Q42 34 37 34 H18 Q13 34 13 29 V21"/>',
            '<path d="M15 19 L11 19 Q7 19 6 22 L4 28 Q4 31 7 31 L11 30 L14 30"/>',
            '<path d="M8 19 Q4 13 10 10 Q15 8 18 12"/>',
            '<path d="M18 34 V42 M22 34 V42 M33 34 V42 M37 34 V42"/>',
            '<path d="M42 23 Q45 27 44 32"/>', dot(8.5, 23)]


def goat() -> list[str]:
    return ['<path d="M17 21 H35 Q39 21 39 25 V28 Q39 31 36 31 H19 Q16 31 16 28 V23"/>',
            '<path d="M17 23 L13 16 Q11 13 9 15 L6 20 Q5 22 7 23 L11 23 L15 27"/>',
            '<path d="M11 15 Q12 9 17 10"/>', '<path d="M7 23 L6 27"/>',
            '<path d="M20 31 V43 M23 31 V43 M32 31 V43 M35 31 V43"/>',
            '<path d="M39 22 L42 18"/>', dot(9.5, 17.5, 0.9)]


def sheep() -> list[str]:
    wool = ("M16 20 Q17 15 22 16 Q25 12 29 15 Q33 12 36 16 Q41 16 41 21 Q44 24 41 28 "
            "Q40 32 35 31 Q31 34 27 31 Q23 34 19 31 Q14 31 15 26 Q12 23 16 20 Z")
    return [f'<path d="{wool}"/>', '<path d="M16 21 L11 18 Q8 17 7 20 L6 25 Q6 27 8 27 L12 26 L15 26"/>',
            '<path d="M12 19 L14 16"/>', '<path d="M20 31 V42 M24 32 V42 M32 32 V42 M36 31 V42"/>',
            dot(9.5, 21, 0.9)]


def pig() -> list[str]:
    return ['<path d="M13 22 Q14 15 25 15 Q39 15 41 24 Q42 33 30 34 H21 Q12 33 13 22 Z"/>',
            '<path d="M13 21 H8 Q6 21 6 23.5 Q6 26 8 26 H13"/>', '<path d="M15 16 L17 11 L20 15"/>',
            '<path d="M18 34 V40 M23 34 V40 M31 34 V40 M36 33 V40"/>',
            '<path d="M41 23 Q45 21 44 25 Q43 28 46 27"/>', dot(16, 20, 0.9), dot(8, 23.5, 0.6)]


HEN_BODY = "M17 19 Q12 25 15 31 Q19 36 28 35 Q36 34 39 26 L42 15 Q37 18 33 20 Q27 22 22 19"
HEN_HEAD = "M17 19 Q13 17 13 13 Q13 9 17 9 Q21 9 22 13 L22 19"
HEN_COMB = "M14 9 Q14 6 16 7 Q17 4 19 7 Q21 5 21 9"
HEN_BEAK = "M13 12 L9 13.5 L13 15"
HEN_WATTLE = "M14 16 Q13 20 16 19"
HEN_LEGS = "M24 35 V42 M20 42 H28 M30 34 V42 M26 42 H34"


def hen(extra: tuple[str, ...] = ()) -> list[str]:
    return [f'<path d="{HEN_BODY}"/>', f'<path d="{HEN_HEAD}"/>', f'<path d="{HEN_COMB}"/>',
            f'<path d="{HEN_BEAK}"/>', f'<path d="{HEN_WATTLE}"/>', f'<path d="{HEN_LEGS}"/>',
            '<path d="M24 25 Q29 29 34 25"/>', dot(17, 12, 0.9), *extra]


# ---------- close-ups ----------

HEAD_OUTLINE = "M40 14 Q36 7 29 8 L12 23 Q8 27 10 31 Q12 34 16 34 L26 33"
HEAD_NECK = "M26 33 Q30 37 33 44 M40 14 Q43 24 45 34"
HEAD_HORN = "M30 8 Q31 3 35 2"
HEAD_EAR = "M38 13 L44 11 L41 16"


def cow_head(mouth: str = "M11 30 H17", extra: tuple[str, ...] = ()) -> list[str]:
    return [f'<path d="{HEAD_OUTLINE}"/>', f'<path d="{HEAD_NECK}"/>', f'<path d="{HEAD_HORN}"/>',
            f'<path d="{HEAD_EAR}"/>', f'<path d="{mouth}"/>', dot(26, 16, 1.2), dot(12.5, 26, 0.8), *extra]


def hen_head(comb_tint: bool = False, wattle_tint: bool = False, swollen: bool = False) -> list[str]:
    comb = ("M17 16 Q15 9 19 10 Q20 4 24 8 Q27 2 30 8 Q34 5 34 12 Q36 15 33 16" if swollen
            else "M18 15 Q17 10 20 11 Q21 6 24 9 Q27 5 29 9 Q32 8 32 14")
    wattle = "M18 30 Q14 41 21 40 Q25 37 22 30" if swollen else "M18 30 Q16 37 20 36 Q22 34 21 30"
    head = "M16 25 Q14 14 25 14 Q35 14 35 24 Q35 30 31 33"
    comb_el = f'<path d="{comb}"/>'
    wattle_el = f'<path d="{wattle}"/>'
    return [f'<path d="{head}"/>', tint(comb_el) if comb_tint else comb_el,
            tint(wattle_el) if wattle_tint else wattle_el, '<path d="M16 22 L8 25 L16 28"/>',
            '<path d="M22 31 Q21 38 19 45 M31 33 Q35 38 37 45"/>', dot(24, 21, 1.2)]


UDDER_CLOSE = "M6 12 H42 M9 12 Q9 30 24 30 Q39 30 39 12"
TEATS = ["M14 26 V35 Q14 37 16 37 Q18 37 18 35 V28", "M22 30 V38 Q22 40 24 40 Q26 40 26 38 V30",
         "M30 28 V35 Q30 37 32 37 Q34 37 34 35 V26"]


def udder(tint_teats: bool = False, extra: tuple[str, ...] = ()) -> list[str]:
    teats = [f'<path d="{t}"/>' for t in TEATS]
    if tint_teats:
        teats = [tint(t) for t in teats]
    return [f'<path d="{UDDER_CLOSE}"/>', *teats, *extra]


def hoof(extra: tuple[str, ...] = ()) -> list[str]:
    return ['<path d="M17 3 V20 Q15 25 16 30 M31 3 V20 Q33 25 32 30"/>',
            '<path d="M16 30 L13 42 H23 V31"/>', '<path d="M25 31 V42 H35 L32 30"/>',
            '<path d="M16 30 Q24 27 32 30"/>', '<path d="M14 22 Q11 24 13 26 M34 22 Q37 24 35 26"/>', *extra]


LYING_COW = ["M8 34 Q8 25 20 24 H33 Q41 24 41 31 Q41 38 33 38 H14 Q8 38 8 34 Z",
             "M9 30 L5 27 Q2 27 2 30 L2 35 Q3 37 6 36 L9 35", "M4 42 H45"]


def lying_cow(extra: tuple[str, ...] = (), legs: str = "M18 38 L22 42 M24 38 L28 42 M31 38 L35 42 M36 36 L41 40",
              belly: str | None = None) -> list[str]:
    parts = [f'<path d="{LYING_COW[0]}"/>', f'<path d="{LYING_COW[1]}"/>', f'<path d="{LYING_COW[2]}"/>',
             f'<path d="{legs}"/>', '<path d="M4 29 L6 31 M6 29 L4 31"/>', '<path d="M6 27 Q6 23 9 22"/>']
    if belly:
        parts.append(tint(f'<path d="{belly}"/>'))
    return parts + list(extra)


def species_icons() -> dict[str, list[str]]:
    return {"species_cattle": cow(), "species_buffalo": buffalo(), "species_goat": goat(),
            "species_sheep": sheep(), "species_pig": pig(), "species_poultry": hen()}


def symptom_icons() -> dict[str, list[str]]:
    thermometer = (tint('<path d="M40 4 Q42 4 42 6 V16 A3.6 3.6 0 1 1 38 16 V6 Q38 4 40 4 Z"/>'),
                   '<path d="M40 8 V17"/>')
    return {
        "fever": cow(extra=thermometer),
        "anorexia": cow(extra=(tint('<path d="M1 36 H12 L11 41 H2 Z"/>'), '<path d="M2 32 L11 44 M11 32 L2 44"/>')),
        "drop_in_milk": udder(extra=(drop(40, 22, 1.1), '<path d="M44 20 V33 M41.5 30.5 L44 33 L46.5 30.5"/>')),
        "skin_nodules": cow(extra=tuple(tint(f'<circle cx="{x}" cy="{y}" r="{r}"/>')
                                        for x, y, r in ((20, 23, 2.2), (27, 21.5, 2), (33, 24, 2.3),
                                                        (24, 28, 1.9), (37, 28, 1.8)))),
        "enlarged_lymph_nodes": cow(extra=(tint('<ellipse cx="16" cy="23" rx="2.6" ry="3.4"/>'),
                                           tint('<ellipse cx="37.5" cy="27" rx="2.4" ry="3.2"/>'))),
        "limb_oedema": cow(legs="M16 32 V42 M22 32 V42 M33 32 V42 M37 32 V42",
                           extra=tuple(tint(f'<path d="M{x} 33 Q{x - 2.5} 38 {x} 42 H{x + 3} Q{x + 5.5} 38 {x + 3} 33 Z"/>')
                                       for x in (14.5, 20.5))),
        "ocular_discharge": cow_head(extra=(drop(26, 18.5, 1.0), drop(24, 25, 0.8))),
        "nasal_discharge": cow_head(extra=(drop(12, 28, 1.0), drop(15, 34, 0.8))),
        "excessive_salivation": cow_head(extra=(tint('<path d="M13 31 Q12 38 14 44 Q16 45 16 43 Q15 38 16 32 Z"/>'),
                                                tint('<path d="M17 31 Q18 36 17 40 Q19 41 19 39 Q19 35 19 31 Z"/>'))),
        "mouth_sores": cow_head(mouth="M11 30 Q15 36 22 32",
                                extra=(tint('<circle cx="15" cy="32.5" r="1.8"/>'),
                                       tint('<circle cx="20" cy="31.5" r="1.5"/>'))),
        "foot_lesions": hoof(extra=(tint('<path d="M21 31 Q24 28 27 31 L26 40 H22 Z"/>'),)),
        "lameness": cow(legs="M21 32 V42 M33 32 V42 M37 32 V42 M17 32 L14 36 L17 39",
                        extra=('<path d="M10 39 Q9 36 10 34 M7 40 Q5 36 7 32"/>',)),
        "teat_lesions": udder(tint_teats=True, extra=(dot(16, 33, 0.9), dot(24, 35, 0.9), dot(32, 33, 0.9))),
        "throat_swelling": cow_head(extra=(tint('<path d="M16 34 Q18 42 25 41 Q31 40 29 35 Z"/>'),)),
        "difficulty_breathing": cow_head(extra=('<path d="M8 23 Q4 21 5 17 M7 27 Q2 27 1 23 M8 31 Q3 33 2 36"/>',)),
        "coughing": cow_head(mouth="M11 30 Q13 33 18 31",
                             extra=('<path d="M6 32 L2 32 M7 36 L4 39 M9 38 L9 42"/>',)),
        "diarrhoea": cow(extra=(drop(44, 34, 0.9), drop(41, 38, 0.8), drop(45, 41, 0.7))),
        "sudden_death": lying_cow(),
        "bleeding_from_orifices": cow_head(extra=(drop(12, 28, 1.1), drop(15, 34, 1.0), drop(19, 35, 0.8))),
        "absence_of_rigor_mortis": lying_cow(legs="M18 38 Q24 40 22 44 M31 38 L35 42 M36 36 L41 40",
                                             extra=('<path d="M26 46 Q30 47 31 44 M29.5 43 L31 44 L32.5 42.5"/>',)),
        "rapid_bloating_carcass": lying_cow(belly="M15 24 Q17 14 27 14 Q37 14 38 24 Z"),
        "trembling_staggering": cow(extra=('<path d="M1 12 Q3 16 1 20 M4 9 Q6 14 4 19 M46 14 Q44 18 46 22 M44 34 Q46 38 44 42"/>',)),
        "sudden_high_mortality": [
            '<g transform="translate(2 44) rotate(-90) scale(0.55)">', *hen(), '</g>',
            '<g transform="translate(22 46) rotate(-90) scale(0.55)">', *hen(), '</g>',
            tint('<path d="M2 45 H46 V47 H2 Z"/>')],
        "swollen_head_comb_wattles": hen_head(comb_tint=True, wattle_tint=True, swollen=True),
        "cyanosis_comb_wattles": hen_head(comb_tint=True, wattle_tint=True),
        "drop_in_egg_production": [tint('<ellipse cx="20" cy="26" rx="10" ry="13"/>'),
                                   '<path d="M38 12 V36 M33 31 L38 36 L43 31"/>'],
        "neurological_signs": cow_head(extra=('<path d="M4 12 A6 6 0 1 1 10 18 M10 18 L7 18 M10 18 L10 15"/>',)),
        # Hen leg close-up: feathered thigh, bare shank with red spots, spread toes.
        "shank_haemorrhages": ['<path d="M14 5 Q24 -1 34 5 Q37 13 29 17 H19 Q11 13 14 5 Z"/>',
                               '<path d="M19 12 Q22 14 24 12 Q26 14 29 12"/>',
                               '<path d="M20 17 V33 M28 17 V33"/>',
                               '<path d="M24 33 L12 42 M24 33 V45 M24 33 L36 42 M21 32 L15 29"/>',
                               tint('<circle cx="24" cy="21" r="2.2"/>'), tint('<circle cx="23" cy="28" r="1.8"/>')],
    }


def app_mark() -> str:
    # The ear tag: wide body with a narrower rounded tab on top and a punched hole.
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">\n'
            '<path d="M18 4 H30 Q33 4 33 7 V13 H38 Q42 13 42 17 V40 Q42 44 38 44 H10 Q6 44 6 40 V17 '
            'Q6 13 10 13 H15 V7 Q15 4 18 4 Z M24 7 A2.6 2.6 0 1 0 24.001 7 Z" fill="#F6C400" '
            'fill-rule="evenodd" stroke="#1C2541" stroke-width="2" stroke-linejoin="round"/>\n'
            '<path d="M14 24 H34 M14 31 H34 M14 38 H26" stroke="#1C2541" stroke-width="2.5" stroke-linecap="round"/>\n'
            '</svg>\n')


def preview(names: list[str]) -> str:
    cells = "".join(
        f'<figure><div class="a"><img src="../assets/pictograms/{n}.svg"></div>'
        f'<div class="b">{(OUT / f"{n}.svg").read_text(encoding="utf-8").replace("currentColor", "#FFFFFF")}</div>'
        f'<figcaption>{n}</figcaption></figure>' for n in names)
    return ("<!doctype html><meta charset=utf-8><title>Pictograms</title><style>"
            "body{font:12px sans-serif;background:#EEF1EC;color:#1C2541;display:flex;flex-wrap:wrap;gap:10px;padding:12px}"
            "figure{margin:0;width:150px;text-align:center}.a,.b{display:inline-block;width:64px;height:64px;padding:4px;"
            "border:1px solid #D6DCD3;border-radius:10px}.a{background:#fff}.b{background:#1C2541}"
            "img,svg{width:64px;height:64px}</style>" + cells)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    icons = {**species_icons(), **symptom_icons()}
    for name, parts in icons.items():
        (OUT / f"{name}.svg").write_text(svg(*parts), encoding="utf-8", newline="\n")
    (OUT / "app_mark.svg").write_text(app_mark(), encoding="utf-8", newline="\n")
    names = list(icons) + ["app_mark"]
    (Path(__file__).parent / "pictograms_preview.html").write_text(preview(names), encoding="utf-8")
    print(f"Wrote {len(icons) + 1} SVGs to {OUT}")


if __name__ == "__main__":
    main()
