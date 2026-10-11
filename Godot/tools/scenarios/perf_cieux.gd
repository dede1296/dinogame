extends RefCounted
## Frame rate of the chapter 7 map without vsync (like carte_monts_perf.gd), at the High quality: the
## Cieux (the arrival, the crossroads, the Mer de nuages at dawn, the long bridge, in mist and in a
## gale), the nests, the Arche du Vent. The zones are entered by vis_cieux.gd's `entrer` (they are
## only in world.gd ZONES once the map's patch is applied).
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/perf_cieux.gd titre="Images par seconde dans les Cieux"

const VIS := "res://tools/scenarios/vis_cieux.gd"
const FLAGS := ["prologue_done", "tuto_commandes", "cieux_ouverts", "cieux_arrivee", "pont_lianes_vu", "vol_obtenu",
	"quetzal_roi_confiance", "sceau_cieux"]

const STEPS := [
	[0.5, "flags", FLAGS], [0.55, "talk", true], [0.6, "clock", 11.0], [0.7, "weather", &"clear"], [0.8, "quality", 2],
	[1.0, "static", [VIS, "entrer", "cieux", "DepuisMonts"]], [3.5, "weather", &"clear"], [3.6, "calm", 900.0], [3.7, "vsync", false],
	[3.8, "tp", Vector2(72.5, 76.5)], [6.8, "perf", "cieux/arrivee"],
	[7.0, "tp", Vector2(52.0, 72.0)], [10.0, "perf", "cieux/guet"],
	[10.2, "tp", Vector2(85.0, 60.0)], [13.2, "perf", "cieux/long_pont"],
	[13.4, "clock", 6.5], [13.5, "tp", Vector2(25.0, 64.0)], [16.5, "perf", "cieux/mer_aube"],
	[16.7, "clock", 11.0], [16.8, "tp", Vector2(46.5, 29.0)], [19.8, "perf", "cieux/haut_rempart"],
	[20.0, "weather", &"mist"], [20.1, "tp", Vector2(52.0, 50.0)], [24.0, "perf", "cieux/vents_brume"],
	[24.2, "weather", &"blizzard"], [28.2, "perf", "cieux/vents_blizzard"], [28.4, "weather", &"clear"],
	[28.6, "static", [VIS, "entrer", "nids_geants", "DepuisCieux"]], [31.1, "weather", &"clear"], [31.2, "calm", 900.0], [31.3, "vsync", false],
	[31.4, "tp", Vector2(36.0, 34.0)], [34.4, "perf", "nids/nids"],
	[34.6, "tp", Vector2(23.0, 15.0)], [37.6, "perf", "nids/grand_nid"],
	[37.8, "static", [VIS, "entrer", "arche_du_vent", "DepuisNids"]], [40.3, "weather", &"clear"], [40.4, "calm", 900.0], [40.5, "vsync", false],
	[40.6, "tp", Vector2(28.0, 24.0)], [43.6, "perf", "arche/terrasse"],
	[43.8, "weather", &"blizzard"], [47.8, "perf", "arche/terrasse_blizzard"],
	[48.0, "weather", &"clear"], [48.2, "state", null],
]
