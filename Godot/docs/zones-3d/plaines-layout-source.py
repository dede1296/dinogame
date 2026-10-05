"""Construit docs/zones-3d/plaines-layout.json (plan v2 « le Crâne au cœur de l'amphithéâtre »).
Les ancres sont déplacées PAR GROUPES DE SCÈNE (translation pure, jamais de rotation : l'histoire
est écrite avec des directions absolues « left/up »), avec l'ancienne position (2,5D x2) et la
nouvelle, pour le champ de déformation des scènes."""
import json

OUT = r"C:\Users\Greg\Dinogame\Godot\docs\zones-3d\plaines-layout.json"

def mv(p, d):
    return [round(p[0] + d[0], 1), round(p[1] + d[1], 1)]

# ------------------------------------------------------------------ groupes de scène
# Δ (m) par groupe ; (0,0) = inchangé.
G = {
    "G_port": (0, 0), "G_carrefour": (-8, 8), "G_chipie": (-8, 8), "G_oeuf": (-4, 4.8), "G_tronc": (18, 4.2),
    "G_bosquet": (0, 0), "G_grotte": (0, 0), "G_porte": (4, -12), "G_poste": (0, -4), "G_crane": (-36, -24),
    "G_etang": (-24, 28), "G_etang_ilot": (-24, 28), "G_elise": (-27, 22), "G_dormeur": (0, 0), "G_crique": (0, 0), "G_foret": (0, 0), "G_libre": (0, 0),
}
GROUP_NOTES = {
    "G_port": "l'arrivée du port : inchangée (raccord avec Port-Ambre)",
    "G_carrefour": "Maïa, le panneau, le feu, l'escale et le Grand Voyageur : le hub glisse de 8 m vers le sud-ouest, au pied de la rampe du parvis",
    "G_chipie": "la course de Chipie et son nid : même Δ que le carrefour (elle part de Maïa)",
    "G_oeuf": "le rocher-œuf et son panneau : dégagés de la route du corridor",
    "G_tronc": "le tronc de Tranche : au bout du chemin creux, 18 m plus près du carrefour (équilibre des trois passages)",
    "G_bosquet": "la clairière d'Hélène (fragment, fleurs, souche) : inchangée",
    "G_grotte": "l'encoche de la Grotte (bouche, rocher, panneau, sortie) : inchangée",
    "G_porte": "la porte d'ambre : la gorge perce le rempart 12 m plus au nord (le corridor des Vertèbres passe devant)",
    "G_poste": "le poste d'observation : 4 m plus au nord (terrasses resserrées)",
    "G_crane": "LE GRAND CRÂNE ET SON PARVIS : du coin sud-est au cœur de la cuvette, 60 m du carrefour, visible de partout ; le groupe entier (antre, panneau, Alpha, Maïa défi, MAIA_FROM, sorties) suit",
    "G_etang": "l'Étang des Chanteurs (îlot, gué, page 2, chanteurs, banc, panneau, peau muée, prêles) : sous le parvis du Crâne, à l'est du carrefour (« Est : l'étang, puis le Grand Crâne »)",
    "G_etang_ilot": "l'îlot (page 2, pierre plate, galet) et le gué : même Δ que l'étang ; l'îlot est petit (5 m) pour rester entouré d'eau profonde hors pleine lune",
    "G_elise": "la prairie d'Élise : toujours au sud de l'étang, sur la rive (le Tricératops dort à 1 m de l'eau), hors du Seuil et hors herbes hautes ; son rectangle vide reste au sud du trio",
    "G_dormeur": "le dormeur et son arbre : inchangés",
    "G_crique": "la crique (panneau, feu, Pointe) : inchangée",
    "G_foret": "la sortie vers la Forêt : inchangée (raccord)",
    "G_libre": "éléments sans scène (galets cachés, habitats) : replacés un à un",
}

A = []   # ancres
def anc(id_, group, old, kind, new=None, note=None, **kw):
    d = G[group]
    nw = new if new is not None else mv(old, d)
    item = {"id": id_, "group": group, "kind": kind, "old": [round(old[0], 1), round(old[1], 1)], "new": nw,
            "moved_m": round(((nw[0] - old[0]) ** 2 + (nw[1] - old[1]) ** 2) ** 0.5, 1)}
    if note: item["note"] = note
    item.update(kw)
    A.append(item)
    return nw

def anc_pts(id_, group, old_pts, kind, new_pts=None, note=None):
    d = G[group]
    nw = new_pts if new_pts is not None else [mv(p, d) for p in old_pts]
    item = {"id": id_, "group": group, "kind": kind, "old_points": old_pts, "new_points": nw, "moved_m": round(max(((a[0]-b[0])**2+(a[1]-b[1])**2)**0.5 for a, b in zip(old_pts, nw)), 1)}
    if note: item["note"] = note
    A.append(item)
    return nw

def anc_rect(id_, group, old_rect, kind, note=None):
    d = G[group]
    nw = [round(old_rect[0] + d[0], 1), round(old_rect[1] + d[1], 1), old_rect[2], old_rect[3]]
    item = {"id": id_, "group": group, "kind": kind, "old_rect": old_rect, "new_rect": nw, "moved_m": round((d[0]**2 + d[1]**2) ** 0.5, 1)}
    if note: item["note"] = note
    A.append(item)
    return nw

# port
spawn_port = anc("spawn_DepuisPort", "G_port", [120, 176.4], "spawn")
anc_rect("exit_port_ambre", "G_port", [116, 178.9, 8, 1.1], "exit")
anc("panneau_debarcadere", "G_port", [123.2, 169.2], "sign")
anc("spawn_Debarcadere", "G_port", [120, 156], "spawn", note="anciennes sauvegardes : sur la route, au sommet du Seuil")
# carrefour
maia = anc("Maia", "G_carrefour", [125.2, 88.8], "npc")
anc("panneau_carrefour", "G_carrefour", [114.8, 89.6], "sign")
anc("spawn_Carrefour", "G_carrefour", [120, 96], "spawn")
anc("feu_camp_carrefour", "G_carrefour", [112, 102], "rest")
voyageur = anc("GrandVoyageur", "G_carrefour", [106.8, 98], "npc_dino")
anc("spawn_Voyageur", "G_carrefour", [112.4, 96.8], "spawn")
anc("panneau_escale", "G_carrefour", [114, 100], "sign")
anc("CHIPIE_HIDE", "G_chipie", [118.4, 94.4], "scene_spot")
chipie_path = anc_pts("Chipie_path", "G_chipie", [[115, 85], [105, 81], [97, 75], [89, 71.2], [83.2, 69.6]], "npc_path")
nid = anc("NidChipie", "G_chipie", [81.2, 68.2], "story_prop")
oeuf = anc("rocher_oeuf", "G_oeuf", [130, 79.2], "prop")
anc("panneau_oeuf", "G_oeuf", [128, 80.6], "sign")
# bosquet
tronc = anc("TroncBosquet", "G_tronc", [40, 81.8], "obstacle_tranche")
ambre = anc("AmbreProtoceratops", "G_bosquet", [31.2, 55.2], "pickup")
anc_pts("props_bosquet", "G_bosquet", [[29, 53], [35.6, 50.4], [26.4, 60.8], [42.8, 58], [44, 52.4]], "props (fleurs_violettes, fleurs_roses, fougeres, fleurs_roses, souche)")
# grotte
anc("EntreeGrotte", "G_grotte", [116, 46], "cave_mouth")
anc_rect("exit_grotte_echos", "G_grotte", [114.4, 45.9, 3.2, 1.0], "exit")
anc("spawn_DepuisGrotte", "G_grotte", [116, 48.6], "spawn")
rocher = anc("RocherGrotte", "G_grotte", [116, 49.2], "obstacle_charge")
anc("panneau_grotte", "G_grotte", [122.4, 54.8], "sign")
anc_pts("props_grotte", "G_grotte", [[111.2, 51.6], [121.6, 51.6], [108.8, 52]], "props (rocher_grotte, cailloux, stalagmite)")
# porte / poste
porte = anc("PorteAmbre", "G_porte", [186, 76], "obstacle_resonance")
anc("spawn_Falaises", "G_porte", [186, 66], "spawn")
anc("poste_banc", "G_poste", [192, 24.8], "prop")
anc("panneau_falaises", "G_poste", [188.4, 25.2], "sign")
page3 = anc("page3", "G_poste", [196, 25.2], "pickup")
anc("ecaille_falaises", "G_poste", [200, 25.6], "pickup")
anc("table_observation", "G_poste", [200, 24.2], "prop")
anc("feu_camp_poste", "G_poste", [192, 20.8], "rest")
anc_pts("nids_dimorphodon", "G_poste", [[183, 18], [206, 19]], "props")
# crâne
antre = anc("AntreCrane", "G_crane", [208, 116], "cave_mouth")
anc_rect("exit_antre_crane", "G_crane", [205, 116, 6, 1.2], "exit")
anc("spawn_DepuisAntre", "G_crane", [208, 120], "spawn")
crane = anc("PorteCrane", "G_crane", [208, 124], "story_prop (grand_crane)")
panneau_crane = anc("panneau_crane", "G_crane", [200.8, 129.6], "sign")
ALPHA_NEW = [178.4, 110.0]   # hors du Grand Crâne modélisé (05/10) : la translation du groupe la mettait 0,6 m dans sa collision
anc("Alpha", "G_crane", [214.4, 127.6], "npc_dino", new=ALPHA_NEW, note='déplacée hors du Grand Crâne modélisé (05/10, intégration) : la translation du groupe la mettait en (178.4, 103.6), 0,6 m dans la collision du crâne ; écart au groupe (0, +6.4) m, vers le sud, sur le parvis plat (6,5 m), 4,5 m devant le crâne (un Tricératops Alpha de 10,8 m) : il sort toujours vers le sud-est')
anc("MaiaDefi", "G_crane", [201.6, 130.4], "npc")
anc("spawn_Crane", "G_crane", [200, 133], "spawn")
anc_pts("scene_crane", "G_crane", [[208, 117], [208, 126.4], [209.8, 124.6], [186, 131]], "scene_spots (DEN, MOUTH, OUT_OF_NOTCH, MAIA_FROM)")
# étang
gue = anc_rect("GueDeLune", "G_etang_ilot", [156, 90, 4, 4], "moon_ford", note="élargi à 6 x 5,5 m (131-137, 116-121.5) pour que le passage fasse 1,2 m une fois les pierres affleurantes")
gue[:] = [131, 116, 6, 6]
ilot = anc_rect("ilot", "G_etang_ilot", [156, 94, 4, 4], "islet")
anc("Page2", "G_etang_ilot", [157, 95.4], "pickup")
anc("pierre_plate", "G_etang_ilot", [157.8, 94.4], "prop")
anc("GaletIlot", "G_etang_ilot", [159, 96.8], "pickup")
panneau_etang = anc("panneau_etang", "G_etang", [162.8, 88.6], "sign")
singers = anc_pts("singer_spots", "G_etang", [[146.8, 95], [171, 95.2], [148.4, 101], [161, 102.8]], "scene_spots")
anc_pts("preles_etang", "G_etang", [[144.8, 91.2], [173.6, 100.4], [154, 105.6]], "props")
anc("CuirMue", "G_etang", [168.8, 100.4], "pickup")
anc("banc_etang", "G_etang", [150.8, 88.8], "rest")
anc_pts("props_etang", "G_etang", [[147, 92.4], [170.4, 90.6], [169.2, 99], [152.4, 102.8], [162, 103.2]], "props (fougere_arbre x2, fougeres, fleurs_roses, cailloux)")
# élise
anc("TriceratopsMalade", "G_elise", [164, 108.8], "npc_dino (show_flag havre_arrive)")
anc("CrottesTriceratops", "G_elise", [159.6, 110.2], "story_prop")
anc("Elise", "G_elise", [158.2, 112.6], "npc")
elise_rect = anc_rect("ELISE_SCENE", "G_elise", [153, 105, 16, 20], "keep_clear")
# dormeur, crique, forêt
anc("arbre_dormeur", "G_dormeur", [110.8, 132.8], "prop (arbre_rond)")
anc("Dormeur", "G_dormeur", [112.8, 134.8], "npc_dino")
anc("banc_dormeur", "G_dormeur", [125.6, 132], "rest")
anc("panneau_anse", "G_crique", [51, 133], "sign")
anc("feu_camp_crique", "G_crique", [63, 128], "rest")
anc("spawn_DepuisForet", "G_foret", [5, 104], "spawn")
anc_rect("exit_foret", "G_foret", [0, 100, 1.1, 8], "exit (verrou selle)")
# galets
anc_pts("galets_arbres", "G_libre", [[90, 128], [140, 144], [60, 104], [104, 72], [176, 116], [200, 48], [30, 66], [220, 150]], "pebbles_in_trees : UN ARBRE à chaque point",
        new_pts=[[90, 128], [140, 144], [60, 104], [104, 72], [180, 124], [200, 40], [30, 66], [220, 150]], note="(176,116) -> (180,124) au pied sud du tertre ; (200,48) -> (200,40) dans le vallon resserré")
