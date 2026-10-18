extends RefCounted
## Les Forges de l'Ombre (chapter 8), 80 x 60 tiles, built as `forges_ombre` (painted by
## tools/zones/volcan_canvas.gd, decor of volcan_decor.gd; places in story/volcan_places.gd). The camp of
## the Ombre Noire in a hollow of ash at the volcano's foot (6.4 m): the way in from the fields at the
## south edge, Léonce and two more masks sitting by the barrels, the three small forges (west, north-west,
## east), each guarded by its numbered dino, cages (most of them empty), barrels of black amber, tents.
## At the back (north) a platform of rock (9.4 m, its face to the camera): a notch cut in its face climbs
## to it, closed by the barricade of cages until « barricade_tombee »; on it, Brac's camp at the top of the
## notch (his fire, his pot, his three dinos, Fournaise in a pen), and at the very back the grande forge,
## a tower of black brick, Dame Suie's bench at its foot. From the platform, the way north to the coulées
## (closed until « suie_partie »). The volcano's foot (13 m, out of reach) along the north edge.
## Build: --script res://tools/build_zone.gd -- volcan_forges --force

const PATH := "res://regions/volcan/forges_ombre.tscn"
const RES_DIR := "res://regions/volcan"
const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/volcan_canvas.gd")
const D := preload("res://tools/zones/volcan_decor.gd")
const V := preload("res://tools/zones/volcan_verif.gd")
const P := preload("res://story/volcan_places.gd")
const CHARS := "res://assets/art/characters/%s.png"
const MUSIC := ["res://assets/audio/music/forges_ombre.ogg", "res://assets/audio/music/ombre.ogg"]
const W := 80
const H := 60
const SEED := 8209
const SALT := 29.0
## Heights (m): the camp, the platform, the volcano's foot.
const H_CAMP := 6.4
const H_PLATEAU := 9.4
const H_PIED := 13.0
## The platform (an ellipse; the notch's sides squared), the notch (its ramp), the way north.
const PLATEAU := [Vector2(40.0, 14.0), Vector2(21.0, 10.5)]
const PLATEAU_FOND := Rect2i(19, 4, 43, 8)
const AUTOUR_ENCOCHE := Rect2i(35, 19, 11, 6)
const ENCOCHE := Rect2i(39, 20, 3, 5)
const PASSAGE := Rect2i(55, 0, 3, 8)
const PIED_ROWS := 4
const SENTIERS := [
	[Vector2(40.5, 60.0), Vector2(40.5, 25.0)],
	[Vector2(40.5, 47.0), Vector2(28.0, 44.6), Vector2(18.6, 44.0)], [Vector2(28.0, 44.6), Vector2(27.6, 36.4)],
	[Vector2(40.5, 44.0), Vector2(52.0, 41.6), Vector2(61.0, 41.0)],
	[Vector2(40.5, 20.0), Vector2(40.6, 14.0), Vector2(45.0, 13.0), Vector2(54.0, 13.0), Vector2(56.5, 11.0), Vector2(56.5, 0.0)],
]
## Level and bare: round each forge, the barricade, Brac's camp, Dame Suie's corner, the way in.
const PLACES_NETTES := [
	Rect2i(12, 38, 9, 8), Rect2i(23, 29, 8, 8), Rect2i(59, 34, 9, 8), Rect2i(35, 25, 12, 3), Rect2i(33, 13, 16, 8),
	Rect2i(42, 7, 14, 6), Rect2i(36, 48, 14, 9),
]
## Swells at the camp's sides (ash heaped by the wind).
const BOSSES := [[Vector2(8.0, 52.0), Vector2(8.0, 6.0), 0.9], [Vector2(72.0, 22.0), Vector2(8.0, 7.0), 1.1],
	[Vector2(8.0, 18.0), Vector2(7.0, 8.0), 1.0], [Vector2(72.0, 54.0), Vector2(7.0, 5.0), 0.8]]
