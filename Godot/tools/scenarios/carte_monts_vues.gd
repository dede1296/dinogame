extends RefCounted
## Visual checks of the Monts Gelés' maps (chapter 6, the map's own), no scene played: the join with
## the Côte seen from both sides, a view of each place of the big zone, the ice caves and the
## sanctuary. The story's scenes are kept quiet by their flags.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/carte_monts_vues.gd

const FLAGS := ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "cote_annonce", "cote_ouverte",
	"cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "barque_nuit_vue", "cache_vue", "coeur_3", "maia_enfuie",
	"monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "grottes_glace_arrivee", "suie_monts_vue"]

const STEPS := [
	[0.8, "flags", FLAGS], [0.85, "talk", true], [0.9, "calm", 900.0], [0.9, "clock", 11.0],
	[0.95, "weather", &"clear"],
	# 1. The join, from the Côte (its east edge, the Monts beyond) and from the Monts.
	[1.0, "zone", &"cote"], [3.4, "weather", &"clear"], [3.5, "tp", Vector2(121.5, 58.0)], [3.6, "face", Vector2(1, 0)],
	[3.7, "camera_distance", 18.0], [6.0, "shot", "j1_cote_vers_monts"],
	[6.2, "zone", &"monts"], [8.6, "weather", &"clear"], [8.7, "calm", 900.0], [8.8, "tp", Vector2(6.0, 30.0)],
	[8.9, "face", Vector2(-1, 0)], [9.0, "camera_distance", 18.0], [11.2, "shot", "j2_monts_vers_cote"],
	# 2. The big zone, place by place.
	[11.4, "camera_distance", 14.0], [11.5, "tp", Vector2(12.0, 31.0)], [11.6, "face", Vector2(1, 0)], [13.6, "shot", "a_entree"],
	[13.8, "tp", Vector2(22.5, 61.4)], [13.9, "face", Vector2(0, -1)], [15.9, "shot", "b_bertille"],
	[16.1, "tp", Vector2(38.0, 70.0)], [18.1, "shot", "c_vallee"],
	[18.3, "tp", Vector2(40.0, 93.0)], [18.4, "face", Vector2(0, -1)], [20.3, "shot", "d_lac"],
	[20.5, "tp", Vector2(10.5, 98.5)], [22.5, "shot", "e_page30"],
	[22.7, "tp", Vector2(40.0, 34.0)], [22.8, "face", Vector2(1, 0)], [24.7, "shot", "f_glacier"],
	[24.9, "tp", Vector2(57.0, 31.0)], [25.0, "face", Vector2(0, -1)], [26.9, "shot", "g_mur1"],
	[27.1, "tp", Vector2(62.0, 22.0)], [29.0, "shot", "h_bande_milieu"],
	[29.2, "tp", Vector2(67.0, 20.6)], [29.3, "face", Vector2(0, -1)], [31.1, "shot", "i_mur2"],
	[31.3, "tp", Vector2(66.0, 10.4)], [31.4, "face", Vector2(0, -1)], [33.3, "shot", "j_bouche_grottes"],
	[33.5, "tp", Vector2(86.0, 40.0)], [33.6, "face", Vector2(1, 0)], [35.5, "shot", "k_rampe_col"],
	[35.7, "tp", Vector2(104.0, 39.0)], [35.8, "face", Vector2(0, -1)], [37.7, "shot", "l_terrasse"],
	[37.9, "tp", Vector2(108.0, 24.0)], [39.8, "shot", "m_col"],
	[40.0, "tp", Vector2(114.5, 12.0)], [40.1, "face", Vector2(0, -1)], [42.0, "shot", "n_porte_givre"],
	[42.2, "tp", Vector2(100.5, 7.5)], [42.3, "face", Vector2(0, -1)], [44.2, "shot", "o_couloir_cieux"],
	[44.4, "tp", Vector2(88.0, 74.0)], [46.3, "shot", "p_toundra"],
	[46.5, "camera_distance", 20.0], [46.6, "tp", Vector2(60.0, 50.0)], [46.7, "face", Vector2(0, -1)], [48.6, "shot", "q_vue_glacier"],
	[48.8, "camera_distance", 12.0],
	# 3. The ice caves.
	[49.0, "zone", &"grottes_glace"], [51.4, "calm", 900.0], [51.5, "tp", Vector2(20.0, 33.0)], [51.6, "face", Vector2(0, -1)],
	[53.4, "shot", "r_grottes_entree"],
	[53.6, "tp", Vector2(20.0, 26.0)], [55.5, "shot", "s_salle"],
	[55.7, "tp", Vector2(5.0, 22.0)], [55.8, "face", Vector2(0, -1)], [57.6, "shot", "t_mur_grottes"],
	[57.8, "tp", Vector2(22.0, 12.5)], [57.9, "face", Vector2(0, -1)], [59.7, "shot", "u_reserve"],
	[59.9, "tp", Vector2(5.0, 12.5)], [61.8, "shot", "v_chambre"],
	# 4. The sanctuary.
	[62.0, "zone", &"sanctuaire_givre"], [64.4, "tp", Vector2(16.0, 30.0)], [64.5, "face", Vector2(0, -1)], [66.3, "shot", "w_couloir"],
	[66.5, "tp", Vector2(16.0, 18.0)], [68.4, "shot", "x_salle_titan"],
	[68.6, "state", null],
]
