@tool
class_name TallGrass
extends Node2D
## Fills every "tall_grass" cell of the terrain with swaying tufts (not saved in the
## scene: regenerated from the terrain, also live in the editor). Must sit in the
## Y-sorted Entities node, so Chloé walks *into* the grass.

const TUFT := preload("res://assets/art/props/hautes_herbes.png")
const SWAY := preload("res://world/shaders/sway.gdshader")
const TUFT_SCALE := 0.23

@export var terrain: TileMapLayer:
	set(value):
		if terrain and terrain.changed.is_connected(_queue_rebuild):
			terrain.changed.disconnect(_queue_rebuild)
		terrain = value
		if terrain:
			terrain.changed.connect(_queue_rebuild)
		_queue_rebuild()

var _material: ShaderMaterial
var _pending := false


func _ready() -> void:
	y_sort_enabled = true
	_material = ShaderMaterial.new()
	_material.shader = SWAY
	_material.set_shader_parameter("strength", 3.0)
	_material.set_shader_parameter("push_strength", 14.0)
	_material.set_shader_parameter("push_radius", 40.0)
	_material.set_shader_parameter("stiffness", 1.4)
	if not Engine.is_editor_hint():
		Quality.changed.connect(_queue_rebuild)
	_queue_rebuild()


## Tufts per cell: from the quality profile in game, the medium density in the editor.
func _tufts_per_cell() -> int:
	return 2 if Engine.is_editor_hint() else Quality.setting(&"grass_tufts")


func _queue_rebuild() -> void:
	if _pending or not is_inside_tree():
		return
	_pending = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_pending = false
	# In game the 3D view draws the grass (WorldView); these tufts are for the editor.
	if not Engine.is_editor_hint():
		return
	for child in get_children():
		child.queue_free()
	if terrain == null or terrain.tile_set == null:
		return
	var tile := Vector2(terrain.tile_set.tile_size)
	var h := TUFT.get_height()
	var tufts := _tufts_per_cell()
	for cell in terrain.get_used_cells():
		var data := terrain.get_cell_tile_data(cell)
		if data == null or StringName(data.get_custom_data("terrain")) != &"tall_grass":
			continue
		# Same layout every time for a given cell.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(cell)
		for i in tufts:
			var s := Sprite2D.new()
			s.texture = TUFT
			s.material = _material
			var k := TUFT_SCALE * rng.randf_range(0.85, 1.12)
			s.scale = Vector2(k, k)
			s.flip_h = rng.randf() < 0.5
			s.offset = Vector2(0, -h / 2.0 + h * 0.06)
			var local := (Vector2(cell) + Vector2(rng.randf_range(0.15, 0.85), (i + 0.5 + rng.randf_range(-0.2, 0.2)) / tufts)) * tile
			s.position = to_local(terrain.to_global(local))
			add_child(s)