## The decor of the camp: cages, barrels of black amber, tents ([wanted, tile, flip]).
const CAMP := [
	[D.CAGE_OUVERTE, Vector2(30.0, 47.4), false], [D.CAGE, Vector2(32.8, 47.8), true], [D.CAGE_OUVERTE, Vector2(54.6, 45.2), false],
	[D.CAGE_OUVERTE, Vector2(57.4, 45.8), true], [D.CAGE_OUVERTE, Vector2(20.8, 51.0), false], [D.CAGE, Vector2(61.0, 52.4), true],
	[D.FUT, Vector2(35.2, 40.4), false], [D.FUT, Vector2(36.6, 41.0), true], [D.FUT, Vector2(52.4, 31.6), false],
	[D.FUT, Vector2(11.4, 47.0), true], [D.FUT, Vector2(58.8, 31.0), false], [D.FUT, Vector2(45.4, 49.4), false],
	[D.FUT, Vector2(48.8, 46.0), true], [D.FUT, Vector2(51.2, 49.8), false],
	[["tente"], Vector2(8.6, 31.0), false], [["tente"], Vector2(71.4, 46.0), true],
	[D.ENCLUME, P.FORGE_1 + Vector2(-2.0, 0.6), false], [D.ENCLUME, P.FORGE_2 + Vector2(2.2, 0.4), true],
	[D.ENCLUME, P.FORGE_3 + Vector2(-2.2, 0.4), false],
	[D.AUVENT, P.FORGE_1 + Vector2(0.0, -0.4), false], [D.AUVENT, P.FORGE_2 + Vector2(0.0, -0.4), false],
	[D.AUVENT, P.FORGE_3 + Vector2(0.0, -0.4), false],
]
## The palisades of burnt planks along the camp's sides (never south of a way: the camera).
const PALISSADES := [Vector2(3.4, 30.0), Vector2(3.4, 33.0), Vector2(3.6, 36.0), Vector2(3.4, 39.0), Vector2(76.4, 30.0),
	Vector2(76.6, 33.0), Vector2(76.4, 36.0), Vector2(76.6, 39.0), Vector2(18.2, 25.6), Vector2(21.0, 25.4), Vector2(59.0, 25.4),
	Vector2(61.8, 25.6)]
## Fournaise's pen: palisades behind and on the sides, a fence in front (gone once « brac_volcan_vu »).
const ENCLOS := [Vector2(49.8, 15.6), Vector2(52.0, 15.4), Vector2(54.2, 15.6), Vector2(49.2, 17.2), Vector2(54.8, 17.2)]


static func build() -> Region:
	var c := C.new(W, H, H_CAMP, SALT)
	_paint(c)
	var root := c.to_region(&"forges_ombre", "Plaine Volcanique", "Les Forges de l'Ombre", Vector2i(43, 46), RES_DIR)
	_climate(root)
	var entities: Node2D = root.get_node("Entities")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	D.fire(root, entities, c, P.FEU_FORGES)
	D.fire(root, entities, c, P.FEU_BRAC)
	_camp(entities)
	_forges(root, entities)
	_brac(root, entities)
	_suie(root, entities)
	D.scatter(c, entities, rng, _keep_clear(), D.ASH_FIELDS, 0.6)
	B.hide_pebbles(root, entities, Vector2i(P.ENTREE_FORGES.floor()), 8221, 0, 3, [Vector2(10, 22), Vector2(70, 26)],
		[Vector2(74, 50), Vector2(28, 16)])
	_places(root)
	_habitats(root)
	var floating := V.settle_all(root)
	V.check(root, "Forges de l'Ombre", Vector2i(P.ENTREE_FORGES.floor()), _on_foot(), {}, floating, {"may_block": ["Barricade"],
		"closed": {"Barricade": [P.RAMPE_PLATEAU, P.BRAC, P.SUIE, P.SORTIE_COULEES]}})
	return root


static func _climate(root: Region) -> void:
	D.climate(root, &"forges_ombre", MUSIC, 0.1)


static func _paint(c: C) -> void:
	for b: Array in BOSSES:
		c.mound(b[0], b[1], b[2])
	c.plateau(PLATEAU[0], PLATEAU[1], H_PLATEAU, 0.4)
	c.block(PLATEAU_FOND, H_PLATEAU, false)   # (its back up to the volcano's foot: no hollow behind it)
	c.block(AUTOUR_ENCOCHE, H_PLATEAU, false)
	c.mass(func(x: int, y: int) -> bool: return y < PIED_ROWS + int(C.fbm(x * 0.3, 2.0) * 2.0) and not PASSAGE.has_point(Vector2i(x, y)),
		H_PIED, 0.5)
	c.block(PASSAGE, H_PLATEAU)
	c.ramp(ENCOCHE, "-y", H_CAMP, H_PLATEAU)
	for r: Rect2i in PLACES_NETTES:
		c.keep_level(r)
	for pts: Array in SENTIERS:
		c.trail(pts)
	c.trail([Vector2(40.5, 60.0), Vector2(40.5, 57.0)], 3.0)
	c.finish(0.8, 0.3)


