class_name MapScreen
extends CanvasLayer
## The map of the current zone, drawn from its ground and relief; the parts Chloé has not
## seen yet stay blank paper. Shows where she is, the places she has found (the habitats'
## names) and the ways out to other zones. Opened from the map button or M; the game is
## paused meanwhile.

signal closed

const LAYER := 80
const SHADER := preload("res://ui/map.gdshader")
const TILE := 48.0
const GOLD := Color(1, 0.86, 0.5)
const INK_TEXT := Color(0.2, 0.13, 0.07)
const CHLOE := Color(0.86, 0.33, 0.16)
## What the ways out are called on the map.
const ZONE_NAMES := {
	&"port_ambre": "Port-Ambre", &"cabinet": "Cabinet du Pr Roc",
	&"plaines": "Plaines des Fougères", &"grotte_echos": "Grotte des Échos",
	&"antre_crane": "Antre du gardien",
}
## A name shows once this much of the ground under it has been seen.
const NAME_SEEN := 0.5
const PULSE_S := 1.4

var _region: Region
var _layers: Dictionary
var _chloe := Vector2.ZERO   # tiles
var _seen: PackedByteArray
var _cells := Vector2i.ONE
var _marks: Control
var _was_paused := false
var _time := 0.0


## Opens the map of `region` (drawn from `layers`, see WorldView.map_layers), Chloé at
## `chloe_tile`, over `parent`'s scene.
static func open(parent: Node, region: Region, layers: Dictionary, chloe_tile: Vector2) -> MapScreen:
	var map := MapScreen.new()
	map._region = region
	map._layers = layers
	map._chloe = chloe_tile
	parent.get_tree().root.add_child(map)
	return map


## Adds the round « map » button under the menu button of a HUD layer.
static func add_open_button(hud: CanvasLayer, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.name = "MapButton"
	button.custom_minimum_size = Vector2(76, 76)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Carte (M)"
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, SettingsMenu._box(Color(SettingsMenu.INK, 0.7 if state == "normal" else 0.9), 38, 2))
	var icon := Control.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.draw.connect(_draw_icon.bind(icon))
	button.add_child(icon)
	hud.add_child(button)
	var place := func() -> void:
		var inset := SafeArea.insets(button.get_viewport())
		var screen := button.get_viewport().get_visible_rect().size
		button.position = Vector2(screen.x - inset.x - button.custom_minimum_size.x, inset.y + 86.0)
	place.call()
	button.get_viewport().size_changed.connect(place)
	button.pressed.connect(on_pressed)
	return button


## A folded map, three panels.
static func _draw_icon(icon: Control) -> void:
	for i in 3:
		var x := 20.0 + i * 12.0
		var up := 24.0 + (i % 2) * 4.0
		var down := 28.0 - (i % 2) * 4.0
		icon.draw_colored_polygon(PackedVector2Array([Vector2(x, up), Vector2(x + 12.0, down),
			Vector2(x + 12.0, down + 26.0), Vector2(x, up + 26.0)]), Color(SettingsMenu.CREAM, 1.0 if i % 2 == 0 else 0.72))
	icon.draw_circle(Vector2(40, 36), 4.5, CHLOE)


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var size := _region.map_size()
	_cells = Game.explore_cells(size)
	_seen = Game.explored_mask(Game.region_id, size)
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.01, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)   # also stops touches from reaching the game

	var inset := SafeArea.insets(get_viewport())
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = inset.x + 8.0
	panel.offset_right = -inset.x - 8.0
	panel.offset_top = inset.y
	panel.offset_bottom = -inset.y
	panel.add_theme_stylebox_override("panel", SettingsMenu._box(SettingsMenu.INK, 22, 3, 14))
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var title := _label(_region.display_name, 30, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(_label("Exploré : %d %%" % floori(_explored_share() * 100.0), 20, Color(SettingsMenu.CREAM, 0.8)))
	var close := Button.new()
	close.text = "✕"
	close.custom_minimum_size = Vector2(56, 56)
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 26)
	close.add_theme_color_override("font_color", SettingsMenu.CREAM)
	for state in ["normal", "hover", "pressed"]:
		close.add_theme_stylebox_override(state, SettingsMenu._box(Color(0.16, 0.18, 0.22, 1.0 if state == "normal" else 0.8), 28, 2))
	close.pressed.connect(_close)
	head.add_child(close)

	var frame := AspectRatioContainer.new()
	var size := Vector2(_region.map_size())
	frame.ratio = size.x / size.y
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(frame)
	var map := ColorRect.new()
	map.material = _material(size)
	frame.add_child(map)
	_marks = Control.new()
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marks.draw.connect(_draw_marks)
	frame.add_child(_marks)


