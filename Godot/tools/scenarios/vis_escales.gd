extends RefCounted
## Visual check only (29/09): the eight stops of the Grand Voyageur (fast travel), the old
## adults at size 1.6. For each region: Chloé is put at the way in, a picture is taken there,
## then she walks to the Brachiosaure until she bumps into him — her position is printed
## before and after, so the walk is on record — and a picture of the stop: the dino, the sign
## and Chloé beside them. The arrival flags are set and every zone change waits for the scene
## to be over, so no welcome scene takes the walk over.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_escales.gd

const ARRIVED := [
	"prologue_done", "sceau_plaines", "selle", "havre_arrive", "foret_arrivee", "maia_defi_1",
	"maia_defi_2", "marais_arrivee", "maia_defi_3", "desert_arrivee", "maia_defi_4",
	"cote_ouverte", "cote_arrivee", "monts_ouverts", "monts_arrivee",
]

const STEPS := [
	[0.7, "flags", ARRIVED], [0.8, "calm", 900.0], [0.8, "talk", true], [0.9, "vsync", false],

	# Port-Ambre: down the road north, through the village, onto the quay east of the pier.
	[1.2, "call", ["goto_zone", [&"port_ambre", &"DepuisPlaines"]]],
	[1.3, "wait_idle", [2.0, 30.0]],
	[1.6, "calm", 900.0], [1.6, "weather", &"clear"], [1.65, "clock", 11.0], [1.7, "tp", Vector2(17.0, 1.5)],
	[2.6, "where", "port entree"], [2.8, "shot", "1_port_entree"],
	[3.0, "hold", "move_down"], [7.3, "hold", "move_right"], [10.1, "hold", "move_up"], [10.5, "hold", ""],
	[11.1, "where", "port escale"], [11.3, "shot", "1_port_escale"],

	# Prairie du Grand Crâne: up the road from the port to the crossroads, then west.
	[11.7, "call", ["goto_zone", [&"plaines", &"DepuisPort"]]],
	[11.8, "wait_idle", [2.0, 30.0]],
	[12.1, "calm", 900.0], [12.1, "weather", &"clear"], [12.15, "clock", 11.0], [12.2, "tp", Vector2(60.0, 88.2)],
	[13.1, "where", "plaines entree"], [13.3, "shot", "2_plaines_entree"],
	[13.5, "hold", "move_up"], [24.4, "hold", ""], [24.8, "where", "plaines carrefour"],
	[25.0, "hold", "move_left"], [27.0, "hold", "move_up"], [27.5, "hold", ""],
	[28.1, "where", "plaines escale"], [28.3, "shot", "2_plaines_escale"],

	# Havre-Doré: straight down the grass west of the houses, onto the quay.
	[28.9, "call", ["goto_zone", [&"havre_dore", &"DepuisPort"]]],
	[29.0, "wait_idle", [2.0, 30.0]],
	[29.3, "calm", 900.0], [29.3, "weather", &"clear"], [29.35, "clock", 11.0], [29.4, "tp", Vector2(1.8, 10.5)],
	[30.3, "where", "havre entree"], [30.5, "shot", "3_havre_entree"],
	[30.7, "hold", "move_down"], [34.2, "hold", "move_right"], [35.1, "hold", "move_up"], [35.6, "hold", ""],
	[36.2, "where", "havre escale"], [36.4, "shot", "3_havre_escale"],

	# Forêt Jurassique: west along the road from the Plaines, then down into the Lisière est.
	[37.0, "call", ["goto_zone", [&"foret", &"DepuisPlaines"]]],
	[37.1, "wait_idle", [2.0, 30.0]],
	[37.4, "calm", 900.0], [37.4, "weather", &"clear"], [37.45, "clock", 11.0], [37.5, "tp", Vector2(126.0, 52.0)],
	[38.4, "where", "foret entree"], [38.6, "shot", "4_foret_entree"],
	[38.8, "hold", "move_left"], [41.1, "hold", "move_down"], [42.95, "hold", "move_left"],
	[44.15, "hold", "move_up"], [44.95, "hold", ""],
	[45.6, "where", "foret escale"], [45.8, "shot", "4_foret_escale"],

	# Marais Brumeux: along the boardwalk to the firm ground of the landing island.
	[46.4, "call", ["goto_zone", [&"marais", &"DepuisForet"]]],
	[46.5, "wait_idle", [2.0, 30.0]],
	[46.8, "calm", 900.0], [46.8, "weather", &"clear"], [46.85, "clock", 11.0], [46.9, "tp", Vector2(116.5, 70.0)],
	[47.8, "where", "marais entree"], [48.0, "shot", "5_marais_entree"],
	[48.2, "hold", "move_left"], [52.5, "hold", "move_down"], [53.8, "hold", "move_left"],
	[54.6, "hold", "move_up"], [55.1, "hold", ""],
	[55.7, "where", "marais escale"], [55.9, "shot", "5_marais_escale"],

	# Désert Aride: up the canyon from the Marais to where it opens out.
	[56.5, "call", ["goto_zone", [&"desert", &"DepuisMarais"]]],
	[56.6, "wait_idle", [2.0, 30.0]],
	[56.9, "calm", 900.0], [56.9, "weather", &"clear"], [56.95, "clock", 11.0], [57.0, "tp", Vector2(102.0, 97.6)],
	[57.9, "where", "desert entree"], [58.1, "shot", "6_desert_entree"],
	[58.3, "hold", "move_up"], [62.6, "hold", ""],
	[63.2, "where", "desert escale"], [63.4, "shot", "6_desert_escale"],

	# Côte Préhistorique: up the beach track from the Désert, then west onto the sand.
	[64.0, "call", ["goto_zone", [&"cote", &"DepuisDesert"]]],
	[64.1, "wait_idle", [2.0, 30.0]],
	[64.4, "calm", 900.0], [64.4, "weather", &"clear"], [64.45, "clock", 11.0], [64.5, "tp", Vector2(19.5, 97.4)],
	[65.4, "where", "cote entree"], [65.6, "shot", "7_cote_entree"],
	[65.8, "hold", "move_up"], [67.0, "hold", "move_left"], [68.2, "hold", "move_up"], [68.9, "hold", ""],
	[69.5, "where", "cote escale"], [69.7, "shot", "7_cote_escale"],

	# Monts Gelés: the low slope just past the way in from the Côte.
	[70.3, "call", ["goto_zone", [&"monts", &"DepuisCote"]]],
	[70.4, "wait_idle", [2.0, 30.0]],
	[70.7, "calm", 900.0], [70.7, "weather", &"clear"], [70.75, "clock", 11.0], [70.8, "tp", Vector2(2.5, 30.0)],
	[71.7, "where", "monts entree"], [71.9, "shot", "8_monts_entree"],
	[72.1, "hold", "move_right"], [73.5, "hold", "move_up"], [73.95, "hold", "move_left"], [74.95, "hold", ""],
	[75.6, "where", "monts escale"], [75.8, "shot", "8_monts_escale"],
	[76.1, "state", null],
]
