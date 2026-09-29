class_name DexTile
extends Control
## A tile one taps or drags with a finger or the mouse: a species of the Dinodex, a dino of the
## team or of the reserve, a portrait of the party bar. A tap opens it (Enter or the A button
## too, when it has the focus). Pressed and moved when `draggable`, its dino is carried by a
## DinoDrag (`drag`, with `payload` and `picture`) to another place. In a list that scrolls
## (`scroll`), moving up or down scrolls it, moving sideways drags at once, and holding still
## a moment (HOLD_S) drags in any direction. Subclasses draw it (and call draw_focus_ring).

signal tapped
## Moved as if to be dragged, but it may not be now (can_drag): the owner says why.
signal drag_refused

const MOVE_PX := 12.0      # a finger moving less than this is still a tap
const HOLD_S := 0.35       # held this long without moving: the drag starts where the finger is
const FOCUS := Color(1, 0.86, 0.5)

enum { IDLE, PRESSED, SCROLLING, DRAGGING, CANCELLED }

## The keyboard or a gamepad is in use: the tile with the focus shows it (a touch hides it).
static var keys_used := false

var draggable := false
var drag: DinoDrag
var payload := {}
var picture: Texture2D
## The list it scrolls when moved up or down (null: none).
var scroll: ScrollContainer
## Can it be dragged now? (e.g. not during a scene.) Empty Callable: always.
var can_drag := Callable()
var _mode := IDLE
var _from := Vector2.ZERO
var _last := Vector2.ZERO   # where the finger was last seen while dragging
var _held := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS   # (the wheel still scrolls the list it is in)
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _process(delta: float) -> void:
	# The finger was lifted but the release never came (the app lost the focus…): it is let
	# go where it was last seen.
	if _mode == DRAGGING and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_let_go(_last)
		return
	if _mode != PRESSED or not _drag_allowed():
		return
	_held += delta
	if _held >= HOLD_S:
		_start_drag(get_global_mouse_position())


## The app goes to the background (a call, the Home button…) in the middle of a drag: the dino
## goes back where it was.
func _notification(what: int) -> void:
	if _mode == DRAGGING and what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT,
			NOTIFICATION_APPLICATION_PAUSED]:
		_mode = IDLE
		if drag:
			drag.finish(_from)   # (dropped where it came from: nothing changes)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var at := (event as InputEventMouseButton).global_position
		if event.pressed:
			if _mode == DRAGGING:   # (its release was lost: this press lets it go)
				_let_go(at)
				return
			_mode = PRESSED
			_from = at
			_held = 0.0
			return
		var was := _mode
		_mode = IDLE
		if was == PRESSED:
			tapped.emit()
		elif was == DRAGGING:
			_let_go(at)
	elif event is InputEventMouseMotion and _mode != IDLE:
		accept_event()
		var motion := event as InputEventMouseMotion
		var moved := motion.global_position - _from
		if _mode == PRESSED and moved.length() > MOVE_PX:
			var sideways := scroll == null or absf(moved.x) > absf(moved.y)
			if _drag_allowed() and sideways:
				_start_drag(motion.global_position)
			else:
				_mode = SCROLLING if scroll else CANCELLED
				if draggable and sideways:
					drag_refused.emit()
		if _mode == SCROLLING:
			scroll.scroll_vertical -= int(motion.relative.y)
		elif _mode == DRAGGING and drag:
			_last = motion.global_position
			drag.move(_last)
	elif event.is_action_pressed(&"ui_accept"):
		accept_event()
		tapped.emit()


## Is it being carried (drawn faded where it was)?
func dragging() -> bool:
	return _mode == DRAGGING


func _drag_allowed() -> bool:
	return draggable and drag != null and (not can_drag.is_valid() or can_drag.call())


func _start_drag(at: Vector2) -> void:
	_mode = DRAGGING
	_last = at
	drag.begin(payload, picture, at)
	queue_redraw()


## Dropped at `at` (on a place that takes it, or back where it was).
func _let_go(at: Vector2) -> void:
	_mode = IDLE
	if drag:
		drag.finish(at)
	queue_redraw()


## A gold ring around it when it has the keyboard / gamepad focus.
func draw_focus_ring(radius := 14.0) -> void:
	if not has_focus() or not keys_used:
		return
	var box := StyleBoxFlat.new()
	box.draw_center = true
	box.bg_color = Color(FOCUS, 0.12)
	box.border_color = FOCUS
	box.set_border_width_all(5)
	box.set_corner_radius_all(int(radius))
	box.shadow_color = Color(FOCUS, 0.45)
	box.shadow_size = 8
	draw_style_box(box, Rect2(Vector2.ZERO, size).grow(1.0))
