class_name CoteObjectives
## Chapter 5, the Côte Préhistorique: what Chloé can do now (DesertObjectives.main calls main()
## once the way north is open — cote_annonce —, Objectives._side calls side() once on the Côte).
## Each step says where to go and what is missing (the mask, a grown diver, a diver waiting at
## the Cabinet, the pass): never stuck without knowing why. Same objectives as Objectives._add,
## with the chapter's own titles; the places are read from the zones (CotePlaces.spot).

const P := preload("res://story/cote_places.gd")
const CS := preload("res://story/cote_stage.gd")
## The short name of each objective (the quest tracker, the map's list).
const TITLES := {
	"cote": "La Côte Préhistorique", "pecheurs": "Les pêcheurs de la plage", "maia_falaises": "Maïa aux falaises",
	"joss_cote": "Le lagon", "plongeur": "Un dino plongeur", "grottes": "Les grottes marines", "plonger": "Le passage noyé",
	"passeur": "Le Passeur", "caisses": "Les caisses de la cache", "barque": "La barque du quai", "page_21": "Une page dans la cache",
	"recif": "La passe du récif", "mosasaure": "Le gardien du récif", "coeur_3": "Le troisième Cœur", "belvedere": "Le belvédère",
	"monts": "Vers les Monts Gelés", "pages_cote": "Le journal sur la Côte", "tortues": "Les petites tortues",
	"entrepot": "L'entrepôt du Comptoir", "roc_cote": "Retour au Cabinet",
}


static func _add(out: Array[Dictionary], id: String, text: String, zone: StringName, tile := Vector2.INF, is_main := false) -> void:
	out.append({"id": id, "title": TITLES.get(id, text), "text": text, "zone": zone, "tile": tile, "main": is_main})


## Where node `node_name` of zone `zone` stands (read from the zone), else `fallback`.
static func _at(zone: StringName, node_name: String, fallback: Vector2) -> Vector2:
	return P.spot(zone, node_name, fallback)


## The main steps, the most advanced first.
static func main(out: Array[Dictionary]) -> void:
	if not Game.flag(&"cote_arrivee"):
		_add(out, "cote", "La Côte Préhistorique, au nord : le vent a tourné, et la piste descend enfin vers la mer.", &"desert", P.spot(&"desert", "DepuisCote", Vector2(100.0, 1.0)), true)
		return
	if Game.flag(&"maia_enfuie"):
		MontsObjectives.main(out)   # chapter 6, the Monts Gelés (story/monts_objectives.gd)
		return
	if Game.flag(&"coeur_3"):
		var text := "Moustique est venu te chercher. Maïa t'attend au belvédère des falaises, au-dessus de la crique." if Game.flag(&"moustique_vu") \
			else "Le troisième Cœur bat dans ta sacoche. Maïa voulait son défi au belvédère des falaises, « avec la mer derrière elle »."
		_add(out, "belvedere", text, &"cote", _at(&"cote", "MaiaGuet", P.BELVEDERE), true)
		return
	if Game.flag(&"mosasaure_battu"):
		_add(out, "coeur_3", "Le gardien du récif t'a acceptée. L'autel, au fond du sanctuaire, s'ouvre pour toi.", &"recif_sanctuaire", _at(&"recif_sanctuaire", "Autel", P.AUTEL), true)
		return
	if Game.flag(&"passe_recif"):
		_reef(out)
		_cache_left(out, false)
		return
	_maia_early(out)
	if not Game.flag(&"pecheurs_vus"):
		_add(out, "pecheurs", "Sur la plage aux tortues, deux pêcheurs réparent un filet près d'une barque échouée. Ils ont peut-être vu passer la barque sans lanterne.", &"cote", _at(&"cote", "Gustave", P.PLAGE_TORTUES), true)
		return
	if not Game.flag(&"joss_cote_vu"):
		_add(out, "joss_cote", "Joss est au lagon, « la tête dans un bocal », disent les pêcheurs. Sur la rive sud, près de la roche plate.", &"cote", _at(&"cote", "JossCote", P.BORD_PLESIOSAURE), true)
		return
	if not Game.flag(&"cache_vue"):
		_caves(out)
		return
	if not Game.flag(&"passeur_battu"):
		_add(out, "passeur", "Le Passeur garde la cache, au fond des grottes. Il veut voir ce que tu vaux.", &"grottes_marines", _at(&"grottes_marines", "Passeur", P.QUAI), true)
		return
	_cache_left(out, true)


## Maïa on the cliffs, from the arrival until she is met (main, alongside the others).
static func _maia_early(out: Array[Dictionary]) -> void:
	if Game.flag(&"maia_falaises_vue"):
		return
	_add(out, "maia_falaises", "Moustique se chamaille avec les Ptéranodons, là-haut : Maïa est aux falaises de l'est.", &"cote", _at(&"cote", "MaiaFalaises", P.SOMMET), true)


