extends RefCounted
## Check (30/09): the two zones that failed to load in the exported game (their built scenes
## pointed at a script under tools/, which the exports leave out) — the Cabinet, entered through
## Roc's door from Port-Ambre, and Havre-Doré.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_zones_portes.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "prologue_done"]],
	[0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "no_help", null], [1.2, "zone", &"port_ambre"],
	# through Roc's door, on foot, as a player does
	[3.4, "tp", Vector2(31.5, 9.9)], [3.6, "hold", "move_up"], [5.0, "hold", ""],
	[8.0, "shot", "z1_cabinet"], [8.4, "where", "dans_le_cabinet"],
	# Havre-Doré
	[8.8, "zone", &"havre_dore"], [11.4, "shot", "z2_havre"], [11.8, "where", "au_havre"],
	[12.2, "state", null],
]
