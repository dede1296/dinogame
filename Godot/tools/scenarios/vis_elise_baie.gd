extends RefCounted
## Check (30/09): the berry half of Élise Sablier's scene — Chloé walks up to the sleeping
## Triceratops, gives it a berry, it wakes and stands, and nudges Élise into the pile. Watching
## that nobody is cut by the edge of the screen.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_elise_baie.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "met_maia", "elise_vue"]],
	[0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "dlog", true], [1.12, "no_help", null],
	[1.15, "item", ["baie", 3]], [1.2, "zone", &"plaines"],
	[3.4, "tp", Vector2(79.2, 57.1)], [3.6, "face", Vector2(0, -1)], [4.2, "interact_now", null],
	[5.4, "shot", "b1_question"], [5.8, "press", "ui_accept"],
	[7.0, "shot", "b2_approche"], [9.0, "shot", "b3_tend_la_baie"],
	[9.40, "press", "interact"],
	[10.50, "press", "interact"],
	[11.60, "press", "interact"],
	[13.2, "shot", "b4_renifle"],
	[13.60, "press", "interact"],
	[14.70, "press", "interact"],
	[15.80, "press", "interact"],
	[17.4, "shot", "b5_se_releve"],
	[17.80, "press", "interact"],
	[18.90, "press", "interact"],
	[20.00, "press", "interact"],
	[21.6, "shot", "b6_coup_de_museau"],
	[22.00, "press", "interact"],
	[23.10, "press", "interact"],
	[24.20, "press", "interact"],
	[25.30, "press", "interact"],
	[27.0, "shot", "b7_assise"],
	[27.40, "press", "interact"],
	[28.50, "press", "interact"],
	[29.60, "press", "interact"],
	[30.70, "press", "interact"],
	[32.5, "shot", "b8_fin"], [33.0, "state", null],
]
