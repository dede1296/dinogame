class_name Wildlife3D
extends Node3D
## The little life of a 3D zone, as the 2.5D has it (WildlifeDB, by the zone's Region.ambience_id;
## world/view3d/wildlife.gd): butterflies over the Prairie, swarms of mosquitoes, dragonflies and
## falling leaves in the woods, frogs by the marsh's water, lizards and scorpions on the desert's
## sand, fireflies at night… The same kinds, as many for the same ground (DENSITY: the 3D sees a wider
## ring round Chloé than the 2.5D's view), the same ways of going (WildlifeDB motion: flutter, dart,
## swarm, walk, hop, leap, fall, drift, swim, circle, soar). Each keeps to its ground as the zone is
## drawn (its painting, its water: ZoneTerrain), on the ground there (ZoneTerrain.height_at); those on
## foot never on a path nor in the water, nor up a cliff; out by day or at night, sheltering from the
## rain; the walkers run off when Chloé comes near, the mosquitoes come round her head.
## Drawn in batches (wildlife_3d_looks.gd: one MultiMesh per kind, the 2.5D's pictures), particles for
## the lights; its ground read by wildlife_3d_ground.gd. It lives in a ring round Chloé, a little ahead
## of her (where the camera looks): an animal left behind comes back near her, growing out of nothing
## (none pops up).
##   Wildlife3D.make(zone, source, terrain)   # (after the terrain: a child « Wildlife » of the zone)

const DB := preload("res://data/wildlife_db.gd")
const LOOKS := preload("res://world3d/zone3d/wildlife_3d_looks.gd")
const GROUND := preload("res://world3d/zone3d/wildlife_3d_ground.gd")
## The ring round Chloé (m) — about twice the 2.5D's view (20 × 15.5 m) — so twice as many of each
## kind: the same life per square metre.
const DENSITY := 2.0
const RANGE_M := 14.0
const AHEAD_M := 6.0
## Farther than AWAY times RANGE_M from the ring's middle, an animal is brought back near her.
const AWAY := 1.4
const TRIES := 14
const RETRY := 1.5
const APPEAR_S := 0.6
## What differs in 3D, by kind. WildlifeDB's sizes are « about twice the real size: seen on a
## phone »; seen close by in 3D, beside Chloé, the tiniest come nearer their true size, and the ants
## go as a file (so many following one another); the leaves fall from the 3D's taller trees.
const IN_3D := {
	&"papillon": {"width": 0.28},
	&"moustique": {"width": 0.08},
	&"feuille": {"width": 0.26, "height": [3.0, 6.0]},
	&"fourmis": {"width": 0.08, "file": 6},
	&"scarabee": {"width": 0.14},
	&"escargot": {"width": 0.15},
}
const ANT_GAP_M := 0.09
const FLY_CLEAR_M := 0.2      # a flyer keeps this far above the ground under it
const TURN_RATE := 8.0        # how quickly one turns to where it goes
const MAX_TURN := 0.6         # a side-on picture turns this far (rad) from the camera, towards its way
const FLIP_AT := 0.15         # …and is mirrored once its way leans this much the other way on screen
const WINGS := Vector2(0.15, 1.3)   # a butterfly's wings: nearly flat to high up (rad)
const ROAM := {&"flutter": Vector2.ZERO, &"swim": Vector2(2.0, 6.0), &"drift": Vector2(1.0, 3.0), &"swarm": Vector2(0.8, 2.5)}
const WOBBLE := {&"flutter": 0.35, &"swim": 0.08, &"drift": 0.04, &"swarm": 0.3}
const DART := Vector2(1.5, 4.0)
const WANDER := Vector2(0.8, 3.0)
const FLEE := Vector2(2.0, 4.0)
## Mosquitoes come round Chloé's head when she passes by them, for a while, then leave her be.
const PESTER_REACH := 4.0
const PESTER_S := 4.0
const PESTER_REST := 9.0
const PESTER_SPEED := 1.5
const PESTER_HEAD_M := 1.35
## Birds and pterosaurs flap for a part of each cycle (s), then glide on that cell.
const FLAP_CYCLE := 3.0
const FLAP_PART := 1.4
const GLIDE_FRAME := 1
const CIRCLE := Vector2(2.0, 3.5)
const CIRCLE_MOVE := Vector2(3.0, 8.0)
const CIRCLE_STAY := Vector2(6.0, 14.0)
const LEAF_FADE := 0.6
## A flyer high up (a pterosaur) crosses the sky so high over the ground (m), over so far, ahead.
const SOAR_HEIGHT := Vector2(12.0, 20.0)
const SOAR_SPAN_M := 70.0
const SOAR_AHEAD := Vector2(8.0, 30.0)
const AFLOAT_M := 0.1         # floating on the water: this much under its surface
const SCATTER_M := 3.0        # an effect on the water is scattered again when Chloé has moved this far
const INTO_WATER := {"on": [&"water"]}
const BOX_M := 60.0           # half the size of the box the batches are culled by (round the ring)