anc_pts("galets_recoins", "G_libre", [[140, 30], [204, 20], [48, 142]], "pebbles_in_nooks : belvédère, terrasse haute, la Pointe", new_pts=[[138, 30], [204, 16], [48, 142]])
A.append({"id": "galets_pierres_et_enterres", "group": "G_libre", "kind": "pebbles", "note": "8 sous des pierres + 8 enterrés (Flair), graine 3007 : repris par ZoneSource puis passés par le champ de déformation ; vérifier qu'aucun ne tombe dans l'eau ou une paroi"})
A.append({"id": "habitats", "group": "G_libre", "kind": "habitats (dex_places.gd)", "old_rects": {"Prairies du sud": [72, 112, 88, 60], "Le carrefour": [52, 64, 100, 48], "Rive de la crique": [20, 112, 56, 48], "L'étang": [140, 86, 36, 22], "Le bosquet d'Hélène": [16, 40, 40, 40], "Les falaises": [162, 16, 60, 56], "Le Grand Crâne": [168, 96, 60, 76]},
          "new_rects": {"Prairies du sud": [72, 118, 88, 54], "Le carrefour": [44, 68, 100, 48], "Rive de la crique": [20, 112, 56, 48], "L'étang": [116, 112, 40, 24], "Le bosquet d'Hélène": [12, 36, 48, 50], "Les falaises": [160, 6, 72, 56], "Le Grand Crâne": [144, 66, 84, 60]},
          "note": "les habitats suivent les lieux : l'étang sous le parvis, le Grand Crâne au centre-est, les falaises = le vallon et les terrasses"})
A.append({"id": "KEEP_CLEAR_2d", "group": "G_libre", "kind": "keep_clear", "note": "les rectangles KEEP_CLEAR du 2,5D sont remplacés par `clearings` (ci-dessous) ; le semis 3D lit `clearings`, pas KEEP_CLEAR"})

