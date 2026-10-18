extends RefCounted
## Le Sanctuaire de Magma (chapter 8), 48 x 42 tiles, indoor, built as `sanctuaire_magma` (painted by
## tools/zones/volcan_canvas.gd, decor of volcan_decor.gd; places in story/volcan_places.gd). The faille's
## corridor climbs from the south edge (the way back to the coulées) into a round hall cut in black glass
## (obsidian), a ring of lava along its walls lighting it from below (none by the way in). At the
## corridor's mouth the warm spring (its water trembles before the T-Rex comes); in the middle the black
## altar (« AutelMagma »); at the back (north) the wall of glass with the lava running in it, the T-Rex de
## Magma before it (DinoNpc « TrexMagma », an Alpha: the scenes bring him through the wall); page 35 in a
## crack of the glass behind the altar, once he is beaten. Amber crystals glow round the hall. The walls
## of its south half are lower (the camera looks north over them into the hall). No wild dinos, no
## weather, no music (« trop calme »), a warm light (indoor, not a cave).
## Build: --script res://tools/build_zone.gd -- volcan_sanctuaire --force

const PATH := "res://regions/volcan/sanctuaire_magma.tscn"
const RES_DIR := "res://regions/volcan"
const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/volcan_canvas.gd")
const D := preload("res://tools/zones/volcan_decor.gd")
const V := preload("res://tools/zones/volcan_verif.gd")
const P := preload("res://story/volcan_places.gd")
const MUSIC := ["res://assets/audio/music/sanctuaire_magma.ogg"]
const W := 48
const H := 42
const SALT := 61.0
## Heights (m): the floor, the walls (north half, south half: lower, the camera sees over them).
const H_SOL := 0.0
const H_MUR_NORD := 4.8
const H_MUR_SUD := 1.8
const MUR_SUD_DES := 18
## The hall (an ellipse), its ring of lava (between the hall's rim and INNER), the corridor (x 23-25 from
## the south edge), the way in kept clear of lava.
const SALLE := [Vector2(24.0, 17.0), Vector2(14.0, 11.0)]
const INTERIEUR := Vector2(12.4, 9.4)
const COULOIR := Rect2i(23, 26, 3, 16)
const ENTREE_SANS_LAVE := Rect2i(18, 24, 13, 8)
## The T-Rex de Magma: his species' own size (an Alpha); ×1.4 of a smaller tyrannosaurid meanwhile.
const TREX_SIZE := 1.0
const TREX_STAND_IN_SIZE := 1.4
## Amber crystals round the hall: angles (degrees, 0 east, clockwise), at this share of INTERIEUR.
const CRISTAUX := [0.0, 35.0, 145.0, 180.0, 215.0, 325.0]
const CRISTAUX_RAYON := 0.86


static func build() -> Region:
	var c := C.new(W, H, H_SOL, SALT)
	_paint(c)
	var root := c.to_region(&"sanctuaire_magma", "Plaine Volcanique", "Le Sanctuaire de Magma", Vector2i(48, 48), RES_DIR,
		C.OBSIDIENNE_TEX)
	_climate(root)
	var entities: Node2D = root.get_node("Entities")
	_story(root, entities)
	_places(root)
	B.habitat(root, "Le Sanctuaire de Magma", Rect2(9, 5, 30, 24), [], 0)   # (its name on the map)
	var floating := V.settle_all(root)
	V.check(root, "Sanctuaire de Magma", Vector2i(P.SANCTUAIRE_ENTREE.floor()), _on_foot(), {}, floating)
	return root


static func _climate(root: Region) -> void:
	D.climate(root, &"sanctuaire_magma", MUSIC, 0.0)   # (no music drawn: silence, « trop calme »)
	root.indoor = true
	root.cave = false   # (indoor: a warm light, as by the lava; a cave's would be bluish)
	# No heat gauge here (MÉCANIQUES' meta « chaleur »): the scenes play by the lava, Chloé is not to step
	# back from it in the middle of them; the warm spring at the way in.
	root.set_meta(&"chaleur", 0.0)


static func _paint(c: C) -> void:
	var open := func(x: int, y: int) -> bool:
		return c.in_ellipse(x, y, SALLE[0], SALLE[1], 0.25) or COULOIR.has_point(Vector2i(x, y))
	c.mass(func(x: int, y: int) -> bool: return not open.call(x, y) and y < MUR_SUD_DES, H_MUR_NORD, 0.3)
	c.mass(func(x: int, y: int) -> bool: return not open.call(x, y) and y >= MUR_SUD_DES, H_MUR_SUD, 0.15)
	c.keep_level(Rect2i(0, 0, W, H))
	c.trail([Vector2(24.5, 42.0), Vector2(24.5, 27.0)], 3.0)
	c.lava_where(func(x: int, y: int) -> bool:
		return c.in_ellipse(x, y, SALLE[0], SALLE[1], 0.25) and not c.in_ellipse(x, y, SALLE[0], INTERIEUR, 0.0) \
			and not ENTREE_SANS_LAVE.has_point(Vector2i(x, y)))
	c.crust_banks(1)
	c.finish(0.0)


## The spring, the altar, the wall of glass, the T-Rex, page 35, the crystals.
static func _story(root: Region, entities: Node2D) -> void:
	D.put(entities, D.VASQUE, P.VASQUE)
	D.story_prop(entities, D.AUTEL, P.AUTEL_MAGMA, "AutelMagma", &"autel_magma",
		{"after_flag": &"trex_magma_battu", "after": ["autel_magma_fendu"]})
	D.put(entities, D.LAVE_PAROI, P.LAVE_PAROI)
	var trex := D.species(&"trex_magma", &"nanuqsaurus")
	B.dino_npc(root, "TrexMagma", trex, P.TREX_MAGMA.x, P.TREX_MAGMA.y, {"event": &"trex_magma",
		"size": TREX_SIZE if trex == &"trex_magma" else TREX_STAND_IN_SIZE})
	D.page(entities, 35, P.PAGE_35, &"trex_magma_battu")
	for a: float in CRISTAUX:
		var at: Vector2 = SALLE[0] + Vector2(cos(deg_to_rad(a)) * INTERIEUR.x, sin(deg_to_rad(a)) * INTERIEUR.y) * CRISTAUX_RAYON
		D.put(entities, ["cristaux"], at, a > 90.0 and a < 270.0)


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.SANCTUAIRE_ENTREE.x, P.SANCTUAIRE_ENTREE.y)
	# South: back down the faille to the coulées (Chloé comes out before it).
	B.spawn(root, String(P.SPAWN_COULEES), P.SANCTUAIRE_ENTREE.x, P.SANCTUAIRE_ENTREE.y)
	B.exit(root, Rect2(23.0, H - 0.55, 3.0, 0.55), &"coulees_lave", P.SPAWN_SANCTUAIRE)


static func _on_foot() -> Dictionary:
	return {
		"entrée": P.SANCTUAIRE_ENTREE, "sortie vers les coulées": P.SORTIE_COULEES_SANCTUAIRE - Vector2(0, 1),
		"la vasque": P.VASQUE + Vector2(0, 1), "la salle": P.SALLE + Vector2(0, 3), "l'autel": P.AUTEL_MAGMA + Vector2(0, 1.4),
		"le T-Rex": P.TREX_MAGMA + Vector2(0, 2.0), "page 35": P.PAGE_35, "où il se couche": P.TREX_COUCHE,
	}
