class_name QuestTracker
extends Control
## The objective being followed, always in view under the party bar, as short as can be: its
## title only. A tap opens it: the details, an arrow turning towards the place and how far it
## is (or the zone to go to when it is elsewhere); another tap, or a few seconds, closes it.
## The one followed: the one picked on the map, else the nearest (Objectives.followed).

const TOP := 104.0
const WIDTH := 340.0
const CHECK_S := 0.3
const OPEN_S := 9.0
const GOLD := Color(0.95, 0.76, 0.31)
const BLUE := Color(0.45, 0.75, 0.98)
const CREAM := Color(1, 0.97, 0.9)
const TILE := 48.0

var player: Node2D
var zone: StringName
var _goal: Dictionary = {}
var _panel: PanelContainer
var _title: Label
var _detail: Label
var _pointer: VBoxContainer
var _distance: Label
var _arrow: Control
var _angle := 0.0
var _timer := 0.0
var _open_left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(&"touch_blockers")
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.07, 0.05, 0.72)
	box.border_color = GOLD
	box.border_width_left = 4
	box.set_corner_radius_all(10)
	box.content_margin_left = 10
	box.content_margin_right = 12
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	_panel.add_theme_stylebox_override("panel", box)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)
	_pointer = VBoxContainer.new()
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.add_theme_constant_override("separation", 0)
	row.add_child(_pointer)
	_arrow = Control.new()
	_arrow.custom_minimum_size = Vector2(34, 30)
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.draw.connect(_draw_arrow)
	_pointer.add_child(_arrow)
	_distance = Label.new()
	_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_distance.add_theme_font_size_override("font_size", 12)
	_distance.add_theme_color_override("font_color", Color(CREAM, 0.8))
	_pointer.add_child(_distance)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 2)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 15)
	_title.add_theme_color_override("font_color", CREAM)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(_title)
	_detail = Label.new()
	_detail.custom_minimum_size = Vector2(WIDTH - 70.0, 0)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 13)
	_detail.add_theme_color_override("font_color", Color(CREAM, 0.8))
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(_detail)
	get_viewport().size_changed.connect(_place)
	_place()
	_refresh()


func _place() -> void:
	var inset := SafeArea.insets(get_viewport())
	position = Vector2(inset.x, inset.y + TOP)


func _process(delta: float) -> void:
	if _open_left > 0.0:
		_open_left -= delta
		if _open_left <= 0.0:
			_refresh()
	_timer -= delta
	if _timer <= 0.0:
		_timer = CHECK_S
		_refresh()
	_arrow.queue_redraw()


func _refresh() -> void:
	if player == null:
		return
	var here := player.global_position / TILE
	_goal = Objectives.followed(zone, here)
	visible = not _goal.is_empty()
	if not visible:
		return
	var open := _open_left > 0.0
	var colour := GOLD if _goal["main"] else BLUE
	_title.text = ("◆ " if not open else "") + String(_goal["title"])
	_title.add_theme_color_override("font_color", colour.lerp(CREAM, 0.35))
	_detail.visible = open
	_pointer.visible = open
	_detail.text = _goal["text"]
	if _goal["zone"] != zone and _goal["zone"] != &"":
		_distance.text = ZoneMap.ZONE_NAMES.get(_goal["zone"], "")
	elif _goal["tile"] != Vector2.INF:
		var to: Vector2 = (_goal["tile"] as Vector2) - here
		_angle = to.angle()
		_distance.text = "ici" if to.length() < 3.0 else "%d m" % roundi(to.length())
	else:
		_distance.text = ""
	_panel.get_theme_stylebox("panel").set("border_color", colour)
	size = _panel.get_combined_minimum_size()
	_panel.size = size


## An arrow towards the objective (the map's north is up, as on screen), or a door when the
## objective is in another zone, or a dot when it has no place.
func _draw_arrow() -> void:
	if _goal.is_empty():
		return
	var c := Vector2(17, 15)
	var colour := GOLD if _goal["main"] else BLUE
	if _goal["zone"] != zone and _goal["zone"] != &"":
		_arrow.draw_rect(Rect2(c + Vector2(-8, -11), Vector2(16, 22)), colour, false, 2.5)
		_arrow.draw_circle(c + Vector2(4, 1), 2.0, colour)
		return
	if _goal["tile"] == Vector2.INF:
		_arrow.draw_circle(c, 7.0, colour)
		return
	var bob := 1.5 * sin(Time.get_ticks_msec() / 200.0)
	var d := Vector2.from_angle(_angle)
	var tip := c + d * (11.0 + bob)
	var side := d.orthogonal() * 7.0
	_arrow.draw_colored_polygon(PackedVector2Array([tip, c - d * 6.0 + side, c - d * 2.0, c - d * 6.0 - side]), colour)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_open_left = 0.0 if _open_left > 0.0 else OPEN_S
		_refresh()
		accept_event()
