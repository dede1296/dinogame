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
## Everything stands on the ground the zone is drawn with (ZoneTerrain.height_at), not the 2.5D's.
## In a REMODELLED zone (its plan's relief) the 2.5D's scenery keeps its places but where the plan
## wants the ground clear (ZoneTerrain.plan_allows: its water, its paths and their clearance, its
## clearings); its woods are walked through, between trunks that stop her (`trunks`: the woods are
## no longer walls); and what the plan says stops her is seen (`plan`, Blockers3D's): its hedges and
## banks are rows of brambles, bushes and blocks along their lines, its dense edges thick woods.

const NATURE := "res://world3d/zone3d/nature_models.gd"
const TOON := preload("res://world3d/render/toon_style.gd")
const ART := "res://assets/art/props/%s.png"
const PX := 48.0
const STRETCH := 1.15            # WorldView.STRETCH: the 2.5D shows its pictures this much taller
const CHUNK_M := 32.0
const WOODS_M2 := 6.0            # square metres of woods per tree
const FILL_M2 := 14.0            # square metres of open grass per fern or flower
const FILL := {"fougeres": 4, "fleurs_roses": 2, "fleurs_violettes": 2, "cailloux": 1, "buisson": 1}
## How far each kind is still drawn (m). Beyond, the sky's far haze takes over (ZoneSky): raised
## on 04/10 because the trees stopping in plain sight was visible (measured: halving the ranges
## doubles the frame rate).
const SMALL_RANGE_M := 120.0
const TREE_RANGE_M := 240.0
const TREES := ["arbre_rond", "araucaria", "fougere_arbre"]
## Too thin for an outline: far off, their stems turn into dark sticks.
const NO_OUTLINE := ["fleurs_roses", "fleurs_violettes", "champignons", "prele"]
const LOD_MERGE_DEG := 25.0   # normals this close are merged when simplifying (ImporterMesh.generate_lods)
const LOD_SPLIT_DEG := 60.0
const LOD_BIAS := 0.3   # the scenery's simpler versions sooner than the people's (1: Godot's own threshold)
## A remodelled zone's hedges and banks, as they are drawn: so many plants per metre of their line,
## across their width; each kind's share and size (× its model: bushes 1 m, brambles 0.85 m, rocks
## 1 m; brambles larger than that grow berries the size of apples).
const HEDGE_PER_M := 3.0
const HEDGE_KINDS := [["buisson", 0.45, 1.4, 1.8], ["ronces", 0.35, 1.1, 1.4], ["souche", 0.08, 1.2, 1.6]]
const TRUNK_HEIGHT_M := 2.5

var source: ZoneSource
var terrain: ZoneTerrain
var blockers: Blockers3D
## A remodelled zone: the trunks of the trees it sowed, what stops Chloé in its woods (null elsewhere).
var trunks: StaticBody3D

var _models := {}       # kind → Array[Mesh] (3D models) — or [] (picture)
var _items := {}        # kind → Array of [Vector3 position, float yaw, float scale]
var _trunk_spots: Array = []   # [Vector3, radius (m)] of the sown trees (a remodelled zone)


## Sows the zone's scenery. `walls`: what stops Chloé (Blockers3D): a remodelled zone's plan blockers
## are made visible, and its scenery stands where they let it (Blockers3D.allows: the same rule).
func build(src: ZoneSource, ground: ZoneTerrain, walls: Blockers3D = null) -> void:
	source = src
	terrain = ground
	blockers = walls
	var plan: Array = walls.plan if walls else []
	_load_models()
	for prop in src.props():
		var at: Vector3 = prop["at"]
		if not _allows(at.x, at.z, _big(prop["kind"])):
			continue
		at.y = ground.height_at(at.x, at.z)   # (the 2.5D's height is not the ground's)
		_place(prop["kind"], at, PI if prop["flip"] else 0.0, 1.0)
	_woods()
	_fill()
	if ground.is_remodelled():
		_show_plan(plan)
		_build_trunks()
	for kind: String in _items:
		_draw(kind, _items[kind])


func _allows(x: float, z: float, big: bool) -> bool:
	return blockers.allows(x, z, big) if blockers else terrain.plan_allows(x, z, big)


## Something big: a tree, or anything that stops Chloé (Prop.KINDS "solid").
static func _big(kind: String) -> bool:
	var solid: Variant = Prop.KINDS.get(kind, {}).get("solid", 0.0)
	return kind in TREES or solid is Vector2 or (solid is float and solid > 0.0)


## How many of each kind were placed (for the tests and the log).
## Where a kind was sown: an Array of [position (Vector3), yaw, size]. Empty if it has none.
func placed(kind: String) -> Array:
	return _items.get(kind, [])


## The meshes a kind is drawn with (several variants), or [] when it is drawn as a picture.
func meshes_of(kind: String) -> Array:
	return _models.get(kind, [])


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
				var yaw := rng.randf() * TAU
				var size := rng.randf_range(0.85, 1.25)
				if not _allows(px, pz, _big(kind)):
					continue
				_place(kind, Vector3(px, terrain.height_at(px, pz), pz), yaw, size)
				_trunk(kind, px, pz, size)


