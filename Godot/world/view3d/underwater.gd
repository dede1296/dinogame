class_name Underwater
extends Node3D
## Under the sea (la Plongée, Dive): a zone played under the water (Region.underwater) is seen
## through blue-green water. The far melts into the deep blue; the light comes from above, pale
## and bluish, dimmer at night; slow shafts of light come and go around Chloé and the light
## dances on the floor (caustics, when the water is detailed: Quality "water_detail"); specks
## drift in the water; bubbles rise from Chloé's mask now and then, and trail behind her diver
## while it swims; her shadow lies blurred on the floor below; the music and the sounds of the
## place are muffled. Chloé on her diver, and the sea's dinos, swim above the floor: hover(),
## which WorldView adds to their height. No rain, pollen, sand nor wake down there.
## WorldView builds it with the zone (build()) and frees it with it; it runs after the view each
## frame (process_priority) and sets the light over what the view has set for the sky.
## build() also builds the zone's currents, bubble columns and dark nooks (SeaFeatures), and marks
## its dive spots (DiveSpot): above the water, a darker patch where
## bubbles break the surface; under it, a dark hollow in the floor with bubbles rising from it.

const PATH := "res://world/view3d/underwater.gd"
const SHAFT := preload("res://world/view3d/light_shaft.gdshader")
const DIVE := preload("res://world/dive.gd")
const SEA_FEATURES := preload("res://world/view3d/sea_features.gd")
## The water: the deep (far away, behind everything) and the light from above (ambient), by
## day and at night; the sun, pale and bluish, straight from above.
const DEEP_DAY := Color(0.06, 0.3, 0.4)
const DEEP_NIGHT := Color(0.01, 0.04, 0.1)
const AMBIENT_DAY := Color(0.38, 0.7, 0.82)
const AMBIENT_NIGHT := Color(0.12, 0.2, 0.38)
const SUN_TINT := Color(0.72, 0.95, 1.0)
const SUN_DAY := 0.62
const SUN_NIGHT := 0.12
## How far one sees: clear up to about Chloé, the deep blue this far beyond her (m); how thick.
const MURK_M := 14.0
const MURK := 0.94
## Swimming above the floor (m), bobbing slowly (m, s).
const HOVER := 0.8
const BOB := 0.07
const BOB_S := 2.8
## Shafts of light: how many, how far around Chloé (m), how big (m), how long each shows (s).
const SHAFTS := 8
const SHAFT_RANGE := 15.0
const SHAFT_SIZE := Vector2(2.4, 12.0)
const SHAFT_LIFE := Vector2(7.0, 13.0)
## Specks in the water, around the camera's focus.
const MOTES := 90
## Chloé breathes through her mask: a few bubbles this often (s).
const BREATH_EVERY := Vector2(2.0, 4.2)
## Muffled sounds: a low-pass on these buses (Hz).
const MUFFLED: Array[StringName] = [&"Music", &"Ambience"]
const MUFFLE_HZ := 750.0
## Caustics on the floor: 2 × 2 decals of this size (m) around Chloé, the light pattern
## drifting (m/s); the pattern's picture (px) and its cells (per px).
const CAUSTIC_TILE := 32.0
const CAUSTIC_DRIFT := Vector2(0.16, 0.1)
const CAUSTIC_COLOUR := Color(0.62, 0.95, 1.0)
const CAUSTIC_ENERGY := 0.17
const CAUSTIC_PX := 256
const CAUSTIC_CELLS := 0.22
## A dive spot's marks: the darker water, and its bubbles.
const SPOT_DARK := Color(0.01, 0.06, 0.14, 0.55)
const BUBBLE := Color(0.88, 0.97, 1.0)
## Swimming, never walking (the rule of the game under the sea): the height a swimmer is shown
## at follows the floor smoothly and rises before the rocks, the reef's ridges and the scenery
## it passes over (the highest within SWIM_REACH m around it, OVER_PROP of a prop's height),
## eased at SWIM_EASE; Chloé and her diver share theirs. A slow roll and pitch (deg, s); turning
## round, the picture narrows and widens again (TURN_S, down to TURN_MIN of its width).
const SWIM_REACH := 1.1
const SWIM_EASE := 2.6
const OVER_PROP := 0.75
const REACH_DIRS: Array[Vector2] = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
	Vector2(0.7, 0.7), Vector2(-0.7, 0.7), Vector2(0.7, -0.7), Vector2(-0.7, -0.7)]
