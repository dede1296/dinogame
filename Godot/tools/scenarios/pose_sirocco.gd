extends RefCounted
## Sitting poses (29/09): Tante Sirocco cross-legged when Chloé meets her, then she stands up.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/pose_sirocco.gd

const STEPS := [
	[0.8, "flags", ["sceau_plaines","maia_defi_1","found_journal_6","havre_arrive","selle","barque_vue","foret_arrivee","griffe_grise_vu","clairiere_vue","found_journal_ancien","mur_camp_brise","camp_arrive","sbire_camp_1_vu","sbire_camp_2_vu","sbire_camp_1_battu","sbire_camp_2_battu","brac_parle","brac_battu","cage_ouverte","sceau_foret","found_journal_11","papiers_brac_lus","masque_vu","maia_defi_2","ambre_noir_tiroir","marais_arrivee","joss_marais_vu","gilet_nage","porte_voix_ouverte","voix_rencontree","temple_ouvert","dame_suie_battue","temple_vanne_1","temple_vanne_2","temple_vanne_3","spinosaure_battu","sceau_marais","coeur_1","found_journal_12","found_journal_13","found_journal_14","found_journal_15","found_journal_16","roc_marais_vu","maia_defi_3","desert_arrivee"]],
	[1.0, "calm", 900.0], [1.2, "clock", 10.0], [1.3, "weather", &"clear"], [1.3, "dlog", true], [1.4, "zone", &"desert"],
	[3.5, "weather", &"clear"], [3.8, "tp", Vector2(85.60, 68.80)], [4.1, "hold", "move_up"], [4.3, "hold", ""], [4.6, "shot", "si_avant"], [4.7, "press", "interact"], [4.8, "auto", true],
	[6.0, "shot", "si_00"],
	[7.5, "shot", "si_01"],
	[9.0, "shot", "si_02"],
	[10.5, "shot", "si_03"],
	[12.0, "shot", "si_04"],
	[13.5, "shot", "si_05"],
	[15.0, "shot", "si_06"],
	[16.5, "shot", "si_07"],
	[18.0, "shot", "si_08"],
	[19.5, "shot", "si_09"],
	[21.0, "shot", "si_10"],
	[22.5, "shot", "si_11"],
	[24.0, "shot", "si_12"],
	[25.5, "shot", "si_13"],
	[27.0, "shot", "si_14"],
	[28.5, "shot", "si_15"],
	[30.0, "shot", "si_16"],
	[31.5, "shot", "si_17"],
	[33.0, "auto", false], [33.2, "state", null],
]
