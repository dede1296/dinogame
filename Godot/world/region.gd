@tool
class_name Region
extends Node2D
## Root of a region scene (regions/<name>/<name>.tscn). Expected children:
##   Terrain  — TileMapLayer painted with regions/terrain_tileset.tres (path, tall grass,
##              water; empty cells or "grass" = grass). Drawn by Ground, hidden in game.
##   Ground   — Ground node drawing the terrain.
##   Entities — Y-sorted: props, characters, dinos. Chloé and her dino are added here.
##   Spawns   — Marker2D arrival points ("Depart" = new game).

@export var region_id: StringName
@export var display_name := ""
@export var music: AudioStream
@export var ambience: AudioStream
## Occasional one-shot sounds (birds…) played over the ambience.
@export var ambience_details: Array[AudioStream] = []

@onready var terrain: TileMapLayer = $Terrain
@onready var entities: Node2D = $Entities


func _ready() -> void:
	if Engine.is_editor_hint():
		terrain.modulate = Color(1, 1, 1, 0.3)   # painting guide over the ground preview
		return
	terrain.visible = false
	_add_bounds()


func tile_size() -> Vector2:
	return Vector2(terrain.tile_set.tile_size)


## The region's area in world pixels.
func bounds() -> Rect2:
	var used := terrain.get_used_rect()
	return Rect2(Vector2(used.position) * tile_size(), Vector2(used.size) * tile_size())


## Ground type at a world position: &"grass", &"path", &"tall_grass" or &"water".
func surface_at(world_pos: Vector2) -> StringName:
	var data := terrain.get_cell_tile_data(terrain.local_to_map(terrain.to_local(world_pos)))
	if data == null:
		return &"grass"
	return StringName(data.get_custom_data("terrain"))


func spawn_point(spawn_name: StringName = &"Depart") -> Vector2:
	var marker := get_node_or_null(NodePath("Spawns/" + String(spawn_name))) as Node2D
	if marker == null:
		push_error("Point d'arrivée introuvable : %s" % spawn_name)
		return bounds().get_center()
	return marker.global_position


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
