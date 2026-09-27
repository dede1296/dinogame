class_name Objectives
## What Chloé can do now, worked out from the story flags: the map lists them (and marks the
## ones with a place), the characters give the main one as a hint.
## An objective: {id, title (a few words), text (the details), zone (StringName), tile (Vector2,
## or Vector2.INF: no marker), main}.
## The one followed on screen (QuestTracker) is the story flag "suivi" (an id), or the nearest.

const NEST := Vector2(41.0, 34.8)
const MAIA_SPOT := Vector2(62.6, 44.4)
const POND := Vector2(79.0, 47.5)
const CABINET_DOOR := Vector2(31.5, 8.8)
const PLAINES_ROAD := Vector2(17.0, 0.8)
const TRUNK := Vector2(20.0, 41.2)
const BOULDER := Vector2(58.0, 25.0)
const AMBER_DOOR := Vector2(93.0, 38.4)
const SKULL := Vector2(104.0, 62.6)
const ALPHA := Vector2(107.2, 63.8)
const COAST_ROAD := Vector2(38.6, 10.5)   # Port-Ambre, the guard of the coast road
const JOSS := Vector2(42.0, 10.2)          # Havre-Doré
const COMPTOIR := Vector2(33.0, 10.2)
const RELAIS := Vector2(22.5, 9.0)
const SKIN := Vector2(84.4, 50.2)          # the Plaines, by the pond
const MAIA_DUEL := Vector2(100.8, 65.2)    # the Plaines, at the foot of the skull
const SBIRE_2 := Vector2(16.2, 2.8)        # the Grotte des Échos, far end
const PROTO := Vector2(18.6, 3.2)
const FORET_EXIT := Vector2(1.0, 52.0)     # the Plaines, the way west into the Forêt
const RAVIN := Vector2(22.0, 80.0)         # the Forêt, Griffe-Grise's hidden ravine (south-west)
const CLAIRIERE := Vector2(24.0, 18.0)     # the Forêt, the clearing of the giant ferns (north-west)
## The Forêt's journal pages, and roughly where Hélène hid them (a direction, not the place).
const FOREST_PAGES := [[&"found_journal_7", "au cœur du sous-bois"], [&"found_journal_8", "en haut de la futaie, au sud"],
	[&"found_journal_9", "dans une clairière du nord"], [&"found_journal_10", "à la lisière, une nuit de pleine lune"]]
## Tears Roc needs for each of his gifts (PlainesAnnexes).
## The short name of each objective (what the quest tracker and the map's list show).
const TITLES := {
	"alpha": "Le défi de l'Alpha", "crane": "Le Grand Crâne",
	"bosquet": "Le bosquet d'Hélène", "grotte": "La Grotte des Échos", "falaises": "La porte des falaises",
	"voleuse": "La voleuse de boussole", "boussole": "Rendre la boussole", "lunettes": "Les lunettes de Roc",
	"etang": "L'étang qui chante", "larmes_roc": "Les larmes pour Roc", "larmes": "Les larmes de l'île", "oeuf": "L'œuf de Pépite",
	"havre": "La route du Havre", "maia": "Le défi de Maïa", "retour": "Retour au port", "selle": "Une selle pour voyager", "relais": "Le Relais des Dresseurs",
	"foret": "La Forêt Jurassique", "ravin": "Le cri du ravin", "clairiere": "La clairière du chef de meute", "fin_foret": "À suivre…",
	"pages_foret": "Le journal dans la Forêt",
}
const TEAR_GOALS := [[10, &"lanterne", "la lanterne d'ambre"], [20, &"pepite_oeuf", "réveiller le fragment"], [30, &"lettre_scellee", "une surprise"]]


static func current() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not Game.flag(&"prologue_done"):
		return out
	_main(out)
	_side(out)
	return out


## The main objective's text (a character's hint), or "" when there is none.
static func main_hint() -> String:
	for o in current():
		if o["main"]:
			return o["text"]
	return ""


static func _add(out: Array[Dictionary], id: String, text: String, zone: StringName, tile := Vector2.INF, main := false) -> void:
	out.append({"id": id, "title": TITLES.get(id, text), "text": text, "zone": zone, "tile": tile, "main": main})


## The objective to follow: the one Chloé picked on the map (flag "suivi") if it is still
## there, else the nearest one with a place in her zone, else the first.
static func followed(zone: StringName, chloe_tile: Vector2) -> Dictionary:
	var all := current()
	if all.is_empty():
		return {}
	var picked := String(Game.flag(&"suivi")) if Game.flag(&"suivi") else ""
	for o in all:
		if o["id"] == picked:
			return o
	var best: Dictionary = {}
	var best_d := INF
	for o in all:
		if o["zone"] == zone and o["tile"] != Vector2.INF:
			var d: float = (o["tile"] as Vector2).distance_to(chloe_tile) - (40.0 if o["main"] else 0.0)
			if d < best_d:
				best_d = d
				best = o
	return best if not best.is_empty() else all[0]


