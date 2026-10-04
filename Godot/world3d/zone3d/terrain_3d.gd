class_name Terrain3D
extends Node3D
## The ground of a 3D zone (docs/migration-3d.md, phase 4), built from its ZoneSource: a real relief
## mesh in chunks (each culled alone), painted by terrain.gdshader with the 2.5D's ground pictures,
## a matching collision (HeightMapShape3D, one sample per metre), and the water sheet.
## The relief is the 2.5D's (HeightMap), stretched to the zone's scale; the ground runs on past the
## edges (the 2.5D's margin) so no edge shows in the distance.

const SHADER := preload("res://world3d/zone3d/terrain.gdshader")
const WATER_SHADER := preload("res://world3d/zone3d/water.gdshader")
const CHUNK_M := 32               # metres per chunk side
const STEP_M := 1.0               # metres between two vertices (and two collision samples)
const VIEW_M := 220.0             # chunks further than this are not drawn
const GROUND := {
	"grass": "res://assets/art/ground/herbe.png", "dirt": "res://assets/art/ground/terre.png",
	"mud": "res://assets/art/ground/vase.png", "rock": "res://assets/art/ground/roche_canyon.png",
	"cliff": "res://assets/art/ground/falaise.png",
}

var source: ZoneSource
var material: ShaderMaterial
var body: StaticBody3D

var _origin := Vector2.ZERO     # metres: the corner of the ground (the margin beyond the zone)
var _samples := Vector2i.ZERO   # vertices along x and z
var _heights := PackedFloat32Array()


func build(src: ZoneSource) -> void:
	source = src
	var margin := src.margin_m()
	_origin = Vector2(-margin, -margin)
	var extent := src.size_m() + Vector2.ONE * margin * 2.0
	_samples = Vector2i(int(extent.x / STEP_M) + 1, int(extent.y / STEP_M) + 1)
	_sample_heights()
	material = _material()
	_build_chunks()
	_build_collision()
	if src.heights.has_water:
		_build_water(extent)


## Height (m) of the ground mesh at a point (the same samples as the collision).
func height_at(x: float, z: float) -> float:
	var g := (Vector2(x, z) - _origin) / STEP_M
	var ix := clampi(floori(g.x), 0, _samples.x - 2)
	var iz := clampi(floori(g.y), 0, _samples.y - 2)
	var fx := clampf(g.x - ix, 0.0, 1.0)
	var fz := clampf(g.y - iz, 0.0, 1.0)
	var top := lerpf(_h(ix, iz), _h(ix + 1, iz), fx)
	var bottom := lerpf(_h(ix, iz + 1), _h(ix + 1, iz + 1), fx)
	return lerpf(top, bottom, fz)


func _h(ix: int, iz: int) -> float:
	return _heights[iz * _samples.x + ix]


func _sample_heights() -> void:
	_heights.resize(_samples.x * _samples.y)
	for iz in _samples.y:
		for ix in _samples.x:
			_heights[iz * _samples.x + ix] = source.height_at(_origin.x + ix * STEP_M, _origin.y + iz * STEP_M)


func _material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("grass_tex", load(GROUND["grass"]) if source.region.ground_tex == null else source.region.ground_tex)
	mat.set_shader_parameter("dirt_tex", load(GROUND["dirt"]) if source.region.path_tex == null else source.region.path_tex)
	mat.set_shader_parameter("mud_tex", load(GROUND["mud"]))
	mat.set_shader_parameter("rock_tex", load(GROUND["rock"]))
	mat.set_shader_parameter("cliff_tex", load(GROUND["cliff"]))
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	var masks := _masks()
	mat.set_shader_parameter("mask_a", masks[0])
	mat.set_shader_parameter("mask_b", masks[1])
	mat.set_shader_parameter("map_tiles", Vector2(source.tiles))
	mat.set_shader_parameter("tile_m", source.scale)
	mat.set_shader_parameter("water_level", HeightMap.WATER_LEVEL if source.heights.has_water else -100.0)
	return mat


