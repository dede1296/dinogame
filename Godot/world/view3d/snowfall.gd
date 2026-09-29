class_name Snowfall
extends Node3D
## The snow of the Monts, drawn by the WorldView around the camera's focus:
##   snow (Game weather &"snow"): soft flakes drifting down, swaying together in the breeze;
##   the blizzard (&"blizzard"): flakes driven across the view on the wind (west to east),
##   in gusts, and puffs of blown snow; the view closes in white (the WorldView's fog, see
##   veil()) like the sandstorm's ochre one.
## As many flakes as the graphics level allows (Quality); lit as the hour is (shade).

## Soft snow: flakes at the best graphics, how long one falls (s), from how high (m).
const FLAKES := 420
const FLAKE_LIFE := 7.5
const FLAKE_ABOVE := 6.5
const FLAKE_SIZE := 0.1
## The breeze swaying the falling flakes (m/s², and how fast it turns).
const SWAY := 0.35
const SWAY_S := 0.55
## The blizzard: flakes flying across (as many as the sandstorm's grains: it costs no more),
## puffs of blown snow drifting along.
const DRIVEN := 260
const PUFFS := 36
## Gusts: how fast they come and go; the wind speeds the flakes up to this much.
const GUST_S := 0.8
const GUST_SPEED := 0.7
## The white of the snow in full daylight; at night the flakes dim down to NIGHT_DIM of it.
const WHITE := Color(0.96, 0.98, 1.0)
const NIGHT_DIM := 0.4
## The blizzard's sky and veil.
const SKY := Color(0.86, 0.89, 0.94)

## 0..1, blended towards the weather (see blend).
var snow := 0.0
var blizzard := 0.0
## The blizzard's gust now (0 lull … 1 strongest).
var gust := 0.0

var _flakes: CPUParticles3D
var _driven: CPUParticles3D
var _puffs: CPUParticles3D
var _time := 0.0


func _ready() -> void:
	_flakes = _make_flakes()
	add_child(_flakes)
	_driven = _make_driven()
	add_child(_driven)
	_puffs = _make_puffs()
	add_child(_puffs)
	snow = 1.0 if Game.weather == &"snow" else 0.0
	blizzard = 1.0 if Game.weather == &"blizzard" else 0.0
	Quality.changed.connect(_apply_quality)
	_apply_quality()


func _apply_quality() -> void:
	_flakes.amount = Quality.scaled(FLAKES)
	_driven.amount = Quality.scaled(DRIVEN)
	_puffs.amount = Quality.scaled(PUFFS)


## Moves the amounts towards the weather (`step`: the view's blend for this frame), and the gusts.
func blend(delta: float, step: float) -> void:
	_time += delta
	snow = lerpf(snow, 1.0 if Game.weather == &"snow" else 0.0, step)
	blizzard = lerpf(blizzard, 1.0 if Game.weather == &"blizzard" else 0.0, step)
	# Two slow waves: now a lull, now a gust, never quite the same twice.
	var wave := sin(_time * GUST_S) * 0.6 + sin(_time * GUST_S * 2.7 + 1.3) * 0.4
	gust = clampf(0.5 + 0.5 * wave, 0.0, 1.0)


## Follows the camera's focus (the driven flakes start upwind, west of it).
func follow(focus: Vector3) -> void:
	_flakes.position = focus + Vector3(0.0, FLAKE_ABOVE, 1.5)
	_driven.position = focus + Vector3(-15.0, 1.4, 1.0)
	_puffs.position = focus + Vector3(0.0, 1.4, 1.0)
	# The breeze turns now and then: the falling flakes sway together.
	_flakes.gravity = Vector3(sin(_time * SWAY_S) * SWAY, -0.25, cos(_time * SWAY_S * 0.7) * SWAY * 0.4)


## After the sky is set: what shows, how thick, lit as the scene is (`light`: 0 night … 1 day).
func shade(light: float) -> void:
	var white := WHITE * lerpf(NIGHT_DIM, 1.0, clampf(light, 0.0, 1.0))
	# In a blizzard the soft flakes give way to the driven ones.
	var soft := maxf(snow, blizzard * 0.35)
	_flakes.emitting = soft > 0.05
	_flakes.color = Color(white, 0.9 * soft)
	_driven.emitting = blizzard > 0.05
	_driven.speed_scale = 1.0 + GUST_SPEED * (gust - 0.5)
	_driven.color = Color(white, 0.75 * blizzard)
	_puffs.emitting = blizzard > 0.05
	_puffs.color = Color(white, blizzard * (0.6 + 0.4 * gust))


