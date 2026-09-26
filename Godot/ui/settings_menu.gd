class_name SettingsMenu
extends CanvasLayer
## Paramètres → Graphismes: the player picks Basse / Moyenne / Haute; the level detected
## for the phone is marked « Recommandée ». Opened from the title screen or, in game, from
## the menu button (the game is paused meanwhile). Built for thumbs: big rows, one tap.

signal closed

const LAYER := 80
const ROW_HEIGHT := 68.0
const PANEL_WIDTH := 640.0
const AMBER := Color(0.79, 0.54, 0.16)
const INK := Color(0.106, 0.122, 0.157, 0.96)
const CREAM := Color(1, 0.97, 0.9)
const HINTS := [
	"Pour les téléphones plus anciens : moins d'effets, 60 images/s.",
	"L'équilibre entre effets et autonomie, 60 images/s.",
	"Tous les effets, et la fluidité maximale de l'écran.",
]

var _rows: Array[Button] = []
var _was_paused := false


## Opens the menu over `parent`'s scene and pauses the game until it is closed.
static func open(parent: Node) -> SettingsMenu:
	var menu := SettingsMenu.new()
	parent.get_tree().root.add_child(menu)
	return menu


## Adds the round « menu » button in the top-right corner of a HUD layer.
static func add_open_button(hud: CanvasLayer) -> Button:
	var button := Button.new()
	button.name = "MenuButton"
	button.custom_minimum_size = Vector2(76, 76)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Paramètres"
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, _box(Color(INK, 0.7 if state == "normal" else 0.9), 38, 2))
	var icon := Control.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.draw.connect(func() -> void:
		for i in 3:
			icon.draw_rect(Rect2(24, 26 + i * 11, 28, 4), CREAM))
	button.add_child(icon)
	hud.add_child(button)
	var place := func() -> void:
		var inset := SafeArea.insets(button.get_viewport())
		var screen := button.get_viewport().get_visible_rect().size
		button.position = Vector2(screen.x - inset.x - button.custom_minimum_size.x, inset.y)
	place.call()
	button.get_viewport().size_changed.connect(place)
	button.pressed.connect(func() -> void: SettingsMenu.open(hud))
	return button


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.01, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)   # also stops touches from reaching the game

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.add_theme_stylebox_override("panel", _box(INK, 22, 3, 28))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	col.add_child(_label("Paramètres", 40, Color(1, 0.86, 0.5)))
	col.add_child(_label("Graphismes", 24, CREAM))
	var group := ButtonGroup.new()
	for level in Quality.Level.values():
		var row := _button(_row_text(level))
		row.toggle_mode = true
		row.button_group = group
		row.button_pressed = level == Quality.level
		row.pressed.connect(_choose.bind(level))
		col.add_child(row)
		_rows.append(row)
	var hint := _label(HINTS[Quality.level], 18, Color(CREAM, 0.8))
	hint.name = "Hint"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)

	col.add_child(_label("Caméra : distance", 24, CREAM))
	var zoom := HSlider.new()
	zoom.min_value = CameraRig.DISTANCE_MIN
	zoom.max_value = CameraRig.DISTANCE_MAX
	zoom.step = 0.5
	zoom.value = float(Quality.pref("camera", "distance", CameraRig.DISTANCE_DEFAULT))
	zoom.custom_minimum_size = Vector2(0, 52)
	zoom.add_theme_icon_override("grabber", _disc_icon(34, Color(0.98, 0.76, 0.35)))
	zoom.add_theme_icon_override("grabber_highlight", _disc_icon(38, Color(1.0, 0.86, 0.5)))
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.3, 0.32, 0.36)
	track.set_corner_radius_all(4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	zoom.add_theme_stylebox_override("slider", track)
	var filled := track.duplicate() as StyleBoxFlat
	filled.bg_color = Color(0.79, 0.54, 0.16)
	zoom.add_theme_stylebox_override("grabber_area", filled)
	zoom.add_theme_stylebox_override("grabber_area_highlight", filled)
	zoom.value_changed.connect(func(v: float) -> void: Quality.set_pref("camera", "distance", v, false))
	col.add_child(zoom)
	col.add_child(_label("(ou pincer l'écran avec deux doigts)", 16, Color(CREAM, 0.6)))

	var close := _button("Fermer")
	close.pressed.connect(_close)
	col.add_child(close)
	_rows[Quality.level].grab_focus()


func _row_text(level: int) -> String:
	var text := Quality.level_name(level)
	if level == Quality.recommended:
		text += "   ·   Recommandée pour cet appareil"
	return text


func _choose(level: int) -> void:
	Quality.set_level(level)
	(find_child("Hint", true, false) as Label).text = HINTS[level]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		_close()


## Android back gesture / button.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()


func _close() -> void:
	if is_queued_for_deletion():
		return
	Quality.save_prefs()
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_pressed_color", Color(1, 0.9, 0.6))
	b.add_theme_stylebox_override("normal", _box(Color(0.16, 0.18, 0.22), 14, 2))
	b.add_theme_stylebox_override("hover", _box(Color(0.2, 0.22, 0.27), 14, 2))
	b.add_theme_stylebox_override("pressed", _box(Color(0.45, 0.29, 0.08), 14, 3, 0, Color(0.98, 0.76, 0.35)))
	b.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), 14, 2, 0, Color(0.98, 0.76, 0.35)))
	return b


## A round slider handle big enough for a thumb.
static func _disc_icon(size: int, colour: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var r := size / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var c := colour if d < r - 3.0 else Color(0.24, 0.13, 0.05)
			img.set_pixel(x, y, Color(c, clampf(r - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _box(bg: Color, radius: int, border: int, margin := 0, border_color := AMBER) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border_color
	s.set_border_width_all(border)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin if margin > 0 else 12)
	return s
