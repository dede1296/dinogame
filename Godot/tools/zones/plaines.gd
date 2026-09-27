extends RefCounted
## Plaines des Fougères — the whole region in one open map (120 x 90 tiles), drawn from
## tools/maps/plaines_sols.png and plaines_relief.png (made by gen-plaines.mjs, retouchable).
## South: the road from Port-Ambre and the cove; centre: the crossroads, the pond; west:
## Hélène's grove behind the trunk (Tranche); north: the Grotte des Échos in its hill, behind
## the boulder (Charge); north-east: the cliffs behind the amber door (Résonance), Hélène's
## observation post on top; south-east: the Grand Crâne and its Alpha.

const PATH := "res://regions/plaines/plaines.tscn"
const B := preload("res://tools/zone_builder.gd")
const MAPS := "res://tools/maps/plaines_%s.png"
const CHARS := "res://assets/art/characters/%s.png"
const OBSTACLE := "res://world/obstacle.gd"
const PICKUP := "res://world/pickup.gd"
const STORY_PROP := "res://world/story_prop.gd"
## Small plants, bushes, rocks and lone trees scattered on the grass: [kind, chance per tile].
const SCATTER := [
	["fleurs_roses", 0.022], ["fleurs_violettes", 0.02], ["fougeres", 0.03], ["buisson", 0.008],
	["cailloux", 0.006], ["rocher", 0.0025], ["souche", 0.003], ["arbre_rond", 0.007],
	["araucaria", 0.005], ["fougere_arbre", 0.006], ["ronces", 0.004],
]
## Where nothing is scattered (tiles): around the story places, so they stay readable.
const KEEP_CLEAR := [
	Rect2(55, 41, 10, 8), Rect2(54, 22, 8, 7), Rect2(88, 34, 10, 6), Rect2(98, 52, 12, 16),
	Rect2(12, 24, 8, 8), Rect2(90, 9, 12, 5), Rect2(55, 84, 10, 6),
	# Off the beaten track: Chipie's nest, the pond's shore and islet, the sleeper, the egg rock, the cove sign.
	Rect2(38.5, 33, 5, 3), Rect2(76, 43.5, 6, 6), Rect2(54, 65, 4, 4), Rect2(63.5, 38.5, 3, 3), Rect2(24, 65.5, 3, 2),
]
## Chipie's run from the crossroads to her nest (tiles; see FleeingDino).
const CHIPIE_PATH := [Vector2(57.5, 42.5), Vector2(52.5, 40.5), Vector2(48.5, 37.5), Vector2(44.5, 35.6), Vector2(41.6, 34.8)]
const FLEEING_DINO := "res://world/fleeing_dino.gd"
const SLEEPER := "res://world/sleeper.gd"


static func build() -> Region:
	var root := B.region_from_maps(&"plaines", "Plaines des Fougères", "", Vector2i(3, 7),
		MAPS % "sols", MAPS % "relief", "res://regions/plaines/plaines_relief.res")
	root.music = load("res://assets/audio/music/plaines.ogg")
	root.ambience_id = &"plaines"
	var entities: Node2D = root.get_node("Entities")
	_scatter(root, entities)
	_story(root, entities)
	_rest_spots(root, entities)
	# 30 amber pebbles: 8 in trees, 8 under stones, 8 buried (Flair), 3 in nooks worth the climb,
	# 2 in Chipie's nest and 1 on the pond's islet (full moon): see _annexes.
	B.hide_pebbles(root, entities, Vector2i(60, 86), 3007, 8, 8,
		[Vector2(45, 64), Vector2(70, 72), Vector2(30, 52), Vector2(52, 36), Vector2(88, 58),
			Vector2(100, 24), Vector2(15, 33), Vector2(110, 75)],
		[Vector2(70, 15), Vector2(102, 10), Vector2(24, 71)])
	_annexes(root, entities)
	_places(root)
	_habitats(root)
	return root


