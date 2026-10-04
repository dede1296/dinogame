class_name Input3D
## Controls of the 3D version (PC). The input map of project.godot is the 2.5D game's (Space,
## Enter, E and the A button interact); the 3D world changes it at run time only, so the 2.5D
## version keeps its controls:
## - Space jumps (no longer interacts); the gamepad's X jumps (A still interacts, B still runs);
## - E, Enter and A interact and advance the dialogues, as in the 2.5D.

const JUMP := &"jump"
const JUMP_PAD_BUTTON := JOY_BUTTON_X


static func setup() -> void:
	if not InputMap.has_action(JUMP):
		InputMap.add_action(JUMP, 0.5)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_SPACE
		InputMap.action_add_event(JUMP, key)
		var pad := InputEventJoypadButton.new()
		pad.button_index = JUMP_PAD_BUTTON
		InputMap.action_add_event(JUMP, pad)
	for event in InputMap.action_get_events(&"interact"):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_SPACE:
			InputMap.action_erase_event(&"interact", event)
