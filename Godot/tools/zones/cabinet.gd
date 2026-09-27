extends RefCounted
## Hélène's Cabinet, inside: Professor Roc's laboratory, the incubator and the three
## hatchlings on the right, the door at the bottom (to Port-Ambre).

const PATH := "res://regions/port/cabinet.tscn"
const B := preload("res://tools/zone_builder.gd")

const PLAN := [
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
]
const CHARS := "res://assets/art/characters/%s.png"


static func build() -> Region:
	var root := B.region(&"cabinet", "Port-Ambre", "Le Cabinet d'Hélène", Vector2i(1, 1), PLAN)
	root.indoor = true
	root.ground_tex = load("res://assets/art/ground/plancher.png")
	root.music = load("res://assets/audio/music/plaines.ogg")
	root.ambience_id = &"cabinet"
	var entities: Node2D = root.get_node("Entities")
	for x: float in [1.8, 5.3, 8.8, 12.3, 14.4]:
		B.prop(entities, "mur_cabinet", B.cell(x, 1.3))
	for p: Array in [
			["bibliotheque", 1.6, 1.9], ["bureau", 5.2, 3.0], ["lampe", 7.4, 1.9], ["fauteuil", 9.4, 3.4],
			["etabli", 11.2, 2.0], ["couveuse", 13.8, 3.2], ["fougere_pot", 0.9, 9.6], ["fougere_pot", 15.1, 9.6]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]))
	B.npc(root, "Roc", "Prof. Roc", CHARS % "roc", 6.5, 4.6, {"facing": "down", "event": &"roc", "hide_flag": &"roc_dehors"})
	# The left drawer of Roc's desk (chapter 2: black amber in it; story/foret_camp.gd). Not
	# drawn: its own spot at the desk's left end, the middle of the desk still shows its notes.
	var drawer: Node2D = load("res://world/story_prop.gd").new()
	drawer.kind = ""   # (no picture of its own)
	drawer.name = "TiroirRoc"
	drawer.event = &"tiroir_roc"
	drawer.position = B.cell(4.35, 3.4)
	entities.add_child(drawer)
	# End of chapter 1: the night Roc goes out, page 6 waits in the empty incubator.
	var page = B.prop(entities, "ambre", B.cell(13.8, 3.9), false, load("res://world/pickup.gd"))
	page.name = "Page6"
	page.show_flag = &"roc_parti_vu"
	page.taken_flag = &"found_journal_6"
	page.dialogue_id = &"page_6"
	B.npc(root, "Isaure", "Isaure", CHARS % "isaure", 4.0, 7.0, {"facing": "right", "show_flag": &"prologue_arrived", "hide_flag": &"maia_left"})
	B.npc(root, "Maia", "Maïa", CHARS % "maia", 5.2, 7.6, {"facing": "right", "show_flag": &"prologue_arrived", "hide_flag": &"maia_left"})
	# The three hatchlings (story/prologue.gd removes the ones already gone).
	for b: Array in [[&"velociraptor", 12.3, 5.8], [&"ankylosaurus", 13.8, 6.5], [&"parasaurolophus", 15.2, 5.8]]:
		B.prop(entities, "socle", B.cell(b[1], b[2] - 0.08))
		B.dino_npc(root, "Bebe_" + String(b[0]), b[0], b[1], b[2], {"event": &"choose_starter", "flip": true, "size": 0.6, "lift": 36.0})
	B.spawn(root, "Depart", 8.0, 9.4)
	B.exit(root, Rect2(7.0, 10.45, 2.0, 0.55), &"port_ambre", &"DepuisCabinet", &"prologue_done", &"cabinet_bloque")
	return root
