extends RefCounted
## La Terre des Apex (chapter 9), the crater, 80 x 70 tiles, built as `terre_apex` (painted by
## tools/zones/apex_canvas.gd, decor of apex_decor.gd, checks of apex_verif.gd; places in
## story/apex_places.gd). Through the portal of porte_cratere, Chloé comes in by the NORTH edge, on the
## rim's ledge (16.2 m, « le bord »): the crater lies below her, towards the camera (the camera looks
## north: the crater's walls all face it, nothing high stands south of a way). No lava: black rock, and in
## it veins of amber that glow on their own (the crystals along them are lit). The trail winds down in a
## spiral: west along the ledge, down the west wall (a ledge sloping 0.5 m a tile, the floor 4 to 12 m
## below it), round the floor (4 m) by the south and the east, to the hole in its middle (the fond, 5.5 m
## deep: the bloc in it, seen from above), and down a ramp along the hole's east side to coeur_apex (its
## exit at the ramp's foot). The ledge's east arm ends over the floor. Blocks of amber as big as houses,
## giants asleep in them (BlocGeant1..4); Hélène's last cairn at the edge, left of the way in (page 39);
## the Roi perched on the rim. Isaure and Maïa a few steps ahead at first (gone down once « apex_arrivee »).
## No wild dinos (the giants wake in the post-game: their scenes), no music (the breath of the crater).
## Build: --script res://tools/build_zone.gd -- apex_terre --force

const PATH := "res://regions/apex/terre_apex.tscn"
const RES_DIR := "res://regions/apex"
const B := preload("res://tools/zone_builder.gd")
const AC := preload("res://tools/zones/apex_canvas.gd")
const A := preload("res://tools/zones/apex_decor.gd")
const VD := preload("res://tools/zones/volcan_decor.gd")
const AV := preload("res://tools/zones/apex_verif.gd")
const P := preload("res://story/apex_places.gd")
const MUSIC := ["res://assets/audio/music/terre_apex.ogg"]
const W := 80
const H := 70
const SEED := 9123
const SALT := 91.0
## Heights (m): the ledge (the way in, the north of the crater and its east arm), the floor, the hole; the
## rim, high on the north (behind the ledge), low on the south (towards the camera: 2 m over the floor).
const H_BORD := 16.2
const H_FOND := 4.0
const H_TROU := -1.5
const H_RIM_NORD := 26.0
const H_RIM_SUD := 6.0
const RIM_DESCEND := Vector2i(30, 44)   # rows over which the rim comes down from high to low
## The crater (an ellipse: [centre, radii], the rim beyond it), its floor (inside it), the hole (the fond).
const CRATERE := [Vector2(40.0, 36.0), Vector2(37.0, 31.5)]
const PLANCHER := [Vector2(40.0, 38.0), Vector2(30.0, 26.0)]
const TROU := [Vector2(40.0, 44.0), Vector2(14.0, 9.5)]
## The way in, through the rim at the north edge, onto the ledge.
const ENTREE := Rect2i(35, 0, 11, 7)
## The west wall's sloping ledge: from the ledge's height at this row down to the floor's at that one.
const PENTE_OUEST := Vector2i(16, 40)
## The ledge's east arm ends at this row (south of it, the floor).
const BRAS_EST_FIN := 30
## The ramp into the hole along its east side (from the floor, northwards, down southwards), its foot.
const RAMPE := Rect2i(46, 36, 3, 8)
const PIED := Rect2i(46, 44, 3, 1)
const H_PIED := 0.0
## The veins of amber (tiles): from the hole out to the walls, along the ledge, up the east arm.
const VEINES := [
	[Vector2(27.0, 44.0), Vector2(20.0, 41.0), Vector2(13.0, 43.5)],
	[Vector2(53.5, 41.0), Vector2(60.0, 36.0), Vector2(67.0, 31.0)],
	[Vector2(35.0, 35.0), Vector2(32.0, 28.0), Vector2(26.0, 22.0), Vector2(22.0, 17.0)],
	[Vector2(45.0, 53.5), Vector2(48.0, 59.0), Vector2(55.0, 62.0)],
	[Vector2(30.0, 51.5), Vector2(24.0, 56.0), Vector2(17.0, 56.5)],
	[Vector2(44.0, 34.5), Vector2(46.5, 27.0), Vector2(51.0, 20.0), Vector2(53.0, 15.0)],
	[Vector2(29.0, 6.8), Vector2(35.0, 5.6), Vector2(45.5, 6.0), Vector2(53.0, 8.5), Vector2(60.0, 11.5)],
	[Vector2(63.0, 14.5), Vector2(69.0, 18.0), Vector2(70.0, 26.0)],
	[Vector2(14.5, 14.0), Vector2(9.0, 22.0), Vector2(6.0, 32.0)],
]
## Level and bare: the way in and the ledge's edge where the scene plays, the cairn, the ramp's top.
const PLACES_NETTES := [Rect2i(34, 1, 14, 11), Rect2i(30, 5, 6, 4), Rect2i(44, 32, 7, 4)]
## The proposed solid feet (px) of the pictures still to be drawn (docs/zones/apex.md): checked to fit.
const PIED_BLOC_GEANT := Vector2(260, 80)
const PIED_BLOC_PETIT := Vector2(190, 64)
const PIED_BLOC_SOUVERAIN := Vector2(480, 100)
const PIED_CAIRN := Vector2(44, 16)


