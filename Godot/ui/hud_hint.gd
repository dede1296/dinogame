class_name HudHint
extends Control
## Les gestes de la souris sur le HUD (ordinateur seulement) : une main au survol, le bord du bouton
## qui s'allume, et une étiquette — son nom et la touche du clavier ou le bouton de la manette qui
## fait pareil (`Prompts`, donc à jour des touches redéfinies). Remplace les infobulles de Godot, qui
## écrivaient « (M) » en dur, restaient dans le coin et ignoraient la manette.
##
##   var hint := HudHint.install(hud)
##   hint.attach(button, "Carte", &"map")
##   hint.attach(slot, func() -> String: return "%s · Niv. %d" % [...], &"", "Clic : menu")
## Le titre est un texte, ou une fonction rappelée à chaque survol (un nom qui change).

## The round buttons are stacked down the right edge: the phone's step, and the computer's — wider,
## to leave room for the small key written under each button (_key_tag).
const STACK_STEP_PHONE := 86.0
const STACK_STEP_PC := 104.0
const TAG_PX := 26.0
const DELAY_S := 0.28        # on ne montre rien tant que la souris ne s'arrête pas
const FADE_PER_S := 10.0
const GAP := 12.0            # entre le bouton et l'étiquette
const ICON_PX := 34.0
const PLATE := Color(0.105882, 0.121569, 0.156863, 0.94)
const RIM := Color(0.98, 0.76, 0.35, 0.95)
const CREAM := Color(1, 0.97, 0.9)
const GOLD := Color(1, 0.86, 0.5)

var _plate: PanelContainer
var _title: Label
var _detail: Label
var _icon: TextureRect
var _target: Control
var _since := 0.0
var _wanted := false


## Where the n-th round button of the right edge starts (0: the menu button), under the safe area.
static func stack_y(n: int) -> float:
	return n * (STACK_STEP_PC if Screen.on_computer() else STACK_STEP_PHONE)


## Le panneau d'étiquette, posé dans `hud` (une seule fois).
static func install(hud: CanvasLayer) -> HudHint:
	var hint := HudHint.new()
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint.z_index = 100   # over what is added to the HUD after it (the quest tracker…)
	hud.add_child(hint)
	return hint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # il doit aussi s'éteindre quand le jeu est en pause
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = PLATE
	box.border_color = RIM
	box.set_border_width_all(2)
	box.set_corner_radius_all(12)
	box.content_margin_left = 14
	box.content_margin_right = 10
	box.content_margin_top = 7
	box.content_margin_bottom = 7
	_plate.add_theme_stylebox_override(&"panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(row)
	var words := VBoxContainer.new()
	words.add_theme_constant_override(&"separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(words)
	_title = _label(22, CREAM)
	words.add_child(_title)
	_detail = _label(16, Color(CREAM, 0.7))
	words.add_child(_detail)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_icon)
	add_child(_plate)
	_plate.modulate.a = 0.0


## `control` : le bouton, la vignette… `title` : un texte ou une fonction qui en rend un ;
## `action` : l'action dont on montre la touche (vide : aucune) ; `detail` : une ligne en dessous.
## `beside` : rend le rectangle à côté duquel poser l'étiquette (à sa droite, en haut) — pour ne pas
## tomber sur ce qui est sous le contrôle (le nom du lieu, sous les portraits).
func attach(control: Control, title: Variant, action := &"", detail := "", beside := Callable()) -> void:
	if not Screen.on_computer() or control == null:
		return
	control.tooltip_text = ""   # (l'infobulle de Godot, remplacée)
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if control is BaseButton:
		_light_up(control as BaseButton)
		if action != &"":
			_key_tag(control as BaseButton, action)
	control.mouse_entered.connect(_enter.bind(control, title, action, detail))
	if beside.is_valid():
		control.set_meta(&"hint_beside", beside)
	control.mouse_exited.connect(_leave.bind(control))
	control.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_leave(control))


## Le bord du bouton s'allume au survol (le reste de son dessin ne change pas).
func _light_up(button: BaseButton) -> void:
	var radius := int(minf(button.custom_minimum_size.x, button.custom_minimum_size.y) / 2.0)
	if radius <= 0:
		return
	button.add_theme_stylebox_override(&"hover", SettingsMenu._box(Color(SettingsMenu.INK, 0.96), radius, 3, 0, GOLD))


## The key (or the pad's button) that does the same, small, under the button: seen without hovering.
func _key_tag(button: BaseButton, action: StringName) -> void:
	var tag := TextureRect.new()
	tag.name = "KeyTag"
	tag.custom_minimum_size = Vector2(TAG_PX, TAG_PX)
	tag.size = Vector2(TAG_PX, TAG_PX)
	tag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(tag)
	var place := func() -> void:
		var wide := maxf(button.size.x, button.custom_minimum_size.x)
		var tall := maxf(button.size.y, button.custom_minimum_size.y)
		tag.position = Vector2((wide - TAG_PX) / 2.0, tall + 3.0)
	var refresh := func() -> void:
		var picture := Prompts.texture(action)
		tag.texture = picture
		tag.visible = picture != null
		place.call()
	refresh.call()
	Prompts.changed.connect(refresh)
	button.resized.connect(place)


func _enter(control: Control, title: Variant, action: StringName, detail: String) -> void:
	_target = control
	_since = 0.0
	_wanted = true
	_title.text = title.call() if title is Callable else str(title)
	_detail.text = detail
	_detail.visible = detail != ""
	var picture := Prompts.texture(action) if action != &"" else null
	_icon.texture = picture
	_icon.visible = picture != null
	_plate.reset_size()


func _leave(control: Control) -> void:
	if _target == control:
		_wanted = false


func _process(delta: float) -> void:
	if _wanted and (not is_instance_valid(_target) or not _target.is_visible_in_tree()):
		_wanted = false
	_since += delta
	var show := _wanted and _since >= DELAY_S
	_plate.modulate.a = move_toward(_plate.modulate.a, 1.0 if show else 0.0, FADE_PER_S * delta)
	if _plate.modulate.a > 0.0 and is_instance_valid(_target):
		_place()


## À gauche d'un bouton du bord droit, en dessous de ce qui est à gauche de l'écran ; toujours dans l'écran.
func _place() -> void:
	var area := _target.get_global_rect()
	var screen := get_viewport().get_visible_rect().size
	var size := _plate.size
	var at := Vector2.ZERO
	var beside: Variant = _target.get_meta(&"hint_beside", null)
	if beside is Callable:
		var row: Rect2 = (beside as Callable).call()
		at = Vector2(row.end.x + GAP, row.position.y)
	elif area.get_center().x > screen.x * 0.5:
		at = Vector2(area.position.x - GAP - size.x, area.get_center().y - size.y * 0.5)
	else:
		at = Vector2(area.position.x, area.end.y + GAP)
	_plate.position = Vector2(clampf(at.x, 8.0, screen.x - size.x - 8.0), clampf(at.y, 8.0, screen.y - size.y - 8.0))


func _label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", colour)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
