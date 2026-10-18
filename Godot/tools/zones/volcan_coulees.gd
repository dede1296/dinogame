extends RefCounted
## Les Coulées de lave (chapter 8), 80 x 60 tiles, built as `coulees_lave` (painted by
## tools/zones/volcan_canvas.gd, decor of volcan_decor.gd; places in story/volcan_places.gd). Black rock
## between rivers of lava, the volcano's flank along the north edge (16 m, its face to the camera).
## South: the way in from the forges' platform (9.4 m), a fire, the cooled flows west and east (their
## crust: the Saichania's, by day). Across the whole zone, THE FIRST FLOW (rows ~40-43): nobody goes
## further on foot; its trigger « PremiereCoulee » and Hélène's sign on its south bank. Beyond it (on a
## stone or fire dino, the mechanic B): two branches of lava coming down from the flank, a lake of lava
## with a black rock in its middle (page 36 in an iron box: only on such a dino), the Daspletosaurus at
## night; the faille into the sanctuary at the back of its notch in the flank (a CaveMouth; the engraving
## beside it); north-east, the crater path cut up the flank to the north edge, its exit closed until
## « lave_retiree ». THE LAVA: see tools/zones/volcan_canvas.gd (meta « lave »).
## Build: --script res://tools/build_zone.gd -- volcan_coulees --force

const PATH := "res://regions/volcan/coulees_lave.tscn"
const RES_DIR := "res://regions/volcan"
const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/volcan_canvas.gd")
const D := preload("res://tools/zones/volcan_decor.gd")
const V := preload("res://tools/zones/volcan_verif.gd")
const P := preload("res://story/volcan_places.gd")
const MUSIC := ["res://assets/audio/music/volcan.ogg", "res://assets/audio/music/desert.ogg"]
const W := 80
const H := 60
const SEED := 8317
const SALT := 47.0
## Heights (m): the way in (the forges' platform), the rock rising a little towards the flank, the flank;
## the crater path from its foot to the north edge (porte_cratere's way in).
const H_ENTREE := 9.4
const H_FLANC_PIED := 9.8
const H_FLANC := 16.0
const H_CRATERE := 12.6
## The flank's ragged foot (row), squared by the faille and the crater path.
const FLANC_PIED := 9
const FLANC_DROIT := 12
## The rock rises gently from this row (the first flow's north bank) to the flank's foot.
const PENTE_PIED := 38
const FLANC_DROIT_COLS: Array[Vector2i] = [Vector2i(35, 47), Vector2i(59, 70)]
const ENCOCHE_FAILLE := Rect2i(39, 8, 3, 4)
const CHEMIN_CRATERE := Rect2i(63, 0, 3, 12)
## The lava that goes back (« lave_retiree »): it fills the lower part of the cut, nobody passes it until
## then, not even on a stone or fire dino (MÉCANIQUES' meta « lave_retrait »).
const LAVE_RETRAIT := Rect2i(63, 4, 3, 7)
## The lava: the first flow across the zone, its two branches from the flank, the lake and its rock.
const PREMIERE := [Vector2(-1.0, 41.5), Vector2(12.0, 40.5), Vector2(26.0, 42.0), Vector2(40.5, 41.2), Vector2(54.0, 42.5),
	Vector2(68.0, 41.0), Vector2(81.0, 41.8)]
const PREMIERE_LARGEUR := 3.4
const BRANCHES := [
	[Vector2(17.0, 12.5), Vector2(20.0, 20.0), Vector2(16.0, 30.0), Vector2(21.0, 40.5)],
	[Vector2(61.0, 17.5), Vector2(57.0, 26.0), Vector2(62.0, 33.0), Vector2(58.0, 40.5)],
]
const BRANCHE_LARGEUR := 2.6
const LAC := [Vector2(29.5, 27.5), Vector2(6.5, 4.6)]
const ROCHER := [Vector2(29.5, 27.3), Vector2(2.3, 1.8)]
const SENTIERS := [
	[Vector2(40.5, 60.0), Vector2(40.5, 12.0)], [Vector2(40.5, 28.5), Vector2(37.0, 28.2)],
	[Vector2(40.5, 14.0), Vector2(52.0, 14.6), Vector2(64.5, 13.0), Vector2(64.5, 11.0)],
]
## Swells of old lava (low).
const BOSSES := [[Vector2(14.0, 52.0), Vector2(9.0, 5.0), 0.6], [Vector2(66.0, 53.0), Vector2(9.0, 5.0), 0.6],
	[Vector2(50.0, 24.0), Vector2(6.0, 5.0), 0.5], [Vector2(8.0, 24.0), Vector2(6.0, 6.0), 0.6]]
