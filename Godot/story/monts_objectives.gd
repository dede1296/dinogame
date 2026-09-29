class_name MontsObjectives
## Chapter 6, the Monts Gelés: what Chloé can do now (CoteObjectives.main calls main() once Maïa
## has run away, Objectives._side calls side() once in the Monts). Each step says where to go and
## what is missing (a dino that charges, in the party or at the Cabinet, or where to find one):
## never stuck without knowing why. Same objectives as Objectives._add, with the chapter's own
## titles; the places are read from the zones (_at: a node's position in the zone's scene), else
## the names of MontsPlaces.

const P := preload("res://story/monts_places.gd")
const MS := preload("res://story/monts_stage.gd")
const TITLES := {
	"monts": "Les Monts Gelés", "manteau": "Un vêtement chaud", "bertille": "La fumée de la vallée", "glacier": "Le glacier", "charge": "Les murs de glace",
	"grottes": "Les grottes de glace", "suie": "La dame en gris", "dormeurs": "Les dormeurs d'Hélène", "col": "Le Col des Tempêtes",
	"porte": "La porte de givre", "sanctuaire": "Le sanctuaire de Givre", "titan": "Le gardien du sanctuaire",
	"coeur_4": "Le quatrième Cœur", "maia_5": "Maïa revient", "cieux": "Vers les Cieux Éternels",
	"pages_monts": "Le journal dans les Monts", "grelot": "Le petit Grelot", "bertille_merci": "Grelot est rentré",
	"roc_monts": "Retour au Cabinet",
}
## The Monts' journal pages and roughly where Hélène left them (a direction, not the place).
const PAGES := [
	[&"found_journal_26", "dans les grottes de glace, dans une petite pièce derrière un mur de glace"],
	[&"found_journal_27", "dans le sanctuaire de Givre"],
	[&"found_journal_28", "au col, sous une pierre plate, à l'abri du vent"],
	[&"found_journal_29", "sur le glacier, entre deux blocs de glace bleue"],
	[&"found_journal_30", "dans la vallée, une nuit claire"],
]
const TILE := 48.0
## The zones' scenes when world.gd does not list them yet (its ZONES comes first).
const ZONE_SCENES := {
	&"monts": "res://regions/monts/monts.tscn",
	&"grottes_glace": "res://regions/monts/grottes_glace.tscn",
	&"sanctuaire_givre": "res://regions/monts/sanctuaire_givre.tscn",
}
## Nodes' places in each zone, read once from the zone's scene (see _at).
static var _spots: Dictionary = {}


static func _add(out: Array[Dictionary], id: String, text: String, zone: StringName, tile := Vector2.INF, is_main := false) -> void:
	out.append({"id": id, "title": TITLES.get(id, text), "text": text, "zone": zone, "tile": tile, "main": is_main})


## The main steps, the most advanced first.
static func main(out: Array[Dictionary]) -> void:
	if not Game.flag(&"monts_arrivee"):
		if not Monts.has_coat():
			_add(out, "manteau", "Là-haut, dans les Monts Gelés, on gèle sans vêtement chaud. " + Monts.coat_step(),
				&"cote", CotePlaces.spot(&"cote", "JossCote", CotePlaces.JOSS), true)
			return
		_add(out, "monts", "À l'est de la Côte, tout en haut des falaises, le sentier monte vers la neige : les Monts Gelés. Le quatrième Cœur t'y attend.",
			&"cote", CotePlaces.SORTIE_MONTS, true)
		return
	if Game.flag(&"maia_alliee"):
		_add(out, "cieux", "Au-dessus des Monts, dans les nuages : les Cieux Éternels. Pour y monter, il faudrait voler… Joss coud un harnais. (La suite de l'aventure arrive bientôt !)",
			&"monts", P.SORTIE_CIEUX, true)
		return
	if Game.flag(&"coeur_4"):
		_add(out, "maia_5", "Quelqu'un t'attend dans la neige, devant le sanctuaire de Givre. Maïa ?", &"monts", _at(&"monts", "MaiaMonts", P.MAIA_RETOUR), true)
		return
	if Game.flag(&"titan_battu"):
		_add(out, "coeur_4", "Le Titan t'a acceptée. L'autel de glace, au fond du sanctuaire, s'ouvre pour toi.",
			&"sanctuaire_givre", _at(&"sanctuaire_givre", "Autel", _at(&"sanctuaire_givre", "AutelGivre", P.AUTEL)), true)
		return
	if Game.flag(&"sanctuaire_givre_ouvert"):
		if Game.region_id == &"sanctuaire_givre" or Game.flag(&"sanctuaire_givre_arrivee"):
			_add(out, "titan", "Le gardien du sanctuaire t'attend : le Cryolophosaure Titan. Un combat d'honneur." + _tip(),
				&"sanctuaire_givre", _at(&"sanctuaire_givre", "Titan", _at(&"sanctuaire_givre", "CryolophosaureTitan", P.TITAN)), true)
		else:
			_add(out, "sanctuaire", "La porte de givre a fondu. Le sanctuaire t'attend, tout en haut du col.", &"monts", P.PORTE_GIVRE, true)
		return
	if Game.flag(&"roc_col_vu"):
		_add(out, "porte", "Tout en haut du Col des Tempêtes, une porte de givre et ses quatre creux. « Tes Cœurs sauront quoi faire », a dit Roc.",
			&"monts", _at(&"monts", "PorteGivre", P.PORTE_GIVRE), true)
		return
	if Game.flag(&"suie_monts_battue"):
		if not Game.flag(&"dormeurs_reveilles"):
			_add(out, "dormeurs", "La dame en gris est partie. Les petits d'Hélène dorment toujours dans la glace… Et si la chaleur de tes Cœurs pouvait les réveiller ?",
				&"grottes_glace", _at(&"grottes_glace", "Dormeur1", (P.DORMEURS as Array)[0]), true)
		_add(out, "col", "« Levez les yeux », a dit Dame Suie. À l'est de la vallée, le Col des Tempêtes monte vers le sanctuaire du quatrième Cœur.",
			&"monts", _at(&"monts", "DeclencheurCol", _at(&"monts", "RocCol", P.COL)), true)
		return
	if Game.flag(&"grottes_glace_arrivee"):
		_add(out, "suie", "Dame Suie est au fond des grottes de glace, au milieu des dormeurs d'Hélène, avec ses fioles. Il faut l'en empêcher.",
			&"grottes_glace", _at(&"grottes_glace", "DameSuieMonts", P.SUIE), true)
		return
	if Game.flag(&"glacier_arrivee"):
		var step := MS.charge_step()
		if step != "":
			_add(out, "charge", "Des murs de glace barrent le glacier. " + step, &"monts", _at(&"monts", "MurGlace1", (P.MURS_GLACE as Array)[0]), true)
		else:
			_add(out, "grottes", "Au bout du glacier, derrière les murs de glace, la bouche des grottes de glace. Les traces du traîneau y entrent.",
				&"monts", P.ENTREE_GROTTES, true)
		return
	if Game.flag(&"bertille_vue"):
		_add(out, "glacier", "Le glacier, au nord : la dame en gris y est montée avec son traîneau, dit Bertille.", &"monts", _at(&"monts", "DeclencheurGlacier", _at(&"monts", "GlacierArrivee", P.GLACIER)), true)
		return
	_add(out, "bertille", "En bas, dans la vallée, un filet de fumée monte d'un abri de roche : quelqu'un campe là, par ce froid.",
		&"monts", _at(&"monts", "Bertille", P.BERTILLE), true)


