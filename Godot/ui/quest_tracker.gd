class_name QuestTracker
extends Control
## The objective being followed, always in view under the party bar: its title and, small under it,
## the way to go — a little arrow turning towards the place and how far it is; when the objective is in
## another zone, towards the way out to take, named (ZoneRoutes.heading : « 18 m · sortie : Havre-Doré »).
## That line can be hidden (Paramètres → Affichage : « Direction de l'objectif ») ; it then shows only
## with the details. A click (or a tap) unrolls the details; another click, or a few seconds, rolls them up.
## The one followed: the one picked on the map, else the nearest (Objectives.followed).

const TOP := 104.0
const WIDTH := 340.0
const CHECK_S := 0.3
const OPEN_S := 9.0
const GOLD := Color(0.95, 0.76, 0.31)
const BLUE := Color(0.45, 0.75, 0.98)
const CREAM := Color(1, 0.97, 0.9)
const TILE := 48.0
const HERE_TILES := 3.0
const ARROW_PX := 16.0
const TURN_REDRAW := 0.03   # the arrow is drawn again when the angle moved this much (radians)
const PREF_SECTION := "hud"
const PREF_DIRECTION := "direction"

var player: Node2D
var zone: StringName
## The zone's scene (world.gd): where its ways out are.
var region: Region
var _goal: Dictionary = {}
var _heading: Dictionary = {}
var _panel: PanelContainer
var _title: Label
var _detail: Label
var _way: HBoxContainer
var _distance: Label
var _arrow: Control
var _angle := 0.0
var _drawn_angle := INF
var _timer := 0.0
var _open_left := 0.0


## Is the direction line shown (Paramètres → Affichage)? Yes by default.
static func direction_shown() -> bool:
	return bool(Quality.pref(PREF_SECTION, PREF_DIRECTION, true))


static func set_direction_shown(on: bool, save := true) -> void:
	Quality.set_pref(PREF_SECTION, PREF_DIRECTION, on, save)


static func distance_text(tiles: float) -> String:
	return "ici" if tiles < HERE_TILES else "%d m" % roundi(tiles)


## The direction line for `h` (ZoneRoutes.heading), Chloé at `here`: « 42 m », « 18 m · sortie :
## Havre-Doré », « vers Côte Préhistorique » (no way known), or "" (nothing to point to).
static func direction_text(h: Dictionary, here: Vector2) -> String:
	if h.is_empty():
		return ""
	var tile: Vector2 = h.get("tile", Vector2.INF)
	var via: StringName = h.get("via", &"")
	var where: String = ZoneMap.ZONE_NAMES.get(via, String(via))
	if tile == Vector2.INF:
		return "" if via == &"" else "vers %s" % where
	var dist := distance_text(here.distance_to(tile))
	if via == &"":
		return dist
	return "%s · %s : %s" % [dist, h.get("kind", "sortie"), where]


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
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 1)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(text)
	_title = _label(15, CREAM)
	text.add_child(_title)
	text.add_child(_way_line())
	_detail = _label(13, Color(CREAM, 0.8))
	_detail.custom_minimum_size = Vector2(WIDTH - 24.0, 0)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(_detail)
	get_viewport().size_changed.connect(_place)
	_place()
	_refresh()


## Under the title, small: the arrow and the words (distance, way out).
func _way_line() -> HBoxContainer:
	_way = HBoxContainer.new()
	_way.add_theme_constant_override("separation", 5)
	_way.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow = Control.new()
	_arrow.custom_minimum_size = Vector2(ARROW_PX, ARROW_PX)
	_arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.draw.connect(_draw_arrow)
	_way.add_child(_arrow)
	_distance = _label(12, Color(CREAM, 0.82))
	_way.add_child(_distance)
	return _way


func _label(font_size: int, colour: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _place() -> void:
	var inset := SafeArea.insets(get_viewport())
	position = Vector2(inset.x, inset.y + TOP * HudHint.scale_pc())


func _process(delta: float) -> void:
	if _open_left > 0.0:
		_open_left -= delta
		if _open_left <= 0.0:
			_refresh()
	_timer -= delta
	if _timer <= 0.0:
		_timer = CHECK_S
		_refresh()
	_turn_arrow()


## The arrow follows Chloé's steps at once (the words, every CHECK_S).
func _turn_arrow() -> void:
	if player == null or not _way.visible:
		return
	var tile: Vector2 = _heading.get("tile", Vector2.INF)
	if tile == Vector2.INF:
		return
	_angle = MinimapMath.angle_to(player.global_position / TILE, tile)
	if absf(angle_difference(_angle, _drawn_angle)) > TURN_REDRAW or _drawn_angle == INF:
		_drawn_angle = _angle
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
	_title.text = "◆ " + String(_goal["title"])
	_title.add_theme_color_override("font_color", colour.lerp(CREAM, 0.35))
	_detail.visible = open
	_detail.text = _goal["text"]
	_heading = ZoneRoutes.heading(_goal, zone, region, here)
	var words := direction_text(_heading, here)
	_way.visible = words != "" and (open or direction_shown())
	_distance.text = words
	_arrow.visible = _heading.get("tile", Vector2.INF) != Vector2.INF
	_panel.get_theme_stylebox("panel").set("border_color", colour)
	_panel.reset_size()
	size = _panel.get_combined_minimum_size()
	_panel.size = size


## A small arrow towards the place, or the way out (north up, as on the map and on screen).
func _draw_arrow() -> void:
	if _goal.is_empty():
		return
	var colour := GOLD if _goal["main"] else BLUE
	if _heading.get("via", &"") != &"":
		colour = ZoneMap.CHLOE.lerp(CREAM, 0.15)   # (the colour of the ways out on the map)
	var c := Vector2.ONE * ARROW_PX / 2.0
	var d := Vector2.from_angle(_angle)
	var side := d.orthogonal() * 4.5
	_arrow.draw_colored_polygon(PackedVector2Array([c + d * 7.5, c - d * 5.0 + side, c - d * 2.0, c - d * 5.0 - side]), colour)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_open_left = 0.0 if _open_left > 0.0 else OPEN_S
		_refresh()
		accept_event()
