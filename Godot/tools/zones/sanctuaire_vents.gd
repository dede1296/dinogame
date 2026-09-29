extends RefCounted
## Le Sanctuaire des Vents (Désert Aride, chapter 4): behind the door of the Vents, at the north
## edge of the desert (tools/zones/desert.gd). A corridor cut in the rock climbs from the door
## (the south edge: the desert's notch goes on here) up a ramp into a great round hall open to
## the sky, 1.2 m up, walled by the canyon rock. Totems of the winds in a ring, sand turning in
## three arms round the altar at its middle, where the second Cœur rests (StoryProp « Autel »,
## event « coeur_vents »); page 18 at the back of the hall. No wild dinos, no weather: the
## wind sings in the rock. (story/desert_sanctuaire.gd plays it.) Its rock walls are as high as
## the desert's rock face at the door (3.6 m), so the two meet where they are shown side by side.

const PATH := "res://regions/desert/sanctuaire_vents.tscn"
const B := preload("res://tools/zone_builder.gd")
const PICKUP := "res://world/pickup.gd"
const STORY_PROP := "res://world/story_prop.gd"
const MUSIC := "res://assets/audio/music/desert.ogg"
const BACKDROP := "res://assets/art/battle/desert.jpg"

## The ground (see ZoneBuilder): r canyon rock, s sand (turning round the altar).
const PLAN := [
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrssrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrsrrrsssrrrrrrrrrrrr",
	"rrrrrrrrrsrrrrrrrssrrrrrrrrrrr",
	"rrrrrrrrrrrrsssrrrrsrrrrrrrrrr",
	"rrrrrrrrrrssrrrssrrsrrrrrrrrrr",
	"rrrrrrrrrrsrrrsssrrsrrrrrrrrrr",
	"rrrrrrrrrsrrrsrrrsrsrrrrrrrrrr",
	"rrrrrrrrrsrrssrrrsrsrrsrrrrrrr",
	"rrrrrrrrrsrrsrsssssrrrsrrrrrrr",
	"rrrrrrrrrsrrssrrrrrrrssrrrrrrr",
	"rrrrrrrrrssrrssrrrrrssrrrrrrrr",
	"rrrrrrrrrrsrrrssssssrrrrrrrrrr",
	"rrrrrrrrrrrsrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrsrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
	"rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr",
]
## The relief (1.2 m a level): the hall at 1, the corridor at 0 (x 14-16) and its ramp, the rock
## walls at 3 all round.
const RELIEF := [
	"333333333333333333333333333333",
	"333333333331111111113333333333",
	"333333333111111111111133333333",
	"333333331111111111111113333333",
	"333333311111111111111111333333",
	"333333111111111111111111133333",
	"333331111111111111111111113333",
	"333331111111111111111111113333",
	"333331111111111111111111113333",
	"333331111111111111111111113333",
	"333331111111111111111111113333",
	"333333111111111111111111133333",
	"333333111111111111111111133333",
	"333333311111111111111111333333",
	"333333333111111111111133333333",
	"333333333331111111113333333333",
	"33333333333333rrr3333333333333",
	"333333333333330003333333333333",
	"333333333333330003333333333333",
	"333333333333330003333333333333",
	"333333333333330003333333333333",
	"333333333333330003333333333333",
	"333333333333330003333333333333",
	"333333333333330003333333333333",
]

## The altar of the second Cœur, at the middle of the hall; page 18 at its back.
const ALTAR := Vector2(15.5, 8.0)
const PAGE_18 := Vector2(17.2, 2.6)
## The totems of the winds, in a ring round the altar (the south of the ring left open: the
## camera looks at the altar over it): [x, y, flip].
const TOTEMS := [
	[9.6, 5.6, false], [12.4, 2.9, false], [18.6, 2.9, true], [21.4, 5.6, true], [7.8, 9.4, false], [23.2, 9.4, true],
]


static func build() -> Region:
	var root := B.region(&"sanctuaire_vents", "Désert Aride", "Le Sanctuaire des Vents", Vector2i(21, 27), PLAN)
	root.relief = PackedStringArray(RELIEF)
	root.terrain = root.get_node("Terrain")   # (out of the tree: its heights need it, see flat_spot)
	root.music = load(MUSIC)
	root.ambience_id = &"desert"
	if ResourceLoader.exists(BACKDROP):
		root.battle_backdrop = load(BACKDROP)
	# Sheltered: no rain, no mist, no sandstorm (one blowing outside stops at the door).
	root.rain_chance = 0.0
	root.mist_chance = 0.0
	root.storm_chance = 0.0
	root.sandstorm_chance = 0.0
	var entities: Node2D = root.get_node("Entities")
	# (the stone altar, once drawn: 29/09; before, the amber lock of the old doors)
	var altar = B.prop(entities, "autel" if Prop.KINDS.has("autel") else "serrure", B.cell(ALTAR.x, ALTAR.y), false, load(STORY_PROP))
	altar.name = "Autel"
	altar.event = &"coeur_vents"
	var page = B.prop(entities, "ambre", B.cell(PAGE_18.x, PAGE_18.y), false, load(PICKUP))
	page.name = "Page18"
	page.taken_flag = &"found_journal_18"
	page.dialogue_id = &"page_18"
	for t: Array in TOTEMS:
		B.prop(entities, "totem_vents", B.cell(t[0], t[1]), t[2])
	_decor(entities)
	B.spawn(root, "Depart", 15.5, 21.6)
	B.spawn(root, "DepuisDesert", 15.5, 21.6)
	B.exit(root, Rect2(13.5, 23.45, 4.0, 0.55), &"desert", &"DepuisSanctuaire")
	# (Its name on the map.)
	B.habitat(root, "Le Sanctuaire des Vents", Rect2(4, 0, 22, 16), [], 0)
	return root


## Boulders and dry scrub in the hall's edges, stones, bones of old offerings.
static func _decor(entities: Node2D) -> void:
	for p: Array in [
			["rocher_canyon", 6.4, 7.0, false], ["rocher_canyon", 24.6, 7.2, true], ["buisson_sec", 8.6, 3.8, true],
			["buisson_sec", 22.8, 3.4, false], ["cailloux", 10.6, 12.8, false], ["cailloux", 20.8, 12.6, true],
			["os_dino", 19.6, 11.8, false], ["buisson_sec", 5.6, 10.6, false], ["buisson_sec", 25.2, 10.2, true]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
