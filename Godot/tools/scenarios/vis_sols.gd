extends RefCounted
## Check (30/09): the ground in every kind of zone, now that its tiling materials share one
## stack of textures (ground.gdshader « materials ») — grass and paths, the Marais' mud, the
## Désert's rock and dunes, the Monts' snow cover, a cave.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_sols.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "foret_arrivee", "marais_arrivee",
		"desert_arrivee", "cote_arrivee", "monts_arrivee", "glacier_arrivee"]],
	[0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "no_help", null], [1.15, "weather", &"clear"],
	[1.2, "zone", &"plaines"], [3.4, "tp", Vector2(60.0, 50.0)], [4.2, "shot", "s1_prairie"],
	[4.6, "zone", &"marais"], [7.0, "tp", Vector2(100.0, 68.0)], [7.8, "shot", "s2_marais"],
	[8.2, "zone", &"desert"], [10.6, "tp", Vector2(85.0, 68.0)], [11.4, "shot", "s3_desert"],
	[11.8, "zone", &"cote"], [14.2, "tp", Vector2(20.0, 90.0)], [15.0, "shot", "s4_cote"],
	[15.4, "zone", &"monts"], [17.8, "tp", Vector2(10.0, 28.0)], [18.6, "shot", "s5_monts"],
	[19.0, "zone", &"grottes_glace"], [21.4, "tp", Vector2(20.0, 20.0)], [22.2, "shot", "s6_grotte"],
	[22.8, "state", null],
]
