extends RefCounted
## Nouvelle partie+ (docs/post-game-plan.md § 4, docs/mecaniques.md « Nouvelle partie+ ») : what a finished game
## passes on to the next one, and how much stronger the foes get. Pure functions over a game's flags (a Dictionary
## with String keys, as saved): Game (core/game_state.gd) keeps the state and calls them —
##   Game.new_game_plus, ng_plus, pages_read_before, egg_known, owned_before, level_bonus, foe_kind, strengthen.
## No class_name: preloaded (const NG_PLUS_RULES := preload("res://core/ng_plus.gd")).
##
## What passes on (KEEP, carry); everything else starts again as in Game.new_game():
## - the Dinodex as it is (seen, caught, where);
## - "flags", "flag_prefixes": these flags as they are: the intro and the controls tutorial seen
##   (ControlsTutorial.FLAG), Roc's Dinodex rewards (given for this very Dinodex: reset, they would all
##   come again at once), the bones of the legendary skeletons (os_*: their objects and their flags);
## - "items", "item_prefixes": these objects, with their count: the fossils, the bones (os_*);
## - "read_prefixes": the pages found, remembered in journal_lu (grey on the wall until found again).
## Not kept, on purpose: fin_vue (the new game is not finished: its own end plays, with its own egg),
## ressuscite_* (the resurrected species stay in the Dinodex; their egg is to be made again), the party,
## the reserve, the Liens, the other objects, the story, the clock, the giants, the rematches, the badge.
const KEEP := {
	"flags": ["intro_vue", "tuto_commandes", "dex_complet"],
	"flag_prefixes": ["os_", "dex_palier_", "dex_region_"],
	"items": ["fossile"],
	"item_prefixes": ["os_"],
	"read_prefixes": ["found_journal_"],
}
## The Nouvelle partie+'s own flags (saved with the others; absent from the saves before it: 0, []): how many
## times the island was started again; the pages found in the games before; the hatchlings chosen before
## (« Celui-là, tu le connais. »); the species owned before and not caught again yet (the Dinodex).
const COUNT := &"ng_plus"
const JOURNAL_READ := &"journal_lu"
const EGGS_KNOWN := &"oeufs_connus"
const OWNED_BEFORE := &"dex_partie_precedente"
## Levels a foe gets on top of its own in a Nouvelle partie+ (foe_kind): trainers and Alphas, wild dinos.
const LEVELS := {&"trainer": 2, &"alpha": 2, &"wild": 1}
## Set on a foe once made stronger (strengthen): never twice.
const META := &"ng_plus_levels"


## What a finished game (`previous`, its to_dict()) passes on to a Nouvelle partie+: {dex_seen, dex_caught,
## dex_where, flags, items} (new copies), the flags with the Nouvelle partie+'s own (ng_plus + 1, the pages
## found, the eggs chosen, the species owned: each added to those of the games before); {} when it is not
## finished (fin_vue) or not a game.
static func carry(previous: Dictionary) -> Dictionary:
	var old_flags := _dict(previous.get("flags"))
	if not _is_true(old_flags.get("fin_vue")):
		return {}
	var kept := _kept_flags(old_flags)
	var read: Array = old_flags.keys().filter(func(k) -> bool:
		return _is_true(old_flags[k]) and _kept(String(k), [], KEEP["read_prefixes"]))
	var caught := _dict(previous.get("dex_caught"))
	var starter = old_flags.get("starter")
	kept[String(COUNT)] = int(_number(old_flags.get(String(COUNT)))) + 1
	kept[String(JOURNAL_READ)] = _joined(old_flags.get(String(JOURNAL_READ)), read)
	kept[String(EGGS_KNOWN)] = _joined(old_flags.get(String(EGGS_KNOWN)), [starter] if starter is String else [])
	kept[String(OWNED_BEFORE)] = _joined(old_flags.get(String(OWNED_BEFORE)), caught.keys())
	return {"dex_seen": _dict(previous.get("dex_seen")).duplicate(true), "dex_caught": caught.duplicate(true),
		"dex_where": _dict(previous.get("dex_where")).duplicate(true), "flags": kept,
		"items": _kept_items(_dict(previous.get("items")))}


