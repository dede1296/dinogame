@tool
class_name Region
extends Node2D
## Root of a region scene (regions/<name>/<name>.tscn). Expected children:
##   Terrain  — TileMapLayer painted with regions/terrain_tileset.tres (path, tall grass,
##              water; empty cells or "grass" = grass). Drawn by Ground, hidden in game.
##   Ground   — Ground node drawing the terrain.
##   Entities — Y-sorted: props, characters, dinos. Chloé and her dino are added here.
##   Spawns   — Marker2D arrival points ("Depart" = new game).

## Id of this zone (what the save and the ZoneExits use).
@export var region_id: StringName
## Name of the region the zone belongs to ("Plaines des Fougères")…
@export var display_name := ""
## …and of the zone itself ("Prairie du Débarcadère").
@export var zone_name := ""
## Levels of the wild dinos here; the party learns faster while behind.
@export var levels := Vector2i(2, 5)
## Amber pebbles hidden in the zone (see Search): how many there are to find.
@export var pebbles := 0
@export var music: AudioStream
## The sounds of the place, under the music: a kind of place of AmbienceDB (&"plaines"…).
@export var ambience_id: StringName
## Inside a building: no sky, no weather, a warm lamp light, the room floating on black.
@export var indoor := false
## Indoors and dark (a cave): a dim bluish light, the amber crystals glowing.
@export var cave := false
## Ground textures: the plain ground ("grass" cells) and the "path" cells (null = the defaults:
## grass and dirt; e.g. cobbles in a village, floorboards indoors).
@export var ground_tex: Texture2D
@export var path_tex: Texture2D
## Where path_tex is used (tiles); elsewhere the paths are plain dirt. Empty = everywhere.
## (A village paved with cobbles, and its road out of it in dirt, like the next zone's.)
@export var paved_rect := Rect2()
## The picture behind the battles fought here (assets/art/battle; its platforms where the
## others have them). Null: the meadow of the Plaines, or the cave's in a cave zone.
@export var battle_backdrop: Texture2D
## Chances per game hour that rain or mist sets in here.
@export_range(0.0, 1.0) var rain_chance := 0.08
@export_range(0.0, 1.0) var mist_chance := 0.1
@export_range(0.0, 1.0) var storm_chance := 0.03
## Relief, one text row per tile row: 0–9 = level (1.2 m each), r = ramp between levels,
## anything else = 0 (small zones and interiors). Empty = flat zone, or height_data.
@export var relief: PackedStringArray = []
## Relief of a big region: one pixel per tile, its height in metres (FORMAT_RF). Made by the
## zone's plan from its relief image (tools/maps/<id>_relief.png). Where two neighbouring
## tiles differ by more than CLIFF_STEP, there is a cliff Chloé cannot climb.
@export var height_data: Image

## Height difference (m) between two neighbouring tiles from which one can't walk between them.
const CLIFF_STEP := 0.75
## Half the thickness of a cliff wall (px): as deep as the rock face is drawn, so nobody
## stands on its foot or its lip.
const WALL_HALF := 12.0

@onready var terrain: TileMapLayer = $Terrain
@onready var entities: Node2D = $Entities


func _ready() -> void:
	if Engine.is_editor_hint():
		terrain.modulate = Color(1, 1, 1, 0.3)   # painting guide over the ground preview
		return
	terrain.visible = false
	_add_bounds()
	_add_cliffs()
	_clear_exit_corridors()


func tile_size() -> Vector2:
	return Vector2(terrain.tile_set.tile_size)


## The region's area in world pixels.
func bounds() -> Rect2:
	var used := terrain.get_used_rect()
	return Rect2(Vector2(used.position) * tile_size(), Vector2(used.size) * tile_size())


## Size of the region in tiles.
func map_size() -> Vector2i:
	return terrain.get_used_rect().end


