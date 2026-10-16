class_name HeightMap
extends RefCounted
## Ground height of a zone in 3D, from its 2D data: each tile's height (Region.tile_height:
## a relief image for big regions, relief levels for small zones), smoothed into hills,
## sharpened into cliffs where neighbouring tiles differ a lot; the water dug in; a gentle
## rolling. 1 tile = 1 metre; the 2D world (y down) maps to 3D x/z.
## Sampled RES times per metre into a float texture: the ground's vertex shader reads it to
## raise its flat grid chunks, and height() reads the same samples on the CPU.

const PX := 48.0                 # 2D pixels per tile (= per metre)
const LEVEL_HEIGHT := 1.2        # metres between two relief levels (small zones)
const WATER_DEPTH := 0.85
## The water sheet: exactly where the dug ground crosses the painted water's edge.
const WATER_LEVEL := -WATER_DEPTH * 0.5
const MARGIN := 10               # ground beyond the zone (tiles), so no edge shows
const RES := 2                   # height samples per metre
## From this height difference between two tiles (m), the slope between them is sharpened
## into a cliff (smooth hills below it).
const CLIFF_FROM := 0.45
const DOCK_TOP := 0.08
## A ford of stones (MoonFord): their tops just out of the water.
const FORD_TOP := WATER_LEVEL + 0.1
## Farther than this from its tile's level (m), a point is on a cliff face (see to_3d).
const STAND_SNAP := 0.35

var size := Vector2i.ZERO        # zone size in tiles
## Ground mesh vertices per metre (quality): used by the view to build its chunks.
var step := 4
var has_water := false
## Ground beyond the zone's edges (tiles): none indoors, the room floats on black.
var margin := MARGIN
## Piers (tiles): walking there, you stand on the planks, not on the dug ground below.
var docks: Array[Rect2] = []
var _fords: Array[Rect2] = []

var _tiles := PackedFloat32Array()   # per tile: its height (m)
var _water := PackedFloat32Array()   # per tile: 1 = water, 0 = land
var _samples := PackedFloat32Array()
var _sw := 0
var _sh := 0
var _texture: ImageTexture
## What the relief was measured from (signature()): two zones with the same key have the same relief.
var key := ""

## Reliefs already measured (key -> HeightMap), the last used last: a zone change measures the new
## zone and every neighbour shown beyond its edges, mostly zones measured a moment ago (the zone just
## left, the one seen beyond the edge before going there). At most KNOWN_MAX of them.
static var _known: Dictionary = {}
const KNOWN_MAX := 12


## The relief of `region` (no region: an empty one, filled by of()).
func _init(region: Region = null, grid_step := 4) -> void:
	step = grid_step
	if region == null:
		return
	margin = 0 if region.indoor else MARGIN
	for dock in region.docks():
		docks.append(Rect2(dock.area().position / PX, dock.area().size / PX))
		if dock is MoonFord:
			_fords.append(docks[-1])
	size = region.map_size()
	_tiles.resize(size.x * size.y)
	_water.resize(size.x * size.y)
	for y in size.y:
		for x in size.x:
			var i := y * size.x + x
			_tiles[i] = region.tile_height(Vector2i(x, y))
			var is_water := region.surface_at(Vector2((x + 0.5) * PX, (y + 0.5) * PX)) == &"water"
			# Under a pier the water goes on (the planks stand above it).
			for d in docks:
				if d.has_point(Vector2(x + 0.5, y + 0.5)):
					is_water = true
			_water[i] = 1.0 if is_water else 0.0
			has_water = has_water or is_water
	_fill_samples()


## The relief of `region` as HeightMap.new() measures it, measured only once for the same content
## (signature()): the zone views (WorldView) ask for it at every zone change.
static func of(region: Region, grid_step := 4) -> HeightMap:
	var sig := "%s|%d" % [signature(region), grid_step]   # (the grid step too: its samples depend on it)
	var known: HeightMap = _known.get(sig)
	if known:
		_known.erase(sig)   # (back at the end: the last used)
	else:
		known = HeightMap.new(region, grid_step)
		known.key = sig
		known.height_texture()   # (made once, shared by every copy)
		if _known.size() >= KNOWN_MAX:
			_known.erase(_known.keys()[0])
	_known[sig] = known
	return known._copy(grid_step)


## Everything the relief is measured from: the tiles (their ground: water), the heights (height_data,
## relief), the piers, indoors or not, and where the terrain lies (surface_at reads it in place).
static func signature(region: Region) -> String:
	var ground := region.terrain
	var heights := region.height_data
	var piers := []
	for dock in region.docks():
		piers.append([dock.area(), dock is MoonFord])
	var cells := ground.tile_map_data
	return "%d|%d|%s|%d|%d|%s|%s|%d" % [hash(cells), cells.size(),
		ground.get_global_transform() if ground.is_inside_tree() else Transform2D.IDENTITY,
		hash(heights.get_data()) if heights else 0, hash(region.relief), heights.get_size() if heights else Vector2i.ZERO,
		region.indoor, hash(var_to_str(piers))]


