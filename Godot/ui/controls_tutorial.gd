class_name ControlsTutorial
extends CanvasLayer
## Le tutoriel des commandes, au début de la partie (ordinateur seulement) : trois pages qui disent
## quelles touches ou quels boutons font quoi, avec les vraies images du clavier ou de la manette
## que le joueur tient — elles changent sous ses yeux dès qu'il passe de l'un à l'autre (Prompts).
## Il attend que Chloé soit libre de ses mouvements (après les premières scènes), ne s'ouvre qu'une
## fois par partie (drapeau « tuto_commandes ») et se rouvre depuis le menu (Commandes).
##
## Souris : « Suivant », « Précédent », « Passer ». Manette : ◀ ▶ ou LB / RB pour changer de page,
## A pour avancer, B pour passer. Clavier : ← →, Entrée, Échap.

const FLAG := &"tuto_commandes"
const LAYER := 85                 # over the HUD and the pause menus (80), under nothing
const PANEL_WIDTH := 840.0
const ICON_PX := 46.0
const ICONS_WIDTH := 250.0        # where the keys are drawn, left of each row's words
const WAIT_FREE_S := 1.5          # Chloé must have been free this long before it opens
const INK := Color(0.106, 0.122, 0.157, 0.97)
const AMBER := Color(0.79, 0.54, 0.16)
const GOLD := Color(1, 0.86, 0.5)
const CREAM := Color(1, 0.97, 0.9)

## What a row's icons are: an action's own key or button, or one of these groups.
const MOVE := &"@move"            # the four directions on a keyboard, the left stick on a pad
const MENUS := &"@menus"          # the arrows on a keyboard, the D-pad on a pad
const CLICK := &"@click"          # the mouse's left click: a keyboard-and-mouse row, hidden on a pad
## [title, [[words, [what is drawn…]], …]]
const PAGES := [
	["Se déplacer et agir", [
		["Se déplacer", [MOVE]],
		["Courir (en marchant)", [&"run"]],
		["Parler, ramasser, fouiller, lire", [&"interact"]],
		["Cliquer sur une personne ou un objet : y aller et l'utiliser", [CLICK]],
		["Revenir, fermer, refuser", [&"cancel"]],
	]],
	["Ton équipe et l'île", [
		["Ton équipe : dino de tête, baies, fiche", [&"team"]],
		["Le Dinodex", [&"dex"]],
		["La carte de l'île", [&"map"]],
		["Monter sur ton dino, descendre", [&"ride"]],
		["Voler sur un grand ptérosaure, se poser", [&"fly"]],
		["Le menu et les réglages", [&"menu"]],
	]],
	["Dans les menus et au combat", [
		["Choisir", [MENUS]],
		["Valider", [&"interact"]],
		["Revenir en arrière", [&"cancel"]],
		["Changer d'onglet dans le Dinodex", [&"@pages"]],
		["Plein écran", [&"@fullscreen"]],
	]],
]

var _page := 0
var _was_paused := false
var _panel: PanelContainer
var _body: VBoxContainer
var _dots: HBoxContainer
var _previous: Button
var _next: Button
var _skip: Button


## Ouvre le tutoriel quand Chloé est libre — une seule fois par partie, sur ordinateur.
static func offer(world: Node) -> void:
	if not Screen.on_computer() or Game.flag(FLAG):
		return
	var waiter := ControlsTutorial.new()
	waiter.visible = false
	world.add_child(waiter)
	waiter._wait_until_free()


## Ouvre le tutoriel tout de suite (depuis le menu).
static func open(parent: Node) -> ControlsTutorial:
	var tutorial := ControlsTutorial.new()
	parent.get_tree().root.add_child(tutorial)
	return tutorial


## Attend Chloé libre (ni dialogue, ni scène, ni combat), puis s'ouvre.
func _wait_until_free() -> void:
	var free_for := 0.0
	while is_inside_tree() and not Game.flag(FLAG):
		await get_tree().process_frame
		var player := get_tree().get_first_node_in_group(&"player")
		var free: bool = player != null and player.call("can_move") and not get_tree().paused
		free_for = free_for + get_process_delta_time() if free else 0.0
		if free_for >= WAIT_FREE_S:
			reparent(get_tree().root)
			_open_now()
			return


func _ready() -> void:
	if not visible and get_parent() != get_tree().root:
		return   # (the waiter: it opens itself later)
	_open_now()


func _open_now() -> void:
	visible = true
	if _panel:
		return
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_build()
	Prompts.changed.connect(_show_page)
	_show_page()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.01, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	_panel.add_theme_stylebox_override(&"panel", SettingsMenu._box(INK, 22, 3, 26))
	center.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	_panel.add_child(column)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override(&"separation", 10)
	_body.custom_minimum_size = Vector2(0, 410)
	column.add_child(_body)
	_dots = HBoxContainer.new()
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots.add_theme_constant_override(&"separation", 10)
	column.add_child(_dots)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 12)
	column.add_child(buttons)
	_skip = _button("Passer", _finish)
	_previous = _button("◂ Précédent", _turn.bind(-1))
	_next = _button("Suivant ▸", _turn.bind(1))
	_skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for button in [_skip, _previous, _next]:
		buttons.add_child(button)


