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

var _tiles := PackedFloat32Array()   # per tile: its height (m)
var _water := PackedFloat32Array()   # per tile: 1 = water, 0 = land
var _samples := PackedFloat32Array()
var _sw := 0
var _sh := 0
var _texture: ImageTexture


func _init(region: Region, grid_step := 4) -> void:
	step = grid_step
	margin = 0 if region.indoor else MARGIN
	for dock in region.docks():
		docks.append(Rect2(dock.area().position / PX, dock.area().size / PX))
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
	_sw = (size.x + margin * 2) * RES + 1
	_sh = (size.y + margin * 2) * RES + 1
	_samples.resize(_sw * _sh)
	var d := 1.0 / RES
	for gy in _sh:
		for gx in _sw:
			_samples[gy * _sw + gx] = _exact(gx * d - margin, gy * d - margin)


## World position (3D) of a 2D point, standing on the ground (or on a pier).
func to_3d(p: Vector2) -> Vector3:
	var t := p / PX
	for d in docks:
		if d.has_point(t):
			return Vector3(t.x, DOCK_TOP, t.y)
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


## A fraction between two tiles, sharpened into a cliff when their heights differ a lot.
static func _sharpen(f: float, diff: float) -> float:
	var k := clampf((absf(diff) - CLIFF_FROM) / 0.5, 0.0, 1.0)
	return lerpf(f, smoothstep(0.3, 0.7, f), k)


func _exact(x: float, z: float) -> float:
	# Tiles are read at their centres, with a slight wobble so cliff lines are not straight.
	var sx := x - 0.5 + 0.12 * sin(z * 2.3 + 0.7)
	var sz := z - 0.5 + 0.12 * sin(x * 1.9 + 0.2)
	var cx := floori(sx)
	var cz := floori(sz)
	var fx := sx - cx
	var fz := sz - cz
	var h00 := _tile(cx, cz)
	var h10 := _tile(cx + 1, cz)
	var h01 := _tile(cx, cz + 1)
	var h11 := _tile(cx + 1, cz + 1)
	var top := lerpf(h00, h10, _sharpen(fx, h10 - h00))
	var bottom := lerpf(h01, h11, _sharpen(fx, h11 - h01))
	var h := lerpf(top, bottom, _sharpen(fz, bottom - top))
	# Water: the water tiles read between their centres, so the half-way line (the shore)
	# runs along the painted water's edge, corners rounded, with a slight wobble.
	var wx := x - 0.5 + 0.1 * sin(z * 2.1 + 0.4)
	var wz := z - 0.5 + 0.1 * sin(x * 1.7 + 1.1)
	var c := Vector2i(floori(wx), floori(wz))
	var f := Vector2(wx - c.x, wz - c.y)
	var wt := lerpf(_water_at(c), _water_at(c + Vector2i(1, 0)), f.x)
	var wb := lerpf(_water_at(c + Vector2i(0, 1)), _water_at(c + Vector2i(1, 1)), f.x)
	var wet := lerpf(wt, wb, f.y)
	h -= WATER_DEPTH * smoothstep(0.15, 0.85, wet)
	# Gentle rolling: none by the water (the shore stays where it is painted), and none near
	# the zone's edges, so a neighbour shown beyond the edge meets it at the same height.
	var inland := minf(minf(x, z), minf(size.x - x, size.y - z))
	h += 0.08 * sin(x * 0.45 + 1.3) * sin(z * 0.38 + 0.4) * (1.0 - smoothstep(0.0, 0.45, wet)) * smoothstep(0.0, 3.0, inland)
	return h


## Water around a tile; beyond the zone, the nearest edge tile (a sea goes on past it).
func _water_at(c: Vector2i) -> float:
	c = Vector2i(clampi(c.x, 0, size.x - 1), clampi(c.y, 0, size.y - 1))
	return _water[c.y * size.x + c.x]
