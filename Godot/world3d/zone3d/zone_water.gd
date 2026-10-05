class_name ZoneWater
extends MeshInstance3D
## The water sheet of a 3D zone (docs/migration-3d.md, phase 4): one plane at the 2.5D's water
## level over the whole zone, painted by water.gdshader, which only shows where the ground is dug
## below it (the sea, the ponds). A remodelled zone has one per body of water of its relief, each at
## its own level and reading its own bed (build_at, from ZoneTerrain): its sea at 0 m, a pond higher up.
##
## Its job here is to keep the water tied to the sky. water.gdshader takes no light from the engine,
## so this script hands it, every time the light moves, the colour of the sky at this hour: taken
## from the real sun and moon of ZoneSky (their direction and their colour, so Sky3D's hours and the
## water agree), turned into a cartoon palette — pale blue at noon, orange and violet at dusk and
## dawn, deep indigo at night. The water mixes that sky into its own body and reflects it, so it is
## never black: at night it is the night sky, lit by the moon.

const SWELL_QUAD_M := 6.0      # metres per quad of the sheet (the swell needs some vertices)
## How far past the zone the sheet runs (m): the sea has to carry on well beyond the shore, or it
## stops short of the skyline and the sky's own ground colour shows as a dark band over it. Past
## the zone the sheet reads the edge of the relief, so it only goes on where the shore was already
## under water. (Sky3D's dark band is not gone for good — see docs/migration-3d.md, phase 5.)
const HORIZON_M := 260.0
## The sky of the hour, as the water sees it: zenith, horizon, the tint over the body of the water
## and the colour of its glitter. The three are blended by the sun's height; how bright it all is
## comes from the sun and the moon themselves (see below).
const DAY := {
	"zenith": Color(0.33, 0.60, 0.95), "horizon": Color(0.72, 0.88, 1.0),
	"body": Color(1.0, 1.0, 1.0), "glint": Color(1.0, 0.98, 0.9),
}
const GOLDEN := {   # the low sun: dusk and dawn
	"zenith": Color(0.45, 0.42, 0.72), "horizon": Color(1.0, 0.64, 0.40),
	"body": Color(1.0, 0.80, 0.70), "glint": Color(1.0, 0.82, 0.55),
}
const NIGHT := {
	"zenith": Color(0.04, 0.07, 0.17), "horizon": Color(0.12, 0.18, 0.34),
	"body": Color(0.30, 0.42, 0.72), "glint": Color(0.80, 0.86, 1.0),
}
## How bright the water is. Sky3D's sun burns at full energy as long as it is up, so the hour shows
## in how square it hits a flat surface (its height) and in the light the sky itself gives back;
## once it is down, the moon and a floor take over, so the water never goes black.
const SKY_AMBIENT := 0.24
const SUN_SHARE := 0.74
const NIGHT_FLOOR := 0.055
const MOON_SHARE := 0.15
## …and how bright the sky dome itself is, which is what the water mirrors: still ablaze at dusk,
## long after the sun has stopped reaching the ground.
const SKY_LEVEL_DAY := 1.0
const SKY_LEVEL_GOLDEN := 0.2
const SKY_LEVEL_NIGHT := 0.07
## Where the sun's height (its sine) puts us: full day above DAY_FROM, full night below NIGHT_FROM,
## the golden hour at its strongest around GOLDEN_AT and gone GOLDEN_SPAN away from it.
const DAY_FROM := 0.26
const NIGHT_FROM := -0.14
const GOLDEN_AT := 0.03
const GOLDEN_SPAN := 0.3
## How much of the sun's own colour (Sky3D's, which turns orange as it sets) the warm sky takes.
const SUN_COLOUR_SHARE := 0.45
## Below this height the sun no longer lights the water: the moon takes over the glint.
const SUN_GONE := -0.05
const CLOUDS_FAIR := 0.3
const CLOUDS_CLOSED := 0.8

