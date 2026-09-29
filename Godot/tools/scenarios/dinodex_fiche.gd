extends RefCounted
## One full sheet of the Dinodex (29/09), top to bottom: a species caught (Velociraptor): its
## abilities out in the world, its attacks, its strengths, its true story, the notebook.

## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/dinodex_fiche.gd

const H := "res://tools/scenarios/dinodex_outils.gd"
const STEPS := [
	[0.8, "static", [H, "setup"]], [0.9, "calm", 900.0], [0.9, "clock", 11.0],
	[1.5, "static", [H, "open"]], [1.9, "static", [H, "entry", "stegosaurus"]],
	[2.4, "static", [H, "scroll_entry", 760]], [2.9, "shot", "df01_terrain_attaques"],
	[3.0, "static", [H, "scroll_entry", 5000]], [3.5, "shot", "df02_fin"],
]
