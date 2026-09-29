extends RefCounted
## Visual checks only (finition B, 29/09), no scene played: Chloé's two new scene poses
## (actors/outfits.gd, Outfits.POSES["chloe"]) — &"main" (reaching out her hand) and &"grimpe"
## (climbing onto a rock), the four ways she can face each time.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_poses_b_chloe.gd

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14", "found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossile_1", "fossile_2", "fossile_3", "fossile_4", "fossile_5", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre", "coeur_2", "maia_oasis_vue", "maia_defi_4", "met_roc", "lunettes_trouvees", "lunettes_rendues", "larmes_expliquees", "roc_sceau_foret", "roc_sceau_marais", "roc_sceau_desert", "cote_annonce", "cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue"]],
	[0.90, "clock", 11],
	[0.92, "weather", &"clear"],
	[1.30, "zone", &"cote"],
	[3.10, "calm", 900],
	[3.20, "camera_distance", 7.0],
	[3.40, "tp", Vector2(56, 61)],
	[4.40, "pose", ["main", 0.0]],
	[4.80, "shot", "b1_main_face"],
	[4.90, "face", Vector2.LEFT],
	[5.20, "shot", "b2_main_gauche"],
	[5.30, "face", Vector2.RIGHT],
	[5.60, "shot", "b3_main_droite"],
	[5.70, "face", Vector2.UP],
	[6.00, "shot", "b4_main_dos"],
	[6.10, "pose", ["", 0.0]],
	[6.40, "face", Vector2.DOWN],
	[7.10, "pose", ["grimpe", 0.0]],
	[7.50, "shot", "b5_grimpe_face"],
	[7.60, "face", Vector2.LEFT],
	[7.90, "shot", "b6_grimpe_gauche"],
	[8.00, "face", Vector2.RIGHT],
	[8.30, "shot", "b7_grimpe_droite"],
	[8.40, "face", Vector2.UP],
	[8.70, "shot", "b8_grimpe_dos"],
	[8.80, "pose", ["", 0.0]],
	[9.10, "face", Vector2.DOWN],
	[9.30, "shot", "b9_debout"],
]