## What the water reflects. SKY: the painted sky above, worked out here — costs nothing, but only
## the sky. MIRROR: the scene itself (the trees, the cliffs, Chloé), rendered a second time by a
## camera placed under the water and mirrored, into a small viewport the shader reads. The sky
## worked out here stays underneath it, both as the fallback and for the shade of the water's body.
enum Reflections { SKY, MIRROR }
## Which one a new zone uses. MIRROR: the real reflection is the one Greg kept (04/10). What had
## dulled it was never the mirror but the pass on the white caps, which faded the whole surface
## out with the distance — see fade_begin_m in water.gdshader. SKY stays the way back.
const DEFAULT_REFLECTIONS := Reflections.MIRROR
## The mirror's picture, as a share of the window's, and how far it sees (m: past that, the sky
## worked out here takes over). Drawing it at full size was tried on 04/10 and cost 1.7 ms on the
## sea and up to 12.5 ms by the pond, for no gain worth that: what made the water look smeared was
## the surface being flattened with the distance, not the size of this picture.
const MIRROR_SCALE := 0.3
const MIRROR_FAR_M := 55.0
## The mirror is redrawn one frame out of this many (2: every other frame). Water is never still,
## so a reflection one frame behind does not show, and it halves what the mirror costs.
const MIRROR_EVERY := 2
## Looking down on the water from high up, next to nothing is mirrored anyway (the surface hands
## back its own colour, not the sky): from this much of a dive to that one, the mirror fades out
## and stops being drawn at all. 0 is level with the water, 1 straight down.
const MIRROR_STEEP_FROM := 0.6
const MIRROR_STEEP_TO := 0.85
## How much of the mirror shows through in the end (1: all of it). Under 1 the painted sky still
## warms it, which keeps the water in the colours of the hour.
const MIRROR_SHARE := 0.65
## How far down the mirror is turned at the darkest hour (see mirror_gain in water.gdshader).
const MIRROR_GAIN_FLOOR := 0.25
## The layer the water sheet alone sits on, so the mirror's camera can leave it out (it must not
## film the very surface it is filling in). 1 to 20, and nothing else in the game uses it.
const WATER_ONLY_LAYER := 20
## Things the mirror leaves out: too small to be seen in the water, too dear to draw twice
## (the tall grass, the rain, the little plants). They carry this visual layer as well.
const NOT_IN_MIRROR_LAYER := 19

## How fast the mirror fades in or out when another sheet of the zone takes it over (share per second).
const MIRROR_HANDOVER := 2.0

var material: ShaderMaterial
## SKY or MIRROR; set it before build(), or with set_reflections() while the game runs.
var reflections: Reflections = DEFAULT_REFLECTIONS
## Whether this sheet may draw its mirror now. A zone with several sheets gives it to the one nearest
## the camera only (ZoneTerrain._process); the others show the painted sky.
var mirror_wanted := true
## The ground its water covers (m of the zone), to tell which sheet is nearest.
var area := Rect2()

var _sun: DirectionalLight3D
var _moon: DirectionalLight3D
var _last := Vector3(INF, INF, INF)   # the sun's direction when the palette was last set
var _mirror: SubViewport
var _mirror_camera: Camera3D
var _frame := 0
var _mirror_weight := 1.0   # eases to mirror_wanted


## Builds the sheet over `extent` metres from `origin` (m), at the 2.5D's water level, reading the bed
## of `source`.
func build(source: ZoneSource, origin: Vector2, extent: Vector2) -> void:
	build_at(source, origin, extent, HeightMap.WATER_LEVEL, source.heights.height_texture(), HORIZON_M)


## Builds the sheet at `level` (m) over `extent` metres from `origin` (m), running on `horizon` m past
## them, reading its bed from `bed` ({texture, origin (tiles), res (samples per tile), texels}, as
## HeightMap.height_texture gives it): it only shows where that bed lies below `level`.
func build_at(source: ZoneSource, origin: Vector2, extent: Vector2, level: float, bed: Dictionary, horizon: float) -> void:
	var sheet := extent + Vector2.ONE * horizon * 2.0
	var plane := PlaneMesh.new()
	plane.size = sheet
	plane.subdivide_width = maxi(int(sheet.x / SWELL_QUAD_M) - 1, 0)
	plane.subdivide_depth = maxi(int(sheet.y / SWELL_QUAD_M) - 1, 0)
	mesh = plane
	position = Vector3(origin.x + extent.x * 0.5, level, origin.y + extent.y * 0.5)
	area = Rect2(origin, extent)
	material = ShaderMaterial.new()
	material.shader = preload("res://world3d/zone3d/water.gdshader")
	material.set_shader_parameter("ground_height", bed["texture"])
	material.set_shader_parameter("height_origin", bed["origin"])
	material.set_shader_parameter("height_res", bed["res"])
	material.set_shader_parameter("height_texels", bed["texels"])
	material.set_shader_parameter("tile_m", source.scale)
	material.set_shader_parameter("water_level", level)
	material.set_shader_parameter("noise_tex", WorldNoise.texture())
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layers = 1 << (WATER_ONLY_LAYER - 1)   # so the mirror's camera can leave the sheet out
	# The sheet is flat and huge: its own box would cull it as soon as its centre leaves the view.
	custom_aabb = AABB(Vector3(-sheet.x * 0.5, -4.0, -sheet.y * 0.5), Vector3(sheet.x, 8.0, sheet.y))


