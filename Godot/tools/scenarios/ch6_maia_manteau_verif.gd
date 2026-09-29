extends RefCounted
## Visual check only (29/09, images agent, demande de l'utilisateur) : Maïa en manteau aux Monts,
## juste avant sa scène (mêmes drapeaux que tools/scenarios/ch6_maia.gd, jusqu'à coeur_4, mais SANS
## "interact_now" : on s'arrête avant que son défi n° 5 ne se déclenche) — un tp devant elle, deux
## captures (son apparence normale = la planche maia_manteau.png, puis sa pose assise forcée =
## maia_manteau_assise.png via Stage.pose, comme vis_poses_b_maia.gd le fait pour son "accroupi").
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/ch6_maia_manteau_verif.gd

const ST := "res://story/stage.gd"
const SELF := "res://tools/scenarios/ch6_maia_manteau_verif.gd"

## MAIA_RETOUR (109.5, 12.5) sits right at the sanctuary notch, on a raised ledge (8.4 m elevation
## in the 3D view) that the cliff face occludes from ground level: fine for the real scene (Chloé
## climbs to meet her there), useless for a clean sprite-check screenshot. Only for this visual
## check, she is slid a few tiles onto the open, flat snow beside Chloé (the real placement in
## tools/zones/monts.gd is untouched).
static func move(actor, to: Vector2) -> bool:
	(actor as Node2D).global_position = to
	return true


const STEPS := [
	[0.80, "flags", ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue", "found_journal_ancien", "mur_camp_brise", "camp_arrive", "sbire_camp_1_vu", "sbire_camp_2_vu", "sbire_camp_1_battu", "sbire_camp_2_battu", "brac_parle", "brac_battu", "cage_ouverte", "sceau_foret", "found_journal_11", "papiers_brac_lus", "masque_vu", "maia_defi_2", "ambre_noir_tiroir", "marais_arrivee", "joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue", "temple_vanne_1", "temple_vanne_2", "temple_vanne_3", "spinosaure_battu", "sceau_marais", "coeur_1", "found_journal_12", "found_journal_13", "found_journal_14", "found_journal_15", "found_journal_16", "roc_marais_vu", "maia_defi_3", "desert_arrivee", "sirocco_vue", "fossile_1", "fossile_2", "fossile_3", "fossile_4", "fossile_5", "fossiles_rendus", "rempart_ouvert", "rempart_rencontre", "found_journal_17", "found_journal_20", "brac_desert_vu", "brac_desert_battu", "chariot_fouille", "carnotaurus_apaise", "sanctuaire_ouvert", "sceau_desert", "sanctuaire_entre", "coeur_2", "maia_oasis_vue", "maia_defi_4", "met_roc", "lunettes_trouvees", "lunettes_rendues", "larmes_expliquees", "roc_sceau_foret", "roc_sceau_marais", "roc_sceau_desert", "cote_annonce", "cote_ouverte", "cote_arrivee", "pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "filet_coupe", "nessie", "masque_plongee", "barque_nuit_vue", "grottes_arrivee", "cache_vue", "passeur_parle", "passeur_battu", "passeur_parti", "caisses_fouillees", "barque_isaure_vue", "found_journal_21", "passe_recif", "recif_arrivee", "mosasaure_parle", "mosasaure_battu", "sceau_cote", "coeur_3", "moustique_vu", "maia_guet_vue", "found_journal_23", "maia_enfuie", "masque_carton", "roc_isaure", "roc_sceau_cote", "roc_carte_intacte", "monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "mur_glace_1_brise", "mur_glace_2_brise", "grottes_glace_arrivee", "suie_monts_vue", "suie_monts_battue", "suie_monts_partie", "suie_indice", "dormeurs_reveilles", "blizzard_col", "roc_col_vu", "roc_innocente", "porte_givre_vue", "sanctuaire_givre_ouvert", "sanctuaire_givre_arrivee", "titan_parle", "titan_battu", "sceau_monts", "coeur_4"]],
	[0.82, "item", ["manteau_duvet", 1]],
	[0.84, "level", 36],
	[0.86, "clock", 11.0],
	[0.88, "weather", &"clear"],
	[0.90, "calm", 900.0],
	[1.20, "zone", &"monts"],
	[2.80, "camera_distance", 6.0],
	[3.00, "tp", Vector2(110.0, 13.0)],
	[3.10, "static", [SELF, "move", "@MaiaMonts", Vector2(108.7, 13.0)]],
	[3.20, "face", Vector2(-1, 0)],
	[3.50, "wait_idle", [0.3, 60]],
	[3.55, "nodes", "Maia"],
	[3.80, "shot", "00_maia_manteau_debout"],
	[3.90, "static", [ST, "pose", "@MaiaMonts", "assis", 0.0]],
	[4.20, "shot", "01_maia_manteau_assise"],
	[4.30, "static", [ST, "pose", "@MaiaMonts", "", 0.0]],
	[4.50, "state", null],
]
