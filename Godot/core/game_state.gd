extends Node
## State of the current game: what the save file holds and what the scenes read.
## Scenes change it through these methods, so the save always has the full picture.

signal flag_changed(id: StringName, value: Variant)
signal party_changed
## A dino gained experience (`levels`: levels gained); the party bar shows it.
signal xp_awarded(dino: Dino, amount: int, levels: int)
## A dino's Lien grew by `hearts` (the party bar shows "+1 ♥").
signal bond_changed(dino: Dino, hearts: int)
## The time of day moved to another phase (&"dawn", &"day", &"dusk", &"night").
signal phase_changed(phase: StringName)
## The weather changed (&"clear", &"rain", &"mist", &"storm", &"sandstorm").
signal weather_changed(weather: StringName)

## The three hatchlings Hélène left for Chloé: species -> default name. Each one beats
## the next (vent > nature > pierre > vent): Maïa takes the one strong against Chloé's.
const STARTERS := {&"velociraptor": "Vif", &"ankylosaurus": "Bastion", &"parasaurolophus": "Écho"}
const STARTER_LEVEL := 5
## Zone where a new game starts (region_id holds the current zone).
const START_REGION := &"port_ambre"
const PARTY_MAX := 5
## Chloé arrives with nothing: Roc gives the collars and berries the morning after.
const START_ITEMS := {}
## HP given back by a berry.
const BERRY_HP := 20
## Party members who did not fight get this share of a battle's experience.
const XP_SHARE := 0.6
## The Lien (Dino.bond): the hatchling of Hélène starts with a heart; bond points for a step
## walked in the lead (or carrying Chloé), a battle won where it fought, a berry, a fern.
const BOND_STARTER := 1
const BOND_STEP := 1
const BOND_WIN := 30
const BOND_BERRY := 20
const BOND_FERN := 40
## Game clock: minutes of the day (0–1440); one game hour lasts CLOCK_HOUR_S real seconds.
const CLOCK_HOUR_S := 60.0
const START_CLOCK := 9.0 * 60.0
## A sandstorm blows only where the zone says it can (Region.sandstorm_chance: the Désert),
## or when a scene sets it (set_weather(&"sandstorm")); leaving for a zone without, it stops.
const WEATHERS: Array[StringName] = [&"clear", &"rain", &"mist", &"storm", &"sandstorm"]
## Each game hour, a spell of rain or mist ends with this chance.
const WEATHER_CLEARS := 0.35

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
var clock := START_CLOCK
## Days since the start of the game (1 = the first); a new one begins at midnight.
var day := 1
## Things searched in the world (a tree shaken, a stone lifted): their id -> the day it was.
var searched: Dictionary = {}
## The moon is full every FULL_MOON_EVERY nights, the first one on the night of day
## FULL_MOON_FIRST: the amber of the island wakes up (see is_full_moon).
const FULL_MOON_EVERY := 4
const FULL_MOON_FIRST := 2
## An egg being carried until it hatches: {species, name, steps (left before hatching)}.
var egg: Dictionary = {}
## Typical level of the current zone (set by the world): behind it, dinos learn faster.
var zone_level := 0
## Old zone ids of the Plaines (before it became one open map) -> arrival point in it.
const OLD_ZONES := {"plaines_debarcadere": "Debarcadere", "plaines_sud": "Carrefour", "plaines_falaises": "Falaises", "plaines_crane": "Crane"}
## Where to arrive in the zone when there is no saved position (&"" = its start).
var arrival: StringName
## A game is loaded or started (a scene launched alone in the editor starts one).
var in_game := false
var weather: StringName = &"clear"
## Chances per game hour of rain, mist, a storm, a sandstorm starting, from the current zone
## (set by the world: set_climate).
var climate := {"rain": 0.08, "mist": 0.1}
## Debug: how fast the clock runs (1 = normal).
var time_scale := 1.0
## The map: what Chloé has seen of each zone. Zone id -> one byte per square of
## EXPLORE_CELL tiles, row by row (0 unseen … 255 seen; in between, the soft edge).
const EXPLORE_CELL := 2
var explored: Dictionary = {}
var _hour := -1

