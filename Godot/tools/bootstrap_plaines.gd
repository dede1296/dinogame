extends SceneTree
## ONE-SHOT bootstrap of the first region scene and of the shared terrain TileSet.
## The generated .tscn is then edited in the Godot editor (paint the Terrain layer, move
## the props): it is the source of truth, not this script. Refuses to overwrite unless
## "--force" is given.
##   godot --headless --path Godot --script res://tools/bootstrap_plaines.gd [-- --force]

const TILE := 48
const TILESET_PATH := "res://regions/terrain_tileset.tres"
const PALETTE_PATH := "res://assets/editor/terrain_palette.png"
const SCENE_PATH := "res://regions/plaines/plaines_sud.tscn"
const TERRAINS := ["grass", "path", "tall_grass", "water"]
const PALETTE := [Color(0.42, 0.62, 0.3), Color(0.72, 0.55, 0.32), Color(0.2, 0.45, 0.15), Color(0.25, 0.5, 0.7)]

# . grass   = path   w tall grass   ~ water
const TERRAIN := [
	"........................................",
	"........................................",
	"..........................==............",
	"...===....................==............",
	"...===....wwwww...........==............",
	"...===...wwwwwwww.........==............",
	"....=...wwwwwwwwww........==............",
	"....=...wwwwwwwwww........==............",
	"....=....wwwwwwwww........==............",
	"....=.....wwwwwww.........==....~~~~....",
	"....=.......www...........==...~~~~~~~..",
	"....=.....................==..~~~~~~~~~.",
	"....=========================.~~~~~~~~..",
	"..........................====~~~~~~~...",
	"..........................==....~~~~....",
	"..........................==............",
	"..........................==............",
	".....wwww.................==............",
	"....wwwwww................==..wwwww.....",
	"....wwwwww................==.wwwwwww....",
	".....wwww.................==..wwwww.....",
	"..........................==............",
	"..........................==............",
	"..........................==............",
	"..........................==............",
	"..........................==............",
]


func _initialize() -> void:
	var force := "--force" in OS.get_cmdline_user_args()
	if FileAccess.file_exists(SCENE_PATH) and not force:
		push_error("%s existe déjà : éditez-le dans Godot (ou relancez avec -- --force)." % SCENE_PATH)
		quit(1)
		return
	var tileset := _make_tileset()
	if tileset == null:
		quit(1)
		return
	var err := ResourceSaver.save(tileset, TILESET_PATH)
	if err != OK:
		push_error("TileSet : %s" % error_string(err))
		quit(1)
		return
	tileset = load(TILESET_PATH)
	var scene := _make_region(tileset)
	var packed := PackedScene.new()
	err = packed.pack(scene)
	if err == OK:
		DirAccess.make_dir_recursive_absolute(SCENE_PATH.get_base_dir())
		err = ResourceSaver.save(packed, SCENE_PATH)
	print("Région : ", SCENE_PATH, " -> ", error_string(err))
	scene.free()
	quit(0 if err == OK else 1)


## The terrain palette (editor guide colours) is a real PNG, imported by Godot. When it is
## missing it is written and the tool asks for an import before running again.
func _palette() -> Texture2D:
	if ResourceLoader.exists(PALETTE_PATH):
		return load(PALETTE_PATH)
	var img := Image.create(TILE * TERRAINS.size(), TILE, false, Image.FORMAT_RGBA8)
	for i in TERRAINS.size():
		img.fill_rect(Rect2i(i * TILE, 0, TILE, TILE), PALETTE[i])
		img.fill_rect(Rect2i(i * TILE + 2, 2, TILE - 4, TILE - 4), PALETTE[i].lightened(0.12))
	DirAccess.make_dir_recursive_absolute(PALETTE_PATH.get_base_dir())
	img.save_png(PALETTE_PATH)
	return null


func _make_tileset() -> TileSet:
	var palette := _palette()
	if palette == null:
		push_error("Palette créée (%s) : lancez « godot --headless --path Godot --import » puis relancez cet outil." % PALETTE_PATH)
		return null
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "terrain")
	ts.set_custom_data_layer_type(0, TYPE_STRING)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = palette
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var half := TILE / 2.0
	for i in TERRAINS.size():
		src.create_tile(Vector2i(i, 0))
		var data := src.get_tile_data(Vector2i(i, 0), 0)
		data.set_custom_data("terrain", TERRAINS[i])
		if TERRAINS[i] == "water":
			# Slightly inset, so Chloé can reach the soft shoreline drawn by the ground shader.
			var s := half - 6.0
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)]))
	return ts


