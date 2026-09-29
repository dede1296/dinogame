extends RefCounted
## The camp of the Ombre Noire (Forêt Jurassique, chapter 2): a muddy clearing up on the rock
## west of the camp's ridge, behind the cracked wall (the tunnel from the forest comes in from
## the east). Closed by the woods (west), a rocky rise (north), a rock block by the way in,
## palisades; the south stays low (the camera looks north over it). Brac and his two
## henchmen, the tents, the crates of black amber, Brac's table and its papers (page 11); in
## cages, the Utahraptor (the pack's Alpha) and other maddened dinos. No wild dinos here.
## (story/foret_camp.gd plays its scenes.) The camp's ground is at relief level 3 (3.6 m), as
## high as the forest's ridge where the two zones meet (see tools/maps/gen-foret.mjs).
## The new scenery (tente, cage, caisse_ambre_noir, table_papiers, palissade) is used once
## world/prop.gd knows it: rebuild the zone then (stand-ins meanwhile, or nothing).

const PATH := "res://regions/foret/camp_ombre.tscn"
const B := preload("res://tools/zone_builder.gd")
const CHARS := "res://assets/art/characters/%s.png"
const STORY_PROP := "res://world/story_prop.gd"
const MUSIC := "res://assets/audio/music/ombre.ogg"
const MUSIC_FALLBACK := "res://assets/audio/music/foret.ogg"
const GROUND := "res://assets/art/ground/sous_bois.png"
const BACKDROP := "res://assets/art/battle/foret.jpg"

## The ground (see ZoneBuilder): . forest floor, = the trampled mud, F the woods.
const PLAN := [
	"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
	"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
	"FFF................................FFFFF",
	"FFF................................FFFFF",
	"FFF................................FFFFF",
	"FFF................====............FFFFF",
	"FFF..........=============.........FFFFF",
	"FFF......=====================.....FFFFF",
	"FFF....========================....FFFFF",
	"FFF....==========================..FFFFF",
	"FFF....==========================.......",
	"FFF...============================......",
	"FFF...==================================",
	"FFF...==================================",
	"FFF....=================================",
	"FFF....=================================",
	"FFF......======================.........",
	"FFF.........=================...........",
	"FFF.........=============...............",
	"FFF.....................................",
	"FFF.....................................",
	"FFF.....................................",
	"FFF.....................................",
	"FFFFF...................................",
]
## The relief (1.2 m a level): the camp at 3, the rise behind it and the rock block at 5.
const RELIEF := [
	"5555555555555555555555555555555555555533",
	"5555555555555555555555555555555555555533",
	"5555555555555555555555555555555555555533",
	"3333333333333333333333333333333335555533",
	"3333333333333333333333333333333335555533",
	"3333333333333333333333333333333335555533",
	"3333333333333333333333333333333335555533",
	"3333333333333333333333333333333335555533",
	"3333333333333333333333333333333335555533",
	"3333333333333333333333333333333335555533",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
	"3333333333333333333333333333333333333333",
]

## Where the story's people and cages are (tiles).
const BRAC := Vector2(20.0, 11.0)
const UTAHRAPTOR := Vector2(31.0, 8.0)
const PAPERS := Vector2(11.0, 8.0)
## The caged dinos of the decor: [species, x, y, size, flip] (freed with the Utahraptor), just
## behind their cage's front bars. The cages were made bigger for them (Prop.KINDS "cage", ×1.35
## on 28/09): a grown Deinonychus (1.8 m), a young Dilophosaurus (2.1 m).
const CAGED := [[&"deinonychus", 25.5, 5.8, 1.0, false], [&"dilophosaurus", 6.2, 12.3, 0.8, false]]
## A caged dino stands between its cage (the picture, a little behind it and to the left: its
## open door hangs on the left of the barred box) and the cage's front bars (in front of it,
## gone once the dinos are freed). Tiles from the dino.
const CAGE_FROM_DINO := Vector2(-0.3375, -0.162)
const BARS_FROM_DINO := Vector2(0.0, 0.189)


