extends RefCounted
## Chapter 5, one moment of the chapter for the integration (state set by flags, then only this
## moment): the ruined lighthouse (3D) on the headland, at noon and at dusk.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/ch5_phare.gd

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14", "found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossile_1", "fossile_2", "fossile_3", "fossile_4", "fossile_5", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre", "coeur_2", "maia_oasis_vue", "maia_defi_4", "met_roc", "lunettes_trouvees", "lunettes_rendues", "larmes_expliquees", "roc_sceau_foret", "roc_sceau_marais", "roc_sceau_desert", "cote_annonce", "cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue"]],
	[0.82, "give", "compsognathus"],
	[0.84, "give", "protoceratops"],
	[0.86, "give", "baryonyx"],
	[0.88, "level", 27],
	[0.90, "clock", 12],
	[0.92, "weather", &"clear"],
	[0.94, "dlog", true],
	[0.96, "demo", true],
	[0.98, "no_help", null],
	[1.00, "auto", true],
	[1.02, "fast_battles", true],
	[1.30, "zone", &"cote"],
	[3.10, "calm", 900],
	[3.12, "weather", &"clear"],
	[3.42, "tp", Vector2(117, 17.5)],
	[5.02, "shot", "ph_midi"],
	[5.32, "tp", Vector2(112, 17.5)],
	[6.92, "shot", "ph_midi_loin"],
	[7.22, "tp", Vector2(108.5, 15.8)],
	[8.82, "shot", "ph_maia"],
	[9.12, "clock", 18.8],
	[9.42, "weather", &"clear"],
	[9.52, "tp", Vector2(117, 17.5)],
	[12.02, "shot", "ph_soir"],
	[12.32, "tp", Vector2(112, 17.5)],
	[13.92, "shot", "ph_soir_loin"],
	[14.22, "state", null],
]