static func _scatter(root: Region, entities: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2609
	var terrain: TileMapLayer = root.get_node("Terrain")
	var size := terrain.get_used_rect().end
	for y in size.y:
		for x in size.x:
			var data := terrain.get_cell_tile_data(Vector2i(x, y))
			if data == null or String(data.get_custom_data("terrain")) != "grass":
				continue
			if KEEP_CLEAR.any(func(r: Rect2) -> bool: return r.has_point(Vector2(x + 0.5, y + 0.5))):
				continue
			if _near_path(terrain, x, y):
				continue
			for row: Array in SCATTER:
				if rng.randf() < row[1]:
					B.prop(entities, row[0], B.cell(x + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9)), rng.randf() < 0.5)
					break
	# Flowers in Hélène's grove, ferns and tree ferns around the pond.
	for p: Array in [["fleurs_violettes", 14.5, 26.5], ["fleurs_roses", 17.8, 25.2], ["fougeres", 13.2, 30.4],
			["fleurs_roses", 21.4, 29.0], ["souche", 22.0, 26.2], ["fougere_arbre", 73.5, 46.2], ["fougeres", 84.6, 49.5],
			["fleurs_roses", 76.2, 51.4], ["fougere_arbre", 85.2, 45.3], ["cailloux", 81.0, 51.6]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), rng.randf() < 0.5)


static func _near_path(terrain: TileMapLayer, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var d := terrain.get_cell_tile_data(Vector2i(x + dx, y + dy))
			if d and String(d.get_custom_data("terrain")) == "path":
				return true
	return false


## The story's places and people.
static func _story(root: Region, entities: Node2D) -> void:
	# The crossroads: Maïa, the signpost.
	B.npc(root, "Maia", "Maïa", CHARS % "maia", 62.6, 44.4, {"facing": "left", "event": &"maia", "hide_flag": &"sceau_plaines"})
	# After the Sceau: she waits at the foot of the skull for her challenge (story/plaines.gd).
	B.npc(root, "MaiaDefi", "Maïa", CHARS % "maia", 100.8, 65.2, {"facing": "right", "event": &"maia_defi",
		"show_flag": &"sceau_plaines", "hide_flag": &"maia_defi_1"})
	B.sign(entities, B.cell(57.4, 44.8), &"panneau_carrefour")
	B.sign(entities, B.cell(61.6, 84.6), &"panneau_debarcadere")
	# Hélène's grove, behind the fallen trunk (Tranche): page 1 and the first amber scale.
	var trunk = B.prop(entities, "tronc", B.cell(20.0, 40.9), false, load(OBSTACLE))
	trunk.name = "TroncBosquet"
	trunk.ability = &"tranche"
	trunk.cleared_flag = &"tronc_bosquet_tranche"
	trunk.blocked_dialogue = &"tronc_bloque"
	var amber = B.prop(entities, "ambre", B.cell(15.6, 27.6), false, load(PICKUP))
	amber.name = "AmbreProtoceratops"
	amber.taken_flag = &"found_journal_1"
	amber.dialogue_id = &"ambre_proto"
	# The Grotte des Échos: a dark mouth at the back of a notch in the hill's south face, the
	# boulder (Charge) plugging the notch.
	var mouth := CaveMouth.new()
	mouth.name = "EntreeGrotte"
	mouth.width = 1.8
	mouth.position = B.cell(58.0, 23.0)
	entities.add_child(mouth)
	var boulder = B.prop(entities, "rocher", B.cell(58.0, 24.6), false, load(OBSTACLE))
	boulder.name = "RocherGrotte"
	boulder.ability = &"charge"
	boulder.cleared_flag = &"rocher_grotte_brise"
	boulder.blocked_dialogue = &"rocher_bloque"
	boulder.debris_color = Color(0.55, 0.55, 0.58)
	B.sign(entities, B.cell(61.2, 27.4), &"panneau_grotte", true)
	for p: Array in [["rocher_grotte", 55.6, 25.8], ["cailloux", 60.8, 25.8], ["stalagmite", 54.4, 26.0]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]))
	# The cliffs: the amber door in the gorge (Résonance); Hélène's observation post on top.
	var door = B.prop(entities, "porte_ambre", B.cell(93.0, 38.0), false, load(OBSTACLE))
	door.name = "PorteAmbre"
	door.ability = &"resonance"
	door.cleared_flag = &"porte_ambre_ouverte"
	door.blocked_dialogue = &"porte_ambre_bloquee"
	door.debris_color = Color(1, 0.72, 0.3)
	B.prop(entities, "banc", B.cell(96.0, 12.4))
	B.sign(entities, B.cell(94.2, 12.6), &"panneau_falaises")
	var page3 = B.prop(entities, "ambre", B.cell(98.0, 12.6), false, load(PICKUP))
	page3.taken_flag = &"found_journal_3"
	page3.dialogue_id = &"page_3"
	var scale3 = B.prop(entities, "ecaille", B.cell(100.0, 12.8), false, load(PICKUP))
	scale3.taken_flag = &"ecaille_falaises"
	scale3.dialogue_id = &"ecaille_falaises"
	# The Grand Crâne: the Alpha's cave at the back of its notch, the amber door closing the
	# notch; the Alpha once it is open.
	var lair := CaveMouth.new()
	lair.name = "AntreCrane"
	lair.width = 3.6
	lair.height = 3.2
	lair.position = B.cell(104.0, 58.0)
	entities.add_child(lair)
	var skull = B.prop(entities, "grand_crane", B.cell(104.0, 62.0), false, load(STORY_PROP))
	skull.name = "PorteCrane"
	skull.event = &"grand_crane"
	skull.hide_flag = &"crane_ouvert"
	B.sign(entities, B.cell(100.4, 64.8), &"panneau_crane")
	B.dino_npc(root, "Alpha", &"triceratops", 107.2, 63.8, {"event": &"alpha_plaines", "size": 1.35, "flip": true,
		"show_flag": &"crane_ouvert", "hide_flag": &"sceau_plaines"})