# ------------------------------------------------------------------ le plan
L = {
 "schema": "ambrelune-zone-layout/2",
 "_doc": {
  "lecture": "Voir docs/conception-zones-3d.md § Format. Positions en mètres dans le repère 3D de la zone (ZoneSource) : origine au coin NORD-OUEST, x vers l'EST (0..size_m[0]), z vers le SUD (0..size_m[1]), y = hauteur (m) au-dessus de la mer (0). Case 2,5D (tx, ty) -> (tx*2, ty*2).",
  "relief": "Modificateurs appliqués DANS L'ORDRE sur `base_m`. kinds : dome (center, radii [rx, rz], rot_deg, height = delta, flat = part du rayon à plat) ; plateau (polygon ou center+radii, level absolu, edge_m = largeur de la paroi/talus, wobble_m = ondulation du bord) ; ridge (points, half_width_m, height, falloff_m ; absolute: true = hauteur absolue) ; gradient (axis x|z, from [coord, h], to [coord, h], op max) ; water_basin (polygon, level, depth, inner_m, outer_m) ; carve (points, width_m, levels [h0, h1] le long de la ligne OU follow_ground+offset_m, blend_m : rabote le sol) ; noise (amplitude_m, wavelength_m, clear_paths_m) ; après l'eau : plateau_ellipse_after_water (îlot), rect_after_water (gué). op : add | max | set.",
  "paths": "Polylignes ; kind main (3 m, ocre), secondary (sente 1,8 m), trail (piste 1,2-1,5 m). Le sol est raboté sous le sentier (profil lissé, pente ≤ grade_max_deg). clear_m : aucun décor solide à moins de cette distance du bord.",
  "areas": "Secteurs d'ambiance : polygone, végétation par strate en instances / 100 m² (canopy, understory, ground) avec essences pondérées, props_set, tall_grass (herbes hautes de rencontre, sans décor), calm (zone calme : rien de moyen/grand hors ancres).",
  "blockers": "Ce qui arrête Chloé et POURQUOI on le voit. Jamais de mur invisible.",
  "anchors": "Chaque ancre : group (groupe de scène, translation pure), old (2,5D x2, m), new (m), moved_m. Les scènes passent par le champ de déformation old -> new. Les points d'un groupe gardent leurs distances et leurs directions (pas de rotation).",
  "frame_check": "ancre A à la case 2,5D (tx,ty) : old = (2tx, 2ty) ; sa position 3D après déformation = new."
 },
 "zone": "plaines", "name": "Prairie du Grand Crâne", "size_m": [240, 180], "tile_scale": 2,
 "frame": {"origin": "coin nord-ouest", "x": "est", "z": "sud", "y": "hauteur (m), mer = 0"},
 "parti": "L'amphithéâtre du Crâne : une cuvette douce (3 m) cernée de hauteurs ; au cœur, le tertre du Grand Crâne (10 m) que l'on voit de partout et dont le parvis domine l'Étang des Chanteurs ; le carrefour de Maïa à son pied sud-ouest ; les trois passages tout autour à distance égale (bosquet à l'ouest, Grotte au nord, porte d'ambre au nord-est par le corridor des Vertèbres) ; le Seuil du Port (6 m) qui cache tout jusqu'à la révélation.",
 "size_note": "240 x 180 m conservés (le raccord avec Port-Ambre et la Forêt reste à l'identique). Le nord est resserré (vallon des Nids z 24-58, terrasses z 8-38). Option : +20 m au nord (240 x 200) si l'on veut des terrasses plus amples ; tout ce qui est au nord de z 80 glisserait de 20 m.",
 "levels_m": {"mer": 0.0, "plage": 0.6, "prairie": 3.0, "cuvette": 2.8, "etang_eau": 2.4, "etang_fond": 0.8, "butte_carrefour": 3.8, "seuil_port": 5.8, "bosquet_helene": 5.0, "hauts_du_col": 5.5, "colline_grotte": 9.5, "rempart": 10.0, "vallon_des_nids": 7.0, "terrasse_basse": 10.0, "poste": 14.0, "tertre_crane": 10.0, "parvis": 6.5, "montagnes_nord": 36.0, "montagnes_est": 26.0},
 "relief": {"base_m": 3.0, "modifiers": [
  {"id": "cuvette", "kind": "dome", "center": [132, 110], "radii": [60, 40], "rot_deg": 0, "height": -0.5, "flat": 0.3, "op": "add", "note": "la cuvette : l'eau s'y rassemble (l'étang est son point bas)"},
  {"id": "noise_prairie", "kind": "noise", "amplitude_m": 0.55, "wavelength_m": 26, "clear_paths_m": 6, "op": "add", "note": "ondulations de la prairie, jamais de marche ; nulles près des sentiers et dans les clairières"},
  {"id": "mer", "kind": "water_basin", "polygon": [[0, 134], [14, 132], [28, 134], [42, 139], [47, 141], [50, 145], [56, 148], [64, 152], [72, 156], [78, 162], [82, 170], [84, 180], [0, 180]], "level": 0.0, "depth": 3.0, "inner_m": 6, "outer_m": 9, "op": "set", "note": "la crique : plage de sable en pente douce, fond à -3 m"},
  {"id": "pointe", "kind": "dome", "center": [48, 141], "radii": [7, 5], "rot_deg": -30, "height": 1.6, "flat": 0.3, "op": "add", "note": "la Pointe : rocher qui avance dans la crique"},
  {"id": "seuil_port", "kind": "ridge", "points": [[100, 164], [124, 163], [150, 161], [174, 158]], "half_width_m": 6, "height": 2.8, "falloff_m": 12, "op": "add", "note": "le Seuil du Port : dos de terrain (5,8 m) qui cache la cuvette jusqu'au sommet de la côte"},
  {"id": "butte_carrefour", "kind": "dome", "center": [110, 99], "radii": [11, 9], "rot_deg": 0, "height": 1.0, "flat": 0.35, "op": "add", "note": "la butte du panneau"},
  {"id": "bosquet_helene", "kind": "dome", "center": [36, 60], "radii": [32, 27], "rot_deg": 10, "height": 2.0, "flat": 0.45, "op": "add"},
  {"id": "bois_chipie", "kind": "dome", "center": [72, 64], "radii": [17, 12], "rot_deg": 0, "height": 1.2, "flat": 0.3, "op": "add"},
  {"id": "bois_crique", "kind": "dome", "center": [66, 116], "radii": [15, 11], "rot_deg": 20, "height": 1.0, "flat": 0.3, "op": "add"},
  {"id": "bois_sud_est", "kind": "dome", "center": [176, 148], "radii": [19, 14], "rot_deg": 0, "height": 1.6, "flat": 0.3, "op": "add"},
  {"id": "hauts_du_col", "kind": "dome", "center": [146, 40], "radii": [16, 24], "rot_deg": 0, "height": 2.5, "flat": 0.4, "op": "add", "note": "les Hauts du Col, entre la colline et l'éperon"},
  {"id": "colline_grotte", "kind": "dome", "center": [114, 30], "radii": [27, 19], "rot_deg": 0, "height": 6.5, "flat": 0.3, "op": "add", "note": "la colline de la Grotte : dôme, flancs 30-35° praticables"},
  {"id": "face_sud_grotte", "kind": "plateau", "center": [114, 30], "radii": [16, 13], "rot_deg": 0, "level": 9.5, "edge_m": 2.5, "wobble_m": 2.0, "op": "max", "note": "le cirque rocheux au-dessus de la bouche : paroi"},
  {"id": "encoche_grotte", "kind": "carve", "points": [[116, 58], [116, 52], [116, 44]], "width_m": 7, "levels": [3.6, 3.8], "blend_m": 2.0, "op": "set", "note": "l'encoche de la Grotte, 7 m de large, murs de 4 à 6 m"},
  {"id": "rampe_belvedere", "kind": "carve", "points": [[146, 46], [140, 40], [134, 34], [128, 29]], "width_m": 4.5, "levels": [5.3, 9.5], "blend_m": 3, "op": "set", "note": "rampe est vers le belvédère (14 %)"},
  {"id": "rempart_falaises", "kind": "ridge", "points": [[156, 60], [240, 56]], "half_width_m": 3.0, "height": 10.0, "falloff_m": 3.0, "wobble_m": 1.5, "op": "max", "absolute": True, "note": "le rempart : crête 10 m, face sud de 7 m zébrée d'ambre, pied vers z 65-67 ; la gorge le perce à x 190"},
  {"id": "eperon_ouest", "kind": "ridge", "points": [[158, 62], [158, 8]], "half_width_m": 3.0, "height": 10.0, "falloff_m": 4, "wobble_m": 2.0, "op": "max", "absolute": True, "note": "l'éperon qui ferme le vallon à l'ouest"},
  {"id": "vallon_des_nids", "kind": "plateau", "polygon": [[166, 56], [224, 54], [232, 42], [226, 26], [200, 24], [176, 28], [166, 40]], "level": 7.0, "edge_m": 5, "wobble_m": 3.0, "op": "max", "note": "derrière la porte : le vallon caché, 7 m"},
  {"id": "terrasse_basse", "kind": "plateau", "polygon": [[174, 38], [218, 38], [222, 26], [216, 14], [178, 14], [172, 26]], "level": 10.0, "edge_m": 2.0, "wobble_m": 3.0, "op": "max"},
  {"id": "terrasse_haute", "kind": "plateau", "polygon": [[180, 26], [212, 26], [214, 8], [180, 8]], "level": 14.0, "edge_m": 2.0, "wobble_m": 3.0, "op": "max", "note": "le poste d'observation d'Hélène, 14 m : toute la Prairie en bas"},
  {"id": "gorge_porte", "kind": "carve", "points": [[190, 74], [190, 64], [190, 56], [188, 48]], "width_m": 5.0, "levels": [3.0, 7.0], "blend_m": 1.5, "op": "set", "note": "la gorge de la porte d'ambre : 5 m de large, parois de 7 m, 9° de pente ; la porte à (190,64)"},
  {"id": "ravin_terrasse_1", "kind": "carve", "points": [[188, 46], [192, 40], [194, 34]], "width_m": 4.0, "levels": [7.0, 10.0], "blend_m": 2.0, "op": "set", "note": "le ravin vers la terrasse basse"},
  {"id": "ravin_terrasse_2", "kind": "carve", "points": [[194, 32], [188, 28], [190, 22], [194, 20]], "width_m": 3.5, "levels": [10.0, 14.0], "blend_m": 2.0, "op": "set", "note": "la dernière montée au poste"},
  {"id": "tertre_crane", "kind": "plateau", "center": [176, 88], "radii": [22, 12], "rot_deg": -10, "level": 10.0, "edge_m": 5, "wobble_m": 2.5, "op": "max", "note": "le tertre du Crâne : flancs raides (roche, racines, araucarias) ; paroi autour de l'encoche seulement"},
  {"id": "parvis_crane", "kind": "plateau", "polygon": [[148, 102], [188, 100], [192, 110], [184, 118], [150, 116]], "level": 6.5, "edge_m": 3, "wobble_m": 1.5, "op": "set", "note": "le parvis : plat, 6,5 m, de x 148 à 190 : le couloir de Maïa (MAIA_FROM 150,107 -> 165,106) y est plat ; duel, sortie de l'Alpha"},
  {"id": "encoche_crane", "kind": "carve", "points": [[172, 106], [172, 98], [172, 88]], "width_m": 8, "levels": [6.5, 6.5], "blend_m": 1.5, "op": "set", "note": "l'encoche du Crâne, 8 m : le crâne la remplit, l'antre au fond (172,92)"},
  {"id": "rampe_parvis", "kind": "carve", "points": [[124, 103], [136, 106], [148, 108]], "width_m": 7, "levels": [3.2, 6.5], "blend_m": 4, "op": "set", "note": "la rampe des Vertèbres : du carrefour au parvis (8,5°), finie à x 148"},
  {"id": "montagnes_nord", "kind": "gradient", "axis": "z", "from": [12, 10.0], "to": [-8, 36.0], "wobble_m": 4.0, "op": "max", "note": "fond de décor : montagnes du nord"},
  {"id": "montagnes_est", "kind": "gradient", "axis": "x", "from": [227, 3.0], "to": [240, 26.0], "wobble_m": 4.0, "op": "max", "note": "les Monts à l'est : paroi, éboulis au pied"},
  {"id": "lisiere_ouest", "kind": "dome", "center": [0, 60], "radii": [26, 70], "rot_deg": 0, "height": 1.5, "flat": 0.2, "op": "add"},
  {"id": "ilot", "kind": "plateau_ellipse_after_water", "center": [134, 124], "radii": [2.6, 2.4], "level": 2.9, "edge_m": 1.8, "after_water": True, "note": "l'îlot : rehaussé à 2,9 m APRÈS le creusement de l'étang"},
  {"id": "gue_de_lune", "kind": "rect_after_water", "rect": gue, "level": 2.3, "blend_m": 1.0, "after_water": True, "note": "le gué : haut-fond à 2,3 m (0,1 m d'eau : les pierres affleurent) de la rive nord à l'îlot ; les pierres d'ambre affleurent à la pleine lune (MoonFord)"},
  {"id": "vallee_du_ru", "kind": "carve", "points": [[123, 126], [118, 127], [106, 126], [94, 130], [84, 137], [76, 146], [70, 152]], "width_m": 2.4, "follow_ground": True, "offset_m": -0.5, "blend_m": 2.5, "op": "set", "note": "le ru de l'étang : lit raboté 0,5 m sous le sol, berges de 2,5 m"}
 ]},
 "water": [
  {"id": "mer_crique", "kind": "sea", "level": 0.0, "ref": "relief.mer", "note": "eau profonde : bloque (pas de nage au ch. 1) ; plage praticable"},
  {"id": "etang", "kind": "pond", "level": 2.4, "ellipse": {"center": [134, 123], "radii": [11.5, 7]}, "depth": 1.6, "note": "l'Étang des Chanteurs, SOUS LE PARVIS du Crâne : rive praticable tout autour, l'îlot et le gué d'ambre (G_etang) ; profond au milieu (bloque)"},
  {"id": "anse_roseaux", "kind": "pond_part", "level": 2.4, "ref": "la pointe est de l'étang (x 140-146)", "depth": 0.5, "note": "l'anse aux roseaux : la pointe est de l'étang, peu profonde, roseaux, prêles, une bille de bois"},
  {"id": "source_crane", "kind": "spring", "at": [156, 120], "note": "LA SOURCE DU CRÂNE : l'eau sort de sous le tertre, au pied du parvis (bassin de roche 2 m), et file en 10 m vers la pointe est de l'étang (l'anse aux roseaux). L'eau de la Prairie naît sous le Crâne : étang → ru → crique, lisible par le joueur"},
  {"id": "ru", "kind": "brook", "level": "suit le sol (plugin Waterways)", "points": [[123, 126], [118, 127], [106, 126], [94, 130], [84, 137], [76, 146], [70, 152]], "width_m": 2.2, "depth": 0.3, "note": "le ru : 0,3 m, NE BLOQUE PAS ; gué de pierres plates sur la route du port à (118,127) ; embouchure dans la crique (70,152). Repli sans Waterways : deux nappes plates (2,4 m jusqu'au gué, 0,3 m après) avec un ressaut au gué"},
  {"id": "cascade_monts", "kind": "waterfall", "at": [230, 84], "height_m": 12, "note": "filet d'eau de fonte des Monts dans une vasque (éboulis du nord) ; décor + son ; sans suite (il s'infiltre)"}
 ],
 "paths": [
  {"id": "route_port", "kind": "main", "width_m": 3.0, "clear_m": 1.5, "grade_max_deg": 12, "points": [[120, 180], [120, 171], [120, 163], [119, 152], [118, 140], [118, 127], [116, 116], [112, 106], [111, 101]], "note": "Port-Ambre -> le Seuil (5,8 m) -> le gué du ru -> la butte du carrefour"},
  {"id": "route_grotte", "kind": "main", "width_m": 3.0, "clear_m": 1.5, "grade_max_deg": 10, "points": [[110, 97], [113, 84], [115, 70], [116, 58], [116, 52]], "note": "carrefour -> l'encoche de la Grotte (rocher de Charge à 116,49)"},
  {"id": "route_bosquet", "kind": "main", "width_m": 3.0, "clear_m": 1.5, "grade_max_deg": 12, "points": [[106, 101], [92, 100], [80, 99], [70, 98], [64, 92], [58, 86], [54, 78], [47, 68], [38, 60], [33, 57]], "note": "carrefour -> prairie du Grand Voyageur -> le chemin creux -> le tronc (58,86) -> la clairière d'Hélène"},
  {"id": "route_crane", "kind": "main", "width_m": 3.0, "clear_m": 1.5, "grade_max_deg": 10, "points": [[115, 101], [124, 103], [136, 106], [148, 108], [160, 109], [168, 107], [172, 104]], "note": "carrefour -> rive nord de l'étang -> la rampe des Vertèbres -> l'arche -> le parvis du Crâne"},
  {"id": "route_corridor", "kind": "main", "width_m": 3.0, "clear_m": 1.5, "grade_max_deg": 10, "points": [[114, 96], [122, 86], [134, 76], [148, 70], [166, 70], [182, 72], [190, 74]], "note": "le corridor entre le tertre et le rempart : du carrefour à l'embouchure de la gorge de la porte d'ambre"},
  {"id": "sentier_gorge", "kind": "secondary", "width_m": 2.0, "clear_m": 1.2, "grade_max_deg": 15, "points": [[190, 74], [190, 64], [190, 56], [188, 48], [192, 40], [194, 34], [188, 28], [190, 22], [194, 20]], "note": "la gorge, la porte (190,64), le vallon, le ravin, les terrasses, le poste"},
  {"id": "sentier_vallon", "kind": "trail", "width_m": 1.5, "clear_m": 1.0, "grade_max_deg": 12, "points": [[190, 54], [200, 48], [212, 44], [222, 40]], "note": "le tour du vallon des Nids"},
  {"id": "sente_belvedere", "kind": "secondary", "width_m": 1.8, "clear_m": 1.2, "grade_max_deg": 12, "points": [[118, 62], [128, 58], [138, 54], [146, 46], [140, 40], [134, 34], [128, 29], [118, 26]], "note": "de l'encoche, la sente monte par les Hauts du Col au belvédère (galet 138,30)"},
  {"id": "sente_chipie", "kind": "trail", "width_m": 1.2, "clear_m": 1.0, "grade_max_deg": 8, "points": chipie_path, "note": "la course de Chipie : herbe foulée jusqu'au nid"},
  {"id": "sente_crique", "kind": "secondary", "width_m": 1.8, "clear_m": 1.2, "grade_max_deg": 12, "points": [[114, 131], [104, 132], [92, 136], [82, 143], [72, 141], [62, 131], [52, 134], [49, 138]], "note": "du gué, le long du ru puis au-dessus de la plage : le feu, le panneau, la Pointe"},
  {"id": "sente_foret", "kind": "secondary", "width_m": 2.0, "clear_m": 1.2, "grade_max_deg": 8, "points": [[70, 98], [54, 103], [34, 106], [16, 104], [0, 104]], "note": "la piste vers la Forêt (sortie z 100-108, verrou « selle » par dialogue)"},
  {"id": "sente_sud", "kind": "trail", "width_m": 1.4, "clear_m": 1.0, "grade_max_deg": 8, "points": [[54, 103], [50, 114], [56, 124], [62, 130]], "note": "boucle sud : de la piste au bois de la crique"},
  {"id": "sente_dormeur", "kind": "trail", "width_m": 1.4, "clear_m": 1.0, "grade_max_deg": 8, "points": [[118, 134], [121, 142], [125, 151], [138, 158], [150, 160]], "note": "du gué, le long de la prairie d'Élise (sans y entrer) jusqu'au Seuil et à la grande boucle de l'est"},
  {"id": "sente_rive_sud", "kind": "trail", "width_m": 1.4, "clear_m": 1.0, "grade_max_deg": 6, "points": [[122, 118], [121, 126], [124, 132], [134, 134], [144, 131], [149, 125], [150, 115]], "note": "le tour de l'étang par la rive des chanteurs (banc, peau muée), jusqu'à la source"},
  {"id": "sente_est", "kind": "secondary", "width_m": 1.8, "clear_m": 1.2, "grade_max_deg": 12, "points": [[192, 76], [206, 80], [218, 88], [224, 100], [222, 114], [214, 124], [206, 132], [196, 142], [180, 152], [160, 158], [150, 160]], "note": "la grande boucle de l'est : du pied du rempart, les éboulis et la cascade, le dos du tertre, le bois du Sud-Est, retour au Seuil"},
  {"id": "sente_cascade", "kind": "trail", "width_m": 1.4, "clear_m": 1.0, "grade_max_deg": 12, "points": [[218, 88], [226, 86]], "note": "jusqu'à la vasque de la cascade"},
  {"id": "sente_eboulis", "kind": "trail", "width_m": 1.4, "clear_m": 1.0, "grade_max_deg": 12, "points": [[206, 132], [216, 142], [222, 152], [222, 166]], "note": "les éboulis du sud : galet (220,150), herbes hautes, ankylosaures la nuit"}
 ],
 "areas": [],
 "landmarks": [
  {"id": "grand_crane", "name": "Le Grand Crâne", "type": "hero_prop", "at": crane, "yaw_deg": 180, "size_m": [16, 9, 12], "visible_from": "le Seuil (60 m), le carrefour (62 m), l'étang (juste en dessous), le belvédère, le poste, le corridor", "note": "crâne fossile géant (cératopsien), vrai modèle 3D, trois serrures d'ambre qui luisent ; face au sud, au-dessus de l'étang ; remplit l'encoche du tertre ; la gueule = la porte de l'antre"},
  {"id": "rempart_ambre", "name": "Le Rempart d'ambre (les Falaises)", "type": "cliff", "at": [198, 62], "size_m": [84, 7, 6], "visible_from": "partout dans la cuvette", "note": "paroi de 7 m zébrée de veines d'ambre (émissives la nuit) ; la gorge en est l'encoche sombre"},
  {"id": "colline_grotte", "name": "La Colline de la Grotte", "type": "hill", "at": [114, 30], "size_m": [54, 6.5, 38], "visible_from": "le carrefour (70 m), le Seuil", "note": "sommet 9,5 m ; face sud en cirque rocheux, la bouche au fond ; un araucaria penché au sommet (belvédère)"},
  {"id": "arbre_helene", "name": "L'Arbre d'Hélène", "type": "giant_tree", "at": [30, 58], "size_m": [10, 15, 10], "visible_from": "le carrefour (90 m), le Seuil, le belvédère", "note": "araucaria de 15 m, le plus haut de la zone : il marque le bosquet depuis partout"},
  {"id": "portes_du_seuil", "name": "Les Portes du Seuil", "type": "rock_gate", "at": [120, 163], "size_m": [10, 3, 3], "visible_from": "la route depuis le port", "note": "deux rochers de 3 m de part et d'autre de la route au sommet du Seuil, un araucaria derrière chacun : le cadre de la révélation"},
  {"id": "vertebres", "name": "Les Vertèbres", "type": "prop_line", "at": [138, 102], "size_m": [3, 2.5, 3], "visible_from": "le carrefour, la rive nord de l'étang", "note": "cinq vertèbres géantes le long de la rampe : (126,101) (132,103.5) (138,104) (144,106) (150,110.5) ; l'arche des côtes à (146,107), à l'entrée du parvis ; le crâne au bout"},
  {"id": "grand_voyageur", "name": "Le Grand Voyageur", "type": "npc_dino", "at": voyageur, "size_m": [12, 11, 4], "visible_from": "partout dans la cuvette", "note": "le brachiosaure (ancre) : repère vivant du carrefour"},
  {"id": "pointe", "name": "La Pointe", "type": "rock", "at": [48, 141], "size_m": [8, 2, 6], "visible_from": "la plage", "note": "promontoire dans la crique : galet caché, vue sur la mer"},
  {"id": "poste_observation", "name": "Le Poste d'observation d'Hélène", "type": "terrace", "at": [196, 18], "size_m": [30, 0, 14], "visible_from": "le vallon ; de là-haut toute la Prairie", "note": "terrasse à 14 m ; table, banc, feu, panneau, longue-vue"},
  {"id": "montagnes", "name": "Les Monts (nord et est)", "type": "backdrop", "at": [240, 0], "size_m": [240, 36, 20], "visible_from": "partout", "note": "roche, névés ; les Monts Gelés sont de ce côté"}
 ],
 "vignettes": [
  {"id": "V01", "name": "L'arrivée du port", "at": [121, 170], "yaw_deg": 0, "type": "entrée", "elements": ["panneau_debarcadere (123.2,169.2)", "deux souches", "cailloux", "ornières"], "clear_radius": 6},
  {"id": "V02", "name": "Les Portes du Seuil", "at": [120, 163], "yaw_deg": 0, "type": "repère", "elements": ["rocher_3m (115,163) et (125,164)", "araucaria derrière chacun", "fleurs_jaunes en dérive", "la vue : le Crâne droit devant, à 60 m, au-dessus de l'étang"], "clear_radius": 7},
  {"id": "V03", "name": "Le gué du ru", "at": [118, 127], "yaw_deg": 90, "type": "passage", "elements": ["pas_japonais x5", "pont_rondins moussu à côté", "prele x6", "pierre_plate", "libellules"], "clear_radius": 5},
  {"id": "V04", "name": "La butte du carrefour", "at": [110, 99], "yaw_deg": 180, "type": "hub", "elements": ["panneau_carrefour", "Maïa", "rocher_plat_banc", "feu_camp", "panneau_escale", "Grand Voyageur"], "clear_radius": 14},
  {"id": "V05", "name": "Le rocher-œuf", "at": oeuf, "yaw_deg": 200, "type": "clin d'œil", "elements": ["rocher_oeuf", "panneau_oeuf", "anneau de cailloux en « nid »", "fleurs_roses"], "clear_radius": 4},
  {"id": "V06", "name": "La course de Chipie", "at": chipie_path[2], "yaw_deg": 300, "type": "sente", "elements": ["herbe foulée", "objets brillants perdus en chemin", "buisson_nid au pied du bois"], "clear_radius": 3},
  {"id": "V07", "name": "L'encoche de la Grotte", "at": [116, 50], "yaw_deg": 0, "type": "passage", "elements": ["rocher_charge (116,49.2) 3 m fissuré", "rocher_grotte", "stalagmite", "cailloux", "eboulis au pied des parois", "panneau_grotte", "bouche sombre (116,46)"], "clear_radius": 8},
  {"id": "V08", "name": "Le belvédère", "at": [128, 29], "yaw_deg": 180, "type": "récompense", "elements": ["araucaria penché", "rocher_plat_banc", "galet caché (138,30)", "vue sur toute la zone"], "clear_radius": 6},
  {"id": "V09", "name": "La porte d'ambre", "at": porte, "yaw_deg": 0, "type": "passage", "elements": ["porte_ambre 3D, fougère gravée", "veines d'ambre dans les parois", "arche_pierre au-dessus de la gorge (190,60)", "fougeres en lit", "blocs tombés"], "clear_radius": 6},
  {"id": "V10", "name": "La source du Crâne", "at": [156, 120], "yaw_deg": 300, "type": "détail vivant", "elements": ["bassin de roche 2 m sous le pied du parvis", "filet d'eau vers l'anse", "prele", "fleurs_violettes", "cailloux mouillés", "mousse"], "clear_radius": 4},
  {"id": "V11", "name": "Le poste d'observation", "at": [196, 20], "yaw_deg": 180, "type": "récompense", "elements": ["banc", "panneau_falaises", "page3", "ecaille", "table_observation", "feu_camp", "longue_vue", "nids sur les corniches", "galet caché (204,16)"], "clear_radius": 8},
  {"id": "V12", "name": "L'anse aux roseaux", "at": [145, 122], "yaw_deg": 220, "type": "détail vivant", "elements": ["roseaux x12", "prêles", "bille_bois", "nénuphars", "libellules"], "clear_radius": 3},
  {"id": "V13", "name": "L'îlot et le gué de lune", "at": [134, 124], "yaw_deg": 0, "type": "récompense", "elements": ["pierre_plate", "page2", "galet", "gué d'ambre sous l'eau", "panneau_etang sur la rive nord"], "clear_radius": 4},
  {"id": "V14", "name": "La rive des chanteurs", "at": [132, 130], "yaw_deg": 0, "type": "scène", "elements": ["4 emplacements des chanteurs : rive de sable nue, face au Crâne", "banc", "peau_mue", "fougere_arbre x2", "prêles"], "clear_radius": 6},
  {"id": "V15", "name": "Les Vertèbres", "at": [138, 104], "yaw_deg": 150, "type": "repère", "elements": ["vertebre_geante x5", "femur_geant (140,103) à demi enterré", "cote_geante x3 dressées"], "clear_radius": 2},
  {"id": "V16", "name": "L'arche des côtes", "at": [146, 107], "yaw_deg": 95, "type": "repère", "elements": ["deux côtes de 9 m jointes, portée 6 m, 5 m de haut : la route passe dessous", "lichen", "fleurs_jaunes"], "clear_radius": 4},
  {"id": "V17", "name": "Le parvis du Crâne", "at": [168, 108], "yaw_deg": 0, "type": "scène", "elements": ["grand_crane", "panneau_crane", "MaiaDefi", "Alpha après ouverture", "cristaux_ambre aux serrures", "os_dino x4", "rocher_plat_banc (164,114)", "vue plongeante sur l'étang"], "clear_radius": 12},
  {"id": "V18", "name": "L'arbre du dormeur", "at": [111, 133], "yaw_deg": 0, "type": "clin d'œil", "elements": ["arbre_rond", "Dormeur protoceratops", "champignons", "herbe aplatie", "banc au bord de l'étang (125.6,132)"], "clear_radius": 5},
  {"id": "V19", "name": "La crique", "at": [56, 132], "yaw_deg": 200, "type": "récompense", "elements": ["panneau_anse", "feu_camp", "bois_flotte x3", "rocher_cote x2", "coquillages", "la Pointe", "embouchure du ru"], "clear_radius": 6},
  {"id": "V20", "name": "La prairie d'Élise", "at": [134, 136], "yaw_deg": 180, "type": "scène", "elements": ["TriceratopsMalade", "crottes", "Élise", "rien d'autre"], "clear_radius": 10},
  {"id": "V21", "name": "La lisière de la Forêt", "at": [10, 104], "yaw_deg": 270, "type": "sortie", "elements": ["tronc_couche_12m en travers à demi (passage de 3 m)", "fougere_geante x6", "souche_geante", "champignons", "ornières"], "clear_radius": 4},
  {"id": "V22", "name": "Les éboulis du sud", "at": [220, 150], "yaw_deg": 270, "type": "récompense", "elements": ["eboulis", "rocher_3m x3", "galet caché (220,150)", "araucaria", "lieu de sommeil des ankylosaures"], "clear_radius": 6},
  {"id": "V23", "name": "Le tronc de Tranche", "at": tronc, "yaw_deg": 0, "type": "passage", "elements": ["tronc_tranche 5 m, moussu, en travers du chemin creux", "haie_ronces sur les deux talus", "fleurs visibles au-delà", "champignons"], "clear_radius": 5},
  {"id": "V24", "name": "La clairière d'Hélène", "at": [31, 56], "yaw_deg": 0, "type": "récompense", "elements": ["arbre_helene (30,58)", "ambre sur pierre_mousse", "souche_banc (44,52.4)", "fleurs", "tapis_fleurs en anneau", "galet caché (30,66)"], "clear_radius": 9},
  {"id": "V25", "name": "La clairière du bois du Sud-Est", "at": [176, 148], "yaw_deg": 0, "type": "récompense", "elements": ["tronc_couche_12m", "champignons", "souche", "une trouée de soleil"], "clear_radius": 6},
  {"id": "V26", "name": "La cascade des Monts", "at": [228, 86], "yaw_deg": 90, "type": "récompense", "elements": ["cascade 12 m sur la paroi", "vasque 3 m", "eboulis", "rocher_3m x2", "prele", "brume de gouttes"], "clear_radius": 5},
  {"id": "V27", "name": "Le dos du tertre", "at": [214, 124], "yaw_deg": 270, "type": "sente", "elements": ["racines géantes qui sortent du tertre", "araucarias noueux", "compsognathus par bandes", "une côte dressée (210,118)"], "clear_radius": 3}
 ],
 "clearings": [
  {"id": "C_port", "center": [120, 172], "radius": 10, "reason": "arrivée"},
  {"id": "C_seuil", "center": [120, 163], "radius": 8, "reason": "la révélation : rien ne bouche la vue"},
  {"id": "C_carrefour", "center": [117, 97], "radius": 18, "reason": "hub autour de Maïa (audit : 24 m dégagés sans arbre, Chipie y court) : rien de solide ; au-delà de 18 m jusqu'à 24 m, rien de plus haut qu'un buisson"},
  {"id": "C_voyageur", "center": voyageur, "radius": 8, "reason": "le brachiosaure (12 m)"},
  {"id": "C_grotte", "center": [116, 52], "radius": 8, "reason": "scène du rocher de Charge, sortie de grotte"},
  {"id": "C_porte", "center": [190, 66], "radius": 6, "reason": "scène de la porte (Résonance)"},
  {"id": "C_poste", "center": [196, 20], "radius": 8, "reason": "poste d'observation"},
  {"id": "C_parvis", "center": [168, 108], "radius": 12, "reason": "duel Maïa n° 1, sortie de l'Alpha, ouverture du crâne"},
  {"id": "C_etang_nord", "center": [134, 117], "radius": 6, "reason": "gué de lune, panneau, banc"},
  {"id": "C_chanteurs", "center": [132, 128], "radius": 10, "reason": "rive des chanteurs"},
  {"id": "C_elise", "center": [134, 139], "radius": 12, "reason": "ELISE_SCENE (caméra vers le nord)"},
  {"id": "C_dormeur", "center": [112, 134], "radius": 5, "reason": "le dormeur"},
  {"id": "C_nid", "center": nid, "radius": 4, "reason": "le nid de Chipie"},
  {"id": "C_clairiere_helene", "center": [31, 56], "radius": 9, "reason": "page 1, écaille, fragment"},
  {"id": "C_tronc", "center": tronc, "radius": 5, "reason": "scène du tronc"},
  {"id": "C_crique", "center": [56, 132], "radius": 5, "reason": "panneau et feu"},
  {"id": "C_foret", "center": [6, 104], "radius": 5, "reason": "sortie ouest"},
  {"id": "C_belvedere", "center": [128, 29], "radius": 5, "reason": "la vue"},
  {"id": "C_oeuf", "center": oeuf, "radius": 4, "reason": "rocher-œuf"},
  {"id": "C_ilot", "center": [134, 124], "radius": 4, "reason": "l'îlot"},
  {"id": "C_cascade", "center": [226, 88], "radius": 5, "reason": "la vasque"},
  {"id": "C_source", "center": [156, 120], "radius": 3, "reason": "la source"}
 ],
 "blockers": [
  {"id": "haie_bosquet", "kind": "hedge", "height_m": 1.6, "width_m": 3.5, "closed": True, "polyline": [[58, 86], [66, 78], [70, 60], [62, 40], [36, 36], [12, 42], [4, 62], [10, 80], [34, 90], [50, 92]], "gap": {"at": tronc, "width_m": 4.5, "closed_by": "tronc_tranche"}, "reason": "la haie de ronces et de blocs qui ferme le bosquet : visiblement infranchissable (1,6 m d'épines, troncs couchés), seule ouverture : le chemin creux barré par le tronc"},
  {"id": "talus_chemin_creux", "kind": "bank", "height_m": 1.8, "width_m": 2.0, "polyline": [[72, 96], [66, 90], [61, 84]], "polyline2": [[66, 101], [60, 95], [55, 89]], "reason": "les deux talus du chemin creux : terre + ronces (1,8 m > saut 0,65 m)"},
  {"id": "tronc_tranche", "kind": "trunk", "at": tronc, "length_m": 5.0, "diameter_m": 1.1, "ability": "tranche", "reason": "obstacle d'histoire (Tranche)"},
  {"id": "rocher_charge", "kind": "boulder", "at": rocher, "diameter_m": 3.0, "eboulis_m": 3.0, "ability": "charge", "reason": "obstacle d'histoire (Charge) : bouche l'encoche de 7 m avec des éboulis solides de part et d'autre"},
  {"id": "porte_ambre", "kind": "door", "at": porte, "width_m": 5.0, "height_m": 4.0, "ability": "resonance", "reason": "obstacle d'histoire (Résonance) : remplit la gorge"},
  {"id": "grand_crane", "kind": "door", "at": crane, "width_m": 8.0, "height_m": 9.0, "ability": "trois écailles (crane_ouvert)", "reason": "le crâne remplit l'encoche ; sa gueule est scellée d'ambre jusqu'à `crane_ouvert`"},
  {"id": "gue_de_lune", "kind": "moon_ford", "rect": gue, "reason": "haut-fond à 0,5 m sous l'eau : bloqué par la logique du jeu sauf à la pleine lune (MoonFord)"},
  {"id": "parois", "kind": "cliff", "ref": "relief : toute pente > 50° (cirque de la Grotte, rempart, gorge, ravins, tertre autour de l'encoche, Monts)", "reason": "roche visible, strates peintes ; jamais une pente d'herbe infranchissable"},
  {"id": "eau_profonde", "kind": "deep_water", "ref": "mer (fond -3 m) et centre de l'étang (fond 1,2 m) ; profondeur > 0,6 m bloque", "reason": "l'eau se lit : bandes de profondeur"},
  {"id": "lisiere_dense", "kind": "forest_edge", "polygon": [[0, 0], [14, 0], [14, 96], [0, 96]], "polygon2": [[0, 112], [14, 112], [14, 120], [0, 120]], "reason": "bord ouest : troncs à 4 m, troncs couchés et fougères géantes entre eux ; la piste (z 100-108) reste ouverte"},
  {"id": "bois_port_dense", "kind": "forest_edge", "polygon": [[84, 174], [110, 174], [110, 180], [84, 180]], "polygon2": [[130, 174], [184, 174], [184, 180], [130, 180]], "reason": "bord sud hors route : haie de ronces + troncs couchés"}
 ],
 "edges": {
  "south": {"neighbour": "port_ambre", "join": {"kind": "road", "x_range": [116, 124], "z": 180, "height_m": 2.5, "width_m": 8}, "neighbour_offset_note": "Port-Ambre (80 m de large) sort à ses x 30-38 : son origine à x = 86 de la Prairie, son bord nord = z 180", "elsewhere": "bois du Port (haie) ; crique (mer) à l'ouest de x 84", "backdrop": "la mer au sud-ouest, les toits du port au loin"},
  "west": {"neighbour": "foret", "join": {"kind": "trail", "z_range": [100, 108], "x": 0, "height_m": 3.5, "width_m": 8}, "neighbour_offset_note": "la Forêt sort à ses lignes 50-54 (z 100-108) : aucun décalage", "elsewhere": "lisière dense ; le sous-bois de la Forêt déborde de 12 m", "backdrop": "la futaie géante (25 m) dès x -10"},
  "north": {"neighbour": None, "join": None, "elsewhere": "montagnes (10 -> 36 m, roche) ; la Grotte des Échos est une zone intérieure (entrée 116,46)", "backdrop": "sommets enneigés"},
  "east": {"neighbour": "monts_geles (à terme ; pas de passage au ch. 1)", "join": None, "elsewhere": "paroi des Monts (3 -> 26 m) avec éboulis praticables jusqu'à x 230 et la cascade", "backdrop": "les Monts Gelés"}
 },
 "scene_groups": {k: {"delta_m": list(v), "note": GROUP_NOTES[k]} for k, v in G.items()},
 "anchors": A,
 "budget": {
  "target_fps": 90, "gpu": "GTX 1650 Ti, Forward+ (SSAO, SSIL, glow, MSAA x4, ombres 90 m)", "frame_ms": 11.0,
  "instances": {"arbres": 1300, "buissons_ronces_fougeres_arbo": 900, "couvre_sol": 5000, "rochers": 320, "os": 40, "props_moyens": 90, "herbes_hautes": "TallGrass3D (en place)"},
  "triangles": {"arbre (LOD0/LOD2)": "2500 / 600", "buisson": "900 / 250", "rocher_3m": "1200 / 300", "vertebre": 800, "grand_crane": 25000, "arche_cotes": 3000, "cumul_visible_cible": "< 2,5 M triangles dans le champ, < 700 draw calls"},
  "rules": ["couvre-sol invisible au-delà de 90 m, buissons 140 m, arbres 240 m (fondu)", "ombres : arbres, rochers, os, crâne ; jamais le couvre-sol", "MultiMesh par sorte et par carré de 32 m, LOD générés", "Terrain3D : clipmap 0,5 m ; 8 textures maxi", "eau : miroir 0,3 x, une image sur deux"]
 },
 "new_props": json.load(open(OUT, encoding="utf-8"))["new_props"]
}

