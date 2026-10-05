class_name WeatherLightning
extends Node3D
## The lightning of a storm (as the 2.5D's, world_view.gd _lightning, but you see it): every so often
## (6–16 s) a flash — the whole scene lit blue-white for a moment, a second weaker flicker just after —
## with a jagged bolt in the sky far off, and its thunder a moment later (further: later, softer).
## The flash is a shadowless light plus a boost of the environment's ambient light and fog colour,
## added AFTER ZoneSky has set them for the frame (so Weather3D must be processed after the sky).

const BOLT_SHADER := preload("res://world3d/zone3d/weather_bolt.gdshader")
const THUNDER: Array[AudioStream] = [preload("res://assets/audio/ambience/tonnerre-1.mp3"), preload("res://assets/audio/ambience/tonnerre-2.mp3")]
const EVERY_S := Vector2(6.0, 16.0)
const FIRST_S := Vector2(2.0, 5.0)         # the first one after the storm breaks
const FLASH_FALL := 3.5                    # per second
const FLICKER_AFTER_S := 0.12
const LIGHT_ENERGY := 1.7
const LIGHT_COLOR := Color(0.82, 0.88, 1.0)
const AMBIENT_FLASH := 1.6
const FOG_FLASH := Color(0.78, 0.84, 1.0)
const BOLT_DIST_M := Vector2(70.0, 130.0)
const BOLT_SEGMENTS := 16
const BOLT_WIDTH_M := 2.0
const HALO_WIDTH := 3.2                    # times the core's
const THUNDER_DELAY_S := Vector2(0.4, 2.8)
const THUNDER_DB := Vector2(-3.0, -10.0)

## 1 at the flash, fading.
var flash := 0.0
## How many bolts have struck (for the tests).
var strikes := 0

var _light: DirectionalLight3D
var _bolt: MeshInstance3D
var _bolt_mat: ShaderMaterial
var _next_s := randf_range(FIRST_S.x, FIRST_S.y)


func _ready() -> void:
	_light = DirectionalLight3D.new()
	_light.name = "Flash"
	_light.light_color = LIGHT_COLOR
	_light.light_energy = 0.0
	_light.shadow_enabled = false
	_light.visible = false
	add_child(_light)
	_bolt_mat = ShaderMaterial.new()
	_bolt_mat.shader = BOLT_SHADER
	_bolt = MeshInstance3D.new()
	_bolt.name = "Bolt"
	_bolt.material_override = _bolt_mat
	_bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bolt.extra_cull_margin = 1000.0
	_bolt.top_level = true
	_bolt.visible = false
	add_child(_bolt)


## Each frame. `storm` 0–1 (a bolt can strike while it is above one half), the environment to light,
## where the camera is and which way it looks.
func update(delta: float, storm: float, env: Environment, camera: Camera3D) -> void:
	flash = maxf(0.0, flash - delta * FLASH_FALL)
	if storm > 0.5 and camera:
		_next_s -= delta
		if _next_s <= 0.0:
			strike(camera)
	elif storm < 0.2:
		_next_s = maxf(_next_s, FIRST_S.x)
	_light.visible = flash > 0.01
	_light.light_energy = flash * LIGHT_ENERGY
	_bolt.visible = flash > 0.12
	_bolt_mat.set_shader_parameter("intensity", clampf(flash * 1.3, 0.0, 1.5))
	if flash > 0.01:
		env.ambient_light_energy += flash * AMBIENT_FLASH
		if env.fog_enabled:
			env.fog_light_color = env.fog_light_color.lerp(FOG_FLASH, flash * 0.55)


