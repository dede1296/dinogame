extends RefCounted
## Côte Préhistorique — the whole region in one open map (128 x 100 tiles), drawn from
## tools/maps/cote_sols.png and cote_relief.png (made by gen-cote.mjs, retouchable). North is
## the sea. South-west: the way in from the Désert (its rim goes on here), dunes, the last one
## over the bay; west: the Baie des Tortues and the Plage aux tortues (the turtles' nests, the
## fishermen of « La Sardine » by their stranded boat, the Cale des Anciens at its west end:
## page 24), the turtles' islet out in the bay; centre-west: the Pointe des Palmes and its rocky
## tip over the open sea; centre: the Lagon (its islet, the Plesiosaurus's sandy point where Joss
## waits, page 25 on its bottom), closed by its reef but for the pass, beyond which one dives to
## the sanctuary's reef (zone recif_sanctuaire); east: the Falaises à Ptéranodons — the east
## beach at their foot, two terraces (ramps), the headland over the sea and its colony (Maïa),
## the cove under it whose beach (reached swimming) has the sea caves' mouth (zone
## grottes_marines), the lookout above the cove (Hélène's box: page 23), the way on to the Monts
## Gelés (east edge, closed for now); south: a grove of palms and cycads. The places are named in
## story/cote_places.gd (CotePlaces), read here so the two agree.

const PATH := "res://regions/cote/cote.tscn"
const B := preload("res://tools/zone_builder.gd")
const P := preload("res://story/cote_places.gd")
const MAPS := "res://tools/maps/cote_%s.png"
const PICKUP := "res://world/pickup.gd"
const STORY_PROP := "res://world/story_prop.gd"
const CHARS := "res://assets/art/characters/%s.png"
## The côte's own music and battle picture when they exist; meanwhile the Plaines' (sea, meadows).
const MUSIC := ["res://assets/audio/music/cote.ogg", "res://assets/audio/music/plaines.ogg"]
const BACKDROP := ["res://assets/art/battle/cote.jpg", "res://assets/art/battle/plaines.jpg"]
## A few light patches of snow along the east edge, where the Côte meets the Monts Gelés (the
## cover layer, Region.cover_*: tools/maps/cote_neige.png, made by gen-monts.mjs, 0.3 at most).
const SNOW_TEX := "res://assets/art/ground/neige.png"
const SNOW_MAP := "res://tools/maps/cote_neige.png"
const SNOW_RES := "res://regions/cote/cote_neige.res"
const ENTRANCE := Vector2i(19, 98)
const SEED := 5281

