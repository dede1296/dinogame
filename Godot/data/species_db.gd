class_name SpeciesDB
## Every species of the game, by id. Listed explicitly (not by scanning the folder) so the
## exported builds, where resources are remapped, find them the same way.

const PATHS := {
	&"velociraptor": "res://data/species/velociraptor.tres",
	&"protoceratops": "res://data/species/protoceratops.tres",
}

static var _cache: Dictionary = {}


static func get_species(id: StringName) -> DinoSpecies:
	if not _cache.has(id):
		if not PATHS.has(id):
			push_error("Espèce inconnue : %s" % id)
			return null
		_cache[id] = load(PATHS[id])
	return _cache[id]


static func all_ids() -> Array:
	return PATHS.keys()
