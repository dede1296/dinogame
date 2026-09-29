extends RefCounted
## The little life of each kind of place (Wildlife), measured: the frame rate in the same spots
## of the Plaines, the Forêt, the Marais, the Désert and the Côte, by day and at night (vsync off).
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/faune_perf.gd

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14", "found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossile_1", "fossile_2", "fossile_3", "fossile_4", "fossile_5", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre", "coeur_2", "maia_oasis_vue", "maia_defi_4", "met_roc", "lunettes_trouvees", "lunettes_rendues", "larmes_expliquees", "roc_sceau_foret", "roc_sceau_marais", "roc_sceau_desert", "cote_annonce", "cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "filet_coupe", "nessie", "masque_plongee"]],
	[0.82, "clock", 11.0], [0.84, "weather", &"clear"], [0.86, "vsync", false],
	[1.0, "zone", &"plaines"], [3.5, "weather", &"clear"], [3.6, "calm", 900.0], [3.7, "tp", Vector2(60, 62)],
	[7.0, "perf", "plaines/jour"], [7.05, "shot", "perf_plaines_jour"],
	[7.1, "clock", 22.5], [10.0, "perf", "plaines/nuit"], [10.05, "shot", "perf_plaines_nuit"], [10.1, "clock", 11.0],
	[10.2, "zone", &"foret"], [12.7, "weather", &"clear"], [12.8, "calm", 900.0], [12.9, "tp", Vector2(68, 52)],
	[16.0, "perf", "foret/jour"], [16.05, "shot", "perf_foret_jour"],
	[16.1, "zone", &"marais"], [18.6, "weather", &"clear"], [18.7, "calm", 900.0], [18.8, "tp", Vector2(84, 43)],
	[22.0, "perf", "marais/jour"], [22.05, "shot", "perf_marais_jour"],
	[22.1, "zone", &"desert"], [24.6, "weather", &"clear"], [24.7, "calm", 900.0], [24.8, "tp", Vector2(99, 33)],
	[28.0, "perf", "desert/jour"], [28.05, "shot", "perf_desert_jour"],
	[28.1, "zone", &"cote"], [30.6, "weather", &"clear"], [30.7, "calm", 900.0], [30.8, "tp", Vector2(26, 74)],
	[34.0, "perf", "cote/jour"], [34.05, "shot", "perf_cote_jour"],
	[34.1, "clock", 22.5], [37.0, "perf", "cote/nuit"], [37.05, "shot", "perf_cote_nuit"],
]
