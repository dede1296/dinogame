extends RefCounted
## The new sizes: wild dinos next to Chloé — young Tricératops of the Plaines (level 3 and 9),
## big ones of the Forêt (an Allosaurus, a Therizinosaurus, a Velociraptor, levels 16-18) —
## and Griffe-Grise in his ravine. See tools/capture.gd.

const STEPS := [
	[0.8, "calm", 900.0], [0.82, "camera_distance", 12.0], [0.85, "weather", &"clear"], [0.9, "clock", 11.0], [0.95, "level", 14],
	[1.0, "tp", Vector2(56.0, 62.0)], [1.1, "wild", ["triceratops", 3, Vector2(2.4, -0.3)]],
	[1.15, "wild", ["triceratops", 9, Vector2(-3.2, -0.8)]], [2.8, "shot", "w0_plaines_jeunes_tricera"],
	[2.9, "zone", &"foret"], [4.4, "tp", Vector2(118.0, 52.5)], [4.5, "state", null],
	[4.6, "wild", ["allosaurus", 16, Vector2(-3.4, -0.6)]], [4.65, "wild", ["therizinosaurus", 18, Vector2(3.6, -0.4)]],
	[4.7, "wild", ["velociraptor", 16, Vector2(1.4, 1.0)]], [4.75, "calm", 900.0], [6.4, "shot", "w1_foret_grands"],
	[6.5, "camera_distance", 17.0], [7.9, "shot", "w2_foret_grands_loin"], [8.0, "camera_distance", 12.0],
	[8.1, "tp", Vector2(24.0, 80.6)], [9.6, "shot", "w3_griffe_grise"],
	# Standing still, standing up (idle pictures: never lying down, 28/09): an Oviraptor, a
	# Spinosaurus, a Corythosaurus, a Triceratops, over a few seconds.
	[9.7, "tp", Vector2(118.0, 52.5)], [9.8, "wild", ["oviraptor", 18, Vector2(-1.6, 0.6)]],
	[9.85, "wild", ["spinosaurus", 22, Vector2(3.6, -0.6)]], [9.9, "wild", ["corythosaurus", 18, Vector2(-4.2, -0.8)]],
	[9.95, "calm", 900.0], [11.4, "shot", "w4_attente_a"], [12.6, "shot", "w5_attente_b"], [13.8, "shot", "w6_attente_c"],
]
