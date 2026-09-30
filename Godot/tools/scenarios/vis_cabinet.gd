extends RefCounted
## Check (30/09): the Cabinet's inside shows when Chloé goes in — reported as black on mobile at
## the very start of the game, the scene playing with its lines but nothing to see or touch.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_cabinet.gd

const STEPS := [
	[0.8, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "no_help", null],
	# the graphics level a phone picks: Basse, then Moyenne, then Haute
	[1.2, "quality", 0], [1.4, "zone", &"cabinet"], [4.0, "shot", "c1_basse"],
	[4.4, "quality", 1], [4.6, "zone", &"port_ambre"], [6.0, "zone", &"cabinet"], [8.0, "shot", "c2_moyenne"],
	[8.4, "quality", 2], [8.6, "zone", &"port_ambre"], [10.0, "zone", &"cabinet"], [12.0, "shot", "c3_haute"],
	[12.4, "state", null],
]
