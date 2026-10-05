"""Writes the Prairie's relief edits (terrain3d_relief/plaines.json) from the validated plan
(docs/zones-3d/plaines-layout.json, plan v2 « l'amphithéâtre du Crâne », Greg 04/10/2026).

The plan's relief is given there as modifiers on a flat base (base_m), computed by
docs/zones-3d/plaines-plan-outil.py; TerrainRelief (terrain3d_relief.gd + terrain3d_relief_shapes.gd)
applies the very same modifiers, so the 3D ground is the plan's target field
(docs/zones-3d/plaines-relief-cible.png) and not a copy of it: each edit stays readable and can be
changed by hand. The plan tool's smooth noise draws its waves from numpy's generator: the waves are
written down here once (the `layout` edit), so GDScript draws the same ripples.

After the plan's modifiers come the sculpting edits (SCULPT, ours: what the plan asks the relief
agent to finish by hand, each with its reason in "_why") and the painting (paint_edits).

    python terrain3d_relief_layout.py            (from this folder; numpy needed)
"""
import json
import math
import os

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT = os.path.join(HERE, "..", "..", "docs", "zones-3d", "plaines-layout.json")
OUT = os.path.join(HERE, "terrain3d_relief", "plaines.json")
WAVES = 6                      # the plan tool's fbm: six waves
NOISE_SEED, WOBBLE_SEED = 7, 11
WOBBLE_WAVELENGTH_M = 14.0

PROTECT_WHY = ("protect: false sur toutes les opérations du plan, EXPRÈS : le plan remplace tout le relief du 2,5D "
               "(base à 3 m, Crâne au centre, rempart percé plus au nord, étang déplacé) ; le garde-fou garderait les "
               "hauteurs du 2,5D (≈ 0 m) à 4 m de chaque falaise et de chaque eau du 2,5D : des fosses de 3 m partout. "
               "Les règles (Blockers3D, ZoneWater) lisent encore le 2,5D : voir le rapport du relief (conflits mesurés "
               "par tools/test_relief_plaines.gd).")

# What the relief adds to the plan's modifiers, by id. The ground runs on 20 m past the zone's edges
# (ZoneSource.margin_m): there, the plan's sea must go on
# (its polygon stopped at the zone's edge, and the bed rose back to the shore along it: a dam in the
# water at the edge of the zone). The crique's polygon, carried out past the south and west edges.
OVERRIDES = {
    "mer": {"polygon": [[0, 134], [14, 132], [28, 134], [42, 139], [47, 141], [50, 145], [56, 148], [64, 152],
                        [72, 156], [78, 162], [82, 170], [84, 180], [85, 205], [-25, 205], [-25, 134]],
            "_open_world": "le polygone du plan, prolongé au-delà des bords sud et ouest (la mer continue dans la marge)"},
    # The ru (the plan's water « brook »: 2.2 m wide, 0.3 m of water) runs in the bed this carve digs: a
    # Waterways river (terrain3d_relief_brooks.gd), from the pond down to the crique.
    "vallee_du_ru": {"brook": {"width_m": 2.2, "depth_m": 0.3, "to_sea_m": 12.0}},
}

