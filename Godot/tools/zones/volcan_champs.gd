extends RefCounted
## Les Champs de Cendre (chapter 8), the first zone of the Plaine Volcanique (90 x 70 tiles), built as
## `champs_cendres` (painted by tools/zones/volcan_canvas.gd, decor of volcan_decor.gd; places in
## story/volcan_places.gd). South: the Descente de Cendre, the Arche du Vent's ridge of cinders (its north
## edge, 14.4 m) going on as a hillside of ash down to the plain (6.4 m, row 48), the trail across it in
## lacets (an even slope, no step: the camera, looking north, sees over it). At its foot the first fire and
## Hélène's sign. The plain: grey ash in swells, burnt trunks, ash ferns (the Styracosaurus graze there
## by day); halfway north, the tracks round a flat stone (two hollows side by side; Caillou's a little
## further); then Numéro 3 at the foot of an open cage; in the north-east, the swell of an old flow gone
## cold (its crust: the Saichania's). North edge: the way to the forges. No lava here.
## Build: --script res://tools/build_zone.gd -- volcan_champs --force

const PATH := "res://regions/volcan/champs_cendres.tscn"
const RES_DIR := "res://regions/volcan"
const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/volcan_canvas.gd")
const D := preload("res://tools/zones/volcan_decor.gd")
const V := preload("res://tools/zones/volcan_verif.gd")
const P := preload("res://story/volcan_places.gd")
const MUSIC := ["res://assets/audio/music/volcan.ogg", "res://assets/audio/music/desert.ogg"]
const W := 90
const H := 70
const SEED := 8101
const SALT := 13.0
## Heights (m): the plain; the top of the Descente (the Arche's ridge at its north edge, 14.4 m).
const H_PLAINE := 6.4
const H_DESCENTE := 14.4
## The hillside: from the south edge (row H - 1) down to row PIED_ROW.
const PIED_ROW := 48
## The trail down in lacets, then north across the plain to the forges.
const LACETS := [Vector2(45.0, 70.0), Vector2(45.0, 66.0), Vector2(36.0, 63.5), Vector2(52.5, 58.5), Vector2(38.5, 53.5),
	Vector2(45.0, 49.5), Vector2(45.0, 46.0)]
const SENTIER := [Vector2(45.0, 46.0), Vector2(43.0, 37.0), Vector2(41.0, 31.0), Vector2(38.8, 24.0), Vector2(41.5, 13.0),
	Vector2(45.0, 5.0), Vector2(45.0, 0.0)]
## Swells of ash (dunes) and of old lava: [centre, radii, rise (m)].
const BOSSES := [
	[Vector2(18.0, 30.0), Vector2(10.0, 7.0), 1.4], [Vector2(24.0, 10.0), Vector2(9.0, 6.0), 1.1],
	[Vector2(70.0, 20.0), Vector2(14.0, 10.0), 0.8], [Vector2(63.0, 40.0), Vector2(8.0, 5.0), 0.9],
	[Vector2(8.0, 14.0), Vector2(7.0, 6.0), 1.0], [Vector2(80.0, 42.0), Vector2(8.0, 6.0), 1.2],
]
## The cooled flow of the north-east (its crust).
const CROUTE := [Vector2(70.0, 20.0), Vector2(13.0, 9.0)]
## Ferns of ash (tall grass: the hidden Styracosaurus): [centre, radii].
const TOUFFES := [
	[Vector2(18.0, 31.0), Vector2(4.0, 2.6)], [Vector2(25.0, 12.0), Vector2(3.4, 2.2)], [Vector2(60.0, 38.0), Vector2(3.0, 2.0)],
	[Vector2(30.0, 41.0), Vector2(3.0, 1.8)], [Vector2(76.0, 30.0), Vector2(2.6, 1.8)], [Vector2(9.0, 22.0), Vector2(2.8, 2.0)],
]
## Level and bare: the foot of the Descente (fire, sign), the tracks, Numéro 3's place.
const PLACES_NETTES := [Rect2i(42, 43, 11, 5), Rect2i(38, 26, 11, 7), Rect2i(32, 18, 7, 6)]


static func build() -> Region:
	var c := C.new(W, H, H_PLAINE, SALT)
	_paint(c)
	var root := c.to_region(&"champs_cendres", "Plaine Volcanique", "Les Champs de Cendre", Vector2i(42, 44), RES_DIR)
	_climate(root)
	var entities: Node2D = root.get_node("Entities")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_story(root, entities)
	D.scatter(c, entities, rng, _keep_clear(), D.ASH_FIELDS)
	D.fire(root, entities, c, P.FEU_CHAMPS)
	B.hide_pebbles(root, entities, Vector2i(P.ENTREE_ARCHE.floor()), 8113, 0, 5,
		[Vector2(14, 34), Vector2(72, 16), Vector2(26, 52)], [Vector2(6, 10), Vector2(84, 40), Vector2(58, 26)])
	_places(root)
	_habitats(root)
	# Every prop on the ground (none floating by a swell's side or on the hillside).
	var floating := V.settle_all(root)
	V.check(root, "Champs de Cendre", Vector2i(P.ENTREE_ARCHE.floor()), _on_foot(), {}, floating)
	return root


static func _climate(root: Region) -> void:
	# Ash in the air (a grey haze, now and then), never rain nor snow; no flight (the lava, the barricade).
	D.climate(root, &"champs_cendres", MUSIC, 0.14)


