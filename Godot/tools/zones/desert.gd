extends RefCounted
## Désert Aride — the whole region in one open map (120 x 100 tiles), drawn from
## tools/maps/desert_sols.png and desert_relief.png (made by gen-desert.mjs, retouchable).
## South-east: the Canyon d'entrée, the way in from the Marais (the marsh drying up: mud, dry
## reeds, puddles), the Lac de sel; centre-south: the Cimetière des Géants (giant bones on the
## hardpan, the six fossils Tante Sirocco asks for, page 17), her tent at its north-east corner;
## west: the Rochers de l'ouest before the Canyon muré, its mouth closed by fallen rocks (Charge),
## the Vieux Rempart at its end (page 20); centre: the Grand Erg (dunes, buttes); north: the
## sanctuary des Vents, its door in the rock face at the north edge (zone sanctuaire_vents beyond
## it), the square before it, the Canyon des Vents winding west to the dead end where Brac is
## cornered (his cart, the Carnotaurus Rouge); north-east: the Oasis (Maïa, page 19), the Grande
## Dune, the way to the Côte (closed for now). Sand ("sand"), canyon rock ("rock"), trails
## (path), sandstorms now and then. (story/desert.gd and desert_sanctuaire.gd play its scenes.)

const PATH := "res://regions/desert/desert.tscn"
const B := preload("res://tools/zone_builder.gd")
const MAPS := "res://tools/maps/desert_%s.png"
const PICKUP := "res://world/pickup.gd"
const STORY_PROP := "res://world/story_prop.gd"
const OBSTACLE := "res://world/obstacle.gd"
const CHARS := "res://assets/art/characters/%s.png"
const MUSIC := "res://assets/audio/music/desert.ogg"
const BACKDROP := "res://assets/art/battle/desert.jpg"
const ENTRANCE := Vector2i(102, 98)

## What stands on each ground (see _table): [kind, chance per tile]. The first row that wins
## the roll is placed.
const DUNES := [
	["buisson_sec", 0.005], ["cailloux", 0.006], ["os_dino", 0.0015], ["rocher_canyon", 0.0015],
	["nid_oviraptor", 0.0008],
]
const ROCKY := [["cailloux", 0.02], ["buisson_sec", 0.01], ["rocher_canyon", 0.005], ["os_dino", 0.003]]
## Up on the rock nobody reaches (seen from above): boulders and dry scrub.
const TOPS := [["rocher_canyon", 0.01], ["buisson_sec", 0.012], ["cailloux", 0.012]]
const OASIS_GRASS := [["fougeres", 0.06], ["hautes_herbes", 0.04], ["fleurs_roses", 0.01], ["fleurs_violettes", 0.008]]
const MUDDY := [["roseaux", 0.07], ["cailloux", 0.01], ["buisson_sec", 0.008]]
const BONES := [["os_dino", 0.02], ["cailloux", 0.012], ["buisson_sec", 0.005]]
## Just south of a trail or a place (the camera looks north, 40° down: anything taller than
## Chloé there would hide them): low things only.
const LOW := [["cailloux", 0.014], ["os_dino", 0.004]]
## How far south of what must be seen (tiles) nothing tall stands.
const VIEW_SHADOW := 5
## Rock above this height (m) is out of reach (the tops of the walls, the buttes).
const TOP := 1.8
## The Cimetière des Géants (tiles): bones everywhere on its hardpan.
const CEMETERY := Rect2(61, 60, 28, 22)
## Where nothing is scattered (tiles): around the places, so they stay readable.
const KEEP_CLEAR := [
	Rect2(96, 88, 12, 12), Rect2(82, 63, 10, 8), Rect2(70, 67, 9, 7), Rect2(63, 73, 8, 6), Rect2(59, 64, 6, 7),
	Rect2(68, 59, 6, 5), Rect2(74, 81, 8, 5), Rect2(24, 55, 10, 8), Rect2(12, 26, 16, 12), Rect2(49, 2, 23, 14),
	Rect2(6, 3, 18, 13), Rect2(88, 22, 18, 13), Rect2(98, 8, 11, 12), Rect2(95, 0, 9, 5), Rect2(77, 72, 6, 6),
]

