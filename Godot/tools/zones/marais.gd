extends RefCounted
## Marais Brumeux — the whole region in one open map (120 x 96 tiles), drawn from
## tools/maps/marais_sols.png and marais_relief.png (made by gen-marais.mjs, retouchable).
## East, walked before the swimming vest: the boardwalk from the Forêt's bridge, the Débarcadère
## (Joss's hut on stilts, a campfire), the Roselière de l'est (the Baryonyx with the vest, other
## Baryonyx fishing, Corythosaurus), the long boardwalk north (Roc's night walk) to the Roselière
## du nord (Maïa, the way to the Désert), the Bassin des nénuphars (page 16, full moon).
## The Grand chenal all round it; with the vest and a grown swimmer (the Nage), the rest: the
## Îlot de la Voix behind its amber door (Résonance), the Îlot aux racines (Dame Suie, page 13),
## the Île du temple (the door of the sunken temple, zone temple_englouti), the Forêt noyée
## (page 14), page 15 on a sand bar in the channels. Mud ("mud" tiles), reed beds (tall grass),
## boardwalks (a Dock over each straight run of path cells), mist often, rain.

const PATH := "res://regions/marais/marais.tscn"
const B := preload("res://tools/zone_builder.gd")
const BORDERS := preload("res://tools/zones/borders.gd")
const MAPS := "res://tools/maps/marais_%s.png"
const PICKUP := "res://world/pickup.gd"
const MOON_PAGE := "res://regions/foret/moon_page.gd"
const STORY_PROP := "res://world/story_prop.gd"
const OBSTACLE := "res://world/obstacle.gd"
const TEMPLE_DOOR := "res://regions/marais/porte_temple.gd"
const CHARS := "res://assets/art/characters/%s.png"
const MUSIC := "res://assets/audio/music/marais.ogg"
const BACKDROP := "res://assets/art/battle/marais.jpg"
const SLABS := "res://assets/art/ground/dalles_temple.png"
const ENTRANCE := Vector2i(117, 69)
## The paved square before the temple's door (path cells paved with the temple's slabs; the
## other path cells are boardwalks). As gen-marais.mjs's PLAZA.
const PLAZA := Rect2(25, 11, 11, 6)
## Boardwalks stop this far from the edges of the map (tiles): they land on the bank there.
const EDGE_LANDING := 3
## The Forêt noyée (south-west): drowned trees everywhere on its mud.
const DROWNED := Rect2(2, 54, 56, 40)
## What grows on each ground (see _table): [kind, chance per tile]. The first row that wins
## the roll is placed. By the water, the reeds; out in the Forêt noyée, the drowned trees.
const MUD := [
	["roseaux", 0.03], ["hautes_herbes", 0.04], ["fougeres", 0.03], ["arbre_noye", 0.006], ["souche", 0.003],
	["cailloux", 0.005], ["champignons", 0.004],
]
const SHORE := [["roseaux", 0.1], ["hautes_herbes", 0.03], ["arbre_noye", 0.006], ["cailloux", 0.004]]
const NOYEE := [
	["arbre_noye", 0.075], ["roseaux", 0.035], ["fougeres", 0.03], ["souche", 0.006], ["champignons", 0.012],
	["tronc_mousse", 0.003], ["cailloux", 0.004],
]
const FIRM := [
	["fougeres", 0.07], ["fleurs_violettes", 0.012], ["prele", 0.006, "fleurs_roses"], ["fougere_arbre", 0.014],
	["arbre_rond", 0.005], ["buisson", 0.008], ["cailloux", 0.008], ["roseaux", 0.012],
]
const REEDS := [["roseaux", 0.07], ["prele", 0.01, "fougeres"]]
const SANDY := [["cailloux", 0.012], ["roseaux", 0.012]]
## Just south of a boardwalk or a place (the camera looks north, 40° down: anything taller
## than Chloé there would hide them): low plants only.
const LOW := [["fougeres", 0.08], ["hautes_herbes", 0.04], ["champignons", 0.01], ["cailloux", 0.006], ["fleurs_violettes", 0.006]]
## How far south of what must be seen (tiles) nothing tall stands.
const VIEW_SHADOW := 5
## Water lilies on the still water, this close to a shore (tiles).
const LILY_SHORE := 2
const LILY_CHANCE := 0.012
## Where nothing is scattered (tiles): around the places, so they stay readable.
const KEEP_CLEAR := [
	Rect2(94, 64, 16, 9), Rect2(80, 38, 8, 6), Rect2(97, 36, 6, 5), Rect2(81, 0, 10, 9), Rect2(75, 6, 6, 5),
	Rect2(90, 79, 14, 10), Rect2(47, 32, 18, 17), Rect2(18, 30, 16, 13), Rect2(19, 3, 23, 17), Rect2(22, 70, 18, 7),
	Rect2(33, 76, 6, 5), Rect2(67, 70, 6, 5), Rect2(62, 4, 36, 10),
]

