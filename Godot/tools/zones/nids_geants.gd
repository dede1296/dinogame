extends RefCounted
## Les Nids géants (chapter 7), the sanctuary of the Quetzalcoatlus Roi (70 x 60 tiles), above the
## Cieux' pitons (painted by tools/zones/cieux_canvas.gd, decor of cieux_decor.gd; places in
## story/cieux_places.gd). South edge: the carved way from the Cieux comes through the last of the
## Rempart onto the Aire des Plumes (13.8 m: the fire under a fallen nest, the sign). A ramp up to the
## nests (14.4 m): four nests « as big as boats », the young Quetzalcoatlus and the Tapejara among them,
## page 32 in a crack of rock by an empty one. A second ramp up to the Grand Nid (15 m): its level
## square, bare, the Roi at its north edge facing the way in, Hélène's old harness by him. From the
## Grand Nid, a liana bridge east to the needle at the north edge: the way to the Arche du Vent
## (closed until the Vol). For the Vol only: an old nest on its own piton in the east (a fern).
## The ground here: straw and down round the nests (the second cover layer), no snow layer.

const PATH := "res://regions/cieux/nids_geants.tscn"
const RES_DIR := "res://regions/cieux"
const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/cieux_canvas.gd")
const D := preload("res://tools/zones/cieux_decor.gd")
const F := preload("res://tools/zones/cieux_pieds.gd")
const P := preload("res://story/cieux_places.gd")
const STORY_PROP := "res://world/story_prop.gd"
const MUSIC := ["res://assets/audio/music/nids_geants.ogg", "res://assets/audio/music/cieux.ogg", "res://assets/audio/music/monts.ogg"]
const BACKDROP := ["res://assets/art/battle/cieux.jpg", "res://assets/art/battle/monts.jpg"]
const W := 70
const H := 60
const SEED := 6113
## Heights (m): the way in (the top of the Cieux' carved ramp), the nests, the Grand Nid and the
## needle; the Rempart (out of reach).
const H_ENTREE := 13.8
const H_NIDS := 14.4
const H_GRAND_NID := 15.0
const H_REMPART := 15.0
## The nests' own sea of clouds (higher than the Cieux'), the void under it; along the south edge it
## sinks to meet the Cieux' (C.EDGE_CLOUDS).
const SEA := 12.0
const VOID := 13.2
## The pitons: [centre, radii, height].
const AIRE := [Vector2(34.5, 47.5), Vector2(9.0, 4.5), H_ENTREE]
const TERRASSE_NIDS := [Vector2(36.0, 32.0), Vector2(15.0, 7.5), H_NIDS]
const GRAND_NID := [Vector2(23.0, 12.5), Vector2(10.0, 7.0), H_GRAND_NID]
const AIGUILLE := [Vector2(43.0, 5.5), Vector2(3.0, 3.5), H_GRAND_NID]
const NID_OUBLIE := [P.NID_OUBLIE, Vector2(3.2, 3.0), H_NIDS]
## The Rempart: its edge along the south border (x 26-42, the Cieux' x 38-54 go on beyond it), its
## mass, the carved way through it (x 33-35); the needle's top, out to the north border (x 41-45:
## the Arche's platform x 26-30 goes on beyond it).
const REMPART_BORD := Rect2i(26, 56, 17, 4)
const REMPART := [Vector2(34.0, 57.0), Vector2(11.0, 3.5)]
const COUPE := Rect2i(33, 52, 3, 8)
const AIGUILLE_BORD := Rect2i(41, 0, 5, 4)
## The ramps: up to the nests, up to the Grand Nid.
const RAMPE_NIDS := Rect2i(33, 39, 3, 5)
const RAMPE_GRAND_NID := Rect2i(26, 18, 3, 8)
## The liana bridge from the Grand Nid to the needle (east, straight).
const PONT_AIGUILLE := [[Vector2(31.0, 8.0), Vector2(41.5, 8.0)], H_GRAND_NID, H_GRAND_NID]
const SENTIERS := [
	[Vector2(34.5, 52.0), Vector2(34.5, 44.0)], [Vector2(34.5, 39.0), Vector2(35.0, 34.0), Vector2(29.0, 27.0), Vector2(27.5, 25.5)],
	[Vector2(27.5, 18.0), Vector2(26.0, 16.0)], [Vector2(31.0, 8.0), Vector2(29.0, 8.5)], [Vector2(41.5, 8.0), Vector2(43.0, 6.0), Vector2(43.0, 0.0)],
	[Vector2(35.0, 34.0), Vector2(45.0, 33.0)],
]
## The straw round the nests: [centre, radii, dose] (the Grand Nid's, wide).
const PAILLE := [
	[Vector2(23.0, 11.0), Vector2(7.0, 4.5), 1.0], [Vector2(26.0, 31.5), Vector2(2.6, 1.7), 1.0], [Vector2(33.5, 28.0), Vector2(2.6, 1.7), 1.0],
	[Vector2(43.0, 28.5), Vector2(2.6, 1.7), 1.0], [Vector2(47.5, 34.0), Vector2(2.6, 1.7), 1.0], [Vector2(27.5, 46.5), Vector2(2.4, 1.4), 0.8],
	[P.NID_OUBLIE, Vector2(2.0, 1.6), 1.0],
]
const TOUFFES := [[Vector2(24.5, 36.0), Vector2(2.6, 1.5)], [Vector2(40.5, 37.2), Vector2(2.4, 1.3)], [Vector2(41.5, 47.5), Vector2(2.2, 1.4)]]
## Level and bare: the Aire, the Grand Nid's square (9 x 7: the Roi and his wings), the needle's top.
const CARRE_ROI := Rect2i(19, 9, 9, 7)
const PLACES_NETTES := [Rect2i(31, 46, 7, 5), CARRE_ROI, Rect2i(41, 2, 5, 5), Rect2i(33, 30, 6, 5)]
## Giant feathers stuck in the ground round the nests and the Grand Nid (never on its square):
## [picture, tile, flipped].
const PLUMES := [
	["plume_geante_1", Vector2(30.5, 29.2), false], ["plume_geante_2", Vector2(41.0, 35.6), true], ["plume_geante_3", Vector2(27.6, 37.0), false],
	["plume_geante_1", Vector2(16.6, 12.4), true], ["plume_geante_3", Vector2(29.8, 15.2), false], ["plume_geante_2", Vector2(38.8, 49.4), false],
]
## The Roi: an Alpha, bigger than its kind (×1.3: the story's figure); the young ones (share of an adult).
const ROI_SIZE := 1.3
const JEUNE_SIZE := 0.4


