extends RefCounted
## La Porte du Cratère (chapter 8), 50 x 40 tiles, built as `porte_cratere` (painted by
## tools/zones/volcan_canvas.gd, decor of volcan_decor.gd; places in story/volcan_places.gd). The end of
## the crater path: from the south edge (12.6 m, the top of the coulées' cut) up in lacets, two terraces
## of black rock with their faces to the camera (14.4 m, then the esplanade at 16.2 m), the crust still
## smoking along the way where the lava has just gone back. On the esplanade, against the rim's wall
## (north, out of reach: 9 m above it), the portal of the Terre des Apex (7 m) between its two torches (« PortailApex »);
## Isaure before it, her back to the way up; Maïa on a stone beside her; Caillou lying behind; Hélène's
## camp against the wall (lantern, blanket, cairn: page 38). No wild dinos, no music (the torches and
## the wind).
## Build: --script res://tools/build_zone.gd -- volcan_porte --force

const PATH := "res://regions/volcan/porte_cratere.tscn"
const RES_DIR := "res://regions/volcan"
const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/volcan_canvas.gd")
const D := preload("res://tools/zones/volcan_decor.gd")
const V := preload("res://tools/zones/volcan_verif.gd")
const P := preload("res://story/volcan_places.gd")
const CHARS := "res://assets/art/characters/%s.png"
const MUSIC := ["res://assets/audio/music/porte_cratere.ogg"]
const W := 50
const H := 40
const SEED := 8423
const SALT := 73.0
## Heights (m): the way in (the coulées' crater path), the terrace, the esplanade; the rim's wall, the
## crater's sides (out of reach).
const H_ENTREE := 12.6
const H_TERRASSE := 14.4
const H_ESPLANADE := 16.2
const H_MUR := 25.0
const H_FLANCS := 18.0
const TERRASSE := Rect2i(0, 22, W, 8)
const ESPLANADE := Rect2i(0, 6, W, 16)
## The rim's wall: straight behind the portal and the camp (x 10-36), ragged elsewhere.
const MUR_DROIT := Vector2i(10, 37)
const MUR_PIED := 6
## The lacets: up the east end of the terrace's face, then up the west end of the esplanade's.
const RAMPE_1 := Rect2i(36, 28, 3, 4)
const RAMPE_2 := Rect2i(11, 20, 3, 4)
const LACETS := [Vector2(24.5, 40.0), Vector2(24.5, 34.5), Vector2(37.5, 33.0), Vector2(37.5, 27.0), Vector2(30.0, 25.5),
	Vector2(12.5, 25.0), Vector2(12.5, 19.5), Vector2(18.0, 16.5), Vector2(25.0, 13.5), Vector2(25.0, 8.0)]
## The crust still smoking where the lava has just gone back: [centre, radii].
const CROUTE := [[Vector2(31.0, 33.0), Vector2(9.0, 2.5)], [Vector2(22.0, 25.5), Vector2(12.0, 2.0)], [Vector2(17.0, 18.0), Vector2(6.0, 2.5)]]
## Level and bare: before the portal (the scene), the camp, the way in.
const PLACES_NETTES := [Rect2i(14, 6, 22, 9), Rect2i(20, 34, 9, 6)]


static func build() -> Region:
	var c := C.new(W, H, H_ENTREE, SALT)
	_paint(c)
	var root := c.to_region(&"porte_cratere", "Plaine Volcanique", "La Porte du Cratère", Vector2i(46, 48), RES_DIR, C.ROCHE_TEX,
		C.CENDRE_TEX)
	_climate(root)
	var entities: Node2D = root.get_node("Entities")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_story(root, entities)
	D.scatter(c, entities, rng, _keep_clear(), D.BLACK_ROCK, 0.6)
	B.hide_pebbles(root, entities, Vector2i(P.PORTE_ENTREE.floor()), 8431, 0, 1, [], [Vector2(41, 14)])
	_places(root)
	B.habitat(root, "La Porte du Cratère", Rect2(0, 0, W, H), [], 0)   # (calm; its name on the map)
	var floating := V.settle_all(root)
	V.check(root, "Porte du Cratère", Vector2i(P.PORTE_ENTREE.floor()), _on_foot(), {}, floating)
	return root


