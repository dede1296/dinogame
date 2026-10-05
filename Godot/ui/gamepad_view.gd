class_name GamepadView
extends Control
## A drawn gamepad (Xbox layout) for the Commandes → Touches page: each button shows the action it
## does; a tap on a button that does something asks for its new button (SettingsMenu).

signal button_tapped(button: int)

const BOARD_SIZE := Vector2(560, 290)
const BODY_RECT := Rect2(Vector2(30, 30), Vector2(500, 230))
const BODY := Color(0.16, 0.18, 0.22)
const KEY := Color(0.27, 0.3, 0.36)
const CREAM := Color(1, 0.97, 0.9)
const GOLD := Color(1, 0.86, 0.5)
const RADIUS := 20.0
const TAP_SLOP := 6.0
## [button, centre, name written on it]
const SPOTS := [
	[JOY_BUTTON_LEFT_SHOULDER, Vector2(120, 52), "LB"],
	[JOY_BUTTON_RIGHT_SHOULDER, Vector2(440, 52), "RB"],
	[JOY_BUTTON_BACK, Vector2(232, 100), "Vue"],
	[JOY_BUTTON_START, Vector2(328, 100), "Menu"],
	[JOY_BUTTON_DPAD_UP, Vector2(140, 112), "↑"],
	[JOY_BUTTON_DPAD_DOWN, Vector2(140, 170), "↓"],
	[JOY_BUTTON_DPAD_LEFT, Vector2(106, 141), "←"],
	[JOY_BUTTON_DPAD_RIGHT, Vector2(174, 141), "→"],
	[JOY_BUTTON_LEFT_STICK, Vector2(214, 212), "LS"],
	[JOY_BUTTON_RIGHT_STICK, Vector2(346, 212), "RS"],
	[JOY_BUTTON_Y, Vector2(470, 100), "Y"],
	[JOY_BUTTON_X, Vector2(436, 134), "X"],
	[JOY_BUTTON_B, Vector2(504, 134), "B"],
	[JOY_BUTTON_A, Vector2(470, 168), "A"],
]

## The short action name written under each button that does one: button -> text.
var _labels := {}


func _init() -> void:
	custom_minimum_size = BOARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_labels(labels: Dictionary) -> void:
	_labels = labels
	queue_redraw()


func _draw() -> void:
	draw_rect(BODY_RECT, BODY)
	var font := get_theme_default_font()
	for spot: Array in SPOTS:
		var centre: Vector2 = spot[1]
		draw_circle(centre, RADIUS, KEY)
		draw_string(font, centre + Vector2(-RADIUS, 6), spot[2], HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2, 16, CREAM)
		if _labels.has(spot[0]):
			draw_string(font, centre + Vector2(-60, RADIUS + 16), _labels[spot[0]],
				HORIZONTAL_ALIGNMENT_CENTER, 120, 13, GOLD)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var spot := _spot_at(click.position)
	if spot >= 0 and _labels.has(SPOTS[spot][0]):
		button_tapped.emit(SPOTS[spot][0])


func _spot_at(point: Vector2) -> int:
	for i in SPOTS.size():
		var centre: Vector2 = SPOTS[i][1]
		if point.distance_to(centre) <= RADIUS + TAP_SLOP:
			return i
	return -1
