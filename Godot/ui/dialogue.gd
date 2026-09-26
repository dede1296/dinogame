extends CanvasLayer
## Dialogue box (autoload "Dialogue"). `await Dialogue.run(DialogueDB.lines(id))` shows a
## script step by step (see DialogueDB); advances with the interact button or a tap.
## A character's line is typed with its little voice (VoiceBlips), unless a recorded voice
## plays; a "letter" step shows a handwritten page (LetterView).

signal finished

const CHARS_PER_SECOND := 48.0
const MIN_ADVANCE_INTERVAL := 0.15   # a tap on the A button also sends a touch: count it once
const VOICE_DUCK_DB := -12.0

var active := false

var _panel: PanelContainer
var _name_tag: Label
var _text: RichTextLabel
var _next_marker: Label
var _voice: AudioStreamPlayer
var _advance_requested := false
var _last_advance := 0.0
var _typing := false
var _in_letter := false
var _choosing := false
var _cancel_requested := false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false
	_voice = AudioStreamPlayer.new()
	_voice.bus = &"SFX"
	add_child(_voice)


## Asks a question: shows `text` said by `who`, then one button per option above the box.
## Returns the index of the chosen option (B / back = the last one, usually "Non" or "Annuler").
func choose(who: String, text: String, options: Array) -> int:
	active = true
	_panel.visible = true
	_panel.modulate.a = 1.0
	await _show_line(who, text, false)
	_next_marker.visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	column.offset_right = -24
	column.offset_bottom = -206
	add_child(column)
	var picked := [-1]
	for i in options.size():
		var b := Button.new()
		b.text = options[i]
		b.custom_minimum_size = Vector2(300, 54)
		b.add_theme_font_size_override("font_size", 21)
		b.add_theme_color_override("font_color", Color(0.97, 0.94, 0.87))
		for state in ["normal", "hover", "pressed", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.45, 0.29, 0.08) if state == "pressed" else Color(0.14, 0.16, 0.2, 0.96)
			sb.border_color = Color(0.98, 0.76, 0.35) if state == "focus" else Color(0.79, 0.54, 0.16)
			sb.set_border_width_all(2)
			sb.border_width_left = 5
			sb.set_corner_radius_all(10)
			sb.content_margin_left = 18
			sb.content_margin_right = 14
			b.add_theme_stylebox_override(state, sb)
		b.pressed.connect(func() -> void: picked[0] = i)
		column.add_child(b)
	(column.get_child(0) as Button).grab_focus()
	_choosing = true
	while picked[0] < 0:
		if _cancel_requested:
			picked[0] = options.size() - 1
		await get_tree().process_frame
	_choosing = false
	_cancel_requested = false
	column.queue_free()
	_panel.visible = false
	active = false
	return picked[0]


func run(steps: Array) -> void:
	if steps.is_empty():
		return
	active = true
	_panel.visible = true
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.15)
	for step: Dictionary in steps:
		if step.has("flag"):
			Game.set_flag(step["flag"])
		elif step.has("letter"):
			_panel.visible = false
			_in_letter = true
			await LetterView.open(get_tree(), step["letter"], step.get("sign", ""), step.get("voice", ""))
			_in_letter = false
			_panel.visible = true
		elif step.has("voice"):
			_play_voice(step["voice"])
		elif step.has("text"):
			await _show_line(step.get("who", ""), step["text"])
		elif step.has("text_fn"):   # a line worked out when it is shown (a count…)
			await _show_line(step.get("who", ""), (step["text_fn"] as Callable).call())
	if _voice.playing:
		_voice.stop()
		Audio.duck(0.0)
	await create_tween().tween_property(_panel, "modulate:a", 0.0, 0.12).finished
	_panel.visible = false
	active = false
	finished.emit()


func _play_voice(path: String) -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		push_error("Voix introuvable : %s" % path)
		return
	_voice.stream = stream
	_voice.play()
	Audio.duck(VOICE_DUCK_DB)
	_voice.finished.connect(func() -> void: Audio.duck(0.0), CONNECT_ONE_SHOT)


## `wait`: false = return once the line is typed (a question waits for its answer instead).
func _show_line(who: String, text: String, wait := true) -> void:
	_name_tag.visible = who != ""
	_name_tag.text = who
	_text.text = text
	_text.visible_characters = 0
	_next_marker.visible = false
	_advance_requested = false
	_typing = true
	var total := _text.get_total_character_count()
	var shown := 0.0
	var plain := _text.get_parsed_text()
	var blip_every := VoiceBlips.every(who)
	var last_blip := -blip_every
	while shown < total:
		if _advance_requested:   # tap while typing: show the whole line
			_advance_requested = false
			break
		shown += CHARS_PER_SECOND * get_process_delta_time()
		_text.visible_characters = int(shown)
		# The speaker's little voice, one blip every few letters (not over a recorded voice).
		var at := mini(int(shown), plain.length()) - 1
		if who != "" and not _voice.playing and at - last_blip >= blip_every and at >= 0 and _is_letter(plain[at]):
			last_blip = at
			VoiceBlips.blip(who)
		await get_tree().process_frame
	_text.visible_characters = -1
	_typing = false
	_next_marker.visible = true
	if not wait:
		return
	while not _advance_requested:
		await get_tree().process_frame
	_advance_requested = false


static func _is_letter(c: String) -> bool:
	return c.to_upper() != c.to_lower()


func _input(event: InputEvent) -> void:
	if not active or _in_letter:
		return
	if _choosing:
		# The buttons take the taps; B / back picks the last option.
		if event.is_action_pressed(&"cancel"):
			get_viewport().set_input_as_handled()
			_cancel_requested = true
		return
	var pressed: bool = event.is_action_pressed(&"interact") \
		or (event is InputEventScreenTouch and event.pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_advance < MIN_ADVANCE_INTERVAL:
		return
	_last_advance = now
	_advance_requested = true


func _process(_delta: float) -> void:
	if _next_marker.visible:
		_next_marker.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 160.0)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	margin.offset_top = -190
	margin.add_theme_constant_override("margin_left", 150)
	margin.add_theme_constant_override("margin_right", 150)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.106, 0.122, 0.157, 0.94)
	style.border_color = Color(0.79, 0.54, 0.16)
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 16
	style.content_margin_bottom = 14
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 10
	_panel.add_theme_stylebox_override("panel", style)
	margin.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)

	_name_tag = Label.new()
	_name_tag.add_theme_color_override("font_color", Color(0.98, 0.76, 0.35))
	_name_tag.add_theme_font_size_override("font_size", 22)
	box.add_child(_name_tag)

	_text = RichTextLabel.new()
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(0, 84)
	_text.add_theme_font_size_override("normal_font_size", 25)
	_text.add_theme_color_override("default_color", Color(0.96, 0.93, 0.86))
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_text)

	_next_marker = Label.new()
	_next_marker.text = "▼"
	_next_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_next_marker.add_theme_color_override("font_color", Color(0.98, 0.76, 0.35))
	box.add_child(_next_marker)
