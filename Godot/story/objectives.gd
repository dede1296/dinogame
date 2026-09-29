class_name Objectives
## What Chloé can do now, worked out from the story flags: the map lists them (and marks the
## ones with a place), the characters give the main one as a hint.
## An objective: {id, title (a few words), text (the details), zone (StringName), tile (Vector2,
## or Vector2.INF: no marker), main}.
## The one followed on screen (QuestTracker) is the story flag "suivi" (an id), or the nearest.
## From chapter 3 on, the places are read from the zones themselves (spot: a node's position in
## the zone's scene), so the markers follow the maps when they change.

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
const MUR := Vector2(12.0, 41.2)           # the Forêt, the cracked wall hiding the camp (west)
const PACHY := Vector2(96.0, 22.0)         # the Forêt, the rocky clearings (north-east)
const PASSERELLE := Vector2(56.5, 77.0)    # the Forêt, the trail under the Masque's walkway (futaie)
const PONT := Vector2(4.0, 12.0)           # the Forêt, the bridge to the Marais (north-west)
const MAIA_PONT := Vector2(6.0, 12.0)
const SBIRES := [Vector2(15.0, 17.0), Vector2(27.0, 17.0)]
const BRAC := Vector2(20.0, 11.0)
const UTAH := Vector2(31.0, 8.0)
const PAPIERS := Vector2(11.0, 8.0)
const TIROIR := Vector2(4.35, 3.4)         # the Cabinet, Roc's drawer (left end of his desk)
const TILE := 48.0
## The Marais's journal pages, and roughly where Hélène hid them (a direction, not the place).
const MARAIS_PAGES := [[&"found_journal_12", "dans le temple englouti"], [&"found_journal_13", "sur l'îlot aux racines, une fois la dame en gris partie"],
	[&"found_journal_14", "dans la forêt noyée"], [&"found_journal_15", "dans les chenaux, à la nage"],
	[&"found_journal_16", "au bassin des nénuphars, une nuit de pleine lune"]]
## Where the Désert's scene would be (the road north says « bientôt » until it exists).
const DESERT_SCENE := "res://regions/desert/desert.tscn"
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
	"foret": "La Forêt Jurassique", "ravin": "Le cri du ravin", "clairiere": "La clairière du chef de meute",
	"pages_foret": "Le journal dans la Forêt",
	"pachy": "Un crâne bien dur", "mur": "Le mur fissuré", "camp": "Derrière le mur", "sbires": "Les sbires du camp",
	"brac": "Brac le braconnier", "chef": "Le chef de la meute", "papiers": "Les papiers de Brac",
	"passerelle": "La passerelle des géants", "pont": "Le pont du Marais", "marais": "Le Marais Brumeux",
	"tiroir": "Retour au Cabinet", "griffe_petit": "Le petit de Griffe-Grise",
	"joss": "La cabane sur pilotis", "gilet": "Le gilet volé", "nageur": "Un dino nageur", "voix": "La Voix du Marais",
	"suie": "La dame en gris", "temple": "Le temple englouti", "vannes": "Les vannes du temple",
	"spinosaure": "Le gardien du temple", "roc_cles": "Les clés du Cabinet", "maia_3": "Le défi de la roselière",
	"desert": "Le Désert Aride", "pages_marais": "Le journal dans le Marais", "fresques": "Les fresques du temple",
	"voix_petit": "La Voix attend son petit",
}
## Nodes' places in each zone (spot), read once per zone.
static var _spots: Dictionary = {}
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
	if Game.flag(&"maia_defi_2"):
		_marais(out)
		return
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
	_forest_camp(out)


