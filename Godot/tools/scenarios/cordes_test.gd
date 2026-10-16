extends RefCounted
## Les cordes des ponts (Ropes) : trois vues rapides, aux Nids géants (le pont de l'aiguille) et aux Pitons
## (le premier pont), de près puis de loin.
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/cordes_test.gd titre="Cordes des ponts : poteaux reliés, de près et de loin"

const VIS := "res://tools/scenarios/vis_cieux.gd"

const STEPS := [
	[0.60, "flags", ["prologue_done", "tuto_commandes", "cieux_ouverts", "vol_obtenu"]], [0.65, "talk", true],
	[0.70, "clock", 11.0], [0.75, "weather", &"clear"],
	[1.00, "static", [VIS, "entrer", "nids_geants", "DepuisCieux"]], [3.50, "weather", &"clear"], [3.60, "calm", 900.0],
	[3.70, "camera_distance", 8.0], [3.80, "tp", Vector2(35.0, 8.0)], [3.90, "face", Vector2(1, 0)], [5.80, "shot", "n0_pont_aiguille_pres"],
	[5.90, "camera_distance", 16.0], [7.90, "shot", "n1_pont_aiguille_loin"],
	[8.00, "static", [VIS, "entrer", "cieux", "DepuisMonts"]], [10.50, "weather", &"clear"], [10.60, "calm", 900.0],
	[10.70, "camera_distance", 8.0], [10.80, "tp", Vector2(66.0, 73.0)], [10.90, "face", Vector2(-1, 0)], [12.90, "shot", "p0_premier_pont_pres"],
	[13.00, "state", null],
]
