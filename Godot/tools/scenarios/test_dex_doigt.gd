extends RefCounted
## Check (29/09): the Dinodex's dinos dragged with a FINGER (touch events, as on a phone): the
## portrait is drawn above the finger and the place under the PORTRAIT takes it (what one sees),
## else the nearest one. A finger aiming with the portrait (below the place), a thumb whose first
## move is a little more up than sideways, a finger right on a place (the portrait over the one
## above); the MOUSE: the portrait is the pointer, the place under it. Then the party bar with a
## thumb pressing below its row. The team printed after each.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_dex_doigt.gd

const H := "res://tools/scenarios/dinodex_outils.gd"
const STEPS := [
	[0.8, "static", [H, "setup"]], [0.9, "calm", 900.0], [0.9, "clock", 11.0],
	[2.1, "static", [H, "open"]], [2.6, "static", [H, "page", "reserve"]],
	# a finger aiming with the portrait: its tip 50 px below place 1's middle → place 1
	[3.0, "static", [H, "finger_drag", 0, 1, 40.0, 0.0, 0.0, 50.0]], [3.3, "shot", "d1_vise_avec_le_portrait"],
	[3.4, "static", [H, "finger_drop"]], [3.7, "static", [H, "report"]],
	# a thumb: its first move a little more up than sideways, then aiming at place 2 → place 2
	[4.0, "static", [H, "finger_drag", 0, 2, 12.0, -16.0, 0.0, 50.0]],
	[4.4, "static", [H, "finger_drop"]], [4.7, "static", [H, "report"]],
	# the finger right on place 4: the portrait is over place 3 (lit) → place 3
	[5.0, "static", [H, "finger_drag", 0, 4, 40.0, 0.0, 0.0, 0.0]], [5.3, "shot", "d3_doigt_sur_la_place"],
	[5.4, "static", [H, "finger_drop"]], [5.7, "static", [H, "report"]],
	# the mouse: the pointer on place 4 → place 4
	[6.0, "static", [H, "drag_begin", 0, 4]], [6.3, "shot", "d4_souris"], [6.4, "static", [H, "drag_end", 4]],
	[6.7, "static", [H, "report"]],
	# the party bar, the Dinodex closed: a thumb takes the last portrait to the 2nd, its tip 50 px
	# below that one's middle (under the row) → they swap
	[7.0, "static", [H, "close"]], [7.8, "static", [H, "bar_thumb", 4, 1, 0.0, 50.0]], [8.1, "shot", "d5_barre_pouce"],
	[8.2, "static", [H, "bar_drop"]], [8.6, "static", [H, "report"]],
	[8.8, "state", null],
]