const ROLL_DEG := 3.5
const PITCH_DEG := 2.5
const ROLL_S := 3.6
const PITCH_S := 2.7
const TURN_S := 0.35
const TURN_MIN := 0.12
const PAIR_PHASE := 0.37
## The view's particles that have no place under the water.
const QUIET: Array[StringName] = [&"_pollen", &"_rain", &"_sand", &"_dust", &"_wake"]

var view   # the WorldView (untyped: it builds this)
var _t := 0.0
var _shafts: Array[Dictionary] = []   # {mesh, age, life}
var _motes: CPUParticles3D
var _breath: CPUParticles3D
var _trail: CPUParticles3D
var _blob: MeshInstance3D
var _caustics: Array[Decal] = []
var _next_breath := 1.5
var _fog_density := 0.01
var _zone_region: Node   # the zone under the water (build)
var _pair := {}    # Chloé and her diver: one swim height, one roll, one turn
var _tall: Array = []   # the scenery one swims over: [place (px), radius (px), height (m)]
var _floor := 0.0      # the zone's lowest ground (m): Region.cliff_between
static var _muffles := {}   # bus index -> its low-pass
static var _caustic: ImageTexture


## Marks the dive spots of `region` (shown by `world_view`, built into `zone`); under the water,
## adds the water itself and returns it (else null).
static func build(world_view: Node3D, region: Node, zone: Node3D) -> Node3D:
	_mark_spots(world_view, region, zone)
	SEA_FEATURES.build(world_view, region, zone)   # currents, bubble columns, dark nooks
	if not DIVE.underwater(region):
		return null
	var u: Node3D = load(PATH).new()
	u.name = "SousLEau"
	u.view = world_view
	u.set(&"_zone_region", region)
	zone.add_child(u)
	return u


func _ready() -> void:
	process_priority = 100   # after the view, which sets the sky first
	var env: Environment = view.get(&"_env")
	_fog_density = env.fog_density
	for i in SHAFTS:
		_add_shaft()
	_motes = _make_motes()
	add_child(_motes)
	_breath = _make_bubbles(5, 2.2, 0.1, true)
	add_child(_breath)
	_trail = _make_bubbles(Quality.scaled(14), 1.8, 0.08, false)
	add_child(_trail)
	_blob = MeshInstance3D.new()
	_blob.mesh = view.call(&"_contact")
	_blob.scale = Vector3(1.5, 1.0, 1.0)
	_blob.transparency = 0.35
	_blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_blob)
	if Quality.setting(&"water_detail"):
		_add_caustics()
	_muffle(true)
	_find_tall_scenery()


func _exit_tree() -> void:
	_muffle(false)
	if is_instance_valid(view):
		var env: Environment = view.get(&"_env")
		if env:
			env.fog_density = _fog_density
		for key: StringName in QUIET:
			var p = view.get(key)
			if p and key != &"_pollen":   # (the view shows the pollen itself, by the hour)
				p.visible = true


func _process(delta: float) -> void:
	if not is_instance_valid(view) or view.get(&"player") == null or view.get(&"heights") == null:
		return
	_t += delta
	var hour := Game.clock / 60.0
	var day := smoothstep(5.5, 8.0, hour) * (1.0 - smoothstep(18.5, 20.5, hour))
	_light(day)
	_quiet_the_sky()
	var focus: Vector3 = view.camera.target
	_update_shafts(delta, focus, day)
	_motes.position = focus + Vector3(0.0, 1.4, 0.0)
	_update_chloe(delta)
	_update_caustics(focus, day)


## How far above the floor `node` is shown (m): Chloé and her diver swim above it, bobbing
## slowly; the sea's dinos too, each at its own height and pace; the rest stands on the floor.
func hover(node: Node) -> float:
	if node is Player or node is Companion:
		return HOVER + BOB * sin(_t * TAU / BOB_S)
	if node is WildDino or node is DinoNpc:
		var k := float(node.get_instance_id() % 101) / 101.0
		return HOVER * lerpf(0.7, 1.4, k) + BOB * sin(_t * TAU / (BOB_S * lerpf(0.8, 1.2, k)) + k * TAU)
	return 0.0


# ------------------------------------------------------------------ swimming, never walking

