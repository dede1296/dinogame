extends RefCounted
## Le Récif du Sanctuaire (Côte Préhistorique, chapter 5): the sanctuary under the sea, reached
## diving beyond the reef's pass (tools/zones/cote.gd) or through the sea caves' tunnel
## (tools/zones/grottes_marines.gd). A round arena of the seabed walled by the reef's rock, its
## sand hollow in the middle where the Mosasaure Abyssal lies (DinoNpc « MosasaureAbyssal »), the
## bones of a giant long dead, weathered pillars of the ancients; at the back, on a dais (steps in
## front), the altar of the third Cœur (StoryProp « Autel », event « coeur_recif ») and page 22
## beside it. All of it under water: a dim bluish light, the amber glowing (a cave, for now: the
## Plongée's own look is the world's, Mécaniques). No wild dinos, no weather.
## (story/cote*.gd plays it.)

const PATH := "res://regions/cote/recif_sanctuaire.tscn"
const B := preload("res://tools/zone_builder.gd")
const P := preload("res://story/cote_places.gd")
const PICKUP := "res://world/pickup.gd"
const STORY_PROP := "res://world/story_prop.gd"
const MUSIC := ["res://assets/audio/music/cote.ogg", "res://assets/audio/music/plaines.ogg"]
const BACKDROP := ["res://assets/art/battle/sous_marin.jpg", "res://assets/art/battle/recif.jpg", "res://assets/art/battle/grotte.jpg"]

