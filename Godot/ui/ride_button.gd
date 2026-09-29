class_name RideButton
extends Button
## The round saddle button under the map one: Chloé climbs on her mount, or gets down
## (key R). Shown once Joss has made her saddle, outdoors only; lit while she rides.

const SIZE := 76.0
const TOP := 258.0   # under the map and Dinodex buttons (MapScreen, DexScreen.add_open_button)
const ICON := preload("res://assets/art/ui/selle.png")
const GOLD := Color(1, 0.86, 0.5)

var _riding := false


static func add(hud: CanvasLayer, on_pressed: Callable) -> RideButton:
	var button := RideButton.new()
	button.name = "RideButton"
	hud.add_child(button)
	button.pressed.connect(on_pressed)
	return button


func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE
	tooltip_text = "Monture (R)"
	visible = false
	var icon := TextureRect.new()
	icon.texture = ICON
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [SIDE_LEFT, SIDE_TOP]:
		icon.set_offset(side, 12.0)
	for side in [SIDE_RIGHT, SIDE_BOTTOM]:
		icon.set_offset(side, -12.0)
	add_child(icon)
	_style()
	_place()
	get_viewport().size_changed.connect(_place)


## Shown or not, lit while Chloé rides (restyled only when that changes).
func show_state(shown: bool, riding: bool) -> void:
	visible = shown
	if riding != _riding:
		_riding = riding
		_style()


func _style() -> void:
	for state in ["normal", "hover", "pressed"]:
		var bg := Color(0.45, 0.29, 0.08, 0.92) if _riding else Color(SettingsMenu.INK, 0.7 if state == "normal" else 0.9)
		add_theme_stylebox_override(state, SettingsMenu._box(bg, 38, 3 if _riding else 2, 0, GOLD if _riding else SettingsMenu.AMBER))


func _place() -> void:
	var inset := SafeArea.insets(get_viewport())
	var screen := get_viewport().get_visible_rect().size
	position = Vector2(screen.x - inset.x - SIZE, inset.y + TOP)
