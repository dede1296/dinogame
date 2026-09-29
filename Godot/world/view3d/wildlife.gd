class_name Wildlife
extends Node3D
## Little life around Chloé, as the place is (WildlifeDB, by the zone's Region.ambience_id):
## butterflies over the meadows, mosquitoes and dragonflies in the woods, frogs in the marsh,
## lizards and scorpions in the desert, crabs on the beaches and fish leaping out of the sea,
## glow-worms in the caves… Each keeps to its own ground (the zone's tiles: sand, water, mud…),
## comes out by day or at night, shelters from the rain; the walkers run off when Chloé comes
## near. One picture per animal (its cells turned through), particles for the clouds and the
## lights. Follows the camera's focus; how many depends on the graphics level. A kind whose
## picture is not there (yet) is left out.

const DB := preload("res://data/wildlife_db.gd")
const LOOKS := preload("res://world/view3d/wildlife_looks.gd")
const PX := 48.0
## Where the life is, around the focus (m): across, towards the top of the screen, towards the
## camera. Farther than AWAY times that, an animal is brought back near the focus.
const RANGE_X := 10.0
const RANGE_NORTH := 10.0
const RANGE_SOUTH := 5.5
const AWAY := 1.35
## Tries to find a spot fitting an animal, and how long before trying again when none fits (s).
const TRIES := 14
const RETRY := 1.5
## How far the gliders go for their next spot (m; zero: anywhere around the focus), and how
## much they wobble on the way.
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
## Birds and pterosaurs flap for a part of each cycle (s), then glide on that cell.
const FLAP_CYCLE := 3.0
const FLAP_PART := 1.4
const GLIDE_FRAME := 1   # (wings spread wide)
## A flyer high up crosses the top of the view (fractions of the screen's height): lower in it, it
## would pass right before the camera, huge.
const SKY_BAND := Vector2(0.05, 0.3)
## A bird circling over the water: its circle (m), how often it moves to another one (s).
const CIRCLE := Vector2(2.0, 3.5)
const CIRCLE_MOVE := Vector2(3.0, 8.0)
const CIRCLE_STAY := Vector2(6.0, 14.0)
const LEAF_FADE := 0.6
## Floating on the water (a jellyfish at night): half sunk.
const AFLOAT := HeightMap.WATER_LEVEL - 0.1
## Effects on the water or the walls are scattered again when the focus has moved this far (m).
const SCATTER := 3.0
const INTO_WATER := {"on": [&"water"]}

var heights: HeightMap
var _region: Region
var _region_key := 0
var _underwater := false
var _size := Vector2i.ZERO
## The zone's ground, read from its tiles as needed: per tile, 0 = not read yet, else an index
## into _names + 1.
var _surfaces := PackedByteArray()
var _names: Array[StringName] = []
var _beasts: Array[Beast] = []
var _effects: Array[Dictionary] = []   # {def, node, at: where the focus was when scattered}
var _splash: CPUParticles3D
var _focus := Vector3.ZERO
var _chloe := Vector3.ZERO
var _time := 0.0


## One animal: its kind (WildlifeDB), its picture (a swarm: its cloud) and how it goes.
class Beast:
	var kind: Dictionary
	var node: Node3D
	var shadow: Node3D        # a walker's, on the ground under it
	var frames := 1
	var out := false          # placed near the focus and shown
	var pos := Vector3.ZERO
	var goal := Vector3.ZERO
	var start := Vector3.ZERO # a dart, a jump, a leap, a flight across: from…
	var t := -1.0             # …how far along (0–1; < 0: none going on)
	var span := 1.0           # …how long it takes (s)
	var lift := 0.0           # how high a jump or a leap goes (m)
	var rest := 0.0           # s left resting (hidden: before it comes out again)
	var fleeing := false
	var phase := 0.0
	var anim := 0.0           # the clock of its cells
	var centre := Vector3.ZERO   # circling: round what, how wide, where on it, which way
	var radius := 1.0
	var angle := 0.0
	var turn := 1.0


