extends RefCounted
## The little life of a kind of place (Wildlife, WildlifeDB): the Marais: mosquitoes, dragonflies, frogs hopping by the water, fish leaping; green fireflies at night.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/faune_marais.gd

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14", "found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossile_1", "fossile_2", "fossile_3", "fossile_4", "fossile_5", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre", "coeur_2", "maia_oasis_vue", "maia_defi_4", "met_roc", "lunettes_trouvees", "lunettes_rendues", "larmes_expliquees", "roc_sceau_foret", "roc_sceau_marais", "roc_sceau_desert", "cote_annonce", "cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "filet_coupe", "nessie", "masque_plongee"]],
	[0.82, "clock", 11.0], [0.84, "weather", &"clear"], [0.86, "talk", true], [0.87, "vsync", false],
	[1.0, "zone", &"marais"], [3.5, "weather", &"clear"], [3.6, "calm", 900.0], [3.7, "tp", Vector2(84, 43)],
	[6.5, "shot", "ma_jour_a"], [7.0, "shot", "ma_jour_b"], [7.5, "shot", "ma_jour_c"], [7.6, "perf", "marais/jour"],
	[7.7, "tp", Vector2(26, 76)], [10.5, "shot", "ma_noyee_a"], [11.2, "shot", "ma_noyee_b"],
	[11.3, "tp", Vector2(116, 70)], [14.0, "shot", "ma_arrivee"],
	[14.1, "clock", 22.5], [14.2, "tp", Vector2(84, 43)], [19.5, "shot", "ma_nuit"], [19.6, "perf", "marais/nuit"],
]
