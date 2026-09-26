class_name Dino
extends RefCounted
## One dino owned or met by Chloé. Its body is a "build": which species each part comes
## from. A pure dino has every part from its own species; the Cabinet's hybridizer
## replaces parts (a raptor with a Protoceratops head gets Charge).
## Stats, experience and move learning follow the Phaser version (battle/dino.js).

const PARTS: Array[StringName] = [&"head", &"teeth", &"front_legs", &"back_legs", &"back", &"tail"]
const MAX_LEVEL := 50
const MAX_MOVES := 4
const FAMILY_INTELLIGENCE := {
	&"raptor": 9, &"tyrant": 7, &"spino": 6, &"marine": 6, &"ceratopsian": 5,
	&"hadrosaur": 5, &"flyer": 5, &"armored": 3, &"sauropod": 2,
}

var build: Dictionary = {}   # part -> species id
var nickname := ""
var level := 1
var xp := 0
var hp := 1
var moves: Array = []        # [{"id": StringName, "pp": int}]
var status := ""             # "", "saigne", "etourdi", "peur"
var status_turns := 0


static func create(species_id: StringName, lvl: int, name := "") -> Dino:
	var d := Dino.new()
	for part in PARTS:
		d.build[part] = species_id
	d.level = lvl
	d.nickname = name if name != "" else SpeciesDB.get_species(species_id).display_name
	d.moves = d._moves_at_level()
	d.hp = d.stats()["hp"]
	return d


static func from_dict(data: Dictionary) -> Dino:
	var d := Dino.new()
	var saved_build: Dictionary = data.get("build", {})
	var head := StringName(saved_build.get("head", ""))
	if not SpeciesDB.PATHS.has(head):
		push_warning("Dino ignoré (espèce inconnue : %s)" % head)
		return null
	for part in PARTS:
		var id := StringName(saved_build.get(String(part), head))
		d.build[part] = id if SpeciesDB.PATHS.has(id) else head
	d.nickname = data.get("nickname", "")
	d.level = int(data.get("level", 1))
	d.xp = int(data.get("xp", 0))
	d.moves = []
	for m: Dictionary in data.get("moves", []):
		if MovesDB.MOVES.has(StringName(m.get("id", ""))):
			d.moves.append({"id": StringName(m["id"]), "pp": int(m.get("pp", 0))})
	if d.moves.is_empty():
		d.moves = d._moves_at_level()
	d.hp = clampi(int(data.get("hp", 1)), 0, d.stats()["hp"])
	return d


func to_dict() -> Dictionary:
	var b := {}
	for part in PARTS:
		b[String(part)] = String(build[part])
	var m := moves.map(func(x: Dictionary) -> Dictionary: return {"id": String(x["id"]), "pp": x["pp"]})
	return {"build": b, "nickname": nickname, "level": level, "xp": xp, "hp": hp, "moves": m}


	## The species the dino looks like (its head decides, as in the Phaser version).
func species() -> DinoSpecies:
	return SpeciesDB.get_species(build[&"head"])


func part_species(part: StringName) -> DinoSpecies:
	return SpeciesDB.get_species(build[part])


func is_hybrid() -> bool:
	for part in PARTS:
		if build[part] != build[&"head"]:
			return true
	return false


func species_name() -> String:
	return species().display_name + (" hybride" if is_hybrid() else "")


## Elemental type, from the head's family.
func type() -> String:
	return MovesDB.FAMILY_TYPES.get(species().family, "terre")


## Part stats (Phaser computeStats), each mixing the parts it depends on.
func part_stats() -> Dictionary:
	var h := part_species(&"head")
	var t := part_species(&"teeth")
	var f := part_species(&"front_legs")
	var b := part_species(&"back_legs")
	var bk := part_species(&"back")
	var tl := part_species(&"tail")
	return {
		"attaque": snappedf((h.head_bite + t.teeth_sharp + tl.tail_power) / 3.0, 0.1),
		"defense": snappedf((bk.back_armor + bk.back_spikes + h.head_size * 0.5) / 2.5, 0.1),
		"vitesse": snappedf((b.back_legs_speed * 1.5 + f.front_reach * 0.5) / 2.0, 0.1),
		"force": snappedf((b.back_legs_power + f.front_power + tl.tail_power) / 3.0, 0.1),
		"taille": snappedf((h.head_size + f.front_reach + tl.tail_length) / 3.0, 0.1),
		"intel": snappedf(FAMILY_INTELLIGENCE.get(h.family, 5) * 0.7 + FAMILY_INTELLIGENCE.get(f.family, 5) * 0.3, 0.1),
	}


## Battle stats (Phaser statsOf): part stats scaled by level, like Pokémon base stats.
func stats() -> Dictionary:
	var s := part_stats()
	var l := float(level)
	return {
		"hp": int(((s["defense"] + s["taille"]) * 2.2 + 14.0) * l / 12.0) + level + 12,
		"atk": int((s["attaque"] * 2.0 + s["force"]) * l / 12.0) + 6,
		"def": int((s["defense"] * 2.0 + s["taille"]) * l / 12.0) + 6,
		"spd": int((s["vitesse"] * 3.0) * l / 12.0) + 5,
	}


func max_hp() -> int:
	return stats()["hp"]


static func xp_to_next(lvl: int) -> int:
	return int(10 + lvl * lvl * 1.6)


## Experience given by beating this dino.
func xp_reward() -> int:
	return int(18 + level * 7)


func heal() -> void:
	hp = max_hp()
	status = ""
	for m: Dictionary in moves:
		m["pp"] = MovesDB.move(m["id"])["pp"]


## Adds experience. Returns the events: {"type": "level", "level"} and
## {"type": "learn", "move", "replaced"}.
func gain_xp(amount: int) -> Array:
	var events: Array = []
	xp += amount
	while level < MAX_LEVEL and xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		var before := max_hp()
		level += 1
		hp += max_hp() - before
		events.append({"type": "level", "level": level})
		for e: Array in MovesDB.learnset(self):
			if e[0] != level or moves.any(func(k: Dictionary) -> bool: return k["id"] == e[1]):
				continue
			var replaced := &""
			if moves.size() >= MAX_MOVES:
				var weakest: Dictionary = moves[0]
				for k: Dictionary in moves:
					if MovesDB.move(k["id"])["power"] < MovesDB.move(weakest["id"])["power"]:
						weakest = k
				replaced = weakest["id"]
				moves.erase(weakest)
			moves.append({"id": e[1], "pp": MovesDB.move(e[1])["pp"]})
			events.append({"type": "learn", "move": e[1], "replaced": replaced})
	if level >= MAX_LEVEL:
		xp = 0
	return events


func _moves_at_level() -> Array:
	var known := MovesDB.learnset(self).filter(func(e: Array) -> bool: return e[0] <= level)
	return known.slice(maxi(0, known.size() - MAX_MOVES)).map(
		func(e: Array) -> Dictionary: return {"id": e[1], "pp": MovesDB.move(e[1])["pp"]})
