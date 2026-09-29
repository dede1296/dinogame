extends RefCounted
## Chapter 6 mechanics: the cover layer (Region.cover_data) seen at the Monts' west edge, where
## they meet the Côte: the snow thinning out over 22 tiles, ragged; the frame rate with and without
## it (vsync off). Until the Monts' own layer is made (gen-monts.mjs), a test layer is laid here
## over an ordinary ground. See tools/capture.gd.

const HERE := "res://tools/scenarios/meca_couche.gd"
const STEPS := [
	[0.5, "flags", ["monts_ouverts", "monts_arrivee", "bertille_vue", "glacier_arrivee", "forges_vues"]], [0.55, "talk", true],
	[0.6, "calm", 900.0], [0.6, "clock", 11.0], [0.7, "weather", &"clear"], [1.4, "zone", &"monts"],
	[3.9, "tp", Vector2(8, 30)], [4.0, "calm", 900.0], [4.1, "quality", 1], [4.2, "vsync", false],
	[7.0, "perf", "MOYENNE sans couche"], [7.1, "shot", "c00_sans_couche"],
	[7.2, "static", [HERE, "couche", "@player"]], [10.0, "perf", "MOYENNE avec couche"], [10.1, "shot", "c01_jointure_ouest"],
	[10.2, "tp", Vector2(18, 30)], [12.0, "shot", "c02_transition"], [12.1, "tp", Vector2(30, 34)], [14.0, "shot", "c03_neige_pleine"],
	[14.1, "quality", 2], [14.2, "vsync", false], [14.3, "tp", Vector2(8, 30)], [17.0, "perf", "HAUTE avec couche"],
	[17.1, "static", [HERE, "sans", "@player"]], [20.0, "perf", "HAUTE sans couche"], [20.1, "quality", 1],
	[20.2, "static", [HERE, "couche", "@player"]], [20.3, "tp", Vector2(14, 30)], [22.0, "static", [HERE, "zoom", "@player"]],
	[23.0, "shot", "c04_jointure_de_loin"], [23.1, "static", [HERE, "dezoom", "@player"]], [23.2, "state", null],
]


## A test layer: none on the west edge, rising irregularly over 22 tiles, full beyond; the ground
## under it ordinary (grass, dirt), the snow and its trodden trails over it.
static func couche(player: Node2D) -> String:
	var region: Region = player.get_parent().get_parent()
	var size := region.map_size()
	var data := Image.create(size.x, size.y, false, Image.FORMAT_L8)
	for y in size.y:
		for x in size.x:
			var wobble := sin(y * 0.37) * 2.5 + sin(y * 0.11 + 1.0) * 3.0
			var v := clampf((x - 3.0 - wobble) / 22.0, 0.0, 1.0)
			data.set_pixel(x, y, Color(v, v, v))
	region.cover_data = data
	region.cover_tex = load("res://assets/art/ground/neige.png")
	region.cover_path_tex = load("res://assets/art/ground/neige_chemin.png")
	region.ground_tex = load("res://assets/art/ground/herbe.png")
	region.path_tex = null
	_rebuild(player, region)
	return "couche posée (%dx%d)" % [size.x, size.y]


## Back as the zone is (no layer; the snow as its ground).
static func sans(player: Node2D) -> String:
	var region: Region = player.get_parent().get_parent()
	region.cover_data = null
	region.ground_tex = load("res://assets/art/ground/neige.png")
	region.path_tex = load("res://assets/art/ground/neige_chemin.png")
	_rebuild(player, region)
	return "sans couche"


## The camera far back (20 m) for a wide view; dezoom puts the player's distance back (before the
## tool ends: restoring the graphics level writes the settings file).
static func zoom(player: Node2D) -> String:
	var view := player.get_tree().get_first_node_in_group(&"world_view") as WorldView
	player.set_meta(&"distance_avant", view.camera.distance())
	view.camera.call("set_distance", 20.0, false)
	return "caméra à 20 m"


static func dezoom(player: Node2D) -> String:
	var view := player.get_tree().get_first_node_in_group(&"world_view") as WorldView
	view.camera.call("set_distance", float(player.get_meta(&"distance_avant", 12.0)), false)
	return "caméra rendue (%.1f m)" % view.camera.distance()


static func _rebuild(player: Node2D, region: Region) -> void:
	var view := player.get_tree().get_first_node_in_group(&"world_view") as WorldView
	view.show_zone(region, player)


## Three layers (the zone's snow, then sand and earth dosed like it): what three layers cost.
static func trois(player: Node2D) -> String:
	var region: Region = player.get_parent().get_parent()
	var data: Image = region.cover_data
	region.cover_layers.assign([{"tex": load("res://assets/art/ground/sable.png"), "data": data},
		{"tex": load("res://assets/art/ground/terre.png"), "data": data}])
	_rebuild(player, region)
	return "%d couches" % region.covers().size()


## Back to the zone's own layer.
static func une(player: Node2D) -> String:
	var region: Region = player.get_parent().get_parent()
	region.cover_layers.clear()
	_rebuild(player, region)
	return "%d couche" % region.covers().size()
