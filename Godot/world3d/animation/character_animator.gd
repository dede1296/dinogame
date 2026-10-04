class_name CharacterAnimator
extends Node
## Plays a model's animations from what its body does (docs/migration-3d.md): standing, and the
## gait nearest its ground speed (walk, run, sprint) played faster or slower so the feet do not
## slide; jumping (start → in the air → landing, the landing skipped when it comes down running);
## falling off a ledge; and one-off actions (interact, pickup, eat…) over the rest. Generic:
## Chloé, the people and the dinos only differ by their AnimSet.
## Built in code: AnimationTree ─ output ← action (OneShot: pace ← sm, act) ; sm = state machine
## move (BlendSpace1D: idle 0, walk 1, run 2, sprint 3) · jump_start · air · land.

## Off the floor this long before it counts as falling (going down a step is not falling).
const AIR_DELAY := 0.12
## Coming down faster than this along the ground (m/s): straight back to moving, no landing.
const LAND_MOVING := 1.2
## Below this share of the walk clip's speed, standing and walking are blended.
const WALK_IN := 0.6
## Past the speed halfway (geometric mean) between two gaits, the faster one takes over within
## this share of that speed.
const GAIT_BAND := 0.15
const POSE_BLEND := 0.45   # into and out of a held move (lying down to sleep, head down to eat)
const PACE_MIN := 0.6
const PACE_MAX := 2.0
const MOVES: Array[StringName] = [&"idle", &"walk", &"run", &"sprint", &"jump_start", &"jump_air", &"jump_land", &"fall"]

@export var body: CharacterBody3D
## The model (an imported scene) with an AnimationPlayer somewhere inside.
@export var model: Node3D
@export var anim_set: AnimSet
## The model's size against the one its AnimSet's clip speeds were measured at (a young dino at
## half its adult size: 0.5, its feet go half as far per step).
@export var size_factor := 1.0

var tree: AnimationTree

var _player: AnimationPlayer
var _playback: AnimationNodeStateMachinePlayback
var _clips := {}                       # move → clip name, after the fallbacks
var _gait_speeds: Array[float] = []    # 0 (idle), then the natural speed of each gait in the blend
var _top_step := 0.0                   # stride mode: the longest step in the blend (m)
var _pose_node: AnimationNodeAnimation  # the looping move held (hold): eat, sleep…
var _air_time := 0.0


func _ready() -> void:
	if anim_set == null:
		anim_set = AnimSet.new()
	_player = model.find_children("*", "AnimationPlayer", true, false).front() if model else null
	if _player == null:
		push_warning("CharacterAnimator : pas d'AnimationPlayer dans %s" % [model])
		set_physics_process(false)
		return
	for move in MOVES:
		_clips[move] = anim_set.clip_for(_player, move)
	for move in AnimSet.LOOPING:
		var clip := anim_set.clip_for(_player, move)
		if clip != &"":
			_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_build_tree()


## Has a clip for this move (after the fallbacks)?
func has_move(move: StringName) -> bool:
	return _clip(move) != &""


## The state it is in: move, jump_start, air or land.
func state() -> StringName:
	return _playback.get_current_node() if _playback else &""


## The body just left the ground on a jump.
func jump() -> void:
	if _playback == null:
		return
	_air_time = AIR_DELAY
	_playback.travel(&"jump_start" if _clips[&"jump_start"] != &"" else &"air")


## Holds a looping move (eat, sleep, sit…) instead of standing and walking, until release(). Returns
## false if it has no such clip.
func hold(move: StringName) -> bool:
	var clip := _clip(move)
	if clip == &"" or _playback == null:
		return false
	_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	(_pose_node as AnimationNodeAnimation).animation = clip
	_playback.travel(&"pose")
	return true


## Back to standing and walking after hold().
func release() -> void:
	if _playback and _playback.get_current_node() == &"pose":
		_playback.travel(&"move")


func holding() -> bool:
	return _playback != null and _playback.get_current_node() == &"pose"


