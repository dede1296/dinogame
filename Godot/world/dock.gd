@tool
class_name Dock
extends Node2D
## A wooden pier over the water (paint its cells as "path" in the terrain, so Chloé can walk
## there): the 3D view lays planks on posts over that area. `size` in tiles.

@export var size := Vector2(3, 6):
	set(value):
		size = value
		queue_redraw()


## The pier's area in world pixels.
func area() -> Rect2:
	return Rect2(global_position if is_inside_tree() else position, size * 48.0)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size * 48.0), Color(0.6, 0.4, 0.2, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(4, 14), "Ponton", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
