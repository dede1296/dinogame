extends RefCounted
## How Wildlife3D's animals and lights look (their kinds: WildlifeDB). The animals are the 2.5D's
## painted pictures (assets/art/fauna: one row of cells drawn facing right, clean cut-outs), on quads
## drawn in batches — one MultiMesh per kind (wildlife_3d.gdshader):
## - card: a side-on picture standing up, turned to the camera and a little towards where it goes
##   (the walkers, the dragonflies, the fish leaping…), its feet on the ground if it walks;
## - file: the same, a file of them following one another (the ants);
## - facing: a picture facing the camera (a leaf falling and turning over; flat once down);
## - wings: the butterfly, flat, its two wings beating about its body, drawn by the shader (the 2.5D's
##   picture is only a white shape of two discs, to tint);
## - speck: a swarm's specks (mosquitoes), moved and turned to the camera by the shader alone.
## The lights (fireflies, plankton, embers…) are particles, as the 2.5D's, in a wider box.

const SHADER := preload("res://world3d/zone3d/wildlife_3d.gdshader")
const STANDING: Array[StringName] = [&"walk", &"hop"]
## Lit from within this much (WildlifeDB "glow": the butterflies' bright wings, the beasts of the night).
const GLOW := 0.45
## A swarm's specks: darker than their picture (its pale wings), so the cloud reads against the woods.
const SPECK_TINT := Color(0.45, 0.4, 0.4)
const MAX_SWARMS := 16          # (wildlife_3d.gdshader: swarms[16])
const SWARM_CLOUD_M := 0.35
const SWARM_DARK := Color(0.1, 0.08, 0.07)
const SPLASH := Color(0.9, 0.97, 1.0)
## The lights' box is this much wider each way than the 2.5D's (the 3D sees farther round Chloé),
## with as many more lights: the same number per square metre.
const EFFECT_SPREAD := 1.5
## The lights (fireflies, plankton, embers) this much bigger: seen from farther than in the 2.5D.
const LIGHT_SIZE := 1.5

static var _dot: Texture2D


## How a kind is drawn: card, file, facing, wings or speck.
static func look_of(kind: Dictionary) -> StringName:
	if kind.has("file"):
		return &"file"
	match kind["motion"]:
		&"swarm":
			return &"speck"
		&"fall":
			return &"facing"
		&"flutter":
			if int(kind.get("frames", 1)) == 1 and kind.has("flap"):
				return &"wings"
	return &"card"


## One batch: `count` instances of the kind's picture (`pic`; a swarm without one: dark specks),
## `per` instances each (a swarm's specks, set here once: the shader moves them).
static func batch(kind: Dictionary, pic: Texture2D, look: StringName, count: int, per := 1) -> MultiMeshInstance3D:
	var frames := maxi(1, int(kind["frames"]))
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter(&"frames", float(frames))
	mat.set_shader_parameter(&"glow", GLOW if kind.has("glow") and look != &"wings" else 0.0)
	var aspect := 1.0
	if pic:
		mat.set_shader_parameter(&"tex", pic)
		aspect = pic.get_height() * frames / float(pic.get_width())
	else:
		mat.set_shader_parameter(&"tex", dot())
		mat.set_shader_parameter(&"frames", 1.0)
	var mesh: Mesh
	match look:
		&"wings":
			mat.set_shader_parameter(&"wings", true)   # (its wings drawn by the shader, in its tint)
			mesh = wings_mesh(aspect)
		&"speck":
			mat.set_shader_parameter(&"swarm", true)
			mat.set_shader_parameter(&"cloud", SWARM_CLOUD_M)
			mat.set_shader_parameter(&"fps", float(kind.get("fps", 24.0)) if pic else 0.0)
			mesh = quad(aspect, false)
		_:
			mesh = quad(aspect, kind["motion"] in STANDING)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = count * per
	if look == &"speck":
		var tint := SPECK_TINT if pic else SWARM_DARK
		for i in mm.instance_count:
			mm.set_instance_transform(i, Transform3D.IDENTITY)
			mm.set_instance_color(i, tint)
			@warning_ignore("integer_division")
			mm.set_instance_custom_data(i, Color(float(i / per), randf(), randf(), randf()))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if look == &"speck" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	inst.layers = 1 | (1 << (ZoneWater.NOT_IN_MIRROR_LAYER - 1))   # (left out of the water's mirror)
	inst.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # (moved every frame drawn)
	return inst


