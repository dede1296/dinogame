extends RefCounted
## L'intro en TEMPS RÉEL, sans rien accélérer ni toucher : ses deux premiers plans (I-01, I-02) restent-ils
## assez longtemps à l'écran pour qu'un enfant lise la phrase ? (ui/cinematic.gd : chaque phrase reste
## entière au moins 0,45 s par mot, 3 s au moins ; I-01, 12 mots, 7 s prévues → 8,4 s ; I-02, 11 mots →
## 7,65 s). La ligne « static debug_timeline » donne la durée de chaque plan à l'horloge murale et à
## celle du film. Aucune capture pendant la mesure : une capture fige le jeu ~0,65 s (le plan dure alors
## d'autant plus) ; les images sont prises après, en revenant sur les deux plans.
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/cinematiques_temps_reel.gd titre="Intro en temps réel : durée à l'écran des plans I-01 et I-02 (temps de lecture)"

const C := "res://story/cinematiques.gd"

const STEPS := [
	[0.80, "flags", ["tuto_commandes"]],
	[2.00, "static", [C, "debug_play", "intro", 0]],
	[19.0, "static", [C, "debug_timeline"]],
	[19.1, "static", [C, "debug_seek", 0]],
	[22.0, "shot", "tr1_i01_phrase_entiere"],
	[22.1, "static", [C, "debug_seek", 1]],
	[25.0, "shot", "tr2_i02_phrase_entiere"],
	[25.1, "static", [C, "debug_press", "skip"]],
	[25.2, "static", [C, "debug_press", "skip"]],
]
