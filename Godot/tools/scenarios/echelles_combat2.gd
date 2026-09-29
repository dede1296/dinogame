extends RefCounted
## The new sizes in battle: a big one (Écho grown) against a small one (a young Velociraptor),
## then against a grown Therizinosaurus. See tools/capture.gd.

const STEPS := [
	[0.8, "calm", 900.0], [0.82, "camera_distance", 12.0], [0.9, "give_named", ["parasaurolophus", "Écho", 16]], [0.95, "lead", 1],
	[1.0, "battle", [&"velociraptor", 4]], [3.0, "press", "interact"], [3.6, "press", "interact"], [4.6, "shot", "b1_combat_echo_raptor_jeune"],
]
