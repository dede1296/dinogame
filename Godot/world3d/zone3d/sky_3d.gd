class_name Sky3D
extends Node3D
## The sky and the sun of a 3D zone over the day (docs/migration-3d.md, phase 5): the game's own
## clock (Game.clock: 1 h of play = 60 s) and the 2.5D's light over the day (WorldView.DAYLIGHT:
## sun height and bearing, its colour and strength, the ambient light, the sky's colour), the
## weather dimming it as in the 2.5D (rain, storm, mist). Fog: far off, closer in the rain and the mist.

const FOG_BEGIN_M := 70.0
const FOG_END_M := 260.0

var sun: DirectionalLight3D
var env: Environment

var _sky: ProceduralSkyMaterial
var _rain := 0.0
var _mist := 0.0
var _storm := 0.0


func _ready() -> void:
	_sky = ProceduralSkyMaterial.new()
	_sky.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = _sky
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)
	_rain = 1.0 if Game.is_raining() else 0.0
	_mist = 1.0 if Game.weather == &"mist" else 0.0
	update_light(Game.clock / 60.0)


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-0.6 * delta)
	_rain = lerpf(_rain, 1.0 if Game.is_raining() else 0.0, blend)
	_mist = lerpf(_mist, 1.0 if Game.weather == &"mist" else 0.0, blend)
	_storm = lerpf(_storm, 1.0 if Game.weather == &"storm" else 0.0, blend)
	update_light(Game.clock / 60.0)


## The light at `hour` (0–24), between the two rows of WorldView.DAYLIGHT around it.
func update_light(hour: float) -> void:
	var rows := WorldView.DAYLIGHT
	var a: Array = rows[0]
	var b: Array = rows[1]
	for i in rows.size() - 1:
		if hour <= rows[i + 1][0]:
			a = rows[i]
			b = rows[i + 1]
			break
	var t := smoothstep(a[0], b[0], hour) if b[0] > a[0] else 0.0
	var gloom := 1.0 - 0.5 * _storm
	sun.rotation_degrees = Vector3(-lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), 0.0)
	sun.light_color = (a[3] as Color).lerp(b[3], t)
	sun.light_energy = lerpf(a[4], b[4], t) * (1.0 - 0.65 * _rain) * (1.0 - 0.4 * _mist) * gloom
	var sky := (a[7] as Color).lerp(b[7], t)
	var bright := clampf(sky.get_luminance() / 0.75, 0.15, 1.0)
	sky = sky.lerp(Color(0.55, 0.58, 0.62) * bright, _rain * 0.8).lerp(Color(0.82, 0.84, 0.86) * bright, _mist * 0.85) * gloom
	env.ambient_light_color = (a[5] as Color).lerp(b[5], t).lerp(Color(0.62, 0.65, 0.7) * bright, _rain * 0.5 + _mist * 0.4)
	env.ambient_light_energy = lerpf(a[6], b[6], t) * gloom
	_sky.sky_horizon_color = sky
	_sky.sky_top_color = sky * Color(0.62, 0.75, 1.0)
	_sky.ground_horizon_color = sky * 0.85
	_sky.ground_bottom_color = sky * 0.4
	env.fog_light_color = sky
	var closed := maxf(_rain, _mist)
	env.fog_depth_begin = lerpf(FOG_BEGIN_M, 12.0, closed)
	env.fog_depth_end = lerpf(FOG_END_M, 70.0, closed)
	RenderingServer.global_shader_parameter_set(&"sun_dir", sun.global_transform.basis.z.normalized())
	RenderingServer.global_shader_parameter_set(&"sun_light", clampf(sun.light_energy / 1.25, 0.0, 1.0))