static func _climate(root: Region) -> void:
	D.climate(root, &"porte_cratere", MUSIC, 0.06)   # (no music drawn: silence, the torches, the wind)


static func _paint(c: C) -> void:
	c.block(TERRASSE, H_TERRASSE, false)
	c.block(ESPLANADE, H_ESPLANADE, false)
	c.mass(func(x: int, y: int) -> bool:
		var foot := MUR_PIED if x >= MUR_DROIT.x and x < MUR_DROIT.y else MUR_PIED - 1 + int(C.fbm(x * 0.3, 4.0) * 3.0)
		return y < foot, H_MUR, 0.8)
	c.mass(func(x: int, y: int) -> bool:
		return y >= MUR_PIED and (x < 2 + int(C.fbm(1.0, y * 0.3) * 3.0) or x > W - 3 - int(C.fbm(7.0, y * 0.3) * 3.0)), H_FLANCS, 0.6)
	c.ramp(RAMPE_1, "-y", H_ENTREE, H_TERRASSE)
	c.ramp(RAMPE_2, "-y", H_TERRASSE, H_ESPLANADE)
	for r: Rect2i in PLACES_NETTES:
		c.keep_level(r)
	c.trail(LACETS)
	c.trail([Vector2(24.5, 40.0), Vector2(24.5, 37.0)], 3.0)
	for k: Array in CROUTE:
		c.crust_field(k[0], k[1], 0.8)
	c.finish(0.35, 0.5)


## The portal and its torches, the people waiting, Hélène's camp and page 38.
static func _story(root: Region, entities: Node2D) -> void:
	D.story_prop(entities, D.PORTAIL, P.PORTAIL, "PortailApex", &"portail_apex")
	for i in P.TORCHES.size():
		D.put(entities, D.TORCHE, P.TORCHES[i], i == 1)
	B.npc(root, "IsaurePorte", "Isaure", CHARS % "isaure_sans_masque", P.ISAURE.x, P.ISAURE.y, {"facing": "up",
		"event": &"isaure_porte"})
	B.npc(root, "MaiaPorte", "Maïa", CHARS % "maia_arche", P.MAIA.x, P.MAIA.y, {"facing": "down", "event": &"maia_porte"})
	B.dino_npc(root, "CaillouPorte", &"triceratops", P.CAILLOU.x, P.CAILLOU.y, {"flip": true})
	D.story_prop(entities, D.CAMP_HELENE, P.CAMP_HELENE, "CampHelene", &"camp_helene")
	D.page(entities, 38, P.PAGE_38)


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.PORTE_ENTREE.x, P.PORTE_ENTREE.y)
	# South: back down the crater path to the coulées (their north edge, x 63-65: Coulées x = Porte x + 40).
	B.spawn(root, String(P.SPAWN_COULEES), P.PORTE_ENTREE.x, P.PORTE_ENTREE.y)
	B.exit(root, Rect2(23.0, H - 0.55, 3.0, 0.55), &"coulees_lave", P.SPAWN_PORTE)


static func _keep_clear() -> Array:
	var keep: Array = []
	for r: Rect2i in PLACES_NETTES:
		keep.append(Rect2(r).grow(1.0))
	for t: Vector2 in [P.CAILLOU, P.LACET_1, P.LACET_2, P.PORTE_ENTREE]:
		keep.append(Rect2(t - Vector2(3, 3), Vector2(6, 6)))
	return keep


static func _on_foot() -> Dictionary:
	return {
		"entrée": P.PORTE_ENTREE, "sortie vers les coulées": P.SORTIE_COULEES_PORTE - Vector2(0, 1), "premier lacet": P.LACET_1,
		"second lacet": P.LACET_2, "l'esplanade": P.ESPLANADE, "devant le portail": P.PORTAIL + Vector2(0, 1.4),
		"Isaure": P.ISAURE + Vector2(0, 1.2), "Maïa": P.MAIA + Vector2(0, 1.2), "Caillou": P.CAILLOU + Vector2(-1.5, 1.5),
		"le camp d'Hélène": P.CAMP_HELENE + Vector2(0, 1.2), "page 38": P.PAGE_38,
	}
