extends RefCounted
## Le Sanctuaire de Givre (Monts Gelés, chapter 6): behind the frost door at the back of its notch
## in the north face of the Col des Tempêtes (tools/zones/monts.gd). A corridor of ice climbs from
## the door (the south edge) up a ramp into a great round hall 1.2 m up, inside the mountain: ice
## pillars and crystals round its walls, a ring of clear ice at its middle where the Cryolophosaure
## Titan waits (DinoNpc « Titan »), the altar of the fourth Cœur at its back between two statues of
## Cryolophosaurus (StoryProp « Autel », event « coeur_givre »), page 27 beside them. No wild
## dinos, no weather. (story/monts*.gd plays it.)

const PATH := "res://regions/monts/sanctuaire_givre.tscn"
const B := preload("res://tools/zone_builder.gd")
const P := preload("res://story/monts_places.gd")
const PICKUP := "res://world/pickup.gd"
const STORY_PROP := "res://world/story_prop.gd"
const MUSIC := ["res://assets/audio/music/monts.ogg", "res://assets/audio/music/plaines.ogg"]
const BACKDROP := ["res://assets/art/battle/sanctuaire_givre.jpg", "res://assets/art/battle/grotte.jpg"]
const FLOORS := ["res://assets/art/ground/sol_grotte_glace.png", "res://assets/art/ground/grotte_sol.png"]
## The Titan: an Alpha, bigger than its kind (docs/direction-artistique.md « Échelle »).
const TITAN_SIZE := 1.2

## The ground (see ZoneBuilder): . the floor, s clear ice (the ring round the Titan).
const PLAN := [
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	".............ssssss.............",
	"............ssssssss............",
	"...........ssssssssss...........",
	"...........ssssssssss...........",
	"...........ssssssssss...........",
	"............ssssssss............",
	".............ssssss.............",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
]
## The relief (1.2 m a level): the hall at 1, the corridor at 0 (x 14-17) and its ramp, the walls at
## 3 all round, 2 on the hall's south side (lower: the camera looks over them into the hall).
const RELIEF := [
	"33333333333333333333333333333333",
	"33333333333333111133333333333333",
	"33333333331111111111113333333333",
	"33333333111111111111111133333333",
	"33333331111111111111111113333333",
	"33333311111111111111111111333333",
	"33333111111111111111111111133333",
	"33333111111111111111111111133333",
	"33331111111111111111111111113333",
	"33331111111111111111111111113333",
	"33331111111111111111111111113333",
	"33331111111111111111111111113333",
	"33331111111111111111111111113333",
	"33331111111111111111111111113333",
	"33333111111111111111111111133333",
	"33333111111111111111111111133333",
	"33333311111111111111111111333333",
	"33333331111111111111111113333333",
	"33333333111111111111111133333333",
	"33333333221111111111112233333333",
	"33333333222222111122222233333333",
	"33333333222222rrrr22222233333333",
	"33333333222222000022222233333333",
	"33333333222222000022222233333333",
	"33333333333333000033333333333333",
	"33333333333333000033333333333333",
	"33333333333333000033333333333333",
	"33333333333333000033333333333333",
	"33333333333333000033333333333333",
	"33333333333333000033333333333333",
	"33333333333333000033333333333333",
	"33333333333333000033333333333333",
	"33333333333333000033333333333333",
	"33333333333333000033333333333333",
]

## Ice pillars and crystals round the hall, the corridor's icicles: [kind, stand-in, x, y, flip].
const DECOR := [
	["stalactites_glace", "stalagmite", 6.4, 8.4, false], ["stalactites_glace", "stalagmite", 25.6, 8.6, true],
	["cristaux_glace", "cristaux", 8.2, 4.8, false], ["cristaux_glace", "cristaux", 23.8, 4.2, true],
	["stalactites_glace", "stalagmite", 5.6, 14.2, false], ["stalactites_glace", "stalagmite", 26.4, 14.6, true],
	["cristaux_glace", "", 9.0, 18.0, false], ["cristaux_glace", "", 23.0, 18.2, true],
	["cristaux_glace", "", 13.2, 27.4, false], ["cristaux_glace", "", 18.8, 30.2, true],
]


static func build() -> Region:
	var root := B.region(&"sanctuaire_givre", "Monts Gelés", "Le Sanctuaire de Givre", Vector2i(40, 40), PLAN)
	root.indoor = true
	root.cave = true
	root.relief = PackedStringArray(RELIEF)
	root.terrain = root.get_node("Terrain")   # (out of the tree: its heights need it, see flat_spot)
	root.ground_tex = load(_first(FLOORS))
	root.music = load(_first(MUSIC))
	root.ambience_id = &"sanctuaire_givre"
	var backdrop := _first(BACKDROP)
	if backdrop != "":
		root.battle_backdrop = load(backdrop)
	for w: String in ["rain_chance", "mist_chance", "storm_chance", "sandstorm_chance", "snow_chance", "blizzard_chance"]:
		root.set(w, 0.0)
	# Cold: ice underfoot, the warm coat.
	root.cold = true
	var entities: Node2D = root.get_node("Entities")
	for p: Array in DECOR:
		_put(entities, p[0], p[1], Vector2(p[2], p[3]), p[4])
	var altar = _put(entities, "autel", "serrure", P.AUTEL, false, load(STORY_PROP))
	altar.name = "Autel"
	altar.event = &"coeur_givre"
	for p: Array in [[P.AUTEL.x - 4.6, P.AUTEL.y + 0.5, false], [P.AUTEL.x + 4.6, P.AUTEL.y + 0.5, true]]:
		_put(entities, "statue_cryolophosaure", "statue_dino", Vector2(p[0], p[1]), p[2])
	var page = B.prop(entities, "ambre", B.cell(P.PAGE_27.x, P.PAGE_27.y), false, load(PICKUP))
	page.name = "Page27"
	page.taken_flag = &"found_journal_27"
	page.dialogue_id = &"page_27"
	if SpeciesDB.PATHS.has(&"cryolophosaure_titan"):   # (once its sheet and species are in the game)
		B.dino_npc(root, "Titan", &"cryolophosaure_titan", P.TITAN.x, P.TITAN.y, {"event": &"titan_givre",
			"size": TITAN_SIZE})   # (it stays after the Cœur: a line at each visit)
	B.spawn(root, "Depart", P.SANCTUAIRE_ENTREE.x, P.SANCTUAIRE_ENTREE.y + 0.5)
	B.spawn(root, P.SPAWN_SANCTUAIRE_DEPUIS_MONTS, P.SANCTUAIRE_ENTREE.x, P.SANCTUAIRE_ENTREE.y + 0.5)
	B.exit(root, Rect2(14.0, 33.45, 4.0, 0.55), &"monts", P.SPAWN_SANCTUAIRE)
	# (Its name on the map.)
	B.habitat(root, "Le Sanctuaire de Givre", Rect2(3, 1, 26, 21), [], 0)
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