## How much higher than the floor under `at` a swimmer is shown (m, added to its place; hover()
## on top): the highest floor or scenery around it, eased, so that it rises before a rock and
## glides over it. `p`: its proxy (WorldView), where its height is kept; Chloé and her diver
## share one, taken where Chloé is.
func swim_lift(p: Dictionary, src: Node, at: Vector2) -> float:
	var pair := src is Player or src is Companion
	var state: Dictionary = _pair if pair else p
	var frame := Engine.get_process_frames()
	if state.get(&"lift_frame", -1) != frame:
		state[&"lift_frame"] = frame
		var here: Vector2 = (view.get(&"player") as Node2D).global_position if pair else at
		var top := _top_near(here)
		var y: float = state.get(&"swim_y", top)
		if absf(y - top) > 6.0:   # (just arrived, or put somewhere else: no long climb)
			y = top
		state[&"swim_y"] = lerpf(y, top, 1.0 - exp(-SWIM_EASE * get_process_delta_time()))
	return maxf(0.0, float(state[&"swim_y"]) - (view.get(&"heights") as HeightMap).to_3d(at).y)


## Where the camera looks under the sea (m): the height Chloé swims over (her floor, eased), not
## the floor right under her; `ground` until she has one.
func camera_height(ground: float) -> float:
	return float(_pair.get(&"swim_y", ground))


## A swimmer's pose on `vis` (its place and size already set): a slow roll and pitch, and a
## soft turn when it comes to face the other way (the picture narrows, then widens facing the
## new way). Chloé on her diver's back rolls, pitches and turns with it, around its body.
func swim_pose(p: Dictionary, src: Node, vis: SpriteBase3D) -> void:
	if vis.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
		vis.billboard = BaseMaterial3D.BILLBOARD_DISABLED   # (the pose turns it: facing the camera below)
	var pair := src is Player or src is Companion
	var state: Dictionary = _pair if pair else p
	if src is Companion or not pair:
		state[&"face"] = -1.0 if vis.flip_h else 1.0
	var frame := Engine.get_process_frames()
	if state.get(&"pose_frame", -1) != frame:
		state[&"pose_frame"] = frame
		var k: float = PAIR_PHASE if pair else float(src.get_instance_id() % 101) / 101.0
		state[&"roll"] = deg_to_rad(ROLL_DEG) * sin(_t * TAU / ROLL_S + k * TAU)
		state[&"pitch"] = deg_to_rad(PITCH_DEG) * sin(_t * TAU / PITCH_S + k * 5.0)
		var face: float = state.get(&"face", 1.0)
		state[&"turn"] = move_toward(float(state.get(&"turn", face)), face, 2.0 * get_process_delta_time() / TURN_S)
	var turn: float = state[&"turn"]
	var width := maxf(absf(turn), TURN_MIN)
	if not src is Player:
		vis.flip_h = turn < 0.0
	var tilt := Basis.from_euler(Vector3(state[&"pitch"], 0.0, state[&"roll"]))
	# Around its feet: its picture's own offset (a rider's seat, a scene's lean) turns with it.
	var sprite = src.get(&"sprite")
	var local: Vector2 = (sprite as Node2D).position if sprite is Node2D else Vector2.ZERO
	var rel := Vector3(local.x / HeightMap.PX, -local.y / HeightMap.PX * WorldView.STRETCH, 0.0)
	var foot := vis.position - rel
	rel.x *= width
	vis.position = foot + tilt * rel
	var size := vis.scale
	var yaw: float = (view.get(&"camera") as Node3D).global_rotation.y
	vis.basis = Basis(Vector3.UP, yaw) * tilt * Basis.from_scale(Vector3(size.x * width, size.y, size.z))


## The highest floor, or top of the scenery one swims over, around `at` (m).
func _top_near(at: Vector2) -> float:
	var heights: HeightMap = view.get(&"heights")
	var reach := SWIM_REACH * HeightMap.PX
	var top: float = heights.to_3d(at).y
	var region := _zone_region as Region
	var here := Vector2i((at / HeightMap.PX).floor())
	for d: Vector2 in REACH_DIRS:
		var p := at + d * reach
		# (not what stands behind a wall: at the foot of a high rock, one does not climb along it)
		if region and region.cliff_between(region.tile_height(here), region.tile_height(Vector2i((p / HeightMap.PX).floor())), _floor):
			continue
		top = maxf(top, heights.to_3d(p).y)
	for t: Array in _tall:
		if (t[0] as Vector2).distance_to(at) < float(t[1]) + reach:
			top = maxf(top, heights.to_3d(t[0]).y + float(t[2]) * OVER_PROP)
	return top