var source: ZoneSource
var terrain: ZoneTerrain
## The kind of place (WildlifeDB.PLACES): the zone's Region.ambience_id.
var place: StringName
## Its ground as the life sees it (wildlife_3d_ground.gd: water, paths, woods, sand…).
var land: GROUND

var _flocks: Array[Flock] = []
var _effects: Array[Dictionary] = []   # {def, node, at: where the ring was when scattered}
var _splash: CPUParticles3D
var _player: Node3D
var _focus := Vector3.ZERO             # the ring's middle
var _chloe := Vector3.ZERO
var _cam := Basis.IDENTITY             # the camera's axes (right, up, back)
var _right := Vector3.RIGHT            # its right, level
var _time := 0.0


## One animal: its kind (WildlifeDB, with IN_3D) and how it goes.
class Beast:
	var kind: Dictionary
	var frames := 1
	var out := false          # placed near Chloé and shown
	var pos := Vector3.ZERO
	var goal := Vector3.ZERO
	var start := Vector3.ZERO # a dart, a jump, a leap, a flight across: from…
	var t := -1.0             # …how far along (0–1; < 0: none going on; a leaf: lying)
	var span := 1.0           # …how long it takes (s)
	var lift := 0.0           # how high a jump or a leap goes (m)
	var rest := 0.0           # s left resting (hidden: before it comes out again)
	var fleeing := false
	var phase := 0.0
	var anim := 0.0           # the clock of its cells
	var frame := 0
	var heading := Vector3.RIGHT
	var left := false         # its picture mirrored (going left on the screen)
	var appear := 0.0         # 0 → 1 as it comes out
	var size := 1.0           # a leaf lying: shrinking away
	var spin := 1.0           # a leaf falling: turning over (its width, −1…1)
	var tint := Color.WHITE
	var trail := PackedVector3Array()   # a file (the ants): where the leader was, every ANT_GAP_M
	var centre := Vector3.ZERO   # circling: round what, how wide, where on it, which way
	var radius := 1.0
	var angle := 0.0
	var turn := 1.0


## The animals of one kind and their batch.
class Flock:
	var kind: Dictionary
	var look: StringName
	var per := 1              # instances per animal (a swarm's specks, a file's ants)
	var beasts: Array[Beast] = []
	var node: MultiMeshInstance3D
	var buffer := PackedFloat32Array()


## Puts the little life in `zone` (a child « Wildlife »), for its ground and its water.
static func make(zone: Node3D, src: ZoneSource, ground: ZoneTerrain) -> Wildlife3D:
	var w := Wildlife3D.new()
	w.name = "Wildlife"
	zone.add_child(w)
	w.build(src, ground)
	return w


func build(src: ZoneSource, ground: ZoneTerrain) -> void:
	source = src
	terrain = ground
	place = src.region.ambience_id
	land = GROUND.new(src, ground)
	_splash = LOOKS.splash()
	add_child(_splash)
	_populate()
	Quality.changed.connect(_populate)


## How many of each kind live here: {kind: count} (for the tests and the log).
func counts() -> Dictionary:
	var out := {}
	for f in _flocks:
		out[f.kind["id"]] = f.beasts.size()
	return out


## The animals out now: [{id, at (Vector3, the zone's metres), motion, ground (what is under it)}].
func out_now() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for f in _flocks:
		for b in f.beasts:
			if b.out:
				out.append({"id": f.kind["id"], "at": b.pos, "motion": f.kind["motion"], "ground": land.surface(_flat(b.pos))})
	return out


## The effects lit now: [kind of effect].
func effects_on() -> Array[StringName]:
	var out: Array[StringName] = []
	for e in _effects:
		if (e["node"] as CPUParticles3D).emitting:
			out.append(e["def"]["id"])
	return out


