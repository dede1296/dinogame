extends RefCounted
## Clins d'œil à Jurassic Park — agent A, contrôle visuel des 12 décors (tailles réelles, Prop.KINDS),
## montrés par Stage.show_thing comme vis_monts_decor.gd (pas de zone jurassique construite encore :
## simple contrôle d'échelle contre Chloé dans les Plaines, une zone existante). Un décor par capture,
## Chloé 1,5 case au sud, face au nord. Les objets muraux (affiche_ambre, chapeau_helene, foot négatif)
## flottent donc au-dessus de leur point d'ancrage en plein champ : normal ici, seule leur taille et
## leur hauteur de suspension comptent (agent B les posera contre un vrai mur).
##   godot --path Godot --headless --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/jp_decors_a.gd

const ST := "res://story/stage.gd"

const STEPS := [
	[0.85, "vsync", false], [0.86, "talk", true],
	[1.0, "zone", &"plaines"], [1.1, "calm", 900.0], [1.2, "weather", &"clear"], [1.3, "clock", 11.0],
	# Spawn the 12 decors (fade-in 0.35 s), spread out along y=70 (open grassland, no trees) so the
	# widest ones (cloture_brisee ~5.8 m, barque_arbre ~5 m) don't overlap their neighbours.
	[2.5, "static", [ST, "show_thing", "griffe_fossile", Vector2(10.0, 70.0), "D_griffe_fossile"]],
	[2.6, "static", [ST, "show_thing", "affiche_ambre", Vector2(18.0, 70.0), "D_affiche_ambre"]],
	[2.7, "static", [ST, "show_thing", "chapeau_helene", Vector2(26.0, 70.0), "D_chapeau_helene"]],
	[2.8, "static", [ST, "show_thing", "canne_roc", Vector2(34.0, 70.0), "D_canne_roc"]],
	[2.9, "static", [ST, "show_thing", "ambre_moustique", Vector2(42.0, 70.0), "D_ambre_moustique"]],
	[3.0, "static", [ST, "show_thing", "barque_arbre", Vector2(50.0, 70.0), "D_barque_arbre"]],
	[3.1, "static", [ST, "show_thing", "cloture_brisee", Vector2(58.0, 70.0), "D_cloture_brisee"]],
	[3.2, "static", [ST, "show_thing", "banderole_fouilles", Vector2(66.0, 70.0), "D_banderole_fouilles"]],
	[3.3, "static", [ST, "show_thing", "creme_raser", Vector2(74.0, 70.0), "D_creme_raser"]],
	[3.4, "static", [ST, "show_thing", "coffre_comptoir", Vector2(82.0, 70.0), "D_coffre_comptoir"]],
	[3.5, "static", [ST, "show_thing", "table_cuisine", Vector2(90.0, 70.0), "D_table_cuisine"]],
	[3.6, "static", [ST, "show_thing", "flaque_ronde", Vector2(98.0, 70.0), "D_flaque_ronde"]],
	# One shot per decor, Chloé 1.5 cases south of it, facing north (close-up, like vis_monts_decor.gd).
	[4.8, "tp", Vector2(10.0, 71.5)], [4.9, "face", Vector2(0, -1)], [5.3, "shot", "jp_griffe_fossile"],
	[5.5, "tp", Vector2(18.0, 71.5)], [5.6, "face", Vector2(0, -1)], [6.0, "shot", "jp_affiche_ambre"],
	[6.2, "tp", Vector2(26.0, 71.5)], [6.3, "face", Vector2(0, -1)], [6.7, "shot", "jp_chapeau_helene"],
	[6.9, "tp", Vector2(34.0, 71.5)], [7.0, "face", Vector2(0, -1)], [7.4, "shot", "jp_canne_roc"],
	[7.6, "tp", Vector2(42.0, 71.5)], [7.7, "face", Vector2(0, -1)], [8.1, "shot", "jp_ambre_moustique"],
	[8.3, "tp", Vector2(50.0, 73.0)], [8.4, "face", Vector2(0, -1)], [8.8, "shot", "jp_barque_arbre"],
	[9.0, "tp", Vector2(58.0, 72.0)], [9.1, "face", Vector2(0, -1)], [9.5, "shot", "jp_cloture_brisee"],
	[9.7, "tp", Vector2(66.0, 72.0)], [9.8, "face", Vector2(0, -1)], [10.2, "shot", "jp_banderole_fouilles"],
	[10.4, "tp", Vector2(74.0, 71.5)], [10.5, "face", Vector2(0, -1)], [10.9, "shot", "jp_creme_raser"],
	[11.1, "tp", Vector2(82.0, 71.5)], [11.2, "face", Vector2(0, -1)], [11.6, "shot", "jp_coffre_comptoir"],
	[11.8, "tp", Vector2(90.0, 71.5)], [11.9, "face", Vector2(0, -1)], [12.3, "shot", "jp_table_cuisine"],
	[12.5, "tp", Vector2(98.0, 71.5)], [12.6, "face", Vector2(0, -1)], [13.0, "shot", "jp_flaque_ronde"],
	[13.3, "state", null],
]