## The story's places (tiles).
const JOSS := Vector2(100.0, 67.3)
const HUT := Vector2(101.2, 65.3)
const BARYONYX := Vector2(84.0, 41.2)
const VOIX_DOOR := Vector2(56.0, 42.15)
const VOIX := Vector2(56.0, 37.3)
const DAME_SUIE := Vector2(26.0, 35.2)
const ROC := Vector2(99.5, 20.0)
const MAIA := Vector2(86.0, 4.8)
## The door stands just in front of the foot of the rock's face, where the dark way in is drawn.
const TEMPLE_DOOR_AT := Vector2(30.0, 11.6)


static func build() -> Region:
	var root := B.region_from_maps(&"marais", "Marais Brumeux", "", Vector2i(15, 21),
		MAPS % "sols", MAPS % "relief", "res://regions/marais/marais_relief.res")
	root.music = load(MUSIC)
	root.ambience_id = &"marais"
	if ResourceLoader.exists(BACKDROP):
		root.battle_backdrop = load(BACKDROP)
	root.path_tex = load(SLABS)
	root.paved_rect = PLAZA
	# Mist rises often from the water (mornings above all), rain comes and goes.
	root.rain_chance = 0.3
	root.mist_chance = 0.3
	root.storm_chance = 0.04
	var entities: Node2D = root.get_node("Entities")
	_boardwalks(root)
	_scatter(root, entities)
	_landmarks(root, entities)
	_story(root, entities)
	_rest_spots(root, entities)
	# 30 amber pebbles: 6 in trees, 8 under stones, 8 buried (Flair), 8 in nooks worth the swim.
	B.hide_pebbles(root, entities, ENTRANCE, 5123, 6, 8,
		[Vector2(104, 34), Vector2(76, 13), Vector2(92, 88), Vector2(44, 30), Vector2(14, 58), Vector2(40, 88),
			Vector2(62, 62), Vector2(10, 16)],
		[Vector2(110, 44), Vector2(68, 15), Vector2(106, 86), Vector2(72, 44), Vector2(48, 26), Vector2(8, 44),
			Vector2(18, 84), Vector2(66, 80)], true)
	# The joins (tools/zones/borders.gd; last: nothing placed before moves): the Forêt's undergrowth
	# and ferns by the east edge; by the north edge, the cracked mud the Désert begins with (its
	# corridor) in patches and its dry scrub (a short band: « le Marais s'arrête d'un coup »).
	var forest := BORDERS.cover(root, "foret", "sous_bois", "terre", "res://regions/marais")
	BORDERS.plants(root, entities, forest, ["fougeres", "fougeres", "fougeres", "champignons", "souche"], 0.3, 5131, KEEP_CLEAR)
	var dry := BORDERS.cover(root, "desert", "vase", "", "res://regions/marais")
	BORDERS.plants(root, entities, dry, ["buisson_sec", "roseaux_secs", "roseaux_secs"], 0.3, 5133, KEEP_CLEAR)
	_places(root)
	_habitats(root)
	return root