## A remodelled zone's woods are walked through: each tree sown there has its trunk (its Prop.KINDS
## radius), what stops her between them.
func _trunk(kind: String, x: float, z: float, size: float) -> void:
	if not terrain.is_remodelled() or not kind in TREES:
		return
	_trunk_spots.append([Vector3(x, terrain.height_at(x, z), z), float(Prop.KINDS[kind]["solid"]) / PX * size])


func _build_trunks() -> void:
	if _trunk_spots.is_empty():
		return
	trunks = StaticBody3D.new()
	trunks.name = "Troncs"
	trunks.collision_layer = Layers3D.WORLD
	trunks.collision_mask = 0
	trunks.add_to_group(&"nav_source")
	for spot: Array in _trunk_spots:
		var cyl := CylinderShape3D.new()
		cyl.radius = spot[1]
		cyl.height = TRUNK_HEIGHT_M
		var shape := CollisionShape3D.new()
		shape.shape = cyl
		shape.position = (spot[0] as Vector3) + Vector3(0, TRUNK_HEIGHT_M * 0.5 - 0.3, 0)
		trunks.add_child(shape)
	add_child(trunks)


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
			var kind := kinds[rng.randi() % kinds.size()]
			if not _allows(px, pz, _big(kind)):
				continue
			_place(kind, Vector3(px, h, pz), rng.randf() * TAU, rng.randf_range(0.8, 1.2))


## What a remodelled zone's plan says stops Chloé, made visible (Blockers3D holds the walls): its
## hedges and banks, rows of brambles, bushes, blocks and stumps along their lines, open where their
## walls are (the gap, the plan's paths: Blockers3D._wall_spans' rule); its dense edges, thick woods
## (but where the 2.5D's woods already stand).
func _show_plan(plan: Array) -> void:
	for b: Dictionary in plan:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(String(b.get("id", "")))
		match String(b.get("kind", "")):
			"hedge", "bank":
				var half := float(b["width_m"]) * 0.5
				var gap: Dictionary = b.get("gap", {})
				var gap_at := Vector2(float(gap["at"][0]), float(gap["at"][1])) if gap.has("at") else Vector2.INF
				var gap_r := float(gap.get("width_m", 0.0)) * 0.5
				var lines := []
				if b.has("polyline"):
					lines.append([b["polyline"], bool(b.get("closed", false))])
				if b.has("polyline2"):
					lines.append([b["polyline2"], false])
				for line: Array in lines:
					_hedge(line[0], line[1], half, gap_at, gap_r, rng)
			"forest_edge":
				for key in ["polygon", "polygon2"]:
					if b.has(key):
						_thicket(b[key], rng)


func _hedge(points: Array, closed: bool, half: float, gap_at: Vector2, gap_r: float, rng: RandomNumberGenerator) -> void:
	var line: PackedVector2Array = TerrainRelief.SHAPES._points(points)
	if closed:
		line.append(line[0])
	var total := 0.0
	for k in HEDGE_KINDS:
		total += float(k[1])
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var dir := (b - a).normalized()
		var side := Vector2(-dir.y, dir.x)
		var count := int(a.distance_to(b) * HEDGE_PER_M)
		for n in count:
			var on_line := a.lerp(b, (n + rng.randf()) / count)
			var p := on_line + side * rng.randf_range(-half, half) * 0.85
			if on_line.distance_to(gap_at) < gap_r or terrain.near_path(on_line.x, on_line.y, half, gap_at, gap_r):
				continue   # (where its wall is left open)
			var pick := rng.randf() * total
			for k: Array in HEDGE_KINDS:
				pick -= float(k[1])
				if pick <= 0.0:
					_place(k[0], Vector3(p.x, terrain.height_at(p.x, p.y), p.y), rng.randf() * TAU, rng.randf_range(k[2], k[3]))
					break


## Thick woods over a polygon: a tree every WOODS_M2 m², a bush or a tree fern between, the 2.5D's
## woods (its forest tiles, sown already) left as they are.
func _thicket(points: Array, rng: RandomNumberGenerator) -> void:
	var poly: PackedVector2Array = TerrainRelief.SHAPES._points(points)
	var box: Rect2 = TerrainRelief.SHAPES._bounds(poly)
	var count := int(box.get_area() / WOODS_M2)
	for n in count:
		var p := Vector2(rng.randf_range(box.position.x, box.end.x), rng.randf_range(box.position.y, box.end.y))
		if not Geometry2D.is_point_in_polygon(p, poly) or source.surface(source.tile_at(p.x, p.y)) == &"forest":
			continue
		var kind: String = TREES[rng.randi() % TREES.size()] if rng.randf() < 0.65 else ["buisson", "fougere_arbre", "ronces"][rng.randi() % 3]
		if not _allows(p.x, p.y, true):
			continue
		var size := rng.randf_range(0.9, 1.3)
		_place(kind, Vector3(p.x, terrain.height_at(p.x, p.y), p.y), rng.randf() * TAU, size)


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
		inst.visibility_range_end_margin = 24.0 if shadows else 12.0
		inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF   # fades out, no popping
		inst.lod_bias = LOD_BIAS
		if not shadows:   # the small plants: left out of the water's mirror (the trees stay in it)
			inst.layers = 1 | (1 << (ZoneWater.NOT_IN_MIRROR_LAYER - 1))
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