# ------------------------------------------------------------------ secteurs
def veg(c, cs, u, us, g, gs):
    return {"canopy": {"per_100m2": c, "species": cs}, "understory": {"per_100m2": u, "species": us}, "ground": {"per_100m2": g, "species": gs}}
AREAS = [
 ("bois_du_port", "Le Bois du Port", "lisière fraîche, l'ombre avant la lumière ; on entend la mer à gauche", [[84, 180], [84, 168], [100, 166], [110, 166], [110, 180]], veg(2.2, {"arbre_rond": 5, "araucaria": 3, "fougere_arbre": 2}, 3.0, {"buisson": 4, "fougere_arbre": 1, "ronces": 1}, 5.0, {"fougeres": 5, "champignons": 2, "cailloux": 1}), ["souche", "tronc_couche_8m", "cailloux"], [], False, {"polygon2": [[130, 180], [130, 166], [140, 166], [160, 170], [176, 174], [184, 180]], "walkable": "sous-bois praticable, troncs à 6-7 m ; se referme en haie vers z > 172"}),
 ("seuil", "Le Seuil du Port", "la côte, deux rochers-portes, puis la révélation : la cuvette entière, le Crâne droit devant au-dessus de l'étang, le rempart d'ambre au fond", [[96, 172], [96, 152], [150, 150], [176, 152], [176, 168], [150, 172]], veg(0.25, {"araucaria": 3, "arbre_rond": 1}, 0.6, {"buisson": 2, "ronces": 1}, 2.0, {"fleurs_jaunes": 3, "fleurs_roses": 2, "fougeres": 1, "cailloux": 1}), ["rocher_3m", "rocher_1m", "souche"], [{"center": [96, 158], "radii": [12, 7]}, {"center": [152, 164], "radii": [12, 7]}], False, {}),
 ("vallee_ru", "La Vallée du Ru", "le ru qui clapote, prêles et libellules, le gué de pierres ; sentier intime sous les fougères arborescentes", [[60, 126], [84, 124], [104, 120], [116, 120], [116, 134], [100, 140], [84, 148], [70, 158], [58, 150], [56, 136]], veg(0.8, {"fougere_arbre": 4, "arbre_rond": 2}, 1.8, {"buisson": 2, "prele": 4}, 5.0, {"fougeres": 3, "fleurs_violettes": 2, "cailloux": 2, "champignons": 1}), ["pierre_plate", "pas_japonais", "tronc_couche_8m"], [], False, {}),
 ("carrefour", "Le Carrefour", "ouvert, chaud, lisible : la butte du panneau, Maïa, le feu, le Grand Voyageur ; le Crâne au-dessus de l'étang à 60 m, les trois routes qui partent", [[90, 80], [124, 80], [128, 96], [124, 112], [108, 116], [92, 110], [86, 96]], veg(0.15, {"arbre_rond": 2, "araucaria": 1}, 0.3, {"buisson": 1}, 1.5, {"fleurs_roses": 2, "fleurs_jaunes": 2, "cailloux": 1}), ["panneau", "feu_camp", "rocher_plat_banc"], [], True, {"note": "ZONE CALME : rien de moyen/grand à moins de 14 m du panneau sauf les ancres"}),
 ("prairie_voyageur", "La Prairie du Grand Voyageur", "grande herbe ondulante, le brachiosaure comme une colline qui bouge, fleurs en dérives", [[44, 86], [90, 84], [92, 110], [70, 118], [48, 110]], veg(0.3, {"arbre_rond": 3, "araucaria": 1}, 0.5, {"buisson": 2, "ronces": 1}, 2.5, {"fleurs_roses": 3, "fleurs_violettes": 2, "fleurs_jaunes": 2, "fougeres": 1}), ["rocher_1m", "souche", "tapis_fleurs"], [{"center": [68, 80], "radii": [10, 6]}], False, {}),
 ("bois_chipie", "Le Bois de Chipie", "petit bois clair, on y entre partout, des trucs brillants dans l'herbe ; le nid au bord sud-est", [[54, 54], [90, 52], [92, 70], [80, 78], [58, 76]], veg(1.8, {"arbre_rond": 5, "fougere_arbre": 2, "araucaria": 1}, 2.5, {"buisson": 5, "ronces": 1}, 6.0, {"fougeres": 4, "champignons": 3, "cailloux": 1, "fleurs_violettes": 1}), ["souche", "tronc_couche_8m", "buisson_nid"], [], False, {"walkable": "troncs tous les 7 m, buissons en bouquets, jamais de rangée fermée"}),
 ("lisieres", "Les Lisières", "entre le carrefour et la colline : herbe courte, buissons isolés, le rocher-œuf ; au crépuscule les vélociraptors sortent des lisières", [[92, 58], [150, 56], [152, 72], [130, 80], [124, 80], [92, 80]], veg(0.4, {"araucaria": 3, "arbre_rond": 2}, 0.8, {"buisson": 3, "ronces": 1}, 2.0, {"fougeres": 2, "cailloux": 2, "fleurs_roses": 1}), ["rocher_1m", "rocher_oeuf", "panneau"], [{"center": [100, 68], "radii": [10, 6]}], False, {}),
 ("encoche_grotte", "L'Encoche de la Grotte", "resserré, minéral, frais : les parois du cirque, l'éboulis, la bouche noire au fond, l'écho", [[106, 60], [126, 60], [126, 44], [106, 44]], veg(0.0, {}, 0.6, {"fougere_arbre": 2, "fougeres": 2}, 6.0, {"cailloux": 5, "fougeres": 2, "champignons": 1}), ["rocher_charge", "rocher_grotte", "stalagmite", "eboulis"], [], True, {}),
 ("colline_grotte", "La Colline de la Grotte", "flancs d'herbe rase et de roche, araucarias tordus par le vent ; au sommet, le belvédère", [[84, 48], [146, 46], [150, 20], [130, 10], [96, 10], [82, 26]], veg(0.5, {"araucaria": 5, "arbre_rond": 1}, 0.7, {"buisson": 2, "ronces": 1}, 3.0, {"cailloux": 3, "fougeres": 1, "fleurs_jaunes": 1}), ["rocher_3m", "rocher_1m", "rocher_plat_banc"], [], False, {}),
 ("hauts_du_col", "Les Hauts du Col", "prairie haute et silencieuse, vent, herbes hautes, les montagnes tout près ; psittacosaures à l'aube", [[146, 60], [156, 60], [156, 14], [136, 14], [136, 36], [146, 46]], veg(0.3, {"araucaria": 4}, 0.6, {"buisson": 2, "ronces": 1}, 2.0, {"cailloux": 2, "fleurs_violettes": 2, "fougeres": 1}), ["rocher_3m", "rocher_1m"], [{"center": [148, 54], "radii": [5, 5]}], True, {}),
 ("etang", "L'Étang des Chanteurs", "miroir d'eau sous le parvis du Crâne : rives de sable et de prêles, l'îlot ; au crépuscule les parasaurolophus chantent face au crâne", [[118, 112], [152, 110], [156, 122], [150, 134], [128, 136], [118, 128]], veg(0.6, {"fougere_arbre": 5, "arbre_rond": 1}, 1.5, {"prele": 4, "roseaux": 4, "buisson": 1}, 3.0, {"fougeres": 2, "fleurs_roses": 1, "cailloux": 2, "nenuphars": 2}), ["banc", "pierre_plate", "bille_bois", "roseaux"], [], True, {"note": "les 4 emplacements des chanteurs et la rive sud-ouest libres de tout décor solide"}),
 ("prairie_elise", "La Prairie d'Élise", "prairie rase au sud de l'étang, en pleine lumière, où dort le Tricératops malade", [[126, 127], [142, 127], [142, 150], [124, 150]], veg(0.0, {}, 0.0, {}, 1.0, {"fleurs_jaunes": 2, "cailloux": 1}), [], [], True, {"note": "ELISE_SCENE %s : aucun décor" % elise_rect}),
 ("vertebres", "La Rampe des Vertèbres", "la colonne vertébrale d'un géant sort de l'herbe et monte vers le crâne ; côtes dressées, l'arche ; l'herbe rase et dorée", [[122, 100], [150, 99], [150, 114], [122, 110]], veg(0.2, {"araucaria": 2, "arbre_rond": 1}, 0.5, {"buisson": 2}, 2.5, {"cailloux": 3, "fleurs_jaunes": 2, "os_dino": 2}), ["vertebre_geante", "cote_geante", "arche_cotes", "femur_geant"], [], False, {}),
 ("parvis_crane", "Le Parvis du Grand Crâne", "une dalle d'herbe rase devant le crâne, au-dessus de l'étang : solennel, trois serrures qui luisent, des os blancs, le silence", [[148, 102], [188, 100], [192, 110], [184, 118], [150, 116]], veg(0.0, {}, 0.3, {"buisson": 1}, 2.0, {"os_dino": 3, "cailloux": 2, "fleurs_jaunes": 1}), ["panneau", "cristaux_ambre", "os_dino", "rocher_plat_banc"], [], True, {}),
 ("tertre_crane", "Le Tertre du Crâne", "la butte rocheuse qui porte le crâne : racines, araucarias noueux, roche ; compsognathus par bandes", [[150, 70], [204, 68], [210, 84], [206, 100], [192, 100], [158, 102], [148, 90]], veg(0.6, {"araucaria": 4, "arbre_rond": 2}, 1.2, {"buisson": 2, "ronces": 2, "fougere_arbre": 1}, 3.0, {"cailloux": 3, "fougeres": 2, "os_dino": 1}), ["rocher_3m", "rocher_1m", "os_dino"], [], False, {}),
 ("corridor", "Le Corridor", "entre le tertre et le rempart d'ambre : une allée d'herbe et de blocs tombés, la paroi dorée à gauche, la butte à droite ; la gorge au bout", [[124, 80], [152, 72], [156, 66], [190, 66], [192, 76], [168, 76], [152, 80], [130, 90]], veg(0.3, {"araucaria": 3}, 0.6, {"buisson": 2, "fougeres": 2}, 3.0, {"cailloux": 4, "fougeres": 1, "fleurs_violettes": 1}), ["rocher_3m", "rocher_1m", "eboulis"], [], False, {}),
 ("eboulis_est", "Les Éboulis de l'Est", "au pied des Monts : pierriers, blocs, la cascade au nord ; au sud, la nuit, les ankylosaures dorment", [[204, 70], [240, 66], [240, 124], [224, 122], [210, 100]], veg(0.3, {"araucaria": 3}, 0.5, {"buisson_sec": 2, "ronces": 1}, 5.0, {"cailloux": 6, "fougeres": 1}), ["rocher_3m", "rocher_1m", "eboulis"], [{"center": [220, 150], "radii": [6, 10]}], True, {"polygon2": [[204, 126], [224, 124], [240, 128], [240, 180], [210, 172], [204, 150]]}),
 ("prairies_sud", "Les Prairies du Sud", "la grande prairie ouverte, herbes hautes par nappes, protocératops qui broutent, l'arbre du dormeur ; la vue sur le Crâne", [[92, 112], [118, 114], [118, 134], [124, 134], [124, 150], [150, 150], [176, 158], [150, 150], [96, 150], [88, 140]], veg(0.25, {"arbre_rond": 4, "araucaria": 1}, 0.4, {"buisson": 2}, 2.0, {"fleurs_roses": 2, "fleurs_jaunes": 2, "fougeres": 1, "cailloux": 1}), ["souche", "rocher_1m", "banc"], [{"center": [104, 114], "radii": [8, 6]}, {"center": [162, 140], "radii": [10, 6]}, {"center": [100, 140], "radii": [10, 6]}], False, {}),
 ("bois_sud_est", "Le Bois du Sud-Est", "bois rond et sombre sur sa butte, clairière au centre avec un tronc couché et une trouée de soleil ; un galet caché", [[158, 136], [194, 134], [196, 160], [160, 162]], veg(2.4, {"arbre_rond": 4, "araucaria": 3, "fougere_arbre": 2}, 3.0, {"buisson": 3, "fougere_arbre": 2, "ronces": 1}, 6.0, {"fougeres": 5, "champignons": 3}), ["tronc_couche_12m", "souche", "champignons"], [], False, {"walkable": "oui, clairière centrale (176,148) r 6"}),
 ("crique", "La Crique", "sable clair, bois flotté, le ru qui se jette dans la mer, le panneau à la dent de mosasaure ; la Pointe ; calme et un peu inquiétant", [[0, 120], [60, 120], [60, 128], [56, 148], [84, 164], [84, 180], [0, 180]], veg(0.3, {"araucaria": 2, "fougere_arbre": 1}, 0.6, {"buisson": 1, "oyats": 3}, 2.5, {"coquillages": 2, "cailloux": 2, "bois_flotte": 1}), ["bois_flotte", "rocher_cote", "feu_camp", "panneau"], [{"center": [44, 128], "radii": [10, 6]}], False, {}),
 ("bois_crique", "Le Bois de la Crique", "petit bois frais entre le ru et la plage, fougères arborescentes, on traverse en diagonale", [[50, 106], [84, 108], [86, 126], [54, 128]], veg(1.8, {"fougere_arbre": 4, "arbre_rond": 3, "araucaria": 1}, 2.2, {"buisson": 3, "fougere_arbre": 1}, 6.0, {"fougeres": 5, "champignons": 2, "fleurs_violettes": 1}), ["souche", "tronc_couche_8m"], [], False, {"walkable": "oui"}),
 ("chemin_creux", "Le Chemin Creux", "le sentier s'enfonce entre deux talus couverts de ronces, l'ombre tombe, puis le tronc moussu barre tout ; derrière, des fleurs", [[54, 102], [72, 100], [72, 92], [62, 82], [54, 76], [48, 82], [50, 94]], veg(1.2, {"arbre_rond": 3, "fougere_arbre": 2}, 6.0, {"ronces": 5, "buisson": 2, "fougeres": 2}, 6.0, {"fougeres": 4, "champignons": 2, "cailloux": 1}), ["haie_ronces", "tronc_tranche", "souche"], [], False, {}),
 ("bosquet_helene", "Le Bosquet d'Hélène", "jardin sauvage caché : lumière tamisée, fleurs partout, l'Arbre d'Hélène, la souche-banc ; on se promène sous les arbres, la haie ferme tout", [[6, 40], [62, 36], [70, 60], [66, 80], [50, 92], [34, 90], [10, 80], [4, 60]], veg(1.6, {"arbre_rond": 4, "araucaria": 2, "fougere_arbre": 3}, 2.0, {"buisson": 2, "fougere_arbre": 1}, 8.0, {"fleurs_roses": 3, "fleurs_violettes": 3, "fleurs_jaunes": 2, "fougeres": 2, "champignons": 1}), ["arbre_helene", "souche_banc", "pierre_mousse", "tapis_fleurs"], [{"center": [32, 56], "radii": [6, 6]}], False, {"walkable": "intérieur praticable partout ; la haie (blocker haie_bosquet) est la seule limite"}),
 ("lisiere_foret", "La Lisière de la Forêt", "la prairie s'assombrit, les fougères deviennent géantes, les troncs se rapprochent ; la piste s'enfonce vers l'ouest", [[0, 0], [22, 0], [26, 40], [4, 40], [0, 40]], veg(3.0, {"araucaria": 3, "arbre_rond": 3, "fougere_arbre": 4}, 4.0, {"fougere_arbre": 3, "buisson": 2, "fougeres": 3}, 8.0, {"fougeres": 6, "champignons": 3, "cailloux": 1}), ["tronc_couche_12m", "souche_geante", "fougere_geante"], [], False, {"polygon2": [[0, 92], [32, 92], [34, 110], [30, 120], [0, 120]], "walkable": "praticable sur 12 m depuis la prairie, puis se referme (blocker lisiere_dense)"}),
 ("vallon_des_nids", "Le Vallon des Nids", "derrière la porte : un vallon secret, herbe haute, parois ocre et ambre, les dimorphodons tournent au-dessus ; psittacosaures à l'aube", [[164, 62], [226, 58], [234, 44], [226, 24], [172, 28], [162, 44]], veg(0.4, {"araucaria": 3, "fougere_arbre": 1}, 1.0, {"buisson": 2, "ronces": 1, "fougeres": 2}, 3.0, {"cailloux": 3, "fleurs_violettes": 2, "fougeres": 1}), ["rocher_3m", "rocher_1m", "nid_dimorphodon", "eboulis"], [{"center": [206, 48], "radii": [12, 5]}, {"center": [174, 46], "radii": [7, 5]}], False, {}),
 ("terrasses", "Les Terrasses du Poste", "deux marches de roche vers le ciel, vent, nids sur les corniches ; au sommet le poste d'Hélène et la vue : tout le chemin parcouru", [[172, 40], [222, 40], [224, 8], [176, 8]], veg(0.3, {"araucaria": 3}, 0.5, {"buisson": 2}, 2.5, {"cailloux": 3, "fleurs_jaunes": 1, "fougeres": 1}), ["banc", "table_observation", "feu_camp", "nid_dimorphodon", "rocher_1m", "longue_vue"], [], True, {}),
]
for id_, name, amb, poly, v, props, tg, calm, extra in AREAS:
    a = {"id": id_, "name": name, "ambiance": amb, "polygon": poly, "vegetation": v, "props_set": props, "tall_grass": tg, "calm": calm}
    a.update(extra)
    L["areas"].append(a)

