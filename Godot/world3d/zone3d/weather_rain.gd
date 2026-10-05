class_name WeatherRain
extends Node3D
## The rain you can see, in the 3D zone (docs/migration-3d.md): streaks falling around Chloé and rings
## spreading where the drops land. Two MultiMeshes (a fixed number of instances, never a node per
## drop), every position computed by their shaders (weather_rain.gdshader, weather_splash.gdshader)
## from the zone's height map, so the rain reaches the real ground, slopes and ponds included.
## The CPU only says where Chloé is, how thick the rain is and which way the wind blows.

const STREAK_SHADER := preload("res://world3d/zone3d/weather_rain.gdshader")
const SPLASH_SHADER := preload("res://world3d/zone3d/weather_splash.gdshader")
const MAX_STREAKS := 1800           # at full density, before the quality profile
const MAX_SPLASHES := 360
const STREAK_BOX_M := 30.0          # the box of falling rain round Chloé (m)
const SPLASH_BOX_M := 22.0
const DROP_HEIGHT_M := 11.0
const RAIN_SPEED := 13.0            # m/s
const STORM_SPEED := 17.0
const STREAK_COLOR := Color(0.86, 0.93, 1.0, 0.8)

var _streak_mat: ShaderMaterial
var _splash_mat: ShaderMaterial
var _streaks: MultiMeshInstance3D
var _splashes: MultiMeshInstance3D


## `height_tex`: one texel per metre (R: height of the ground or the water), the first at `origin`.
func build(height_tex: Texture2D, cover_tex: Texture2D, origin: Vector2, size: Vector2) -> void:
	_streak_mat = _material(STREAK_SHADER, height_tex, cover_tex, origin, size)
	_streak_mat.set_shader_parameter("box", STREAK_BOX_M)
	_streak_mat.set_shader_parameter("drop_height", DROP_HEIGHT_M)
	_splash_mat = _material(SPLASH_SHADER, height_tex, cover_tex, origin, size)
	_splash_mat.set_shader_parameter("box", SPLASH_BOX_M)
	_streaks = _instances(_streak_quad(), Quality.scaled(MAX_STREAKS), _streak_mat, 11)
	_splashes = _instances(_splash_quad(), Quality.scaled(MAX_SPLASHES), _splash_mat, 23)
	_splash_mat.render_priority = 1
	visible = false


## Each frame: the middle of the box (Chloé), the rain's thickness (0: none, 1: a storm's downpour,
## `storm` 0–1 makes it fall faster and slantier), the wind (m/s, which way it carries the drops).
func update(center: Vector3, density: float, storm: float, wind: Vector2) -> void:
	visible = density > 0.01
	if not visible:
		return
	var speed := lerpf(RAIN_SPEED, STORM_SPEED, storm)
	for mat in [_streak_mat, _splash_mat]:
		mat.set_shader_parameter("center", center)
		mat.set_shader_parameter("density", density)
	_streak_mat.set_shader_parameter("fall_speed", speed)
	_streak_mat.set_shader_parameter("wind", wind)
	_streak_mat.set_shader_parameter("streak_length", lerpf(0.85, 1.15, storm))
	_streak_mat.set_shader_parameter("color", Color(STREAK_COLOR.r, STREAK_COLOR.g, STREAK_COLOR.b, STREAK_COLOR.a + 0.12 * storm))
	_splash_mat.set_shader_parameter("ring_size", lerpf(0.65, 0.8, storm))


## How many streaks and splashes are in the pool (for the tests).
func pool() -> Vector2i:
	return Vector2i(_streaks.multimesh.instance_count, _splashes.multimesh.instance_count)


func _material(shader: Shader, height_tex: Texture2D, cover_tex: Texture2D, origin: Vector2, size: Vector2) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("height_tex", height_tex)
	mat.set_shader_parameter("cover_tex", cover_tex)
	mat.set_shader_parameter("height_origin", origin)
	mat.set_shader_parameter("height_size", size)
	return mat


## A pool of identical instances (identity transforms: the shader places them) each with its own
## random numbers in the custom data; the last one is its rank, so a thinner rain is just its first.
func _instances(mesh: Mesh, count: int, mat: Material, seed_value: int) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = count
	var buffer := PackedFloat32Array()
	buffer.resize(count * 16)
	for i in count:
		var o := i * 16
		buffer[o] = 1.0
		buffer[o + 5] = 1.0
		buffer[o + 10] = 1.0
		buffer[o + 12] = rng.randf()
		buffer[o + 13] = rng.randf()
		buffer[o + 14] = rng.randf()
		buffer[o + 15] = (i + 0.5) / count   # (the rank: in order, so that the first drops are always there)
	mm.buffer = buffer
	mm.custom_aabb = AABB(Vector3(-4000, -4000, -4000), Vector3(8000, 8000, 8000))   # (placed by the shader)
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.extra_cull_margin = 16384.0
	inst.layers = 1 | (1 << (ZoneWater.NOT_IN_MIRROR_LAYER - 1))   # left out of the water's mirror
	add_child(inst)
	return inst


## A quad one metre long standing from its head (y = 0) up its tail (y = 1), one wide.
func _streak_quad() -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0), Vector3(-0.5, 1, 0), Vector3(0.5, 1, 0)])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 1, 3, 2])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _splash_quad() -> PlaneMesh:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	return plane


## Draws the streaks and rings once with nothing alive, so that the video driver builds their
## pipelines now, while the zone loads, not in a hitch the first time it rains.
func warm_up() -> void:
	visible = true
	_streak_mat.set_shader_parameter("density", 0.0)
	_splash_mat.set_shader_parameter("density", 0.0)
