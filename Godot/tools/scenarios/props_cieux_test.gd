extends RefCounted
## Les nouveaux décors du chapitre 7 : le vieux harnais (Nids), le masque d'obsidienne (Arche, après
## sa chute) et les bouffées de nuage bas (Pitons).
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/props_cieux_test.gd titre="Décors des Cieux : harnais, masque, nuages bas"

const VIS := "res://tools/scenarios/vis_cieux.gd"

const STEPS := [
	[0.60, "flags", ["prologue_done", "tuto_commandes", "cieux_ouverts", "vol_obtenu", "masque_tombe"]], [0.65, "talk", true],
	[0.70, "clock", 11.0], [0.75, "weather", &"clear"],
	[1.00, "static", [VIS, "entrer", "nids_geants", "DepuisCieux"]], [3.50, "weather", &"clear"], [3.60, "calm", 900.0],
	[3.70, "camera_distance", 9.0], [3.80, "tp", Vector2(25.6, 12.5)], [3.90, "face", Vector2(0, -1)], [5.80, "shot", "h0_vieux_harnais"],
	[6.00, "static", [VIS, "entrer", "arche_du_vent", "DepuisNids"]], [8.50, "weather", &"clear"], [8.60, "calm", 900.0],
	[8.70, "tp", Vector2(27.0, 24.5)], [8.80, "face", Vector2(0, -1)], [10.80, "shot", "m0_masque_obsidienne"],
	[11.00, "static", [VIS, "entrer", "cieux", "DepuisMonts"]], [13.50, "weather", &"clear"], [13.60, "calm", 900.0],
	[13.70, "camera_distance", 14.0], [13.80, "tp", Vector2(52.0, 73.0)], [13.90, "face", Vector2(0, -1)], [15.90, "shot", "c0_nuages_bas"],
	[16.00, "state", null],
]
