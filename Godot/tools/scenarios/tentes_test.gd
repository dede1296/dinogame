extends RefCounted
## The tents and the palisade in real 3D (tools/modeles3d/maisons.py + tentes.py, pieux.py): the
## four tents of the Ombre Noire's camp (two mirrored) in front of the palisade of the north,
## the west palisade, and Tante Sirocco's tent in the Désert; from the front and aside (the
## camera's edges: the hidden side), as pictures then as models, at noon then in the evening. No
## scene plays (camp_arrive, desert_arrivee); Brac, his henchmen and Sirocco stand where they stand.
##   godot --path Godot --script res://tools/capture.gd -- out=<folder> scenario_file=res://tools/scenarios/tentes_test.gd

const STEPS := [
	[0.75, "flags", ["prologue_done", "foret_arrivee", "camp_arrive", "desert_arrivee", "marais_arrivee", "havre_arrive"]],
	[0.78, "talk", true], [0.8, "calm", 900.0], [0.85, "clock", 12.5], [0.9, "weather", &"clear"], [0.95, "quality", 2],
	[1.0, "zone", &"camp_ombre"], [2.4, "weather", &"clear"], [2.45, "calm", 900.0], [2.5, "camera_distance", 18.0],
	# The camp at noon: pictures, then models.
	[2.6, "reliefs", false], [2.7, "tp", Vector2(11.0, 10.6)], [4.2, "shot", "a01_camp_fond_images"],
	[4.3, "reliefs", true], [5.8, "shot", "a02_camp_fond_modeles"], [5.9, "camera_distance", 16.0],
	[6.0, "tp", Vector2(6.1, 10.4)], [7.4, "shot", "a03_tente1_face"],
	[7.5, "tp", Vector2(9.8, 10.2)], [8.9, "shot", "a04_tentes12_34"],
	[9.0, "tp", Vector2(13.6, 10.4)], [10.4, "shot", "a05_tente2_face"],
	[10.5, "tp", Vector2(18.0, 11.6)], [11.9, "shot", "a06_tente3_brac"],
	[12.0, "tp", Vector2(23.5, 10.2)], [13.4, "shot", "a07_tente3_34_droite"],
	[13.5, "reliefs", false], [15.0, "shot", "a08_tente3_34_droite_images"], [15.1, "reliefs", true],
	[15.2, "tp", Vector2(5.4, 20.4)], [16.6, "shot", "a09_tente4_face"],
	[16.7, "tp", Vector2(8.8, 19.8)], [18.1, "shot", "a10_tente4_34"],
	[18.2, "tp", Vector2(10.2, 5.4)], [19.6, "shot", "a11_palissade_fond_entre_tentes"],
	[19.7, "tp", Vector2(24.2, 7.6)], [21.1, "shot", "a12_palissade_fond_face"],
	[21.2, "tp", Vector2(8.2, 14.2)], [22.6, "shot", "a13_palissade_ouest_cage"],
	[22.7, "reliefs", false], [24.2, "shot", "a14_palissade_ouest_images"], [24.3, "reliefs", true],
	[24.4, "camera_distance", 24.0], [24.5, "tp", Vector2(13.0, 12.0)], [26.1, "shot", "a15_camp_vue_generale"],
	[26.2, "camera_distance", 16.0],
	# The camp in the evening.
	[26.3, "clock", 19.2], [26.4, "weather", &"clear"], [26.5, "tp", Vector2(9.8, 10.2)], [28.3, "shot", "b01_soir_tentes12"],
	[28.4, "tp", Vector2(18.0, 11.6)], [29.8, "shot", "b02_soir_tente3"],
	[29.9, "tp", Vector2(8.8, 19.8)], [31.3, "shot", "b03_soir_tente4"],
	[31.4, "tp", Vector2(10.2, 5.4)], [32.8, "shot", "b04_soir_palissade"],
	# Tante Sirocco's tent (Désert).
	[32.9, "clock", 12.5], [33.0, "zone", &"desert"], [34.4, "weather", &"clear"], [34.45, "calm", 900.0],
	[34.5, "reliefs", false], [34.6, "tp", Vector2(86.4, 70.0)], [36.1, "shot", "c01_nomade_face_images"],
	[36.2, "reliefs", true], [37.7, "shot", "c02_nomade_face"],
	[37.8, "tp", Vector2(90.6, 68.8)], [39.2, "shot", "c03_nomade_34_droite"],
	[39.3, "tp", Vector2(82.4, 68.8)], [40.7, "shot", "c04_nomade_34_gauche"],
	[40.8, "clock", 19.2], [40.9, "weather", &"clear"], [41.0, "tp", Vector2(86.4, 70.0)], [42.8, "shot", "c05_soir_nomade"],
	# The real openings of the buildings: the hut's open doorway and window (Marais); the doors
	# of the contract, closed, unchanged (Havre-Doré, Port-Ambre's Cabinet); the Mercerie's stall.
	[42.9, "clock", 12.5], [43.0, "zone", &"marais"], [44.4, "weather", &"clear"], [44.45, "calm", 900.0],
	[44.5, "tp_prop", ["cabane_pilotis", Vector2(80, 130)]], [46.0, "shot", "d01_cabane_ouvertures"],
	[46.1, "tp_prop", ["cabane_pilotis", Vector2(-170, 110)]], [47.6, "shot", "d02_cabane_34"],
	[47.7, "flags", ["sceau_plaines", "met_maia", "found_journal_1"]], [47.8, "zone", &"havre_dore"], [49.2, "weather", &"clear"],
	[49.25, "calm", 900.0], [49.3, "tp", Vector2(10.0, 11.0)], [50.8, "shot", "e01_herbo_mercerie"],
	[50.9, "tp", Vector2(15.5, 11.0)], [52.3, "shot", "e02_mercerie_etal"],
	[52.4, "tp", Vector2(27.8, 11.4)], [53.8, "shot", "e03_relais_comptoir"],
	[53.9, "tp", Vector2(44.0, 11.0)], [55.3, "shot", "e04_sellerie"],
	[55.4, "tp", Vector2(48.5, 20.0)], [56.8, "shot", "e05_entrepot"],
	[56.9, "zone", &"port_ambre"], [58.3, "weather", &"clear"], [58.35, "calm", 900.0],
	[58.4, "tp_prop", ["cabinet", Vector2(-170, 120)]], [59.9, "shot", "e06_cabinet"],
	[60.0, "state", null],
]