static func _main(out: Array[Dictionary]) -> void:
	if Game.flag(&"selle"):
		_forest(out)
		return
	if Game.flag(&"havre_arrive"):
		_saddle(out)
		return
	if Game.flag(&"sceau_plaines") and not Game.flag(&"maia_defi_1"):
		_add(out, "maia", "Maïa veut sa revanche : son défi t'attend au pied du Grand Crâne.", &"plaines", MAIA_DUEL, true)
		return
	if Game.flag(&"maia_defi_1") and not Game.flag(&"found_journal_6"):
		var text := "Rentrer à Port-Ambre raconter ta victoire au Pr Roc." if not Game.flag(&"roc_parti_vu") \
			else "Roc est parti vers le volcan… Entrer dans le Cabinet resté ouvert."
		_add(out, "retour", text, &"port_ambre", CABINET_DOOR, true)
		return
	if Game.flag(&"sceau_plaines"):
		_add(out, "havre", "Havre-Doré, par la route côtière à l'est de Port-Ambre. Le garde laisse passer ceux qui portent un Sceau.", &"port_ambre", COAST_ROAD, true)
		return
	if Game.flag(&"crane_ouvert"):
		_add(out, "alpha", "Relever le défi du Tricératops Alpha, devant le Grand Crâne.", &"plaines", ALPHA, true)
		return
	if DialogueDB.ecailles() >= 3:
		_add(out, "crane", "Poser les trois écailles d'ambre dans le Grand Crâne, au sud-est.", &"plaines", SKULL, true)
		return
	if not Game.flag(&"ecaille_bosquet"):
		var how := "" if Game.ability_user(&"tranche") else " Il faut un dino qui tranche : un Velociraptor, aux lisières au crépuscule."
		_add(out, "bosquet", "Le bosquet d'Hélène, à l'ouest : un tronc barre le chemin." + how, &"plaines", TRUNK, true)
	if not Game.flag(&"ecaille_grotte"):
		if Game.flag(&"proto_apaise"):
			_add(out, "grotte", "Ramasser l'écaille d'ambre, au fond de la Grotte des Échos.", &"grotte_echos", PROTO, true)
		elif Game.flag(&"sbire_grotte_2"):
			_add(out, "grotte", "Apaiser le Protoceratops corrompu, au fond de la Grotte des Échos.", &"grotte_echos", PROTO, true)
		elif Game.flag(&"sbire_grotte_1"):
			_add(out, "grotte", "Un autre sbire de l'Ombre Noire pille le fond de la Grotte des Échos.", &"grotte_echos", SBIRE_2, true)
		else:
			var how := "" if Game.ability_user(&"charge") else " Il faut un dino qui charge : un Protoceratops, dans les herbes hautes."
			_add(out, "grotte", "La Grotte des Échos, au nord : un rocher bouche l'entrée." + how, &"plaines", BOULDER, true)
	if not Game.flag(&"ecaille_falaises"):
		var how := "" if Game.ability_user(&"resonance") else " Il faut un dino qui chante : un Parasaurolophus, à l'étang."
		_add(out, "falaises", "Les falaises, au nord-est : une porte d'ambre éteinte." + how, &"plaines", AMBER_DOOR, true)


## The saddle: ask Joss, bring him the moulted skin and an amber buckle.
static func _saddle(out: Array[Dictionary]) -> void:
	if not Game.flag(&"selle_demandee"):
		_add(out, "selle", "Joss, le sellier de Havre-Doré, peut te fabriquer une selle.", &"havre_dore", JOSS, true)
	elif Game.item_count("cuir") == 0:
		_add(out, "selle", "Trouver du cuir mué de Parasaurolophus, au bord de l'étang des Plaines, pour Joss.", &"plaines", SKIN, true)
	elif Game.item_count("boucle") == 0:
		_add(out, "selle", "Acheter une boucle d'ambre au Comptoir de Ferréol, pour Joss.", &"havre_dore", COMPTOIR, true)
	elif Game.coins() < Havre.SADDLE_PRICE:
		_add(out, "selle", "Réunir %d pièces pour le travail de Joss (tu en as %d) : les dresseurs du Relais, la revente au Comptoir." % [Havre.SADDLE_PRICE, Game.coins()], &"havre_dore", RELAIS, true)
	else:
		_add(out, "selle", "Rapporter le cuir, la boucle et les pièces à Joss.", &"havre_dore", JOSS, true)


