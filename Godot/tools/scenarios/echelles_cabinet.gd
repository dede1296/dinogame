extends RefCounted
## The new sizes: in the Cabinet, the three hatchlings on their pedestals (as big as the dino
## Chloé takes, level 5), Roc at his desk, the furniture (×0.70). See tools/capture.gd.

const STEPS := [
	[0.8, "calm", 900.0], [0.82, "camera_distance", 12.0], [0.9, "clock", 11.0],
	[1.0, "zone", &"cabinet"],
	[2.4, "dino_npc", ["velociraptor", Vector2(12.3, 5.8), 1.0, 5, true, 25.0]],
	[2.42, "dino_npc", ["ankylosaurus", Vector2(13.8, 6.5), 1.0, 5, true, 25.0]],
	[2.44, "dino_npc", ["parasaurolophus", Vector2(15.2, 5.8), 1.0, 5, true, 25.0]],
	[2.5, "tp", Vector2(12.4, 7.8)], [2.6, "hold", "move_up"], [2.65, "hold", ""], [4.0, "shot", "q0_bebes_socles"],
	[4.1, "tp", Vector2(7.6, 5.6)], [5.6, "shot", "q1_roc_bureau"],
]
