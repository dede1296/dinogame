extends RefCounted
## A tour of the big scenery in real 3D (tools/modeles3d/volumes*.py), fair weather, late
## afternoon: Port-Ambre's houses and Cabinet, the Plaines' and Forêt's rocks, the Marais' hut
## and statue, the Désert's bones, canyon rocks and arch. Each seen from the front, then aside.

const STEPS := [
	[0.75, "flags", ["prologue_done", "desert_arrivee", "marais_arrivee", "foret_arrivee", "havre_arrive"]], [0.78, "talk", true], [0.8, "calm", 900.0], [0.85, "clock", 16.0], [0.9, "weather", &"clear"], [0.95, "quality", 2],
	[1.0, "zone", &"port_ambre"], [2.4, "weather", &"clear"], [2.5, "tp_prop", ["maison_blanche", Vector2(60, 130)]],
	[2.6, "camera_distance", 18.0], [4.0, "shot", "t01_port_maisons"],
	[4.1, "tp_prop", ["maison_blanche", Vector2(210, 30)]], [5.6, "shot", "t02_port_de_cote"],
	[5.7, "tp_prop", ["cabinet", Vector2(-40, 150)]], [7.2, "shot", "t03_port_cabinet"],
	[7.3, "zone", &"plaines"], [8.7, "weather", &"clear"], [8.8, "tp_prop", ["rocher", Vector2(90, 90)]],
	[8.9, "camera_distance", 14.0], [10.4, "shot", "t04_plaines_rocher"],
	[10.5, "zone", &"foret"], [11.9, "weather", &"clear"], [12.0, "tp_prop", ["rocher_mousse", Vector2(90, 90)]],
	[13.5, "shot", "t05_foret_rocher_mousse"],
	[13.6, "zone", &"marais"], [15.0, "weather", &"clear"], [15.1, "tp_prop", ["cabane_pilotis", Vector2(80, 130)]],
	[15.2, "camera_distance", 16.0], [16.7, "shot", "t06_marais_cabane"],
	[16.8, "tp_prop", ["statue_dino", Vector2(90, 90)]], [18.3, "shot", "t07_marais_statue"],
	[18.4, "zone", &"desert"], [19.8, "weather", &"clear"], [19.9, "tp_prop", ["squelette_geant", Vector2(60, 170)]],
	[20.0, "camera_distance", 20.0], [21.5, "shot", "t08_desert_squelette"],
	[21.6, "tp_prop", ["crane_geant_desert", Vector2(120, 120)]], [23.1, "shot", "t09_desert_crane"],
	[23.2, "tp_prop", ["arche_rocheuse", Vector2(60, 160)]], [24.7, "shot", "t10_desert_arche"],
	[24.8, "tp_prop", ["rocher_canyon", Vector2(100, 110)]], [26.3, "shot", "t11_desert_canyon"],
	[26.4, "tp_prop", ["os_geant", Vector2(90, 110)]], [27.9, "shot", "t12_desert_os"],
]
