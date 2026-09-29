extends RefCounted
## Check (29/09): on a touch screen, a thumb walks (joystick) and the other one presses B to run
## on the way: Chloé must keep walking, then run (the camera used to take B's finger for a pinch
## and let go of the joystick). Prints her position: walking 1.5 s, then B held 1.5 s, then B let go.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_course_tactile.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines"]], [0.9, "calm", 900.0], [1.0, "vsync", false], [1.2, "zone", &"plaines"],
	[3.0, "tp", Vector2(40.0, 60.0)],
	[3.3, "touch", [0, "down", Vector2(260.0, 520.0)]], [3.35, "touch", [0, "drag", Vector2(330.0, 520.0)]],
	[3.4, "where", "marche_0"], [4.9, "where", "marche_1"],
	[4.9, "touch", [1, "down", "B"]], [4.9, "where", "course_0"], [6.4, "where", "course_1"],
	[6.4, "touch", [1, "up", "B"]], [6.4, "where", "apres_0"], [7.9, "where", "apres_1"],
	[7.9, "touch", [0, "up", Vector2(330.0, 520.0)]], [8.4, "where", "arret"],
	[8.6, "state", null],
]
