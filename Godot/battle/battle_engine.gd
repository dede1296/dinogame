class_name BattleEngine
extends RefCounted
## Battle rules, without any display: same formulas as the Phaser version
## (nouveau/src/battle/engine.js). Each action returns a list of events that the battle
## scene plays one by one (text, move, damage, faint, catch…), so the rules can be tested
## on their own and the animations can change without touching them.
##
## Events: {"type": "text"|"move"|"miss"|"damage"|"heal"|"status"|"stat"|"faint"|"catch"|
##          "run"|"item"|"recall"|"switch"|"xp"|"level"|"learn"|"calm"|"calmed"|"bond"|"bond_hold"|
##          "end", …} — most carry a "text".
##
## Using a healing item (HEAL_ITEMS) on a dino of the party, or sending another one in, takes the
## turn: the foe acts after it. The item heals as out of battle (Game.feed_berry, Game.feed_fern:
## the same PV, the same little growth of the Lien), never a knocked-out dino. When the dino in
## battle is knocked out and another can fight, the player picks who takes its place
## (must_switch): that choice is the next action, and nothing else happens that turn. A dino with
## no power points left in any move struggles (STRUGGLE, the move index moves.size()): a weak blow
## that hurts itself a little; so does the foe.
##
## A corrupted foe (Dino.corrupted, black amber) cannot be caught nor knocked out: the fury
## keeps it standing at 1 PV. It is calmed instead (Apaiser): each calm action that works
## fills its calm gauge (more with a dino of its own family, or when it is worn out); an
## attack empties some of it. Full: the veins fade, the battle ends ("calmed"). Calming is
## always a way out, even for a young player: each refusal makes the next try likelier
## (CALM_RETRY_BONUS), the calmer it gets, the softer it hits (CALM_SOFTENS), and while Chloé
## speaks to it, it hesitates: that turn it hits softer still (CALM_HESITATES). Tiring it
## first also helps, as the lines say: a worn foe listens more and calms faster (worn bonus),
## and a hit only frightens it a little (CALM_LOST_ON_HIT).
##
## The Lien (Dino.bond) of the dino in battle helps, never blocks: each heart makes a calm
## action likelier to work and worth more calm; at MAX_BOND hearts, the dino holds on at 1 PV
## once per battle ("bond_hold"). A battle won (or a foe calmed) brings the dinos that fought
## a little closer (Game.grow_bond, "bond" when a heart is gained).
##
## Rules (the third argument; BattleScene passes them): "long_calm": true for a deep
## corruption, a gauge LONG_CALM_FACTOR times as long, where Chloé's own hatchling (species
## "starter") stands between her and the foe: more calm per try (CALM_STARTER_BONUS).

const STATUS_TURNS := {"saigne": 0, "etourdi": 1, "peur": 3}
const STAT_NAMES := {"atk": "L'attaque", "def": "La défense", "spd": "La vitesse"}
## The items that can be used in a battle (ItemsDB ids), and how Chloé gives them.
const HEAL_ITEMS := {"baie": "Chloé donne une baie à %s.", "fougere": "Chloé donne une fougère curative à %s."}
## No power points left: « Se débattre », weak, and it costs its user this share of its PV.
const STRUGGLE := {"name": "Se débattre", "type": "neutre", "power": 40, "accuracy": 1.0, "pp": 1, "fx": "charge"}
const STRUGGLE_RECOIL := 0.125

var team: Array[Dino]     # the player's party; `active` is the dino in battle
var active := 0
var foe: Dino
var over := false
var result := ""          # "win", "lose", "run", "catch", "calmed"
## The dino in battle is knocked out: the next action must send another in ({"type": "switch"}).
var must_switch := false
## Calm of a corrupted foe, 0 to `calm_full`.
var calm := 0
## The calm needed to free the foe: CALM_FULL, times LONG_CALM_FACTOR in a "long_calm" battle.
var calm_full := CALM_FULL
## A deep corruption (rule "long_calm"): see the header.
var long_calm := false
## Species of Chloé's hatchling (rule "starter"; &"" when unknown).
var starter: StringName = &""
## Who the foe belongs to (rule "trainer": "" for a wild dino), for its name in the lines.
var trainer := ""
const CALM_FULL := 100
const CALM_STEP := 30        # a calm action that works
const CALM_KIN_BONUS := 15   # …by a dino of the foe's family
const CALM_LOST_ON_HIT := 5  # an attack frightens it again (a little)
const CALM_BASE_CHANCE := 0.55
const CALM_MAX_CHANCE := 0.95
const CALM_BOND_CHANCE := 0.05   # per heart of the calming dino's Lien
const CALM_BOND_STEP := 3        # calm per heart
const LONG_CALM_FACTOR := 1.6
## Worn out, it calms faster: up to this much more calm per try, at 1 PV.
const CALM_WORN_STEP := 20
## While Chloé speaks to it, its blow that turn is this much softer.
const CALM_HESITATES := 0.45
const CALM_STARTER_BONUS := 15   # Chloé's hatchling, in a long calm
## A corrupted foe calming down hits softer: its blows lose up to this share (gauge full).
const CALM_SOFTENS := 0.5
## Each calm action refused in a row makes the next one likelier (it heard her all the same).
const CALM_RETRY_BONUS := 0.15
var stages := {"player": {"atk": 0, "def": 0, "spd": 0}, "foe": {"atk": 0, "def": 0, "spd": 0}}
var rng := RandomNumberGenerator.new()