## The story's places (tiles).
const SIROCCO := Vector2(85.6, 67.6)
const TENT := Vector2(86.6, 65.9)
## The sanctuary's door, in its notch at the north edge (gen-desert.mjs NOTCH: x 59-61).
const DOOR := Vector2(60.5, 3.0)
const TRIGGER_SANCTUAIRE := Vector2(60.5, 10.0)
const CARNO_GARDIEN := Vector2(63.8, 5.3)
## The Canyon des Vents: the three moments of the chase, from the square to the dead end.
const CHASE := [Vector2(45.0, 11.2), Vector2(35.0, 15.0), Vector2(25.5, 12.6)]
const CHASE_RADIUS := 3.2
const BRAC := Vector2(15.5, 12.4)
const CART := Vector2(12.6, 8.2)
const CARNO := Vector2(17.8, 7.6)
## The fallen rocks across the walled canyon's mouth (x 26-31), the Vieux Rempart at its end.
const RUBBLE := Vector2(28.5, 58.8)
const RAMPART := Vector2(20.5, 32.0)
const MAIA := Vector2(93.2, 30.2)
const WELL := Vector2(92.2, 27.6)
## The six fossils, where Tante Sirocco's hints say (story/desert_places.gd FOSSILS), each at
## the foot of its landmark: [flag, fossil (tiles), landmark kind, landmark (tiles), flip].
const FOSSILS := [
	[&"fossile_1", Vector2(74.2, 71.3), "crane_geant_desert", Vector2(74.0, 70.4), false],   # under the great skull
	[&"fossile_2", Vector2(66.6, 77.0), "squelette_geant", Vector2(66.8, 76.2), false],        # between its ribs
	[&"fossile_3", Vector2(83.4, 69.5), "os_geant", Vector2(83.2, 68.6), true],               # by the tent
	[&"fossile_4", Vector2(77.2, 83.8), "", Vector2.ZERO, false],                              # the salt lake's shore
	[&"fossile_5", Vector2(61.3, 67.2), "arche_rocheuse", Vector2(61.0, 66.8), false],         # under the arch, west
	[&"fossile_6", Vector2(70.7, 61.8), "buisson_sec", Vector2(70.5, 61.1), false],            # a dry bush, north
]


static func build() -> Region:
	var root := B.region_from_maps(&"desert", "Désert Aride", "", Vector2i(21, 27),
		MAPS % "sols", MAPS % "relief", "res://regions/desert/desert_relief.res")
	root.music = load(MUSIC)
	root.ambience_id = &"desert"
	if ResourceLoader.exists(BACKDROP):
		root.battle_backdrop = load(BACKDROP)
	# Dry: hardly any rain, a little haze at dawn, a sandstorm now and then.
	root.rain_chance = 0.01
	root.mist_chance = 0.03
	root.storm_chance = 0.0
	root.sandstorm_chance = 0.12
	var entities: Node2D = root.get_node("Entities")
	_scatter(root, entities)
	_landmarks(root, entities)
	_story(root, entities)
	_rest_spots(root, entities)
	# 30 amber pebbles: 2 in the oasis's tree ferns, 10 under stones, 8 buried (Flair: the
	# Oviraptors have it), 10 in nooks worth the walk.
	B.hide_pebbles(root, entities, ENTRANCE, 7412, 2, 10,
		[Vector2(40, 72), Vector2(20, 90), Vector2(58, 90), Vector2(110, 58), Vector2(86, 44), Vector2(46, 28),
			Vector2(112, 20), Vector2(100, 74)],
		[Vector2(8, 62), Vector2(52, 84), Vector2(93, 90), Vector2(114, 40), Vector2(70, 30), Vector2(84, 10),
			Vector2(32, 44), Vector2(58, 50), Vector2(106, 72), Vector2(9, 12)])
	_places(root)
	_habitats(root)
	return root


