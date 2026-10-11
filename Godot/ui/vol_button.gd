class_name VolButton
extends Button
## The round harness button, under the saddle's (Vol, chapter 7): « Voler » on the ground, lit
## « Se poser » in the air. The key « fly » (F, the pad's X) does the same. Shown once Chloé has
## Joss's harness and the leave to fly (Vol.available), outdoors, when no scene plays; pressed
## without a grown pterosaur, it says why (Vol.take_off). Put on the HUD by Vol.install.

const SIZE := 76.0
const STACK := 4   # under the menu, the map, the Dinodex and the saddle's (HudHint.stack_y)
const ICON := "res://assets/art/ui/harnais_vol.png"
const SKY := Color(0.62, 0.86, 1.0)
const DEEP := Color(0.07, 0.16, 0.3)
const LIT := Color(0.16, 0.36, 0.62, 0.94)

var world: Node
var _flying := false
var _icon: Control


func _ready() -> void:
	name = "VolButton"
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE
	HudHint.fit(self)
	visible = false
	if not Screen.on_computer():
		tooltip_text = "Voler (F)"
	_add_icon()
	_style()
	pressed.connect(_on_pressed)
	_place()
	get_viewport().size_changed.connect(_place)


## Joss's harness when drawn (assets/art/ui/harnais_vol.png), else a wing drawn here.
func _add_icon() -> void:
	if ResourceLoader.exists(ICON):
		var picture := TextureRect.new()
		picture.texture = load(ICON)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon = picture
	else:
		_icon = Control.new()
		_icon.draw.connect(func() -> void: Abilities.draw_icon(_icon, "wing", _icon.size / 2.0, 40.0, SKY))
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [SIDE_LEFT, SIDE_TOP]:
		_icon.set_offset(side, 12.0)
	for side in [SIDE_RIGHT, SIDE_BOTTOM]:
		_icon.set_offset(side, -12.0)
	add_child(_icon)


func _process(_delta: float) -> void:
	var player: Player = world.get(&"player") if world else null
	visible = _shown(player)
	var now := player != null and player.flight != null
	if now != _flying:
		_flying = now
		_style()


## Is she flying (the button lit, « Se poser »)?
func flying() -> bool:
	return _flying


func _shown(player: Player) -> bool:
	if player == null or not Vol.available():
		return false
	if player.flight:
		return player.flight.is_up() and not get_tree().paused
	return Vol.take_off_problem(world) in ["", "none", "too_small", "young", "swimming", "forbidden"]


func _on_pressed() -> void:
	if world:
		Vol.toggle(world)


## The key works as soon as the story gave her the Vol (so that a refusal says why: the harness
## left behind…), not only when the button shows.
func _unhandled_input(event: InputEvent) -> void:
	if world and Game.flag(Vol.FLAG) and event.is_action_pressed(Vol.ACTION):
		get_viewport().set_input_as_handled()
		Vol.toggle(world)


func _style() -> void:
	for state in ["normal", "hover", "pressed"]:
		var bg := LIT if _flying else Color(DEEP, 0.78 if state == "normal" else 0.95)
		add_theme_stylebox_override(state, SettingsMenu._box(bg, 38, 3 if _flying else 2, 0, SKY))


func _place() -> void:
	var inset := SafeArea.insets(get_viewport())
	var screen := get_viewport().get_visible_rect().size
	position = Vector2(screen.x - inset.x - SIZE * HudHint.scale_pc(), inset.y + HudHint.stack_y(STACK))
