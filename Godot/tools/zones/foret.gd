extends RefCounted
## Forêt Jurassique — the whole region in one open map (130 x 100 tiles), drawn from
## tools/maps/foret_sols.png and foret_relief.png (made by gen-foret.mjs, retouchable).
## East: the Lisière, the way in from the Plaines, the Mare de lune (page 10, full moon);
## centre: the Sous-bois, its stream and the Mare aux libellules (page 7); north: the Clairière
## (page 9), the Clairière aux fougères géantes (the Alpha's, chapter 2 part 2), the rocky
## clearings; south: the Haute futaie on its plateau (page 8), the Masque's footbridge over its
## trail; west: the Cœur de la forêt, the rock face of the poachers' camp (the cracked wall,
## Coup de crâne, the tunnel to camp_ombre), the hidden ravine of Griffe-Grise; north-west:
## the bridge to the Marais over a marshy pond, Maïa's second challenge.
## The new scenery (fougere_geante, tronc_mousse…) is used once world/prop.gd knows it:
## rebuild the zone then (the same tiles get it, in place of what stands there meanwhile).

const PATH := "res://regions/foret/foret.tscn"
const B := preload("res://tools/zone_builder.gd")
const BORDERS := preload("res://tools/zones/borders.gd")
const MAPS := "res://tools/maps/foret_%s.png"
const PICKUP := "res://world/pickup.gd"
const MOON_PAGE := "res://regions/foret/moon_page.gd"
const STORY_PROP := "res://world/story_prop.gd"
const OBSTACLE := "res://world/obstacle.gd"
const CHARS := "res://assets/art/characters/%s.png"
const MUSIC := "res://assets/audio/music/foret.ogg"
const MUSIC_FALLBACK := "res://assets/audio/music/plaines.ogg"
const GROUND := "res://assets/art/ground/sous_bois.png"
const BACKDROP := "res://assets/art/battle/foret.jpg"
const ENTRANCE := Vector2i(126, 52)
## What grows on the open ground (see _table): [kind, chance per tile, stand-in while the kind
## is not drawn yet ("" = nothing)]. The first row that wins the roll is placed.
## (29/09: a few rows of the Plaines' flowers became the jungle's own plants, cycads, ginkgos and
## horsetails, same chances: the rest of the forest stays where it was.)
const SOUS_BOIS := [
	["fougeres", 0.1], ["fougere_geante", 0.012, "fougere_arbre"], ["fougere_arbre", 0.02], ["araucaria", 0.009],
	["buisson", 0.009], ["champignons", 0.012, ""], ["tronc_mousse", 0.004, "tronc"], ["souche", 0.004],
	["rocher_mousse", 0.004, "rocher"], ["cailloux", 0.005], ["ronces", 0.004], ["cycas", 0.005, "fleurs_violettes"],
	["arbre_rond", 0.004], ["souche_geante", 0.0012, ""],
]
const LISIERE := [
	["fleurs_roses", 0.02], ["fleurs_violettes", 0.014], ["fougeres", 0.05], ["buisson", 0.012], ["arbre_rond", 0.008],
	["araucaria", 0.006], ["fougere_arbre", 0.008], ["cailloux", 0.005], ["souche", 0.003], ["champignons", 0.005, ""],
]
const FUTAIE := [
	["fougeres", 0.08], ["araucaria", 0.018], ["fougere_arbre", 0.014],
	["fougere_geante", 0.01, "fougere_arbre"], ["tronc_mousse", 0.005, "tronc"], ["champignons", 0.012, ""],
	["buisson", 0.006], ["souche_geante", 0.002, "souche"], ["cailloux", 0.004],
]
const ROCHES := [
	["cailloux", 0.02], ["rocher", 0.008], ["rocher_mousse", 0.008, "rocher"], ["fougeres", 0.035], ["buisson", 0.008],
	["araucaria", 0.005], ["os_dino", 0.002, ""], ["ginkgo", 0.006, "fleurs_violettes"],
]
## Up on the rock nobody reaches, and in and over the ravine (the camera looks into it from
## the south): low things only.
const ROC := [["cailloux", 0.012], ["buisson", 0.012], ["fougeres", 0.03], ["rocher", 0.004]]
## Just south of a trail, the water or a place (the camera looks north, 40° down: anything
## taller than Chloé there would hide them): the undergrowth, nothing tall.
const LOW := [
	["fougeres", 0.11], ["champignons", 0.014, ""], ["fleurs_violettes", 0.008], ["buisson", 0.006], ["cailloux", 0.006],
	["souche", 0.003], ["ronces", 0.003], ["prele", 0.004, "fleurs_roses"],
]
## How far south of what must be seen (tiles) nothing tall stands (as gen-foret.mjs's SHADOW).
const VIEW_SHADOW := 5
## The giant trees (arbre_geant, 12 m): landmarks at the back of the open places. They hide
## this far north of them (tiles), so they only stand where nothing is to be seen there.
const GIANT_TREES := [Vector2(40, 13.5), Vector2(123, 76), Vector2(116, 10), Vector2(28, 5.5), Vector2(50, 6.5), Vector2(126, 88)]
const GIANT_SHADOW := 16
## Where nothing is scattered (tiles): around the places, so they stay readable.
const KEEP_CLEAR := [
	Rect2(119, 49, 11, 6), Rect2(115.5, 38, 5, 4.5), Rect2(66, 50.5, 4.5, 3.5), Rect2(67.5, 80, 5.5, 4.5),
	Rect2(43.5, 22, 5.5, 4.5), Rect2(15, 11, 18, 14), Rect2(16, 75, 12, 9), Rect2(10.5, 41, 8, 10),
	Rect2(0, 7, 11, 10), Rect2(55, 23, 9, 6), Rect2(38, 53, 8, 6), Rect2(59, 52, 6, 6),
	Rect2(78, 61, 6, 9), Rect2(41, 74, 9, 5.5), Rect2(106, 82, 8, 5.5), Rect2(28, 60, 6, 8),
	# The notch of the camp's wall and the bay before it; the Masque's rock and footbridge.
	Rect2(9.5, 37, 6, 5), Rect2(51, 71, 11, 6.5),
]
## The footbridges over the stream (tiles: where the trails cross it; gen-foret.mjs prints them).
const BRIDGES := [Rect2(57, 25, 5, 2), Rect2(40, 55, 4, 2)]
## The bridge to the Marais, over the marshy pond by the west border (also printed there).
const MARAIS_BRIDGE := Rect2(1, 11, 5, 2)
## The camp's wall (Coup de crâne) in the notch at the back of the bay, the tunnel's dark mouth
## behind it (tiles). The notch is x 11-12, y 39-40 (gen-foret.mjs CAMP_NOTCH).
const CAMP_WALL := Vector2(12.0, 40.6)
const CAMP_MOUTH := Vector2(12.0, 39.0)
## The Masque's rock up on the Haute futaie (gen-foret.mjs maskRockAt: a shelf 1.4 m over the
## plateau, its straight face at y = 75, just north of the futaie's trail): the footbridge hangs
## at its foot; the two giant trees stand on the shelf behind, where the picture's trunks are
## (2.65 m either side); he stands on the lip between them, just behind the footbridge, his feet
## as high as its deck, in front of the trees. The circle on the trail below, where he is seen:
## close to it, or he would be at the top of the screen (tiles).
const MASQUE_AT := Vector2(56.5, 74.75)
const MASQUE_WALKWAY := Vector2(56.5, 75.2)
const MASQUE_TREES := [Vector2(53.85, 73.3), Vector2(59.15, 73.3)]
const MASQUE_TRIGGER := Vector2(56.5, 77.0)
const MASQUE_RADIUS := 2.5


