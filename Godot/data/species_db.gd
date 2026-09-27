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
	# Marais Brumeux
	&"iguanodon": "res://data/species/iguanodon.tres",
	&"corythosaurus": "res://data/species/corythosaurus.tres",
	&"baryonyx": "res://data/species/baryonyx.tres",
	&"koolasuchus": "res://data/species/koolasuchus.tres",
	&"therizinosaurus": "res://data/species/therizinosaurus.tres",
	&"suchomimus": "res://data/species/suchomimus.tres",
	&"voix_du_marais": "res://data/species/voix_du_marais.tres",
	&"spinosaurus": "res://data/species/spinosaurus.tres",
	# Désert Aride
	&"oviraptor": "res://data/species/oviraptor.tres",
	&"pinacosaurus": "res://data/species/pinacosaurus.tres",
	&"stygimoloch": "res://data/species/stygimoloch.tres",
	&"ouranosaurus": "res://data/species/ouranosaurus.tres",
	&"velociraptor_sables": "res://data/species/velociraptor_sables.tres",
	&"majungasaurus": "res://data/species/majungasaurus.tres",
	&"vieux_rempart": "res://data/species/vieux_rempart.tres",
	&"carnotaurus": "res://data/species/carnotaurus.tres",
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
