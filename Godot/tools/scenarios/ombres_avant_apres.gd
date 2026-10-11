extends Node
## Steps for tools/capture.gd: les ombres aplaties (11/10) — les mêmes vues avant et après, météo
## fixée à « clair », à 7 h, 12 h 30 et 18 h 30 : la lisière d'arbres et les buissons de la Prairie,
## les hautes herbes, Vif qui marche à côté de Chloé, le quai de Port-Ambre (barques, filet,
## séchoir), les pieux de la clairière de la Forêt. Puis les images/s, sans vsync, à qualité Haute,
## aux trois endroits (Prairie, forêt, port), trois relevés chacun.
## Se lance deux fois (avant/après) en ne changeant que le code.
##   godot --path Godot --script res://tools/capture.gd -- out=<dossier>
##       scenario_file=res://tools/scenarios/ombres_avant_apres.gd titre="Ombres : avant / après"
const STEPS := [
	[0.6, "flags", ["sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee"]],
	[0.7, "quality", 2], [0.8, "calm", 900.0], [0.85, "weather", &"clear"],
	# La Prairie : la lisière d'arbres (arbres, buissons, rochers).
	[0.9, "clock", 7.0], [1.0, "tp", Vector2(47.0, 70.0)], [2.6, "weather", &"clear"], [3.0, "shot", "a_lisiere_07h"],
	[3.1, "clock", 12.5], [3.15, "weather", &"clear"], [4.4, "shot", "a_lisiere_12h30"],
	[4.5, "clock", 18.5], [4.55, "weather", &"clear"], [5.8, "shot", "a_lisiere_18h30"],
	# Les hautes herbes, et Vif qui marche.
	[5.9, "clock", 7.0], [5.95, "weather", &"clear"], [6.0, "tp", Vector2(58.0, 62.0)], [7.6, "shot", "b_herbes_07h"],
	[7.7, "clock", 12.5], [7.75, "weather", &"clear"], [9.0, "shot", "b_herbes_12h30"],
	[9.1, "clock", 18.5], [9.15, "weather", &"clear"], [10.4, "shot", "b_herbes_18h30"],
	[10.5, "clock", 17.5], [10.55, "weather", &"clear"], [10.6, "tp", Vector2(52.0, 66.0)], [11.8, "hold", "move_right"],
	[12.55, "shot", "c_marche_17h30_1"], [12.72, "shot", "c_marche_17h30_2"], [12.9, "hold", ""],
	# Port-Ambre : le quai, les barques, le filet, le séchoir.
	[13.0, "zone", &"port_ambre"], [14.6, "calm", 900.0], [14.65, "clock", 7.0], [14.7, "weather", &"clear"],
	[14.8, "tp", Vector2(14.0, 15.5)], [16.4, "shot", "d_port_07h"],
	[16.5, "clock", 12.5], [16.55, "weather", &"clear"], [17.8, "shot", "d_port_12h30"],
	[17.9, "clock", 18.5], [17.95, "weather", &"clear"], [19.2, "shot", "d_port_18h30"],
	# La Forêt : les pieux et la clôture de la clairière vide.
	[19.3, "zone", &"foret"], [21.0, "calm", 900.0], [21.05, "clock", 7.0], [21.1, "weather", &"clear"],
	[21.2, "tp", Vector2(24.0, 22.0)], [22.8, "shot", "e_foret_07h"],
	[22.9, "clock", 12.5], [22.95, "weather", &"clear"], [24.2, "shot", "e_foret_12h30"],
	[24.3, "clock", 18.5], [24.35, "weather", &"clear"], [25.6, "shot", "e_foret_18h30"],
	# Les images/s, sans vsync, à midi, à qualité Haute : forêt, port, Prairie.
	[25.7, "vsync", false], [25.75, "clock", 12.5], [25.8, "weather", &"clear"], [25.9, "tp", Vector2(62.5, 57.5)],
	[28.0, "perf", "foret_1"], [29.0, "perf", "foret_2"], [30.0, "perf", "foret_3"],
	[30.1, "zone", &"port_ambre"], [31.7, "calm", 900.0], [31.75, "clock", 12.5], [31.8, "weather", &"clear"],
	[31.9, "tp", Vector2(20.0, 15.0)],
	[34.0, "perf", "port_1"], [35.0, "perf", "port_2"], [36.0, "perf", "port_3"],
	[36.1, "zone", &"plaines"], [37.7, "calm", 900.0], [37.75, "clock", 12.5], [37.8, "weather", &"clear"],
	[37.9, "tp", Vector2(47.0, 70.0)],
	[40.0, "perf", "prairie_1"], [41.0, "perf", "prairie_2"], [42.0, "perf", "prairie_3"],
]
