extends Control
## The PC game's first screen: the 3D version — go on with its save, or a new game. It is the main
## scene of the PC build (project.godot run/main_scene.pc) and of the editor's runs (F5).
## Command line: `-- --3d` goes straight into the 3D version.

const ZONE_3D := "res://world3d/zone3d/zone_3d.tscn"
const INK := Color(0.105882, 0.121569, 0.156863)
const GOLD := Color(0.98, 0.76, 0.35)
const CREAM := Color(0.97, 0.94, 0.87)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--3d" in args:
		_continue_3d.call_deferred()
		return
	_build()


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override(&"separation", 14)
	add_child(column)
	column.add_child(_label("Ambrelune", 46, GOLD))
	column.add_child(_spacer(10))
	var has_save := FileAccess.file_exists(Session3D.SAVE_PATH)
	var first: Button = null
	if has_save:
		first = _button(column, "Continuer", _continue_3d)
	var fresh := _button(column, "Nouvelle partie", _new_3d)
	if first == null:
		first = fresh
	first.grab_focus()


func _continue_3d() -> void:
	_go(ZONE_3D)


## A new game of the 3D version (its save, user://save_3d.json, is written over at the next save).
func _new_3d() -> void:
	Game.new_game()
	Game.give_starter(Session3D.STARTER)
	Game.set_flag(&"prologue_done")
	_go(ZONE_3D)


func _go(path: String) -> void:
	Router.go_to(path)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	return l


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(420, 56)
	b.add_theme_font_size_override(&"font_size", 21)
	b.add_theme_color_override(&"font_color", CREAM)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.45, 0.29, 0.08) if state == "pressed" else Color(0.14, 0.16, 0.2, 0.96)
		sb.border_color = GOLD if state in ["focus", "hover"] else Color(0.79, 0.54, 0.16)
		sb.set_border_width_all(2)
		sb.border_width_left = 5
		sb.set_corner_radius_all(10)
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(action)
	parent.add_child(b)
	return b
