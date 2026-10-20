class_name SettingsMenu
extends CanvasLayer
## The game's menu, over a paused game: from the ☰ button in game (Reprendre, Commandes, Sons,
## Affichage, Retour au titre), or « Paramètres » on the title screen. Commandes: what every key
## and every finger does, phone and computer side by side (CONTROLS); Sons: a volume for each kind
## of sound (Audio.CATEGORIES), heard as it is set; Affichage: the graphics level (the one detected
## for the phone marked « Recommandée ») and the camera's distance. Built for thumbs: big rows,
## one tap; B, Échap or the back gesture go back a page, then close.

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
## The slots screen (loaded when used: it draws its boxes with this menu's _box).
const SAVE_SLOTS := "res://ui/save_slots.gd"
## The Commandes page: how tall its list is, and how wide its three columns are.
const CONTROLS_HEIGHT := 380.0
const CANCEL_PAD_BUTTON := JOY_BUTTON_B   # while a new button is awaited, B cancels (it cannot be given)
const KEY_NAME_W := 170.0    # the Touches page: the action's name before its key and its pad button
const CONTROL_WHAT_W := 196.0
const CONTROL_TOUCH_W := 214.0
const CONTROL_KEYS_W := 150.0
const PROMPT_PX := 44.0   # the keys and buttons drawn on the Commandes page (computer)
## What one does, on a phone and on a computer: [what it does, finger, keys]. Kept next to the
## game's own input map (project.godot [input], DexScreen.ensure_action).
const CONTROLS := [
	["Se déplacer", "Le pouce gauche, n'importe où sur la moitié gauche", "Les flèches, ou Z Q S D"],
	["Courir", "Garder B appuyé en marchant", "Maj (ou B de la manette) en marchant", [&"run"]],
	["Parler, ramasser, fouiller", "A", "Espace, Entrée ou E", [&"interact"]],
	["Revenir, fermer, refuser", "B", "Échap ou Retour arrière", [&"cancel"]],
	["Monter sur un dino, descendre", "Le bouton de selle, en bas à droite", "R", [&"ride"]],
	["La carte de l'île", "Le bouton carte, en haut à droite", "M", [&"map"]],
	["Le Dinodex", "Le bouton Dinodex, en haut à droite", "X", [&"dex"]],
	["Ce menu", "Le bouton ☰, en haut à droite", "Échap (ou Start)", [&"menu"]],
	["Plein écran, fenêtre", "—", "F11 (ou Alt + Entrée)"],
	["Voir de plus près, de plus loin", "Pincer l'écran à deux doigts", "La molette de la souris"],
	["Changer un dino d'équipe", "Glisser son portrait sur un autre", "Le glisser à la souris"],
]
const HINTS := [
	"Pour les téléphones plus anciens : moins d'effets, 60 images/s.",
	"L'équilibre entre effets et autonomie, 60 images/s.",
	"Tous les effets, et la fluidité maximale de l'écran.",
]
## The same three levels, said for someone playing on a computer.
const HINTS_PC := [
	"Pour une machine modeste : moins d'effets, 60 images/s.",
	"Tous les effets courants, 60 images/s.",
	"Tous les effets, et autant d'images par seconde que l'écran en affiche.",
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
## Touches: the action waiting for a new key ("key") or gamepad button ("pad"); &"" when none.
var _capture_action := &""
var _capture_kind := ""
## Touches: the button to give the focus back to once the page is redrawn (the one just used).
var _capture_focus: Button = null
var _last_capture_action := &""
var _last_capture_kind := ""


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
	HudHint.fit(button)
	hud.add_child(button)
	var place := func() -> void:
		var inset := SafeArea.insets(button.get_viewport())
		var screen := button.get_viewport().get_visible_rect().size
		button.position = Vector2(screen.x - inset.x - button.custom_minimum_size.x * HudHint.scale_pc(), inset.y)
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
	if page != "touches":
		_capture_focus = null
		_last_capture_action = &""
	_page = page
	match page:
		"commandes":
			_controls_page()
		"touches":
			_keys_page()
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
		if JournalWall.available():   # (a page found, or read in a game before: the journal wall)
			_rows.add_child(_button("Journal d'Hélène", _open_journal))
	_rows.add_child(_button("Commandes", _show.bind("commandes")))
	_rows.add_child(_button("Touches", _show.bind("touches")))
	_rows.add_child(_button("Sons", _show.bind("sons")))
	_rows.add_child(_button("Affichage", _show.bind("affichage")))
	_rows.add_child(_films_row())
	if in_game:
		if Save.slot_of_file(Save.path) > 0:   # (the game saves in a slot: not in the 3D's own file)
			_rows.add_child(_save_row())
		_rows.add_child(_button("Retour au titre", _show.bind("titre")))
	else:
		_rows.add_child(_button("Fermer", _close))


## What every key and every finger does: one row each, the phone on one side, the computer on the
## other. It scrolls: there are more rows than a phone screen holds.
func _controls_page() -> void:
	_rows.add_child(_label("Commandes", 40, GOLD))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	# (+ the rows' own left margin, so the titles sit over their column)
	var columns: Array = [["", CONTROL_WHAT_W + 10.0], ["Sur le téléphone", CONTROL_TOUCH_W],
		["Sur l'ordinateur", CONTROL_KEYS_W]]
	if Screen.on_computer():   # the finger column says nothing to someone playing on a computer
		columns = [["", CONTROL_WHAT_W + 10.0], ["Clavier, souris, manette", CONTROL_TOUCH_W + CONTROL_KEYS_W]]
	for column: Array in columns:
		var title := _label(column[0], 17, Color(GOLD, 0.85))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.custom_minimum_size = Vector2(column[1], 0)
		head.add_child(title)
	_rows.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, CONTROLS_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rows.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 6)
	scroll.add_child(rows)
	for control: Array in CONTROLS:
		var actions: Array = control[3] if control.size() > 3 else []
		if Screen.on_computer():
			rows.add_child(_control_row(control[0], control[2], "", actions))
		else:
			rows.add_child(_control_row(control[0], control[1], control[2]))
	if Screen.on_computer() and in_game:
		_rows.add_child(_button("Revoir le tutoriel des commandes", _replay_tutorial))
	_rows.add_child(_button("Retour", _show.bind("menu")))


