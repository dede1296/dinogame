class_name AnimSet
extends Resource
## Which clip of a model plays each generic move, and how fast the feet go in its walk, run and
## sprint clips. With it the same CharacterAnimator drives Chloé, the people and every dino
## species (docs/migration-3d.md §4): a new model only needs a new AnimSet, no code.
## Generic moves: idle, walk, run, sprint, jump_start, jump_air, jump_land, fall, and any one-off
## action (interact, pickup, wave, sit, eat, attack, roar…).

## Loop by themselves (glTF does not say which clips loop).
const LOOPING: Array[StringName] = [
	&"idle", &"walk", &"run", &"sprint", &"jump_air", &"fall", &"swim", &"swim_idle", &"sleep", &"eat",
	&"crouch", &"crouch_walk", &"sit", &"push", &"talk",
]
## A move whose clip is missing plays this one instead ("" = left out).
const FALLBACKS := {
	&"sprint": &"run", &"run": &"walk", &"walk": &"idle", &"jump_air": &"fall", &"fall": &"jump_air",
}

## Generic move → clip name in the model's AnimationPlayer. A move not listed is looked for under
## its own name (a model whose clips are already called idle, walk… needs no list).
@export var clips: Dictionary[StringName, StringName] = {}
## Ground speed of the feet in the walk, run and sprint clips played at 1× (m/s, at the model's
## scale; 0 = no such clip). The animator picks the gait nearest the body's speed and plays it
## faster or slower, so the feet never slide.
@export var walk_clip_speed := 1.4
@export var run_clip_speed := 3.6
@export var sprint_clip_speed := 0.0
@export_group("Strides")
## Stride mode (for people, whose steps must look grounded): steps per second at a ground speed
## (m/s → steps/s, from slow to fast). The step length follows (speed / cadence); the gait clips,
## all stretched to the same cycle and lined up on the same foot, are blended by step length.
## Empty: no stride mode, the gaits are picked by speed alone (walk_clip_speed…).
@export var cadence := PackedVector2Array()
## Step length (m) of each gait clip (walk, run, sprint) at the model's adult size, and when its
## left foot is set down (s into the clip) — measured once on the clips.
@export var gait_steps: Dictionary[StringName, float] = {}
@export var gait_left_down: Dictionary[StringName, float] = {}
@export_group("")

## Part of a clip only (s): move → Vector2(start, end), end 0 = to the clip's end. For a clip
## with a long wind-up or a long still ending (a landing that stands still for half a second).
@export var trims: Dictionary[StringName, Vector2] = {}
## Cross-fade between moves (s).
@export var blend := 0.15


func uses_strides() -> bool:
	return cadence.size() >= 2 and not gait_steps.is_empty()


## Steps per second at `speed` (m/s), along `cadence` (held at its ends).
func cadence_at(speed: float) -> float:
	if speed <= cadence[0].x:
		return cadence[0].y
	for i in range(1, cadence.size()):
		if speed <= cadence[i].x:
			return lerpf(cadence[i - 1].y, cadence[i].y, inverse_lerp(cadence[i - 1].x, cadence[i].x, speed))
	return cadence[cadence.size() - 1].y


## The clip for a move in this player, after the fallbacks; "" if none.
func clip_for(player: AnimationPlayer, move: StringName) -> StringName:
	var tried := {}
	var key := move
	while key != &"" and not tried.has(key):
		tried[key] = true
		var clip: StringName = clips.get(key, key)
		if player.has_animation(clip):
			return clip
		key = FALLBACKS.get(key, &"")
	return &""
