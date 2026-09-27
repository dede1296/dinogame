extends RefCounted
## Le Temple englouti (Marais Brumeux, chapter 3): under the island of the temple, behind the
## door the Voix du Marais sings open. Slabs, walls of the same stone, pools, amber glowing in
## the corners. The way in from the south opens on the entry hall; the flood water fills three
## passages, drained one after the other by three sluices, always in the same order:
##   Vanne1, in the entry hall, drains Crue1: the passage to the west gallery;
##   Vanne2, at the end of the west gallery (north-west room), drains Crue2: the passage to the
##     east gallery;
##   Vanne3, at the end of the east gallery (north-east room), drains Crue3: the stairs from the
##     entry hall up to the great hall, where the Spinosaure Ancestral guards the first Heart on
##     its altar.
## One fresco in the hall and one at the end of each gallery; page 12 in the east gallery. The
## flooded stairs are in sight from the way in: the goal is seen from the start. The water
## never comes back (the sluices only drain). No wild dinos. (story/marais_temple.gd plays it.)

const PATH := "res://regions/marais/temple_englouti.tscn"
const B := preload("res://tools/zone_builder.gd")
const STORY_PROP := "res://world/story_prop.gd"
const PICKUP := "res://world/pickup.gd"
const MUSIC := "res://assets/audio/music/marais.ogg"
const SLABS := "res://assets/art/ground/dalles_temple.png"
const BACKDROP := "res://assets/art/battle/temple.jpg"

