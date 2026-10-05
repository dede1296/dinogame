class_name ZoneTerrain
extends Node3D
## The ground of a 3D zone (docs/migration-3d.md, phase 4), built from its ZoneSource, and the water
## sheet. Two grounds, chosen by `Kind` (DEFAULT_KIND, or `-- --terrain=mesh|terrain3d` on the
## command line, or ZoneTerrain.kind_override before the zone is built):
## - TERRAIN3D, the base of the 3D relief for every zone: the Terrain3D plugin (ZoneGroundTerrain3D,
##   terrain3d_ground.gd), its clipmap with levels of detail and its collision, fed with a
##   TerrainRelief (terrain3d_relief.gd): the heights ZoneSource gives, then the zone's edits as data
##   (by default: smoothed away from the cliffs and the water, the sea dug deeper), or the regions
##   saved for the zone and retouched by hand (ZoneGroundTerrain3D.DATA_DIR). Only where the plugin
##   can draw (Forward+): else the mesh below, said in the console.
## - MESH: the home-made ground, kept whole as the way back — a relief mesh in chunks (each culled
##   alone) and a matching collision (HeightMapShape3D, one sample per metre), exactly ZoneSource's
##   heights.
## Both are painted by the same code (terrain_paint.gdshaderinc) with the 2.5D's ground pictures.
## Whatever the kind, the rest of the zone sees the same thing: height_at(x, z) (the drawn and
## walked ground), `material` (set_shader_parameter: grass_tint…), `water`, bed_look().
## The relief is the 2.5D's (HeightMap), stretched to the zone's scale; the ground runs on past the
## edges (the 2.5D's margin) so no edge shows in the distance.
## A REMODELLED zone (TerrainRelief.remodelled: its plan's relief, docs/conception-zones-3d.md) has the
## water of its relief, not the 2.5D's: one sheet per body of water (its sea, its ponds: `waters`), each
## at its own level and reading the relief's bed, and its brooks as Waterways rivers (`brooks`).
## water_level_at / water_depth_at say where the water stands, whatever the zone; plan_allows says
## where the plan keeps its paths, clearings and water clear of scenery.

enum Kind { MESH, TERRAIN3D }
const DEFAULT_KIND := Kind.TERRAIN3D   # the base of the 3D relief (Greg, 04/10); MESH: the way back
## Set before a zone is built to choose its ground (the tests compare the two); -1: the default.
static var kind_override := -1
## Set before a zone is built to give its relief these edits instead of its file's (an Array of
## TerrainRelief edits: tools/test_terrain3d.gd builds the Prairie as the 2.5D had it, not
## remodelled, with TerrainRelief.DEFAULT_EDITS); null: the zone's own.
static var edits_override: Variant = null
## The clearance a plan keeps beside its paths for anything big (docs/zones-3d/<zone>-plan.md:
## 1.5 m by a main path, 1.2 m by a secondary one, 1 m by a trail), by the path's kind.
const PATH_CLEAR_M := {"main": 1.5, "secondary": 1.2, "trail": 1.0}
const SCENERY_WET_M := 0.05       # scenery does not stand in the water (a ford's shoal: 0.1 m)
const POND_BANK_M := 0.3          # a pond's water reaches this far past its ellipse (TerrainRelief.water_level_at)
const DRY := 50.0                 # a bed this far above its water: the sheet draws nothing there
const POND_SHEET_MARGIN_M := 4.0  # a pond's sheet runs this far past its shape (its shore's foam)
## A pond's level reaches this far past its shape on the painting's water map, over its banks (the
## relief raises them back over 4 m: terrain3d_relief_shapes.gd POND_BANK_M), for its wet shore.
const WET_REACH_M := 4.0

