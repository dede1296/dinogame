extends RefCounted
## The ground of a 3D zone as its little life sees it (Wildlife3D): what each square metre is (water,
## a path, grass, the woods, sand, mud, rock), read from the zone as it is drawn and walked — its water
## (ZoneTerrain), its relief's painting (a remodelled zone's paths and sands), the 2.5D's tiles for the
## woods — once per cell, as needed; and the rules of WildlifeDB's kinds on it: the ground a kind lives
## on ("on"), what it keeps near or away from ("near", "far"), those on foot never on a path nor in
## the water nor up a cliff.

const STANDING: Array[StringName] = [&"walk", &"hop"]
const CELL_M := 1.0
const WET_M := 0.03           # water this deep is water (a wet bank is not)
const STEEP := 1.2            # a walker stops at ground this steep (rise over run: a cliff's face)

var source: ZoneSource
var terrain: ZoneTerrain
var _cells := Vector2i.ZERO
var _ground := PackedByteArray()       # per cell: 0 = not read yet, else an index into _names + 1
var _names: Array[StringName] = []


func _init(src: ZoneSource, ground: ZoneTerrain) -> void:
	source = src
	terrain = ground
	var size := src.size_m()
	_cells = Vector2i(ceili(size.x / CELL_M), ceili(size.y / CELL_M))
	_ground.resize(_cells.x * _cells.y)


## The ground at `p` (m of the zone); &"" outside the zone. Read once per cell.
func surface(p: Vector2) -> StringName:
	var c := Vector2i((p / CELL_M).floor())
	if c.x < 0 or c.y < 0 or c.x >= _cells.x or c.y >= _cells.y:
		return &""
	var i := c.y * _cells.x + c.x
	if _ground[i] == 0:
		var s := _read((Vector2(c) + Vector2.ONE * 0.5) * CELL_M)
		var k := _names.find(s)
		if k < 0:
			_names.append(s)
			k = _names.size() - 1
		_ground[i] = k + 1
	return _names[_ground[i] - 1]


## Water where the zone's water stands; a remodelled zone's paths; else what the ground is painted with
## (its relief's painting), the woods where the 2.5D's are (Scatter3D sows them there); without a
## relief (the home-made ground), the 2.5D's tile.
func _read(m: Vector2) -> StringName:
	if terrain.water_depth_at(m.x, m.y) > WET_M:
		return &"water"
	if terrain.is_remodelled() and terrain.near_path(m.x, m.y, 0.0):
		return &"path"
	var tile := source.tile_at(m.x, m.y)
	var own := source.surface(tile)
	var relief := terrain.relief
	if relief == null or relief.mask_a == null:
		return &"grass" if own == &"water" else own   # (dry here in 3D: its bank)
	var a := relief.mask_a.get_pixelv(tile)   # R path, G tall grass, B water, A woods
	var b := relief.mask_b.get_pixelv(tile)   # R sand, G mud, B rock
	if a.r > 0.5:
		return &"path"
	if own == &"forest" or a.a > 0.5:
		return &"forest"
	if b.b > 0.5:
		return &"rock"
	if b.r > 0.5:
		return &"sand"
	if b.g > 0.5:
		return &"mud"
	if a.g > 0.5:
		return &"tall_grass"
	return &"grass"


## A spot the kind may be at: on its ground, near and far from what it should be.
func fits(p: Vector2, kind: Dictionary) -> bool:
	if not on_ground(p, kind):
		return false
	var near: Dictionary = kind.get("near", {})
	for s: StringName in near:
		if not within(p, s, near[s]):
			return false
	var far: Dictionary = kind.get("far", {})
	for s: StringName in far:
		if within(p, s, far[s]):
			return false
	return true


## Inside the zone, on a ground the kind lives on; on foot, never on a path nor in the water.
func on_ground(p: Vector2, kind: Dictionary) -> bool:
	var s := surface(p)
	if s == &"":
		return false
	if kind.get("motion", &"") in STANDING and (s == &"path" or s == &"water"):
		return false
	var on: Array = kind.get("on", [])
	return on.is_empty() or s in on


## Is there that ground (&"land": any but water) within `r` m of `p`?
func within(p: Vector2, ground: StringName, r: float) -> bool:
	var step := CELL_M if r <= 3.0 else CELL_M * 2.0
	var n := ceili(r / step)
	for dz in range(-n, n + 1):
		for dx in range(-n, n + 1):
			var d := Vector2(dx, dz) * step
			if d.length_squared() > r * r:
				continue
			var s := surface(p + d)
			if s == ground or (ground == &"land" and s != &"water" and s != &""):
				return true
	return false


## A step from `from` to `to` stays on the kind's ground and does not go up (or down) a cliff.
func can_step(kind: Dictionary, from: Vector2, to: Vector2) -> bool:
	if Vector2i((to / CELL_M).floor()) != Vector2i((from / CELL_M).floor()) and not on_ground(to, kind):
		return false
	var run := from.distance_to(to)
	return run < 0.0001 or absf(height(to) - height(from)) <= STEEP * run + 0.002


func height(p: Vector2) -> float:
	return terrain.height_at(p.x, p.y)


## The water's level over `p` (-INF: none).
func water_level(p: Vector2) -> float:
	return terrain.water_level_at(p.x, p.y)


## What the kind stands on or flies over: the ground, or the water over it.
func base(kind: Dictionary, p: Vector2) -> float:
	if kind.get("motion", &"") in STANDING:
		return height(p)
	return maxf(height(p), water_level(p))
