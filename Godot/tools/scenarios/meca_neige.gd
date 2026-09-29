extends RefCounted
## Chapter 6 mechanics: snow and the blizzard seen in the world (day, night), the badge, battles,
## and their frame rate without vsync next to fine weather and the sandstorm (same spot, same
## graphics level). In the Plaines' carrefour (the Monts are not built yet). See tools/capture.gd.

const SPOT := Vector2(60, 47)
const STEPS := [
	[0.5, "flags", ["selle", "sceau_plaines", "maia_defi_1", "havre_arrive"]], [0.6, "calm", 900.0],
	[0.6, "clock", 11.0], [0.7, "weather", &"clear"], [0.9, "vsync", false], [1.4, "zone", &"plaines"],
	[3.9, "weather", &"clear"], [4.0, "quality", 2], [4.1, "vsync", false], [4.2, "tp", SPOT],
	[7.2, "perf", "HAUTE clair"], [7.3, "shot", "n00_clair"],
	[7.4, "weather", &"snow"], [13.4, "shot", "n01_neige_jour"], [13.5, "perf", "HAUTE neige"], [16.5, "perf", "HAUTE neige 2"],
	[16.6, "weather", &"blizzard"], [22.6, "shot", "n02_blizzard_jour"], [22.7, "perf", "HAUTE blizzard"],
	[23.4, "shot", "n02b_blizzard_rafale"], [25.7, "perf", "HAUTE blizzard 2"],
	[25.8, "weather", &"sandstorm"], [31.8, "shot", "n03_sable"], [31.9, "perf", "HAUTE sable"], [34.9, "perf", "HAUTE sable 2"],
	[35.0, "clock", 11.0], [35.1, "quality", 1], [35.2, "vsync", false], [35.3, "weather", &"clear"],
	[41.3, "perf", "MOYENNE clair"], [41.4, "weather", &"snow"], [47.4, "perf", "MOYENNE neige"],
	[47.5, "weather", &"blizzard"], [53.5, "perf", "MOYENNE blizzard"],
	[53.6, "clock", 11.0], [53.7, "weather", &"sandstorm"], [59.7, "perf", "MOYENNE sable"],
	[59.8, "quality", 0], [59.9, "vsync", false], [60.0, "weather", &"clear"], [66.0, "perf", "BASSE clair"],
	[66.1, "weather", &"snow"], [72.1, "perf", "BASSE neige"], [72.2, "clock", 11.0], [72.3, "weather", &"blizzard"],
	[78.3, "perf", "BASSE blizzard"], [78.4, "weather", &"sandstorm"], [84.4, "perf", "BASSE sable"],
	[84.5, "quality", 2], [84.6, "vsync", false],
	[84.7, "clock", 22.5], [84.8, "weather", &"snow"], [90.8, "shot", "n04_neige_nuit"],
	[90.9, "weather", &"blizzard"], [96.9, "shot", "n05_blizzard_nuit"],
	[97.0, "clock", 11.0], [97.1, "weather", &"snow"], [98.0, "fight", "protoceratops"], [101.2, "shot", "n06_combat_neige"],
	[101.3, "auto", true], [115.0, "auto", false], [115.5, "calm", 900.0],
	[115.6, "weather", &"blizzard"], [116.0, "fight", "protoceratops"], [119.2, "shot", "n07_combat_blizzard"],
	[119.3, "auto", true], [133.0, "auto", false], [133.5, "state", null],
]