## The caves: the cove under the cliffs, then the flooded passage (and what is missing to dive).
static func _caves(out: Array[Dictionary]) -> void:
	var step := CS.dive_step()
	if not Game.flag(&"grottes_arrivee"):
		var text := "Les grottes marines, sous les falaises de l'est : la crique se rejoint à la nage. C'est là que la barque sans lanterne disparaît, la nuit."
		_add(out, "grottes", text + (" " + step if step != "" else ""), &"cote", P.ANSE_GROTTES, true)
		return
	if step != "":
		_add(out, "plongeur", "Au fond de la grotte, le passage est noyé jusqu'à la voûte. " + step, &"grottes_marines", P.GROTTES_PLONGEE, true)
		return
	_add(out, "plonger", "Au fond de la grotte, le passage est noyé jusqu'à la voûte. Avec le masque et ton plongeur, passe dessous : quelqu'un fait passer des caisses par là.", &"grottes_marines", P.GROTTES_PLONGEE, true)


## What is still to see in the cache (the crates, the boat, the page); `is_main` before the pass
## is known, side after.
static func _cache_left(out: Array[Dictionary], is_main: bool) -> void:
	if not Game.flag(&"passeur_battu"):
		return
	if not Game.flag(&"caisses_fouillees"):
		_add(out, "caisses", "Les caisses de la cache : de l'ambre noir, et des papiers sur une caisse plus petite.", &"grottes_marines", _at(&"grottes_marines", "CacheContrebande", P.CACHE), is_main)
	if not Game.flag(&"barque_isaure_vue"):
		_add(out, "barque", "Une barque est amarrée au quai de la cache. À qui est-elle ?", &"grottes_marines", _at(&"grottes_marines", "BarqueIsaure", P.BARQUE), is_main)
	if not Game.flag(&"found_journal_21"):
		_add(out, "page_21", "Une page d'Hélène serait cachée dans la grotte de la cache, sous deux initiales gravées dans la roche.", &"grottes_marines", _at(&"grottes_marines", "Page21", Vector2.INF), is_main)


## The pass (page 21), then the guardian.
static func _reef(out: Array[Dictionary]) -> void:
	var zone: StringName = Game.region_id
	if zone == &"recif_sanctuaire":
		_add(out, "mosasaure", "Le gardien du récif t'attend au milieu du sanctuaire : le Mosasaure Abyssal. Un combat d'honneur. (Astuce : les attaques du Vent le touchent fort.)",
			zone, _at(zone, "MosasaureAbyssal", P.MOSASAURE), true)
		return
	var step := CS.dive_step()
	var how := (" " + step) if step != "" else ""
	if zone == &"grottes_marines":
		_add(out, "recif", "La passe, Hélène l'a écrite : là où pêchent les Ptéranodons. D'ici, le tunnel de la mer, au bout du quai, y mène sous l'eau." + how, zone, P.TUNNEL_MER, true)
		return
	_add(out, "recif", "La passe du récif, là où pêchent les Ptéranodons, au nord du lagon : la mer y est plus sombre. Plonge, et descends jusqu'au sanctuaire." + how, &"cote", P.ACCES_RECIF, true)


## The side steps: the pages, the turtles, the warehouse at the Havre, Roc.
static func side(out: Array[Dictionary]) -> void:
	if not Game.flag(&"cote_arrivee"):
		return
	_pages(out)
	if not Game.flag(&"tortues_sauvees"):
		var when := "ce soir, au crépuscule" if Game.phase() == &"day" else "au crépuscule"
		_add(out, "tortues", "Un nid de tortues remue, en haut de la plage. Les petits sortiront %s… et les Masiakasaurus rôdent." % when, &"cote", _at(&"cote", "NidTortues", (P.NIDS as Array)[1]))
	if Game.flag(&"caisses_fouillees") and not Game.flag(&"entrepot_ferreol"):
		_add(out, "entrepot", "« Entrepôt du Comptoir : 12 caisses. Reçu : F. » L'entrepôt de Maître Ferréol, au bout du quai de Havre-Doré.", &"havre_dore", Vector2(48.5, 19.6))
	_roc(out)


## The Côte's journal pages still to find (page 23 is the end's): a direction for each.
static func _pages(out: Array[Dictionary]) -> void:
	var missing: Array[String] = []
	var total := 0
	for page: Array in P.PAGES:
		if page[0] == &"found_journal_23" or page[0] == &"found_journal_21":
			continue
		total += 1
		if not Game.flag(page[0]):
			missing.append(page[3])
	if missing.is_empty():
		return
	var where := ", ".join(missing.slice(0, -1)) + " et " + missing[-1] if missing.size() > 1 else missing[0]
	_add(out, "pages_cote", "Pages d'Hélène sur la Côte : %d sur %d. Il en reste %s." % [total - missing.size(), total, where], &"cote")


## Roc at the Cabinet: the Sceau, his map (after page 21), and after Maïa ran away, the name.
static func _roc(out: Array[Dictionary]) -> void:
	var text := ""
	if Game.flag(&"maia_enfuie") and not Game.flag(&"roc_isaure"):
		text = "Maïa s'est enfuie. Au Cabinet, le Pr Roc t'attend. Il sait peut-être des choses qu'il n'a jamais dites."
	elif Game.flag(&"found_journal_21") and not Game.flag(&"roc_carte_intacte"):
		text = "« Seule I. connaissait la passe. » Et Roc garde une copie de la carte d'Hélène… Lui en parler, au Cabinet."
	elif Game.flag(&"sceau_cote") and not Game.flag(&"roc_sceau_cote"):
		text = "Montrer le Sceau de la Côte au Pr Roc, au Cabinet."
	if text != "":
		_add(out, "roc_cote", text, &"cabinet", Objectives.spot(&"cabinet", "Roc"), Game.flag(&"maia_enfuie"))
