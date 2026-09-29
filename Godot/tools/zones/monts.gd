extends RefCounted
## Monts Gelés — the whole region in one open map (130 x 110 tiles), drawn from
## tools/maps/monts_sols.png and monts_relief.png (made by gen-monts.mjs, retouchable). The land
## climbs from the south to the north and the east, under the peaks along the north and east
## edges. West: the way in from the Côte (its clifftops' level, 4.8 m; the Côte's last column is
## the Monts' first), snowy conifers either side; south-west: the Vallée des Troupeaux (3.6 m):
## Bertille's rock shelter and fire at the foot of a knoll, the herds' meadow, the frozen lake,
## the rise of page 30; centre-north: the glacier (6 m), up a slope from the way in, cut by two
## crevasses each crossed at one bridge an ice wall plugs (Charge): page 29 in its middle band,
## the caves' mouth at the back of a notch in its north band (zone grottes_glace); east: the Col
## des Tempêtes, its terrace (7.2 m) and its top (8.4 m) up two ramps from the glacier's
## south-east: page 28, the frost door at the back of a notch in its north face (zone
## sanctuaire_givre, once the three Cœurs have melted it), the gully up to the Cieux (north edge,
## closed); south-east: the tundra, the herds' pastures. The places are named in
## story/monts_places.gd (MontsPlaces), read here so the two agree.
## (The ground is the Côte's under a layer of snow, thin by the way in, whole farther on; ice on the
## glacier and the lake; WorldView gives it snowy conifers and snowy cliffs.)

const PATH := "res://regions/monts/monts.tscn"
const B := preload("res://tools/zone_builder.gd")
const P := preload("res://story/monts_places.gd")
const MAPS := "res://tools/maps/monts_%s.png"
const PICKUP := "res://world/pickup.gd"
const STORY_PROP := "res://world/story_prop.gd"
const OBSTACLE := "res://world/obstacle.gd"
const CHARS := "res://assets/art/characters/%s.png"
## The Monts' own music and battle picture when they exist; meanwhile the Plaines'.
const MUSIC := ["res://assets/audio/music/monts.ogg", "res://assets/audio/music/plaines.ogg"]
const BACKDROP := ["res://assets/art/battle/monts.jpg", "res://assets/art/battle/plaines.jpg"]
## The snow over the ground (Region.cover_*): its pictures (the snow, the trodden trail) and how
## much of it lies on each tile (tools/maps/monts_neige.png, made by gen-monts.mjs), saved next to
## the scene. Under it, the ground is the Côte's (grass, earth): the snow thins out towards it.
const SNOW_TEX := "res://assets/art/ground/neige.png"
const SNOW_PATH_TEX := "res://assets/art/ground/neige_chemin.png"
const SNOW_MAP := "res://tools/maps/monts_neige.png"
const SNOW_RES := "res://regions/monts/monts_neige.res"
## Less snow than this on a tile (0-1): the band towards the Côte, where its plants mix with the
## Monts' own (COAST, see _scatter).
const THIN_SNOW := 0.85
## Bertille's walking sheet, and a woman of her height meanwhile (1.60 m).
const BERTILLE_SHEETS := ["res://assets/art/characters/bertille.png", "res://assets/art/characters/marchande.png"]
const ENTRANCE := Vector2i(1, 30)
const SEED := 6271

