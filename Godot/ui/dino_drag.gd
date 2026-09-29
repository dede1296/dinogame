class_name DinoDrag
extends Control
## A dino carried by the finger (or the mouse) from one place to another (see DexTile): its
## portrait follows the pointer, the places that can take it glow and the one it will go to
## lights up (under the portrait, else the nearest to the finger or the portrait: a thumb is not
## precise and hides what it aims at; from the party bar, at the top of the screen, the finger
## alone picks); let go then and it is dropped, let go anywhere else and it goes back (nothing
## changes). Places: add_target(the Control, can it take this payload?, what
## dropping does).
## Lives full screen over what it serves, in the same canvas (pointer = its coordinates).

const GOLD := Color(1, 0.86, 0.5)
const INK := Color(0.106, 0.122, 0.157, 0.96)
const SIZE := 84.0
const BACK_S := 0.16
## A place this far (px) from the finger or from the portrait still takes the dino.
const SNAP := 40.0
## The portrait's middle above the finger (portrait sizes); taken where there is no room above
## (the party bar, at the top of the screen): beside it, below the row (not over its places).
const ABOVE := 0.6
const BESIDE := Vector2(0.85, 0.95)

var _targets: Array[Dictionary] = []
var _payload := {}
var _picture: Texture2D
var _at := Vector2.ZERO
var _origin := Vector2.ZERO
var _hover := -1
var _back: Tween
var _by_touch := false
var _beside := false   # (taken with no room above the finger: see BESIDE)


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


## `by_touch`: carried by a finger (the portrait is drawn off it, the finger would hide it), not
## the mouse (the portrait is the pointer).
func begin(payload: Dictionary, picture: Texture2D, at: Vector2, by_touch := false) -> void:
	if _back and _back.is_valid():
		_back.kill()
	_by_touch = by_touch
	_beside = by_touch and at.y - SIZE * (ABOVE + 0.5) < get_viewport_rect().position.y
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


## The place it goes to: the one under the portrait (what one sees), else the nearest to the
## finger or to the portrait, SNAP px at most. Beside the finger, the portrait does not pick.
func _update_hover() -> void:
	_hover = -1
	var portrait := _at if _beside else _portrait_at()
	var best := SNAP
	for i in _targets.size():
		var t: Dictionary = _targets[i]
		var c: Control = t["control"]
		if not is_instance_valid(c) or not c.is_visible_in_tree() or not t["accepts"].call(_payload):
			continue
		var rect := c.get_global_rect()
		if rect.has_point(portrait):
			_hover = i
			best = -1.0   # (only another place under the portrait, drawn over this one, beats it)
		elif best >= 0.0:
			var d := minf(_gap(rect, _at), _gap(rect, portrait))
			if d <= best:
				best = d
				_hover = i


## How far `p` is from `rect` (0 inside).
static func _gap(rect: Rect2, p: Vector2) -> float:
	return p.distance_to(p.clamp(rect.position, rect.end))


## Where the portrait is drawn (global): on the mouse pointer; above the finger, which hides less
## of it; or beside it (towards the middle of the screen) and below the row it was taken from.
func _portrait_at() -> Vector2:
	if not _by_touch:
		return _at
	if not _beside:
		return _at - Vector2(0.0, SIZE * ABOVE)
	var side := 1.0 if _at.x < get_viewport_rect().get_center().x else -1.0
	return _at + SIZE * Vector2(BESIDE.x * side, BESIDE.y)


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
			box.bg_color = Color(GOLD, 0.3)
			box.border_color = Color(GOLD, 1.0 if i == _hover else 0.45)
			box.set_border_width_all(4 if i == _hover else 2)
			box.set_corner_radius_all(16)
			draw_style_box(box, place)
	var p := _portrait_at() - get_global_rect().position
	var r := SIZE / 2.0
	draw_circle(p + Vector2(0, 5), r, Color(0, 0, 0, 0.35))
	draw_circle(p, r, INK)
	if _picture:
		draw_texture_rect(_picture, Rect2(p - Vector2(r - 6.0, r - 6.0), Vector2(r - 6.0, r - 6.0) * 2.0), false)
	draw_arc(p, r, 0.0, TAU, 48, GOLD, 3.0, true)
