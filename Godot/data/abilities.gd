class_name Abilities
## Exploration abilities (like Pokémon HMs): a party dino can use one when it belongs
## to the right family (a raptor slices, a ceratopsian charges).
## Same rules as the Phaser version (nouveau/src/data/abilities.js).

const DEFS := {
	&"charge": {"name": "Charge", "part": &"head", "families": [&"ceratopsian", &"armored"],
		"desc": "Fonce tête baissée : brise les gros rochers."},
	&"resonance": {"name": "Résonance", "part": &"head", "families": [&"hadrosaur"],
		"desc": "Sa crête chante : l'ambre endormi s'éveille et les portes d'ambre s'ouvrent."},
	&"tranche": {"name": "Tranche", "part": &"front_legs", "families": [&"raptor"],
		"desc": "Griffes acérées : tranche les troncs et les ronces."},
}


static func has(dino: Dino, ability: StringName) -> bool:
	var def: Dictionary = DEFS.get(ability, {})
	if def.is_empty():
		push_error("Capacité inconnue : %s" % ability)
		return false
	return dino.part_species(def["part"]).family in def["families"]


static func display_name(ability: StringName) -> String:
	return DEFS.get(ability, {}).get("name", String(ability))
