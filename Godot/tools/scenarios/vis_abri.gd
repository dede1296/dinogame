extends RefCounted
## Visual check only (29/09): Bertille's rock shelter against its knoll.

## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_abri.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "monts_arrivee"]],
	[0.9, "calm", 900.0], [0.9, "talk", true], [1.0, "clock", 11.0], [1.0, "vsync", false],
	[1.2, "zone", &"monts"], [3.2, "wait_idle", [1, 40]], [3.4, "weather", &"clear"],
	[3.5, "tp", Vector2(20.5, 61.5)], [3.6, "face", Vector2(0, -1)], [4.4, "shot", "ab_1_face"], [4.6, "tp", Vector2(25.5, 61.0)], [4.7, "face", Vector2(-1, -1)], [5.5, "shot", "ab_2_biais"],
	[5.7, "state", null],
]
