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
## Tears Roc needs for each of his gifts (PlainesAnnexes).
## The short name of each objective (what the quest tracker and the map's list show).
const TITLES := {
	"fin_plaines": "La suite de l'aventure", "alpha": "Le défi de l'Alpha", "crane": "Le Grand Crâne",
	"bosquet": "Le bosquet d'Hélène", "grotte": "La Grotte des Échos", "falaises": "La porte des falaises",
	"voleuse": "La voleuse de boussole", "boussole": "Rendre la boussole", "lunettes": "Les lunettes de Roc",
	"etang": "L'étang qui chante", "larmes_roc": "Les larmes pour Roc", "larmes": "Les larmes de l'île", "oeuf": "L'œuf de Pépite",
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
	if Game.flag(&"sceau_plaines"):
		_add(out, "fin_plaines", "Les Plaines sont à toi. La route de la Forêt Jurassique ouvrira bientôt.", &"plaines", Vector2.INF, true)
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
		var how := "" if Game.ability_user(&"charge") else " Il faut un dino qui charge : un Protoceratops, dans les herbes hautes."
		_add(out, "grotte", "La Grotte des Échos, au nord : un rocher bouche l'entrée." + how, &"plaines", BOULDER, true)
	if not Game.flag(&"ecaille_falaises"):
		var how := "" if Game.ability_user(&"resonance") else " Il faut un dino qui chante : un Parasaurolophus, à l'étang."
		_add(out, "falaises", "Les falaises, au nord-est : une porte d'ambre éteinte." + how, &"plaines", AMBER_DOOR, true)


static func _side(out: Array[Dictionary]) -> void:
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
		var n := Game.pebbles_found()
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
