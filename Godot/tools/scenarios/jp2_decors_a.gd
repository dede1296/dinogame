extends RefCounted
## Clins d'œil à Jurassic Park — agent A, 2e passe (NOUVELLE DIRECTION), contrôle visuel des 5
## décors neufs/refaits (tailles réelles, Prop.KINDS), montrés par Stage.show_thing comme
## jp_decors_a.gd (pas de zone régénérée : simple contrôle d'échelle contre Chloé dans les
## Plaines, une zone existante). Un décor par capture, Chloé 1,5 case au sud, face au nord.
##   godot --path Godot --headless --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/jp2_decors_a.gd

const ST := "res://story/stage.gd"

const STEPS := [
	[0.85, "vsync", false], [0.86, "talk", true],
	[1.0, "zone", &"plaines"], [1.1, "calm", 900.0], [1.2, "weather", &"clear"], [1.3, "clock", 11.0],
	# voiture_arbre is by far the tallest (~11.8 m, same height as arbre_geant): spread wide (y=70)
	# so it does not overlap its neighbours.
	# creme_raser (x=10) and crottes_triceratops (x=40) at y=70 landed in a lake / thick reeds in the
	# 1st try (hidden) — moved to y=66, a drier row nearer their working neighbours.
	[2.5, "static", [ST, "show_thing", "creme_raser", Vector2(10.0, 66.0), "D_creme_raser"]],
	[2.6, "static", [ST, "show_thing", "affiche_adn", Vector2(18.0, 70.0), "D_affiche_adn"]],
	[2.7, "static", [ST, "show_thing", "banderole_fouilles", Vector2(28.0, 70.0), "D_banderole_fouilles"]],
	[2.8, "static", [ST, "show_thing", "crottes_triceratops", Vector2(34.0, 74.0), "D_crottes_triceratops"]],
	[2.9, "static", [ST, "show_thing", "voiture_arbre", Vector2(52.0, 70.0), "D_voiture_arbre"]],
	# One shot per decor, Chloé 1.5 cases south of it, facing north (close-up, like jp_decors_a.gd).
	[4.2, "tp", Vector2(10.0, 67.5)], [4.3, "face", Vector2(0, -1)], [4.7, "shot", "jp2_creme_raser"],
	[4.9, "tp", Vector2(18.0, 71.5)], [5.0, "face", Vector2(0, -1)], [5.4, "shot", "jp2_affiche_adn"],
	[5.6, "tp", Vector2(28.0, 71.5)], [5.7, "face", Vector2(0, -1)], [6.1, "shot", "jp2_banderole_fouilles"],
	[6.3, "tp", Vector2(34.0, 75.5)], [6.4, "face", Vector2(0, -1)], [6.8, "shot", "jp2_crottes_triceratops"],
	# voiture_arbre is much taller than Chloé: stand a little further back (3 cases) so the whole
	# tree+car fits in frame, like vis_monts_decor.gd does for its tallest props.
	[7.0, "tp", Vector2(52.0, 73.0)], [7.1, "face", Vector2(0, -1)], [7.5, "shot", "jp2_voiture_arbre"],
	[7.8, "state", null],
]
