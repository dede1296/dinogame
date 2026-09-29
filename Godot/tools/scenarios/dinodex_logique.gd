extends RefCounted
## The Dinodex's rules (29/09): hints by what Chloé knows, the team's limits, no Dinodex during
## a scene; opened in the water (the team locked: buttons off, no drag); Roc's rewards for
## the Dinodex at the Cabinet.

## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/dinodex_logique.gd

const H := "res://tools/scenarios/dinodex_outils.gd"
const STEPS := [
	[0.8, "static", [H, "setup"]], [0.9, "calm", 900.0], [0.9, "clock", 11.0], [0.95, "weather", &"clear"],
	[1.5, "static", [H, "logic"]],
	[1.8, "static", [H, "open_locked"]], [2.2, "static", [H, "entry", "velociraptor"]], [2.6, "static", [H, "scroll_entry", 420]],
	[3.1, "shot", "dl01_verrou_fiche"],
	[3.2, "static", [H, "page", "reserve"]], [3.6, "static", [H, "drag_begin", 0, 2]], [4.0, "shot", "dl02_verrou_glisse"],
	[4.1, "static", [H, "drag_end", 2]], [4.5, "static", [H, "report"]], [4.6, "static", [H, "close"]],
	[5.0, "static", [H, "catch_more", 5]],
	[5.2, "talk", true], [5.3, "static", ["res://story/story.gd", "_dex_rewards"]], [5.9, "shot", "dl03_roc_recompense"],
	[9.0, "talk", false], [9.1, "static", [H, "catch_more", 0]], [9.2, "state", null],
]