func _ready() -> void:
	_find_lights()
	_follow_sky(true)
	set_reflections(reflections)


func _process(_delta: float) -> void:
	_follow_sky(false)
	_aim_mirror()


## Switches between the painted sky and the real mirror (Reflections). Takes effect at once.
func set_reflections(mode: Reflections) -> void:
	reflections = mode
	if material == null:
		return
	if mode == Reflections.MIRROR and _mirror == null:
		_build_mirror()
	if _mirror:
		_mirror.render_target_update_mode = SubViewport.UPDATE_DISABLED   # _aim_mirror asks for each frame it wants
	material.set_shader_parameter("mirror_mix", MIRROR_SHARE if mode == Reflections.MIRROR else 0.0)


func _mirror_size() -> Vector2i:
	var window := get_viewport().get_visible_rect().size
	return Vector2i(maxi(int(window.x * MIRROR_SCALE), 64), maxi(int(window.y * MIRROR_SCALE), 64))


## A viewport onto the same world, filmed from under the water by a mirrored camera.
func _build_mirror() -> void:
	_mirror = SubViewport.new()
	_mirror.name = "Mirror"
	_mirror.size = _mirror_size()
	_mirror.transparent_bg = false
	_mirror.msaa_3d = Viewport.MSAA_DISABLED
	_mirror.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	_mirror.use_debanding = false
	_mirror.positional_shadow_atlas_size = 0     # the sun's shadows are enough in a reflection
	_mirror_camera = Camera3D.new()
	_mirror_camera.name = "MirrorCamera"
	# Everything but the water sheet itself: it must not film the surface it is filling in.
	_mirror_camera.cull_mask = 0xFFFFF & ~(1 << (WATER_ONLY_LAYER - 1)) & ~(1 << (NOT_IN_MIRROR_LAYER - 1))
	_mirror_camera.far = MIRROR_FAR_M
	_mirror_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # it is aimed every drawn frame
	_mirror_camera.environment = _cheap_sky()
	_mirror_camera.attributes = get_viewport().find_world_3d().camera_attributes
	_mirror.add_child(_mirror_camera)
	add_child(_mirror)
	material.set_shader_parameter("mirror_tex", _mirror.get_texture())


## The world's own sky and colours for the mirror, but without what costs the most and shows the
## least in a reflection: ambient occlusion, bounced light, the glow. The sky itself is the same
## resource as the zone's, so Sky3D's hours and clouds keep showing in the water.
func _cheap_sky() -> Environment:
	var world := get_viewport().find_world_3d().environment
	if world == null:
		return null
	var cheap: Environment = world.duplicate()   # shallow: the Sky resource stays shared
	cheap.ssao_enabled = false
	cheap.ssil_enabled = false
	cheap.sdfgi_enabled = false
	cheap.glow_enabled = false
	cheap.volumetric_fog_enabled = false
	return cheap


## Puts the mirror's camera where the real one would stand if the water were a looking-glass: the
## same spot turned over about the water's level, looking the mirrored way. Turning a camera over
## reverses its handedness, which would hide every front face, so its sideways axis is turned round
## as well — the picture then comes out swapped left to right, and the shader reads it swapped back.
func _aim_mirror() -> void:
	if _mirror == null or reflections != Reflections.MIRROR:
		return
	var eye := get_viewport().get_camera_3d()
	if eye == null or eye == _mirror_camera:
		return
	var at := eye.global_transform
	var level := global_position.y
	var axis_x := Vector3(-at.basis.x.x, at.basis.x.y, -at.basis.x.z)   # mirrored, then turned round
	var axis_y := Vector3(at.basis.y.x, -at.basis.y.y, at.basis.y.z)
	var axis_z := Vector3(at.basis.z.x, -at.basis.z.y, at.basis.z.z)
	_mirror_camera.global_transform = Transform3D(Basis(axis_x, axis_y, axis_z),
		Vector3(at.origin.x, 2.0 * level - at.origin.y, at.origin.z))
	_mirror_camera.fov = eye.fov
	_mirror_camera.near = eye.near
	_mirror_camera.keep_aspect = eye.keep_aspect
	var want := _mirror_size()   # the window may have been resized: the mirror is read pixel for pixel
	if _mirror.size != want:
		_mirror.size = want
	# Straight down on the water there is nothing to mirror: fade it out and stop drawing it.
	var steep := clampf(at.basis.z.y, 0.0, 1.0)   # the camera looks along -Z, so +Z.y rises as it dives
	_mirror_weight = move_toward(_mirror_weight, 1.0 if mirror_wanted else 0.0, MIRROR_HANDOVER * get_process_delta_time())
	var share := MIRROR_SHARE * (1.0 - smoothstep(MIRROR_STEEP_FROM, MIRROR_STEEP_TO, steep)) * _mirror_weight
	material.set_shader_parameter("mirror_mix", share)
	_frame += 1
	if share > 0.001 and _frame % MIRROR_EVERY == 0:
		_mirror.render_target_update_mode = SubViewport.UPDATE_ONCE   # (it puts itself back to off)


