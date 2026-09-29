extends RefCounted
## Clins d'œil JP (agent B, 29/09): one look at each new piece of scenery and each visitor where it stands
## in its zone (tools/zones/*.gd, docs/histoire.md « Clins d'œil »). Visual check only.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/jp_decors_b.gd

const STEPS := [
	[0.8, "flags", ["sceau_plaines", "maia_defi_1", "havre_arrive", "barque_vue", "foret_arrivee", "marais_arrivee", "desert_arrivee",
		"sirocco_vue", "grottes_arrivee", "cache_vue", "sanctuaire_givre_arrivee", "roc_parti_vu", "roc_nuit_niee", "cabinet_vide_vu",
		"found_journal_6", "compsos_cuisine", "hamon_vu", "malcombe_vu", "granit_vu", "elise_vue"]],
	[0.9, "calm", 900.0], [0.95, "clock", 11.0], [0.96, "weather", &"clear"],
	[1.0, "zone", &"cabinet"], [3.5, "tp", Vector2(8.6, 5.2)], [3.6, "face", Vector2(0, -1)], [5.0, "shot", "b01_cabinet"],
	[5.1, "tp", Vector2(6.2, 4.3)], [5.2, "face", Vector2(0, -1)], [6.5, "shot", "b02_cabinet_bureau"],
	[6.6, "zone", &"havre_dore"], [9.1, "calm", 900.0], [9.2, "tp", Vector2(31.2, 10.7)], [9.3, "face", Vector2(0, -1)], [10.6, "shot", "b04_havre_coffre"],
	[10.7, "tp", Vector2(9.75, 8.2)], [10.8, "face", Vector2(0, -1)], [12.2, "shot", "b05_havre_table"],
	[12.3, "tp", Vector2(31.0, 19.0)], [12.4, "face", Vector2(0, -1)], [13.8, "shot", "b06_havre_visiteurs"],
	[13.9, "zone", &"foret"], [16.4, "calm", 900.0], [16.5, "weather", &"clear"], [16.6, "tp", Vector2(112.2, 76.0)], [16.7, "face", Vector2(-1, -1)],
	[18.1, "shot", "b07_foret_cloture_voiture"],
	[18.2, "tp", Vector2(28.9, 61.0)], [18.3, "face", Vector2(0, -1)], [19.7, "shot", "b08_foret_ambre"],
	[19.8, "zone", &"desert"], [22.3, "calm", 900.0], [22.4, "tp", Vector2(70.2, 84.6)], [22.5, "face", Vector2(0, -1)], [23.9, "shot", "b09_desert_banderole"],
	[24.0, "tp", Vector2(86.8, 70.4)], [24.1, "face", Vector2(0, -1)], [25.5, "shot", "b10_desert_granit"],
	[25.6, "zone", &"grottes_marines"], [28.1, "tp", Vector2(9.0, 6.6)], [28.2, "face", Vector2(0, -1)], [29.6, "shot", "b11_grotte_creme"],
	[29.7, "zone", &"sanctuaire_givre"], [32.2, "tp", Vector2(16.0, 30.8)], [32.3, "face", Vector2(0, -1)], [33.7, "shot", "b12_sanctuaire_flaque"],
	[33.8, "zone", &"plaines"], [36.3, "calm", 900.0], [36.4, "weather", &"clear"], [36.5, "tp", Vector2(77.0, 59.5)], [36.6, "face", Vector2(1, -1)],
	[38.0, "shot", "b13_plaines_elise"],
	[38.1, "state", null],
]
