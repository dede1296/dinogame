class_name Scatter3D
extends Node3D
## The scenery of a 3D zone (docs/migration-3d.md, phase 4), at its real size on the wider map:
## - the 2.5D zone's own scenery (its Prop nodes: trees, rocks, ferns, flowers…), each where it was;
## - woods on its forest tiles (the 2.5D's tree kinds: WorldView.FOREST_TREES / ZONE_TREES, bushes
##   by the trails), so many per square metre, the map being wider than the 2.5D's;
## - a little more fern and flowers on the open grass, the same way.
## A kind with a 3D model (nature_models.gd) is shown as that model, turned at random; else as its
## 2.5D picture standing up (a billboard), until its model comes. Drawn in batches (one MultiMesh
## per kind and per 32 m square), small plants not drawn far away.

const NATURE := "res://world3d/zone3d/nature_models.gd"
const TOON := preload("res://world3d/render/toon_style.gd")
const ART := "res://assets/art/props/%s.png"
const PX := 48.0
const STRETCH := 1.15            # WorldView.STRETCH: the 2.5D shows its pictures this much taller
const CHUNK_M := 32.0
const WOODS_M2 := 6.0            # square metres of woods per tree
const FILL_M2 := 14.0            # square metres of open grass per fern or flower
const FILL := {"fougeres": 4, "fleurs_roses": 2, "fleurs_violettes": 2, "cailloux": 1, "buisson": 1}
const SMALL_RANGE_M := 50.0     # (measured: halving the ranges doubles the frame rate; the haze hides the rest)
const TREE_RANGE_M := 150.0
const TREES := ["arbre_rond", "araucaria", "fougere_arbre"]
## Too thin for an outline: far off, their stems turn into dark sticks.
const NO_OUTLINE := ["fleurs_roses", "fleurs_violettes", "champignons", "prele"]
const LOD_MERGE_DEG := 25.0   # normals this close are merged when simplifying (ImporterMesh.generate_lods)
const LOD_SPLIT_DEG := 60.0
const LOD_BIAS := 0.3   # the scenery's simpler versions sooner than the people's (1: Godot's own threshold)

var source: ZoneSource
var terrain: ZoneTerrain

var _models := {}       # kind → Array[Mesh] (3D models) — or [] (picture)
var _items := {}        # kind → Array of [Vector3 position, float yaw, float scale]


func build(src: ZoneSource, ground: ZoneTerrain) -> void:
	source = src
	terrain = ground
	_load_models()
	for prop in src.props():
		_place(prop["kind"], prop["at"], PI if prop["flip"] else 0.0, 1.0)
	_woods()
	_fill()
	for kind: String in _items:
		_draw(kind, _items[kind])


## How many of each kind were placed (for the tests and the log).
func counts() -> Dictionary:
	var out := {}
	for kind: String in _items:
		out[kind] = (_items[kind] as Array).size()
	return out


func _load_models() -> void:
	if not ResourceLoader.exists(NATURE):
		return
	var table: Dictionary = (load(NATURE) as Script).get_script_constant_map().get("MODELS", {})
	for kind: String in table:
		var meshes: Array[Mesh] = []
		for path: String in table[kind]:
			if ResourceLoader.exists(path):
				var mesh := _merged_mesh(load(path) as PackedScene, not kind in NO_OUTLINE)
				if mesh:
					meshes.append(mesh)
		if not meshes.is_empty():
			_models[kind] = meshes


## A model's meshes as one mesh (its parts moved where they stand in the scene), for a MultiMesh.
func _merged_mesh(scene: PackedScene, outline := true) -> Mesh:
	if scene == null:
		return null
	var root := scene.instantiate() as Node3D
	TOON.apply(root, {"fade": false, "outline": outline})   # the cartoon look, as Chloé and the dinos
	var out := ImporterMesh.new()   # (to give the merged model its levels of detail, as an import does)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var to_root := Transform3D.IDENTITY
		var n: Node = mi
		while n != null and n != root:
			if n is Node3D:
				to_root = (n as Node3D).transform * to_root
			n = n.get_parent()
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for i in verts.size():
				verts[i] = to_root * verts[i]
			arrays[Mesh.ARRAY_VERTEX] = verts
			if arrays[Mesh.ARRAY_NORMAL] != null:
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				for i in normals.size():
					normals[i] = (to_root.basis * normals[i]).normalized()
				arrays[Mesh.ARRAY_NORMAL] = normals
			if arrays[Mesh.ARRAY_TANGENT] != null:   # (the outline's smoothed normals, toon_style)
				var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
				@warning_ignore("integer_division")
				for i in tangents.size() / 4:
					var t := (to_root.basis * Vector3(tangents[i * 4], tangents[i * 4 + 1], tangents[i * 4 + 2])).normalized()
					tangents[i * 4] = t.x
					tangents[i * 4 + 1] = t.y
					tangents[i * 4 + 2] = t.z
				arrays[Mesh.ARRAY_TANGENT] = tangents
			arrays[Mesh.ARRAY_BONES] = null
			arrays[Mesh.ARRAY_WEIGHTS] = null
			out.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, mi.get_active_material(s))
	root.free()
	if out.get_surface_count() == 0:
		return null
	# simpler versions of it, drawn further off (each batch of 32 m picks one by its distance)
	out.generate_lods(LOD_MERGE_DEG, LOD_SPLIT_DEG, [])
	return out.get_mesh()


