class_name BattleEngine
extends RefCounted
## Battle rules, without any display: same formulas as the Phaser version
## (nouveau/src/battle/engine.js). Each action returns a list of events that the battle
## scene plays one by one (text, move, damage, faint, catch…), so the rules can be tested
## on their own and the animations can change without touching them.
##
## Events: {"type": "text"|"move"|"miss"|"damage"|"heal"|"status"|"stat"|"faint"|"catch"|
##          "run"|"switch"|"xp"|"level"|"learn"|"end", …} — most carry a "text".

const STATUS_TURNS := {"saigne": 0, "etourdi": 1, "peur": 3}
const STAT_NAMES := {"atk": "L'attaque", "def": "La défense", "spd": "La vitesse"}
const XP_SHARE := 0.5   # part of the XP for party members who did not fight

var team: Array[Dino]     # the player's party; `active` is the dino in battle
var active := 0
var foe: Dino
var over := false
var result := ""          # "win", "lose", "run", "catch"
var stages := {"player": {"atk": 0, "def": 0, "spd": 0}, "foe": {"atk": 0, "def": 0, "spd": 0}}
var rng := RandomNumberGenerator.new()

var _escape_tries := 0
var _fought: Array[Dino] = []


func _init(player_team: Array[Dino], wild: Dino) -> void:
	team = player_team
	foe = wild
	active = _first_able()
	_fought.append(team[active])


func player() -> Dino:
	return team[active]


func dino(side: String) -> Dino:
	return player() if side == "player" else foe


func name_of(side: String) -> String:
	return player().nickname if side == "player" else "le %s sauvage" % foe.species_name()


## One turn with the player's choice: {"type": "move", "index": i} | {"type": "catch"} | {"type": "run"}.
func turn(action: Dictionary) -> Array:
	var ev: Array = []
	if over:
		return ev
	var foe_move := _choose_foe_move()
	match action["type"]:
		"run":
			if _try_run(ev):
				return ev
		"catch":
			if _try_catch(ev):
				return ev
	var order: Array = []
	if action["type"] == "move":
		order.append({"side": "player", "move": action["index"]})
	order.append({"side": "foe", "move": foe_move})
	if order.size() == 2 and _foe_goes_first(action["index"], foe_move):
		order.reverse()
	for o: Dictionary in order:
		if over:
			break
		if dino(o["side"]).hp <= 0:
			continue
		_use_move(o["side"], o["move"], ev)
		if _check_faints(ev):
			break
	if not over:
		_end_of_turn(ev)
	return ev


func _foe_goes_first(player_move: int, foe_move: int) -> bool:
	var pp := 1 if MovesDB.move(player().moves[player_move]["id"]).get("priority", false) else 0
	var pf := 1 if MovesDB.move(foe.moves[foe_move]["id"]).get("priority", false) else 0
	var sp := _speed("player")
	var sf := _speed("foe")
	return pf > pp or (pf == pp and (sf > sp or (sf == sp and rng.randf() < 0.5)))


func _speed(side: String) -> float:
	return dino(side).stats()["spd"] * _stage_mult(stages[side]["spd"])


static func _stage_mult(s: int) -> float:
	return (2.0 + s) / 2.0 if s >= 0 else 2.0 / (2.0 - s)


func _choose_foe_move() -> int:
	var usable: Array = []
	for i in foe.moves.size():
		if foe.moves[i]["pp"] > 0:
			usable.append(i)
	return usable.pick_random() if not usable.is_empty() else 0


