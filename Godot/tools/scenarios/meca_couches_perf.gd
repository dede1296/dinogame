extends RefCounted
## Chapter 6 mechanics: what the cover layers cost (1, then 3 layers; medium and high graphics;
## the Monts' west edge), vsync off. See tools/capture.gd and meca_couche.gd.

const HERE := "res://tools/scenarios/meca_couche.gd"
const STEPS := [
	[0.5, "flags", ["monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "forges_vues"]], [0.55, "talk", true],
	[0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"], [1.4, "zone", &"monts"], [3.6, "calm", 900.0],
	[3.9, "weather", &"clear"], [4.0, "tp", Vector2(14, 30)], [4.1, "calm", 900.0], [4.2, "quality", 1], [4.3, "vsync", false],
	[7.5, "perf", "MOYENNE 1 couche"], [7.6, "static", [HERE, "trois", "@player"]], [11.0, "perf", "MOYENNE 3 couches"],
	[11.1, "shot", "c05_trois_couches"], [11.2, "static", [HERE, "une", "@player"]], [14.5, "perf", "MOYENNE 1 couche (bis)"],
	[14.6, "quality", 2], [14.7, "vsync", false], [18.0, "perf", "HAUTE 1 couche"], [18.1, "static", [HERE, "trois", "@player"]],
	[21.5, "perf", "HAUTE 3 couches"], [21.6, "static", [HERE, "une", "@player"]], [25.0, "perf", "HAUTE 1 couche (bis)"],
	[25.1, "quality", 1], [25.2, "state", null],
]
