extends RefCounted
## Visual checks only (29/09): the empty turtles' nest seen clearly, and the painted cart wheel.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_finition_integ2.gd

const DS := "res://story/desert_sanctuaire.gd"

const STEPS := [
	[0.8, "flags", ["sceau_plaines", "maia_defi_1", "havre_arrive", "selle", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "moustique_vu", "tortues_sauvees", "desert_arrivee", "sirocco_vue"]],
	[1.0, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "vsync", false],
	[1.2, "zone", &"cote"], [3.4, "weather", &"clear"], [3.5, "tp", Vector2(18.2, 76.8)], [3.6, "face", Vector2(-1, 0)],
	[4.4, "shot", "fj_1_nid_vide"], [5.4, "shot", "fj_2_nid_vide"],
	[5.6, "zone", &"desert"], [7.8, "weather", &"clear"], [7.9, "tp", Vector2(102.0, 92.0)],
	[8.1, "static", [DS, "_make_wheel", Vector2(103.4, 92.8)]],
	[9.0, "shot", "fj_3_roue"],
	[9.2, "state", null],
]
