extends Node
## Les icônes de touches et de manette (autoload « Prompts »). `Prompts.texture(&"interact")` donne
## l'image de ce qui déclenche l'action : la touche du clavier, ou le bouton de la manette de la
## famille branchée (Xbox, PlayStation, Switch), selon ce que le joueur a touché en dernier. Elle
## suit les touches redéfinies (Commandes → Touches : on lit l'InputMap) et la disposition du
## clavier (un AZERTY voit « Z » là où un QWERTY voit « W »).
##
## Les images : assets/art/ui/prompts/ (Kenney « Input Prompts », CC0). `changed` part quand le
## joueur passe du clavier à la manette ou inversement : les invites se redessinent.

signal changed

const FOLDER := "res://assets/art/ui/prompts/%s/%s.png"
const KEYBOARD := &"key"
## Les touches dont le nom de Godot n'est pas celui du fichier.
const KEY_FILES := {
	"escape": "esc", "space": "space", "enter": "enter", "kp enter": "enter", "shift": "shift",
	"ctrl": "ctrl", "alt": "alt", "tab": "tab", "backspace": "backspace", "capslock": "caps_lock",
	"left": "arrow_left", "right": "arrow_right", "up": "arrow_up", "down": "arrow_down",
	"delete": "del", "pageup": "page_up", "pagedown": "page_down", "minus": "minus", "equal": "equals",
	"comma": "comma", "period": "period", "slash": "slash", "semicolon": "semicolon",
	"apostrophe": "apostrophe", "bracketleft": "bracket_left", "bracketright": "bracket_right",
	"quoteleft": "backtick", "printscreen": "print_screen", "numlock": "num_lock",
}
## Bouton de manette (JoyButton) → fichier, par famille.
const PAD_FILES := {
	&"xbox": {
		JOY_BUTTON_A: "a", JOY_BUTTON_B: "b", JOY_BUTTON_X: "x", JOY_BUTTON_Y: "y",
		JOY_BUTTON_BACK: "view", JOY_BUTTON_START: "menu",
		JOY_BUTTON_LEFT_STICK: "l_stick_click", JOY_BUTTON_RIGHT_STICK: "r_stick_click",
		JOY_BUTTON_LEFT_SHOULDER: "lb", JOY_BUTTON_RIGHT_SHOULDER: "rb",
		JOY_BUTTON_DPAD_UP: "dpad_up", JOY_BUTTON_DPAD_DOWN: "dpad_down",
		JOY_BUTTON_DPAD_LEFT: "dpad_left", JOY_BUTTON_DPAD_RIGHT: "dpad_right",
	},
	&"ps5": {
		JOY_BUTTON_A: "cross", JOY_BUTTON_B: "circle", JOY_BUTTON_X: "square", JOY_BUTTON_Y: "triangle",
		JOY_BUTTON_BACK: "share", JOY_BUTTON_START: "options",
		JOY_BUTTON_LEFT_STICK: "l_stick_click", JOY_BUTTON_RIGHT_STICK: "r_stick_click",
		JOY_BUTTON_LEFT_SHOULDER: "l1", JOY_BUTTON_RIGHT_SHOULDER: "r1",
		JOY_BUTTON_DPAD_UP: "dpad_up", JOY_BUTTON_DPAD_DOWN: "dpad_down",
		JOY_BUTTON_DPAD_LEFT: "dpad_left", JOY_BUTTON_DPAD_RIGHT: "dpad_right",
	},
	&"switch": {
		# (Nintendo : A à droite et B en bas, l'inverse d'une Xbox — Godot nomme par position.)
		JOY_BUTTON_A: "b", JOY_BUTTON_B: "a", JOY_BUTTON_X: "y", JOY_BUTTON_Y: "x",
		JOY_BUTTON_BACK: "minus", JOY_BUTTON_START: "plus",
		JOY_BUTTON_LEFT_STICK: "l_stick", JOY_BUTTON_RIGHT_STICK: "r_stick",
		JOY_BUTTON_LEFT_SHOULDER: "l", JOY_BUTTON_RIGHT_SHOULDER: "r",
		JOY_BUTTON_DPAD_UP: "dpad_up", JOY_BUTTON_DPAD_DOWN: "dpad_down",
		JOY_BUTTON_DPAD_LEFT: "dpad_left", JOY_BUTTON_DPAD_RIGHT: "dpad_right",
	},
}

