extends RefCounted
## Chapter 8, finitions (18/10): the forges' people sitting from the start (Npc meta « held_pose »,
## actors/outfits.gd POSES): Léonce with his mask on his knee (leonce_assis), the two bone masks
## (sbire_assis), what a mask says (event « masques_os »), Brac on his cage (brac_assis_cage), Dame
## Suie without her smoked glasses (Outfits.LOOKS, Stage.dress), the north way shut until she has gone
## (dialogue « coulees_bloquees »). No scene is played (the arrival's flag is set).
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/ch8_poses_forges_test.gd titre="Ch. 8 : Léonce, les masques et Brac assis ; Dame Suie sans lunettes ; sortie nord fermée"

const STEPS := [
	[0.80, "flags", ["prologue_done", "tuto_commandes", "met_roc", "sceau_plaines", "maia_defi_1", "havre_arrive", "selle", "foret_arrivee", "sceau_foret", "maia_defi_2", "marais_arrivee", "gilet_nage", "sceau_marais", "coeur_1", "maia_defi_3", "desert_arrivee", "sceau_desert", "coeur_2", "maia_defi_4", "cote_annonce", "cote_ouverte", "cote_arrivee", "nessie", "masque_plongee", "sceau_cote", "coeur_3", "maia_enfuie", "masque_carton", "monts_ouverts", "monts_arrivee", "bertille_vue", "suie_monts_battue", "suie_indice", "roc_col_vu", "roc_innocente", "sanctuaire_givre_ouvert", "titan_battu", "sceau_monts", "coeur_4", "maia_monts_vue", "masque_rendu", "maia_defi_5", "maia_alliee", "found_journal_25", "harnais_vol", "cieux_ouverts", "cieux_arrivee", "nids_arrivee", "quetzal_roi_parle", "quetzal_roi_battu", "quetzal_roi_confiance", "sceau_cieux", "vol_obtenu", "arche_arrivee", "arche_piege", "masque_arche_battu", "coeurs_voles", "masque_tombe", "moustique_confie", "masque_carton_confie", "roc_masque_tombe", "volcan_ouvert", "descente_cendre", "cendres_arrivee", "traces_vues", "premier_corrompu_volcan", "forges_arrivee", "leonce_vu", "forge_1_eteinte", "forge_2_eteinte", "forge_3_eteinte", "petites_forges_eteintes", "barricade_tombee"]],
	[0.82, "give_named", ["parasaurolophus", "Écho", 6]],
	[0.84, "give_named", ["pachyrhinosaurus", "Bosse", 6]],
	[0.90, "level", 43],
	[1.00, "clock", 11],
	[1.02, "dlog", true],
	[1.08, "auto", false],
	[1.20, "weather", &"clear"],
	[1.40, "zone", &"forges_ombre"],
	[4.20, "calm", 900],
	[4.30, "weather", &"clear"],
	# Léonce (44.6, 50.2) and the two masks (48.0, 46.8), (50.2, 50.6), sitting by the barrels.
	[4.40, "camera_distance", 9.0],
	[4.50, "tp", Vector2(46.6, 54.0)],
	[4.60, "face", Vector2(0, -1)],
	[6.60, "nodes", "Leonce"],
	[6.70, "nodes", "MasqueOs"],
	[6.80, "shot", "f1_leonce_masques_assis"],
	# A mask, talked to: the arrival's words (it stays sitting).
	[7.00, "tp", Vector2(48.0, 47.9)],
	[7.10, "face", Vector2(0, -1)],
	[7.60, "interact_now", null],
	[8.80, "shot", "f2_masque_parle"],
	[9.00, "next", null],
	[9.60, "next", null],
	[10.20, "shot", "f3_masque_toujours_assis"],
	# Brac on his cage, at the top of the notch (42.0, 17.2).
	[10.40, "tp", Vector2(42.6, 20.6)],
	[10.50, "face", Vector2(0, -1)],
	[12.40, "nodes", "BracVolcan"],
	[12.50, "shot", "f4_brac_sur_sa_cage"],
	# Dame Suie (46.4, 11.0) without her glasses.
	[12.70, "tp", Vector2(46.4, 13.4)],
	[12.80, "face", Vector2(0, -1)],
	[13.00, "camera_distance", 6.0],
	[14.20, "shot", "f5_suie_avec_lunettes"],
	[14.30, "dress", ["SuieVolcan", "sans_lunettes"]],
	[15.30, "shot", "f6_suie_sans_lunettes"],
	# The north way, shut until she has gone (56.5, 0.5).
	[15.50, "camera_distance", 9.0],
	[15.60, "tp", Vector2(56.5, 2.4)],
	[15.70, "hold", "move_up"],
	[16.90, "hold", ""],
	[17.60, "shot", "f7_sortie_coulees_fermee"],
	[17.80, "next", null],
	[18.50, "state", null],
]
