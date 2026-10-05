class_name ZoneSky
extends Node3D
## The sky, the sun and the moon of a 3D zone over the day (docs/migration-3d.md): the Sky3D plugin
## (an atmosphere that colours the sky and the far haze, clouds drifting, sun disc, a moon with its
## light, stars), set by the game's own clock (Game.clock: 1 h of play = 60 s) and weather (rain,
## storm, mist: thicker clouds, dimmer light, the fog closing in). Greg (04/10): the PC 3D takes the
## best there is, not the 2.5D's look — of the 2.5D, only the game: the hours and the weather.
## Sky3D's sun rises and sets in the game's dawn and dusk (Game.phase: dawn 5–7 h, dusk 18–20:30 h).
## Without the plugin: Godot's plain sky and one sun, coloured by the 2.5D's table (WorldView.DAYLIGHT).

const SKY3D := "res://addons/sky_3d/src/Sky3D.gd"
## Where and when Sky3D's sky is: its sun rises at 5:55 and sets at 19:45, a full moon up from
## 20 h to 5:45 (29° at midnight); the date stays (the game counts days, not months).
const PLACE := {"latitude": 40.0, "longitude": 4.0, "utc": 1.0, "year": 2025, "month": 8, "day": 9}
const SHADOW_M := 60.0
## Light to play by at night and in the low sun (Sky3D's own is true to life, too dark for the game):
## the moon's strength, the ambient light's share taken from the sky (day, night) and its strength
## once the sun is down (the rest of it a blue-grey night colour).
const MOON_ENERGY := 0.45
const SKY_SHARE_DAY := 0.85
const SKY_SHARE_NIGHT := 0.3
const AMBIENT_NIGHT := 1.0
## In fair weather, a far haze of the sky's own colour (aerial perspective): it hides where the
## distant scenery stops being drawn (Scatter3D's ranges), as the real air does. Metres.
const HAZE_BEGIN_M := 110.0
const HAZE_END_M := 330.0
const HAZE_SKY_SHARE := 0.9
## What Sky3D paints under the horizon (its own default is a grey that cuts against the sea).
const GROUND_UNDER_SKY := Color(0.17, 0.42, 0.56)
## The weather closing in (rain, mist: 0–1): clouds (cumulus cover, 0–1), the fog's depths (m).
const CLOUDS_FAIR := 0.45
const CLOUDS_OVERCAST := 0.92
const FOG_CLOSED_BEGIN_M := 12.0
const FOG_CLOSED_END_M := 70.0
const FOG_CLOSED := Color(0.62, 0.65, 0.7)
## With the PC renderer (Forward+, the PC 3D's: project.godot rendering_method.pc): which effects
## are on (see set_pc_effects). Tried 04/10: AgX and the volumetric fog dulled the cartoon colours
## (grey sky, drab grass) — off.
const PC_EFFECTS := {"ssao": true, "ssil": true, "glow": true, "auto_exposure": true}
## The eye getting used to the dark (auto exposure, Forward+): Sky3D's sensitivity floor (ISO: the
## higher, the less it brightens the dark — 100 turned the night to day, 300 too black; tried 04/10),
## its ceiling, how fast.
const AUTO_EXPOSURE_MIN := 170.0
const AUTO_EXPOSURE_MAX := 800.0
const AUTO_EXPOSURE_SPEED := 0.8
## …and the PC's finer picture: edges smoothed (MSAA ×4), sharper and softer shadows further out.
const PC_SHADOW_ATLAS := 4096
const PC_SHADOW_M := 90.0

var sun: DirectionalLight3D
var moon: DirectionalLight3D
var env: Environment

var _sky3d: Node                        # Sky3D (a WorldEnvironment)
var _plain_sky: ProceduralSkyMaterial   # without the plugin
var _rain := 0.0
var _mist := 0.0
var _storm := 0.0


func _ready() -> void:
	if ResourceLoader.exists(SKY3D):
		_build_sky3d()
	else:
		_build_plain()
	for light in [sun, moon]:
		if light:
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			light.directional_shadow_max_distance = SHADOW_M
	_rain = 1.0 if Game.is_raining() else 0.0
	_mist = 1.0 if Game.weather == &"mist" else 0.0
	env.fog_mode = Environment.FOG_MODE_DEPTH
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		set_pc_effects(PC_EFFECTS)
		_pc_picture()
	update_light(Game.clock / 60.0)


