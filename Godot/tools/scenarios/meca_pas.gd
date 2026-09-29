extends RefCounted
## Chapter 6 mechanics: Chloé's steps in the Monts (snow, packed-snow path, the frozen lake's ice
## with its faint cracks): prints the ground under her and the sounds playing. See tools/capture.gd.

const STEPS := [
	[0.5, "flags", ["monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "forges_vues"]], [0.55, "talk", true],
	[0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"], [1.4, "zone", &"monts"],
	[3.9, "tp", Vector2(32, 72)], [4.0, "static", ["res://tools/scenarios/meca_pas.gd", "neige", "@player"]],
	[4.2, "hold", "move_right"], [4.6, "static", ["res://tools/scenarios/meca_pas.gd", "sol", "@player"]], [4.65, "audio", null],
	[5.1, "audio", null], [5.5, "hold", ""],
	[5.6, "tp", Vector2(2.5, 30)], [5.8, "hold", "move_right"], [6.3, "static", ["res://tools/scenarios/meca_pas.gd", "sol", "@player"]],
	[6.35, "audio", null], [6.8, "audio", null], [7.0, "hold", ""],
	[7.1, "tp", Vector2(40, 86)], [7.3, "hold", "move_left"], [7.7, "static", ["res://tools/scenarios/meca_pas.gd", "sol", "@player"]],
	[7.75, "audio", null], [8.0, "audio", null], [8.25, "audio", null], [8.5, "audio", null], [8.75, "audio", null], [9.0, "audio", null],
	[9.25, "audio", null], [9.5, "audio", null], [9.75, "audio", null], [10.0, "static", ["res://tools/scenarios/meca_pas.gd", "sol", "@player"]],
	[10.1, "hold", ""], [10.2, "state", null],
]


## A cold region, until the zone says so itself (Region.cold).
static func neige(player: Node2D) -> bool:
	player.set("cold", true)
	return true


## The ground under Chloé and the step it makes.
static func sol(player: Node2D) -> String:
	var surface: StringName = player.get("surface_at").call(player.global_position)
	return "%s -> %s" % [surface, player.call("step_kind", surface, player.get("cold"))]
