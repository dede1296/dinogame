class_name ZoneSource
extends RefCounted
## A 2.5D zone read as the plan of a 3D one (docs/migration-3d.md, phase 4) — the DATA layer of a 3D
## zone, nothing drawn. The 2.5D scene (regions/…/<zone>.tscn) is opened out of the tree
## (Region.open_for_preview): none of its scripts runs, it is only read.
## The 3D zone is the same map, larger: `scale` metres per tile horizontally (Greg, 04/10: wider
## regions, the 3D crossing them faster); heights stay true (a 1.2 m relief level stays 1.2 m).
## What stands on it keeps its real size (trees, rocks, people, dinos): only places are spread out.
## The relief is the 2.5D's own (HeightMap: levels, cliffs, dug water).

const PX := 48.0                  # 2.5D pixels per tile
const DEFAULT_SCALE := 2.0
const PROP_SCRIPT := preload("res://world/prop.gd")
const WORLD := preload("res://world/world.gd")   # its ZONES: zone id → scene

var id: StringName
var region: Region
var heights: HeightMap
## Metres of the 3D zone per tile of the 2.5D one.
var scale := DEFAULT_SCALE
var tiles := Vector2i.ZERO

var _surfaces: Array[StringName] = []   # per tile (row by row)
var _tile_heights := PackedFloat32Array()  # per tile (m)
var _floor := 0.0                       # the zone's lowest ground (Region.floor_height), read once


## The 2.5D zone `zone_id` (an id of World.ZONES), read at `scale` m per tile. Null if unknown.
static func open(zone_id: StringName, zone_scale := DEFAULT_SCALE) -> ZoneSource:
	if not WORLD.ZONES.has(zone_id):
		push_error("ZoneSource : zone inconnue %s" % zone_id)
		return null
	var src := ZoneSource.new()
	src.id = zone_id
	src.scale = zone_scale
	src.region = Region.open_for_preview(WORLD.ZONES[zone_id])
	src.heights = HeightMap.new(src.region, 2)
	src.tiles = src.region.map_size()
	src._read_surfaces()
	return src


## Frees the 2.5D scene once everything is read and built.
func close() -> void:
	if is_instance_valid(region):
		region.free()


## Size of the 3D zone (m).
func size_m() -> Vector2:
	return Vector2(tiles) * scale


## The area around it that is still ground (the 2.5D's margin, m): no edge shows in the distance.
func margin_m() -> float:
	return heights.margin * scale


## Ground height (m) at a point of the 3D zone (metres): the 2.5D's relief, smooth, except by a
## cliff where the tile's own level holds (as HeightMap.to_3d stands people), so a cliff stays a
## steep face over the wider map instead of a slope one could half climb.
func height_at(x: float, z: float) -> float:
	var t := Vector2(x, z) / scale
	var h := heights.height(t)
	var tile := tile_at(x, z)
	var own := tile_height(tile)
	if absf(h - own) > HeightMap.STAND_SNAP and surface(tile) != &"water":
		return own
	return h


## A 2.5D position (pixels of the zone) in the 3D zone, on the ground.
func to_3d(px: Vector2) -> Vector3:
	var t := px / PX
	return Vector3(t.x * scale, heights.to_3d(px).y, t.y * scale)


## The tile under a point of the 3D zone.
func tile_at(x: float, z: float) -> Vector2i:
	return Vector2i(clampi(floori(x / scale), 0, tiles.x - 1), clampi(floori(z / scale), 0, tiles.y - 1))


## Ground type of a tile: grass, path, tall_grass, water, forest, sand, mud, rock (Region.surface_at).
func surface(tile: Vector2i) -> StringName:
	if tile.x < 0 or tile.y < 0 or tile.x >= tiles.x or tile.y >= tiles.y:
		return &"grass"
	return _surfaces[tile.y * tiles.x + tile.x]


func tile_height(tile: Vector2i) -> float:
	var t := Vector2i(clampi(tile.x, 0, tiles.x - 1), clampi(tile.y, 0, tiles.y - 1))
	return _tile_heights[t.y * tiles.x + t.x]


## A cliff between two tiles' heights (the 2.5D's rule: Region.cliff_between).
func is_cliff(a: float, b: float) -> bool:
	return region.cliff_between(a, b, _floor)


## Where Chloé arrives by `spawn_name` (Spawns/<name> of the 2.5D zone), in the 3D zone.
func spawn(spawn_name: StringName) -> Vector3:
	var marker := region.get_node_or_null(NodePath("Spawns/" + String(spawn_name))) as Node2D
	if marker == null:
		push_error("ZoneSource : point d'arrivée introuvable %s" % spawn_name)
		return Vector3(size_m().x * 0.5, 0.0, size_m().y * 0.5)
	return to_3d(_zone_position(marker))


## The plain scenery of the zone (Prop, not story props): [{kind, at (Vector3), flip, solid}],
## `solid` as Prop.KINDS gives it (a radius or a size in px, 0: walked through).
func props() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for node in region.entities.get_children():
		if node.get_script() != PROP_SCRIPT:
			continue
		var def: Dictionary = Prop.KINDS.get(node.kind, {})
		if def.is_empty():
			continue
		out.append({"kind": String(node.kind), "at": to_3d(_zone_position(node)), "flip": bool(node.flip), "solid": def.get("solid", 0.0)})
	return out


## The zone's habitats: [{area (Rect2, m of the 3D zone), encounters (Array[Encounter]), roamers}].
func habitats() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for h in region.habitats():
		var at := _zone_position(h)
		var rect := Rect2(at / PX * scale, h.size / PX * scale)   # (its position: the top left corner)
		out.append({"area": rect, "encounters": h.encounters, "roamers": h.roamers, "label": h.label})
	return out


## Reads the ground types and heights of every tile once (the 2.5D's per-tile queries are slow to
## repeat: Region.floor_height goes over the whole zone).
func _read_surfaces() -> void:
	_surfaces.resize(tiles.x * tiles.y)
	_tile_heights.resize(tiles.x * tiles.y)
	_floor = INF
	for y in tiles.y:
		for x in tiles.x:
			_surfaces[y * tiles.x + x] = region.surface_at(Vector2((x + 0.5) * PX, (y + 0.5) * PX))
			var h := region.tile_height(Vector2i(x, y))
			_tile_heights[y * tiles.x + x] = h
			_floor = minf(_floor, h)


## A node's position in the zone (px), out of the tree (its parents' transforms up to the region).
func _zone_position(node: Node2D) -> Vector2:
	var t := Transform2D.IDENTITY
	var n: Node = node
	while n != null and n != region:
		if n is Node2D:
			t = (n as Node2D).transform * t
		n = n.get_parent()
	return t.origin
