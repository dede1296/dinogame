class_name Blockers3D
extends Node3D
## What stops Chloé in a 3D zone besides its slopes (docs/migration-3d.md, phase 4): the 2.5D's own
## rules, carried over so the 3D zone opens and closes the same ways —
## - the woods (forest tiles) and the edges of the zone stop her (world layer);
## - deep water (water tiles) stops her unless she can swim (water layer, as the 2.5D's);
## - a cliff (Region.cliff_between: 0.75 m or more between two tiles) is a wall on both sides, too
##   high to jump (her jump stays under it): she can neither climb it nor drop down it;
## - solid scenery (Prop.KINDS "solid": a radius or a footprint, in px) at its real size.
## Rows of tiles are merged into long boxes; collinear cliff edges into long walls.

const PX := 48.0
const ABOVE_M := 4.0          # how high the blockers rise above the ground they stand on
const CLIFF_ABOVE_M := 1.4    # a cliff wall rises this far above its top (more than a jump)
const WALL_THICK_M := 0.3
const SCENERY_HEIGHT_M := 2.5

var source: ZoneSource
var solid: StaticBody3D   # world layer: woods, cliffs, edges, scenery
var water: StaticBody3D   # water layer


func build(src: ZoneSource) -> void:
	source = src
	solid = _body("Solid", Layers3D.WORLD)
	water = _body("Water", Layers3D.WATER)
	_tile_rows(&"forest", solid)
	_tile_rows(&"water", water)
	_cliffs()
	_edges()
	_scenery()


func _body(body_name: String, layer: int) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = body_name
	b.collision_layer = layer
	b.collision_mask = 0
	b.add_to_group(&"nav_source")
	add_child(b)
	return b


## A box from tile rect `tiles` (in tiles), standing on the ground under it.
func _box_on_tiles(body: StaticBody3D, tiles: Rect2, above: float) -> void:
	var span := source.heights.range_in(tiles)
	var bottom := span.x - 1.0
	var top := span.y + above
	var s := source.scale
	_box(body, Vector3((tiles.position.x + tiles.size.x * 0.5) * s, (bottom + top) * 0.5, (tiles.position.y + tiles.size.y * 0.5) * s),
		Vector3(tiles.size.x * s, top - bottom, tiles.size.y * s))


func _box(body: StaticBody3D, center: Vector3, size: Vector3, yaw := 0.0) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = center
	shape.rotation.y = yaw
	body.add_child(shape)


## Runs of `surface` tiles along each row, one box each.
func _tile_rows(surface: StringName, body: StaticBody3D) -> void:
	for y in source.tiles.y:
		var x := 0
		while x < source.tiles.x:
			if source.surface(Vector2i(x, y)) != surface:
				x += 1
				continue
			var start := x
			while x < source.tiles.x and source.surface(Vector2i(x, y)) == surface:
				x += 1
			_box_on_tiles(body, Rect2(start, y, x - start, 1), ABOVE_M)


## A wall along every edge between two tiles of a cliff (the 2.5D's rule), collinear edges merged.
func _cliffs() -> void:
	var s := source.scale
	# edges between (x, y) and (x + 1, y): vertical walls at x + 1, merged down the column
	for x in source.tiles.x - 1:
		var y := 0
		while y < source.tiles.y:
			if not _cliff(Vector2i(x, y), Vector2i(x + 1, y)):
				y += 1
				continue
			var start := y
			var hi := -INF
			var lo := INF
			while y < source.tiles.y and _cliff(Vector2i(x, y), Vector2i(x + 1, y)):
				for t in [Vector2i(x, y), Vector2i(x + 1, y)]:
					hi = maxf(hi, source.tile_height(t))
					lo = minf(lo, source.tile_height(t))
				y += 1
			_wall(Vector3((x + 1) * s, 0.0, (start + y) * 0.5 * s), Vector3(WALL_THICK_M, 0.0, (y - start) * s), lo, hi)
	# edges between (x, y) and (x, y + 1): walls at y + 1, merged along the row
	for y in source.tiles.y - 1:
		var x := 0
		while x < source.tiles.x:
			if not _cliff(Vector2i(x, y), Vector2i(x, y + 1)):
				x += 1
				continue
			var start := x
			var hi := -INF
			var lo := INF
			while x < source.tiles.x and _cliff(Vector2i(x, y), Vector2i(x, y + 1)):
				for t in [Vector2i(x, y), Vector2i(x, y + 1)]:
					hi = maxf(hi, source.tile_height(t))
					lo = minf(lo, source.tile_height(t))
				x += 1
			_wall(Vector3((start + x) * 0.5 * s, 0.0, (y + 1) * s), Vector3((x - start) * s, 0.0, WALL_THICK_M), lo, hi)


func _cliff(a: Vector2i, b: Vector2i) -> bool:
	return source.is_cliff(source.tile_height(a), source.tile_height(b))


func _wall(at: Vector3, size: Vector3, lo: float, hi: float) -> void:
	var bottom := lo - 1.0
	var top := hi + CLIFF_ABOVE_M
	_box(solid, Vector3(at.x, (bottom + top) * 0.5, at.z), Vector3(size.x, top - bottom, size.z))


## The zone's four edges (the ways out to the other zones come with phase 8).
func _edges() -> void:
	var size := source.size_m()
	var tall := 12.0
	for side in [[Vector3(size.x * 0.5, 0, 0), Vector3(size.x, tall, WALL_THICK_M)], [Vector3(size.x * 0.5, 0, size.y), Vector3(size.x, tall, WALL_THICK_M)],
			[Vector3(0, 0, size.y * 0.5), Vector3(WALL_THICK_M, tall, size.y)], [Vector3(size.x, 0, size.y * 0.5), Vector3(WALL_THICK_M, tall, size.y)]]:
		_box(solid, side[0] + Vector3(0, tall * 0.5 - 2.0, 0), side[1])


## Solid scenery at its real size: a radius (px) as a cylinder, a footprint (px) as a box.
func _scenery() -> void:
	for prop in source.props():
		var def = prop["solid"]
		var at: Vector3 = prop["at"]
		if def is float and def > 0.0:
			var cyl := CylinderShape3D.new()
			cyl.radius = def / PX
			cyl.height = SCENERY_HEIGHT_M
			var shape := CollisionShape3D.new()
			shape.shape = cyl
			shape.position = at + Vector3(0, SCENERY_HEIGHT_M * 0.5, 0)
			solid.add_child(shape)
		elif def is Vector2:
			_box(solid, at + Vector3(0, SCENERY_HEIGHT_M * 0.5, 0), Vector3(def.x / PX, SCENERY_HEIGHT_M, def.y / PX))
