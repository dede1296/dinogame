extends RefCounted
## Visual check only (29/09): the turtles' nest repainted live (Stage.repaint, end of the scene).
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_nid_repaint.gd

const STEPS := [
	[0.8, "flags", ["sceau_plaines", "havre_arrive", "selle", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "moustique_vu"]],
	[1.0, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "vsync", false],
	[1.2, "zone", &"cote"], [3.4, "weather", &"clear"], [3.5, "tp", Vector2(18.2, 76.8)], [3.6, "face", Vector2(-1, 0)],
	[4.3, "shot", "nr_1_plein"],
	[4.4, "static", ["res://story/stage.gd", "repaint", "@NidTortues", "nid_tortue_vide"]],
	[5.8, "shot", "nr_2_vide"],
	[6.0, "state", null],
]
