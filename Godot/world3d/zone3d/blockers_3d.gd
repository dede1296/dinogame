class_name Blockers3D
extends Node3D
## What stops Chloé in a 3D zone besides its slopes (docs/migration-3d.md, phase 4).
## A zone still on the 2.5D's relief keeps the 2.5D's own rules, carried over so the 3D zone opens
## and closes the same ways —
## - the woods (forest tiles) and the edges of the zone stop her (world layer);
## - deep water (water tiles) stops her unless she can swim (water layer, as the 2.5D's);
## - a cliff (Region.cliff_between: 0.75 m or more between two tiles) is a wall on both sides, too
##   high to jump (her jump stays under it): she can neither climb it nor drop down it;
## - solid scenery (Prop.KINDS "solid": a radius or a footprint, in px) at its real size.
## Rows of tiles are merged into long boxes; collinear cliff edges into long walls.
## A REMODELLED zone (ZoneTerrain.is_remodelled: its plan's relief, docs/conception-zones-3d.md) no
## longer matches the 2.5D's tiles; what stops her there is the plan's (docs/zones-3d/<zone>-plan.md,
## « Infranchissable, et pourquoi on le voit ») —
## - deep water, more than DEEP_M of it (ZoneTerrain.water_depth_at: the relief's sea and ponds),
##   on the water layer; the shallows, the ford's shoal and the brooks are walked in;
## - the relief's own slopes: steeper than she can stand on, she slides (no wall needed);
## - the plan's blockers (blockers3d/<zone>.json, its own list): the hedges and banks along their
##   lines, `width_m` thick and `height_m` high over the ground, with the gap the plan leaves; the
##   dense edges over their polygons;
## - the story's obstacles of the plan (tronc, rocher, porte d'ambre, Grand Crâne, gué de lune):
##   StoryObstacles3D, solid until the 2.5D's rule opens them;
## - the 2.5D's solid scenery, on the new ground, where the plan lets it stand (allows: ZoneTerrain.plan_allows,
##   and nothing big in the cones of view of its landmarks, `sightlines`).
## Boxes are laid over cells of CELL_M, merged along the rows and down the columns; the hedges in
## pieces of PIECE_M at most, so they follow the ground. The zone's four edges stand in both cases.

const PX := 48.0
const ABOVE_M := 4.0          # how high the blockers rise above the ground they stand on
const CLIFF_ABOVE_M := 1.4    # a cliff wall rises this far above its top (more than a jump)
const WALL_THICK_M := 0.3
const SCENERY_HEIGHT_M := 2.5
## A remodelled zone's plan, as the game reads it (docs/ is not exported with the game).
const PLAN_DIR := "res://world3d/zone3d/blockers3d/"
const DEEP_M := 0.6           # deeper water than this stops her (the plan's « profondeur > 0,6 m »)
const CELL_M := 1.0           # the cells deep water and dense edges are laid over
const PIECE_M := 3.0          # a hedge or a bank: a box per this many metres of its line at most
const WALL_LOOK_M := 0.25     # …looked at this often along it (its gap, the paths it lets through)
const STORY_KINDS := ["trunk", "boulder", "door", "moon_ford"]

var source: ZoneSource
var terrain: ZoneTerrain      # (null: the 2.5D's heights, as a test reading the rules alone)
var solid: StaticBody3D   # world layer: woods, cliffs, edges, scenery, hedges
var water: StaticBody3D   # water layer
## A remodelled zone's story obstacles (null elsewhere).
var story: StoryObstacles3D
## A remodelled zone's plan blockers (blockers3d/<zone>.json), for the scenery that shows them.
var plan: Array[Dictionary] = []
## …and the cones of view of its landmarks (the same file): {id, from, to, from_half_m, to_half_m}.
var sightlines: Array[Dictionary] = []

var _gap_axes := {}   # the obstacle closing a hedge's gap → the hedge's way there (Vector2)


