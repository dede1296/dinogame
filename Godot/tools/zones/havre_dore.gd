extends RefCounted
## Havre-Doré: the merchant town of the south-east bay, at the end of the coast road from
## Port-Ambre (west). Two paved streets between the hills (north) and the harbour (south),
## the market square in the middle; the shops on the upper street (the herbalist, the
## haberdasher, the Relais des Dresseurs, Ferréol's Comptoir d'Ambre, Joss's saddlery), the
## Comptoir's warehouse on the quay. See docs/lore.md « Havre-Doré » and story/havre.gd.
## (Its own buildings in real 3D, tools/modeles3d/maisons.py; provisional: tinted characters.)

const PATH := "res://regions/havre/havre_dore.tscn"
const B := preload("res://tools/zone_builder.gd")
const CHARS := "res://assets/art/characters/%s.png"
const STORY_PROP := "res://world/story_prop.gd"
const FLAGGED_PROP := "res://tools/zones/flagged_prop.gd"
## The Anurognathus on Ferréol's chest: its picture raised onto the lid (px; the chest ~0.6 m up).
const ANURO_LIFT := 26.0

const PLAN := [
	"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
	"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
	"........................................................",
	"........................................................",
	"........................................................",
	"........................................................",
	"........................................................",
	"........................................................",
	"........................................................",
	"========================================================",
	"========================================================",
	"========================================================",
	"....==................============................==....",
	"....==................============................==....",
	"....==................============................==....",
	"....==................============................==....",
	"....==................============................==....",
	"....==................============................==....",
	"..====================================================..",
	"..====================================================..",
	"========================================================",
	"========================================================",
	"========================================================",
	"~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~===~~~~~~~",
	"~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~===~~~~~~~",
	"~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~===~~~~~~~",
	"~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~===~~~~~~~",
	"~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~===~~~~~~~",
	"~~~~~~~~~~===~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~===~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~===~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
]


static func build() -> Region:
	var root := B.region(&"havre_dore", "Havre-Doré", "", Vector2i(1, 1), PLAN)
	root.path_tex = load("res://assets/art/ground/paves.png")
	root.paved_rect = Rect2(0, 9, 56, 14)
	root.music = load("res://assets/audio/music/village.ogg")
	root.ambience_id = &"port"
	root.rain_chance = 0.1
	root.mist_chance = 0.08
	var entities: Node2D = root.get_node("Entities")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	B.forest_edge(entities, PLAN, rng, func(x: int, y: int) -> bool: return y >= 8)
	B.scatter(entities, PLAN, rng, 18, func(x: int, y: int) -> bool: return y >= 7 and y <= 8)
	_buildings(entities)
	_decor(entities)
	_people(root)
	B.dock(root, Rect2(10, 23, 3, 6))
	B.dock(root, Rect2(46, 23, 3, 7))
	B.spawn(root, "Depart", 3.0, 10.5)
	B.spawn(root, "DepuisPort", 1.8, 10.5)
	B.exit(root, Rect2(0.0, 9.0, 0.55, 3.0), &"port_ambre", &"DepuisHavre")
	_clins_doeil(root, entities)
	# The Grand Voyageur's stop (fast travel, story/voyage.gd): the dino, the arrival point
	# right beside him, and Hélène's sign marking the stop. Here at the west end of the quay,
	# below the way in from Port-Ambre and well clear of the market: the streets above are
	# hemmed in by the houses, the quay is the only open ground a sauropod fits on.
	B.dino_npc(root, "GrandVoyageur", &"brachiosaurus", 4.8, 21.2, {"event": &"grand_voyageur", "size": 1.6})
	B.spawn(root, "Voyageur", 7.4, 20.6)
	B.sign(entities, B.cell(3.0, 22.4), &"panneau_escale")
	return root


## Winks at a famous dinosaur film (29/09; docs/histoire.md « Clins d'œil », story/clins_doeil.gd):
## Ferréol's iron-bound chest before his window, an Anurognathus perched on its lid (« T'as pas dit
## le mot magique ! »); Mémé Pervenche's kitchen table in the lane behind her shop, and the
## circle round it where, once a day, two Compsognathus come for the biscuits.
static func _clins_doeil(root: Region, entities: Node2D) -> void:
	if Prop.KINDS.has("coffre_comptoir"):
		B.prop(entities, "coffre_comptoir", B.cell(31.2, 9.0))
		# Just in front of the chest (so it is the one talked to), up on its lid.
		B.dino_npc(root, "Anurognathus", &"anurognathus", 31.2, 9.04, {"event": &"anurognathus_coffre", "lift": ANURO_LIFT})
	if Prop.KINDS.has("table_cuisine"):
		# (in the lane between her shop and the haberdashery, x 8.9-10.6: in sight from the street, the
		# forest at its end; the west side of her shop is all trees, they would hide it)
		B.prop(entities, "table_cuisine", B.cell(9.75, 4.9))
		B.trigger(root, 9.75, 6.6, 1.0, &"cuisine_compsos", {"name": "CuisinePervenche"})
	# Mémé Pervenche's goat, stolen by Brac's henchmen to bait the forest's Ancien: home again in
	# her lane, below the table, once Brac is beaten (she chewed through her rope and walked back).
	# At the mouth of the lane, on the street side (deeper in, the houses hide her): between the two
	# shops (their walls stand at x 8.8 and 11.0), just below them, facing her mistress's door.
	if Prop.KINDS.has("chevre"):
		var goat = B.prop(entities, "chevre", B.cell(9.8, 11.3), true, load(FLAGGED_PROP))
		goat.name = "ChevrePervenche"
		goat.show_flag = &"brac_battu"
	# « Les visiteurs » come by boat (story/visiteurs.gd), once their sheets are drawn: M. Hamon by
	# the square's east bench, looking at the sea; Ivan Malcombe on the quay, counting the waves.
	for v: Array in [["Hamon", "M. Hamon", "hamon", 34.2, 16.6, &"hamon"], ["Malcombe", "Ivan Malcombe", "malcombe", 24.5, 22.2, &"malcombe"]]:
		if ResourceLoader.exists(CHARS % v[2]):
			B.npc(root, v[0], v[1], CHARS % v[2], v[3], v[4], {"facing": "down", "event": v[5]})