## The ground (see ZoneBuilder): . slabs, ~ water (the pools). The walls are the relief.
const PLAN := [
	"........................................",
	"........................................",
	"........................................",
	"...........~~~............~~~...........",
	"...........~~~............~~~...........",
	"...........~~~............~~~...........",
	"...........~~~............~~~...........",
	"...........~~~............~~~...........",
	"...........~~~............~~~...........",
	"...........~~~............~~~...........",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	".................~~~~~~.................",
	".................~~~~~~.................",
	".................~~~~~~.................",
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
## Walls (1.2 m; the north wall 2.4 m) round the rooms and passages (level 0):
##   the great hall (x 11-28, y 2-10), the north-west and north-east rooms (x 2-8 / 31-37,
##   y 2-7), the galleries (x 3-6 / 33-36, y 8-21), their passages to the hall (x 7-12 / 27-32,
##   y 19-21), the stairs (x 18-21, y 11-14), the entry hall (x 13-26, y 15-25), the way in
##   (x 18-21, y 26-29).
const RELIEF := [
	"2222222222222222222222222222222222222222",
	"2222222222222222222222222222222222222222",
	"1100000001100000000000000000011000000011",
	"1100000001100000000000000000011000000011",
	"1100000001100000000000000000011000000011",
	"1100000001100000000000000000011000000011",
	"1100000001100000000000000000011000000011",
	"1100000001100000000000000000011000000011",
	"1110000111100000000000000000011110000111",
	"1110000111100000000000000000011110000111",
	"1110000111100000000000000000011110000111",
	"1110000111111111110000111111111110000111",
	"1110000111111111110000111111111110000111",
	"1110000111111111110000111111111110000111",
	"1110000111111111110000111111111110000111",
	"1110000111111000000000000001111110000111",
	"1110000111111000000000000001111110000111",
	"1110000111111000000000000001111110000111",
	"1110000111111000000000000001111110000111",
	"1110000000000000000000000000000000000111",
	"1110000000000000000000000000000000000111",
	"1110000000000000000000000000000000000111",
	"1111111111111000000000000001111111111111",
	"1111111111111000000000000001111111111111",
	"1111111111111000000000000001111111111111",
	"1111111111111000000000000001111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
	"1111111111111111110000111111111111111111",
]

## The flood water (tiles) and the sluice that drains each: [name, cells, dry flag].
const FLOODS := [
	["Crue1", Rect2(3, 18, 10, 4), &"temple_vanne_1"],
	["Crue2", Rect2(27, 18, 10, 4), &"temple_vanne_2"],
	["Crue3", Rect2(18, 11, 4, 4), &"temple_vanne_3"],
]
## [name, event, x, y, flip]
const SLUICES := [
	["Vanne1", &"vanne_1", 14.4, 17.3, false],
	["Vanne2", &"vanne_2", 7.4, 5.2, true],
	["Vanne3", &"vanne_3", 31.8, 5.2, false],
]
const FRESCOES := [
	["Fresque1", &"fresque_1", 23.4, 15.3],
	["Fresque2", &"fresque_2", 5.2, 2.3],
	["Fresque3", &"fresque_3", 34.2, 2.3],
]
const SPINOSAURE := Vector2(19.5, 5.9)
const ALTAR := Vector2(19.5, 3.1)
const PAGE_12 := Vector2(34.6, 12.6)


## The flooded passages are sunk into the floor (relief "b", Region.BASIN_DEPTH): the water
## fills them to the brim, and as it drains, their stone sides show, then their dry floor.
static func _with_basins() -> PackedStringArray:
	var rows := PackedStringArray(RELIEF)
	for f: Array in FLOODS:
		var r: Rect2 = f[1]
		for y in range(int(r.position.y), int(r.end.y)):
			var row := rows[y]
			for x in range(int(r.position.x), int(r.end.x)):
				if row[x] == "0":
					row = row.substr(0, x) + "b" + row.substr(x + 1)
			rows[y] = row
	return rows


static func build() -> Region:
	var root := B.region(&"temple_englouti", "Marais Brumeux", "Le Temple englouti", Vector2i(15, 21), PLAN)
	root.indoor = true
	root.cave = false   # (the warm light of the indoors: readable; the amber glows in the corners)
	root.relief = _with_basins()
	root.terrain = root.get_node("Terrain")   # (out of the tree: its heights need it, see flat_spot)
	root.ground_tex = load(SLABS)
	root.music = load(MUSIC)
	root.ambience_id = &"grotte"
	if ResourceLoader.exists(BACKDROP):
		root.battle_backdrop = load(BACKDROP)
	var entities: Node2D = root.get_node("Entities")
	for f: Array in FLOODS:
		B.flood(root, f[1], f[2], {"name": f[0], "blocked_dialogue": &"crue_temple"})
	for s: Array in SLUICES:
		var v = B.prop(entities, "vanne", B.cell(s[2], s[3]), s[4], load(STORY_PROP))
		v.name = s[0]
		v.event = s[1]
	for f: Array in FRESCOES:
		var p = B.prop(entities, "fresque", B.cell(f[2], f[3]), false, load(STORY_PROP))
		p.name = f[0]
		p.event = f[1]
	var page = B.prop(entities, "ambre", B.cell(PAGE_12.x, PAGE_12.y), false, load(PICKUP))
	page.name = "Page12"
	page.taken_flag = &"found_journal_12"
	page.dialogue_id = &"page_12"
	_great_hall(root, entities)
	_decor(entities)
	B.spawn(root, "Depart", 19.5, 27.6)
	B.spawn(root, "DepuisMarais", 19.5, 27.6)
	B.exit(root, Rect2(18.0, 29.45, 4.0, 0.55), &"marais", &"DepuisTemple")
	return root


## The great hall: the Spinosaure Ancestral before the altar where the first Heart rests
## (gone once the Sceau du Marais is given), statues either side.
static func _great_hall(root: Region, entities: Node2D) -> void:
	var altar = B.prop(entities, "serrure", B.cell(ALTAR.x, ALTAR.y), false, load(STORY_PROP))
	altar.name = "Autel"
	B.dino_npc(root, "Spinosaure", &"spinosaurus", SPINOSAURE.x, SPINOSAURE.y, {"event": &"spinosaure_ancestral",
		"hide_flag": &"sceau_marais", "size": 1.1})
	for p: Array in [["statue_dino", 15.4, 3.0, false], ["statue_dino", 23.6, 3.0, true],
			["colonne", 14.6, 9.4, false], ["colonne", 24.4, 9.4, true], ["cristaux", 16.8, 2.5, false], ["cristaux", 22.2, 2.5, true]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])


## Columns, amber crystals glowing, stones fallen from the ceiling.
static func _decor(entities: Node2D) -> void:
	for p: Array in [
			["colonne", 25.0, 17.2, true], ["colonne", 14.4, 24.2, false], ["colonne", 25.0, 24.2, true],
			["colonne", 3.4, 12.0, false], ["colonne", 6.6, 16.0, true], ["colonne", 36.6, 12.0, true], ["colonne", 33.4, 16.0, false],
			["cristaux", 13.6, 25.4, false], ["cristaux", 25.6, 25.4, true], ["cristaux", 2.6, 2.6, false],
			["cristaux", 37.4, 2.6, true], ["cristaux", 6.4, 9.2, true], ["cristaux", 33.6, 9.2, false],
			["cristaux", 16.4, 15.6, false], ["cailloux", 8.0, 7.2, false], ["cailloux", 35.8, 19.4, true],
			["cailloux", 22.6, 22.6, false], ["cailloux", 3.6, 20.6, true], ["fougeres", 13.8, 21.8, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
