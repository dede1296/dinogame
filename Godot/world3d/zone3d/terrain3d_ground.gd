class_name ZoneGroundTerrain3D
extends Node3D
## The ground of a 3D zone on the Terrain3D plugin (addons/terrain_3d, 1.0.2; docs/migration-3d.md,
## phase 4, « Terrain3D »): ZoneTerrain builds it when its kind is TERRAIN3D. It draws the ground
## (Terrain3D's clipmap: levels of detail round the camera) and holds its collision (Terrain3D's
## own, the whole zone at once). The rules of the game do not change: they still read the 2.5D
## through ZoneSource. The heights come from a TerrainRelief (terrain3d_relief.gd: the 2.5D's relief,
## then the zone's edits, all by script), or from Terrain3D regions saved for the zone and retouched
## by hand in the editor (DATA_DIR, see save() and terrain3d_bake.gd).
## The painting is terrain3d_ground.gdshader (Terrain3D's shader override), the same as the home-made
## mesh's. Terrain3D is reached through ClassDB and untyped variables only, so this script compiles
## even where the extension is missing (ZoneTerrain then keeps its own mesh).
##
## The open world, prepared: the ground stands at `world_offset` (m) in a world shared with other
## zones — the zone's own coordinates (height_at, the relief) stay 0,0 at its corner; Terrain3D's
## regions sit on the world's grid (REGION_SIZE × VERTEX_SPACING = 64 m). See docs/migration-3d.md.

const SHADER := preload("res://world3d/zone3d/terrain3d_ground.gdshader")
## Metres between two vertices of the ground (and two samples of its collision). 0.5: a cliff face
## is half a metre deep instead of one, so it stands steeper and its edge reads sharper.
const VERTEX_SPACING := TerrainRelief.STEP_M
## Vertices per side of a Terrain3D region (64 m at 0.5 m): the zone is covered by whole regions,
## so small ones waste less ground beyond its margin.
const REGION_SIZE := 128
const MESH_SIZE := 48             # Terrain3D's clipmap: vertices per side of its finest ring
const MESH_LODS := 5              # (48 vertices × 0.5 m × 2⁴: the last ring reaches about 400 m, past the zone)
const COLLISION_FULL_GAME := 3    # Terrain3DCollision.FULL_GAME: the whole zone, without nodes
const BACKGROUND_NONE := 0        # Terrain3DMaterial.NONE: nothing drawn outside the regions
const MAP_ALL := 3                # Terrain3DRegion.TYPE_MAX: every map
const NAV_STEP_M := 1.0           # metres between the vertices handed to the navigation bake (the old ground's)
## Where a zone's Terrain3D regions are saved to be retouched by hand (one folder per zone id,
## Terrain3D's own files: terrain3d_XX_YY.res). When it holds regions, they are the zone's ground.
const DATA_DIR := "res://world3d/zone3d/terrain3d_data/"

## Terrain3D's material seen as a ShaderMaterial (set_shader_parameter / get_shader_parameter), so
## what tints the ground (the rain: Weather3D) works on both grounds alike.
class Params extends RefCounted:
	var target: Object   # the Terrain3DMaterial

	func _init(material: Object) -> void:
		target = material

	func set_shader_parameter(param: StringName, value: Variant) -> void:
		target.call(&"set_shader_param", param, value)

	func get_shader_parameter(param: StringName) -> Variant:
		return target.call(&"get_shader_param", param)


var terrain: Node3D               # the Terrain3D node
var material: Params
var relief: TerrainRelief
## Where the zone's corner stands in the world (m, x and z).
var world_offset := Vector2.ZERO
## The folder the regions were read from (hand-retouched ground), or "" (built from the relief).
var loaded_from := ""
## What the build took (ms).
var timings := {}

var _parser := RID()
var _nav_faces := PackedVector3Array()


## True where Terrain3D can draw: the extension is loaded and the renderer is Forward+ (it fails to
## compile under Mobile on Direct3D 12; Mobile on Vulkan would do, but the 3D PC runs Forward+).
static func available() -> bool:
	return ClassDB.class_exists(&"Terrain3D") and RenderingServer.get_current_rendering_method() == "forward_plus"


## The folder of zone `zone_id`'s retouched regions, if it holds any; else "".
static func saved_regions(zone_id: StringName) -> String:
	var dir := DATA_DIR + String(zone_id)
	if not DirAccess.dir_exists_absolute(dir):
		return ""
	for file in DirAccess.get_files_at(dir):
		if file.begins_with("terrain3d") and (file.ends_with(".res") or file.ends_with(".res.remap")):
			return dir
	return ""