## The sun and the moon of the zone's sky (ZoneSky), or any directional light of the scene.
func _find_lights() -> void:
	var node := get_parent()
	while node:
		var sky: Variant = node.get("sky")
		if sky is Node:
			_sun = (sky as Node).get("sun") as DirectionalLight3D
			_moon = (sky as Node).get("moon") as DirectionalLight3D
			if _sun:
				return
		node = node.get_parent()
	# No ZoneSky above us (a test scene): take the brightest directional light of the scene.
	for light in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
		if _sun == null or (light as DirectionalLight3D).light_energy > _sun.light_energy:
			_sun = light as DirectionalLight3D


## Hands the shader the sky of this hour, whenever the sun has moved enough to show.
func _follow_sky(force: bool) -> void:
	if _sun == null or material == null:
		return
	# A DirectionalLight3D shines along -Z, so +Z points at the sun; its y is the sine of its height.
	var to_sun := _sun.global_transform.basis.z
	if not force and to_sun.distance_squared_to(_last) < 0.000002:
		return
	_last = to_sun
	var up := to_sun.y
	var day := smoothstep(NIGHT_FROM, DAY_FROM, up)
	var golden := 1.0 - smoothstep(0.0, GOLDEN_SPAN, absf(up - GOLDEN_AT))
	var sky := _blend(NIGHT, DAY, day)
	sky = _blend(sky, _warmed(), golden)
	material.set_shader_parameter("sky_zenith", sky["zenith"])
	material.set_shader_parameter("sky_horizon", sky["horizon"])
	material.set_shader_parameter("body_tint", sky["body"])
	material.set_shader_parameter("glint_colour", sky["glint"])
	# What the water glitters with: the sun while it is up, the moon once it is gone.
	var glint_dir := to_sun
	var moon_up := 0.0
	if _moon:
		moon_up = _moon.global_transform.basis.z.y
		if up < SUN_GONE:
			glint_dir = _moon.global_transform.basis.z
	var by_day := SKY_AMBIENT + SUN_SHARE * clampf(up, 0.0, 1.0)
	var by_night := NIGHT_FLOOR + MOON_SHARE * clampf(moon_up, 0.0, 1.0)
	material.set_shader_parameter("light_level", lerpf(by_night, by_day, day))
	var sky_level := lerpf(lerpf(SKY_LEVEL_NIGHT, SKY_LEVEL_DAY, day), SKY_LEVEL_GOLDEN, golden)
	material.set_shader_parameter("sky_level", sky_level)
	# The mirror has been exposed once already; the darker the hour, the wider the window opens on
	# top of it, so it is turned down by about as much (see mirror_gain in water.gdshader).
	material.set_shader_parameter("mirror_gain", lerpf(MIRROR_GAIN_FLOOR, 1.0, sky_level))
	material.set_shader_parameter("sun_dir", glint_dir.normalized())
	material.set_shader_parameter("cloudiness", CLOUDS_CLOSED if Game.weather != &"clear" else CLOUDS_FAIR)


## The golden hour, tinted by the sun's own colour (Sky3D turns it orange as it sets).
func _warmed() -> Dictionary:
	var warm := GOLDEN.duplicate()
	var sun_colour: Color = _sun.light_color
	warm["horizon"] = (GOLDEN["horizon"] as Color).lerp(sun_colour, SUN_COLOUR_SHARE)
	warm["glint"] = (GOLDEN["glint"] as Color).lerp(sun_colour, SUN_COLOUR_SHARE)
	return warm


static func _blend(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	return {
		"zenith": (a["zenith"] as Color).lerp(b["zenith"], t),
		"horizon": (a["horizon"] as Color).lerp(b["horizon"], t),
		"body": (a["body"] as Color).lerp(b["body"], t),
		"glint": (a["glint"] as Color).lerp(b["glint"], t),
	}