var _escape_tries := 0
var _told_fury := false
var _told_starter := false
## Calm actions refused since the last one that worked.
var _calm_refusals := 0
var _calming := false   # Chloé speaks to the corrupted foe this turn: it hesitates
var _fought: Array[Dino] = []
## The dinos of the party that already held on at 1 PV this battle (Lien at MAX_BOND).
var _endured: Array[Dino] = []


func _init(player_team: Array[Dino], wild: Dino, rules := {}) -> void:
	team = player_team
	foe = wild
	active = _first_able()
	_fought.append(team[active])
	long_calm = rules.get("long_calm", false)
	starter = StringName(rules.get("starter", &""))
	trainer = String(rules.get("trainer", ""))
	if long_calm:
		calm_full = roundi(CALM_FULL * LONG_CALM_FACTOR)


func player() -> Dino:
	return team[active]


func dino(side: String) -> Dino:
	return player() if side == "player" else foe


## How the lines call a fighter: Chloé's by name; a trainer's by its name (Caillou), or
## « le Dilophosaurus de Firmin » when it has none; an Alpha or an Ancient by its title
## (« le Tricératops Alpha », « le Spinosaure Ancestral »); any other « le … sauvage/corrompu ».
func name_of(side: String) -> String:
	if side == "player":
		return player().nickname
	var named := foe.nickname != "" and foe.nickname != foe.species().display_name
	if trainer != "":
		# « Sbire à la lanterne » is who he is, not his name: « du sbire à la lanterne ».
		var owner := "le s" + trainer.substr(1) if trainer.begins_with("Sbire") else trainer
		return foe.nickname if named else "%s %s" % [French.le(foe.species_name()), French.de(owner)]
	if foe.corrupted:
		return French.le(foe.species_name() + " corrompu")
	if named:
		return French.le(foe.nickname)
	if foe.species().rarity in ["epic", "legendary"]:
		return French.le(foe.species_name())
	return French.le(foe.species_name() + " sauvage")


## One turn with the player's choice: {"type": "move", "index": i} | {"type": "catch"} |
## {"type": "calm"} | {"type": "run"} | {"type": "item", "id": "baie", "target": i} (heals dino
## i of the party; the one in battle without "target") | {"type": "switch", "index": i} (that
## dino takes its place). An item that cannot be used, or a dino that cannot fight, changes
## nothing: no event, the turn is kept. After a knock-out (must_switch), only a switch is taken.
func turn(action: Dictionary) -> Array:
	var ev: Array = []
	if over:
		return ev
	if must_switch:
		if action["type"] == "switch" and can_switch_to(int(action.get("index", -1))):
			must_switch = false
			_send_in(int(action["index"]), ev)
		return ev
	_calming = false
	var target := int(action.get("target", active))
	match action["type"]:
		"item":
			if not can_use_item(String(action.get("id", "")), target):
				return ev
		"switch":
			if not can_switch_to(int(action.get("index", -1))):
				return ev
	var foe_move := _choose_foe_move()
	match action["type"]:
		"run":
			if _try_run(ev):
				return ev
		"catch":
			if _try_catch(ev):
				return ev
		"calm":
			_calming = true
			if _try_calm(ev):
				return ev
		"item":
			_use_item(String(action["id"]), target, ev)
		"switch":
			ev.append({"type": "recall", "side": "player", "text": "Reviens, %s !" % player().nickname})
			_send_in(int(action["index"]), ev)
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
	var pp := 1 if _move_of(player(), player_move).get("priority", false) else 0
	var pf := 1 if _move_of(foe, foe_move).get("priority", false) else 0
	var sp := _speed("player")
	var sf := _speed("foe")
	return pf > pp or (pf == pp and (sf > sp or (sf == sp and rng.randf() < 0.5)))