func build(src: ZoneSource, ground: ZoneTerrain = null) -> void:
	source = src
	terrain = ground
	solid = _body("Solid", Layers3D.WORLD)
	water = _body("Water", Layers3D.WATER)
	if ground and ground.is_remodelled():
		_build_remodelled()
	else:
		_tile_rows(&"forest", solid)
		_tile_rows(&"water", water)
		_cliffs()
		_scenery()
	_edges()


## A remodelled zone's plan blockers ([] when it has no file); `key`: another list of its file.
static func plan_of(zone_id: StringName, key := "blockers") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var path := PLAN_DIR + String(zone_id) + ".json"
	if not FileAccess.file_exists(path):
		return out
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not (data as Dictionary).get("blockers") is Array:
		push_error("Blockers3D : %s illisible (attendu {\"blockers\": [...]})" % path)
		return out
	for b: Variant in data.get(key, []):
		if b is Dictionary:
			out.append(b)
	return out


## Whether scenery may stand at (x, z) (Scatter3D asks the same, so what stops her is what she sees):
## where the zone's plan lets it (ZoneTerrain.plan_allows), and, if `big`, out of its landmarks' cones
## of view.
func allows(x: float, z: float, big: bool) -> bool:
	if terrain == null:
		return true
	if not terrain.plan_allows(x, z, big):
		return false
	if big:
		for s in sightlines:
			if _in_cone(s, Vector2(x, z)):
				return false
	return true


## In a cone of view: between its two ends, closer to its axis than its half-width there.
static func _in_cone(s: Dictionary, p: Vector2) -> bool:
	var a := Vector2(float(s["from"][0]), float(s["from"][1]))
	var b := Vector2(float(s["to"][0]), float(s["to"][1]))
	var length := a.distance_to(b)
	var dir := (b - a) / maxf(length, 0.001)
	var along := (p - a).dot(dir)
	if along < 0.0 or along > length:
		return false
	return absf((p - a).cross(dir)) < lerpf(float(s.get("from_half_m", 1.0)), float(s.get("to_half_m", 1.0)), along / maxf(length, 0.001))


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
	var low := -2.0
	if terrain and terrain.is_remodelled():
		low = -6.0   # (its sea is dug 3 m deep)
		tall = 40.0  # (its mountains rise to 36 m along the edges)
	for side in [[Vector3(size.x * 0.5, 0, 0), Vector3(size.x, tall, WALL_THICK_M)], [Vector3(size.x * 0.5, 0, size.y), Vector3(size.x, tall, WALL_THICK_M)],
			[Vector3(0, 0, size.y * 0.5), Vector3(WALL_THICK_M, tall, size.y)], [Vector3(size.x, 0, size.y * 0.5), Vector3(WALL_THICK_M, tall, size.y)]]:
		_box(solid, side[0] + Vector3(0, tall * 0.5 + low, 0), side[1])


## Solid scenery at its real size: a radius (px) as a cylinder, a footprint (px) as a box — on the
## ground the zone is drawn with (when it is given), and in a remodelled zone only where its plan
## lets something big stand (the same rule as Scatter3D's, so what stops her is what she sees).
func _scenery() -> void:
	for prop in source.props():
		var def = prop["solid"]
		var at: Vector3 = prop["at"]
		if terrain:
			if not allows(at.x, at.z, true):
				continue
			at.y = terrain.height_at(at.x, at.z)
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


# --- a remodelled zone ------------------------------------------------------------------------------

