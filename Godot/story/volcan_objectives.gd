class_name VolcanObjectives
## Chapter 8, the Plaine Volcanique: what Chloé can do now (CieuxObjectives.main hands over to
## main() once the mask has fallen, Objectives._side calls side() from then on). Each step says
## where to go and what is missing (a dino of stone or fire for the lava, what hits the T-Rex
## hard): never stuck without knowing why. Same shape as CieuxObjectives; the places are read from
## the zones (_at: a node's position in the zone's scene), else the names of VolcanPlaces.

const V := preload("res://story/volcan.gd")
const MS := preload("res://story/monts_stage.gd")
const TITLES := {
	"descente": "La Descente de Cendre", "corrompu": "Le premier corrompu", "forges": "Les forges de l'Ombre Noire",
	"petites_forges": "Les trois petites forges", "brac": "Brac, une dernière fois", "suie": "Dame Suie et la grande forge",
	"coulees": "Les coulées de lave", "sanctuaire": "Le sanctuaire de Magma", "trex": "Le T-Rex de Magma",
	"coeur": "Le cinquième Cœur", "porte": "La porte du cratère", "isaure": "Isaure, devant la porte",
	"apex": "Vers la Terre des Apex (bientôt)", "pages_volcan": "Le journal dans la Plaine Volcanique",
	"roc_volcan": "Retour au Cabinet", "bertille_volcan": "Bertille, aux Monts", "leonce_port": "Léonce, au port",
}
## The chapter's journal pages and roughly where Hélène left them (a direction, not the place).
const PAGES := [
	[&"found_journal_35", "au sanctuaire de Magma, dans une fente du mur de verre"],
	[&"found_journal_36", "sur un rocher au milieu des coulées : sur le dos d'un dino de pierre ou de feu"],
	[&"found_journal_37", "aux forges, chez Dame Suie"],
	[&"found_journal_38", "devant la porte du cratère, sous le cairn d'Hélène"],
]
const TILE := 48.0
## The zones' scenes when world.gd does not list them yet (its ZONES comes first).
const ZONE_SCENES := {
	&"champs_cendres": "res://regions/volcan/champs_cendres.tscn",
	&"forges_ombre": "res://regions/volcan/forges_ombre.tscn",
	&"coulees_lave": "res://regions/volcan/coulees_lave.tscn",
	&"sanctuaire_magma": "res://regions/volcan/sanctuaire_magma.tscn",
	&"porte_cratere": "res://regions/volcan/porte_cratere.tscn",
}
static var _spots: Dictionary = {}


static func _add(out: Array[Dictionary], id: String, text: String, zone: StringName, tile := Vector2.INF, is_main := false) -> void:
	out.append({"id": id, "title": TITLES.get(id, text), "text": text, "zone": zone, "tile": tile, "main": is_main})


