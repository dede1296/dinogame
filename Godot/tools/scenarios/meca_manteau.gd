extends RefCounted
## Chapter 6 mechanics: Chloé in her down coat in the Monts (a cold zone), on foot (still, walking)
## and in the saddle (an Edmontosaurus).
## See tools/capture.gd.

const STEPS := [
	[0.5, "flags", ["monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "forges_vues", "selle"]],
	[0.55, "talk", true], [0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"],
	[0.8, "item", ["manteau_duvet", 1]], [0.9, "give", "edmontosaurus"], [0.95, "level", 20],
	[1.4, "zone", &"monts"], [3.9, "tp", Vector2(32, 72)], [4.0, "calm", 900.0],
	[4.1, "static", ["res://tools/scenarios/meca_pas.gd", "neige", "@player"]],   # (cold, until the zone is rebuilt)
	[5.5, "shot", "k00_manteau_a_pied"], [5.6, "hold", "move_right"], [6.2, "shot", "k01_manteau_marche"], [6.3, "hold", ""],
	[6.5, "press", "ride"], [8.0, "hold", "move_right"], [8.6, "shot", "k02_manteau_selle"], [8.7, "hold", ""],
	[9.0, "hold", "move_down"], [9.5, "shot", "k03_manteau_selle_face"], [9.6, "hold", ""], [9.8, "press", "ride"],
	[10.0, "state", null],
]
