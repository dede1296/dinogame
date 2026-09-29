extends RefCounted
## The battle HUD against the Mosasaure Abyssal (rules "underwater", "abyss"): its moves' cards
## while it hides in the dark (« hors d'atteinte »). See tools/capture.gd.

const STEPS := [
	[0.9, "flags", ["combat_sous_marin_vu"]], [0.95, "level", 30], [1.0, "tp", Vector2(60.0, 62.0)],
	[1.2, "battle_rules", ["mosasaure_abyssal", 30, {"underwater": true, "catch": false, "run": false, "abyss": true, "size": 1.2}]],
	[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"], [6.2, "shot", "hb_abysse_roue"],
	[6.3, "battle_set", ["deep", 1]], [6.4, "hud", "moves"], [6.9, "shot", "hb_abysse_hors_atteinte"],
]
