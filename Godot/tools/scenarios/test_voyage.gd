extends RefCounted
## Check (29/09): the Grand Voyageur — the first meeting (it sneezes on Chloé), the stop noted,
## the line when she knows only that one, then the destination screen: the stops found, her own
## greyed out, and « Rester ici » that changes nothing.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_voyage.gd

const H := "res://tools/scenarios/voyage_outils.gd"
const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines"]], [0.9, "calm", 900.0], [1.0, "clock", 11.0],
	[1.1, "talk", true], [1.2, "zone", &"plaines"],
	[3.0, "tp", Vector2(60.0, 48.0)], [3.2, "static", [H, "report"]],
	# the first meeting: it leans down, sniffs, sneezes, kneels
	[3.4, "static", [H, "talk"]],
	[4.6, "shot", "v1_penche"], [6.2, "shot", "v2_renifle"], [8.4, "shot", "v3_atchoum"],
	[11.5, "shot", "v4_agenouille"], [14.0, "static", [H, "report"]],
	# only one stop known: it waits, no screen
	[14.2, "static", [H, "rows"]], [14.6, "shot", "v5_une_seule_escale"],
	# three stops known: the screen, with the Prairie greyed out
	[15.5, "static", [H, "know", ["havre_dore", "foret"]]],
	[15.8, "static", [H, "talk"]], [16.6, "static", [H, "rows"]], [17.0, "shot", "v6_ecran"],
	[17.2, "static", [H, "press", "Rester"]], [17.8, "static", [H, "report"]], [18.2, "shot", "v7_reste"],
	[18.5, "state", null],
]
