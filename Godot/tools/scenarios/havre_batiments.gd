extends RefCounted
## Havre-Doré's own buildings (tools/modeles3d/maisons.py): the upper street and the quay row,
## from the front and aside, at noon then in the evening; the shops' facades still open the
## shops (Herboristerie, Comptoir), talking to the facade and not to the shopkeeper.

const STEPS := [
	[0.75, "flags", ["prologue_done", "havre_arrive", "sceau_plaines", "met_maia", "found_journal_1"]], [0.78, "talk", true],
	[0.8, "calm", 900.0], [0.85, "clock", 12.5], [0.9, "weather", &"clear"], [0.95, "quality", 2], [0.96, "dlog", true],
	[1.0, "zone", &"havre_dore"], [2.4, "weather", &"clear"], [2.45, "calm", 900.0], [2.5, "camera_distance", 17.0],
	# Upper street, noon.
	[2.6, "tp", Vector2(6.0, 11.0)], [4.0, "shot", "a01_herboristerie"],
	[4.1, "tp", Vector2(10.0, 11.0)], [5.5, "shot", "a02_herbo_mercerie_34"],
	[5.6, "tp", Vector2(13.5, 11.0)], [7.0, "shot", "a03_mercerie"],
	[7.1, "tp", Vector2(22.5, 11.4)], [8.5, "shot", "a04_relais"],
	[8.6, "tp", Vector2(27.8, 11.4)], [10.0, "shot", "a05_relais_comptoir_34"],
	[10.1, "tp", Vector2(33.0, 11.4)], [11.5, "shot", "a06_comptoir"],
	[11.6, "tp", Vector2(42.0, 11.0)], [13.0, "shot", "a07_sellerie"],
	[13.1, "tp", Vector2(46.0, 11.0)], [14.5, "shot", "a08_sellerie_maison1_34"],
	[14.6, "tp", Vector2(49.5, 11.0)], [16.0, "shot", "a09_maison1"],
	# Quay row, noon.
	[16.1, "tp", Vector2(6.0, 20.0)], [17.5, "shot", "a10_maison2"],
	[17.6, "tp", Vector2(10.0, 20.0)], [19.0, "shot", "a11_maison2_maison3_34"],
	[19.1, "tp", Vector2(13.5, 20.0)], [20.5, "shot", "a12_maison3"],
	[20.6, "tp", Vector2(40.0, 20.0)], [22.0, "shot", "a13_maison4"],
	[22.1, "tp", Vector2(44.0, 20.0)], [23.5, "shot", "a14_maison4_entrepot_34"],
	[23.6, "tp", Vector2(48.5, 20.0)], [25.0, "shot", "a15_entrepot"],
	# The lanes between the two streets.
	[25.1, "tp", Vector2(5.0, 12.0)], [26.5, "shot", "a16_ruelle_ouest"],
	[26.6, "tp", Vector2(51.0, 12.0)], [28.0, "shot", "a17_ruelle_est"],
	# Evening.
	[28.1, "clock", 19.2], [28.2, "tp", Vector2(9.0, 11.0)], [30.0, "shot", "b01_soir_ouest"],
	[30.1, "tp", Vector2(27.8, 11.4)], [31.5, "shot", "b02_soir_relais_comptoir"],
	[31.6, "tp", Vector2(45.0, 11.0)], [33.0, "shot", "b03_soir_sellerie"],
	[33.1, "tp", Vector2(10.0, 20.0)], [34.5, "shot", "b04_soir_quai_ouest"],
	[34.6, "tp", Vector2(44.0, 20.0)], [36.0, "shot", "b05_soir_quai_est"],
	# The shops' facades (not their keepers): the Herboristerie (its menu: « Voir la boutique »),
	# then the Comptoir (Ferréol's welcome, then his shop).
	[36.1, "clock", 12.5], [36.3, "tp", Vector2(7.6, 9.0)], [36.5, "hold", "move_up"], [36.6, "hold", ""],
	[37.2, "near", null], [37.25, "pick", 0], [37.3, "interact_now", null], [39.5, "shot", "c01_herboristerie_boutique"],
	[39.6, "state", null], [39.7, "press", "cancel"], [40.3, "press", "cancel"], [40.9, "press", "cancel"],
	[41.5, "tp", Vector2(34.5, 9.0)], [41.7, "hold", "move_up"], [41.8, "hold", ""],
	[42.4, "near", null], [42.5, "interact_now", null], [47.0, "shot", "c02_comptoir_boutique"], [47.1, "state", null],
	[47.2, "press", "cancel"], [47.8, "press", "cancel"],
	# Port-Ambre's retouched houses (jardinière, maison_port's roof, the Cabinet's valley).
	[48.0, "zone", &"port_ambre"], [49.4, "weather", &"clear"], [49.45, "calm", 900.0],
	[49.5, "tp_prop", ["maison_jaune", Vector2(0, 110)]], [51.0, "shot", "d01_port_maison_jaune"],
	[51.1, "tp_prop", ["maison_port", Vector2(-170, 110)]], [52.6, "shot", "d02_port_maison_port_34"],
	[52.7, "tp_prop", ["cabinet", Vector2(170, 120)]], [54.2, "shot", "d03_port_cabinet_34d"],
	[54.3, "tp_prop", ["cabinet", Vector2(-170, 120)]], [55.8, "shot", "d04_port_cabinet_34g"],
]
