extends RefCounted
## Port-Ambre: the fishing village where Chloé lands. A pier on the sea (south), the quay,
## the main street with the houses and Hélène's Cabinet, the path north to the Plaines, and
## east the coast road to Havre-Doré (its guard lets through only the trainers with a Sceau).

const PATH := "res://regions/port/port_ambre.tscn"
const B := preload("res://tools/zone_builder.gd")

const PLAN := [
	"................==......................",
	"................==......................",
	"................==......................",
	"................==......................",
	"................==......................",
	"................==......................",
	"................==......................",
	"................==......................",
	"................==......................",
	"..======================================",
	"..======================================",
	"..======================================",
	".................===....................",
	".................===....................",
	".................===....................",
	"========================================",
	"========================================",
	"~~~~~~~~~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
]
const CHARS := "res://assets/art/characters/%s.png"


static func build() -> Region:
	var root := B.region(&"port_ambre", "Port-Ambre", "", Vector2i(1, 1), PLAN)
	root.path_tex = load("res://assets/art/ground/paves.png")
	root.paved_rect = Rect2(0, 8.6, 40, 16)
	root.music = load("res://assets/audio/music/plaines.ogg")
	root.ambience_id = &"port"
	root.rain_chance = 0.1
	root.mist_chance = 0.12
	var entities: Node2D = root.get_node("Entities")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1111
	B.forest_edge(entities, PLAN, rng, func(x: int, y: int) -> bool: return x >= 14 and x <= 19 and y <= 2)
	B.scatter(entities, PLAN, rng, 16, func(x: int, y: int) -> bool: return y >= 3 and y <= 8 and x >= 3 and x <= 36)

	# The houses face the street (their origin: the middle of the facade's foot).
	for p: Array in [["maison_blanche", 6.5], ["maison_jaune", 12.6], ["maison_port", 24.0], ["cabinet", 31.5]]:
		B.prop(entities, p[0], B.cell(p[1], 8.3))
	for p: Array in [
			["lanterne", 10.0, 9.0], ["lanterne", 16.2, 9.0], ["lanterne", 20.8, 9.0], ["lanterne", 27.8, 9.0],
			["bac_fleurs", 8.6, 8.7], ["bac_fleurs", 14.4, 8.7], ["tonneau", 22.2, 8.8], ["caisses", 26.4, 8.9],
			["filet", 5.0, 13.8], ["sechoir", 9.6, 13.6], ["banc", 13.6, 13.2], ["casiers", 23.6, 13.8],
			["ancre", 29.2, 13.6], ["bac_fleurs", 34.0, 13.2], ["tonneau", 35.2, 13.6],
			["bitte", 4.5, 16.8], ["bitte", 11.0, 16.8], ["bitte", 26.0, 16.8], ["bitte", 33.0, 16.8],
			["caisses", 29.6, 15.7], ["tonneau", 31.2, 15.4], ["cordage", 22.0, 16.4], ["casiers", 8.0, 15.6]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]))
	# Boats moored along the pier.
	B.prop(entities, "barque", B.cell(23.2, 20.4))
	B.prop(entities, "barque", B.cell(15.6, 19.6), true)
	B.prop(entities, "barque", B.cell(28.5, 19.2))
	B.dock(root, Rect2(18, 17, 3, 6))
	B.sign(entities, B.cell(20.8, 2.8), &"panneau_plaines", true)

	# People. The arrival scene (story/prologue.gd) moves Maïa and Isaure to the Cabinet.
	B.npc(root, "IsaureQuai", "Isaure", CHARS % "isaure", 20.3, 21.4, {"facing": "left", "hide_flag": &"prologue_arrived"})
	B.npc(root, "MaiaQuai", "Maïa", CHARS % "maia", 19.8, 15.8, {"facing": "down", "hide_flag": &"prologue_arrived"})
	B.npc(root, "Isaure", "Isaure", CHARS % "isaure", 22.6, 15.7, {"facing": "down", "dialogue": &"isaure", "show_flag": &"prologue_done"})
	# The guard of the coast road (east), at his post.
	B.npc(root, "Garde", "Le garde du Havre", CHARS % "garde", 37.6, 8.6, {"facing": "down", "dialogue": &"garde_route"})
	B.sign(entities, B.cell(36.2, 8.7), &"panneau_route_cotiere")

	B.spawn(root, "Depart", 19.0, 21.2)
	B.spawn(root, "DepuisPlaines", 17.0, 1.5)
	B.spawn(root, "DepuisCabinet", 31.5, 9.7)
	B.spawn(root, "DepuisHavre", 37.8, 10.5)
	B.exit(root, Rect2(39.45, 9.0, 0.55, 3.0), &"havre_dore", &"DepuisPort", &"sceau_plaines", &"route_cotiere")
	B.exit(root, Rect2(15.0, 0.0, 4.0, 0.55), &"plaines", &"DepuisPort", &"prologue_done", &"port_bloque")
	B.exit(root, Rect2(30.9, 8.35, 1.2, 0.5), &"cabinet", &"Depart")
	# The Grand Voyageur's stop (fast travel, story/voyage.gd): the dino, the arrival point
	# right beside him, and Hélène's sign marking the stop. Here on the quay east of the pier
	# where Chloé lands: an old adult is 7 tiles wide, and the streets of the village are too
	# narrow for him — the harbour front is the only open ground, and a ferry-beast waits there.
	B.dino_npc(root, "GrandVoyageur", &"brachiosaurus", 26.6, 15.4, {"event": &"grand_voyageur", "size": 1.6})
	B.spawn(root, "Voyageur", 23.8, 15.9)
	B.sign(entities, B.cell(27.6, 16.5), &"panneau_escale")
	return root
