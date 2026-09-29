extends RefCounted
## Clins d'œil JP (agent B, 29/09): entering the sanctuary of Givre, the puddle whose water trembles at the
## Titan's heavy steps (rings, a dull thud, the camera shaking), then silence, then the Titan climbs down
## (story/monts_sanctuaire.gd arrival). A shot every 0.7 s at the demo's pace.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/jp_titan.gd

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14", "found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossile_1", "fossile_2", "fossile_3", "fossile_4", "fossile_5", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre", "coeur_2", "maia_oasis_vue", "maia_defi_4", "met_roc", "lunettes_trouvees", "lunettes_rendues", "larmes_expliquees", "roc_sceau_foret", "roc_sceau_marais", "roc_sceau_desert", "cote_annonce", "cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "filet_coupe", "nessie", "masque_plongee", "barque_nuit_vue", "grottes_arrivee", "cache_vue", "passeur_parle", "passeur_battu", "passeur_parti", "caisses_fouillees", "barque_isaure_vue", "found_journal_21", "passe_recif", "recif_arrivee", "mosasaure_parle", "mosasaure_battu", "sceau_cote", "coeur_3", "moustique_vu", "maia_guet_vue", "found_journal_23", "maia_enfuie", "masque_carton", "moustique_vu", "maia_guet_vue", "found_journal_23", "maia_enfuie", "masque_carton", "roc_isaure", "roc_sceau_cote", "roc_carte_intacte", "monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "mur_glace_1_brise", "mur_glace_2_brise", "grottes_glace_arrivee", "suie_monts_vue", "suie_monts_battue", "suie_monts_partie", "suie_indice", "dormeurs_reveilles", "blizzard_col", "roc_col_vu", "roc_innocente", "porte_givre_vue", "sanctuaire_givre_ouvert"]],
	[0.82, "give_named", ["parasaurolophus", "Écho", 6]],
	[0.84, "give_named", ["plesiosaurus", "Nessie", 6]],
	[0.86, "give_named", ["baryonyx", "Bouée", 6]],
	[0.88, "give_named", ["pachyrhinosaurus", "Bosse", 6]],
	[0.90, "level", 35],
	[0.92, "item", ["piece", 450]],
	[0.94, "item", ["manteau_duvet", 1]],
	[0.96, "clock", 11],
	[0.98, "dlog", true], [1.00, "demo", true], [1.02, "no_help", null], [1.04, "auto", true],
	[1.36, "zone", &"sanctuaire_givre"],
	[19.00, "shot", "t00"],
	[19.70, "shot", "t01"],
	[20.40, "shot", "t02"],
	[21.10, "shot", "t03"],
	[21.80, "shot", "t04"],
	[22.50, "shot", "t05"],
	[23.20, "shot", "t06"],
	[23.90, "shot", "t07"],
	[24.60, "shot", "t08"],
	[25.30, "shot", "t09"],
	[26.00, "shot", "t10"],
	[26.70, "shot", "t11"],
	[27.40, "shot", "t12"],
	[28.10, "shot", "t13"],
	[30.00, "wait_idle", [0.5, 200]], [30.10, "state", null],
]