static func build() -> Region:
	var root := B.region(&"camp_ombre", "Forêt Jurassique", "Le camp de l'Ombre Noire", Vector2i(14, 18), PLAN)
	root.relief = PackedStringArray(RELIEF)
	root.terrain = root.get_node("Terrain")   # (out of the tree: its heights need it, see flat_spot)
	root.music = load(MUSIC if ResourceLoader.exists(MUSIC) else MUSIC_FALLBACK)
	root.ambience_id = &"foret"
	if ResourceLoader.exists(GROUND):
		root.ground_tex = load(GROUND)
	if ResourceLoader.exists(BACKDROP):
		root.battle_backdrop = load(BACKDROP)
	root.rain_chance = 0.35
	root.mist_chance = 0.15
	root.storm_chance = 0.04
	var entities: Node2D = root.get_node("Entities")
	_camp(root, entities)
	_cages(root, entities)
	_edges(entities)
	_people(root)
	B.spawn(root, "Depart", 37.0, 14.0)
	B.spawn(root, "DepuisForet", 37.0, 14.0)
	B.exit(root, Rect2(39.45, 12.0, 0.55, 4.0), &"foret", &"DepuisCamp")
	return root


## A kind of scenery, or its stand-in while world/prop.gd does not know it yet ("" = none).
static func _kind(kind: String, stand_in := "") -> String:
	if Prop.KINDS.has(kind):
		return kind
	return stand_in if Prop.KINDS.has(stand_in) else ""


## A prop of `kind` (or its stand-in) at tile (x, y); null when neither is drawn.
static func _put(entities: Node2D, kind: String, stand_in: String, x: float, y: float, flip := false, script: Script = null) -> Node2D:
	var k := _kind(kind, stand_in)
	return B.prop(entities, k, B.cell(x, y), flip, script) if k != "" else null


## The tents (north, where they hide nothing), the crates of black amber, the fire, Brac's
## table with its papers (page 11), barrels, lanterns for the night.
static func _camp(root: Region, entities: Node2D) -> void:
	# (Tents in real 3D, 2.4 m high, 3.9 m deep with their pegs: in front of the palisade of the
	# north, clear of the crates, of Brac's way up round the third one (x 21.8), of the west
	# palisade and of the Dilophosaurus' cage.)
	for t: Array in [[6.1, 7.7, false], [13.6, 7.7, true], [19.3, 7.7, false], [5.4, 17.6, true]]:
		_put(entities, "tente", "", t[0], t[1], t[2])
	for c: Array in [[27.6, 10.4], [28.8, 11.1], [9.4, 10.8], [16.6, 7.9], [23.6, 8.9], [34.2, 17.8]]:
		_put(entities, "caisse_ambre_noir", "caisses", c[0], c[1], int(c[0]) % 2 == 0)
	var table = _put(entities, "table_papiers", "etabli", PAPERS.x, PAPERS.y, false, load(STORY_PROP))
	if table:
		table.name = "PapiersBrac"
		table.event = &"papiers_brac"
	B.prop(entities, "feu_camp", B.flat_spot(root, Vector2(21.0, 14.8), 1))
	for p: Array in [["tonneau", 10.3, 11.6], ["caisses", 8.4, 6.2], ["tonneau", 23.0, 5.4], ["tonneau", 33.6, 16.9],
			["lanterne", 17.3, 8.3], ["lanterne", 24.6, 12.9], ["lanterne", 32.9, 10.6], ["cailloux", 12.6, 14.9],
			["cailloux", 29.4, 15.9], ["os_dino", 26.4, 15.2]]:
		_put(entities, p[0], "", p[1], p[2])


