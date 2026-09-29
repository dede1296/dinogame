extends RefCounted
## Check (29/09): Chloé's speeds, walking, running (B / Shift held), in boots, on her mount.
## Prints her position before and after 1.5 s of walking right on the Plaines' open meadow.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_vitesses.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines"]], [0.9, "calm", 900.0], [1.0, "vsync", false], [1.2, "zone", &"plaines"],
	# walking
	[3.0, "tp", Vector2(40.0, 60.0)], [3.3, "where", "marche_0"], [3.3, "hold", "move_right"], [4.8, "hold", ""], [4.8, "where", "marche_1"],
	# running (B)
	[5.2, "tp", Vector2(40.0, 60.0)], [5.5, "hold_also", ["cancel", true]], [5.5, "where", "course_0"], [5.5, "hold", "move_right"],
	[7.0, "hold", ""], [7.0, "where", "course_1"], [7.0, "hold_also", ["cancel", false]],
	# boots: walking, running (Shift)
	[7.2, "item", ["bottes", 1]],
	[7.4, "tp", Vector2(40.0, 60.0)], [7.7, "where", "bottes_0"], [7.7, "hold", "move_right"], [9.2, "hold", ""], [9.2, "where", "bottes_1"],
	[9.6, "tp", Vector2(40.0, 60.0)], [9.9, "hold_also", ["run", true]], [9.9, "where", "bottes_course_0"], [9.9, "hold", "move_right"],
	[11.4, "hold", ""], [11.4, "where", "bottes_course_1"], [11.4, "hold_also", ["run", false]],
	[11.6, "state", null],
]