## Builds the ground of `from` (its heights and its painting) at `offset` (m) in the world, painted
## with `ground_material`'s parameters. `regions_dir`: read the heights from there instead (hand
## retouches), the relief keeping the 2.5D's base and the painting.
func build(from: TerrainRelief, offset: Vector2, ground_material: ShaderMaterial, regions_dir := "") -> void:
	var t0 := Time.get_ticks_msec()
	relief = from
	world_offset = offset.snapped(Vector2.ONE * relief.step)
	if not world_offset.is_equal_approx(offset):
		push_warning("ZoneGroundTerrain3D : position de zone %s ramenée à %s (multiple de %.2f m)" % [offset, world_offset, relief.step])
	_make_terrain(ground_material, regions_dir)
	timings["terrain3d"] = Time.get_ticks_msec() - t0


## Height (m) of the ground at a point of the zone (m, its own coordinates).
func height_at(x: float, z: float) -> float:
	return relief.height_at(x, z)


## Saves the zone's regions (Terrain3D's files) to `dir`, so they can be opened and retouched in
## the editor, and read back by the game (DATA_DIR + zone id). Returns the error, OK if all went.
func save(dir: String) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return err
	terrain.get(&"data").call(&"save_directory", dir)
	return OK if saved_files(dir) > 0 else ERR_FILE_CANT_WRITE


static func saved_files(dir: String) -> int:
	return Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool: return f.begins_with("terrain3d")).size()


func _make_terrain(ground_material: ShaderMaterial, regions_dir: String) -> void:
	terrain = ClassDB.instantiate(&"Terrain3D")
	terrain.name = "Terrain3D"
	terrain.set(&"vertex_spacing", relief.step)
	terrain.set(&"mesh_size", MESH_SIZE)
	terrain.set(&"mesh_lods", MESH_LODS)
	var mat: Object = ClassDB.instantiate(&"Terrain3DMaterial")
	mat.set(&"world_background", BACKGROUND_NONE)
	mat.set(&"shader_override", SHADER)
	mat.set(&"shader_override_enabled", true)
	terrain.set(&"material", mat)
	terrain.set(&"assets", placeholder_assets())
	terrain.set(&"free_editor_textures", false)   # (it would reload the assets from a file: there is none)
	terrain.add_to_group(&"nav_source")   # Zone3D bakes the dinos' navigation from this group
	add_child(terrain)
	terrain.set(&"region_size", REGION_SIZE)
	var data: Object = terrain.get(&"data")
	if regions_dir != "":
		data.call(&"load_directory", regions_dir)
		loaded_from = regions_dir
		relief.read_heights(func(x: float, z: float) -> float:
			return data.call(&"get_height", Vector3(x + world_offset.x, 0.0, z + world_offset.y)))
	else:
		_add_regions()
	# (the collision settings are set once it is in the tree: set before, they were not kept)
	terrain.set(&"collision_mode", COLLISION_FULL_GAME)
	terrain.set(&"collision_layer", Layers3D.WORLD)
	terrain.set(&"collision_mask", 0)
	terrain.get(&"collision").call(&"build")
	material = Params.new(mat)
	copy_params(ground_material, material)
	material.set_shader_parameter(&"zone_origin", world_offset)
	_parser = NavigationServer3D.source_geometry_parser_create()
	NavigationServer3D.source_geometry_parser_set_callback(_parser, _parse_navigation)


