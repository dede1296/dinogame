class_name DesertObjectives
## Chapter 4, the Désert Aride: what Chloé can do now (Objectives.current() calls main() and
## side() once chapter 3 is over: sceau_marais and maia_defi_3). Each step says where to go and
## how (a dino with Flair, a dino that charges, the fossils and the pages still to find): never
## stuck without knowing why. Same objectives as Objectives._add, with the chapter's own titles.

const P := preload("res://story/desert_places.gd")
## The short name of each objective (the quest tracker, the map's list).
const TITLES := {
	"desert": "Le Désert Aride", "traces": "Les traces du chariot", "sirocco": "La tente du cimetière",
	"rempart": "Le canyon muré", "brac_porte": "Le sanctuaire des Vents", "brac_desert": "La tempête du canyon",
	"carnotaurus": "Le Carnotaurus Rouge", "chariot": "Le chariot de Brac", "coeur_2": "Le deuxième Cœur",
	"maia_4": "Le défi de l'oasis", "cote": "Vers la Côte", "fossiles": "Les fossiles de Sirocco",
	"pages_desert": "Le journal dans le Désert", "rempart_petit": "Le petit du Vieux Rempart",
}


## Where node `node_name` of the Désert stands (read from the zone), else `fallback`.
static func _at(node_name: String, fallback: Vector2) -> Vector2:
	return P.spot(&"desert", node_name, fallback)


static func _add(out: Array[Dictionary], id: String, text: String, zone: StringName, tile := Vector2.INF, is_main := false) -> void:
	out.append({"id": id, "title": TITLES.get(id, text), "text": text, "zone": zone, "tile": tile, "main": is_main})


## The main steps, the most advanced first: the Côte, Maïa and the Cœur, the Carnotaurus, the
## chase, then Sirocco, the Vieux Rempart and the sanctuary.
static func main(out: Array[Dictionary]) -> void:
	if not Game.flag(&"desert_arrivee"):
		_add(out, "desert", "Maïa est partie devant, vers le Désert Aride : la route du nord, au bout de la roselière du Marais.", &"marais", P.spot(&"marais", "DepuisDesert", P.MARAIS_NORD), true)
		return
	if Game.flag(&"maia_defi_4"):
		_add(out, "cote", "La Côte Préhistorique, au nord, là où les dunes finissent en plages. (La suite de l'aventure arrive bientôt !)", &"desert", _at("DepuisCote", P.SORTIE_COTE), true)
		return
	if Game.flag(&"sceau_desert"):
		if not Game.flag(&"coeur_2"):
			var inside: bool = Game.region_id == &"sanctuaire_vents"
			_add(out, "coeur_2", "La porte des Vents est ouverte. Au fond du sanctuaire, le deuxième Cœur d'Hélène attend.",
				&"sanctuaire_vents" if inside else &"desert", P.spot(&"sanctuaire_vents", "Autel", P.AUTEL) if inside else _at("PorteVents", P.PORTE_VENTS), true)
		_add(out, "maia_4", "Maïa t'attend à l'oasis, au nord-est, pour son défi n° 4. Elle a une surprise… une ÉNORME surprise.", &"desert", _at("MaiaOasis", P.MAIA_OASIS), true)
		return
	if Game.flag(&"brac_desert_battu"):
		_add(out, "carnotaurus", _carno_text(), &"desert", _at("CarnotaurusRouge", P.CARNO), true)
		return
	if Game.flag(&"brac_desert_vu"):
		_add(out, "brac_desert", "Brac s'est enfui dans le canyon des Vents, à l'ouest du sanctuaire, avec le Carnotaurus Rouge. Suis-le dans la tempête : le canyon finit en cul-de-sac.", &"desert", _at("BracDesert", P.BRAC_DESERT), true)
		return
	if not Game.flag(&"sirocco_vue"):
		_add(out, "traces", "Des traces de roues et de grosses pattes traversent le Désert. Au bord du Cimetière des Géants, une tente fume : quelqu'un a peut-être vu passer Brac.", &"desert", _at("Sirocco", P.SIROCCO), true)
		return
	if not Game.flag(&"rempart_rencontre"):
		_rempart(out, true)
	_add(out, "brac_porte", "Tante Sirocco a vu passer Brac avec un grand dino rouge aux yeux violets, enchaîné, vers le sanctuaire des Vents, au nord.", &"desert", _at("DepuisSanctuaire", P.PLACE_SANCTUAIRE), true)


## The side steps: Sirocco's fossils, the pages, the Vieux Rempart once the chase has begun,
## Brac's cart, and the stolen hatchling when it was Bastion.
static func side(out: Array[Dictionary]) -> void:
	if not Game.flag(&"desert_arrivee"):
		return
	_fossils(out)
	_pages(out)
	if Game.flag(&"brac_desert_vu") and not Game.flag(&"sirocco_vue"):
		_add(out, "sirocco", "Une tente fume au bord du Cimetière des Géants. Qui peut bien vivre là, au milieu des os ?", &"desert", _at("Sirocco", P.SIROCCO))
	if Game.flag(&"brac_desert_vu") and Game.flag(&"sirocco_vue") and not Game.flag(&"rempart_rencontre"):
		_rempart(out, false)
	if Game.flag(&"brac_desert_battu") and not Game.flag(&"chariot_fouille"):
		_add(out, "chariot", "Le chariot de Brac est resté au fond du canyon des Vents. Qu'est-ce qu'il transportait ?", &"desert", _at("ChariotBrac", P.CHARIOT))
	_rempart_little(out)


