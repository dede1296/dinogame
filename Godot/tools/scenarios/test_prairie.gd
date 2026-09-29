extends RefCounted
## Check (29/09): the region renamed « Prairie du Grand Crâne » (Chapitre 1) shows correctly:
## title screen subtitle, entering the zone (banner), the pause map, the Dinodex tab and page.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_prairie.gd

const STEPS := [
	[1.0, "shot", "p0_titre"],
	[1.2, "new_game", null], [1.4, "clock", 11.0], [1.6, "shot", "p1_arrivee_banniere"],
	[2.4, "press", "map"], [2.9, "shot", "p2_carte_pause"], [3.0, "press", "cancel"],
	[3.3, "static", ["res://tools/scenarios/dinodex_outils.gd", "setup"]],
	[3.4, "static", ["res://tools/scenarios/dinodex_outils.gd", "open"]],
	[3.8, "static", ["res://tools/scenarios/dinodex_outils.gd", "page", "plaines"]],
	[4.2, "shot", "p3_dex_onglet"],
	[4.3, "press", "cancel"], [4.5, "state", null],
]