## Plays a one-off move over the rest (interact, wave…). Returns its length (s), 0 if none.
func act(move: StringName) -> float:
	var clip := _clip(move)
	if clip == &"" or tree == null:
		return 0.0
	(tree.tree_root.get_node(&"act") as AnimationNodeAnimation).animation = clip
	tree.set(&"parameters/action/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	return _player.get_animation(clip).length


func _clip(move: StringName) -> StringName:
	if _clips.has(move):
		return _clips[move]
	return anim_set.clip_for(_player, move) if _player else &""


func _physics_process(delta: float) -> void:
	if _playback == null:
		return
	var speed := Vector2(body.velocity.x, body.velocity.z).length()
	var on_floor := body.is_on_floor()
	_air_time = 0.0 if on_floor else _air_time + delta
	var current := _playback.get_current_node()
	if on_floor and (current == &"air" or current == &"jump_start"):
		var land: bool = _clips[&"jump_land"] != &"" and speed < LAND_MOVING
		_playback.travel(&"land" if land else &"move")
	elif _air_time >= AIR_DELAY and current == &"move":
		_playback.travel(&"air")
	var gait := _gait(speed)
	tree.set(&"parameters/sm/move/blend_position", gait.x)
	tree.set(&"parameters/pace/scale", gait.y if current == &"move" else 1.0)


## Where in the blend and how fast to play it, for a ground speed. Stride mode: the blend is by step
## length (speed / cadence), the gaits stretched to a 1 s cycle played `cadence / 2` cycles a second.
## Else: 0 idle, 1 walk, 2 run, 3 sprint, the nearest gait sped up or slowed to the speed.
func _gait(speed: float) -> Vector2:
	if anim_set.uses_strides():
		if speed < 0.01:
			return Vector2(0.0, 1.0)
		var steps := anim_set.cadence_at(speed / size_factor)
		return Vector2(minf(speed / steps, _top_step), steps / 2.0)
	var n := _gait_speeds.size()
	if n < 2 or speed < 0.01:
		return Vector2(0.0, 1.0)
	var walk := _gait_speeds[1]
	if speed < walk * WALK_IN:
		return Vector2(speed / (walk * WALK_IN), 1.0)
	var i := 1
	while i + 1 < n and speed > sqrt(_gait_speeds[i] * _gait_speeds[i + 1]):
		i += 1
	var pace := clampf(speed / _gait_speeds[i], PACE_MIN, PACE_MAX)
	if i > 1:
		var switch := sqrt(_gait_speeds[i - 1] * _gait_speeds[i])
		var into := (speed / switch - 1.0) / GAIT_BAND
		if into < 1.0:   # just past the switch: the slower gait fades out
			var slower := clampf(speed / _gait_speeds[i - 1], PACE_MIN, PACE_MAX)
			return Vector2(i - 1 + into, lerpf(slower, pace, into))
	return Vector2(float(i), pace)


func _build_tree() -> void:
	var sm := AnimationNodeStateMachine.new()
	var move := _strides_blend() if anim_set.uses_strides() else _speeds_blend()
	sm.add_node(&"move", move)
	sm.add_node(&"air", _anim(&"jump_air" if _clips[&"jump_air"] != &"" else &"idle"))
	sm.add_transition(&"Start", &"move", _go(0.0, true))
	sm.add_transition(&"move", &"air", _go(0.2))
	sm.add_transition(&"air", &"move", _go(0.12))
	_pose_node = _anim(&"idle")   # (its clip is set by hold())
	sm.add_node(&"pose", _pose_node)
	sm.add_transition(&"move", &"pose", _go(POSE_BLEND))
	sm.add_transition(&"pose", &"move", _go(POSE_BLEND))
	sm.add_transition(&"pose", &"air", _go(0.15))
	if _clips[&"jump_start"] != &"":
		sm.add_node(&"jump_start", _anim(&"jump_start"))
		sm.add_transition(&"move", &"jump_start", _go(0.08))
		sm.add_transition(&"jump_start", &"air", _go(0.15, true, true))
		sm.add_transition(&"jump_start", &"move", _go(0.12))
	if _clips[&"jump_land"] != &"":
		sm.add_node(&"land", _anim(&"jump_land"))
		sm.add_transition(&"air", &"land", _go(0.05))
		sm.add_transition(&"land", &"move", _go(anim_set.blend, true, true))
		sm.add_transition(&"land", &"air", _go(0.1))
		if _clips[&"jump_start"] != &"":
			sm.add_transition(&"jump_start", &"land", _go(0.05))
	var root := AnimationNodeBlendTree.new()
	root.add_node(&"sm", sm)
	root.add_node(&"pace", AnimationNodeTimeScale.new())
	root.add_node(&"act", AnimationNodeAnimation.new())
	var shot := AnimationNodeOneShot.new()
	shot.fadein_time = anim_set.blend
	shot.fadeout_time = anim_set.blend
	root.add_node(&"action", shot)
	root.connect_node(&"pace", 0, &"sm")
	root.connect_node(&"action", 0, &"pace")
	root.connect_node(&"action", 1, &"act")
	root.connect_node(&"output", 0, &"action")
	tree = AnimationTree.new()
	tree.name = "AnimationTree"
	tree.tree_root = root
	_player.add_sibling(tree)
	tree.anim_player = tree.get_path_to(_player)
	tree.active = true
	_playback = tree.get(&"parameters/sm/playback")


## Gaits by speed: idle 0, walk 1, run 2, sprint 3 (the gaits the model has, slowest first).
func _speeds_blend() -> AnimationNodeBlendSpace1D:
	var move := AnimationNodeBlendSpace1D.new()
	move.add_blend_point(_anim(&"idle"), 0.0, -1, &"idle")
	_gait_speeds = [0.0]
	var gaits := [[&"walk", anim_set.walk_clip_speed], [&"run", anim_set.run_clip_speed], [&"sprint", anim_set.sprint_clip_speed]]
	var previous: StringName = _clips[&"idle"]
	for g: Array in gaits:
		var clip: StringName = _clips[g[0]]
		if clip == &"" or clip == previous or float(g[1]) <= 0.0:
			break
		move.add_blend_point(_anim(g[0]), float(_gait_speeds.size()), -1, g[0])
		_gait_speeds.append(float(g[1]) * size_factor)
		previous = clip
	move.max_space = maxf(_gait_speeds.size() - 1, 1.0)
	return move


## Gaits by step length (m): idle 0, then each gait at its own step; all stretched to a 1 s cycle,
## lined up on the left foot, played in step (sync) so that blending them shortens or lengthens the
## stride without the legs crossing.
func _strides_blend() -> AnimationNodeBlendSpace1D:
	var move := AnimationNodeBlendSpace1D.new()
	move.sync = true
	move.add_blend_point(_anim(&"idle"), 0.0, -1, &"idle")
	_top_step = 0.0
	for g: StringName in [&"walk", &"run", &"sprint"]:
		var step: float = anim_set.gait_steps.get(g, 0.0) * size_factor
		if _clips[g] == &"" or step <= _top_step:
			continue
		var node := _anim(g)
		node.use_custom_timeline = true
		node.timeline_length = 1.0
		node.stretch_time_scale = true
		node.start_offset = anim_set.gait_left_down.get(g, 0.0)
		node.loop_mode = Animation.LOOP_LINEAR
		move.add_blend_point(node, step, -1, g)
		_top_step = step
	move.max_space = maxf(_top_step, 0.1)
	return move


## The node playing a move's clip, trimmed if its AnimSet says so.
func _anim(move: StringName) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = _clips.get(move, move)
	if anim_set.trims.has(move):
		var trim: Vector2 = anim_set.trims[move]
		var length := _player.get_animation(node.animation).length
		var end := trim.y if trim.y > 0.0 else length
		node.use_custom_timeline = true
		node.start_offset = trim.x
		node.timeline_length = maxf(end - trim.x, 0.05)
		node.stretch_time_scale = false
		node.loop_mode = Animation.LOOP_NONE
	return node


## A transition: cross-fade `xfade` s; `auto` follows it by itself; `at_end` once the clip is over.
func _go(xfade: float, auto := false, at_end := false) -> AnimationNodeStateMachineTransition:
	var t := AnimationNodeStateMachineTransition.new()
	t.xfade_time = xfade
	if auto:
		t.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	if at_end:
		t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	return t