## One pixel per tile — A: R path, G tall grass, B water, A woods; B: R sand, G mud, B rock.
func _masks() -> Array[ImageTexture]:
	var a := Image.create(source.tiles.x, source.tiles.y, false, Image.FORMAT_RGBA8)
	var b := Image.create(source.tiles.x, source.tiles.y, false, Image.FORMAT_RGBA8)
	for y in source.tiles.y:
		for x in source.tiles.x:
			var s := source.surface(Vector2i(x, y))
			a.set_pixel(x, y, Color(float(s == &"path"), float(s == &"tall_grass"), float(s == &"water"), float(s == &"forest")))
			b.set_pixel(x, y, Color(float(s == &"sand"), float(s == &"mud"), float(s == &"rock"), 0.0))
	return [ImageTexture.create_from_image(a), ImageTexture.create_from_image(b)]


func _build_chunks() -> void:
	var per := int(CHUNK_M / STEP_M)
	for cz in range(0, _samples.y - 1, per):
		for cx in range(0, _samples.x - 1, per):
			var mesh := _chunk_mesh(cx, cz, mini(per, _samples.x - 1 - cx), mini(per, _samples.y - 1 - cz))
			var view := MeshInstance3D.new()
			view.mesh = mesh
			view.material_override = material
			view.visibility_range_end = VIEW_M
			view.visibility_range_end_margin = 10.0
			add_child(view)


## The ground of `nx` × `nz` cells from sample (cx, cz): one vertex per sample, smooth normals.
func _chunk_mesh(cx: int, cz: int, nx: int, nz: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for iz in nz + 1:
		for ix in nx + 1:
			var gx := cx + ix
			var gz := cz + iz
			verts.append(Vector3(_origin.x + gx * STEP_M, _h(gx, gz), _origin.y + gz * STEP_M))
			var l := _h(maxi(gx - 1, 0), gz)
			var r := _h(mini(gx + 1, _samples.x - 1), gz)
			var u := _h(gx, maxi(gz - 1, 0))
			var d := _h(gx, mini(gz + 1, _samples.y - 1))
			normals.append(Vector3(l - r, 2.0 * STEP_M, u - d).normalized())
	var row := nx + 1
	for iz in nz:
		for ix in nx:
			var i := iz * row + ix
			indices.append_array([i, i + 1, i + row, i + 1, i + row + 1, i + row])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## The same samples as one height map shape (its samples are 1 unit apart: STEP_M = 1 m).
func _build_collision() -> void:
	body = StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = Layers3D.WORLD
	body.collision_mask = 0
	body.add_to_group(&"nav_source")
	var shape := HeightMapShape3D.new()
	shape.map_width = _samples.x
	shape.map_depth = _samples.y
	shape.map_data = _heights
	var holder := CollisionShape3D.new()
	holder.shape = shape
	# (a height map shape is centred on its node)
	holder.position = Vector3(_origin.x + (_samples.x - 1) * STEP_M * 0.5, 0.0, _origin.y + (_samples.y - 1) * STEP_M * 0.5)
	body.add_child(holder)
	add_child(body)


func _build_water(extent: Vector2) -> void:
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = extent
	plane.mesh = mesh
	plane.position = Vector3(_origin.x + extent.x * 0.5, HeightMap.WATER_LEVEL, _origin.y + extent.y * 0.5)
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	var ground := source.heights.height_texture()
	mat.set_shader_parameter("ground_height", ground["texture"])
	mat.set_shader_parameter("height_origin", ground["origin"])
	mat.set_shader_parameter("height_res", ground["res"])
	mat.set_shader_parameter("height_texels", ground["texels"])
	mat.set_shader_parameter("tile_m", source.scale)
	mat.set_shader_parameter("water_level", HeightMap.WATER_LEVEL)
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	plane.material_override = mat
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(plane)