func _material(size: Vector2) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	for key: String in _layers:
		mat.set_shader_parameter(key, _layers[key])
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	var fog := Image.create_from_data(_cells.x, _cells.y, false, Image.FORMAT_L8, _seen)
	mat.set_shader_parameter("fog", ImageTexture.create_from_image(fog))
	mat.set_shader_parameter("fog_scale", size / Vector2(_cells * Game.EXPLORE_CELL))
	return mat


func _process(delta: float) -> void:
	_time += delta
	_marks.queue_redraw()


# ------------------------------------------------------------------ marks

func _draw_marks() -> void:
	var k := _marks.size / Vector2(_region.map_size())   # pixels per tile
	var font := _marks.get_theme_default_font()
	# The places found, by name.
	for h in _region.habitats():
		var centre := h.area().get_center() / TILE
		if h.label != "" and _seen_at(centre) >= NAME_SEEN:
			_text(font, centre * k, h.label, 17, INK_TEXT, Color(1, 0.95, 0.82, 0.85))
	# The ways out, once seen: an arrow to the edge, or a dark arch for a cave.
	for e in _region.exits():
		var r := _region.exit_rect(e)
		var at := r.get_center() / TILE
		if _seen_at(at) < NAME_SEEN:
			continue
		var where: String = ZONE_NAMES.get(e.target_zone, "")
		if _region.exit_on_edge(e):
			var dir := _region.exit_edge(e)
			var tip := (at * k).clamp(Vector2.ZERO, _marks.size) - dir * 4.0
			var side := dir.orthogonal() * 7.0
			_marks.draw_colored_polygon(PackedVector2Array([tip, tip - dir * 11.0 + side, tip - dir * 11.0 - side]), CHLOE)
			_text(font, tip - dir * 26.0, where, 15, Color(SettingsMenu.CREAM), Color(0.1, 0.07, 0.04, 0.9))
		else:
			var p := at * k
			_marks.draw_circle(p, 7.0, Color(0.08, 0.06, 0.05))
			_marks.draw_rect(Rect2(p + Vector2(-7, 0), Vector2(14, 6)), Color(0.08, 0.06, 0.05))
			_text(font, p + Vector2(0, -16), where, 15, Color(SettingsMenu.CREAM), Color(0.1, 0.07, 0.04, 0.9))
	# Chloé: a dot, and a ring spreading from it.
	var me := _chloe * k
	var pulse := fmod(_time, PULSE_S) / PULSE_S
	_marks.draw_arc(me, 8.0 + pulse * 16.0, 0.0, TAU, 32, Color(CHLOE, 1.0 - pulse), 3.0)
	_marks.draw_circle(me, 9.0, Color.WHITE)
	_marks.draw_circle(me, 6.5, CHLOE)
	# North, and the frame.
	var n := Vector2(_marks.size.x - 26.0, 30.0)
	_marks.draw_colored_polygon(PackedVector2Array([n + Vector2(0, -14), n + Vector2(7, 6), n + Vector2(-7, 6)]), INK_TEXT)
	_text(font, n + Vector2(0, 22), "N", 16, INK_TEXT, Color(1, 0.95, 0.82, 0.85))
	_marks.draw_rect(Rect2(Vector2.ZERO, _marks.size), Color(SettingsMenu.AMBER, 0.9), false, 2.0)


## Text centred on `at`, with an outline so it reads on any ground.
func _text(font: Font, at: Vector2, text: String, font_size: int, colour: Color, outline: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := at + Vector2(-w / 2.0, font_size * 0.35)
	_marks.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, outline)
	_marks.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


## How much of the ground at `tile` has been seen (0–1).
func _seen_at(tile: Vector2) -> float:
	var c := Vector2i(tile / Game.EXPLORE_CELL).clamp(Vector2i.ZERO, _cells - Vector2i.ONE)
	return _seen[c.y * _cells.x + c.x] / 255.0


## Share of the walkable ground seen (woods and water do not count).
func _explored_share() -> float:
	var total := 0
	var seen := 0.0
	for y in _cells.y:
		for x in _cells.x:
			var s := _region.surface_at((Vector2(x, y) * Game.EXPLORE_CELL + Vector2.ONE) * TILE)
			if s == &"forest" or s == &"water" or s == &"":
				continue
			total += 1
			seen += _seen[y * _cells.x + x] / 255.0
	return seen / maxf(total, 1.0)


# ------------------------------------------------------------------ closing

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"map"):
		get_viewport().set_input_as_handled()
		_close()


## Android back gesture / button.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()


func _close() -> void:
	if is_queued_for_deletion():
		return
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()


func _label(text: String, font_size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	return l
