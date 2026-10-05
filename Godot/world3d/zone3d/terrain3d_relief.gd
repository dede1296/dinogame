class_name TerrainRelief
extends RefCounted
## The relief and the painting of a zone's ground, authored by script, without the editor
## (docs/migration-3d.md, phase 4, « Terrain3D : écrire le relief »). It is what the Terrain3D ground
## (ZoneGroundTerrain3D) draws and walks on, and what ZoneTerrain.height_at answers.
##
## (a) The base is the 2.5D's relief, as the rules read it: ZoneSource.height_at, sampled every
##     `step` m over the zone and its margin (zone coordinates, metres: 0,0 is the zone's corner).
## (b) Edits, given as data, change it: hills, valleys, ramps, flattened ground, smoothing, a deeper
##     sea. Each is one Dictionary; coordinates are [x, z] in metres of the zone.
## (c) The painting (the ground types the shader paints: grass, dirt path, sand, mud, rock, tall
##     grass, the dark floor of the woods) starts from the 2.5D's tiles and can be repainted too.
##
## Where they come from: res://world3d/zone3d/terrain3d_relief/<zone id>.json, {"edits": [...]};
## a zone without a file gets DEFAULT_EDITS (smooth, then dig the sea: the 2.5D's relief, rounded).
##
##   var relief := TerrainRelief.from_source(source)          # (a) the 2.5D's heights
##   relief.apply([                                           # (b) and (c), in this order
##       {"op": "smooth"},                                    #   round off the 2 m facets
##       {"op": "dig_sea", "extra_m": 2.4},                   #   the open sea deeper than a pond
##       {"op": "hill", "at": [60, 40], "radius_m": 12, "height_m": 1.5},
##       {"op": "valley", "at": [150, 90], "radius_m": 8, "depth_m": 1.0},
##       {"op": "flatten", "at": [120, 170], "radius_m": 6, "height_m": 0.0},
##       {"op": "ramp", "from": [30, 60], "to": [42, 60], "width_m": 4},
##       {"op": "paint", "ground": "sand", "at": [80, 160], "radius_m": 6},
##       {"op": "paint", "ground": "path", "from": [100, 120], "to": [130, 118], "width_m": 3},
##   ])
##   relief.height_at(x, z)                                   # what Chloé walks on
##
## Keys every relief edit takes: "soft" (0–1, how much of the radius or half-width fades out,
## default 0.5) and "protect" (default true): the edit fades out within PROTECT_TILES tiles of a
## cliff or of the water, where the rules of the game stand on the 2.5D's exact heights (the walls
## of Blockers3D along the cliffs, the water's edge the water sheet draws). Set it to false only
## knowing that: a ramp up a cliff, say, also needs the 2.5D's cliff rule lifted there, or the
## invisible wall stays across it.
## The painting is what is SEEN only: the rules (encounters in the tall grass, the woods that stop
## Chloé, what is walkable) still read the 2.5D's tiles. Paint at tile resolution (2 m in the
## Prairie), with soft edges; the shader's ragged edges do the rest.
## Things placed from the 2.5D's own heights (ZoneSource.to_3d: the story's actors, the plain
## scenery) do not follow an edit; what asks ZoneTerrain.height_at (the woods, the herbs, the NPCs,
## the dinos, the rain) does. Keep big edits away from the story's places, or re-snap them.
##
## A REMODELLED zone (docs/conception-zones-3d.md: a plan of its own, docs/zones-3d/<zone>-layout.json)
## writes its plan's relief with the plan's own modifiers — level, dome, plateau, ridge, gradient,
## water_basin, carve, noise, pond, islet, shoal, paths, soften (terrain3d_relief_shapes.gd) — from a flat
## base: the 2.5D's relief is replaced (`remodelled`), and the water it digs is listed (`water_level_at`, `shapes.waters`,
## `shapes.beds`; a bed marked "brook" gets its river: BROOKS.build(relief, ground node)). The
## Prairie's file is written from its plan by terrain3d_relief_layout.py.
## Painting more: "paint" also takes "points" (a polyline, `width_m` wide) or "polygon", and
## "above_m" / "below_m" (only where the ground's height at the tile's centre is in that band);
## "paint_reset" clears the painting but what it is told to "keep" (the tall grass: the rules' tiles).