## Move `index` of `d`: one of its moves, or STRUGGLE (index moves.size()).
static func _move_of(d: Dino, index: int) -> Dictionary:
	return MovesDB.move(d.moves[index]["id"]) if index < d.moves.size() else STRUGGLE


func _speed(side: String) -> float:
	return dino(side).stats()["spd"] * _stage_mult(stages[side]["spd"])


static func _stage_mult(s: int) -> float:
	return (2.0 + s) / 2.0 if s >= 0 else 2.0 / (2.0 - s)


func _choose_foe_move() -> int:
	var usable: Array = []
	for i in foe.moves.size():
		if foe.moves[i]["pp"] > 0:
			usable.append(i)
	return usable.pick_random() if not usable.is_empty() else foe.moves.size()   # (it struggles)


func _use_move(side: String, index: int, ev: Array) -> void:
	var other := "foe" if side == "player" else "player"
	var user := dino(side)
	var target := dino(other)
	if user.status == "etourdi":
		ev.append({"type": "text", "text": "%s est étourdi et ne peut pas bouger !" % _cap(name_of(side))})
		user.status = ""
		ev.append({"type": "status", "side": side, "status": ""})
		return
	var struggling := index >= user.moves.size()
	var slot: Dictionary = {"id": &"se_debattre", "pp": 1} if struggling else user.moves[index]
	var move := _move_of(user, index)
	slot["pp"] = maxi(0, slot["pp"] - 1)
	ev.append({"type": "move", "side": side, "move": slot["id"], "fx": move.get("fx", "charge"), "move_type": move["type"],
		"text": "%s utilise %s !" % [_cap(name_of(side)), move["name"]]})
	if rng.randf() > move["accuracy"]:
		ev.append({"type": "miss", "side": side, "text": "%s esquive l'attaque !" % _cap(name_of(other))})
		return
	if move["power"] > 0:
		var hit := _damage(side, other, move)
		var held := _hurt(other, hit["damage"])
		ev.append({"type": "damage", "side": other, "amount": hit["damage"], "hp": target.hp, "max_hp": target.max_hp(),
			"crit": hit["crit"], "eff": hit["eff"], "move_type": move["type"]})
		if hit["crit"]:
			ev.append({"type": "text", "text": "Coup critique !"})
		if hit["eff"] > 1.0:
			ev.append({"type": "text", "text": "C'est super efficace !"})
		elif hit["eff"] < 1.0:
			ev.append({"type": "text", "text": "Ce n'est pas très efficace…"})
		if held:
			_tell_held_on(ev)
		if other == "foe" and foe.corrupted:
			_frighten(ev)
		if struggling:
			_struggle_recoil(side, ev)
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
	var soft := 1.0
	if side == "foe" and foe.corrupted:
		soft = (1.0 - CALM_SOFTENS * calm / float(calm_full)) * (1.0 - CALM_HESITATES if _calming else 1.0)
	var total := maxi(1, int(dmg * stab * eff * soft * (1.5 if crit else 1.0) * (0.85 + rng.randf() * 0.15)))
	return {"damage": total, "crit": crit, "eff": eff}


## Struggling hurts its user a little (STRUGGLE_RECOIL of its PV).
func _struggle_recoil(side: String, ev: Array) -> void:
	var d := dino(side)
	if d.hp <= 0:
		return
	var loss := maxi(1, ceili(d.max_hp() * STRUGGLE_RECOIL))
	var held := _hurt(side, loss)
	ev.append({"type": "damage", "side": side, "amount": loss, "hp": d.hp, "max_hp": d.max_hp(), "bleed": true,
		"crit": false, "eff": 1.0, "text": "%s se fait mal en se débattant…" % _cap(name_of(side))})
	if held:
		_tell_held_on(ev)


func _change_stage(side: String, stat: String, delta: int, ev: Array) -> void:
	var before: int = stages[side][stat]
	stages[side][stat] = clampi(before + delta, -4, 4)
	var who := _cap(name_of(side))
	if stages[side][stat] == before:
		ev.append({"type": "text", "text": "%s %s ne peut plus changer !" % [STAT_NAMES[stat], French.de(who)]})
		return
	var word := "augmente beaucoup" if delta > 1 else "augmente" if delta > 0 else "baisse beaucoup" if delta < -1 else "baisse"
	ev.append({"type": "stat", "side": side, "stat": stat, "delta": delta, "text": "%s %s %s !" % [STAT_NAMES[stat], French.de(who), word]})


