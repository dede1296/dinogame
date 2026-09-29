extends RefCounted
## Visual check only (29/09): the dragonflies' size and their single drawing (no doubling), in the marsh by day.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_libellules.gd

const STEPS := [
	[0.8, "clock", 11.0], [0.84, "weather", &"clear"], [0.87, "vsync", false],
	[1.0, "zone", &"marais"], [3.5, "weather", &"clear"], [3.6, "calm", 900.0], [3.7, "tp", Vector2(84, 43)],
	[6.5, "shot", "li_a"], [7.3, "shot", "li_b"], [8.1, "shot", "li_c"],
	[8.3, "state", null],
]