const STEP_M := 0.5               # metres between two samples (Terrain3D's vertex spacing)
const SHAPES := preload("res://world3d/zone3d/terrain3d_relief_shapes.gd")   # the plans' modifiers
const BROOKS := preload("res://world3d/zone3d/terrain3d_relief_brooks.gd")   # their brooks, Waterways rivers
const EDITS_DIR := "res://world3d/zone3d/terrain3d_relief/"
const DEFAULT_EDITS: Array[Dictionary] = [{"op": "smooth"}, {"op": "dig_sea"}]
const PROTECT_TILES := 2          # no relief edit (protected) within this many tiles of a cliff or water
## smooth: two passes of a box `radius_m` wide on a 1 m grid (about a Gaussian of 1.6 m at 2 m),
## never further than `max_m` from the ground it smooths.
const SMOOTH_RADIUS_M := 2
const SMOOTH_MAX_M := 0.15
## dig_sea: every body of water reaching the edge of the zone goes down by up to `extra_m`, from
## `from_m` off the shore (from the centre of the first water tile) to `full_m` out. The 2.5D digs all
## its water 0.85 m (HeightMap.WATER_DEPTH); a pond keeps that.
const SEA_EXTRA_M := 2.4
const SEA_FROM_M := 3.0
const SEA_FULL_M := 16.0
const HEIGHT_EASE_M := 0.3       # a paint's height band eases out over this
## The ground types the painting knows: [mask (0: mask_a, 1: mask_b), channel]. "grass" clears.
const GROUNDS := {
	"path": [0, 0], "tall_grass": [0, 1], "water": [0, 2], "forest": [0, 3],
	"sand": [1, 0], "mud": [1, 1], "rock": [1, 2],
}

var source: ZoneSource
## The grid, in metres of the zone: from `origin`, a sample every `step` m, `samples` along x and z.
var origin := Vector2.ZERO
var step := STEP_M
var samples := Vector2i.ZERO
var heights := PackedFloat32Array()   # the ground as it is now
var base := PackedFloat32Array()      # the 2.5D's (ZoneSource.height_at), untouched
## The painting, one pixel per tile — mask_a: R path, G tall grass, B water, A woods;
## mask_b: R sand, G mud, B rock.
var mask_a: Image
var mask_b: Image
## What each edit took (ms), in order: [[op, ms]].
var timings: Array = []
## True once a `level` edit has replaced the 2.5D's relief (a remodelled zone): the rules that still read
## the 2.5D's tiles (Blockers3D's cliffs and woods, ZoneWater's water) no longer match the ground.
var remodelled := false
## The plan's modifiers and what they leave behind (the water dug, the planed paths' profiles).
var shapes: RefCounted   # a SHAPES (terrain3d_relief_shapes.gd)

var _calm := PackedFloat32Array()     # per tile: 1 far from cliffs and water, 0 near (protect)


## (a) The 2.5D's relief of `src` over the zone and its margin, and its painting.
static func from_source(src: ZoneSource, sample_step := STEP_M) -> TerrainRelief:
	var relief := TerrainRelief.new()
	relief.source = src
	relief.step = sample_step
	var margin := src.margin_m()
	relief.origin = Vector2(-margin, -margin)
	var extent := src.size_m() + Vector2.ONE * margin * 2.0
	relief.samples = Vector2i(int(extent.x / sample_step) + 1, int(extent.y / sample_step) + 1)
	relief._sample()
	relief.heights = relief.base.duplicate()
	relief._paint_from_tiles()
	return relief


## The edits of zone `zone_id`: its file in EDITS_DIR, else DEFAULT_EDITS.
static func edits_of(zone_id: StringName) -> Array[Dictionary]:
	var path := EDITS_DIR + String(zone_id) + ".json"
	var out: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		out.assign(DEFAULT_EDITS)
		return out
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not (data as Dictionary).get("edits") is Array:
		push_error("TerrainRelief : %s illisible (attendu {\"edits\": [...]}) : relief du 2,5D seul" % path)
		return out
	for edit: Variant in data["edits"]:
		if edit is Dictionary:
			out.append(edit)
	return out