static func build() -> Region:
	var c := C.new(W, H, 37.0, SEA, VOID)
	_paint(c)
	var root := c.to_region(&"nids_geants", "Cieux Éternels", "Les Nids géants", Vector2i(40, 43), RES_DIR, C.NEST_TEX, C.PLANKS_TEX, false)
	_climate(root)
	var entities: Node2D = root.get_node("Entities")
	var ground := HeightMap.new(root, 2)   # (the ground as the view draws it: where a post holds)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_landmarks(root, entities)
	var ropes := D.bridge_posts(c, ground, entities, PONT_AIGUILLE[0])
	D.landing_flags(c, entities, [P.ATTERRISSAGES_NIDS[0], P.ATTERRISSAGES_NIDS[1], P.ATTERRISSAGES_NIDS[3]])
	D.scatter(c, entities, rng, _keep_clear(), 0.8)
	D.sea_decor(c, entities, rng, 4, 16)
	_story(root, entities)
	B.hide_pebbles(root, entities, Vector2i(P.NIDS_ENTREE.floor()), 6127, 0, 4,
		[Vector2(40, 49), Vector2(22, 33)], [Vector2(49, 31), Vector2(16, 13)])
	D.pebbles_in_sight(root, entities, [P.NID_OUBLIE + Vector2(1.6, 0.8)])
	_places(root)
	_habitats(root)
	# Every prop on the ground (none floating over a drop, by a bridge's edge or a piton's rim).
	_check(root, F.settle_all(root))
	D.ropes(root, ropes)
	return root


static func _climate(root: Region) -> void:
	root.music = load(C.first(MUSIC))
	root.ambience_id = &"nids_geants"
	var backdrop := C.first(BACKDROP)
	if backdrop != "":
		root.battle_backdrop = load(backdrop)
	root.rain_chance = 0.0
	root.storm_chance = 0.0
	root.sandstorm_chance = 0.0
	root.mist_chance = 0.15
	root.snow_chance = 0.06
	root.blizzard_chance = 0.06
	root.cold = true