## What stands on each ground (see _table): [kind, chance per tile, stand-in while the kind has
## no picture yet ("" = nothing)]. The first row that wins the roll is placed.
## The snow of the valley, the tundra and the way in: firs, frosted shrubs, snowy rocks, stones.
const SNOW := [
	["sapin_neige", 0.011, ""], ["buisson_givre", 0.024, ""], ["rocher_neige", 0.006, ""], ["cailloux", 0.007, ""],
	["pin_tordu", 0.003, ""],
]
## The band towards the Côte, where the snow thins out: the Côte's clifftop plants (scrub, ferns,
## an araucaria), mixed with SNOW by how much snow lies there.
const COAST := [
	["buisson", 0.012, ""], ["fougeres", 0.018, ""], ["araucaria", 0.004, ""], ["cailloux", 0.007, ""],
	["fleurs_violettes", 0.004, ""],
]
## Up on the col (wind-bent pines, snowy rocks) and the glacier's snowy margins.
const HIGH := [
	["pin_tordu", 0.006, ""], ["rocher_neige", 0.008, ""], ["buisson_givre", 0.01, ""], ["cailloux", 0.008, ""],
]
## The ice (the glacier, the frozen lake): séracs, ice crystals, a snowy boulder carried down.
const ICE := [["bloc_glace", 0.004, ""], ["cristaux_glace", 0.003, ""], ["rocher_neige", 0.002, ""]]
## The peaks' tops, out of reach (seen from below, behind their faces): a few twisted pines.
const PEAKS := [["pin_tordu", 0.004, ""], ["rocher_neige", 0.004, ""]]
## Just south of a trail or a place (the camera looks north, 40° down: anything taller than
## Chloé there would hide them): low things only.
const LOW := [["cailloux", 0.012, ""], ["buisson_givre", 0.006, ""]]
## How far south of what must be seen (tiles) nothing tall stands.
const VIEW_SHADOW := 5
## Heights (m): the peaks; the glacier and the col, above it.
const PEAK := 12.0
const GLACIER := 5.9
## Where nothing is scattered (tiles): around the places, so they stay readable.
const KEEP_CLEAR := [
	Rect2(0, 26, 10, 8), Rect2(15, 55, 12, 8), Rect2(35, 63, 10, 6), Rect2(6, 91, 9, 8), Rect2(42, 31, 8, 6),
	Rect2(54, 25, 6, 8), Rect2(64, 15, 6, 8), Rect2(62, 5, 8, 7), Rect2(80, 18, 7, 5), Rect2(88, 34, 8, 6),
	Rect2(102, 29, 7, 9), Rect2(104, 17, 10, 10), Rect2(108, 6, 14, 9), Rect2(97, 0, 7, 12), Rect2(118, 12, 6, 5),
	Rect2(84, 67, 8, 7),
]


static func build() -> Region:
	var root := B.region_from_maps(&"monts", "Monts Gelés", "", Vector2i(33, 40),
		MAPS % "sols", MAPS % "relief", "res://regions/monts/monts_relief.res")
	root.music = load(_first(MUSIC))
	root.ambience_id = &"monts"
	var backdrop := _first(BACKDROP)
	if backdrop != "":
		root.battle_backdrop = load(backdrop)
	_snow(root)
	# Up in the snow: often snowing, now and then a blizzard off the peaks, mist in the valley;
	# never rain nor thunder.
	root.rain_chance = 0.0
	root.storm_chance = 0.0
	root.mist_chance = 0.06
	root.sandstorm_chance = 0.0
	root.snow_chance = 0.12
	root.blizzard_chance = 0.03
	# A cold region: snow underfoot (the steps), and the warm coat.
	root.cold = true
	var entities: Node2D = root.get_node("Entities")
	_scatter(root, entities)
	_landmarks(root, entities)
	_story(root, entities)
	_rest_spots(root, entities)
	# 30 amber pebbles: 12 under stones, 8 buried (Flair: the Leaellynasaura have it), 10 in nooks
	# worth the walk (the lake's far shore, the rise, the glacier's bands, the col's corners, the
	# gully, the tundra's far end). (None in trees: the firs are not shaken, Search.TREES.)
	B.hide_pebbles(root, entities, ENTRANCE, 7316, 0, 12,
		[Vector2(9, 70), Vector2(30, 98), Vector2(52, 84), Vector2(76, 56), Vector2(96, 80), Vector2(120, 102),
			Vector2(31, 38), Vector2(114, 40)],
		[Vector2(47, 90), Vector2(12, 96), Vector2(88, 21), Vector2(44, 10), Vector2(123, 10), Vector2(100, 4),
			Vector2(122, 44), Vector2(124, 76), Vector2(6, 104), Vector2(62, 102)])
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
## pebbles are hidden (_swap_stand_ins).
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
static func _table(root: Region, c: Vector2i, ground: String, reach: Dictionary) -> Array:
	var h := root.tile_height(c)
	if h >= PEAK:
		return PEAKS
	if not reach.has(c):
		return []   # (the knoll, the outcrops, the crevasses' floors: nothing, they stay bare)
	if ground == "sand":
		return ICE
	if h >= GLACIER:
		return HIGH
	return SNOW


