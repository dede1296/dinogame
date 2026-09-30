extends RefCounted
## Visual check (30/09): Élise Sablier the botanist, her sick Triceratops and the dung pile she
## is digging in, up to her elbows (a wink at a famous dinosaur film), in the Prairie.
## No « auto »: the lines are stepped through with the interact button.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_elise.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "met_maia"]],
	[0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "dlog", true], [1.12, "no_help", null],
	[1.2, "zone", &"plaines"],
	[3.4, "tp", Vector2(79.6, 58.0)], [3.6, "face", Vector2(0, -1)], [4.4, "shot", "e1_le_pre"],
	[4.8, "tp", Vector2(79.1, 57.4)], [5.0, "face", Vector2(0, -1)], [5.6, "interact_now", null],
	[6.8, "shot", "e2_le_triceratops"],
	[7.40, "press", "interact"],
	[8.50, "press", "interact"],
	[9.60, "press", "interact"],
	[10.70, "press", "interact"],
	[12.4, "shot", "e3_la_pile"],
	[13.00, "press", "interact"],
	[14.10, "press", "interact"],
	[15.20, "press", "interact"],
	[16.30, "press", "interact"],
	[18.0, "shot", "e4_elise"],
	[18.60, "press", "interact"],
	[19.70, "press", "interact"],
	[20.80, "press", "interact"],
	[21.90, "press", "interact"],
	[23.6, "shot", "e5_un_livre_ouvert"],
	[24.20, "press", "interact"],
	[25.30, "press", "interact"],
	[26.40, "press", "interact"],
	[27.50, "press", "interact"],
	[29.2, "shot", "e6_la_feuille"],
	[29.80, "press", "interact"],
	[30.90, "press", "interact"],
	[32.00, "press", "interact"],
	[33.10, "press", "interact"],
	[34.8, "shot", "e7_fin"], [35.4, "state", null],
]