## The zone's scenery that stands in the way on foot (Prop.KINDS "solid"): under the water one
## swims over it (Dive lets it through), a little above its top.
func _find_tall_scenery() -> void:
	if _zone_region == null:
		return
	_floor = (_zone_region as Region).floor_height()
	for n in (_zone_region.get(&"entities") as Node).get_children():
		if not n is Prop:
			continue
		var solid = Prop.KINDS.get((n as Prop).kind, {}).get("solid", 0.0)
		var radius: float = maxf(solid.x, solid.y) * 0.5 if solid is Vector2 else float(solid)
		var sprite: Sprite2D = (n as Prop).sprite
		if radius <= 0.0 or sprite == null or sprite.texture == null:
			continue
		var height := sprite.texture.get_height() * absf(sprite.global_scale.y) / HeightMap.PX * WorldView.STRETCH
		_tall.append([(n as Node2D).global_position, radius, height])


# ------------------------------------------------------------------ light and sound

## The water's light over the sky the view has just set (`day`: 0 at night, 1 by day).
func _light(day: float) -> void:
	var env: Environment = view.get(&"_env")
	var sun: DirectionalLight3D = view.get(&"_sun")
	var deep := DEEP_NIGHT.lerp(DEEP_DAY, day)
	env.background_color = deep
	env.fog_light_color = deep
	env.fog_density = MURK
	var near: float = view.camera.distance()
	env.fog_depth_begin = near - 1.0
	env.fog_depth_end = near + MURK_M
	env.ambient_light_color = AMBIENT_NIGHT.lerp(AMBIENT_DAY, day)
	env.ambient_light_energy = lerpf(0.55, 0.8, day)
	sun.rotation_degrees = Vector3(-74.0, 18.0, 0.0)
	sun.light_color = SUN_TINT
	sun.light_energy = lerpf(SUN_NIGHT, SUN_DAY, day)
	RenderingServer.global_shader_parameter_set(&"sun_dir", sun.global_transform.basis.z.normalized())
	RenderingServer.global_shader_parameter_set(&"sun_light", clampf(sun.light_energy / 1.25, 0.0, 1.0))


## No pollen, rain, sand, dust nor wake on the water's sheet down there (hidden: the view keeps
## setting them going; shown again when the water is gone, _exit_tree).
func _quiet_the_sky() -> void:
	for key: StringName in QUIET:
		var p = view.get(key)
		if p:
			p.visible = false
	var ground = view.get(&"_ground_mat")
	if ground:
		ground.set_shader_parameter("wetness", 0.0)


## The music and the place's sounds heard through the water (on), or clearly again.
static func _muffle(on: bool) -> void:
	for bus_name in MUFFLED:
		var bus := AudioServer.get_bus_index(bus_name)
		if bus < 0:
			continue
		if on and not _muffles.has(bus):
			var fx := AudioEffectLowPassFilter.new()
			fx.cutoff_hz = MUFFLE_HZ
			AudioServer.add_bus_effect(bus, fx)
			_muffles[bus] = fx
		elif not on and _muffles.has(bus):
			var i := _effect_index(bus, _muffles[bus])
			if i >= 0:
				AudioServer.remove_bus_effect(bus, i)
			_muffles.erase(bus)


## A battle under the water: its music heard clearly (`clear`), then muffled again.
static func hold_muffle(clear: bool) -> void:
	for bus: int in _muffles:
		var i := _effect_index(bus, _muffles[bus])
		if i >= 0:
			AudioServer.set_bus_effect_enabled(bus, i, not clear)


static func _effect_index(bus: int, fx: AudioEffect) -> int:
	for i in AudioServer.get_bus_effect_count(bus):
		if AudioServer.get_bus_effect(bus, i) == fx:
			return i
	return -1


# ------------------------------------------------------------------ shafts of light

func _add_shaft() -> void:
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = SHAFT_SIZE
	var mat := ShaderMaterial.new()
	mat.shader = SHAFT
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	quad.material = mat
	mesh.mesh = quad
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.set_instance_shader_parameter(&"phase", randf())
	mesh.set_instance_shader_parameter(&"fade", 0.0)
	add_child(mesh)
	var shaft := {"mesh": mesh, "age": 0.0, "life": 1.0}
	_shafts.append(shaft)
	_place_shaft(shaft, view.heights.to_3d(view.player.global_position))   # (the camera is still on the last zone)
	shaft["age"] = randf() * float(shaft["life"])   # they do not all come at once