## (b) and (c): applies the edits in order. An unknown op is reported and skipped.
func apply(edits: Array) -> void:
	for edit: Dictionary in edits:
		var t0 := Time.get_ticks_msec()
		match String(edit.get("op", "")):
			"smooth": _smooth(edit)
			"dig_sea": _dig_sea(edit)
			"hill": _bump(edit, float(edit.get("height_m", 1.0)))
			"valley": _bump(edit, -float(edit.get("depth_m", 1.0)))
			"flatten": _flatten(edit)
			"ramp": _ramp(edit)
			"paint": _paint(edit)
			"paint_reset": _paint_reset(edit)
			var other:
				if shapes == null:
					shapes = SHAPES.new(self)
				if not shapes.apply(edit):
					push_error("TerrainRelief : opération inconnue « %s » (ignorée)" % other)
		timings.append([String(edit.get("op", "")), Time.get_ticks_msec() - t0])


## Height (m) of the ground at a point of the zone (m): bilinear between the samples, as
## Terrain3DData.get_height reads its vertices.
func height_at(x: float, z: float) -> float:
	return _bilinear(heights, x, z)


## The level of the relief's own water over (x, z) (a remodelled zone: its sea, its ponds), or -INF:
## what stops Chloé there is `water_level_at(x, z) - height_at(x, z)` metres of it.
func water_level_at(x: float, z: float) -> float:
	return shapes.water_level_at(x, z) if shapes else -INF


## The 2.5D's own height on the same grid (what the ground was before any edit).
func base_height_at(x: float, z: float) -> float:
	return _bilinear(base, x, z)


## The painting as textures for the shader: [mask_a, mask_b].
func mask_textures() -> Array[ImageTexture]:
	return [ImageTexture.create_from_image(mask_a), ImageTexture.create_from_image(mask_b)]


## Takes the heights back from somewhere else (Terrain3D regions edited by hand), sample by sample:
## `read` is called with (x, z) in metres of the zone.
func read_heights(read: Callable) -> void:
	for iz in samples.y:
		var row := iz * samples.x
		for ix in samples.x:
			heights[row + ix] = float(read.call(origin.x + ix * step, origin.y + iz * step))


func _bilinear(grid: PackedFloat32Array, x: float, z: float) -> float:
	var g := (Vector2(x, z) - origin) / step
	var ix := clampi(floori(g.x), 0, samples.x - 2)
	var iz := clampi(floori(g.y), 0, samples.y - 2)
	var fx := clampf(g.x - ix, 0.0, 1.0)
	var fz := clampf(g.y - iz, 0.0, 1.0)
	var row := iz * samples.x
	var top := lerpf(grid[row + ix], grid[row + ix + 1], fx)
	var bottom := lerpf(grid[row + samples.x + ix], grid[row + samples.x + ix + 1], fx)
	return lerpf(top, bottom, fz)


## ZoneSource.height_at at every sample, one row per task over the cores: it only reads the 2.5D's
## data (the HeightMap, the tiles), and each row writes its own samples of a grid sized beforehand.
func _sample() -> void:
	base.resize(samples.x * samples.y)
	var task := WorkerThreadPool.add_group_task(_sample_row, samples.y, -1, true, "TerrainRelief : hauteurs")
	WorkerThreadPool.wait_for_group_task_completion(task)


func _sample_row(iz: int) -> void:
	var z := origin.y + iz * step
	var row := iz * samples.x
	for ix in samples.x:
		base[row + ix] = source.height_at(origin.x + ix * step, z)


# --- relief edits --------------------------------------------------------------------------------

## Where an edit may change the ground at a sample: 1 far from the rules' heights, fading to 0 by
## them (or 1 everywhere with "protect": false).
func freedom(edit: Dictionary, x: float, z: float) -> float:
	if not bool(edit.get("protect", true)):
		return 1.0
	if _calm.is_empty():
		_calm = _calm_tiles()
	return _tile_bilinear(_calm, source.tiles, x / source.scale - 0.5, z / source.scale - 0.5)


