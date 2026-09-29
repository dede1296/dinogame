extends RefCounted
## Clins d'œil JP (agent B, 29/09): Élise Sablier and the sick Triceratops only (story/visiteurs.gd,
## tools/zones/plaines.gd), the berry given. Fast (rush=1) or at the demo's pace.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/jp_elise.gd [rush=1]

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "havre_arrive", "barque_vue"]],
	[0.82, "clock", 10.0], [0.83, "weather", &"clear"], [0.84, "dlog", true], [0.85, "demo", true], [0.86, "no_help", null],
	[0.87, "auto", true], [0.88, "item", ["baie", 2]], [0.89, "level", 30],
	[0.95, "zone", &"plaines"], [1.05, "wait_idle", [2.0, 90]], [3.40, "calm", 900.0], [3.50, "tp", Vector2(77.9, 56.6)], [3.60, "face", Vector2(1, 0)],
	[4.00, "interact_now", null],
	[5.0, "shot", "e00"], [6.0, "shot", "e01"], [7.0, "shot", "e02"], [8.0, "shot", "e03"], [9.0, "shot", "e04"], [10.0, "shot", "e05"],
	[11.0, "shot", "e06"], [12.0, "shot", "e07"], [13.0, "shot", "e08"], [14.0, "shot", "e09"], [15.0, "shot", "e10"], [16.0, "shot", "e11"],
	[17.0, "shot", "e12"], [18.0, "shot", "e13"], [19.0, "shot", "e14"], [20.0, "shot", "e15"], [21.0, "shot", "e16"], [22.0, "shot", "e17"],
	[23.0, "wait_idle", [0.5, 90]], [23.1, "shot", "e99"], [23.2, "state", null], [23.3, "coins", null],
]
