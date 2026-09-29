extends RefCounted
## The battle HUD under the sea (rules "underwater"; a battle of honour: no collar, no running
## away). See tools/capture.gd.

const STEPS := [
	[0.9, "flags", ["combat_sous_marin_vu"]], [1.0, "tp", Vector2(60.0, 62.0)],
	[1.2, "battle_rules", ["ichthyosaurus", 4, {"underwater": true, "catch": false, "run": false}]],
	[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"], [6.2, "shot", "h8_sous_eau"],
	[6.3, "hud", "moves"], [6.8, "shot", "h9_sous_eau_attaques"],
]
