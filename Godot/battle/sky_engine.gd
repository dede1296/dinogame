class_name SkyEngine
extends BattleEngine
## A battle in the Cieux Éternels (chapter 7, BattleScene rule "cieux", or any battle in ZONES): the
## rules of BattleEngine, and the wind's own, told the first time they show in the battle (and shown
## on the moves' cards, mark()): high up in the wind, Wind moves hit harder (WIND_BOOST), Earth
## moves lose some of their force, far from the ground (EARTH_DAMP). Nothing else changes: a child
## sees the ▲ and ▼ on the cards and the line that explains them.
## The Quetzalcoatlus Roi never lands (docs/histoire.md § 7): his battle is one of these, the
## pterosaurs hovering on the wind (BattleSky).

const ZONES: Array[StringName] = [&"cieux", &"nids_geants", &"arche_du_vent"]
const WIND_BOOST := 1.25
const EARTH_DAMP := 0.75
## Said the first time in the battle that a rule shows.
const TOLD := {
	"vent": "Le vent porte le coup : si haut, les attaques Vent frappent plus fort !",
	"terre": "Si loin du sol, la Terre perd de sa force…",
}

var _told := {}


## Is a battle fought here one in the wind (rule "cieux", or one of ZONES)?
static func applies(rules: Dictionary, zone: StringName) -> bool:
	return rules.get("cieux", zone in ZONES)


## How much harder (or softer) a move of this type hits in the wind.
static func power(move_type: String) -> float:
	match move_type:
		"vent":
			return WIND_BOOST
		"terre":
			return EARTH_DAMP
	return 1.0


## A sign on a move's card: ▲ stronger in the wind, ▼ weaker ("" otherwise).
func mark(move_type: String) -> String:
	var k := power(move_type)
	return "▲" if k > 1.0 else "▼" if k < 1.0 else ""


func _damage(side: String, other: String, move: Dictionary) -> Dictionary:
	var hit := super(side, other, move)
	hit["damage"] = maxi(1, int(hit["damage"] * power(move["type"])))
	return hit


func _use_move(side: String, index: int, ev: Array) -> void:
	var before := ev.size()
	super(side, index, ev)
	_tell_rules(side, index, ev, before)


## The first Wind or Earth move that hits in the battle: a line says what the wind does to it.
func _tell_rules(side: String, index: int, ev: Array, from: int) -> void:
	var moves: Array = dino(side).moves
	if index >= moves.size():
		return
	var move_type: String = MovesDB.move(moves[index]["id"])["type"]
	if not TOLD.has(move_type) or _told.has(move_type):
		return
	for i in range(from, ev.size()):
		if ev[i]["type"] == "damage":
			_told[move_type] = true
			ev.append({"type": "text", "text": TOLD[move_type]})
			return
