extends RefCounted
## Chapter 8, finitions (18/10): Maïa sitting on her stone at the crater's door from the start (Npc
## meta « held_pose », pose « maia_pierre »: the stone in the picture, its feet on the ground), Caillou
## who sneezes when talked to (event « caillou_porte »); then Port-Ambre once the forges are out and
## Brac gone: Léonce mending the nets on the pontoon (pecheur_assis), Brac at the end of it on a cage,
## what each one does when talked to (Léonce's line, Brac's glance).
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/ch8_poses_porte_port_test.gd titre="Ch. 8 : Maïa sur sa pierre ; Léonce et Brac sur le ponton de Port-Ambre"

const STEPS := [
	[0.80, "flags", ["prologue_arrived", "prologue_done", "roc_parti_vu", "raptor_porte_vu", "tuto_commandes", "met_roc", "sceau_plaines", "maia_defi_1", "havre_arrive", "selle", "foret_arrivee", "sceau_foret", "maia_defi_2", "marais_arrivee", "gilet_nage", "sceau_marais", "coeur_1", "maia_defi_3", "desert_arrivee", "sceau_desert", "coeur_2", "maia_defi_4", "cote_annonce", "cote_ouverte", "cote_arrivee", "nessie", "masque_plongee", "sceau_cote", "coeur_3", "maia_enfuie", "masque_carton", "monts_ouverts", "monts_arrivee", "bertille_vue", "suie_monts_battue", "suie_indice", "roc_col_vu", "roc_innocente", "sanctuaire_givre_ouvert", "titan_battu", "sceau_monts", "coeur_4", "maia_monts_vue", "masque_rendu", "maia_defi_5", "maia_alliee", "found_journal_25", "harnais_vol", "cieux_ouverts", "cieux_arrivee", "nids_arrivee", "quetzal_roi_parle", "quetzal_roi_battu", "quetzal_roi_confiance", "sceau_cieux", "vol_obtenu", "arche_arrivee", "arche_piege", "masque_arche_battu", "coeurs_voles", "masque_tombe", "moustique_confie", "masque_carton_confie", "roc_masque_tombe", "volcan_ouvert", "descente_cendre", "cendres_arrivee", "premier_corrompu_volcan", "forges_arrivee", "petites_forges_eteintes", "barricade_tombee", "brac_vaincu", "brac_parti", "fournaise_garde", "suie_alliee", "grande_forge_eteinte", "antidote_ambre", "suie_partie", "coulees_arrivee", "lave_franchie", "sanctuaire_magma_arrivee", "trex_magma_parle", "trex_magma_battu", "sceau_volcan", "coeur_5", "lave_retiree", "porte_arrivee"]],
	[0.82, "give_named", ["parasaurolophus", "Écho", 6]],
	[0.84, "give_named", ["pachyrhinosaurus", "Bosse", 6]],
	[0.90, "level", 46],
	[1.00, "clock", 11],
	[1.02, "dlog", true],
	[1.08, "auto", false],
	[1.20, "weather", &"clear"],
	[1.40, "zone", &"porte_cratere"],
	[4.20, "calm", 900],
	[4.30, "weather", &"clear"],
	# Maïa (20.2, 11.8) on her stone, Isaure (25.0, 10.4) her back to us, Caillou (31.0, 9.6).
	[4.40, "camera_distance", 9.0],
	[4.50, "tp", Vector2(22.4, 15.4)],
	[4.60, "face", Vector2(0, -1)],
	[6.50, "nodes", "MaiaPorte"],
	[6.60, "shot", "p1_maia_sur_sa_pierre"],
	[6.80, "camera_distance", 5.5],
	[6.90, "tp", Vector2(20.2, 13.4)],
	[8.60, "shot", "p2_maia_sur_sa_pierre_pres"],
	# Caillou, talked to.
	[8.80, "camera_distance", 9.0],
	[8.90, "tp", Vector2(30.4, 10.7)],
	[9.00, "face", Vector2(1, -1.4)],
	[9.60, "interact_now", null],
	[10.80, "shot", "p3_caillou_eternue"],
	[11.00, "next", null],
	[11.50, "next", null],
	[12.00, "next", null],
	# Port-Ambre: Léonce (18.6, 18.6) and Brac (18.6, 22.3) on the pontoon.
	[12.40, "zone", &"port_ambre"],
	[15.20, "calm", 900],
	[15.30, "weather", &"clear"],
	[15.40, "camera_distance", 10.0],
	[15.50, "tp", Vector2(20.3, 22.7)],
	[15.60, "face", Vector2(0, -1)],
	[17.40, "nodes", "Leonce"],
	[17.50, "nodes", "BracJetee"],
	[17.60, "shot", "q1_leonce_et_brac_ponton"],
	# Léonce, talked to (he stays sitting with his net).
	[17.80, "camera_distance", 7.0],
	[17.90, "tp", Vector2(19.3, 19.2)],
	[18.00, "face", Vector2(-1, -1)],
	[18.60, "interact_now", null],
	[20.00, "shot", "q2_leonce_parle"],
	[20.20, "next", null],
	[20.70, "next", null],
	[21.20, "next", null],
	# Brac, talked to: « … », and back to the sea.
	[21.60, "tp", Vector2(19.5, 22.4)],
	[21.70, "face", Vector2(-1, 0)],
	[22.30, "interact_now", null],
	[22.90, "shot", "q3_brac_regarde_chloe"],
	[25.20, "shot", "q4_brac_regarde_la_mer"],
	[25.60, "state", null],
]