static func _paint(c: C) -> void:
	for p: Array in [AIRE, TERRASSE_NIDS, GRAND_NID, AIGUILLE, NID_OUBLIE]:
		c.plateau(p[0], p[1], p[2], 0.4 if p != NID_OUBLIE else 0.3)
	c.block(AIGUILLE_BORD, H_GRAND_NID)
	c.plateau(REMPART[0], REMPART[1], H_REMPART, 0.3)
	c.block(REMPART_BORD, H_REMPART, false)
	c.block(COUPE, H_ENTREE)
	c.ramp(RAMPE_NIDS, "-y", H_ENTREE, H_NIDS)
	c.ramp(RAMPE_GRAND_NID, "-y", H_NIDS, H_GRAND_NID)
	c.bridge(PONT_AIGUILLE[0], PONT_AIGUILLE[1], PONT_AIGUILLE[2])
	c.edge_clouds("south", C.EDGE_CLOUDS)
	c.banks()
	for pts: Array in SENTIERS:
		c.trail(pts)
	c.trail([Vector2(34.5, H), Vector2(34.5, COUPE.position.y)], 3.0)
	for r: Rect2i in PLACES_NETTES:
		c.keep_level(r)
	for t: Array in TOUFFES:
		c.tufts(t[0], t[1])
	c.finish(0.0)
	for s: Array in PAILLE:
		c.straw(s[0], s[1], s[2])


## Scenery placed by hand: the nests (their pictures, or a stand-in in the straw), the fallen nest
## sheltering the fire, the rock with page 32's crack.
static func _landmarks(root: Region, entities: Node2D) -> void:
	for i in P.NIDS_BRANCHES.size():
		var t: Vector2 = P.NIDS_BRANCHES[i]
		# (The last one, by page 32's crack, is empty.)
		var full := i < P.NIDS_BRANCHES.size() - 1
		D.put(entities, ["nid_cieux" if full else "nid_cieux_vide", "nid_branches", "nid_pteranodon"], t, t.x > 36.0)
	D.put(entities, ["nid_cieux_vide", "nid_branches", "nid_pteranodon"], P.FEU_NIDS + Vector2(-0.6, -1.8), true)
	for p: Array in PLUMES:
		D.put(entities, [p[0]], p[1], p[2])
	D.fire(root, entities, P.FEU_NIDS)
	D.put(entities, ["rocher_neige"], P.PAGE_32 + Vector2(0.9, -0.5))
	# The Grand Nid's crown of branches behind the Roi (north of his square: never on it).
	D.put(entities, ["nid_roi", "nid_cieux_vide", "nid_branches"], P.ROI + Vector2(0.0, -2.2))
	# The Arche du Vent far off (a hazy picture of it), on the rim west of that crown.
	D.put(entities, ["arche_vent_loin"], P.ARCHE_LOIN)
	# The forgotten nest (only the Vol reaches it): an old fern in it.
	D.put(entities, ["nid_cieux_vide", "nid_branches", "nid_pteranodon"], P.NID_OUBLIE + Vector2(0.0, -0.4))
	D.find(entities, ["fougeres", "ambre"], P.NID_OUBLIE + Vector2(-1.4, 0.6), "fougere",
		"Au bord du vieux nid, à l'abri du vent, une fougère curative a poussé dans le duvet. Chloé en cueille une tige.",
		&"nids_fougere_oubliee", "FougereOubliee")


