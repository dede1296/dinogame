extends RefCounted
## Grotte des Échos: under the Plaines, behind the boulder (Charge). A dark cave in three
## chambers joined by passages (relief: rock walls); Troodons in the dark, a page of the
## journal, and the second amber scale among the crystals at the far end.

const PATH := "res://regions/plaines/grotte_echos.tscn"
const B := preload("res://tools/zone_builder.gd")

const PLAN := [
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
	"........................",
]
## Rock walls (level 1) around the chambers and passages (level 0).
const RELIEF := [
	"111111111111111111111111",
	"111100000000000000000111",
	"111100000000000000000111",
	"111100000000000000000111",
	"111100000000000000000111",
	"111100001111111111111111",
	"111100001111111111111111",
	"111100001111111111111111",
	"111100001111111111111111",
	"111100000000000000001111",
	"111100000000000000001111",
	"111100000000000000001111",
	"111100000000000000001111",
	"111100000000000000001111",
	"111111111100001111111111",
	"111111111100001111111111",
	"111111111100001111111111",
	"111111111100001111111111",
]


static func build() -> Region:
	var root := B.region(&"grotte_echos", "Plaines des Fougères", "Grotte des Échos", Vector2i(5, 8), PLAN)
	root.indoor = true
	root.cave = true
	root.relief = PackedStringArray(RELIEF)
	root.ground_tex = load("res://assets/art/ground/grotte_sol.png")
	root.music = load("res://assets/audio/music/plaines.ogg")
	root.ambience_id = &"grotte"
	var entities: Node2D = root.get_node("Entities")
	for p: Array in [
			["stalagmite", 4.8, 12.6], ["stalagmite", 18.6, 9.8], ["rocher_grotte", 16.0, 13.4], ["stalagmite", 7.4, 3.9],
			["cristaux", 5.0, 10.0], ["cristaux", 12.2, 13.5], ["cristaux", 19.6, 1.9], ["cristaux", 17.2, 1.6],
			["rocher_grotte", 10.5, 2.0], ["stalagmite", 14.0, 1.7], ["cristaux", 6.8, 6.5], ["stalagmite", 13.5, 11.2]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]))
	B.sign(entities, B.cell(8.6, 12.8), &"panneau_grotte_int")
	var page = B.prop(entities, "ambre", B.cell(18.4, 12.6), false, load("res://world/pickup.gd"))
	page.taken_flag = &"found_journal_4"
	page.dialogue_id = &"page_4"
	var scale = B.prop(entities, "ecaille", B.cell(18.6, 2.9), false, load("res://world/pickup.gd"))
	scale.taken_flag = &"ecaille_grotte"
	scale.dialogue_id = &"ecaille_grotte"
	B.spawn(root, "Depart", 11.9, 16.2)
	B.spawn(root, "DepuisCarrefour", 11.9, 16.2)
	B.exit(root, Rect2(10.0, 17.45, 4.0, 0.55), &"plaines", &"DepuisGrotte")
	B.habitat(root, "Salle basse", Rect2(4, 9, 16, 5), [[&"troodon", 6, 8, 10, "toujours", false]], 1)
	B.habitat(root, "Salle haute", Rect2(4, 1, 17, 4), [[&"troodon", 6, 8, 10, "toujours", false]], 1)
	return root
