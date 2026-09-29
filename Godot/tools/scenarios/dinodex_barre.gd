extends RefCounted
## The party bar alone (29/09): a portrait dragged with a finger onto the first one (they swap,
## the dino following Chloé changes), then one dropped nowhere (nothing changes).

## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/dinodex_barre.gd

const H := "res://tools/scenarios/dinodex_outils.gd"
const STEPS := [
	[0.8, "static", [H, "setup"]], [0.9, "calm", 900.0], [0.9, "clock", 11.0], [0.95, "weather", &"clear"],
	[2.0, "static", [H, "bar_drag_begin", 4, 0]], [2.4, "shot", "db01_barre_glisse"],
	[2.5, "static", [H, "bar_drag_end", 0]], [3.3, "static", [H, "report"]], [3.4, "shot", "db02_barre_apres"],
	[3.6, "static", [H, "bar_drag_begin", 1, 3]], [4.0, "static", [H, "bar_drag_end", 3]], [4.6, "static", [H, "report"]],
]
