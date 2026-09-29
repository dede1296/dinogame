extends RefCounted
## Chapter 6 mechanics in the Monts: the ground and walls (snow, ice, snowy rock), the weather
## (fine, snow, blizzard; day and night), a battle in the blizzard, and the frame rate without
## vsync (fine / snow / blizzard, medium and high graphics). See tools/capture.gd.

const VALLEE := Vector2(32, 72)
const GLACIER := Vector2(46, 34)
const STEPS := [
	[0.5, "flags", ["monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee"]], [0.55, "talk", true],
	[0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"], [1.4, "zone", &"monts"],
	[3.9, "weather", &"clear"], [4.0, "tp", VALLEE], [4.1, "calm", 900.0], [4.2, "quality", 1], [4.3, "vsync", false],
	[8.0, "shot", "m00_vallee_clair"], [8.1, "perf", "MONTS MOYENNE clair"],
	[8.2, "weather", &"snow"], [14.2, "shot", "m01_vallee_neige"], [14.3, "perf", "MONTS MOYENNE neige"],
	[14.4, "weather", &"blizzard"], [20.4, "shot", "m02_vallee_blizzard"], [20.5, "perf", "MONTS MOYENNE blizzard"],
	[20.6, "quality", 2], [20.7, "vsync", false], [24.0, "perf", "MONTS HAUTE blizzard"],
	[24.1, "weather", &"snow"], [30.1, "perf", "MONTS HAUTE neige"], [30.2, "weather", &"clear"], [36.2, "perf", "MONTS HAUTE clair"],
	[36.3, "quality", 1], [36.4, "clock", 11.0],
	[36.5, "tp", GLACIER], [36.6, "calm", 900.0], [39.5, "shot", "m03_glacier_clair"],
	[39.6, "weather", &"snow"], [45.6, "shot", "m04_glacier_neige"],
	[45.7, "clock", 22.5], [45.8, "weather", &"snow"], [51.8, "shot", "m05_glacier_neige_nuit"],
	[51.9, "weather", &"blizzard"], [57.9, "shot", "m06_glacier_blizzard_nuit"],
	[58.0, "clock", 11.0], [58.1, "weather", &"blizzard"], [59.0, "fight", "nanuqsaurus"], [62.2, "shot", "m07_combat_blizzard"],
	[62.3, "auto", true], [80.0, "auto", false], [80.5, "state", null],
]