## Level and bare: the way in, the fire, the first flow's bank, the rock in the lake, before the faille.
const PLACES_NETTES := [Rect2i(36, 50, 10, 8), Rect2i(37, 43, 8, 4), Rect2i(27, 25, 5, 5), Rect2i(37, 12, 7, 3),
	Rect2i(61, 11, 7, 3)]


static func build() -> Region:
	var c := C.new(W, H, H_ENTREE, SALT)
	_paint(c)
	var root := c.to_region(&"coulees_lave", "Plaine Volcanique", "Les Coulées de lave", Vector2i(44, 47), RES_DIR, C.ROCHE_TEX,
		C.CENDRE_TEX)
	_climate(root)
	var entities: Node2D = root.get_node("Entities")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	D.fire(root, entities, c, P.FEU_COULEES)
	_story(root, entities)
	D.scatter(c, entities, rng, _keep_clear(), D.BLACK_ROCK)
	B.hide_pebbles(root, entities, Vector2i(P.ENTREE_COULEES.floor()), 8329, 0, 3, [Vector2(10, 49), Vector2(70, 29)],
		[Vector2(20, 55), Vector2(60, 56), Vector2(50, 21)])
	_places(root)
	_habitats(root)
	var floating := V.settle_all(root)
	V.check(root, "Coulées de lave", Vector2i(P.ENTREE_COULEES.floor()), _on_foot(), _mounted(), floating,
		{"after_retreat": {"le chemin du cratère": P.LAVE_CRATERE, "sortie vers la porte": P.SORTIE_PORTE}})
	return root


static func _climate(root: Region) -> void:
	D.climate(root, &"coulees_lave", MUSIC, 0.08)


static func _paint(c: C) -> void:
	c.hillside(Vector2i(0, W), FLANC_DROIT, H_FLANC_PIED, PENTE_PIED, H_ENTREE)
	for b: Array in BOSSES:
		c.mound(b[0], b[1], b[2])
	c.mass(func(x: int, y: int) -> bool: return y < _flank_foot(x), H_FLANC, 0.8)
	c.block(ENCOCHE_FAILLE, H_FLANC_PIED)
	# The crater path: up the cut to the north edge, its top row at H_CRATERE (ramp(): (to - from) * n / (n + 1)).
	var n := CHEMIN_CRATERE.size.y
	c.ramp(CHEMIN_CRATERE, "-y", H_FLANC_PIED, H_FLANC_PIED + (H_CRATERE - H_FLANC_PIED) * (n + 1.0) / n)
	for r: Rect2i in PLACES_NETTES:
		c.keep_level(r)
	for pts: Array in SENTIERS:
		c.trail(pts)
	c.trail([Vector2(40.5, 60.0), Vector2(40.5, 57.0)], 3.0)
	# The lava, once the relief is done (it runs sunk in it).
	c.lava_river(PREMIERE, PREMIERE_LARGEUR)
	for pts: Array in BRANCHES:
		c.lava_river(pts, BRANCHE_LARGEUR)
	c.lava_pool(LAC[0], LAC[1], ROCHER)
	c.lava_retreat(func(x: int, y: int) -> bool: return LAVE_RETRAIT.has_point(Vector2i(x, y)))
	c.crust_banks(2)
	c.crust_field(P.COULEES_REFROIDIES_OUEST, Vector2(11.0, 5.0))
	c.crust_field(P.COULEES_REFROIDIES_EST, Vector2(11.0, 5.0))
	c.finish(0.3, 0.6)


## The flank's foot at column `x` (rows above it are the flank): ragged, straight by the faille and the
## crater path.
static func _flank_foot(x: int) -> int:
	for cols: Vector2i in FLANC_DROIT_COLS:
		if x >= cols.x and x < cols.y:
			return FLANC_DROIT
	return FLANC_PIED + int(C.fbm(x * 0.13 + 5.0, 1.7) * 3.0)