## The cages: the Utahraptor's big one (story, see _people), a pen of stakes against the rock
## block, too big for the cage picture: a low fence in front (its head and its veins show
## over it; Chloé reaches it from there), stakes behind and on the side; and the decor's
## cages with their maddened dinos (no scene; gone with the Utahraptor once the Sceau is won,
## their cages left open), each cage just in front (south) of its dino: its bars over it.
static func _cages(root: Region, entities: Node2D) -> void:
	for p: Array in [["palissade", 29.7, 6.5, false], ["palissade", 31.6, 6.6, true], ["palissade", 28.8, 7.8, false],
			["cloture", 30.2, 8.6, false], ["cloture", 31.8, 8.65, true]]:
		_put(entities, p[0], "cloture", UTAHRAPTOR.x + p[1] - 31.0, UTAHRAPTOR.y + p[2] - 8.0, p[3])
	for c: Array in CAGED:
		B.dino_npc(root, "Cage" + String(c[0]).to_pascal_case(), c[0], c[1], c[2], {"corrupted": true, "size": c[3],
			"flip": c[4], "hide_flag": &"sceau_foret"})
		_put(entities, "cage", "cloture", c[1] + CAGE_FROM_DINO.x, c[2] + CAGE_FROM_DINO.y)
		var bars = B.prop(entities, "barreaux_cage", B.cell(c[1] + BARS_FROM_DINO.x, c[2] + BARS_FROM_DINO.y), false, load(STORY_PROP))
		bars.name = "Barreaux" + String(c[0]).to_pascal_case()
		bars.hide_flag = &"sceau_foret"


## The camp's bounds: a palisade along the foot of the rise (north: Brac flees over it) and on
## the west, pieces at the south corners, a gate post by the way in; low scrub along the south
## (the camera looks over it), rocks on the rise, bushes and stones beyond the south edge.
static func _edges(entities: Node2D) -> void:
	var fence: Array = [[3.7, 7.8], [3.7, 10.8], [3.7, 13.8], [3.7, 19.6], [4.6, 22.4], [7.8, 22.6],
		[31.0, 22.6], [34.2, 22.4], [32.8, 9.9]]
	for i in 15:
		fence.append([4.4 + i * 1.9, 3.45 + (0.08 if i % 2 == 0 else 0.0)])
	for p: Array in fence:
		_put(entities, "palissade", "cloture", p[0], p[1], int(p[0] * 10.0) % 3 == 0)
	for p: Array in [["buisson", 11.4, 21.4], ["buisson", 17.8, 22.1], ["buisson", 25.4, 21.8], ["buisson", 37.2, 21.4],
			["ronces", 14.6, 22.9], ["ronces", 22.4, 23.1], ["ronces", 28.6, 22.8], ["fougeres", 20.2, 20.6],
			["fougeres", 8.6, 20.2], ["fougeres", 35.6, 19.6], ["rocher", 37.4, 18.6], ["rocher_mousse", 5.6, 20.8],
			["cailloux", 16.2, 20.4], ["cailloux", 30.2, 20.2], ["champignons", 3.9, 21.6],
			["rocher", 10.4, 2.6], ["rocher_mousse", 27.4, 2.5], ["cailloux", 18.6, 2.4], ["buisson", 33.6, 2.6],
			["buisson", 8.0, 24.6], ["rocher", 19.6, 24.9], ["buisson", 31.4, 24.5], ["ronces", 38.4, 24.7]]:
		_put(entities, p[0], "rocher" if p[0] == "rocher_mousse" else "", p[1], p[2], int(p[1] * 10.0) % 2 == 0)


## Brac and his henchmen (gone once beaten), the Utahraptor in its cage (gone once calmed:
## it hands over the Sceau de la Forêt).
static func _people(root: Region) -> void:
	var drawn := ResourceLoader.exists(CHARS % "brac")
	B.npc(root, "Brac", "Brac", CHARS % ("brac" if drawn else "sbire"), BRAC.x, BRAC.y, {"facing": "down",
		"event": &"brac", "hide_flag": &"brac_battu", "tint": Color.WHITE if drawn else Color(1.0, 0.72, 0.62)})
	B.npc(root, "SbireCamp1", "Sbire masqué", CHARS % "sbire", 15.0, 17.0, {"facing": "down",
		"event": &"sbire_camp_1", "hide_flag": &"sbire_camp_1_battu"})
	B.npc(root, "SbireCamp2", "Sbire bougon", CHARS % "sbire", 27.0, 17.0, {"facing": "right",
		"event": &"sbire_camp_2", "hide_flag": &"sbire_camp_2_battu", "tint": Color(0.86, 0.8, 1.0)})
	B.dino_npc(root, "Utahraptor", &"utahraptor", UTAHRAPTOR.x, UTAHRAPTOR.y, {"event": &"utahraptor_cage",
		"corrupted": true, "size": 1.2, "flip": true, "hide_flag": &"sceau_foret"})   # (ForetCamp.UTAH_SIZE)
