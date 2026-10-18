class_name CieuxObjectives
## Chapter 7, the Cieux Éternels: what Chloé can do now (MontsObjectives.main hands over to main()
## once Maïa and Chloé are a team, Objectives._side calls side() once Chloé has the harness). Each
## step says where to go and what is missing (the harness, a grown pterosaur, the Vol): never stuck
## without knowing why. Same shape as MontsObjectives; the places are read from the zones (_at: a
## node's position in the zone's scene), else the names of CieuxPlaces (Cieux.place).

const C := preload("res://story/cieux.gd")
const MS := preload("res://story/monts_stage.gd")
const TITLES := {
	"harnais": "Le harnais de vol", "porteur": "Un grand ptérosaure", "cieux": "Les Cieux Éternels", "pitons": "Les pitons et les ponts",
	"nids": "Les nids géants", "roi": "Le Roi des Cieux", "arche": "L'Arche du Vent", "masque": "Le Masque, sous l'arche",
	"volcan": "Vers la Plaine Volcanique", "pages_cieux": "Le journal dans les Cieux", "maia_col": "Maïa, au col",
	"roc_cieux": "Retour au Cabinet",
}
## The Cieux's journal pages and roughly where Hélène left them (a direction, not the place).
const PAGES := [
	[&"found_journal_31", "au Belvédère, le plus haut des pitons qu'on atteint à pied"],
	[&"found_journal_32", "dans les nids géants, au bord d'un nid vide"],
	[&"found_journal_33", "sur l'îlot de la mer de nuages, sans aucun pont : en volant"],
	[&"found_journal_34", "au sommet, près de l'Arche du Vent, sous des pierres plates"],
]
const TILE := 48.0
## The zones' scenes when world.gd does not list them yet (its ZONES comes first).
const ZONE_SCENES := {
	&"cieux": "res://regions/cieux/cieux.tscn",
	&"nids_geants": "res://regions/cieux/nids_geants.tscn",
	&"arche_du_vent": "res://regions/cieux/arche_du_vent.tscn",
}
static var _spots: Dictionary = {}


static func _add(out: Array[Dictionary], id: String, text: String, zone: StringName, tile := Vector2.INF, is_main := false) -> void:
	out.append({"id": id, "title": TITLES.get(id, text), "text": text, "zone": zone, "tile": tile, "main": is_main})


## The main steps, the most advanced first (once maia_alliee).
static func main(out: Array[Dictionary]) -> void:
	if Game.flag(&"masque_tombe"):
		VolcanObjectives.main(out)   # chapter 8, the Plaine Volcanique (story/volcan_objectives.gd)
		return
	if Game.flag(&"arche_arrivee"):
		_add(out, "masque", "Sous l'Arche du Vent, le Masque attend. Il veut les quatre Cœurs. Apaise ses ptérosaures : ils ont peur, comme les autres.",
			&"arche_du_vent", _at(&"arche_du_vent", "MasqueArche", C.place("ARCHE")), true)
		return
	if Game.flag(&"vol_obtenu"):
		_add(out, "arche", "L'Arche du Vent, tout en haut. Le vent de l'aiguille te laisse passer, maintenant : du Grand Nid, le pont de lianes mène à l'aiguille, et son arête à l'Arche, tout droit vers le nord. Ou en volant : file vers le nord au-dessus de l'aiguille.",
			&"nids_geants", _at(&"nids_geants", "Aiguille", C.place("AIGUILLE")), true)
		return
	if Game.flag(&"nids_arrivee"):
		_add(out, "roi", "Tout en haut des nids, au bord du Grand Nid, le Quetzalcoatlus Roi. Un combat d'honneur, dans le vent." + _tip(),
			&"nids_geants", _at(&"nids_geants", "QuetzalRoi", C.place("GRAND_NID")), true)
		return
	if Game.flag(&"cieux_arrivee"):
		_add(out, "nids", "Les nids géants sont tout en haut des pitons : par les ponts de lianes, puis la rampe taillée dans la roche.",
			&"cieux", _at(&"cieux", "SortieNids", C.place("SORTIE_NIDS")), true)
		return
	if Game.flag(&"cieux_ouverts"):
		_add(out, "cieux", "Au bout du sentier des Monts, au nord du col, le vide… et le vent qui monte. Avec le harnais et ton ptérosaure, c'est le moment : les Cieux Éternels.",
			&"monts", MontsPlaces.SORTIE_CIEUX, true)
		return
	if not C.has_harness():
		_add(out, "harnais", "Joss coud le harnais de vol, au Havre. « Trois jours », a dit Maïa. Donc une semaine. Va voir où il en est.",
			&"havre_dore", Objectives.spot(&"havre_dore", "Joss"), true)
		return
	_add(out, "porteur", "Le harnais est prêt. " + C.fly_step(), &"cote", Vector2.INF, true)


## The tip before the Roi (what hits it hard), read from its species.
static func _tip() -> String:
	var species := SpeciesDB.get_species(C.species_or(&"quetzalcoatlus"))
	if species == null:
		return ""
	var weak := MS.weak_to(MovesDB.FAMILY_TYPES.get(species.family, "vent"))
	if weak == "":
		return ""
	return " (Astuce : %s le touche%s fort.)" % [weak, "nt" if " et " in weak else ""]


## The side steps: the pages, Maïa at the col, Roc at the Cabinet.
static func side(out: Array[Dictionary]) -> void:
	if not C.has_harness():
		return
	_pages(out)
	if Game.flag(&"cieux_ouverts") and not Game.flag(&"maia_cieux_plan") and not Game.flag(&"masque_tombe"):
		_add(out, "maia_col", "Maïa attend au col des Monts, devant le sanctuaire. Elle a « un plan stylé ».",
			&"monts", Objectives.spot(&"monts", "MaiaMonts"))
	_roc(out)


## The Cieux's journal pages still to find: a direction for each.
static func _pages(out: Array[Dictionary]) -> void:
	if not Game.flag(&"cieux_arrivee"):
		return
	var missing: Array[String] = []
	for page: Array in PAGES:
		if not Game.flag(page[0]):
			missing.append(page[1])
	if missing.is_empty():
		return
	var where := ", ".join(missing.slice(0, -1)) + " et " + missing[-1] if missing.size() > 1 else missing[0]
	_add(out, "pages_cieux", "Pages d'Hélène dans les Cieux : %d sur %d. Il en reste %s." % [PAGES.size() - missing.size(), PAGES.size(), where], &"cieux")


## Roc at the Cabinet: the Sceau des Cieux; after the mask.
static func _roc(out: Array[Dictionary]) -> void:
	var text := ""
	if Game.flag(&"masque_tombe") and not Game.flag(&"roc_masque_tombe"):
		text = "Roc doit savoir, pour Isaure. Et pour les Cœurs. Au Cabinet."
	elif Game.flag(&"sceau_cieux") and not Game.flag(&"roc_sceau_cieux"):
		text = "Montrer le Sceau des Cieux au Pr Roc, au Cabinet. Et lui raconter le Vol."
	if text != "":
		_add(out, "roc_cieux", text, &"cabinet", Objectives.spot(&"cabinet", "Roc"))


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