var _phase: StringName = &""


func _process(delta: float) -> void:
	play_time += delta
	var before := clock
	clock = fmod(clock + delta * time_scale * 60.0 / CLOCK_HOUR_S, 1440.0)
	if clock < before:
		day += 1
	var hour := int(clock / 60.0)
	if hour != _hour:
		if _hour >= 0:
			_roll_weather(hour)
		_hour = hour
	var now := phase()
	if now != _phase:
		_phase = now
		phase_changed.emit(now)


## Time passes until `hour` (resting by a fire, on a bench): the next time it is that hour.
func pass_time_until(hour: float) -> void:
	var target := hour * 60.0
	if target <= clock:
		day += 1
	clock = target


## The day the current night began on (-1 in the daytime): a night belongs to its evening.
func night_of() -> int:
	var h := clock / 60.0
	if h >= 20.5:
		return day
	if h < 5.0:
		return day - 1
	return -1


func is_full_moon() -> bool:
	var n := night_of()
	return n >= 0 and posmod(n - FULL_MOON_FIRST, FULL_MOON_EVERY) == 0


## Nights before the next full moon: 0 tonight (or now), 1 tomorrow night…
func nights_to_full_moon() -> int:
	var n := night_of()
	var tonight := n if n >= 0 else day
	return posmod(FULL_MOON_FIRST - tonight, FULL_MOON_EVERY)


## The amber tears Chloé still has: found, minus those sold at the Comptoir (Roc counts these).
func tears() -> int:
	return pebbles_found() - item_count("larmes_vendues")


func coins() -> int:
	return item_count("piece")


## Pays `amount` pièces if Chloé has them.
func pay(amount: int) -> bool:
	if coins() < amount:
		return false
	items["piece"] = coins() - amount
	return true


## Amber pebbles found in zone `zone` (flags "galet_<zone>_<n>"), or in the whole island.
func pebbles_found(zone := "") -> int:
	var prefix := "galet_%s_" % zone if zone != "" else "galet_"
	return flags.keys().filter(func(k: String) -> bool: return k.begins_with(prefix)).size()


## Part of the day: dawn 5h–7h, day 7h–18h, dusk 18h–20h30, night otherwise.
func phase() -> StringName:
	var h := clock / 60.0
	if h >= 5.0 and h < 7.0:
		return &"dawn"
	if h >= 7.0 and h < 18.0:
		return &"day"
	if h >= 18.0 and h < 20.5:
		return &"dusk"
	return &"night"


## Each new hour the weather may turn (mist is likelier at dawn).
func _roll_weather(hour: int) -> void:
	if weather != &"clear":
		if randf() < WEATHER_CLEARS or (weather == &"sandstorm" and float(climate.get("sandstorm", 0.0)) <= 0.0):
			set_weather(&"clear")
		return
	set_weather(weather_for(randf(), hour, climate))


## The weather a roll (0–1) brings at `hour` with `chances` (a zone's climate, see
## climate): the first spell whose share the roll falls into, else clear.
static func weather_for(roll: float, hour: int, chances: Dictionary) -> StringName:
	var mist: float = float(chances.get("mist", 0.0)) * (3.0 if hour >= 4 and hour <= 8 else 1.0)
	var edge := 0.0
	for spell: Array in [[&"mist", mist], [&"rain", float(chances.get("rain", 0.0))],
			[&"storm", float(chances.get("storm", 0.0))], [&"sandstorm", float(chances.get("sandstorm", 0.0))]]:
		if spell[1] <= 0.0:
			continue
		edge += spell[1]
		if roll < edge:
			return spell[0]
	return &"clear"


## The zone's chances of each weather (the world, entering a zone). A sandstorm stops at
## once where none can blow (out of the Désert, indoors).
func set_climate(chances: Dictionary) -> void:
	climate = chances
	if weather == &"sandstorm" and float(chances.get("sandstorm", 0.0)) <= 0.0:
		set_weather(&"clear")


## Rain falls (a shower or a storm).
func is_raining() -> bool:
	return weather == &"rain" or weather == &"storm"


