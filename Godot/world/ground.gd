@tool
class_name Ground
extends ColorRect
## Draws the region's ground (grass, paths, water) with ground.gdshader, from the terrain
## painted in the region's Terrain layer. Rebuilt live in the editor while painting.

const MASK_COLORS := {
	&"path": Color(1, 0, 0),
	&"tall_grass": Color(0, 1, 0),
	&"water": Color(0, 0, 1),
}
const GRASS_TEX := preload("res://assets/art/ground/herbe.png")
const DIRT_TEX := preload("res://assets/art/ground/terre.png")
const SHADER := preload("res://world/shaders/ground.gdshader")

@export var terrain: TileMapLayer:
	set(value):
		if terrain and terrain.changed.is_connected(_queue_rebuild):
			terrain.changed.disconnect(_queue_rebuild)
		terrain = value
		if terrain:
			terrain.changed.connect(_queue_rebuild)
		_queue_rebuild()

var _pending := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_queue_rebuild()


func _queue_rebuild() -> void:
	if _pending or not is_inside_tree():
		return
	_pending = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_pending = false
	if terrain == null or terrain.tile_set == null:
		return
	var rect := terrain.get_used_rect()
	if rect.size == Vector2i.ZERO:
		return
	var tile := Vector2(terrain.tile_set.tile_size)
	var mask := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGB8)
	for cell in terrain.get_used_cells():
		var data := terrain.get_cell_tile_data(cell)
		var kind: StringName = StringName(data.get_custom_data("terrain")) if data else &""
		mask.set_pixelv(cell - rect.position, MASK_COLORS.get(kind, Color.BLACK))
	position = Vector2(rect.position) * tile
	size = Vector2(rect.size) * tile
	var mat := material as ShaderMaterial
	if mat == null or mat.shader != SHADER:
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		material = mat
	mat.set_shader_parameter("terrain_mask", ImageTexture.create_from_image(mask))
	mat.set_shader_parameter("map_tiles", Vector2(rect.size))
	mat.set_shader_parameter("tile_px", tile.x)
	mat.set_shader_parameter("grass_tex", GRASS_TEX)
	mat.set_shader_parameter("dirt_tex", DIRT_TEX)
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