## La page courante : titre, lignes (touches + mots), pastilles, boutons.
func _show_page() -> void:
	if _body == null:
		return
	for child in _body.get_children():
		child.queue_free()
	var page: Array = PAGES[_page]
	_body.add_child(_label(page[0], 36, GOLD))
	_body.add_child(_label(_source_line(), 18, Color(CREAM, 0.7)))
	for row: Array in page[1]:
		if row[1] == [CLICK] and Prompts.family != Prompts.KEYBOARD:
			continue   # (a pad has no click)
		_body.add_child(_row(row[0], row[1]))
	for child in _dots.get_children():
		child.queue_free()
	for i in PAGES.size():
		_dots.add_child(_label("●" if i == _page else "○", 22, GOLD if i == _page else Color(CREAM, 0.45)))
	_previous.visible = _page > 0
	_next.text = "Suivant ▸" if _page < PAGES.size() - 1 else "C'est parti !"
	_skip.visible = _page < PAGES.size() - 1
	PadFocus.prepare(_panel, _next, 0 if not _next.visible else -1)
	if Prompts.navigating:
		_next.grab_focus.call_deferred()


## « Au clavier et à la souris » ou « À la manette » : ce que montrent les images.
func _source_line() -> String:
	if Prompts.family == Prompts.KEYBOARD:
		return "Au clavier et à la souris (la molette zoome la vue)"
	return "À la manette"


func _row(words: String, shown: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	var icons := HBoxContainer.new()
	icons.custom_minimum_size = Vector2(ICONS_WIDTH, ICON_PX)
	icons.add_theme_constant_override(&"separation", 6)
	for what: StringName in shown:
		if what == CLICK:
			icons.add_child(_label("Clic gauche", 20, GOLD))
			continue
		for texture in _textures(what):
			icons.add_child(_picture(texture))
	row.add_child(icons)
	row.add_child(_label(words, 22, CREAM))
	return row


## Les images d'une ligne : celles de la touche / du bouton, selon ce que le joueur tient.
func _textures(what: StringName) -> Array[Texture2D]:
	var found: Array[Texture2D] = []
	var pad := Prompts.family != Prompts.KEYBOARD
	match what:
		MOVE:
			if pad:
				found.append(Prompts.named("l_stick"))
			else:
				for action in [&"move_up", &"move_left", &"move_down", &"move_right"]:
					found.append(Prompts.texture(action))
		MENUS:
			if pad:
				found.append(Prompts.named("dpad"))
			else:
				for arrow in ["arrow_up", "arrow_down", "arrow_left", "arrow_right"]:
					found.append(Prompts.named(arrow))
		&"@pages":
			if pad:
				found.append(Prompts.named("lb" if Prompts.family == &"xbox" else "l1" if Prompts.family == &"ps5" else "l"))
				found.append(Prompts.named("rb" if Prompts.family == &"xbox" else "r1" if Prompts.family == &"ps5" else "r"))
			else:
				found.append(Prompts.named("page_up"))
				found.append(Prompts.named("page_down"))
		&"@fullscreen":
			if not pad:
				found.append(Prompts.named("f11"))
		_:
			found.append(Prompts.texture(what))
	return found.filter(func(t: Texture2D) -> bool: return t != null)


func _picture(texture: Texture2D) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return picture


func _turn(step: int) -> void:
	if step > 0 and _page == PAGES.size() - 1:
		_finish()
		return
	_page = clampi(_page + step, 0, PAGES.size() - 1)
	_show_page()


## Fermé (fini ou passé) : on ne le reproposera plus, et le jeu repart.
func _finish() -> void:
	if is_queued_for_deletion():
		return
	Game.set_flag(FLAG)
	get_tree().paused = _was_paused
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _panel == null:
		return
	var pad := event as InputEventJoypadButton
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()
	elif event.is_action_pressed(&"ui_left") or (pad and pad.pressed and pad.button_index == JOY_BUTTON_LEFT_SHOULDER):
		get_viewport().set_input_as_handled()
		_turn(-1)
	elif event.is_action_pressed(&"ui_right") or (pad and pad.pressed and pad.button_index == JOY_BUTTON_RIGHT_SHOULDER):
		get_viewport().set_input_as_handled()
		if _page < PAGES.size() - 1:
			_turn(1)


func _button(text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 60)
	button.add_theme_font_size_override(&"font_size", 22)
	button.add_theme_color_override(&"font_color", CREAM)
	button.add_theme_stylebox_override(&"normal", SettingsMenu._box(Color(0.2, 0.22, 0.27), 14, 2))
	button.add_theme_stylebox_override(&"hover", SettingsMenu._box(Color(0.26, 0.28, 0.34), 14, 2, 0, GOLD))
	button.add_theme_stylebox_override(&"pressed", SettingsMenu._box(Color(0.45, 0.29, 0.08), 14, 3, 0, GOLD))
	button.pressed.connect(on_press)
	return button


func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", colour)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label