static func build() -> Region:
	var c := AC.new(W, H, H_FOND, SALT)
	_paint(c)
	var root := c.apex_region(&"terre_apex", "Terre des Apex", "La Terre des Apex", Vector2i(50, 50), RES_DIR)
	A.climate(root, &"terre_apex", MUSIC, 0.05)
	var entities: Node2D = root.get_node("Entities")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_story(root, entities)
	A.crystals(c, entities, rng, VEINES, 9.5, _keep_clear())
	A.scatter(c, entities, rng, _keep_clear(), A.BLACK_ROCK, 0.8)
	B.hide_pebbles(root, entities, Vector2i(P.TERRE_ENTREE.floor()), 9131, 0, 1, [], [Vector2(70.0, 24.0), Vector2(14.0, 56.0)])
	_places(root)
	B.habitat(root, "La Terre des Apex", Rect2(0, 0, W, H), [], 0)   # (calm until the giants wake; its name on the map)
	var floating := AV.settle_all(root)
	AV.check(root, "Terre des Apex", Vector2i(P.TERRE_ENTREE.floor()), _on_foot(), floating, {
		"out": {"le fond (sol du trou)": P.FOND + Vector2(-6.0, 2.0), "le bloc vu d'en haut": P.BLOC_LOIN, "le perchoir du Roi": P.ROI_PERCHE,
			"la crête au nord-ouest": Vector2(20.0, 3.0), "le rebord sud": Vector2(40.0, 68.5)},
		"unreached_ok": ["RoiApex", "BlocLoin", "BlocLoinEclate", "SouverainLoin"],
		"footprints": _footprints(),
	})
	return root


static func _paint(c: AC) -> void:
	c.shape(func(_x: int, _y: int) -> bool: return true, func(x: int, y: int) -> float: return _height(c, x, y))
	for r: Rect2i in PLACES_NETTES:
		c.keep_level(r)
	c.keep_level(Rect2i(26, 34, 29, 20))   # (the hole: the bloc stands level in it)
	for t: Vector2 in P.BLOCS_GEANTS:
		c.keep_level(Rect2i(Vector2i(t.floor()) - Vector2i(4, 3), Vector2i(9, 5)))
	c.trail([Vector2(40.5, 0.0), Vector2(40.5, 5.0)], 3.0)
	c.trail(P.SPIRALE)
	c.ramp(RAMPE, "y", H_FOND, H_PIED)
	c.block(PIED, H_PIED)
	for x in range(PIED.position.x, PIED.end.x):
		c.ground[PIED.position.y * c.w + x] = "path"
	for pts: Array in VEINES:
		c.vein(pts, 1.1)
	c.finish(0.0)


## The relief: the rim beyond the crater (high behind the ledge, low on the south), the way in, the hole,
## the floor, and between the floor and the rim the ledge (north, its east arm) or the west wall's slope.
static func _height(c: AC, x: int, y: int) -> float:
	if ENTREE.has_point(Vector2i(x, y)):
		return H_BORD
	if not c.in_ellipse(x, y, CRATERE[0], CRATERE[1], 0.25):
		var k := smoothstep(float(RIM_DESCEND.x), float(RIM_DESCEND.y), float(y))
		var jitter := (AC.fbm(x * 0.21 + SALT, y * 0.21 + 3.0) - 0.5) * lerpf(1.2, 0.3, k)
		return lerpf(H_RIM_NORD, H_RIM_SUD, k) + jitter
	if c.in_ellipse(x, y, TROU[0], TROU[1], 0.0):
		return H_TROU
	if c.in_ellipse(x, y, PLANCHER[0], PLANCHER[1], 0.12):
		return H_FOND
	if x < CRATERE[0].x:
		if y < PENTE_OUEST.x:
			return H_BORD
		if y < PENTE_OUEST.y:
			return lerpf(H_BORD, H_FOND, float(y - PENTE_OUEST.x) / float(PENTE_OUEST.y - PENTE_OUEST.x))
		return H_FOND
	return H_BORD if y < BRAS_EST_FIN else H_FOND


