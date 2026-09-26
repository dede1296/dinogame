class_name MovesDB
## Moves, elemental types and what each body part teaches — same data and rules as the
## Phaser version (nouveau/src/battle/moves.js, src/game/types.js). Only the moves the
## slice's species can learn are listed; the others are added with their species.
##
## type: "neutre" or an elemental type. power: 0 for status moves. accuracy: 0..1.
## effect: {"status": id, "chance": p} | {"self": {stat: stages}} | {"foe": {stat: stages}} | {"heal": fraction}
## crit: higher critical chance. priority: acts first. fx: animation used in battle.

const MOVES := {
	&"morsure": {"name": "Morsure", "type": "neutre", "power": 40, "accuracy": 1.0, "pp": 25, "fx": "bite"},
	&"coupQueue": {"name": "Coup de queue", "type": "neutre", "power": 40, "accuracy": 1.0, "pp": 25, "fx": "tail"},
	&"charge": {"name": "Charge", "type": "neutre", "power": 45, "accuracy": 0.95, "pp": 20, "fx": "charge"},
	&"griffes": {"name": "Griffes", "type": "neutre", "power": 40, "accuracy": 1.0, "pp": 25, "crit": true, "fx": "claw"},
	&"rugissement": {"name": "Rugissement", "type": "neutre", "power": 0, "accuracy": 1.0, "pp": 20, "effect": {"foe": {"atk": -1}}, "fx": "roar"},
	&"regardFeroce": {"name": "Regard féroce", "type": "neutre", "power": 0, "accuracy": 1.0, "pp": 20, "effect": {"foe": {"def": -1}}, "fx": "roar"},
	&"coupCorne": {"name": "Coup de corne", "type": "terre", "power": 60, "accuracy": 0.95, "pp": 15, "effect": {"status": "etourdi", "chance": 0.2}, "fx": "charge"},
	&"pietinement": {"name": "Piétinement", "type": "terre", "power": 70, "accuracy": 0.9, "pp": 10, "fx": "quake"},
	&"bondGriffu": {"name": "Bond griffu", "type": "vent", "power": 50, "accuracy": 1.0, "pp": 20, "priority": true, "fx": "claw"},
	&"laceration": {"name": "Lacération", "type": "vent", "power": 65, "accuracy": 0.95, "pp": 15, "crit": true, "effect": {"status": "saigne", "chance": 0.2}, "fx": "claw"},
	&"blindage": {"name": "Blindage", "type": "pierre", "power": 0, "accuracy": 1.0, "pp": 10, "effect": {"self": {"def": 2}}, "fx": "shield"},
}

const TYPE_NAMES := {"neutre": "Neutre", "feu": "Feu", "eau": "Eau", "terre": "Terre", "vent": "Vent", "pierre": "Pierre", "nature": "Nature"}
const TYPE_COLORS := {
	"neutre": Color("#b9b3a4"), "feu": Color("#e8622a"), "eau": Color("#3a8fd0"), "terre": Color("#b8894a"),
	"vent": Color("#8fd0c8"), "pierre": Color("#8a8272"), "nature": Color("#5fae44"),
}
const FAMILY_TYPES := {
	&"tyrant": "feu", &"spino": "eau", &"raptor": "vent", &"sauropod": "terre", &"ceratopsian": "terre",
	&"armored": "pierre", &"hadrosaur": "nature", &"flyer": "vent", &"marine": "eau",
}
## Attacker type -> defender type -> multiplier (1.5 strong, 0.7 weak, 1 otherwise).
const TYPE_CHART := {
	"feu": {"nature": 1.5, "vent": 1.5, "eau": 0.7, "pierre": 0.7},
	"eau": {"feu": 1.5, "terre": 1.5, "vent": 0.7, "nature": 0.7},
	"terre": {"pierre": 1.5, "feu": 1.5, "vent": 0.7, "nature": 0.7},
	"vent": {"nature": 1.5, "eau": 1.5, "feu": 0.7, "pierre": 0.7},
	"pierre": {"vent": 1.5, "nature": 1.5, "eau": 0.7, "feu": 0.7},
	"nature": {"pierre": 1.5, "terre": 1.5, "feu": 0.7, "vent": 0.7},
}

## Part -> donor family -> [[level, move], …]. A hybrid learns from all of its parts.
const LEARN := {
	&"head": {
		&"tyrant": [[1, &"morsure"], [8, &"ragePredateur"], [14, &"morsureBroyeuse"]],
		&"spino": [[1, &"morsure"], [7, &"machoireAquatique"]],
		&"raptor": [[1, &"morsure"], [6, &"regardFeroce"]],
		&"sauropod": [[1, &"charge"], [9, &"rugissement"]],
		&"ceratopsian": [[1, &"charge"], [5, &"coupCorne"]],
		&"armored": [[1, &"charge"], [7, &"coupCrane"]],
		&"hadrosaur": [[1, &"charge"], [5, &"criTrompette"]],
		&"flyer": [[1, &"morsure"], [8, &"pique"]],
		&"marine": [[1, &"morsure"], [6, &"machoireAquatique"], [18, &"plongeon"]],
	},
	&"teeth": {
		&"tyrant": [[10, &"crocsBrulants"]], &"spino": [[12, &"crocsBrulants"]], &"marine": [[10, &"crocsBrulants"]],
	},
	&"front_legs": {
		&"raptor": [[1, &"griffes"], [9, &"laceration"]], &"spino": [[4, &"griffes"]],
		&"flyer": [[1, &"tornadeAiles"]], &"tyrant": [[3, &"rugissement"]],
	},
	&"back_legs": {
		&"raptor": [[3, &"bondGriffu"]], &"sauropod": [[6, &"pietinement"], [20, &"seisme"]],
		&"ceratopsian": [[8, &"pietinement"]], &"armored": [[12, &"pietinement"]],
		&"hadrosaur": [[10, &"fougeres"]], &"marine": [[4, &"vagueCaudale"]],
	},
	&"back": {
		&"armored": [[4, &"blindage"], [9, &"picsDorsaux"]], &"spino": [[5, &"voileMenacante"]], &"ceratopsian": [[6, &"blindage"]],
	},
	&"tail": {
		&"armored": [[1, &"coupQueue"], [11, &"massue"]], &"sauropod": [[1, &"coupQueue"], [7, &"fouetCaudal"]],
		&"marine": [[1, &"vagueCaudale"]], &"hadrosaur": [[7, &"racines"]],
	},
}
const DEFAULT_TAIL := [[1, &"coupQueue"]]


static func move(id: StringName) -> Dictionary:
	return MOVES.get(id, MOVES[&"charge"])


static func effectiveness(move_type: String, defender_type: String) -> float:
	if move_type == "neutre":
		return 1.0
	return TYPE_CHART.get(move_type, {}).get(defender_type, 1.0)


## Moves a dino can know at `level`, as [[level, id], …] ordered by level. Moves not yet
## in MOVES (species of later regions) are skipped.
static func learnset(dino: Dino) -> Array:
	var list: Array = []
	var seen := {}
	for part in LEARN:
		var family: StringName = dino.part_species(part).family
		var entries: Array = LEARN[part].get(family, DEFAULT_TAIL if part == &"tail" else [])
		for e: Array in entries:
			if MOVES.has(e[1]) and not seen.has(e[1]):
				seen[e[1]] = true
				list.append(e)
	list.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return list
