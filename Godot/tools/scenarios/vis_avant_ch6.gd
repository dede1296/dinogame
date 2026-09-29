extends RefCounted
## Visual checks only (29/09, passe « avant ch6 »), no scene played: the carved rock shown by
## Stage.show_thing (Sanctuaire des Vents), the existing campfire hearth (Plaines, night, the
## "feu_camp" rest spot at 96.0, 10.4 — judged alone: its animated flame and smoke are wired by
## the intégrateur), and the Pteranodon flight cycle (Côte, like tools/scenarios/vis_ch5.gd).
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_avant_ch6.gd

const ST := "res://story/stage.gd"
const CS := "res://story/cote_stage.gd"

const STEPS := [
	[0.85, "vsync", false], [0.86, "talk", true],
	# 1. The carved rock (Stage.show_thing, like desert_sanctuaire.gd:243).
	[1.0, "zone", &"sanctuaire_vents"], [1.1, "calm", 900.0], [1.2, "weather", &"clear"], [1.3, "clock", 11.0],
	[2.5, "tp", Vector2(10.0, 13.0)], [2.6, "face", Vector2(0, -1)],
	[3.0, "static", [ST, "show_thing", "rocher_grave", Vector2(10.0, 12.0), "RocherGrave"]],
	[4.2, "shot", "ac_rocher_grave"],
	# 2. The campfire hearth (unchanged feu_camp.png), Plaines at night.
	[4.6, "zone", &"plaines"], [6.6, "weather", &"clear"], [6.7, "clock", 22.0], [6.8, "calm", 900.0],
	[8.0, "tp", Vector2(97.0, 11.4)], [8.1, "face", Vector2(0, -1)],
	[10.8, "shot", "ac_feu_camp_nuit"],
	# 3. The Pteranodon flight cycle, two circling over the cove (like vis_ch5.gd — same flags, so
	# no arrival dialogue/trigger covers the shot).
	[11.2, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14", "found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossile_1", "fossile_2", "fossile_3", "fossile_4", "fossile_5", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre", "coeur_2", "maia_oasis_vue", "maia_defi_4", "met_roc", "lunettes_trouvees", "lunettes_rendues", "larmes_expliquees", "roc_sceau_foret", "roc_sceau_marais", "roc_sceau_desert", "cote_annonce", "cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "filet_coupe", "nessie", "masque_plongee", "barque_nuit_vue", "grottes_arrivee", "cache_vue", "passeur_parle", "passeur_battu", "passeur_parti", "caisses_fouillees", "barque_isaure_vue", "found_journal_21", "passe_recif", "recif_arrivee", "mosasaure_parle", "mosasaure_battu", "sceau_cote", "coeur_3"]],
	[11.3, "zone", &"cote"], [13.2, "weather", &"clear"], [13.3, "clock", 11.0], [13.4, "calm", 900.0],
	[14.6, "tp", Vector2(90.0, 32.0)], [14.7, "face", Vector2(0, -1)],
	[15.0, "static", [CS, "stand_in", "pteranodon", Vector2(92.5, 32.0), "PteroA"]],
	[15.0, "static", [CS, "stand_in", "pteranodon", Vector2(87.0, 32.0), "PteroB"]],
	[15.1, "static", [ST, "fade_in", "@PteroA", 0.4]],
	[15.1, "static", [ST, "fade_in", "@PteroB", 0.4]],
	[15.3, "static", [CS, "circle", "@PteroA", Vector2(89.75, 32.0), 132.0, 6.0, 130.0, 0.0]],
	[15.3, "static", [CS, "circle", "@PteroB", Vector2(89.75, 32.0), 132.0, 6.0, 130.0, PI]],
	[16.3, "shot", "ac_pteros_a"],
	[17.8, "shot", "ac_pteros_b"],
	[19.3, "shot", "ac_pteros_c"],
	[19.6, "state", null],
]