const SHADER := preload("res://world3d/zone3d/terrain.gdshader")
const CHUNK_M := 32               # metres per chunk side
const STEP_M := 1.0               # metres between two vertices (and two collision samples)
const VIEW_M := 220.0             # chunks further than this are not drawn
const GROUND := {
	"grass": "res://assets/art/ground/herbe.png", "dirt": "res://assets/art/ground/terre.png",
	"mud": "res://assets/art/ground/vase.png", "rock": "res://assets/art/ground/roche_canyon.png",
	"cliff": "res://assets/art/ground/falaise.png",
}
## The bed under the water (terrain.gdshader: bed_tint, bed_shade). It keeps its own sand and
## pebbles; the water only lends it its colour and dims it. The colour follows the zone's own
## shallow water (the 2.5D's WorldView.WATER_TINT: clear blue-green on the coast, murky green in
## the marsh), so a new zone is right without being listed. BED_SHADE says how dark the bottom
## goes; a zone that needs something else of its own goes in BED, by region id.
const BED_WATER_SHARE := 0.6      # how much of the water's colour the bed takes
const BED_SHADE := 0.42           # how dark the deepest bed goes (1: not at all)
const BED := {
	&"marais": {"tint": Color(0.62, 0.72, 0.5), "shade": 0.3},      # murky, little light gets down
	&"monts_geles": {"tint": Color(0.82, 0.92, 0.98), "shade": 0.6},  # pale, icy, shallow
}
## The water's colour bands follow the depth of the bed. False: the 2.5D's bed (0.85 m everywhere),
## the look Greg validated, even over the deeper sea of Terrain3D. True: the real, deeper bed.
const WATER_SEES_DEEP_SEA := false

var source: ZoneSource
var kind := Kind.MESH
## The ground's material: a ShaderMaterial (MESH), or Terrain3D's seen through the same
## set_shader_parameter / get_shader_parameter (TERRAIN3D).
var material: Variant
var body: StaticBody3D            # the collision of the MESH ground (Terrain3D holds its own)
var ground3d: ZoneGroundTerrain3D # the TERRAIN3D ground (null with the mesh)
## The relief of the TERRAIN3D ground (terrain3d_relief.gd: the 2.5D's, then the zone's edits; null with the mesh).
var relief: TerrainRelief
## Where the zone's corner stands in the world (m, x and z): this node's position when it is built.
## height_at and everything else stay in the zone's own metres.
var world_offset := Vector2.ZERO
var water: Node3D                 # the water sheet (null in a zone without water); a remodelled zone: its sea's
## Every water sheet of the zone (one; a remodelled zone: one per body of water of its relief).
var waters: Array[ZoneWater] = []
## A remodelled zone's brooks, as Waterways rivers (TerrainRelief.BROOKS).
var brooks: Array[Node3D] = []
## What the build took (ms).
var build_ms := 0

var _origin := Vector2.ZERO     # metres: the corner of the ground (the margin beyond the zone)
var _step := STEP_M
var _samples := Vector2i.ZERO   # samples along x and z
var _heights := PackedFloat32Array()
var _sea_level := -INF          # a remodelled zone: its sea's level (any ground under it is sea)
var _plan_paths: Array[Dictionary] = []   # a remodelled zone's paths: {line, half, clear, box}
var _plan_clearings: Array[Dictionary] = []   # …and clearings: {at, radius}