## The share of an edit at `d` metres from its centre (or its line): 1 inside, fading out over the
## last `soft` of `reach`, 0 beyond.
static func _bell(d: float, reach: float, soft: float) -> float:
	return 1.0 - smoothstep(reach * (1.0 - clampf(soft, 0.0, 1.0)), reach, d)


static func _xz(value: Variant) -> Vector2:
	return Vector2(float(value[0]), float(value[1])) if value is Array else value as Vector2


## The samples within `reach` m of `at` (their indices), so an edit only walks over its own area.
func _area(at: Vector2, reach: float) -> Rect2i:
	var lo := ((at - Vector2.ONE * reach - origin) / step).floor()
	var hi := ((at + Vector2.ONE * reach - origin) / step).ceil()
	var a := Vector2i(clampi(int(lo.x), 0, samples.x - 1), clampi(int(lo.y), 0, samples.y - 1))
	var b := Vector2i(clampi(int(hi.x), 0, samples.x - 1), clampi(int(hi.y), 0, samples.y - 1))
	return Rect2i(a, b - a + Vector2i.ONE)


## hill (up) and valley (down): a round bump of `rise` m at its centre.
func _bump(edit: Dictionary, rise: float) -> void:
	var at := _xz(edit.get("at", [0, 0]))
	var reach := float(edit.get("radius_m", 8.0))
	var soft := float(edit.get("soft", 0.5))
	var box := _area(at, reach)
	for iz in range(box.position.y, box.end.y):
		for ix in range(box.position.x, box.end.x):
			var p := origin + Vector2(ix, iz) * step
			var w := _bell(p.distance_to(at), reach, soft) * freedom(edit, p.x, p.y)
			heights[iz * samples.x + ix] += rise * w


## flatten: the ground round `at` brought to `height_m` (default: the height at the centre).
func _flatten(edit: Dictionary) -> void:
	var at := _xz(edit.get("at", [0, 0]))
	var reach := float(edit.get("radius_m", 6.0))
	var soft := float(edit.get("soft", 0.5))
	var level := float(edit.get("height_m", height_at(at.x, at.y)))
	var box := _area(at, reach)
	for iz in range(box.position.y, box.end.y):
		for ix in range(box.position.x, box.end.x):
			var p := origin + Vector2(ix, iz) * step
			var w := _bell(p.distance_to(at), reach, soft) * freedom(edit, p.x, p.y)
			var i := iz * samples.x + ix
			heights[i] = lerpf(heights[i], level, w)


## ramp: a strip `width_m` wide from `from` to `to`, sloping evenly from the height at one end to the
## height at the other (or `from_h` / `to_h`, m).
func _ramp(edit: Dictionary) -> void:
	var a := _xz(edit.get("from", [0, 0]))
	var b := _xz(edit.get("to", [0, 0]))
	var half := float(edit.get("width_m", 4.0)) * 0.5
	var soft := float(edit.get("soft", 0.5))
	var ha := float(edit.get("from_h", height_at(a.x, a.y)))
	var hb := float(edit.get("to_h", height_at(b.x, b.y)))
	var box := _area((a + b) * 0.5, (a.distance_to(b) * 0.5) + half)
	var along := b - a
	var length2 := maxf(along.length_squared(), 0.0001)
	for iz in range(box.position.y, box.end.y):
		for ix in range(box.position.x, box.end.x):
			var p := origin + Vector2(ix, iz) * step
			var t := clampf((p - a).dot(along) / length2, 0.0, 1.0)
			var w := _bell(p.distance_to(a + along * t), half, soft) * freedom(edit, p.x, p.y)
			var i := iz * samples.x + ix
			heights[i] = lerpf(heights[i], lerpf(ha, hb, t), w)


