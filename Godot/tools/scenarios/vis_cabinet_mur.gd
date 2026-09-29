extends RefCounted
## Visual check only (29/09): the Cabinet's back wall and what stands against it (the shelf, the
## lantern on its hook, the kettle), for clipping. No scene played.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_cabinet_mur.gd

const STEPS := [
	[0.8, "flags", ["sceau_plaines", "maia_defi_1", "havre_arrive"]],
	[1.0, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "vsync", false], [1.2, "zone", &"cabinet"],
	[3.4, "tp", Vector2(9.9, 3.2)], [3.5, "face", Vector2(0, -1)], [4.3, "shot", "cm_1_lanterne"],
	[4.5, "tp", Vector2(3.3, 3.4)], [4.6, "face", Vector2(0, -1)], [5.4, "shot", "cm_2_etagere"],
	[5.6, "tp", Vector2(2.6, 4.6)], [5.7, "face", Vector2(0, -1)], [6.5, "shot", "cm_3_bouilloire"],
	[6.7, "state", null],
]
