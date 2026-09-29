class_name VoyageScreen
extends CanvasLayer
## Where to? The Grand Voyageur's stops (Voyage.STOPS): one row per stop already found, with its
## region and what one sees from there; the one Chloé stands at is marked and cannot be picked.
## Opened by talking to a Grand Voyageur (story/voyage.gd), the game paused meanwhile. Built for
## thumbs: big rows, one tap. B, Échap or the back gesture leave without going anywhere.

signal picked(zone: StringName)

const LAYER := 80
const PANEL_WIDTH := 660.0
const ROW_HEIGHT := 62.0
const LIST_HEIGHT := 380.0
const TEXT_INSET := 18.0   # a row's text away from its edge
const GOLD := Color(1, 0.86, 0.5)
const CREAM := Color(1, 0.97, 0.9)

## The stops to show: [zone, region name, what one sees from there]; `here`: Chloé's own zone.
var stops: Array = []
var here: StringName

var _was_paused := false
var _answered := false


## Asks where to go; returns the zone picked, or &"" if Chloé stays. Awaitable.
static func ask(parent: Node, to_show: Array, standing_at: StringName) -> StringName:
	var screen := VoyageScreen.new()
	screen.stops = to_show
	screen.here = standing_at
	parent.get_tree().root.add_child(screen)
	return await screen.picked


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.01, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)   # also stops touches from reaching the game

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.add_theme_stylebox_override("panel", SettingsMenu._box(SettingsMenu.INK, 22, 3, 22))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	col.add_child(_label("Où allons-nous ?", 34, GOLD))
	col.add_child(_label("Le Grand Voyageur connaît les vieux chemins de l'île.", 18, Color(CREAM, 0.75)))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, minf(LIST_HEIGHT, stops.size() * (ROW_HEIGHT + 8)))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)
	var first: Button = null
	for stop: Array in stops:
		var row := _row(stop[0], stop[1], stop[2])
		rows.add_child(row)
		if first == null and not row.disabled:
			first = row

	var stay := _button("Rester ici")
	stay.pressed.connect(_answer.bind(&""))
	col.add_child(stay)
	(first if first else stay).grab_focus()


## One stop: its region and what one sees from there; Chloé's own is shown, greyed, « tu es ici ».
func _row(zone: StringName, region_name: String, sight: String) -> Button:
	var button := _button("")
	button.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = TEXT_INSET     # (the button's own margin does not reach a child laid over it)
	box.offset_right = -TEXT_INSET
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := _label(region_name, 24, CREAM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(title)
	var under := _label("Tu es ici." if zone == here else sight, 16, Color(CREAM, 0.7))
	under.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(under)
	button.add_child(box)
	if zone == here:
		button.disabled = true
		button.modulate = Color(1, 1, 1, 0.5)
	else:
		button.pressed.connect(_answer.bind(zone))
	return button


func _answer(zone: StringName) -> void:
	if _answered:
		return
	_answered = true
	get_tree().paused = _was_paused
	picked.emit(zone)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		_answer(&"")


## Android back gesture / button.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_answer(&"")


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
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_pressed_color", Color(1, 0.9, 0.6))
	b.add_theme_stylebox_override("normal", SettingsMenu._box(Color(0.16, 0.18, 0.22), 14, 2))
	b.add_theme_stylebox_override("hover", SettingsMenu._box(Color(0.2, 0.22, 0.27), 14, 2))
	b.add_theme_stylebox_override("pressed", SettingsMenu._box(Color(0.45, 0.29, 0.08), 14, 3, 0, Color(0.98, 0.76, 0.35)))
	b.add_theme_stylebox_override("disabled", SettingsMenu._box(Color(0.12, 0.13, 0.16), 14, 2, 0, Color(GOLD, 0.3)))
	b.add_theme_stylebox_override("focus", SettingsMenu._box(Color(0, 0, 0, 0), 14, 2, 0, Color(0.98, 0.76, 0.35)))
	return b
