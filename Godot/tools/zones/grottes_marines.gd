extends RefCounted
## Les Grottes marines (Côte Préhistorique, chapter 5): behind the dark mouth at the back of the
## cove under the headland (tools/zones/cote.gd). From the way in (south), the Grotte des marées:
## sand, tide pools, amber crystals; at its back, at the foot of the rock, the blue pool where the
## rock comes down into the water: one dives there (Plongée, with Joss's mask) and comes up in the
## inner cave, cut off from the rest — the smugglers' cache: crates of black amber, the Passeur by
## them, page 21 under « H. + I. » carved in the rock, Isaure's boat moored at the stone quay on
## the sea pool, whose tunnel (north-east) goes out under the reef to the sanctuary (zone
## recif_sanctuaire, once page 21 has told the way). Elasmosaurs on full-moon nights.
## The dives are ZoneExits within the zone (a fade, then the other side), closed without the mask:
## the Plongée's own dive (world, Mécaniques) may take their place. (story/cote*.gd plays it.)

const PATH := "res://regions/cote/grottes_marines.tscn"
const B := preload("res://tools/zone_builder.gd")
const P := preload("res://story/cote_places.gd")
const PICKUP := "res://world/pickup.gd"
const STORY_PROP := "res://world/story_prop.gd"
const CHARS := "res://assets/art/characters/%s.png"
const MUSIC := ["res://assets/audio/music/cote.ogg", "res://assets/audio/music/plaines.ogg"]
const BACKDROP := ["res://assets/art/battle/grotte_marine.jpg", "res://assets/art/battle/grotte.jpg"]
## The flag the dives need (Joss's diving mask), and what Chloé says at the blue pool without it.
const DIVE_FLAG := &"masque_plongee"
const DIVE_BLOCKED := &"plongee_bloquee"

## The ground (see ZoneBuilder): . cave floor, v wet sand (the tide comes in), ~ water (the pools, the sea pool and its
## tunnel), = the stone quay. The walls are the relief. (Made by a script: the inner cave is cut
## off from the first one, even swimming.)
const PLAN := [
	".................................~~~~~..",
	".............................~~~.~~~~~..",
	"........................===.~~~~~~~.....",
	"........................===~~~~~~~~~~...",
	"........................===~~~~~~~~~~~..",
	"...................~....===.~~~~~~~~~...",
	".................~~~~~..===...~~~~~.....",
	"..................~~~...................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"................~~~~~~..................",
	"................~~~~~~~~................",
	"..................~~~~..................",
	"........................................",
	"........................................",
	"........................................",
	".......vvvvvv...........................",
	".......v~~~~v..............vvvvv........",
	".......vvvvvv..............v~~~v........",
	"......vvvvvvvvvvvvvvvvvvvvvvvvvvv.......",
	".........vvvvvvvvvvvvvvvvvvvvvvv........",
	"...........vvvvvvvvvvvvvvvvvv...........",
	"...............vvvvvvv..................",
	"..................vvvv..................",
	"..................vvvv..................",
	"..................vvvv..................",
	"..................vvvv..................",
	"..................vvvv..................",
]
## Walls 1.2 m (2.4 m along the north edge) round the Grotte des marées (y 12-24) and its way in
## (x 18-21), the inner cave (y 1-8) and the sea tunnel (x 33-37, y 0-1).
const RELIEF := [
	"2222222222222222222222222222222220000022",
	"1111110000000000000000000000000010000011",
	"1110000000000000000000000000000000011111",
	"1000000000000000000000000000000000000111",
	"1000000000000000000000000000000000000001",
	"1000000000000000000000000000000000000011",
	"1110000000000000000000000000000000001111",
	"1111111000000000000000000000000000111111",
	"1111111111100000000000000000111111111111",
	"1111111111111111111111111111111111111111",
	"1111111111111111111111111111111111111111",
	"1111111111111111111111111111111111111111",
	"1111111111111110000000111101111111111111",
	"1111111111000000000000000000011111111111",
	"1111111110000000000000000000000111111111",
	"1111111000000000000000000000000001111111",
	"1111100000000000000000000000000000111111",
	"1111100000000000000000000000000000011111",
	"1111100000000000000000000000000000011111",
	"1111100000000000000000000000000000011111",
	"1111100000000000000000000000000000111111",
	"1111110000000000000000000000000001111111",
	"1111111110000000000000000000000011111111",
	"1111111111100000000000000000011111111111",
	"1111111111111110000000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
]

