extends RefCounted
## Visual check (30/09): the sleeping dinos lie down now (DinoSpecies.sleep_sheet) and hold a
## single still picture — the sleeper under his tree in the Prairie, and the four of the Grottes
## de glace's reserve.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_dormeurs.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "monts_arrivee", "bertille_vue",
		"glacier_arrivee", "mur_glace_1_brise", "mur_glace_2_brise", "grottes_glace_arrivee",
		"suie_monts_vue", "suie_monts_battue", "suie_monts_partie"]],
	[0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "no_help", null], [1.2, "zone", &"plaines"],
	# the sleeper under his tree (protoceratops) — after the Dinodex toasts have gone
	[3.4, "tp", Vector2(58.6, 68.8)], [3.6, "face", Vector2(-1, 0)], [9.0, "shot", "d1_dormeur_plaines"],
	# the ice caves: the four blocks at tiles 15 / 19.5 / 29.5 / 34, rows 3.4-4.6
	[9.6, "zone", &"grottes_glace"], [12.0, "tp", Vector2(17.4, 6.2)], [12.2, "face", Vector2(-1, 0)],
	[19.0, "shot", "d2_dormeurs_ouest"],
	[19.4, "tp", Vector2(21.8, 5.0)], [19.6, "face", Vector2(-1, 0)], [21.5, "shot", "d3_de_pres"],
	[22.0, "tp", Vector2(32.0, 5.0)], [22.2, "face", Vector2(-1, 0)], [24.0, "shot", "d4_dormeurs_est"],
	[24.6, "state", null],
]