func _end_of_turn(ev: Array) -> void:
	for side in ["player", "foe"]:
		var d := dino(side)
		if d.hp <= 0 or d.status == "":
			continue
		if d.status == "saigne":
			var loss := maxi(1, d.max_hp() / 12)
			var held := _hurt(side, loss)
			ev.append({"type": "damage", "side": side, "amount": loss, "hp": d.hp, "max_hp": d.max_hp(), "bleed": true,
				"crit": false, "eff": 1.0, "text": "%s perd du sang…" % _cap(name_of(side))})
			if held:
				_tell_held_on(ev)
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
	if player().hp <= 0 and not must_switch:
		ev.append({"type": "faint", "side": "player", "text": "%s est K.O. !" % player().nickname})
		var next := _first_able()
		if next < 0:
			ev.append({"type": "text", "text": "Tous tes dinos sont épuisés…"})
			_finish("lose", ev)
			return true
		must_switch = true   # Chloé picks who goes in: the next action
		return true
	return false


## Dino `index` of the party goes into battle (its stat changes start afresh; it shares the XP).
func _send_in(index: int, ev: Array) -> void:
	active = index
	stages["player"] = {"atk": 0, "def": 0, "spd": 0}
	if not _fought.has(player()):
		_fought.append(player())
	ev.append({"type": "switch", "side": "player", "text": "Vas-y, %s !" % player().nickname})


## Can dino `index` of the party take the place of the one in battle? (standing, not already in)
func can_switch_to(index: int) -> bool:
	return index >= 0 and index < team.size() and index != active and team[index].hp > 0


## Is there an item `id` to give dino `target` of the party (-1: the one in battle), and would it
## help? (HEAL_ITEMS; standing, not at full PV: an item never brings back a knocked-out dino)
func can_use_item(id: String, target := -1) -> bool:
	var i := active if target < 0 else target
	if not HEAL_ITEMS.has(id) or Game.item_count(id) <= 0 or i >= team.size():
		return false
	return team[i].hp > 0 and team[i].hp < team[i].max_hp()


## Dino `target` of the party eats a berry or a fern (see HEAL_ITEMS): the same care as out of
## battle. The events carry the dino ("dino"): it may not be the one in battle.
func _use_item(id: String, target: int, ev: Array) -> void:
	var d := team[target]
	var before := d.hp
	var used := Game.feed_berry(d) if id == "baie" else Game.feed_fern(d) > 0
	if not used:
		return
	ev.append({"type": "item", "id": id, "side": "player", "dino": d, "text": HEAL_ITEMS[id] % d.nickname})
	var text := "%s est complètement soigné !" % d.nickname if id == "fougere" else "%s récupère %d PV !" % [d.nickname, d.hp - before]
	ev.append({"type": "heal", "side": "player", "dino": d, "amount": d.hp - before, "hp": d.hp, "max_hp": d.max_hp(), "text": text})


## How well move `index` of the dino in battle would hit the foe: 1 strong, -1 weak, 0 as usual
## (or a move that does not hurt). For the hint on its card.
func move_hint(index: int) -> int:
	var move := _move_of(player(), index)
	if move["power"] <= 0:
		return 0
	var eff := MovesDB.effectiveness(move["type"], foe.type())
	return 1 if eff > 1.0 else -1 if eff < 1.0 else 0


## XP for the dinos that fought; a share for the rest of the party (Game.XP_SHARE). Those
## that fought and are still standing grow closer to Chloé (Game.BOND_WIN bond points).
func _give_xp(ev: Array) -> void:
	var reward := foe.xp_reward()
	for d in team:
		if d.hp <= 0:
			continue
		var amount := reward if _fought.has(d) else int(reward * Game.XP_SHARE)
		var gained := maxi(1, roundi(amount * Game.catch_up(d)))
		ev.append({"type": "xp", "dino": d, "amount": gained, "text": "%s gagne %d points d'expérience." % [d.nickname, gained]})
		for e: Dictionary in Game.award_xp(d, amount):
			if e["type"] == "level":
				ev.append({"type": "level", "dino": d, "text": "%s passe au niveau %d !" % [d.nickname, e["level"]]})
			else:
				var name: String = MovesDB.move(e["move"])["name"]
				var text := "%s apprend %s !" % [d.nickname, name]
				if e["replaced"] != &"":
					text = "%s oublie %s et apprend %s !" % [d.nickname, MovesDB.move(e["replaced"])["name"], name]
				ev.append({"type": "learn", "dino": d, "text": text})
		if _fought.has(d) and Game.grow_bond(d, Game.BOND_WIN) > 0:
			ev.append({"type": "bond", "dino": d, "text": "Le lien entre Chloé et %s grandit ! (%d ♥)" % [d.nickname, d.bond]})


