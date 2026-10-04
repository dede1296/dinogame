class_name Dinosaur3D
extends CharacterBody3D
## A dino in the 3D world (docs/migration-3d.md, phase 3), any species: Dinosaur3D.create(species, level).
## - Data: its Species3D (model, animations, real size, diet, temperament, speeds) and the 2.5D's
##   sheet; `dino` is the gameplay creature of the 2.5D (game/dino.gd: stats, level, moves),
##   unchanged — what a battle or a capture will use.
## - Body: scaled to its real length (compressed for the big ones) and to its age (DinoSize.growth),
##   a capsule on the dinos' layer, gravity, a NavigationAgent3D to find its way.
## - Presentation: its model animated by the generic CharacterAnimator.
## - Behaviour: a DinoBrain (rest, amble, watch Chloé, run off). Chloé can observe it (E).
## - A wild one Chloé walks into starts a battle (`encountered`, as the 2.5D's WildDino): calm, she
##   can come close; running at it, it runs off. A companion (`companion_of`, Chloé's lead dino:
##   Dinosaur3D.companion) follows her, and is neither met nor in her way.

@warning_ignore("unused_signal")   # emitted by its DinoBrain
signal state_changed(state: StringName)
## Chloé walked into this wild dino (phase 5: Encounters3D plays the battle).
signal encountered(dino: Dinosaur3D)

const ACCEL := 9.0          # m/s²
const TURN := 7.0
const LOOK_TURN := 4.0
const OBSERVE_REACH := 6.0  # Chloé can observe it from this far (m)
const FALL_LIMIT := -30.0
const TOON := preload("res://world3d/render/toon_style.gd")
## Chloé this close to its body (m, beyond its capsule) meets it: a battle.
const TOUCH_M := 0.9

var species: Species3D
var dino: Dino
## Where it lives: it ambles around here.
var home := Vector3.ZERO
var brain: DinoBrain
var animator: CharacterAnimator
var agent: NavigationAgent3D
var model: Node3D
## Its size against an adult of its species (DinoSize.growth: 1 = grown).
var growth := 1.0
## Its length and height as shown (m).
var length_m := 0.0
var height_m := 0.0
## Whom it follows as a companion (Chloé), null: a wild dino.
var companion_of: Node3D = null
## Its herd (the same array for all of them, itself included), when its species lives in groups.
var herd: Array[Dinosaur3D] = []

var _calm := 0.0   # (s) not met again so soon after a battle it was left out of (calm_down)
var _voice: AudioStreamPlayer3D
var _cry_in := 0.0   # (s) until it cries out by itself (as the 2.5D's WildDino, every 10–22 s)
var _gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _speed := 0.0
var _moving := false
var _look := Vector3.INF
var _holder: Node3D


static func create(of_species: Species3D, level: int) -> Dinosaur3D:
	var d := Dinosaur3D.new()
	d.species = of_species
	d.dino = Dino.create(of_species.id, level)
	d.name = String(of_species.id).capitalize().replace(" ", "")
	return d


## Chloé's own dino `of_dino` (one of Game.party) walking with her, if its species has a 3D sheet.
static func companion(of_dino: Dino, chloe: Node3D) -> Dinosaur3D:
	var sheet := Species3D.of(of_dino.species().id)
	if sheet == null:
		return null
	var d := Dinosaur3D.new()
	d.species = sheet
	d.dino = of_dino
	d.companion_of = chloe
	d.name = "Companion"
	return d


func _ready() -> void:
	add_to_group(&"dino3d")
	# a companion is in no one's way (not on the dinos' layer)
	collision_layer = 0 if companion_of else Layers3D.DINOS
	collision_mask = Layers3D.WORLD | Layers3D.WATER
	floor_snap_length = 0.3
	if home == Vector3.ZERO:
		home = global_position
	_build()
	brain = DinoBrain.new(self)


## Not met again for `secs` (a battle it was left out of: Chloé ran away, or it was the other one).
func calm_down(secs: float) -> void:
	_calm = secs


func is_calm() -> bool:
	return _calm > 0.0


## Its speeds, slower when it is young.
func walk_speed() -> float:
	return species.walk_speed * sqrt(growth)


func run_speed() -> float:
	return species.run_speed * sqrt(growth)


func state() -> StringName:
	return brain.state_name() if brain else &""


## Walks or runs (`speed`, m/s) to `point`, along the navigation mesh if there is one.
func go_to(point: Vector3, speed: float) -> void:
	agent.target_position = point
	_speed = speed
	_moving = true
	_look = Vector3.INF


func stop() -> void:
	_moving = false


## Goes on where it was going, at this speed (m/s).
func set_speed(speed: float) -> void:
	_speed = speed


## Its cry (DinoSpecies.cry: neutre, attaque…), heard from where it stands.
func cry(kind: StringName) -> void:
	var stream := species.sheet().cry(kind)
	if stream and _voice:
		_voice.stream = stream
		_voice.pitch_scale = randf_range(0.95, 1.05)
		_voice.play()


## The closest point to `point` it can walk to (on the navigation mesh; `point` itself without one).
func walkable_point(point: Vector3) -> Vector3:
	var map := agent.get_navigation_map()
	if NavigationServer3D.map_get_regions(map).is_empty():
		return point
	return NavigationServer3D.map_get_closest_point(map, point)


