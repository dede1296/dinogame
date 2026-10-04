extends RefCounted
## Ambrelune's cartoon look for every 3D model, whatever its source (docs/migration-3d.md, phase 4):
## the soft-stepped shading of toon.gdshader and the dark brown outline of outline.gdshader.
##   const TOON := preload("res://world3d/render/toon_style.gd")
##   TOON.apply(model)                                  # after instantiating it
##   TOON.apply(bush, {"outline": false})               # dense leaves: no outline (or thinner)
## Each imported material (StandardMaterial3D / BaseMaterial3D of a glb) under `root` is swapped,
## on the MeshInstance3D only (surface overrides: the shared imported mesh is untouched), for a toon
## ShaderMaterial with its colour, texture, vertex colours, transparency (alpha scissor for
## cut-out leaves) and sidedness, and the outline as its next pass. Materials that are alike share
## one toon material (cached), so a herd of the same dino costs no more materials than one.
## A mesh with hard edges (low-poly, flat-shaded) is given, once, a copy with smoothed normals in
## its tangents, so its outline has no gaps (see _outline_mesh).
## Kept as they are: materials it does not know (a ShaderMaterial, already toon), unshaded ones,
## triplanar ones (world-space textures).
## No class_name: preloaded, so adding it needs no import of the project.

const TOON_SHADER := preload("res://world3d/render/toon.gdshader")
const OUTLINE_SHADER := preload("res://world3d/render/outline.gdshader")
## The outlines of the 2.5D's pictures (docs/direction-artistique.md, palette).
const OUTLINE_COLOR := Color("2a180c")
const DEFAULTS := {
	"outline": true,            # the dark brown outline
	"outline_px": 2.0,          # its width, in pixels per 720 of screen height (~3 px at 1080p)
	"outline_color": OUTLINE_COLOR,
	"outline_cutout": false,    # outline the cut-out (alpha scissor) materials too: leaves, off
	"intensity": 1.0,           # 1: the full cartoon steps; 0: plain smooth lighting
	"rim": 0.35,                # the rim of light on the edges turned to the sun (0: none)
	"fade": true,               # follow GeometryInstance3D.transparency (see FadeWatch)
}
const WATCH_NAME := "ToonFade"
## Vertices this close (m) are one point; normals further apart than this cosine (~25°) at one
## point are a hard edge.
const WELD := 0.0001
const HARD_EDGE_COS := 0.9
## Only low-poly meshes get smoothed outline normals: on a dense one (Chloé's body) the facets are
## too small for the gaps to show, and the copy would cost load time.
const SMOOTH_MAX_VERTICES := 6000

enum Alpha { OPAQUE, SCISSOR, BLEND }

static var _variants := {}    # its #defines → Shader
static var _materials := {}   # what makes two materials alike → toon ShaderMaterial
static var _outlines := {}    # width, colour, normals → outline ShaderMaterial
static var _smoothed := {}    # mesh → the mesh to outline (itself, or its copy with smooth tangents)
static var _rebuilt := {}     # those copies


## Gives every MeshInstance3D under `root` (and `root` itself) the cartoon look. `options`: any of
## DEFAULTS. Calling it again on the same model changes nothing.
static func apply(root: Node, options := {}) -> void:
	if root == null:
		push_error("toon_style: apply() on no node")
		return
	for key in options:
		if not DEFAULTS.has(key):
			push_warning("toon_style: unknown option '%s' (known: %s)" % [key, ", ".join(DEFAULTS.keys())])
	var opts := DEFAULTS.merged(options, true)
	var nodes := root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		nodes.push_front(root)
	var toon_meshes: Array[GeometryInstance3D] = []
	for node in nodes:
		var mi := node as MeshInstance3D
		if mi.mesh != null and _convert(mi, opts):
			toon_meshes.append(mi)
	if opts["fade"] and not toon_meshes.is_empty() and root.get_node_or_null(WATCH_NAME) == null:
		var watch := FadeWatch.new()
		watch.name = WATCH_NAME
		watch.meshes = toon_meshes
		root.add_child(watch, false, Node.INTERNAL_MODE_BACK)


## Swaps the materials of one mesh; true if it has a toon material now.
static func _convert(mi: MeshInstance3D, opts: Dictionary) -> bool:
	var smooth := false
	if opts["outline"] and float(opts["outline_px"]) > 0.0:
		var outlined := _outline_mesh(mi.mesh)
		if outlined != mi.mesh:
			mi.mesh = outlined
		smooth = _rebuilt.has(outlined)
	if mi.material_override:
		var whole := _toon_for(mi.material_override, opts, smooth)
		if whole:
			mi.material_override = whole
		return mi.material_override is ShaderMaterial and _is_toon(mi.material_override)
	var any := false
	for s in mi.mesh.get_surface_count():
		var source := mi.get_surface_override_material(s)
		if source == null:
			source = mi.mesh.surface_get_material(s)
		var toon := _toon_for(source, opts, smooth)
		if toon:
			mi.set_surface_override_material(s, toon)
		any = any or toon != null or _is_toon(source)
	return any