## Terrain3D's texture list, with one tiny blank texture the shader never reads: with none, the
## plugin switches on its checkered debug view (and its code no longer fits our shader), and with a
## missing picture it would make two of 1024² for nothing.
static func placeholder_assets() -> Object:
	var img := Image.create(4, 4, true, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	img.generate_mipmaps()
	var texture: Object = ClassDB.instantiate(&"Terrain3DTextureAsset")
	texture.set(&"name", "vide")
	texture.set(&"albedo_texture", ImageTexture.create_from_image(img))
	var assets: Object = ClassDB.instantiate(&"Terrain3DAssets")
	assets.call(&"set_texture", 0, texture)
	return assets


## The heights, cut into Terrain3D regions on the world's grid, covering the zone and its margin;
## beyond the margin, the edge samples run on to the end of the region (as the 2.5D's HeightMap
## holds its edge).
func _add_regions() -> void:
	var data: Object = terrain.get(&"data")
	var step := relief.step
	var samples := relief.samples
	var corner := world_offset + relief.origin                     # the grid's first sample, in the world
	var region_m := REGION_SIZE * step
	var first := Vector2i(floori(corner.x / region_m), floori(corner.y / region_m))
	var far_corner := corner + Vector2(samples - Vector2i.ONE) * step
	var last := Vector2i(floori(far_corner.x / region_m), floori(far_corner.y / region_m))
	var lattice := Vector2i(roundi(corner.x / step), roundi(corner.y / step))   # sample (0, 0) on the vertex grid
	for rz in range(first.y, last.y + 1):
		for rx in range(first.x, last.x + 1):
			var values := PackedFloat32Array()
			values.resize(REGION_SIZE * REGION_SIZE)
			for j in REGION_SIZE:
				var iz := clampi(rz * REGION_SIZE + j - lattice.y, 0, samples.y - 1)
				var row := iz * samples.x
				for i in REGION_SIZE:
					var ix := clampi(rx * REGION_SIZE + i - lattice.x, 0, samples.x - 1)
					values[j * REGION_SIZE + i] = relief.heights[row + ix]
			var img := Image.create_from_data(REGION_SIZE, REGION_SIZE, false, Image.FORMAT_RF, values.to_byte_array())
			var region: Object = ClassDB.instantiate(&"Terrain3DRegion")
			region.set(&"region_size", REGION_SIZE)
			region.set(&"vertex_spacing", step)
			region.set(&"location", Vector2i(rx, rz))
			region.set(&"height_map", img)
			region.call(&"calc_height_range")
			data.call(&"add_region", region, false)
	data.call(&"update_maps", MAP_ALL, true, false)
	data.call(&"calc_height_range", true)


## The painting's parameters, the same as the home-made mesh's (ZoneTerrain._material sets them).
static func copy_params(from: ShaderMaterial, to: Object) -> void:
	for uniform: Dictionary in from.shader.get_shader_uniform_list():
		var param := StringName(uniform["name"])
		var value: Variant = from.get_shader_parameter(param)
		if value != null:
			to.call(&"set_shader_parameter", param, value)


## The navigation mesh is baked from the colliders of the group nav_source; Terrain3D's collision
## is not a node, so the ground's triangles are handed over here when the bake reaches the Terrain3D
## node. They are ours, one metre apart as the old ground's collision was, not the plugin's
## generate_nav_mesh_source_geometry: in 1.0.2, given a box, it tests the height of each vertex at
## its index taken as metres, which skips half the ground when the vertices are not 1 m apart.
func _parse_navigation(_mesh: NavigationMesh, geometry: NavigationMeshSourceGeometryData3D, node: Node) -> void:
	if node != terrain:
		return
	if _nav_faces.is_empty():
		_nav_faces = _ground_faces(maxi(roundi(NAV_STEP_M / relief.step), 1))
	geometry.add_faces(_nav_faces, Transform3D.IDENTITY)


## Two triangles per cell of `stride` samples, over the zone and its margin, in the world.
func _ground_faces(stride: int) -> PackedVector3Array:
	var faces := PackedVector3Array()
	var nx := int((relief.samples.x - 1) / float(stride))
	var nz := int((relief.samples.y - 1) / float(stride))
	faces.resize(nx * nz * 6)
	var i := 0
	for cz in nz:
		for cx in nx:
			var a := _vertex(cx * stride, cz * stride)
			var b := _vertex((cx + 1) * stride, cz * stride)
			var c := _vertex(cx * stride, (cz + 1) * stride)
			var d := _vertex((cx + 1) * stride, (cz + 1) * stride)
			faces[i] = a; faces[i + 1] = b; faces[i + 2] = c
			faces[i + 3] = b; faces[i + 4] = d; faces[i + 5] = c
			i += 6
	return faces


func _vertex(ix: int, iz: int) -> Vector3:
	var at := world_offset + relief.origin + Vector2(ix, iz) * relief.step
	return Vector3(at.x, relief.heights[iz * relief.samples.x + ix], at.y)


## Terrain3D centres its rings on one camera: keep it on the one drawing the view (Chloé's, a scene's).
func _process(_delta: float) -> void:
	if terrain == null:
		return
	var eye := get_viewport().get_camera_3d()
	if eye and terrain.call(&"get_camera") != eye:
		terrain.call(&"set_camera", eye)


func _exit_tree() -> void:
	if _parser.is_valid():
		NavigationServer3D.free_rid(_parser)
		_parser = RID()
