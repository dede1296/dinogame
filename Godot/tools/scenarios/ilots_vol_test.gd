extends RefCounted
## Les trouvailles des îlots des Cieux (atteints seulement en vol) : le balcon (coffre et fougère), le nid de l'aiguille (collier).
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/ilots_vol_test.gd titre="Îlots des Cieux : trouvailles à ramasser"

const VIS := "res://tools/scenarios/vis_cieux.gd"

const STEPS := [
	[0.60, "flags", ["prologue_done", "tuto_commandes", "cieux_ouverts", "vol_obtenu"]], [0.65, "talk", true],
	[0.70, "clock", 11.0], [0.75, "weather", &"clear"],
	[1.00, "static", [VIS, "entrer", "cieux", "DepuisMonts"]], [3.50, "weather", &"clear"], [3.60, "calm", 900.0],
	[3.70, "camera_distance", 9.0], [3.80, "tp", Vector2(18.0, 39.5)], [3.90, "face", Vector2(0, -1)], [5.80, "shot", "i0_balcon"],
	[5.90, "tp", Vector2(93.0, 37.5)], [6.00, "face", Vector2(0, -1)], [7.90, "shot", "i1_nid_aiguille"],
	[8.00, "state", null],
]
