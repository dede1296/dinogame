extends RefCounted
## Les Cieux Éternels (chapter 7), the big zone (100 x 86 tiles): pitons above the sea of clouds,
## joined by liana bridges, climbing northwards (painted by tools/zones/cieux_canvas.gd; the decor of
## tools/zones/cieux_decor.gd). The places are named in story/cieux_places.gd (CieuxPlaces).
## South: the Monts' gully comes out onto a ridge over the clouds, then the Piton d'Arrivée
## (10.8 m; the fire in the shelter of a rock). The first liana bridge (the one that sways) leads west
## to the Piton du Guet (11.4 m), the crossroads: west, the Mer de nuages (10.8 m, a big piton whose
## hollow the clouds fill: one walks on them like on a frozen lake, the Tupandactylus there at dawn);
## north, the Vents (12 m) then the Haut (12.6 m) under the Rempart, a mass of rock the carved ramp
## climbs through to the nests (north edge, zone nids_geants). East, a loop: the Vents, the Piton
## Fendu (12 m), the long bridge down to the rhamphorhynchus' piton (11.4 m) and back to the arrival;
## from the Fendu, a bridge and a ramp up to the Belvédère (13.2 m, the highest on foot: page 31, a
## bench). For the Vol only: page 33 on its islet south-west of the Mer, a needle with a nest (a
## pebble) in the east, a balcony over the clouds (an old chest) in the north-west.
## Every bridge runs straight north-south or east-west (a slanting one breaks into steps of tiles).

