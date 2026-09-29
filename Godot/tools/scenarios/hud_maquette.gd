extends RefCounted
## The battle HUD (battle/battle_hud.gd): the wheel, then each of its lists. See tools/capture.gd.

const STEPS := [
	[0.9, "give", "compsognathus"], [0.95, "give", "parasaurolophus"], [1.0, "tp", Vector2(60.0, 62.0)],
	[1.05, "item", ["fougere", 1]], [1.1, "hurt", [0, 11]], [1.15, "hurt", [2, 0]],
	[1.2, "battle", [&"protoceratops", 3]], [2.2, "shot", "h0_intro"],
	[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"], [6.2, "shot", "h1_roue"],
	[6.3, "hud", "moves"], [6.8, "shot", "h2_attaques"],
	[6.9, "hud", "bag"], [7.4, "shot", "h3_sac"],
	[7.5, "hud", "team"], [8.0, "shot", "h4_dinos"],
	[8.1, "hud", "wheel"], [8.2, "press", "ui_up"], [8.5, "shot", "h5_focus_collier"],
	[8.6, "hurt", [-1, 2]], [8.7, "press", "ui_down"], [9.3, "shot", "h5b_collier_affaibli"],
]
