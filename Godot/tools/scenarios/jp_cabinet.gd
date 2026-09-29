extends RefCounted
## Clins d'œil JP (agent B, 29/09), after the Sceau de la Forêt: Roc's walking stick (Roc there), the
## mosquito in amber shown to Roc, then out of the Cabinet the raptor that opens its door (the lead,
## Vif, slips in behind Roc's back). story/clins_doeil.gd. Fast: rush=1.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/jp_cabinet.gd rush=1

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "havre_arrive", "barque_vue", "foret_arrivee", "roc_parti_vu", "roc_nuit_niee",
		"cabinet_vide_vu", "found_journal_6", "met_roc", "lunettes_trouvees", "lunettes_rendues", "roc_myope", "larmes_expliquees",
		"sceau_foret", "oeuf_vole_apaise", "roc_oeuf_retrouve", "roc_sceau_foret", "tiroir_flaire", "ambre_noir_tiroir", "found_journal_8"]],
	[0.82, "calm", 900.0], [0.84, "clock", 10.0], [0.85, "weather", &"clear"],
	[0.86, "dlog", true], [0.88, "demo", true], [0.89, "no_help", null], [0.90, "auto", true],
	[1.00, "zone", &"cabinet"],
	[3.40, "tp", Vector2(10.3, 4.35)], [3.50, "face", Vector2(-0.3, -1)],
	[3.80, "interact_now", null], [4.3, "shot", "c01_canne"], [4.9, "shot", "c02_canne"], [5.5, "shot", "c03_canne"],
	[5.60, "wait_idle", [0.5, 40]],
	[5.70, "item", ["ambre_moustique", 1]],
	[5.80, "tp", Vector2(6.5, 5.6)], [5.90, "face", Vector2(0, -1)], [6.20, "interact_now", null],
	[6.7, "shot", "c04_moustique"], [7.3, "shot", "c05_moustique"], [7.9, "shot", "c06_moustique"], [8.5, "shot", "c07_moustique"],
	[8.60, "wait_idle", [0.5, 40]],
	[8.70, "tp", Vector2(8.0, 9.6)], [8.80, "hold", "move_down"], [10.0, "hold", ""],
	[11.0, "shot", "c10_porte"], [11.6, "shot", "c11_porte"], [12.2, "shot", "c12_porte"], [12.8, "shot", "c13_porte"],
	[13.4, "shot", "c14_porte"], [14.0, "shot", "c15_porte"], [14.6, "shot", "c16_porte"], [15.2, "shot", "c17_porte"],
	[15.8, "shot", "c18_porte"], [16.4, "shot", "c19_porte"], [17.0, "shot", "c20_porte"], [17.6, "shot", "c21_porte"],
	[18.2, "shot", "c22_porte"], [18.8, "shot", "c23_porte"],
	[19.00, "wait_idle", [0.5, 60]],
	[19.10, "shot", "c30_apres"],
	[19.20, "state", null], [19.3, "check", null],
]