func build(src: ZoneSource) -> void:
	var t0 := Time.get_ticks_msec()
	set_process(false)   # (only with several water sheets: see _process)
	source = src
	var margin := src.margin_m()
	_origin = Vector2(-margin, -margin)
	var extent := src.size_m() + Vector2.ONE * margin * 2.0
	var at := global_position if is_inside_tree() else position
	world_offset = Vector2(at.x, at.z)
	kind = chosen_kind()
	var mat := _material()
	if kind == Kind.TERRAIN3D:
		relief = TerrainRelief.from_source(src)
		var edits: Array = edits_override if edits_override is Array else TerrainRelief.edits_of(src.id)
		var saved := ZoneGroundTerrain3D.saved_regions(src.id)
		if saved == "":
			relief.apply(edits)
		else:
			relief.apply(edits.filter(func(e: Dictionary) -> bool: return e.get("op") == "paint"))
		var masks := relief.mask_textures()
		mat.set_shader_parameter("mask_a", masks[0])
		mat.set_shader_parameter("mask_b", masks[1])
		if is_remodelled():
			_read_plan()
			# the wet sand and the dimmed bed of the ground's painting: at each body of water's own level
			# (its sea, its ponds), not the 2.5D's water
			mat.set_shader_parameter("water_level", _sea_level if _sea_level > -INF else -100.0)
			var levels := _water_map(extent)
			mat.set_shader_parameter("use_water_map", true)
			mat.set_shader_parameter("water_map", levels["texture"])
			mat.set_shader_parameter("water_map_origin", levels["origin"])
			mat.set_shader_parameter("water_map_texels", levels["texels"])
		ground3d = ZoneGroundTerrain3D.new()
		ground3d.name = "Ground3D"
		add_child(ground3d)
		ground3d.build(relief, world_offset, mat, saved)
		material = ground3d.material
		_step = relief.step
		_samples = relief.samples
		_heights = relief.heights
	else:
		material = mat
		_step = STEP_M
		_samples = Vector2i(int(extent.x / STEP_M) + 1, int(extent.y / STEP_M) + 1)
		_sample_heights()
		_build_chunks()
		_build_collision()
	if is_remodelled():
		_build_relief_water(extent)
	elif src.heights.has_water:
		_build_water(extent)
	build_ms = Time.get_ticks_msec() - t0
	print("ZoneTerrain : sol %s, %d ms%s%s" % ["Terrain3D" if kind == Kind.TERRAIN3D else "maillage maison", build_ms,
		" (relief %s, régions %s)" % [relief.timings, ground3d.loaded_from if ground3d.loaded_from != "" else "calculées"] if ground3d else "",
		" ; zone remodelée : %d nappe(s) d'eau, %d ru(s)" % [waters.size(), brooks.size()] if is_remodelled() else ""])


## The ground the next zone gets: kind_override, else `--terrain=mesh|terrain3d`, else DEFAULT_KIND;
## Terrain3D only where it can draw.
static func chosen_kind() -> Kind:
	var want: int = DEFAULT_KIND if kind_override < 0 else kind_override
	for arg in OS.get_cmdline_user_args():
		if arg == "--terrain=mesh":
			want = Kind.MESH
		elif arg == "--terrain=terrain3d":
			want = Kind.TERRAIN3D
	if want == Kind.TERRAIN3D and not ZoneGroundTerrain3D.available():
		print("ZoneTerrain : Terrain3D indisponible ici (extension absente ou rendu %s) : sol maison" % RenderingServer.get_current_rendering_method())
		return Kind.MESH
	return want as Kind


## Height (m) of the ground at a point: the drawn ground, the one walked on (bilinear between the
## samples of the collision).
func height_at(x: float, z: float) -> float:
	var g := (Vector2(x, z) - _origin) / _step
	var ix := clampi(floori(g.x), 0, _samples.x - 2)
	var iz := clampi(floori(g.y), 0, _samples.y - 2)
	var fx := clampf(g.x - ix, 0.0, 1.0)
	var fz := clampf(g.y - iz, 0.0, 1.0)
	var top := lerpf(_h(ix, iz), _h(ix + 1, iz), fx)
	var bottom := lerpf(_h(ix, iz + 1), _h(ix + 1, iz + 1), fx)
	return lerpf(top, bottom, fz)


func _h(ix: int, iz: int) -> float:
	return _heights[iz * _samples.x + ix]


## True when the zone's relief is its plan's (TerrainRelief.remodelled): the 2.5D's tiles no longer
## say where its woods, water and cliffs are.
func is_remodelled() -> bool:
	return relief != null and relief.remodelled


