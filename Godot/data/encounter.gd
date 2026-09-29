class_name Encounter
extends Resource
## One species living in a habitat (see world/habitat.gd): when, at which levels, how often,
## in which weather, and how it is met — roaming in sight, or hidden in the tall grass.

@export var species: StringName = &"protoceratops"
@export var levels := Vector2i(2, 4)
## Relative chance against the habitat's other encounters.
@export var weight := 10
## Part of the day when it comes out.
@export_enum("toujours", "jour", "nuit", "aube et crépuscule", "jour et crépuscule", "pleine lune") var when := 0
## true: met in the tall grass (random encounter); false: roams in sight in the habitat.
@export var hidden := true
## Weathers it comes out in (Game.WEATHERS: &"snow", &"blizzard"…); empty: any weather.
@export var weathers: Array[StringName] = []

const PHASES := [
	[&"dawn", &"day", &"dusk", &"night"],
	[&"day"],
	[&"night"],
	[&"dawn", &"dusk"],
	[&"day", &"dusk"],
	[&"night"],   # full-moon nights only (see active)
]
## « pleine lune »: out only on the nights the moon is full (Game.is_full_moon).
const FULL_MOON := 5


func active(phase: StringName) -> bool:
	if when == FULL_MOON and not Game.is_full_moon():
		return false
	if not weathers.is_empty() and not Game.weather in weathers:
		return false
	return phase in PHASES[when]


func roll_level() -> int:
	return randi_range(levels.x, levels.y)