# Sculpting (the plan's § 12: « sculpter à la main »), applied after the plan's own carving of the paths.
SCULPT = [
    # The Grotte's notch: the plan wants it 7 m wide with walls of 4 to 6 m, closed by the rocher de Charge
    # (116, 49.2) and its screes; its own modifiers stop the cirque's face at z 44, 5 m north of the rocher,
    # so the rocher stood in the open and Chloé walked round it. Two spurs of rock carry the cirque's walls
    # south to the rocher: the notch (x 112.5-119.5, the plan's 7 m) is now the one the rocher fills.
    {"op": "ridge", "id": "eperon_encoche_ouest", "points": [[109.5, 41], [109.5, 48.5]], "half_width_m": 1.0, "falloff_m": 2.0,
     "height": 8.5, "absolute": True, "mode": "max", "wobble_m": 0.5, "protect": False,
     "_why": "l'encoche de 7 m que bouche le rocher : ses murs (4,8 m) prolongés jusqu'au rocher (116, 49,2)"},
    {"op": "ridge", "id": "eperon_encoche_est", "points": [[122.5, 41], [122.5, 48.5]], "half_width_m": 1.0, "falloff_m": 2.0,
     "height": 8.5, "absolute": True, "mode": "max", "wobble_m": 0.5, "protect": False,
     "_why": "l'encoche de 7 m que bouche le rocher : ses murs (4,8 m) prolongés jusqu'au rocher (116, 49,2)"},
    # …and the colline's top is walked (its flanks, the belvédère): from its cirque one dropped into the notch,
    # behind the rocher. A crown of rock round the notch, too steep to climb from the top (1.8 m over the
    # plateau) or to stand on, closes it from above as the rocher closes it from the front.
    {"op": "ridge", "id": "couronne_encoche", "points": [[109.5, 49], [109.5, 40.5], [112, 37.5], [116, 36.5], [120, 37.5], [122.5, 40.5], [122.5, 49]],
     "half_width_m": 0.3, "falloff_m": 1.6, "height": 11.3, "absolute": True, "mode": "max", "wobble_m": 0.3, "protect": False,
     "_why": "depuis le haut de la colline (praticable), on sautait dans l'encoche derrière le rocher : une couronne de roche l'empêche"},
    # L'anse aux roseaux (the plan's water: « pond_part », 0.5 m deep): the pond's dug profile left its
    # east tip nearly a metre deep.
    {"op": "plateau", "id": "anse_roseaux", "polygon": [[141, 118], [147, 119], [147.5, 127], [141, 128]], "level": 1.9,
     "edge_m": 1.5, "wobble_m": 0.4, "mode": "max", "protect": False,
     "_why": "l'anse aux roseaux du plan : 0,5 m d'eau (le creusement de l'étang la laissait à 1 m)"},
    # The paths planed again, once the rest is laid: where one path starts on another (the corridor and the
    # gorge, the gorge and the sente de l'est…) the later one cut the earlier one's grade; a second pass
    # brings every path back under its grade_max_deg on the ground as it is now (not smoothed again: the
    # crests, the Seuil's, would wear down).
    {"op": "paths", "id": "rabotage_2", "smooth_samples": 1, "protect": False,
     "_why": "les pentes des sentiers du plan, mesurées sur le sol final (les raccords entre sentiers les dépassaient)"},
    # The gorge's path and the vallon's trail meet behind the porte (190, 54): even planed twice, their
    # profiles left a step of 0.3 m between them. Softened there (twice), after the second pass.
    {"op": "soften", "id": "raccord_gorge_vallon", "at": [190, 55], "radius_m": 4.0, "kernel_m": 1.0, "protect": False,
     "_why": "le raccord du sentier de la gorge et de celui du vallon (marche de 0,3 m)"},
    {"op": "soften", "id": "raccord_gorge_vallon_2", "at": [190, 55], "radius_m": 4.0, "kernel_m": 1.0, "protect": False,
     "_why": "le raccord du sentier de la gorge et de celui du vallon (marche de 0,3 m)"},
    # The source du Crâne (156, 120): its rill, to the anse (the plan's water; the relief had no bed for it). It
    # goes round by the south: the sente de la rive sud climbs the parvis' bank between the source and the
    # pond, and the rill crosses it where it is still down by the water (a step over it, 0.3 m).
    {"op": "carve", "id": "ru_source", "points": [[156, 121], [153, 126], [149, 129.5], [146.5, 128.3]], "width_m": 1.0,
     "follow_ground": True, "offset_m": -0.15, "blend_m": 2.0, "brook": {"width_m": 0.8, "depth_m": 0.1}, "protect": False,
     "_why": "le filet d'eau de la source du Crâne vers l'anse aux roseaux"},
    # The ru's bed (the plan's vallee_du_ru, carved before the pond and the paths) cut again: the pond's banks
    # had raised a sill at its outlet, and the route du port (the gué, 118,127) and the sente de la crique
    # (79,142) were laid over it: the water would have gone under them. The plan: 0.3 m of water, one walks in it.
    {"op": "carve", "id": "ru_gues", "points": [[123, 126], [118, 127], [106, 126], [94, 130], [84, 137], [76, 146], [70, 152]],
     "width_m": 2.4, "bed_of": "vallee_du_ru", "blend_m": 2.5, "protect": False,
     "_why": "le lit du ru continu de l'étang à la crique, à travers les sentiers (les gués) et le seuil de l'étang"},
]

