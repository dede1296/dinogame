extends RefCounted
## Chapter 6 mechanics: the ice caves' walls (darker ice, their tops shaded) against the floor, in
## the first hall and its way north. See tools/capture.gd.

const STEPS := [
	[0.5, "flags", ["monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "forges_vues", "grottes_glace_arrivee", "suie_monts_vue"]],
	[0.55, "talk", true], [0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"], [1.4, "zone", &"grottes_glace"],
	[3.6, "calm", 900.0], [3.9, "weather", &"clear"], [4.0, "tp", Vector2(21.5, 19.5)], [4.1, "calm", 900.0], [6.5, "shot", "g00_salle_nord"],
	[6.6, "tp", Vector2(7, 26)], [6.7, "calm", 900.0], [8.5, "shot", "g01_salle_ouest"], [8.6, "state", null],
]
