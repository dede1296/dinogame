@tool
class_name ZoneExit
extends Area2D
## A way out of the zone (a path leaving the map, a cave mouth…): Chloé walking into it
## goes to `target_zone`, arriving at its `target_spawn` marker. The spawn markers must
## stand outside the exits, or arriving would leave at once.

signal taken(exit: ZoneExit)

@export var size := Vector2(192, 36):
	set(value):
		size = value
		_update_shape()
		queue_redraw()
@export var target_zone: StringName
@export var target_spawn: StringName = &"Depart"
## Closed until this story flag is set; then `blocked_dialogue` is shown and Chloé steps back.
@export var required_flag: StringName
@export var blocked_dialogue: StringName


func is_open() -> bool:
	return required_flag == &"" or bool(Game.flag(required_flag))

var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # Chloé
	monitorable = false
	_update_shape()
	if not Engine.is_editor_hint():
		body_entered.connect(func(body: Node2D) -> void:
			if body is Player:
				taken.emit(self))


func _update_shape() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		add_child(_shape)
	var box := RectangleShape2D.new()
	box.size = size
	_shape.shape = box
	_shape.position = size / 2.0


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.6, 1.0, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(4, 14), "→ %s (%s)" % [target_zone, target_spawn], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
