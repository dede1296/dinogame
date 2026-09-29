extends RefCounted
## Currents (la Plongée, chapter 5), for the integration: needs patch_ch5_mecaniques.md and
## patch_ch5_mecaniques2.md applied and the Récif rebuilt. See tools/capture.gd:
##   godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/ch5_courant.gd
## What to look at:
##   co00-03  the first current (the pass, a shortcut north): Nessie stops at its edge, weed and bubbles
##            rush past (the lines say it as it shows); streaks rushing north, its sound
##   co04-05  carried: Chloé lets go, the current takes them north to the dais (log: « état » before/after)
##   co06-08  the current of the abyss (south, in the way): the toast once; swimming against it she gets
##            nowhere (log); behind a rock (its lee) she holds; from rock to rock she goes up
##   co09     the same at low quality (fewer streaks, still readable)

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
	[3.40, "tp", Vector2(9.6, 21.0)],
	[3.50, "auto", true],
	[4.40, "shot", "co00_lecon"],
	[5.60, "shot", "co01_lecon_algues"],
	[6.80, "shot", "co02_lecon_nessie"],
	[8.00, "shot", "co03_lecon_fin"],
	[11.0, "auto", false],
	[11.1, "state", null],
	[11.2, "hold", "move_up"],
	[12.0, "hold", ""],
	[12.2, "shot", "co04_emportes"],
	[14.0, "state", null],
	[14.1, "shot", "co05_arrives_estrade"],
	[14.3, "tp", Vector2(23.5, 17.2)],
	[15.0, "shot", "co06_courant_contraire"],
	[15.1, "state", null],
	[15.2, "hold", "move_up"],
	[17.2, "state", null],
	[17.3, "shot", "co07_contre_le_courant"],
	[17.4, "hold", ""],
	[17.5, "tp", Vector2(23.4, 16.1)],
	[18.5, "state", null],
	[18.6, "shot", "co08_a_labri"],
	[18.7, "quality", 0],
	[19.8, "tp", Vector2(9.6, 18.0)],
	[21.0, "shot", "co09_basse"],
	[21.1, "quality", 2],
]
