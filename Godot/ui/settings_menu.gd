class_name SettingsMenu
extends CanvasLayer
## The game's menu, over a paused game: from the ☰ button in game (Reprendre, Sons, Affichage,
## Retour au titre), or « Paramètres » on the title screen (Sons, Affichage). Sons: a volume for
## each kind of sound (Audio.CATEGORIES), heard as it is set; Affichage: the graphics level (the
## one detected for the phone marked « Recommandée ») and the camera's distance. Built for thumbs:
## big rows, one tap; B, Échap or the back gesture go back a page, then close.

signal closed

const LAYER := 80
const ROW_HEIGHT := 68.0
const SLIDER_ROW := 54.0
const PANEL_WIDTH := 640.0
const AMBER := Color(0.79, 0.54, 0.16)
const INK := Color(0.106, 0.122, 0.157, 0.96)
const CREAM := Color(1, 0.97, 0.9)
const GOLD := Color(1, 0.86, 0.5)
const TITLE_SCREEN := "res://scenes/boot/boot.tscn"
const HINTS := [
	"Pour les téléphones plus anciens : moins d'effets, 60 images/s.",
	"L'équilibre entre effets et autonomie, 60 images/s.",
	"Tous les effets, et la fluidité maximale de l'écran.",
]
## What a kind of sound plays once its volume is set (the music and the ambience: already heard).
const SAMPLES := {
	&"Master": "res://assets/audio/sfx/item.wav", &"Cries": "res://assets/audio/cries/raptor-neutre.mp3",
	&"Voices": "res://assets/audio/voices/roc-1.mp3", &"SFX": "res://assets/audio/sfx/item.wav",
	&"Steps": "res://assets/audio/footsteps/footstep00.ogg",
}
const SAMPLE_WAIT_S := 0.25   # the slider still this long: its sample plays
const SAMPLE_S := 2.5         # then stops (a voice: its first words)

## Opened in game (the ☰ button): Reprendre and Retour au titre too.
var in_game := false
var _was_paused := false
var _page := ""
var _rows: VBoxContainer
var _levels: Array[Button] = []
var _sample: AudioStreamPlayer
var _sample_ticket := 0


## Opens the menu over `parent`'s scene and pauses the game until it is closed.
static func open(parent: Node, from_game := false) -> SettingsMenu:
	var menu := SettingsMenu.new()
	menu.in_game = from_game
	parent.get_tree().root.add_child(menu)
	return menu


