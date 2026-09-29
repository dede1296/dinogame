extends RefCounted
## La Plongée (chapter 5), for the integration: needs patch_ch5_mecaniques.md applied and the Côte's zones
## built. See tools/capture.gd:
##   godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/plongee_test.gd
## What to look at:
##   pl00-01  the dive spot beyond the pass: darker water, rings of bubbles; over it, the dive button (bubbles, arrow down)
##   pl02-05  the dive: Nessie and Chloé sink under the surface (splash, bubbles), the screen goes deep blue, they come
##            down into the Récif du Sanctuaire from above; the Remonter button (arrow up)
##   pl06-07  swimming under the water: blue-green light, shafts, caustics on the floor, specks, bubbles from Chloé's
##            mask and behind Nessie, both above the floor (never lying on it); the Mosasaure hovering; at night
##   pl08-11  a wild battle under the water: the water all around, the fighters floating; the rules said once;
##            ▲ on the Water moves' cards, ▼ on the Fire ones
##   pl12-27  the Mosasaure Abyssal (rule "abyss"): every third turn it sinks into the dark (the foe fades, the water
##            darkens), « Trop profond… », it surges (jolt, bubbles), « à découvert », then a sure critical hit
##   pl30-33  Remonter: they rise out of view, the light of the surface, they come up out of the water at the pass
##   pl40-43  the sea caves' flooded passage: into the blue pool, up in the inner cave
## The log: « plongée : … » lines (dive_state), the battle's lines (⚔), the save and load (check).

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
	[0.86, "give", "baryonyx"],
	[0.88, "level", 30],
	[0.90, "clock", 11.0],
	[0.92, "weather", &"clear"],
	[0.94, "dlog", true],
	[1.30, "zone", &"cote"],
	[3.20, "calm", 900.0],
	[3.30, "weather", &"clear"],
	# The dive spot beyond the pass (CotePlaces.ACCES_RECIF), then over it: the dive button.
	[3.40, "tp", Vector2(68.5, 23.2)],
	[5.00, "shot", "pl00_point_de_plongee"],
	[5.10, "tp", Vector2(68.5, 20.5)],
	[6.30, "shot", "pl01_bouton_plonger"],
	[6.40, "dive_state", null],
	# The dive.
	[6.50, "dive", "PlongeeRecif"],
	[7.35, "shot", "pl02_plonge"],
	[8.00, "shot", "pl03_bleu"],
	[9.90, "shot", "pl04_descente"],
	[11.40, "shot", "pl05_recif"],
	[11.50, "dive_state", null],
	[11.60, "calm", 900.0],
	[11.70, "hold", "move_up"],
	[13.00, "shot", "pl06_nage_sous_leau"],
	[13.10, "hold", ""],
	[13.20, "clock", 21.5],
	[14.80, "shot", "pl07_nuit_sous_leau"],
	[14.90, "clock", 11.0],
	# A wild battle under the water.
	[15.30, "battle", [&"ichthyosaurus", 30]],
	[18.00, "shot", "pl08_combat_intro"],
	[18.10, "press", "interact"],
	[19.10, "shot", "pl09_regles"],
	[19.20, "press", "interact"],
	[20.20, "press", "interact"],
	[21.20, "press", "interact"],
	[22.00, "moves", null],
	[22.40, "shot", "pl10_cartes"],
	[22.50, "auto", true],
	[75.80, "auto", false],
	[75.90, "shot", "pl11_apres_combat"],
	[76.00, "party", null],
	# The Mosasaure's battle (its rhythm): shots every 2 s.
	[76.40, "tp", Vector2(16.0, 18.0)],
	[77.30, "battle_rules", [&"mosasaure_abyssal", 32, {"catch": false, "run": false, "abyss": true, "size": 1.2,
		"intro": "Le Mosasaure Abyssal ouvre sa gueule immense !"}, "Mosasaure Abyssal"]],
	[78.80, "auto", true],
	[80.80, "shot", "pl12_mosa"], [82.80, "shot", "pl13_mosa"], [84.80, "shot", "pl14_mosa"], [86.80, "shot", "pl15_mosa"],
	[88.80, "shot", "pl16_mosa"], [90.80, "shot", "pl17_mosa"], [92.80, "shot", "pl18_mosa"], [94.80, "shot", "pl19_mosa"],
	[96.80, "shot", "pl20_mosa"], [98.80, "shot", "pl21_mosa"], [100.80, "shot", "pl22_mosa"], [102.80, "shot", "pl23_mosa"],
	[104.80, "shot", "pl24_mosa"], [106.80, "shot", "pl25_mosa"], [108.80, "shot", "pl26_mosa"], [110.80, "shot", "pl27_mosa"],
	[140.80, "auto", false],
	[141.00, "party", null],
	# Back up.
	[141.80, "calm", 900.0],
	[142.00, "surface", null],
	[142.60, "shot", "pl30_remonte"],
	[143.40, "shot", "pl31_lumiere"],
	[144.20, "shot", "pl32_emerge"],
	[145.80, "shot", "pl33_surface"],
	[145.90, "dive_state", null],
	# The sea caves' flooded passage.
	[146.30, "zone", &"grottes_marines"],
	[148.30, "calm", 900.0],
	[148.40, "dive", "PlongeeAller"],
	[149.20, "shot", "pl40_passage_plonge"],
	[150.20, "shot", "pl41_passage_bleu"],
	[151.40, "shot", "pl42_passage_remonte"],
	[152.80, "shot", "pl43_grotte_du_fond"],
	[152.90, "dive_state", null],
	[153.10, "check", null],
]