## The mesh to outline: `mesh` itself, or, if it has hard edges (flat-shaded faces: split normals),
## a copy with smoothed normals in its TANGENT channel (outline.gdshader), made once per mesh.
## The copy keeps the vertices, bones, blend shapes, materials and shadow mesh; not the LODs.
static func _outline_mesh(mesh: Mesh) -> Mesh:
	if _smoothed.has(mesh):
		return _smoothed[mesh]
	var result := mesh
	var source := mesh as ArrayMesh
	if source and _vertex_count(source) <= SMOOTH_MAX_VERTICES and _has_hard_edges(source):
		result = _with_smooth_tangents(source)
		if result != mesh:
			_rebuilt[result] = true
			_smoothed[result] = result
	_smoothed[mesh] = result
	return result


static func _vertex_count(mesh: ArrayMesh) -> int:
	var count := 0
	for s in mesh.get_surface_count():
		count += mesh.surface_get_array_len(s)
	return count


static func _has_hard_edges(mesh: ArrayMesh) -> bool:
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		if normals.size() != verts.size():
			continue
		var seen := {}
		for i in verts.size():
			var at := verts[i].snapped(Vector3.ONE * WELD)
			if not seen.has(at):
				seen[at] = normals[i]
			elif (seen[at] as Vector3).dot(normals[i]) < HARD_EDGE_COS:
				return true
	return false


static func _with_smooth_tangents(mesh: ArrayMesh) -> ArrayMesh:
	var copy := ArrayMesh.new()
	copy.resource_name = mesh.resource_name
	copy.blend_shape_mode = mesh.blend_shape_mode
	for b in mesh.get_blend_shape_count():
		copy.add_blend_shape(mesh.get_blend_shape_name(b))
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		if normals.size() == verts.size():
			var sums := {}
			for i in verts.size():
				var at := verts[i].snapped(Vector3.ONE * WELD)
				sums[at] = (sums.get(at, Vector3.ZERO) as Vector3) + normals[i]
			var tangents := PackedFloat32Array()
			tangents.resize(verts.size() * 4)
			for i in verts.size():
				var n := (sums[verts[i].snapped(Vector3.ONE * WELD)] as Vector3).normalized()
				if n.is_zero_approx():
					n = normals[i]
				tangents[i * 4] = n.x
				tangents[i * 4 + 1] = n.y
				tangents[i * 4 + 2] = n.z
				tangents[i * 4 + 3] = 1.0
			arrays[Mesh.ARRAY_TANGENT] = tangents
		# what the arrays alone do not say: 8 bone weights, the formats of the custom channels
		var keep: int = Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		for c in 4:
			keep |= Mesh.ARRAY_FORMAT_CUSTOM_MASK << (Mesh.ARRAY_FORMAT_CUSTOM_BASE + c * Mesh.ARRAY_FORMAT_CUSTOM_BITS)
		var flags: int = mesh.surface_get_format(s) & keep
		copy.add_surface_from_arrays(mesh.surface_get_primitive_type(s), arrays, mesh.surface_get_blend_shape_arrays(s), {}, flags)
		if copy.get_surface_count() != s + 1:
			push_warning("toon_style: no smoothed copy of mesh '%s' (its outline keeps its own normals)" % mesh.resource_name)
			return mesh
		copy.surface_set_name(s, mesh.surface_get_name(s))
		copy.surface_set_material(s, mesh.surface_get_material(s))
	if mesh.shadow_mesh and mesh.shadow_mesh != mesh:
		copy.shadow_mesh = mesh.shadow_mesh
	copy.custom_aabb = mesh.custom_aabb
	return copy


static func _is_toon(material: Material) -> bool:
	var sm := material as ShaderMaterial
	return sm != null and sm.shader != null and (sm.shader == TOON_SHADER or _variants.values().has(sm.shader))


## The Mobile and Compatibility renderers ignore GeometryInstance3D.transparency: the toon shader
## dithers the model away instead. Forward+ fades it itself.
static func _dithers() -> bool:
	return RenderingServer.get_current_rendering_method() != "forward_plus"