## Adds the round « menu » button in the top-right corner of a HUD layer.
static func add_open_button(hud: CanvasLayer) -> Button:
	var button := Button.new()
	button.name = "MenuButton"
	button.custom_minimum_size = Vector2(76, 76)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Menu"
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
	button.pressed.connect(func() -> void: SettingsMenu.open(hud, true))
	return button


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_sample = AudioStreamPlayer.new()
	add_child(_sample)
	_build()
	_show("menu")


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
	panel.add_theme_stylebox_override("panel", _box(INK, 22, 3, 24))
	center.add_child(panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	panel.add_child(_rows)


# ------------------------------------------------------------------ pages

## Shows page `page` ("menu", "sons", "affichage", "titre") in place of the current one.
func _show(page: String) -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_levels.clear()
	_page = page
	match page:
		"sons":
			_sounds_page()
		"affichage":
			_display_page()
		"titre":
			_title_page()
		_:
			_menu_page()
	_focus_first()


func _menu_page() -> void:
	_rows.add_child(_label("Menu" if in_game else "Paramètres", 40, GOLD))
	if in_game:
		_rows.add_child(_button("Reprendre", _close))
	_rows.add_child(_button("Sons", _show.bind("sons")))
	_rows.add_child(_button("Affichage", _show.bind("affichage")))
	if in_game:
		_rows.add_child(_button("Retour au titre", _show.bind("titre")))
	else:
		_rows.add_child(_button("Fermer", _close))


func _sounds_page() -> void:
	_rows.add_child(_label("Sons", 40, GOLD))
	for category: Array in Audio.CATEGORIES:
		_rows.add_child(_volume_row(category[0], category[1]))
	_rows.add_child(_button("Retour", _show.bind("menu")))


## A kind of sound: its name, its slider (0 to 100 %), the value; its sample once set.
func _volume_row(bus: StringName, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, SLIDER_ROW)
	row.add_theme_constant_override("separation", 14)
	var name_label := _label(title, 24, CREAM)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.custom_minimum_size = Vector2(196, 0)
	row.add_child(name_label)
	var slider := _slider(0.0, 100.0, 5.0, roundf(Audio.volume(bus) * 100.0))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value := _label("%d %%" % int(slider.value), 22, Color(CREAM, 0.8))
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(76, 0)
	row.add_child(value)
	slider.value_changed.connect(func(v: float) -> void:
		Audio.set_volume(bus, v / 100.0, false)
		value.text = "%d %%" % int(v)
		_sample_later(bus))
	return row


func _display_page() -> void:
	_rows.add_child(_label("Affichage", 40, GOLD))
	_rows.add_child(_label("Graphismes", 24, CREAM))
	var group := ButtonGroup.new()
	for level in Quality.Level.values():
		var row := _button(_level_text(level), _choose.bind(level))
		row.toggle_mode = true
		row.button_group = group
		row.button_pressed = level == Quality.level
		_rows.add_child(row)
		_levels.append(row)
	var hint := _label(HINTS[Quality.level], 18, Color(CREAM, 0.8))
	hint.name = "Hint"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(hint)
	_rows.add_child(_label("Caméra : distance", 24, CREAM))
	var zoom := _slider(CameraRig.DISTANCE_MIN, CameraRig.DISTANCE_MAX, 0.5, CameraRig.saved_distance())
	zoom.value_changed.connect(func(v: float) -> void: Quality.set_pref("camera", "distance", v, false))
	_rows.add_child(zoom)
	_rows.add_child(_label("(ou pincer l'écran avec deux doigts)", 16, Color(CREAM, 0.6)))
	_rows.add_child(_button("Retour", _show.bind("menu")))


## Back to the title screen: the game saved first. Not in the middle of a scene (its script
## would go on without its world): wait for its end.
func _title_page() -> void:
	_rows.add_child(_label("Retour au titre", 40, GOLD))
	var can_leave := not _scene_playing()
	var text := "La partie est sauvegardée : « Continuer » la reprendra ici." if can_leave \
		else "Une scène est en cours : attends qu'elle se termine pour revenir au titre."
	var note := _label(text, 22, CREAM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(0, 70)
	_rows.add_child(note)
	if can_leave:
		_rows.add_child(_button("Revenir au titre", _to_title))
		_rows.add_child(_button("Non, continuer à jouer", _show.bind("menu")))
	else:
		_rows.add_child(_button("Retour", _show.bind("menu")))


# ------------------------------------------------------------------ actions

func _level_text(level: int) -> String:
	var text := Quality.level_name(level)
	if level == Quality.recommended:
		text += "   ·   Recommandée pour cet appareil"
	return text


func _choose(level: int) -> void:
	Quality.set_level(level)
	(find_child("Hint", true, false) as Label).text = HINTS[level]


## A scene or a dialogue is going on (Chloé is not free to move).
func _scene_playing() -> bool:
	if Dialogue.active:
		return true
	var player := get_tree().get_first_node_in_group(&"player")
	return player != null and bool(player.get("busy"))


func _to_title() -> void:
	Quality.save_prefs()
	if Save.enabled:
		Save.save_game()
	get_tree().paused = false
	closed.emit()
	queue_free()
	Router.go_to(TITLE_SCREEN)


## The sample of `bus` once its slider has been still a moment (not at each step of a drag).
func _sample_later(bus: StringName) -> void:
	_sample_ticket += 1
	var ticket := _sample_ticket
	await get_tree().create_timer(SAMPLE_WAIT_S, true).timeout
	if ticket != _sample_ticket or not is_inside_tree() or not SAMPLES.has(bus):
		return
	_sample.bus = bus if bus != &"Master" else Audio.SFX_BUS
	_sample.stream = load(SAMPLES[bus])
	_sample.play()
	await get_tree().create_timer(SAMPLE_S, true).timeout
	if ticket == _sample_ticket and is_instance_valid(_sample):
		_sample.stop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		_back()


## Android back gesture / button.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


## Back a page, or closed from the first one.
func _back() -> void:
	if _page != "menu":
		_show("menu")
	else:
		_close()


func _close() -> void:
	if is_queued_for_deletion():
		return
	Quality.save_prefs()
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()


# ------------------------------------------------------------------ widgets

func _focus_first() -> void:
	if not _levels.is_empty():
		_levels[Quality.level].grab_focus()
		return
	for child in _rows.get_children():
		var control := child as Control
		if control is BaseButton or control is Slider:
			control.grab_focus()
			return
		if control is HBoxContainer:   # a volume row: its slider
			control.get_child(1).grab_focus()
			return


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, action: Callable) -> Button:
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
	b.pressed.connect(action)
	return b


## A slider for a thumb: a big round handle, the filled part amber.
func _slider(from: float, to: float, step: float, value: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = from
	s.max_value = to
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(0, 48)
	s.add_theme_icon_override("grabber", _disc_icon(34, Color(0.98, 0.76, 0.35)))
	s.add_theme_icon_override("grabber_highlight", _disc_icon(38, GOLD))
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.3, 0.32, 0.36)
	track.set_corner_radius_all(4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	s.add_theme_stylebox_override("slider", track)
	var filled := track.duplicate() as StyleBoxFlat
	filled.bg_color = AMBER
	s.add_theme_stylebox_override("grabber_area", filled)
	s.add_theme_stylebox_override("grabber_area_highlight", filled)
	return s


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
