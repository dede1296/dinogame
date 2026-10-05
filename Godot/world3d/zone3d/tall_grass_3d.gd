class_name TallGrass3D
extends Node3D
## The tall grass of a 3D zone (docs/migration-3d.md): where the 2.5D zone has tall grass (the
## tiles its ground layer marks "tall_grass": ZoneSource.surface, the same data the hidden dinos
## and Encounters3D use), tufts of waist-high grass grow, so a patch of tall grass is what you
## see, and the hiding place of what you may meet. (The 2.5D's own: TallGrass, WorldView._build_tall_grass.)
## - Many tufts per tile, in the zone's metres, smaller toward the patch's open edges;
## - MultiMesh by 32 m square (never a node per tuft), two levels of detail (a near and a far mesh,
##   one fading into the other), nothing drawn beyond FAR_M: the ground shows the grass colour there;
## - one shared material (tall_grass.gdshader): wind, and the grass parting round Chloé and the wild
##   dinos — their places are given to the shader each frame (`pushers`).
##   grass = TallGrass3D.new(); grass.name = "TallGrass"; add_child(grass); grass.build(source, terrain)

const SHADER := preload("res://world3d/zone3d/tall_grass.gdshader")
const CHUNK_M := 32.0
const TUFTS_PER_M2 := 2.6          # tufts of a full patch (before the quality profile)
const NEAR_M := 20.0               # the full tuft up to here, the far one beyond
const FAR_M := 52.0
const FADE_M := 8.0
const NEAR_BLADES := 7
const NEAR_SEGMENTS := 3
const FAR_BLADES := 5
const FAR_SEGMENTS := 2
const FAR_SHARE := 2               # the far version has one tuft in this many (and wider blades)
const EDGE_SHRINK := 0.55          # the grass at an open edge is this tall against the heart of the patch
const EDGE_REACH_M := 1.1          # …growing to full height over this distance
const SIZE_RANGE := Vector2(0.85, 1.3)
const MAX_SLOPE := 0.28            # steeper ground (a cliff's face) grows none: height change over 0.5 m
const MAX_PUSHERS := 12
const PUSH_REACH_M := 30.0         # what walks further from Chloé than this does not part the grass
const CHLOE_PUSH_M := 0.75         # how far Chloé's parting reaches
const DINO_PUSH_PER_M := 0.45      # a dino's reaches this much of its length, plus DINO_PUSH_MIN_M
const DINO_PUSH_MIN_M := 0.5
const WIND_DIR := Vector2(0.88, 0.47)   # as Weather3D's
const WIND_BASE := 1.0             # a breeze…
const WIND_RAIN := 1.7             # …in the rain…
const WIND_STORM := 2.6            # …and in a storm
## Where a zone's grass is not the meadow's green: [foot, mid, tip] (the 2.5D has its own picture for the Monts).
const PALETTES := {
	&"monts": [Color(0.22, 0.25, 0.12), Color(0.52, 0.55, 0.26), Color(0.80, 0.78, 0.50)],
	&"desert": [Color(0.30, 0.26, 0.10), Color(0.66, 0.58, 0.26), Color(0.90, 0.82, 0.48)],
}

var source: ZoneSource
var terrain: ZoneTerrain
## Tufts planted (near version), for the tests and the log.
var tufts := 0

var _material: ShaderMaterial
var _near_mesh: ArrayMesh
var _far_mesh: ArrayMesh
var _wind := WIND_BASE
var _wet := 0.0


func build(src: ZoneSource, ground: ZoneTerrain) -> void:
	source = src
	terrain = ground
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("wind_dir", WIND_DIR)
	if PALETTES.has(src.id):
		var palette: Array = PALETTES[src.id]
		_material.set_shader_parameter("foot_color", palette[0])
		_material.set_shader_parameter("mid_color", palette[1])
		_material.set_shader_parameter("tip_color", palette[2])
	_near_mesh = TallGrassMesh.build(NEAR_BLADES, NEAR_SEGMENTS, 1.0, 5)
	_far_mesh = TallGrassMesh.build(FAR_BLADES, FAR_SEGMENTS, 1.8, 6)
	_plant()


func _process(delta: float) -> void:
	if _material == null:
		return
	var blend := 1.0 - exp(-0.6 * delta)   # (the sky's own easing)
	var rain := 1.0 if Game.is_raining() else 0.0
	var storm := 1.0 if Game.weather == &"storm" else 0.0
	_wind = lerpf(_wind, lerpf(lerpf(WIND_BASE, WIND_RAIN, rain), WIND_STORM, storm), blend)
	_wet = lerpf(_wet, rain, blend)
	_material.set_shader_parameter("wind_strength", _wind)
	_material.set_shader_parameter("wet", _wet)
	_material.set_shader_parameter("pushers", _pushers())


