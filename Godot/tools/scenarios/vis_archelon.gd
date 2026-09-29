extends RefCounted
## Visual check only (29/09): the Archelon from the front, from behind and from the side, crawling
## flat on the sand (its first front/back views stood up). No scene played.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_archelon.gd

const ST := "res://story/stage.gd"
const CS := "res://story/cote_stage.gd"

const STEPS := [
	[0.8, "flags", ["cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "moustique_vu"]],
	[1.0, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "weather", &"clear"], [1.1, "vsync", false], [1.2, "zone", &"cote"],
	[3.4, "weather", &"clear"], [3.5, "tp", Vector2(26, 72)],
	[3.8, "static", [CS, "stand_in", "archelon", Vector2(23.5, 74.5), "ArchFace"]],
	[3.8, "static", [CS, "stand_in", "archelon", Vector2(26.5, 74.8), "ArchDos"]],
	[3.8, "static", [CS, "stand_in", "archelon", Vector2(29.5, 74.5), "ArchProfil"]],
	[3.9, "static", [ST, "turn_to", "@ArchFace", Vector2(1128.0, 3900.0)]],
	[3.9, "static", [ST, "turn_to", "@ArchDos", Vector2(1272.0, 3000.0)]],
	[3.9, "static", [ST, "turn_to", "@ArchProfil", Vector2(1700.0, 3576.0)]],
	[4.0, "static", [ST, "fade_in", "@ArchFace", 0.3]],
	[4.0, "static", [ST, "fade_in", "@ArchDos", 0.3]],
	[4.0, "static", [ST, "fade_in", "@ArchProfil", 0.3]],
	[5.0, "shot", "ar_1"],
	[5.2, "state", null],
]
