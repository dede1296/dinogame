extends RefCounted
## Check (29/09): what tells the player the fast travel exists — Roc explains the Grands
## Voyageurs the first time Chloé sees him after meeting one (once only), and the question
## « Les Grands Voyageurs ? » then appears in her questions.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_voyage_textes.gd

const H := "res://tools/scenarios/voyage_outils.gd"
const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "met_maia", "prologue_done"]], [0.9, "calm", 900.0],
	[1.0, "clock", 11.0], [1.1, "talk", true], [1.2, "zone", &"cabinet"],
	# before meeting one: no question about them
	[3.0, "static", [H, "topics"]],
	# after meeting one: Roc explains, once
	[3.4, "static", [H, "know", ["plaines"]]], [3.5, "flags", ["voyageur_rencontre"]],
	[3.8, "static", [H, "topics"]],
	[4.0, "static", [H, "roc"]], [5.4, "shot", "t1_roc_explique"], [8.0, "shot", "t2_roc_suite"],
	[13.0, "static", [H, "report"]],
	# talked to again: he does not say it twice
	[13.4, "static", [H, "roc"]], [14.6, "shot", "t3_deuxieme_fois"],
	[15.2, "state", null],
]