func set_weather(value: StringName) -> void:
	if value == weather or not value in WEATHERS:
		return
	weather = value
	weather_changed.emit(value)


## Experience multiplier that lets a dino behind the zone's level catch up (and slows one ahead).
func catch_up(d: Dino) -> float:
	if zone_level <= 0:
		return 1.0
	return clampf(1.0 + (zone_level - d.level) * 0.25, 0.5, 3.0)


## Gives experience to one dino (with catch-up). Returns its gain_xp() events.
func award_xp(d: Dino, amount: int) -> Array:
	var gained := maxi(1, roundi(amount * catch_up(d)))
	var events := d.gain_xp(gained)
	xp_awarded.emit(d, gained, events.filter(func(e: Dictionary) -> bool: return e["type"] == "level").size())
	return events


## Experience for the whole party from exploring (a page, a new species, a cleared obstacle…).
func award_team_xp(amount: int) -> void:
	for d in party:
		award_xp(d, amount)


## Makes the dino at `index` the lead (it follows Chloé and fights first).
func set_lead(index: int) -> void:
	if index <= 0 or index >= party.size():
		return
	var d: Dino = party[index]
	party.remove_at(index)
	party.insert(0, d)
	party_changed.emit()


## Feeds a berry to `d`. Returns false when there is none or it is already healthy.
func feed_berry(d: Dino) -> bool:
	if d.hp >= d.max_hp() or not use_item("baie"):
		return false
	d.hp = mini(d.max_hp(), d.hp + BERRY_HP)
	party_changed.emit()
	grow_bond(d, BOND_BERRY)   # cared for: the Lien grows a little
	return true


## Mémé Pervenche's fern: a dino fully healed. Returns the PV it got back (0: nothing done).
func feed_fern(d: Dino) -> int:
	var missing := d.max_hp() - d.hp
	if missing <= 0 or not use_item("fougere"):
		return 0
	d.hp = d.max_hp()
	party_changed.emit()
	grow_bond(d, BOND_FERN)
	return missing


## A story moment brings Chloé and `d` closer: whole hearts of Lien (Dino.bond, at most
## Dino.MAX_BOND). Returns the hearts gained; the party bar shows them ("+1 ♥").
func add_bond(d: Dino, hearts := 1) -> int:
	if d == null:
		return 0
	var gained: int = d.add_hearts(hearts)
	if gained > 0:
		bond_changed.emit(d, gained)
	return gained


## Bond points for `d` (a step together, a battle won, some care): a heart every so often
## (see Dino.gain_bond_points). Returns the hearts gained.
func grow_bond(d: Dino, points: int) -> int:
	if d == null:
		return 0
	var gained: int = d.gain_bond_points(points)
	if gained > 0:
		bond_changed.emit(d, gained)
	return gained


## Chloé's own hatchling, the egg of Hélène she chose (in the party, else in the box), or
## null. For the scenes that bring them closer: Game.add_bond(Game.starter_dino()).
func starter_dino() -> Dino:
	var species = flag(&"starter")
	if not species is String:
		return null
	for d in party + box:
		if String(d.species().id) == species:
			return d
	return null


func new_game() -> void:
	region_id = START_REGION
	player_position = Vector2.ZERO
	has_position = false
	flags = {}
	dex_seen = {}
	dex_caught = {}
	explored = {}
	searched = {}
	egg = {}
	day = 1
	play_time = 0.0
	clock = START_CLOCK
	weather = &"clear"
	party = []
	box = []
	items = START_ITEMS.duplicate()
	in_game = true
	party_changed.emit()


## Chloé takes one of the three hatchlings (the prologue; or directly, for tests).
func give_starter(species: StringName) -> Dino:
	var d := Dino.create(species, STARTER_LEVEL, STARTERS.get(species, ""))
	d.bond = BOND_STARTER   # hatched for Chloé: already a heart
	party.insert(0, d)
	mark_caught(species)
	flags["starter"] = String(species)
	var others := STARTERS.keys().filter(func(k: StringName) -> bool: return k != species)
	# Maïa gets the one that beats Chloé's; the Ombre Noire steals the last one.
	var maia: StringName = others[0] if MovesDB.effectiveness(MovesDB.FAMILY_TYPES[SpeciesDB.get_species(others[0]).family], d.type()) > 1.0 else others[1]
	flags["maia_starter"] = String(maia)
	flags["stolen_starter"] = String(others[1] if maia == others[0] else others[0])
	party_changed.emit()
	return d


