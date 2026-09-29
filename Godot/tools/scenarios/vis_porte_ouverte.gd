extends RefCounted
## Visual check only (29/09): the frost door's notch once the door has melted (the dark way into
## the sanctuary behind it), and the door still closed.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_porte_ouverte.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "monts_arrivee"]],
	[0.9, "calm", 900.0], [0.9, "talk", true], [1.0, "clock", 11.0], [1.0, "vsync", false],
	[1.2, "zone", &"monts"], [3.2, "wait_idle", [1, 40]], [3.4, "weather", &"clear"],
	[3.5, "tp", Vector2(114.5, 10.5)], [3.6, "face", Vector2(0, -1)], [4.4, "shot", "po_fermee"],
	[4.6, "flags", ["sanctuaire_givre_ouvert"]], [4.7, "zone", &"monts"], [6.7, "wait_idle", [1, 40]], [6.9, "weather", &"clear"],
	[7.0, "tp", Vector2(114.5, 10.5)], [7.1, "face", Vector2(0, -1)], [7.9, "shot", "po_ouverte"],
	[8.1, "state", null],
]