## Off the beaten track (story/plaines_annexes.gd, docs/histoire.md « Hors des sentiers »):
## Chipie and her nest, the pond's full-moon ford and islet (page 2), the sleeper, signs.
static func _annexes(root: Region, entities: Node2D) -> void:
	var chipie = load(FLEEING_DINO).new()
	chipie.name = "Chipie"
	chipie.species_id = &"compsognathus"
	chipie.flip = true
	chipie.waypoints = PackedVector2Array(CHIPIE_PATH)
	chipie.stage_flag = &"chipie_etape"
	chipie.arrived_flag = &"chipie_au_nid"
	chipie.appear_flag = &"boussole_volee"
	chipie.hide_flag = &"chipie_au_nid"
	chipie.position = B.cell(CHIPIE_PATH[0].x, CHIPIE_PATH[0].y)
	entities.add_child(chipie)
	var nest = B.prop(entities, "buisson", B.cell(40.6, 34.1), false, load(STORY_PROP))
	nest.name = "NidChipie"
	nest.event = &"nid_chipie"
	# The pond: the ford lights up at full moon, the singers gather; page 2 on the islet.
	var ford := MoonFord.new()
	ford.name = "GueDeLune"
	ford.position = B.cell(78, 45)
	ford.size = Vector2(2, 2)
	ford.islet = Rect2(78, 47, 2, 2)
	ford.singer_spots = PackedVector2Array([Vector2(73.4, 47.5), Vector2(85.5, 47.6), Vector2(74.2, 50.5), Vector2(80.5, 51.4)])
	root.add_child(ford)
	var page = B.prop(entities, "ambre", B.cell(78.5, 47.7), false, load(PICKUP))
	page.name = "Page2"
	page.taken_flag = &"found_journal_2"
	page.dialogue_id = &"page_2"
	var pebble = B.prop(entities, "galet", B.cell(79.5, 48.4), false, load(PICKUP))
	pebble.name = "GaletIlot"
	pebble.taken_flag = &"galet_plaines_ilot"
	B.sign(entities, B.cell(81.4, 44.3), &"panneau_etang")
	# A moulted Parasaurolophus skin on the shore, once Joss has asked for one (Havre-Doré).
	var skin = B.prop(entities, "cailloux", B.cell(84.4, 50.2), false, load(PICKUP))
	skin.name = "CuirMue"
	skin.show_flag = &"selle_demandee"
	skin.taken_flag = &"cuir_trouve"
	skin.item_id = "cuir"
	skin.dialogue_id = &"cuir_trouve"
	root.pebbles += 3
	# The sleeper under his tree, south of the crossroads.
	B.prop(entities, "arbre_rond", B.cell(55.4, 66.4))
	var sleeper = load(SLEEPER).new()
	sleeper.name = "Dormeur"
	sleeper.species_id = &"protoceratops"
	sleeper.event = &"dormeur"
	sleeper.size_scale = 0.9
	sleeper.position = B.cell(56.4, 67.4)
	entities.add_child(sleeper)
	# A smile or two.
	B.sign(entities, B.cell(25.5, 66.5), &"panneau_anse")
	B.prop(entities, "rocher", B.cell(65.0, 39.6))
	B.sign(entities, B.cell(64.0, 40.3), &"panneau_oeuf")


