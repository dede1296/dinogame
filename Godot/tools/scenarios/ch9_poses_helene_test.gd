extends RefCounted
## Chapter 9, after the tea (19/10): who sits how. At the Cabinet, Hélène in Roc's armchair from the
## start (Npc « HeleneAssise »: meta « held_pose » assis, meta « person » helene_fauteuil: her picture
## without the armchair once drawn, the armchair being the room's prop), Isaure sitting at the table
## (« IsaureCabinet », isaure_sans_masque_assise), who turns to Chloé when talked to without getting
## up. The next day on the jetty (epilogue_port, before the end): Hélène standing in her own sheet
## (helene.png: hat and cane, no more Mémé Pervenche tinted), Isaure by her boat, then holding the
## cardboard mask (Outfits.LOOKS « masque_carton »), then Hélène sitting on the ground (her pose of
## the crater, helene_sol: a check here, the crater's scene being long to reach); the new sheets of
## 19/10 on the jetty: Firmin without his mask (firmin_sans_masque), Léonce home with his net on his arm
## (leonce_port, no more Gustave's head), and Maïa sitting on her new stone (maia_pierre: feet on the
## ground; Stage.sit, as on the Cabinet's step).
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/ch9_poses_helene_test.gd titre="Ch. 9 : Hélène au fauteuil et Isaure assise au Cabinet ; sur la jetée Hélène debout, Isaure au masque en carton, Hélène assise au sol, Firmin sans masque, Léonce au filet, Maïa sur sa pierre"

