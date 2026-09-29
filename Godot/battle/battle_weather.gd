class_name BattleWeather
extends Control
## The battle happens under the same sky as the exploration: the backdrop and the fighters
## take the light of the hour (dawn, dusk, night) and of the weather; rain falls in front of
## the scene, mist veils its far part, a sandstorm veils it in ochre with sand blowing across;
## snow drifts down, a blizzard veils it in white with flakes driven across in gusts.
## Sits above the fighters, below the battle panels.

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
## A sandstorm: an ochre veil, grains streaking across from the left.
const SAND_VEIL := Color(0.88, 0.68, 0.42)
const SAND_GRAINS := 140
const SAND := Color(0.95, 0.8, 0.55, 0.45)
## Snow: soft flakes drifting down, a cold light. The blizzard: a white veil, flakes driven
## across from the left (as many as the sand's grains), faster in the gusts (GUST_S).
const SNOW_FLAKES := 90
const SNOW_LIGHT := Color(0.84, 0.88, 0.95)
const BLIZZARD_VEIL := Color(0.9, 0.93, 0.97)
const BLIZZARD_FLAKES := 140
const GUST_S := 0.8
## The flakes' white at night: this much of the daylight's.
const NIGHT_DIM := 0.5

var _flash: ColorRect
var _next_lightning := 3.0
var _driven: CPUParticles2D
var _time := 0.0


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
	elif weather == &"sandstorm":
		c = c.lerp(SAND_VEIL * maxf(c.get_luminance(), 0.45), 0.45) * 0.95
	elif weather == &"snow":
		c = c.lerp(SNOW_LIGHT * maxf(c.get_luminance(), 0.4), 0.3)
	elif weather == &"blizzard":
		c = c.lerp(BLIZZARD_VEIL * maxf(c.get_luminance(), 0.45), 0.45)
	return Color(c, 1.0)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Game.weather == &"mist":
		_add_mist()
	elif Game.weather == &"sandstorm":
		_add_mist(SAND_VEIL, 0.62)
		_add_sand()
	elif Game.weather == &"blizzard":
		_add_mist(BLIZZARD_VEIL, 0.62)
		_add_snow(false)
	elif Game.weather == &"snow":
		_add_snow(true)
	elif Game.is_raining():
		_add_rain(STORM_RAIN if Game.weather == &"storm" else 1.0)
	if Game.weather == &"storm":
		_flash = ColorRect.new()
		_flash.color = Color(0.9, 0.93, 1.0, 0.0)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_flash)
		_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	if _driven:   # the blizzard's gusts: now a lull, now a gust
		_driven.speed_scale = 1.0 + 0.35 * (sin(_time * GUST_S) * 0.6 + sin(_time * GUST_S * 2.7 + 1.3) * 0.4)
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


## A pale veil (`colour`), thick over the far part of the scene (the top), thin in front.
func _add_mist(colour := Color(0.9, 0.92, 0.94), thick := 0.72) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(colour, thick))
	g.add_point(0.45, Color(colour, thick * 5.0 / 9.0))
	g.set_color(g.get_point_count() - 1, Color(colour, thick / 9.0))
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


## Grains of sand blowing across the whole scene, left to right, and a few drifting puffs.
func _add_sand() -> void:
	var screen := get_viewport().get_visible_rect().size
	var p := CPUParticles2D.new()
	p.amount = Quality.scaled(SAND_GRAINS)
	p.lifetime = 0.9
	p.preprocess = 0.9
	p.position = Vector2(-60.0, screen.y / 2.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(20.0, screen.y * 0.55)
	p.direction = Vector2(1.0, 0.08)
	p.spread = 4.0
	p.gravity = Vector2(0, 30)
	p.initial_velocity_min = screen.x * 1.1
	p.initial_velocity_max = screen.x * 1.5
	p.particle_flag_align_y = true
	var streak := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 1))
	streak.gradient = g
	streak.fill_from = Vector2(0.5, 0.0)
	streak.fill_to = Vector2(0.5, 1.0)
	streak.width = 2
	streak.height = 18
	p.texture = streak
	p.color = SAND
	add_child(p)


## Snow over the whole scene: soft flakes drifting down (`gentle`), or driven across from the
## left by the blizzard. White by day, dimmer at night.
func _add_snow(gentle: bool) -> void:
	var screen := get_viewport().get_visible_rect().size
	var light := tint(Game.clock / 60.0, &"clear").get_luminance()
	var white := Color.WHITE * lerpf(NIGHT_DIM, 1.0, clampf(light, 0.0, 1.0))
	var p := CPUParticles2D.new()
	p.texture = _soft_dot(1)
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.8
	if gentle:
		p.amount = Quality.scaled(SNOW_FLAKES)
		p.lifetime = 6.0
		p.preprocess = 6.0
		p.position = Vector2(screen.x / 2.0, -30.0)
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(screen.x * 0.65, 10.0)
		p.direction = Vector2(0.2, 1.0)
		p.spread = 18.0
		p.gravity = Vector2(0, 12)
		p.initial_velocity_min = screen.y * 0.1
		p.initial_velocity_max = screen.y * 0.18
		p.color = Color(white, 0.85)
	else:
		p.amount = Quality.scaled(BLIZZARD_FLAKES)
		p.lifetime = 1.1
		p.preprocess = 1.1
		p.position = Vector2(-60.0, screen.y / 2.0)
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(20.0, screen.y * 0.55)
		p.direction = Vector2(1.0, 0.12)
		p.spread = 6.0
		p.gravity = Vector2(0, 40)
		p.initial_velocity_min = screen.x * 0.9
		p.initial_velocity_max = screen.x * 1.3
		p.color = Color(white, 0.8)
		p.texture = _soft_dot(3)   # blurred by their speed, drawn along it
		p.particle_flag_align_y = true
		_driven = p
	add_child(p)


static var _dots := {}


## A soft flake: white with a faint blue-grey rim (it still shows over a snowy backdrop), round,
## or `stretch` times longer than wide (a driven one).
static func _soft_dot(stretch: int) -> GradientTexture2D:
	if not _dots.has(stretch):
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.45, Color(0.97, 0.98, 1.0, 0.9))
		g.add_point(0.72, Color(0.5, 0.56, 0.68, 0.5))
		g.set_color(g.get_point_count() - 1, Color(0.5, 0.56, 0.68, 0))
		var dot := GradientTexture2D.new()
		dot.gradient = g
		dot.fill = GradientTexture2D.FILL_RADIAL
		dot.fill_from = Vector2(0.5, 0.5)
		dot.fill_to = Vector2(1.0, 0.5)
		dot.width = 24 if stretch == 1 else 10
		dot.height = 24 if stretch == 1 else 10 * stretch
		_dots[stretch] = dot
	return _dots[stretch]


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
