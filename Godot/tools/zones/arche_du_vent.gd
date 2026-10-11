extends RefCounted
## L'Arche du Vent (chapter 7), the summit (56 x 44 tiles): the trap, then the mask's scene (painted
## by tools/zones/cieux_canvas.gd, decor of cieux_decor.gd; places in story/cieux_places.gd). South
## edge: the platform where the Vol lands (15 m, the top of the nests' needle goes on here), a ramp
## up to the terrace (16.2 m): wide, level and bare under and in front of the natural arch (its
## picture stands at the north of the scene's square, so that its top shows when the camera frames
## the middle). East of the arch, Hélène's post (a cairn, an iron box, page 34); in the shelter of its
## west pillar, a fire. Behind it, north-west, a ridge of cinders going down towards the Plaine
## Volcanique (closed: « volcan_bloque »). The void all round: one flies over it.
## Nothing tall south of the scene's square (the camera looks north), no tufts on the terrace.

const PATH := "res://regions/cieux/arche_du_vent.tscn"
const RES_DIR := "res://regions/cieux"
const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/cieux_canvas.gd")
const D := preload("res://tools/zones/cieux_decor.gd")
const F := preload("res://tools/zones/cieux_pieds.gd")
const P := preload("res://story/cieux_places.gd")
const STORY_PROP := "res://world/story_prop.gd"
const CHARS := "res://assets/art/characters/%s.png"
const MUSIC := ["res://assets/audio/music/arche_du_vent.ogg", "res://assets/audio/music/cieux.ogg", "res://assets/audio/music/monts.ogg"]
const BACKDROP := ["res://assets/art/battle/cieux.jpg", "res://assets/art/battle/monts.jpg"]
const W := 56
const H := 44
const SEED := 4409
## Heights (m): the landing platform (the needle's top), the terrace; the ridge of cinders goes down
## to H_DESCENTE at the north edge.
const H_PLATEFORME := 15.0
const H_TERRASSE := 16.2
const H_DESCENTE := 14.4
## The summit's sea of clouds (as the nests'), the void under it.
const SEA := 12.0
const VOID := 13.2
const PLATEFORME := [Vector2(28.0, 40.5), Vector2(4.2, 3.2), H_PLATEFORME]
const PLATEFORME_BORD := Rect2i(26, 39, 5, 5)
const TERRASSE := [Vector2(28.0, 22.0), Vector2(14.0, 10.0), H_TERRASSE]
const RAMPE := Rect2i(26, 32, 5, 7)
const DESCENTE := [Vector2(20.0, 15.0), Vector2(20.0, 0.0)]
const SENTIERS := [[Vector2(28.0, 43.0), Vector2(28.0, 32.0)], [Vector2(28.0, 32.0), Vector2(28.0, 27.0)]]
## The scene's square (12 x 10, level, nothing on it), the platform, the Roi's landing on the east.
const CARRE := Rect2i(22, 16, 12, 10)
## Rows over which the snow thins out to none at the south edge (the nests have none).
const NEIGE_AIGUILLE := 6
const PLACES_NETTES := [CARRE, Rect2i(26, 38, 5, 6), Rect2i(36, 19, 5, 5)]
## The terrace's rim, around the square (rocks and pines there, never south of it): [kind, at, flip].
const BORDURE := [
	[["pin_tordu"], Vector2(16.5, 19.0), false], [["rocher_neige"], Vector2(15.8, 23.5), true], [["rocher_neige"], Vector2(39.6, 14.6), false],
	[["rocher_neige"], Vector2(39.4, 25.6), true], [["buisson_givre"], Vector2(17.4, 26.6), false], [["buisson_givre"], Vector2(38.4, 27.4), true],
	[["rocher_neige"], Vector2(23.0, 13.8), true], [["cailloux"], Vector2(33.6, 13.6), false],
]


static func build() -> Region:
	var c := C.new(W, H, 71.0, SEA, VOID)
	_paint(c)
	var root := c.to_region(&"arche_du_vent", "Cieux Éternels", "L'Arche du Vent", Vector2i(42, 44), RES_DIR, C.SNOW_TEX, [], true)
	_climate(root)
	var entities: Node2D = root.get_node("Entities")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_landmarks(root, entities)
	D.sea_decor(c, entities, rng, 3, 14)
	_story(root, entities)
	B.hide_pebbles(root, entities, Vector2i(P.ARCHE_ENTREE.floor()), 4421, 0, 1, [Vector2(40, 20)], [Vector2(16, 21), Vector2(20, 5)])
	_places(root)
	_habitats(root)
	# Every prop on the ground (none floating over a drop, by a bridge's edge or a piton's rim).
	_check(root, F.settle_all(root))
	return root


static func _climate(root: Region) -> void:
	root.music = load(C.first(MUSIC))
	root.ambience_id = &"arche_du_vent"
	var backdrop := C.first(BACKDROP)
	if backdrop != "":
		root.battle_backdrop = load(backdrop)
	# The summit: the wind, often a gale (the Hatzegopteryx come out in it), the mist below.
	root.rain_chance = 0.0
	root.storm_chance = 0.0
	root.sandstorm_chance = 0.0
	root.mist_chance = 0.12
	root.snow_chance = 0.06
	root.blizzard_chance = 0.08
	root.cold = true