func _ready() -> void:
	_splash = LOOKS.splash()
	add_child(_splash)
	Quality.changed.connect(_populate)


## Moves the life around `focus` for the hour and weather (`rain` 0–1) of `region`; the
## walkers flee `chloe` (her feet; INF: the focus).
func update(delta: float, focus: Vector3, hour: float, rain: float, region: Region, chloe := Vector3.INF) -> void:
	if region == null:
		return
	if region.get_instance_id() != _region_key:
		_enter(region)
	_time += delta
	_focus = focus
	_chloe = focus if chloe == Vector3.INF else chloe
	var now := DB.moment(hour)
	var wet := 0.0 if region.indoor else rain
	for b in _beasts:
		_update_beast(b, delta, now, wet)
	for e in _effects:
		_update_effect(e, now, wet)


func _enter(region: Region) -> void:
	_region = region
	_region_key = region.get_instance_id()
	_underwater = region.is_underwater()
	_size = region.map_size()
	_surfaces = PackedByteArray()
	_surfaces.resize(_size.x * _size.y)
	_names.clear()
	_populate()


## The animals and effects of the place, as many as the graphics level allows.
func _populate() -> void:
	for b in _beasts:
		b.node.queue_free()
	_beasts.clear()
	for e in _effects:
		(e["node"] as Node).queue_free()
	_effects.clear()
	if _region == null or not is_instance_valid(_region):
		return
	for kind in DB.kinds_of(_region.ambience_id):
		var pic := LOOKS.texture(kind)
		if pic == null and kind["motion"] != &"swarm":   # (a swarm makes do with specks)
			continue
		for i in Quality.scaled(int(kind["count"])):
			_beasts.append(_make_beast(kind, pic))
	for def in DB.effects_of(_region.ambience_id):
		var node := LOOKS.effect(def)
		add_child(node)
		_effects.append({"def": def, "node": node, "at": Vector3.INF})


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


## Brings an animal out somewhere fitting near the focus; false if nowhere fits now.
func _place(b: Beast) -> bool:
	var kind := b.kind
	var motion: StringName = kind["motion"]
	if motion == &"soar":
		if not _cross_sky(b):
			return false
	else:
		var p := _spot(kind)
		if p == Vector2.INF:
			return false
		b.pos = _point(kind, p)
		b.goal = b.pos
		b.t = -1.0
		b.rest = 0.0
		match motion:
			&"dart", &"walk", &"hop":
				b.rest = randf_range(0.0, _wait(kind))
			&"leap":   # from under the water, out, and back in
				var h: Array = kind["height"]
				var reach: Array = kind["jump"]
				b.lift = randf_range(h[0], h[1])
				b.start = Vector3(p.x, HeightMap.WATER_LEVEL - 0.12, p.y)
				b.goal = b.start + Vector3(randf_range(reach[0], reach[1]) * (1.0 if randf() < 0.5 else -1.0), 0.0, randf_range(-0.2, 0.2))
				b.pos = b.start
				b.span = randf_range(0.8, 1.0)
				b.t = 0.0
				_splash_at(b.start)
			&"circle":
				b.centre = b.pos
				b.radius = randf_range(CIRCLE.x, CIRCLE.y)
				b.angle = randf() * TAU
				b.turn = 1.0 if randf() < 0.5 else -1.0
				b.rest = randf_range(CIRCLE_STAY.x, CIRCLE_STAY.y)
			&"fall":
				b.t = 0.0
				(b.node as Sprite3D).frame = randi() % b.frames   # (its cells: different leaves)
				b.node.scale = Vector3.ONE
	b.out = true
	b.node.position = b.pos
	if b.node is CPUParticles3D:
		(b.node as CPUParticles3D).restart()
	b.node.visible = true
	return true