## The story's places and people (story/cieux_nids.gd): the Roi, the old harness, the young ones and
## the Tapejara (their species once in SpeciesDB), page 32, the sign.
static func _story(root: Region, entities: Node2D) -> void:
	if SpeciesDB.PATHS.has(&"quetzalcoatlus"):
		B.dino_npc(root, "QuetzalRoi", &"quetzalcoatlus", P.ROI.x, P.ROI.y, {"event": &"quetzal_roi", "size": ROI_SIZE})
		for i in P.JEUNES_QUETZAL.size():
			var at: Vector2 = P.JEUNES_QUETZAL[i]
			B.dino_npc(root, "JeuneQuetzal%d" % (i + 1), &"quetzalcoatlus", at.x, at.y, {"size": JEUNE_SIZE, "flip": i % 2 == 1})
	if SpeciesDB.PATHS.has(&"tapejara"):
		for i in P.TAPEJARAS.size():
			var at: Vector2 = P.TAPEJARAS[i]
			B.dino_npc(root, "Tapejara%d" % (i + 1), &"tapejara", at.x, at.y, {"flip": i == 1})
	if Prop.KINDS.has("vieux_harnais"):
		var harness: Node2D = B.prop(entities, "vieux_harnais", B.cell(P.VIEUX_HARNAIS.x, P.VIEUX_HARNAIS.y), false, load(STORY_PROP))
		harness.name = "VieuxHarnais"
	D.page(entities, 32, P.PAGE_32)
	B.sign(entities, B.cell(P.PANNEAU_NIDS.x, P.PANNEAU_NIDS.y), &"panneau_nids")


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.NIDS_ENTREE.x, 52.5)
	# South: back down to the Cieux (their carved ramp, x 45-47: Cieux x = Nids x + 12).
	B.spawn(root, String(P.SPAWN_CIEUX), P.NIDS_ENTREE.x, 52.5)
	B.exit(root, Rect2(33.0, H - 0.55, 3.0, 0.55), &"cieux", P.SPAWN_NIDS)
	# North: off the needle to the Arche du Vent (its platform, x 26-30: Nids x = Arche x + 15),
	# closed until the Vol.
	B.spawn(root, String(P.SPAWN_ARCHE), P.AIGUILLE.x, P.AIGUILLE.y + 1.0)
	B.exit(root, Rect2(41.5, 0.0, 3.0, 0.55), &"arche_du_vent", P.SPAWN_NIDS, &"vol_obtenu", &"arche_bloquee")


static func _habitats(root: Region) -> void:
	B.habitat(root, "Les Nids géants", Rect2(0, 0, W, H), _known([
		[&"tapejara", 40, 42, 6, "jour", false], [&"rhamphorhynchus", 39, 41, 4, "jour", false],
	]), 1)
	B.habitat(root, "Les Nids", Rect2(20, 23, 33, 17), _known([
		[&"tapejara", 40, 43, 10, "jour", false], [&"tapejara", 40, 43, 8, "jour", true],
	]), 2)
	# Calm places (no wild dinos; their names on the map): the Grand Nid, the needle.
	B.habitat(root, "Le Grand Nid", Rect2(12, 4, 22, 16), [], 0)
	B.habitat(root, "L'Aiguille", Rect2(38, 0, 9, 10), [], 0)


static func _known(rows: Array) -> Array:
	return rows.filter(func(r: Array) -> bool: return SpeciesDB.PATHS.has(r[0]))


static func _keep_clear() -> Array:
	var keep: Array = []
	for r: Rect2i in PLACES_NETTES:
		keep.append(Rect2(r).grow(1.0))
	for t: Vector2 in P.NIDS_BRANCHES + P.JEUNES_QUETZAL + P.TAPEJARAS + [P.PAGE_32, P.PANNEAU_NIDS, P.FEU_NIDS, P.VIEUX_HARNAIS]:
		keep.append(Rect2(t - Vector2(2, 2), Vector2(4, 4)))
	keep.append(Rect2(NID_OUBLIE[0] - NID_OUBLIE[1], NID_OUBLIE[1] * 2.0))
	return keep


static func _check(root: Region, floating: Array[String]) -> void:
	var on_foot := {
		"entrée": P.NIDS_ENTREE, "sortie vers les Cieux": P.SORTIE_CIEUX - Vector2(0, 1), "les nids": P.NIDS, "page 32": P.PAGE_32,
		"le Grand Nid": P.GRAND_NID, "le Roi": P.ROI, "l'aiguille": P.AIGUILLE, "sortie vers l'Arche": P.SORTIE_ARCHE,
	}
	print("Nids géants : vérifications")
	var failures := C.check(root, Vector2i(P.NIDS_ENTREE.floor()), on_foot, {"nid oublié": P.NID_OUBLIE})
	for s in D.on_paths(root):
		print("  NON décor sur un chemin : ", s)
		failures += 1
	for s in floating:
		print("  NON décor qui flotte, impossible à poser : ", s)
		failures += 1
	if Prop.KINDS.has("arche_vent_loin") and not root.has_node("Entities/ArcheVentLoin"):
		print("  NON l'Arche au loin n'a pas de sol où tenir (retirée)")
		failures += 1
	print("  %s" % ("tous les lieux sont bons" if failures == 0 else "%d DÉFAUT(S)" % failures))
