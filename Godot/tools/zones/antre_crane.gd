extends RefCounted
## L'antre du gardien: the Tricératops Alpha's cave, behind the Grand Crâne's amber door.
## A passage up from the mouth, one round chamber, and at its back a dark tunnel going
## deeper, where the guardian sleeps: going on is not allowed (yet). Room for a secret.

const PATH := "res://regions/plaines/antre_crane.tscn"
const B := preload("res://tools/zone_builder.gd")

const PLAN := [
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
]
## Rock walls around the chamber and passage: high at the back (level 3, room for the
## tunnel's mouth), low elsewhere so they never hide Chloé from the camera.
const RELIEF := [
	"33333333333333",
	"33333333333333",
	"11000000000011",
	"10000000000001",
	"10000000000001",
	"10000000000001",
	"11000000000011",
	"11110000001111",
	"11111100111111",
	"11111100111111",
	"11111100111111",
	"11111100111111",
]


static func build() -> Region:
	var root := B.region(&"antre_crane", "Prairie du Grand Crâne", "Antre du gardien", Vector2i(7, 8), PLAN)
	root.indoor = true
	root.cave = true
	root.relief = PackedStringArray(RELIEF)
	root.ground_tex = load("res://assets/art/ground/grotte_sol.png")
	root.music = load("res://assets/audio/music/plaines.ogg")
	root.ambience_id = &"grotte"
	var entities: Node2D = root.get_node("Entities")
	for p: Array in [
			["stalagmite", 2.6, 3.6], ["stalagmite", 11.5, 4.2], ["cristaux", 3.4, 6.3], ["cristaux", 10.4, 2.9],
			["rocher_grotte", 11.2, 6.4], ["cailloux", 4.6, 2.8], ["cailloux", 9.2, 6.6], ["stalagmite", 5.2, 7.4]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]))
	# The tunnel going deeper, where the guardian sleeps.
	var deeper := CaveMouth.new()
	deeper.name = "TunnelGardien"
	deeper.width = 2.0
	deeper.height = 2.4
	deeper.position = B.cell(7.0, 2.0)
	entities.add_child(deeper)
	B.exit(root, Rect2(6.0, 2.0, 2.0, 0.7), &"antre_crane", &"Depart", &"gardien_eveille", &"antre_gardien")
	B.spawn(root, "Depart", 7.0, 10.4)
	B.spawn(root, "DepuisPlaines", 7.0, 10.4)
	B.exit(root, Rect2(6.0, 11.45, 2.0, 0.55), &"plaines", &"DepuisAntre")
	return root
