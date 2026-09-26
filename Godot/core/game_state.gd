extends Node
## State of the current game: what the save file holds and what the scenes read.
## Scenes change it through these methods, so the save always has the full picture.

signal flag_changed(id: StringName, value: Variant)
signal party_changed

const STARTER_SPECIES := &"velociraptor"
const STARTER_NICKNAME := "Vif"
const START_REGION := &"plaines_sud"
const PARTY_MAX := 4
const START_ITEMS := {"collier": 5}

var region_id: StringName = START_REGION
## Where Chloé stands in the region; `has_position` is false until the first save in a region.
var player_position := Vector2.ZERO
var has_position := false
var party: Array[Dino] = []
## Dinos caught while the party is full (the Cabinet, later).
var box: Array[Dino] = []
var items: Dictionary = {}
var dex_seen: Dictionary = {}   # species id -> first time seen (unix seconds)
var dex_caught: Dictionary = {}
var flags: Dictionary = {}
var play_time := 0.0


func _process(delta: float) -> void:
	play_time += delta


func new_game() -> void:
	region_id = START_REGION
	player_position = Vector2.ZERO
	has_position = false
	flags = {}
	dex_seen = {}
	dex_caught = {}
	play_time = 0.0
	party = [Dino.create(STARTER_SPECIES, 5, STARTER_NICKNAME)]
	box = []
	items = START_ITEMS.duplicate()
	mark_caught(STARTER_SPECIES)
	party_changed.emit()


func item_count(id: String) -> int:
	return items.get(id, 0)


func use_item(id: String) -> bool:
	if item_count(id) <= 0:
		return false
	items[id] -= 1
	return true


## A caught dino joins the party, or the box when the party is full. Returns true if in the party.
func add_caught(d: Dino) -> bool:
	mark_caught(d.species().id)
	if party.size() < PARTY_MAX:
		party.append(d)
		party_changed.emit()
		return true
	box.append(d)
	return false


func heal_party() -> void:
	for d in party:
		d.heal()


## Flags are stored with String keys: that is what comes back from the JSON save.
func flag(id: StringName) -> Variant:
	return flags.get(String(id), false)


func set_flag(id: StringName, value: Variant = true) -> void:
	flags[String(id)] = value
	flag_changed.emit(id, value)


func mark_seen(species_id: StringName) -> bool:
	var key := String(species_id)
	if dex_seen.has(key):
		return false
	dex_seen[key] = int(Time.get_unix_time_from_system())
	return true


func mark_caught(species_id: StringName) -> bool:
	mark_seen(species_id)
	var key := String(species_id)
	if dex_caught.has(key):
		return false
	dex_caught[key] = int(Time.get_unix_time_from_system())
	return true


func lead_dino() -> Dino:
	return party[0] if not party.is_empty() else null


## First dino of the party able to use the exploration ability, or null.
func ability_user(ability: StringName) -> Dino:
	for d in party:
		if Abilities.has(d, ability):
			return d
	return null


func to_dict() -> Dictionary:
	return {
		"region": String(region_id),
		"position": [player_position.x, player_position.y],
		"has_position": has_position,
		"party": party.map(func(d: Dino) -> Dictionary: return d.to_dict()),
		"box": box.map(func(d: Dino) -> Dictionary: return d.to_dict()),
		"items": items,
		"dex_seen": dex_seen,
		"dex_caught": dex_caught,
		"flags": flags,
		"play_time": play_time,
	}


func from_dict(data: Dictionary) -> void:
	region_id = StringName(data.get("region", START_REGION))
	var pos: Array = data.get("position", [0, 0])
	player_position = Vector2(pos[0], pos[1])
	has_position = data.get("has_position", false)
	party.clear()
	for d in data.get("party", []):
		var dino := Dino.from_dict(d)
		if dino:
			party.append(dino)
	if party.is_empty():
		party = [Dino.create(STARTER_SPECIES, 5, STARTER_NICKNAME)]
	box.clear()
	for d in data.get("box", []):
		var dino := Dino.from_dict(d)
		if dino:
			box.append(dino)
	items = START_ITEMS.duplicate()
	for k in data.get("items", {}):
		items[String(k)] = int(data["items"][k])
	dex_seen = data.get("dex_seen", {})
	dex_caught = data.get("dex_caught", {})
	flags = data.get("flags", {})
	play_time = data.get("play_time", 0.0)
	party_changed.emit()