## What stands on each ground (see _table): [kind, chance per tile, stand-in while the kind has
## no picture yet ("" = nothing)]. The first row that wins the roll is placed.
const BEACH := [
	["coquillages", 0.012, "cailloux"], ["algues", 0.008, "cailloux"], ["bois_flotte", 0.002, "tronc"],
	["rocher_cote", 0.0015, "rocher"],
]
const DUNES := [
	["oyats", 0.03, "hautes_herbes"], ["buisson_sec", 0.004, ""], ["cailloux", 0.004, ""],
	["palmier_cote", 0.0015, "palmier_oasis"],
]
## (29/09: cycads instead of the Plaines' pink flowers, the coast's own plants.)
const MEADOW := [
	["palmier_cote", 0.012, "palmier_oasis"], ["fougere_arbre", 0.005, ""], ["buisson", 0.006, ""],
	["fougeres", 0.02, ""], ["cycas", 0.006, "fleurs_roses"], ["fleurs_violettes", 0.005, ""],
	["rocher_cote", 0.003, "rocher"], ["cailloux", 0.004, ""],
]
## Up on the terraces and the headland: wind-bent scrub, stones, a few araucarias.
const CLIFFTOP := [
	["buisson", 0.01, ""], ["fougeres", 0.018, ""], ["rocher_cote", 0.005, "rocher"], ["cailloux", 0.008, ""],
	["fleurs_violettes", 0.008, ""], ["araucaria", 0.003, ""],
]
## Bare rock at sea level (the Pointe's tip): stones, weed, shells.
const ROCKY := [["cailloux", 0.03, ""], ["algues", 0.02, "cailloux"], ["coquillages", 0.01, "cailloux"]]
## Up on the Désert's rim nobody reaches (seen from above).
const TOPS := [["rocher_canyon", 0.01, ""], ["buisson_sec", 0.012, ""], ["cailloux", 0.012, ""]]
## The headland's ledges and the sea stacks, out of reach: the Pteranodons' nests.
const LEDGES := [["nid_pteranodon", 0.06, "nid_oviraptor"], ["buisson", 0.01, ""], ["cailloux", 0.01, ""]]
## Just south of a trail or a place (the camera looks north, 40° down: anything taller than
## Chloé there would hide them): low things only.
const LOW := [["cailloux", 0.012, ""], ["coquillages", 0.008, "cailloux"]]
## How far south of what must be seen (tiles) nothing tall stands.
const VIEW_SHADOW := 5
## Ground above this height (m) is a terrace or the top (2.4 m, 4.8 m).
const UPLAND := 2.2
## Heights of the reef's rock (1 m out of the water) and of the Désert's rim.
const REEF := Vector2(0.9, 1.1)
const RIM := 1.8
## Where nothing is scattered (tiles): around the places, so they stay readable.
const KEEP_CLEAR := [
	Rect2(14, 86, 12, 14), Rect2(15, 78, 9, 6), Rect2(22, 69, 11, 8), Rect2(1, 68, 10, 10), Rect2(41, 28, 9, 6),
	Rect2(57, 50, 9, 12), Rect2(86, 36, 9, 4), Rect2(88, 24, 9, 7), Rect2(95, 26, 9, 9), Rect2(88, 60, 10, 6),
	Rect2(99, 43, 9, 6), Rect2(104, 10, 10, 8), Rect2(120, 54, 8, 8), Rect2(113, 10, 8, 6), Rect2(71, 27, 6, 4),
]
## Buildings of the côte, assembled in 3D later (docs/direction-artistique.md « Bâtiments
## assemblés en vraie 3D »): placed once world/prop.gd knows their kind. [kind, tiles, flip]
const BUILDINGS_3D := [
	["phare_ruine", P.PHARE, false],   # the ruined lighthouse on the headland, seen from all the côte
]


static func build() -> Region:
	var root := B.region_from_maps(&"cote", "Côte Préhistorique", "", Vector2i(28, 35),
		MAPS % "sols", MAPS % "relief", "res://regions/cote/cote_relief.res")
	root.music = load(_first(MUSIC))
	root.ambience_id = &"cote"
	var backdrop := _first(BACKDROP)
	if backdrop != "":
		root.battle_backdrop = load(backdrop)
	# By the sea: showers, morning mist off the water, now and then a storm.
	root.rain_chance = 0.07
	root.mist_chance = 0.12
	root.storm_chance = 0.05
	root.sandstorm_chance = 0.0
	if ResourceLoader.exists(SNOW_TEX) and FileAccess.file_exists(ProjectSettings.globalize_path(SNOW_MAP)):
		root.cover_tex = load(SNOW_TEX)
		var dose := Image.load_from_file(ProjectSettings.globalize_path(SNOW_MAP))
		dose.convert(Image.FORMAT_L8)
		ResourceSaver.save(dose, SNOW_RES)
		root.cover_data = load(SNOW_RES)
	var entities: Node2D = root.get_node("Entities")
	_scatter(root, entities)
	_landmarks(root, entities)
	_reef(root, entities)
	_story(root, entities)
	_rest_spots(root, entities)
	# 30 amber pebbles: 3 in the cycads and araucarias, 10 under stones, 8 buried (Flair: the
	# Masiakasaurus have it), 9 in nooks worth the swim or the climb (the islets, the sand bars,
	# the Pointe's tip, the cove, the far end of the headland, the Cale, the dunes' far corner).
	B.hide_pebbles(root, entities, ENTRANCE, 8316, 3, 10,
		[Vector2(8, 88), Vector2(31, 91), Vector2(36, 72), Vector2(55, 78), Vector2(82, 84), Vector2(91, 44),
			Vector2(101, 86), Vector2(120, 34)],
		[Vector2(23, 57), Vector2(45, 31), Vector2(74, 29.5), Vector2(76, 42), Vector2(94.5, 28.5), Vector2(126, 20),
			Vector2(4, 76), Vector2(100, 96), Vector2(3, 90)], true)
	_swap_stand_ins(entities)
	_places(root)
	_habitats(root)
	return root