## A corrupted foe never goes below 1 PV: only calming it ends the battle.
func _lowest_hp(side: String) -> int:
	return 1 if side == "foe" and foe.corrupted else 0


## Takes `amount` PV from `side`. A dino of the party with a full Lien holds on at 1 PV
## instead of falling, once per battle: returns true when it just did.
func _hurt(side: String, amount: int) -> bool:
	var d := dino(side)
	var hp := maxi(_lowest_hp(side), d.hp - amount)
	var holds: bool = side == "player" and hp <= 0 and d.hp > 1 and d.bond >= Dino.MAX_BOND and not _endured.has(d)
	if holds:
		_endured.append(d)
		hp = 1
	d.hp = hp
	return holds


func _tell_held_on(ev: Array) -> void:
	ev.append({"type": "bond_hold", "side": "player", "text": "%s tient bon, pour Chloé ! Le Lien le garde debout." % player().nickname})


## Hit, it is frightened again: some calm is lost (and, the first time it holds on at 1 PV,
## the player is told why it does not fall).
func _frighten(ev: Array) -> void:
	if calm > 0:
		calm = maxi(0, calm - CALM_LOST_ON_HIT)
		ev.append({"type": "calm", "calm": calm, "text": "Le coup l'affole : il se méfie davantage…"})
	if foe.hp == 1 and not _told_fury:
		_told_fury = true
		ev.append({"type": "text", "text": "La fureur le tient debout ! Seul l'apaisement peut l'arrêter."})


## Speaking softly to it (the dino in battle, then Chloé). Works more often when it is worn
## out and with a strong Lien; a dino of its own family, a strong Lien, and in a long calm
## Chloé's own hatchling, calm it faster.
func _try_calm(ev: Array) -> bool:
	var helper: bool = starter_helps()
	var foe_name: String = French.le(foe.species_name() + " corrompu")
	if helper and not _told_starter:
		_told_starter = true
		ev.append({"type": "text", "text": "%s se met entre Chloé et %s…" % [player().nickname, foe_name]})
	ev.append({"type": "text", "text": "%s s'approche doucement %s, et Chloé lui parle tout bas…" % [player().nickname, French.de(foe_name)]})
	if rng.randf() >= calm_chance():
		_calm_refusals += 1
		ev.append({"type": "text", "text": "%s gronde et refuse d'écouter… mais il l'a entendue." % _cap(name_of("foe"))})
		return false
	_calm_refusals = 0
	var kin := player().species().family == foe.species().family
	calm = mini(calm_full, calm + calm_step())
	var how := "Il reconnaît un dino de sa famille : il s'apaise vite !" if kin else "Il écoute… ses veines violettes pâlissent un peu."
	if helper:
		how = "Il fixe %s, qui ne recule pas… ses veines violettes pâlissent !" % player().nickname
	ev.append({"type": "calm", "calm": calm, "text": how})
	if calm < calm_full:
		return false
	ev.append({"type": "calmed", "text": "Les veines violettes s'effacent. %s est apaisé !" % _cap(foe.species_name())})
	foe.corrupted = false
	foe.status = ""
	_give_xp(ev)
	_finish("calmed", ev)
	return true


## Chance that a calm action by the dino in battle works: more when the foe is worn out,
## more with each heart of its Lien, more after each refusal in a row.
func calm_chance() -> float:
	var worn := 1.0 - float(foe.hp) / foe.max_hp()
	return clampf(CALM_BASE_CHANCE + worn * 0.4 + player().bond * CALM_BOND_CHANCE + _calm_refusals * CALM_RETRY_BONUS,
		0.0, CALM_MAX_CHANCE)


## Calm brought by a calm action that works (of `calm_full`).
func calm_step() -> int:
	var worn := 1.0 - float(foe.hp) / foe.max_hp()
	var step: int = CALM_STEP + player().bond * CALM_BOND_STEP + roundi(worn * CALM_WORN_STEP)
	if player().species().family == foe.species().family:
		step += CALM_KIN_BONUS
	if starter_helps():
		step += CALM_STARTER_BONUS
	return step


## In a long calm, the dino in battle is Chloé's own hatchling: it helps her calm the foe.
func starter_helps() -> bool:
	return long_calm and starter != &"" and player().species().id == starter


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
