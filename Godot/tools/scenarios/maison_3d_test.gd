extends RefCounted
## Check of Le Clos Blanc and its 3D cottage: the arrival, the door up close and a line when
## looking at it, the east gable seen from the side, Chloé behind the house (see-through).
## (Chloé is set down where to look: a screenshot stalls the game, a timed walk falls short.)

const STEPS := [
	[0.85, "clock", 10.0], [0.9, "weather", &"clear"], [1.0, "zone", &"clos_blanc"],
	[3.0, "shot", "m0_arrivee"],
	[3.2, "tp", Vector2(17.0, 11.2)], [3.3, "hold", "move_up"], [3.45, "hold", ""], [4.4, "state", null],
	[4.5, "shot", "m1_devant_maison"], [4.6, "interact_now", null], [6.8, "shot", "m2_examen"],
	[6.9, "talk", true], [8.4, "talk", false],
	[8.5, "tp", Vector2(24.5, 8.4)], [10.0, "shot", "m3_cote"],
	[10.1, "tp", Vector2(17.0, 3.6)], [11.6, "shot", "m4_derriere"],
]