## How many times the island was started again (0: the first game), from a game's `flags`.
static func count(flags: Dictionary) -> int:
	return int(_number(flags.get(String(COUNT))))


## The pages found in the games before (their found_journal_* flags).
static func pages_read(flags: Dictionary) -> Array:
	return _joined(flags.get(String(JOURNAL_READ)), [])


## Was this hatchling Chloé's in a game before?
static func egg_known(flags: Dictionary, species: StringName) -> bool:
	return _joined(flags.get(String(EGGS_KNOWN)), []).has(String(species))


## Owned in a game before and not caught again in this one.
static func owned_before(flags: Dictionary, species: StringName) -> bool:
	return _joined(flags.get(String(OWNED_BEFORE)), []).has(String(species))


## The species owned before, without `species` (caught again in this game): a new list for the flag.
static func owned_without(flags: Dictionary, species: StringName) -> Array:
	var key := String(species)
	return _joined(flags.get(String(OWNED_BEFORE)), []).filter(func(s: String) -> bool: return s != key)


## The levels a foe of `kind` (foe_kind) gets on top of its own after `plus` restarts (count): LEVELS, else 0.
static func level_bonus(plus: int, kind: StringName) -> int:
	return int(LEVELS.get(kind, 0)) if plus > 0 else 0


## What a battle's foe is, from the battle's rules (World._battle): a trainer's dino (« trainer »: Story.duel,
## the Relais, Isaure), an Alpha or a guardian (no collar: « catch » false), else a wild dino.
static func foe_kind(rules: Dictionary) -> StringName:
	if rules.has("trainer"):
		return &"trainer"
	if rules.get("catch", true) == false:
		return &"alpha"
	return &"wild"


## A battle's foe made `bonus` levels stronger: its level, the moves of that level, the same share of its HP.
## Changed in place — the scene that made it keeps it (to name it, to take it after a capture) — and once only
## (META), however many times it is fought.
static func strengthen(foe: Dino, bonus: int) -> void:
	if foe == null or bonus <= 0 or foe.has_meta(META):
		return
	var share := float(foe.hp) / float(maxi(1, foe.max_hp()))
	foe.set_meta(META, bonus)
	foe.level += bonus
	foe.moves = foe._moves_at_level()
	foe.hp = clampi(roundi(foe.max_hp() * share), 1 if foe.hp > 0 else 0, foe.max_hp())


static func _kept_flags(old_flags: Dictionary) -> Dictionary:
	var kept := {}
	for k in old_flags:
		if _kept(String(k), KEEP["flags"], KEEP["flag_prefixes"]):
			kept[String(k)] = old_flags[k]
	return kept


static func _kept_items(old_items: Dictionary) -> Dictionary:
	var bag := {}
	for k in old_items:
		var n := int(_number(old_items[k]))
		if n > 0 and _kept(String(k), KEEP["items"], KEEP["item_prefixes"]):
			bag[String(k)] = n
	return bag


static func _kept(key: String, names: Array, prefixes: Array) -> bool:
	return names.has(key) or prefixes.any(func(p: String) -> bool: return key.begins_with(p))


static func _is_true(value: Variant) -> bool:
	return value is bool and value


static func _dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _number(value: Variant) -> float:
	return float(value) if value is int or value is float else 0.0


## The strings of `list` (a saved list: anything else counts as empty), then those of `more` not in it.
static func _joined(list: Variant, more: Array) -> Array:
	var out: Array = []
	for v in (list if list is Array else []) + more:
		if (v is String or v is StringName) and not out.has(String(v)):
			out.append(String(v))
	return out
