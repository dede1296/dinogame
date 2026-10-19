extends RefCounted
## Les cinématiques et les crédits (story/cinematiques.gd, ui/cinematic.gd, ui/credits.gd), vus : quelques
## plans de l'intro (les peintures manquantes : fond uni et la phrase dans son bandeau), « Passer » allumé
## au premier appui et passé au second (retour au jeu), F-06 selon le dino de départ (Vif), puis les
## crédits depuis le menu : le carton d'ouverture, le défilé, la pause, la nuit tombée, « Pour Chloé »,
## « Merci d'avoir joué », et le retour.
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/cinematiques_test.gd titre="Cinématiques : intro (fond uni si la peinture manque), Passer, F-06 selon le dino de départ, crédits (ouverture, défilé, pause, Pour Chloé)"

const C := "res://story/cinematiques.gd"

const STEPS := [
	[0.80, "flags", ["tuto_commandes"]],
	[2.00, "static", [C, "debug_play", "intro", 0]],
	[5.00, "shot", "i01_au_large"],
	[5.10, "static", [C, "debug_press", "skip"]],
	[5.50, "shot", "i01_passer_allume_au_premier_appui"],
	[7.80, "static", [C, "debug_seek", 2]],
	[9.20, "shot", "i03_cabinet"],
	[9.30, "static", [C, "debug_seek", 4]],
	[12.0, "shot", "i05_carte"],
	[12.1, "static", [C, "debug_seek", 6]],
	[13.5, "shot", "i07_ponton"],
	[13.6, "static", [C, "debug_seek", 9]],
	[15.0, "shot", "i10_carton_ambrelune"],
	[15.1, "static", [C, "debug_press", "skip"]],
	[15.2, "static", [C, "debug_press", "skip"]],
	[17.0, "shot", "i11_passee_retour_au_jeu"],
	[17.2, "static", [C, "debug_play", "fin", 5]],
	[19.6, "shot", "f06_vif_a_l_etang"],
	[19.7, "static", [C, "debug_press", "skip"]],
	[19.8, "static", [C, "debug_press", "skip"]],
	[21.5, "static", [C, "debug_play", "credits", 0]],
	[24.5, "shot", "c01_carton_d_ouverture"],
	[24.6, "static", [C, "debug_forward", 25.0]],
	[25.4, "shot", "c02_defile"],
	[25.5, "static", [C, "debug_press", "next"]],
	[26.0, "shot", "c03_en_pause"],
	[26.1, "static", [C, "debug_press", "next"]],
	[26.2, "static", [C, "debug_forward", 46.0]],
	[27.0, "shot", "c04_la_nuit_tombee"],
	[27.1, "static", [C, "debug_forward", 10.0]],
	[27.9, "shot", "c05_pour_chloe"],
	[28.0, "static", [C, "debug_forward", 4.5]],
	[28.8, "shot", "c06_merci_d_avoir_joue"],
	[28.9, "static", [C, "debug_press", "skip"]],
	[29.0, "static", [C, "debug_press", "skip"]],
	[30.8, "shot", "c07_retour_au_jeu"],
]