## Chapter 2, the Forêt Jurassique (step 1): getting there, Griffe-Grise, the empty clearing.
static func _forest(out: Array[Dictionary]) -> void:
	if not Game.flag(&"foret_arrivee"):
		var mount := "" if Game.ability_user(&"monture") else " Pour monter, il te faudra un grand dino adulte (niveau %d)." % Abilities.ADULT_LEVEL
		_add(out, "foret", "La Forêt Jurassique, par la sortie ouest des Plaines. En selle, ses chemins immenses deviennent enfin praticables." + mount, &"plaines", FORET_EXIT, true)
		return
	if not Game.flag(&"griffe_grise_vu"):
		var vif: Dino = Foret.vif_dino()
		var text := "Un cri grave, venu d'un ravin au sud-ouest de la Forêt, a fait taire toute la meute. Qui a bien pu le pousser ?"
		if Game.flag(&"clairiere_vue"):
			text = "Quelqu'un a emmené le chef de la meute. Celui qui a crié dans le ravin du sud-ouest sait peut-être qui."
		elif vif:
			text = "Un cri grave est monté d'un ravin caché, au sud-ouest de la Forêt. Griffe-Grise, le père %s, vivrait là." % French.de(vif.nickname)
		_add(out, "ravin", text, &"foret", RAVIN, true)
		return
	if not Game.flag(&"clairiere_vue"):
		_add(out, "clairiere", "Griffe-Grise regarde vers le nord-ouest : la clairière aux fougères géantes, où vivait le chef de la meute.", &"foret", CLAIRIERE, true)
		return
	_add(out, "fin_foret", "Qui a emmené le chef de la meute ? Les sillons de la clairière filent vers l'ouest… (La suite de l'aventure arrive bientôt !)", &"foret", Vector2.INF, true)


## The Forêt's journal pages still to find, with a direction for each (not the exact place).
static func _forest_pages(out: Array[Dictionary]) -> void:
	var missing: Array[String] = []
	for page: Array in FOREST_PAGES:
		if not Game.flag(page[0]):
			missing.append(page[1])
	if missing.is_empty():
		return
	var moon := Game.is_full_moon() or Game.nights_to_full_moon() == 0
	if not Game.flag(&"found_journal_10"):
		var nights := Game.nights_to_full_moon()
		missing[-1] += " (ce soir)" if moon else " (dans %d nuit%s)" % [nights, "s" if nights > 1 else ""]
	var where := ", ".join(missing.slice(0, -1)) + " et " + missing[-1] if missing.size() > 1 else missing[0]
	_add(out, "pages_foret", "Pages d'Hélène dans la Forêt : %d sur %d. Il en reste %s." % [FOREST_PAGES.size() - missing.size(), FOREST_PAGES.size(), where], &"foret")


static func _side(out: Array[Dictionary]) -> void:
	if Game.flag(&"foret_arrivee"):
		_forest_pages(out)
	if Game.flag(&"havre_arrive") and not (Game.flag(&"gaspard_battu") and Game.flag(&"lilou_battu")):
		_add(out, "relais", "Affronter les dresseurs du Relais : Gaspard (rang Bronze), puis Lilou (rang Argent).", &"havre_dore", RELAIS)
	if Game.flag(&"boussole_volee") and not Game.flag(&"boussole_trouvee"):
		_add(out, "voleuse", "Rattraper la voleuse de boussole : elle file vers le petit bois, au nord-ouest du carrefour.", &"plaines", NEST)
	if Game.flag(&"boussole_trouvee") and not Game.flag(&"boussole_rendue"):
		_add(out, "boussole", "Rendre la boussole à Maïa, au carrefour.", &"plaines", MAIA_SPOT)
	if Game.flag(&"lunettes_trouvees") and not Game.flag(&"lunettes_rendues"):
		_add(out, "lunettes", "Rapporter ses lunettes au Professeur Roc, au Cabinet de Port-Ambre.", &"port_ambre", CABINET_DOOR)
	if Game.flag(&"boussole_rendue") and not Game.flag(&"found_journal_2"):
		var when := "ce soir" if Game.is_full_moon() or Game.nights_to_full_moon() == 0 else "dans %d nuits" % Game.nights_to_full_moon()
		_add(out, "etang", "L'étang chanterait les soirs de pleine lune (%s)." % when, &"plaines", POND)
	if Game.flag(&"larmes_expliquees"):
		var n := Game.tears()
		for goal: Array in TEAR_GOALS:
			if Game.flag(goal[1]):
				continue
			if n >= goal[0]:
				_add(out, "larmes_roc", "Montrer tes %d larmes de l'île au Professeur Roc." % n, &"port_ambre", CABINET_DOOR)
			else:
				_add(out, "larmes", "Larmes de l'île : %d. À %d, Roc promet %s." % [n, goal[0], goal[2]], &"plaines")
			break
	if not Game.egg.is_empty():
		_add(out, "oeuf", "Porter l'œuf de %s : il éclora en marchant." % Game.egg.get("name", "?"), &"")
