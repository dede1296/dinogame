extends RefCounted
## Variantes de personnages (actors/outfits.gd): Chloé on foot in Rosalie's walking boots (the key
## item « bottes »): the same moment without them, then with them, walking each way.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/variantes_bottes.gd

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14", "found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossile_1", "fossile_2", "fossile_3", "fossile_4", "fossile_5", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre", "coeur_2", "maia_oasis_vue", "maia_defi_4", "met_roc", "lunettes_trouvees", "lunettes_rendues", "larmes_expliquees", "roc_sceau_foret", "roc_sceau_marais", "roc_sceau_desert", "cote_annonce", "cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue"]],
	[0.90, "clock", 11],
	[0.92, "weather", &"clear"],
	[1.30, "zone", &"cote"],
	[3.10, "calm", 900],
	[3.20, "camera_distance", 7.0],
	[3.40, "tp", Vector2(56, 61)],
	[4.60, "shot", "vb_00_sans_bottes"],
	[4.70, "item", ["bottes", 1]],
	[5.20, "shot", "vb_01_bottes_face"],
	[5.30, "hold", "move_right"],
	[5.62, "shot", "vb_02_bottes_droite"],
	[5.70, "hold", "move_left"],
	[6.12, "shot", "vb_03_bottes_gauche"],
	[6.20, "hold", "move_up"],
	[6.62, "shot", "vb_04_bottes_dos"],
	[6.70, "hold", "move_down"],
	[7.12, "shot", "vb_05_bottes_marche_face"],
	[7.20, "hold", ""],
]
