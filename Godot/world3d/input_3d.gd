class_name Input3D
## Controls of the 3D version (PC). The input map of project.godot is the 2.5D game's (Space,
## Enter, E and the A button interact); the 3D world changes it at run time only, so the 2.5D
## version keeps its controls (Greg, 04/10, gamepad):
## - jump: Space, and the gamepad's A (it no longer interacts here);
## - interact and go on with the dialogues: E, Enter, and the gamepad's X;
## - run: Shift or B held, as in the 2.5D, or a press of the left stick (RUN_TOGGLE), which keeps
##   her running as long as she moves (Player3D.running).

const JUMP := &"jump"
const JUMP_PAD_BUTTON := JOY_BUTTON_A
const INTERACT_PAD_BUTTON := JOY_BUTTON_X
## A press of the left stick: run on, until she stops moving.
const RUN_TOGGLE := &"run_toggle"
## The gamepad's Start: the settings menu (the game's menu button does the same with the mouse).
const MENU := &"menu"
const MENU_PAD_BUTTON := JOY_BUTTON_START
const RUN_TOGGLE_PAD_BUTTON := JOY_BUTTON_LEFT_STICK


static func setup() -> void:
	_pad_action(JUMP, JUMP_PAD_BUTTON, KEY_SPACE)
	_pad_action(RUN_TOGGLE, RUN_TOGGLE_PAD_BUTTON)
	_pad_action(MENU, MENU_PAD_BUTTON, KEY_ESCAPE)   # the menu: Start, or Échap (its icon is gone from the HUD)
	for event in InputMap.action_get_events(&"interact"):
		var key := event as InputEventKey
		if key and key.physical_keycode == KEY_SPACE:
			InputMap.action_erase_event(&"interact", event)   # Space jumps now
		var pad := event as InputEventJoypadButton
		if pad and pad.button_index == JUMP_PAD_BUTTON:
			InputMap.action_erase_event(&"interact", event)   # A jumps now
	_add_pad_event(&"interact", INTERACT_PAD_BUTTON)
	KeyRemap.apply_saved()   # the player's own keys and buttons (Commandes → Touches), last


## Makes `action` (if the 2.5D has none) out of a gamepad button and, with `keycode`, a key.
static func _pad_action(action: StringName, button: JoyButton, keycode := KEY_NONE) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.5)
	if keycode != KEY_NONE:
		var key := InputEventKey.new()
		key.physical_keycode = keycode
		InputMap.action_add_event(action, key)
	_add_pad_event(action, button)


static func _add_pad_event(action: StringName, button: JoyButton) -> void:
	for event in InputMap.action_get_events(action):
		var pad := event as InputEventJoypadButton
		if pad and pad.button_index == button:
			return
	var new_pad := InputEventJoypadButton.new()
	new_pad.button_index = button
	InputMap.action_add_event(action, new_pad)
