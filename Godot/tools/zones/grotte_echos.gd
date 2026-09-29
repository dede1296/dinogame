extends RefCounted
## Grotte des Échos: under the Plaines, behind the boulder (Charge). A dark cave in three
## chambers joined by passages (relief: rock walls); Troodons in the dark, Anurognathus under
## the ceiling, a page of the journal; two henchmen of the Ombre Noire tearing out amber, and
## at the far end the corrupted Protoceratops lying on the second amber scale (story/grotte.gd).

const PATH := "res://regions/plaines/grotte_echos.tscn"
const B := preload("res://tools/zone_builder.gd")
const CHARS := "res://assets/art/characters/%s.png"

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
	# « Tac… tac… tac… Des coups de pioche » (29/09): the henchman's pickaxe and his bucket of amber.
	if Prop.KINDS.has("outils_mine"):
		B.prop(entities, "outils_mine", B.cell(14.9, 3.1))
	var page = B.prop(entities, "ambre", B.cell(18.4, 12.6), false, load("res://world/pickup.gd"))
	page.taken_flag = &"found_journal_4"
	page.dialogue_id = &"page_4"
	# The scale shows once the Protoceratops lying on it is calmed (Grotte.proto drops it then).
	var scale = B.prop(entities, "ecaille", B.cell(18.6, 2.9), false, load("res://world/pickup.gd"))
	scale.taken_flag = &"ecaille_grotte"
	scale.dialogue_id = &"ecaille_grotte"
	scale.show_flag = &"proto_apaise"
	B.npc(root, "Sbire1", "Sbire masqué", CHARS % "sbire", 7.2, 10.6, {"facing": "left", "event": &"sbire_grotte_1", "hide_flag": &"sbire_grotte_1"})
	B.npc(root, "Sbire2", "Sbire à la pioche", CHARS % "sbire", 16.2, 2.6, {"facing": "left", "event": &"sbire_grotte_2",
		"hide_flag": &"sbire_grotte_2", "tint": Color(0.86, 0.8, 1.0)})
	B.dino_npc(root, "ProtoCorrompu", &"protoceratops", 18.6, 3.1, {"event": &"proto_corrompu", "hide_flag": &"proto_apaise",
		"corrupted": true, "size": 1.0, "flip": true})
	B.spawn(root, "Depart", 11.9, 16.2)
	B.spawn(root, "DepuisCarrefour", 11.9, 16.2)
	B.exit(root, Rect2(10.0, 17.45, 4.0, 0.55), &"plaines", &"DepuisGrotte")
	B.habitat(root, "Salle basse", Rect2(4, 9, 16, 5), [[&"troodon", 6, 8, 10, "toujours", false]], 1)
	B.habitat(root, "Salle haute", Rect2(4, 1, 17, 4), [[&"troodon", 6, 8, 10, "toujours", false],
		[&"anurognathus", 6, 8, 10, "toujours", false]], 1)
	B.habitat(root, "Le passage", Rect2(4, 5, 4, 4), [[&"anurognathus", 6, 7, 10, "toujours", false]], 1)
	return root
