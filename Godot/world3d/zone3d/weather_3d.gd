class_name Weather3D
extends Node3D
## The weather you can SEE in a 3D zone (docs/migration-3d.md): ZoneSky already dims the light and closes
## the fog for rain, storm and mist; this node adds what falls and what floats —
## - rain: streaks round Chloé and rings where the drops land (WeatherRain), thicker in a storm;
## - storm: lightning that lights the scene up, with a bolt in the sky and its thunder (WeatherLightning);
## - mist: a veil of drifting banks hugging the ground (WeatherMist), a thin one in the rain too;
## - the ground and the grass darken a little when it rains (the terrain's grass tint).
## It reads the game's weather (Game.weather, Game.is_raining()) and eases in and out as ZoneSky does.
##   weather = Weather3D.new(); weather.name = "Weather"; add_child(weather); weather.build(self)
## (after the sky, the terrain and Chloé exist). It runs after ZoneSky each frame: the lightning adds to
## the light ZoneSky has just set.

const WEATHER_BLEND := 0.6              # per second: ZoneSky's own easing, so the two stay together
const RAIN_DENSITY := 0.55              # of the full downpour, in plain rain (a storm: 1)
const MIST_UNDER_RAIN := 0.0            # the ground mist a rain stirs up (share of a mist's): off — the veil is a full-screen pass, the one part of the weather that costs (0.3 ms at 720p), and rain needs it least
## The wind (it blows the rain and bends the grass): which way (towards +x, a little +z), how strong.
const WIND_DIR := Vector2(0.88, 0.47)
const WIND_RAIN_MS := 2.2
const WIND_STORM_MS := 6.0
const WET_GRASS := Color(0.74, 0.82, 0.86)
const PROCESS_AFTER_SKY := 100

var rain: WeatherRain
var mist: WeatherMist
var lightning: WeatherLightning
## Amounts now, 0–1 (eased).
var rain_amount := 0.0
var storm_amount := 0.0
var mist_amount := 0.0

var _zone: Zone3D
var _height_tex: ImageTexture
var _warm := 3   # frames of empty draws first: the pipelines are built while the zone loads


func build(zone: Zone3D) -> void:
	_zone = zone
	process_priority = PROCESS_AFTER_SKY
	rain_amount = 1.0 if Game.is_raining() else 0.0
	storm_amount = 1.0 if Game.weather == &"storm" else 0.0
	mist_amount = 1.0 if Game.weather == &"mist" else 0.0
	_height_tex = _ground_heights(zone)
	var span := _height_span(zone)
	rain = WeatherRain.new()
	rain.name = "Rain"
	add_child(rain)
	rain.build(_height_tex, WeatherCover.build(_zone.scatter, span[0], span[1]), span[0], span[1])
	mist = WeatherMist.new()
	mist.name = "Mist"
	add_child(mist)
	lightning = WeatherLightning.new()
	lightning.name = "Lightning"
	add_child(lightning)


## The wind now (m/s, x and z).
func wind() -> Vector2:
	return WIND_DIR * lerpf(lerpf(0.0, WIND_RAIN_MS, rain_amount), WIND_STORM_MS, storm_amount)


func _process(delta: float) -> void:
	if _zone == null or _zone.player == null or _zone.sky == null:
		return
	if _warm > 0:
		_warm -= 1
		rain.warm_up()
		mist.warm_up()
		lightning.warm_up(get_viewport().get_camera_3d())
		return
	var blend := 1.0 - exp(-WEATHER_BLEND * delta)
	rain_amount = lerpf(rain_amount, 1.0 if Game.is_raining() else 0.0, blend)
	storm_amount = lerpf(storm_amount, 1.0 if Game.weather == &"storm" else 0.0, blend)
	mist_amount = lerpf(mist_amount, 1.0 if Game.weather == &"mist" else 0.0, blend)
	var here := _zone.player.global_position
	var thickness := rain_amount * lerpf(RAIN_DENSITY, 1.0, storm_amount)
	rain.update(here, thickness, storm_amount, wind())
	var env := _zone.sky.env
	var veil := maxf(mist_amount, rain_amount * MIST_UNDER_RAIN)
	mist.update(veil, env.fog_light_color.lightened(0.15), _zone.terrain.height_at(here.x, here.z), _sun_dir(), delta)
	lightning.update(delta, storm_amount, env, get_viewport().get_camera_3d())
	_zone.terrain.material.set_shader_parameter("grass_tint", Color.WHITE.lerp(WET_GRASS, rain_amount))


func _sun_dir() -> Vector3:
	var sun := _zone.sky.sun
	return sun.global_transform.basis.z if sun else Vector3.UP


## The ground's height (or the water's surface: rain falls on the water, not the bed) on a one-metre
## grid over the whole zone and its margin — the same samples as the terrain — as one float texture.
## The water is the zone's own where it stands (ZoneTerrain.water_level_at: a remodelled zone's pond
## is 2.4 m up, its sea at 0), the 2.5D's one level elsewhere.
static func _ground_heights(zone: Zone3D) -> ImageTexture:
	var span := _height_span(zone)
	var origin: Vector2 = span[0]
	var size: Vector2 = span[1]
	var img := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RF)
	for z in int(size.y):
		for x in int(size.x):
			var px := origin.x + x
			var pz := origin.y + z
			img.set_pixel(x, z, Color(maxf(zone.terrain.height_at(px, pz), maxf(zone.terrain.water_level_at(px, pz), -1000.0)), 0.0, 0.0))
	return ImageTexture.create_from_image(img)


## [the corner (m), the size (m = texels)] of the height grid: the zone and its margin.
static func _height_span(zone: Zone3D) -> Array[Vector2]:
	var margin := zone.source.margin_m()
	var origin := Vector2(-margin, -margin)
	return [origin, zone.source.size_m() + Vector2.ONE * margin * 2.0 + Vector2.ONE]