## A copy of this relief for a ground grid of `grid_step` vertices per metre (its arrays shared:
## nobody writes in them once measured).
func _copy(grid_step: int) -> HeightMap:
	var out := HeightMap.new(null, grid_step)
	out.size = size
	out.has_water = has_water
	out.margin = margin
	out.docks = docks.duplicate()
	out._fords = _fords.duplicate()
	out._tiles = _tiles
	out._water = _water
	out._samples = _samples
	out._sw = _sw
	out._sh = _sh
	out._texture = _texture
	out.key = key
	return out


## Every sample of _exact(), its waves along each column and each row worked out once (the very
## same sums: the very same heights).
func _fill_samples() -> void:
	_sw = (size.x + margin * 2) * RES + 1
	_sh = (size.y + margin * 2) * RES + 1
	_samples.resize(_sw * _sh)
	var d := 1.0 / RES
	var waves_x: Array[PackedFloat64Array] = [PackedFloat64Array(), PackedFloat64Array(), PackedFloat64Array(), PackedFloat64Array()]
	for gx in _sw:
		var x := gx * d - margin
		waves_x[0].append(x)
		waves_x[1].append(sin(x * 1.9 + 0.2))
		waves_x[2].append(sin(x * 1.7 + 1.1))
		waves_x[3].append(0.08 * sin(x * 0.45 + 1.3))
	var xs := waves_x[0]
	var cliff_x := waves_x[1]
	var water_x := waves_x[2]
	var roll_x := waves_x[3]
	for gy in _sh:
		var z := gy * d - margin
		var cliff_z := sin(z * 2.3 + 0.7)
		var water_z := sin(z * 2.1 + 0.4)
		var roll_z := sin(z * 0.38 + 0.4)
		var row := gy * _sw
		for gx in _sw:
			_samples[row + gx] = _exact(xs[gx], z, cliff_z, cliff_x[gx], water_z, water_x[gx], roll_x[gx] * roll_z)


## World position (3D) of a 2D point, standing on the ground (or on a pier).
func to_3d(p: Vector2) -> Vector3:
	var t := p / PX
	for d in docks:
		if d.has_point(t):
			return Vector3(t.x, FORD_TOP if d in _fords else DOCK_TOP, t.y)
	# By a cliff, the smooth ground there is the rock face: stand on the tile's own level.
	var h := height(t)
	var cell := Vector2i(clampi(floori(t.x), 0, size.x - 1), clampi(floori(t.y), 0, size.y - 1))
	var own := _tile(cell.x, cell.y)
	if absf(h - own) > STAND_SNAP and _water[cell.y * size.x + cell.x] == 0.0:   # (water is dug below)
		h = own
	return Vector3(t.x, h, t.y)


## Height (m) at a point given in tiles (bilinear between the samples, like the GPU does).
func height(t: Vector2) -> float:
	var gx := (t.x + margin) * RES
	var gy := (t.y + margin) * RES
	var ix := clampi(floori(gx), 0, _sw - 2)
	var iy := clampi(floori(gy), 0, _sh - 2)
	var fx := clampf(gx - ix, 0.0, 1.0)
	var fy := clampf(gy - iy, 0.0, 1.0)
	var a := lerpf(_samples[iy * _sw + ix], _samples[iy * _sw + ix + 1], fx)
	var b := lerpf(_samples[(iy + 1) * _sw + ix], _samples[(iy + 1) * _sw + ix + 1], fx)
	return lerpf(a, b, fy)


## Lowest and highest ground (m) inside a rectangle given in tiles.
func range_in(rect: Rect2) -> Vector2:
	var x0 := clampi(floori((rect.position.x + margin) * RES), 0, _sw - 1)
	var y0 := clampi(floori((rect.position.y + margin) * RES), 0, _sh - 1)
	var x1 := clampi(ceili((rect.end.x + margin) * RES), 0, _sw - 1)
	var y1 := clampi(ceili((rect.end.y + margin) * RES), 0, _sh - 1)
	var lo := INF
	var hi := -INF
	for gy in range(y0, y1 + 1):
		for gx in range(x0, x1 + 1):
			var v := _samples[gy * _sw + gx]
			lo = minf(lo, v)
			hi = maxf(hi, v)
	return Vector2(lo, hi)


## The area covered by the ground, in tiles (the zone and its margin).
func extent() -> Rect2:
	return Rect2(Vector2(-margin, -margin), Vector2(size) + Vector2.ONE * margin * 2.0)


