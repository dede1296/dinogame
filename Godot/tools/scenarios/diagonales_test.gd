extends RefCounted
## Les trois-quarts de Chloé (19/10, docs/sprites-mouvements.md § Trois-quarts de Chloé) : sur la prairie
## dégagée de test_vitesses.gd (zone « plaines », 40 x 60), elle marche en diagonale dans les 4 sens (deux touches tenues), puis s'arrête ;
## une touche lâchée un peu avant l'autre, comme au clavier : elle doit rester de trois-quarts. En haut à
## droite en courant, puis en bottes (chloe_bottes_diag.png). « vis » écrit l'animation jouée en 3D :
## walk_down_left… avec les planches _diag, walk_down / walk_left… (l'axe dominant) sans elles.
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/diagonales_test.gd titre="Trois-quarts de Chloé : marche et arrêt en diagonale, 4 sens, en bottes"

const AT := Vector2(40.0, 60.0)   # (cases)

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines"]], [0.9, "calm", 900.0], [1.0, "clock", 11], [1.1, "weather", &"clear"],
	[1.2, "zone", &"plaines"],
	[3.4, "calm", 900.0], [3.5, "weather", &"clear"], [3.6, "camera_distance", 6.0],
	# Vers le bas à gauche (trois-quarts face).
	[4.0, "tp", AT], [4.2, "hold", "move_down"], [4.2, "hold_also", ["move_left", true]],
	[5.0, "shot", "a1_bas_gauche_marche"], [5.0, "vis", null],
	[5.2, "hold_also", ["move_left", false]], [5.24, "hold", ""],   # (une touche lâchée avant l'autre)
	[5.9, "shot", "a2_bas_gauche_arret"], [5.9, "vis", null],
	# Vers le bas à droite (le miroir du bas à gauche).
	[6.2, "tp", AT], [6.4, "hold", "move_down"], [6.4, "hold_also", ["move_right", true]],
	[7.2, "shot", "b1_bas_droite_marche"], [7.2, "vis", null],
	[7.4, "hold", ""], [7.44, "hold_also", ["move_right", false]],
	[8.1, "shot", "b2_bas_droite_arret"], [8.1, "vis", null],
	# Vers le haut à gauche (trois-quarts dos).
	[8.4, "tp", AT + Vector2(0.0, 3.0)], [8.6, "hold", "move_up"], [8.6, "hold_also", ["move_left", true]],
	[9.4, "shot", "c1_haut_gauche_marche"], [9.4, "vis", null],
	[9.6, "hold_also", ["move_left", false]], [9.64, "hold", ""],
	[10.3, "shot", "c2_haut_gauche_arret"], [10.3, "vis", null],
	# Vers le haut à droite, en courant (Maj tenue).
	[10.6, "tp", AT + Vector2(0.0, 3.0)], [10.7, "hold_also", ["run", true]],
	[10.8, "hold", "move_up"], [10.8, "hold_also", ["move_right", true]],
	[11.5, "shot", "d1_haut_droite_course"], [11.5, "vis", null],
	[11.7, "hold", ""], [11.74, "hold_also", ["move_right", false]], [11.74, "hold_also", ["run", false]],
	[12.4, "shot", "d2_haut_droite_arret"], [12.4, "vis", null],
	# En bottes (les bottes de Rosalie) : bas à droite, puis haut à gauche.
	[12.6, "item", ["bottes", 1]],
	[12.8, "tp", AT], [13.0, "hold", "move_down"], [13.0, "hold_also", ["move_right", true]],
	[13.8, "shot", "e1_bottes_bas_droite_marche"], [13.8, "vis", null],
	[14.0, "hold", ""], [14.0, "hold_also", ["move_right", false]],
	[14.4, "tp", AT + Vector2(0.0, 3.0)], [14.6, "hold", "move_up"], [14.6, "hold_also", ["move_left", true]],
	[15.4, "shot", "e2_bottes_haut_gauche_marche"], [15.4, "vis", null],
	[15.6, "hold_also", ["move_left", false]], [15.64, "hold", ""],
	[16.3, "shot", "e3_bottes_haut_gauche_arret"], [16.3, "vis", null],
	[16.5, "state", null],
]
