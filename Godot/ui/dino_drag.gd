class_name DinoDrag
extends Control
## A dino carried by the finger (or the mouse) from one place to another (see DexTile): its
## portrait follows the pointer, the places that can take it glow and the one under it lights
## up; let go there and it is dropped, let go anywhere else and it goes back (nothing
## changes). Places: add_target(the Control, can it take this payload?, what dropping does).
## Lives full screen over what it serves, in the same canvas (pointer = its coordinates).

const GOLD := Color(1, 0.86, 0.5)
const INK := Color(0.106, 0.122, 0.157, 0.96)
const SIZE := 84.0
const BACK_S := 0.16

var _targets: Array[Dictionary] = []
var _payload := {}
var _picture: Texture2D
var _at := Vector2.ZERO
var _origin := Vector2.ZERO
var _hover := -1
var _back: Tween
## Where the portrait is drawn from the finger, in portrait sizes (above it: negative; the
## party bar, at the top of the screen, carries it under the finger).
var lift := -0.55


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## `accepts(payload) -> bool`; `drop(payload)`.
func add_target(control: Control, accepts: Callable, drop: Callable) -> void:
	_targets.append({"control": control, "accepts": accepts, "drop": drop})


func clear_targets() -> void:
	_targets.clear()


func active() -> bool:
	return not _payload.is_empty()


func begin(payload: Dictionary, picture: Texture2D, at: Vector2) -> void:
	if _back and _back.is_valid():
		_back.kill()
	_payload = payload
	_picture = picture
	_origin = at
	_at = at
	visible = true
	_update_hover()
	queue_redraw()


func move(at: Vector2) -> void:
	if _payload.is_empty():
		return
	_at = at
	_update_hover()
	queue_redraw()


## Let go at `at`: dropped on the place under it (true), or back where it came from.
func finish(at: Vector2) -> bool:
	if _payload.is_empty():
		return false
	move(at)
	var target := _hover
	var payload := _payload
	_payload = {}
	_hover = -1
	if target >= 0:
		visible = false
		_targets[target]["drop"].call(payload)
		return true
	# Nowhere to go: it flies back and vanishes.
	var fly := func(p: Vector2) -> void:
		_at = p
		queue_redraw()
	_back = create_tween()
	_back.tween_method(fly, _at, _origin, BACK_S).set_trans(Tween.TRANS_SINE)
	_back.tween_callback(func() -> void: visible = false)
	return false


func _update_hover() -> void:
	_hover = -1
	for i in _targets.size():
		var t: Dictionary = _targets[i]
		var c: Control = t["control"]
		if is_instance_valid(c) and c.is_visible_in_tree() and c.get_global_rect().has_point(_at) and t["accepts"].call(_payload):
			_hover = i


func _draw() -> void:
	if not _payload.is_empty():
		for i in _targets.size():
			var t: Dictionary = _targets[i]
			var c: Control = t["control"]
			if not is_instance_valid(c) or not c.is_visible_in_tree() or not t["accepts"].call(_payload):
				continue
			var place := Rect2(c.get_global_rect().position - get_global_rect().position, c.get_global_rect().size).grow(4.0)
			var box := StyleBoxFlat.new()
			box.draw_center = i == _hover
			box.bg_color = Color(GOLD, 0.22)
			box.border_color = Color(GOLD, 1.0 if i == _hover else 0.45)
	# The portrait, beside the finger (see lift: the finger hides less of it).
			box.set_corner_radius_all(16)
			draw_style_box(box, place)
	# The portrait, a little above the finger (which hides less of it).
	var p := _at - get_global_rect().position + Vector2(0, SIZE * lift)
	var r := SIZE / 2.0
	draw_circle(p + Vector2(0, 5), r, Color(0, 0, 0, 0.35))
	draw_circle(p, r, INK)
	if _picture:
		draw_texture_rect(_picture, Rect2(p - Vector2(r - 6.0, r - 6.0), Vector2(r - 6.0, r - 6.0) * 2.0), false)
	draw_arc(p, r, 0.0, TAU, 48, GOLD, 3.0, true)