func _build_remodelled() -> void:
	plan = plan_of(source.id)
	sightlines = plan_of(source.id, "sightlines")
	_deep_water()
	for b in plan:
		match String(b.get("kind", "")):
			"hedge", "bank":
				var half := float(b["width_m"]) * 0.5
				var rise := float(b["height_m"])
				if b.has("polyline"):
					_wall_line(b["polyline"], half, rise, bool(b.get("closed", false)), b.get("gap", {}))
				if b.has("polyline2"):
					_wall_line(b["polyline2"], half, rise, false, {})
			"forest_edge":
				for key in ["polygon", "polygon2"]:
					if b.has(key):
						var poly: PackedVector2Array = TerrainRelief.SHAPES._points(b[key])
						var inside := func(x: float, z: float) -> bool: return Geometry2D.is_point_in_polygon(Vector2(x, z), poly)
						var top := func(x: float, z: float) -> float: return terrain.height_at(x, z) + ABOVE_M
						_cell_boxes(solid, TerrainRelief.SHAPES._bounds(poly), inside, top)
	story = StoryObstacles3D.new()
	story.name = "Story"
	add_child(story)
	story.build(source, terrain, plan.filter(func(b: Dictionary) -> bool: return String(b.get("kind", "")) in STORY_KINDS), _gap_axes)
	_scenery()


## The water deeper than DEEP_M, over the zone (its edges hold the rest), on the water layer: each
## box from under the bed up to CLIFF_ABOVE_M over the water (more than a jump).
func _deep_water() -> void:
	var highest := -INF   # (only ground under the highest water less DEEP_M can be under deep water)
	for sheet in terrain.waters:
		highest = maxf(highest, sheet.position.y)
	if highest == -INF:
		return
	var deep := func(x: float, z: float) -> bool: return terrain.height_at(x, z) < highest - DEEP_M and terrain.water_depth_at(x, z) > DEEP_M
	var top := func(x: float, z: float) -> float: return terrain.water_level_at(x, z) + CLIFF_ABOVE_M
	_cell_boxes(water, Rect2(Vector2.ZERO, source.size_m()), deep, top)


## Boxes over the CELL_M cells of `rect` (m) where `inside(x, z)` holds at the cell's centre: runs
## along each row, merged with the run of the row above when they span the same cells. Each box goes
## from 1 m under the lowest ground of its cells to the highest `top(x, z)` of them.
func _cell_boxes(body: StaticBody3D, rect: Rect2, inside: Callable, top: Callable) -> void:
	var i0 := floori(rect.position.x / CELL_M)
	var i1 := ceili(rect.end.x / CELL_M)
	var open := {}   # Vector2i(first cell, end cell) of a run → [first row, lowest ground, highest top]
	for j in range(floori(rect.position.y / CELL_M), ceili(rect.end.y / CELL_M) + 1):
		var runs := {}
		var z := (j + 0.5) * CELL_M
		var i := i0
		while i < i1:
			var x := (i + 0.5) * CELL_M
			if not inside.call(x, z):
				i += 1
				continue
			var start := i
			var lo := INF
			var hi := -INF
			while i < i1 and inside.call((i + 0.5) * CELL_M, z):
				lo = minf(lo, terrain.height_at((i + 0.5) * CELL_M, z))
				hi = maxf(hi, float(top.call((i + 0.5) * CELL_M, z)))
				i += 1
			var key := Vector2i(start, i)
			var was: Array = open.get(key, [j, INF, -INF])
			runs[key] = [was[0], minf(was[1], lo), maxf(was[2], hi)]
		for key: Vector2i in open:
			if not runs.has(key):
				_cells_box(body, key, open[key], j)
		open = runs
	for key: Vector2i in open:
		_cells_box(body, key, open[key], ceili(rect.end.y / CELL_M) + 1)


func _cells_box(body: StaticBody3D, cells: Vector2i, run: Array, end_row: int) -> void:
	var bottom := float(run[1]) - 1.0
	var top := float(run[2])
	var x0 := cells.x * CELL_M
	var x1 := cells.y * CELL_M
	var z0 := int(run[0]) * CELL_M
	var z1 := end_row * CELL_M
	_box(body, Vector3((x0 + x1) * 0.5, (bottom + top) * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, top - bottom, z1 - z0))


