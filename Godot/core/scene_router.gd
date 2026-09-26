extends CanvasLayer
## Scene changes with a transition drawn above everything (fade to a colour).
## Later: the battle transition (swirl/flash) goes here too.

signal changed(scene: Node)

var _curtain: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_curtain = ColorRect.new()
	_curtain.color = Color(0.06, 0.05, 0.04, 0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_curtain)


func is_busy() -> bool:
	return _busy


## Fades out, swaps the current scene for `path`, fades back in.
func go_to(path: String, fade := 0.35) -> void:
	if _busy:
		return
	_busy = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	await fade_out(fade)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		# The scene did not change: scene_changed will never come, so don't wait for it.
		push_error("Scène introuvable : %s (%s)" % [path, error_string(err)])
		await fade_in(fade)
		_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_busy = false
		return
	await get_tree().scene_changed
	changed.emit(get_tree().current_scene)
	await fade_in(fade)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


## Entering a battle: three white flashes, then black. Call fade_in() once the battle is shown.
func battle_flash() -> void:
	_busy = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	for i in 3:
		t.tween_callback(func() -> void: _curtain.color = Color(1, 1, 1, 0))
		t.tween_property(_curtain, "color:a", 0.85, 0.07)
		t.tween_property(_curtain, "color:a", 0.0, 0.09)
	t.tween_callback(func() -> void: _curtain.color = Color(0.06, 0.05, 0.04, 0))
	t.tween_property(_curtain, "color:a", 1.0, 0.3)
	await t.finished


func end_transition(time := 0.3) -> void:
	await fade_in(time)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func fade_out(time: float, color := Color(0.06, 0.05, 0.04)) -> void:
	_curtain.color = Color(color, _curtain.color.a)
	await create_tween().tween_property(_curtain, "color:a", 1.0, time).finished


func fade_in(time: float) -> void:
	await create_tween().tween_property(_curtain, "color:a", 0.0, time).finished
