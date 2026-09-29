extends RefCounted
## The big scenery in real 3D (tools/modeles3d/volumes*.py): each one from the front, from
## the side (its gable, its flank) and at dusk. Port-Ambre's white house, Havre-Doré's shop.

const STEPS := [
	[0.8, "calm", 600.0], [0.85, "clock", 11.0], [0.9, "weather", &"clear"], [0.95, "quality", 2],
	[1.0, "zone", &"port_ambre"], [2.5, "tp", Vector2(6.5, 11.2)], [2.6, "camera_distance", 18.0], [4.0, "shot", "v0_port_face"],
	[4.1, "tp", Vector2(12.5, 9.0)], [5.6, "shot", "v1_port_cote"],
	[5.7, "clock", 18.7], [7.2, "shot", "v2_port_soir"], [7.3, "clock", 11.0],
	[7.4, "reliefs", false], [8.9, "shot", "v3_port_images"], [9.0, "reliefs", true],
	[9.1, "zone", &"havre_dore"], [10.6, "tp", Vector2(13.5, 10.8)], [10.7, "camera_distance", 18.0], [12.2, "shot", "v4_havre_mercerie"],
	[12.3, "state", null],
]
