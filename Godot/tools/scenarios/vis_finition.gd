extends RefCounted
## Visual checks only (passe de finition, 29/09), no scene played: the decors fixes posés par
## l'agent A — nids de Dimorphodons et rocher-œuf (Plaines), lanterne au crochet + bouilloire
## (Cabinet), frise de masques d'os (Marais, porte du temple), corde de falaise (Désert).
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_finition.gd

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise"]],
	[0.82, "clock", 11.0], [0.84, "weather", &"clear"], [0.86, "talk", true], [0.87, "vsync", false],
	# Plaines: the falaises, away from the "feu_camp" rest spot at (96.0, 10.4) — the two nests
	# (finition.mjs) sit clear of its 2.6-tile clearing radius (tools/zones/plaines.gd _rest_spots).
	[1.0, "zone", &"plaines"], [3.5, "weather", &"clear"], [3.6, "calm", 900.0],
	[3.7, "tp", Vector2(97.0, 10.5)], [3.8, "face", Vector2(0, -1)],
	[6.5, "shot", "pl_nids_dimorphodon"],
	# The egg-shaped rock (replaces the plain "rocher" at 65.0, 39.6, next to its "PAR OÙ" sign).
	[7.0, "tp", Vector2(65.5, 40.0)], [7.1, "face", Vector2(0, -1)],
	[9.8, "shot", "pl_rocher_oeuf"],
	# Chipie's lined bush (replaces the plain "buisson" stand-in, tools/zones/plaines.gd:181).
	[10.2, "tp", Vector2(41.0, 34.6)], [10.3, "face", Vector2(0, -1)],
	[13.0, "shot", "pl_buisson_nid"],
	# Cabinet: the lantern lit on its hook (default: "roc_dehors" not set).
	[13.4, "zone", &"cabinet"], [15.4, "tp", Vector2(9.9, 2.6)], [15.5, "face", Vector2(0, -1)],
	[18.2, "shot", "cab_lanterne_allumee"],
	# The kettle on its little stove.
	[18.6, "tp", Vector2(2.9, 4.0)], [18.7, "face", Vector2(0, -1)],
	[21.4, "shot", "cab_bouilloire"],
	# The empty hook, once Roc is out for the night (FlaggedProp swap: tools/zones/flagged_prop.gd).
	[21.8, "flags", ["roc_dehors"]], [21.9, "zone", &"cabinet"],
	[24.6, "tp", Vector2(9.9, 2.6)], [24.7, "face", Vector2(0, -1)],
	[27.4, "shot", "cab_crochet_vide"],
	# Marais: the frieze of bone masks over the temple's amber door (tools/zones/marais.gd).
	[27.8, "zone", &"marais"], [29.8, "tp", Vector2(30.0, 13.0)], [29.9, "face", Vector2(0, -1)],
	[32.6, "shot", "ma_frise_masques"],
	# Désert: the old rope down the cliff where Brac climbed away (Canyon des Vents dead end).
	[33.0, "zone", &"desert"], [35.0, "tp", Vector2(8.5, 4.5)], [35.1, "face", Vector2(0, -1)],
	[37.8, "shot", "de_corde_falaise"],
	[38.2, "state", null],
]