const PATH := "res://regions/cieux/cieux.tscn"
const RES_DIR := "res://regions/cieux"
const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/cieux_canvas.gd")
const D := preload("res://tools/zones/cieux_decor.gd")
const F := preload("res://tools/zones/cieux_pieds.gd")
const P := preload("res://story/cieux_places.gd")
const MUSIC := ["res://assets/audio/music/cieux.ogg", "res://assets/audio/music/monts.ogg"]
const BACKDROP := ["res://assets/art/battle/cieux.jpg", "res://assets/art/battle/monts.jpg"]
const W := 100
const H := 86
const SEED := 7731
## The pitons' heights (m): the arrival (the Monts' gully), up to the Belvédère; the top of the
## carved ramp at the north edge (the nests' way in); the Rempart, out of reach.
const H_ARRIVEE := 10.8
const H_GUET := 11.4
const H_VENTS := 12.0
const H_HAUT := 12.6
const H_BELVEDERE := 13.2
const H_SORTIE := 13.8
const H_REMPART := 15.0
## The pitons: [centre, radii, height] (tiles, m).
const ARRIVEE := [Vector2(72.0, 75.0), Vector2(7.0, 5.5), H_ARRIVEE]
const GUET := [Vector2(52.0, 72.0), Vector2(7.0, 5.0), H_GUET]
const MER := [Vector2(26.0, 64.0), Vector2(13.0, 9.0), H_ARRIVEE]
const VENTS := [Vector2(52.0, 50.0), Vector2(8.0, 5.5), H_VENTS]
const HAUT := [Vector2(46.0, 30.0), Vector2(7.0, 5.0), H_HAUT]
const FENDU := [Vector2(79.0, 50.0), Vector2(7.0, 5.0), H_VENTS]
const RHAMPHOS := [Vector2(89.0, 70.0), Vector2(6.0, 4.5), H_GUET]
const BEL_BAS := [Vector2(77.0, 33.0), Vector2(5.0, 4.0), H_HAUT]
const BEL_HAUT := [Vector2(76.0, 21.0), Vector2(4.0, 3.5), H_BELVEDERE]
## The hollow of the Mer de nuages (walkable clouds): its ellipse and its floor (m).
const MER_CREUX := [Vector2(25.0, 63.5), Vector2(9.5, 5.5)]
const MER_FOND := 10.4
## The islets only the Vol reaches: [centre, radii, height].
const ILOTS := [
	[P.ILOT_NUAGES, Vector2(3.2, 3.2), H_GUET], [P.AIGUILLE_AU_NID, Vector2(3.2, 3.2), H_BELVEDERE],
	[P.BALCON_BRUMES, Vector2(3.6, 3.2), H_VENTS],
]
## The liana bridges, straight: [points (from inside one piton to inside the next), from height, to height].
const PONTS := [
	[[Vector2(66.5, 73.0), Vector2(57.5, 73.0)], H_ARRIVEE, H_GUET],     # the first bridge (arrival -> Guet)
	[[Vector2(46.5, 71.0), Vector2(33.5, 71.0)], H_GUET, H_ARRIVEE],     # Guet -> Mer
	[[Vector2(52.0, 68.0), Vector2(52.0, 54.5)], H_GUET, H_VENTS],       # Guet -> Vents
	[[Vector2(49.0, 46.0), Vector2(49.0, 34.5)], H_VENTS, H_HAUT],       # Vents -> Haut
	[[Vector2(59.5, 50.0), Vector2(72.5, 50.0)], H_VENTS, H_VENTS],      # Vents -> Fendu
	[[Vector2(77.5, 72.0), Vector2(84.0, 72.0)], H_ARRIVEE, H_GUET],     # arrival -> rhamphorhynchus
	[[Vector2(85.0, 54.0), Vector2(85.0, 66.5)], H_VENTS, H_GUET],       # Fendu -> rhamphorhynchus (the long bridge)
	[[Vector2(78.0, 45.5), Vector2(78.0, 36.5)], H_VENTS, H_HAUT],       # Fendu -> Belvédère (its lower shelf)
]
## The trails over the pitons (2 tiles wide), joining the bridges' heads and the places.
const SENTIERS := [
	[Vector2(72.5, 79.0), Vector2(72.5, 75.0), Vector2(66.5, 73.0)], [Vector2(72.5, 75.0), Vector2(78.0, 72.0)],
	[Vector2(58.0, 73.0), Vector2(52.0, 72.0), Vector2(46.0, 71.0)], [Vector2(52.0, 72.0), Vector2(52.0, 67.5)],
	[Vector2(34.0, 71.0), Vector2(32.0, 69.0), Vector2(28.5, 66.5)],
	[Vector2(52.0, 55.0), Vector2(52.0, 50.0), Vector2(49.0, 46.0)], [Vector2(52.0, 50.0), Vector2(59.5, 50.0)],
	[Vector2(49.0, 35.0), Vector2(47.0, 30.0), Vector2(46.5, 25.0)],
	[Vector2(72.5, 50.0), Vector2(79.0, 50.0), Vector2(78.0, 45.5)], [Vector2(79.0, 50.0), Vector2(85.0, 54.0)],
	[Vector2(85.0, 66.5), Vector2(89.0, 70.0), Vector2(84.0, 72.0)],
	[Vector2(78.0, 37.0), Vector2(76.5, 33.0), Vector2(76.5, 29.0)], [Vector2(76.5, 24.0), Vector2(76.0, 21.0)],
]
## The ramps: the Belvédère's (its lower shelf to its top), the carved ramp through the Rempart.
const RAMPE_BELVEDERE := Rect2i(75, 24, 3, 6)
const RAMPE_NIDS := Rect2i(45, 6, 3, 19)
## The Rempart (out of reach): its mass, and its edge along the north border (x 38-54: the nests'
## x 26-42 go on beyond it); the carved way through it (x 45-47), level at the edge.
const REMPART := [Vector2(46.0, 9.0), Vector2(13.0, 8.0)]
const REMPART_BORD := Rect2i(38, 0, 17, 4)
const COUPE := Rect2i(45, 0, 3, 6)
## The way in from the Monts at the south edge: their gully opens onto a ridge over the clouds; the
## snow of their gully thins out along it over NEIGE_COULOIR rows (and the snow of the Pitons, towards
## the nests, over NEIGE_NIDS rows).
const COULOIR := Rect2i(71, 80, 3, 6)
const NEIGE_COULOIR := 6
## (The rim of the Monts' peaks along the south edge: all snow at the edge, as theirs, patchy a few
## rows in.)
const NEIGE_BORD := 3
const NEIGE_NIDS := 8
## The join with the Monts all along the south edge: their row 0 is their peaks (12.6 m) from Monts x 34
## (Cieux x 6) on, but for their gully; their woods (4.8 m) west of it. The peaks go on here as a rim of
## snowy rock RIM_DEPTH rows deep (ragged), then drop into the clouds; west of it the clouds sink to
## the woods' height at the edge (no step between the two zones, no straight line along the edge).
const MONTS_PEAKS := 12.6
const MONTS_WOODS := 4.8
const MONTS_PEAKS_FROM := 6
const RIM_DEPTH := Vector2(2.0, 5.0)
const RIM_THIN_NEAR := 9
## Tufts (the rhamphorhynchus hide there): [centre, radii].
const TOUFFES := [
	[Vector2(47.5, 74.5), Vector2(2.5, 1.6)], [Vector2(56.5, 69.5), Vector2(2.0, 1.4)], [Vector2(46.5, 52.0), Vector2(2.5, 1.8)],
	[Vector2(57.0, 52.5), Vector2(2.0, 1.4)], [Vector2(83.0, 52.0), Vector2(2.5, 1.6)], [Vector2(92.5, 72.0), Vector2(2.0, 1.6)],
	[Vector2(41.5, 31.0), Vector2(2.4, 1.8)], [Vector2(50.5, 31.5), Vector2(2.2, 1.6)], [Vector2(36.5, 62.0), Vector2(1.8, 2.5)],
]
## The broken bridges' ends: [tile, flipped] (on the Mer's south-west rim towards page 33's islet,
## on the Haut's west rim towards the balcony).
const PONTS_ROMPUS := [[Vector2(15.8, 68.6), true], [Vector2(39.8, 30.6), true]]
## Level and bare: the arrival's terrace, the Belvédère's, the landing squares.
const PLACES_NETTES := [
	Rect2i(69, 72, 7, 6), Rect2i(74, 19, 5, 5), Rect2i(49, 69, 6, 6), Rect2i(49, 47, 6, 6), Rect2i(43, 27, 6, 6),
	Rect2i(76, 47, 6, 6), Rect2i(86, 67, 6, 6),
]