func arrived() -> bool:
	return not _moving


## Turns its head (its body, standing) towards `point`.
func look_toward(point: Vector3) -> void:
	_look = point


func _physics_process(delta: float) -> void:
	_calm = maxf(_calm - delta, 0.0)
	_cry_in -= delta
	if _cry_in <= 0.0:
		_cry_in = randf_range(10.0, 22.0)
		if not companion_of:
			cry(&"neutre")
	brain.update(delta)
	var wish := Vector3.ZERO
	if _moving:
		var next := _next_point()
		var to := (next - global_position).slide(Vector3.UP)
		if agent.is_navigation_finished() or to.length() < 0.05:
			_moving = false
		else:
			# brakes on the way in, so it stops where it was going (not past a ledge's edge)
			var left := agent.distance_to_target()
			wish = to.normalized() * minf(_speed, sqrt(2.0 * ACCEL * maxf(left, 0.0)) + 0.2)
	var flat := Vector3(velocity.x, 0.0, velocity.z).move_toward(wish, ACCEL * delta)
	velocity = Vector3(flat.x, velocity.y, flat.z)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()
	if global_position.y < FALL_LIMIT:   # fell out of the world: back home
		global_position = home + Vector3(0.0, 0.3, 0.0)
		velocity = Vector3.ZERO
		stop()
	_face(flat, delta)


## The next corner of its path; straight at the target where there is no navigation mesh.
func _next_point() -> Vector3:
	var map := agent.get_navigation_map()
	if NavigationServer3D.map_get_regions(map).is_empty():
		return agent.target_position
	return agent.get_next_path_position()


func _face(flat: Vector3, delta: float) -> void:
	var dir := flat
	var rate := TURN
	if flat.length() < 0.2:
		if _look == Vector3.INF:
			return
		dir = (_look - global_position).slide(Vector3.UP)
		rate = LOOK_TURN
	if dir.length() < 0.01:
		return
	_holder.rotation.y = lerp_angle(_holder.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-rate * delta))


func _build() -> void:
	_holder = Node3D.new()
	_holder.name = "Model"
	add_child(_holder)
	model = species.model.instantiate() as Node3D
	_holder.add_child(model)
	TOON.apply(model)   # the cartoon look: soft steps, brown outline
	var drawn := ModelSize.posed_box(model, species.model.resource_path).size
	growth = DinoSize.growth(species.sheet(), dino.level)
	var scale_by := species.adult_scale(drawn) * growth
	_holder.scale = Vector3.ONE * scale_by
	length_m = maxf(drawn.z, drawn.x) * scale_by
	height_m = drawn.y * scale_by
	var radius := clampf(length_m * 0.16, 0.12, 2.5)
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = maxf(height_m * 0.8, radius * 2.0)
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	add_child(shape)
	agent = NavigationAgent3D.new()
	agent.radius = radius
	agent.height = capsule.height
	agent.path_desired_distance = 0.6
	agent.target_desired_distance = 0.8
	add_child(agent)
	animator = CharacterAnimator.new()
	animator.name = "Animator"
	animator.body = self
	animator.model = model
	animator.anim_set = species.anim_set
	animator.size_factor = growth   # its AnimSet's speeds are an adult's
	add_child(animator)
	_voice = AudioStreamPlayer3D.new()
	_voice.bus = Audio.CRIES_BUS
	_voice.unit_size = 6.0
	_voice.max_distance = 60.0
	_voice.position.y = height_m * 0.7
	add_child(_voice)
	_cry_in = randf_range(3.0, 22.0)
	if companion_of:
		return
	var look := Interactable3D.new()
	look.verb = "observer"
	look.reach = OBSERVE_REACH
	look.hint_height = height_m + 0.3
	look.lines = _observe_lines()
	add_child(look)
	_add_touch(radius, capsule.height)


## Chloé walking into it (her layer, within TOUCH_M of its body): `encountered`, unless it is calm
## or a scene or a battle holds her.
func _add_touch(radius: float, height: float) -> void:
	var touch := Area3D.new()
	touch.name = "Touch"
	touch.collision_layer = Layers3D.INTERACT
	touch.collision_mask = Layers3D.PLAYER
	var sphere := CylinderShape3D.new()
	sphere.radius = radius + TOUCH_M
	sphere.height = height + 1.0
	var shape := CollisionShape3D.new()
	shape.shape = sphere
	shape.position.y = height * 0.5
	touch.add_child(shape)
	add_child(touch)
	touch.body_entered.connect(func(body: Node3D) -> void:
		if body is Player3D and not is_calm() and (body as Player3D).can_move():
			encountered.emit(self))


## What Chloé reads observing it: name and level, then the Dinodex's facts (DexFacts).
func _observe_lines() -> Array[Dictionary]:
	var sheet := species.sheet()
	var lines: Array[Dictionary] = [{"who": "", "text": "%s sauvage, niveau %d." % [sheet.display_name, dino.level]}]
	var facts: Dictionary = DexFacts.INFO.get(species.id, {})
	if facts.has("size"):
		lines.append({"who": "", "text": "%s. %s." % [facts["size"], DexFacts.DIETS.get(facts.get("diet", ""), "")]})
	if facts.has("fact"):
		lines.append({"who": "", "text": facts["fact"]})
	return lines
