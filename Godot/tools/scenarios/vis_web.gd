extends RefCounted
## Check (30/09): the game as the browser gets it — no 3D building models at all (they weighed
## 416 Mo of textures), the houses drawn as pictures. Port-Ambre, chez Roc, and Havre-Doré.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_web.gd

const H := "res://tools/scenarios/web_outils.gd"
const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "prologue_done"]],
	[0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "no_help", null],
	[1.15, "static", [H, "as_web"]], [1.2, "zone", &"port_ambre"],
	[3.4, "static", [H, "models"]], [3.6, "tp", Vector2(31.5, 11.5)], [3.8, "face", Vector2(0, -1)],
	[4.6, "shot", "w1_port_ambre"],
	# through Roc's door
	[5.0, "tp", Vector2(31.5, 9.9)], [5.2, "hold", "move_up"], [6.6, "hold", ""],
	[9.4, "shot", "w2_cabinet"], [9.6, "where", "dans_le_cabinet"],
	# Havre-Doré, the zone with the most models
	[10.0, "zone", &"havre_dore"], [12.4, "static", [H, "models"]],
	[12.6, "tp", Vector2(24.0, 13.0)], [12.8, "face", Vector2(0, -1)], [13.6, "shot", "w3_havre"],
	[14.0, "state", null],
]
