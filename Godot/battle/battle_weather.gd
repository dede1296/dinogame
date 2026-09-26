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
const RAIN_DROPS := 160
const RAIN := Color(0.85, 0.9, 1.0, 0.3)


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
	if weather == &"rain":
		c = c.lerp(Color(0.62, 0.66, 0.72) * c.get_luminance(), 0.45) * 0.92
	elif weather == &"mist":
		c = c.lerp(Color(0.8, 0.83, 0.86) * maxf(c.get_luminance(), 0.4), 0.3)
	return Color(c, 1.0)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Game.weather == &"mist":
		_add_mist()
	elif Game.weather == &"rain":
		_add_rain()


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


## Light, slanted streaks across the whole screen.
func _add_rain() -> void:
	var screen := get_viewport().get_visible_rect().size
	var p := CPUParticles2D.new()
	p.amount = Quality.scaled(RAIN_DROPS)
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
	streak.width = 2
	streak.height = 34
	p.texture = streak
	p.color = RAIN
	add_child(p)