static func build() -> Region:
	var root := B.region_from_maps(&"foret", "Forêt Jurassique", "", Vector2i(10, 18),
		MAPS % "sols", MAPS % "relief", "res://regions/foret/foret_relief.res")
	root.music = load(MUSIC if ResourceLoader.exists(MUSIC) else MUSIC_FALLBACK)
	root.ambience_id = &"foret"
	if ResourceLoader.exists(GROUND):
		root.ground_tex = load(GROUND)
	if ResourceLoader.exists(BACKDROP):
		root.battle_backdrop = load(BACKDROP)
	# Rain comes often under the canopy, mist at dawn; storms now and then.
	root.rain_chance = 0.35
	root.mist_chance = 0.15
	root.storm_chance = 0.04
	var entities: Node2D = root.get_node("Entities")
	_bridges(root)
	_scatter(root, entities)
	_landmarks(entities)
	_story(root, entities)
	_rest_spots(root, entities)
	# 30 amber pebbles: 10 in trees, 8 under stones, 6 buried (Flair), 6 in nooks worth the walk.
	B.hide_pebbles(root, entities, ENTRANCE, 4417, 10, 8,
		[Vector2(75, 45), Vector2(93, 62), Vector2(34, 40), Vector2(62, 90), Vector2(111, 47), Vector2(20, 58)],
		[Vector2(95, 91), Vector2(24, 83), Vector2(104, 16), Vector2(6, 22), Vector2(125, 63), Vector2(52, 93)])
	# The joins (tools/zones/borders.gd; last: nothing placed before moves): the Plaines' grass and
	# flowers thinning out into the undergrowth by the east edge, the Marais' mud and reeds by the
	# west edge.
	var meadow := BORDERS.cover(root, "plaines", "herbe", "terre", "res://regions/foret")
	BORDERS.plants(root, entities, meadow, ["fleurs_roses", "fleurs_violettes", "fleurs_violettes", "hautes_herbes"], 0.3, 4471, KEEP_CLEAR)
	var marsh := BORDERS.cover(root, "marais", "vase", "", "res://regions/foret")
	BORDERS.plants(root, entities, marsh, ["roseaux", "roseaux", "hautes_herbes", "prele"], 0.3, 4473, KEEP_CLEAR)
	_places(root)
	_habitats(root)
	return root