## The camp's decor: cages, barrels, tents, anvils and awnings (once drawn), the palisades, the masks
## sitting by the barrels and Léonce (all gone once the grande forge is out).
static func _camp(entities: Node2D) -> void:
	for p: Array in CAMP:
		D.put(entities, p[0], p[1], p[2])
	for t: Vector2 in PALISSADES:
		D.put(entities, ["palissade", "cloture"], t, int(t.x * 10.0) % 3 == 0)
	var root := entities.get_parent() as Region
	B.npc(root, "Leonce", "Léonce", CHARS % "sbire", P.LEONCE.x, P.LEONCE.y, {"facing": "left", "event": &"leonce",
		"hide_flag": &"grande_forge_eteinte"})
	for i in P.MASQUES_OS.size():
		var at: Vector2 = P.MASQUES_OS[i]
		B.npc(root, "MasqueOs%d" % (i + 1), "Masque d'os", CHARS % "sbire", at.x, at.y, {"facing": "down" if i == 0 else "left",
			"event": &"masques_os", "hide_flag": &"grande_forge_eteinte"})


## The three small forges (StoryProps, out once their flag is set: their « forge_eteinte » picture once
## drawn), their guards (gone once calmed), the bellows of the second, the big barrel by the third.
static func _forges(root: Region, entities: Node2D) -> void:
	var forges := [[P.FORGE_1, "Forge1", &"forge_1", &"forge_1_eteinte"], [P.FORGE_2, "Forge2", &"forge_2", &"forge_2_eteinte"],
		[P.FORGE_3, "Forge3", &"forge_3", &"forge_3_eteinte"]]
	for i in forges.size():
		var f: Array = forges[i]
		D.story_prop(entities, D.FORGE, f[0], f[1], f[2], {"after_flag": f[3], "after": D.FORGES_ETEINTES[i]})
	B.dino_npc(root, "Numero7", D.species(&"saichania", &"pinacosaurus"), P.NUMERO_7.x, P.NUMERO_7.y,
		{"event": &"numero_7", "corrupted": true, "hide_flag": &"forge_1_eteinte"})
	B.dino_npc(root, "Numero11", &"allosaurus", P.NUMERO_11.x, P.NUMERO_11.y,
		{"event": &"numero_11", "corrupted": true, "hide_flag": &"forge_2_eteinte", "flip": true})
	B.dino_npc(root, "Numero12", &"majungasaurus", P.NUMERO_12.x, P.NUMERO_12.y,
		{"event": &"numero_12", "corrupted": true, "hide_flag": &"forge_3_eteinte"})
	D.flagged(entities, D.SOUFFLET, P.SOUFFLET, "Soufflet", &"", &"forge_2_eteinte")
	D.flagged(entities, D.FUT, P.FUT_FORGE_3, "FutForge3", &"", &"forge_3_eteinte", true)


## The barricade closing the notch, Brac's camp on the platform (his people gone once « brac_parti »),
## Fournaise's pen, the mask he throws in the ash.
static func _brac(root: Region, entities: Node2D) -> void:
	D.story_prop(entities, D.BARRICADE, P.BARRICADE, "Barricade", &"barricade", {"hide_flag": &"barricade_tombee"})
	D.flagged(entities, D.BARRICADE_TOMBEE, P.BARRICADE_TOMBEE, "BarricadeTombee", &"barricade_tombee", &"")
	B.npc(root, "BracVolcan", "Brac", CHARS % "brac", P.BRAC.x, P.BRAC.y, {"facing": "down", "event": &"brac_volcan",
		"hide_flag": &"brac_parti"})
	D.put(entities, D.MARMITE, P.MARMITE)
	D.put(entities, ["tente"], P.TENTE_BRAC, true)
	for d: Array in [["Mastoc", &"allosaurus", P.MASTOC, true], ["Cabosse", &"stygimoloch", P.CABOSSE, false],
			["Grognon", &"majungasaurus", P.GROGNON, true]]:
		B.dino_npc(root, d[0], d[1], d[2].x, d[2].y, {"flip": d[3], "hide_flag": &"brac_parti"})
	for t: Vector2 in ENCLOS:
		D.put(entities, ["palissade", "cloture"], t, t.x > P.FOURNAISE.x)
	D.flagged(entities, ["cloture"], P.FOURNAISE + Vector2(0.0, 1.8), "EnclosFournaise", &"", &"brac_volcan_vu")
	B.dino_npc(root, "Fournaise", D.species(&"daspletosaurus", &"nanuqsaurus"), P.FOURNAISE.x, P.FOURNAISE.y,
		{"corrupted": true, "flip": true, "hide_flag": &"brac_parti"})
	D.story_prop(entities, D.MASQUE_OS, P.MASQUE_BRAC, "MasqueBrac", &"masque_brac", {"show_flag": &"brac_parti"})


