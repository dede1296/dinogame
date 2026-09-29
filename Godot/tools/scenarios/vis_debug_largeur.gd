extends RefCounted
## Visual check only (29/09): the debug window keeps its width when the party's levels change
## (its status line wraps instead of pushing the window right).
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_debug_largeur.gd

const STEPS := [
	[0.8, "give", "compsognathus"], [0.85, "give", "protoceratops"], [0.9, "give", "baryonyx"], [0.95, "give", "triceratops"],
	[1.2, "zone", &"plaines"], [3.0, "debug", null],
	[3.4, "shot", "dbg_1_avant"],
	[3.5, "debug_call", ["_party_level", [5]]], [3.6, "debug_call", ["_party_level", [5]]], [3.7, "debug_call", ["_party_level", [5]]],
	[3.8, "debug_call", ["_party_level", [5]]], [3.9, "debug_call", ["_party_level", [5]]], [4.0, "debug_call", ["_party_level", [5]]],
	[4.4, "shot", "dbg_2_apres"],
	[4.6, "state", null],
]