## The height samples as a half-float texture (filterable on phones), with what a shader
## needs to read it: {texture, origin (m), res (samples per m), texels}.
func height_texture() -> Dictionary:
	if _texture == null:
		var img := Image.create_empty(_sw, _sh, false, Image.FORMAT_RH)
		for gy in _sh:
			for gx in _sw:
				img.set_pixel(gx, gy, Color(_samples[gy * _sw + gx], 0, 0))
		_texture = ImageTexture.create_from_image(img)
	return {"texture": _texture, "origin": Vector2(-margin, -margin), "res": float(RES), "texels": Vector2(_sw, _sh)}


func _tile(x: int, y: int) -> float:
	return _tiles[clampi(y, 0, size.y - 1) * size.x + clampi(x, 0, size.x - 1)]


## The ground's height at (x, z) (tiles), given its waves there (see _fill_samples): `cliff_z` =
## sin(z * 2.3 + 0.7), `cliff_x` = sin(x * 1.9 + 0.2), `water_z` = sin(z * 2.1 + 0.4), `water_x` =
## sin(x * 1.7 + 1.1), `roll` = 0.08 * sin(x * 0.45 + 1.3) * sin(z * 0.38 + 0.4). (Reading the
## tiles written out here: called for every sample, small functions cost more than their sums.)
func _exact(x: float, z: float, cliff_z: float, cliff_x: float, water_z: float, water_x: float, roll: float) -> float:
	var w := size.x
	var last_x := size.x - 1
	var last_z := size.y - 1
	# Tiles are read at their centres, with a slight wobble so cliff lines are not straight;
	# none by the zone's edges: a cliff running on into the neighbour shown beyond an edge
	# meets its own there exactly (no crack between the two rock faces).
	var edge := minf(minf(x, z), minf(size.x - x, size.y - z))
	var wobble := 0.12 * smoothstep(0.0, 2.0, edge)
	var sx := x - 0.5 + wobble * cliff_z
	var sz := z - 0.5 + wobble * cliff_x
	var cx := floori(sx)
	var cz := floori(sz)
	var fx := sx - cx
	var fz := sz - cz
	var x0 := clampi(cx, 0, last_x)
	var x1 := clampi(cx + 1, 0, last_x)
	var z0 := clampi(cz, 0, last_z) * w
	var z1 := clampi(cz + 1, 0, last_z) * w
	var h00 := _tiles[z0 + x0]
	var h10 := _tiles[z0 + x1]
	var h01 := _tiles[z1 + x0]
	var h11 := _tiles[z1 + x1]
	# Between two tiles, the fraction is sharpened into a cliff when their heights differ by more
	# than CLIFF_FROM (smoothstep); below that, it is left as it is.
	var diff := h10 - h00
	var k := clampf((absf(diff) - CLIFF_FROM) / 0.5, 0.0, 1.0)
	var top := lerpf(h00, h10, lerpf(fx, smoothstep(0.3, 0.7, fx), k) if k > 0.0 else fx)
	diff = h11 - h01
	k = clampf((absf(diff) - CLIFF_FROM) / 0.5, 0.0, 1.0)
	var bottom := lerpf(h01, h11, lerpf(fx, smoothstep(0.3, 0.7, fx), k) if k > 0.0 else fx)
	diff = bottom - top
	k = clampf((absf(diff) - CLIFF_FROM) / 0.5, 0.0, 1.0)
	var h := lerpf(top, bottom, lerpf(fz, smoothstep(0.3, 0.7, fz), k) if k > 0.0 else fz)
	# Water: the water tiles read between their centres, so the half-way line (the shore)
	# runs along the painted water's edge, corners rounded, with a slight wobble; beyond the
	# zone, the nearest edge tile (a sea goes on past it).
	var wx := x - 0.5 + 0.1 * water_z
	var wz := z - 0.5 + 0.1 * water_x
	var c := Vector2i(floori(wx), floori(wz))
	var f := Vector2(wx - c.x, wz - c.y)
	x0 = clampi(c.x, 0, last_x)
	x1 = clampi(c.x + 1, 0, last_x)
	z0 = clampi(c.y, 0, last_z) * w
	z1 = clampi(c.y + 1, 0, last_z) * w
	var wt := lerpf(_water[z0 + x0], _water[z0 + x1], f.x)
	var wb := lerpf(_water[z1 + x0], _water[z1 + x1], f.x)
	var wet := lerpf(wt, wb, f.y)
	h -= WATER_DEPTH * smoothstep(0.15, 0.85, wet)
	# Gentle rolling: none by the water (the shore stays where it is painted), and none near
	# the zone's edges, so a neighbour shown beyond the edge meets it at the same height.
	h += roll * (1.0 - smoothstep(0.0, 0.45, wet)) * smoothstep(0.0, 3.0, edge)
	return h
