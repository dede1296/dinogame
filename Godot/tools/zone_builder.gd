class_name ZoneBuilder
extends RefCounted
## Helpers to generate a zone scene from a text plan (tools/zones/<id>.gd, built by
## tools/build_zone.gd). The generated .tscn is the source of truth afterwards: it is edited
## in the Godot editor (paint the terrain, move props, resize habitats).
## Plan characters: . grass   = path   w tall grass   ~ water

const TILE := 48
const TILESET := preload("res://regions/terrain_tileset.tres")
const TERRAIN_CHARS := ".=w~"
const TREES := ["arbre_rond", "araucaria", "arbre_rond", "fougere_arbre"]
const SMALL := ["fleurs_roses", "fleurs_violettes", "fougeres", "fleurs_roses", "fougeres"]
const WHEN := {"toujours": 0, "jour": 1, "nuit": 2, "aube et crépuscule": 3, "jour et crépuscule": 4}


static func cell(x: float, y: float) -> Vector2:
	return Vector2(x * TILE, y * TILE)


static func at(plan: Array, x: int, y: int) -> String:
	if y < 0 or y >= plan.size() or x < 0 or x >= (plan[y] as String).length():
		return "?"
	return (plan[y] as String)[x]


## The zone's root with its Terrain, Ground, Entities (with TallGrass) and Spawns.
static func region(id: StringName, region_name: String, zone_name: String, levels: Vector2i, plan: Array) -> Region:
	var root := Region.new()
	root.name = String(id).to_pascal_case()
	root.region_id = id
	root.display_name = region_name
	root.zone_name = zone_name
	root.levels = levels
	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = TILESET
	root.add_child(terrain)
	var width := (plan[0] as String).length()
	for y in plan.size():
		var row: String = plan[y]
		assert(row.length() == width, "ligne %d : %d colonnes au lieu de %d" % [y, row.length(), width])
		for x in row.length():
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(maxi(TERRAIN_CHARS.find(row[x]), 0), 0))
	var ground := Ground.new()
	ground.name = "Ground"
	ground.z_index = -10
	root.add_child(ground)
	ground.terrain = terrain
	var entities := Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	root.add_child(entities)
	var grass := TallGrass.new()
	grass.name = "TallGrass"
	entities.add_child(grass)
	grass.terrain = terrain
	var spawns := Node2D.new()
	spawns.name = "Spawns"
	root.add_child(spawns)
	var habitats := Node2D.new()
	habitats.name = "Habitats"
	root.add_child(habitats)
	var exits := Node2D.new()
	exits.name = "Exits"
	root.add_child(exits)
	return root


## A big region from its two map images (tools/maps): the ground by colour (SOLS) and the
## relief in grey levels (5 cm each). The relief is saved next to the scene (`relief_res`).
const SOLS := {
	"grass": [Color8(90, 158, 58), 0], "path": [Color8(200, 160, 96), 1], "tall_grass": [Color8(47, 107, 31), 2],
	"water": [Color8(46, 111, 181), 3], "forest": [Color8(31, 64, 32), 4], "sand": [Color8(232, 212, 154), 5],
}


static func region_from_maps(id: StringName, region_name: String, zone_name: String, levels: Vector2i,
		sols_png: String, relief_png: String, relief_res: String) -> Region:
	var sols := Image.load_from_file(ProjectSettings.globalize_path(sols_png))
	var relief := Image.load_from_file(ProjectSettings.globalize_path(relief_png))
	var w := sols.get_width()
	var h := sols.get_height()
	var plan: Array = []
	for y in h:
		plan.append(".".repeat(w))
	var root := region(id, region_name, zone_name, levels, plan)
	var terrain: TileMapLayer = root.get_node("Terrain")
	var heights := Image.create_empty(w, h, false, Image.FORMAT_RF)
	for y in h:
		for x in w:
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(_sol_index(sols.get_pixel(x, y)), 0))
			heights.set_pixel(x, y, Color(relief.get_pixel(x, y).r * 255.0 * 0.05, 0, 0))
	ResourceSaver.save(heights, relief_res)
	root.height_data = load(relief_res)
	return root


## Tileset index of the ground colour closest to `c` (grass when unsure).
static func _sol_index(c: Color) -> int:
	var best := 0
	var best_d := INF
	for k: String in SOLS:
		var ref: Color = SOLS[k][0]
		var d := Vector3(c.r - ref.r, c.g - ref.g, c.b - ref.b).length()
		if d < best_d:
			best_d = d
			best = SOLS[k][1]
	return best if best_d < 0.12 else 0


static func prop(parent: Node, kind: String, pos: Vector2, flip := false, prop_script: Script = null) -> Node2D:
	var p: Node2D = prop_script.new() if prop_script else Prop.new()
	p.kind = kind
	p.flip = flip
	p.position = pos
	p.name = kind.to_pascal_case()
	parent.add_child(p, true)
	return p


static func sign(parent: Node, pos: Vector2, dialogue_id: StringName, flip := false) -> Node2D:
	var s := prop(parent, "panneau", pos, flip, load("res://world/sign.gd"))
	s.dialogue_id = dialogue_id
	return s