## Planks over the stream where the trails cross it, and the bridge to the Marais over the
## pond (their cells are painted as path).
static func _bridges(root: Region) -> void:
	var terrain: TileMapLayer = root.get_node("Terrain")
	var all: Array = BRIDGES + [MARAIS_BRIDGE]
	for i in all.size():
		var r: Rect2 = all[i]
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var data := terrain.get_cell_tile_data(Vector2i(x, y))
				if data == null or String(data.get_custom_data("terrain")) != "path":
					push_warning("Passerelle %d : la case (%d, %d) n'est pas un sentier" % [i, x, y])
		var d := B.dock(root, r)
		d.name = "PontMarais" if r == MARAIS_BRIDGE else "Passerelle%d" % (i + 1)


## A kind of scenery from a table row, or its stand-in while it is not drawn yet ("" = none).
static func _kind(row: Array) -> String:
	if Prop.KINDS.has(row[0]):
		return row[0]
	var stand_in: String = row[2] if row.size() > 2 else ""
	return stand_in if Prop.KINDS.has(stand_in) else ""


## What grows on tile `c`, by the part of the forest it is in.
static func _table(root: Region, c: Vector2i) -> Array:
	var h := root.tile_height(c)
	if c.x >= 12 and c.x <= 36 and c.y >= 64:
		return ROC
	if c.y >= 64 and c.x >= 44 and h >= 2.0 and h < 3.2:
		return FUTAIE
	if h > 1.3:
		return ROC
	if c.x >= 106:
		return LISIERE
	if c.x >= 78 and c.y <= 38:
		return ROCHES
	return SOUS_BOIS


