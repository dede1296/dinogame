class_name SpeciesDB
## Every species of the game, by id. Listed explicitly (not by scanning the folder) so the
## exported builds, where resources are remapped, find them the same way.

const PATHS := {
	&"velociraptor": "res://data/species/velociraptor.tres",
	&"protoceratops": "res://data/species/protoceratops.tres",
	&"parasaurolophus": "res://data/species/parasaurolophus.tres",
	&"ankylosaurus": "res://data/species/ankylosaurus.tres",
	&"troodon": "res://data/species/troodon.tres",
	&"psittacosaurus": "res://data/species/psittacosaurus.tres",
	&"dimorphodon": "res://data/species/dimorphodon.tres",
	&"compsognathus": "res://data/species/compsognathus.tres",
	&"triceratops": "res://data/species/triceratops.tres",
	&"anurognathus": "res://data/species/anurognathus.tres",
	&"dilophosaurus": "res://data/species/dilophosaurus.tres",
	&"stegosaurus": "res://data/species/stegosaurus.tres",
	&"deinonychus": "res://data/species/deinonychus.tres",
	&"pachycephalosaurus": "res://data/species/pachycephalosaurus.tres",
	&"microraptor": "res://data/species/microraptor.tres",
	&"brachiosaurus": "res://data/species/brachiosaurus.tres",
	&"allosaurus": "res://data/species/allosaurus.tres",
	&"utahraptor": "res://data/species/utahraptor.tres",
	&"griffe_grise": "res://data/species/griffe_grise.tres",
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