## Two staggered rows of trees on the zone's edges, on grass only, except where
## `keep_clear(x, y)` says so (openings, exits).
static func forest_edge(entities: Node, plan: Array, rng: RandomNumberGenerator, keep_clear: Callable) -> void:
	var w := (plan[0] as String).length()
	var h := plan.size()
	for y in range(-1, h + 1):
		for x in range(-1, w + 1):
			var edge := x <= 1 or x >= w - 2 or y <= 1 or y >= h - 2
			if not edge or (x + y) % 2 != 0 or keep_clear.call(x, y):
				continue
			if at(plan, clampi(x, 0, w - 1), clampi(y, 0, h - 1)) != ".":
				continue
			var pos := cell(x + 0.5 + rng.randf_range(-0.3, 0.3), y + 0.9 + rng.randf_range(-0.2, 0.2))
			prop(entities, TREES[rng.randi() % TREES.size()], pos, rng.randf() < 0.5)


## Small plants on plain grass, away from paths and from `avoid(x, y)`.
static func scatter(entities: Node, plan: Array, rng: RandomNumberGenerator, count: int, avoid: Callable) -> void:
	var w := (plan[0] as String).length()
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 40:
		tries += 1
		var x := rng.randi_range(2, w - 3)
		var y := rng.randi_range(2, plan.size() - 3)
		if at(plan, x, y) != "." or at(plan, x + 1, y) == "=" or at(plan, x - 1, y) == "=" or avoid.call(x, y):
			continue
		prop(entities, SMALL[rng.randi() % SMALL.size()], cell(x + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9)), rng.randf() < 0.5)
		placed += 1


static func spawn(root: Region, spawn_name: String, x: float, y: float) -> void:
	var m := Marker2D.new()
	m.name = spawn_name
	m.position = cell(x, y)
	root.get_node("Spawns").add_child(m)


## `rows`: [species, min level, max level, weight, when (see WHEN), hidden].
static func habitat(root: Region, label: String, cells: Rect2, rows: Array, roamers := 0) -> Habitat:
	var h := Habitat.new()
	h.name = label.to_pascal_case().replace("'", "")
	h.label = label
	h.position = cell(cells.position.x, cells.position.y)
	h.size = cells.size * TILE
	h.roamers = roamers
	var list: Array[Encounter] = []
	for r: Array in rows:
		var e := Encounter.new()
		e.species = r[0]
		e.levels = Vector2i(r[1], r[2])
		e.weight = r[3]
		e.when = WHEN[r[4]]
		e.hidden = r[5]
		list.append(e)
	h.encounters = list
	root.get_node("Habitats").add_child(h)
	return h


static func exit(root: Region, cells: Rect2, target_zone: StringName, target_spawn: StringName,
		required_flag: StringName = &"", blocked_dialogue: StringName = &"") -> ZoneExit:
	var e := ZoneExit.new()
	e.name = "Vers" + String(target_zone).to_pascal_case()
	e.position = cell(cells.position.x, cells.position.y)
	e.size = cells.size * TILE
	e.target_zone = target_zone
	e.target_spawn = target_spawn
	e.required_flag = required_flag
	e.blocked_dialogue = blocked_dialogue
	root.get_node("Exits").add_child(e)
	return e


## A character (actors/npc.tscn). `opts`: dialogue, event, facing, show_flag, hide_flag.
static func npc(root: Region, node_name: String, display_name: String, sheet: String, x: float, y: float, opts := {}) -> Node:
	var n: Node2D = load("res://actors/npc.tscn").instantiate()
	n.name = node_name
	n.display_name = display_name
	n.sheet = load(sheet)
	n.dialogue_id = opts.get("dialogue", &"")
	n.event = opts.get("event", &"")
	n.facing = opts.get("facing", "down")
	n.show_flag = opts.get("show_flag", &"")
	n.hide_flag = opts.get("hide_flag", &"")
	n.position = cell(x, y)
	root.get_node("Entities").add_child(n)
	return n


## A dino standing in a scene (actors/dino_npc.gd).
static func dino_npc(root: Region, node_name: String, species: StringName, x: float, y: float, opts := {}) -> Node:
	var d := DinoNpc.new()
	d.name = node_name
	d.species_id = species
	d.event = opts.get("event", &"")
	d.flip = opts.get("flip", false)
	d.show_flag = opts.get("show_flag", &"")
	d.hide_flag = opts.get("hide_flag", &"")
	d.size_scale = opts.get("size", 0.8)
	d.lift = opts.get("lift", 0.0)
	d.position = cell(x, y)
	root.get_node("Entities").add_child(d)
	return d


## A wooden pier over the water: its cells must be painted as path (walkable).
static func dock(root: Region, cells: Rect2) -> Dock:
	var d := Dock.new()
	d.name = "Ponton"
	d.position = cell(cells.position.x, cells.position.y)
	d.size = cells.size
	root.add_child(d)
	return d


## Saves the zone; refuses to overwrite unless `force`.
static func save(root: Region, path: String, force: bool) -> Error:
	if FileAccess.file_exists(path) and not force:
		push_error("%s existe déjà : éditez-le dans Godot (ou relancez avec --force)." % path)
		return ERR_ALREADY_EXISTS
	set_owner_all(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		err = ResourceSaver.save(packed, path)
	return err


static func set_owner_all(node: Node, root_owner: Node) -> void:
	for child in node.get_children():
		child.owner = root_owner
		# Not into instanced scenes, nor into nodes generated at run time by @tool scripts.
		if child.scene_file_path == "" and not (child is Prop or child is TallGrass or child is ZoneExit):
			set_owner_all(child, root_owner)
