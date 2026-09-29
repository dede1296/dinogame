extends RefCounted
## The new sizes (28/09/2026), for the board generated_imgs/captures/echelles_en_jeu.png: people
## in front of the houses (Port-Ambre, Havre-Doré), the camp, a companion of each size, Chloé in
## the saddle, big wild dinos, the quay's objects, a battle small against big. See tools/capture.gd.

const STEPS := [
	[0.8, "calm", 900.0], [0.82, "camera_distance", 12.0], [0.85, "weather", &"clear"], [0.9, "clock", 11.0],
	[0.92, "flags", ["havre_arrive", "camp_arrive", "foret_arrivee", "selle"]], [0.94, "level", 14],
	[0.96, "give_named", ["compsognathus", "Mini", 20]], [0.98, "give_named", ["parasaurolophus", "Écho", 14]],
	[1.0, "give_named", ["spinosaurus", "Spino", 22]], [1.02, "give_named", ["triceratops", "Cornu", 5]],
	# Port-Ambre: Chloé between Maïa and Roc; the quay's objects.
	[1.1, "zone", &"port_ambre"],
	[2.6, "tp", Vector2(22.5, 10.5)], [2.7, "npc", ["maia", Vector2(21.3, 10.3), "right"]],
	[2.75, "npc", ["roc", Vector2(23.8, 10.3), "left"]], [2.8, "hold", "move_down"], [2.85, "hold", ""],
	[4.4, "shot", "e00_port_gens"],
	[4.5, "tp", Vector2(30.2, 14.6)], [6.0, "shot", "e01_port_objets"],
	# Havre-Doré: the market; Ferréol at his door.
	[6.1, "zone", &"havre_dore"], [7.6, "tp", Vector2(25.5, 12.6)], [7.7, "hold", "move_down"], [7.75, "hold", ""],
	[9.2, "shot", "e02_havre_marche"], [9.3, "tp", Vector2(31.6, 10.8)], [10.8, "shot", "e03_havre_ferreol"],
	# The camp: Brac and his henchmen.
	[10.9, "zone", &"camp_ombre"], [12.4, "camera_distance", 14.0], [12.5, "tp", Vector2(21.0, 14.6)],
	[12.6, "hold", "move_up"], [12.65, "hold", ""], [14.2, "shot", "e04_camp_brac_sbires"], [14.3, "camera_distance", 12.0],
	# A companion of each size (Plaines).
	[14.4, "zone", &"plaines"],
	[15.9, "lead", 1], [16.0, "tp", Vector2(56.0, 62.0)], [16.1, "hold", "move_right"], [17.3, "hold", ""], [18.4, "shot", "e05_compagnon_mini"],
	[18.5, "lead", 1], [18.6, "tp", Vector2(56.0, 62.0)], [18.7, "hold", "move_right"], [19.9, "hold", ""], [21.0, "shot", "e06_compagnon_vif"],
	[21.1, "lead", 2], [21.2, "tp", Vector2(56.0, 62.0)], [21.3, "hold", "move_right"], [22.5, "hold", ""], [23.6, "shot", "e07_compagnon_echo"],
	[23.7, "lead", 3], [23.8, "tp", Vector2(56.0, 62.0)], [23.9, "hold", "move_right"], [25.1, "hold", ""], [26.2, "shot", "e08_compagnon_spino"],
	[26.3, "lead", 4], [26.4, "tp", Vector2(56.0, 62.0)], [26.5, "hold", "move_right"], [27.7, "hold", ""], [28.8, "shot", "e09_compagnon_cornu_niv5"],
	[28.9, "party", null],
	# Chloé in the saddle on Écho (a Parasaurolophus of 3 m, shown 1.95 m while she rides).
	[29.0, "tp", Vector2(56.0, 62.0)], [30.0, "call", ["toggle_ride", []]], [30.15, "shot", "e10_monte_transition"],
	[30.8, "hold", "move_right"], [31.5, "shot", "e11_en_selle"], [31.6, "hold", ""], [31.7, "riding", null],
	[32.2, "call", ["toggle_ride", []]],
	# Big wild dinos of the Forêt around Chloé.
	[32.4, "zone", &"foret"], [33.9, "tp", Vector2(118.0, 52.5)],
	[34.0, "wild", ["allosaurus", 16, Vector2(-3.4, -0.6)]], [34.05, "wild", ["therizinosaurus", 18, Vector2(3.6, -0.4)]],
	[34.1, "wild", ["velociraptor", 16, Vector2(1.4, 1.0)]], [34.15, "calm", 900.0], [35.8, "shot", "e12_foret_grands"],
	# A battle, small against big: Mini the Compsognathus against a Spinosaurus.
	[35.9, "lead", 4], [36.0, "battle", [&"spinosaurus", 22]], [38.0, "press", "interact"], [38.6, "press", "interact"],
	[39.6, "shot", "e13_combat_petit_grand"],
]