## The animals and effects of the place, as many as the graphics level allows.
func _populate() -> void:
	for f in _flocks:
		f.node.queue_free()
	_flocks.clear()
	for e in _effects:
		(e["node"] as Node).queue_free()
	_effects.clear()
	var swarms := 0
	for kind in DB.kinds_of(place):
		kind.merge(IN_3D.get(kind["id"], {}), true)
		var pic := DB.picture(kind)
		if pic == null and kind["motion"] != &"swarm":   # (a swarm makes do with specks)
			continue
		var count := Quality.scaled(roundi(float(kind["count"]) * DENSITY))
		if kind["motion"] == &"swarm":
			count = mini(count, LOOKS.MAX_SWARMS - swarms)
			swarms += count
		_flocks.append(_make_flock(kind, pic, count))
	for def in DB.effects_of(place):
		if def["emit"] == &"walls":   # (glow-worms on a cave's walls: no cave in 3D yet)
			continue
		var node := LOOKS.effect(def)
		add_child(node)
		_effects.append({"def": def, "node": node, "at": Vector3.INF})


func _make_flock(kind: Dictionary, pic: Texture2D, count: int) -> Flock:
	var f := Flock.new()
	f.kind = kind
	f.look = LOOKS.look_of(kind)
	match f.look:
		&"speck":
			f.per = int(kind.get("specks", 12))
		&"file":
			f.per = int(kind["file"])
	var tints: Array = kind.get("tints", [Color.WHITE])
	var light: Color = kind.get("glow", Color.WHITE)
	for i in count:
		var b := Beast.new()
		b.kind = kind
		b.frames = maxi(1, int(kind["frames"]))
		b.phase = randf() * TAU
		b.rest = randf_range(0.0, 1.5)
		b.tint = (tints.pick_random() as Color) * light
		f.beasts.append(b)
	f.node = LOOKS.batch(kind, pic, f.look, count, f.per)
	add_child(f.node)
	return f


func _process(delta: float) -> void:
	if source == null or (_flocks.is_empty() and _effects.is_empty()):
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player3d") as Node3D
		if _player == null:
			return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	_time += delta
	_chloe = to_local(_player.global_position)
	_cam = (global_basis.inverse() * cam.global_basis).orthonormalized()
	var ahead := Vector3(-_cam.z.x, 0.0, -_cam.z.z)
	ahead = ahead.normalized() if ahead.length() > 0.01 else Vector3.FORWARD
	_right = Vector3(-ahead.z, 0.0, ahead.x)
	_focus = _chloe + ahead * AHEAD_M
	var now := DB.moment(Game.clock / 60.0)
	var wet := 1.0 if Game.is_raining() or Game.weather in [&"sandstorm", &"blizzard"] else 0.0
	for f in _flocks:
		for b in f.beasts:
			_update_beast(b, delta, now, wet)
		_draw(f)
	for e in _effects:
		_update_effect(e, now, wet)


func _update_beast(b: Beast, delta: float, now: int, wet: float) -> void:
	if not DB.is_out(b.kind, now, wet):
		if b.out:
			_hide(b)
		return
	var motion: StringName = b.kind["motion"]
	if b.out and motion != &"soar" and _strayed(b.pos):
		_hide(b)
		b.rest = 0.0
	if not b.out:
		b.rest -= delta
		if b.rest > 0.0:
			return
		if not _place(b):
			b.rest = RETRY * randf_range(0.7, 1.3)
			return
	b.appear = minf(b.appear + delta / APPEAR_S, 1.0)
	match motion:
		&"flutter", &"swim", &"drift", &"swarm":
			_glide(b, delta)
		&"dart":
			_dart(b, delta)
		&"walk":
			_walk(b, delta)
		&"hop":
			_hop(b, delta)
		&"leap":
			_leap(b, delta)
		&"soar":
			_soar(b, delta)
		&"circle":
			_circle(b, delta)
		&"fall":
			_fall(b, delta)