## Chapter 2, step 2: the cracked wall (Coup de crâne), Brac's camp, the pack's leader and the
## Sceau, Brac's papers, the Masque on the footbridge, Maïa at the bridge; then the Marais.
static func _forest_camp(out: Array[Dictionary]) -> void:
	if not Game.flag(&"mur_camp_brise"):
		if Game.ability_user(&"coup_crane") == null:
			_add(out, "pachy", _dome_text(), &"foret", PACHY, true)
		_add(out, "mur", "Les sillons de la clairière mènent à l'ouest, jusqu'à une paroi fendue de haut en bas. Quelque chose se cache derrière.", &"foret", MUR, true)
		return
	if not Game.flag(&"camp_arrive"):
		_add(out, "camp", "Le mur fissuré a cédé. Derrière, un passage s'enfonce dans la roche, vers l'ouest…", &"foret", MUR, true)
		return
	if not Game.flag(&"brac_battu"):
		for i in SBIRES.size():
			if not Game.flag(StringName("sbire_camp_%d_battu" % (i + 1))):
				_add(out, "sbires", "Deux sbires gardent le camp de l'Ombre Noire. Pour atteindre Brac, il faudra passer par eux.", &"camp_ombre", SBIRES[i], true)
				return
		_add(out, "brac", "Brac, le braconnier, garde le chef de la meute. Il attend près du feu, au milieu du camp.", &"camp_ombre", BRAC, true)
		return
	if not Game.flag(&"sceau_foret"):
		var mine: Dino = Foret.starter()
		var help := " Avec %s en tête, il t'écoutera mieux." % mine.nickname if mine and Game.party.has(mine) else ""
		_add(out, "chef", "Le chef de la meute est enfermé dans la grande cage, au fond du camp. Brac l'a gavé d'ambre noir : il faut l'apaiser, longtemps." + help, &"camp_ombre", UTAH, true)
	if not Game.flag(&"found_journal_11"):
		_add(out, "papiers", "Brac a laissé ses papiers sur sa table, dans le camp. Qu'est-ce qu'il préparait ?", &"camp_ombre", PAPIERS, true)
	if not Game.flag(&"sceau_foret"):
		return
	if not Game.flag(&"masque_vu"):
		var text := "« Je viendrai juger ton travail moi-même, depuis la passerelle des deux arbres géants. — M. » La haute futaie, au sud de la Forêt…" if Game.flag(&"papiers_brac_lus") \
			else "En partant, le Chef de Meute a grondé vers les arbres géants de la haute futaie, au sud-est du camp. Quelqu'un regardait ?"
		_add(out, "passerelle", text, &"foret", PASSERELLE, true)
	else:
		var text := "Le Masque est parti vers le nord-ouest, vers le vieux pont du Marais."
		if Game.flag(&"maia_pont_vue"):
			text = "Maïa t'attend au pont du Marais, au nord-ouest de la Forêt : son défi, puis elle réparera le pont."
		_add(out, "pont", text, &"foret", MAIA_PONT, true)
	_drawer(out, false)


## Roc's drawer (after the Sceau de la Forêt): main until Chloé reaches the Marais.
static func _drawer(out: Array[Dictionary], main: bool) -> void:
	if not Game.flag(&"sceau_foret") or Game.flag(&"ambre_noir_tiroir"):
		return
	var text := "Montrer le Sceau de la Forêt au Pr Roc, au Cabinet."
	if Game.flag(&"tiroir_flaire"):
		text = "Le nez collé au tiroir de Roc, ton dino a senti de la cendre froide. Qu'y a-t-il dedans ?"
	_add(out, "tiroir", text, &"cabinet", TIROIR, main)


## Chapter 3, the Marais Brumeux: Joss and his stolen vest, a swimmer, the Voix du Marais behind
## her amber door, then the temple and Dame Suie (either order), Roc after page 14, Maïa, the
## road north. Each step says where to go and how.
static func _marais(out: Array[Dictionary]) -> void:
	_drawer(out, not Game.flag(&"marais_arrivee"))
	if not Game.flag(&"marais_arrivee"):
		_add(out, "marais", "Le Marais Brumeux, au nord-ouest de la Forêt, par le pont que Maïa a réparé.", &"foret", PONT, true)
		return
	_roc_keys(out)
	if Game.flag(&"sceau_marais"):
		if not Game.flag(&"maia_defi_3"):
			_add(out, "maia_3", "Maïa t'attend dans la roselière du nord, devant la route du Désert : son défi n° 3.", &"marais", spot(&"marais", "MaiaRoseliere"), true)
		else:
			DesertObjectives.main(out)   # chapter 4, the Désert Aride (story/desert_objectives.gd)
		return
	if not Game.flag(&"gilet_nage"):
		if not Game.flag(&"joss_marais_vu"):
			_add(out, "joss", "Quelqu'un crie près de la cabane sur pilotis, à l'entrée du Marais. On dirait Joss, le sellier !", &"marais", spot(&"marais", "Joss"), true)
		else:
			_add(out, "gilet", "Un jeune Baryonyx a chipé le gilet de nage de Joss. Il joue avec sur un banc de sable, au milieu de la roselière : on y va à pied, par les pontons et la vase.", &"marais", spot(&"marais", "BaryonyxGilet"), true)
		return
	var swim := Marais.swim_step()
	if swim != "":
		_add(out, "nageur", swim, &"marais", Vector2.INF, true)
		return
	if not Game.flag(&"voix_rencontree"):
		_voice(out)
		return
	if not Game.flag(&"dame_suie_battue"):
		_add(out, "suie", "Une dame en gris cueille des racines sur l'îlot aux racines, dit Joss. On y va à la nage. Elle sent la cheminée froide…", &"marais", spot(&"marais", "DameSuie"), true)
	_temple(out)