func _hide(b: Beast) -> void:
	b.out = false
	b.fleeing = false
	b.t = -1.0
	if b.node is CPUParticles3D:
		(b.node as CPUParticles3D).emitting = false   # (its specks fade away)
	else:
		b.node.visible = false


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
	var at := b.pos
	if kind.get("surface", false):
		at.y = AFLOAT
	elif motion == &"drift":
		at.y += sin(_time * 0.9 + b.phase) * 0.12
	b.node.position = at
	if b.node is Sprite3D:
		if motion != &"drift":
			_face(b, step.x)
		_wings(b, delta * (2.0 if b.fleeing else 1.0))


## A swarm near Chloé follows her head for a while; the speed it goes at.
func _pester(b: Beast, delta: float, speed: float) -> float:
	b.rest -= delta
	if b.t > 0.0:
		b.t -= delta
		b.goal = _chloe + Vector3(sin(_time * 1.3 + b.phase) * 0.4, 1.35, cos(_time * 1.1 + b.phase) * 0.3)
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
		_face(b, b.goal.x - b.start.x)
		if b.t >= 1.0:
			b.t = -1.0
			b.rest = _wait(b.kind)
	b.node.position = b.pos
	_wings(b, delta)


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
		_set_frame(b, 0)
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
	if Vector2i(next.floor()) != Vector2i(flat.floor()) and not _on_ground(next, kind):   # its ground ends here
		b.fleeing = false
		b.rest = _wait(kind) * 0.5
		return
	if next.distance_to(_flat(b.goal)) < 0.01:
		b.fleeing = false
		b.rest = _wait(kind)
	_face(b, step.x)
	_frames(b, delta * speed / float(kind["speed"]), kind["fps"])
	b.pos = Vector3(next.x, _base(kind, next), next.y)
	b.node.position = b.pos


## Sits, then jumps a little way; from Chloé, into the water if it is near (plop: gone).
func _hop(b: Beast, delta: float) -> void:
	if b.t >= 0.0:
		b.t = minf(b.t + delta / b.span, 1.0)
		b.pos = b.start.lerp(b.goal, b.t) + Vector3(0.0, 4.0 * b.lift * b.t * (1.0 - b.t), 0.0)
		b.node.position = b.pos
		_set_frame(b, 1 if b.t < 0.6 else 2)
		if b.shadow:   # (it stays on the ground)
			b.shadow.position.y = (lerpf(b.start.y, b.goal.y, b.t) - b.pos.y) / LOOKS.STRETCH + 0.02
		if b.t >= 1.0:
			b.t = -1.0
			_set_frame(b, 0)
			b.rest = _wait(b.kind)
			if _surface(Vector2i(_flat(b.goal).floor())) == &"water":
				_splash_at(Vector3(b.goal.x, HeightMap.WATER_LEVEL, b.goal.z))
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
	var land := HeightMap.WATER_LEVEL if _surface(Vector2i(to.floor())) == &"water" else _base(b.kind, to)
	b.goal = Vector3(to.x, land, to.y)
	b.lift = 0.38 if threat else 0.28
	b.span = 0.42
	b.t = 0.0
	_face(b, to.x - flat.x)


## A fish out of the water: up, over, and back in with a splash; then hidden for a while.
func _leap(b: Beast, delta: float) -> void:
	b.t = minf(b.t + delta / b.span, 1.0)
	b.pos = b.start.lerp(b.goal, b.t) + Vector3(0.0, 4.0 * b.lift * b.t * (1.0 - b.t), 0.0)
	b.node.position = b.pos
	_face(b, b.goal.x - b.start.x)
	_set_frame(b, mini(int(b.t * b.frames), b.frames - 1))
	if b.t >= 1.0:
		_splash_at(b.goal)
		_hide(b)
		b.rest = _wait(b.kind)


## High above, across the whole view, flapping and gliding; then gone for a while.
func _soar(b: Beast, delta: float) -> void:
	b.t = minf(b.t + delta / b.span, 1.0)
	b.pos = b.start.lerp(b.goal, b.t) + Vector3(0.0, sin(b.t * TAU + b.phase) * 0.25, 0.0)
	b.node.position = b.pos
	_face(b, b.goal.x - b.start.x)
	_flap_glide(b, delta)
	if b.t >= 1.0:
		_hide(b)
		b.rest = _wait(b.kind)


