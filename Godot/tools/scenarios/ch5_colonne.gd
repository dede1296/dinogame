extends RefCounted
## The bubble column (la Plongée, chapter 5), for the integration: needs patch_ch5_mecaniques.md and
## patch_ch5_mecaniques2.md applied and the Récif rebuilt. See tools/capture.gd:
##   godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/ch5_colonne.gd
## What to look at:
##   cl00-03  the first column (at the foot of the spire, north-east): big bubbles gushing from the fissure,
##            the camera up to the plateau, Nessie pointing at it (the lines say it as it shows)
##   cl04-06  into the bubbles: they rise past the spire's rock, overshoot a little, settle on the top
##   cl07     page 22 up there (found: its lines)
##   cl08-09  swimming on over the south edge: they sink gently down beside the spire (log: « état »)

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
	[0.84, "give", "pteranodon"],
	[0.88, "level", 30],
	[0.89, "item", ["coeur_1", 1]],
	[0.895, "item", ["coeur_2", 1]],
	[0.90, "clock", 11.0],
	[0.92, "weather", &"clear"],
	[0.94, "dlog", true],
	[1.30, "zone", &"recif_sanctuaire"],
	[3.20, "calm", 900.0],
	[3.40, "tp", Vector2(22.8, 7.9)],
	[3.50, "auto", true],
	[4.40, "shot", "cl00_lecon"],
	[5.60, "shot", "cl01_lecon_bulles"],
	[6.80, "shot", "cl02_lecon_plateau"],
	[8.00, "shot", "cl03_lecon_nessie"],
	[12.0, "auto", false],
	[12.1, "state", null],
	[12.2, "hold", "move_right"],
	[13.0, "hold", ""],
	[13.3, "shot", "cl04_monte"],
	[14.0, "shot", "cl05_monte_haut"],
	[15.4, "shot", "cl06_sur_le_piton"],
	[15.5, "state", null],
	[15.6, "hold", "move_right"],
	[15.9, "hold", "move_up"],
	[16.1, "hold", ""],
	[16.3, "interact_now", null],
	[16.4, "auto", true],
	[17.4, "shot", "cl07_page_22"],
	[24.0, "auto", false],
	[24.2, "hold", "move_down"],
	[25.2, "shot", "cl08_redescend"],
	[26.0, "hold", ""],
	[26.6, "state", null],
	[26.7, "shot", "cl09_en_bas"],
]
