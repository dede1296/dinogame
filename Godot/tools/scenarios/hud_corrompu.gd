extends RefCounted
## The battle HUD against a corrupted dino: Apaiser instead of Collier. See tools/capture.gd.

const STEPS := [
	[1.0, "tp", Vector2(60.0, 62.0)], [1.2, "battle_corrupt", ["velociraptor", 4]],
	[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"], [6.2, "shot", "h6_corrompu"],
	[6.3, "hud", "moves"], [6.8, "shot", "h7_corrompu_attaques"],
]