## The ground under tile `c` ("" outside the map).
static func _ground(terrain: TileMapLayer, c: Vector2i) -> String:
	var d := terrain.get_cell_tile_data(c)
	return String(d.get_custom_data("terrain")) if d else ""


## A Dock (planks on posts, the water running on under them) over each straight run of
## boardwalk (path cells outside the temple's square): runs across a row first, then as many
## rows down as the same run goes on. Near the edges of the map the boardwalks land on the
## bank (plain path there, as the next zone's path goes on beyond it).
static func _boardwalks(root: Region) -> void:
	var terrain: TileMapLayer = root.get_node("Terrain")
	var size := terrain.get_used_rect().end
	var taken := {}
	var plank := func(c: Vector2i) -> bool:
		return not taken.has(c) and _ground(terrain, c) == "path" and not PLAZA.has_point(Vector2(c) + Vector2(0.5, 0.5)) \
			and c.x >= EDGE_LANDING and c.y >= EDGE_LANDING and c.x < size.x - EDGE_LANDING and c.y < size.y - EDGE_LANDING
	var n := 0
	for y in size.y:
		for x in size.x:
			if not plank.call(Vector2i(x, y)):
				continue
			var w := 1
			while plank.call(Vector2i(x + w, y)):
				w += 1
			var h := 1
			while range(w).all(func(i: int) -> bool: return plank.call(Vector2i(x + i, y + h))):
				h += 1
			for yy in h:
				for xx in w:
					taken[Vector2i(x + xx, y + yy)] = true
			n += 1
			var d := B.dock(root, Rect2(x, y, w, h))
			d.name = "Ponton%d" % n


## What grows on tile `c`, by its ground and where it is.
static func _table(terrain: TileMapLayer, c: Vector2i, ground: String) -> Array:
	match ground:
		"tall_grass":
			return REEDS
		"sand":
			return SANDY
		"grass":
			return FIRM
	if DROWNED.has_point(Vector2(c) + Vector2(0.5, 0.5)):
		return NOYEE
	return SHORE if _near(terrain, c, "water", 1) else MUD


static func _scatter(root: Region, entities: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2311
	var terrain: TileMapLayer = root.get_node("Terrain")
	var size := terrain.get_used_rect().end
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			var ground := _ground(terrain, c)
			var middle := Vector2(x + 0.5, y + 0.5)
			if KEEP_CLEAR.any(func(r: Rect2) -> bool: return r.has_point(middle)):
				continue
			if ground == "water":
				# Water lilies on the still water near a shore (they float: Prop "float").
				if rng.randf() < LILY_CHANCE and _near(terrain, c, "mud", LILY_SHORE) and not _near(terrain, c, "path", 2):
					B.prop(entities, "nenuphars", B.cell(x + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.8)), rng.randf() < 0.5)
				continue
			if not ground in ["grass", "mud", "tall_grass", "sand"]:
				continue
			if _near(terrain, c, "path", 1) or not _steady(root, c):
				continue
			for row: Array in LOW if _in_view(terrain, c) else _table(terrain, c, ground):
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


## A boardwalk or a place kept clear just north of tile `c` (it must stay in sight).
static func _in_view(terrain: TileMapLayer, c: Vector2i) -> bool:
	for k in range(1, VIEW_SHADOW + 1):
		for dx in range(-2, 3):
			var n := c + Vector2i(dx, -k)
			if _ground(terrain, n) == "path":
				return true
			var middle := Vector2(n) + Vector2(0.5, 0.5)
			if KEEP_CLEAR.any(func(r: Rect2) -> bool: return r.has_point(middle)):
				return true
	return false


## Tile `c` is level with all its neighbours (nothing stands on a cliff's edge or a ramp).
static func _steady(root: Region, c: Vector2i) -> bool:
	var h := root.tile_height(c)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if absf(root.tile_height(c + Vector2i(dx, dy)) - h) > 0.3:
				return false
	return true