## The people at the edge (gone down once the arrival is played), the cairn and page 39, the giants'
## blocks, the bloc seen from above in the hole (then what is left of it; then him, lying), the Roi.
static func _story(root: Region, entities: Node2D) -> void:
	A.person(root, "IsaureApex", "Isaure", ["isaure_sans_masque"], P.ISAURE_ARRIVEE, {"facing": "down", "event": &"isaure_apex",
		"hide_flag": &"apex_arrivee"})
	A.person(root, "MaiaApex", "Maïa", ["maia_arche"], P.MAIA_ARRIVEE, {"facing": "down", "event": &"maia_apex", "hide_flag": &"apex_arrivee"})
	B.dino_npc(root, "CaillouApex", &"triceratops", P.CAILLOU_ARRIVEE.x, P.CAILLOU_ARRIVEE.y, {"event": &"caillou_apex",
		"hide_flag": &"apex_arrivee", "flip": true})
	A.put(entities, A.CAIRN, P.CAIRN)
	A.page(entities, 39, P.PAGE_39)
	for i in P.BLOCS_GEANTS.size():
		A.story_prop(entities, A.BLOCS_GEANTS[i], P.BLOCS_GEANTS[i], "BlocGeant%d" % (i + 1), StringName("bloc_geant_%d" % (i + 1)),
			{"flip": i % 2 == 1})
	A.flagged(entities, A.BLOC_SOUVERAIN, P.BLOC_LOIN, "BlocLoin", &"", &"souverain_eveille")
	A.flagged(entities, A.BLOC_ECLATE, P.BLOC_LOIN, "BlocLoinEclate", &"souverain_eveille", &"")
	A.souverain(root, "SouverainLoin", P.SOUVERAIN_LOIN, {"show_flag": &"souverain_apaise"})
	B.dino_npc(root, "RoiApex", A.ROI, P.ROI_PERCHE.x, P.ROI_PERCHE.y, {"event": &"roi_apex", "size": A.ROI_SIZE, "flip": true,
		"hide_flag": &"apex_fini"})


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.TERRE_ENTREE.x, P.TERRE_ENTREE.y)
	# North: back through the portal to porte_cratere (it comes out before the portal: « DepuisApex »).
	B.spawn(root, String(P.SPAWN_PORTE), P.TERRE_ENTREE.x, P.TERRE_ENTREE.y)
	B.exit(root, Rect2(39.0, 0.0, 3.0, 0.55), &"porte_cratere", P.SPAWN_APEX)
	# The fond: down the ramp into coeur_apex (its north edge); back up, Chloé comes out at the ramp's top.
	B.spawn(root, String(P.SPAWN_COEUR), P.DEPUIS_COEUR.x, P.DEPUIS_COEUR.y)
	B.exit(root, Rect2(PIED.position.x - 0.1, PIED.position.y, PIED.size.x + 0.2, 0.6), &"coeur_apex", P.SPAWN_TERRE)


static func _keep_clear() -> Array:
	var keep: Array = []
	for r: Rect2i in PLACES_NETTES:
		keep.append(Rect2(r).grow(1.0))
	for t: Vector2 in P.BLOCS_GEANTS:
		keep.append(Rect2(t - Vector2(4.5, 3.0), Vector2(9.0, 5.5)))
	for t: Vector2 in [P.TERRE_ENTREE, P.DEPUIS_COEUR, P.RAMPE_HAUT, P.PIED_PAROI, P.CAIRN, P.ISAURE_ARRIVEE, P.MAIA_ARRIVEE,
			P.CAILLOU_ARRIVEE]:
		keep.append(Rect2(t - Vector2(2.5, 2.5), Vector2(5, 5)))
	return keep


static func _on_foot() -> Dictionary:
	var places := {
		"entrée": P.TERRE_ENTREE, "sortie vers la porte": P.SORTIE_PORTE_TERRE + Vector2(0.0, 0.6), "le bord": P.LE_BORD,
		"Isaure (arrivée)": P.ISAURE_ARRIVEE + Vector2(0.0, 1.0), "Maïa (arrivée)": P.MAIA_ARRIVEE + Vector2(0.0, 1.0),
		"Caillou (arrivée)": P.CAILLOU_ARRIVEE + Vector2(-2.4, 1.2), "le cairn": P.CAIRN + Vector2(1.2, 0.2), "page 39": P.PAGE_39,
		"pied de la paroi ouest": P.PIED_PAROI, "haut de la rampe": P.RAMPE_HAUT, "bas de la rampe": P.RAMPE_BAS,
		"sortie vers le cœur": P.SORTIE_COEUR, "retour du cœur": P.DEPUIS_COEUR,
	}
	for i in P.DEVANT_BLOCS.size():
		places["devant le bloc %d" % (i + 1)] = P.DEVANT_BLOCS[i]
	for i in range(1, P.SPIRALE.size()):
		places["spirale %d" % i] = P.SPIRALE[i]
	return places


static func _footprints() -> Dictionary:
	var out := {}
	for i in P.BLOCS_GEANTS.size():
		out["bloc_geant_%d" % (i + 1)] = [P.BLOCS_GEANTS[i], PIED_BLOC_PETIT if i == 3 else PIED_BLOC_GEANT]
	out["bloc_souverain (vu d'en haut)"] = [P.BLOC_LOIN, PIED_BLOC_SOUVERAIN]
	out["cairn_helene"] = [P.CAIRN, PIED_CAIRN]
	return out
