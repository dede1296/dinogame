class_name VolHelp
extends PanelContainer
## The help strip at the bottom of the screen while Chloé flies (Vol): how to steer, dive, land,
## with the real keys or the pad's buttons (Prompts: they change as soon as the player switches),
## or in words on a phone. Hidden on the ground, during a landing, in a pause. Put by Vol.install.

const BOTTOM := 22.0
const ICON_PX := 30.0
const INK := Color(0.07, 0.12, 0.2, 0.84)
const SKY := Color(0.62, 0.86, 1.0)
const CREAM := Color(1, 0.97, 0.9)
const FONT := 18
const PHONE := "Joystick : diriger · bouton du harnais : se poser"
## [what is drawn, words]: MOVE = the stick or the four movement keys.
const MOVE := &"@move"
const ROWS := [[MOVE, "Diriger"], [&"run", "Piquer"], [&"fly", "Se poser"]]
## « Se poser » also answers the interaction key (A, Espace: nothing to talk to up there).
const ALSO := {&"fly": &"interact"}

var world: Node
var _row: HBoxContainer


func _ready() -> void:
	name = "VolHelp"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = INK
	box.border_color = Color(SKY, 0.8)
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	add_theme_stylebox_override(&"panel", box)
	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override(&"separation", 10)
	add_child(_row)
	visible = false
	_fill()
	Prompts.changed.connect(_fill)
	get_viewport().size_changed.connect(_place)


func _process(_delta: float) -> void:
	var player: Player = world.get(&"player") if world else null
	var shown: bool = player != null and player.flight != null and player.flight.is_up() and not get_tree().paused
	if shown != visible:
		visible = shown
		_place.call_deferred()


## The strip's contents, for what the player holds now.
func _fill() -> void:
	for child in _row.get_children():
		child.queue_free()
	if not Screen.on_computer():
		_row.add_child(_words(PHONE))
		return
	for i in ROWS.size():
		if i > 0:
			_row.add_child(_words("·"))
		for texture in _textures(ROWS[i][0]):
			_row.add_child(_picture(texture))
		_row.add_child(_words(ROWS[i][1]))
	_place.call_deferred()


func _textures(what: StringName) -> Array[Texture2D]:
	var found: Array[Texture2D] = []
	if what == MOVE:
		if Prompts.family != Prompts.KEYBOARD:
			found.append(Prompts.named("l_stick"))
		else:
			for action in [&"move_up", &"move_left", &"move_down", &"move_right"]:
				found.append(Prompts.texture(action))
	else:
		found.append(Prompts.texture(what))
		if ALSO.has(what):
			found.append(Prompts.texture(ALSO[what]))
	return found.filter(func(t: Texture2D) -> bool: return t != null)


func _picture(texture: Texture2D) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture


func _words(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", FONT)
	label.add_theme_color_override(&"font_color", CREAM)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _place() -> void:
	reset_size()
	var inset := SafeArea.insets(get_viewport())
	var screen := get_viewport().get_visible_rect().size
	position = Vector2((screen.x - size.x) / 2.0, screen.y - inset.y - size.y - BOTTOM)