## Scenery placed by hand: Joss's hut and workshop, lanterns along the boardwalks, the lilies
## of the Bassin, the Voix's island, the roots of Dame Suie's island, the temple's island.
static func _landmarks(root: Region, entities: Node2D) -> void:
	B.prop(entities, "cabane_pilotis", B.cell(HUT.x, HUT.y))
	for p: Array in [["caisses", 104.2, 66.6, false], ["tonneau", 105.3, 67.4, true], ["filet", 95.6, 65.8, false],
			["barque", 111.6, 72.7, true], ["cordage", 103.2, 67.6, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# Lanterns on the edge of the boardwalks: lit at night (Roc's walk in the mist).
	for p: Array in [[112.0, 69.15], [99.15, 16.0], [100.85, 23.5], [97.15, 58.5], [96.85, 82.2], [94.0, 12.15]]:
		B.prop(entities, "lanterne", B.cell(p[0], p[1]))
	# The Bassin des nénuphars.
	for p: Array in [[93.4, 86.6], [99.6, 84.3], [100.9, 87.2], [94.3, 83.6], [98.3, 87.7], [101.6, 85.2], [92.6, 85.0]]:
		B.prop(entities, "nenuphars", B.cell(p[0], p[1]), int(p[0] * 10.0) % 2 == 0)
	# The Voix's island: drowned trees behind her rock, reeds on the sides of the beach (the south
	# stays open: the amber door and the rock seen from the water).
	for p: Array in [["arbre_noye", 51.4, 34.4], ["arbre_noye", 60.8, 34.6], ["arbre_noye", 56.4, 33.9],
			["roseaux", 49.2, 40.2], ["roseaux", 63.2, 40.6], ["roseaux", 49.8, 43.4], ["roseaux", 62.6, 43.8],
			["fougeres", 51.6, 44.6], ["fougeres", 60.4, 44.8], ["nenuphars", 50.0, 49.8], ["nenuphars", 61.8, 50.2]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), int(p[1] * 10.0) % 2 == 0)
	# Dame Suie's island: roots all round its north half, her barrels and crates, her boat.
	for p: Array in [["racines", 21.8, 32.4], ["racines", 30.4, 32.0], ["racines", 33.2, 36.8], ["racines", 18.8, 36.0],
			["tonneau", 23.2, 33.6], ["caisses", 28.8, 37.8], ["roseaux", 31.6, 40.0], ["roseaux", 20.6, 40.4],
			["barque", 28.3, 43.1]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), int(p[1] * 10.0) % 2 == 1)
	# (29/09) « Elle les range une à une dans des fioles… et ramasse son panier de fioles »: her
	# basket by her, gone with her.
	if Prop.KINDS.has("panier_fioles"):
		var basket = B.prop(entities, "panier_fioles", B.cell(DAME_SUIE.x + 1.1, DAME_SUIE.y + 0.3), false, load(STORY_PROP))
		basket.name = "PanierFioles"
		basket.hide_flag = &"dame_suie_battue"
	# The Voix's island: « les pierres d'ambre de l'îlot s'allument » (glowing amber), and « sur une
	# pierre plate, quelqu'un a gravé un nom, avec une petite fougère : La Voix ».
	for p: Array in [["cristaux", 53.0, 38.6, false], ["cristaux", 59.2, 38.8, true], ["cristaux", 54.4, 35.6, true],
			["pierre_gravee", 58.4, 40.4, true]]:
		if Prop.KINDS.has(p[0]):
			B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# The temple's island: statues either side of the door, columns round the square (the south
	# ones broken and low, so they hide nothing), ferns on the rock.
	for p: Array in [["statue_dino", 26.0, 11.7, false], ["statue_dino", 34.0, 11.7, true],
			["colonne", 25.4, 14.2, false], ["colonne", 34.6, 14.2, true], ["cailloux", 24.8, 16.6, false],
			["cailloux", 35.4, 16.8, true], ["fougere_arbre", 26.6, 6.6, false], ["fougere_arbre", 33.8, 6.9, true],
			["arbre_noye", 21.6, 9.4, false], ["arbre_noye", 38.4, 9.8, true], ["roseaux", 22.6, 15.6, false],
			["roseaux", 37.6, 15.4, true]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# Tree ferns and a few round trees on the firm ground (a pebble hides in some of them).
	for p: Array in [["fougere_arbre", 90.6, 44.2], ["arbre_rond", 104.6, 31.0], ["fougere_arbre", 72.2, 9.6],
			["fougere_arbre", 93.2, 7.6], ["arbre_rond", 91.0, 83.0], ["fougere_arbre", 108.4, 84.4],
			["fougere_arbre", 14.2, 57.4], ["arbre_rond", 48.4, 25.4], ["fougere_arbre", 62.6, 61.4], ["fougere_arbre", 38.4, 81.2]]:
		B.prop(entities, p[0], _open_near(root, Vector2(p[1], p[2])), int(p[1] * 10.0) % 2 == 0)
	# Page 14's clearing in the Forêt noyée: drowned trees round it, behind.
	for p: Array in [["arbre_noye", 22.4, 71.2], ["arbre_noye", 29.6, 70.8], ["arbre_noye", 20.6, 75.2],
			["champignons", 24.2, 73.2], ["fougeres", 27.8, 75.6]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), int(p[1] * 10.0) % 2 == 0)