## The toon material standing for `source` (shared by the materials alike); null: keep `source`.
static func _toon_for(source: Material, opts: Dictionary, smooth_tangent: bool) -> ShaderMaterial:
	var base := source as BaseMaterial3D
	if base == null or base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or base.uv1_triplanar:
		return null
	var alpha := _alpha_mode(base)
	var key := str([base.albedo_color, base.albedo_texture.get_instance_id() if base.albedo_texture else 0,
		alpha, base.cull_mode, snappedf(base.alpha_scissor_threshold, 0.001), base.vertex_color_use_as_albedo,
		base.vertex_color_is_srgb, base.uv1_scale, base.uv1_offset, base.render_priority, smooth_tangent,
		opts["intensity"], opts["rim"], opts["outline"], opts["outline_px"], opts["outline_color"], opts["outline_cutout"]])
	if _materials.has(key):
		return _materials[key]
	var mat := ShaderMaterial.new()
	mat.resource_name = base.resource_name + " (toon)"
	mat.shader = _variant(alpha, base.cull_mode)
	mat.render_priority = base.render_priority
	mat.set_shader_parameter(&"albedo", base.albedo_color)
	if base.albedo_texture:
		mat.set_shader_parameter(&"albedo_texture", base.albedo_texture)
	mat.set_shader_parameter(&"use_vertex_color", base.vertex_color_use_as_albedo)
	mat.set_shader_parameter(&"vertex_color_is_srgb", base.vertex_color_is_srgb)
	mat.set_shader_parameter(&"uv1_scale", base.uv1_scale)
	mat.set_shader_parameter(&"uv1_offset", base.uv1_offset)
	mat.set_shader_parameter(&"alpha_scissor", base.alpha_scissor_threshold)
	mat.set_shader_parameter(&"toon_strength", clampf(float(opts["intensity"]), 0.0, 1.0))
	mat.set_shader_parameter(&"rim_strength", maxf(float(opts["rim"]), 0.0))
	mat.set_shader_parameter(&"dither_fade", _dithers())
	var wants_outline: bool = opts["outline"] and float(opts["outline_px"]) > 0.0
	if wants_outline and (alpha == Alpha.OPAQUE or (alpha == Alpha.SCISSOR and opts["outline_cutout"])):
		mat.next_pass = _outline(opts, smooth_tangent)
	_materials[key] = mat
	return mat


static func _alpha_mode(base: BaseMaterial3D) -> Alpha:
	match base.transparency:
		BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH:
			return Alpha.SCISSOR
		BaseMaterial3D.TRANSPARENCY_ALPHA, BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS:
			return Alpha.BLEND
	return Alpha.OPAQUE


## toon.gdshader as it is (opaque, back faces culled), or a copy with its #defines.
static func _variant(alpha: Alpha, cull: BaseMaterial3D.CullMode) -> Shader:
	var defines := PackedStringArray()
	if alpha == Alpha.SCISSOR:
		defines.append("TOON_ALPHA_SCISSOR")
	elif alpha == Alpha.BLEND:
		defines.append("TOON_ALPHA_BLEND")
	if cull == BaseMaterial3D.CULL_DISABLED:
		defines.append("TOON_CULL_DISABLED")
	elif cull == BaseMaterial3D.CULL_FRONT:
		defines.append("TOON_CULL_FRONT")
	if defines.is_empty():
		return TOON_SHADER
	var key := ",".join(defines)
	if not _variants.has(key):
		var head := "shader_type spatial;"
		for define in defines:
			head += "\n#define %s" % define
		var shader := Shader.new()
		shader.code = TOON_SHADER.code.replace("shader_type spatial;", head)
		_variants[key] = shader
	return _variants[key]


static func _outline(opts: Dictionary, smooth_tangent: bool) -> ShaderMaterial:
	var key := str([opts["outline_px"], opts["outline_color"], smooth_tangent])
	if not _outlines.has(key):
		var mat := ShaderMaterial.new()
		mat.resource_name = "outline (toon)"
		mat.shader = OUTLINE_SHADER
		mat.set_shader_parameter(&"width_px", float(opts["outline_px"]))
		mat.set_shader_parameter(&"outline_color", opts["outline_color"])
		mat.set_shader_parameter(&"dither_fade", _dithers())
		mat.set_shader_parameter(&"smooth_normal_in_tangent", smooth_tangent)
		_outlines[key] = mat
	return _outlines[key]


## Passes each toon mesh's GeometryInstance3D.transparency (Chloé fading out near the camera, a tree
## hiding her) to its shaders, per mesh (the instance uniform `toon_fade`): the model is dithered
## away where the renderer ignores `transparency` (Mobile), and the outline thins and is gone before
## the model turns see-through, or its hull would show through it.
class FadeWatch extends Node:
	var meshes: Array[GeometryInstance3D] = []
	var _sent := PackedFloat32Array()

	func _ready() -> void:
		_sent.resize(meshes.size())
		_sent.fill(0.0)

	func _process(_delta: float) -> void:
		for i in meshes.size():
			var mesh := meshes[i]
			if not is_instance_valid(mesh):
				continue
			var fade := mesh.transparency
			if fade != _sent[i]:
				_sent[i] = fade
				mesh.set_instance_shader_parameter(&"toon_fade", fade)