## A flight across the view at the kind's height, from one side of the screen to the other
## (the camera looks down steeply: only there is a flyer high up seen at all).
func _cross_sky(b: Beast) -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var h: Array = b.kind["height"]
	var level := _focus.y + randf_range(h[0], h[1])
	var screen := get_viewport().get_visible_rect().size
	var y := randf_range(SKY_BAND.x, SKY_BAND.y) * screen.y
	var a := _on_level(cam, Vector2(-0.1 * screen.x, y), level)
	var z := _on_level(cam, Vector2(1.1 * screen.x, y + randf_range(-0.12, 0.12) * screen.y), level)
	if a == Vector3.INF or z == Vector3.INF:
		return false
	if randf() < 0.5:
		var swap := a
		a = z
		z = swap
	b.start = a
	b.goal = z
	b.pos = a
	b.t = 0.0
	b.span = a.distance_to(z) / float(b.kind["speed"])
	return true


## Where the ray through a point of the screen meets the height `level` (INF: never).
static func _on_level(cam: Camera3D, screen: Vector2, level: float) -> Vector3:
	var from := cam.project_ray_origin(screen)
	var dir := cam.project_ray_normal(screen)
	if dir.y > -0.01 or from.y <= level:
		return Vector3.INF
	return from + dir * ((level - from.y) / dir.y)


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
	b.pos = b.centre + Vector3(cos(b.angle) * b.radius, sin(_time * 0.8 + b.phase) * 0.2, sin(b.angle) * b.radius * 0.6)
	b.node.position = b.pos
	_face(b, b.pos.x - was.x)
	_flap_glide(b, delta)


## A leaf falling from the trees, turning over and over; it lies a while, then is gone.
func _fall(b: Beast, delta: float) -> void:
	var s := b.node as Sprite3D
	if b.t < 0.0:
		b.rest -= delta
		s.scale = Vector3.ONE * clampf(b.rest / LEAF_FADE, 0.0, 1.0)
		if b.rest <= 0.0:
			_hide(b)
			b.rest = randf_range(0.3, 2.5)
		return
	b.pos += Vector3(sin(_time * 1.7 + b.phase) * 0.5 + 0.12, -float(b.kind["speed"]), cos(_time * 1.3 + b.phase) * 0.2) * delta
	var spin := cos(_time * 3.2 + b.phase)
	s.scale = Vector3(maxf(absf(spin), 0.2), 1.0, 1.0)
	s.flip_h = spin < 0.0
	var ground := _base(b.kind, _flat(b.pos)) + 0.03
	if b.pos.y <= ground:
		b.pos.y = ground
		b.t = -1.0
		b.rest = _wait(b.kind)
		s.scale = Vector3.ONE
	s.position = b.pos


# --- Where: the zone's ground -----------------------------------------------------------

## A spot fitting the kind: around the focus, or `reach` (min, max m) from `around`; INF: none found.
func _spot(kind: Dictionary, around := Vector2.INF, reach := Vector2.ZERO) -> Vector2:
	for i in TRIES:
		var p: Vector2
		if around == Vector2.INF:
			p = Vector2(_focus.x + randf_range(-RANGE_X, RANGE_X), _focus.z + randf_range(-RANGE_NORTH, RANGE_SOUTH))
		else:
			p = around + Vector2.from_angle(randf() * TAU) * randf_range(reach.x, reach.y)
		if _fits(p, kind) and (not kind.get("seen", false) or _in_view(kind, p)):
			return p
	return Vector2.INF


## Would the camera see the kind over that spot (half way up its heights)?
func _in_view(kind: Dictionary, p: Vector2) -> bool:
	var cam := get_viewport().get_camera_3d()
	var h: Array = kind.get("height", [0.0, 0.0])
	return cam == null or cam.is_position_in_frustum(Vector3(p.x, _base(kind, p) + (h[0] + h[1]) * 0.5, p.y))