static func build() -> Region:
	var c := C.new(W, H, 0.0)
	_paint(c)
	var root := c.to_region(&"cieux", "Cieux Éternels", "Les Pitons", Vector2i(38, 41), RES_DIR, C.SNOW_TEX, C.PLANKS_TEX, true)
	_climate(root)
	var entities: Node2D = root.get_node("Entities")
	var ground := HeightMap.new(root, 2)   # (the ground as the view draws it: where a post holds)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_landmarks(root, entities)
	var ropes: Array = []   # (the posts' ropes, declared once the props are settled)
	for p: Array in PONTS:
		ropes += D.bridge_posts(c, ground, entities, p[0])
	D.landing_flags(c, entities, P.ATTERRISSAGES_CIEUX)
	D.scatter(c, entities, rng, _keep_clear())
	D.sea_decor(c, entities, rng, 7, 26)
	_story(root, entities)
	B.hide_pebbles(root, entities, Vector2i(P.ENTREE_MONTS.floor()), 7741, 0, 6,
		[Vector2(55, 75), Vector2(43, 32), Vector2(82, 48), Vector2(19, 61), Vector2(87, 73), Vector2(50, 33), Vector2(30, 57),
			Vector2(74, 22)],
		[Vector2(91, 73), Vector2(47, 53), Vector2(75, 52), Vector2(14, 66), Vector2(56, 47), Vector2(81, 33), Vector2(43, 70)])
	D.pebbles_in_sight(root, entities, [P.AIGUILLE_AU_NID + Vector2(0.6, -0.4)])
	_places(root)
	_habitats(root)
	# Every prop on the ground (none floating over a drop, by a bridge's edge or a piton's rim).
	_check(root, F.settle_all(root))
	D.ropes(root, ropes)
	return root