static func _paint(c: C) -> void:
	c.plateau(TERRASSE[0], TERRASSE[1], TERRASSE[2], 0.35)
	c.plateau(PLATEFORME[0], PLATEFORME[1], PLATEFORME[2], 0.3)
	c.block(PLATEFORME_BORD, H_PLATEFORME)
	c.ramp(RAMPE, "-y", H_PLATEFORME, H_TERRASSE)
	c.bridge(DESCENTE, H_TERRASSE, H_DESCENTE, 2.0, false)
	for pts: Array in SENTIERS:
		c.trail(pts)
	for r: Rect2i in PLACES_NETTES:
		c.keep_level(r)
	c.finish(0.8)
	# The scene's square: no snow lying on it (it reads clearly, the characters stand out).
	for y in range(CARRE.position.y, CARRE.end.y):
		for x in range(CARRE.position.x, CARRE.end.x):
			c.snow[y * c.w + x] = 0.0
	# The join with the nests' needle (no snow there): bare towards the south edge.
	c.edge_snow("south", 0.0, NEIGE_AIGUILLE)


## Scenery placed by hand: the arch, the rim's rocks and pines, Hélène's cairn, the fire.
static func _landmarks(root: Region, entities: Node2D) -> void:
	D.put(entities, ["arche_vent", "arche_rocheuse"], P.ARCHE_PIED)
	for p: Array in BORDURE:
		D.put(entities, p[0], p[1], p[2])
	for t: Vector2 in [P.CAIRN + Vector2(-0.6, 0.2), P.CAIRN + Vector2(0.5, -0.3)]:
		D.put(entities, ["pierre_plate"], t, t.x > P.CAIRN.x)
	D.put(entities, ["boite_fer"], P.CAIRN + Vector2(0.0, 0.9))
	# Wind flags on their cairns: by Hélène's post, at the landing platform.
	D.put(entities, ["drapeau_vent_2"], P.CAIRN + Vector2(1.6, -0.6))
	D.put(entities, ["drapeau_vent_1"], P.ARCHE_ENTREE + Vector2(-2.2, -0.6), true)
	D.fire(root, entities, P.FEU_ARCHE)


## The story's places and people (story/cieux_arche.gd): the Masque under the arch (from the Vol
## until the mask falls), the obsidian mask left in the grass after the scene, page 34, the sign.
static func _story(root: Region, entities: Node2D) -> void:
	var sheet := CHARS % ("masque" if ResourceLoader.exists(CHARS % "masque") else "sbire")
	B.npc(root, "MasqueArche", "Le Masque", sheet, P.MASQUE.x, P.MASQUE.y, {"facing": "down", "event": &"masque_arche",
		"show_flag": &"vol_obtenu", "hide_flag": &"masque_tombe"})
	if Prop.KINDS.has("masque_obsidienne"):
		var mask: Node2D = B.prop(entities, "masque_obsidienne", B.cell(P.MASQUE_OBSIDIENNE.x, P.MASQUE_OBSIDIENNE.y), false, load(STORY_PROP))
		mask.name = "MasqueObsidienne"
		mask.event = &"masque_obsidienne"
		mask.show_flag = &"masque_tombe"
	D.page(entities, 34, P.PAGE_34)
	B.sign(entities, B.cell(P.PANNEAU_ARCHE.x, P.PANNEAU_ARCHE.y), &"panneau_arche")


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.ARCHE_ENTREE.x, P.ARCHE_ENTREE.y)
	# South: back to the nests' needle (its north border, x 41-45: Nids x = Arche x + 15).
	B.spawn(root, String(P.SPAWN_NIDS), P.ARCHE_ENTREE.x, P.ARCHE_ENTREE.y)
	B.exit(root, Rect2(26.5, H - 0.55, 3.0, 0.55), &"nids_geants", P.SPAWN_ARCHE)
	# North-west: the ridge of cinders down to the Plaine Volcanique (chapter 8: closed for now).
	B.spawn(root, "DepuisVolcan", P.DESCENTE_CENDRE.x, P.DESCENTE_CENDRE.y)
	B.exit(root, Rect2(19.0, 0.0, 2.0, 0.55), &"volcan", &"DepuisArche", &"volcan_ouvert", &"volcan_bloque")


static func _habitats(root: Region) -> void:
	var gale := {"weather": [&"blizzard", &"storm"]}
	B.habitat(root, "L'Arche du Vent", Rect2(0, 0, W, H), _known([
		[&"hatzegopteryx", 42, 44, 10, "toujours", false, gale], [&"rhamphorhynchus", 41, 42, 3, "jour", false],
	]), 1)


static func _known(rows: Array) -> Array:
	return rows.filter(func(r: Array) -> bool: return SpeciesDB.PATHS.has(r[0]))


static func _check(root: Region, floating: Array[String]) -> void:
	var on_foot := {
		"plateforme d'arrivée": P.ARCHE_ENTREE, "sortie vers les nids": P.SORTIE_NIDS_ARCHE - Vector2(0, 1), "l'arche (centre)": P.ARCHE,
		"le Masque": P.MASQUE, "bord du Roi": P.BORD_ROI, "le cairn": P.CAIRN, "la descente de cendre": P.DESCENTE_CENDRE,
		"sortie vers le volcan": P.SORTIE_VOLCAN, "le feu": P.FEU_ARCHE + Vector2(1, 0),
	}
	print("Arche du Vent : vérifications")
	var failures := C.check(root, Vector2i(P.ARCHE_ENTREE.floor()), on_foot, {})
	for s in D.on_paths(root):
		print("  NON décor sur un chemin : ", s)
		failures += 1
	for s in floating:
		print("  NON décor qui flotte, impossible à poser : ", s)
		failures += 1
	print("  %s" % ("tous les lieux sont bons" if failures == 0 else "%d DÉFAUT(S)" % failures))