const STEPS := [
	[0.80, "flags", ["prologue_arrived", "prologue_done", "roc_parti_vu", "raptor_porte_vu", "tuto_commandes", "met_roc", "sceau_plaines", "maia_defi_1", "havre_arrive", "selle", "foret_arrivee", "sceau_foret", "maia_defi_2", "marais_arrivee", "gilet_nage", "sceau_marais", "coeur_1", "maia_defi_3", "desert_arrivee", "sceau_desert", "coeur_2", "maia_defi_4", "cote_annonce", "cote_ouverte", "cote_arrivee", "nessie", "masque_plongee", "sceau_cote", "coeur_3", "maia_enfuie", "masque_carton", "monts_ouverts", "monts_arrivee", "bertille_vue", "suie_monts_battue", "suie_indice", "roc_col_vu", "roc_innocente", "sanctuaire_givre_ouvert", "titan_battu", "sceau_monts", "coeur_4", "maia_monts_vue", "masque_rendu", "maia_defi_5", "maia_alliee", "found_journal_25", "harnais_vol", "cieux_ouverts", "cieux_arrivee", "nids_arrivee", "quetzal_roi_parle", "quetzal_roi_battu", "quetzal_roi_confiance", "sceau_cieux", "vol_obtenu", "arche_arrivee", "arche_piege", "masque_arche_battu", "coeurs_voles", "masque_tombe", "moustique_confie", "masque_carton_confie", "roc_masque_tombe", "volcan_ouvert", "descente_cendre", "cendres_arrivee", "premier_corrompu_volcan", "forges_arrivee", "petites_forges_eteintes", "barricade_tombee", "brac_vaincu", "brac_parti", "fournaise_garde", "suie_alliee", "grande_forge_eteinte", "antidote_ambre", "suie_partie", "coulees_arrivee", "lave_franchie", "sanctuaire_magma_arrivee", "trex_magma_parle", "trex_magma_battu", "sceau_volcan", "coeur_5", "lave_retiree", "porte_arrivee",
		# (the Cabinet without the prologue's Maïa and Isaure, the lead dino sniffing the drawer, Roc and the Heart)
		"maia_left", "tiroir_flaire", "ambre_noir_tiroir", "roc_sceau_marais",
		# Chapter 9 (docs/chapitre-9-scenes.md, the flags' table), up to the tea at the Cabinet.
		"apex_aube", "isaure_pari", "isaure_aveu_oeuf", "isaure_vaincue", "apex_decision", "coeurs_rendus", "apex_ouvert", "apex_arrivee", "found_journal_39", "bloc_geant_vu", "coeur_apex_arrivee", "helene_vue", "essai_griffes", "essai_charge", "essai_chant", "essais_finis", "goutte_noire", "souverain_eveille", "helene_sortie", "caillou_rempart", "starter_lien_5", "souverain_apaise", "helene_liberee", "helene_reveillee", "moustique_rendu", "masque_carton_rendu", "masque_carton_pris", "apex_fini", "moufles_rendues", "isaure_cabinet", "tasse_bleue", "lettre_lue", "reserve_dite"]],
	[0.82, "give_named", ["parasaurolophus", "Écho", 6]],
	[0.84, "give_named", ["pachyrhinosaurus", "Bosse", 6]],
	[0.90, "level", 50],
	[1.00, "clock", 11],
	[1.02, "dlog", true],
	[1.08, "auto", false],
	[1.20, "weather", &"clear"],
	# The Cabinet: Hélène (9.4, 3.65) in Roc's armchair, the table (9.4, 5.1), Isaure (10.9, 5.6).
	[1.40, "zone", &"cabinet"],
	[4.20, "calm", 900],
	[4.40, "camera_distance", 7.0],
	[4.50, "tp", Vector2(9.4, 8.4)],
	[4.60, "face", Vector2(0, -1)],
	[6.40, "nodes", "Helene"],
	[6.50, "nodes", "Isaure"],
	[6.60, "shot", "c1_cabinet_helene_fauteuil_isaure_table"],
	[6.80, "camera_distance", 4.5],
	[6.90, "tp", Vector2(9.9, 7.2)],
	[8.60, "shot", "c2_cabinet_de_pres"],
	# Isaure, talked to: she turns to Chloé, still sitting.
	[8.80, "tp", Vector2(12.0, 6.0)],
	[8.90, "face", Vector2(-1, 0)],
	[9.50, "interact_now", null],
	[9.95, "shot", "c3_isaure_se_tourne_assise"],
	[11.00, "next", null],
	# The next morning, on the jetty (« epilogue_port »: its scene played, before the end).
	[11.40, "flags", ["epilogue_cabinet", "epilogue_port"]],
	[11.50, "zone", &"port_ambre"],
	[14.30, "calm", 900],
	[14.40, "weather", &"clear"],
	[14.50, "camera_distance", 9.0],
	[14.60, "tp", Vector2(19.5, 17.6)],
	[14.70, "face", Vector2(0, -1)],
	[16.40, "nodes", "Helene"],
	[16.50, "nodes", "Isaure"],
	[16.60, "shot", "j1_jetee_helene_debout"],
	[16.80, "camera_distance", 5.0],
	[16.90, "tp", Vector2(19.6, 16.6)],
	[18.60, "shot", "j2_helene_de_pres"],
	# Isaure by her boat, then the cardboard mask in her hand (Mastoc, in front of her, faded out first).
	[18.70, "static", ["res://story/stage.gd", "fade_out", "@MastocJetee", 0.3]],
	[18.80, "tp", Vector2(21.8, 20.5)],
	[18.90, "face", Vector2(-1, -0.6)],
	[20.40, "shot", "j3_isaure_barque"],
	[20.50, "dress", ["IsaureJetee", "masque_carton"]],
	[21.40, "shot", "j4_isaure_masque_carton"],
	[21.50, "dress", ["IsaureJetee", ""]],
	# Hélène sitting on the ground (her pose of the crater, helene_sol), a check.
	[21.70, "tp", Vector2(20.9, 16.9)],
	[21.80, "face", Vector2(-1, -1)],
	[22.00, "static", ["res://story/stage.gd", "sit", "@HeleneJetee"]],
	[23.60, "shot", "j5_helene_assise_au_sol"],
	# Firmin (14.2, 16.4) without his mask, Gustave (16.6, 16.6), Léonce (18.6, 18.6) with his net.
	[23.80, "camera_distance", 5.5],
	[23.90, "tp", Vector2(16.4, 19.2)],
	[24.00, "face", Vector2(0, -1)],
	[25.60, "shot", "j6_firmin_sans_masque_leonce_filet"],
	# Maïa (18.4, 16.4) sat on her stone: its foot on the planks, hers on the stone.
	[25.80, "static", ["res://story/stage.gd", "sit", "@MaiaJetee"]],
	[25.90, "camera_distance", 4.0],
	[26.00, "tp", Vector2(17.6, 18.0)],
	[26.10, "face", Vector2(1, -1)],
	[27.70, "shot", "j7_maia_sur_sa_pierre"],
	[27.90, "state", null],
]
