class_name DinoBrain
extends RefCounted
## What a wild dino does, moment to moment (docs/migration-3d.md, phase 3): it rests, ambles about
## its home, notices Chloé and watches her, runs off when she comes too close (sooner if she runs
## at it), and calms down once she is far. A small state machine, one method per state; the
## species' temperament and distances (Species3D) tune it. States to add later the same way:
## graze, drink, sleep, herd, hunt, follow (a companion), fight back (a territorial one).

enum State { IDLE, WANDER, ALERT, FLEE }

const IDLE_S := Vector2(2.0, 5.0)       # rests this long (s, at random)
const WATCH_BORED_S := 7.0              # a curious one stops watching a Chloé who stays still
const CALM_AFTER_S := 2.5               # runs at least this long once scared
const RUNNING := 1.0                    # Chloé faster than this × Player3D.SPEED (a jog): she runs at it
const FLEE_SPREAD_DEG := 35.0
const CORNERED_TURNS_DEG: Array[float] = [60.0, -60.0, 110.0, -110.0, 180.0]
const STATE_NAMES := {State.IDLE: &"idle", State.WANDER: &"wander", State.ALERT: &"alert", State.FLEE: &"flee"}

var body: Dinosaur3D
var state := State.IDLE

var _timer := 0.0
var _rng := RandomNumberGenerator.new()


func _init(owner_body: Dinosaur3D) -> void:
	body = owner_body
	_rng.randomize()
	_enter(State.IDLE)


func state_name() -> StringName:
	return STATE_NAMES[state]


func update(delta: float) -> void:
	_timer -= delta
	var chloe := body.get_tree().get_first_node_in_group(&"player3d") as CharacterBody3D
	var d := INF
	var running := false
	if chloe:
		d = (chloe.global_position - body.global_position).slide(Vector3.UP).length()
		running = Vector2(chloe.velocity.x, chloe.velocity.z).length() > Player3D.SPEED * RUNNING
	if state != State.FLEE and _scared(d, running):
		_enter(State.FLEE, chloe)
		return
	match state:
		State.IDLE:
			if _notices(d):
				_enter(State.ALERT, chloe)
			elif _timer <= 0.0:
				_enter(State.WANDER)
		State.WANDER:
			if _notices(d):
				_enter(State.ALERT, chloe)
			elif body.arrived():
				_enter(State.IDLE)
		State.ALERT:
			body.look_toward(chloe.global_position if chloe else body.global_position)
			if d > body.species.perception_m * 1.2 or _timer <= 0.0:
				_enter(State.IDLE)
		State.FLEE:
			if body.arrived():
				if _timer <= 0.0 and d > body.species.perception_m * 1.3:
					_enter(State.IDLE)
				else:
					_run_from(chloe)


## Chloé is close enough to make it run: how close depends on its temperament.
func _scared(d: float, running: bool) -> bool:
	var flee := body.species.flee_m
	match body.species.temperament:
		&"calm":
			return d < flee * 0.4
		&"curious":
			return d < flee * 0.6 or (running and d < flee)
		_:
			return d < flee or (running and d < body.species.perception_m * 0.8)


func _notices(d: float) -> bool:
	return body.species.temperament != &"calm" and d < body.species.perception_m


func _enter(next: State, chloe: Node3D = null) -> void:
	state = next
	match next:
		State.IDLE:
			body.stop()
			_timer = _rng.randf_range(IDLE_S.x, IDLE_S.y)
		State.WANDER:
			var angle := _rng.randf() * TAU
			var reach := _rng.randf_range(0.3, 1.0) * body.species.roam_m
			body.go_to(body.home + Vector3(cos(angle), 0.0, sin(angle)) * reach, body.walk_speed())
		State.ALERT:
			body.stop()
			_timer = WATCH_BORED_S if body.species.temperament == &"curious" else INF
		State.FLEE:
			_timer = CALM_AFTER_S
			_run_from(chloe)
	body.state_changed.emit(STATE_NAMES[next])


## Runs off away from Chloé (a little to one side, at random), as far as it notices her, to ground
## it can walk; cornered (a cliff, the edge of the zone), it breaks off sideways, else back past her.
func _run_from(chloe: Node3D) -> void:
	var away := Vector3.FORWARD
	if chloe:
		away = (body.global_position - chloe.global_position).slide(Vector3.UP)
		away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	away = away.rotated(Vector3.UP, deg_to_rad(_rng.randf_range(-FLEE_SPREAD_DEG, FLEE_SPREAD_DEG)))
	var reach := body.species.perception_m
	var target := body.walkable_point(body.global_position + away * reach)
	for turn_deg in CORNERED_TURNS_DEG:
		if (target - body.global_position).length() >= reach * 0.5:
			break
		target = body.walkable_point(body.global_position + away.rotated(Vector3.UP, deg_to_rad(turn_deg)) * reach)
	body.go_to(target, body.run_speed())