## A bolt now: the flash, its second flicker, the bolt in the sky ahead of the camera, the thunder.
func strike(camera: Camera3D) -> void:
	strikes += 1
	_next_s = randf_range(EVERY_S.x, EVERY_S.y)
	flash = 1.0
	get_tree().create_timer(FLICKER_AFTER_S).timeout.connect(_flicker)
	var cam_pos := camera.global_position
	var ahead := -camera.global_basis.z
	ahead.y = 0.0
	ahead = ahead.normalized() if ahead.length() > 0.01 else Vector3.FORWARD
	var distance := randf_range(BOLT_DIST_M.x, BOLT_DIST_M.y)
	var dir := ahead.rotated(Vector3.UP, randf_range(-0.7, 0.7))
	var foot := cam_pos + dir * distance
	foot.y = cam_pos.y - 4.0
	var top := foot + Vector3(randf_range(-12.0, 12.0), randf_range(45.0, 70.0), randf_range(-12.0, 12.0))
	_bolt.global_transform = Transform3D.IDENTITY
	_bolt.mesh = _bolt_mesh(top, foot, cam_pos)
	_light.look_at_from_position(Vector3.ZERO, -dir * 0.55 + Vector3.DOWN * 0.85, Vector3.UP)
	var far := inverse_lerp(BOLT_DIST_M.x, BOLT_DIST_M.y, distance)
	get_tree().create_timer(lerpf(THUNDER_DELAY_S.x, THUNDER_DELAY_S.y, far)).timeout.connect(_thunder.bind(far))


func _flicker() -> void:
	flash = maxf(flash, 0.6)


func _thunder(far: float) -> void:
	Audio.play_sfx(THUNDER[0 if far > 0.5 else 1], lerpf(THUNDER_DB.x, THUNDER_DB.y, far), 0.08)


## The bolt: a jagged line from the cloud to the ground, with a branch or two, as ribbons facing the camera.
func _bolt_mesh(top: Vector3, foot: Vector3, cam_pos: Vector3) -> ArrayMesh:
	var main := PackedVector3Array()
	var side := Vector3.ZERO
	for i in BOLT_SEGMENTS + 1:
		var t := float(i) / BOLT_SEGMENTS
		side += Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * 11.0 * (1.0 - t * 0.5)
		side *= 0.65
		main.append(top.lerp(foot, t) + (side if i > 0 and i < BOLT_SEGMENTS else Vector3.ZERO))
	var mesh := ArrayMesh.new()
	var lines: Array[PackedVector3Array] = [main]
	for b in 2:
		var from := 3 + randi() % (BOLT_SEGMENTS - 8)
		var branch := PackedVector3Array([main[from]])
		var heading := (foot - top).normalized() + Vector3(randf_range(-0.8, 0.8), 0.0, randf_range(-0.8, 0.8))
		for k in 5:
			branch.append(branch[k] + (heading.normalized() + Vector3(randf_range(-0.4, 0.4), 0.0, randf_range(-0.4, 0.4))) * 9.0)
		lines.append(branch)
	for line in lines:
		var width := BOLT_WIDTH_M * (1.0 if line == main else 0.45)
		_add_ribbon(mesh, line, width * HALO_WIDTH, Color(0.62, 0.76, 1.0, 0.3), cam_pos)
		_add_ribbon(mesh, line, width, Color(1.0, 1.0, 1.0, 1.0), cam_pos)
	return mesh


func _add_ribbon(mesh: ArrayMesh, line: PackedVector3Array, width: float, color: Color, cam_pos: Vector3) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	surface.set_color(color)
	for i in line.size():
		var along := (line[mini(i + 1, line.size() - 1)] - line[maxi(i - 1, 0)]).normalized()
		var across := along.cross(cam_pos - line[i]).normalized() * width * 0.5 * (1.0 - 0.5 * float(i) / line.size())
		surface.set_uv(Vector2(0.0, 0.0))
		surface.add_vertex(line[i] - across)
		surface.set_uv(Vector2(1.0, 0.0))
		surface.add_vertex(line[i] + across)
	surface.commit(mesh)


## One invisible bolt drawn ahead of the camera (see WeatherRain.warm_up): the pipeline is built now.
func warm_up(camera: Camera3D) -> void:
	if camera == null:
		return
	var ahead := camera.global_position - camera.global_basis.z * 6.0
	_bolt.global_transform = Transform3D.IDENTITY
	_bolt.mesh = _bolt_mesh(ahead + Vector3.UP * 3.0, ahead - Vector3.UP * 1.0, camera.global_position)
	_bolt_mat.set_shader_parameter("intensity", 0.0)
	_bolt.visible = true
