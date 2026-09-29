extends RefCounted
## Check (29/09): the Grand Voyageur in the game — it stands on the ground beside Chloé at the
## Prairie's stop, the first meeting plays with the dino on screen, then a real ride to
## Havre-Doré (the sky and the clock move on, Chloé lands at its « Voyageur » spawn).
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_voyage_jeu.gd

const H := "res://tools/scenarios/voyage_outils.gd"
const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "met_maia", "havre_arrive"]], [0.9, "calm", 900.0],
	[1.0, "clock", 11.0], [1.1, "talk", true], [1.2, "zone", &"plaines"],
	# beside it: does it stand on the ground?
	[3.0, "tp", Vector2(56.4, 47.4)], [3.2, "face", Vector2(-1, 0)], [4.0, "shot", "g1_au_pied"],
	[4.2, "tp", Vector2(54.0, 52.0)], [4.4, "face", Vector2(0, -1)], [5.2, "shot", "g2_de_face"],
	# the meeting, with the dino on screen
	[5.4, "tp", Vector2(56.4, 47.4)], [5.6, "static", [H, "talk"]],
	[6.6, "shot", "g3_penche"], [8.4, "shot", "g4_renifle"], [10.6, "shot", "g5_atchoum"],
	[13.6, "shot", "g6_agenouille"], [16.5, "static", [H, "report"]],
	# a real ride: the Prairie → Havre-Doré
	[16.8, "static", [H, "know", ["havre_dore"]]], [17.2, "static", [H, "talk"]],
	[18.2, "static", [H, "rows"]], [18.6, "shot", "g7_ecran"],
	[18.8, "static", [H, "press", "Havre"]], [20.0, "shot", "g8_grimpe"], [22.5, "shot", "g9_en_route"],
	[26.0, "shot", "g10_arrivee"], [26.4, "static", [H, "report"]],
	[27.0, "state", null],
]