## A hedge or a bank along `points` (closed: back to its first point), `half` m either side, `rise` m
## over the ground: boxes of PIECE_M at most, lengthened by `half` at the line's corners and ends so
## they join, left open where `gap` ({at, width_m, closed_by}) says (the obstacle closing it is told the
## hedge's way there, to lie across it) and wherever it would stand on one of the plan's paths (the
## path through the gap aside: that one is the gap's).
func _wall_line(points: Array, half: float, rise: float, closed: bool, gap: Dictionary) -> void:
	var line: PackedVector2Array = TerrainRelief.SHAPES._points(points)
	if closed:
		line.append(line[0])
	var gap_at := Vector2(float(gap["at"][0]), float(gap["at"][1])) if gap.has("at") else Vector2.INF
	var gap_r := float(gap.get("width_m", 0.0)) * 0.5
	if gap.has("closed_by"):
		_gap_axes[String(gap["closed_by"])] = _way_at(line, gap_at)
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		for span: Vector2 in _wall_spans(a, b, half, gap_at, gap_r):
			var n := maxi(1, ceili(a.distance_to(b) * (span.y - span.x) / PIECE_M))
			for k in n:
				var t0 := lerpf(span.x, span.y, float(k) / n)
				var t1 := lerpf(span.x, span.y, float(k + 1) / n)
				# lengthened at the line's corners and ends (to join the next piece), not where it is left open
				var cut0 := k == 0 and span.x > 0.0
				var cut1 := k == n - 1 and span.y < 1.0
				_wall_box(a.lerp(b, t0), a.lerp(b, t1), half, rise, 0.0 if cut0 else half, 0.0 if cut1 else half)


## The parts of segment a→b (as [t0, t1], 0–1 along it) a wall `half` m either side stands on: not
## within `gap_r` of `gap_at`, nor over a path of the plan (but the gap's own), looked at every
## WALL_LOOK_M.
func _wall_spans(a: Vector2, b: Vector2, half: float, gap_at: Vector2, gap_r: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var steps := maxi(1, ceili(a.distance_to(b) / WALL_LOOK_M))
	var start := -1
	for k in steps + 1:
		var keep := false
		if k < steps:
			var p := a.lerp(b, (k + 0.5) / steps)
			keep = p.distance_to(gap_at) >= gap_r and not terrain.near_path(p.x, p.y, half, gap_at, gap_r)
		if keep and start < 0:
			start = k
		elif not keep and start >= 0:
			out.append(Vector2(float(start) / steps, float(k) / steps))
			start = -1
	return out


## The way a line runs at `p` (its segments nearest `p`, their directions averaged: at a corner, both).
static func _way_at(line: PackedVector2Array, p: Vector2) -> Vector2:
	var best := INF
	var way := Vector2.ZERO
	for i in line.size() - 1:
		var ab := line[i + 1] - line[i]
		var t := clampf((p - line[i]).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		var d := p.distance_to(line[i] + ab * t)
		if d < best - 0.01:
			best = d
			way = ab.normalized()
		elif d < best + 0.01:
			way += ab.normalized()
	return way.normalized()


## One piece of a hedge from p0 to p1, lengthened by `ext0` / `ext1` at its ends, `half` m either side,
## from under the lowest ground it covers to `rise` over the highest.
func _wall_box(p0: Vector2, p1: Vector2, half: float, rise: float, ext0: float, ext1: float) -> void:
	var dir := (p1 - p0).normalized()
	var a := p0 - dir * ext0
	var b := p1 + dir * ext1
	var side := Vector2(-dir.y, dir.x) * half
	var lo := INF
	var hi := -INF
	for p in [a, b, (a + b) * 0.5, (a + b) * 0.5 + side, (a + b) * 0.5 - side, a + side, a - side, b + side, b - side]:
		var h := terrain.height_at(p.x, p.y)
		lo = minf(lo, h)
		hi = maxf(hi, h)
	var bottom := lo - 1.0
	var top := hi + rise
	var mid := (a + b) * 0.5
	_box(solid, Vector3(mid.x, (bottom + top) * 0.5, mid.y), Vector3(a.distance_to(b), top - bottom, half * 2.0), atan2(-dir.y, dir.x))
