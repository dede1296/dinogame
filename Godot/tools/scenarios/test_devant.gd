extends RefCounted
## Check (29/09): Chloé in front of a Grand Voyageur is drawn over it, not hidden by its legs
## (the pictures are sorted by their feet), and behind it, it turns see-through like tall scenery.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_devant.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines"]], [0.9, "calm", 900.0], [1.0, "clock", 11.0],
	[1.1, "no_help", null], [1.2, "zone", &"plaines"],
	# in front of it (south): she must be seen whole
	[3.0, "tp", Vector2(54.0, 50.2)], [3.2, "face", Vector2(0, -1)], [4.2, "shot", "d1_devant"],
	[4.4, "tp", Vector2(54.0, 49.4)], [5.2, "shot", "d2_tout_pres"],
	# beside it
	[5.4, "tp", Vector2(56.0, 48.8)], [6.2, "shot", "d3_a_cote"],
	# behind it (north): it turns see-through
	[6.4, "tp", Vector2(54.0, 47.2)], [7.2, "shot", "d4_derriere"],
	[7.6, "state", null],
]
