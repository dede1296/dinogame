class_name UnderwaterEngine
extends BattleEngine
## A battle under the sea (la Plongée, chapter 5): the rules of BattleEngine, and the water's own
## (told the first time a battle is fought down there, BattleUnderwater; shown on the moves'
## cards, mark()): Water moves hit harder (WATER_BOOST), Fire is stifled (FIRE_DAMP), and the
## dinos that cannot swim (neither Nage nor Plongée, whatever their age) are slower (LAND_SLOW).
## Rule "abyss" (the Mosasaure Abyssal): a rhythm in three beats, told as it comes. After
## ABYSS_AFTER turns it sinks into the dark of the abyss (at the end of a turn); the next turn
## Chloé's moves cannot reach it (only those on her own dino work: Blindage, a heal…), then it
## surges and strikes with its great dive (Plongeon abyssal, else its strongest Water move).
## Carried by its rush, it stays exposed: the next turn, Chloé's blow is a sure critical hit.
## Events {"type": "abyss", "kind": "hide" | "surge" | "exposed", "text"} (BattleUnderwater.abyss).

const WATER_BOOST := 1.25
const FIRE_DAMP := 0.5
const LAND_SLOW := 0.75
const ABYSS_AFTER := 2
const SURGE_MOVE := &"plongeon"
## Said the first time in the battle that a rule shows.
const TOLD := {
	"eau": "L'eau porte le coup : sous la mer, les attaques Eau frappent plus fort !",
	"feu": "Sous l'eau, les flammes s'étouffent : l'attaque perd la moitié de sa force…",
}
const LOST := "Trop profond : l'attaque se perd dans le noir…"
const EXPOSED := "Emporté par son élan, il reste à découvert : c'est le moment de frapper !"
## Before the Mosasaure's battle (Story: rules "lesson").
const ABYSS_LESSON := [
	"Le Mosasaure est un dino de l'Eau : le Vent le frappe fort, et les dinos Vent ou Nature encaissent mieux ses coups.",
	"Quand il plonge dans le noir, tes attaques ne l'atteignent pas : protège-toi. Quand il jaillit, il reste à découvert : frappe à ce moment-là !",
]

enum Deep { NONE, HIDDEN, EXPOSED }

var abyss := false
var deep := Deep.NONE
var _since := 0         # turns since it last came up
var _surged := false    # it came up this turn (exposed from the next one)
var _told := {}


func _init(player_team: Array[Dino], wild: Dino, rules := {}) -> void:
	super(player_team, wild, rules)
	abyss = rules.get("abyss", false)


## Does `d` swim (Nage or Plongée, even young)? It keeps its speed under the water.
static func swims(d: Dino) -> bool:
	return Abilities.has(d, &"nage") or Abilities.has(d, &"plongee")


## How much harder (or softer) a move of this type hits under the water.
static func power(move_type: String) -> float:
	match move_type:
		"eau":
			return WATER_BOOST
		"feu":
			return FIRE_DAMP
	return 1.0


## A sign on a move's card: ▲ stronger under the water, ▼ weaker ("" otherwise).
func mark(move_type: String) -> String:
	var k := power(move_type)
	return "  ▲" if k > 1.0 else "  ▼" if k < 1.0 else ""


func _speed(side: String) -> float:
	return super(side) * (1.0 if swims(dino(side)) else LAND_SLOW)


func _damage(side: String, other: String, move: Dictionary) -> Dictionary:
	var hit := super(side, other, move)
	var k := power(move["type"])
	if side == "player" and deep == Deep.EXPOSED and not _surged and not hit["crit"]:
		hit["crit"] = true   # it is exposed: a sure critical hit
		k *= 1.5
	hit["damage"] = maxi(1, int(hit["damage"] * k))
	return hit


func _choose_foe_move() -> int:
	if not abyss:
		return super()
	var surge := _surge_move()
	if deep == Deep.HIDDEN:
		return surge
	# Its great dive is kept for when it surges.
	var usable: Array = []
	for i in foe.moves.size():
		if foe.moves[i]["pp"] > 0 and i != surge:
			usable.append(i)
	return usable.pick_random() if not usable.is_empty() else super()


## Its strongest move with power points left: Plongeon abyssal first, then Water moves.
func _surge_move() -> int:
	var best := 0
	var best_score := -1.0
	for i in foe.moves.size():
		var slot: Dictionary = foe.moves[i]
		if slot["pp"] <= 0:
			continue
		var move := MovesDB.move(slot["id"])
		var score: float = move["power"] + (1000.0 if slot["id"] == SURGE_MOVE else 0.0) + (100.0 if move["type"] == "eau" else 0.0)
		if score > best_score:
			best_score = score
			best = i
	return best


func _foe_goes_first(player_move: int, foe_move: int) -> bool:
	if deep == Deep.HIDDEN:
		return false   # from the dark, it surges once Chloé has acted
	return super(player_move, foe_move)


func _use_move(side: String, index: int, ev: Array) -> void:
	var user := dino(side)
	var stunned := user.status == "etourdi"
	if side == "player" and deep == Deep.HIDDEN and not stunned and _reaches_foe(index):
		_lost_in_the_dark(index, ev)
		return
	var surging := side == "foe" and deep == Deep.HIDDEN and not stunned
	if surging:
		ev.append({"type": "abyss", "kind": "surge", "text": "%s jaillit des profondeurs !" % _cap(name_of("foe"))})
		deep = Deep.EXPOSED
		_surged = true
		_since = 0
	var before := ev.size()
	super(side, index, ev)
	if surging:
		ev.append({"type": "abyss", "kind": "exposed", "text": EXPOSED})
	_tell_rules(side, index, ev, before)


func _end_of_turn(ev: Array) -> void:
	super(ev)
	if not abyss or over:
		return
	if _surged:   # it has just come up: exposed during the next turn
		_surged = false
		return
	if deep == Deep.EXPOSED:
		deep = Deep.NONE
	_since += 1
	if deep == Deep.NONE and _since >= ABYSS_AFTER:
		deep = Deep.HIDDEN
		ev.append({"type": "abyss", "kind": "hide",
			"text": "%s s'enfonce dans le noir de l'abîme… On ne le voit plus !" % _cap(name_of("foe"))})


## A move of Chloé's dino that would reach the foe (an attack, or an effect on it).
func _reaches_foe(index: int) -> bool:
	if index >= player().moves.size():
		return true
	var move := MovesDB.move(player().moves[index]["id"])
	var fx: Dictionary = move.get("effect", {})
	return move["power"] > 0 or fx.has("foe") or fx.has("status")


## The foe is deep in the dark: the move is used (its power point too) and lost.
func _lost_in_the_dark(index: int, ev: Array) -> void:
	var slot: Dictionary = player().moves[index] if index < player().moves.size() else {"id": &"charge", "pp": 1}
	var move := MovesDB.move(slot["id"])
	slot["pp"] = maxi(0, slot["pp"] - 1)
	ev.append({"type": "move", "side": "player", "move": slot["id"], "fx": move.get("fx", "charge"), "move_type": move["type"],
		"text": "%s utilise %s !" % [_cap(name_of("player")), move["name"]]})
	ev.append({"type": "miss", "side": "player", "text": LOST})


## The first Water or Fire move that hits in the battle: a line says what the water does to it.
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