## smooth: rounds off the facets of the relief (the 2.5D's 2 m tiles joined by straight slopes):
## a blurred copy on a 1 m grid, blended in where the ground is free (always protected: the rules'
## heights stay exact), never further than `max_m` from the ground it smooths.
func _smooth(edit: Dictionary) -> void:
	var radius := int(edit.get("radius_m", SMOOTH_RADIUS_M))
	var most := float(edit.get("max_m", SMOOTH_MAX_M))
	var k := maxi(roundi(1.0 / step), 1)   # samples per metre
	var coarse := Vector2i(int((samples.x - 1) / float(k)) + 1, int((samples.y - 1) / float(k)) + 1)
	var grid := PackedFloat32Array()
	grid.resize(coarse.x * coarse.y)
	for cz in coarse.y:
		for cx in coarse.x:
			grid[cz * coarse.x + cx] = heights[mini(cz * k, samples.y - 1) * samples.x + mini(cx * k, samples.x - 1)]
	for _round in 2:
		grid = _box_rows(grid, coarse, radius)
		grid = _box_columns(grid, coarse, radius)
	if _calm.is_empty():
		_calm = _calm_tiles()
	var tiles := source.tiles
	var tile_m := source.scale
	# Where each column of samples falls between two tile centres and two coarse samples, worked out
	# once (the loop below runs over every sample: it must stay plain).
	var xa := PackedInt32Array()
	var xb := PackedInt32Array()
	var xf := PackedFloat32Array()
	var ca := PackedInt32Array()
	var cf := PackedFloat32Array()
	for ix in samples.x:
		var tx := (origin.x + ix * step) / tile_m - 0.5
		var x0 := floori(tx)
		xa.append(clampi(x0, 0, tiles.x - 1))
		xb.append(clampi(x0 + 1, 0, tiles.x - 1))
		xf.append(clampf(tx - x0, 0.0, 1.0))
		var gx := ix / float(k)
		var c0 := clampi(floori(gx), 0, coarse.x - 2)
		ca.append(c0)
		cf.append(clampf(gx - c0, 0.0, 1.0))
	var calm_row := PackedFloat32Array()
	calm_row.resize(tiles.x)
	var soft_row := PackedFloat32Array()
	soft_row.resize(coarse.x)
	for iz in samples.y:
		var tz := (origin.y + iz * step) / tile_m - 0.5
		var z0 := floori(tz)
		var za := clampi(z0, 0, tiles.y - 1) * tiles.x
		var zb := clampi(z0 + 1, 0, tiles.y - 1) * tiles.x
		var fz := clampf(tz - z0, 0.0, 1.0)
		var any := false
		for x in tiles.x:
			calm_row[x] = lerpf(_calm[za + x], _calm[zb + x], fz)
			any = any or calm_row[x] > 0.0
		if not any:
			continue
		var gz := iz / float(k)
		var c0 := clampi(floori(gz), 0, coarse.y - 2)
		var cfz := clampf(gz - c0, 0.0, 1.0)
		for cx in coarse.x:
			soft_row[cx] = lerpf(grid[c0 * coarse.x + cx], grid[(c0 + 1) * coarse.x + cx], cfz)
		var row := iz * samples.x
		for ix in samples.x:
			var w := lerpf(calm_row[xa[ix]], calm_row[xb[ix]], xf[ix])
			if w <= 0.0:
				continue
			var soft := lerpf(soft_row[ca[ix]], soft_row[ca[ix] + 1], cf[ix])
			var h := heights[row + ix]
			heights[row + ix] = h + w * clampf(soft - h, -most, most)


## 1 per tile at least PROTECT_TILES tiles from any cliff and any water, else 0.
func _calm_tiles() -> PackedFloat32Array:
	var tiles := source.tiles
	var bad := PackedByteArray()
	bad.resize(tiles.x * tiles.y)
	for y in tiles.y:
		for x in tiles.x:
			var t := Vector2i(x, y)
			var h := source.tile_height(t)
			var flagged := source.surface(t) == &"water"
			for n in [Vector2i(x + 1, y), Vector2i(x - 1, y), Vector2i(x, y + 1), Vector2i(x, y - 1)]:
				if n.x >= 0 and n.y >= 0 and n.x < tiles.x and n.y < tiles.y and source.is_cliff(h, source.tile_height(n)):
					flagged = true
			bad[y * tiles.x + x] = 1 if flagged else 0
	# grown by PROTECT_TILES (a square), along the rows then down the columns
	var r := PROTECT_TILES
	var near := PackedByteArray()
	near.resize(bad.size())
	for y in tiles.y:
		for x in tiles.x:
			for dx in range(-r, r + 1):
				if bad[y * tiles.x + clampi(x + dx, 0, tiles.x - 1)]:
					near[y * tiles.x + x] = 1
					break
	var calm := PackedFloat32Array()
	calm.resize(tiles.x * tiles.y)
	for y in tiles.y:
		for x in tiles.x:
			var clear := 1.0
			for dy in range(-r, r + 1):
				if near[clampi(y + dy, 0, tiles.y - 1) * tiles.x + x]:
					clear = 0.0
					break
			calm[y * tiles.x + x] = clear
	return calm


