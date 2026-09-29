extends RefCounted
## Visual checks of the Monts Gelés after the snow layer (cover): the join with the Côte from both
## sides, near and far, and the places changed since carte_monts_vues.gd (Bertille's shelter, the
## frost door, the reserve with Dame Suie's sled and Mandragore, Grelot at the first ice wall).
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/carte_monts_jointure.gd

const FLAGS := ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "cote_annonce", "cote_ouverte",
	"cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "barque_nuit_vue", "cache_vue", "coeur_3", "maia_enfuie",
	"monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "grottes_glace_arrivee", "suie_monts_vue"]

const STEPS := [
	[0.8, "flags", FLAGS], [0.85, "talk", true], [0.9, "calm", 900.0], [0.9, "clock", 11.0],
	[0.95, "weather", &"clear"],
	# 1. The join, from the Côte (near, far) and from the Monts (near, far).
	[1.0, "zone", &"cote"], [3.4, "weather", &"clear"], [3.5, "tp", Vector2(124.0, 57.6)], [3.6, "face", Vector2(1, 0)],
	[3.7, "camera_distance", 12.0], [6.0, "shot", "j1_cote_pres"],
	[6.1, "camera_distance", 20.0], [6.2, "tp", Vector2(120.0, 60.0)], [8.4, "shot", "j1_cote_loin"],
	[8.6, "zone", &"monts"], [11.0, "weather", &"clear"], [11.1, "calm", 900.0], [11.2, "tp", Vector2(3.0, 30.5)],
	[11.3, "face", Vector2(-1, 0)], [11.4, "camera_distance", 12.0], [13.6, "shot", "j2_monts_pres"],
	[13.7, "camera_distance", 20.0], [13.8, "tp", Vector2(9.0, 33.0)], [16.0, "shot", "j2_monts_loin"],
	[16.1, "tp", Vector2(16.0, 44.0)], [18.3, "shot", "j3_bande_sud"],
	[18.4, "camera_distance", 12.0],
	# 2. The places changed.
	[18.5, "tp", Vector2(22.5, 61.6)], [18.6, "face", Vector2(0, -1)], [20.6, "shot", "b_bertille"],
	[20.8, "tp", Vector2(57.0, 31.2)], [20.9, "face", Vector2(0, -1)], [22.9, "shot", "g_mur1_grelot"],
	[23.1, "tp", Vector2(114.5, 12.2)], [23.2, "face", Vector2(0, -1)], [25.2, "shot", "n_porte_givre"],
	[25.4, "tp", Vector2(40.0, 70.0)], [27.4, "shot", "c_vallee"],
	[27.6, "zone", &"grottes_glace"], [30.0, "calm", 900.0], [30.1, "tp", Vector2(24.0, 13.0)], [30.2, "face", Vector2(0, -1)],
	[32.2, "shot", "u_reserve"],
	[32.4, "state", null],
]
