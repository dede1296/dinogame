class_name Wildlife
extends Node3D
## Little life around Chloé, outdoors: butterflies by day (the web version's picture, wings
## beating), fireflies blinking at night; none in the rain. Follows the camera's focus;
## how many depends on the graphics level.

const BUTTERFLY := preload("res://assets/art/props/papillon.png")
const BUTTERFLIES := 6
const BUTTERFLY_SIZE := 0.22        # metres wide
const FIREFLIES := 26
const RANGE := Vector2(9.0, 6.0)   # metres around the focus (x, z)
const COLOURS: Array[Color] = [Color(1.0, 0.72, 0.1), Color(1.0, 0.45, 0.62), Color(0.35, 0.62, 1.0), Color(0.62, 0.9, 0.35)]
const WING_HZ := 7.0
const SPEED := 0.7                 # m/s

var heights: HeightMap
var _flyers: Array[Dictionary] = []   # {sprite, target, phase}
var _fireflies: CPUParticles3D
var _time := 0.0


func _ready() -> void:
	_fireflies = _make_fireflies()
	add_child(_fireflies)
	Quality.changed.connect(_apply_quality)
	_apply_quality()


func _apply_quality() -> void:
	_fireflies.amount = maxi(1, Quality.scaled(FIREFLIES))
	var count := maxi(2, Quality.scaled(BUTTERFLIES))
	while _flyers.size() > count:
		(_flyers.pop_back()["sprite"] as Node).queue_free()
	while _flyers.size() < count:
		_flyers.append(_make_butterfly())


## Places the life around `focus` for the hour and weather (`rain` 0–1); `outdoors` false: none.
func update(delta: float, focus: Vector3, hour: float, rain: float, outdoors: bool) -> void:
	_time += delta
	var day := outdoors and hour > 7.0 and hour < 19.0 and rain < 0.3
	var night := outdoors and (hour > 20.5 or hour < 4.5) and rain < 0.3
	_fireflies.emitting = night
	_fireflies.position = focus + Vector3(0, 0.8, 0)
	for f in _flyers:
		var s: Sprite3D = f["sprite"]
		s.visible = day
		if not day:
			continue
		var at: Vector3 = s.position
		var target: Vector3 = f["target"]
		# Too far from Chloé (she walked on) or arrived: a new flower to go to.
		if absf(at.x - focus.x) > RANGE.x * 1.3 or absf(at.z - focus.z) > RANGE.y * 1.3:
			at = _somewhere(focus)
			s.position = at
			target = _somewhere(focus)
		if at.distance_to(target) < 0.3:
			target = _somewhere(focus)
		f["target"] = target
		var phase: float = f["phase"]
		var step := (target - at).normalized() * SPEED * delta
		# Fluttering: a wobbly path, bobbing up and down.
		step += Vector3(sin(_time * 3.1 + phase), sin(_time * 5.3 + phase) * 1.5, cos(_time * 2.7 + phase)) * 0.35 * delta
		s.position = at + step
		s.flip_h = step.x < 0.0
		s.scale.x = 0.25 + 0.75 * absf(sin(_time * TAU * WING_HZ + phase))


func _somewhere(focus: Vector3) -> Vector3:
	var p := Vector2(focus.x + randf_range(-RANGE.x, RANGE.x), focus.z + randf_range(-RANGE.y, RANGE.y))
	var ground := heights.height(p) if heights else focus.y
	return Vector3(p.x, ground + randf_range(0.5, 1.4), p.y)


func _make_butterfly() -> Dictionary:
	var s := Sprite3D.new()
	s.texture = BUTTERFLY
	s.pixel_size = BUTTERFLY_SIZE / BUTTERFLY.get_width()
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.modulate = COLOURS.pick_random()
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.visible = false
	s.position = Vector3(0, -100, 0)   # placed far: the first update brings it near Chloé
	add_child(s)
	return {"sprite": s, "target": Vector3.ZERO, "phase": randf() * TAU}


## Small yellow-green lights drifting slowly, blinking on and off.
func _make_fireflies() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = FIREFLIES
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.local_coords = false
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(RANGE.x, 0.7, RANGE.y)
	p.direction = Vector3(1, 0.2, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	p.gravity = Vector3.ZERO
	var blink := Gradient.new()
	blink.offsets = PackedFloat32Array([0.0, 0.12, 0.25, 0.4, 0.55, 0.7, 0.85, 1.0])
	var on := Color(0.85, 1.0, 0.45, 1.0)
	var off := Color(0.85, 1.0, 0.45, 0.0)
	blink.colors = PackedColorArray([off, on, off, off, on, on, off, off])
	p.color_ramp = blink
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = WorldView._soft_dot()
	q.material = m
	p.mesh = q
	return p