## The main steps, the most advanced first (once masque_tombe).
static func main(out: Array[Dictionary]) -> void:
	if ApexObjectives.active():   # chapter 9 and the epilogue (story/apex_objectives.gd)
		ApexObjectives.main(out)
		return
	if Game.flag(&"porte_arrivee"):
		_add(out, "isaure", "Isaure attend devant la porte du cratère, les quatre Cœurs dans sa sacoche de marin. Maïa est assise à côté.",
			V.PORTE, _at(V.PORTE, "IsaurePorte", V.place("ISAURE")), true)
		return
	if Game.flag(&"lave_retiree"):
		_add(out, "porte", "Le volcan a grondé : la lave s'est retirée du chemin du cratère, « comme une marée ». Il monte depuis les coulées jusqu'à la porte de la Terre des Apex.",
			V.COULEES, _at(V.COULEES, "SortiePorte", V.place("PIED_CHEMIN_CRATERE")), true)
		return
	if Game.flag(&"trex_magma_battu"):
		_add(out, "coeur", "Le T-Rex de Magma a frappé l'autel du pied : le cinquième Cœur est là, dans sa coque de lave.",
			V.SANCTUAIRE, _at(V.SANCTUAIRE, "AutelMagma", V.place("AUTEL_MAGMA")), true)
		return
	if Game.flag(&"sanctuaire_magma_arrivee"):
		_add(out, "trex", "Le T-Rex de Magma garde le cinquième Cœur. Un combat d'honneur, le plus dur : viens reposée." + _tip(),
			V.SANCTUAIRE, _at(V.SANCTUAIRE, "TrexMagma", V.place("TREX_MAGMA")), true)
		return
	if Game.flag(&"lave_franchie"):
		_add(out, "sanctuaire", "De l'autre côté des coulées, une faille dans le flanc du volcan : le sanctuaire de Magma." + _tip(),
			V.COULEES, _at(V.COULEES, "Faille", V.place("FAILLE")), true)
		return
	if Game.flag(&"coulees_arrivee") or Game.flag(&"suie_partie"):
		_add(out, "coulees", "Les coulées de lave : pour les franchir, il faut un dino qui a le cuir pour, de pierre ou de feu, en tête de l'équipe. " + _lava(),
			V.COULEES if Game.flag(&"coulees_arrivee") else V.FORGES,
			_at(V.COULEES, "PremiereCoulee", V.place("PREMIERE_COULEE")) if Game.flag(&"coulees_arrivee") else _at(V.FORGES, "SortieCoulees", V.place("SORTIE_COULEES")), true)
		return
	if Game.flag(&"brac_vaincu"):
		_add(out, "suie", "Dame Suie, au pied de la grande forge. Elle a tout regardé, et tout noté.",
			V.FORGES, _at(V.FORGES, "SuieVolcan", V.place("ETABLI")), true)
		return
	if Game.flag(&"barricade_tombee"):
		_add(out, "brac", "Derrière la barricade tombée, Brac attend, assis sur une cage. Il veut « gagner UNE fois ».",
			V.FORGES, _at(V.FORGES, "BracVolcan", V.place("BRAC")), true)
		return
	if Game.flag(&"forges_arrivee"):
		_small_forges(out)
		return
	if Game.flag(&"premier_corrompu_volcan"):
		_add(out, "forges", "Les forges de l'Ombre Noire, au pied du volcan : là où Numéro 3 est parti, au trot.",
			V.CHAMPS, _at(V.CHAMPS, "SortieForges", V.place("SORTIE_FORGES")), true)
		return
	if Game.flag(&"cendres_arrivee"):
		_add(out, "corrompu", "Dans les champs de cendre, un Styracosaurus corrompu gratte la cendre près d'une cage ouverte. Une plaque de fer au cou : « 3 ».",
			V.CHAMPS, _at(V.CHAMPS, "Numero3", V.place("NUMERO_3")), true)
		return
	_add(out, "descente", "Isaure est partie vers le volcan avec les quatre Cœurs. Le cinquième dort sous la Plaine Volcanique : la Descente de Cendre y mène, derrière l'Arche du Vent.",
		&"arche_du_vent", _at(&"arche_du_vent", "SortieVolcan", CieuxPlaces.DESCENTE_CENDRE), true)


## The three small forges: the next one still burning (« les dinos savent comment »).
static func _small_forges(out: Array[Dictionary]) -> void:
	var done := 0
	var next := 0
	for n in [1, 2, 3]:
		if Game.flag(StringName("forge_%d_eteinte" % n)):
			done += 1
		elif next == 0:
			next = n
	var guard: String = ["", "Numero7", "Numero11", "Numero12"][next]
	_add(out, "petites_forges", "Éteindre les trois petites forges (%d sur 3) : chacune est gardée par un dino corrompu à plaque numérotée. Apaise-le : les dinos savent comment." % done,
		V.FORGES, _at(V.FORGES, guard, V.place("FORGE_%d" % next)), true)