## The tip before the Titan (what hits it hard), read from its species.
static func _tip() -> String:
	var species := SpeciesDB.get_species(MS.species_or(&"cryolophosaure_titan"))
	if species == null:
		return ""
	var weak := MS.weak_to(MovesDB.FAMILY_TYPES.get(species.family, "terre"))
	if weak == "":
		return ""
	return " (Astuce : %s le touche%s fort.)" % [weak, "nt" if " et " in weak else ""]


## The side steps: the pages, Grelot and Bertille's thanks, Roc at the Cabinet.
static func side(out: Array[Dictionary]) -> void:
	if not Game.flag(&"monts_arrivee"):
		return
	_pages(out)
	if Game.flag(&"bertille_vue") and not Game.flag(&"grelot_rentre"):
		_add(out, "grelot", "Grelot, le petit Pachyrhinosaurus de Bertille, a suivi le traîneau vers le glacier. Il a un grelot autour du cou : au pied des murs de glace, peut-être ?",
			&"monts", _at(&"monts", "Grelot", (P.MURS_GLACE as Array)[0]))
	if Game.flag(&"grelot_rentre") and Game.flag(&"bertille_vue") and not Game.flag(&"moufles_helene"):
		_add(out, "bertille_merci", "Grelot est rentré au chaud. Bertille voudrait te voir, près de son feu.", &"monts", _at(&"monts", "Bertille", P.BERTILLE))
	_roc(out)


## The Monts' journal pages still to find: a direction for each.
static func _pages(out: Array[Dictionary]) -> void:
	var missing: Array[String] = []
	for page: Array in PAGES:
		if not Game.flag(page[0]):
			var hint: String = page[1]
			if page[0] == &"found_journal_30" and Game.flag(&"forges_vues"):
				hint = "dans la vallée, au bord du chemin"
			missing.append(hint)
	if missing.is_empty():
		return
	var where := ", ".join(missing.slice(0, -1)) + " et " + missing[-1] if missing.size() > 1 else missing[0]
	_add(out, "pages_monts", "Pages d'Hélène dans les Monts : %d sur %d. Il en reste %s." % [PAGES.size() - missing.size(), PAGES.size(), where], &"monts")


## Roc at the Cabinet: tea after the col, the three little ones, the Sceau des Monts.
static func _roc(out: Array[Dictionary]) -> void:
	var text := ""
	if Game.flag(&"sceau_monts") and not Game.flag(&"roc_sceau_monts"):
		text = "Montrer le Sceau des Monts au Pr Roc, au Cabinet."
	elif Game.flag(&"dormeurs_reveilles") and not Game.flag(&"roc_dormeurs"):
		text = "Les trois petits de la glace sont arrivés au Cabinet, avec le troupeau de Bertille. Roc doit être débordé."
	elif Game.flag(&"roc_innocente") and not Game.flag(&"roc_monts_the"):
		text = "Roc est redescendu au Cabinet. Il a promis du thé. Chaud, cette fois."
	if text != "":
		_add(out, "roc_monts", text, &"cabinet", Objectives.spot(&"cabinet", "Roc"))


## Where node `node_name` stands in zone `zone` (tiles), read from the zone's scene, so the
## markers follow the map when it changes; `fallback` (MontsPlaces) when the zone or the node is
## not there (yet).
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