# Painting (the plan's § 12): earth on the main paths, trodden grass on the others, sand on the beach and
# the pond's banks, the dark floor of the woods, rock on the screes and in the notches, mud in the brook,
# « dry golden grass » on the ramp and the forecourt (no such ground: sand, half laid, gives patches of it).
# The 2.5D's painting is cleared first but its tall grass (the encounters' tiles, still the rules').
WOODS = {"bois_du_port": 0.9, "lisiere_foret": 0.9, "chemin_creux": 0.7, "bois_chipie": 0.6, "bois_crique": 0.6,
         "bois_sud_est": 0.7, "bosquet_helene": 0.4, "vallee_ru": 0.25, "tertre_crane": 0.3}
ROCK = {"eboulis_est": 0.7, "encoche_grotte": 0.55}
DRY_GRASS = {"vertebres": 0.33, "parvis_crane": 0.33}
TRODDEN = {"secondary": 0.42, "trail": 0.34}


def paint_edits(layout: dict) -> list:
    areas = {a["id"]: a for a in layout["areas"]}

    def polys(area_id: str) -> list:
        a = areas[area_id]
        return [a[k] for k in ("polygon", "polygon2") if a.get(k)]

    out = [{"op": "paint_reset", "keep": ["tall_grass", "water"], "_why": "la peinture du 2,5D effacée (le plan déplace tout) ; ses herbes hautes restent : ce sont encore les cases des rencontres"}]
    for area_id, amount in WOODS.items():
        out += [{"op": "paint", "ground": "forest", "polygon": p, "amount": amount, "feather_m": 3.0, "_area": area_id} for p in polys(area_id)]
    out.append({"op": "paint", "ground": "grass", "at": [176, 148], "radius_m": 6, "_area": "clairière du bois du Sud-Est"})
    out.append({"op": "paint", "ground": "grass", "at": [31, 56], "radius_m": 8, "amount": 0.6, "_area": "clairière d'Hélène"})
    for area_id, amount in ROCK.items():
        out += [{"op": "paint", "ground": "rock", "polygon": p, "amount": amount, "feather_m": 2.0, "_area": area_id} for p in polys(area_id)]
    gorge = next(m for m in layout["relief"]["modifiers"] if m["id"] == "gorge_porte")
    out.append({"op": "paint", "ground": "rock", "points": gorge["points"], "width_m": 5.0, "amount": 0.6, "_area": "la gorge de la porte d'ambre"})
    out += [{"op": "paint", "ground": "sand", "polygon": p, "below_m": 0.9, "feather_m": 2.0, "_area": "la plage de la crique"} for p in polys("crique")]
    pond = next(w for w in layout["water"] if w["kind"] == "pond")["ellipse"]
    bank = [[round(pond["center"][0] + (pond["radii"][0] + 2.5) * math.cos(a), 2), round(pond["center"][1] + (pond["radii"][1] + 2.5) * math.sin(a), 2)]
            for a in np.linspace(0, 2 * math.pi, 24, endpoint=False)]
    out.append({"op": "paint", "ground": "sand", "polygon": bank, "below_m": 2.75, "amount": 0.75, "feather_m": 1.0, "_area": "les rives de l'étang"})
    for area_id, amount in DRY_GRASS.items():
        out += [{"op": "paint", "ground": "sand", "polygon": p, "amount": amount, "feather_m": 2.0, "_area": area_id + " (herbe sèche dorée)"} for p in polys(area_id)]
    ru = next(w for w in layout["water"] if w["kind"] == "brook")
    out.append({"op": "paint", "ground": "mud", "points": ru["points"], "width_m": ru["width_m"], "amount": 0.8, "_area": "le lit du ru"})
    rill = next(e for e in SCULPT if e["id"] == "ru_source")
    out.append({"op": "paint", "ground": "mud", "points": rill["points"], "width_m": 1.0, "amount": 0.6, "_area": "le filet de la source"})
    out.append({"op": "paint", "ground": "mud", "at": [144, 123], "radius_m": 3.0, "amount": 0.6, "_area": "l'anse aux roseaux"})
    for p in layout["paths"]:   # the main paths last: on top of everything
        amount = 1.0 if p["kind"] == "main" else TRODDEN.get(p["kind"], 0.34)
        out.append({"op": "paint", "ground": "path", "points": p["points"], "width_m": p["width_m"], "amount": amount, "_path": p["id"]})
    return out