## A spot on its ground `reach` (min, max m) from `from`, away from Chloé; INF: none found.
func _away(kind: Dictionary, from: Vector2, reach: Vector2) -> Vector2:
	var away := (from - _flat(_chloe)).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	for i in TRIES:
		var p := from + away.rotated(randf_range(-0.9, 0.9)) * randf_range(reach.x, reach.y)
		if _on_ground(p, kind):
			return p
	return Vector2.INF


func _fits(p: Vector2, kind: Dictionary) -> bool:
	if not _on_ground(p, kind):
		return false
	var cell := Vector2i(p.floor())
	var near: Dictionary = kind.get("near", {})
	for s: StringName in near:
		if not _within(cell, s, near[s]):
			return false
	var far: Dictionary = kind.get("far", {})
	for s: StringName in far:
		if _within(cell, s, far[s]):
			return false
	return true


## Inside the zone, on a ground the kind lives on.
func _on_ground(p: Vector2, kind: Dictionary) -> bool:
	var s := _surface(Vector2i(p.floor()))
	if s == &"":
		return false
	var on: Array = kind.get("on", [])
	return on.is_empty() or s in on


## Is there that ground (&"land": any but water) within `r` m of the tile? (Far: every other tile.)
func _within(cell: Vector2i, surface: StringName, r: float) -> bool:
	var n := ceili(r)
	var step := 1 if r <= 3.0 else 2
	for dy in range(-n, n + 1, step):
		for dx in range(-n, n + 1, step):
			if dx * dx + dy * dy > r * r:
				continue
			var s := _surface(cell + Vector2i(dx, dy))
			if s == surface or (surface == &"land" and s != &"water" and s != &""):
				return true
	return false


## The ground of a tile (Region.surface_at); &"" outside the zone.
func _surface(cell: Vector2i) -> StringName:
	if _region == null or cell.x < 0 or cell.y < 0 or cell.x >= _size.x or cell.y >= _size.y:
		return &""
	var i := cell.y * _size.x + cell.x
	if _surfaces[i] == 0:
		var s := _region.surface_at(Vector2((cell.x + 0.5) * PX, (cell.y + 0.5) * PX))
		var k := _names.find(s)
		if k < 0:
			_names.append(s)
			k = _names.size() - 1
		_surfaces[i] = k + 1
	return _names[_surfaces[i] - 1]


## A point for the kind above a spot: on the ground, or at a height over it (the water).
func _point(kind: Dictionary, p: Vector2) -> Vector3:
	if kind.get("surface", false):
		return Vector3(p.x, AFLOAT, p.y)
	var h: Array = kind.get("height", [0.0, 0.0])
	return Vector3(p.x, _base(kind, p) + randf_range(h[0], h[1]), p.y)


## What the kind stands on or flies over: the ground, or the water over it (under the sea:
## the floor).
func _base(kind: Dictionary, p: Vector2) -> float:
	var ground := heights.height(p) if heights else _focus.y
	if _underwater or kind["motion"] in LOOKS.STANDING:
		return ground
	return maxf(ground, HeightMap.WATER_LEVEL)


func _strayed(pos: Vector3) -> bool:
	var d := pos - _focus
	return absf(d.x) > RANGE_X * AWAY or d.z < -RANGE_NORTH * AWAY or d.z > RANGE_SOUTH * AWAY


func _threat(b: Beast) -> bool:
	var reach: float = b.kind.get("flee", 0.0)
	return reach > 0.0 and _flat(b.pos).distance_to(_flat(_chloe)) < reach


static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


static func _wait(kind: Dictionary) -> float:
	var w: Array = kind.get("wait", [1.0, 3.0])
	return randf_range(w[0], w[1])


# --- How it looks ----------------------------------------------------------------------------

func _face(b: Beast, dx: float) -> void:
	var s := b.node as Sprite3D
	if absf(dx) > 0.0005 and s.flip_h != (dx < 0.0):
		s.flip_h = dx < 0.0   # (drawn facing right)