## The first of `paths` that exists ("" when none does).
static func _first(paths: Array) -> String:
	for p: String in paths:
		if ResourceLoader.exists(p):
			return p
	return ""


## The kind of a table row, or its stand-in while the kind has no picture ("" = nothing).
## A kind whose stand-in is a stone one can turn over (Search.STONES) stays that stone until the
## pebbles are hidden (_swap_stand_ins): the pebbles keep the stones they were given before the
## shore had its own pictures (29/09), and a stone hiding one stays a stone.
static func _kind(row: Array) -> String:
	var stand_in: String = row[2] if row.size() > 2 else ""
	if Prop.KINDS.has(row[0]) and not (stand_in in Search.STONES):
		return row[0]
	if Prop.KINDS.has(stand_in):
		return stand_in
	return row[0] if Prop.KINDS.has(row[0]) else ""


## A prop of `kind` (or its stand-in, see _kind) at tile point `t`; null when neither exists.
static func _put(entities: Node2D, kind: String, stand_in: String, t: Vector2, flip := false, script: Script = null) -> Node2D:
	var k := _kind([kind, 0.0, stand_in])
	if k == "":
		return null
	return _mark(B.prop(entities, k, B.cell(t.x, t.y), flip, script), kind)


## A stone standing in for `kind` until the pebbles are hidden (see _kind): marked to become it.
static func _mark(p: Node2D, kind: String) -> Node2D:
	if p is Prop and (p as Prop).kind != kind and Prop.KINDS.has(kind):
		p.set_meta(&"becomes", kind)
	return p


## Once the pebbles are hidden: the stones marked by _mark become what they stood in for,
## unless they hide a pebble (then they stay stones, to be turned over).
static func _swap_stand_ins(entities: Node) -> void:
	for p in entities.get_children():
		if not p.has_meta(&"becomes"):
			continue
		var kind: String = p.get_meta(&"becomes")
		p.remove_meta(&"becomes")
		if p is Prop and (p as Prop).hidden_pebble == &"":
			(p as Prop).kind = kind
			p.name = kind.to_pascal_case()


## The ground under tile `c` ("" outside the map).
static func _ground(terrain: TileMapLayer, c: Vector2i) -> String:
	var d := terrain.get_cell_tile_data(c)
	return String(d.get_custom_data("terrain")) if d else ""


static func _kept_clear(middle: Vector2) -> bool:
	return KEEP_CLEAR.any(func(r: Rect2) -> bool: return r.has_point(middle))


## What stands on tile `c`, by its ground, its height and whether Chloé can get there.
static func _table(root: Region, terrain: TileMapLayer, c: Vector2i, ground: String, reach: Dictionary) -> Array:
	var h := root.tile_height(c)
	if ground == "rock":
		if h >= RIM:
			return TOPS
		return [] if h >= REEF.x else ROCKY
	if not reach.has(c):
		return LEDGES if h >= UPLAND else []
	if h >= UPLAND:
		return CLIFFTOP
	if ground == "sand":
		return BEACH if _near(terrain, c, "water", 3) or c.x >= 42 else DUNES
	return MEADOW


static func _scatter(root: Region, entities: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var terrain: TileMapLayer = root.get_node("Terrain")
	var reach: Dictionary = B._reachable(root, ENTRANCE, true)
	var size := terrain.get_used_rect().end
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			var ground := _ground(terrain, c)
			if not ground in B.OPEN_GROUND or _kept_clear(Vector2(x + 0.5, y + 0.5)):
				continue
			if _near(terrain, c, "path", 1) or not _steady(root, c, 0.35):
				continue
			var table: Array = _table(root, terrain, c, ground, reach)
			if table.is_empty():
				continue
			if table != BEACH and table != ROCKY and _near(terrain, c, "water", 1):
				continue
			if (table == TOPS or table == LEDGES) and _overlooks(root, c):
				continue
			if not (table in [TOPS, LEDGES, BEACH, ROCKY]) and _in_view(terrain, c):
				table = LOW
			for row: Array in table:
				if rng.randf() < row[1]:
					var kind := _kind(row)
					if kind != "":
						_mark(B.prop(entities, kind, B.cell(x + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9)), rng.randf() < 0.5), row[0])
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
			if _kept_clear(Vector2(n) + Vector2(0.5, 0.5)):
				return true
	return false