def waves(seed: int) -> list:
    """The plan tool's fbm (plaines-plan-outil.py, fbm): per wave its angle and phase, as numpy draws them."""
    rng = np.random.default_rng(seed)
    out = []
    for _ in range(WAVES):
        angle = float(rng.uniform(0, math.pi))
        phase = float(rng.uniform(0, 2 * math.pi))
        out.append([round(angle, 9), round(phase, 9)])
    return out


def plan_edits(layout: dict) -> list:
    """The plan's relief, in the plan tool's order: base, modifiers, the pond dug, then what comes after the
    water (the islet, the ford), then the paths planed."""
    edits = [{
        "op": "layout",
        "_doc": "ce que les opérations suivantes lisent : les vagues du bruit (graine 7) et des bords ondulés (graine 11), les sentiers et les clairières du plan",
        "waves": {str(NOISE_SEED): waves(NOISE_SEED), str(WOBBLE_SEED): waves(WOBBLE_SEED)},
        "wobble_seed": WOBBLE_SEED, "wobble_wavelength_m": WOBBLE_WAVELENGTH_M, "noise_seed": NOISE_SEED,
        "paths": [{k: p[k] for k in ("id", "kind", "width_m", "grade_max_deg", "points")} for p in layout["paths"]],
        "clearings": [{k: c[k] for k in ("id", "center", "radius")} for c in layout["clearings"]],
    }, {"op": "level", "id": "base", "height_m": float(layout["relief"]["base_m"]), "protect": False}]
    after_water = []
    renamed = {"plateau_ellipse_after_water": "islet", "rect_after_water": "shoal"}
    for m in layout["relief"]["modifiers"]:
        e = {"op": renamed.get(m["kind"], m["kind"])}
        for k, v in m.items():
            if k in ("kind", "note", "after_water"):
                continue
            e["mode" if k == "op" else k] = v   # (the plan's add | max | set: "op" is the edit's name here)
        if m["id"] in OVERRIDES:
            e.update(OVERRIDES[m["id"]])
        e["protect"] = False
        (after_water if m.get("after_water") else edits).append(e)
    for w in layout["water"]:
        if w["kind"] == "pond":
            edits.append({"op": "pond", "id": w["id"], "ellipse": w["ellipse"], "level": w["level"], "depth": w["depth"], "protect": False})
    edits += after_water
    edits.append({"op": "paths", "id": "rabotage", "_doc": "le sol raboté sous chaque sentier du plan (profil lissé sur 9 m, pente bornée)", "protect": False})
    return edits


def main() -> None:
    layout = json.load(open(LAYOUT, encoding="utf-8"))
    ru = next(m for m in layout["relief"]["modifiers"] if m["id"] == "vallee_du_ru")
    assert next(e for e in SCULPT if e["id"] == "ru_gues")["points"] == ru["points"], "ru_gues : mêmes points que vallee_du_ru"
    data = {
        "_doc": ("Relief et peinture du sol 3D de la Prairie (TerrainRelief, terrain3d_relief.gd). Les opérations s'appliquent "
                 "dans l'ordre, en mètres de la zone ([x, z], 0,0 au coin nord-ouest). Généré par terrain3d_relief_layout.py "
                 "depuis docs/zones-3d/plaines-layout.json (plan v2 validé par Greg) : ne pas retoucher à la main, retoucher le "
                 "plan, ou SCULPT / la peinture dans le générateur."),
        "_protect": PROTECT_WHY,
        "edits": plan_edits(layout) + SCULPT + paint_edits(layout),
    }
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:   # one edit per line: readable, and diffs well
        f.write("{\n")
        for key in ("_doc", "_protect"):
            f.write("\t%s: %s,\n" % (json.dumps(key), json.dumps(data[key], ensure_ascii=False)))
        f.write('\t"edits": [\n')
        lines = [json.dumps(e, ensure_ascii=False, separators=(", ", ": ")) for e in data["edits"]]
        f.write(",\n".join("\t\t" + line for line in lines))
        f.write("\n\t]\n}\n")
    print("%s : %d opérations" % (OUT, len(data["edits"])))


if __name__ == "__main__":
    main()