## Brings an animal out somewhere fitting in the ring; false if nowhere fits now.
func _place(b: Beast) -> bool:
	var kind := b.kind
	var motion: StringName = kind["motion"]
	b.appear = 0.0
	b.size = 1.0
	if motion == &"soar":
		_cross_sky(b)
		b.out = true
		return true
	var p := _spot(kind)
	if p == Vector2.INF:
		return false
	b.pos = _point(kind, p)
	b.goal = b.pos
	b.t = -1.0
	b.rest = 0.0
	b.heading = (_right if randf() < 0.5 else -_right).rotated(Vector3.UP, randf_range(-0.8, 0.8))
	match motion:
		&"dart", &"walk", &"hop":
			b.rest = randf_range(0.0, _wait(kind))
		&"leap":   # from under the water, out, and back in — across the screen, seen side on
			var h: Array = kind["height"]
			var reach: Array = kind["jump"]
			b.lift = randf_range(h[0], h[1])
			b.start = Vector3(p.x, land.water_level(p) - 0.12, p.y)
			b.heading = _right * (1.0 if randf() < 0.5 else -1.0)
			b.goal = b.start + b.heading * randf_range(reach[0], reach[1])
			b.pos = b.start
			b.span = randf_range(0.8, 1.0)
			b.t = 0.0
			b.appear = 1.0
			_splash_at(b.start)
		&"circle":
			b.centre = b.pos
			b.radius = randf_range(CIRCLE.x, CIRCLE.y)
			b.angle = randf() * TAU
			b.turn = 1.0 if randf() < 0.5 else -1.0
			b.rest = randf_range(CIRCLE_STAY.x, CIRCLE_STAY.y)
		&"fall":
			b.t = 0.0
			b.frame = randi() % b.frames   # (its cells: different leaves)
	if b.kind.has("file"):
		b.trail.resize(int(b.kind["file"]))
		b.trail.fill(b.pos)
	b.out = true
	return true


func _hide(b: Beast) -> void:
	b.out = false
	b.fleeing = false
	b.t = -1.0


## Flutters, swims, drifts or buzzes from one spot to the next, wobbling; the fish flee Chloé,
## the mosquitoes come round her head.
func _glide(b: Beast, delta: float) -> void:
	var kind := b.kind
	var motion: StringName = kind["motion"]
	var speed: float = kind["speed"]
	if not b.fleeing and _threat(b):
		var away := _away(kind, _flat(b.pos), FLEE + Vector2.ONE)
		if away != Vector2.INF:
			b.goal = _point(kind, away)
			b.fleeing = true
	if b.fleeing:
		speed = kind.get("run", speed)
	if motion == &"swarm":
		speed = _pester(b, delta, speed)
	if b.pos.distance_to(b.goal) < maxf(0.3, speed * delta * 2.0):
		b.fleeing = false
		var roam: Vector2 = ROAM[motion]
		var p := _spot(kind) if roam == Vector2.ZERO else _spot(kind, _flat(b.pos), roam)
		if p != Vector2.INF:
			b.goal = _point(kind, p)
	var step := (b.goal - b.pos).normalized() * speed * delta
	step += Vector3(sin(_time * 3.1 + b.phase), sin(_time * 5.3 + b.phase) * 1.5, cos(_time * 2.7 + b.phase)) * float(WOBBLE[motion]) * delta
	b.pos += step
	var flat := _flat(b.pos)
	if kind.get("surface", false):
		var level := land.water_level(flat)
		if level > -INF:
			b.pos.y = level - AFLOAT_M
	else:
		b.pos.y = maxf(b.pos.y, land.base(kind, flat) + FLY_CLEAR_M)
	_turn_to(b, step, delta)
	if b.frames > 1 and motion != &"swarm":
		_frames(b, delta * (2.0 if b.fleeing else 1.0), kind.get("fps", 10.0))


## A swarm near Chloé follows her head for a while; the speed it goes at.
func _pester(b: Beast, delta: float, speed: float) -> float:
	b.rest -= delta
	if b.t > 0.0:
		b.t -= delta
		b.goal = _chloe + Vector3(sin(_time * 1.3 + b.phase) * 0.4, PESTER_HEAD_M, cos(_time * 1.1 + b.phase) * 0.3)
		if b.t <= 0.0:
			b.rest = PESTER_REST
			b.goal = b.pos
		return PESTER_SPEED
	if b.rest <= 0.0 and _flat(b.pos).distance_to(_flat(_chloe)) < PESTER_REACH:
		b.t = PESTER_S
	return speed


