extends RefCounted
## Test scenario: the Cabinet's house in Port-Ambre, by its own door (was removed as if it stood
## in the way of the exit).
const STEPS := [
	[0.8, "calm", 900.0],
	[0.9, "zone", &"port_ambre"],
	[2.6, "tp", Vector2(31.5, 11.5)],
	[3.8, "shot", "maison_cabinet"],
]
