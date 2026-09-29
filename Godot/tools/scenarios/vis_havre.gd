extends RefCounted
## Visual check only (29/09): the dark boat of the Havre's night scene, in the water along the pier.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_havre.gd

const STEPS := [
	[0.8, "flags", ["sceau_plaines", "maia_defi_1", "havre_arrive", "barque_vue"]],
	[1.0, "calm", 900.0], [1.0, "clock", 22.5], [1.1, "weather", &"clear"], [1.2, "zone", &"havre_dore"],
	[3.2, "clock", 22.5], [3.3, "tp", Vector2(47.5, 24.5)], [3.4, "face", Vector2(0, 1)],
	[3.5, "static", ["res://story/cote_stage.gd", "prop", "barque", Vector2(44.3, 27.8), "BarqueTest", true]],
	[4.5, "shot", "h1_barque_nuit"],
	[4.8, "state", null],
]