## Campfires and benches to rest by (see Rest), the ground around them cleared.
static func _rest_spots(root: Region, entities: Node2D) -> void:
	for p: Array in [["feu_camp", 56.0, 51.0], ["feu_camp", 31.5, 64.0], ["feu_camp", 96.0, 10.4],
			["banc", 75.4, 44.4], ["banc", 62.8, 66.0]]:
		# On flat ground, two tiles round (not in the water, not on a cliff's edge).
		var at := B.flat_spot(root, Vector2(p[1], p[2]), 2)
		for c in entities.get_children():
			if c.get_script() == Prop and c.position.distance_to(at) < 2.6 * B.TILE:
				c.free()
		B.prop(entities, p[0], at)


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", 60.0, 86.0)
	B.spawn(root, "DepuisPort", 60.0, 88.2)
	B.spawn(root, "DepuisGrotte", 58.0, 24.3)
	# Where the saves from the older, smaller zones of the Plaines land.
	B.spawn(root, "Debarcadere", 60.0, 78.0)
	B.spawn(root, "Carrefour", 60.0, 48.0)
	B.spawn(root, "Falaises", 93.0, 33.0)
	B.spawn(root, "Crane", 100.0, 66.5)
	B.exit(root, Rect2(58.0, 89.45, 4.0, 0.55), &"port_ambre", &"DepuisPlaines")
	B.exit(root, Rect2(57.2, 22.95, 1.6, 0.5), &"grotte_echos", &"DepuisCarrefour")
	# Into the Alpha's lair, at the back of the Grand Crâne (once its door is open).
	B.spawn(root, "DepuisAntre", 104.0, 60.0)
	B.exit(root, Rect2(102.5, 58.0, 3.0, 0.6), &"antre_crane", &"DepuisPlaines", &"crane_ouvert")


static func _habitats(root: Region) -> void:
	# The widest first (where they overlap, the last one listed wins).
	B.habitat(root, "Prairies du sud", Rect2(36, 56, 44, 30), [
		[&"protoceratops", 3, 5, 10, "toujours", true], [&"parasaurolophus", 3, 5, 3, "jour", true],
		[&"protoceratops", 3, 5, 10, "jour", false], [&"velociraptor", 4, 5, 4, "nuit", false],
	], 3)
	B.habitat(root, "Le carrefour", Rect2(26, 32, 50, 24), [
		[&"protoceratops", 3, 6, 10, "toujours", true], [&"velociraptor", 4, 6, 3, "nuit", true],
		[&"protoceratops", 3, 6, 10, "jour", false], [&"psittacosaurus", 4, 6, 6, "aube et crépuscule", false],
		[&"velociraptor", 4, 6, 5, "nuit", false],
	], 3)
	B.habitat(root, "Rive de l'anse", Rect2(10, 56, 28, 24), [
		[&"parasaurolophus", 3, 5, 10, "jour et crépuscule", false], [&"protoceratops", 3, 5, 10, "toujours", true],
	], 2)
	B.habitat(root, "L'étang", Rect2(70, 43, 18, 11), [[&"parasaurolophus", 3, 6, 10, "jour et crépuscule", false]], 2)
	B.habitat(root, "Le bosquet d'Hélène", Rect2(8, 20, 20, 20), [
		[&"velociraptor", 4, 6, 10, "aube et crépuscule", false], [&"velociraptor", 4, 6, 10, "toujours", true],
	], 1)
	B.habitat(root, "Les falaises", Rect2(81, 8, 30, 28), [
		[&"dimorphodon", 5, 7, 10, "jour et crépuscule", false], [&"psittacosaurus", 5, 7, 10, "aube et crépuscule", true],
		[&"protoceratops", 5, 6, 6, "toujours", true],
	], 3)
	B.habitat(root, "Le Grand Crâne", Rect2(84, 48, 30, 38), [
		[&"compsognathus", 5, 7, 10, "jour", false], [&"ankylosaurus", 7, 8, 3, "nuit", false],
		[&"compsognathus", 5, 7, 10, "toujours", true], [&"psittacosaurus", 5, 6, 4, "aube et crépuscule", true],
	], 3)