## A shaft comes somewhere near Chloé, its foot on the floor.
func _place_shaft(shaft: Dictionary, focus: Vector3) -> void:
	var at := Vector2(focus.x, focus.z) + Vector2.from_angle(randf() * TAU) * randf_range(2.0, SHAFT_RANGE)
	var floor_y: float = view.heights.height(at)
	(shaft["mesh"] as MeshInstance3D).position = Vector3(at.x, floor_y + SHAFT_SIZE.y / 2.0 - 0.6, at.y)
	shaft["age"] = 0.0
	shaft["life"] = randf_range(SHAFT_LIFE.x, SHAFT_LIFE.y)


func _update_shafts(delta: float, focus: Vector3, day: float) -> void:
	for shaft in _shafts:
		shaft["age"] = float(shaft["age"]) + delta
		if shaft["age"] >= shaft["life"]:
			_place_shaft(shaft, focus)
		var k: float = shaft["age"] / shaft["life"]
		var mesh: MeshInstance3D = shaft["mesh"]
		mesh.set_instance_shader_parameter(&"fade", smoothstep(0.0, 0.25, k) * (1.0 - smoothstep(0.7, 1.0, k)) * lerpf(0.2, 1.0, day))
		mesh.position += Vector3(CAUSTIC_DRIFT.x, 0.0, CAUSTIC_DRIFT.y) * delta * 0.5


# ------------------------------------------------------------------ Chloé, bubbles, specks

func _update_chloe(delta: float) -> void:
	var player: CharacterBody2D = view.player
	var at: Vector3 = view.heights.to_3d(player.global_position)
	var carried: bool = player.get(&"swimmer") != null
	var sink = view.get(&"dive_sink")
	var lift: float = hover(player) - (float(sink) if sink != null else 0.0)
	_blob.visible = carried
	_blob.position = at + Vector3(0.0, 0.04, 0.0)
	# She breathes through her mask: a few bubbles rise from her head.
	_next_breath -= delta
	if _next_breath <= 0.0 and carried:
		_next_breath = randf_range(BREATH_EVERY.x, BREATH_EVERY.y)
		_breath.position = at + Vector3(0.1, lift + WorldView.head_height(player) + 0.05, 0.05)
		_breath.restart()
	# Her diver leaves a trail of bubbles as it swims.
	var moving := carried and player.velocity.length() > 40.0
	_trail.emitting = moving
	if moving:
		var back := -player.velocity.normalized() * 1.1
		_trail.position = at + Vector3(back.x, lift + 0.35, back.y)


## Specks drifting in the water around the camera's focus.
func _make_motes() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = Quality.scaled(MOTES)
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(14.0, 3.0, 11.0)
	p.direction = Vector3(1.0, 0.1, 0.3)
	p.spread = 180.0
	p.gravity = Vector3(0.02, 0.01, 0.0)
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.12
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	var fade := Gradient.new()
	fade.set_color(0, Color(0.8, 0.95, 1.0, 0.0))
	fade.add_point(0.25, Color(0.8, 0.95, 1.0, 0.5))
	fade.add_point(0.75, Color(0.8, 0.95, 1.0, 0.5))
	fade.set_color(fade.get_point_count() - 1, Color(0.8, 0.95, 1.0, 0.0))
	p.color_ramp = fade
	p.mesh = WorldView._speck(0.05)
	return p


