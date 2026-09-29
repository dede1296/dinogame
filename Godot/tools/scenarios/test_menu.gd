extends RefCounted
## Check (29/09): the game menu (☰): its pages (Menu, Sons, Affichage, Retour au titre), the
## volumes per kind of sound (moved, kept, on their bus, each sound routed to its own), the
## return to the title refused during a scene, then done (the game saved, the title screen), and « Continuer » brings the game back.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_menu.gd

const H := "res://tools/scenarios/menu_outils.gd"
const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines"]], [0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.2, "zone", &"plaines"],
	[3.0, "tp", Vector2(40.0, 60.0)], [3.5, "static", [H, "report"]],
	[3.6, "static", [H, "open"]], [4.0, "shot", "m1_menu"],
	[4.1, "static", [H, "page", "sons"]], [4.5, "shot", "m2_sons"],
	[4.6, "static", [H, "slide", 1, 40.0]], [4.7, "static", [H, "slide", 3, 0.0]], [4.8, "static", [H, "slide", 4, 70.0]],
	[5.4, "shot", "m3_sons_regles"], [5.5, "static", [H, "report"]],
	[5.6, "static", [H, "page", "affichage"]], [6.0, "shot", "m4_affichage"],
	[6.1, "static", [H, "page", "titre"]], [6.5, "shot", "m5_titre"],
	[6.6, "press", "cancel"], [6.9, "static", [H, "where"]], [7.0, "press", "cancel"], [7.4, "static", [H, "where"]],
	[7.5, "static", [H, "busy", true]], [7.6, "static", [H, "open"]], [7.7, "static", [H, "page", "titre"]],
	[8.1, "shot", "m6_titre_pendant_scene"], [8.2, "press", "cancel"], [8.3, "press", "cancel"],
	[8.5, "static", [H, "busy", false]],
	[8.6, "static", [H, "open"]], [8.7, "static", [H, "page", "titre"]], [8.9, "static", [H, "press", "Revenir"]],
	[10.5, "shot", "m7_ecran_titre"], [10.6, "static", [H, "where"]], [10.7, "static", [H, "report"]],
	[10.8, "static", [H, "title_continue"]], [13.5, "shot", "m8_repris"], [13.6, "static", [H, "where"]], [13.7, "state", null],
]