func _place(kind: String, at: Vector3, yaw: float, size: float) -> void:
	if not Prop.KINDS.has(kind):
		return
	if not _items.has(kind):
		_items[kind] = []
	_items[kind].append([at, yaw, size])


## Trees on the forest tiles: so many per square metre, bushes mostly by the trails (as the 2.5D).
func _woods() -> void:
	var tile_m2 := source.scale * source.scale
	for y in source.tiles.y:
		for x in source.tiles.x:
			if source.surface(Vector2i(x, y)) != &"forest":
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(Vector2i(x, y) * 7 + Vector2i(3, 11))
			var own: Dictionary = WorldView._woods_at(source.region, Vector2(x + 0.5, y + 0.5))
			var trees: Array = own.get("forest", WorldView.FOREST_TREES)
			var low: Array = own.get("low", ["buisson"])
			var by_path := WorldView._by_path(source.region, x, y)
			var count := int(tile_m2 / WOODS_M2 + rng.randf())
			for i in count:
				var kind: String = trees[rng.randi() % trees.size()]
				if rng.randf() < (0.6 if by_path else 0.15):
					kind = low[rng.randi() % low.size()]
				var px := (x + rng.randf_range(0.1, 0.9)) * source.scale
				var pz := (y + rng.randf_range(0.1, 0.9)) * source.scale
				_place(kind, Vector3(px, terrain.height_at(px, pz), pz), rng.randf() * TAU, rng.randf_range(0.85, 1.25))


## A few ferns and flowers on the open grass, away from the trails, the water and the slopes.
func _fill() -> void:
	var kinds: Array[String] = []
	for kind: String in FILL:
		for i in FILL[kind]:
			kinds.append(kind)
	var tile_m2 := source.scale * source.scale
	for y in source.tiles.y:
		for x in source.tiles.x:
			if source.surface(Vector2i(x, y)) != &"grass":
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(Vector2i(x, y) * 13 + Vector2i(5, 1))
			if rng.randf() > tile_m2 / FILL_M2:
				continue
			var px := (x + rng.randf_range(0.1, 0.9)) * source.scale
			var pz := (y + rng.randf_range(0.1, 0.9)) * source.scale
			var h := terrain.height_at(px, pz)
			if absf(terrain.height_at(px + 0.5, pz) - h) > 0.2 or absf(terrain.height_at(px, pz + 0.5) - h) > 0.2:
				continue   # a slope: a cliff's face
			_place(kinds[rng.randi() % kinds.size()], Vector3(px, h, pz), rng.randf() * TAU, rng.randf_range(0.8, 1.2))


func _draw(kind: String, items: Array) -> void:
	var meshes: Array = _models.get(kind, [])
	var tree := kind in TREES or kind == "rocher"
	var range_end := TREE_RANGE_M if tree else SMALL_RANGE_M
	if meshes.is_empty():
		var picture := _picture(kind)
		if picture:
			_batches(picture, items, range_end, tree, true)
		return
	# several variants: share the items out among them, by position
	var parts := []
	parts.resize(meshes.size())
	for i in parts.size():
		parts[i] = []
	for it: Array in items:
		var at: Vector3 = it[0]
		parts[absi(hash(Vector2i(roundi(at.x * 10.0), roundi(at.z * 10.0)))) % meshes.size()].append(it)
	for i in meshes.size():
		_batches(meshes[i], parts[i], range_end, tree, false)


## One MultiMesh per CHUNK_M square: models turned and sized, pictures sized (they face the camera).
func _batches(mesh: Mesh, items: Array, range_end: float, shadows: bool, picture: bool) -> void:
	var chunks := {}
	for it: Array in items:
		var at: Vector3 = it[0]
		var key := Vector2i(floori(at.x / CHUNK_M), floori(at.z / CHUNK_M))
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(it)
	for key: Vector2i in chunks:
		var list: Array = chunks[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i in list.size():
			var it: Array = list[i]
			var turn := Basis.from_scale(Vector3.ONE * float(it[2]))
			if not picture:
				turn = Basis(Vector3.UP, float(it[1])) * turn
			elif float(it[1]) > 1.0:   # a flipped picture
				turn = turn * Basis.from_scale(Vector3(-1, 1, 1))
			mm.set_instance_transform(i, Transform3D(turn, it[0]))
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		inst.visibility_range_end = range_end
		inst.visibility_range_end_margin = 12.0
		inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF   # fades out, no popping
		inst.lod_bias = LOD_BIAS
		add_child(inst)


## A kind's 2.5D picture standing up at its 2.5D size, its foot on the ground, facing the camera.
func _picture(kind: String) -> Mesh:
	var path := ART % kind
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	var def: Dictionary = Prop.KINDS[kind]
	var h := tex.get_height() * float(def["scale"]) / PX * STRETCH
	var w := tex.get_width() * float(def["scale"]) / PX
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	quad.center_offset = Vector3(0.0, h * (0.5 - float(def.get("foot", 0.0))), 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	quad.material = mat
	return quad