## Ground height (m) of a tile: from height_data, or from the relief levels (a ramp takes
## the middle of the neighbours it joins). Outside the map: the nearest edge tile.
func tile_height(cell: Vector2i) -> float:
	if height_data:
		var c := Vector2i(clampi(cell.x, 0, height_data.get_width() - 1), clampi(cell.y, 0, height_data.get_height() - 1))
		return height_data.get_pixelv(c).r
	if relief.is_empty():
		return 0.0
	var size := map_size()
	cell = Vector2i(clampi(cell.x, 0, size.x - 1), clampi(cell.y, 0, size.y - 1))
	var lvl := relief_at(cell)
	if lvl >= 0:
		return lvl * 1.2
	var best := [0, 0]
	var best_d := -1
	for axis: Array in [[Vector2i.LEFT, Vector2i.RIGHT], [Vector2i.UP, Vector2i.DOWN]]:
		var a := relief_at(cell + axis[0])
		var b := relief_at(cell + axis[1])
		if a >= 0 and b >= 0 and absi(a - b) > best_d:
			best_d = absi(a - b)
			best = [a, b]
	return (best[0] + best[1]) * 0.6


## Ground type at a world position: &"grass", &"path", &"tall_grass", &"water", &"forest" or &"sand".
func surface_at(world_pos: Vector2) -> StringName:
	# (A zone opened only for a preview is not in the tree: it sits at the origin.)
	var local := terrain.to_local(world_pos) if terrain.is_inside_tree() else world_pos
	var data := terrain.get_cell_tile_data(terrain.local_to_map(local))
	if data == null:
		return &"grass"
	return StringName(data.get_custom_data("terrain"))


func spawn_point(spawn_name: StringName = &"Depart") -> Vector2:
	var marker := get_node_or_null(NodePath("Spawns/" + String(spawn_name))) as Node2D
	if marker == null:
		push_error("Point d'arrivée introuvable : %s" % spawn_name)
		return bounds().get_center()
	return marker.global_position


func habitats() -> Array[Habitat]:
	var out: Array[Habitat] = []
	out.assign(find_children("*", "Habitat", true, false))
	return out


func docks() -> Array[Dock]:
	var out: Array[Dock] = []
	out.assign(find_children("*", "Dock", true, false))
	return out


func exits() -> Array[ZoneExit]:
	var out: Array[ZoneExit] = []
	out.assign(find_children("*", "ZoneExit", true, false))
	return out


## The habitat under a world position (the last one listed wins where they overlap), or null.
func habitat_at(p: Vector2) -> Habitat:
	var found: Habitat = null
	for h in habitats():
		if h.has_point(p):
			found = h
	return found


## Relief level of a cell (0–9), or -1 for a ramp.
func relief_at(cell: Vector2i) -> int:
	if cell.y < 0 or cell.y >= relief.size():
		return 0
	var row := relief[cell.y]
	if cell.x < 0 or cell.x >= row.length():
		return 0
	var c := row[cell.x]
	if c == "r":
		return -1
	return int(c) if c.is_valid_int() else 0


## Invisible walls along the cliffs: on the shared edge of two tiles whose heights differ by
## more than CLIFF_STEP. Consecutive edges are merged into one long wall.
func _add_cliffs() -> void:
	if relief.is_empty() and height_data == null:
		return
	var body := StaticBody2D.new()
	body.name = "Cliffs"
	add_child(body)
	var tile := tile_size()
	var size := map_size()
	var h := PackedFloat32Array()
	h.resize(size.x * size.y)
	for y in size.y:
		for x in size.x:
			h[y * size.x + x] = tile_height(Vector2i(x, y))
	# Vertical walls (between x and x+1), merged down the columns.
	for x in size.x - 1:
		var start := -1
		for y in size.y + 1:
			var steep := y < size.y and absf(h[y * size.x + x] - h[y * size.x + x + 1]) > CLIFF_STEP
			if steep and start < 0:
				start = y
			elif not steep and start >= 0:
				_wall(body, Rect2((x + 1) * tile.x - WALL_HALF, start * tile.y, WALL_HALF * 2.0, (y - start) * tile.y))
				start = -1
	# Horizontal walls (between y and y+1), merged along the rows.
	for y in size.y - 1:
		var start := -1
		for x in size.x + 1:
			var steep := x < size.x and absf(h[y * size.x + x] - h[(y + 1) * size.x + x]) > CLIFF_STEP
			if steep and start < 0:
				start = x
			elif not steep and start >= 0:
				_wall(body, Rect2(start * tile.x, (y + 1) * tile.y - WALL_HALF, (x - start) * tile.x, WALL_HALF * 2.0))
				start = -1