## What parts the grass now: Chloé, then the dinos nearest to her. Packed as x, y, z, reach.
func _pushers() -> PackedVector4Array:
	var out := PackedVector4Array()
	var chloe := get_tree().get_first_node_in_group(&"player3d") as Node3D
	if chloe == null:
		out.resize(MAX_PUSHERS)
		return out
	var here := chloe.global_position
	out.append(Vector4(here.x, here.y, here.z, CHLOE_PUSH_M))
	var near: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group(&"dino3d"):
		var dino := node as Dinosaur3D
		if dino == null or not dino.is_inside_tree():
			continue
		var d := dino.global_position.distance_to(here)
		if d < PUSH_REACH_M:
			near.append({"d": d, "v": Vector4(dino.global_position.x, dino.global_position.y, dino.global_position.z,
				dino.length_m * DINO_PUSH_PER_M + DINO_PUSH_MIN_M)})
	near.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["d"] < b["d"])
	for entry in near:
		if out.size() >= MAX_PUSHERS:
			break
		out.append(entry["v"])
	out.resize(MAX_PUSHERS)   # (the rest: radius 0, nobody)
	return out


## Every tall-grass tile gets its tufts; they are gathered by chunk and drawn in MultiMeshes.
func _plant() -> void:
	var chunks := {}   # Vector2i → Array of Transform3D
	var per_tile := TUFTS_PER_M2 * source.scale * source.scale
	for y in source.tiles.y:
		for x in source.tiles.x:
			var tile := Vector2i(x, y)
			if source.surface(tile) != &"tall_grass":
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(tile * 17 + Vector2i(9, 2))
			for i in int(per_tile + rng.randf()):
				var fx := rng.randf()
				var fy := rng.randf()
				var px := (x + fx) * source.scale
				var pz := (y + fy) * source.scale
				var size := rng.randf_range(SIZE_RANGE.x, SIZE_RANGE.y) * _edge_scale(tile, fx, fy)
				var h := terrain.height_at(px, pz)
				if absf(terrain.height_at(px + 0.5, pz) - h) > MAX_SLOPE or absf(terrain.height_at(px, pz + 0.5) - h) > MAX_SLOPE:
					continue
				var key := Vector2i(floori(px / CHUNK_M), floori(pz / CHUNK_M))
				if not chunks.has(key):
					chunks[key] = []
				var turn := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
				chunks[key].append(Transform3D(turn, Vector3(px, h - 0.03, pz)))
	for key: Vector2i in chunks:
		var list: Array = chunks[key]
		tufts += list.size()
		_draw(list, _near_mesh, 0.0, NEAR_M, 1)
		_draw(list, _far_mesh, NEAR_M, FAR_M, FAR_SHARE)


## A tuft's size at a tile position (0–1 across): shrinks toward an edge that borders other ground.
func _edge_scale(tile: Vector2i, fx: float, fy: float) -> float:
	var open := INF   # metres to the nearest open edge
	for side: Array in [[Vector2i(-1, 0), fx], [Vector2i(1, 0), 1.0 - fx], [Vector2i(0, -1), fy], [Vector2i(0, 1), 1.0 - fy]]:
		if source.surface(tile + (side[0] as Vector2i)) != &"tall_grass":
			open = minf(open, float(side[1]) * source.scale)
	return lerpf(EDGE_SHRINK, 1.0, clampf(open / EDGE_REACH_M, 0.0, 1.0)) if open < INF else 1.0


## One MultiMesh with every `every`-th tuft of the chunk, seen between `from_m` and `to_m`.
func _draw(list: Array, mesh: Mesh, from_m: float, to_m: float, every: int) -> void:
	var picked: Array = []
	for i in range(0, list.size(), every):
		picked.append(list[i])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = picked.size()
	for i in picked.size():
		var t: Transform3D = picked[i]
		if every > 1:
			t.basis = t.basis.scaled(Vector3.ONE * 1.15)   # (fewer tufts: a little bigger each)
		mm.set_instance_transform(i, t)
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = _material
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.extra_cull_margin = 1.0   # (the shader bends the blades)
	inst.layers = 1 | (1 << (ZoneWater.NOT_IN_MIRROR_LAYER - 1))   # left out of the water's mirror
	if from_m > 0.0:
		inst.visibility_range_begin = from_m
		inst.visibility_range_begin_margin = FADE_M
	inst.visibility_range_end = to_m
	inst.visibility_range_end_margin = FADE_M if to_m == NEAR_M else 14.0
	inst.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(inst)
