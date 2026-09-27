extends RefCounted
## ANIM-1's check: is the Cabinet's house drawn in Port-Ambre? See tools/capture.gd.

const STEPS := [
	[0.85, "calm", 900.0],
	[0.9, "zone", &"port_ambre"],
	[2.5, "tp", Vector2(31.5, 10.6)],
	[3.8, "shot", "vc_0"],
	[4.0, "tp", Vector2(26.0, 10.6)],
	[5.3, "shot", "vc_1"],
	[5.4, "state", null],
]