static func _wall(body: StaticBody2D, rect: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	body.add_child(shape)


## How far (tiles) in front of an exit the way stays clear, and how much wider than it.
const CORRIDOR_DEPTH := 4.0
const CORRIDOR_MARGIN := 1.2


## An exit's corridor: its area widened, stretched towards the zone (inward > 0) or away
## from it (inward < 0, beyond the edge), in world pixels.
func exit_corridor(exit: ZoneExit, depth_tiles: float) -> Rect2:
	var t := tile_size().x
	var r := exit_rect(exit)
	if not exit_on_edge(exit):
		return r.grow(t * 1.5) if depth_tiles > 0.0 else Rect2()
	var edge := exit_edge(exit)
	var inward := -edge * depth_tiles * t
	var across := Vector2(absf(edge.y), absf(edge.x)) * CORRIDOR_MARGIN * t
	# Towards the camera (south) the tall scenery hides the way even from aside: more room there.
	var south := t * 2.5 if edge.x != 0.0 else 0.0
	r = r.grow_individual(across.x, across.y, across.x, across.y + south)
	# …and a little past the edge too (the border trees planted just beyond it).
	var outward := edge * 2.0 * t if depth_tiles > 0.0 else Vector2.ZERO
	return r.merge(Rect2(r.position + inward, r.size)).merge(Rect2(r.position + outward, r.size))


## An exit's area in the zone's pixels (works outside the tree: the zone is at the origin).
func exit_rect(exit: ZoneExit) -> Rect2:
	var parent := exit.get_parent() as Node2D
	return Rect2(exit.position + (parent.position if parent else Vector2.ZERO), exit.size)


## Is the exit on the edge of the map (a way on to the next zone), or inside it (a cave mouth)?
func exit_on_edge(exit: ZoneExit) -> bool:
	var r := exit_rect(exit)
	var b := bounds().grow(-tile_size().x * 1.5)
	return not (b.encloses(r))


## The edge of the zone an exit is on (UP, DOWN, LEFT or RIGHT).
func exit_edge(exit: ZoneExit) -> Vector2:
	var r := exit_rect(exit)
	var b := bounds()
	var d := {
		Vector2.UP: absf(r.position.y - b.position.y), Vector2.DOWN: absf(r.end.y - b.end.y),
		Vector2.LEFT: absf(r.position.x - b.position.x), Vector2.RIGHT: absf(r.end.x - b.end.x),
	}
	return d.keys().reduce(func(a: Vector2, k: Vector2) -> Vector2: return k if d[k] < d[a] else a)


## A zone loaded only to be looked at (the neighbour shown beyond an edge): not in the
## tree, so nothing of it runs; its terrain and entities are reachable all the same.
static func open_for_preview(path: String) -> Region:
	var r: Region = (load(path) as PackedScene).instantiate()
	r.terrain = r.get_node("Terrain")
	r.entities = r.get_node("Entities")
	return r


## Nothing plain (trees, bushes, flowers) may stand in front of an exit: the way out must
## look like a way out. (Story props, obstacles and doors stay.)
func _clear_exit_corridors() -> void:
	var corridors := exits().map(func(e: ZoneExit) -> Rect2: return exit_corridor(e, CORRIDOR_DEPTH)).filter(
		func(c: Rect2) -> bool: return c.has_area())
	for n in entities.get_children():
		if n is Prop and n.get_script() == preload("res://world/prop.gd"):
			for c: Rect2 in corridors:
				if c.has_point(n.position):
					entities.remove_child(n)
					n.free()
					break


## Invisible walls on the edges of the region.
func _add_bounds() -> void:
	var r := bounds()
	var body := StaticBody2D.new()
	body.name = "Bounds"
	add_child(body)
	var thickness := 64.0
	for rect: Rect2 in [
		Rect2(r.position.x, r.position.y - thickness, r.size.x, thickness),
		Rect2(r.position.x, r.end.y, r.size.x, thickness),
		Rect2(r.position.x - thickness, r.position.y, thickness, r.size.y),
		Rect2(r.end.x, r.position.y, thickness, r.size.y),
	]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		body.add_child(shape)