func _use_move(side: String, index: int, ev: Array) -> void:
	var other := "foe" if side == "player" else "player"
	var user := dino(side)
	var target := dino(other)
	if user.status == "etourdi":
		ev.append({"type": "text", "text": "%s est étourdi et ne peut pas bouger !" % _cap(name_of(side))})
		user.status = ""
		ev.append({"type": "status", "side": side, "status": ""})
		return
	var slot: Dictionary = user.moves[index] if index < user.moves.size() else {"id": &"charge", "pp": 1}
	var move := MovesDB.move(slot["id"])
	slot["pp"] = maxi(0, slot["pp"] - 1)
	ev.append({"type": "move", "side": side, "move": slot["id"], "fx": move.get("fx", "charge"), "move_type": move["type"],
		"text": "%s utilise %s !" % [_cap(name_of(side)), move["name"]]})
	if rng.randf() > move["accuracy"]:
		ev.append({"type": "miss", "side": side, "text": "%s esquive l'attaque !" % _cap(name_of(other))})
		return
	if move["power"] > 0:
		var hit := _damage(side, other, move)
		target.hp = maxi(0, target.hp - hit["damage"])
		ev.append({"type": "damage", "side": other, "amount": hit["damage"], "hp": target.hp, "max_hp": target.max_hp(),
			"crit": hit["crit"], "eff": hit["eff"], "move_type": move["type"]})
		if hit["crit"]:
			ev.append({"type": "text", "text": "Coup critique !"})
		if hit["eff"] > 1.0:
			ev.append({"type": "text", "text": "C'est super efficace !"})
		elif hit["eff"] < 1.0:
			ev.append({"type": "text", "text": "Ce n'est pas très efficace…"})
	var fx: Dictionary = move.get("effect", {})
	if fx.has("heal"):
		var amount := mini(user.max_hp() - user.hp, ceili(user.max_hp() * fx["heal"]))
		user.hp += amount
		ev.append({"type": "heal", "side": side, "amount": amount, "hp": user.hp, "max_hp": user.max_hp(),
			"text": "%s récupère des forces !" % _cap(name_of(side))})
	if fx.has("status") and target.hp > 0 and target.status == "" and rng.randf() < fx["chance"]:
		target.status = fx["status"]
		target.status_turns = STATUS_TURNS[fx["status"]]
		var msg: String = {"saigne": "saigne !", "etourdi": "est étourdi !", "peur": "a peur !"}[fx["status"]]
		ev.append({"type": "status", "side": other, "status": fx["status"], "text": "%s %s" % [_cap(name_of(other)), msg]})
	for key in ["self", "foe"]:
		if fx.has(key):
			var s := side if key == "self" else other
			for stat in fx[key]:
				_change_stage(s, stat, fx[key][stat], ev)


## Phaser formula: Pokémon-like damage with same-type bonus, type chart, crits, ±15 %.
func _damage(side: String, other: String, move: Dictionary) -> Dictionary:
	var user := dino(side)
	var target := dino(other)
	var a: float = user.stats()["atk"] * _stage_mult(stages[side]["atk"]) * (0.6 if user.status == "peur" else 1.0)
	var d: float = target.stats()["def"] * _stage_mult(stages[other]["def"])
	var l := float(user.level)
	var dmg: float = floorf(floorf((2.0 * l / 5.0 + 2.0) * move["power"] * (a / d)) / 50.0) + 2.0
	var stab := 1.25 if move["type"] == user.type() else 1.0
	var eff := MovesDB.effectiveness(move["type"], target.type())
	var crit := rng.randf() < (1.0 / 6.0 if move.get("crit", false) else 1.0 / 16.0)
	var total := maxi(1, int(dmg * stab * eff * (1.5 if crit else 1.0) * (0.85 + rng.randf() * 0.15)))
	return {"damage": total, "crit": crit, "eff": eff}


func _change_stage(side: String, stat: String, delta: int, ev: Array) -> void:
	var before: int = stages[side][stat]
	stages[side][stat] = clampi(before + delta, -4, 4)
	var who := _cap(name_of(side))
	if stages[side][stat] == before:
		ev.append({"type": "text", "text": "%s de %s ne peut plus changer !" % [STAT_NAMES[stat], who]})
		return
	var word := "augmente beaucoup" if delta > 1 else "augmente" if delta > 0 else "baisse beaucoup" if delta < -1 else "baisse"
	ev.append({"type": "stat", "side": side, "stat": stat, "delta": delta, "text": "%s de %s %s !" % [STAT_NAMES[stat], who, word]})


