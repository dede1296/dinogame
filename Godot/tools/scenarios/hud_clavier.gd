extends RefCounted
## The battle HUD with the keyboard: the arrows turn around the wheel, Entrée opens, Échap goes
## back. See tools/capture.gd.

const STEPS := [
	[1.0, "tp", Vector2(60.0, 62.0)], [1.05, "hurt", [0, 11]], [1.2, "battle", [&"protoceratops", 3]],
	[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"], [6.2, "shot", "k0_roue"],
	[6.3, "press", "ui_left"], [6.5, "press", "ui_left"], [6.8, "shot", "k1_focus_sac"],
	[6.9, "press", "ui_accept"], [7.4, "shot", "k2_sac_ouvert"],
	[7.5, "press", "cancel"], [8.0, "shot", "k3_retour_roue"],
	[8.1, "press", "ui_accept"], [8.6, "shot", "k4_attaques"], [8.7, "press", "ui_right"], [9.0, "shot", "k5_focus_griffes"],
]