static func _climate(root: Region) -> void:
	root.music = load(C.first(MUSIC))
	root.ambience_id = &"cieux"
	var backdrop := C.first(BACKDROP)
	if backdrop != "":
		root.battle_backdrop = load(backdrop)
	# Above the clouds: mist rising off the sea of clouds, now and then snow, a gale (the blizzard);
	# never rain nor thunder. A cold region: the down coat.
	root.rain_chance = 0.0
	root.storm_chance = 0.0
	root.sandstorm_chance = 0.0
	root.mist_chance = 0.15
	root.snow_chance = 0.06
	root.blizzard_chance = 0.06
	root.cold = true


static func _paint(c: C) -> void:
	for p: Array in [ARRIVEE, GUET, MER, VENTS, HAUT, FENDU, RHAMPHOS, BEL_BAS, BEL_HAUT]:
		c.plateau(p[0], p[1], p[2])
	for p: Array in ILOTS:
		c.plateau(p[0], p[1], p[2], 0.3)
	c.cloud_field(MER_CREUX[0], MER_CREUX[1], MER_FOND)
	# The Rempart and its carved way, the end of the Monts' gully.
	c.plateau(REMPART[0], REMPART[1], H_REMPART, 0.4)
	c.block(REMPART_BORD, H_REMPART, false)
	c.block(COUPE, H_SORTIE)
	c.ramp(RAMPE_NIDS, "-y", H_HAUT, H_SORTIE)
	_monts_rim(c)
	c.block(COULOIR, H_ARRIVEE)
	for p: Array in PONTS:
		c.bridge(p[0], p[1], p[2])
	c.edge_clouds("north", C.EDGE_CLOUDS)
	c.banks()
	c.ramp(RAMPE_BELVEDERE, "-y", H_HAUT, H_BELVEDERE)
	for pts: Array in SENTIERS:
		c.trail(pts)
	c.trail([Vector2(72.5, H), Vector2(72.5, COULOIR.position.y)], 3.0)
	c.trail([Vector2(46.5, 0.0), Vector2(46.5, COUPE.end.y)], 3.0)
	for r: Rect2i in PLACES_NETTES:
		c.keep_level(r)
	for t: Array in TOUFFES:
		c.tufts(t[0], t[1])
	c.finish()
	c.rock_top_where(func(x: int, y: int) -> bool: return c.height_at(x, y) >= H_REMPART - 0.01)
	# The joins: all snow at the south edge (the Monts' gully, under its snow, goes on here), none at the
	# north edge (the nests have no snow: the Rempart's top goes bare towards them).
	c.edge_snow("south", 1.0, NEIGE_BORD)
	for y in range(H - NEIGE_COULOIR, H):
		for x in range(COULOIR.position.x, COULOIR.end.x):
			c.snow[y * W + x] = maxf(c.snow[y * W + x], smoothstep(H - NEIGE_COULOIR - 1.0, H - 1.0, float(y)))
	c.edge_snow("north", 0.0, NEIGE_NIDS)


## The rim of the Monts' peaks along the south edge (see MONTS_PEAKS), the clouds sinking to their woods
## west of it.
static func _monts_rim(c: C) -> void:
	for x in W:
		if x < MONTS_PEAKS_FROM:
			for y in range(H - 6, H):
				var k := float(y - (H - 6)) / 5.0
				c.height[y * W + x] = minf(c.height[y * W + x], lerpf(c.height[y * W + x], MONTS_WOODS, k))
			continue
		var depth := roundi(lerpf(RIM_DEPTH.x, RIM_DEPTH.y, C.fbm(x * 0.21 + 7.0, 3.3)))
		if absi(x - COULOIR.position.x - 1) <= RIM_THIN_NEAR:
			# (By the way in: the void stays south of the arrival's terrace; its edge still ragged.)
			depth = int(RIM_DEPTH.x) + (1 if C.fbm(x * 0.5 + 3.0, 9.1) > 0.5 else 0)
		c.block(Rect2i(x, H - depth, 1, depth), MONTS_PEAKS, false)


