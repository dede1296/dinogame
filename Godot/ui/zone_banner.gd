class_name ZoneBanner
extends Control
## Entering a zone: its name slides in on the left, under the party bar, with a gold strip
## and a dark band fading to the right; the region's name in small capitals below it.
## Holds for a moment, then fades away.

const GOLD := Color(0.95, 0.76, 0.31)
const BAND := Color(0.08, 0.07, 0.05)
const SHOW_S := 3.2
const TOP := 112.0   # below the party bar
const SLIDE := 20.0

var _title: Label
var _sub: Label
var _band: TextureRect
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	_band = TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(BAND, 0.85))
	g.add_point(0.55, Color(BAND, 0.6))
	g.set_color(g.get_point_count() - 1, Color(BAND, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 64
	tex.height = 4
	_band.texture = tex
	_band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_band.stretch_mode = TextureRect.STRETCH_SCALE
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_band)
	var strip := ColorRect.new()
	strip.name = "Strip"
	strip.color = GOLD
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	var col := VBoxContainer.new()
	col.name = "Text"
	col.position = Vector2(16, 8)
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	_title.add_theme_constant_override("shadow_offset_y", 2)
	col.add_child(_title)
	_sub = Label.new()
	_sub.add_theme_font_size_override("font_size", 14)
	_sub.add_theme_color_override("font_color", Color(1, 0.97, 0.9, 0.72))
	var spaced := FontVariation.new()
	spaced.base_font = ThemeDB.fallback_font
	spaced.spacing_glyph = 2
	_sub.add_theme_font_override("font", spaced)
	col.add_child(_sub)


## Shows `title` (the zone) with `subtitle` (the region) in small capitals.
func show_zone(title: String, subtitle := "") -> void:
	_title.text = title
	_sub.text = subtitle.to_upper()
	_sub.visible = subtitle != ""
	var col: Control = get_node("Text")
	col.reset_size()
	var h := col.get_combined_minimum_size().y + 16.0
	var w := maxf(col.get_combined_minimum_size().x + 110.0, 320.0)
	size = Vector2(w, h)
	_band.size = size
	var strip: ColorRect = get_node("Strip")
	strip.size = Vector2(4, h)
	var inset := SafeArea.insets(get_viewport())
	var home := Vector2(inset.x, inset.y + TOP)
	if _tween and _tween.is_valid():
		_tween.kill()
	position = home - Vector2(SLIDE, 0)
	modulate.a = 0.0
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", home, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	_tween.chain().tween_interval(SHOW_S * 0.68)
	_tween.chain().tween_property(self, "modulate:a", 0.0, SHOW_S * 0.2)

