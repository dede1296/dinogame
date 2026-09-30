extends RefCounted
## Check (30/09): Élise Sablier's crouch (the « accroupi » pose, sheet elise_accroupie).
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_elise_pose.gd

const H := "res://tools/scenarios/elise_outils.gd"
const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "met_maia"]],
	[0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "no_help", null], [1.2, "zone", &"plaines"],
	[3.4, "tp", Vector2(79.9, 57.6)], [3.6, "face", Vector2(0, -1)], [4.2, "shot", "p1_debout"],
	[4.6, "static", [H, "crouch"]], [5.6, "shot", "p2_accroupie"],
	[6.0, "static", [H, "stand"]], [7.0, "shot", "p3_relevee"],
	[7.4, "state", null],
]