## The Voix du Marais: the amber door of her islet (a crested dino sings it open), then her.
static func _voice(out: Array[Dictionary]) -> void:
	var swimmer: Dino = Swim.swimmer()
	var carry := " Avance dans l'eau profonde : %s te portera." % swimmer.nickname if swimmer else ""
	var echo: Dino = Marais.echo_dino()
	if Game.flag(&"porte_voix_ouverte"):
		var who := "la mère %s" % French.de(echo.nickname) if echo else "une vieille amie d'Hélène"
		_add(out, "voix", "La porte d'ambre s'est ouverte. Sur l'îlot, la Voix du Marais chante toujours : %s." % who, &"marais", spot(&"marais", "VoixDuMarais"), true)
		return
	var sing := Marais.sing_step()
	_add(out, "voix", "Au cœur de la roselière, sur un îlot, quelqu'un chante derrière une porte d'ambre." + carry + (" " + sing if sing != "" else ""),
		&"marais", spot(&"marais", "PorteVoix"), true)


## The sunken temple: its door, the three sluices one after the other, its guardian.
static func _temple(out: Array[Dictionary]) -> void:
	if not Game.flag(&"temple_arrive"):
		_add(out, "temple", "La Voix a ouvert le temple englouti : sa grande porte t'attend, sur l'île aux colonnes.", &"marais", spot(&"marais", "PorteTemple"), true)
	elif not Game.flag(&"temple_vanne_1"):
		_add(out, "vannes", "Les galeries du temple sont noyées. Dans le hall, une grande roue de pierre sort du mur : une vanne. Et si on la tournait ?", &"temple_englouti", spot(&"temple_englouti", "Vanne1"), true)
	elif not Game.flag(&"temple_vanne_2"):
		_add(out, "vannes", "La galerie ouest s'est vidée. Au bout, une deuxième vanne…", &"temple_englouti", spot(&"temple_englouti", "Vanne2"), true)
	elif not Game.flag(&"temple_vanne_3"):
		_add(out, "vannes", "La galerie est s'est vidée à son tour. Au bout, la dernière vanne !", &"temple_englouti", spot(&"temple_englouti", "Vanne3"), true)
	else:
		_add(out, "spinosaure", "L'escalier est à sec. Au fond de la grande salle, le gardien du temple attend : le Spinosaure Ancestral. (Astuce : les attaques du Vent le touchent fort.)", &"temple_englouti", spot(&"temple_englouti", "Spinosaure"), true)


## Page 14: three keys to the Cabinet. Ask Roc (at the Cabinet, or some evening in the Marais).
static func _roc_keys(out: Array[Dictionary]) -> void:
	if not Game.flag(&"found_journal_14") or Game.flag(&"roc_marais_vu"):
		return
	_add(out, "roc_cles", "Trois personnes avaient la clé du Cabinet : Hélène, Roc et « I. ». Il faut parler à Roc : au Cabinet, ou un soir dans le Marais, où une lanterne se promène parfois dans la brume.",
		&"cabinet", spot(&"cabinet", "Roc"), true)


