class_name SeaFeatures
extends Node3D
## The Plongée's features of a zone, as the 3D view shows them (built with the zone by
## Underwater.build, freed with it):
##   currents (SeaCurrent): streaks of water and bubbles rushing along the flow, mid-water;
##   bubble columns (BubbleColumn): big bubbles rising from a dark fissure up past the plateau,
##     a pale shaft of light along them;
##   dark nooks (DarkNook): the floor darkened, the light taken away (a negative light), and the
##     amber glow of Chloé's Cœurs around her as she comes near one (wider with more Cœurs).
## show_current(), show_column(), flare(): the first explanations show them off (SeaLessons).
## Particle counts follow the quality (Quality.scaled); the glow and the darkness stay at every
## level (they are the game).

const SHAFT := preload("res://world/view3d/light_shaft.gdshader")
const STREAK := preload("res://world/view3d/current_streak.gdshader")
const DIVE := preload("res://world/dive.gd")
const NOOK := preload("res://world/dark_nook.gd")
const PX := 48.0
## Streaks and bubbles: how high above the floor (m), how fast compared with the current.
const MID_WATER := 1.1
const STREAK_SPEED := 1.25
const STREAKS_PER_M2 := 0.9
const BUBBLE := Color(0.88, 0.97, 1.0)
## A column: its bubbles (per m² of fissure), their speed (m/s), how far above the plateau.
const COLUMN_BUBBLES := 16.0
const COLUMN_SPEED := 1.7
const COLUMN_ABOVE := 2.5
const CRACK := Color(0.01, 0.04, 0.08, 0.7)
## A nook: how dark (the negative light, the floor's tint), and Chloé's amber glow.
const DARK_ENERGY := 2.6
const DARK_FLOOR := Color(0.04, 0.05, 0.09, 0.62)
const DARK_TAKES := Color(1.0, 0.96, 0.86)
const AMBER := Color(1.0, 0.84, 0.55)
const GLOW_ENERGY := 2.8
const GLOW_MORE := 0.6    # energy by each more Cœur
const GLOW_FADE := 3.0    # how fast it comes and goes (per s)

var view   # the WorldView (untyped: it builds this, through Underwater)
var _currents := {}   # SeaCurrent -> {streaks, bubbles}
var _columns := {}    # BubbleColumn -> {bubbles, shaft}
var _nooks: Array[Node2D] = []
var _glow: OmniLight3D
var _motes: CPUParticles3D
var _glow_k := 0.0
var _flare := 0.0


## The features of `region` (shown by `world_view`, built into `zone`); null when it has none.
static func build(world_view: Node3D, region: Node, zone: Node3D) -> Node3D:
	var found := false
	for group: StringName in [&"sea_current", &"bubble_column", &"dark_nook"]:
		for n in world_view.get_tree().get_nodes_in_group(group):
			if region.is_ancestor_of(n):
				found = true
	if not found:
		return null
	var f: Node3D = load("res://world/view3d/sea_features.gd").new()
	f.name = "Plongee"
	f.view = world_view
	zone.add_child(f)
	for n in world_view.get_tree().get_nodes_in_group(&"sea_current"):
		if region.is_ancestor_of(n):
			f._add_current(n)
	for n in world_view.get_tree().get_nodes_in_group(&"bubble_column"):
		if region.is_ancestor_of(n):
			f._add_column(n)
	for n in world_view.get_tree().get_nodes_in_group(&"dark_nook"):
		if region.is_ancestor_of(n):
			f._add_nook(n)
	return f


func _ready() -> void:
	add_to_group(&"sea_features")
	process_priority = 110   # after the water (Underwater), whose light dances on the floor: dimmed in a nook


# ------------------------------------------------------------------ currents