func _end_of_turn(ev: Array) -> void:
	for side in ["player", "foe"]:
		var d := dino(side)
		if d.hp <= 0 or d.status == "":
			continue
		if d.status == "saigne":
			var loss := maxi(1, d.max_hp() / 12)
			d.hp = maxi(0, d.hp - loss)
			ev.append({"type": "damage", "side": side, "amount": loss, "hp": d.hp, "max_hp": d.max_hp(), "bleed": true,
				"crit": false, "eff": 1.0, "text": "%s perd du sang…" % _cap(name_of(side))})
		elif d.status == "peur":
			d.status_turns -= 1
			if d.status_turns <= 0:
				d.status = ""
				ev.append({"type": "status", "side": side, "status": "", "text": "%s n'a plus peur." % _cap(name_of(side))})
	_check_faints(ev)


func _check_faints(ev: Array) -> bool:
	if foe.hp <= 0:
		ev.append({"type": "faint", "side": "foe", "text": "%s est K.O. !" % _cap(name_of("foe"))})
		_give_xp(ev)
		_finish("win", ev)
		return true
	if player().hp <= 0:
		ev.append({"type": "faint", "side": "player", "text": "%s est K.O. !" % player().nickname})
		var next := _first_able()
		if next < 0:
			ev.append({"type": "text", "text": "Tous tes dinos sont épuisés…"})
			_finish("lose", ev)
			return true
		active = next
		stages["player"] = {"atk": 0, "def": 0, "spd": 0}
		if not _fought.has(player()):
			_fought.append(player())
		ev.append({"type": "switch", "side": "player", "text": "Vas-y, %s !" % player().nickname})
		return true
	return false


## XP for the dinos that fought; a share for the rest of the party (Phaser rules).
func _give_xp(ev: Array) -> void:
	var reward := foe.xp_reward()
	for d in team:
		if d.hp <= 0:
			continue
		var amount := reward if _fought.has(d) else int(reward * XP_SHARE)
		ev.append({"type": "xp", "dino": d, "amount": amount, "text": "%s gagne %d points d'expérience." % [d.nickname, amount]})
		for e: Dictionary in d.gain_xp(amount):
			if e["type"] == "level":
				ev.append({"type": "level", "dino": d, "text": "%s passe au niveau %d !" % [d.nickname, e["level"]]})
			else:
				var name: String = MovesDB.move(e["move"])["name"]
				var text := "%s apprend %s !" % [d.nickname, name]
				if e["replaced"] != &"":
					text = "%s oublie %s et apprend %s !" % [d.nickname, MovesDB.move(e["replaced"])["name"], name]
				ev.append({"type": "learn", "dino": d, "text": text})


func _try_run(ev: Array) -> bool:
	_escape_tries += 1
	var chance := (_speed("player") / _speed("foe")) * 0.5 + 0.35 + _escape_tries * 0.15
	if rng.randf() < chance:
		ev.append({"type": "run", "success": true, "text": "Tu prends la fuite !"})
		_finish("run", ev)
		return true
	ev.append({"type": "run", "success": false, "text": "Impossible de fuir !"})
	return false


## Phaser rule: the weaker the dino, the easier; a status helps. 0 to 3 shakes.
func _try_catch(ev: Array) -> bool:
	var ratio := float(foe.hp) / foe.max_hp()
	var chance := clampf(foe.species().catch_ease() * (1.0 - ratio * 0.75) * (1.4 if foe.status != "" else 1.0), 0.05, 0.95)
	var per_shake := pow(chance, 1.0 / 3.0)
	var shakes := 0
	while shakes < 3 and rng.randf() < per_shake:
		shakes += 1
	var success := shakes == 3
	ev.append({"type": "catch", "shakes": shakes, "success": success, "text": "Tu lances un Collier d'ambre !"})
	if success:
		ev.append({"type": "text", "text": "%s est capturé !" % foe.species_name()})
		_finish("catch", ev)
		return true
	var misses := ["Oh non ! Il s'est libéré tout de suite !", "Presque ! Il s'est libéré.", "Aaah ! C'était si proche !"]
	ev.append({"type": "text", "text": misses[shakes]})
	return false


func _finish(how: String, ev: Array) -> void:
	over = true
	result = how
	for d in team:
		d.status = ""
	ev.append({"type": "end", "result": how})


func _first_able() -> int:
	for i in team.size():
		if team[i].hp > 0:
			return i
	return -1


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)
