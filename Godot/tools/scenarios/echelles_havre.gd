extends RefCounted
## The new sizes: Havre-Doré, the market (Maïa, Lilou, Gaspard, the merchant), the Relais' low
## double door, Ferréol at the Comptoir's door. See tools/capture.gd.

const STEPS := [
	[0.8, "calm", 900.0], [0.82, "camera_distance", 12.0], [0.85, "weather", &"clear"], [0.9, "clock", 11.0],
	[1.0, "zone", &"havre_dore"],
	[2.5, "tp", Vector2(25.5, 12.6)], [2.6, "hold", "move_down"], [2.65, "hold", ""], [4.2, "shot", "h0_marche"],
	[4.3, "tp", Vector2(21.4, 10.2)], [5.8, "shot", "h1_relais_porte"],
	[5.9, "tp", Vector2(31.6, 10.8)], [7.4, "shot", "h2_ferreol_comptoir"],
]
