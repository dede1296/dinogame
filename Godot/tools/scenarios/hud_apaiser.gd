extends RefCounted
## A whole battle against a corrupted dino, calmed with Apaiser (auto). See tools/capture.gd.

const STEPS := [
	[1.0, "tp", Vector2(60.0, 62.0)], [1.2, "battle_corrupt", ["velociraptor", 3]], [1.3, "auto", true],
	[9.0, "shot", "ha_09"], [12.0, "shot", "ha_12"],
	[45.0, "auto", false], [45.2, "shot", "ha_fin"], [45.3, "party", null],
]