func _add_current(c: Node2D) -> void:
	var r: Rect2 = c.call(&"area")
	var t := Rect2(r.position / PX, r.size / PX)
	var d: Vector2 = c.call(&"flow")
	var along := absf(d.x) * t.size.x + absf(d.y) * t.size.y
	var across := absf(d.y) * t.size.x + absf(d.x) * t.size.y
	var centre := t.get_center()
	var at := Vector3(centre.x, view.heights.height(centre) + MID_WATER, centre.y)
	var speed: float = float(c.get(&"strength")) / PX * STREAK_SPEED
	var streaks := _flow_particles(d, along, across, speed, true, Quality.scaled(roundi(along * across * STREAKS_PER_M2) + 4))
	streaks.position = at
	add_child(streaks)
	var bubbles := _flow_particles(d, along, across, speed * 0.8, false, Quality.scaled(roundi(along * across * 0.45) + 4))
	bubbles.position = at + Vector3(0.0, 0.3, 0.0)
	add_child(bubbles)
	_currents[c] = {"streaks": streaks, "bubbles": bubbles, "d": d, "along": along, "across": across, "speed": speed, "at": at}


## Particles rushing along `d` (2D) over a box `along` × `across` m: streaks, or bubbles.
func _flow_particles(d: Vector2, along: float, across: float, speed: float, streak: bool, amount: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = maxi(1, amount)
	p.lifetime = clampf(along / maxf(speed, 0.1) * 0.7, 0.6, 5.0)
	p.preprocess = p.lifetime
	p.local_coords = false
	# The emitter's local +X is the flow.
	p.rotation.y = atan2(-d.y, d.x)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(along * 0.45, 0.8 if streak else 0.9, across * 0.45)
	p.direction = Vector3(1.0, 0.0, 0.0) if streak else Vector3(1.0, 0.12, 0.0)
	p.spread = 3.0 if streak else 10.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = speed * 0.8
	p.initial_velocity_max = speed * 1.2
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 0.9 if streak else 0.8))
	fade.add_point(0.75, Color(1, 1, 1, 0.8 if streak else 0.7))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	if streak:
		var q := QuadMesh.new()
		var m := ShaderMaterial.new()
		m.shader = STREAK
		m.set_shader_parameter("flow", Vector3(d.x, 0.0, d.y))
		m.set_shader_parameter("streak_length", 1.3)
		m.set_shader_parameter("streak_width", 0.06)
		m.set_shader_parameter("colour", Color(0.85, 0.97, 1.0, 0.95))
		q.material = m
		p.mesh = q
	else:
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.3
		p.mesh = _ring_quad(0.1)
	return p


## The current `c` at its strongest for a moment: weed and bubbles swept along it.
func show_current(c: Node2D) -> void:
	var data: Dictionary = _currents.get(c, {})
	if data.is_empty():
		return
	var d: Vector2 = data["d"]
	var gust := _flow_particles(d, data["along"], data["across"] * 0.6, data["speed"] * 1.3, true, Quality.scaled(40))
	gust.one_shot = true
	gust.preprocess = 0.0
	gust.explosiveness = 0.5
	gust.position = data["at"] - Vector3(d.x, 0.0, d.y) * float(data["along"]) * 0.3
	gust.emission_box_extents.x *= 0.4
	add_child(gust)
	gust.emitting = true
	gust.finished.connect(gust.queue_free)
	var weed := _flow_particles(d, data["along"], data["across"] * 0.5, data["speed"] * 1.1, false, Quality.scaled(18))
	weed.one_shot = true
	weed.preprocess = 0.0
	weed.explosiveness = 0.4
	weed.color = Color(0.45, 0.75, 0.4)   # (bits of weed, green, among the bubbles)
	weed.position = gust.position
	add_child(weed)
	weed.emitting = true
	weed.finished.connect(weed.queue_free)


# ------------------------------------------------------------------ bubble columns

