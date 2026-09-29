extends RefCounted
## The new sizes (28/09/2026): Port-Ambre, Chloé between Maïa and Roc in front of the houses;
## the quay's objects; a « ! » over Isaure's head. See tools/capture.gd.

const STEPS := [
	[0.8, "calm", 900.0], [0.82, "camera_distance", 12.0], [0.85, "weather", &"clear"], [0.9, "clock", 11.0],
	[1.0, "zone", &"port_ambre"],
	[2.4, "tp", Vector2(22.5, 10.5)], [2.5, "npc", ["maia", Vector2(21.4, 10.3), "right"]],
	[2.55, "npc", ["roc", Vector2(23.7, 10.3), "left"]], [2.6, "hold", "move_down"], [2.65, "hold", ""],
	[4.2, "shot", "p0_port_gens"],
	[4.3, "camera_distance", 16.0], [5.6, "shot", "p1_port_gens_loin"], [5.7, "camera_distance", 12.0],
	[5.8, "tp", Vector2(30.2, 14.6)], [7.3, "shot", "p2_port_objets"],
	[7.4, "tp", Vector2(12.0, 12.8)], [8.9, "shot", "p3_port_banc_sechoir"],
	[9.0, "tp", Vector2(22.6, 16.6)], [9.1, "hold", "move_up"], [9.2, "hold", ""], [9.6, "interact_now", null],
	[10.0, "shot", "p4_isaure_emote"],
]
