class_name WeatherMist
extends MeshInstance3D
## The veil of the mist (weather_mist.gdshader): one quad over the whole screen that is a ground-hugging
## mist in drifting banks, between the camera and what it sees. The grey fog of the environment
## (ZoneSky) closes the distance; this one gives the mist its body near the ground.

const SHADER := preload("res://world3d/zone3d/weather_mist.gdshader")
const NOISE_PX := 256
const SMOOTH := 2.0      # how fast the mist's base follows the ground under Chloé (per second)

var _mat: ShaderMaterial
var _ground := 0.0
var _started := false


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	mesh = quad
	extra_cull_margin = 16384.0   # (it covers the screen whatever its node says)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.seed = 4
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = NOISE_PX
	tex.height = NOISE_PX
	tex.seamless = true
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("noise_tex", tex)
	_mat.render_priority = 50   # after the water and the rain: it veils them too
	material_override = _mat
	visible = false


## Each frame: how thick it is (0–1), its colour (the fog's), the ground under Chloé (m), the sun's direction.
func update(amount: float, color: Color, ground_y: float, sun_dir: Vector3, delta: float) -> void:
	visible = amount > 0.01
	if not visible:
		_started = false
		return
	_ground = ground_y if not _started else lerpf(_ground, ground_y, 1.0 - exp(-SMOOTH * delta))
	_started = true
	_mat.set_shader_parameter("amount", amount)
	_mat.set_shader_parameter("mist_color", color)
	_mat.set_shader_parameter("ground_y", _ground)
	_mat.set_shader_parameter("sun_dir", sun_dir)


## One empty draw (see WeatherRain.warm_up).
func warm_up() -> void:
	visible = true
	_mat.set_shader_parameter("amount", 0.0)
