extends RefCounted
## Chapter 6 mechanics: what is heard in the Monts in a blizzard (the ambience, the blizzard's
## howl), and in the frost sanctuary. See tools/capture.gd.

const STEPS := [
	[0.5, "flags", ["monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "forges_vues"]], [0.55, "talk", true],
	[0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"], [1.4, "zone", &"monts"],
	[3.9, "tp", Vector2(32, 72)], [4.0, "weather", &"blizzard"], [9.0, "audio", null],
	[9.5, "zone", &"sanctuaire_givre"], [14.0, "audio", null], [14.1, "state", null],
]