static func _scatter(root: Region, entities: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var terrain: TileMapLayer = root.get_node("Terrain")
	var reach: Dictionary = B._reachable(root, ENTRANCE)   # (the ice walls are props: the bands behind count)
	var size := terrain.get_used_rect().end
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			var ground := _ground(terrain, c)
			if not ground in B.OPEN_GROUND or _kept_clear(Vector2(x + 0.5, y + 0.5)):
				continue
			if _near(terrain, c, "path", 1) or not _steady(root, c, 0.35):
				continue
			var table: Array = _table(root, c, ground, reach)
			if table.is_empty():
				continue
			if table == PEAKS and _overlooks(root, c):
				continue
			if table == SNOW and _snow_on(root, c) < THIN_SNOW and rng.randf() >= _snow_on(root, c):
				table = COAST
			if table != PEAKS and _in_view(terrain, c):
				table = LOW
			for row: Array in table:
				if rng.randf() < row[1]:
					var kind := _kind(row)
					if kind != "":
						_mark(B.prop(entities, kind, B.cell(x + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9)), rng.randf() < 0.5), row[0])
					break


## The snow over the ground (Region.cover_*): the Côte's grass and earth under it (the zone's own
## ground pictures stay the defaults), dosed by tools/maps/monts_neige.png.
static func _snow(root: Region) -> void:
	if not (ResourceLoader.exists(SNOW_TEX) and FileAccess.file_exists(ProjectSettings.globalize_path(SNOW_MAP))):
		return
	root.cover_tex = load(SNOW_TEX)
	if ResourceLoader.exists(SNOW_PATH_TEX):
		root.cover_path_tex = load(SNOW_PATH_TEX)
	var dose := Image.load_from_file(ProjectSettings.globalize_path(SNOW_MAP))
	dose.convert(Image.FORMAT_L8)
	ResourceSaver.save(dose, SNOW_RES)
	root.cover_data = load(SNOW_RES)


## How much snow lies on tile `c` (0-1; all of it without a cover layer).
static func _snow_on(root: Region, c: Vector2i) -> float:
	if root.cover_data == null:
		return 1.0
	return root.cover_data.get_pixel(clampi(c.x, 0, root.cover_data.get_width() - 1), clampi(c.y, 0, root.cover_data.get_height() - 1)).r