## Hovers, quivering, then darts to another spot nearby (a dragonfly).
func _dart(b: Beast, delta: float) -> void:
	if b.t < 0.0:
		b.rest -= delta
		b.pos = b.goal + Vector3(sin(_time * 9.0 + b.phase) * 0.03, sin(_time * 6.0 + b.phase) * 0.05, 0.0)
		if b.rest <= 0.0:
			var p := _spot(b.kind, _flat(b.goal), DART)
			if p == Vector2.INF:
				b.rest = 0.5
			else:
				b.start = b.pos
				b.goal = _point(b.kind, p)
				b.span = maxf(0.25, b.start.distance_to(b.goal) / float(b.kind["speed"]))
				b.t = 0.0
	else:
		b.t = minf(b.t + delta / b.span, 1.0)
		b.pos = b.start.lerp(b.goal, smoothstep(0.0, 1.0, b.t))
		_turn_to(b, b.goal - b.start, delta)
		if b.t >= 1.0:
			b.t = -1.0
			b.rest = _wait(b.kind)
	if b.frames > 1:
		_frames(b, delta, b.kind.get("fps", 10.0))


## Walks on its own ground from spot to spot, resting between; runs off from Chloé.
func _walk(b: Beast, delta: float) -> void:
	var kind := b.kind
	var flat := _flat(b.pos)
	if not b.fleeing and _threat(b):
		var away := _away(kind, flat, FLEE)
		if away != Vector2.INF:
			b.goal = Vector3(away.x, 0.0, away.y)
			b.fleeing = true
			b.rest = 0.0
	if b.rest > 0.0:
		b.rest -= delta
		b.frame = 0
		if b.rest <= 0.0:
			var p := _spot(kind, flat, WANDER)
			if p == Vector2.INF:
				b.rest = _wait(kind)
			else:
				b.goal = Vector3(p.x, 0.0, p.y)
		return
	var speed: float = kind["speed"]
	if b.fleeing:
		speed = kind.get("run", speed)
	var step := (_flat(b.goal) - flat).limit_length(speed * delta)
	var next := flat + step
	if not land.can_step(kind, flat, next):   # its ground ends there, or a wall of the relief
		b.fleeing = false
		b.rest = _wait(kind) * 0.5
		return
	if next.distance_to(_flat(b.goal)) < 0.01:
		b.fleeing = false
		b.rest = _wait(kind)
	_turn_to(b, Vector3(step.x, 0.0, step.y), delta)
	_frames(b, delta * speed / float(kind["speed"]), kind.get("fps", 8.0))
	b.pos = Vector3(next.x, terrain.height_at(next.x, next.y), next.y)
	if not b.trail.is_empty() and b.pos.distance_to(b.trail[0]) >= ANT_GAP_M:
		for k in range(b.trail.size() - 1, 0, -1):
			b.trail[k] = b.trail[k - 1]
		b.trail[0] = b.pos


## Sits, then jumps a little way; from Chloé, into the water if it is near (plop: gone).
func _hop(b: Beast, delta: float) -> void:
	if b.t >= 0.0:
		b.t = minf(b.t + delta / b.span, 1.0)
		b.pos = b.start.lerp(b.goal, b.t) + Vector3(0.0, 4.0 * b.lift * b.t * (1.0 - b.t), 0.0)
		b.frame = 1 if b.t < 0.6 else 2
		if b.t >= 1.0:
			b.t = -1.0
			b.frame = 0
			b.rest = _wait(b.kind)
			if land.surface(_flat(b.goal)) == &"water":
				_splash_at(b.goal)
				_hide(b)
				b.rest = randf_range(3.0, 8.0)
		return
	var threat := _threat(b)
	b.rest -= delta
	if not threat and b.rest > 0.0:
		return
	var flat := _flat(b.pos)
	var reach: Array = b.kind["jump"]
	var to := Vector2.INF
	if threat:
		to = _spot(INTO_WATER, flat, Vector2(reach[0], reach[1] * 1.8))
		if to == Vector2.INF:
			to = _away(b.kind, flat, Vector2(reach[0], reach[1]) * 1.3)
	else:
		to = _spot(b.kind, flat, Vector2(reach[0], reach[1]))
	if to == Vector2.INF:
		b.rest = 0.6
		return
	b.start = b.pos
	var landing := land.water_level(to) if land.surface(to) == &"water" else terrain.height_at(to.x, to.y)
	b.goal = Vector3(to.x, landing, to.y)
	b.lift = 0.38 if threat else 0.28
	b.span = 0.42
	b.t = 0.0
	b.heading = Vector3(to.x - flat.x, 0.0, to.y - flat.y).normalized()


