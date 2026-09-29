extends RefCounted
## A whole battle played by the HUD's buttons: a berry (given to Vif), then Compsognathus sent
## in, then the fight goes on by itself (auto) to the end. See tools/capture.gd (« hud_tap »).

const STEPS := [
	[0.9, "give", "compsognathus"], [1.0, "tp", Vector2(60.0, 62.0)], [1.05, "hurt", [0, 8]],
	[1.1, "hud_tap", ["sac", "item:baie", "dino:0", "dinos", "dino:1"]],
	[1.3, "battle", [&"protoceratops", 4]], [1.4, "auto", true],
	[6.0, "shot", "hc_06"], [6.4, "shot", "hc_06b"], [6.8, "shot", "hc_07"], [7.2, "shot", "hc_07b"],
	[7.6, "shot", "hc_08"], [8.0, "shot", "hc_08b"], [9.0, "shot", "hc_09"], [10.0, "shot", "hc_10"],
	[11.0, "shot", "hc_11"], [11.4, "shot", "hc_11b"], [11.8, "shot", "hc_12"], [12.2, "shot", "hc_12b"],
	[12.6, "shot", "hc_13"], [13.0, "shot", "hc_13b"], [14.0, "shot", "hc_14"], [15.0, "shot", "hc_15"],
	[40.0, "auto", false], [40.2, "shot", "hc_apres_combat"], [40.3, "party", null],
]