## Side objectives of the Marais: the pages, the frescoes, the Voix waiting for her little one.
static func _marais_side(out: Array[Dictionary]) -> void:
	var missing: Array[String] = []
	for page: Array in MARAIS_PAGES:
		if not Game.flag(page[0]):
			missing.append(page[1])
	if not missing.is_empty():
		if not Game.flag(&"found_journal_16"):
			var nights := Game.nights_to_full_moon()
			missing[-1] += " (ce soir)" if Game.is_full_moon() or nights == 0 else " (dans %d nuit%s)" % [nights, "s" if nights > 1 else ""]
		var where := ", ".join(missing.slice(0, -1)) + " et " + missing[-1] if missing.size() > 1 else missing[0]
		_add(out, "pages_marais", "Pages d'Hélène dans le Marais : %d sur %d. Il en reste %s." % [MARAIS_PAGES.size() - missing.size(), MARAIS_PAGES.size(), where], &"marais")
	if Game.flag(&"temple_arrive") and not Game.flag(&"fresques_vues"):
		var seen := 0
		for i in [1, 2, 3]:
			if Game.flag(StringName("fresque_%d_vue" % i)):
				seen += 1
		_add(out, "fresques", "Les fresques du temple englouti : %d sur 3. Une dans le hall, une au bout de chaque galerie." % seen, &"temple_englouti")
	var echo: Dino = Marais.echo_dino()
	if echo and Game.flag(&"voix_rencontree") and not Game.flag(&"voix_echo_reconnu"):
		var with_her := "" if Game.party.has(echo) else " (Il attend au Cabinet : le Pr Roc peut te l'échanger.)"
		_add(out, "voix_petit", "La Voix du Marais cherche son petit. Ramène-lui %s, sur son îlot." % echo.nickname + with_her, &"marais", spot(&"marais", "VoixDuMarais"))


## Where node `node_name` of zone `zone` stands (tiles), read once from the zone's saved scene;
## Vector2.INF (no marker) when the zone or the node is not there.
static func spot(zone: StringName, node_name: String) -> Vector2:
	if not _spots.has(zone):
		_spots[zone] = _read_spots(zone)
	return (_spots[zone] as Dictionary).get(node_name, Vector2.INF)


static func _read_spots(zone: StringName) -> Dictionary:
	var out := {}
	var zones: Dictionary = (load("res://world/world.gd") as Script).get_script_constant_map().get("ZONES", {})
	var path: String = zones.get(zone, "")
	if path == "" or not ResourceLoader.exists(path):
		return out
	var scene := load(path) as PackedScene
	if scene == null:
		return out
	var state := scene.get_state()
	for i in state.get_node_count():
		for p in state.get_node_property_count(i):
			if state.get_node_property_name(i, p) == &"position":
				out[String(state.get_node_name(i))] = (state.get_node_property_value(i, p) as Vector2) / TILE
				break
	return out


## What Chloé needs for the cracked wall: a Pachycephalosaurus (Coup de crâne).
static func _dome_text() -> String:
	for d: Dino in Game.box:
		if Abilities.has(d, &"coup_crane"):
			return "Ton %s attend au Cabinet : lui saurait enfoncer le mur fissuré. Le Pr Roc peut l'échanger contre un dino de ton équipe." % d.nickname
	var full := " Ton équipe est pleine : il ira attendre au Cabinet, où Roc pourra l'échanger." if Game.party.size() >= Game.PARTY_MAX else ""
	return "Pour enfoncer le mur fissuré, il faut un crâne bien dur : un Pachycephalosaurus. Ils vivent dans les clairières rocheuses, au nord-est de la Forêt, et sortent le jour." + full


## The stolen hatchling was a Velociraptor: Griffe-Grise may know him (a side objective).
static func _forest_side(out: Array[Dictionary]) -> void:
	var little: Dino = ForetCamp.recovered()
	if little == null or ForetCamp.stolen_species() != &"velociraptor":
		return
	if Game.flag(&"griffe_grise_vu") and not Game.flag(&"griffe_vole_reconnu"):
		var with_her := "" if Game.party.has(little) else " (Il attend au Cabinet : le Pr Roc peut te l'échanger.)"
		_add(out, "griffe_petit", "Un Velociraptor d'Hélène… Griffe-Grise, dans son ravin, le reconnaîtrait peut-être." + with_her, &"foret", RAVIN)


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
		_forest_side(out)
	if Game.flag(&"marais_arrivee"):
		_marais_side(out)
	if Game.flag(&"desert_arrivee"):
		DesertObjectives.side(out)
	if Game.flag(&"cote_arrivee"):
		CoteObjectives.side(out)   # chapter 5 (story/cote_objectives.gd)
	if Game.flag(&"monts_arrivee"):
		MontsObjectives.side(out)   # chapter 6 (story/monts_objectives.gd)
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
		_add(out, "oeuf", "Porter l'œuf %s : il éclora en marchant." % French.de(String(Game.egg.get("name", "?"))), &"")
