extends RefCounted
## Chapter 8, finitions (18/10): the arrival in the Champs de Cendre, where the camera looks at the
## seven red fires at the volcano's foot (VolcanPlaces.FEUX_FORGES, north of the fields), and Moustique
## peeking out of Chloé's collar (Volcan.shoulder_peek: only his beak and eyes over her collar),
## close up, from the front and from behind.
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/ch8_feux_col_test.gd titre="Ch. 8 : les sept feux vus des Champs ; Moustique dans le col"

const STEPS := [
	[0.80, "flags", ["prologue_arrived", "prologue_done", "tuto_commandes", "met_roc", "sceau_plaines", "maia_defi_1", "havre_arrive", "selle", "foret_arrivee", "sceau_foret", "maia_defi_2", "marais_arrivee", "gilet_nage", "sceau_marais", "coeur_1", "maia_defi_3", "desert_arrivee", "sceau_desert", "coeur_2", "maia_defi_4", "cote_annonce", "cote_ouverte", "cote_arrivee", "nessie", "masque_plongee", "sceau_cote", "coeur_3", "maia_enfuie", "masque_carton", "monts_ouverts", "monts_arrivee", "bertille_vue", "suie_monts_battue", "suie_indice", "roc_col_vu", "roc_innocente", "sanctuaire_givre_ouvert", "titan_battu", "sceau_monts", "coeur_4", "maia_monts_vue", "masque_rendu", "maia_defi_5", "maia_alliee", "found_journal_25", "harnais_vol", "cieux_ouverts", "cieux_arrivee", "nids_arrivee", "quetzal_roi_parle", "quetzal_roi_battu", "quetzal_roi_confiance", "sceau_cieux", "vol_obtenu", "arche_arrivee", "arche_piege", "masque_arche_battu", "coeurs_voles", "masque_tombe", "moustique_confie", "masque_carton_confie", "roc_masque_tombe", "volcan_ouvert", "descente_cendre"]],
	[0.82, "give_named", ["parasaurolophus", "Écho", 6]],
	[0.84, "give_named", ["pachyrhinosaurus", "Bosse", 6]],
	[0.90, "level", 42],
	[1.00, "clock", 11],
	[1.02, "dlog", true],
	[1.08, "auto", false],
	[1.20, "weather", &"clear"],
	[1.40, "zone", &"champs_cendres"],
	# The arrival: 1st line (the grey), 2nd (the volcano: the camera goes to the fires, they pulse).
	[5.40, "next", null],
	[6.00, "next", null],
	[8.60, "shot", "c1_camera_vers_les_feux"],
	[9.40, "shot", "c2_sept_feux"],
	[10.20, "shot", "c3_sept_feux_bis"],
	[11.00, "next", null], [11.50, "next", null], [12.50, "next", null], [13.00, "next", null], [14.00, "next", null],
	[14.50, "next", null], [15.50, "next", null], [16.00, "next", null], [17.00, "next", null], [17.50, "next", null],
	[18.50, "next", null], [19.00, "next", null], [19.40, "next", null],
	# Moustique in the collar, close up (Chloé facing us, then from behind).
	[19.50, "calm", 900],
	[19.60, "camera_distance", 3.5],
	[19.70, "face", Vector2(0, 1)],
	[20.50, "static", ["res://story/volcan.gd", "static_col", 6.0]],
	[21.50, "nodes", "MoustiqueCol"],
	[21.60, "shot", "m1_moustique_col_face"],
	[22.00, "face", Vector2(0, -1)],
	[23.00, "shot", "m2_moustique_col_dos"],
	[24.00, "face", Vector2(1, 0)],
	[25.00, "shot", "m3_moustique_col_profil"],
	[27.50, "state", null],
]