## A running box blur along the rows (radius `r` samples), edges held.
static func _box_rows(grid: PackedFloat32Array, size: Vector2i, r: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(grid.size())
	var span := 2 * r + 1
	for y in size.y:
		var row := y * size.x
		var sum := 0.0
		for i in range(-r, r + 1):
			sum += grid[row + clampi(i, 0, size.x - 1)]
		for x in size.x:
			out[row + x] = sum / span
			sum += grid[row + mini(x + r + 1, size.x - 1)] - grid[row + maxi(x - r, 0)]
	return out


static func _box_columns(grid: PackedFloat32Array, size: Vector2i, r: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(grid.size())
	var span := 2 * r + 1
	for x in size.x:
		var sum := 0.0
		for i in range(-r, r + 1):
			sum += grid[clampi(i, 0, size.y - 1) * size.x + x]
		for y in size.y:
			out[y * size.x + x] = sum / span
			sum += grid[mini(y + r + 1, size.y - 1) * size.x + x] - grid[maxi(y - r, 0) * size.x + x]
	return out


## A per-tile value read between the tile centres (`tx`, `tz`: tile coordinates less half a tile),
## the edge tiles held beyond the zone.
static func _tile_bilinear(map: PackedFloat32Array, tiles: Vector2i, tx: float, tz: float) -> float:
	var x0 := floori(tx)
	var z0 := floori(tz)
	var fx := clampf(tx - x0, 0.0, 1.0)
	var fz := clampf(tz - z0, 0.0, 1.0)
	var xa := clampi(x0, 0, tiles.x - 1)
	var xb := clampi(x0 + 1, 0, tiles.x - 1)
	var za := clampi(z0, 0, tiles.y - 1)
	var zb := clampi(z0 + 1, 0, tiles.y - 1)
	var top := lerpf(map[za * tiles.x + xa], map[za * tiles.x + xb], fx)
	var bottom := lerpf(map[zb * tiles.x + xa], map[zb * tiles.x + xb], fx)
	return lerpf(top, bottom, fz)


# --- the sea -------------------------------------------------------------------------------------

## dig_sea: every body of water that reaches the edge of the zone, deeper with the distance from its
## shore. The shore and the first metres off it are left as they are (the water's edge stays put).
func _dig_sea(edit: Dictionary) -> void:
	if not source.heights.has_water:
		return
	var extra := float(edit.get("extra_m", SEA_EXTRA_M))
	var from_m := float(edit.get("from_m", SEA_FROM_M))
	var full_m := float(edit.get("full_m", SEA_FULL_M))
	var sea := _sea_tiles()
	if sea.is_empty():
		return
	var offshore := _distance_offshore(sea)
	var tile_m := source.scale
	for iz in samples.y:
		var z := origin.y + iz * step
		var row := iz * samples.x
		for ix in samples.x:
			if base[row + ix] >= HeightMap.WATER_LEVEL:
				continue   # dry ground, or the shore: untouched
			var x := origin.x + ix * step
			var dist := _tile_bilinear(offshore, source.tiles, x / tile_m - 0.5, z / tile_m - 0.5) * tile_m
			heights[row + ix] -= extra * smoothstep(from_m, full_m, dist)


## {tile: true} for the water tiles of every body of water that touches the edge of the zone.
func _sea_tiles() -> Dictionary:
	var tiles := source.tiles
	var seen := {}
	var sea := {}
	for y in tiles.y:
		for x in tiles.x:
			var start := Vector2i(x, y)
			if seen.has(start) or source.surface(start) != &"water":
				continue
			var body: Array[Vector2i] = []
			var queue: Array[Vector2i] = [start]
			seen[start] = true
			var at_edge := false
			while not queue.is_empty():
				var t: Vector2i = queue.pop_back()
				body.append(t)
				at_edge = at_edge or t.x == 0 or t.y == 0 or t.x == tiles.x - 1 or t.y == tiles.y - 1
				for n: Vector2i in [t + Vector2i.LEFT, t + Vector2i.RIGHT, t + Vector2i.UP, t + Vector2i.DOWN]:
					if n.x < 0 or n.y < 0 or n.x >= tiles.x or n.y >= tiles.y or seen.has(n):
						continue
					if source.surface(n) == &"water":
						seen[n] = true
						queue.append(n)
			if at_edge:
				for t in body:
					sea[t] = true
	return sea


## Per tile: how far (in tiles, centre to centre) a sea tile is from the nearest tile that is not
## water (two-pass chamfer distance); 0 off the sea. Beyond the edges the sea runs on (no shore).
func _distance_offshore(sea: Dictionary) -> PackedFloat32Array:
	var tiles := source.tiles
	var d := PackedFloat32Array()
	d.resize(tiles.x * tiles.y)
	var far := float(tiles.x + tiles.y)
	for y in tiles.y:
		for x in tiles.x:
			d[y * tiles.x + x] = far if source.surface(Vector2i(x, y)) == &"water" else 0.0
	var diag := sqrt(2.0)
	for y in tiles.y:
		for x in tiles.x:
			var i := y * tiles.x + x
			if x > 0: d[i] = minf(d[i], d[i - 1] + 1.0)
			if y > 0: d[i] = minf(d[i], d[i - tiles.x] + 1.0)
			if x > 0 and y > 0: d[i] = minf(d[i], d[i - tiles.x - 1] + diag)
			if x < tiles.x - 1 and y > 0: d[i] = minf(d[i], d[i - tiles.x + 1] + diag)
	for y in range(tiles.y - 1, -1, -1):
		for x in range(tiles.x - 1, -1, -1):
			var i := y * tiles.x + x
			if x < tiles.x - 1: d[i] = minf(d[i], d[i + 1] + 1.0)
			if y < tiles.y - 1: d[i] = minf(d[i], d[i + tiles.x] + 1.0)
			if x < tiles.x - 1 and y < tiles.y - 1: d[i] = minf(d[i], d[i + tiles.x + 1] + diag)
			if x > 0 and y < tiles.y - 1: d[i] = minf(d[i], d[i + tiles.x - 1] + diag)
	for y in tiles.y:
		for x in tiles.x:
			if not sea.has(Vector2i(x, y)):
				d[y * tiles.x + x] = 0.0
	return d


# --- painting ------------------------------------------------------------------------------------

## The 2.5D's ground types, one pixel per tile (ZoneTerrain's masks, the same ones).
func _paint_from_tiles() -> void:
	var tiles := source.tiles
	mask_a = Image.create(tiles.x, tiles.y, false, Image.FORMAT_RGBA8)
	mask_b = Image.create(tiles.x, tiles.y, false, Image.FORMAT_RGBA8)
	for y in tiles.y:
		for x in tiles.x:
			var s := source.surface(Vector2i(x, y))
			mask_a.set_pixel(x, y, Color(float(s == &"path"), float(s == &"tall_grass"), float(s == &"water"), float(s == &"forest")))
			mask_b.set_pixel(x, y, Color(float(s == &"sand"), float(s == &"mud"), float(s == &"rock"), 0.0))


## paint: lays a ground type over a disc ("at", "radius_m"), a strip ("from", "to", "width_m"), a
## polyline ("points", "width_m") or a polygon ("polygon", fading out over "feather_m" beyond its
## edge, a tile by default), "amount" of it (0–1, default 1) with soft edges, only where the ground
## stands between "above_m" and "below_m" if given (eased over HEIGHT_EASE_M); "grass" takes the
## others away. Water is not painted: it is the relief's (dig, or the 2.5D's tiles).
func _paint(edit: Dictionary) -> void:
	var ground := String(edit.get("ground", "grass"))
	if ground != "grass" and not GROUNDS.has(ground) or ground == "water":
		push_error("TerrainRelief : sol inconnu ou non peignable « %s »" % ground)
		return
	var amount := clampf(float(edit.get("amount", 1.0)), 0.0, 1.0)
	var soft := float(edit.get("soft", 0.5))
	var tile_m := source.scale
	var line := PackedVector2Array()
	var polygon := PackedVector2Array()
	var reach := float(edit.get("radius_m", 4.0))
	if edit.has("polygon"):
		polygon = SHAPES._points(edit["polygon"])
		line = polygon.duplicate()
		line.append(polygon[0])
		reach = float(edit.get("feather_m", tile_m))
	elif edit.has("points") or edit.has("from"):
		line = SHAPES._points(edit["points"]) if edit.has("points") else PackedVector2Array([_xz(edit["from"]), _xz(edit.get("to", edit["from"]))])
		reach = float(edit.get("width_m", 3.0)) * 0.5
	else:
		line = PackedVector2Array([_xz(edit.get("at", [0, 0]))])
	var area := SHAPES._bounds(line).grow(reach + tile_m)
	var lo := (area.position / tile_m).floor()
	var hi := (area.end / tile_m).ceil()
	for ty in range(maxi(int(lo.y), 0), mini(int(hi.y) + 1, source.tiles.y)):
		for tx in range(maxi(int(lo.x), 0), mini(int(hi.x) + 1, source.tiles.x)):
			var p := (Vector2(tx, ty) + Vector2.ONE * 0.5) * tile_m   # the tile's centre
			var w := amount * _within_heights(edit, p)
			if not polygon.is_empty():
				var d := SHAPES._distance_to(line, p.x, p.y)
				w *= 1.0 if Geometry2D.is_point_in_polygon(p, polygon) else 1.0 - smoothstep(0.0, reach, d)
			else:
				var d := line[0].distance_to(p) if line.size() == 1 else SHAPES._distance_to(line, p.x, p.y)
				w *= _bell(d, reach + tile_m * 0.5, soft)
			if w > 0.0:
				_paint_tile(Vector2i(tx, ty), ground, w)


## How much of a paint lands at `p` for its height band ("above_m", "below_m"): 1 inside, eased out.
func _within_heights(edit: Dictionary, p: Vector2) -> float:
	if not edit.has("above_m") and not edit.has("below_m"):
		return 1.0
	var h := height_at(p.x, p.y)
	var w := 1.0
	if edit.has("above_m"):
		w *= smoothstep(float(edit["above_m"]) - HEIGHT_EASE_M, float(edit["above_m"]), h)
	if edit.has("below_m"):
		w *= 1.0 - smoothstep(float(edit["below_m"]), float(edit["below_m"]) + HEIGHT_EASE_M, h)
	return w


## paint_reset: clears the painting, but the grounds listed in "keep" (default: the tall grass and
## the water, the rules' own tiles).
func _paint_reset(edit: Dictionary) -> void:
	var keep: Array = edit.get("keep", ["tall_grass", "water"])
	var ka := Color(float("path" in keep), float("tall_grass" in keep), float("water" in keep), float("forest" in keep))
	var kb := Color(float("sand" in keep), float("mud" in keep), float("rock" in keep), 1.0)
	for y in source.tiles.y:
		for x in source.tiles.x:
			mask_a.set_pixel(x, y, mask_a.get_pixel(x, y) * ka)
			mask_b.set_pixel(x, y, mask_b.get_pixel(x, y) * kb)


func _paint_tile(tile: Vector2i, ground: String, w: float) -> void:
	var ca := mask_a.get_pixelv(tile)
	var cb := mask_b.get_pixelv(tile)
	# whatever was there gives way (but not the water: it is the relief's)
	ca = Color(ca.r * (1.0 - w), ca.g * (1.0 - w), ca.b, ca.a * (1.0 - w))
	cb = Color(cb.r * (1.0 - w), cb.g * (1.0 - w), cb.b * (1.0 - w), cb.a)
	if ground != "grass":
		var where: Array = GROUNDS[ground]
		if where[0] == 0:
			ca[where[1]] = maxf(ca[where[1]], w)
		else:
			cb[where[1]] = maxf(cb[where[1]], w)
	mask_a.set_pixelv(tile, ca)
	mask_b.set_pixelv(tile, cb)
