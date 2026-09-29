extends RefCounted
## Soft joins between neighbouring regions (29/09): along the edge two zones share, the
## neighbour's ground is laid over this zone's, thinning out inwards (Region.cover_*, dosed tile
## by tile by tools/maps/<zone>_couche_<neighbour>.png, made by gen-couches.mjs), and a few of
## its plants grow among this zone's there. Used by the zone plans (tools/zones/<zone>.gd), last,
## so that nothing they placed before moves (the amber pebbles keep their stones and trees).

const B := preload("res://tools/zone_builder.gd")
const GROUND := "res://assets/art/ground/%s.png"
const MAPS := "res://tools/maps/%s_couche_%s.png"
## Ground where a plant may grow in the band (not by a path: DISTANCE_TO_PATH tiles).
const OPEN := ["grass", "tall_grass", "sand", "mud"]
const DISTANCE_TO_PATH := 1


## Lays `ground` (a picture of assets/art/ground: "sous_bois", "herbe"…; `path` on the paths)
## over zone `root` along its edge with `neighbour`, dosed by tools/maps/<zone>_couche_<neighbour>.png,
## saved next to the zone's scene (`res_dir`): its first layer (cover_*: the only one with a path
## picture of its own), or one more (cover_layers). Not snow (Region.cover_snow). Returns the dose
## (null when a picture is missing: then nothing is laid).
static func cover(root: Region, neighbour: String, ground: String, path: String, res_dir: String) -> Image:
	var png := MAPS % [root.region_id, neighbour]
	if not (ResourceLoader.exists(GROUND % ground) and FileAccess.file_exists(ProjectSettings.globalize_path(png))):
		return null
	var dose := Image.load_from_file(ProjectSettings.globalize_path(png))
	dose.convert(Image.FORMAT_L8)
	var res := "%s/%s_couche_%s.res" % [res_dir, root.region_id, neighbour]
	ResourceSaver.save(dose, res)
	var data: Image = load(res)
	if root.cover_data == null:
		root.cover_tex = load(GROUND % ground)
		root.cover_path_tex = load(GROUND % path) if path != "" and ResourceLoader.exists(GROUND % path) else null
		root.cover_data = data
		root.cover_snow = false
	else:
		root.cover_layers.append({"tex": load(GROUND % ground), "data": data, "snow": false})
	return data


## A few of the neighbour's `kinds` (repeat one to make it commoner) in the band: on open ground
## away from the paths, level with its neighbours, on no other prop's tile, outside `keep_clear`
## (tiles); each tile by chance `density` × its dose. Own random draws (`seed_value`).
static func plants(root: Region, entities: Node2D, dose: Image, kinds: Array, density: float, seed_value: int,
		keep_clear: Array = []) -> int:
	if dose == null:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var terrain: TileMapLayer = root.get_node("Terrain")
	var taken := {}
	for n in entities.get_children():
		if n is Node2D:
			taken[Vector2i(((n as Node2D).position / B.TILE).floor())] = true
	var placed := 0
	for y in dose.get_height():
		for x in dose.get_width():
			var d := dose.get_pixel(x, y).r
			if d < 0.05:
				continue
			var roll := rng.randf()
			var kind: String = kinds[rng.randi() % kinds.size()]
			var at := Vector2(x + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9))
			var flip := rng.randf() < 0.5
			var c := Vector2i(x, y)
			if roll >= density * d or taken.has(c) or not Prop.KINDS.has(kind):
				continue
			if not _ground(terrain, c) in OPEN or _near_path(terrain, c) or not _level(root, c):
				continue
			if keep_clear.any(func(r: Rect2) -> bool: return r.has_point(Vector2(x + 0.5, y + 0.5))):
				continue
			B.prop(entities, kind, B.cell(at.x, at.y), flip)
			taken[c] = true
			placed += 1
	return placed


## Tile `c` is nearly level with its neighbours (nothing on a cliff's edge or a steep slope).
static func _level(root: Region, c: Vector2i) -> bool:
	var h := root.tile_height(c)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if absf(root.tile_height(c + Vector2i(dx, dy)) - h) > 0.3:
				return false
	return true


static func _ground(terrain: TileMapLayer, c: Vector2i) -> String:
	var d := terrain.get_cell_tile_data(c)
	return String(d.get_custom_data("terrain")) if d else ""


static func _near_path(terrain: TileMapLayer, c: Vector2i) -> bool:
	for dy in range(-DISTANCE_TO_PATH, DISTANCE_TO_PATH + 1):
		for dx in range(-DISTANCE_TO_PATH, DISTANCE_TO_PATH + 1):
			if _ground(terrain, c + Vector2i(dx, dy)) == "path":
				return true
	return false
