extends RefCounted
## Le Clos Blanc: a test zone, a quiet clearing around one stone cottage. The cottage is a
## real 3D model (assets/models/maison_3d.glb): modelled in Blender, stone by stone and slate
## by slate (C:/ComfyUI_windows_portable/blender_tests/maison_3d_organique.py), its two views
## painted in the game's style by ComfyUI (SD 1.5 + IPAdapter + the Ambrelune LoRA), the
## paintings projected back onto it (see Prop.KINDS "model", WorldView._model_mesh).
## A path runs from the south shore to its door, a pond and a bench on
## the west, a fenced garden on the east. Not linked to the island: reached from the debug
## menu (F2 › zones) or with tools/lancer-maison-3d.cmd.

const PATH := "res://regions/essai/clos_blanc.tscn"
const B := preload("res://tools/zone_builder.gd")

const PLAN := [
	"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
	"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
	"FF..............................FF",
	"FF..............................FF",
	"FF..............................FF",
	"FF..............................FF",
	"FF..............................FF",
	"FF..............................FF",
	"FF..............................FF",
	"FF..............................FF",
	"FF..............==..............FF",
	"FF..............==..............FF",
	"FF..............==..............FF",
	"FF..............==..............FF",
	"FF..~~~~~.=================.....FF",
	"FF..~~~~~.......==..............FF",
	"FF..~~~~~.......==..............FF",
	"FF..~~~~~.......==..............FF",
	"FF..............==..............FF",
	"FF..............==..............FF",
	"FF..............==..............FF",
	"FF..............==..............FF",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
]


static func build() -> Region:
	var root := B.region(&"clos_blanc", "Le Clos Blanc", "La maison de pierre", Vector2i(1, 1), PLAN)
	root.music = load("res://assets/audio/music/village.ogg")
	root.ambience_id = &"plaines"
	# A place to look at the house: fair weather.
	root.rain_chance = 0.0
	root.mist_chance = 0.0
	root.storm_chance = 0.0
	var entities: Node2D = root.get_node("Entities")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	# The cottage faces the path (its origin: the middle of the facade's foot, at its door).
	B.prop(entities, "maison_3d", B.cell(17.0, 10.0))
	_around_house(entities)
	_pond(entities)
	_garden(entities)
	_woods(entities)
	# Small plants on the grass, but not against the house, in the garden or by the bench.
	var busy := func(x: int, y: int) -> bool: return (x >= 11 and x <= 23 and y <= 11) or (x >= 20 and x <= 29 and y >= 11 and y <= 18) or (x >= 9 and x <= 14 and y >= 12 and y <= 15)
	B.scatter(entities, PLAN, rng, 14, busy)
	B.spawn(root, "Depart", 17.0, 20.3)
	return root


## Flower boxes under the windows, two lanterns along the path, barrels by the wall.
static func _around_house(entities: Node2D) -> void:
	for p: Array in [["bac_fleurs", 14.4, 10.6], ["bac_fleurs", 19.6, 10.6], ["lanterne", 15.3, 11.6],
			["lanterne", 18.7, 11.6], ["tonneau", 22.3, 9.8], ["caisses", 23.5, 10.2], ["souche", 10.2, 9.4]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]))


## The pond on the west, and a bench looking at it.
static func _pond(entities: Node2D) -> void:
	for p: Array in [["nenuphars", 5.9, 15.6], ["nenuphars", 7.3, 16.8], ["roseaux", 4.4, 18.1],
			["roseaux", 8.7, 14.0], ["banc", 11.2, 13.7], ["fleurs_violettes", 12.9, 13.4]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]))


## A little garden east of the house, between two fences.
static func _garden(entities: Node2D) -> void:
	for x: float in [22.0, 23.6, 25.2, 26.8]:
		B.prop(entities, "cloture", B.cell(x, 12.3))
		B.prop(entities, "cloture", B.cell(x, 17.6))
	for p: Array in [["fleurs_roses", 22.4, 13.4], ["fleurs_violettes", 24.6, 13.5], ["fougere_pot", 26.9, 13.5],
			["fleurs_roses", 23.2, 16.4], ["champignons", 25.4, 16.5], ["fleurs_violettes", 27.1, 16.3]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]))


## A few trees in the clearing (none near the south shore: they would hide the view).
static func _woods(entities: Node2D) -> void:
	for p: Array in [["arbre_rond", 5.8, 7.2, false], ["fougere_arbre", 4.1, 11.2, true], ["araucaria", 29.4, 8.6, false],
			["arbre_rond", 27.9, 4.6, true], ["tronc", 6.2, 12.6, false], ["buisson", 27.2, 20.4, false],
			["buisson", 6.4, 20.7, true], ["rocher", 11.6, 19.9, false], ["cailloux", 22.4, 20.3, false]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]), p[3])
