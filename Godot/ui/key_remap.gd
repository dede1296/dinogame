class_name KeyRemap
extends RefCounted
## Remapping of the keys and of the gamepad buttons (Commandes → Touches). Only what differs from
## the game's defaults is kept, in user://keybinds.json, and put back at each start (Input3D.setup,
## world.gd). A key or a button taken by another action goes to it: it gets the old one.

const PATH := "user://keybinds.json"
const UNBOUND := -1
## Reserved: it cancels a remap, so it cannot be given to an action.
const ESCAPE_KEY := KEY_ESCAPE
## [action, short name shown on the pad and in the list]
const ACTIONS := [
	[&"interact", "Parler"],
	[&"jump", "Sauter"],
	[&"run", "Courir"],
	[&"run_toggle", "Course (stick)"],
	[&"ride", "Monter"],
	[&"map", "Carte"],
	[&"dex", "Dinodex"],
	[&"menu", "Menu"],
	[&"cancel", "Revenir"],
]

## The events the game starts with, per action, taken the first time the controls are set up.
static var _defaults := {}


## The actions this build has (the 2.5D has no jump; the 3D one has them all).
static func actions() -> Array:
	return ACTIONS.filter(func(entry: Array) -> bool: return InputMap.has_action(entry[0]))


static func apply_saved() -> void:
	_remember_defaults()
	var saved := _read()
	for name in saved:
		_apply_entry(StringName(name), saved[name])


## Binds `event` (a key or a gamepad button) to `action`, and moves the old one of that kind to
## the action that had the new one.
static func bind(action: StringName, event: InputEvent) -> void:
	var is_key := event is InputEventKey
	var kind := "key" if is_key else "pad"
	var code := _code_of(event)
	var previous := current(action, kind)
	var saved := _read()
	_store(saved, action, kind, code)
	for entry in actions():
		var other: StringName = entry[0]
		if other != action and current(other, kind) == code:
			_store(saved, other, kind, previous)
	_write(saved)
	apply_saved()


static func reset() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	for action in _defaults:
		InputMap.action_erase_events(action)
		for event: InputEvent in _defaults[action]:
			InputMap.action_add_event(action, event)


## The key (or pad button) code the action has now, or UNBOUND.
static func current(action: StringName, kind: String) -> int:
	for event in InputMap.action_get_events(action):
		if kind == "key" and event is InputEventKey:
			return event.physical_keycode
		if kind == "pad" and event is InputEventJoypadButton:
			return event.button_index
	return UNBOUND


## The name the player reads: « Espace », « Bouton A »…
static func label(action: StringName, kind: String) -> String:
	var code := current(action, kind)
	if code == UNBOUND:
		return "—"
	if kind == "key":
		return OS.get_keycode_string(code)
	var pad := InputEventJoypadButton.new()
	pad.button_index = code as JoyButton
	return pad.as_text()


static func _remember_defaults() -> void:
	for entry in ACTIONS:
		var action: StringName = entry[0]
		if InputMap.has_action(action) and not _defaults.has(action):
			_defaults[action] = InputMap.action_get_events(action).duplicate()


static func _apply_entry(action: StringName, entry: Dictionary) -> void:
	if not InputMap.has_action(action):
		return
	if entry.has("key"):
		_replace(action, InputEventKey, _key_event(entry["key"]))
	if entry.has("pad"):
		_replace(action, InputEventJoypadButton, _pad_event(entry["pad"]))


static func _replace(action: StringName, type: Variant, event: InputEvent) -> void:
	for old in InputMap.action_get_events(action):
		if is_instance_of(old, type):
			InputMap.action_erase_event(action, old)
	if event:
		InputMap.action_add_event(action, event)


static func _key_event(code: int) -> InputEventKey:
	if code == UNBOUND:
		return null
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


static func _pad_event(button: int) -> InputEventJoypadButton:
	if button == UNBOUND:
		return null
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


static func _code_of(event: InputEvent) -> int:
	if event is InputEventKey:
		return event.physical_keycode
	return (event as InputEventJoypadButton).button_index


static func _store(saved: Dictionary, action: StringName, kind: String, code: int) -> void:
	var entry: Dictionary = saved.get(String(action), {})
	entry[kind] = code
	saved[String(action)] = entry


static func _read() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}


static func _write(saved: Dictionary) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Commandes : impossible d'écrire %s" % PATH)
		return
	file.store_string(JSON.stringify(saved, "\t"))
