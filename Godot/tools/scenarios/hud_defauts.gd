extends RefCounted
## The battle HUD's small fixes (30/09): an item for a dino beside Chloé (who gets it), the
## party's list after a knock-out (no Retour), a long name that fits, the E key, « Se débattre »
## when no power points are left. See tools/capture.gd.

const STEPS := [
	[0.9, "give", "compsognathus"], [0.95, "give", "parasaurolophus"], [1.0, "tp", Vector2(60.0, 62.0)],
	[1.05, "hurt", [1, 6]], [1.1, "item", ["fougere", 1]],
	[1.2, "battle", [&"protoceratops", 3]],
	[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"],
	[6.2, "key", "E"], [6.7, "shot", "d1_touche_e_attaques"],
	[6.8, "hud", "bag"], [7.2, "hud_press", "item:baie"], [7.7, "shot", "d2_soin_qui"],
	[7.8, "hud_press", "dino:1"], [8.6, "shot", "d3_soin_banc"],
	[12.0, "press", "interact"], [13.0, "press", "interact"], [14.0, "press", "interact"],
	[15.0, "hurt", [0, 0]], [15.1, "battle_set", ["must_switch", true]], [15.2, "hud", "relief"], [15.7, "shot", "d4_relais"],
	[15.8, "press", "cancel"], [16.2, "shot", "d5_relais_sans_retour"],
	[16.3, "hud_press", "dino:2"], [17.5, "shot", "d6_relais_entre"],
	[19.0, "press", "interact"], [20.0, "press", "interact"],
	[21.0, "pp", [2, 0]], [21.1, "hud", "moves"], [21.6, "shot", "d7_se_debattre"],
]
