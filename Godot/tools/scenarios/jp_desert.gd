extends RefCounted
## Clins d'œil JP (agent B, 29/09), in the Désert: Tante Sirocco and a Dilophosaurus of the party
## (story/clins_doeil.gd sirocco_dilo: « pas de collerette »… and it opens one), then Brac cornered in the
## Canyon des Vents (« Petite futée… », story/desert_sanctuaire.gd). Fast: rush=1.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/jp_desert.gd rush=1

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "havre_arrive", "barque_vue", "foret_arrivee", "marais_arrivee", "desert_arrivee",
		"sirocco_vue", "brac_desert_vu", "poursuite_1_ok", "poursuite_2_ok", "poursuite_3_ok", "granit_vu"]],
	[0.82, "clock", 10.0], [0.83, "weather", &"clear"], [0.84, "dlog", true], [0.85, "demo", true], [0.86, "no_help", null],
	[0.87, "auto", true], [0.875, "fast_battles", true], [0.88, "level", 40],
	[0.89, "give_named", ["dilophosaurus", "Braise", 20]],
	[1.00, "zone", &"desert"], [1.10, "wait_idle", [2.0, 90]], [3.40, "calm", 900.0], [3.45, "weather", &"clear"],
	[3.50, "tp", Vector2(85.6, 68.5)], [3.60, "face", Vector2(0, -1)], [3.80, "interact_now", null],
	[4.3, "shot", "s00"], [5.3, "shot", "s01"], [6.3, "shot", "s02"], [7.3, "shot", "s03"], [8.3, "shot", "s04"], [9.3, "shot", "s05"],
	[10.0, "wait_idle", [0.5, 200]],
	[10.1, "tp", Vector2(15.5, 13.6)], [10.2, "face", Vector2(0, -1)], [10.3, "calm", 900.0], [10.5, "interact_now", null],
	[11.0, "shot", "b00"], [12.0, "shot", "b01"], [13.0, "shot", "b02"], [14.0, "shot", "b03"], [15.0, "shot", "b04"], [16.0, "shot", "b05"],
	[17.0, "wait_idle", [0.5, 300]], [17.1, "state", null],
]
