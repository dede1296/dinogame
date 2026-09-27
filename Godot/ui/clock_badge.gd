class_name ClockBadge
extends PanelContainer
## The time of day at a glance, top-right next to the menu button: an icon (sun, moon, rain,
## mist, sandstorm) and the hour. Holding it down (or F2 on a computer) opens the debug panel.

const ICONS := {
	&"sun": preload("res://assets/art/ui/meteo_soleil.png"),
	&"moon": preload("res://assets/art/ui/meteo_lune.png"),
	&"full_moon": preload("res://assets/art/ui/meteo_pleine_lune.png"),
	&"rain": preload("res://assets/art/ui/meteo_pluie.png"),
	&"mist": preload("res://assets/art/ui/meteo_brume.png"),
	&"storm": preload("res://assets/art/ui/meteo_orage.png"),
}
## The sandstorm's own icon when there is one; else the mist's, tinted ochre (SAND_TINT).
const SANDSTORM_ICON := "res://assets/art/ui/meteo_sable.png"
const SAND_TINT := Color(1.0, 0.72, 0.38)
const HOLD_S := 1.0          # long press for the debug panel
const RIGHT_OF_MENU := 96.0  # room left for the menu button (76 px + gap)

var _icon: TextureRect
var _label: Label
var _held := -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(&"touch_blockers")
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.106, 0.122, 0.157, 0.72)
	box.border_color = Color(0.79, 0.54, 0.16)
	box.set_border_width_all(2)
	box.set_corner_radius_all(24)
	box.content_margin_left = 8
	box.content_margin_right = 16
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(40, 40)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_label)
	_refresh()
	get_viewport().size_changed.connect(_place)
	_place.call_deferred()


func _place() -> void:
	var inset := SafeArea.insets(get_viewport())
	var screen := get_viewport().get_visible_rect().size
	reset_size()
	position = Vector2(screen.x - inset.x - RIGHT_OF_MENU - size.x, inset.y + 14.0)


func _process(delta: float) -> void:
	_refresh()
	if _held >= 0.0:
		_held += delta
		if _held >= HOLD_S:
			_held = -1.0
			DebugMenu.open(self)


func _refresh() -> void:
	var minutes := int(Game.clock)
	_label.text = "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]
	if Game.weather == &"sandstorm":
		_show_sandstorm()
		return
	var key := &"sun"
	if Game.weather == &"storm":
		key = &"storm"
	elif Game.weather == &"rain":
		key = &"rain"
	elif Game.weather == &"mist":
		key = &"mist"
	elif Game.phase() == &"night":
		key = &"full_moon" if Game.is_full_moon() else &"moon"
	_icon.texture = ICONS[key]
	_icon.modulate = Color.WHITE


static var _sand_icon: Texture2D


func _show_sandstorm() -> void:
	if _sand_icon == null:
		_sand_icon = load(SANDSTORM_ICON) if ResourceLoader.exists(SANDSTORM_ICON) else ICONS[&"mist"]
	_icon.texture = _sand_icon
	_icon.modulate = Color.WHITE if _sand_icon != ICONS[&"mist"] else SAND_TINT


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_held = 0.0 if event.pressed else -1.0
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		get_viewport().set_input_as_handled()
		DebugMenu.open(self)
