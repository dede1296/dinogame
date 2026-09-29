extends RefCounted
## Visual check (29/09): every door set in a rock face, seen from in front (its facing vs the
## camera, which looks north): Plaines amber door and Grand Crâne, Marais amber door and temple
## door, Désert wind door and the Rempart's rubble, the Forêt's cracked wall, the Monts' frost door.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/vis_portes.gd

const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "maia_defi_1", "marais_arrivee", "desert_arrivee", "foret_arrivee", "monts_arrivee"]],
	[0.9, "calm", 900.0], [0.9, "talk", true], [1.0, "clock", 11.0], [1.0, "vsync", false],
	[1.2, "zone", &"plaines"], [3.2, "wait_idle", [1, 40]], [3.4, "weather", &"clear"],
	[3.5, "tp", Vector2(93.0, 41.0)], [3.6, "face", Vector2(0, -1)], [4.4, "shot", "po_1_plaines_ambre"],
	[4.6, "tp", Vector2(104.0, 65.0)], [4.7, "face", Vector2(0, -1)], [5.5, "shot", "po_2_plaines_crane"],
	[5.8, "zone", &"marais"], [7.8, "wait_idle", [1, 40]], [8.0, "weather", &"clear"],
	[8.1, "tp", Vector2(56.0, 45.0)], [8.2, "face", Vector2(0, -1)], [9.0, "shot", "po_3_marais_ambre"],
	[9.2, "tp", Vector2(30.0, 14.5)], [9.3, "face", Vector2(0, -1)], [10.1, "shot", "po_4_marais_temple"],
	[10.4, "zone", &"desert"], [12.4, "wait_idle", [1, 40]], [12.6, "weather", &"clear"],
	[12.7, "tp", Vector2(60.5, 6.0)], [12.8, "face", Vector2(0, -1)], [13.6, "shot", "po_5_desert_vents"],
	[13.8, "tp", Vector2(28.5, 61.5)], [13.9, "face", Vector2(0, -1)], [14.7, "shot", "po_6_desert_rempart"],
	[15.0, "zone", &"foret"], [17.0, "wait_idle", [1, 40]], [17.2, "weather", &"clear"],
	[17.3, "tp", Vector2(12.0, 43.5)], [17.4, "face", Vector2(0, -1)], [18.2, "shot", "po_7_foret_mur"],
	[18.5, "zone", &"monts"], [20.5, "wait_idle", [1, 40]], [20.7, "weather", &"clear"],
	[20.8, "tp", Vector2(114.5, 10.0)], [20.9, "face", Vector2(0, -1)], [21.7, "shot", "po_8_monts_givre"],
	[22.0, "state", null],
]
