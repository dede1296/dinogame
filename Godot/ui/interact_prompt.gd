class_name InteractPrompt
extends Control
## L'invite d'interaction, sur ordinateur : quand quelque chose peut être « utilisé » à portée de
## Chloé (parler, ramasser, fouiller, lire), une petite bulle avec la touche — ou le bouton de la
## manette branchée — flotte au-dessus. Elle montre ce que fera la touche et laquelle presser, là
## où il fallait deviner. C'est le même objet que celui qu'atteindrait la touche (Player.
## nearest_interactable). Sur téléphone, le bouton A à l'écran joue ce rôle : rien n'est affiché.

const ICON_PX := 56.0
const LIFT_M := 1.9          # au-dessus des pieds de la cible (m)
const BOB_PX := 4.0          # le va-et-vient, pour qu'on la voie
const BOB_HZ := 1.4
const FADE_PER_S := 9.0
const PLATE := Color(0.105882, 0.121569, 0.156863, 0.82)
const RIM := Color(0.98, 0.76, 0.35, 0.9)

var player: Player
var view: WorldView

var _plate: PanelContainer
var _icon: TextureRect
var _text: Label
var _target: Node2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = PLATE
	box.border_color = RIM
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.set_content_margin_all(6)
	_plate.add_theme_stylebox_override(&"panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	_plate.add_child(row)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)
	_text = Label.new()
	_text.add_theme_font_size_override(&"font_size", 22)
	_text.add_theme_color_override(&"font_color", Color(1, 0.97, 0.9))
	_text.visible = false
	row.add_child(_text)
	add_child(_plate)
	_plate.modulate.a = 0.0
	visible = Screen.on_computer()


func _process(delta: float) -> void:
	if not visible or player == null or view == null:
		return
	var found := player.nearest_interactable() if player.can_move() else null
	if found != _target:
		_target = found
		_refresh()
	var shown := _target != null
	_plate.modulate.a = move_toward(_plate.modulate.a, 1.0 if shown else 0.0, FADE_PER_S * delta)
	if not shown:
		return
	var feet := view.heights.to_3d(_target.global_position)
	var head := feet + Vector3(0.0, LIFT_M, 0.0)
	if view.camera.is_position_behind(head):
		_plate.modulate.a = 0.0
		return
	var at := view.camera.unproject_position(head)
	at.y -= absf(sin(Time.get_ticks_msec() / 1000.0 * TAU * BOB_HZ)) * BOB_PX
	_plate.position = at - _plate.size * Vector2(0.5, 1.0)


## L'image (ou, à défaut, le nom) de la touche pour « interact », selon ce que le joueur a touché.
func _refresh() -> void:
	var picture := Prompts.texture(&"interact")
	_icon.texture = picture
	_icon.visible = picture != null
	_text.text = Prompts.label(&"interact")
	_text.visible = picture == null
