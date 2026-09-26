class_name Toast
extends CanvasLayer
## Short news at the top of the screen that do not stop the game (« +1 baie », « Galet
## d'ambre ! 7 / 30 »): a dark rounded band with a gold edge, which fades after a moment.
## Several stack up, the newest below.

const LAYER := 40
const SHOW_S := 2.4
const FADE_S := 0.45
const GOLD := Color(0.95, 0.76, 0.31)
const CREAM := Color(1, 0.97, 0.9)
const TOP := 96.0

var _column: VBoxContainer


## Shows `text` for a moment (`accent`: the colour of the edge).
static func say(tree: SceneTree, text: String, accent := GOLD) -> void:
	var toast := tree.root.get_node_or_null("Toast") as Toast
	if toast == null:
		toast = Toast.new()
		toast.name = "Toast"
		tree.root.add_child(toast)
	toast._add(text, accent)


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_column = VBoxContainer.new()
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override("separation", 6)
	_column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_column.position.y = TOP
	add_child(_column)


func _add(text: String, accent: Color) -> void:
	var band := PanelContainer.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.07, 0.05, 0.82)
	box.border_color = accent
	box.border_width_left = 4
	box.set_corner_radius_all(10)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	band.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", CREAM)
	band.add_child(label)
	_column.add_child(band)
	band.modulate.a = 0.0
	var t := band.create_tween()
	t.tween_property(band, "modulate:a", 1.0, 0.2)
	t.tween_interval(SHOW_S)
	t.tween_property(band, "modulate:a", 0.0, FADE_S)
	t.tween_callback(band.queue_free)
