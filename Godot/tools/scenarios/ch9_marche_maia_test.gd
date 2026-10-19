extends RefCounted
## Chapitre 9 : Maïa assise dès le départ sur la marche du Cabinet (pose « assis_marche », manteau de Joss, sans pierre).
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier> scenario_file=res://tools/scenarios/ch9_marche_maia_test.gd titre="Ch. 9 : Maïa assise sur la marche du Cabinet, manteau de Joss, sans pierre"

const STEPS := [
	[0.80, "flags", ["prologue_arrived", "prologue_done", "roc_parti_vu", "raptor_porte_vu", "tuto_commandes", "met_roc", "sceau_plaines", "maia_defi_1", "havre_arrive", "selle", "foret_arrivee", "sceau_foret", "maia_defi_2", "marais_arrivee", "gilet_nage", "sceau_marais", "coeur_1", "maia_defi_3", "desert_arrivee", "sceau_desert", "coeur_2", "maia_defi_4", "cote_annonce", "cote_ouverte", "cote_arrivee", "nessie", "masque_plongee", "sceau_cote", "coeur_3", "maia_enfuie", "masque_carton", "monts_ouverts", "monts_arrivee", "bertille_vue", "suie_monts_battue", "suie_indice", "roc_col_vu", "roc_innocente", "sanctuaire_givre_ouvert", "titan_battu", "sceau_monts", "coeur_4", "maia_monts_vue", "masque_rendu", "maia_defi_5", "maia_alliee", "found_journal_25", "harnais_vol", "cieux_ouverts", "cieux_arrivee", "nids_arrivee", "quetzal_roi_parle", "quetzal_roi_battu", "quetzal_roi_confiance", "sceau_cieux", "vol_obtenu", "arche_arrivee", "arche_piege", "masque_arche_battu", "coeurs_voles", "masque_tombe", "moustique_confie", "masque_carton_confie", "roc_masque_tombe", "volcan_ouvert", "descente_cendre", "cendres_arrivee", "premier_corrompu_volcan", "forges_arrivee", "petites_forges_eteintes", "barricade_tombee", "brac_vaincu", "brac_parti", "fournaise_garde", "suie_alliee", "grande_forge_eteinte", "antidote_ambre", "suie_partie", "coulees_arrivee", "lave_franchie", "sanctuaire_magma_arrivee", "trex_magma_parle", "trex_magma_battu", "sceau_volcan", "coeur_5", "lave_retiree", "porte_arrivee",
		# (the Cabinet without the prologue's Maïa and Isaure, the lead dino sniffing the drawer, Roc and the Heart)
		"maia_left", "tiroir_flaire", "ambre_noir_tiroir", "roc_sceau_marais",
		"apex_aube", "isaure_pari", "isaure_aveu_oeuf", "isaure_vaincue", "apex_decision", "coeurs_rendus", "apex_ouvert", "apex_arrivee", "apex_fini", "isaure_cabinet", "tasse_bleue", "lettre_lue", "reserve_dite"]],
	[1.00, "clock", 11],
	[1.02, "dlog", true],
	[1.08, "auto", false],
	[1.20, "weather", &"clear"],
	[1.40, "zone", &"port_ambre"],
	[4.20, "calm", 900],
	[4.30, "weather", &"clear"],
	[4.40, "camera_distance", 4.0],
	[4.50, "tp", Vector2(31.0, 11.0)],
	[4.60, "face", Vector2(1, -1)],
	[6.40, "nodes", "MaiaMarche"],
	[6.50, "static", ["res://actors/outfits.gd", "pose", "@MaiaMarche", &"assis_marche"]],
	[6.60, "shot", "m1_maia_assise_marche"],
	[6.80, "state", null],
]
