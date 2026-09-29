extends RefCounted
## Frame rate without vsync (like perf_regions of tools/capture.gd): three places of the Côte, then
## the Monts Gelés (the way in and its snow band, the valley, the glacier, the col; the valley
## again in falling snow and in a blizzard), to compare the two big zones.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/carte_monts_perf.gd

const FLAGS := ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "cote_annonce", "cote_ouverte",
	"cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "barque_nuit_vue", "cache_vue", "coeur_3", "maia_enfuie",
	"monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "grottes_glace_arrivee", "suie_monts_vue"]

const STEPS := [
	[0.5, "flags", FLAGS], [0.55, "talk", true], [0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"],
	[0.9, "vsync", false],
	[1.4, "zone", &"cote"], [3.9, "weather", &"clear"], [4.0, "vsync", false], [4.2, "tp", Vector2(20.0, 76.0)], [7.2, "perf", "cote/plage"],
	[7.4, "tp", Vector2(70.0, 60.0)], [10.4, "perf", "cote/lagon"], [10.6, "tp", Vector2(110.0, 48.0)], [13.6, "perf", "cote/sommet"],
	[14.1, "zone", &"monts"], [16.6, "weather", &"clear"], [16.7, "vsync", false], [16.8, "calm", 900.0],
	[17.0, "tp", Vector2(10.0, 31.0)], [20.0, "perf", "monts/entree"],
	[20.2, "tp", Vector2(38.0, 70.0)], [23.2, "perf", "monts/vallee"],
	[23.4, "tp", Vector2(60.0, 36.0)], [26.4, "perf", "monts/glacier"],
	[26.6, "tp", Vector2(108.0, 24.0)], [29.6, "perf", "monts/col"],
	[29.8, "tp", Vector2(38.0, 70.0)], [30.0, "weather", &"snow"], [34.0, "perf", "monts/vallee_neige"],
	[34.2, "weather", &"blizzard"], [38.2, "perf", "monts/vallee_blizzard"],
	[38.4, "weather", &"clear"], [38.6, "state", null],
]