func _add_column(c: Node2D) -> void:
	var r: Rect2 = c.call(&"area")
	var foot_px := r.get_center()
	var foot: Vector3 = view.heights.to_3d(foot_px)
	var top_y: float = view.heights.to_3d(c.call(&"landing_px")).y
	var rise := maxf(top_y - foot.y, 1.0) + COLUMN_ABOVE
	var w := r.size / PX
	var big := _column_bubbles(w, rise, 0.3, Quality.scaled(roundi(w.x * w.y * COLUMN_BUBBLES * 0.4) + 6))
	big.position = foot + Vector3(0.0, 0.15, 0.0)
	add_child(big)
	var small := _column_bubbles(w, rise, 0.1, Quality.scaled(roundi(w.x * w.y * COLUMN_BUBBLES) + 8))
	small.position = big.position
	add_child(small)
	# A pale light along it.
	var shaft := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(maxf(w.x, w.y) * 0.9 + 0.5, rise)
	var mat := ShaderMaterial.new()
	mat.shader = SHAFT
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	mat.set_shader_parameter("lean", 0.0)
	mat.set_shader_parameter("strength", 0.22)
	quad.material = mat
	shaft.mesh = quad
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shaft.position = foot + Vector3(0.0, rise / 2.0, 0.0)
	add_child(shaft)
	# The fissure: a dark crack in the floor.
	var crack := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = w + Vector2(0.6, 0.6)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = CRACK
	m.albedo_texture = WorldView._soft_dot()
	plane.material = m
	crack.mesh = plane
	crack.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crack.position = foot + Vector3(0.0, 0.04, 0.0)
	add_child(crack)
	_columns[c] = {"big": big, "shaft": mat, "foot": foot, "w": w, "rise": rise}