func _set_frame(b: Beast, f: int) -> void:
	var s := b.node as Sprite3D
	if s.frame != f:
		s.frame = f


func _frames(b: Beast, delta: float, fps: float) -> void:
	b.anim += delta * fps
	_set_frame(b, int(b.anim) % b.frames)


## Wings beating: through its cells, or (one picture, the butterfly) by narrowing it.
func _wings(b: Beast, delta: float) -> void:
	if b.frames > 1:
		_frames(b, delta, b.kind.get("fps", 10.0))
	else:
		b.node.scale.x = 0.25 + 0.75 * absf(sin(_time * TAU * float(b.kind.get("flap", 7.0)) + b.phase))


func _flap_glide(b: Beast, delta: float) -> void:
	if fmod(_time + b.phase, FLAP_CYCLE) < FLAP_PART:
		_frames(b, delta, b.kind["fps"])
	else:
		_set_frame(b, mini(GLIDE_FRAME, b.frames - 1))



func _make_beast(kind: Dictionary, pic: Texture2D) -> Beast:
	var b := Beast.new()
	b.kind = kind
	b.frames = maxi(1, int(kind["frames"]))
	b.phase = randf() * TAU
	b.rest = randf_range(0.0, 1.5)
	if kind["motion"] == &"swarm":
		b.node = LOOKS.swarm(kind, pic)
	else:
		b.node = LOOKS.picture(kind, pic, b.frames)
		if b.node.get_child_count() > 0:
			b.shadow = b.node.get_child(0)
	b.node.visible = false
	b.node.position = Vector3(0, -100, 0)   # placed far: the first update brings it near Chloé
	add_child(b.node)
	return b


# --- Effects: particles ------------------------------------------------------------------------

func _update_effect(e: Dictionary, now: int, wet: float) -> void:
	var def: Dictionary = e["def"]
	var p: CPUParticles3D = e["node"]
	var on := DB.is_out(def, now, wet)
	if def["emit"] == &"box":
		p.position = _focus + Vector3(0, float(def.get("above", 0.0)), 0)
	elif on and (e["at"] as Vector3).distance_to(_focus) > SCATTER:
		_scatter(e)
	on = on and (def["emit"] == &"box" or not p.emission_points.is_empty())
	if p.emitting != on:
		p.emitting = on


## Points for an effect on the water (plankton) or on the walls' rims (glow-worms) around the focus.
func _scatter(e: Dictionary) -> void:
	e["at"] = _focus
	var def: Dictionary = e["def"]
	var points := PackedVector3Array()
	var floor_m := heights.height(_flat(_focus)) if heights else _focus.y
	var c := Vector2i(_flat(_focus).floor())
	for z in range(c.y - int(RANGE_NORTH), c.y + int(RANGE_SOUTH) + 1):
		for x in range(c.x - int(RANGE_X), c.x + int(RANGE_X) + 1):
			var cell := Vector2i(x, z)
			if def["emit"] == &"water":
				if _surface(cell) == &"water":
					points.append(Vector3(x + randf(), HeightMap.WATER_LEVEL + 0.03, z + randf()))
			elif _surface(cell) != &"" and heights:
				var mid := Vector2(x + 0.5, z + 0.5)
				var top := heights.height(mid)
				if top > floor_m + 1.0 and _by_floor(mid, floor_m):
					points.append(Vector3(x + randf(), top - randf_range(0.0, 0.5), z + randf()))
	var p: CPUParticles3D = e["node"]
	p.position = Vector3.ZERO
	p.emission_points = points


## A wall's rim: a tile beside it is down on the floor.
func _by_floor(mid: Vector2, floor_m: float) -> bool:
	for d: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		if heights.height(mid + d) < floor_m + 0.5:
			return true
	return false


func _splash_at(at: Vector3) -> void:
	_splash.position = Vector3(at.x, HeightMap.WATER_LEVEL + 0.02, at.z)
	_splash.restart()
