extends RefCounted
## Chapitre 6 — Les Monts Gelés : vérification visuelle des 10 décors (tailles réelles, Prop.KINDS),
## montrés par Stage.show_thing comme vis_avant_ch6.gd (pas de zone monts/grottes_glace encore :
## la carte n'est pas construite, ce n'est qu'un contrôle d'échelle contre Chloé dans une zone
## existante, plaines). Un décor par capture, Chloé 3 cases au sud, face au nord.
## godot --path Godot --headless --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_monts_decor.gd

const ST := "res://story/stage.gd"

const STEPS := [
	[0.85, "vsync", false], [0.86, "talk", true],
	# y=70 (open grassland near the "fight" scenario's wild-encounter spot, no grove/trees there,
	# unlike y=50's "Bosquet d'Hélène" which blocked the first attempt with palm foliage).
	[1.0, "zone", &"plaines"], [1.1, "calm", 900.0], [1.2, "weather", &"clear"], [1.3, "clock", 11.0],
	# Spawn the 10 decors (fade-in 0.35 s), spread out along y=70 so none overlaps.
	[2.5, "static", [ST, "show_thing", "bloc_glace", Vector2(10.0, 70.0), "D_bloc_glace"]],
	[2.6, "static", [ST, "show_thing", "oeufs_glace", Vector2(15.0, 70.0), "D_oeufs_glace"]],
	[2.7, "static", [ST, "show_thing", "mur_glace", Vector2(20.0, 70.0), "D_mur_glace"]],
	[2.8, "static", [ST, "show_thing", "stalactites_glace", Vector2(25.0, 70.0), "D_stalactites_glace"]],
	[2.9, "static", [ST, "show_thing", "cristaux_glace", Vector2(30.0, 70.0), "D_cristaux_glace"]],
	[3.0, "static", [ST, "show_thing", "porte_givre", Vector2(35.0, 70.0), "D_porte_givre"]],
	[3.1, "static", [ST, "show_thing", "traineau_suie", Vector2(40.0, 70.0), "D_traineau_suie"]],
	[3.2, "static", [ST, "show_thing", "fioles_suie", Vector2(45.0, 70.0), "D_fioles_suie"]],
	[3.3, "static", [ST, "show_thing", "abri_roche", Vector2(50.0, 70.0), "D_abri_roche"]],
	[3.4, "static", [ST, "show_thing", "statue_cryolophosaure", Vector2(55.0, 70.0), "D_statue_cryolophosaure"]],
	# One shot per decor, Chloé 1.5 cases south of it, facing north (close-up, like vis_avant_ch6.gd).
	[4.5, "tp", Vector2(10.0, 71.5)], [4.6, "face", Vector2(0, -1)], [5.0, "shot", "monts_bloc_glace"],
	[5.2, "tp", Vector2(15.0, 71.5)], [5.3, "face", Vector2(0, -1)], [5.7, "shot", "monts_oeufs_glace"],
	[5.9, "tp", Vector2(20.0, 71.5)], [6.0, "face", Vector2(0, -1)], [6.4, "shot", "monts_mur_glace"],
	[6.6, "tp", Vector2(25.0, 71.5)], [6.7, "face", Vector2(0, -1)], [7.1, "shot", "monts_stalactites_glace"],
	[7.3, "tp", Vector2(30.0, 71.5)], [7.4, "face", Vector2(0, -1)], [7.8, "shot", "monts_cristaux_glace"],
	[8.0, "tp", Vector2(35.0, 71.5)], [8.1, "face", Vector2(0, -1)], [8.5, "shot", "monts_porte_givre"],
	[8.7, "tp", Vector2(40.0, 71.5)], [8.8, "face", Vector2(0, -1)], [9.2, "shot", "monts_traineau_suie"],
	[9.4, "tp", Vector2(45.0, 71.5)], [9.5, "face", Vector2(0, -1)], [9.9, "shot", "monts_fioles_suie"],
	[10.1, "tp", Vector2(50.0, 71.5)], [10.2, "face", Vector2(0, -1)], [10.6, "shot", "monts_abri_roche"],
	[10.8, "tp", Vector2(55.0, 71.5)], [10.9, "face", Vector2(0, -1)], [11.3, "shot", "monts_statue_cryolophosaure"],
	[11.6, "state", null],
]