## Scenery placed by hand: the shelter of the arrival's fire, the rhamphorhynchus' nests, the
## Belvédère's bench, the islets' finds.
static func _landmarks(root: Region, entities: Node2D) -> void:
	D.put(entities, ["rocher_neige"], P.FEU_ARRIVEE + Vector2(-0.6, -1.4))
	D.fire(root, entities, P.FEU_ARRIVEE)
	for t: Vector2 in [Vector2(86.5, 68.0), Vector2(91.6, 68.4), Vector2(92.4, 72.6)]:
		D.put(entities, ["nid_pteranodon"], t, t.x > 90.0)
	D.put(entities, ["banc"], P.BANC_BELVEDERE)
	# The islets: a nest on the needle (its pebble: build), an old chest on the balcony, and by it
	# what Hélène left there (a fossil); page 33 on its islet (_story).
	D.put(entities, ["nid_cieux_vide", "nid_pteranodon"], P.AIGUILLE_AU_NID + Vector2(0.4, -0.6))
	# The old bridges that led to the islets, broken (that is why only the Vol gets there): their
	# ends hanging off the rims facing them.
	for b: Array in PONTS_ROMPUS:
		D.put(entities, ["pont_lianes_rompu"], b[0], b[1])
	D.put(entities, ["coffre_comptoir", "boite_fer"], P.BALCON_BRUMES + Vector2(0.0, -0.8))
	D.find(entities, ["ambre"], P.BALCON_BRUMES + Vector2(0.9, -0.2), "fossile",
		"Dans le vieux coffre, roulé dans une toile cirée : un fossile. Une aile de ptérosaure, toute fine, prise dans la pierre. Qui a bien pu monter ça jusqu'ici ?",
		&"cieux_coffre_balcon", "TresorBalcon")
	D.put(entities, ["rocher_neige"], P.ILOT_NUAGES + Vector2(-1.4, -1.2))
	D.put(entities, ["buisson_givre"], P.BALCON_BRUMES + Vector2(-1.8, 0.6), true)


## The story's places and people (story/cieux*.gd): the pages, the first bridge's trigger, the signs.
static func _story(root: Region, entities: Node2D) -> void:
	D.page(entities, 31, P.PAGE_31)
	D.page(entities, 33, P.PAGE_33)
	B.trigger(root, P.PREMIER_PONT_DEBUT.x, P.PREMIER_PONT_DEBUT.y, 2.0, &"premier_pont",
		{"once_flag": &"pont_lianes_vu", "name": "PremierPont"})
	B.sign(entities, B.cell(P.PANNEAU_ENTREE.x, P.PANNEAU_ENTREE.y), &"panneau_cieux_entree")
	B.sign(entities, B.cell(P.PANNEAU_PONT.x, P.PANNEAU_PONT.y), &"panneau_pont", true)
	B.sign(entities, B.cell(P.PANNEAU_BELVEDERE.x, P.PANNEAU_BELVEDERE.y), &"panneau_belvedere")


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.ENTREE_MONTS.x, P.ENTREE_MONTS.y)
	# South: back to the Monts (their gully, x 99-101: Monts x = Cieux x + 28).
	B.spawn(root, String(P.SPAWN_MONTS), P.ENTREE_MONTS.x, P.ENTREE_MONTS.y)
	B.exit(root, Rect2(71.0, H - 0.55, 3.0, 0.55), &"monts", &"DepuisCieux")
	# North: up the carved ramp to the nests (their south edge, x 33-35: Cieux x = Nids x + 12).
	B.spawn(root, String(P.SPAWN_NIDS), P.SORTIE_NIDS.x, 3.0)
	B.exit(root, Rect2(45.0, 0.0, 3.0, 0.55), &"nids_geants", P.SPAWN_CIEUX)


