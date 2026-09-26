extends CanvasLayer
## Performance readout for the Phaser/Godot comparison (autoload "Debug").
## F3 on desktop, or a three-finger tap on a phone, shows/hides it.
## Tracks the worst frame of the last second: stutters show there, not in the FPS.

const REFRESH_S := 0.5

var _label: Label
var _elapsed := 0.0
var _worst_ms := 0.0
var _frames := 0
var _touches := {}


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(10, 8)
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(1, 1, 0.85))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 5)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = true   # prototype: always on, for the comparison


func _process(delta: float) -> void:
	_frames += 1
	_elapsed += delta
	_worst_ms = maxf(_worst_ms, delta * 1000.0)
	if _elapsed < REFRESH_S or not visible:
		return
	var fps := _frames / _elapsed
	_label.text = "%d FPS · pire image %.1f ms · %d draw calls · %d objets\nMém. %.0f Mo · audio : latence %.0f ms · %s · %s" % [
		roundi(fps), _worst_ms,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		AudioServer.get_output_latency() * 1000.0,
		RenderingServer.get_current_rendering_method(),
		OS.get_name(),
	]
	_elapsed = 0.0
	_frames = 0
	_worst_ms = 0.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_debug"):
		visible = not visible
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = true
			if _touches.size() >= 3:
				visible = not visible
				_touches.clear()
		else:
			_touches.erase(event.index)