## The level (m) of the water standing over (x, z), -INF where there is none. A remodelled zone: its
## relief's water (its ponds' shapes; its sea: any ground under the sea's level). Else the 2.5D's one
## water level, over whatever is dug under it.
func water_level_at(x: float, z: float) -> float:
	if is_remodelled():
		var level := relief.water_level_at(x, z)
		if _sea_level > -INF and height_at(x, z) < _sea_level:
			level = maxf(level, _sea_level)
		return level
	return HeightMap.WATER_LEVEL if source.heights.has_water else -INF


## How deep the water is over (x, z) (m; 0 or less: dry ground).
func water_depth_at(x: float, z: float) -> float:
	return water_level_at(x, z) - height_at(x, z)


## Whether scenery may stand at (x, z): not in the water; in a remodelled zone, not on its plan's paths
## either, and nothing `big` (a tree, a rock, anything solid) within their clearance or in its clearings
## (docs/zones-3d/<zone>-plan.md: « rien de moyen ou de grand » there). The 2.5D's scenery stood where
## its own map wanted it; the plan moved the places.
func plan_allows(x: float, z: float, big: bool) -> bool:
	if water_depth_at(x, z) > SCENERY_WET_M:
		return false
	if not is_remodelled():
		return true
	var p := Vector2(x, z)
	for path in _plan_paths:
		var reach: float = path["half"] + (path["clear"] if big else 0.0)
		if (path["box"] as Rect2).grow(reach).has_point(p) and TerrainRelief.SHAPES._distance_to(path["line"], x, z) < reach:
			return false
	if big:
		for c in _plan_clearings:
			if p.distance_to(c["at"]) < float(c["radius"]):
				return false
	return true


## Whether (x, z) is within `reach` m of the band of one of the plan's paths (closer to its line than
## its half-width plus `reach`) — leaving out the paths that pass within `skip_r` of `skip` (the path a
## hedge's gap is left for: the gap is its way through).
func near_path(x: float, z: float, reach: float, skip := Vector2.INF, skip_r := 0.0) -> bool:
	var p := Vector2(x, z)
	for path in _plan_paths:
		var line: PackedVector2Array = path["line"]
		var r: float = path["half"] + reach
		if not (path["box"] as Rect2).grow(r).has_point(p) or TerrainRelief.SHAPES._distance_to(line, x, z) >= r:
			continue
		if skip != Vector2.INF and TerrainRelief.SHAPES._distance_to(line, skip.x, skip.y) < skip_r:
			continue
		return true
	return false