## The walled canyon: the fallen rocks (a dino that charges), then the Vieux Rempart.
static func _rempart(out: Array[Dictionary], is_main: bool) -> void:
	if Game.flag(&"rempart_ouvert"):
		_add(out, "rempart", "Les éboulis ont cédé. Au fond du canyon muré, quelque chose d'énorme respire, lentement…", &"desert", _at("VieuxRempart", P.VIEUX_REMPART), is_main)
		return
	var bastion: Dino = bastion_dino()
	var text := "Dans le canyon muré, à l'ouest, dort le Vieux Rempart, la vieille Ankylosaurus d'Hélène. Des éboulis bouchent l'entrée."
	if bastion:
		text = "Le canyon muré, à l'ouest : la mère %s, le Vieux Rempart, y dort derrière des éboulis." % French.de(bastion.nickname)
	_add(out, "rempart", text + _charge_how(), &"desert", _at("RempartEboulis", P.REMPART_EBOULIS), is_main)


## Who can charge the fallen rocks: a dino of the party, of the Cabinet, or where to find one.
static func _charge_how() -> String:
	var horn := Game.ability_user(&"charge")
	if horn:
		return " Ton %s sait charger : un bon coup de tête, et ça passera." % horn.nickname
	for d: Dino in Game.box:
		if Abilities.has(d, &"charge"):
			return " Ton %s attend au Cabinet : lui saurait charger. Le Pr Roc peut te l'échanger." % d.nickname
	return " Il faut un dino qui charge : un Pinacosaurus des dunes, un Protoceratops, un Tricératops…"


## Calming the Carnotaurus: heal first, her own hatchling in front.
static func _carno_text() -> String:
	var text := "Le Carnotaurus Rouge est libre, mais fou de peur, près du chariot de Brac. Il faut l'apaiser, longtemps : soigne ton équipe d'abord."
	var mine: Dino = Foret.starter()
	if mine and Game.party.has(mine):
		text += " Avec %s en tête, il t'écoutera mieux." % mine.nickname
	return text


## Tante Sirocco's fossils: how many, and what it takes (a dino with Flair).
static func _fossils(out: Array[Dictionary]) -> void:
	if not Game.flag(&"sirocco_vue") or Game.flag(&"fossiles_rendus"):
		return
	var n := P.fossils_found()
	if n >= P.FOSSILS_WANTED:
		_add(out, "fossiles", "Tu as %d fossiles ! Tante Sirocco t'attend devant sa tente, au bord du Cimetière des Géants." % n, &"desert", _at("Sirocco", P.SIROCCO))
		return
	var how := ""
	if Game.ability_user(&"flair") == null:
		how = " Il faut un dino qui a du flair : un Oviraptor (dans les nids des canyons, le jour), un Compsognathus ou un Troodon."
		for d: Dino in Game.box:
			if Abilities.has(d, &"flair"):
				how = " Ton %s a du flair, mais il attend au Cabinet : le Pr Roc peut te l'échanger." % d.nickname
				break
	_add(out, "fossiles", "Fossiles pour Tante Sirocco : %d sur %d (six sont enfouis dans le Cimetière des Géants)." % [n, P.FOSSILS_WANTED] + how, &"desert", P.CIMETIERE)


## The Désert's journal pages still to find, with a direction for each (not the exact place).
static func _pages(out: Array[Dictionary]) -> void:
	var missing: Array[String] = []
	for page: Array in P.PAGES:
		if not Game.flag(page[0]):
			missing.append(page[1])
	if missing.is_empty():
		return
	var where := ", ".join(missing.slice(0, -1)) + " et " + missing[-1] if missing.size() > 1 else missing[0]
	_add(out, "pages_desert", "Pages d'Hélène dans le Désert : %d sur %d. Il en reste %s." % [P.PAGES.size() - missing.size(), P.PAGES.size(), where], &"desert")


## Her little one was not with Chloé when she met the Vieux Rempart (Bastion waiting at the
## Cabinet, or the stolen hatchling when it was Bastion): take him to his mother.
static func _rempart_little(out: Array[Dictionary]) -> void:
	var little: Dino = bastion_dino()
	if little == null or not Game.flag(&"rempart_rencontre") or Game.flag(&"rempart_bastion_reconnu"):
		return
	var with_her := "" if Game.party.has(little) else " (Il attend au Cabinet : le Pr Roc peut te l'échanger.)"
	var text := "Le Vieux Rempart a senti l'odeur %s sur tes mains. Emmène-le la voir, au fond du canyon muré." % French.de(little.nickname)
	if str(Game.flag(&"starter")) != "ankylosaurus":
		text = "Un Ankylosaurus d'Hélène… Le Vieux Rempart, au fond du canyon muré, reconnaîtrait peut-être %s." % little.nickname
	_add(out, "rempart_petit", text + with_her, &"desert", _at("VieuxRempart", P.VIEUX_REMPART))


## Chloé's Ankylosaurus from the Cabinet (the Vieux Rempart's little one): her own hatchling
## when she chose Bastion, or the stolen one, found again in the Forêt; null otherwise.
static func bastion_dino() -> Dino:
	if str(Game.flag(&"starter")) == "ankylosaurus":
		return Foret.starter()
	if ForetCamp.stolen_species() == &"ankylosaurus":
		return ForetCamp.recovered()
	return null
