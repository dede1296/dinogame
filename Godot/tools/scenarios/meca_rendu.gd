extends RefCounted
## Chapter 6 mechanics, render fixes: the glacier's crevasse walls and its ice meeting the snow,
## the woods and tufts where the snow thins out (the west edge), the ice caves' walls; the frame
## rate at the west edge (the cover layer), vsync off. See tools/capture.gd.

const STEPS := [
	[0.5, "flags", ["monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "forges_vues"]], [0.55, "talk", true],
	[0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"], [1.4, "zone", &"monts"],
	[3.9, "tp", Vector2(57, 29.5)], [4.0, "calm", 900.0], [6.0, "shot", "r00_crevasse_mur1"],
	[6.1, "tp", Vector2(40, 84)], [6.2, "calm", 900.0], [8.0, "shot", "r01_lac_gele_rive"],
	[8.1, "tp", Vector2(8, 30)], [8.2, "calm", 900.0], [10.5, "shot", "r02_ouest_arbres_touffes"],
	[10.6, "quality", 1], [10.7, "vsync", false], [14.0, "perf", "MONTS ouest MOYENNE"],
	[14.1, "quality", 2], [14.2, "vsync", false], [17.5, "perf", "MONTS ouest HAUTE"], [17.6, "quality", 1],
	[17.8, "tp", Vector2(20, 30)], [18.0, "calm", 900.0], [20.0, "shot", "r03_transition"],
	[20.05, "static", ["res://tools/scenarios/meca_rendu.gd", "herbes", "@player", true]], [20.1, "calm", 900.0], [21.6, "shot", "r06_touffes_neige"],
	[21.65, "static", ["res://tools/scenarios/meca_rendu.gd", "herbes", "@player", false]], [21.7, "calm", 900.0], [23.2, "shot", "r07_touffes_sans_neige"],
	[23.3, "state", null],
]


## Takes Chloé next to the tall grass nearest to her where the snow lies (`thick`) or not.
static func herbes(player: Node2D, thick: bool) -> String:
	var region: Region = player.get_parent().get_parent()
	var size := region.map_size()
	var here := player.global_position / 48.0
	var best := Vector2.INF
	for y in size.y:
		for x in size.x:
			var p := Vector2(x + 0.5, y + 0.5) * 48.0
			if region.surface_at(p) != &"tall_grass" or (region.snow_at(p) > 0.6) != thick:
				continue
			if best == Vector2.INF or Vector2(x, y).distance_to(here) < best.distance_to(here):
				best = Vector2(x, y)
	if best == Vector2.INF:
		return "aucune"
	player.call("teleport", (best + Vector2(0.5, 2.5)) * 48.0)
	return "herbes en %s" % best