## World position of tile point `t`, moved to the nearest firm ground (grass) that is level
## all round (the map may have been retouched under it).
static func _open_near(root: Region, t: Vector2) -> Vector2:
	var terrain: TileMapLayer = root.get_node("Terrain")
	for r in 4:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := Vector2i(t.floor()) + Vector2i(dx, dy)
				if _ground(terrain, c) in ["grass", "mud"] and _steady(root, c):
					return B.cell(t.x + dx, t.y + dy)
	return B.cell(t.x, t.y)


## The story's places and people (story/marais.gd plays their scenes).
static func _story(root: Region, entities: Node2D) -> void:
	# Hélène's pages: 13 on the roots' island (once Dame Suie has gone), 14 in the Forêt noyée,
	# 15 on the sand bar in the channels, 16 at the end of the lilies' pier (full-moon nights).
	for p: Array in [[13, 29.3, 33.8, PICKUP], [14, 26.0, 74.2, PICKUP], [15, 70.0, 72.3, PICKUP], [16, 96.0, 85.4, MOON_PAGE]]:
		var page = B.prop(entities, "ambre", B.cell(p[1], p[2]), false, load(p[3]))
		page.name = "Page%d" % p[0]
		page.taken_flag = StringName("found_journal_%d" % p[0])
		page.dialogue_id = StringName("page_%d" % p[0])
		if p[0] == 13:
			page.show_flag = &"dame_suie_battue"
	B.npc(root, "Joss", "Joss", CHARS % "joss", JOSS.x, JOSS.y, {"facing": "down", "event": &"joss_marais"})
	B.dino_npc(root, "BaryonyxGilet", &"baryonyx", BARYONYX.x, BARYONYX.y, {"event": &"baryonyx_gilet",
		"hide_flag": &"gilet_nage", "size": 0.55})   # (young: Marais.BARYONYX_SIZE)
	# The Voix's island: the amber door in the notch of her rock (Résonance), she up on it.
	var door = B.prop(entities, "porte_ambre", B.cell(VOIX_DOOR.x, VOIX_DOOR.y), false, load(OBSTACLE))
	door.name = "PorteVoix"
	door.ability = &"resonance"
	door.cleared_flag = &"porte_voix_ouverte"
	door.blocked_dialogue = &"porte_voix_bloquee"
	door.debris_color = Color(1.0, 0.72, 0.28)
	B.dino_npc(root, "VoixDuMarais", &"voix_du_marais", VOIX.x, VOIX.y, {"event": &"voix_du_marais", "size": 1.1})
	B.npc(root, "DameSuie", "Dame Suie", CHARS % "dame_suie", DAME_SUIE.x, DAME_SUIE.y, {"facing": "down",
		"event": &"dame_suie", "hide_flag": &"dame_suie_battue"})
	B.npc(root, "RocMarais", "Roc", CHARS % "roc", ROC.x, ROC.y, {"facing": "down", "event": &"roc_marais",
		"show_flag": &"roc_marais_en_vue", "hide_flag": &"roc_marais_vu"})
	B.npc(root, "MaiaRoseliere", "Maïa", CHARS % "maia", MAIA.x, MAIA.y, {"facing": "down", "event": &"maia_defi_3",
		"show_flag": &"sceau_marais", "hide_flag": &"maia_defi_3"})
	# The temple's door: gone once the Voix has sung it open (it fades then, even in sight),
	# showing the dark way in behind it, in the rock's face.
	var mouth := CaveMouth.new()
	mouth.name = "EntreeTemple"
	mouth.width = 2.4
	mouth.height = 2.2
	mouth.position = B.cell(TEMPLE_DOOR_AT.x, 11.0)
	entities.add_child(mouth)
	var temple = B.prop(entities, "porte_temple", B.cell(TEMPLE_DOOR_AT.x, TEMPLE_DOOR_AT.y), false, load(TEMPLE_DOOR))
	temple.name = "PorteTemple"
	temple.hide_flag = &"temple_ouvert"
	# « Des dizaines de petits masques d'os sculptés » above the temple's entrance (story/
	# marais_temple.gd): carved in the 2.4 m rock face over the cave mouth (2.3 m wide, 1.6 to 2.38 m, by its
	# negative foot: Region._clear_exit_corridors spares it); the door hides it until it is gone.
	if Prop.KINDS.has("frise_masques"):
		B.prop(entities, "frise_masques", B.cell(TEMPLE_DOOR_AT.x, 11.03))
	B.sign(entities, B.cell(107.0, 67.6), &"panneau_marais")
	B.sign(entities, B.cell(32.4, 17.6), &"panneau_temple", true)
	B.sign(entities, B.cell(89.6, 5.6), &"panneau_desert")


