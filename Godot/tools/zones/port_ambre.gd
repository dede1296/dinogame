extends RefCounted
## Port-Ambre: the fishing village where Chloé lands. A pier on the sea (south), the quay,
## the main street with the houses and Hélène's Cabinet, the path north to the Plaines, and
## east the coast road to Havre-Doré (its guard lets through only the trainers with a Sceau).

const PATH := "res://regions/port/port_ambre.tscn"
const B := preload("res://tools/zone_builder.gd")
const A := preload("res://tools/zones/apex_decor.gd")
const AP := preload("res://story/apex_places.gd")

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
	B.npc(root, "Isaure", "Isaure", CHARS % "isaure", 22.6, 15.7, {"facing": "down", "dialogue": &"isaure", "show_flag": &"prologue_done",
		"hide_flag": &"masque_tombe"})   # (chapter 7: after the mask, she is gone to the volcano)
	# Chapter 8 (story/volcan_autour.gd): Léonce home from the forges, mending the nets on the pontoon
	# (his own sheet, drawn on 19/10: no mask, a net on his arm and the shuttle in his hand; standing:
	# his sitting pose is the forges' one, the bone mask on his knee), once the great forge is out; Brac
	# at the end of it, on a cage, looking at the sea « de loin », once he has gone (« Le rouquin est
	# assis au bout de la jetée »). On its west side: the way to Maïa's boat stays free.
	B.npc(root, "Leonce", "Léonce", CHARS % ("leonce_port" if Outfits.drawn("leonce_port") else "pecheur"), 18.6, 18.6,
		{"facing": "down", "event": &"leonce_port", "show_flag": &"grande_forge_eteinte"})
	var brac := B.npc(root, "BracJetee", "Brac", CHARS % "brac", 18.6, 22.3, {"facing": "down", "event": &"brac_jetee",
		"show_flag": &"brac_parti"})
	brac.set_meta(Outfits.HELD_META, &"assis")
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
	# Maïa's boat (fast travel by sea, story/barque.gd), once she and Chloé are a team: alongside
	# the end of the pier where Chloé first landed, on its east side, Chloé on the planks beside it
	# (her dino then stands on her left, still on the pier). Far enough from the fishing boats and
	# the bollards that « interact » there means the boat.
	B.maias_boat(root, Vector2(22.1, 23.0), Vector2(20.5, 22.6))
	_epilogue(root)
	return root


## Chapter 9, the epilogue (docs/chapitre-9-scenes.md 4 d and 5, places in story/apex_places.gd). The
## evening of the tea (« tasse_bleue », until « epilogue_cabinet »): Maïa on the Cabinet's step, Caillou
## across the street. The next day (« epilogue_cabinet »), the jetty: the whole village on the quay at the
## foot of the pier, Hélène on Roc's arm before them, Isaure by her boat, Brac at the end (« BracJetee »,
## chapter 8) with his three, Dame Suie at the back. After the end (« epilogue_fini »), stay: Isaure at her
## boat, Dame Suie on the quay, Cabosse and Grognon (Brac is the night watchman); the others go home, and
## Mastoc too (by Brac on the pier, he would bar the way to Maïa's boat).
static func _epilogue(root: Region) -> void:
	var maia := A.person(root, "MaiaMarche", "Maïa", ["maia_arche"], AP.MARCHE_MAIA, {"facing": "down", "event": &"maia_marche",
		"show_flag": &"tasse_bleue", "hide_flag": &"epilogue_cabinet"})
	maia.set_meta(Outfits.HELD_META, &"assis_marche")   # sitting on the step from the start (no stone: maia_arche_assise)
	B.dino_npc(root, "CaillouRuelle", &"triceratops", AP.RUELLE_CAILLOU.x, AP.RUELLE_CAILLOU.y, {"event": &"caillou_ruelle",
		"show_flag": &"tasse_bleue", "hide_flag": &"epilogue_cabinet"})
	# [node, name, sheets, place, facing, event, gone once, stand-in's tint]
	for p: Array in [
			["HeleneJetee", "Hélène", A.HELENE, AP.JETEE_HELENE, "down", &"helene_jetee", &"epilogue_fini", Color.WHITE],
			["RocJetee", "Prof. Roc", ["roc"], AP.JETEE_ROC, "down", &"roc_jetee", &"epilogue_fini", Color.WHITE],
			["MaiaJetee", "Maïa", ["maia_arche"], AP.JETEE_MAIA, "right", &"maia_jetee", &"epilogue_fini", Color.WHITE],
			["IsaureJetee", "Isaure", ["isaure_sans_masque"], AP.JETEE_ISAURE, "right", &"isaure_jetee", &"", Color.WHITE],
			["SuieJetee", "Dame Suie", ["dame_suie"], AP.JETEE_SUIE, "down", &"suie_jetee", &"", Color.WHITE],
			["HamonJetee", "M. Hamon", ["hamon"], AP.JETEE_HAMON, "left", &"hamon_jetee", &"epilogue_fini", Color.WHITE],
			["JossJetee", "Joss", ["joss"], AP.JETEE_JOSS, "left", &"joss_jetee", &"epilogue_fini", Color.WHITE],
			["GustaveJetee", "Gustave", ["pecheur"], AP.JETEE_GUSTAVE, "right", &"gustave_jetee", &"epilogue_fini", Color.WHITE],
			["FirminJetee", "Firmin", A.FIRMIN, AP.JETEE_FIRMIN, "right", &"firmin_jetee", &"epilogue_fini", Color.WHITE],
			["RosalieJetee", "Rosalie", ["rosalie"], AP.JETEE_ROSALIE, "right", &"rosalie_jetee", &"epilogue_fini", Color.WHITE],
			["PervencheJetee", "Mémé Pervenche", ["pervenche"], AP.JETEE_PERVENCHE, "right", &"pervenche_jetee", &"epilogue_fini", Color.WHITE]]:
		var t: Vector2 = p[3]
		A.person(root, p[0], p[1], p[2], t, {"facing": p[4], "event": p[5], "show_flag": &"epilogue_cabinet", "hide_flag": p[6]}, p[7])
	# [node, species, place, flip, gone once]
	for d: Array in [["CaillouJetee", &"triceratops", AP.JETEE_CAILLOU, true, &"epilogue_fini"],
			["MastocJetee", &"allosaurus", AP.JETEE_MASTOC, true, &"epilogue_fini"], ["CabosseJetee", &"stygimoloch", AP.JETEE_CABOSSE, false, &""],
			["GrognonJetee", &"majungasaurus", AP.JETEE_GROGNON, false, &""]]:
		var t: Vector2 = d[2]
		B.dino_npc(root, d[0], d[1], t.x, t.y, {"event": StringName(String(d[0]).to_snake_case()), "flip": d[3],
			"show_flag": &"epilogue_cabinet", "hide_flag": d[4]})
