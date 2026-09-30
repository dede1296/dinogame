extends RefCounted
## Visual check (30/09): the menu's « Commandes » page — what every key and every finger does,
## the phone on one side, the computer on the other.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_commandes.gd

const H := "res://tools/scenarios/menu_outils.gd"
const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines"]], [0.9, "calm", 900.0], [1.0, "clock", 11.0],
	[1.2, "zone", &"plaines"], [3.0, "tp", Vector2(60.0, 60.0)],
	[3.6, "static", [H, "open"]], [4.2, "shot", "m1_menu"],
	[4.4, "static", [H, "page", "commandes"]], [5.2, "shot", "m2_commandes"],
	[5.6, "state", null],
]