static func _scatter(root: Region, entities: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1807
	var terrain: TileMapLayer = root.get_node("Terrain")
	var size := terrain.get_used_rect().end
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			var data := terrain.get_cell_tile_data(c)
			if data == null or String(data.get_custom_data("terrain")) != "grass":
				continue
			var middle := Vector2(x + 0.5, y + 0.5)
			if KEEP_CLEAR.any(func(r: Rect2) -> bool: return r.has_point(middle)):
				continue
			if _near_way(terrain, c) or not _steady(root, c):
				continue
			for row: Array in LOW if _in_view(terrain, c) else _table(root, c):
				if rng.randf() < row[1]:
					var kind := _kind(row)
					if kind != "":
						B.prop(entities, kind, B.cell(x + rng.randf_range(0.2, 0.8), y + rng.randf_range(0.3, 0.9)), rng.randf() < 0.5)
					break


## Something that must be seen (a trail, water, a place kept clear) just north of tile `c`.
static func _in_view(terrain: TileMapLayer, c: Vector2i) -> bool:
	for k in range(1, VIEW_SHADOW + 1):
		for dx in range(-2, 3):
			var n := c + Vector2i(dx, -k)
			var d := terrain.get_cell_tile_data(n)
			if d and String(d.get_custom_data("terrain")) in ["path", "water"]:
				return true
			var middle := Vector2(n) + Vector2(0.5, 0.5)
			if KEEP_CLEAR.any(func(r: Rect2) -> bool: return r.has_point(middle)):
				return true
	return false


## A trail or water on tile `c` or around it.
static func _near_way(terrain: TileMapLayer, c: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var d := terrain.get_cell_tile_data(c + Vector2i(dx, dy))
			if d and String(d.get_custom_data("terrain")) in ["path", "water"]:
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


## Scenery placed by hand: the giant ferns of the Alpha's clearing, ferns hiding page 7, the
## tree ferns by the ponds, the landmarks (giant trees, bones) once they are drawn.
static func _landmarks(entities: Node2D) -> void:
	# (Tall ones on the north half of the ring, ferns on the south half: the camera looks north.)
	var giant_fern := _kind(["fougere_geante", 0.0, "fougere_arbre"])
	for i in 14:
		var a := TAU * i / 14.0 + 0.2
		var r := 8.0 + 0.8 * sin(i * 2.7)
		var at := Vector2(24.0 + cos(a) * r * 1.05, 18.4 + sin(a) * r * 0.72)
		B.prop(entities, giant_fern if at.y < 19.5 else "fougeres", _open_near(entities.get_parent(), at), i % 2 == 0)
	for p: Array in [["fougeres", 66.6, 51.6], ["fougeres", 69.6, 51.4], ["fougeres", 67.4, 53.6], ["fougeres", 69.3, 53.4],
			["fougere_arbre", 66.2, 50.9], ["fougeres", 70.4, 52.6], ["champignons", 67.0, 52.9],
			["fougere_arbre", 50.2, 41.6], ["fougere_arbre", 59.6, 42.2], ["fougeres", 58.8, 46.9], ["fougeres", 49.4, 46.4],
			["fougere_arbre", 33.2, 58.9], ["fougeres", 42.6, 63.2], ["fougeres", 35.0, 64.1],
			["fleurs_violettes", 116.4, 41.4], ["fleurs_roses", 119.8, 41.8], ["fleurs_violettes", 121.0, 40.6],
			["fleurs_roses", 43.6, 21.4], ["fleurs_violettes", 48.4, 22.2], ["fleurs_roses", 47.2, 25.6],
			["rocher", 19.2, 76.8], ["cailloux", 25.6, 82.6], ["fougeres", 18.0, 81.6], ["fougeres", 26.4, 78.4],
			["os_dino", 19.4, 79.0], ["os_dino", 98.6, 30.2], ["os_dino", 88.4, 19.6],
			["souche_geante", 29.6, 59.2], ["souche_geante", 86.4, 90.2],
			["tronc_mousse", 64.6, 47.6], ["tronc_mousse", 101.4, 60.8]]:
		var kind := _kind([p[0], 0.0, ""])
		if kind != "":
			B.prop(entities, kind, _open_near(entities.get_parent(), Vector2(p[1], p[2])), int(p[1] * 10.0) % 2 == 0)
	# The giant trees, a dozen metres tall: only where nothing to see lies behind them.
	if not Prop.KINDS.has("arbre_geant"):
		return
	var terrain: TileMapLayer = entities.get_parent().get_node("Terrain")
	for t: Vector2 in GIANT_TREES:
		var at := _open_near(entities.get_parent(), t)
		if _hides_nothing(terrain, Vector2i((at / B.TILE).floor())):
			B.prop(entities, "arbre_geant", at, int(t.x) % 2 == 0)
		else:
			push_warning("Arbre géant en %s : il cacherait un sentier ou un lieu, pas posé." % t)


## Nothing to see (trail, water, place kept clear) in the band a giant tree at tile `c` hides:
## GIANT_SHADOW tiles north of it, as wide as its crown.
static func _hides_nothing(terrain: TileMapLayer, c: Vector2i) -> bool:
	for k in range(0, GIANT_SHADOW + 1):
		for dx in range(-4, 5):
			var n := c + Vector2i(dx, -k)
			var d := terrain.get_cell_tile_data(n)
			if d and String(d.get_custom_data("terrain")) in ["path", "water"]:
				return false
			var middle := Vector2(n) + Vector2(0.5, 0.5)
			if KEEP_CLEAR.any(func(r: Rect2) -> bool: return r.has_point(middle)):
				return false
	return true


## World position of tile point `t`, moved to the nearest open ground that is level all round
## (the map may have been retouched under it: not in the water, the trees, over a drop).
static func _open_near(root: Region, t: Vector2) -> Vector2:
	var terrain: TileMapLayer = root.get_node("Terrain")
	for r in 4:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := Vector2i(t.floor()) + Vector2i(dx, dy)
				var data := terrain.get_cell_tile_data(c)
				if data and String(data.get_custom_data("terrain")) in ["grass", "tall_grass"] and _steady(root, c):
					return B.cell(t.x + dx, t.y + dy)
	return B.cell(t.x, t.y)


## The story's places and people.
static func _story(root: Region, entities: Node2D) -> void:
	# Hélène's pages: 7 in the ferns of the Sous-bois, 8 up on the Haute futaie, 9 in the
	# Clairière, 10 by the Mare de lune — there only on full-moon nights (moon_page.gd).
	for p: Array in [[7, 68.5, 52.6, PICKUP], [8, 70.5, 82.6, PICKUP], [9, 46.5, 24.6, PICKUP], [10, 118.5, 40.6, MOON_PAGE]]:
		var page = B.prop(entities, "ambre", B.cell(p[1], p[2]), false, load(p[3]))
		page.name = "Page%d" % p[0]
		page.taken_flag = StringName("found_journal_%d" % p[0])
		page.dialogue_id = StringName("page_%d" % p[0])
	# Griffe-Grise, Hélène's old Velociraptor, in his hidden ravine.
	B.dino_npc(root, "GriffeGrise", &"griffe_grise", 22.0, 80.0, {"event": &"griffe_grise", "size": 1.1, "flip": true})
	# The clearing of the giant ferns, empty (the Alpha is gone): old broken posts.
	var posts = B.prop(entities, "cloture", B.cell(24.0, 18.6), false, load(STORY_PROP))
	posts.name = "ClairiereVide"
	posts.event = &"clairiere_vide"
	for p: Array in [[21.2, 17.2, false], [27.0, 19.8, true]]:
		B.prop(entities, "cloture", B.cell(p[0], p[1]), p[2])
	# (29/09) « Au milieu, elles sont couchées, écrasées… Tout autour, un anneau de pieux plantés
	# dans la terre, reliés par des cordes coupées »: the ring of cut stakes, the flattened ferns.
	if Prop.KINDS.has("pieu_corde"):
		for i in 8:
			var a := TAU * i / 8.0 + 0.35
			B.prop(entities, "pieu_corde", B.cell(24.0 + cos(a) * 3.4, 18.4 + sin(a) * 2.4), i % 2 == 1)
	if Prop.KINDS.has("fougeres_ecrasees"):
		for p: Array in [[22.8, 17.6, false], [25.3, 18.1, true], [24.2, 16.4, false]]:
			B.prop(entities, "fougeres_ecrasees", B.cell(p[0], p[1]), p[2])
	# « Au-dessus de sa couche, quelqu'un a gravé un nom dans la roche, avec une petite fougère »
	if Prop.KINDS.has("pierre_gravee"):
		B.prop(entities, "pierre_gravee", B.cell(23.8, 78.4))
	B.sign(entities, B.cell(121.6, 49.6), &"panneau_lisiere")
	B.sign(entities, B.cell(33.4, 65.2), &"panneau_ravin", true)
	B.sign(entities, B.cell(83.4, 63.4), &"panneau_futaie")
	_camp_wall(entities)
	_masque(root, entities)
	_marais_bridge(root, entities)


## The poachers' camp (zone camp_ombre, story/foret_camp.gd): the cracked wall (Coup de crâne)
## in the notch at the back of the bay, the tunnel's dark mouth behind it, a sign.
static func _camp_wall(entities: Node2D) -> void:
	var mouth := CaveMouth.new()
	mouth.name = "TunnelCamp"
	mouth.width = 1.8
	mouth.position = B.cell(CAMP_MOUTH.x, CAMP_MOUTH.y)
	entities.add_child(mouth)
	# (A boulder stands in for the cracked wall until world/prop.gd knows it.)
	var wall = B.prop(entities, _kind(["mur_fissure", 0.0, "rocher"]), B.cell(CAMP_WALL.x, CAMP_WALL.y), false, load(OBSTACLE))
	wall.name = "MurFissure"
	wall.ability = &"coup_crane"
	wall.cleared_flag = &"mur_camp_brise"
	wall.blocked_dialogue = &"mur_fissure_bloque"
	wall.debris_color = Color(0.52, 0.5, 0.47)
	B.sign(entities, B.cell(14.3, 41.7), &"panneau_camp", true)


## The Masque d'Obsidienne, seen once after the Sceau: on the footbridge between two giant trees
## of the Haute futaie, over its trail (the trees hide nothing but the plateau's edge north of
## his rock). He shows once the scene sets masque_en_vue; the circle on the trail below starts
## the scene (story/foret_fin.gd).
static func _masque(root: Region, entities: Node2D) -> void:
	if Prop.KINDS.has("arbre_geant"):
		for t: Vector2 in MASQUE_TREES:
			B.prop(entities, "arbre_geant", B.cell(t.x, t.y), t.x > MASQUE_AT.x)
	var walkway := _kind(["passerelle", 0.0, ""])
	if walkway != "":
		var w = B.prop(entities, walkway, B.cell(MASQUE_WALKWAY.x, MASQUE_WALKWAY.y))
		w.name = "PasserelleMasque"
	var drawn := ResourceLoader.exists(CHARS % "masque")
	B.npc(root, "Masque", "Le Masque", CHARS % ("masque" if drawn else "sbire"), MASQUE_AT.x, MASQUE_AT.y, {
		"facing": "down", "show_flag": &"masque_en_vue", "hide_flag": &"masque_vu",
		"tint": Color.WHITE if drawn else Color(0.3, 0.26, 0.4)})
	_trigger(root, MASQUE_TRIGGER, MASQUE_RADIUS, &"masque_passerelle", {"required_flag": &"sceau_foret", "once_flag": &"masque_vu"})


## The bridge to the Marais (its planks: _bridges): Maïa waits by it after the Sceau for her
## second challenge; the way over opens once she is beaten (see _places).
static func _marais_bridge(root: Region, entities: Node2D) -> void:
	B.npc(root, "MaiaPont", "Maïa", CHARS % "maia", 6.0, 12.0, {"facing": "right", "event": &"maia_defi_2",
		"show_flag": &"sceau_foret", "hide_flag": &"maia_defi_2"})
	B.sign(entities, B.cell(7.6, 10.5), &"panneau_pont")


## A StoryTrigger (ZoneBuilder.trigger), called by name: the plan still builds while that
## helper is missing (it then only warns).
static func _trigger(root: Region, at: Vector2, radius: float, event: StringName, opts: Dictionary) -> void:
	var builder: Script = load("res://tools/zone_builder.gd")
	if not builder.get_script_method_list().any(func(m: Dictionary) -> bool: return m["name"] == "trigger"):
		push_warning("ZoneBuilder.trigger n'existe pas encore : pas de déclencheur « %s »." % event)
		return
	builder.call(&"trigger", root, at.x, at.y, radius, event, opts)


## Campfires and a bench to rest by (see Rest), the ground around them cleared.
static func _rest_spots(root: Region, entities: Node2D) -> void:
	for p: Array in [["feu_camp", 117.5, 57.0], ["feu_camp", 50.5, 21.5], ["feu_camp", 75.5, 84.5],
			["feu_camp", 27.5, 55.5], ["feu_camp", 93.5, 20.5], ["banc", 58.5, 47.5]]:
		# On flat ground, two tiles round (not in the water, not on a cliff's edge).
		var at := B.flat_spot(root, Vector2(p[1], p[2]), 2)
		for c in entities.get_children():
			if c.get_script() == Prop and c.position.distance_to(at) < 2.6 * B.TILE:
				c.free()
		B.prop(entities, p[0], at)


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", 123.0, 52.0)
	B.spawn(root, "DepuisPlaines", 126.0, 52.0)
	B.exit(root, Rect2(129.45, 50.0, 0.55, 4.0), &"plaines", &"DepuisForet")
	# The tunnel to the camp, at the back of the notch (the wall stands in front of it; the
	# flag is only a safety net). Chloé comes back just before the notch.
	B.spawn(root, "DepuisCamp", 12.0, 42.2)
	B.exit(root, Rect2(11.2, 38.95, 1.6, 0.5), &"camp_ombre", &"DepuisForet", &"mur_camp_brise", &"mur_fissure_bloque")
	# Over the bridge, the Marais (zone marais: later), once Maïa's second challenge is won.
	B.spawn(root, "DepuisMarais", 3.0, 12.0)
	B.exit(root, Rect2(0.0, 10.0, 0.55, 4.0), &"marais", &"DepuisForet", &"maia_defi_2", &"pont_marais_bloque")


static func _habitats(root: Region) -> void:
	# The widest first (where they overlap, the last one listed wins). "pluie" is not a time
	# of day: the Allosaurus comes out at night.
	B.habitat(root, "Le Sous-bois", Rect2(40, 28, 70, 40), [
		[&"dilophosaurus", 11, 14, 10, "jour", false], [&"dilophosaurus", 11, 14, 10, "toujours", true],
		[&"deinonychus", 12, 15, 7, "aube et crépuscule", false], [&"deinonychus", 12, 15, 5, "aube et crépuscule", true],
		[&"troodon", 11, 13, 6, "nuit", false], [&"troodon", 11, 13, 6, "nuit", true],
	], 4)
	B.habitat(root, "La Haute Futaie", Rect2(44, 64, 66, 34), [
		[&"microraptor", 14, 17, 10, "jour", false], [&"microraptor", 14, 17, 10, "jour", true],
		[&"dilophosaurus", 14, 16, 5, "toujours", true], [&"anurognathus", 14, 16, 6, "nuit", true],
		[&"anurognathus", 14, 16, 6, "nuit", false],
	], 3)
	# (Brachiosaurus: "aube" alone is not a time of day, "aube et crépuscule" is.)
	B.habitat(root, "La Lisière", Rect2(106, 26, 24, 34), [
		[&"dilophosaurus", 10, 12, 6, "jour", false], [&"compsognathus", 10, 12, 6, "jour et crépuscule", false],
		[&"compsognathus", 10, 12, 10, "toujours", true], [&"dilophosaurus", 10, 12, 6, "jour", true],
		[&"velociraptor", 10, 12, 5, "nuit", true],
	], 2)
	B.habitat(root, "La Prairie des brachiosaures", Rect2(104, 60, 26, 24), [
		[&"brachiosaurus", 10, 12, 3, "aube et crépuscule", false], [&"compsognathus", 10, 12, 6, "toujours", false],
		[&"compsognathus", 10, 12, 10, "toujours", true], [&"dilophosaurus", 10, 12, 4, "jour", true],
	], 2)
	B.habitat(root, "La Clairière", Rect2(34, 14, 26, 18), [
		[&"stegosaurus", 12, 14, 10, "jour", false], [&"stegosaurus", 12, 14, 8, "toujours", true],
		[&"dilophosaurus", 12, 14, 4, "jour", true],
	], 2)
	B.habitat(root, "Les Clairières rocheuses", Rect2(78, 6, 46, 32), [
		[&"pachycephalosaurus", 13, 16, 10, "jour", false], [&"pachycephalosaurus", 13, 16, 8, "jour", true],
		[&"stegosaurus", 13, 15, 4, "jour", true], [&"troodon", 13, 15, 5, "nuit", true],
		[&"anurognathus", 13, 15, 5, "nuit", false],
	], 3)
	B.habitat(root, "Le Cœur de la forêt", Rect2(14, 38, 34, 26), [
		[&"allosaurus", 15, 18, 3, "nuit", false], [&"deinonychus", 15, 17, 8, "aube et crépuscule", false],
		[&"dilophosaurus", 15, 17, 8, "toujours", true], [&"deinonychus", 15, 17, 6, "aube et crépuscule", true],
		[&"allosaurus", 16, 18, 2, "nuit", true],
	], 3)
	# Calm places (no dinos; their names on the map): the Alpha's clearing (chapter 2, part 2)
	# and Griffe-Grise's ravine.
	B.habitat(root, "La Clairière aux fougères géantes", Rect2(14, 10, 20, 16), [], 0)
	B.habitat(root, "Le Ravin", Rect2(12, 62, 24, 36), [], 0)