static func _paint(c: C) -> void:
	c.hillside(Vector2i(0, W), H - 1, H_DESCENTE, PIED_ROW, H_PLAINE)
	for b: Array in BOSSES:
		c.mound(b[0], b[1], b[2])
	for r: Rect2i in PLACES_NETTES:
		c.keep_level(r)
	c.trail(LACETS)
	c.trail(SENTIER)
	c.trail([Vector2(45.0, 70.0), Vector2(45.0, 67.0)], 3.0)
	c.crust_field(CROUTE[0], CROUTE[1])
	for t: Array in TOUFFES:
		c.tufts(t[0], t[1])
	c.finish(1.0, 0.25)


## The story's places and people (story/volcan.gd): the sign, the tracks and the flat stone, Caillou's
## hollow, Numéro 3 by his open cage, the overturned barrel.
static func _story(root: Region, entities: Node2D) -> void:
	B.sign(entities, B.cell(P.PANNEAU_CHAMPS.x, P.PANNEAU_CHAMPS.y), &"panneau_volcan_entree")
	B.trigger(root, P.TRACES.x, P.TRACES.y, 2.5, &"traces", {"once_flag": &"traces_vues", "name": "Traces"})
	D.story_prop(entities, D.PIERRE_PLATE, P.PIERRE_PLATE, "PierrePlate", &"pierre_plate")
	# Caillou's hollow in the ash, and the reeds he chewed (Prop « roseaux_secs »: dry reeds).
	D.put(entities, ["roseaux_secs", "fougere_cendre"], P.CREUX_CAILLOU)
	D.put(entities, ["roseaux_secs", "fougere_cendre"], P.CREUX_CAILLOU + Vector2(1.1, 0.4), true)
	D.story_prop(entities, D.CAGE_OUVERTE, P.CAGE_OUVERTE, "CageOuverte", &"cage_ouverte")
	D.story_prop(entities, D.FUT_RENVERSE, P.FUT_RENVERSE, "FutRenverse", &"fut_renverse", {"flip": true})
	B.dino_npc(root, "Numero3", D.species(&"styracosaurus", &"pachyrhinosaurus"), P.NUMERO_3.x, P.NUMERO_3.y,
		{"event": &"numero_3", "corrupted": true, "hide_flag": &"premier_corrompu_volcan"})


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.ENTREE_ARCHE.x, P.ENTREE_ARCHE.y)
	# South: back up the Descente to the Arche du Vent (its north edge, x 19-21: Arche x = Champs x - 25).
	B.spawn(root, String(P.SPAWN_ARCHE), P.ENTREE_ARCHE.x, P.ENTREE_ARCHE.y)
	B.exit(root, Rect2(43.5, H - 0.55, 3.0, 0.55), &"arche_du_vent", P.SPAWN_DEPUIS_VOLCAN)
	# North: the forges (their south edge, x 39-42: Forges x = Champs x - 4.5).
	B.spawn(root, String(P.SPAWN_FORGES), P.DEPUIS_FORGES.x, P.DEPUIS_FORGES.y)
	B.exit(root, Rect2(43.5, 0.0, 3.0, 0.55), &"forges_ombre", P.SPAWN_CHAMPS)


static func _habitats(root: Region) -> void:
	# The widest first (where they overlap, the last one listed wins).
	B.habitat(root, "Les Champs de Cendre", Rect2(0, 0, W, PIED_ROW), D.known([
		[&"styracosaurus", 42, 44, 10, "jour", false], [&"styracosaurus", 42, 44, 6, "jour", true],
		[&"saichania", 43, 44, 3, "jour", false],
	]), 3)
	B.habitat(root, "Les Coulées refroidies", Rect2(56, 8, 32, 24), D.known([
		[&"saichania", 43, 45, 10, "jour", false], [&"styracosaurus", 42, 44, 3, "jour", false],
	]), 2)
	# Calm (its name on the map): the Descente.
	B.habitat(root, "La Descente de Cendre", Rect2(0, PIED_ROW, W, H - PIED_ROW), [], 0)


## Where nothing is scattered (tiles): the places, the story's things.
static func _keep_clear() -> Array:
	var keep: Array = []
	for r: Rect2i in PLACES_NETTES:
		keep.append(Rect2(r).grow(1.0))
	for t: Vector2 in [P.PANNEAU_CHAMPS, P.FEU_CHAMPS, P.TRACES, P.PIERRE_PLATE, P.CREUX_CAILLOU, P.NUMERO_3, P.CAGE_OUVERTE,
			P.FUT_RENVERSE, P.ENTREE_ARCHE, P.DEPUIS_FORGES]:
		keep.append(Rect2(t - Vector2(2.5, 2.5), Vector2(5, 5)))
	return keep


static func _on_foot() -> Dictionary:
	return {
		"arrivée (la Descente)": P.ENTREE_ARCHE, "sortie vers l'Arche": P.SORTIE_ARCHE - Vector2(0, 1), "les lacets": P.DESCENTE,
		"pied de la Descente": P.PIED_DESCENTE, "le feu": P.FEU_CHAMPS + Vector2(1.5, 0), "le panneau": P.PANNEAU_CHAMPS + Vector2(0, 1),
		"les traces": P.TRACES, "la pierre plate": P.PIERRE_PLATE + Vector2(0, 1), "le creux de Caillou": P.CREUX_CAILLOU + Vector2(0, 1),
		"Numéro 3": P.NUMERO_3 + Vector2(0, 1.5), "les coulées refroidies": P.COULEES_REFROIDIES, "les dunes": P.DUNES,
		"sortie vers les forges": P.SORTIE_FORGES,
	}
