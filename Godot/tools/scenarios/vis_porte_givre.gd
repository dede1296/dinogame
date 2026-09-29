extends RefCounted
## Visual check only (29/09): the Monts' frost door, front-on in its notch (the first picture was
## drawn at an angle and looked turned aside).
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_porte_givre.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "monts_arrivee"]],
	[0.9, "calm", 900.0], [0.9, "talk", true], [1.0, "clock", 11.0], [1.0, "vsync", false],
	[1.2, "zone", &"monts"], [3.2, "wait_idle", [1, 40]], [3.4, "weather", &"clear"],
	[3.5, "tp", Vector2(114.5, 10.0)], [3.6, "face", Vector2(0, -1)], [4.4, "shot", "pg_givre"],
	[4.6, "state", null],
]