## Bubbles rising and wobbling up: a breath (`breath`, a few at once), or a trail.
static func _make_bubbles(amount: int, life: float, size: float, breath: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.one_shot = breath
	p.explosiveness = 0.55 if breath else 0.0
	p.emitting = false
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.08 if breath else 0.3
	p.direction = Vector3.UP
	p.spread = 14.0 if breath else 30.0
	p.initial_velocity_min = 0.45
	p.initial_velocity_max = 0.9
	p.gravity = Vector3(0.0, 0.35, 0.0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var fade := Gradient.new()
	fade.set_color(0, Color(BUBBLE, 0.9))
	fade.add_point(0.8, Color(BUBBLE, 0.7))
	fade.set_color(fade.get_point_count() - 1, Color(BUBBLE, 0.0))
	p.color_ramp = fade
	p.mesh = _ring_quad(size)
	return p


## A camera-facing bubble (a clear round with a bright rim).
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


# ------------------------------------------------------------------ caustics

func _add_caustics() -> void:
	var tex := caustic_texture()
	for i in 4:
		var d := Decal.new()
		d.size = Vector3(CAUSTIC_TILE, 40.0, CAUSTIC_TILE)
		d.texture_emission = tex
		d.emission_energy = CAUSTIC_ENERGY
		d.modulate = CAUSTIC_COLOUR
		d.normal_fade = 0.45
		d.upper_fade = 0.1
		d.lower_fade = 0.1
		add_child(d)
		_caustics.append(d)


## The four decals cover the ground around Chloé; the pattern (seamless) drifts slowly and
## sways, so the tiles shift without a seam.
func _update_caustics(focus: Vector3, day: float) -> void:
	if _caustics.is_empty():
		return
	var drift := CAUSTIC_DRIFT * _t + Vector2(sin(_t * 0.23), cos(_t * 0.19)) * 0.6
	var fx := floorf((focus.x - drift.x) / CAUSTIC_TILE - 0.5)
	var fz := floorf((focus.z - drift.y) / CAUSTIC_TILE - 0.5)
	var energy := CAUSTIC_ENERGY * lerpf(0.12, 1.0, day) * (0.85 + 0.15 * sin(_t * 1.3))
	for i in _caustics.size():
		var d := _caustics[i]
		d.position = Vector3(drift.x + (fx + (i & 1) + 0.5) * CAUSTIC_TILE, focus.y + 8.0,
			drift.y + (fz + (i >> 1) + 0.5) * CAUSTIC_TILE)
		d.emission_energy = energy


## The light's net on the floor: the edges between cells of a seamless cellular noise, thin and
## bright (made once).
static func caustic_texture() -> ImageTexture:
	if _caustic == null:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_CELLULAR
		noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
		noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
		noise.fractal_type = FastNoiseLite.FRACTAL_NONE
		noise.frequency = CAUSTIC_CELLS
		noise.seed = 7
		var img := noise.get_seamless_image(CAUSTIC_PX, CAUSTIC_PX, true, false, 0.1, true)
		img.convert(Image.FORMAT_L8)
		var data := img.get_data()
		for i in data.size():
			data[i] = int(pow(data[i] / 255.0, 9.0) * 255.0)
		img = Image.create_from_data(CAUSTIC_PX, CAUSTIC_PX, false, Image.FORMAT_L8, data)
		img.convert(Image.FORMAT_RGBA8)
		img.generate_mipmaps()
		_caustic = ImageTexture.create_from_image(img)
	return _caustic


# ------------------------------------------------------------------ dive spots

## Each dive spot of the zone: above the water, a darker patch where bubbles break the surface;
## under it, a dark hollow in the floor with bubbles rising from it.
static func _mark_spots(world_view: Node3D, region: Node, zone: Node3D) -> void:
	var under := DIVE.underwater(region)
	for s in world_view.get_tree().get_nodes_in_group(&"dive_spot"):
		var spot := s as Node2D
		if spot == null or not region.is_ancestor_of(spot):
			continue
		var r: Rect2 = spot.call(&"area")
		var c := r.get_center() / HeightMap.PX
		var size := r.size / HeightMap.PX
		var floor_y: float = world_view.get(&"heights").height(c)
		var y: float = (floor_y + 0.03) if under else maxf(HeightMap.WATER_LEVEL, floor_y) + 0.012
		var patch := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = size + Vector2.ONE
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = SPOT_DARK
		m.albedo_texture = WorldView._soft_dot()
		m.render_priority = 1   # over the water's sheet
		plane.material = m
		patch.mesh = plane
		patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		patch.position = Vector3(c.x, y, c.y)
		zone.add_child(patch)
		var bubbles := _make_bubbles(Quality.scaled(10 if not under else 16), 1.4 if not under else 3.0, 0.18 if not under else 0.12, false)
		bubbles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		bubbles.emission_box_extents = Vector3(size.x * 0.35, 0.0, size.y * 0.35)
		if not under:   # rings opening on the surface, not rising
			bubbles.initial_velocity_min = 0.02
			bubbles.initial_velocity_max = 0.08
			bubbles.gravity = Vector3.ZERO
			var grow := Curve.new()
			grow.add_point(Vector2(0.0, 0.4))
			grow.add_point(Vector2(1.0, 1.4))
			bubbles.scale_amount_curve = grow
		bubbles.position = Vector3(c.x, y + 0.02, c.y)
		zone.add_child(bubbles)
		bubbles.emitting = true