## A fish out of the water: up, over, and back in with a splash; then hidden for a while.
func _leap(b: Beast, delta: float) -> void:
	b.t = minf(b.t + delta / b.span, 1.0)
	b.pos = b.start.lerp(b.goal, b.t) + Vector3(0.0, 4.0 * b.lift * b.t * (1.0 - b.t), 0.0)
	b.frame = mini(int(b.t * b.frames), b.frames - 1)
	if b.t >= 1.0:
		_splash_at(b.goal)
		_hide(b)
		b.rest = _wait(b.kind)


## High above, across the sky ahead of Chloé, flapping and gliding; then gone for a while.
func _soar(b: Beast, delta: float) -> void:
	b.t = minf(b.t + delta / b.span, 1.0)
	b.pos = b.start.lerp(b.goal, b.t) + Vector3(0.0, sin(b.t * TAU + b.phase) * 0.6, 0.0)
	_flap_glide(b, delta)
	if b.t >= 1.0:
		_hide(b)
		b.rest = _wait(b.kind)


func _cross_sky(b: Beast) -> void:
	var ahead := (_focus - _chloe).normalized()
	var mid := _focus + ahead * randf_range(SOAR_AHEAD.x, SOAR_AHEAD.y)
	mid.y = terrain.height_at(mid.x, mid.z) + randf_range(SOAR_HEIGHT.x, SOAR_HEIGHT.y)
	var across := (_right * (1.0 if randf() < 0.5 else -1.0)).rotated(Vector3.UP, randf_range(-0.3, 0.3))
	b.start = mid - across * SOAR_SPAN_M * 0.5
	b.goal = mid + across * SOAR_SPAN_M * 0.5
	b.pos = b.start
	b.heading = across
	b.t = 0.0
	b.span = SOAR_SPAN_M / float(b.kind["speed"])


## Circles over the water, now and then moving on to circle a little farther.
func _circle(b: Beast, delta: float) -> void:
	b.rest -= delta
	if b.rest <= 0.0:
		var p := _spot(b.kind, _flat(b.centre), CIRCLE_MOVE)
		if p != Vector2.INF:
			b.goal = Vector3(p.x, b.centre.y, p.y)
		b.rest = randf_range(CIRCLE_STAY.x, CIRCLE_STAY.y)
	var speed: float = b.kind["speed"]
	b.centre = b.centre.move_toward(b.goal, speed * 0.35 * delta)
	b.angle += b.turn * speed / b.radius * delta
	var was := b.pos
	b.pos = b.centre + Vector3(cos(b.angle) * b.radius, sin(_time * 0.8 + b.phase) * 0.2, sin(b.angle) * b.radius)
	_turn_to(b, b.pos - was, delta)
	_flap_glide(b, delta)


## A leaf falling from the trees, turning over and over; it lies a while, then is gone.
func _fall(b: Beast, delta: float) -> void:
	if b.t < 0.0:
		b.rest -= delta
		b.size = clampf(b.rest / LEAF_FADE, 0.0, 1.0)
		if b.rest <= 0.0:
			_hide(b)
			b.rest = randf_range(0.3, 2.5)
		return
	b.pos += Vector3(sin(_time * 1.7 + b.phase) * 0.5 + 0.12, -float(b.kind["speed"]), cos(_time * 1.3 + b.phase) * 0.2) * delta
	b.spin = cos(_time * 3.2 + b.phase)
	var ground := terrain.height_at(b.pos.x, b.pos.z) + 0.02
	if b.pos.y <= ground:
		b.pos.y = ground
		b.t = -1.0
		b.rest = _wait(b.kind)


# --- Where: the zone's ground -----------------------------------------------------------------------

## A spot fitting the kind: in the ring, or `reach` (min, max m) from `around`; INF: none found.
func _spot(kind: Dictionary, around := Vector2.INF, reach := Vector2.ZERO) -> Vector2:
	var cam: Camera3D = get_viewport().get_camera_3d() if kind.get("seen", false) else null
	for i in TRIES:
		var p: Vector2
		if around == Vector2.INF:
			p = _flat(_focus) + Vector2.from_angle(randf() * TAU) * RANGE_M * sqrt(randf())
		else:
			p = around + Vector2.from_angle(randf() * TAU) * randf_range(reach.x, reach.y)
		if land.fits(p, kind) and (cam == null or _in_view(cam, kind, p)):
			return p
	return Vector2.INF


