extends RefCounted
## Variantes de personnages (actors/outfits.gd, Stage.pose): Chloé crouching (« accroupi », the four
## ways she can face), then swimming on her own in the lagoon (« nage », lifted to the surface).
## No swimmer and no vest: she is not carried in the water.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/variantes_poses.gd

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14", "found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossile_1", "fossile_2", "fossile_3", "fossile_4", "fossile_5", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre", "coeur_2", "maia_oasis_vue", "maia_defi_4", "met_roc", "lunettes_trouvees", "lunettes_rendues", "larmes_expliquees", "roc_sceau_foret", "roc_sceau_marais", "roc_sceau_desert", "cote_annonce", "cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue"]],
	[0.82, "unflag", ["gilet_nage"]],
	[0.90, "clock", 11],
	[0.92, "weather", &"clear"],
	[1.30, "zone", &"cote"],
	[3.10, "calm", 900],
	[3.20, "camera_distance", 7.0],
	[3.40, "tp", Vector2(56, 61)],
	[4.40, "pose", ["accroupi", 0.0]],
	[4.80, "shot", "vp_00_accroupie_face"],
	[4.90, "face", Vector2.LEFT],
	[5.20, "shot", "vp_01_accroupie_gauche"],
	[5.30, "face", Vector2.RIGHT],
	[5.60, "shot", "vp_02_accroupie_droite"],
	[5.70, "face", Vector2.UP],
	[6.00, "shot", "vp_03_accroupie_dos"],
	[6.10, "pose", ["", 0.0]],
	[6.40, "face", Vector2.DOWN],
	[6.60, "shot", "vp_04_debout"],
	[6.70, "tp", Vector2(62.5, 49.6)],
	[7.60, "pose", ["nage", 0.0]],
	[8.00, "shot", "vp_05_nage_face"],
	[8.40, "shot", "vp_06_nage_face_b"],
	[8.50, "face", Vector2.RIGHT],
	[8.90, "shot", "vp_07_nage_droite"],
	[9.00, "face", Vector2.UP],
	[9.40, "shot", "vp_08_nage_dos"],
	[9.50, "pose", ["", 0.0]],
	[9.90, "shot", "vp_09_debout_dans_leau"],
]