## A tile of `ground` within `r` tiles of tile `c`.
static func _near(terrain: TileMapLayer, c: Vector2i, ground: String, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if _ground(terrain, c + Vector2i(dx, dy)) == ground:
				return true
	return false


## A trail or a place kept clear just north of tile `c` (it must stay in sight).
static func _in_view(terrain: TileMapLayer, c: Vector2i) -> bool:
	for k in range(1, VIEW_SHADOW + 1):
		for dx in range(-2, 3):
			var n := c + Vector2i(dx, -k)
			if _ground(terrain, n) == "path":
				return true
			if _kept_clear(Vector2(n) + Vector2(0.5, 0.5)):
				return true
	return false


## Tile `c` is up on a wall over lower ground just north of it: a thing standing there would
## hide what is below from the camera, which looks north.
static func _overlooks(root: Region, c: Vector2i) -> bool:
	var h := root.tile_height(c)
	for k in range(1, VIEW_SHADOW + 3):
		for dx in range(-2, 3):
			if root.tile_height(c + Vector2i(dx, -k)) < h - 1.0:
				return true
	return false


## Tile `c` is nearly level with all its neighbours (nothing stands on a cliff's edge).
static func _steady(root: Region, c: Vector2i, step := 0.3) -> bool:
	var h := root.tile_height(c)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if absf(root.tile_height(c + Vector2i(dx, dy)) - h) > step:
				return false
	return true


## World position of tile point `t`, moved to the nearest open ground that is level all round
## (the map may have been retouched under it: not over a drop).
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


## Scenery placed by hand: the way in, Bertille's camp, the lake, the glacier, the caves' mouth,
## the col.
static func _landmarks(root: Region, entities: Node2D) -> void:
	# The way in, where the snow starts: the Côte's araucarias and scrub, then the first snowy firs.
	for p: Array in [["araucaria", 7.4, 26.4, false], ["sapin_neige", 13.8, 26.8, true], ["rocher_neige", 17.6, 27.6, false],
			["buisson", 9.2, 34.2, true], ["araucaria", 5.6, 36.8, false], ["sapin_neige", 19.4, 35.6, true]]:
		_put(entities, p[0], "", _open_near(root, Vector2(p[1], p[2])) / B.TILE, p[3])
	# Bertille's camp: her shelter, a dark hollow dug into the knoll at the back of its notch; her
	# crates, a barrel, a rope either side of the way in (her fire in front: _rest_spots).
	var shelter := CaveMouth.new()
	shelter.name = "AbriBertille"
	shelter.width = 2.4
	shelter.height = 1.8
	shelter.position = B.cell(P.ABRI.x, P.ABRI.y)
	entities.add_child(shelter)
	for p: Array in [["caisses", 17.6, 57.9, false], ["tonneau", 24.6, 57.8, true], ["cordage", 18.6, 58.6, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# The frozen lake: snowy rocks on its shore, a boulder frozen in its ice.
	for p: Array in [["rocher_neige", 30.6, 84.2, false], ["rocher_neige", 49.4, 88.6, true], ["buisson_givre", 33.0, 82.0, true],
			["buisson_givre", 46.6, 81.6, false], ["rocher_neige", 43.2, 87.4, false]]:
		_put(entities, p[0], "", _open_near(root, Vector2(p[1], p[2])) / B.TILE, p[3])
	# The glacier: séracs and ice crystals along its bands (not in front of the walls).
	for p: Array in [["bloc_glace", "rocher_neige", 44.4, 38.6, false], ["bloc_glace", "rocher_neige", 72.6, 33.4, true],
			["cristaux_glace", "", 50.2, 20.4, false], ["bloc_glace", "rocher_neige", 81.4, 20.0, true],
			["cristaux_glace", "", 86.4, 21.8, false], ["bloc_glace", "rocher_neige", 48.6, 11.4, true],
			["cristaux_glace", "", 76.0, 10.6, true], ["bloc_glace", "rocher_neige", 58.8, 40.4, false]]:
		_put(entities, p[0], p[1], Vector2(p[2], p[3]), p[4])
	# The caves' mouth, dark at the back of its notch in the peaks' face; icicles hanging over it.
	var mouth := CaveMouth.new()
	mouth.name = "EntreeGrottes"
	mouth.width = 1.8
	mouth.height = 2.0
	mouth.position = B.cell(P.ENTREE_GROTTES.x, P.ENTREE_GROTTES.y)
	entities.add_child(mouth)
	for p: Array in [["cristaux_glace", "", 63.2, 8.8, false], ["cristaux_glace", "", 69.0, 8.6, true]]:
		_put(entities, p[0], p[1], Vector2(p[2], p[3]), p[4])
	# The col: boulders fallen from the peaks, pines bent by the storms.
	for p: Array in [["rocher_neige", 98.6, 22.4, false], ["pin_tordu", 123.0, 20.4, true], ["rocher_neige", 116.8, 29.6, true],
			["pin_tordu", 96.8, 12.2, false], ["rocher_neige", 124.2, 36.4, false], ["pin_tordu", 110.2, 40.8, true]]:
		_put(entities, p[0], "", _open_near(root, Vector2(p[1], p[2])) / B.TILE, p[3])


## The story's places and people (story/monts*.gd).
static func _story(root: Region, entities: Node2D) -> void:
	# Hélène's pages: 28 on the col, 29 among the séracs of the glacier's middle band, 30 on the
	# valley's rise. (26: the ice caves; 27: the sanctuary.)
	for p: Array in [[28, P.PAGE_28], [29, P.PAGE_29], [30, P.PAGE_30]]:
		var page = B.prop(entities, "ambre", B.cell(p[1].x, p[1].y), false, load(PICKUP))
		page.name = "Page%d" % p[0]
		page.taken_flag = StringName("found_journal_%d" % p[0])
		page.dialogue_id = StringName("page_%d" % p[0])
		if p[0] == 30:
			page.show_flag = &"forges_vues"   # (it shows the first night in the valley: Monts.night, the forges' glow)
	# The glacier's ice walls (Charge), each across the one bridge over its crevasse.
	for i in P.MURS_GLACE.size():
		var at: Vector2 = P.MURS_GLACE[i]
		var wall = B.prop(entities, _kind(["mur_glace", 0.0, "rocher_neige"]), B.cell(at.x, at.y), false, load(OBSTACLE))
		wall.name = "MurGlace%d" % (i + 1)
		wall.ability = &"charge"
		wall.cleared_flag = StringName("mur_glace_%d_brise" % (i + 1))
		wall.blocked_dialogue = &"mur_glace_bloque"
		wall.debris_color = Color(0.82, 0.92, 1.0)
	# The frost door of the sanctuary at the back of its notch (gone once the Cœurs have melted it).
	var door = B.prop(entities, _kind(["porte_givre", 0.0, "porte_vents"]), B.cell(P.PORTE_GIVRE.x, P.PORTE_GIVRE.y), false, load(STORY_PROP))
	door.name = "PorteGivre"
	door.event = &"porte_givre"
	door.hide_flag = &"sanctuaire_givre_ouvert"
	# Behind it, the way into the sanctuary: a dark passage at the back of the notch (its back face,
	# row 7), hidden by the door until it melts (like the temple's, tools/zones/marais.gd).
	var way_in := CaveMouth.new()
	way_in.name = "EntreeSanctuaire"
	way_in.width = 2.4
	way_in.height = 3.0
	way_in.position = B.cell(P.PORTE_GIVRE.x, 7.0)
	entities.add_child(way_in)
	B.npc(root, "Bertille", "Bertille", _first(BERTILLE_SHEETS), P.BERTILLE.x, P.BERTILLE.y, {"facing": "down", "event": &"bertille"})
	# Grelot, her smallest: at the foot of the first ice wall (too small for it), then home.
	B.dino_npc(root, "Grelot", &"pachyrhinosaurus", P.GRELOT.x, P.GRELOT.y, {"event": &"grelot", "level": 5, "hide_flag": &"grelot_rentre"})
	B.dino_npc(root, "GrelotVallee", &"pachyrhinosaurus", P.GRELOT_VALLEE.x, P.GRELOT_VALLEE.y, {"event": &"grelot", "level": 5,
		"show_flag": &"grelot_rentre", "flip": true})
	# Maïa back on the col once the fourth Cœur is found, Caillou beside her, in her own coat
	# (29/09, demande de l'utilisateur : le vêtement chaud des régions froides) once drawn.
	var maia_drawn := ResourceLoader.exists(CHARS % "maia_manteau")
	B.npc(root, "MaiaMonts", "Maïa", CHARS % ("maia_manteau" if maia_drawn else "maia"), P.MAIA_RETOUR.x, P.MAIA_RETOUR.y, {"facing": "down", "event": &"maia_monts",
		"show_flag": &"coeur_4"})
	B.dino_npc(root, "CaillouMonts", &"triceratops", P.MAIA_RETOUR.x + 1.6, P.MAIA_RETOUR.y + 0.3, {"size": 0.95, "show_flag": &"coeur_4"})
	B.trigger(root, P.GLACIER.x, P.GLACIER.y, 3.5, &"glacier_arrivee", {"once_flag": &"glacier_arrivee", "name": "DeclencheurGlacier"})
	B.trigger(root, 97.5, 37.5, 3.0, &"blizzard_col", {"required_flag": &"suie_monts_battue", "once_flag": &"blizzard_col",
		"name": "DeclencheurCol"})
	B.sign(entities, _open_near(root, Vector2(8.6, 27.4)), &"panneau_monts_entree")
	B.sign(entities, _open_near(root, Vector2(27.6, 50.6)), &"panneau_vallee", true)
	B.sign(entities, _open_near(root, Vector2(29.4, 34.8)), &"panneau_glacier")
	B.sign(entities, _open_near(root, Vector2(96.6, 35.4)), &"panneau_col", true)


## Campfires to rest by (see Rest), the ground around them cleared: by the way in, Bertille's,
## the lake's south shore, the tundra, the col's top.
static func _rest_spots(root: Region, entities: Node2D) -> void:
	for p: Array in [["feu_camp", 14.5, 36.5], ["feu_camp", P.FEU_BERTILLE.x, P.FEU_BERTILLE.y], ["feu_camp", 44.5, 93.5],
			["feu_camp", 87.5, 70.5], ["feu_camp", 118.5, 24.5]]:
		var at := B.flat_spot(root, Vector2(p[1], p[2]), 1)
		for c in entities.get_children():
			if c.get_script() == Prop and c.position.distance_to(at) < 2.0 * B.TILE:
				c.free()
		B.prop(entities, p[0], at)


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.ENTREE_COTE.x + 1.5, P.ENTREE_COTE.y)
	# West: the way back to the Côte (its east exit, x 127.45, rows 56-60: Côte row = Monts row + 28).
	B.spawn(root, P.SPAWN_COTE, P.ENTREE_COTE.x, P.ENTREE_COTE.y)
	B.exit(root, Rect2(0.0, 28.0, 0.55, 4.0), &"cote", &"DepuisMonts")
	# The ice caves: their way in at the back of the notch; Chloé comes back out in front of it.
	B.spawn(root, P.SPAWN_GROTTES, P.ENTREE_GROTTES.x, P.ENTREE_GROTTES.y + 2.6)
	B.exit(root, Rect2(P.ENTREE_GROTTES.x - 0.8, P.ENTREE_GROTTES.y - 0.05, 1.6, 0.5), &"grottes_glace", P.SPAWN_GROTTES_DEPUIS_MONTS)
	# The sanctuary: its way in just before the door (walking up to the shut door says why it is
	# shut); Chloé comes back out on the col, room before the door for the scenes.
	B.spawn(root, P.SPAWN_SANCTUAIRE, P.PORTE_GIVRE.x, P.PORTE_GIVRE.y + 3.8)
	B.exit(root, Rect2(P.PORTE_GIVRE.x - 1.4, P.PORTE_GIVRE.y - 0.05, 2.8, 0.5), &"sanctuaire_givre",
		P.SPAWN_SANCTUAIRE_DEPUIS_MONTS, &"sanctuaire_givre_ouvert", &"porte_givre_fermee")
	# North: the Cieux Éternels, up the gully (to come: « il faudrait voler »).
	B.spawn(root, "DepuisCieux", P.SORTIE_CIEUX.x, P.SORTIE_CIEUX.y + 2.0)
	B.exit(root, Rect2(P.SORTIE_CIEUX.x - 1.5, 0.0, 3.0, 0.55), &"cieux", &"DepuisMonts", &"cieux_ouverts", &"cieux_bloques")


static func _habitats(root: Region) -> void:
	# The widest first (where they overlap, the last one listed wins). Levels climb towards the col.
	var storms := {"weather": [&"snow", &"blizzard"]}
	B.habitat(root, "L'Entrée des Monts", Rect2(0, 0, 36, 44), _known([
		[&"pachyrhinosaurus", 33, 34, 6, "jour", true], [&"edmontosaurus", 33, 34, 6, "jour", false],
		[&"edmontosaurus", 33, 34, 4, "toujours", true],
	]), 1)
	B.habitat(root, "La Vallée des Troupeaux", Rect2(0, 44, 60, 66), _known([
		[&"pachyrhinosaurus", 33, 35, 10, "jour", false], [&"edmontosaurus", 33, 35, 8, "jour", false],
		[&"pachyrhinosaurus", 33, 35, 6, "toujours", true], [&"edmontosaurus", 33, 35, 6, "jour", true],
	]), 4)
	B.habitat(root, "La Toundra", Rect2(60, 46, 70, 64), _known([
		[&"edmontosaurus", 34, 36, 10, "jour", false], [&"pachyrhinosaurus", 34, 36, 8, "jour", false],
		[&"edmontosaurus", 34, 36, 6, "toujours", true], [&"pachyrhinosaurus", 34, 36, 5, "jour", true],
	]), 3)
	B.habitat(root, "Le Glacier", Rect2(34, 5, 60, 45), _known([
		[&"leaellynasaura", 35, 37, 10, "nuit", true], [&"leaellynasaura", 35, 37, 4, "aube et crépuscule", true],
		[&"pachyrhinosaurus", 35, 36, 4, "jour", true],
	]), 0)
	B.habitat(root, "Le Col des Tempêtes", Rect2(94, 8, 36, 40), _known([
		[&"nanuqsaurus", 38, 40, 4, "toujours", false, storms], [&"nanuqsaurus", 38, 40, 3, "toujours", true, storms],
		[&"leaellynasaura", 37, 39, 6, "nuit", true], [&"pachyrhinosaurus", 37, 39, 6, "jour", true],
	]), 1)
	# Calm places (no dinos; their names on the map): Bertille's shelter, the frozen lake, the
	# frost door, the gully.
	B.habitat(root, "L'Abri de Bertille", Rect2(14, 50, 14, 13), [], 0)
	B.habitat(root, "Le Lac gelé", Rect2(30, 80, 20, 12), [], 0)
	B.habitat(root, "La Porte de Givre", Rect2(106, 5, 17, 9), [], 0)
	B.habitat(root, "Le Couloir des Cieux", Rect2(97, 0, 7, 9), [], 0)


## The rows of the species the game knows already (the Monts' own species come with their
## pictures: the zone is built again once they are all there).
static func _known(rows: Array) -> Array:
	return rows.filter(func(r: Array) -> bool: return SpeciesDB.PATHS.has(r[0]))