## Ce que le joueur a touché en dernier : le clavier (&"key"), ou la famille de sa manette.
var family: StringName = KEYBOARD
## Vrai tant que le dernier geste est une touche ou la manette (pas la souris) : les écrans mettent
## alors un contour doré sur le bouton choisi, et un premier focus (PadFocus).
var navigating := false
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_pad_for_menus()
	if Input.get_connected_joypads().is_empty():
		return
	# Une manette branchée au lancement et pas de clavier touché : elle est sans doute la manette.
	if DisplayServer.is_touchscreen_available():
		family = pad_family(Input.get_connected_joypads()[0])


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length() > 1.0):
		navigating = false
	elif event is InputEventKey or event is InputEventJoypadButton or 			(event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		navigating = true
	var now := family
	if event is InputEventKey or event is InputEventMouseButton:
		now = KEYBOARD
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		now = pad_family(event.device)
	if now != family:
		family = now
		changed.emit()


## Les menus de Godot (ui_accept, ui_cancel : un bouton pressé, un écran qu'on quitte) n'ont ici
## AUCUN bouton de manette — la croix navigue, mais A ne valide pas et B ne ferme pas. On les
## ajoute : A valide, B revient (tous les écrans du jeu qui utilisent le focus s'y fient).
static func ensure_pad_for_menus() -> void:
	for pair: Array in [[&"ui_accept", JOY_BUTTON_A], [&"ui_cancel", JOY_BUTTON_B]]:
		var action: StringName = pair[0]
		if not InputMap.has_action(action):
			continue
		var has_pad := InputMap.action_get_events(action).any(func(e: InputEvent) -> bool: return e is InputEventJoypadButton)
		if has_pad:
			continue
		var event := InputEventJoypadButton.new()
		event.button_index = pair[1]
		InputMap.action_add_event(action, event)


## La famille d'une manette d'après le nom que Godot lui lit.
static func pad_family(device: int) -> StringName:
	return pad_family_of_name(Input.get_joy_name(device))


## La même chose, depuis le nom (testable sans manette branchée).
static func pad_family_of_name(joy_name: String) -> StringName:
	joy_name = joy_name.to_lower()
	for word in ["playstation", "ps5", "ps4", "dualsense", "dualshock", "sony"]:
		if word in joy_name:
			return &"ps5"
	for word in ["nintendo", "switch", "pro controller", "joy-con"]:
		if word in joy_name:
			return &"switch"
	return &"xbox"


## L'image de l'action : la touche du clavier ou le bouton de la manette, selon `kind`
## ("" : ce que le joueur a touché en dernier ; "key" ; "pad"). Vide si on n'a pas d'image.
func texture(action: StringName, kind := "") -> Texture2D:
	var wants_pad := (kind == "pad") or (kind == "" and family != KEYBOARD)
	var pad := family if family != KEYBOARD else pad_family(_first_pad())
	var path := _pad_path(action, pad) if wants_pad else _key_path(action)
	if path == "":
		return null
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


## Le nom de la touche ou du bouton, pour un texte (« E », « Maj »…), quand l'image manque.
func label(action: StringName, kind := "") -> String:
	var wants_pad := (kind == "pad") or (kind == "" and family != KEYBOARD)
	for event in InputMap.action_get_events(action):
		if wants_pad and event is InputEventJoypadButton:
			return event.as_text()
		if not wants_pad and event is InputEventKey:
			return OS.get_keycode_string(_label_keycode(event))
	return ""


## L'icône de la touche : parmi celles de l'action, une lettre de préférence (« E » parle mieux
## qu'« Espace » à qui joue au clavier), sinon la première.
func _key_path(action: StringName) -> String:
	var keys: Array[InputEventKey] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append(event)
	if keys.is_empty():
		return ""
	var pick := keys[0]
	for event in keys:
		if OS.get_keycode_string(_label_keycode(event)).length() == 1:
			pick = event
			break
	var key := OS.get_keycode_string(_label_keycode(pick)).to_lower()
	return FOLDER % [KEYBOARD, KEY_FILES.get(key, key)]


func _pad_path(action: StringName, pad: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			var file: String = PAD_FILES[pad].get(event.button_index, "")
			return FOLDER % [pad, file] if file != "" else ""
	return ""


## Le code de la touche telle qu'elle est écrite sur SON clavier (AZERTY, QWERTY…).
func _label_keycode(event: InputEventKey) -> Key:
	if event.physical_keycode != KEY_NONE:
		var shown := DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
		return shown if shown != KEY_NONE else event.physical_keycode
	return event.keycode


func _first_pad() -> int:
	var pads := Input.get_connected_joypads()
	return pads[0] if not pads.is_empty() else 0
