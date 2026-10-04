class_name Species3D
extends Resource
## What the 3D world needs of a dino species, besides its 2.5D sheet (data/species/<id>.tres, the
## gameplay's source of truth: stats, family, rarity, cries — unchanged). One file per species,
## world3d/creatures/species/<id>.tres, found by its id (Species3D.of): a new species is a model,
## an AnimSet and this file, no code (docs/migration-3d.md §4).
## Sizes are real (DexFacts): the model is scaled to `length_m`, compressed like the 2.5D for the
## big ones (DinoSize's rule: true to life up to a 1.5 m gabarit, then 1.5 × (g / 1.5)^0.6), and a
## young one is smaller (DinoSize.growth, from its level).

const DIR := "res://world3d/creatures/species/%s.tres"
const GABARIT_TRUE_M := 1.5
const GABARIT_POWER := 0.6

## The species' id, as in SpeciesDB (velociraptor, triceratops…).
@export var id: StringName
@export var model: PackedScene
@export var anim_set: AnimSet
## Real adult length, nose to tail (m) and mass (kg) — DexFacts' "size".
@export var length_m := 2.0
@export var mass_kg := 15.0
## carnivore, herbivore, piscivore, omnivore, insectivore (DexFacts.DIETS).
@export var diet: StringName = &"herbivore"
## Where it lives (region ids of the 2.5D: plaines, foret, marais…; DexPlaces).
@export var biomes: Array[StringName] = []

@export_group("Behaviour")
## shy: keeps away and flees early; curious: watches, flees late; calm: hardly minds Chloé;
## (later: territorial, predator).
@export var temperament: StringName = &"shy"
## Ground speeds of an adult (m/s): ambling about, running away.
@export var walk_speed := 1.3
@export var run_speed := 6.0
## Notices Chloé this far (m); runs off when she comes this close; ambles this far from home.
@export var perception_m := 10.0
@export var flee_m := 4.0
@export var roam_m := 8.0

static var _loaded := {}


## The 3D sheet of species `species_id`, or null if it has none yet.
static func of(species_id: StringName) -> Species3D:
	if not _loaded.has(species_id):
		var path := DIR % species_id
		_loaded[species_id] = load(path) as Species3D if ResourceLoader.exists(path) else null
	return _loaded[species_id]


## The 2.5D sheet (stats, name, rarity…).
func sheet() -> DinoSpecies:
	return SpeciesDB.get_species(id)


## Scale to give the model (drawn `drawn_size` in its own units) for an adult: its real length,
## compressed past a 1.5 m gabarit as the 2.5D does.
func adult_scale(drawn_size: Vector3) -> float:
	var drawn_length := maxf(drawn_size.z, drawn_size.x)
	if drawn_length <= 0.0:
		return 1.0
	var height := length_m * drawn_size.y / drawn_length
	var gabarit := sqrt(height * length_m)
	var shown := length_m
	if gabarit > GABARIT_TRUE_M:
		shown *= GABARIT_TRUE_M * pow(gabarit / GABARIT_TRUE_M, GABARIT_POWER) / gabarit
	return shown / drawn_length