## The ground under tile `c` ("" outside the map).
static func _ground(terrain: TileMapLayer, c: Vector2i) -> String:
	var d := terrain.get_cell_tile_data(c)
	return String(d.get_custom_data("terrain")) if d else ""


## What stands on tile `c`, by its ground and where it is.
static func _table(root: Region, terrain: TileMapLayer, c: Vector2i, ground: String) -> Array:
	if root.tile_height(c) >= TOP:
		return TOPS
	match ground:
		"grass", "tall_grass":
			return OASIS_GRASS
		"mud":
			return MUDDY
	if CEMETERY.has_point(Vector2(c) + Vector2(0.5, 0.5)):
		return BONES
	return ROCKY if ground == "rock" else DUNES


static func _scatter(root: Region, entities: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4127
	var terrain: TileMapLayer = root.get_node("Terrain")
	var size := terrain.get_used_rect().end
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			var ground := _ground(terrain, c)
			var middle := Vector2(x + 0.5, y + 0.5)
			if not ground in B.OPEN_GROUND or KEEP_CLEAR.any(func(r: Rect2) -> bool: return r.has_point(middle)):
				continue
			if _near(terrain, c, "path", 1) or _near(terrain, c, "water", 1) or not _steady(root, c, 0.35):
				continue
			var table: Array = _table(root, terrain, c, ground)
			if table == TOPS and _overlooks(root, c):
				continue
			if table != TOPS and _in_view(terrain, c):
				table = LOW
			for row: Array in table:
				if rng.randf() < row[1]:
					B.prop(entities, row[0], B.cell(x + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9)), rng.randf() < 0.5)
					break