func item_count(id: String) -> int:
	return items.get(id, 0)


func use_item(id: String) -> bool:
	if item_count(id) <= 0:
		return false
	items[id] -= 1
	return true


func give_item(id: String, amount := 1) -> void:
	items[id] = item_count(id) + amount


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
		if Abilities.usable(d, ability):
			return d
	return null


## Chloé sees the ground within `radius` tiles of `tile` in zone `id` (`size` tiles).
func explore(id: StringName, size: Vector2i, tile: Vector2, radius: float) -> void:
	var cells := explore_cells(size)
	var seen := explored_mask(id, size)
	var c := tile / EXPLORE_CELL
	var r := radius / EXPLORE_CELL
	for y in range(maxi(0, floori(c.y - r - 1.0)), mini(cells.y, ceili(c.y + r + 1.0))):
		for x in range(maxi(0, floori(c.x - r - 1.0)), mini(cells.x, ceili(c.x + r + 1.0))):
			var v := int(clampf(r + 0.5 - Vector2(x + 0.5, y + 0.5).distance_to(c), 0.0, 1.0) * 255.0)
			var i := y * cells.x + x
			if v > seen[i]:
				seen[i] = v
	explored[String(id)] = seen


## What Chloé has seen of zone `id` (`size` tiles; see `explored`): nothing at first.
func explored_mask(id: StringName, size: Vector2i) -> PackedByteArray:
	var cells := explore_cells(size)
	var seen: PackedByteArray = explored.get(String(id), PackedByteArray())
	if seen.size() != cells.x * cells.y:   # a zone not visited yet, or its map changed size
		seen = PackedByteArray()
		seen.resize(cells.x * cells.y)
		seen.fill(0)
	return seen


@warning_ignore("integer_division")   # whole cells, rounded up
func explore_cells(size: Vector2i) -> Vector2i:
	return (size + Vector2i.ONE * (EXPLORE_CELL - 1)) / EXPLORE_CELL


func to_dict() -> Dictionary:
	var seen := {}
	for id: String in explored:
		seen[id] = Marshalls.raw_to_base64(explored[id])
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
		"explored": seen,
		"play_time": play_time,
		"clock": clock,
		"day": day,
		"searched": searched,
		"egg": egg,
		"weather": String(weather),
	}


func from_dict(data: Dictionary) -> void:
	in_game = true
	region_id = StringName(data.get("region", START_REGION))
	var pos: Array = data.get("position", [0, 0])
	player_position = Vector2(pos[0], pos[1])
	has_position = data.get("has_position", false)
	# The Plaines used to be small separate zones: now one region, arriving near the old spot.
	if OLD_ZONES.has(String(region_id)):
		arrival = StringName(OLD_ZONES[String(region_id)])
		region_id = &"plaines"
		has_position = false
	party.clear()
	for d in data.get("party", []):
		var dino := Dino.from_dict(d)
		if dino:
			party.append(dino)
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
	explored = {}
	var seen: Dictionary = data.get("explored", {})
	for id in seen:
		explored[String(id)] = Marshalls.base64_to_raw(String(seen[id]))
	play_time = data.get("play_time", 0.0)
	clock = fmod(float(data.get("clock", START_CLOCK)), 1440.0)
	day = int(data.get("day", 1))
	searched = data.get("searched", {})
	egg = data.get("egg", {})
	weather = StringName(data.get("weather", "clear"))
	if not weather in WEATHERS:
		weather = &"clear"
	weather_changed.emit(weather)
	# Saves from before the prologue existed: their dino was Vif, and they were past the port.
	if not party.is_empty() and not flags.has("starter"):
		flags["starter"] = "velociraptor"
		flags["prologue_done"] = true
	party_changed.emit()