## Indoors: nothing falls.
func stop() -> void:
	for p in [_flakes, _driven, _puffs]:
		(p as CPUParticles3D).emitting = false


## How much the blizzard closes the view (0..1, thicker in the gusts), for the fog.
func veil() -> float:
	return blizzard * (0.85 + 0.15 * gust)


func _make_flakes() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = FLAKES
	p.lifetime = FLAKE_LIFE
	p.preprocess = FLAKE_LIFE
	p.local_coords = false
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(14.0, 0.6, 11.0)
	p.direction = Vector3(0.15, -1.0, 0.0)
	p.spread = 20.0
	p.initial_velocity_min = 0.45
	p.initial_velocity_max = 0.9
	p.damping_min = 0.2
	p.damping_max = 0.3
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	p.color_ramp = _fade(0.1)
	p.mesh = _dot_mesh(Vector2(FLAKE_SIZE, FLAKE_SIZE), BaseMaterial3D.BILLBOARD_PARTICLES, _flake())
	return p


func _make_driven() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = DRIVEN
	p.lifetime = 2.0
	p.local_coords = false
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(3.0, 2.6, 13.0)
	p.direction = Vector3(1.0, -0.06, 0.12)
	p.spread = 7.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 15.0
	p.gravity = Vector3(0.0, -0.8, 0.0)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	p.color_ramp = _fade(0.08)
	# Blurred by their speed: a stretched soft dot, not a streak of rain.
	p.mesh = _dot_mesh(Vector2(0.24, 0.06), BaseMaterial3D.BILLBOARD_FIXED_Y, _flake())
	return p


func _make_puffs() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = PUFFS
	p.lifetime = 3.0
	p.preprocess = 3.0
	p.local_coords = false
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(15.0, 1.8, 12.0)
	p.direction = Vector3(1.0, 0.05, 0.0)
	p.spread = 10.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 7.0
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.2
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.3, Color(1, 1, 1, 0.14))
	fade.add_point(0.7, Color(1, 1, 1, 0.14))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	# (As big as the sandstorm's dust, but a haze with no edge: not a round blot.)
	p.mesh = _dot_mesh(Vector2(1.1, 1.1), BaseMaterial3D.BILLBOARD_PARTICLES, _haze())
	return p


static var _haze_tex: GradientTexture2D
static var _flake_tex: GradientTexture2D


## A flake: white, with a faint blue-grey rim so that it still shows falling over the snow.
static func _flake() -> GradientTexture2D:
	if _flake_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.45, Color(0.97, 0.98, 1.0, 0.95))
		g.add_point(0.72, Color(0.5, 0.56, 0.68, 0.55))
		g.set_color(g.get_point_count() - 1, Color(0.5, 0.56, 0.68, 0))
		_flake_tex = GradientTexture2D.new()
		_flake_tex.gradient = g
		_flake_tex.fill = GradientTexture2D.FILL_RADIAL
		_flake_tex.fill_from = Vector2(0.5, 0.5)
		_flake_tex.fill_to = Vector2(1.0, 0.5)
		_flake_tex.width = 32
		_flake_tex.height = 32
	return _flake_tex


## A soft haze: dense in the middle, fading out slowly to nothing (no visible rim).
static func _haze() -> GradientTexture2D:
	if _haze_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.9))
		g.add_point(0.35, Color(1, 1, 1, 0.5))
		g.add_point(0.7, Color(1, 1, 1, 0.12))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		_haze_tex = GradientTexture2D.new()
		_haze_tex.gradient = g
		_haze_tex.fill = GradientTexture2D.FILL_RADIAL
		_haze_tex.fill_from = Vector2(0.5, 0.5)
		_haze_tex.fill_to = Vector2(1.0, 0.5)
		_haze_tex.width = 32
		_haze_tex.height = 32
	return _haze_tex


## Fades in and out over `edge` of the life.
static func _fade(edge: float) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(edge, Color(1, 1, 1, 1))
	g.add_point(1.0 - edge, Color(1, 1, 1, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	return g


## A soft round dot (WorldView._soft_dot, or `tex`) on a quad of `size` m, unshaded, tinted by
## the particle.
static func _dot_mesh(size: Vector2, billboard: BaseMaterial3D.BillboardMode, tex: Texture2D = null) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	m.billboard_mode = billboard
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = tex if tex else WorldView._soft_dot()
	q.material = m
	return q
