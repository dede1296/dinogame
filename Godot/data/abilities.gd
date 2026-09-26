class_name Abilities
## Exploration abilities (like Pokémon HMs): a party dino can use one when it belongs
## to the right family (a raptor slices, a ceratopsian charges), or is one of the species
## listed (only the small hunters with a keen nose have Flair).
## Same rules as the Phaser version (nouveau/src/data/abilities.js), plus Flair.

const DEFS := {
	&"charge": {"name": "Charge", "part": &"head", "families": [&"ceratopsian", &"armored"],
		"desc": "Fonce tête baissée : brise les gros rochers."},
	&"resonance": {"name": "Résonance", "part": &"head", "families": [&"hadrosaur"],
		"desc": "Sa crête chante : l'ambre endormi s'éveille et les portes d'ambre s'ouvrent."},
	&"tranche": {"name": "Tranche", "part": &"front_legs", "families": [&"raptor"],
		"desc": "Griffes acérées : tranche les troncs et les ronces."},
	&"flair": {"name": "Flair", "part": &"head", "species": [&"compsognathus", &"troodon", &"oviraptor"],
		"desc": "Un nez infaillible : sent ce qui est enfoui et le déterre."},
}


static func has(dino: Dino, ability: StringName) -> bool:
	var def: Dictionary = DEFS.get(ability, {})
	if def.is_empty():
		push_error("Capacité inconnue : %s" % ability)
		return false
	var species := dino.part_species(def["part"])
	return species.family in def.get("families", []) or species.id in def.get("species", [])


static func display_name(ability: StringName) -> String:
	return DEFS.get(ability, {}).get("name", String(ability))


## The exploration abilities `dino` can use (ids of DEFS), in their order there.
static func of(dino: Dino) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in DEFS:
		if has(dino, id):
			out.append(id)
	return out


## One line per ability of `dino`, for its sheet: « Flair : un nez infaillible… ».
static func describe(dino: Dino) -> Array[String]:
	var out: Array[String] = []
	for id in of(dino):
		out.append("Capacité %s — %s" % [DEFS[id]["name"], DEFS[id]["desc"]])
	return out