## Campfires and a bench to rest by (see Rest), the ground around them cleared.
static func _rest_spots(root: Region, entities: Node2D) -> void:
	for p: Array in [["feu_camp", 95.8, 68.8], ["feu_camp", 100.5, 38.5], ["feu_camp", 78.5, 8.8],
			["feu_camp", 21.5, 38.2], ["feu_camp", 36.4, 79.4], ["banc", 101.5, 81.4]]:
		var at := B.flat_spot(root, Vector2(p[1], p[2]), 1)
		for c in entities.get_children():
			if c.get_script() == Prop and c.position.distance_to(at) < 2.2 * B.TILE:
				c.free()
		B.prop(entities, p[0], at)


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", 104.0, 70.0)
	B.spawn(root, "DepuisForet", 116.5, 70.0)
	B.exit(root, Rect2(119.45, 68.0, 0.55, 4.0), &"foret", &"DepuisMarais")
	# North, the way to the Désert (zone desert: chapter 4), once Maïa's third challenge is won.
	B.spawn(root, "DepuisDesert", 86.0, 1.8)
	B.exit(root, Rect2(84.0, 0.0, 4.0, 0.55), &"desert", &"DepuisMarais", &"maia_defi_3", &"desert_bloque")
	# The temple's door: its way in just before the door (walking up to the shut door says why
	# it is shut); Chloé comes back out on the square.
	B.spawn(root, "DepuisTemple", 30.0, 13.4)
	B.exit(root, Rect2(28.6, 11.5, 2.8, 0.5), &"temple_englouti", &"DepuisMarais", &"temple_ouvert", &"porte_temple_fermee")