## Would the camera see the kind over that spot (half way up its heights)?
func _in_view(cam: Camera3D, kind: Dictionary, p: Vector2) -> bool:
	var h: Array = kind.get("height", [0.0, 0.0])
	return cam.is_position_in_frustum(to_global(Vector3(p.x, land.base(kind, p) + (h[0] + h[1]) * 0.5, p.y)))


## A spot on its ground `reach` (min, max m) from `from`, away from Chloé; INF: none found.
func _away(kind: Dictionary, from: Vector2, reach: Vector2) -> Vector2:
	var away := (from - _flat(_chloe)).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	for i in TRIES:
		var p := from + away.rotated(randf_range(-0.9, 0.9)) * randf_range(reach.x, reach.y)
		if land.on_ground(p, kind):
			return p
	return Vector2.INF


## A point for the kind above a spot: on the ground, or at a height over it (the water).
func _point(kind: Dictionary, p: Vector2) -> Vector3:
	if kind.get("surface", false):
		return Vector3(p.x, land.water_level(p) - AFLOAT_M, p.y)
	var h: Array = kind.get("height", [0.0, 0.0])
	return Vector3(p.x, land.base(kind, p) + randf_range(h[0], h[1]), p.y)


func _strayed(pos: Vector3) -> bool:
	return _flat(pos).distance_to(_flat(_focus)) > RANGE_M * AWAY


func _threat(b: Beast) -> bool:
	var reach: float = b.kind.get("flee", 0.0)
	return reach > 0.0 and _flat(b.pos).distance_to(_flat(_chloe)) < reach


static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


static func _wait(kind: Dictionary) -> float:
	var w: Array = kind.get("wait", [1.0, 3.0])
	return randf_range(w[0], w[1])


# --- How it looks --------------------------------------------------------------------------------------

func _turn_to(b: Beast, way: Vector3, delta: float) -> void:
	if way.length_squared() > 1e-8:
		b.heading = b.heading.lerp(way.normalized(), 1.0 - exp(-TURN_RATE * delta))


func _frames(b: Beast, delta: float, fps: float) -> void:
	b.anim += delta * fps
	b.frame = int(b.anim) % b.frames


func _flap_glide(b: Beast, delta: float) -> void:
	if fmod(_time + b.phase, FLAP_CYCLE) < FLAP_PART:
		_frames(b, delta, b.kind.get("fps", 8.0))
	else:
		b.frame = mini(GLIDE_FRAME, b.frames - 1)


## A side-on picture standing up: turned to the camera, mirrored when it goes left on the screen, and
## turned a little towards where it goes (narrower going away or coming: it is seen to go there).
func _card(way: Vector3, left: bool, size: float) -> Basis:
	var r0 := -_right if left else _right
	var h := Vector3(way.x, 0.0, way.z)
	var r := r0
	if h.length_squared() > 1e-6:
		r = r0.rotated(Vector3.UP, clampf(r0.signed_angle_to(h.normalized(), Vector3.UP), -MAX_TURN, MAX_TURN))
	return Basis(r * size, Vector3.UP * size, r.cross(Vector3.UP) * size)


func _facing(size: float, spin := 1.0) -> Basis:
	var w := signf(spin) * maxf(absf(spin), 0.2)
	return Basis(_cam.x * size * w, _cam.y * size, _cam.z * size)


## Which way its picture faces (mirrored or not), with a margin: no flicker when it goes to or from
## the camera.
func _mirror(b: Beast) -> void:
	var side := b.heading.dot(_right)
	if absf(side) > FLIP_AT:
		b.left = side < 0.0


