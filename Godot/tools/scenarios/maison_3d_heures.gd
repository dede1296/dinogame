extends RefCounted
## Le Clos Blanc's 3D cottage through the day (same spot): dawn, noon, dusk, night, rain.

const STEPS := [
	[0.8, "calm", 300.0], [0.85, "clock", 6.3], [0.9, "weather", &"clear"], [1.0, "zone", &"clos_blanc"],
	[2.5, "tp", Vector2(17.0, 11.6)], [2.6, "camera_distance", 24.0], [4.0, "shot", "h1_aube"],
	[4.1, "clock", 12.5], [5.6, "shot", "h2_midi"],
	[5.7, "clock", 18.6], [7.2, "shot", "h3_crepuscule"],
	[7.3, "clock", 22.5], [8.8, "shot", "h4_nuit"],
	[8.9, "clock", 15.0], [9.0, "weather", &"rain"], [11.5, "shot", "h5_pluie"],
]
