class_name WildlifeLooks
extends RefCounted
## How Wildlife's animals and effects look (their kinds: WildlifeDB): an animal's picture
## (standing on the ground, or facing the camera in the air), a swarm's cloud of specks, the
## particles of an effect (fireflies, plankton, glow-worms, drops, snow, embers…), a splash.

const DB := preload("res://data/wildlife_db.gd")
## Standing pictures are stretched like WorldView's (the camera looks down on them).
const STRETCH := 1.15
const STANDING: Array[StringName] = [&"walk", &"hop"]
const SPLASH := Color(0.9, 0.97, 1.0)
const SWARM_LIFE := 1.4
const SWARM_DARK := Color(0.1, 0.08, 0.07)
const CONTACT := preload("res://world/view3d/contact_shadow.gdshader")
const SHADOW_STRENGTH := 0.6

static var _shadow_mesh: PlaneMesh


## A kind's picture: its own (WildlifeDB.picture), or, for tests (command line
## « faune_essai=1 »), a stand-in while it is not drawn yet; null: none.
static func texture(kind: Dictionary) -> Texture2D:
	var pic := DB.picture(kind)
	if pic == null and "faune_essai=1" in OS.get_cmdline_user_args():
		return stand_in(kind)
	return pic


## A coloured block per cell, its head (black) to the right, a white mark moving cell by cell.
static func stand_in(kind: Dictionary) -> Texture2D:
	var n := maxi(1, int(kind["frames"]))
	var img := Image.create_empty(96 * n, 96, false, Image.FORMAT_RGBA8)
	var colour := Color.from_hsv(float(hash(kind["id"]) % 360) / 360.0, 0.75, 0.95)
	for f in n:
		img.fill_rect(Rect2i(f * 96 + 8, 34, 70, 50), colour)
		img.fill_rect(Rect2i(f * 96 + 74, 40, 18, 18), Color.BLACK)
		img.fill_rect(Rect2i(f * 96 + 12 + f * 14, 12, 12, 16), Color.WHITE)
	return ImageTexture.create_from_image(img)


## An animal's picture, `width` m across a cell: the walkers stand on the ground like the
## characters, the rest face the camera; lit like the scene, or from within (`glow`).
static func picture(kind: Dictionary, pic: Texture2D, frames: int) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = pic
	s.hframes = frames
	var cell := Vector2(pic.get_width() / float(frames), pic.get_height())
	s.pixel_size = float(kind["width"]) / cell.x
	if kind["motion"] in STANDING:
		s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		s.offset = Vector2(0, cell.y * 0.5)   # its feet on the ground
		s.scale = Vector3(1, STRETCH, 1)
		s.add_child(shadow(kind))
	else:
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = not kind.has("glow")
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tints: Array = kind.get("tints", [Color.WHITE])
	s.modulate = (tints.pick_random() as Color) * (kind.get("glow", Color.WHITE) as Color)
	return s


## A soft dark patch under a walker, like the characters' (WorldView's contact shadows): it stands
## out from the ground it is the colour of. (Its picture's child: shown and hidden with it.)
static func shadow(kind: Dictionary) -> MeshInstance3D:
	if _shadow_mesh == null:
		_shadow_mesh = PlaneMesh.new()
		_shadow_mesh.size = Vector2.ONE
		var mat := ShaderMaterial.new()
		mat.shader = CONTACT
		mat.set_shader_parameter(&"strength", SHADOW_STRENGTH)
		_shadow_mesh.material = mat
	var m := MeshInstance3D.new()
	m.mesh = _shadow_mesh
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var w: float = kind["width"]
	m.scale = Vector3(w * 0.85, 1.0, w * 0.45)
	m.position.y = 0.02
	return m


## A cloud of tiny flyers kept round its middle, which drifts (a swarm of mosquitoes): their
## picture's cells turned through, or dark specks while it is not there.
static func swarm(kind: Dictionary, pic: Texture2D) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = int(kind.get("specks", 12))
	p.lifetime = SWARM_LIFE
	p.preprocess = SWARM_LIFE
	p.local_coords = false
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.3
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.gravity = Vector3.ZERO
	p.radial_accel_min = -2.6   # (towards its middle)
	p.radial_accel_max = -1.6
	p.color_ramp = fade(Color.WHITE, 0.15)
	var width: float = kind["width"]
	var q := QuadMesh.new()
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if pic:
		var frames := maxi(1, int(kind["frames"]))
		q.size = Vector2(width, width * pic.get_height() * frames / pic.get_width())
		m.albedo_texture = pic
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.particles_anim_h_frames = frames
		m.particles_anim_v_frames = 1
		m.particles_anim_loop = true
		p.anim_speed_min = float(kind["fps"]) * SWARM_LIFE / frames
		p.anim_speed_max = p.anim_speed_min
	else:
		q.size = Vector2(width, width) * 0.7
		m.albedo_texture = WorldView._soft_dot()
		m.albedo_color = SWARM_DARK
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	p.mesh = q
	return p


## The particles of an effect (WildlifeDB.EFFECTS), not emitting yet.
static func effect(def: Dictionary) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var life: float = def["life"]
	p.amount = Quality.scaled(int(def["amount"]))
	p.lifetime = life
	p.preprocess = life
	p.local_coords = false
	p.emitting = false
	if def["emit"] == &"box":
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = def["box"]
	else:   # points given by Wildlife (on the water, on the walls)
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	p.direction = def.get("dir", Vector3.UP)
	p.spread = def.get("spread", 180.0)
	var speed: Array = def["speed"]
	p.initial_velocity_min = speed[0]
	p.initial_velocity_max = speed[1]
	p.gravity = Vector3(0, float(def.get("gravity", 0.0)), 0)
	var colour: Color = def["colour"]
	p.color_ramp = blink(colour) if def.get("blink", false) else fade(colour, 0.15)
	var size: float = def["size"]
	var q := QuadMesh.new()
	q.size = Vector2(size, size * float(def.get("drop", 1.0)))
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if def.get("glow", false):
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = WorldView._soft_dot()
	q.material = m
	p.mesh = q
	return p


## Droplets thrown up where a fish or a frog goes into the water (restart() it there).
static func splash() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 12
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = false
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 35.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.0
	p.gravity = Vector3(0, -9.8, 0)
	p.color_ramp = fade(SPLASH, 0.05)
	p.mesh = WorldView._speck(0.05)
	return p


## Lights blinking on and off (fireflies, plankton, embers).
static func blink(colour: Color) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.12, 0.25, 0.4, 0.55, 0.7, 0.85, 1.0])
	var off := Color(colour, 0.0)
	g.colors = PackedColorArray([off, colour, off, off, colour, colour, off, off])
	return g


## Fading in, staying, fading out (`edge`: the part of its life each fade takes).
static func fade(colour: Color, edge: float) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, edge, 1.0 - edge, 1.0])
	g.colors = PackedColorArray([Color(colour, 0.0), colour, colour, Color(colour, 0.0)])
	return g
