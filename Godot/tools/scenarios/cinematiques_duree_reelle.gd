extends RefCounted
## Les deux films en entier, en TEMPS RÉEL, sans rien toucher (3 min 10) : la durée mesurée de l'intro
## (jusqu'au noir de la fin) et de la fin (jusqu'au défilé des crédits, carton F-10 compris), plan par
## plan (lignes « static debug_timeline » et « Cinématique « intro » : … s à l'écran »).
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/cinematiques_duree_reelle.gd titre="Les deux cinématiques en temps réel : durée mesurée, plan par plan"

const C := "res://story/cinematiques.gd"

const STEPS := [
	[0.80, "flags", ["tuto_commandes"]],
	[2.00, "static", [C, "debug_play", "intro", 0]],
	[84.0, "static", [C, "debug_timeline"]],
	[85.0, "static", [C, "debug_play", "fin", 0]],
	[184.0, "static", [C, "debug_timeline"]],
	[184.1, "shot", "dr3_fin_debut_du_defile"],
	[184.2, "static", [C, "debug_press", "skip"]],
	[184.3, "static", [C, "debug_press", "skip"]],
	[186.5, "static", [C, "debug_timeline"]],
]
