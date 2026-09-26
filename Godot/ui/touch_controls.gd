extends CanvasLayer
## On-screen controls for touch screens: a floating joystick on the left half of the
## screen (appears where the thumb lands) and A / B buttons on the right.
## They press the same input actions as the keyboard, so the game code only reads actions.

const RADIUS := 78.0
const DEAD_ZONE := 0.18
const BUTTON_RADIUS := 52.0

var _touch_index := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _pad: Control


func _ready() -> void:
	layer = 20
	visible = _touch_screen()
	_pad = Control.new()
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)
	_add_button("A", &"interact", Vector2(-92, -120), Color(0.85, 0.62, 0.2))
	_add_button("B", &"cancel", Vector2(-200, -64), Color(0.35, 0.4, 0.45))


func _touch_screen() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


func _add_button(label: String, action: StringName, corner_offset: Vector2, color: Color) -> void:
	var button := TouchScreenButton.new()
	var size := int(BUTTON_RADIUS * 2)
	button.texture_normal = _disc(size, Color(color, 0.72))
	button.texture_pressed = _disc(size, Color(color.lightened(0.25), 0.9))
	var shape := CircleShape2D.new()
	shape.radius = BUTTON_RADIUS
	button.shape = shape
	button.shape_centered = true
	button.action = action
	button.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	var anchor := Control.new()
	anchor.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	anchor.position = corner_offset - Vector2(BUTTON_RADIUS, BUTTON_RADIUS)
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)
	anchor.add_child(button)
	var text := Label.new()
	text.text = label
	text.add_theme_font_size_override("font_size", 34)
	text.add_theme_color_override("font_color", Color(1, 0.98, 0.9))
	text.size = Vector2(size, size)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(text)


static func _disc(size: int, color: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, Color(color, 0.0))
	g.add_point(0.93, color)
	g.add_point(0.97, Color(color.darkened(0.4), color.a))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = size
	tex.height = size
	return tex


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not visible:
			visible = true   # first touch on a device that didn't report a touch screen
		var half := get_viewport().get_visible_rect().size.x * 0.5
		if event.pressed and _touch_index < 0 and event.position.x < half:
			_touch_index = event.index
			_origin = event.position
			_knob = Vector2.ZERO
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_knob = Vector2.ZERO
			_apply(Vector2.ZERO)
		_pad.queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_knob = (event.position - _origin).limit_length(RADIUS)
		_apply(_knob / RADIUS)
		_pad.queue_redraw()


## The app going to the background (call, Home button…) may never deliver the finger's
## release: let go of the joystick, or Chloé keeps walking and new touches are ignored.
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		_touch_index = -1
		_knob = Vector2.ZERO
		_apply(Vector2.ZERO)
		for action in [&"interact", &"cancel"]:
			Input.action_release(action)
		if _pad:
			_pad.queue_redraw()


func _apply(v: Vector2) -> void:
	if v.length() < DEAD_ZONE:
		v = Vector2.ZERO
	_set_axis(&"move_left", &"move_right", v.x)
	_set_axis(&"move_up", &"move_down", v.y)


func _set_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value < 0.0:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	elif value > 0.0:
		Input.action_press(positive, value)
		Input.action_release(negative)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


func _draw_pad() -> void:
	if _touch_index < 0:
		return
	_pad.draw_circle(_origin, RADIUS, Color(1, 1, 1, 0.12))
	_pad.draw_arc(_origin, RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0, true)
	_pad.draw_circle(_origin + _knob, 34, Color(1, 0.95, 0.85, 0.55))