func _make_region(tileset: TileSet) -> Region:
	var root := Region.new()
	root.name = "PlainesSud"
	root.region_id = &"plaines_sud"
	root.display_name = "Plaines des Fougères"
	if ResourceLoader.exists("res://assets/audio/music/plaines.ogg"):
		root.music = load("res://assets/audio/music/plaines.ogg")
	root.ambience = load("res://assets/audio/ambience/prairie.mp3")
	root.ambience_details = [
		load("res://assets/audio/ambience/oiseau-1.mp3"),
		load("res://assets/audio/ambience/oiseau-2.mp3"),
		load("res://assets/audio/ambience/oiseau-3.mp3"),
	]

	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = tileset
	root.add_child(terrain)
	for y in TERRAIN.size():
		var row: String = TERRAIN[y]
		assert(row.length() == 40, "ligne %d : %d colonnes" % [y, row.length()])
		for x in row.length():
			var idx := ".=w~".find(row[x])
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(maxi(idx, 0), 0))

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
	var start := Marker2D.new()
	start.name = "Depart"
	start.position = _cell(27.0, 24.2)
	spawns.add_child(start)

	_place_scenery(entities)
	_place_story(entities)
	_set_owner(root, root)
	return root


func _cell(x: float, y: float) -> Vector2:
	return Vector2(x * TILE, y * TILE)


func _terrain_at(x: int, y: int) -> String:
	if y < 0 or y >= TERRAIN.size() or x < 0 or x >= 40:
		return "?"
	return TERRAIN[y][x]


func _prop(parent: Node, kind: String, pos: Vector2, flip := false, prop_script: Script = null) -> Node2D:
	var p: Node2D = prop_script.new() if prop_script else Prop.new()
	p.kind = kind
	p.flip = flip
	p.position = pos
	p.name = kind.capitalize().replace(" ", "")
	parent.add_child(p, true)
	return p


func _place_scenery(entities: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1296
	var trees := ["arbre_rond", "araucaria", "arbre_rond", "fougere_arbre"]
	# Forest edge: two staggered rows of trees all around, leaving the paths open.
	for y in range(-1, 27):
		for x in range(-1, 41):
			var edge := x <= 1 or x >= 38 or y <= 1 or y >= 25
			if not edge or (x + y) % 2 != 0:
				continue
			var t := _terrain_at(clampi(x, 0, 39), clampi(y, 0, 25))
			if t == "=" or (y >= 24 and x >= 24 and x <= 29):
				continue
			var pos := _cell(x + 0.5 + rng.randf_range(-0.3, 0.3), y + 0.9 + rng.randf_range(-0.2, 0.2))
			_prop(entities, trees[rng.randi() % trees.size()], pos, rng.randf() < 0.5)
	# The grove to the west (behind the trunk): a wall of trees and bushes.
	for y in range(2, 12):
		_prop(entities, "araucaria" if y % 2 == 0 else "arbre_rond", _cell(6.9 + rng.randf_range(-0.2, 0.2), y + 0.8), y % 3 == 0)
	_prop(entities, "buisson", _cell(2.8, 11.6))
	_prop(entities, "buisson", _cell(5.9, 11.5), true)
	# The trees don't touch: an invisible hedge closes the grove until the trunk is cut.
	var hedge := StaticBody2D.new()
	hedge.name = "HaieBosquet"
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 10.5 * TILE)
	shape.shape = box
	shape.position = _cell(6.9, 2.0 + 10.5 / 2.0)
	hedge.add_child(shape)
	entities.add_child(hedge)
	_prop(entities, "fougere_arbre", _cell(2.2, 4.5))
	_prop(entities, "fleurs_violettes", _cell(3.2, 6.8))
	_prop(entities, "fougeres", _cell(5.4, 3.2))
	# Around the pond.
	for p: Array in [["fougere_arbre", 29.2, 9.6], ["fougere_arbre", 38.2, 12.8], ["fougeres", 31.0, 15.3],
			["fougeres", 36.4, 15.0], ["fleurs_roses", 33.5, 8.3], ["buisson", 29.0, 15.4], ["souche", 35.5, 8.6]]:
		_prop(entities, p[0], _cell(p[1], p[2]))
	# Along the paths and in the meadows.
	for p: Array in [["buisson", 22.0, 9.0], ["buisson", 30.5, 21.5], ["cailloux", 24.2, 16.5], ["souche", 20.5, 15.8],
			["arbre_rond", 21.0, 19.8], ["araucaria", 14.5, 16.4], ["fougere_arbre", 12.0, 22.5], ["cailloux", 9.0, 14.6],
			["ronces", 33.0, 4.5], ["arbre_rond", 34.8, 3.9], ["buisson", 18.8, 3.6], ["cloture", 23.2, 21.2], ["cloture", 23.2, 22.6]]:
		_prop(entities, p[0], _cell(p[1], p[2]), rng.randf() < 0.5)
	# Flowers and ferns scattered on the grass (not on paths, water or tall grass).
	var small := ["fleurs_roses", "fleurs_violettes", "fougeres", "fleurs_roses", "fougeres"]
	var placed := 0
	while placed < 34:
		var x := rng.randi_range(2, 37)
		var y := rng.randi_range(2, 23)
		if _terrain_at(x, y) != "." or _terrain_at(x + 1, y) == "=" or _terrain_at(x - 1, y) == "=" or (x < 8 and y < 12):
			continue
		_prop(entities, small[rng.randi() % small.size()], _cell(x + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9)), rng.randf() < 0.5)
		placed += 1