## Writes a flock's instances: where each is, its turn and size, its tint, its cell (or its wings).
func _draw(f: Flock) -> void:
	if f.look == &"speck":
		_draw_swarms(f)
		return
	var n := f.beasts.size() * f.per
	var buf := f.buffer
	if buf.size() != n * 20:
		buf.resize(n * 20)
	var width: float = f.kind["width"]
	var flap := float(f.kind.get("flap", 7.0))
	var i := 0
	for b in f.beasts:
		if not b.out:
			for k in f.per:
				LOOKS.put(buf, i, Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), _focus, b.tint, 0.0, 0.0)
				i += 1
			continue
		var size := width * b.appear * b.size
		_mirror(b)
		match f.look:
			&"wings":
				var open := 0.5 + 0.5 * sin(_time * TAU * flap + b.phase)
				var way := Vector3(b.heading.x, clampf(b.heading.y, -0.4, 0.4), b.heading.z)
				if Vector2(way.x, way.z).length() < 0.05:
					way = Vector3.FORWARD
				var basis := Basis.looking_at(way.normalized(), Vector3.UP).scaled(Vector3.ONE * size)
				LOOKS.put(buf, i, basis, b.pos + Vector3(0.0, (1.0 - open) * 0.03, 0.0), b.tint, 0.0, lerpf(WINGS.x, WINGS.y, open))
			&"facing":
				var basis := _facing(size, b.spin)
				if b.t < 0.0:   # a leaf lying on the ground, flat
					basis = Basis(Vector3.UP, b.phase) * Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3.ONE * size)
				LOOKS.put(buf, i, basis, b.pos, b.tint, b.frame, 0.0)
			&"file":
				var u := clampf(b.pos.distance_to(b.trail[0]) / ANT_GAP_M, 0.0, 1.0)
				var prev := b.pos
				for k in f.per:
					var at := b.pos if k == 0 else b.trail[k].lerp(b.trail[k - 1], u)
					var way := b.heading if k == 0 else prev - at
					LOOKS.put(buf, i, _card(way, b.left, size), at, b.tint, float((b.frame + k) % b.frames), 0.0)
					prev = at
					i += 1
				continue
			_:
				LOOKS.put(buf, i, _card(b.heading, b.left, size), b.pos, b.tint, b.frame, 0.0)
		i += 1
	f.buffer = buf
	f.node.multimesh.buffer = buf
	f.node.custom_aabb = AABB(_focus - Vector3.ONE * BOX_M, Vector3.ONE * BOX_M * 2.0)


## A swarm's specks are moved by the shader: only each swarm's middle and size (0: not out) here.
func _draw_swarms(f: Flock) -> void:
	var swarms := PackedVector4Array()
	swarms.resize(LOOKS.MAX_SWARMS)
	var size: float = f.kind["width"]
	for k in f.beasts.size():
		var b := f.beasts[k]
		if b.out:
			var at := to_global(b.pos)
			swarms[k] = Vector4(at.x, at.y, at.z, size * b.appear)
	(f.node.material_override as ShaderMaterial).set_shader_parameter(&"swarms", swarms)
	f.node.custom_aabb = AABB(_focus - Vector3.ONE * BOX_M, Vector3.ONE * BOX_M * 2.0)


# --- Effects: particles ----------------------------------------------------------------------------------

func _update_effect(e: Dictionary, now: int, wet: float) -> void:
	var def: Dictionary = e["def"]
	var p: CPUParticles3D = e["node"]
	var on: bool = DB.is_out(def, now, wet) and (not Game.is_snowing() or def.get("snowfall", true))
	if def["emit"] == &"box":
		p.position = Vector3(_focus.x, terrain.height_at(_focus.x, _focus.z) + float(def.get("above", 0.0)), _focus.z)
	elif on and (e["at"] as Vector3).distance_to(_focus) > SCATTER_M:
		_scatter(e)
	on = on and (def["emit"] == &"box" or not p.emission_points.is_empty())
	if p.emitting != on:
		p.emitting = on


## Points for an effect on the water (plankton) in the ring.
func _scatter(e: Dictionary) -> void:
	e["at"] = _focus
	var points := PackedVector3Array()
	var c := Vector2i((_flat(_focus) / GROUND.CELL_M).floor())
	var n := int(RANGE_M / GROUND.CELL_M)
	for z in range(c.y - n, c.y + n + 1):
		for x in range(c.x - n, c.x + n + 1):
			var m := Vector2(x + randf(), z + randf()) * GROUND.CELL_M
			if m.distance_to(_flat(_focus)) <= RANGE_M and land.surface(m) == &"water":
				points.append(Vector3(m.x, land.water_level(m) + 0.03, m.y))
	var p: CPUParticles3D = e["node"]
	p.position = Vector3.ZERO
	p.emission_points = points


func _splash_at(at: Vector3) -> void:
	_splash.position = at
	_splash.restart()
