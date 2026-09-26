class_name LetterView
extends CanvasLayer
## A handwritten letter or journal page on illustrated old paper, over the dimmed game.
## `await LetterView.open(tree, paragraphs, "— H.", voice_path)`: the page slides in, a
## recorded voice reads it if there is one, a tap / A / B puts it away.

signal closed

const PAPER := preload("res://assets/art/ui/papier.webp")
const HAND := preload("res://assets/fonts/Caveat.ttf")
const PAGE_SFX := preload("res://assets/audio/sfx/page.wav")
const INK := Color(0.23, 0.165, 0.1)
const LAYER := 60
## Where the writing goes on the paper (fractions: left, top, right, bottom), as on the web.
const MARGINS := [0.13, 0.12, 0.12, 0.31]
const VOICE_DUCK_DB := -12.0

var _voice: AudioStreamPlayer
var _paper: TextureRect
var _closing := false
var _opened_at := 0


static func open(tree: SceneTree, paragraphs: Array, sign := "", voice := "") -> void:
	var view := LetterView.new()
	view._setup(paragraphs, sign, voice)
	tree.root.add_child(view)
	await view.closed


func _setup(paragraphs: Array, sign: String, voice: String) -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.024, 0.03, 0.047, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_paper = TextureRect.new()
	_paper.texture = PAPER
	_paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paper.stretch_mode = TextureRect.STRETCH_SCALE
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_paper)

	var text := VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("separation", 10)
	_paper.add_child(text)
	var lines := paragraphs
	for i in lines.size():
		text.add_child(_hand_label(lines[i], 30 if i == 0 and lines.size() > 1 else 25, i == 0 and lines.size() > 1))
	if sign != "":
		var s := _hand_label(sign, 27, false)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		text.add_child(s)
	_paper.set_meta(&"text", text)

	var hint := Label.new()
	hint.text = "Touche l'écran ou appuie sur A pour ranger la lettre"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.95, 0.94, 0.92, 0.7))
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -40
	hint.offset_bottom = -14
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	_voice = AudioStreamPlayer.new()
	_voice.bus = &"SFX"
	add_child(_voice)
	if voice != "" and ResourceLoader.exists(voice):
		_voice.stream = load(voice)


func _ready() -> void:
	_layout()
	get_viewport().size_changed.connect(_layout)
	_opened_at = Time.get_ticks_msec()
	Audio.play_sfx(PAGE_SFX, -4.0)
	if _voice.stream:
		_voice.play()
		Audio.duck(VOICE_DUCK_DB)
	# Slides up while turning straight, like a page laid on the table.
	_paper.modulate.a = 0.0
	_paper.pivot_offset = _paper.custom_minimum_size / 2.0
	_paper.rotation_degrees = -2.0
	_paper.scale = Vector2(0.96, 0.96)
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_paper, "modulate:a", 1.0, 0.3)
	t.tween_property(_paper, "rotation_degrees", -0.6, 0.45)
	t.tween_property(_paper, "scale", Vector2.ONE, 0.45)


## The paper keeps the web page's shape (3:4) and fits the screen's height.
func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	var h := minf(screen.y - 90.0, 640.0)
	var size := Vector2(h * 0.75, h)
	_paper.custom_minimum_size = size
	_paper.pivot_offset = size / 2.0
	var text: Control = _paper.get_meta(&"text")
	text.position = Vector2(size.x * MARGINS[0], size.y * MARGINS[1])
	text.size = Vector2(size.x * (1.0 - MARGINS[0] - MARGINS[2]), size.y * (1.0 - MARGINS[1] - MARGINS[3]))
	var scale_text := h / 640.0
	for child in text.get_children():
		var l := child as Label
		l.add_theme_font_size_override("font_size", roundi(float(l.get_meta(&"size")) * scale_text))


func _hand_label(content: String, font_size: int, title: bool) -> Label:
	var l := Label.new()
	l.text = content
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := FontVariation.new()
	font.base_font = HAND
	font.variation_opentype = {"wght": 700 if title else 500}
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.set_meta(&"size", font_size)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("line_spacing", -4)
	return l


func _input(event: InputEvent) -> void:
	var pressed: bool = event.is_action_pressed(&"interact") or event.is_action_pressed(&"cancel") \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	# The tap that picked the page up must not put it away at once.
	if Time.get_ticks_msec() - _opened_at > 350:
		_close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()


func _close() -> void:
	if _closing:
		return
	_closing = true
	if _voice.playing:
		_voice.stop()
	if _voice.stream:
		Audio.duck(0.0)
	Audio.play_sfx(PAGE_SFX, -6.0)
	var t := create_tween().set_parallel(true)
	t.tween_property(_paper, "modulate:a", 0.0, 0.2)
	t.tween_property(get_child(0), "modulate:a", 0.0, 0.25)
	await t.finished
	closed.emit()
	queue_free()
