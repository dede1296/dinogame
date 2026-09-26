@tool
class_name CaveMouth
extends Node2D
## The entrance of a cave: a dark opening in a rock face, drawn by the 3D view. Place it at
## the foot of a steep slope (a cliff facing south, towards the camera), and a ZoneExit just
## in front of it. `width` and `height` in metres.

@export var width := 2.6:
	set(value):
		width = value
		queue_redraw()
@export var height := 2.3


func _draw() -> void:
	if Engine.is_editor_hint():
		var w := width * 48.0
		draw_rect(Rect2(-w / 2.0, -20.0, w, 20.0), Color(0.05, 0.05, 0.08, 0.8))
		draw_string(ThemeDB.fallback_font, Vector2(-w / 2.0, -24.0), "Grotte", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
