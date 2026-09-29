extends RefCounted
## Visual checks only (29/09, finishing pass of chapters 1-5), no scene played: the things scenes
## show (Stage.show_thing) side by side at their size, the empty turtles' nest (on loading, and
## repainted live), the egg rock / Chipie's nest bush / Dimorphodon nests after their rescale,
## the painted cart wheel.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_finition_integ.gd

const ST := "res://story/stage.gd"
const DS := "res://story/desert_sanctuaire.gd"

const STEPS := [
	[0.8, "flags", ["sceau_plaines", "maia_defi_1", "havre_arrive", "selle", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "moustique_vu", "tortues_sauvees"]],
	[1.0, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "vsync", false],
	# The things of the scenes, by Chloé on the beach.
	[1.2, "zone", &"cote"], [3.4, "weather", &"clear"], [3.5, "tp", Vector2(26, 72)], [3.6, "face", Vector2(0, 1)],
	[3.8, "static", [ST, "show_thing", "boite_fer_blanc", Vector2(24.6, 73.2), "T1"]],
	[3.8, "static", [ST, "show_thing", "piege_machoires", Vector2(25.5, 73.4), "T2"]],
	[3.8, "static", [ST, "show_thing", "tube_cuivre", Vector2(26.5, 73.4), "T3"]],
	[3.8, "static", [ST, "show_thing", "boite_ronde", Vector2(27.3, 73.2), "T4"]],
	[3.8, "static", [ST, "show_thing", "registre", Vector2(28.2, 73.3), "T5"]],
	[4.8, "shot", "fi_1_objets"],
	# The nest: empty on loading (tortues_sauvees).
	[5.0, "tp", Vector2(16.0, 75.8)], [5.1, "face", Vector2(0, 1)], [6.0, "shot", "fi_2_nid_vide"],
	# The painted wheel.
	[6.2, "zone", &"desert"], [8.4, "weather", &"clear"], [8.5, "tp", Vector2(60.5, 12.0)],
	[8.7, "static", [DS, "_make_wheel", Vector2(61.8, 12.6)]],
	[9.6, "shot", "fi_3_roue"],
	# The Plaines: egg rock, Chipie's bush, the Dimorphodon nests.
	[9.8, "zone", &"plaines"], [12.0, "weather", &"clear"],
	[12.1, "tp", Vector2(65.0, 41.4)], [12.2, "face", Vector2(0, -1)], [13.0, "shot", "fi_4_rocher_oeuf"],
	[13.2, "tp", Vector2(40.6, 35.9)], [13.3, "face", Vector2(0, -1)], [14.1, "shot", "fi_5_buisson_nid"],
	[14.3, "tp", Vector2(97.0, 11.6)], [14.4, "face", Vector2(0, -1)], [15.2, "shot", "fi_6_nids_dimorphodon"],
	[15.4, "state", null],
]
