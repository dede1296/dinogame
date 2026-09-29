extends RefCounted
## Les Grottes de glace (Monts Gelés, chapter 6): behind the dark mouth at the back of the notch in
## the peaks' face, north of the glacier (tools/zones/monts.gd). From the way in (south), the Salle
## des stalactites: ice pillars, frozen pools, blue crystals; north-west, a narrow passage up to
## Hélène's little room, plugged by an ice wall (Charge): page 26 there; north, up a corridor,
## Hélène's reserve: the sleepers (juveniles in their ice blocks) along its back wall, the eggs in
## the ice at its middle, Dame Suie at work by her vials, her sled at its east side. Minmi in the
## first hall. (story/monts*.gd plays it.)

const PATH := "res://regions/monts/grottes_glace.tscn"
const B := preload("res://tools/zone_builder.gd")
const P := preload("res://story/monts_places.gd")
const PICKUP := "res://world/pickup.gd"
const STORY_PROP := "res://world/story_prop.gd"
const OBSTACLE := "res://world/obstacle.gd"
const CHARS := "res://assets/art/characters/%s.png"
const MUSIC := ["res://assets/audio/music/monts.ogg", "res://assets/audio/music/plaines.ogg"]
const BACKDROP := ["res://assets/art/battle/grotte_glace.jpg", "res://assets/art/battle/grotte.jpg"]
## The ice cave's floor, and the plain cave's meanwhile.
const FLOORS := ["res://assets/art/ground/sol_grotte_glace.png", "res://assets/art/ground/grotte_sol.png"]

## The ground (see ZoneBuilder): . cave floor, s ice (frozen pools). The walls are the relief.
## (Made by a script: the rooms drawn as ellipses.)
const PLAN := [
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	".............................sssss......",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"............................sss.........",
	"...........................sssss........",
	"............................sss.........",
	"........................................",
	".........ssss...........................",
	"........ssssss..........................",
	".........ssss...........................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
]
## Walls 1.2 m (2.4 m along the north edge) round the reserve (rows 2-13), Hélène's room (x 1-8, rows
## 6-13) and its passage (x 4-5, rows 13-19), the corridor (x 20-23, rows 12-18), the first hall
## (rows 17-29) and the way in (x 18-21).
const RELIEF := [
	"2222222222222222222222222222222222222222",
	"2222222222222222222222222222222222222222",
	"1111111111111111000000000000000001111111",
	"1111111111111100000000000000000000011111",
	"1111111111111000000000000000000000001111",
	"1111111111110000000000000000000000000111",
	"1110000111100000000000000000000000000011",
	"1100000011100000000000000000000000000011",
	"1100000011100000000000000000000000000011",
	"1000000001110000000000000000000000000111",
	"1000000001111000000000000000000000001111",
	"1100000011111100000000000000000000011111",
	"1100000011111111000000000000000001111111",
	"1110000111111111111100000000011111111111",
	"1111001111111111111100001111111111111111",
	"1111001111111111111100001111111111111111",
	"1111001111111111111100001111111111111111",
	"1111001111111000000000000011111111111111",
	"1111001110000000000000000000001111111111",
	"1111001000000000000000000000000011111111",
	"1111000000000000000000000000000000111111",
	"1111000000000000000000000000000000011111",
	"1110000000000000000000000000000000001111",
	"1110000000000000000000000000000000001111",
	"1110000000000000000000000000000000001111",
	"1111000000000000000000000000000000011111",
	"1111100000000000000000000000000000111111",
	"1111111000000000000000000000000011111111",
	"1111111110000000000000000000001111111111",
	"1111111111111000000000000011111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
]

## Ice pillars, crystals, fallen blocks round the first hall and the reserve: [kind, stand-in, x, y, flip].
const DECOR := [
	["stalactites_glace", "stalagmite", 7.6, 21.2, false], ["stalactites_glace", "stalagmite", 32.4, 21.8, true],
	["cristaux_glace", "", 14.4, 18.8, false], ["cristaux_glace", "", 27.0, 18.6, true], ["cristaux_glace", "", 5.6, 24.6, false],
	["bloc_glace", "rocher_grotte", 33.2, 25.6, true], ["stalactites_glace", "stalagmite", 12.4, 28.0, false],
	["cristaux_glace", "", 28.6, 28.0, true], ["rocher_grotte", "", 16.0, 27.4, false],
	# the reserve
	["cristaux_glace", "", 13.2, 8.2, false], ["cristaux_glace", "", 36.2, 8.6, true], ["stalactites_glace", "stalagmite", 17.4, 11.6, false],
	["stalactites_glace", "stalagmite", 31.8, 12.4, true],
	# Hélène's room
	["cristaux_glace", "", 7.4, 8.0, true],
]