func _column_bubbles(w: Vector2, rise: float, size: float, amount: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = maxi(1, amount)
	p.lifetime = rise / COLUMN_SPEED
	p.preprocess = p.lifetime
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(w.x * 0.3, 0.05, w.y * 0.3)
	p.direction = Vector3.UP
	p.spread = 5.0
	p.gravity = Vector3(0.0, 0.25, 0.0)
	p.initial_velocity_min = COLUMN_SPEED * 0.75
	p.initial_velocity_max = COLUMN_SPEED * 1.15
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.5
	var fade := Gradient.new()
	fade.set_color(0, Color(BUBBLE, 0.0))
	fade.add_point(0.08, Color(BUBBLE, 0.9))
	fade.add_point(0.85, Color(BUBBLE, 0.75))
	fade.set_color(fade.get_point_count() - 1, Color(BUBBLE, 0.0))
	p.color_ramp = fade
	p.mesh = _ring_quad(size)
	return p


## The column `c` gushing for a moment: a burst of big bubbles, its light brighter.
func show_column(c: Node2D) -> void:
	var data: Dictionary = _columns.get(c, {})
	if data.is_empty():
		return
	var gush := _column_bubbles(data["w"], data["rise"], 0.34, Quality.scaled(34))
	gush.one_shot = true
	gush.preprocess = 0.0
	gush.explosiveness = 0.6
	gush.initial_velocity_max *= 1.4
	gush.position = data["foot"] + Vector3(0.0, 0.15, 0.0)
	add_child(gush)
	gush.emitting = true
	gush.finished.connect(gush.queue_free)
	var mat: ShaderMaterial = data["shaft"]
	var t := create_tween()
	t.tween_method(func(k: float) -> void: mat.set_shader_parameter("strength", k), 0.22, 0.5, 0.4)
	t.tween_method(func(k: float) -> void: mat.set_shader_parameter("strength", k), 0.5, 0.22, 1.6)


# ------------------------------------------------------------------ dark nooks, the Cœurs' glow

func _add_nook(n: Node2D) -> void:
	var r: Rect2 = n.call(&"area")
	var t := Rect2(r.position / PX, r.size / PX)
	var c := t.get_center()
	var floor_y: float = view.heights.height(c)
	var dark := OmniLight3D.new()
	dark.light_negative = true
	dark.light_color = DARK_TAKES   # (it takes more of the warm light: the dark stays sea-blue, not red)
	dark.light_energy = DARK_ENERGY
	dark.omni_range = maxf(t.size.x, t.size.y) * 0.6 + 1.6
	dark.omni_attenuation = 0.5
	dark.shadow_enabled = false
	dark.position = Vector3(c.x, floor_y + 1.4, c.y)
	add_child(dark)
	var shade := Decal.new()
	shade.size = Vector3(t.size.x + 2.0, 6.0, t.size.y + 2.0)
	shade.texture_albedo = WorldView._soft_dot()
	shade.modulate = DARK_FLOOR
	shade.albedo_mix = DARK_FLOOR.a
	shade.normal_fade = 0.3
	shade.position = Vector3(c.x, floor_y + 1.0, c.y)
	add_child(shade)
	_nooks.append(n)
	if _glow == null:
		_glow = OmniLight3D.new()
		_glow.light_color = AMBER
		_glow.light_energy = 0.0
		_glow.shadow_enabled = false
		_glow.omni_attenuation = 0.8
		add_child(_glow)
		_motes = CPUParticles3D.new()
		_motes.amount = Quality.scaled(14)
		_motes.lifetime = 1.6
		_motes.local_coords = false
		_motes.emitting = false
		_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_motes.emission_sphere_radius = 0.35
		_motes.direction = Vector3.UP
		_motes.spread = 30.0
		_motes.gravity = Vector3(0.0, 0.25, 0.0)
		_motes.initial_velocity_min = 0.1
		_motes.initial_velocity_max = 0.35
		var fade := Gradient.new()
		fade.set_color(0, Color(AMBER, 0.0))
		fade.add_point(0.3, Color(AMBER, 0.9))
		fade.set_color(fade.get_point_count() - 1, Color(AMBER, 0.0))
		_motes.color_ramp = fade
		_motes.mesh = WorldView._speck(0.05)
		add_child(_motes)


## The Cœurs flare up for a moment (the first time Chloé comes to a dark nook).
func flare(_what: Node2D = null) -> void:
	_flare = 1.0


func _process(delta: float) -> void:
	if _glow == null or not is_instance_valid(view) or view.get(&"player") == null:
		return
	var chloe: Node2D = view.player
	var lit := false
	for n in _nooks:
		if is_instance_valid(n) and n.call(&"lit_by", chloe):
			lit = true
	_glow_k = move_toward(_glow_k, 1.0 if lit else 0.0, GLOW_FADE * delta)
	_flare = maxf(0.0, _flare - delta * 0.6)
	var hearts: int = NOOK.hearts()
	var reach: float = NOOK.light_radius_px() / PX
	var under = view.get(&"_underwater")
	var lift: float = under.hover(chloe) if under else 0.0
	var sink = view.get(&"dive_sink")
	lift -= float(sink) if sink != null else 0.0
	_glow.visible = _glow_k > 0.01
	_glow.light_energy = (GLOW_ENERGY + GLOW_MORE * maxf(0.0, hearts - 1.0)) * _glow_k * (1.0 + 0.8 * _flare) * (0.92 + 0.08 * sin(Time.get_ticks_msec() / 260.0))
	_glow.omni_range = reach + 1.2 + 1.0 * _flare
	_glow.position = view.heights.to_3d(chloe.global_position) + Vector3(0.0, 0.9 + lift, 0.25)
	_motes.emitting = _glow_k > 0.5
	_motes.position = _glow.position
	# In the dark, no light dancing on the floor either.
	if under and _glow_k > 0.0:
		for d in under.get(&"_caustics"):
			(d as Decal).emission_energy *= 1.0 - 0.85 * _glow_k


## A camera-facing bubble (DIVE.ring_texture).
static func _ring_quad(size: float) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = DIVE.ring_texture()
	q.material = m
	return q
