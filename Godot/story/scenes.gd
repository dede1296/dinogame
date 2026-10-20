class_name Scenes
## Une scène à la fois (docs/mecaniques.md « Une scène à la fois ») : the one lock every scene of the
## story holds while it plays — a scene started by Chloé (talking to someone, picking something up,
## a sign: Player._interact_with → interact), a story scene (Story.run, and the scenes it chains, played
## inside it), an automatic one (entering a zone, the time of day: Story.on_zone_entered/on_phase_changed).
## - While one plays, a press of « interact » (or a click) is ignored (interact returns false), and Chloé
##   cannot move (Player.can_move).
## - An automatic scene asked meanwhile waits in a queue (request) and plays when the lock is free,
##   its handler checking its conditions then (flags, the hour, the zone): never lost, never played
##   twice (the same key waits once; a zone's scene is dropped when Chloé has left that zone: entering
##   it again asks again).
## - When the last scene ends (finish), Chloé gets her controls back if a scene took them and did not
##   give them back (Story.lock), and the camera comes back to her — even when the scene left early, or
##   when the character it was started from has been freed meanwhile (_until_done).
## - reset(): « Se débloquer » (story/unstick.gd) forgets the scenes playing and waiting.

## The scenes let go by reset() still have this long to end (their lines skipped meanwhile).
const SKIP_MAX_S := 4.0

## Scenes holding the lock now: the one playing and those played inside it. 0: nothing plays.
static var depth := 0
## The automatic scenes waiting for their turn: {"key", "zone", "play"} (see request).
static var _queue: Array[Dictionary] = []
## Bumped by reset(): what started before it is forgotten.
static var _epoch := 0
## Scenes started before the last reset() and not over yet, and until when they are waited for (ms).
static var _stale := 0
static var _stale_until_ms := 0
## A scene took Chloé's controls (Story.lock(true)) and has not given them back yet.
static var _player_locked := false
static var _draining := false


## Something plays (or the scenes let go by reset() are ending): no other scene starts.
static func busy() -> bool:
	return depth > 0 or stale_alive()


## A scene starts: its token, for finish().
static func begin() -> int:
	if depth == 0:
		_cancel_errand()
	depth += 1
	return _epoch


## The scene of `token` is over. The last one: Chloé is given back to the player, then the next scene
## waiting plays (at once: no frame where nothing holds the lock while one waits).
static func finish(token: int) -> void:
	if token != _epoch:   # (a scene from before a reset)
		_stale = maxi(_stale - 1, 0)
		return
	depth = maxi(depth - 1, 0)
	if depth == 0:
		_released()


## True when `token` was given since the last reset (its scene still counts).
static func is_current(token: int) -> bool:
	return token == _epoch


## An automatic scene (`key`: what it is, e.g. "zone:havre_dore"; `zone`: the zone it belongs to, &""
## for any): `play` (a coroutine that begins/finishes itself, e.g. Story._zone_scene) is called now if
## nothing plays, else when the lock is free. Once in the queue, the same key is not added again.
static func request(key: String, zone: StringName, play: Callable) -> void:
	for q: Dictionary in _queue:
		if q["key"] == key:
			return
	_queue.append({"key": key, "zone": zone, "play": play})
	if not busy() and not _draining:
		_drain()


## How many automatic scenes wait (the tests).
static func waiting() -> int:
	return _queue.size()


## Story.lock: whether a scene holds Chloé's controls now.
static func note_lock(on: bool) -> void:
	_player_locked = on


static func holds_player() -> bool:
	return _player_locked


# ------------------------------------------------------------------ an interaction

## Chloé uses `target` (a press of « interact », a click): nothing while a scene plays (false). Else the
## interaction holds the lock until it is over (automatic scenes wait for it), Chloé held meanwhile.
static func interact(target: Node, player: Node) -> bool:
	if busy() or Dialogue.active or not is_instance_valid(target):
		return false
	var token := begin()
	player.set(&"busy", true)
	player.set(&"velocity", Vector2.ZERO)
	await _until_done(target, player)
	if is_instance_valid(player) and is_current(token):
		player.set(&"busy", false)
	finish(token)
	return true


## Waits for `target.interact(player)` to end; or, when the target is freed meanwhile (a scene sent
## that character away: its own method can never go on), for the scene it started to be over.
static func _until_done(target: Node, player: Node) -> void:
	var done := {"v": false}
	_drive(target, player, done)
	var level := depth
	var epoch := _epoch
	var tree := Engine.get_main_loop() as SceneTree
	while not done["v"] and epoch == _epoch:
		if not is_instance_valid(target) and depth <= level and not Dialogue.active:
			return
		await tree.process_frame


static func _drive(target: Node, player: Node, done: Dictionary) -> void:
	await target.interact(player)
	done["v"] = true


# ------------------------------------------------------------------ the lock given back

static func _released() -> void:
	if _player_locked:   # (a scene that ended without giving Chloé back: early return, a freed node)
		Story.lock(false)
	_camera_back()
	if not _draining:
		_drain()


## The scenes waiting, one after the other, as long as nothing plays: each starts at once (and holds
## the lock from its first line); one of a zone Chloé has left is dropped.
static func _drain() -> void:
	_draining = true
	while not busy() and not _queue.is_empty():
		var q: Dictionary = _queue.pop_front()
		var zone: StringName = q["zone"]
		if zone != &"" and zone != Game.region_id:
			continue
		(q["play"] as Callable).call()
	_draining = false


## The camera back on Chloé (Stage.look_at, a close-up a scene left on).
static func _camera_back() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var view: Node = tree.get_first_node_in_group(&"world_view") if tree else null
	if view:
		view.set("focus_px", Vector2.INF)
		view.set("close_up", 0.0)


## A click's errand (Chloé walking to something to use it) ends when a scene starts.
static func _cancel_errand() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var player: Node = tree.get_first_node_in_group(&"player") if tree else null
	if player and player.has_method(&"cancel_goal"):
		player.call(&"cancel_goal")


# ------------------------------------------------------------------ Se débloquer

## Forgets the scenes playing (they still have SKIP_MAX_S to end, their lines skipped: see Unstick) and
## those waiting; nobody holds Chloé any more. Story.playing back to 0.
static func reset() -> void:
	_stale += depth
	_stale_until_ms = Time.get_ticks_msec() + int(SKIP_MAX_S * 1000.0)
	depth = 0
	_epoch += 1
	_queue.clear()
	_player_locked = false
	_draining = false
	Story.playing = 0


## Scenes let go by reset() are still ending (and SKIP_MAX_S has not gone by).
static func stale_alive() -> bool:
	return _stale > 0 and Time.get_ticks_msec() < _stale_until_ms


## No more waiting for the scenes let go: the queue may play.
static func forget_stale() -> void:
	_stale = 0
	if not busy() and not _draining:
		_drain()