## The story's places (story/volcan_sanctuaire.gd): the first flow's trigger and sign, page 36 on its
## rock, the faille (a dark opening in the flank) and its engraving.
static func _story(root: Region, entities: Node2D) -> void:
	B.trigger(root, P.PREMIERE_COULEE.x, P.PREMIERE_COULEE.y, 2.0, &"premiere_coulee", {"once_flag": &"lave_franchie",
		"name": "PremiereCoulee"})
	B.sign(entities, B.cell(P.PANNEAU_LAVE.x, P.PANNEAU_LAVE.y), &"panneau_lave")
	D.page(entities, 36, P.PAGE_36)
	D.put(entities, ["boite_fer"], P.ROCHER_36 + Vector2(0.9, -0.5))
	var mouth := CaveMouth.new()
	mouth.name = "Faille"
	mouth.width = 1.6
	mouth.height = 3.4
	mouth.position = B.cell(P.FAILLE.x, P.FAILLE.y)
	entities.add_child(mouth)
	D.sign_of(entities, "pierre_gravee", P.GRAVURE_FAILLE, &"gravure_faille", "GravureFaille")


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.ENTREE_COULEES.x, P.ENTREE_COULEES.y)
	# South: back to the forges' platform (its north edge, x 55-57: Forges x = Coulées x + 16).
	B.spawn(root, String(P.SPAWN_FORGES), P.ENTREE_COULEES.x, P.ENTREE_COULEES.y)
	B.exit(root, Rect2(39.0, H - 0.55, 3.0, 0.55), &"forges_ombre", P.SPAWN_COULEES)
	# The faille: into the sanctuary; Chloé comes back out before it.
	B.spawn(root, String(P.SPAWN_SANCTUAIRE), P.DEVANT_FAILLE.x, P.DEVANT_FAILLE.y)
	B.exit(root, Rect2(P.FAILLE.x - 0.8, P.FAILLE.y - 0.05, 1.6, 0.5), &"sanctuaire_magma", P.SPAWN_COULEES)
	# North-east: up the crater path to the portal (its south edge, x 23-25: Porte x = Coulées x - 40), once
	# the lava has gone back.
	B.spawn(root, String(P.SPAWN_PORTE), P.DEPUIS_PORTE.x, P.DEPUIS_PORTE.y)
	B.exit(root, Rect2(63.0, 0.0, 3.0, 0.55), &"porte_cratere", P.SPAWN_COULEES, &"lave_retiree", &"cratere_bloque")


static func _habitats(root: Region) -> void:
	B.habitat(root, "Les Coulées de lave", Rect2(0, 12, W, 32), D.known([
		[&"daspletosaurus", 45, 47, 10, "nuit", false], [&"saichania", 43, 45, 4, "jour", false],
	]), 2)
	B.habitat(root, "Les Coulées refroidies", Rect2(0, 44, W, H - 44), D.known([
		[&"saichania", 43, 45, 10, "jour", false], [&"daspletosaurus", 45, 47, 3, "nuit", false],
	]), 2)
	# Calm (their names on the map): before the faille, the crater path.
	B.habitat(root, "La Faille", Rect2(33, 4, 15, 9), [], 0)
	B.habitat(root, "Le Chemin du Cratère", Rect2(58, 0, 14, 12), [], 0)


static func _keep_clear() -> Array:
	var keep: Array = []
	for r: Rect2i in PLACES_NETTES:
		keep.append(Rect2(r).grow(1.0))
	for t: Vector2 in [P.PANNEAU_LAVE, P.FEU_COULEES, P.PREMIERE_COULEE, P.GRAVURE_FAILLE, P.DEVANT_FAILLE, P.PIED_CHEMIN_CRATERE,
			P.ENTREE_COULEES]:
		keep.append(Rect2(t - Vector2(2.5, 2.5), Vector2(5, 5)))
	return keep


static func _on_foot() -> Dictionary:
	return {
		"entrée": P.ENTREE_COULEES, "sortie vers les forges": P.SORTIE_FORGES_COULEES - Vector2(0, 1), "le feu": P.FEU_COULEES + Vector2(1.5, 0),
		"la première coulée (sa rive)": P.PREMIERE_COULEE, "le panneau": P.PANNEAU_LAVE + Vector2(0, 1),
		"coulées refroidies (ouest)": P.COULEES_REFROIDIES_OUEST, "coulées refroidies (est)": P.COULEES_REFROIDIES_EST,
	}


static func _mounted() -> Dictionary:
	return {
		"au-delà de la première coulée": P.PREMIERE_COULEE_TRAVERSEE - Vector2(0, 3), "les coulées": P.COULEES,
		"le rocher de la page 36": P.PAGE_36, "devant la faille": P.DEVANT_FAILLE, "la faille (sortie)": P.FAILLE + Vector2(0, 0.2),
		"la gravure": P.GRAVURE_FAILLE + Vector2(0, 1), "pied du chemin du cratère": P.PIED_CHEMIN_CRATERE,
		"les Daspletosaurus": P.DASPLETOS,
	}
