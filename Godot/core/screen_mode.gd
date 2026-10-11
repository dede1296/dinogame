extends Node
## The game window on a computer (autoload "Screen"): full screen or windowed, remembered
## between two launches. F11 or Alt + Entrée switches, at any time, even while the game is
## paused. On a phone the window is always the whole screen: everything here does nothing.
##
## The chosen mode lives in user://settings.cfg with the other player settings (Quality.pref),
## apart from the game save, so a new game keeps it.

signal changed

## Smaller than this, the interface no longer fits (the base view is 1280 × 720).
const MIN_SIZE := Vector2i(960, 540)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not on_computer():
		return
	get_window().min_size = MIN_SIZE
	if bool(Quality.pref("screen", "fullscreen", false)):
		set_fullscreen(true)


## A computer (Windows, Linux, macOS), where a window can be resized.
func on_computer() -> bool:
	return OS.has_feature("pc")


func is_fullscreen() -> bool:
	return get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]


func set_fullscreen(on: bool, remember := true) -> void:
	if not on_computer():
		return
	get_window().mode = Window.MODE_FULLSCREEN if on else Window.MODE_WINDOWED
	if remember:
		Quality.set_pref("screen", "fullscreen", on)
	changed.emit()


func toggle() -> void:
	set_fullscreen(not is_fullscreen())


func _input(event: InputEvent) -> void:
	if not on_computer():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var f11 := key.keycode == KEY_F11
	var alt_enter := key.alt_pressed and key.keycode in [KEY_ENTER, KEY_KP_ENTER]
	if f11 or alt_enter:
		toggle()
		get_viewport().set_input_as_handled()