static func build() -> Region:
	var root := B.region(&"grottes_glace", "Monts Gelés", "Les Grottes de glace", Vector2i(35, 38), PLAN)
	root.indoor = true
	root.cave = true
	root.relief = PackedStringArray(RELIEF)
	root.terrain = root.get_node("Terrain")   # (out of the tree: its heights need it, see flat_spot)
	root.ground_tex = load(_first(FLOORS))
	root.music = load(_first(MUSIC))
	root.ambience_id = &"grotte_glace"
	var backdrop := _first(BACKDROP)
	if backdrop != "":
		root.battle_backdrop = load(backdrop)
	for w: String in ["rain_chance", "mist_chance", "storm_chance", "sandstorm_chance", "snow_chance", "blizzard_chance"]:
		root.set(w, 0.0)
	# Cold: ice and frozen ground underfoot, the warm coat.
	root.cold = true
	var entities: Node2D = root.get_node("Entities")
	for p: Array in DECOR:
		_put(entities, p[0], p[1], Vector2(p[2], p[3]), p[4])
	_reserve(root, entities)
	_room(entities)
	root.pebbles = 0
	_places(root)
	B.habitat(root, "La Salle des stalactites", Rect2(3, 17, 34, 21), [
		[&"minmi", 35, 37, 10, "toujours", false],
	].filter(func(r: Array) -> bool: return SpeciesDB.PATHS.has(r[0])), 2)   # (once the Minmi is in the game)
	# (Calm: nobody wild in Hélène's reserve nor in her room; their names on the map.)
	B.habitat(root, "La Réserve d'Hélène", Rect2(10, 1, 29, 13), [], 0)
	B.habitat(root, "La Chambre d'Hélène", Rect2(0, 5, 10, 15), [], 0)
	return root


## The first of `paths` that exists ("" when none does).
static func _first(paths: Array) -> String:
	for p: String in paths:
		if ResourceLoader.exists(p):
			return p
	return ""


## A prop of `kind`, or of its stand-in while `kind` has no picture ("" = nothing).
static func _put(entities: Node2D, kind: String, stand_in: String, t: Vector2, flip := false, script: Script = null) -> Node2D:
	var k := kind if Prop.KINDS.has(kind) else stand_in
	if k == "" or not Prop.KINDS.has(k):
		return null
	return B.prop(entities, k, B.cell(t.x, t.y), flip, script)


## Hélène's reserve: the sleepers' ice blocks (StoryProps « Dormeur1 »…: the first three melt away
## once the sleepers are woken; the juveniles inside are the story's « DormeurDino1 »…), the eggs in
## the ice (« OeufsGlace »), Dame Suie by her vials (« FiolesSuie »), her sled (« TraineauSuie ») and
## Mandragore harnessed to it, all gone with her; the scene when Chloé comes up the corridor into
## the reserve (StoryTrigger « DeclencheurReserve »).
static func _reserve(root: Region, entities: Node2D) -> void:
	for i in P.DORMEURS.size():
		var block = _put(entities, "bloc_glace", "rocher_grotte", P.DORMEURS[i], i % 2 == 1, load(STORY_PROP))
		block.name = "Dormeur%d" % (i + 1)
		block.event = &"dormeurs"
		if i < 3:
			block.hide_flag = &"dormeurs_reveilles"
	var eggs = _put(entities, "oeufs_glace", "rocher_grotte", P.OEUFS, false, load(STORY_PROP))
	eggs.name = "OeufsGlace"
	eggs.event = &"dormeurs"
	var sled = _put(entities, "traineau_suie", "caisses", P.TRAINEAU, false, load(STORY_PROP))
	sled.name = "TraineauSuie"
	sled.event = &"traineau_suie"
	sled.hide_flag = &"suie_monts_partie"
	var vials = _put(entities, "fioles_suie", "panier_fioles", P.FIOLES, false, load(STORY_PROP))
	vials.name = "FiolesSuie"
	vials.hide_flag = &"suie_monts_partie"
	B.npc(root, "DameSuieMonts", "Dame Suie", CHARS % "dame_suie", P.SUIE.x, P.SUIE.y, {"facing": "up",
		"event": &"suie_monts", "hide_flag": &"suie_monts_partie"})
	B.dino_npc(root, "Mandragore", &"therizinosaurus", P.MANDRAGORE.x, P.MANDRAGORE.y, {"hide_flag": &"suie_monts_partie", "flip": true})
	B.trigger(root, P.RESERVE.x - 2.5, P.RESERVE.y + 4.0, 3.0, &"grottes_glace_reserve",
		{"once_flag": &"suie_monts_vue", "name": "DeclencheurReserve"})


## Hélène's little room up the narrow passage: the ice wall across the passage (Charge), page 26.
static func _room(entities: Node2D) -> void:
	var wall = B.prop(entities, "mur_glace" if Prop.KINDS.has("mur_glace") else "rocher_grotte",
		B.cell(P.MUR_GROTTES.x, P.MUR_GROTTES.y), false, load(OBSTACLE))
	wall.name = "MurGrottes"
	wall.ability = &"charge"
	wall.cleared_flag = &"mur_grottes_brise"
	wall.blocked_dialogue = &"mur_glace_bloque"
	wall.debris_color = Color(0.82, 0.92, 1.0)
	var page = B.prop(entities, "ambre", B.cell(P.PAGE_26.x, P.PAGE_26.y), false, load(PICKUP))
	page.name = "Page26"
	page.taken_flag = &"found_journal_26"
	page.dialogue_id = &"page_26"


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.GROTTES_ENTREE.x, P.GROTTES_ENTREE.y + 0.6)
	B.spawn(root, P.SPAWN_GROTTES_DEPUIS_MONTS, P.GROTTES_ENTREE.x, P.GROTTES_ENTREE.y + 0.6)
	B.exit(root, Rect2(18.0, 37.45, 4.0, 0.55), &"monts", P.SPAWN_GROTTES)