## A picture 1 m wide (`aspect` m high), its foot at the origin if it stands, else its middle.
static func quad(aspect: float, standing: bool) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(1.0, aspect)
	q.center_offset = Vector3(0.0, aspect * 0.5 if standing else 0.0, 0.0)
	return q


## The butterfly: its picture (seen from above, head at the top) laid flat, 1 m across, its head
## towards -Z; two halves hinged on the body (x = 0), which the shader lifts.
static func wings_mesh(aspect: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var xs := [-0.5, 0.0, 0.5]
	for half in 2:
		var x0: float = xs[half]
		var x1: float = xs[half + 1]
		var corners := [Vector2(x0, -0.5), Vector2(x1, -0.5), Vector2(x1, 0.5), Vector2(x0, 0.5)]
		for k: int in [0, 1, 2, 0, 2, 3]:
			var c: Vector2 = corners[k]
			st.set_uv(Vector2(c.x + 0.5, c.y + 0.5))
			st.add_vertex(Vector3(c.x, 0.0, c.y * aspect))
	return st.commit()


## The particles of an effect (WildlifeDB.EFFECTS), not emitting yet: its box EFFECT_SPREAD wider.
static func effect(def: Dictionary) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var life: float = def["life"]
	var spread := EFFECT_SPREAD * EFFECT_SPREAD if def["emit"] == &"box" else 1.0
	p.amount = Quality.scaled(roundi(float(def["amount"]) * spread))
	p.lifetime = life
	p.preprocess = life
	p.local_coords = false
	p.emitting = false
	if def["emit"] == &"box":
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		var box: Vector3 = def["box"]
		p.emission_box_extents = Vector3(box.x * EFFECT_SPREAD, box.y, box.z * EFFECT_SPREAD)
	else:   # points given by Wildlife3D (on the water)
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	p.direction = def.get("dir", Vector3.UP)
	p.spread = def.get("spread", 180.0)
	var speed: Array = def["speed"]
	p.initial_velocity_min = speed[0]
	p.initial_velocity_max = speed[1]
	p.gravity = Vector3(0, float(def.get("gravity", 0.0)), 0)
	var colour: Color = def["colour"]
	p.color_ramp = blink(colour) if def.get("blink", false) else fade(colour, 0.15)
	var size: float = float(def["size"]) * (LIGHT_SIZE if def.get("glow", false) else 1.0)
	var q := QuadMesh.new()
	q.size = Vector2(size, size * float(def.get("drop", 1.0)))
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if def.get("glow", false):
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_texture = dot()
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


## One instance in a MultiMesh's buffer (TRANSFORM_3D, colours, custom data: 20 floats): where it
## is, turned and sized (`basis`), its tint, its cell, its wings (rad).
static func put(buf: PackedFloat32Array, i: int, basis: Basis, at: Vector3, tint: Color, cell: float, wing: float) -> void:
	var o := i * 20
	buf[o] = basis.x.x
	buf[o + 1] = basis.y.x
	buf[o + 2] = basis.z.x
	buf[o + 3] = at.x
	buf[o + 4] = basis.x.y
	buf[o + 5] = basis.y.y
	buf[o + 6] = basis.z.y
	buf[o + 7] = at.y
	buf[o + 8] = basis.x.z
	buf[o + 9] = basis.y.z
	buf[o + 10] = basis.z.z
	buf[o + 11] = at.z
	buf[o + 12] = tint.r
	buf[o + 13] = tint.g
	buf[o + 14] = tint.b
	buf[o + 15] = tint.a
	buf[o + 16] = cell
	buf[o + 17] = wing
	buf[o + 18] = 0.0
	buf[o + 19] = 0.0


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
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = dot()
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


## A soft round dot, white (the lights, the splashes, a swarm without its picture).
static func dot() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		g.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 32
		t.height = 32
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_dot = t
	return _dot


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