## Tile `c` is up on a wall over lower ground just north of it: a boulder standing there would
## hide what is below from the camera, which looks north.
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
				if _ground(terrain, c) in B.OPEN_GROUND and _steady(root, c, 0.35):
					return B.cell(t.x + dx, t.y + dy)
	return B.cell(t.x, t.y)


## Scenery placed by hand: the way in, the turtles' beach and the Cale des Anciens, the Pointe's
## palms, the lagoon's islet, the cove, the lookout.
static func _landmarks(root: Region, entities: Node2D) -> void:
	# The way in: the Désert's rock and dry scrub still, the first dune grass.
	for p: Array in [["rocher_canyon", "", 13.2, 93.4, false], ["buisson_sec", "", 26.8, 93.0, true], ["cailloux", "", 16.4, 90.2, false],
			["oyats", "hautes_herbes", 23.2, 89.4, true], ["oyats", "hautes_herbes", 15.6, 86.6, false]]:
		var at := _open_near(root, Vector2(p[2], p[3])) / B.TILE
		_put(entities, p[0], p[1], at, p[4])
	# The turtles' beach: driftwood and shells at the tide line, the turtles' nests (the second
	# one is the StoryProp of the little turtles' quest: _story).
	for i in P.NIDS.size():
		if i != 1:
			_put(entities, "nid_tortue", "monticule", P.NIDS[i], i % 2 == 0)
	for p: Array in [["bois_flotte", "tronc", 14.6, 73.8, false], ["bois_flotte", "tronc", 33.0, 69.4, true],
			["coquillages", "cailloux", 18.4, 74.2, false], ["algues", "cailloux", 9.4, 74.8, true], ["coquillages", "cailloux", 31.2, 71.6, true]]:
		_put(entities, p[0], p[1], Vector2(p[2], p[3]), p[4])
	# The fishermen of « La Sardine »: their boat stranded at the water's edge, the net spread on
	# the sand, pots and a barrel (they stand there: _story).
	B.prop(entities, "barque", B.cell(P.SARDINE.x, P.SARDINE.y), true)
	for p: Array in [["filet", 30.6, 73.0, false], ["casiers", 24.4, 72.6, false], ["tonneau", 30.0, 75.2, true], ["cordage", 25.6, 75.4, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# The Cale des Anciens: two weathered pillars either side of the platform.
	for p: Array in [[3.4, 74.4, false], [8.6, 74.4, true]]:
		B.prop(entities, "colonne", B.cell(p[0], p[1]), p[2])
	# « Au pied des vieilles marches taillées dans la roche, coincée sous un masque d'os sculpté »
	# (page 24): the carved stone just behind the page.
	_put(entities, "masque_pierre", "", Vector2(P.CALE.x + 0.3, P.CALE.y - 0.7))
	# The Pointe des Palmes: palms along its spine, rocks on its tip.
	for p: Array in [[44.0, 60.6, true], [47.2, 53.4, true], [44.2, 45.2, false], [47.0, 38.6, true]]:
		_put(entities, "palmier_cote", "palmier_oasis", _open_near(root, Vector2(p[0], p[1])) / B.TILE, p[2])
	for p: Array in [[42.8, 31.0, false], [48.0, 31.6, true]]:
		_put(entities, "rocher_cote", "rocher_mousse", Vector2(p[0], p[1]), p[2])
	# The lagoon: palms on its islet, a rock by the Plesiosaurus's point (its tip stays clear).
	for p: Array in [[74.2, 42.2, false], [76.2, 43.0, true]]:
		_put(entities, "palmier_cote", "palmier_oasis", Vector2(p[0], p[1]), p[2])
	_put(entities, "rocher_cote", "rocher", Vector2(64.4, 56.2), true)
	# The cove: the sea caves' dark mouth at the back of the notch in the headland's face, weed
	# and stones on the shingle.
	var mouth := CaveMouth.new()
	mouth.name = "EntreeGrottes"
	mouth.width = 1.8
	mouth.height = 2.0
	mouth.position = B.cell(P.ENTREE_GROTTES.x, P.ENTREE_GROTTES.y)
	entities.add_child(mouth)
	for p: Array in [["algues", "cailloux", 90.2, 28.8, false], ["cailloux", "", 95.3, 29.0, true], ["rocher_cote", "rocher", 89.6, 27.8, false]]:
		_put(entities, p[0], p[1], Vector2(p[2], p[3]), p[4])
	# Buildings in 3D, once assembled.
	for b: Array in BUILDINGS_3D:
		if Prop.KINDS.has(b[0]):
			B.prop(entities, b[0], B.cell(b[1].x, b[1].y), b[2])


## The reef: rocks along its ridge (one every few tiles, on the rock out of the water), the two
## big ones either side of the pass.
static func _reef(root: Region, entities: Node2D) -> void:
	var terrain: TileMapLayer = root.get_node("Terrain")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 1
	var last_x := -10
	for x in range(40, 92):
		if x - last_x < 5:
			continue
		for y in range(14, 36):
			var c := Vector2i(x, y)
			var h := root.tile_height(c)
			if _ground(terrain, c) != "rock" or h < REEF.x or h > REEF.y or absf(x - P.PASSE.x) < 4.5:
				continue
			_put(entities, "rocher_recif", "rocher_mousse", Vector2(x + rng.randf_range(0.3, 0.7), y + 0.7), rng.randf() < 0.5)
			last_x = x
			break
	for p: Array in [[P.PASSE.x - 2.9, P.PASSE.y + 0.9, false], [P.PASSE.x + 3.1, P.PASSE.y + 0.4, true]]:
		var rock = _put(entities, "rocher_recif", "rocher_mousse", Vector2(p[0], p[1]), p[2])
		if rock:
			rock.name = "SoeurRecif"


## The story's places and people (story/cote*.gd).
static func _story(root: Region, entities: Node2D) -> void:
	# Hélène's pages: 24 on the Cale des Anciens; 25 on the lagoon's bottom, glinting once Chloé has
	# Joss's diving mask (Plongée). (21 and 22: the sea caves, the sanctuary; 23: her box below.)
	var page24 = B.prop(entities, "ambre", B.cell(P.CALE.x, P.CALE.y), false, load(PICKUP))
	page24.name = "Page24"
	page24.taken_flag = &"found_journal_24"
	page24.dialogue_id = &"page_24"
	var bottom: Vector2 = P.PAGES[4][2]
	var page25 = B.prop(entities, "ambre", B.cell(bottom.x, bottom.y), false, load(PICKUP))
	page25.name = "Page25"
	page25.taken_flag = &"found_journal_25"
	page25.dialogue_id = &"page_25"
	page25.show_flag = &"masque_plongee"
	# The lookout: Hélène's box in a niche at the foot of the rock face (page 23, found with Maïa).
	var box = _put(entities, "boite_fer", "cailloux", P.BOITE_HELENE, false, load(STORY_PROP))
	box.name = "BoiteHelene"
	box.event = &"boite_helene"
	# (it stays once page 23 is found: « La boîte d'Hélène, vide, le couvercle tordu », story/cote_fin.gd)
	# The little turtles' nest (the quest at dusk).
	var nest = _put(entities, "nid_tortue", "monticule", P.NIDS[1], false, load(STORY_PROP))
	nest.name = "NidTortues"
	nest.event = &"nid_tortues"
	nest.after_flag = &"tortues_sauvees"   # (empty once the little ones have reached the sea)
	nest.after_kind = "nid_tortue_vide"
	# The fishermen of « La Sardine », Joss by the lagoon.
	B.npc(root, "Gustave", "Gustave", CHARS % "pecheur", P.GUSTAVE.x, P.GUSTAVE.y, {"facing": "up", "event": &"pecheurs_cote"})
	B.npc(root, "Firmin", "Firmin", CHARS % "sbire", P.FIRMIN.x, P.FIRMIN.y, {"facing": "left", "event": &"pecheurs_cote"})
	B.npc(root, "JossCote", "Joss", CHARS % "joss", P.JOSS.x, P.JOSS.y, {"facing": "up", "event": &"joss_cote"})
	# Maïa by the colony (until the third Cœur), then at the lookout over the cove.
	B.npc(root, "MaiaFalaises", "Maïa", CHARS % "maia", P.MAIA_FALAISES.x, P.MAIA_FALAISES.y, {"facing": "up",
		"event": &"maia_falaises", "show_flag": &"cote_arrivee", "hide_flag": &"coeur_3"})
	B.dino_npc(root, "CaillouFalaises", &"triceratops", P.MAIA_FALAISES.x + 1.6, P.MAIA_FALAISES.y + 0.4,
		{"size": 0.95, "show_flag": &"cote_arrivee", "hide_flag": &"coeur_3"})
	B.npc(root, "MaiaGuet", "Maïa", CHARS % "maia", P.MAIA_GUET.x, P.MAIA_GUET.y, {"facing": "up",
		"event": &"maia_guet", "show_flag": &"coeur_3", "hide_flag": &"maia_enfuie"})
	B.dino_npc(root, "CaillouGuet", &"triceratops", P.MAIA_GUET.x + 1.7, P.MAIA_GUET.y + 0.3,
		{"size": 0.95, "show_flag": &"coeur_3", "hide_flag": &"maia_enfuie"})
	B.sign(entities, _open_near(root, Vector2(22.6, 92.8)), &"panneau_cote_entree")
	B.sign(entities, _open_near(root, Vector2(21.0, 82.2)), &"panneau_plage_tortues", true)
	B.sign(entities, _open_near(root, Vector2(60.4, 66.2)), &"panneau_lagon")
	B.sign(entities, _open_near(root, Vector2(89.4, 65.8)), &"panneau_falaises", true)


## Campfires to rest by (see Rest), the ground around them cleared.
static func _rest_spots(root: Region, entities: Node2D) -> void:
	for p: Array in [["feu_camp", 25.0, 88.5], ["feu_camp", 29.5, 77.0], ["feu_camp", 72.0, 63.0],
			["feu_camp", 90.5, 56.5], ["feu_camp", 115.0, 52.0]]:
		var at := B.flat_spot(root, Vector2(p[1], p[2]), 1)
		for c in entities.get_children():
			if c.get_script() == Prop and c.position.distance_to(at) < 2.0 * B.TILE:
				c.free()
		B.prop(entities, p[0], at)


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.ARRIVEE.x, P.ARRIVEE.y + 4.0)
	# South: the way back to the Désert (its north exit, x 98-102: Désert x = côte x + 80).
	B.spawn(root, P.SPAWN_DESERT, 19.5, 97.4)
	B.exit(root, Rect2(18.0, 99.45, 4.0, 0.55), &"desert", P.DESERT_SPAWN_COTE)
	# The sea caves: their way in at the back of the notch; Chloé comes back out on the shingle.
	B.spawn(root, P.SPAWN_GROTTES, P.ENTREE_GROTTES.x, P.ANSE_GROTTES.y + 0.3)
	B.exit(root, Rect2(P.ENTREE_GROTTES.x - 0.8, P.ENTREE_GROTTES.y - 0.05, 1.6, 0.5), &"grottes_marines", P.GROTTES_SPAWN_COTE)
	# The sanctuary's reef: one dives beyond the pass (only once page 21 has told where); back up
	# on the sand bar inside the pass.
	B.spawn(root, P.SPAWN_RECIF, P.BANC_PASSE.x, P.BANC_PASSE.y)
	# (a dive spot: the water darker there, the dive button; « Remonter » comes back up right here)
	DiveSpot.place(root, Rect2(P.ACCES_RECIF.x - 1.5, P.ACCES_RECIF.y - 1.5, 3.0, 3.0), &"recif_sanctuaire",
		P.RECIF_SPAWN_COTE, {"name": "PlongeeRecif", "required_flag": &"passe_recif", "blocked_dialogue": &"recif_bloque"})
	# East: the Monts Gelés (to come: « bientôt »), up on the top.
	B.spawn(root, P.SPAWN_MONTS, 125.5, 57.5)
	B.exit(root, Rect2(127.45, 56.0, 0.55, 4.0), &"monts", &"DepuisCote", &"monts_ouverts", &"monts_bloques")


static func _habitats(root: Region) -> void:
	# The widest first (where they overlap, the last one listed wins). The sea's own dinos are met
	# in the sea grass along the shores (tall grass) — and swimming, once the water has encounters.
	B.habitat(root, "La Baie des Tortues", Rect2(0, 0, 42, 66), [
		[&"archelon", 29, 31, 8, "jour", false], [&"archelon", 29, 31, 8, "toujours", true],
		[&"ichthyosaurus", 31, 33, 3, "jour", true], [&"plesiosaurus", 29, 31, 4, "jour", true],
	], 1)
	B.habitat(root, "Le Large", Rect2(42, 0, 46, 24), [
		[&"ichthyosaurus", 32, 34, 10, "jour", true], [&"plesiosaurus", 30, 32, 5, "toujours", true],
		[&"archelon", 30, 32, 4, "toujours", true],
	], 0)
	B.habitat(root, "Les Dunes", Rect2(0, 80, 44, 20), [
		[&"masiakasaurus", 28, 30, 8, "aube et crépuscule", false], [&"masiakasaurus", 28, 30, 8, "toujours", true],
		[&"pinacosaurus", 27, 29, 6, "jour", true], [&"archelon", 28, 29, 3, "jour", false],
	], 2)
	B.habitat(root, "La Plage aux tortues", Rect2(0, 66, 40, 14), [
		[&"archelon", 28, 30, 12, "jour", false], [&"archelon", 28, 30, 8, "jour", true],
		[&"masiakasaurus", 28, 30, 8, "aube et crépuscule", false], [&"masiakasaurus", 28, 30, 6, "toujours", true],
		[&"pteranodon", 29, 31, 3, "jour", true],
	], 3)
	B.habitat(root, "Les Prés du lagon", Rect2(44, 58, 52, 42), [
		[&"masiakasaurus", 28, 30, 8, "toujours", true], [&"masiakasaurus", 28, 30, 6, "aube et crépuscule", false],
		[&"pteranodon", 29, 31, 6, "jour", true], [&"pteranodon", 29, 31, 5, "jour", false],
		[&"archelon", 28, 30, 3, "jour", true],
	], 2)
	B.habitat(root, "La Pointe des Palmes", Rect2(38, 28, 14, 36), [
		[&"plesiosaurus", 29, 31, 8, "jour", true], [&"ichthyosaurus", 31, 33, 4, "jour", true],
		[&"masiakasaurus", 29, 31, 5, "toujours", true], [&"archelon", 29, 30, 5, "jour", false],
	], 1)
	B.habitat(root, "Le Lagon", Rect2(50, 28, 36, 30), [
		[&"plesiosaurus", 29, 31, 10, "jour", true], [&"plesiosaurus", 29, 31, 5, "toujours", true],
		[&"archelon", 29, 31, 6, "jour", true], [&"archelon", 29, 31, 6, "jour", false],
	], 2)
	B.habitat(root, "La Passe", Rect2(62, 16, 16, 16), [
		[&"ichthyosaurus", 31, 33, 8, "jour", true], [&"plesiosaurus", 30, 32, 6, "toujours", true],
	], 0)
	B.habitat(root, "La Plage des falaises", Rect2(84, 36, 12, 28), [
		[&"masiakasaurus", 30, 32, 8, "aube et crépuscule", false], [&"masiakasaurus", 30, 32, 6, "toujours", true],
		[&"plesiosaurus", 30, 31, 4, "jour", true], [&"archelon", 29, 31, 4, "jour", false],
	], 2)
	B.habitat(root, "Les Terrasses", Rect2(96, 27, 32, 73), [
		[&"pteranodon", 31, 33, 8, "jour", false], [&"pteranodon", 31, 33, 8, "jour", true],
		[&"masiakasaurus", 31, 33, 5, "toujours", true], [&"masiakasaurus", 31, 33, 5, "aube et crépuscule", false],
	], 2)
	B.habitat(root, "Les Falaises à Ptéranodons", Rect2(86, 6, 42, 21), [
		[&"pteranodon", 31, 34, 12, "jour", false], [&"pteranodon", 31, 34, 10, "jour", true],
		[&"masiakasaurus", 32, 34, 3, "toujours", true],
	], 3)
	# Calm places (no dinos; their names on the map): the Cale des Anciens, the cove of the sea
	# caves, the lookout.
	B.habitat(root, "La Cale des Anciens", Rect2(0, 68, 10, 9), [], 0)
	B.habitat(root, "La Crique des grottes", Rect2(86, 24, 10, 7), [], 0)
	B.habitat(root, "Le Belvédère", Rect2(96, 27, 8, 8), [], 0)
