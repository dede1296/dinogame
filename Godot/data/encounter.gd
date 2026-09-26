class_name Encounter
extends Resource
## One species living in a habitat (see world/habitat.gd): when, at which levels, how often,
## and how it is met — roaming in sight, or hidden in the tall grass.

@export var species: StringName = &"protoceratops"
@export var levels := Vector2i(2, 4)
## Relative chance against the habitat's other encounters.
@export var weight := 10
## Part of the day when it comes out.
@export_enum("toujours", "jour", "nuit", "aube et crépuscule", "jour et crépuscule") var when := 0
## true: met in the tall grass (random encounter); false: roams in sight in the habitat.
@export var hidden := true

const PHASES := [
	[&"dawn", &"day", &"dusk", &"night"],
	[&"day"],
	[&"night"],
	[&"dawn", &"dusk"],
	[&"day", &"dusk"],
]


func active(phase: StringName) -> bool:
	return phase in PHASES[when]


func roll_level() -> int:
	return randi_range(levels.x, levels.y)