AUDIT_GROUPS = {"G_port": "sortie_port", "G_carrefour": "carrefour_maia + voyageur", "G_chipie": "poursuite_chipie", "G_oeuf": "(panneaux)", "G_tronc": "bosquet_tronc (le tronc)", "G_bosquet": "bosquet_tronc (le bosquet)", "G_grotte": "grotte_rocher", "G_porte": "falaises_porte", "G_poste": "poste_observation", "G_crane": "crane_cour", "G_etang": "etang_gue", "G_etang_ilot": "etang_gue (îlot)", "G_elise": "elise", "G_dormeur": "dormeur", "G_crique": "(panneaux, repos)", "G_foret": "sortie_foret", "G_libre": "(galets, habitats)"}
for k in L["scene_groups"]:
    L["scene_groups"][k]["audit_group"] = AUDIT_GROUPS[k]
L["scene_groups"]["G_tronc"]["note"] += " ; l'audit met le tronc et le bosquet dans un seul groupe (bosquet_tronc) : ils sont ici séparés car aucune scène ne marche de l'un à l'autre (obstacles_capacites et page1_bosquet sont deux scènes) ; le tronc reste en travers de l'ouverture, le bosquet derrière (au nord-ouest), 41 m au lieu de 28"
L["scene_groups"]["G_crane"]["note"] += " ; TRANSLATION PURE (audit : « ne pas faire pivoter ») : DEN -> MOUTH reste nord -> sud, l'Alpha va vers le sud-est, Maïa arrive de l'ouest"
dc = G["G_crane"]; dchip = G["G_chipie"]
def nt(p, d):
    return [round((p[0] + d[0]) / 2, 2), round((p[1] + d[1]) / 2, 2)]