## The buildings face the street below them (their origin: the middle of the facade's foot).
## The shops and the Relais are story props: talking to the facade is talking to the house.
static func _buildings(entities: Node2D) -> void:
	for b: Array in [
			["havre_herboristerie", 6.0, 8.3, false, &"shop_herboristerie", "Herboristerie"],
			["havre_mercerie", 13.5, 8.3, false, &"shop_mercerie", "Mercerie"],
			["havre_relais", 22.5, 8.3, false, &"relais", "Relais"],
			["havre_comptoir", 33.0, 8.3, true, &"ferreol", "Comptoir"],
			["havre_sellerie", 42.0, 8.3, false, &"joss", "Sellerie"],
			["havre_entrepot", 48.5, 17.3, true, &"entrepot", "Entrepot"]]:
		var p = B.prop(entities, b[0], B.cell(b[1], b[2]), b[3], load(STORY_PROP))
		p.name = b[5]
		p.event = b[4]
	for h: Array in [["havre_maison_1", 49.5, 8.3, true], ["havre_maison_2", 6.0, 17.3, true], ["havre_maison_3", 13.5, 17.3, false],
			["havre_maison_4", 40.0, 17.3, true]]:
		B.prop(entities, h[0], B.cell(h[1], h[2]), h[3])
	# (the Entrepôt is 9 m wide: its sign stands past its right corner)
	for s: Array in [[9.0, 8.7, &"enseigne_herboristerie"], [16.3, 8.7, &"enseigne_mercerie"], [26.4, 8.7, &"enseigne_relais"],
			[29.2, 8.7, &"enseigne_comptoir"], [45.0, 8.7, &"enseigne_sellerie"], [53.0, 17.7, &"enseigne_entrepot"]]:
		B.sign(entities, B.cell(s[0], s[1]), s[2])


static func _decor(entities: Node2D) -> void:
	for p: Array in [
			["etal_fruits", 25.0, 14.2], ["etal_poisson", 30.8, 14.2], ["banc", 23.4, 16.9], ["banc", 32.4, 16.9],
			["bac_fleurs", 22.6, 12.6], ["bac_fleurs", 33.4, 12.6], ["tonneau", 27.9, 16.6], ["caisses", 21.4, 15.6],
			["lanterne", 10.0, 8.9], ["lanterne", 18.0, 8.9], ["lanterne", 28.0, 8.9], ["lanterne", 38.0, 8.9], ["lanterne", 46.0, 8.9],
			["lanterne", 18.0, 17.9], ["lanterne", 36.0, 17.9], ["bac_fleurs", 3.0, 8.7], ["bac_fleurs", 53.0, 8.7],
			["caisses", 44.6, 17.9], ["tonneau", 45.8, 17.7], ["caisses", 44.2, 21.9], ["tonneau", 45.3, 21.8], ["caisses", 51.0, 21.4], ["tonneau", 52.4, 21.2], ["caisses", 38.0, 21.4],
			["filet", 8.0, 21.8], ["casiers", 15.0, 21.8], ["cordage", 20.0, 22.3], ["ancre", 28.0, 21.8], ["sechoir", 33.0, 21.6],
			["bitte", 6.0, 22.8], ["bitte", 18.0, 22.8], ["bitte", 30.0, 22.8], ["bitte", 40.0, 22.8], ["bitte", 54.0, 22.8]]:
		B.prop(entities, p[0], B.cell(p[1], p[2]))
	B.prop(entities, "barque", B.cell(15.0, 24.2))
	B.prop(entities, "barque", B.cell(22.0, 24.6), true)
	B.prop(entities, "barque", B.cell(35.0, 24.3))
	B.prop(entities, "barque", B.cell(52.0, 24.8), true)


## The people of the town (provisional: tinted sheets of other characters).
static func _people(root: Region) -> void:
	B.npc(root, "Pervenche", "Mémé Pervenche", CHARS % "pervenche", 6.0, 9.5, {"facing": "down", "event": &"shop_herboristerie"})
	B.npc(root, "Rosalie", "Rosalie", CHARS % "rosalie", 13.5, 9.5, {"facing": "down", "event": &"shop_mercerie"})
	B.npc(root, "Ferreol", "Maître Ferréol", CHARS % "ferreol", 33.0, 9.6, {"facing": "down", "event": &"ferreol"})
	B.npc(root, "Joss", "Joss", CHARS % "joss", 42.0, 9.6, {"facing": "down", "event": &"joss"})
	B.npc(root, "Maia", "Maïa", CHARS % "maia", 24.6, 9.9, {"facing": "down", "event": &"maia_havre"})
	B.npc(root, "Gaspard", "Gaspard", CHARS % "gaspard", 19.6, 11.2, {"facing": "right", "event": &"dresseur_gaspard"})
	B.npc(root, "Lilou", "Lilou", CHARS % "lilou", 26.4, 11.2, {"facing": "left", "event": &"dresseur_lilou"})
	B.npc(root, "Marchande", "La marchande", CHARS % "marchande", 27.6, 15.0, {"facing": "down", "event": &"marchande"})
	B.npc(root, "Pecheur", "Un pêcheur", CHARS % "pecheur", 11.6, 21.4, {"facing": "down", "dialogue": &"pecheur_havre"})
