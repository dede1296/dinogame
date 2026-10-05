class_name NpcBody
extends RefCounted
## The 3D look of the people of Ambrelune (docs/migration-3d.md, « Npc → Npc3D »).
##
## **Choice**: the same body as Chloé — `assets/models3d/characters/chloe/chloe.glb`, built from the
## Quaternius *Universal Base Characters* — worn at the person's own height and painted in their own
## colours. Not a drawn panel facing the camera: next to a modelled Chloé a flat person is the very
## mix of styles that sank the earlier 3D attempt. Not another pack of models either: nothing free
## matches her (shapes, outline, 20 000 triangles), and anything else would be that same mix.
## Her rig, her 23 clips and her AnimSet come along unchanged, so a person walks and talks like her.
##
## **The colours are not written down anywhere**: they are read off the person's own 2.5D sheet
## (NpcPalette) — hair, skin, top, trousers, boots — so every character of the game, in every zone,
## is dressed by their own drawing. Chloé's own kit (backpack, straps, barrette) is left off.
##
## **Known limit**: everyone shares her build and her ponytail; only the height, the colours and the
## hair style (STYLES) change. A hair shape or a body of someone's own means new models (Blender,
## same base), which is a step of its own.

const MODEL := preload("res://assets/models3d/characters/chloe/chloe.glb")
## Chloé's AnimSet: the same skeleton, so the same clips and the same strides (world3d/animation).
const ANIMS := preload("res://world3d/player/chloe_anims.tres")
const TOON := preload("res://world3d/render/toon_style.gd")
## The height the model is drawn at (Player3D.HEIGHT): everyone else is it, scaled.
const BASE_HEIGHT := 1.5
## Chloé's own things, worn by nobody else (the start of their node names in the glb: her kit, and
## the pockets sewn on her own waistcoat, which would read as patches on anyone else's clothes).
const HER_OWN := ["Chloe_Backpack", "Chloe_Straps", "Chloe_Barrette", "Chloe_Pocket"]
## Material of the model → which colour of the sheet paints it.
const DRESSING := {
	"Chloe_Skin": &"skin", "Chloe_Tshirt": &"top", "Chloe_Vest": &"top", "Chloe_Pocket": &"top_dark",
	"Chloe_Shorts": &"bottom", "Chloe_Boots": &"boots", "Chloe_Sole": &"boots_dark",
	"Chloe_Hair": &"hair", "Chloe_HairPart.001": &"hair_dark", "Chloe_Brows": &"hair_dark",
	"Chloe_Lashes": &"hair_dark", "Chloe_Accessory": &"hair",
}
## A painted material (skin, hair) is multiplied by its texture, so the factor is the colour wanted
## over what the texture averages; past this the strands and the shading would wash out.
const MAX_FACTOR := 2.5
## Sheets whose hair Chloé's ponytail cannot stand in for (sheet file name → style).
const STYLES := {"maia": &"afro"}
## The afro: a ball of hair over the skull and the lumps around it, and the headband under it
## (metres at 1.50 m, in the skeleton's own space; the Head bone sits at 1.277 m).
const HEAD_TOP := 1.365
const AFRO_RADIUS := 0.125
const AFRO_LUMPS := 6
const AFRO_BACK_M := -0.075   # the ball's centre, behind the skull's middle (the face is at +Z)
const AFRO_LUMP_RADIUS := 0.072
const BAND_HEIGHT := 1.345   # above the eyebrows, on the forehead line (Greg, 05/10: it sat on the mouth)

static var _texture_average := {}


## The body of the person drawn on `sheet`, `height_m` tall, painted in their colours and given
## Ambrelune's cartoon look. `tint` is the 2.5D's own tint (a stand-in sheet), white for most.
static func build(sheet: Texture2D, height_m: float, tint := Color.WHITE) -> Node3D:
	var shown := MODEL.instantiate() as Node3D
	var palette := NpcPalette.of(sheet)
	var colours := _colours(palette, tint)
	for node in shown.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if _hers(mesh.name):
			mesh.visible = false
			continue
		_paint(mesh, colours)
	_style_hair(shown, sheet, colours)
	shown.scale = Vector3.ONE * (height_m / BASE_HEIGHT)
	TOON.apply(shown)   # the same cartoon look as Chloé and the dinos
	return shown


## Is that part of the model Chloé's own (HER_OWN)?
static func _hers(node_name: StringName) -> bool:
	for own: String in HER_OWN:
		if String(node_name).begins_with(own):
			return true
	return false


## How big a person is against the model (for the animator's strides: shorter legs, shorter steps).
static func size_factor(height_m: float) -> float:
	return height_m / BASE_HEIGHT


## Every colour the model needs, from the five read off the sheet.
static func _colours(palette: NpcPalette, tint: Color) -> Dictionary:
	var out := {
		&"skin": palette.skin, &"hair": palette.hair, &"top": palette.top,
		&"bottom": palette.bottom, &"boots": palette.boots,
		&"hair_dark": NpcPalette.darker(palette.hair, 0.7),
		&"top_dark": NpcPalette.darker(palette.top, 0.8),
		&"boots_dark": NpcPalette.darker(palette.boots, 0.6),
	}
	if tint != Color.WHITE:   # a character drawn with someone else's sheet, tinted in the 2.5D
		for key: StringName in out:
			out[key] = (out[key] as Color) * tint
	return out