## What the lava needs, with the party's names (Volcan.lava_step), or who carries her.
static func _lava() -> String:
	var step := V.lava_step()
	if step != "":
		return step
	var lead := V.lava_crosser()
	return "Ton %s a le cuir pour." % lead.nickname if lead else ""


## The tip before the T-Rex (what hits it hard), read from its species.
static func _tip() -> String:
	var species := SpeciesDB.get_species(V.species_or(&"trex_magma"))
	if species == null:
		return ""
	var weak := MS.weak_to(MovesDB.FAMILY_TYPES.get(species.family, "feu"))
	if weak == "":
		return ""
	return " (Astuce : %s le touche%s fort.)" % [weak, "nt" if " et " in weak else ""]


## The side steps: the pages, Roc at the Cabinet, Bertille, Léonce at the port.
static func side(out: Array[Dictionary]) -> void:
	if not Game.flag(&"masque_tombe"):
		return
	_pages(out)
	_roc(out)
	if Game.flag(&"grande_forge_eteinte") and not Game.flag(&"bertille_forges_eteintes"):
		_add(out, "bertille_volcan", "Bertille, aux Monts, compte les feux du volcan depuis deux ans. Elle a dû les voir s'éteindre.",
			&"monts", Objectives.spot(&"monts", "Bertille"))
	if Game.flag(&"grande_forge_eteinte") and not Game.flag(&"leonce_port_vu"):
		_add(out, "leonce_port", "Léonce est rentré au port. Il raccommode les filets sur le ponton.",
			&"port_ambre", Objectives.spot(&"port_ambre", "Leonce"))


## The chapter's journal pages still to find: a direction for each.
static func _pages(out: Array[Dictionary]) -> void:
	if not Game.flag(&"cendres_arrivee"):
		return
	var missing: Array[String] = []
	for page: Array in PAGES:
		if not Game.flag(page[0]):
			missing.append(page[1])
	if missing.is_empty():
		return
	var where := ", ".join(missing.slice(0, -1)) + " et " + missing[-1] if missing.size() > 1 else missing[0]
	_add(out, "pages_volcan", "Pages d'Hélène dans la Plaine Volcanique : %d sur %d. Il en reste %s." % [PAGES.size() - missing.size(), PAGES.size(), where], V.CHAMPS)


## Roc at the Cabinet: the notebooks, Brac, the Sceau du Volcan.
static func _roc(out: Array[Dictionary]) -> void:
	var text := ""
	if Game.flag(&"sceau_volcan") and not Game.flag(&"roc_sceau_volcan"):
		text = "Montrer le Sceau du Volcan au Pr Roc, au Cabinet. Et le cinquième Cœur."
	elif Game.flag(&"suie_partie") and not Game.flag(&"roc_suie_carnets"):
		text = "Dame Suie a dit qu'elle rapporterait les carnets d'Hélène au Cabinet. Roc les a peut-être déjà."
	elif Game.flag(&"brac_parti") and not Game.flag(&"roc_brac_parti"):
		text = "Brac est parti « voir la mer ». Roc, au Cabinet, saura peut-être où."
	if text != "":
		_add(out, "roc_volcan", text, &"cabinet", Objectives.spot(&"cabinet", "Roc"))


## Where node `node_name` stands in zone `zone` (tiles), read from the zone's scene, so the markers
## follow the map when it changes; `fallback` when the zone or the node is not there (yet).
static func _at(zone: StringName, node_name: String, fallback: Vector2) -> Vector2:
	if not _spots.has(zone):
		_spots[zone] = _read_spots(zone)
	return (_spots[zone] as Dictionary).get(node_name, fallback)


static func _read_spots(zone: StringName) -> Dictionary:
	var out := {}
	var zones: Dictionary = (load("res://world/world.gd") as Script).get_script_constant_map().get("ZONES", {})
	var path: String = zones.get(zone, ZONE_SCENES.get(zone, ""))
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

