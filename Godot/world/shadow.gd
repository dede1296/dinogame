class_name Shadow
## Soft oval contact shadow under characters and objects (a radial gradient, no image file).

const BASE_PX := 64.0
const FLATTEN := 0.38
static var _texture: GradientTexture2D


static func texture() -> GradientTexture2D:
	if _texture == null:
		var g := Gradient.new()
		g.set_color(0, Color(0.08, 0.06, 0.03, 0.42))
		g.set_color(1, Color(0.08, 0.06, 0.03, 0.0))
		g.add_point(0.55, Color(0.08, 0.06, 0.03, 0.3))
		_texture = GradientTexture2D.new()
		_texture.gradient = g
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
		_texture.width = int(BASE_PX)
		_texture.height = int(BASE_PX)
	return _texture


## Adds a shadow as the first child of `parent` (drawn below its sprite).
static func make(parent: Node2D, width := 48.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture()
	s.name = "Shadow"
	parent.add_child(s)
	parent.move_child(s, 0)
	fit(s, width)
	return s


static func fit(s: Sprite2D, width: float) -> void:
	s.visible = width > 0.0
	s.scale = Vector2(width / BASE_PX, width * FLATTEN / BASE_PX)