L["hardcoded_constants"] = {
 "_doc": "les constantes en pixels de story/*.gd (audit § 3.3) : ancienne valeur (cases) -> nouvelle (cases 2,5D = m/2) et nouvelle en m 3D. Elles suivent le groupe de scène ; à recalculer par le champ de déformation ou à la main avec ces valeurs.",
 "story/plaines.gd": {
  "ALPHA_SPOT": {"old_tiles": [107.2, 63.8], "new_m": ALPHA_NEW, "new_tiles": [ALPHA_NEW[0] / 2, ALPHA_NEW[1] / 2], "note": "hors de la translation du groupe G_crane : voir l'ancre Alpha"},
  "DEN": {"old_tiles": [104.0, 58.5], "new_m": mv([208, 117], dc), "new_tiles": nt([208, 117], dc)},
  "MOUTH": {"old_tiles": [104.0, 63.2], "new_m": mv([208, 126.4], dc), "new_tiles": nt([208, 126.4], dc)},
  "OUT_OF_NOTCH": {"old_tiles": [104.9, 62.3], "new_m": mv([209.8, 124.6], dc), "new_tiles": nt([209.8, 124.6], dc)},
  "MAIA_FROM": {"old_tiles": [93.0, 65.5], "new_m": mv([186, 131], dc), "new_tiles": nt([186, 131], dc)},
  "walk_to(player + (-90, 12) px)": "relatif : Maïa reste à l'OUEST de Chloé (inchangé)"
 },
 "story/plaines_annexes.gd": {
  "CHIPIE_HIDE": {"old_tiles": [59.2, 47.2], "new_m": mv([118.4, 94.4], dchip), "new_tiles": nt([118.4, 94.4], dchip)},
  "walk_to(maia + (-26, 14) px)": "relatif (inchangé)"
 },
 "tools/zones/plaines.gd": {"CHIPIE_PATH": {"old_tiles": [[57.5, 42.5], [52.5, 40.5], [48.5, 37.5], [44.5, 35.6], [41.6, 34.8]], "new_tiles": [[round(p[0] / 2, 2), round(p[1] / 2, 2)] for p in chipie_path]}, "ELISE_TRI/PILE/AT/SCENE": "groupe G_elise (Δ %s m)" % list(G["G_elise"]), "ELISE_SCENE_new_m": elise_rect},
 "story/objectives.gd": {"ALPHA": "même valeur que ALPHA_SPOT"},
 "note_panneau_carrefour": "R-panneau-directions (audit § 3.4) : depuis Maïa, Grotte au nord (0°), Falaises à l'est-nord-est (66°), le Grand Crâne à l'est (90°) avec l'étang sur sa droite en chemin (sud-est, 130°), bosquet à l'ouest-nord-ouest, port au sud : le texte « Est : l'étang, puis le Grand Crâne » reste vrai en suivant la route de l'est (l'étang est longé avant le parvis)."
}
L["audit_reconciliation"] = {
 "file": "plaines-audit.md / plaines-ancres.json (04/10)",
 "kept": ["85 ancres toutes présentes (translation par groupe)", "rayons dégagés de l'audit repris dans clearings (carrefour 18 m + couronne basse jusqu'à 24 m, nid 5 m, bosquet 9 m + intérieur sans forêt, encoche 8 m, porte 6 m, poste 8 m, parvis 12 m, étang nord 6 m, chanteurs 10 m, Élise rectangle 16 x 20 m sans décor ni herbe haute ni relief > 1 m, dormeur 5 m, Voyageur 8 m, arrivée 10 m avec un couloir de 20 m entre les deux bois", "couloir de Chipie (4 segments, 4 m de large) au sud du bois de Chipie, sol plat", "couloir de Maïa (26 m, 6 m de large, plat) sur le parvis à 6,5 m", "les 10 spawns et les 4 sorties conservés (sorties aux mêmes bords)", "le gué : rive nord -> gué -> îlot, l'étang entre les deux", "les 3 serrures : 6 m dégagés côté sud, le tronc (5 m) remplit son ouverture de 4,5 m (l'audit signale que l'obstacle 2,5D de 2,2 m fuyait)"],
 "risks_answered": {"R5 gué de lune": "le gué est un haut-fond à 2,3 m : Blockers3D doit ouvrir/fermer cette boîte d'eau avec MoonFord (à coder par l'agent décor/gameplay)", "R6 avant-cour": "parvis plat de 6,5 m, 12 m dégagés, ALPHA_SPOT sur le plat", "R7 Élise": "rectangle sans décor, hors herbes hautes, hors du Seuil (déplacé au sud, crête z 163)", "R13 Chipie": "couloir dégagé, le bois au nord de la course"}
}
json.dump(L, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("écrit", OUT, "ancres :", len(A))
