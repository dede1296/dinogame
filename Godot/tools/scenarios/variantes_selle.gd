extends RefCounted
## Variantes de personnages (actors/outfits.gd, Saddle): Chloé on her swimmer's back at the surface
## of the lagoon, in the swimming vest (gilet_nage), then under the sea on Nessie, with Joss's
## diving mask (Player.diving), seen each way.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/variantes_selle.gd

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee",
		"griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu",
		"sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret",
		"found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu",
		"gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2",
		"temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14",
		"found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossiles_rendus",
		"rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu",
		"carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "maia_oasis_vue",
		"cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "filet_coupe", "nessie",
		"masque_plongee", "barque_nuit_vue", "grottes_arrivee", "cache_vue", "passeur_parle", "passeur_battu", "passeur_parti",
		"caisses_fouillees", "barque_isaure_vue", "found_journal_21", "passe_recif", "recif_arrivee", "mosasaure_parle"]],
	[0.82, "give_named", ["plesiosaurus", "Nessie", 26]],
	[0.88, "level", 30],
	[0.90, "clock", 11.0],
	[0.92, "weather", &"clear"],
	[1.30, "zone", &"cote"],
	[3.20, "calm", 900.0],
	[3.25, "camera_distance", 8.0],
	# At the surface, on Nessie's back: the vest.
	[3.40, "tp", Vector2(66.0, 40.0)],
	[4.60, "hold", "move_right"],
	[5.30, "shot", "vs_00_gilet_droite"],
	[5.40, "hold", "move_left"],
	[6.30, "shot", "vs_01_gilet_gauche"],
	[6.40, "hold", "move_down"],
	[7.30, "shot", "vs_02_gilet_face"],
	[7.40, "hold", "move_up"],
	[8.30, "shot", "vs_03_gilet_dos"],
	[8.40, "hold", ""],
	# The dive beyond the pass: the mask.
	[8.50, "tp", Vector2(68.5, 20.5)],
	[9.60, "dive", "PlongeeRecif"],
	[14.60, "calm", 900.0],
	[14.70, "camera_distance", 8.0],
	[14.80, "hold", "move_up"],
	[15.50, "shot", "vs_07_masque_dos"],
	[15.60, "hold", "move_down"],
	[16.60, "shot", "vs_06_masque_face"],
	[16.70, "hold", "move_right"],
	[17.90, "shot", "vs_04_masque_droite"],
	[18.00, "hold", "move_left"],
	[19.40, "shot", "vs_05_masque_gauche"],
	[19.50, "hold", ""],
	[19.60, "dive_state", null],
]