## Dame Suie's corner at the foot of the grande forge (her people and things gone once « suie_partie »,
## her gloves left on the bench then).
static func _suie(root: Region, entities: Node2D) -> void:
	D.story_prop(entities, D.GRANDE_FORGE, P.GRANDE_FORGE, "GrandeForge", &"grande_forge",
		{"after_flag": &"grande_forge_eteinte", "after": ["grande_forge_eteinte"]})
	D.story_prop(entities, D.ETABLI, P.ETABLI, "Etabli", &"etabli")
	D.put(entities, D.FIOLES, P.FIOLES)
	D.flagged(entities, D.GANTS, P.GANTS, "Gants", &"suie_partie", &"")
	D.flagged(entities, D.TRAINEAU, P.TRAINEAU, "Traineau", &"", &"suie_partie", true)
	B.npc(root, "SuieVolcan", "Dame Suie", CHARS % "dame_suie", P.SUIE.x, P.SUIE.y, {"facing": "down", "event": &"suie_volcan",
		"hide_flag": &"suie_partie"})
	B.dino_npc(root, "Mandragore", &"therizinosaurus", P.MANDRAGORE.x, P.MANDRAGORE.y, {"flip": true, "hide_flag": &"suie_partie"})


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.ENTREE_FORGES.x, P.ENTREE_FORGES.y)
	# South: back to the fields (their north edge, x 44-46).
	B.spawn(root, String(P.SPAWN_CHAMPS), P.ENTREE_FORGES.x, P.ENTREE_FORGES.y)
	B.exit(root, Rect2(39.0, H - 0.55, 3.0, 0.55), &"champs_cendres", P.SPAWN_FORGES)
	# North, from the platform: the coulées (their south edge, x 39-41), once Dame Suie has gone.
	B.spawn(root, String(P.SPAWN_COULEES), P.DEPUIS_COULEES_FORGES.x, P.DEPUIS_COULEES_FORGES.y)
	B.exit(root, Rect2(55.0, 0.0, 3.0, 0.55), &"coulees_lave", P.SPAWN_FORGES, &"suie_partie", &"coulees_fermees")


static func _habitats(root: Region) -> void:
	# Calm (no wild dinos: the corrupted are the story's; their names on the map).
	B.habitat(root, "Les Forges de l'Ombre", Rect2(0, 24, W, H - 24), [], 0)
	B.habitat(root, "La Grande Forge", Rect2(18, 0, 46, 24), [], 0)


static func _keep_clear() -> Array:
	var keep: Array = []
	for r: Rect2i in PLACES_NETTES:
		keep.append(Rect2(r).grow(1.0))
	for t: Vector2 in [P.LEONCE, P.FEU_FORGES, P.ENTREE_FORGES, P.DEPUIS_COULEES_FORGES, P.MANDRAGORE, P.TRAINEAU, P.FOURNAISE,
			P.TENTE_BRAC, P.GRANDE_FORGE] + P.MASQUES_OS:
		keep.append(Rect2(t - Vector2(2.5, 2.5), Vector2(5, 5)))
	for p: Array in CAMP:
		keep.append(Rect2(p[1] - Vector2(1.5, 1.5), Vector2(3, 3)))
	return keep


static func _on_foot() -> Dictionary:
	return {
		"entrée": P.ENTREE_FORGES, "sortie vers les champs": P.SORTIE_CHAMPS - Vector2(0, 1), "le feu": P.FEU_FORGES + Vector2(1.5, 0),
		"Léonce": P.LEONCE + Vector2(-1.0, 0.6), "forge 1": P.FORGE_1 + Vector2(1.5, 1.6), "Numéro 7": P.NUMERO_7 + Vector2(0, 1.4),
		"forge 2": P.FORGE_2 + Vector2(1.5, 1.6), "Numéro 11": P.NUMERO_11 + Vector2(0, 1.4), "forge 3": P.FORGE_3 + Vector2(-1.5, 1.6),
		"Numéro 12": P.NUMERO_12 + Vector2(0, 1.4), "devant la barricade": P.BARRICADE + Vector2(0, 1.2),
		"la rampe (derrière la barricade)": P.RAMPE_PLATEAU, "Brac": P.BRAC + Vector2(0, 1.2), "la grande forge": P.GRANDE_FORGE + Vector2(0, 1.4),
		"Dame Suie": P.SUIE + Vector2(0, 1.2), "sortie vers les coulées": P.SORTIE_COULEES,
	}