## The ground (see ZoneBuilder): . rocky seabed, s the sand hollow. The walls are the relief.
const PLAN := [
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
	"............ssssssss............",
	"...........ssssssssss...........",
	"..........ssssssssssss..........",
	"..........ssssssssssss..........",
	"..........ssssssssssss..........",
	"...........ssssssssss...........",
	"............ssssssss............",
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
## The reef's rock 2.4 m round the arena (1.2 m where it stands just south of the floor: the
## camera looks north), the dais 1.2 m (x 12-19, y 3-6) and its steps (r), the way down from the
## pass (x 14-17, south) and the tunnel from the sea caves (south-west).
const RELIEF := [
	"22222222222222222222222222222222",
	"22222222222222222222222222222222",
	"22222222222222222222222222222222",
	"22222222222211111111222222222222",
	"22222222222011111111022224444222",
	"22222222200011111111000024444222",
	"22222220000011111111000004444222",
	"222222000000000rr000000000002222",
	"22222200000000000000000000022222",
	"22222000000000000000000000002222",
	"22222000000000000000000000000222",
	"22220000000000000000000000000222",
	"22200000000000000000000000000222",
	"22200000000000000000000000001222",
	"22210000000000000000000000001222",
	"22210000000000000000000000002222",
	"22220000000000000000000000002222",
	"22221000000000000000000000012222",
	"22221000000000000000000000112222",
	"22220000000000000000000001122222",
	"22200000100000000000000111222222",
	"22000001111000000000011112222222",
	"22000011211111000011111222222222",
	"22000012222111000011122222222222",
	"22000122222222000022222222222222",
	"22000122222222000022222222222222",
	"22000222222222000022222222222222",
	"22000222222222000022222222222222",
]

## Pillars of the ancients either side of the dais, their carved slabs (bone masks: stone, not a
## statue one could take for a dino), the giant's bones, amber crystals, kelp along the rock
## (stand-in: reeds, which sway the same): [kind, stand-in, x, y, flip].
const DECOR := [
	["colonne", "", 10.8, 6.6, false], ["colonne", "", 21.2, 6.6, true], ["fresque", "", 8.6, 9.0, false],
	["fresque", "", 23.4, 9.0, true], ["os_geant", "", 6.8, 14.2, false], ["os_geant", "", 25.6, 16.4, true],
	["cristaux", "", 11.2, 3.6, false], ["cristaux", "", 20.8, 3.6, true], ["cristaux", "", 5.8, 15.6, false],
	["cristaux", "", 26.2, 4.6, true], ["cristaux", "", 16.0, 21.4, false], ["varech", "roseaux", 4.8, 16.8, false],
	["varech", "roseaux", 26.6, 18.2, true], ["varech", "roseaux", 9.4, 19.6, false], ["varech", "roseaux", 22.4, 20.2, true],
	["corail", "rocher_grotte", 12.2, 19.4, false], ["corail", "rocher_grotte", 20.0, 18.8, true], ["corail", "rocher_grotte", 7.4, 18.0, true],
	["corail", "rocher_grotte", 23.5, 15.2, false], ["corail", "rocher_grotte", 23.5, 12.5, true], ["corail", "rocher_grotte", 23.5, 9.9, false],
	# (29/09) « Pris dans le corail, de vieilles pierres sculptées : des masques d'os, tournés vers
	# le fond » either side of the steps; more reef life out of the currents' way: branching coral,
	# sponges, anemones, sea grass in the sand hollow.
	["masque_pierre", "", 12.6, 7.6, false], ["masque_pierre", "", 19.4, 7.6, true],
	["corail_branches", "", 6.4, 8.4, false], ["corail_branches", "", 19.6, 21.0, true], ["corail_branches", "", 11.6, 21.2, false],
	["eponges", "", 27.0, 10.4, true], ["eponges", "", 5.8, 9.2, false],
	["anemones", "", 12.8, 17.8, false], ["anemones", "", 19.8, 17.2, true], ["anemones", "", 5.6, 19.4, false],
	["herbier", "", 11.4, 12.6, false], ["herbier", "", 20.6, 13.8, true], ["herbier", "", 13.2, 16.0, true], ["herbier", "", 18.8, 10.8, false],
]


static func build() -> Region:
	var root := B.region(&"recif_sanctuaire", "Côte Préhistorique", "Le Récif du Sanctuaire", Vector2i(30, 35), PLAN)
	root.indoor = true
	root.cave = true
	root.relief = PackedStringArray(RELIEF)
	root.terrain = root.get_node("Terrain")   # (out of the tree: its heights need it, see flat_spot)
	root.ground_tex = load("res://assets/art/ground/grotte_sol.png")
	root.music = load(_first(MUSIC))
	root.ambience_id = &"recif"
	var backdrop := _first(BACKDROP)
	if backdrop != "":
		root.battle_backdrop = load(backdrop)
	# Under water (the Plongée's look, once the world knows it: Mécaniques).
	if &"underwater" in root:
		root.set(&"underwater", true)
	root.set_meta(&"underwater", true)   # (Dive.underwater reads it too)
	root.rain_chance = 0.0
	root.mist_chance = 0.0
	root.storm_chance = 0.0
	var entities: Node2D = root.get_node("Entities")
	for p: Array in DECOR:
		var k: String = p[0] if Prop.KINDS.has(p[0]) else p[1]
		if k != "" and Prop.KINDS.has(k):
			B.prop(entities, k, B.cell(p[2], p[3]), p[4])
	# (the giant clam once the decor has its picture; until then the amber lock of the old altars)
	var altar = B.prop(entities, "benitier" if Prop.KINDS.has("benitier") else "serrure", B.cell(P.AUTEL.x, P.AUTEL.y), false, load(STORY_PROP))
	altar.name = "Autel"
	altar.event = &"coeur_recif"
	var page = B.prop(entities, "ambre", B.cell(P.PAGE_22.x, P.PAGE_22.y), false, load(PICKUP))
	page.name = "Page22"
	page.taken_flag = &"found_journal_22"
	page.dialogue_id = &"page_22"
	_sea_features(root, entities)
	B.dino_npc(root, "MosasaureAbyssal", &"mosasaure_abyssal", P.MOSASAURE.x, P.MOSASAURE.y,
		{"event": &"mosasaure_abyssal", "size": 1.2})
	B.spawn(root, "Depart", P.RECIF_ARRIVEE.x, P.RECIF_ARRIVEE.y + 1.4)
	B.spawn(root, P.RECIF_SPAWN_COTE, P.RECIF_ARRIVEE.x, P.RECIF_ARRIVEE.y + 1.4)
	B.exit(root, Rect2(14.0, 27.45, 4.0, 0.55), &"cote", P.SPAWN_RECIF)
	B.spawn(root, P.RECIF_SPAWN_GROTTES, P.RECIF_TUNNEL.x, P.RECIF_TUNNEL.y + 1.0)
	B.exit(root, Rect2(2.0, 27.45, 3.0, 0.55), &"grottes_marines", P.GROTTES_SPAWN_RECIF)
	# (Its name on the map.)
	B.habitat(root, "Le Récif du Sanctuaire", Rect2(3, 2, 26, 20), [], 0)
	return root


## The first of `paths` that exists ("" when none does).
static func _first(paths: Array) -> String:
	for p: String in paths:
		if ResourceLoader.exists(p):
			return p
	return ""


## La Plongée (Mécaniques): page 22 lies up on the spire by the altar (4.8 m: out of reach for a
## swimmer), only the bubble column rising at its foot takes Chloé there; the current of the pass
## carries her from the tunnel's side up to the dais (a one-way shortcut); the current of the
## abyss sweeps down the east side, in the way (round by the dais, or from rock to rock, in their
## lee); two dark nooks lit by the Cœurs (an amber pebble in the west, a fossil by the bones).
static func _sea_features(root: Region, entities: Node) -> void:
	BubbleColumn.place(root, Rect2(25.0, 7.05, 2.0, 1.5), Rect2(25.0, 4.0, 4.0, 3.0), Vector2(26.4, 5.4), {"name": "ColonnePiton"})
	SeaCurrent.place(root, Rect2(8.6, 8.6, 2.0, 11.4), Vector2.UP, 330.0, {"name": "CourantPasse", "helps": true})
	SeaCurrent.place(root, Rect2(21.6, 9.2, 3.8, 8.6), Vector2.DOWN, 300.0, {"name": "CourantAbime", "helps": false})
	DarkNook.place(root, Rect2(2.9, 10.8, 2.8, 3.4), {"name": "RecoinOuest"})
	DarkNook.hide_find(entities, "RecoinOuest", "galet", Vector2(3.9, 12.4), &"galet_recif_sanctuaire_00")
	DarkNook.place(root, Rect2(25.6, 12.2, 2.6, 3.2), {"name": "RecoinOs"})
	DarkNook.hide_find(entities, "RecoinOs", "os_dino", Vector2(27.0, 13.6), &"fossile_recif", {"item": "fossile",
		"line": "Dans la lumière des Cœurs, une vertèbre de pierre, polie par la mer : un fossile de reptile marin, bien plus vieux que le récif. Roc va adorer."})
	root.pebbles = 1