func _pc_picture() -> void:
	var view := get_viewport()
	view.msaa_3d = Viewport.MSAA_4X
	view.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	RenderingServer.directional_shadow_atlas_set_size(PC_SHADOW_ATLAS, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	for light in [sun, moon]:
		if light:
			light.directional_shadow_max_distance = PC_SHADOW_M


func _build_sky3d() -> void:
	_sky3d = load(SKY3D).new()
	_sky3d.name = "Sky3D"
	add_child(_sky3d)   # (it makes its environment, sun, moon, dome and clock on entering)
	env = _sky3d.environment
	sun = _sky3d.get("sun")
	moon = _sky3d.get("moon")
	var tod: Node = _sky3d.get("tod")
	tod.set("game_time_enabled", false)   # the game's clock drives it
	tod.set("editor_time_enabled", false)
	for key in PLACE:
		tod.set(key, deg_to_rad(PLACE[key]) if key in ["latitude", "longitude"] else PLACE[key])
	_sky3d.set("sky_contribution", SKY_SHARE_DAY)
	_sky3d.set("night_sky_contribution", SKY_SHARE_NIGHT)
	# Under the horizon, past the water, Sky3D paints its own ground: a dark band over the sea.
	# Given the sea's own colour, the two blend into each other.
	(_sky3d.get("sky") as Node).set("ground_color", GROUND_UNDER_SKY)


func _build_plain() -> void:
	_plain_sky = ProceduralSkyMaterial.new()
	_plain_sky.sun_angle_max = 20.0
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = _plain_sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	add_child(sun)


## The PC renderer's (Forward+) light effects, each on or off: ambient occlusion (ssao), indirect
## light (ssil, sdfgi), the sun's rays in the haze (volumetric), glow, the AgX colours, the eye
## getting used to the dark (auto_exposure). The Mobile renderer has none of them.
func set_pc_effects(on: Dictionary) -> void:
	env.ssao_enabled = on.get("ssao", false)
	env.ssao_radius = 1.4
	env.ssao_intensity = 1.6
	env.ssil_enabled = on.get("ssil", false)
	env.sdfgi_enabled = on.get("sdfgi", false)
	env.sdfgi_use_occlusion = true
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.25
	env.glow_enabled = on.get("glow", false)
	env.glow_intensity = 0.5
	env.glow_bloom = 0.04
	env.volumetric_fog_enabled = on.get("volumetric", false)
	env.volumetric_fog_density = 0.006
	env.volumetric_fog_albedo = Color(0.96, 0.92, 0.84)
	env.volumetric_fog_length = 90.0
	sun.light_volumetric_fog_energy = 1.4
	if on.has("agx"):
		env.tonemap_mode = Environment.TONE_MAPPER_AGX if on.agx else Environment.TONE_MAPPER_FILMIC
	if _sky3d:
		_sky3d.set("auto_exposure", on.get("auto_exposure", false))
		_sky3d.set("auto_exposure_min", AUTO_EXPOSURE_MIN)
		_sky3d.set("auto_exposure_max", AUTO_EXPOSURE_MAX)
		_sky3d.set("auto_exposure_speed", AUTO_EXPOSURE_SPEED)
	var splits := DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if on.get("ssao", false) else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	for light in [sun, moon]:
		if light:
			light.directional_shadow_mode = splits


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-0.6 * delta)
	_rain = lerpf(_rain, 1.0 if Game.is_raining() else 0.0, blend)
	_mist = lerpf(_mist, 1.0 if Game.weather == &"mist" else 0.0, blend)
	_storm = lerpf(_storm, 1.0 if Game.weather == &"storm" else 0.0, blend)
	update_light(Game.clock / 60.0)


## The sky at `hour` (0–24) and in the weather of the moment.
func update_light(hour: float) -> void:
	var closed := maxf(_rain, _mist)
	var dim := (1.0 - 0.65 * _rain) * (1.0 - 0.4 * _mist) * (1.0 - 0.5 * _storm)
	if _sky3d:
		_update_sky3d(hour, closed, dim)
	else:
		_update_plain(hour, dim)
	# Fair weather: a far haze of the sky's colour. Closing in (rain, mist): a grey fog, near,
	# that hides the sky too.
	if _sky3d:
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_aerial_perspective = HAZE_SKY_SHARE
		env.fog_light_color = FOG_CLOSED * clampf(dim + 0.3, 0.3, 1.0)
		env.fog_depth_begin = lerpf(HAZE_BEGIN_M, FOG_CLOSED_BEGIN_M, closed)
		env.fog_depth_end = lerpf(HAZE_END_M, FOG_CLOSED_END_M, closed)
		env.fog_depth_curve = 1.4
		env.fog_sky_affect = 0.85 * closed


func _update_sky3d(hour: float, closed: float, dim: float) -> void:
	var tod: Node = _sky3d.get("tod")
	if absf(float(tod.get("current_time")) - hour) > 0.0005:
		tod.set("current_time", hour)
	if absf(float(_sky3d.get("sun_energy")) - dim) > 0.002:
		_sky3d.set("sun_energy", dim)
		_sky3d.set("moon_energy", MOON_ENERGY * dim)
	# More ambient light as the sun goes down (0 by day, 1 once it is ~10° under the horizon).
	var low := clampf((0.2 - sun.global_transform.basis.z.y) / 0.37, 0.0, 1.0)
	env.ambient_light_energy = lerpf(1.0, AMBIENT_NIGHT, low)   # (not Sky3D's setter: it restarts a tween)
	var dome: Node = _sky3d.get("sky")
	var cover := lerpf(CLOUDS_FAIR, CLOUDS_OVERCAST, maxf(closed, _storm))
	if absf(float(dome.get("cumulus_coverage")) - cover) > 0.005:
		dome.set("cumulus_coverage", cover)


## Without Sky3D: the 2.5D's light over the day (WorldView.DAYLIGHT), between its two rows around `hour`.
func _update_plain(hour: float, dim: float) -> void:
	var rows := WorldView.DAYLIGHT
	var a: Array = rows[0]
	var b: Array = rows[1]
	for i in rows.size() - 1:
		if hour <= rows[i + 1][0]:
			a = rows[i]
			b = rows[i + 1]
			break
	var t := smoothstep(a[0], b[0], hour) if b[0] > a[0] else 0.0
	sun.rotation_degrees = Vector3(-lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), 0.0)
	sun.light_color = (a[3] as Color).lerp(b[3], t)
	sun.light_energy = lerpf(a[4], b[4], t) * dim
	var sky := (a[7] as Color).lerp(b[7], t) * clampf(dim + 0.3, 0.3, 1.0)
	_plain_sky.sky_horizon_color = sky
	_plain_sky.sky_top_color = sky * Color(0.62, 0.75, 1.0)
	_plain_sky.ground_horizon_color = sky * 0.85
	_plain_sky.ground_bottom_color = sky * 0.4
	env.ambient_light_color = (a[5] as Color).lerp(b[5], t)
	env.ambient_light_energy = lerpf(a[6], b[6], t)
	env.fog_light_color = sky
	env.fog_depth_begin = 70.0
	env.fog_depth_end = 260.0