## Amber crystals glowing, stalagmites, fallen rocks, weed on the sand: [kind, stand-in, x, y, flip].
const DECOR := [
	["cristaux", "", 6.4, 16.2, false], ["cristaux", "", 33.2, 17.0, true], ["cristaux", "", 14.6, 12.6, false],
	["cristaux", "", 26.0, 12.8, true], ["stalagmite", "", 8.2, 21.6, false], ["stalagmite", "", 31.6, 22.2, true],
	["rocher_grotte", "", 24.8, 16.6, false], ["rocher_grotte", "", 12.4, 17.2, true], ["algues", "cailloux", 17.2, 23.4, false],
	["coquillages", "cailloux", 23.4, 22.8, true], ["algues", "cailloux", 28.2, 21.4, false], ["cailloux", "", 9.4, 21.2, true],
	# the inner cave
	["cristaux", "", 3.6, 3.6, false], ["cristaux", "", 16.4, 2.0, true], ["stalagmite", "", 13.6, 7.4, false],
	["rocher_grotte", "", 21.8, 7.6, true], ["cristaux", "", 37.4, 4.6, true], ["algues", "cailloux", 27.2, 7.2, false],
]


static func build() -> Region:
	var root := B.region(&"grottes_marines", "Côte Préhistorique", "Les Grottes marines", Vector2i(30, 35), PLAN)
	root.indoor = true
	root.cave = true
	root.relief = PackedStringArray(RELIEF)
	root.terrain = root.get_node("Terrain")   # (out of the tree: its heights need it, see flat_spot)
	root.ground_tex = load("res://assets/art/ground/grotte_sol.png")
	root.path_tex = load("res://assets/art/ground/paves.png")   # (the quay's stones)
	root.music = load(_first(MUSIC))
	root.ambience_id = &"grotte_marine"
	var backdrop := _first(BACKDROP)
	if backdrop != "":
		root.battle_backdrop = load(backdrop)
	var entities: Node2D = root.get_node("Entities")
	for p: Array in DECOR:
		_put(entities, p[0], p[1], Vector2(p[2], p[3]), p[4])
	_cache(root, entities)
	# La Plongée (Mécaniques): the darkest corner of the cache, lit only by the Cœurs.
	DarkNook.place(root, Rect2(1.1, 2.6, 2.9, 3.4), {"name": "RecoinCache"})
	DarkNook.hide_find(entities, "RecoinCache", "galet", Vector2(2.0, 4.3), &"galet_grottes_marines_00")
	root.pebbles = 1
	_places(root)
	# Elasmosaurs on full-moon nights (on plain nights until Encounter knows the full moon).
	var moon := "pleine lune" if B.WHEN.has("pleine lune") else "nuit"
	B.habitat(root, "La Grotte des marées", Rect2(5, 12, 30, 13), [
		[&"masiakasaurus", 31, 33, 8, "toujours", false], [&"archelon", 31, 33, 5, "jour", false],
		[&"elasmosaurus", 33, 35, 6, moon, false],
	], 1)
	B.habitat(root, "La Cache des contrebandiers", Rect2(1, 1, 38, 8), [
		[&"elasmosaurus", 33, 35, 10, moon, false],
	], 1)
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