## « Revoir l'intro », « Revoir la fin » (once the game is finished) and « Crédits » side by side
## (story/cinematiques.gd): one row, the menu stays short.
func _films_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for pair: Array in [["Revoir l'intro", "intro"], ["Revoir la fin", "end"], ["Crédits", "credits"]]:
		if not Cinematiques.replay_available(pair[1]):
			continue
		var button := _button(pair[0], _replay_film.bind(pair[1]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
	return row


## In game: the slot the game saves in (Save.slot), and « Changer d'emplacement » (ui/save_slots.gd,
## « Sauvegarder dans… »: the game is copied into the slot picked, which is the one from then on).
func _save_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "SaveRow"
	row.add_theme_constant_override("separation", 12)
	var where := _label("Sauvegarde : emplacement %d" % Save.slot, 22, CREAM)
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(where)
	var change := _button("Changer d'emplacement", _change_slot)
	change.name = "ChangeSlot"
	change.add_theme_font_size_override("font_size", 22)
	row.add_child(change)
	return row


## The slots screen over the menu (hidden meanwhile: the pad stays on the cards), then the menu again.
func _change_slot() -> void:
	visible = false
	var slots = load(SAVE_SLOTS)
	var screen = slots.open(self, slots.Mode.SAVE_TO)
	var n: int = await screen.chosen
	if n > 0 and not Save.switch_slot(n, true):   # (save_slots.gd asked before overwriting a game)
		Toast.say(get_tree(), "Sauvegarde impossible dans l'emplacement %d : la partie reste dans l'emplacement %d." % [n, Save.slot])
	visible = true
	_show("menu")
	var change := find_child("ChangeSlot", true, false) as Button
	if change and Prompts.navigating:
		change.grab_focus()


## Closes the menu, then plays the intro or the credits over the screen; back to it at the end.
func _replay_film(what: String) -> void:
	var root := get_tree().root
	_close()
	Cinematiques.replay.call_deferred(root, what)


## Closes the menu, then plays the controls tutorial again.
func _replay_tutorial() -> void:
	var root := get_tree().root
	_close()
	ControlsTutorial.open.call_deferred(root)


## Closes the menu, then opens the journal wall: the pages found, read again (grey: those of a game before).
func _open_journal() -> void:
	var root := get_tree().root
	_close()
	JournalWall.open.call_deferred(root)


## Touches: the gamepad drawn, each button with the action it does (tap it, then press the new
## button), and the keyboard keys in a list (tap one, then press the new key). Échap cancels.
func _keys_page() -> void:
	_rows.add_child(_label("Touches", 40, GOLD))
	var hint := _label(_capture_text(), 20, GOLD if _capture_action != &"" else Color(CREAM, 0.8))
	hint.name = "Hint"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(hint)
	var pad := GamepadView.new()
	pad.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pad.set_labels(_pad_labels())
	pad.button_tapped.connect(func(button: int) -> void:
		var action := _action_on_pad(button)
		if action != &"":
			_start_capture(action, "pad"))
	# The drawing and the list scroll (the focus brings the line it is on into view); the hint above
	# and the two buttons below stay on screen.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, CONTROLS_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_rows.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var first_key: Button = null
	for entry: Array in KeyRemap.actions():
		var row := _key_row(entry[0], entry[1])
		list.add_child(row)
		first_key = first_key if first_key else row.get_child(1) as Button
	list.add_child(pad)   # (the list first: it is what the pad uses; the drawing is below it)
	if _capture_focus == null:
		_capture_focus = first_key
	_rows.add_child(_button("Rétablir les commandes par défaut", _reset_keys))
	_rows.add_child(_button("Retour", _show.bind("menu")))


## One action of the list: its name, then the keyboard key it uses (tap it to change).
func _key_row(action: StringName, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := _label(title, 22, CREAM)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.custom_minimum_size = Vector2(KEY_NAME_W, 0)
	row.add_child(name_label)
	var key := _button(KeyRemap.label(action, "key"), _start_capture.bind(action, "key"))
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(key)
	# Le bouton de la manette de l'action : on le redéfinit à la manette seule, sans passer par le dessin.
	var pad_button := _button(GamepadView.name_of(KeyRemap.current(action, "pad")), _start_capture.bind(action, "pad"))
	pad_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(pad_button)
	if action == _last_capture_action:
		_capture_focus = key if _last_capture_kind == "key" else pad_button
	return row


func _pad_labels() -> Dictionary:
	var labels := {}
	for entry: Array in KeyRemap.actions():
		var button := KeyRemap.current(entry[0], "pad")
		if button != KeyRemap.UNBOUND:
			labels[button] = entry[1]
	return labels


func _action_on_pad(button: int) -> StringName:
	for entry: Array in KeyRemap.actions():
		if KeyRemap.current(entry[0], "pad") == button:
			return entry[0]
	return &""


func _start_capture(action: StringName, kind: String) -> void:
	_capture_action = action
	_capture_kind = kind
	_last_capture_action = action
	_last_capture_kind = kind
	_show("touches")


func _end_capture() -> void:
	_capture_action = &""
	_show("touches")


func _capture_text() -> String:
	if _capture_action == &"":
		return "Choisissez une touche ou un bouton de la manette dans la liste (ou touchez le dessin), puis appuyez sur la nouvelle commande."
	var what := "une touche" if _capture_kind == "key" else "un bouton de la manette"
	return "Appuyez sur %s pour « %s »… (Échap ou B annule)" % [what, _entry_name(_capture_action)]


func _entry_name(action: StringName) -> String:
	for entry: Array in KeyRemap.actions():
		if entry[0] == action:
			return entry[1]
	return String(action)


func _reset_keys() -> void:
	KeyRemap.reset()
	_show("touches")


## While a new key or button is awaited, it is taken here (before the menu's buttons see it).
func _input(event: InputEvent) -> void:
	if _capture_action == &"":
		return
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	var pressed := (key != null and key.pressed and not key.echo) or (pad != null and pad.pressed)
	if not pressed or (key != null and _capture_kind != "key"):
		return
	# (a pad button during a key capture is only good to cancel it: B, so the pad alone can get out)
	var cancels := (key != null and key.physical_keycode == KeyRemap.ESCAPE_KEY) \
		or (pad != null and pad.button_index == CANCEL_PAD_BUTTON)
	if pad != null and _capture_kind != "pad" and not cancels:
		return
	get_viewport().set_input_as_handled()
	if cancels:
		_end_capture()
		return
	KeyRemap.bind(_capture_action, event)
	_end_capture()


## One line of the Commandes page: what it does, then the finger and the keys for it.
func _control_row(what: String, touch: String, keys: String, actions: Array = []) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(0.16, 0.18, 0.22), 12, 1, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	for column: Array in [[what, CONTROL_WHAT_W, CREAM, 19], [touch, CONTROL_TOUCH_W, Color(CREAM, 0.8), 15],
			[keys, CONTROL_KEYS_W, Color(CREAM, 0.8), 15]]:
		var text := _label(column[0], column[3], column[2])
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text.custom_minimum_size = Vector2(column[1], 0)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(text)
	if not actions.is_empty():
		_show_prompts(row, actions)
	return panel


## Sur ordinateur : à la place du texte des touches, les vraies — la touche du clavier ET le bouton
## de la manette de l'action (ce que la page Touches a redéfini, pas ce que le texte annonçait).
func _show_prompts(row: HBoxContainer, actions: Array) -> void:
	var texts := row.get_children().filter(func(c: Node) -> bool: return c is Label)
	for i in range(1, texts.size()):
		texts[i].visible = false   # the keys text (and the empty column after it) give way
	# The icons sit where the keys text was: after the action's name.
	for action: StringName in actions:
		for kind in ["key", "pad"]:
			var picture := Prompts.texture(action, kind)
			if picture == null:
				continue
			var icon := TextureRect.new()
			icon.texture = picture
			icon.custom_minimum_size = Vector2(PROMPT_PX, PROMPT_PX)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)


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
	var hint := _label(_level_hint(Quality.level), 18, Color(CREAM, 0.8))
	hint.name = "Hint"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(hint)
	_rows.add_child(_label("Caméra : distance", 24, CREAM))
	var zoom := _slider(CameraRig.DISTANCE_MIN, CameraRig.DISTANCE_MAX, 0.5, CameraRig.saved_distance())
	zoom.value_changed.connect(func(v: float) -> void: Quality.set_pref("camera", "distance", v, false))
	_rows.add_child(zoom)
	var how := "(ou la molette de la souris)" if Screen.on_computer() 		else "(ou pincer l'écran avec deux doigts)"
	_rows.add_child(_label(how, 16, Color(CREAM, 0.6)))
	if Screen.on_computer():
		_rows.add_child(_label("Fenêtre", 24, CREAM))
		_rows.add_child(_fullscreen_row())
	_rows.add_child(_button("Retour", _show.bind("menu")))


## Full screen or a window, remembered (Screen). F11 and Alt + Entrée do the same thing.
func _fullscreen_row() -> Button:
	var row := _button(_fullscreen_text(), func() -> void: Screen.toggle())
	row.text = _fullscreen_text()
	Screen.changed.connect(func() -> void:
		if is_instance_valid(row):
			row.text = _fullscreen_text())
	return row


func _fullscreen_text() -> String:
	return "Plein écran   ·   oui   (F11)" if Screen.is_fullscreen() else "Plein écran   ·   non   (F11)"


## Back to the title screen: the game saved first. Not in the middle of a scene (its script
## would go on without its world): wait for its end.
func _title_page() -> void:
	_rows.add_child(_label("Retour au titre", 40, GOLD))
	var can_leave := not _scene_playing()
	var text := "La partie est sauvegardée (emplacement %d) : « Continuer » la reprendra ici." % Save.slot if can_leave \
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
		text += "   ·   Recommandée pour cette machine" if Screen.on_computer() 			else "   ·   Recommandée pour cet appareil"
	return text


func _choose(level: int) -> void:
	Quality.set_level(level)
	(find_child("Hint", true, false) as Label).text = _level_hint(level)


## What a graphics level means, said for the machine this is played on.
func _level_hint(level: int) -> String:
	return HINTS_PC[level] if Screen.on_computer() else HINTS[level]


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
	if not visible:   # (hidden under the slots screen: it answers)
		return
	if event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		_back()


## Android back gesture / button.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible:
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
	if _page == "touches" and is_instance_valid(_capture_focus) and _capture_focus.is_inside_tree():
		_capture_focus.grab_focus()   # (back on the line just used, not on the first one)
		return
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
