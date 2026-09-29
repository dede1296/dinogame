extends RefCounted
## Free play in Le Clos Blanc, the test zone of the Blender + ComfyUI cottage
## (tools/lancer-maison-3d.cmd). The tool's own save file, never the player's.
## The last step is far away: the window stays open until it is closed.

const STEPS := [
	[0.85, "clock", 10.0], [0.9, "weather", &"clear"], [1.0, "zone", &"clos_blanc"],
	[2.5, "banner", "Le Clos Blanc · maison modelée dans Blender, peinte par ComfyUI"], [8.0, "banner", ""],
	[86400.0, "banner", ""],
]
