extends RefCounted
## The new sizes in battle: a small one (Mini the Compsognathus) against a big one (a wild
## Spinosaurus). See tools/capture.gd.

const STEPS := [
	[0.8, "calm", 900.0], [0.82, "camera_distance", 12.0], [0.9, "give_named", ["compsognathus", "Mini", 22]], [0.95, "lead", 1],
	[1.0, "battle", [&"spinosaurus", 22]], [3.0, "press", "interact"], [3.6, "press", "interact"], [4.6, "shot", "b0_combat_compso_spino"],
]