## A tile of `ground` within `r` tiles of tile `c`.
static func _near(terrain: TileMapLayer, c: Vector2i, ground: String, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if _ground(terrain, c + Vector2i(dx, dy)) == ground:
				return true
	return false


## A trail, the water or a place kept clear just north of tile `c` (it must stay in sight).
static func _in_view(terrain: TileMapLayer, c: Vector2i) -> bool:
	for k in range(1, VIEW_SHADOW + 1):
		for dx in range(-2, 3):
			var n := c + Vector2i(dx, -k)
			if _ground(terrain, n) in ["path", "water"]:
				return true
			var middle := Vector2(n) + Vector2(0.5, 0.5)
			if KEEP_CLEAR.any(func(r: Rect2) -> bool: return r.has_point(middle)):
				return true
	return false


## Tile `c` is up on a wall over lower ground just north of it (a canyon, a trail): a boulder
## standing there would hide what is below from the camera, which looks north.
static func _overlooks(root: Region, c: Vector2i) -> bool:
	var h := root.tile_height(c)
	for k in range(1, VIEW_SHADOW + 3):
		for dx in range(-2, 3):
			if root.tile_height(c + Vector2i(dx, -k)) < h - 1.0:
				return true
	return false


## Tile `c` is nearly level with all its neighbours (nothing stands on a cliff's edge; on a
## dune's gentle slope, yes).
static func _steady(root: Region, c: Vector2i, step := 0.3) -> bool:
	var h := root.tile_height(c)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if absf(root.tile_height(c + Vector2i(dx, dy)) - h) > step:
				return false
	return true


## World position of tile point `t`, moved to the nearest open ground that is level all round
## (the map may have been retouched under it: not in the water, not over a drop).
static func _open_near(root: Region, t: Vector2) -> Vector2:
	var terrain: TileMapLayer = root.get_node("Terrain")
	for r in 4:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := Vector2i(t.floor()) + Vector2i(dx, dy)
				if _ground(terrain, c) in B.OPEN_GROUND and _steady(root, c, 0.35) and root.tile_height(c) < TOP:
					return B.cell(t.x + dx, t.y + dy)
	return B.cell(t.x, t.y)


## Scenery placed by hand: the way in, the cemetery's giant bones, the salt lake, the oasis and
## its palms, the square of the sanctuary, the dead end of the Canyon des Vents.
static func _landmarks(root: Region, entities: Node2D) -> void:
	# The way in: the marsh dying out (a drowned tree, dry reeds), rocks along the walls.
	for p: Array in [["arbre_noye", 97.2, 92.6, false], ["roseaux", 99.0, 96.6, false], ["roseaux", 105.8, 95.4, true],
			["roseaux", 97.8, 97.8, true], ["roseaux", 106.4, 91.2, false], ["buisson_sec", 106.2, 86.6, true],
			["rocher_canyon", 96.4, 84.2, false], ["rocher_canyon", 107.0, 81.4, true], ["cailloux", 99.6, 88.4, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# The cemetery: the great skull and the long skeleton (their fossils: _story), ribs and
	# bones all over, nests of Oviraptors on its edges.
	for p: Array in [["os_geant", 79.4, 75.2, false], ["os_geant", 69.4, 66.2, true], ["os_geant", 78.4, 64.4, false],
			["os_geant", 64.6, 73.8, true], ["os_geant", 86.0, 76.6, false], ["crane_geant_desert", 83.2, 79.6, true],
			["squelette_geant", 70.2, 79.6, true], ["os_dino", 76.6, 68.4, false], ["os_dino", 71.2, 72.8, true],
			["os_dino", 81.6, 72.0, false], ["os_dino", 67.6, 70.2, true], ["os_dino", 75.8, 77.6, false],
			["nid_oviraptor", 64.0, 63.4, false], ["nid_oviraptor", 87.4, 61.8, true], ["nid_oviraptor", 62.4, 79.0, false],
			["rocher_canyon", 62.0, 61.0, false], ["buisson_sec", 84.6, 62.2, true], ["buisson_sec", 66.2, 81.4, false]]:
		B.prop(entities, p[0], _open_near(root, Vector2(p[1], p[2])), p[3])
	# The salt lake: bleached bones and stones on its crust (nothing tall south of it).
	for p: Array in [["os_dino", 71.6, 86.4, true], ["cailloux", 84.2, 86.0, false], ["os_dino", 86.4, 90.2, false],
			["cailloux", 70.8, 91.4, true]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# The oasis: palms round its pond (tall ones north, east and west; the south side stays low,
	# the camera looks over it), tree ferns (an amber pebble in one of them), the well.
	for p: Array in [["palmier_oasis", 95.6, 27.2, false], ["palmier_oasis", 99.4, 26.4, true], ["palmier_oasis", 103.4, 27.0, false],
			["palmier_oasis", 106.2, 29.8, true], ["palmier_oasis", 107.8, 31.2, false], ["palmier_oasis", 106.6, 33.6, false],
			["palmier_oasis", 101.6, 23.6, true], ["palmier_oasis", 94.0, 24.2, true], ["palmier_oasis", 108.4, 26.4, false],
			["fougere_arbre", 97.6, 24.8, false], ["fougere_arbre", 105.0, 24.6, true], ["fougere_arbre", 90.4, 29.2, false],
			["fougeres", 96.2, 35.4, false], ["fougeres", 101.8, 35.2, true], ["hautes_herbes", 98.6, 36.2, false],
			["fleurs_roses", 94.0, 34.6, false], ["fleurs_violettes", 104.2, 35.8, true]]:
		B.prop(entities, p[0], _open_near(root, Vector2(p[1], p[2])), p[3])
	B.prop(entities, "puits_oasis", B.cell(WELL.x, WELL.y))
	# The square of the sanctuary: totems of the winds either side of the door and round it.
	for p: Array in [[55.5, 3.7, false], [65.5, 3.7, true], [52.6, 8.2, false], [68.4, 8.2, true]]:
		B.prop(entities, "totem_vents", B.cell(p[0], p[1]), p[2])
	for p: Array in [["cailloux", 53.4, 12.6, false], ["cailloux", 67.2, 12.8, true], ["os_dino", 57.0, 13.4, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# The dead end of the Canyon des Vents: boulders fallen from the walls.
	for p: Array in [["rocher_canyon", 9.4, 6.2, false], ["rocher_canyon", 20.6, 5.4, true], ["cailloux", 8.6, 12.4, false],
			["os_dino", 19.8, 13.6, true], ["buisson_sec", 10.2, 14.2, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# The Vieux Rempart's hollow: a dry bush, bones of old meals, a boulder.
	for p: Array in [["buisson_sec", 25.4, 30.2, true], ["os_dino", 17.4, 35.4, false], ["rocher_canyon", 15.0, 33.8, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# Tante Sirocco's camp: her tent, her finds laid out, a crate.
	B.prop(entities, "tente_nomade", B.cell(TENT.x, TENT.y))
	for p: Array in [["caisses", 88.8, 65.6, true], ["os_dino", 84.0, 66.0, false], ["tonneau", 89.6, 66.4, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])


## The story's places and people (story/desert.gd, story/desert_sanctuaire.gd).
static func _story(root: Region, entities: Node2D) -> void:
	# Hélène's pages: 17 among the ribs of the cemetery, 19 by the oasis's well, 20 at the far end
	# of the walled canyon.
	for p: Array in [[17, 80.8, 76.4], [19, 93.7, 27.3], [20, 16.0, 30.4]]:
		var page = B.prop(entities, "ambre", B.cell(p[1], p[2]), false, load(PICKUP))
		page.name = "Page%d" % p[0]
		page.taken_flag = StringName("found_journal_%d" % p[0])
		page.dialogue_id = StringName("page_%d" % p[0])
	# The six fossils, each at the foot of its landmark (Tante Sirocco's hints).
	for f: Array in FOSSILS:
		if f[2] != "":
			B.prop(entities, f[2], B.cell(f[3].x, f[3].y), f[4])
		B.buried_item(root, f[1].x, f[1].y, "fossile", f[0])
	B.npc(root, "Sirocco", "Tante Sirocco", CHARS % "tante_sirocco", SIROCCO.x, SIROCCO.y, {"facing": "down", "event": &"sirocco"})
	# The walled canyon: the fallen rocks (Charge) wall to wall across its mouth, the Vieux
	# Rempart at its end.
	var rubble = B.prop(entities, "rempart_eboulis", B.cell(RUBBLE.x, RUBBLE.y), false, load(OBSTACLE))
	rubble.name = "RempartEboulis"
	rubble.ability = &"charge"
	rubble.cleared_flag = &"rempart_ouvert"
	rubble.blocked_dialogue = &"rempart_bloque"
	rubble.debris_color = Color(0.78, 0.52, 0.34)
	B.dino_npc(root, "VieuxRempart", &"vieux_rempart", RAMPART.x, RAMPART.y, {"event": &"vieux_rempart", "size": 1.3})
	# The sanctuary: its door in the rock face (gone once open: the scene fades it), the circle on
	# the square where Brac is met, the Carnotaurus home again by the door afterwards.
	var door = B.prop(entities, "porte_vents", B.cell(DOOR.x, DOOR.y), false, load(STORY_PROP))
	door.name = "PorteVents"
	door.event = &"porte_vents"
	door.hide_flag = &"sanctuaire_ouvert"
	B.trigger(root, TRIGGER_SANCTUAIRE.x, TRIGGER_SANCTUAIRE.y, 3.0, &"brac_sanctuaire",
		{"required_flag": &"desert_arrivee", "once_flag": &"brac_desert_vu"})
	B.dino_npc(root, "CarnoGardien", &"carnotaurus", CARNO_GARDIEN.x, CARNO_GARDIEN.y, {"event": &"carno_gardien",
		"show_flag": &"sceau_desert", "size": 1.2, "flip": true})
	# The Canyon des Vents: the chase in three moments, Brac cornered at the dead end with his
	# cart, the Carnotaurus Rouge (corrupted) once he is beaten.
	for i in CHASE.size():
		B.trigger(root, CHASE[i].x, CHASE[i].y, CHASE_RADIUS, StringName("poursuite_%d" % (i + 1)),
			{"required_flag": &"brac_desert_vu", "once_flag": StringName("poursuite_%d_ok" % (i + 1))})
	B.npc(root, "BracDesert", "Brac", CHARS % "brac", BRAC.x, BRAC.y, {"facing": "down", "event": &"brac_desert",
		"show_flag": &"brac_desert_vu", "hide_flag": &"brac_desert_battu"})
	var cart = B.prop(entities, "chariot_cage", B.cell(CART.x, CART.y), false, load(STORY_PROP))
	cart.name = "ChariotBrac"
	cart.event = &"chariot_brac"
	B.dino_npc(root, "CarnotaurusRouge", &"carnotaurus", CARNO.x, CARNO.y, {"event": &"carnotaurus_rouge",
		"corrupted": true, "size": 1.3, "show_flag": &"brac_desert_battu", "hide_flag": &"sceau_desert", "flip": true})
	B.npc(root, "MaiaOasis", "Maïa", CHARS % "maia", MAIA.x, MAIA.y, {"facing": "down", "event": &"maia_defi_4",
		"show_flag": &"sceau_desert", "hide_flag": &"maia_defi_4"})
	B.sign(entities, B.cell(104.0, 94.2), &"panneau_desert_entree")
	B.sign(entities, B.cell(90.4, 73.8), &"panneau_cimetiere")
	B.sign(entities, B.cell(89.4, 34.4), &"panneau_oasis", true)
	B.sign(entities, B.cell(63.4, 14.8), &"panneau_sanctuaire")


## Campfires to rest by (see Rest), the ground around them cleared.
static func _rest_spots(root: Region, entities: Node2D) -> void:
	for p: Array in [["feu_camp", 104.8, 85.6], ["feu_camp", 89.4, 68.4], ["feu_camp", 95.4, 24.8],
			["feu_camp", 36.0, 64.2], ["feu_camp", 56.5, 15.4]]:
		var at := B.flat_spot(root, Vector2(p[1], p[2]), 1)
		for c in entities.get_children():
			if c.get_script() == Prop and c.position.distance_to(at) < 2.0 * B.TILE:
				c.free()
		B.prop(entities, p[0], at)


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", 102.0, 95.0)
	# South: the way back to the Marais (its north exit, x 84-88).
	B.spawn(root, "DepuisMarais", 102.0, 97.6)
	B.exit(root, Rect2(100.0, 99.45, 4.0, 0.55), &"marais", &"DepuisDesert")
	# The sanctuary's door: its way in just before the door (walking up to the shut door says
	# why it is shut); Chloé comes back out on the square, room before the door for the scenes.
	B.spawn(root, "DepuisSanctuaire", DOOR.x, DOOR.y + 3.8)
	B.exit(root, Rect2(DOOR.x - 1.4, DOOR.y - 0.05, 2.8, 0.5), &"sanctuaire_vents", &"DepuisDesert",
		&"sanctuaire_ouvert", &"porte_vents_fermee")
	# North: the Côte Préhistorique (to come: « bientôt »).
	B.spawn(root, "DepuisCote", 100.0, 2.0)
	B.exit(root, Rect2(98.0, 0.0, 4.0, 0.55), &"cote", &"DepuisDesert", &"cote_ouverte", &"cote_bloquee")


static func _habitats(root: Region) -> void:
	# The widest first (where they overlap, the last one listed wins).
	B.habitat(root, "Le Grand Erg", Rect2(36, 16, 56, 42), [
		[&"pinacosaurus", 22, 25, 7, "jour", false], [&"oviraptor", 22, 24, 4, "jour", false], [&"pinacosaurus", 22, 25, 8, "toujours", true],
		[&"velociraptor_sables", 23, 26, 8, "nuit", false], [&"velociraptor_sables", 23, 26, 6, "nuit", true],
		[&"psittacosaurus", 22, 24, 5, "jour", true], [&"oviraptor", 22, 24, 4, "jour", true],
	], 3)
	B.habitat(root, "Les Dunes du sud", Rect2(0, 70, 64, 30), [
		[&"pinacosaurus", 21, 24, 7, "jour", false], [&"psittacosaurus", 21, 23, 6, "jour", false],
		[&"velociraptor_sables", 22, 25, 8, "nuit", false], [&"velociraptor_sables", 22, 25, 6, "nuit", true],
		[&"pinacosaurus", 21, 24, 6, "toujours", true], [&"protoceratops", 21, 23, 5, "jour", true],
	], 3)
	B.habitat(root, "Les Dunes de l'est", Rect2(88, 36, 32, 44), [
		[&"pinacosaurus", 22, 25, 10, "jour", false], [&"protoceratops", 21, 23, 6, "jour", false],
		[&"velociraptor_sables", 23, 26, 8, "nuit", false], [&"pinacosaurus", 22, 24, 6, "toujours", true],
		[&"velociraptor_sables", 23, 25, 5, "nuit", true],
	], 2)
	B.habitat(root, "Les Dunes du nord", Rect2(76, 0, 44, 22), [
		[&"pinacosaurus", 23, 26, 8, "jour", false], [&"velociraptor_sables", 24, 27, 8, "nuit", false],
		[&"oviraptor", 23, 25, 6, "jour", true], [&"velociraptor_sables", 24, 26, 5, "nuit", true],
	], 2)
	B.habitat(root, "Les Rochers de l'ouest", Rect2(14, 56, 50, 16), [
		[&"stygimoloch", 22, 25, 10, "jour", false], [&"oviraptor", 22, 24, 6, "jour", false],
		[&"stygimoloch", 22, 25, 6, "toujours", true], [&"protoceratops", 21, 23, 4, "jour", true],
		[&"majungasaurus", 24, 26, 2, "nuit", false],
	], 2)
	B.habitat(root, "Le Canyon d'entrée", Rect2(88, 78, 32, 22), [
		[&"pinacosaurus", 21, 23, 8, "jour", false], [&"oviraptor", 21, 22, 8, "jour", false],
		[&"protoceratops", 21, 22, 6, "toujours", true], [&"stygimoloch", 21, 23, 4, "jour", true],
		[&"velociraptor_sables", 22, 23, 4, "nuit", false],
	], 2)
	B.habitat(root, "Le Lac de sel", Rect2(64, 82, 24, 14), [
		[&"pinacosaurus", 21, 23, 8, "jour", false], [&"protoceratops", 21, 23, 6, "jour", true],
		[&"velociraptor_sables", 22, 24, 4, "nuit", false],
	], 1)
	B.habitat(root, "Le Cimetière des Géants", Rect2(60, 58, 30, 24), [
		[&"oviraptor", 21, 24, 12, "jour", false], [&"oviraptor", 21, 24, 10, "toujours", true],
		[&"majungasaurus", 25, 27, 3, "nuit", false], [&"majungasaurus", 25, 27, 1, "nuit", true],
		[&"velociraptor_sables", 23, 25, 5, "nuit", true], [&"protoceratops", 22, 23, 4, "jour", true],
	], 3)
	B.habitat(root, "L'Oasis", Rect2(86, 20, 26, 18), [
		[&"ouranosaurus", 22, 25, 10, "jour", false], [&"ouranosaurus", 22, 25, 8, "toujours", true],
		[&"iguanodon", 22, 24, 4, "jour", false], [&"compsognathus", 21, 23, 5, "jour et crépuscule", true],
		[&"dimorphodon", 22, 23, 4, "aube et crépuscule", true],
	], 3)
	B.habitat(root, "Le Canyon des Vents", Rect2(24, 4, 26, 16), [
		[&"stygimoloch", 23, 26, 8, "jour", false], [&"stygimoloch", 23, 26, 6, "toujours", true],
		[&"velociraptor_sables", 24, 26, 4, "nuit", false],
	], 1)
	# Calm places (no dinos; their names on the map): the square of the sanctuary, the dead end
	# of the Canyon des Vents (Brac's), the walled canyon (the Vieux Rempart's).
	B.habitat(root, "Le Sanctuaire des Vents", Rect2(48, 0, 26, 16), [], 0)
	B.habitat(root, "Le Cul-de-sac", Rect2(4, 2, 20, 16), [], 0)
	B.habitat(root, "Le Canyon muré", Rect2(12, 24, 22, 36), [], 0)