## The inner cave: the crates of black amber (StoryProp « CacheContrebande »), the Passeur, page 21
## under the carved initials, Isaure's boat at the quay (StoryProp « BarqueIsaure »), the scene
## when Chloé comes up there (StoryTrigger « CacheArrivee »).
static func _cache(root: Region, entities: Node2D) -> void:
	var cache = B.prop(entities, "caisse_ambre_noir", B.cell(P.CACHE.x, P.CACHE.y), false, load(STORY_PROP))
	cache.name = "CacheContrebande"
	cache.event = &"cache_contrebande"
	for p: Array in [["caisse_ambre_noir", 6.4, 3.2, true], ["caisse_ambre_noir", 9.8, 3.0, false], ["caisses", 5.2, 5.4, false],
			["caisses", 10.8, 5.6, true], ["tonneau", 4.2, 3.4, false], ["filet", 14.8, 6.8, true], ["caisses", 23.4, 4.5, false]]:   # (no lantern: « pas de lumière, ici »; the crate the Passeur leans on)
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	# (half a tile off the rock's foot: right against it, the relief would lift it onto the wall)
	_put(entities, "gravure_hi", "", P.GRAVURE + Vector2(0.0, 0.5))
	var page = B.prop(entities, "ambre", B.cell(P.PAGE_21.x, P.PAGE_21.y), false, load(PICKUP))
	page.name = "Page21"
	page.taken_flag = &"found_journal_21"
	page.dialogue_id = &"page_21"
	B.npc(root, "Passeur", "Le Passeur", CHARS % "sbire", P.PASSEUR.x, P.PASSEUR.y, {"facing": "left", "event": &"passeur",
		"hide_flag": &"passeur_parti"})
	var boat = B.prop(entities, "barque", B.cell(P.BARQUE.x, P.BARQUE.y), true, load(STORY_PROP))
	boat.name = "BarqueIsaure"
	boat.event = &"barque_isaure"
	for p: Array in [["bitte", 26.4, 3.0, false], ["bitte", 26.4, 6.0, true], ["cordage", 24.6, 6.4, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
	B.trigger(root, P.GROTTES_REMONTEE.x, P.GROTTES_REMONTEE.y - 2.2, 3.0, &"cache_arrivee",
		{"once_flag": &"cache_vue", "name": "CacheArrivee"})


static func _places(root: Region) -> void:
	B.spawn(root, "Depart", P.GROTTES_ENTREE.x, P.GROTTES_ENTREE.y + 0.6)
	B.spawn(root, P.GROTTES_SPAWN_COTE, P.GROTTES_ENTREE.x, P.GROTTES_ENTREE.y + 0.6)
	B.exit(root, Rect2(18.0, 29.45, 4.0, 0.55), &"cote", P.SPAWN_GROTTES)
	# The flooded passage: into the blue pool, up in the inner cave; and back.
	B.spawn(root, P.GROTTES_SPAWN_FOND, P.GROTTES_PLONGEE.x, P.GROTTES_PLONGEE.y + 2.6)
	B.spawn(root, P.GROTTES_SPAWN_REMONTEE, P.GROTTES_REMONTEE.x, P.GROTTES_REMONTEE.y - 0.1)   # in the pool: up on her diver
	# (dive spots, world/dive_spot.gd: the dive button over the pool; without the mask, DIVE_BLOCKED)
	DiveSpot.place(root, Rect2(P.GROTTES_PLONGEE.x - 1.2, P.GROTTES_PLONGEE.y - 0.9, 2.4, 1.2), &"grottes_marines",
		P.GROTTES_SPAWN_REMONTEE, {"name": "PlongeeAller", "required_flag": DIVE_FLAG, "blocked_dialogue": DIVE_BLOCKED})
	DiveSpot.place(root, Rect2(P.GROTTES_REMONTEE.x - 1.2, P.GROTTES_REMONTEE.y - 0.5, 2.4, 1.2), &"grottes_marines",
		P.GROTTES_SPAWN_FOND, {"name": "PlongeeRetour"})
	# The sea tunnel, under the reef to the sanctuary (once page 21 has told the way); Chloé comes
	# back up at the quay.
	B.spawn(root, P.GROTTES_SPAWN_RECIF, P.QUAI.x, P.QUAI.y - 1.2)
	DiveSpot.place(root, Rect2(P.TUNNEL_MER.x - 2.5, 0.0, 5.0, 1.5), &"recif_sanctuaire",
		P.RECIF_SPAWN_GROTTES, {"name": "TunnelMer", "required_flag": &"passe_recif", "blocked_dialogue": &"recif_bloque"})