static func _habitats(root: Region) -> void:
	# The widest first (where they overlap, the last one listed wins).
	B.habitat(root, "Les Pitons", Rect2(0, 0, W, H), _known([
		[&"rhamphorhynchus", 38, 40, 10, "jour", false], [&"rhamphorhynchus", 38, 40, 8, "jour", true],
	]), 2)
	B.habitat(root, "Le Piton d'Arrivée", Rect2(64, 68, 18, 18), _known([
		[&"rhamphorhynchus", 38, 39, 10, "jour", false],
	]), 2)
	B.habitat(root, "La Mer de nuages", Rect2(12, 54, 29, 21), _known([
		[&"tupandactylus", 40, 42, 10, "aube et crépuscule", false], [&"tupandactylus", 40, 42, 4, "aube et crépuscule", true],
		[&"rhamphorhynchus", 38, 40, 5, "jour", true],
	]), 2)
	B.habitat(root, "Le Piton aux Rhamphorhynques", Rect2(82, 64, 14, 12), _known([
		[&"rhamphorhynchus", 39, 41, 10, "jour", false], [&"rhamphorhynchus", 39, 41, 6, "jour", true],
	]), 2)
	# Calm places (no dinos; their names on the map): the Belvédère, the ramp to the nests.
	B.habitat(root, "Le Belvédère", Rect2(70, 16, 14, 22), [], 0)
	B.habitat(root, "La Rampe des Nids", Rect2(38, 0, 18, 26), [], 0)


## The rows of the species the game knows already (the chapter's come with their sheets: the zone is
## built again once they are all in SpeciesDB).
static func _known(rows: Array) -> Array:
	return rows.filter(func(r: Array) -> bool: return SpeciesDB.PATHS.has(r[0]))


## Where nothing is scattered (tiles): the places, the bridges' heads, the islets.
static func _keep_clear() -> Array:
	var keep: Array = []
	for r: Rect2i in PLACES_NETTES:
		keep.append(Rect2(r).grow(1.0))
	for t: Vector2 in [P.PAGE_31, P.PANNEAU_ENTREE, P.PANNEAU_PONT, P.PANNEAU_BELVEDERE, P.PREMIER_PONT_DEBUT]:
		keep.append(Rect2(t - Vector2(2, 2), Vector2(4, 4)))
	for p: Array in ILOTS:
		keep.append(Rect2(p[0] - p[1], p[1] * 2.0))
	return keep


## The plan's checks (printed when the zone is built).
static func _check(root: Region, floating: Array[String]) -> void:
	var on_foot := {
		"arrivée": P.ENTREE_MONTS, "sortie vers les Monts": P.SORTIE_MONTS - Vector2(0, 1), "premier pont": P.PREMIER_PONT,
		"le Guet": P.GUET, "la Mer de nuages (le creux)": P.MER_DE_NUAGES, "les Vents": P.VENTS, "le Haut": P.HAUT,
		"le Fendu": P.FENDU, "les rhamphorhynques": P.RHAMPHOS, "le Belvédère": P.BELVEDERE, "page 31": P.PAGE_31,
		"sortie vers les nids": P.SORTIE_NIDS,
	}
	var by_air := {"îlot de la page 33": P.ILOT_NUAGES, "aiguille au nid": P.AIGUILLE_AU_NID, "balcon des brumes": P.BALCON_BRUMES}
	print("Cieux : vérifications")
	var failures := C.check(root, Vector2i(P.ENTREE_MONTS.floor()), on_foot, by_air)
	for s in D.on_paths(root):
		print("  NON décor sur un chemin : ", s)
		failures += 1
	for s in floating:
		print("  NON décor qui flotte, impossible à poser : ", s)
		failures += 1
	print("  %s" % ("tous les lieux sont bons" if failures == 0 else "%d DÉFAUT(S)" % failures))