## Paints one mesh: each surface whose material DRESSING knows takes the person's colour, on the
## MeshInstance3D only (surface overrides; the shared imported mesh is left alone, as toon_style does).
static func _paint(mi: MeshInstance3D, colours: Dictionary) -> void:
	if mi.mesh == null:
		return
	for s in mi.mesh.get_surface_count():
		var source := mi.get_surface_override_material(s)
		if source == null:
			source = mi.mesh.surface_get_material(s)
		var base := source as BaseMaterial3D
		if base == null or not DRESSING.has(base.resource_name):
			continue
		var wanted: Color = colours[DRESSING[base.resource_name]]
		var painted := base.duplicate() as BaseMaterial3D
		painted.resource_name = "%s %s" % [base.resource_name, wanted.to_html(false)]
		painted.albedo_color = _factor(wanted, base.albedo_texture)
		mi.set_surface_override_material(s, painted)


## What to set as albedo so the surface comes out `wanted`: the colour itself when the material is
## plain, and the colour over the texture's own average when it is painted (skin, hair).
static func _factor(wanted: Color, texture: Texture2D) -> Color:
	if texture == null:
		return wanted
	var average := _average(texture)
	return Color(
		clampf(wanted.r / maxf(average.r, 0.02), 0.0, MAX_FACTOR),
		clampf(wanted.g / maxf(average.g, 0.02), 0.0, MAX_FACTOR),
		clampf(wanted.b / maxf(average.b, 0.02), 0.0, MAX_FACTOR))


## The average colour of a texture (one pixel in 8 each way), read once.
static func _average(texture: Texture2D) -> Color:
	var key := texture.resource_path if texture.resource_path != "" else str(texture.get_instance_id())
	if _texture_average.has(key):
		return _texture_average[key]
	var image := texture.get_image()
	var out := Color.WHITE
	if image != null:
		if image.is_compressed():
			image.decompress()
		var sum := Vector3.ZERO
		var seen := 0
		for y in range(0, image.get_height(), 8):
			for x in range(0, image.get_width(), 8):
				var pixel := image.get_pixel(x, y)
				if pixel.a < 0.5:
					continue
				sum += Vector3(pixel.r, pixel.g, pixel.b)
				seen += 1
		if seen > 0:
			out = Color(sum.x / seen, sum.y / seen, sum.z / seen)
	_texture_average[key] = out
	return out


## Hair Chloé's ponytail cannot stand in for (STYLES): her ponytail goes and another one is built
## on the Head bone, so it follows the animations.
static func _style_hair(shown: Node3D, sheet: Texture2D, colours: Dictionary) -> void:
	var name := sheet.resource_path.get_file().get_basename() if sheet else ""
	if STYLES.get(name, &"") != &"afro":
		return
	for part: String in ["Chloe_Ponytail", "Chloe_HairPart", "Chloe_HairTie"]:
		var node := shown.find_child(part, true, false)
		if node is Node3D:
			(node as Node3D).visible = false
	var skeletons := shown.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	var skeleton: Skeleton3D = skeletons[0]
	var bone := skeleton.find_bone("Head")
	if bone < 0:
		return
	var holder := BoneAttachment3D.new()
	holder.name = "Hair"
	holder.bone_idx = bone
	skeleton.add_child(holder)
	# the lumps are placed in the skeleton's own axes, whatever way the bone is turned
	var to_bone := skeleton.get_bone_global_rest(bone).affine_inverse()
	var hair := StandardMaterial3D.new()
	hair.resource_name = "Npc_Hair_%s" % (colours[&"hair"] as Color).to_html(false)
	hair.albedo_color = colours[&"hair"]
	hair.roughness = 1.0
	# the ball sits back on the skull: the face is in front (+Z), it must stay uncovered (Greg, 05/10)
	_ball(holder, to_bone, Vector3(0.0, HEAD_TOP + 0.01, AFRO_BACK_M), AFRO_RADIUS, hair)
	for i in AFRO_LUMPS:
		# the lumps only on the back half of the head (sin <= 0 is the back, as the face is at +Z)
		var angle := PI + (i + 0.5) * PI / AFRO_LUMPS
		var at := Vector3(cos(angle) * AFRO_RADIUS * 0.82, HEAD_TOP - 0.035, AFRO_BACK_M + sin(angle) * AFRO_RADIUS * 0.82)
		_ball(holder, to_bone, at, AFRO_LUMP_RADIUS, hair)
	var band := StandardMaterial3D.new()   # the headband, under the hair
	band.resource_name = "Npc_Band_%s" % (colours[&"top"] as Color).to_html(false)
	band.albedo_color = colours[&"top"]
	band.roughness = 1.0
	var torus := TorusMesh.new()
	torus.inner_radius = 0.082
	torus.outer_radius = 0.097
	torus.material = band
	var ring := MeshInstance3D.new()
	ring.name = "Headband"
	ring.mesh = torus
	ring.transform = to_bone * Transform3D(Basis(), Vector3(0.0, BAND_HEIGHT, AFRO_BACK_M * 0.5))
	holder.add_child(ring)


static func _ball(holder: Node3D, to_bone: Transform3D, at: Vector3, radius: float, material: Material) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.85
	sphere.radial_segments = 16
	sphere.rings = 10
	sphere.material = material
	var mesh := MeshInstance3D.new()
	mesh.name = "HairBall"
	mesh.mesh = sphere
	mesh.transform = to_bone * Transform3D(Basis.IDENTITY, at)
	holder.add_child(mesh)
