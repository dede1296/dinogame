class_name DiveButton
extends Button
## The round dive button, where the saddle one is (nobody rides in the water): « Plonger »
## (bubbles going down) while Chloé swims over deep water marked for it (DiveSpot), « Remonter »
## (bubbles going up) under the water (Dive). Key R too. Hidden otherwise, and during a scene.
## Pressing « Plonger » without the mask or a grown diver says what is missing.

const SIZE := 76.0
const TOP := 258.0   # under the map and Dinodex buttons, in the saddle button's place (RideButton)
const DIVE := preload("res://world/dive.gd")
const CYAN := Color(0.62, 0.92, 1.0)
const DEEP := Color(0.04, 0.2, 0.3)
## Said once, the first time the button shows over deep water.
const HINT_FLAG := &"plongee_bouton_vu"
const HINT := "De l'eau profonde : touche le bouton aux bulles pour plonger."

var _mode := ""   # "", "down" (Plonger), "up" (Remonter)
var _icon: Control


func _ready() -> void:
	name = "DiveButton"
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE
	visible = false
	_icon = Control.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.draw.connect(_draw_icon)
	add_child(_icon)
	for state in ["normal", "hover", "pressed"]:
		add_theme_stylebox_override(state, SettingsMenu._box(Color(DEEP, 0.78 if state == "normal" else 0.95), 38, 2, 0, CYAN))
	pressed.connect(_on_pressed)
	_place()
	get_viewport().size_changed.connect(_place)


func _process(_delta: float) -> void:
	var mode := _wanted()
	if mode == _mode:
		return
	_mode = mode
	visible = mode != ""
	tooltip_text = "Plonger (R)" if mode == "down" else "Remonter (R)"
	_icon.queue_redraw()
	if mode == "down" and not Game.flag(HINT_FLAG) and DIVE.can_dive():
		Game.set_flag(HINT_FLAG)
		Toast.say(get_tree(), HINT, CYAN)


## What the button offers now ("" : nothing).
func _wanted() -> String:
	var w = get_tree().current_scene
	if w == null or w.get(&"player") == null or w.get(&"region") == null:
		return ""
	var player: Player = w.player
	if player.busy or Dialogue.active or get_tree().paused or w.get(&"_changing_zone"):
		return ""
	if DIVE.underwater(w.region):
		return "up"
	if player.is_swimming() and DIVE.spot_at(player) != null:
		return "down"
	return ""


func _on_pressed() -> void:
	if _mode == "up":
		DIVE.surface()
	elif _mode == "down":
		DIVE.plunge(DIVE.spot_at(get_tree().current_scene.get(&"player")))


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ride"):
		get_viewport().set_input_as_handled()
		_on_pressed()


## Bubbles, and an arrow down (dive) or up (back to the surface).
func _draw_icon() -> void:
	var c := size / 2.0
	Abilities.draw_icon(_icon, "bubbles", c + Vector2(-7, 2), 34.0, CYAN)
	var up := _mode == "up"
	var x := c.x + 15.0
	var y0 := c.y + (10.0 if up else -12.0)
	var y1 := c.y + (-12.0 if up else 10.0)
	_icon.draw_line(Vector2(x, y0), Vector2(x, y1), CYAN, 3.0, true)
	var tip := 6.0 * (-1.0 if up else 1.0)
	_icon.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, y1 - tip), Vector2(x + 6, y1 - tip), Vector2(x, y1 + tip * 0.4)]), CYAN)


func _place() -> void:
	var inset := SafeArea.insets(get_viewport())
	var screen := get_viewport().get_visible_rect().size
	position = Vector2(screen.x - inset.x - SIZE, inset.y + TOP)
