extends RefCounted
## Clins d'œil JP (agent B, 29/09): the old expedition car in its tree (Forêt, behind the broken fence),
## then Roc about it at the Cabinet (« Notre vieille voiture ! »). story/clins_doeil.gd.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/jp_voiture.gd [rush=1]

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "havre_arrive", "barque_vue", "foret_arrivee", "roc_parti_vu", "roc_nuit_niee",
		"cabinet_vide_vu", "found_journal_6", "met_roc", "lunettes_trouvees", "lunettes_rendues", "roc_myope", "larmes_expliquees",
		"sceau_foret", "oeuf_vole_apaise", "roc_oeuf_retrouve", "roc_sceau_foret", "tiroir_flaire", "ambre_noir_tiroir", "found_journal_8",
		"raptor_porte_vu", "canne_vue", "roc_moustique", "griffe_grise_vu", "clairiere_vue"]],
	[0.82, "clock", 10.0], [0.83, "weather", &"clear"], [0.84, "dlog", true], [0.85, "demo", true], [0.86, "no_help", null],
	[0.87, "auto", true], [0.88, "level", 30],
	[1.00, "zone", &"foret"], [1.10, "wait_idle", [2.0, 90]], [3.40, "calm", 900.0], [3.45, "weather", &"clear"], [3.50, "tp", Vector2(107.6, 67.7)], [3.60, "face", Vector2(0, -1)],
	[3.80, "shot", "v00_avant"], [4.00, "interact_now", null],
	[4.6, "shot", "v01"], [5.6, "shot", "v02"], [6.6, "shot", "v03"], [7.6, "shot", "v04"], [8.6, "shot", "v05"], [9.6, "shot", "v06"],
	[10.0, "wait_idle", [0.5, 200]],
	[10.2, "zone", &"cabinet"], [10.30, "wait_idle", [2.0, 90]], [12.6, "tp", Vector2(6.5, 5.6)], [12.7, "face", Vector2(0, -1)], [13.0, "interact_now", null],
	[13.6, "shot", "v10_roc"], [14.6, "shot", "v11_roc"], [15.6, "shot", "v12_roc"], [16.6, "shot", "v13_roc"],
	[17.0, "wait_idle", [0.5, 200]], [17.1, "state", null],
]