## The way the plan's path nearest (x, z) runs there (a unit vector; ZERO without a plan): what lies
## across a path (a log, a door) lies across that.
func path_way_at(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best := INF
	var way := Vector2.ZERO
	for path in _plan_paths:
		var line: PackedVector2Array = path["line"]
		for i in line.size() - 1:
			var ab := line[i + 1] - line[i]
			var t := clampf((p - line[i]).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
			var d := p.distance_to(line[i] + ab * t)
			if d < best:
				best = d
				way = ab.normalized()
	return way


## A remodelled zone's paths and clearings (its relief's `layout`), and its sea's level.
func _read_plan() -> void:
	var shapes: RefCounted = relief.shapes
	for w: Dictionary in shapes.get("waters"):
		if w["kind"] == "sea":
			_sea_level = maxf(_sea_level, float(w["level"]))
	for p: Dictionary in shapes.get("paths"):
		var line: PackedVector2Array = TerrainRelief.SHAPES._points(p["points"])
		_plan_paths.append({"line": line, "half": float(p["width_m"]) * 0.5, "clear": float(PATH_CLEAR_M.get(String(p.get("kind", "trail")), 1.0)),
			"box": TerrainRelief.SHAPES._bounds(line)})
	for c: Dictionary in shapes.get("clearings"):
		_plan_clearings.append({"at": Vector2(float(c["center"][0]), float(c["center"][1])), "radius": float(c["radius"])})


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
	mat.set_shader_parameter("zone_origin", world_offset)
	mat.set_shader_parameter("water_level", HeightMap.WATER_LEVEL if source.heights.has_water else -100.0)
	var bed := bed_look(source.region.region_id)
	mat.set_shader_parameter("bed_tint", bed["tint"])
	mat.set_shader_parameter("bed_shade", bed["shade"])
	return mat


## How the bed under the water looks in a zone: {tint, shade} (see BED).
static func bed_look(region_id: StringName) -> Dictionary:
	if BED.has(region_id):
		return BED[region_id]
	var shades: Array = WorldView.WATER_TINT.get(region_id, WorldView.WATER_DEFAULT)
	return {"tint": Color.WHITE.lerp((shades[0] as Color).lightened(0.3), BED_WATER_SHARE), "shade": BED_SHADE}


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


## The water sheet: ZoneWater paints it and keeps it in the colour of the sky of the hour.
func _build_water(extent: Vector2) -> void:
	var sheet := ZoneWater.new()
	sheet.name = "Water"
	sheet.build(source, _origin, extent)
	if WATER_SEES_DEEP_SEA and ground3d:
		_show_deep_bed(sheet)
	add_child(sheet)
	water = sheet
	waters.append(sheet)


## Hands the water the real bed of the Terrain3D ground in place of the 2.5D's (WATER_SEES_DEEP_SEA):
## the same kind of texture ZoneWater reads (origin and resolution in tiles of the 2.5D zone).
func _show_deep_bed(sheet: ZoneWater) -> void:
	var bed := _bed_texture(_heights)
	sheet.material.set_shader_parameter("ground_height", bed["texture"])
	sheet.material.set_shader_parameter("height_origin", bed["origin"])
	sheet.material.set_shader_parameter("height_res", bed["res"])
	sheet.material.set_shader_parameter("height_texels", bed["texels"])


## The relief's heights as the bed a water sheet reads: {texture, origin (tiles), res (samples per
## tile), texels}, as HeightMap.height_texture gives the 2.5D's.
func _bed_texture(heights: PackedFloat32Array) -> Dictionary:
	var img := Image.create_from_data(_samples.x, _samples.y, false, Image.FORMAT_RF, heights.to_byte_array())
	img.convert(Image.FORMAT_RH)
	return {"texture": ImageTexture.create_from_image(img), "origin": _origin / source.scale, "res": source.scale / _step,
		"texels": Vector2(_samples)}


## A remodelled zone's water: a sheet per body of water of its relief, at its own level, over its own
## bed. The sea's runs on past the zone (any ground under its level is sea, out to the skyline); a
## pond's covers its own ground only (ground of the zone lower than the pond but outside it is told to
## the sheet as dry, or the pond would flood the prairie). Then its brooks (Waterways rivers).
func _build_relief_water(extent: Vector2) -> void:
	var bodies: Array = relief.shapes.get("waters") if relief.shapes else []
	for w: Dictionary in bodies:
		var level := float(w["level"])
		var sea := String(w["kind"]) == "sea"
		var sheet := ZoneWater.new()
		sheet.name = "Water_%s" % w["id"]
		var area := _body_area(w)
		if sea:
			sheet.build_at(source, _origin, extent, level, _bed_texture(_heights), ZoneWater.HORIZON_M)
		else:
			var around := area.grow(POND_SHEET_MARGIN_M)
			sheet.build_at(source, around.position, around.size, level, _bed_texture(_own_bed(w)), 0.0)
		sheet.area = area
		add_child(sheet)
		waters.append(sheet)
		if sea or water == null:
			water = sheet
	brooks = TerrainRelief.BROOKS.build(relief, self)
	set_process(waters.size() > 1)


## The heights a pond's sheet reads: the relief's, but ground lower than its water outside it raised
## out of the water (DRY).
func _own_bed(w: Dictionary) -> PackedFloat32Array:
	var level := float(w["level"])
	var out := _heights.duplicate()
	for iz in _samples.y:
		var z := _origin.y + iz * _step
		var row := iz * _samples.x
		for ix in _samples.x:
			if out[row + ix] < level and not _in_body(w, Vector2(_origin.x + ix * _step, z)):
				out[row + ix] = level + DRY
	return out


## The level each point of the ground goes by for its wet shore and its dimmed bed (the painting's
## water_map): a pond's within WET_REACH_M of it, else the sea's. A texel per metre, from _origin:
## {texture (half floats: filtered everywhere), origin (m), texels}.
func _water_map(extent: Vector2) -> Dictionary:
	var texels := Vector2i(int(extent.x) + 1, int(extent.y) + 1)
	var img := Image.create(texels.x, texels.y, false, Image.FORMAT_RF)
	var ponds: Array = (relief.shapes.get("waters") as Array).filter(func(w: Dictionary) -> bool: return w["kind"] != "sea")
	var base := _sea_level if _sea_level > -INF else -100.0
	for iz in texels.y:
		for ix in texels.x:
			var p := _origin + Vector2(ix, iz)
			var level := base
			for w: Dictionary in ponds:
				if _in_body(w, p, WET_REACH_M):
					level = maxf(level, float(w["level"]))
			img.set_pixel(ix, iz, Color(level, 0.0, 0.0))
	img.convert(Image.FORMAT_RH)
	return {"texture": ImageTexture.create_from_image(img), "origin": _origin, "texels": Vector2(texels)}


## Whether (x, z) is in a body of water of the relief (its polygon; its ellipse and the first `reach`
## m of its bank — POND_BANK_M: as TerrainRelief.water_level_at reads it).
static func _in_body(w: Dictionary, p: Vector2, reach := POND_BANK_M) -> bool:
	if w.has("ellipse"):
		var c := Vector2(float(w["ellipse"]["center"][0]), float(w["ellipse"]["center"][1]))
		var r := Vector2(float(w["ellipse"]["radii"][0]), float(w["ellipse"]["radii"][1]))
		return (Vector2((p.x - c.x) / r.x, (p.y - c.y) / r.y).length() - 1.0) * minf(r.x, r.y) <= reach
	if w.has("polygon"):
		return Geometry2D.is_point_in_polygon(p, TerrainRelief.SHAPES._points(w["polygon"]))
	return false


## The ground a body of water covers (m of the zone): its ellipse's or its polygon's bounds.
static func _body_area(w: Dictionary) -> Rect2:
	if w.has("ellipse"):
		var c := Vector2(float(w["ellipse"]["center"][0]), float(w["ellipse"]["center"][1]))
		var r := Vector2(float(w["ellipse"]["radii"][0]), float(w["ellipse"]["radii"][1])) + Vector2.ONE * POND_BANK_M
		return Rect2(c - r, r * 2.0)
	if w.has("polygon"):
		return TerrainRelief.SHAPES._bounds(TerrainRelief.SHAPES._points(w["polygon"]))
	return Rect2()


## With several sheets, only the one nearest the camera mirrors the scene (ZoneWater.mirror_wanted):
## each mirror is a second rendering of the zone, and two cost twice as much.
func _process(_delta: float) -> void:
	var eye := get_viewport().get_camera_3d()
	if eye == null:
		return
	var at := to_local(eye.global_position)
	var flat := Vector2(at.x, at.z)
	var nearest: ZoneWater = null
	var best := INF
	for sheet in waters:
		var r := sheet.area
		var d := Vector2(maxf(maxf(r.position.x - flat.x, flat.x - r.end.x), 0.0), maxf(maxf(r.position.y - flat.y, flat.y - r.end.y), 0.0)).length()
		if d < best:
			best = d
			nearest = sheet
	for sheet in waters:
		sheet.mirror_wanted = sheet == nearest
