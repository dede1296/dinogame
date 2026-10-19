class_name CinematicSkip
extends Control
## « Passer », en bas à droite des cinématiques et des crédits (ui/cinematic.gd). Toujours cliquable à
## la souris, dès la première image, mais discret tant qu'on ne touche à rien. N'importe quelle touche,
## bouton ou geste l'allume LIT_S secondes et écrit en petit, au-dessus, ce que font les touches. Deux
## appuis (Échap, B, ou toute autre touche que celle qui avance) dans ces secondes-là, ou un clic sur le
## bouton : on passe tout. La touche est dessinée SOUS le bouton (Prompts : celle du clavier ou de la
## manette tenue, à jour des touches redéfinies), jamais écrite en dur. Dans les crédits, un bouton
## « Pause » à sa gauche (A, Espace, Entrée ou un clic sur l'image font pareil).

signal skip_requested
signal pause_requested

const LIT_S := 2.0
const DIM := 0.42
const FADE_PER_S := 5.0
const MARGIN := 22.0
const BUTTON_SIZE := Vector2(150, 52)
const TAG_PX := 36.0
const HINT_SIZE := 17
const ICON_PX := 30.0
const INK := Color(0.106, 0.122, 0.157, 0.9)
const GOLD := Color(1, 0.86, 0.5)
const CREAM := Color(1, 0.97, 0.9)

## A first press was made: a second one, while the button is lit, skips.
var armed := false
## Seconds left with the button lit.
var lit := 0.0
var skip_button: Button
var pause_button: Button
var _hint: PanelContainer
var _skip_words: Label
var _next_words: Label
var _skip_icon: TextureRect
var _next_icon: TextureRect
var _credits := false
var _paused := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override(&"separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, int(MARGIN))
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(column)
	_hint = _hint_panel()
	column.add_child(_hint)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override(&"separation", 12)
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(buttons)
	pause_button = _button("Pause", &"interact", pause_requested.emit)
	skip_button = _button("Passer", &"cancel", skip_requested.emit)
	buttons.add_child(pause_button.get_parent())
	buttons.add_child(skip_button.get_parent())
	pause_button.get_parent().visible = false
	modulate.a = DIM


func _ready() -> void:
	Prompts.changed.connect(_refresh)
	_refresh()


## Any input: lit for LIT_S seconds (a second press then skips only if it is a press, see press()).
func reveal() -> void:
	lit = LIT_S
	_refresh()


## A press of a key or button (not the one that goes on): the first one lights the button and arms
## it; a second one while it is lit asks to skip. True when this press skips.
func press() -> bool:
	if armed and lit > 0.0:
		armed = false
		skip_requested.emit()
		return true
	armed = true
	reveal()
	return false


## The credits: a « Pause » button, and A says « pause ».
func set_credits(on: bool) -> void:
	_credits = on
	pause_button.get_parent().visible = on
	_refresh()


func set_paused(on: bool) -> void:
	_paused = on
	pause_button.text = "Reprendre" if on else "Pause"
	_refresh()


## True when `point` (screen) is on one of the buttons: the click is theirs.
func covers(point: Vector2) -> bool:
	for button: Button in [skip_button, pause_button]:
		if button.is_visible_in_tree() and button.get_global_rect().has_point(point):
			return true
	return false


func tick(dt: float) -> void:
	lit = maxf(lit - dt, 0.0)
	if lit <= 0.0 and armed:
		armed = false
		_refresh()
	var shown := lit > 0.0 or _paused
	modulate.a = move_toward(modulate.a, 1.0 if shown else DIM, FADE_PER_S * dt)
	_hint.modulate.a = move_toward(_hint.modulate.a, 1.0 if shown else 0.0, FADE_PER_S * dt)


## Keys are drawn on a computer (a phone has its fingers); never without a screen (the tests: there,
## the keyboard's layout cannot be read).
static func keys_drawn() -> bool:
	return Screen.on_computer() and DisplayServer.get_name() != "headless"


## The two small lines over the buttons: what passes, what goes on (keys drawn, words in French).
func _hint_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.add_theme_stylebox_override(&"panel", SettingsMenu._box(Color(INK, 0.78), 10, 0, 8))
	panel.modulate.a = 0.0
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override(&"separation", 2)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(rows)
	var skip_row := _hint_row()
	_skip_icon = skip_row[0]
	_skip_words = skip_row[1]
	rows.add_child(skip_row[2])
	var next_row := _hint_row()
	_next_icon = next_row[0]
	_next_words = next_row[1]
	rows.add_child(next_row[2])
	return panel


func _hint_row() -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var words := Label.new()
	words.add_theme_font_size_override(&"font_size", HINT_SIZE)
	words.add_theme_color_override(&"font_color", Color(CREAM, 0.9))
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(words)
	return [icon, words, row]


## The words and the keys of the moment (keyboard or pad: whichever was touched last).
func _refresh() -> void:
	if _skip_words == null:
		return
	var computer := keys_drawn()
	_skip_icon.texture = Prompts.texture(&"cancel") if computer else null
	_next_icon.texture = Prompts.texture(&"interact") if computer else null
	_skip_icon.visible = _skip_icon.texture != null
	_next_icon.visible = _next_icon.texture != null
	if armed:
		_skip_words.text = "Encore une fois : tout passer" if computer else "Touche « Passer » : tout passer"
		_skip_words.add_theme_color_override(&"font_color", GOLD)
	else:
		_skip_words.text = "Deux fois, ou maintenu : tout passer" if computer else "Touche « Passer » : tout passer"
		_skip_words.add_theme_color_override(&"font_color", Color(CREAM, 0.9))
	var next := ("Reprendre" if _paused else "Pause") if _credits else "Image suivante"
	_next_words.text = next if computer else "Touche l'image : %s" % next.to_lower()


## A button with its key drawn small under it (HudHint's rule: the key seen without hovering).
func _button(text: String, action: StringName, on_press: Callable) -> Button:
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override(&"separation", 3)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE   # (A and B are read by the film itself: no focus to steal them)
	button.custom_minimum_size = BUTTON_SIZE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override(&"font_size", 22)
	button.add_theme_color_override(&"font_color", CREAM)
	button.add_theme_stylebox_override(&"normal", SettingsMenu._box(INK, 14, 2))
	button.add_theme_stylebox_override(&"hover", SettingsMenu._box(Color(0.2, 0.22, 0.27, 0.95), 14, 3, 0, GOLD))
	button.add_theme_stylebox_override(&"pressed", SettingsMenu._box(Color(0.45, 0.29, 0.08), 14, 3, 0, GOLD))
	button.pressed.connect(on_press)
	button.mouse_entered.connect(reveal)
	holder.add_child(button)
	var tag := TextureRect.new()
	tag.name = "KeyTag"
	tag.custom_minimum_size = Vector2(TAG_PX, TAG_PX)
	tag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(tag)
	var refresh := func() -> void:
		tag.texture = Prompts.texture(action) if keys_drawn() else null
		tag.modulate.a = 1.0 if tag.texture else 0.0
	refresh.call()
	Prompts.changed.connect(refresh)
	return button
