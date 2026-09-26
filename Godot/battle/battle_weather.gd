class_name BattleWeather
extends Control
## The battle happens under the same sky as the exploration: the backdrop and the fighters
## take the light of the hour (dawn, dusk, night) and of the weather; rain falls in front of
## the scene, mist veils its far part. Sits above the fighters, below the battle panels.

## Light of the hour: [hour, colour], blended between neighbours.
const DAYLIGHT := [
	[0.0, Color(0.42, 0.47, 0.72)], [4.5, Color(0.42, 0.47, 0.72)], [6.0, Color(0.95, 0.8, 0.78)],
	[8.0, Color(1, 1, 1)], [17.0, Color(1, 1, 1)], [19.0, Color(1.0, 0.8, 0.64)],
	[20.8, Color(0.46, 0.5, 0.76)], [24.0, Color(0.42, 0.47, 0.72)],
]
## The fighters are lit a little more than the backdrop, so they stay easy to read.
const FIGHTER_LIFT := 0.35
const RAIN_DROPS := 110
const RAIN := Color(0.85, 0.9, 1.0, 0.2)
## A storm: more rain, and lightning flashes over the scene every so often (s).
const STORM_RAIN := 1.8
const LIGHTNING_EVERY := Vector2(5.0, 12.0)
const THUNDER: Array[AudioStream] = [preload("res://assets/audio/ambience/tonnerre-1.mp3"), preload("res://assets/audio/ambience/tonnerre-2.mp3")]

var _flash: ColorRect
var _next_lightning := 3.0


## Adds the weather over `world` (the fighters) and tints `backdrop` and `world` for the hour.
static func apply(parent: Control, backdrop: CanvasItem, world: CanvasItem) -> BattleWeather:
	var layer := BattleWeather.new()
	parent.add_child(layer)
	parent.move_child(layer, world.get_index() + 1)
	var light := tint(Game.clock / 60.0, Game.weather)
	backdrop.modulate = light
	world.modulate = light.lerp(Color.WHITE, FIGHTER_LIFT)
	return layer


## Colour of the light at `hour` in `weather` (white = plain daylight).
static func tint(hour: float, weather: StringName) -> Color:
	var c: Color = DAYLIGHT[0][1]
	for i in DAYLIGHT.size() - 1:
		var a: Array = DAYLIGHT[i]
		var b: Array = DAYLIGHT[i + 1]
		if hour <= b[0]:
			c = (a[1] as Color).lerp(b[1], smoothstep(a[0], b[0], hour))
			break
	if weather == &"storm":
		c = c.lerp(Color(0.5, 0.54, 0.62) * c.get_luminance(), 0.55) * 0.75
	elif weather == &"rain":
		c = c.lerp(Color(0.62, 0.66, 0.72) * c.get_luminance(), 0.45) * 0.92
	elif weather == &"mist":
		c = c.lerp(Color(0.8, 0.83, 0.86) * maxf(c.get_luminance(), 0.4), 0.3)
	return Color(c, 1.0)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Game.weather == &"mist":
		_add_mist()
	elif Game.is_raining():
		_add_rain(STORM_RAIN if Game.weather == &"storm" else 1.0)
	if Game.weather == &"storm":
		_flash = ColorRect.new()
		_flash.color = Color(0.9, 0.93, 1.0, 0.0)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_flash)
		_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if _flash == null:
		return
	_next_lightning -= delta
	if _next_lightning > 0.0:
		return
	_next_lightning = randf_range(LIGHTNING_EVERY.x, LIGHTNING_EVERY.y)
	var t := create_tween()
	t.tween_property(_flash, "color:a", 0.55, 0.04)
	t.tween_property(_flash, "color:a", 0.1, 0.1)
	t.tween_property(_flash, "color:a", 0.35, 0.04)
	t.tween_property(_flash, "color:a", 0.0, 0.35)
	var far := randf()
	get_tree().create_timer(lerpf(0.4, 2.2, far)).timeout.connect(func() -> void:
		Audio.play_sfx(THUNDER[0 if far > 0.5 else 1], lerpf(-4.0, -11.0, far), 0.08))


## A pale veil, thick over the far part of the scene (the top), thin in front.
func _add_mist() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.9, 0.92, 0.94, 0.72))
	g.add_point(0.45, Color(0.9, 0.92, 0.94, 0.4))
	g.set_color(g.get_point_count() - 1, Color(0.9, 0.92, 0.94, 0.08))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 128
	var veil := TextureRect.new()
	veil.texture = tex
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Light, fine slanted streaks across the whole screen (`more`: a storm's heavier rain).
func _add_rain(more := 1.0) -> void:
	var screen := get_viewport().get_visible_rect().size
	var p := CPUParticles2D.new()
	p.amount = Quality.scaled(roundi(RAIN_DROPS * more))
	p.lifetime = 0.7
	p.preprocess = 0.7
	p.position = Vector2(screen.x / 2.0, -40.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(screen.x * 0.6, 10.0)
	p.direction = Vector2(0.12, 1.0)
	p.spread = 2.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 1100.0
	p.initial_velocity_max = 1400.0
	p.particle_flag_align_y = true
	var streak := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 1))
	streak.gradient = g
	streak.fill_from = Vector2(0.5, 0.0)
	streak.fill_to = Vector2(0.5, 1.0)
	streak.width = 1
	streak.height = 24
	p.texture = streak
	p.color = RAIN
	add_child(p)