func _place_story(entities: Node2D) -> void:
	# Signposts.
	var sign = _prop(entities, "panneau", _cell(25.2, 14.9), false, load("res://world/sign.gd"))
	sign.name = "PanneauCarrefour"
	sign.dialogue_id = &"panneau_carrefour"
	var cave_sign = _prop(entities, "panneau", _cell(29.0, 4.9), true, load("res://world/sign.gd"))
	cave_sign.name = "PanneauGrotte"
	cave_sign.dialogue_id = &"panneau_grotte"
	# The boulder closing the Grotte des Échos (Charge).
	var boulder = _prop(entities, "rocher", _cell(27.0, 3.4), false, load("res://world/obstacle.gd"))
	boulder.name = "RocherGrotte"
	boulder.ability = &"charge"
	boulder.cleared_flag = &"rocher_grotte_brise"
	boulder.blocked_dialogue = &"rocher_bloque"
	boulder.debris_color = Color(0.55, 0.55, 0.58)
	# The fallen trunk on the way to the grove (Tranche).
	var trunk = _prop(entities, "tronc", _cell(4.6, 11.4), false, load("res://world/obstacle.gd"))
	trunk.name = "TroncBosquet"
	trunk.ability = &"tranche"
	trunk.cleared_flag = &"tronc_bosquet_tranche"
	trunk.blocked_dialogue = &"tronc_bloque"
	# Hélène's amber fragment and journal page, in the grove.
	var amber = _prop(entities, "ambre", _cell(4.4, 3.6), false, load("res://world/pickup.gd"))
	amber.name = "AmbreProtoceratops"
	amber.taken_flag = &"found_journal_1"
	amber.dialogue_id = &"ambre_proto"
	# Maïa, at the crossroads.
	var maia = load("res://actors/npc.tscn").instantiate()
	maia.name = "Maia"
	maia.display_name = "Maïa"
	maia.sheet = load("res://assets/art/characters/maia.png")
	maia.dialogue_id = &"maia"
	maia.facing = "left"
	maia.position = _cell(29.3, 17.0)
	entities.add_child(maia)
	# Wild Protoceratops roaming the meadows.
	for p: Array in [[12.5, 7.5, 140.0], [7.0, 19.5, 90.0], [33.0, 19.8, 100.0]]:
		var wild = load("res://actors/wild_dino.tscn").instantiate()
		wild.name = "Protoceratops"
		wild.species_id = &"protoceratops"
		wild.roam_radius = p[2]
		wild.position = _cell(p[0], p[1])
		entities.add_child(wild, true)


func _set_owner(node: Node, root_owner: Node) -> void:
	for child in node.get_children():
		child.owner = root_owner
		# Don't descend into instanced scenes or nodes generated at runtime by @tool scripts.
		if child.scene_file_path == "" and not (child is Prop or child is TallGrass):
			_set_owner(child, root_owner)
