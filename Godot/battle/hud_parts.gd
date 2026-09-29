extends RefCounted
## The battle HUD's building blocks (BattleHud): one look for its panels and cards (a dark
## gradient under a thin golden edge, PANEL_SHADER), its round action buttons (a disc of their
## colour under a golden ring, DISC_SHADER; they glow when chosen), and the parts that draw
## themselves: health and experience bars (Gauge), a dino's round portrait (Portrait), the Lien's
## hearts (Hearts). Everything springs a little when pressed (bouncy).

const INK_TOP := Color(0.17, 0.155, 0.135, 0.93)
const INK_BOTTOM := Color(0.065, 0.07, 0.085, 0.93)
const GOLD := Color(0.93, 0.7, 0.3)
const CREAM := Color(1, 0.97, 0.9)
const MUTED := Color(1, 0.97, 0.9, 0.66)
## A round button's disc, as a share of its box (the rest: its glow).
const DISC_SHARE := 0.84
const CARD := Vector2(236, 78)
const PANEL_SHADER := """
shader_type canvas_item;
uniform vec2 rect_size = vec2(300.0, 100.0);
uniform float radius = 16.0;
uniform float border = 2.5;
uniform vec4 top : source_color = vec4(0.17, 0.155, 0.135, 0.93);
uniform vec4 bottom : source_color = vec4(0.065, 0.07, 0.085, 0.93);
uniform vec4 edge : source_color = vec4(0.93, 0.7, 0.3, 1.0);
uniform float lift = 0.0;
float box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
void fragment() {
	vec4 tint = COLOR;
	vec2 p = (UV - 0.5) * rect_size;
	float d = box(p, rect_size * 0.5 - 0.5, radius);
	float inside = 1.0 - smoothstep(-0.8, 0.8, d);
	vec4 fill = mix(top, bottom, UV.y);
	fill.rgb += 0.06 * (1.0 - smoothstep(0.0, 0.45, UV.y)) + lift * 0.05;
	float rim = smoothstep(-border - 0.8, -border + 0.8, d);
	vec3 edge_col = mix(edge.rgb * 1.2, edge.rgb * 0.72, UV.y) + lift * 0.3;
	vec4 col = mix(fill, vec4(edge_col, edge.a), rim);
	COLOR = vec4(col.rgb, col.a * inside) * tint;
}
"""
const DISC_SHADER := """
shader_type canvas_item;
uniform vec4 base : source_color = vec4(0.84, 0.36, 0.2, 1.0);
uniform vec4 rim : source_color = vec4(0.93, 0.7, 0.3, 1.0);
uniform float radius = 0.84;
uniform float rim_width = 0.075;
uniform float glow = 0.0;
uniform float pressed = 0.0;
uniform float dim = 0.0;
void fragment() {
	vec4 tint = COLOR;
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float aa = fwidth(r) * 1.2;
	float disc = 1.0 - smoothstep(radius - aa, radius + aa, r);
	float t = clamp(p.y / radius * 0.5 + 0.5, 0.0, 1.0);
	vec3 body = mix(base.rgb * 1.25 + 0.05, base.rgb * 0.5, t);
	body = mix(body, base.rgb * 0.42, pressed * 0.7);
	float gloss = 1.0 - smoothstep(0.0, 0.5, length((p - vec2(-0.16, -0.46) * radius) * vec2(1.0, 1.9)));
	body += vec3(0.2) * gloss * (1.0 - pressed);
	float inner = radius - rim_width;
	float on_rim = smoothstep(inner - aa, inner + aa, r);
	vec3 col = mix(body, mix(rim.rgb * 1.25, rim.rgb * 0.68, t), on_rim);
	col = mix(col, vec3(0.1, 0.06, 0.03), (1.0 - smoothstep(0.0, aa * 1.6, abs(r - inner))) * 0.55);
	col = mix(col, vec3(dot(col, vec3(0.3, 0.59, 0.11))) * 0.6, dim);
	float shadow = (1.0 - smoothstep(radius - 0.04, radius + 0.1, length(p - vec2(0.0, 0.06)))) * 0.4;
	float line = 1.0 - smoothstep(0.0, aa * 1.8, abs(r - radius - 0.055));
	float halo = glow * max(line, 0.55 * (1.0 - smoothstep(radius, 1.0, r)));
	vec4 outside = vec4(mix(rim.rgb * 1.3, vec3(1.0, 0.96, 0.8), line), halo);
	outside = halo > shadow ? outside : vec4(0.0, 0.0, 0.0, shadow);
	COLOR = mix(outside, vec4(col, 1.0), disc) * tint;
}
"""

