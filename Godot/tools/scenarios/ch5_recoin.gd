extends RefCounted
## Dark nooks (la Plongée, chapter 5), for the integration: needs patch_ch5_mecaniques.md and
## patch_ch5_mecaniques2.md applied and the Récif rebuilt. See tools/capture.gd:
##   godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/ch5_recoin.gd
## What to look at:
##   re00-02  the first nook (west): so dark nothing shows; Chloé's Cœurs light up around her (amber),
##            the lines say it as it shows; the pebble glints as it comes into the light
##   re03     picked up (« Galet d'ambre ! »)
##   re04-05  the second (by the bones, east): the fossil, its line
##   re06     with one Cœur only: a smaller light (the fossil stays in the dark until very near)
##   re07     the sea caves' nook (back of the cache), at low quality

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
	[3.40, "tp", Vector2(6.6, 12.4)],
	[3.50, "auto", true],
	[4.30, "shot", "re00_lecon_noir"],
	[5.50, "shot", "re01_lecon_lueur"],
	[9.00, "auto", false],
	[9.10, "hold", "move_left"],
	[9.60, "hold", ""],
	[10.2, "shot", "re02_galet_luit"],
	[10.3, "interact_now", null],
	[11.8, "shot", "re03_galet_trouve"],
	[12.0, "tp", Vector2(26.9, 15.3)],
	[13.0, "shot", "re04_recoin_os"],
	[13.1, "hold", "move_up"],
	[13.35, "hold", ""],
	[13.8, "interact_now", null],
	[14.0, "auto", true],
	[14.8, "shot", "re05_fossile"],
	[18.0, "auto", false],
	[18.1, "gset", ["items", {"coeur_1": 1, "masque_plongee": 1, "gilet_nage": 1}]],
	[18.2, "tp", Vector2(5.4, 12.4)],
	[19.4, "shot", "re06_un_seul_coeur"],
	[19.5, "item", ["coeur_2", 1]],
	[19.6, "quality", 0],
	[19.7, "zone", &"grottes_marines"],
	[21.8, "calm", 900.0],
	[21.9, "tp", Vector2(4.6, 4.2)],
	[23.2, "shot", "re07_grotte_basse"],
	[23.3, "quality", 2],
	[23.4, "check", null],
]