static func _habitats(root: Region) -> void:
	# The widest first (where they overlap, the last one listed wins). None of the roaming ones
	# reaches the Voix's rock (x 51-61, y 33-42): nobody wild waits behind her amber door.
	B.habitat(root, "Le Grand Chenal", Rect2(62, 20, 20, 76), [
		[&"koolasuchus", 17, 19, 6, "nuit", true], [&"baryonyx", 17, 19, 8, "jour", true],
		[&"iguanodon", 17, 19, 6, "jour", false], [&"koolasuchus", 17, 19, 4, "nuit", false],
	], 1)
	B.habitat(root, "Les Chenaux", Rect2(28, 43, 34, 11), [
		[&"baryonyx", 17, 19, 8, "toujours", true], [&"koolasuchus", 18, 20, 5, "nuit", true],
		[&"corythosaurus", 17, 19, 6, "jour", true], [&"iguanodon", 17, 19, 5, "jour", false],
	], 1)
	B.habitat(root, "Le Cœur de la roselière", Rect2(34, 14, 36, 18), [
		[&"corythosaurus", 17, 19, 8, "jour", true], [&"baryonyx", 17, 19, 8, "toujours", true],
		[&"koolasuchus", 18, 20, 5, "nuit", true], [&"corythosaurus", 17, 19, 6, "jour", false],
		[&"parasaurolophus", 17, 19, 4, "jour et crépuscule", false],
	], 2)
	B.habitat(root, "La Forêt noyée", Rect2(2, 54, 56, 40), [
		[&"therizinosaurus", 18, 21, 3, "toujours", true], [&"therizinosaurus", 18, 20, 3, "aube et crépuscule", false],
		[&"iguanodon", 17, 19, 6, "jour", false], [&"koolasuchus", 18, 20, 6, "nuit", true],
		[&"koolasuchus", 18, 20, 4, "nuit", false], [&"compsognathus", 17, 18, 6, "jour", true],
		[&"iguanodon", 17, 19, 4, "jour", true],
	], 3)
	B.habitat(root, "L'Îlot aux racines", Rect2(14, 26, 24, 20), [
		[&"suchomimus", 19, 21, 2, "toujours", true], [&"baryonyx", 18, 20, 6, "jour", false],
		[&"baryonyx", 18, 20, 6, "toujours", true], [&"koolasuchus", 18, 20, 5, "nuit", true],
		[&"iguanodon", 18, 19, 4, "jour", false],
	], 1)
	B.habitat(root, "La Roselière de l'est", Rect2(76, 24, 40, 34), [
		[&"baryonyx", 15, 17, 10, "jour", false], [&"baryonyx", 15, 17, 10, "toujours", true],
		[&"corythosaurus", 15, 17, 8, "jour", false], [&"corythosaurus", 15, 17, 8, "toujours", true],
		[&"iguanodon", 16, 17, 4, "jour", false], [&"koolasuchus", 16, 18, 5, "nuit", true],
		[&"dimorphodon", 15, 16, 4, "aube et crépuscule", true],
	], 3)
	B.habitat(root, "La Roselière du nord", Rect2(60, 0, 44, 20), [
		[&"corythosaurus", 17, 19, 8, "jour", false], [&"corythosaurus", 17, 19, 6, "toujours", true],
		[&"parasaurolophus", 17, 19, 6, "jour", false], [&"baryonyx", 17, 19, 8, "toujours", true],
		[&"dimorphodon", 17, 18, 4, "aube et crépuscule", true], [&"koolasuchus", 18, 19, 4, "nuit", true],
	], 3)
	B.habitat(root, "Le Débarcadère", Rect2(86, 52, 28, 20), [
		[&"corythosaurus", 15, 17, 8, "jour", false], [&"iguanodon", 15, 17, 5, "jour", false],
		[&"corythosaurus", 15, 17, 8, "toujours", true], [&"dimorphodon", 15, 16, 4, "aube et crépuscule", true],
	], 2)
	B.habitat(root, "Le Bassin des nénuphars", Rect2(86, 78, 28, 16), [
		[&"corythosaurus", 15, 17, 6, "toujours", true], [&"dimorphodon", 15, 16, 4, "aube et crépuscule", true],
		[&"iguanodon", 15, 17, 4, "jour", false],
	], 1)
	# Calm places (no dinos; their names on the map): the Voix's island, the temple's.
	B.habitat(root, "L'Îlot de la Voix", Rect2(46, 32, 20, 18), [], 0)
	B.habitat(root, "L'Île du temple", Rect2(16, 8, 28, 16), [], 0)