## A panel in the HUD's look: a gradient from `top` to `bottom` under an `edge` line, rounded.
## `margin`: left, top, right, bottom.
static func frame(top: Color, bottom: Color, edge: Color, radius := 16.0, margin := Vector4(14, 10, 14, 10)) -> PanelContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _blank(margin))
	box.material = _panel_material(top, bottom, edge, radius)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.resized.connect(func() -> void: (box.material as ShaderMaterial).set_shader_parameter("rect_size", box.size))
	return box


## A card to tap in a list: the panel's look, a row for its content, a little bounce.
static func card_button(top: Color, bottom: Color, edge: Color, tap_id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD
	var style := _blank(Vector4.ZERO)
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(state, style)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var mat := _panel_material(top, bottom, edge, 14.0)
	b.material = mat
	b.resized.connect(func() -> void:
		mat.set_shader_parameter("rect_size", b.size)
		b.pivot_offset = b.size / 2.0)
	b.focus_entered.connect(func() -> void: mat.set_shader_parameter("lift", 1.0))
	b.focus_exited.connect(func() -> void: mat.set_shader_parameter("lift", 0.0))
	b.set_meta(&"tap_id", tap_id)
	bouncy(b)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.offset_top = 6
	row.offset_bottom = -6
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	b.set_meta(&"row", row)
	return b


## A rounded label: a type, a state, a hint.
static func pill(text: String, font_size: int, bg: Color, fg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(12)
	box.content_margin_left = 9
	box.content_margin_right = 9
	box.content_margin_top = 1
	box.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", box)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(label(text, font_size, fg))
	return p


## Pressed, it squashes a little; released, it springs back.
static func bouncy(b: Control) -> void:
	var squash := func(to: float) -> void:
		if b.has_meta(&"bounce") and (b.get_meta(&"bounce") as Tween).is_valid():
			(b.get_meta(&"bounce") as Tween).kill()
		var t := b.create_tween()
		if to < 1.0:
			t.tween_property(b, "scale", Vector2.ONE * to, 0.06)
		else:
			t.tween_property(b, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		b.set_meta(&"bounce", t)
	(b as BaseButton).button_down.connect(squash.bind(0.9))
	(b as BaseButton).button_up.connect(squash.bind(1.0))


## A round action button (RoundButton): its colour, picture (or a `glyph`), name, diameter; `tap_id`
## for BattleHud.tap().
static func round_button(colour: Color, icon: Texture2D, caption: String, diameter: float, tap_id: String, glyph := "") -> RoundButton:
	var b := RoundButton.new()
	b.setup(icon, caption, diameter, _blank(Vector4.ZERO), _disc_material(colour), glyph)
	b.set_meta(&"tap_id", tap_id)
	bouncy(b)
	return b


## A card that cannot be chosen stays readable, a little faded.
static func enable_card(card: Button, on: bool) -> void:
	card.disabled = not on
	card.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
	card.modulate = Color.WHITE if on else Color(0.78, 0.78, 0.78, 0.78)


## A title and, below it, a smaller line.
static func two_lines(title: String, detail: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(shrink_to_fit(label(title, 19, CREAM), 14))
	col.add_child(fitted(label(detail, 14, MUTED)))
	return col


## A label that shrinks with an ellipsis in a card too narrow for it.
static func fitted(l: Label) -> Label:
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(20, 0)
	return l


## A label whose text keeps to its width: its font gets smaller, down to `smallest`, then the
## ellipsis (a long name, « Parasaurolophus », in a card).
static func shrink_to_fit(l: Label, smallest: int) -> Label:
	var biggest := l.get_theme_font_size(&"font_size")
	l.resized.connect(func() -> void:
		var font := l.get_theme_font(&"font")
		var size := biggest
		while size > smallest and font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > l.size.x:
			size -= 1
		if l.get_theme_font_size(&"font_size") != size:
			l.add_theme_font_size_override("font_size", size))
	return fitted(l)


## A little round of a type's colour, on the left of a move's card.
static func gem(colour: Color) -> Control:
	var dot := Control.new()
	dot.custom_minimum_size = Vector2(14, 14)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.draw.connect(func() -> void:
		var c := dot.size / 2.0
		dot.draw_circle(c, 7.0, colour.lightened(0.15))
		dot.draw_arc(c, 7.0, 0.0, TAU, 24, GOLD, 1.5, true)
		dot.draw_circle(c + Vector2(-2, -2), 2.0, Color(1, 1, 1, 0.6)))
	return dot


## A label that lets taps through.
static func label(text: String, font_size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Takes the room left in a row.
static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static var _shaders := {}
static var _white: ImageTexture


static func _shader(code: String) -> Shader:
	if not _shaders.has(code):
		var s := Shader.new()
		s.code = code
		_shaders[code] = s
	return _shaders[code]


## A plain white stylebox (drawn by a shader) with content margins: left, top, right, bottom.
static func _blank(margin: Vector4) -> StyleBoxTexture:
	if _white == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	var s := StyleBoxTexture.new()
	s.texture = _white
	s.content_margin_left = margin.x
	s.content_margin_top = margin.y
	s.content_margin_right = margin.z
	s.content_margin_bottom = margin.w
	return s


static func _panel_material(top: Color, bottom: Color, edge: Color, radius: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(PANEL_SHADER)
	m.set_shader_parameter("top", top)
	m.set_shader_parameter("bottom", bottom)
	m.set_shader_parameter("edge", edge)
	m.set_shader_parameter("radius", radius)
	return m


static func _disc_material(colour: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(DISC_SHADER)
	m.set_shader_parameter("base", colour)
	m.set_shader_parameter("rim", GOLD)
	m.set_shader_parameter("radius", DISC_SHARE)
	return m


# ------------------------------------------------------------------ drawn parts

## A bar that draws itself: rounded, glassy. "hp" goes from green to amber to red as it empties.
class Gauge extends Control:
	var kind := "hp"
	var max_value := 1.0:
		set(v):
			max_value = maxf(v, 1.0)
			queue_redraw()
	var value := 0.0:
		set(v):
			value = v
			queue_redraw()
	var _box := StyleBoxFlat.new()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_box.anti_aliasing = true

	func colour(k: float) -> Color:
		match kind:
			"xp":
				return Color(0.45, 0.75, 1.0)
			"calm":
				return Color(0.98, 0.84, 0.45)
		var green := Color(0.38, 0.82, 0.36)
		var amber := Color(0.97, 0.76, 0.22)
		var red := Color(0.92, 0.3, 0.25)
		if k > 0.35:
			return amber.lerp(green, smoothstep(0.4, 0.6, k))
		return red.lerp(amber, smoothstep(0.15, 0.3, k))

	func _draw() -> void:
		var h := size.y
		_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55), h / 2.0)
		var k := clampf(value / max_value, 0.0, 1.0)
		if k <= 0.0:
			return
		var fill := Rect2(Vector2.ZERO, Vector2(maxf(size.x * k, h), h))
		_rect(fill, colour(k), h / 2.0)
		if h >= 8.0:   # a glassy light along its top
			_rect(Rect2(Vector2(h * 0.4, h * 0.14), Vector2(maxf(fill.size.x - h * 0.8, 0.0), h * 0.3)), Color(1, 1, 1, 0.3), h * 0.15)

	func _rect(r: Rect2, c: Color, radius: float) -> void:
		_box.bg_color = c
		_box.set_corner_radius_all(int(radius))
		draw_style_box(_box, r)


## A dino's round portrait on its type's colour, a golden ring, its level on a badge.
class Portrait extends Control:
	var dino: Dino
	var small := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if dino == null:
			return
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		var type_colour: Color = MovesDB.TYPE_COLORS.get(dino.type(), Color.WHITE)
		draw_circle(c + Vector2(0, 2), r, Color(0, 0, 0, 0.35))
		draw_circle(c, r, type_colour.darkened(0.4))
		draw_circle(c, r - 3.0, type_colour.lerp(Color.WHITE, 0.5))
		var inner := r - 4.0
		draw_texture_rect(PartyBar.portrait(dino.species()), Rect2(c - Vector2(inner, inner), Vector2(inner, inner) * 2.0), false)
		draw_arc(c, r - 1.5, 0.0, TAU, 48, Color(0.93, 0.7, 0.3), 3.0, true)
		if small:
			return
		var b := c + Vector2(r, r) * 0.74
		draw_circle(b, 14.0, Color(0.106, 0.122, 0.157))
		draw_arc(b, 14.0, 0.0, TAU, 24, Color(0.93, 0.7, 0.3), 1.5, true)
		var font := get_theme_default_font()
		var text := str(dino.level)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(font, b + Vector2(-w / 2.0, 5.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.97, 0.9))


## The Lien: Dino.MAX_BOND hearts, the first `bond` full (DinoCard.draw_heart).
class Hearts extends Control:
	const HEART := 16.0
	var bond := 0:
		set(v):
			bond = v
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(Dino.MAX_BOND * (HEART + 3.0), HEART)

	func _draw() -> void:
		for i in Dino.MAX_BOND:
			DinoCard.draw_heart(self, Vector2(HEART / 2.0 + i * (HEART + 3.0), size.y / 2.0), HEART, i < bond)


## A round action button: a disc of its colour under a golden ring (DISC_SHADER), its picture,
## its name on a little label across its lower edge, maybe a count on a badge. It glows when it
## has the focus, or softly (`pulse`) to be noticed.
class RoundButton extends Button:
	var diameter := 78.0
	var pulse := false
	var badge := -1:
		set(v):
			badge = v
			if _badge:
				_badge.queue_redraw()
	var _disc: ShaderMaterial
	var _icon: Control
	var _caption: Control
	var _badge: Control
	var _glow := -1.0
	var _t := 0.0
	var _pulsed := false

	func setup(picture: Texture2D, caption: String, d: float, blank: StyleBox, disc: ShaderMaterial, glyph: String) -> void:
		diameter = d
		var box := Vector2.ONE * roundf(d / 0.84)   # (DISC_SHARE: room for its glow)
		custom_minimum_size = box
		size = box
		pivot_offset = box / 2.0
		for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(state, blank)
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		_disc = disc
		material = disc
		if picture:
			var pic := TextureRect.new()
			pic.texture = picture
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var s := d * (0.66 if d > 100.0 else 0.76)
			pic.size = Vector2(s, s)
			pic.position = box / 2.0 - Vector2(s / 2.0, s * (0.58 if d > 100.0 else 0.56))
			_icon = pic
		else:
			var l := Label.new()
			l.text = glyph
			l.add_theme_font_size_override("font_size", int(d * 0.36))
			l.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.size = Vector2(d, d * 0.8)
			l.position = box / 2.0 - Vector2(d / 2.0, d * 0.45)
			_icon = l
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icon)
		var tag := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.09, 0.085, 0.08, 0.92)
		style.border_color = Color(0.93, 0.7, 0.3)
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 0
		style.content_margin_bottom = 1
		tag.add_theme_stylebox_override("panel", style)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var word := Label.new()
		word.text = caption
		word.add_theme_font_size_override("font_size", 18 if d > 100.0 else 15)
		word.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
		tag.add_child(word)
		add_child(tag)
		tag.reset_size()
		tag.position = Vector2(box.x / 2.0 - tag.size.x / 2.0, box.y / 2.0 + d / 2.0 - tag.size.y * 0.7)
		_caption = tag
		_badge = Control.new()
		_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_badge.size = Vector2(30, 30)
		_badge.position = box / 2.0 + Vector2(d, -d) * 0.4 - Vector2(15, 15)
		_badge.draw.connect(_draw_badge)
		add_child(_badge)
		focus_mode = Control.FOCUS_ALL
		button_down.connect(func() -> void: _disc.set_shader_parameter("pressed", 1.0))
		button_up.connect(func() -> void: _disc.set_shader_parameter("pressed", 0.0))

	func enable(on: bool) -> void:
		disabled = not on
		focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
		_disc.set_shader_parameter("dim", 0.0 if on else 1.0)
		_icon.modulate = Color(1, 1, 1, 1.0 if on else 0.4)
		_caption.modulate = Color(1, 1, 1, 1.0 if on else 0.55)

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		var g := 0.0
		if has_focus():
			g = 0.95
		elif pulse:
			g = 0.45 + 0.55 * (0.5 + 0.5 * sin(_t * 3.2))
		var springing := has_meta(&"bounce") and (get_meta(&"bounce") as Tween).is_running()
		if pulse and not springing:   # (its spring, when pressed, comes first)
			scale = Vector2.ONE * (1.0 + 0.045 * (0.5 + 0.5 * sin(_t * 3.2)))
			_pulsed = true
		elif _pulsed and not pulse:
			_pulsed = false
			scale = Vector2.ONE
		if not is_equal_approx(g, _glow):
			_glow = g
			_disc.set_shader_parameter("glow", g)

	## Taps land on the disc and its label, not on the corners of its box.
	func _has_point(point: Vector2) -> bool:
		return point.distance_to(size / 2.0) <= diameter / 2.0 + 6.0 or Rect2(_caption.position, _caption.size).has_point(point)

	func _draw_badge() -> void:
		if badge < 0:
			return
		var c := _badge.size / 2.0
		_badge.draw_circle(c, 13.0, Color(0.106, 0.122, 0.157))
		_badge.draw_arc(c, 13.0, 0.0, TAU, 24, Color(0.93, 0.7, 0.3), 2.0, true)
		var font := _badge.get_theme_default_font()
		var count := str(badge)
		var w := font.get_string_size(count, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		_badge.draw_string(font, c + Vector2(-w / 2.0, 5.5), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.97, 0.9))
