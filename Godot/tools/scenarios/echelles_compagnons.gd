extends RefCounted
## The new sizes: one companion of each size walking behind Chloé (Mini the Compsognathus,
## Vif, Écho grown, the Spinosaurus, a young Écho), then Chloé in the saddle (getting on,
## riding, getting down). See tools/capture.gd.

const STEPS := [
	[0.8, "calm", 900.0], [0.82, "camera_distance", 12.0], [0.85, "weather", &"clear"], [0.9, "clock", 11.0], [0.95, "level", 14],
	[1.0, "give_named", ["compsognathus", "Mini", 20]], [1.02, "give_named", ["parasaurolophus", "Écho", 14]],
	[1.04, "give_named", ["spinosaurus", "Spino", 22]], [1.06, "give_named", ["parasaurolophus", "Petit", 5]],
	[1.1, "lead", 1], [1.2, "tp", Vector2(56.0, 62.0)], [1.3, "hold", "move_right"], [2.5, "hold", ""], [3.6, "shot", "c0_mini"],
	[3.7, "lead", 1], [3.8, "tp", Vector2(56.0, 62.0)], [3.9, "hold", "move_right"], [5.1, "hold", ""], [6.2, "shot", "c1_vif"],
	[6.3, "lead", 4], [6.4, "tp", Vector2(56.0, 62.0)], [6.5, "hold", "move_right"], [7.7, "hold", ""], [8.8, "shot", "c2_petit_echo_niv5"],
	[8.9, "lead", 3], [9.0, "tp", Vector2(56.0, 62.0)], [9.1, "hold", "move_right"], [10.3, "hold", ""], [11.4, "shot", "c3_echo_adulte"],
	[11.5, "lead", 4], [11.6, "tp", Vector2(56.0, 62.0)], [11.7, "hold", "move_right"], [12.9, "hold", ""], [14.0, "shot", "c4_spino"],
	[14.1, "party", null],
	# In the saddle: Écho (a Parasaurolophus of 2.9 m) shrinks to 1.95 m as she climbs on.
	[14.2, "flags", ["selle"]], [14.3, "tp", Vector2(56.0, 62.0)], [15.3, "call", ["toggle_ride", []]],
	[15.45, "shot", "s0_monte_transition"], [16.2, "shot", "s1_en_selle"],
	[16.3, "hold", "move_right"], [17.0, "shot", "s2_en_selle_marche"], [17.1, "hold", "move_down"], [17.8, "shot", "s3_en_selle_face"],
	[17.9, "hold", "move_up"], [18.6, "shot", "s4_en_selle_dos"], [18.7, "hold", ""], [18.8, "riding", null],
	[19.5, "call", ["toggle_ride", []]], [19.65, "shot", "s5_descend_transition"], [20.6, "shot", "s6_descendue"],
]
