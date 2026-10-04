class_name Player3D
extends CharacterBody3D
## Chloé in the 3D world (docs/migration-3d.md). Moves relative to the camera with the input
## actions of the 2.5D game (keyboard, gamepad), falls and lands, runs (B held, Escape, Shift),
## jumps (Space, X), climbs low steps, turns to where she goes, and uses what is in front of her
## (E, Enter, A: Interactable3D). She walks at a child's pace (WALK, the 3D's own: the 2.5D's
## walking speed is a jog once seen in 3D) and runs at the 2.5D's running speed (Player), in metres:
## 1 tile = 48 px = 1 m. 1.50 m, 32 kg, slim. Her origin is at her feet; her model faces +Z (glTF), under `Model`:
## `model_scene` if set (animated by a CharacterAnimator from `anim_set`), else a stand-in capsule.
## She fades out when the camera comes too close (against a wall), so she never fills the screen.

signal jumped
## Back on the ground; how fast she was falling (m/s).
signal landed(fall_speed: float)
signal interacted(what: Node3D)

const PX_PER_M := 48.0
const SPEED := Player.SPEED / PX_PER_M     # the 2.5D's walking speed, m/s (~3.4): a jog in 3D
## Her walk (m/s): a child's walking pace (Greg, 04/10: her steps must look grounded, not a jog).
const WALK := 1.6
const ACCEL := Player.ACCEL / PX_PER_M     # m/s²: full speed in about a tenth of a second
const TURN := 12.0                         # how fast she faces where she goes (higher = quicker)
const HEIGHT := 1.5                        # Chloé: 1.50 m, 32 kg, slim
const RADIUS := 0.17
const MASS_KG := 32.0
const FLOOR_SNAP := 0.35                   # stays on the ground down slopes and small steps
## Climbs a step up to this high (a kerb, a stair, a stone) without slowing; higher is a wall.
## (The 2.5D relief levels are 1.2 m and Region.CLIFF_STEP 0.75 m: those stay cliffs.)
const STEP_MAX := 0.35
## Jump: up to this high (m, the feet; ~0.68 once integrated) with the button held, less with a tap. Under
## Region.CLIFF_STEP (0.75 m), so a jump never opens a way the 2.5D zones close.
const JUMP_HEIGHT := 0.65
const JUMP_CUT := 0.45        # letting go while rising keeps this share of the rising speed
const COYOTE := 0.12          # can still jump this long after walking off an edge (s)
const JUMP_BUFFER := 0.15     # a press this long before landing jumps on landing (s)
const AIR_CONTROL := 0.4      # share of the ground acceleration in the air
const INTERACT_REACH := Player.INTERACT_REACH / PX_PER_M   # ~1.3 m, as in the 2.5D
const INTERACT_CONE := 0.3    # what is in front of her: cos of about 70°
const INTERACT_CLOSE := 0.6   # this close, in front or not
const FADE_NEAR := 1.4        # the camera closer than this to her head (m): she fades…
const FADE_GONE := 0.6        # …to FADE_MAX at this
const FADE_MAX := 0.85
const FALL_LIMIT := -50.0     # fell out of the world: back to where she last stood

## Her 3D model (an imported glb). None: the stand-in capsule of the scene.
@export var model_scene: PackedScene
## Which of its clips play idle, walk, run, jump… (see AnimSet).
@export var anim_set: AnimSet

var busy := false   # during an interaction or a scene: no moving
var animator: CharacterAnimator

var _gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _last_ground := Vector3.ZERO
var _coyote := 0.0
var _jump_buffer := 0.0
var _rising := false          # going up from a jump, the button still held
var _was_on_floor := true
var _fall_speed := 0.0
var _hinted: Interactable3D
var _meshes: Array[GeometryInstance3D] = []
var _fade := 0.0

@onready var pivot: CameraPivot = $CameraPivot
@onready var model: Node3D = $Model


func _ready() -> void:
	add_to_group(&"player3d")
	Input3D.setup()
	collision_layer = Layers3D.PLAYER
	collision_mask = Layers3D.WORLD | Layers3D.WATER | Layers3D.DINOS   # she bumps into dinos
	floor_snap_length = FLOOR_SNAP
	floor_max_angle = deg_to_rad(46.0)
	_last_ground = global_position
	_set_up_model()


func can_move() -> bool:
	return not busy and not Dialogue.active and not Router.is_busy()


## B held (the touch button, Escape) or Shift: she runs. Same rule as the 2.5D Player.
func running() -> bool:
	return Input.is_action_pressed(&"run") or Input.is_action_pressed(&"cancel")


func top_speed() -> float:
	var boots := Game.item_count("bottes") > 0
	if running():   # the 2.5D's run: ~5 m/s, ~5.85 in the boots
		return SPEED * (Player.BOOTS_RUN_SPEED if boots else Player.RUN_SPEED)
	return WALK * (Player.BOOTS_SPEED if boots else 1.0)


## Where she looks, on the ground.
func facing() -> Vector3:
	return model.global_basis.z.slide(Vector3.UP).normalized()


## Puts her there (arrival, a teleport) and the camera with her.
func place_at(where: Vector3, facing_yaw := NAN) -> void:
	global_position = where
	velocity = Vector3.ZERO
	_last_ground = where
	if not is_nan(facing_yaw):
		model.rotation.y = facing_yaw
	reset_physics_interpolation()
	pivot.snap()


## The closest Interactable3D she could use: in reach, in front of her (or right against her).
func nearest_interactable() -> Interactable3D:
	var best: Interactable3D = null
	var best_d := INF
	var ahead := facing()
	for node in get_tree().get_nodes_in_group(&"interactable3d"):
		var it := node as Interactable3D
		var to := (it.global_position - global_position).slide(Vector3.UP)
		var d := to.length()
		if d > (it.reach if it.reach > 0.0 else INTERACT_REACH) or d >= best_d:
			continue
		if d > INTERACT_CLOSE and ahead.dot(to / d) < INTERACT_CONE:
			continue
		best = it
		best_d = d
	return best


func _unhandled_input(event: InputEvent) -> void:
	if not can_move():
		return
	if event.is_action_pressed(Input3D.JUMP):
		get_viewport().set_input_as_handled()
		_jump_buffer = JUMP_BUFFER
	elif event.is_action_pressed(&"interact") and is_on_floor():
		var it := nearest_interactable()
		if it:
			get_viewport().set_input_as_handled()
			_use(it)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if can_move():
		input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_coyote = COYOTE if is_on_floor() else maxf(_coyote - delta, 0.0)
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	var wish := pivot.flat_direction(input) * top_speed()
	var accel := ACCEL if is_on_floor() else ACCEL * AIR_CONTROL
	var flat := Vector3(velocity.x, 0.0, velocity.z).move_toward(wish, accel * delta)
	velocity = Vector3(flat.x, velocity.y, flat.z)
	if _jump_buffer > 0.0 and _coyote > 0.0 and can_move():
		_jump()
	elif not is_on_floor():
		velocity.y -= _gravity * delta
		if _rising and (velocity.y <= 0.0 or not Input.is_action_pressed(Input3D.JUMP)):
			if velocity.y > 0.0:
				velocity.y *= JUMP_CUT
			_rising = false
		_fall_speed = maxf(_fall_speed, -velocity.y)
	elif flat.length() > 0.01:
		_step_up(flat * delta)
	move_and_slide()
	if is_on_floor():
		if not _was_on_floor:
			landed.emit(_fall_speed)
		_fall_speed = 0.0
		_rising = false
		_last_ground = global_position
	elif global_position.y < FALL_LIMIT:
		place_at(_last_ground)
	_was_on_floor = is_on_floor()
	_face(flat, delta)
	_update_hint()


func _process(_delta: float) -> void:
	var head := global_position + Vector3(0.0, HEIGHT * 0.8, 0.0)
	var d := pivot.camera.global_position.distance_to(head)
	var fade := clampf(inverse_lerp(FADE_NEAR, FADE_GONE, d), 0.0, 1.0) * FADE_MAX
	if not is_equal_approx(fade, _fade):
		_fade = fade
		for mesh in _meshes:
			mesh.transparency = fade


func _jump() -> void:
	velocity.y = sqrt(2.0 * _gravity * JUMP_HEIGHT)
	_coyote = 0.0
	_jump_buffer = 0.0
	_rising = true
	jumped.emit()
	if animator:
		animator.jump()


func _use(it: Interactable3D) -> void:
	busy = true
	velocity = Vector3(0.0, velocity.y, 0.0)
	var to := it.global_position - global_position
	model.rotation.y = atan2(to.x, to.z)
	if animator:
		animator.act(&"interact")
	interacted.emit(it)
	await it.interact(self)
	busy = false


func _update_hint() -> void:
	var it := nearest_interactable() if can_move() and is_on_floor() else null
	if it == _hinted:
		return
	if is_instance_valid(_hinted):
		_hinted.set_hinted(false)
	_hinted = it
	if it:
		it.set_hinted(true)


## A body (a capsule) stops against a step's edge as against a wall. If what is in front is a step
## (free above it, a floor on top), she is lifted onto it before moving on.
func _step_up(motion: Vector3) -> void:
	var hit := KinematicCollision3D.new()
	if not test_move(global_transform, motion, hit) or hit.get_normal().angle_to(Vector3.UP) <= floor_max_angle:
		return
	var lift := Vector3(0.0, STEP_MAX, 0.0)
	var raised := global_transform
	if test_move(raised, lift):
		return   # a ceiling
	raised.origin += lift
	# looked for a body's width ahead, so the round bottom ends up over the step, not on its edge
	var probe := motion.normalized() * maxf(motion.length(), RADIUS + 0.05)
	if test_move(raised, probe):
		return   # still blocked up there: a wall
	raised.origin += probe
	var floor_hit := KinematicCollision3D.new()
	if not test_move(raised, -lift, floor_hit) or floor_hit.get_normal().angle_to(Vector3.UP) > floor_max_angle:
		return   # nothing to stand on, or too steep
	global_position.y = raised.origin.y - floor_hit.get_travel().length()


func _face(flat: Vector3, delta: float) -> void:
	if flat.length() < 0.2:
		return
	var want := atan2(flat.x, flat.z)
	model.rotation.y = lerp_angle(model.rotation.y, want, 1.0 - exp(-TURN * delta))


## Her model in place of the stand-in, with its animator; the meshes that fade near the camera.
func _set_up_model() -> void:
	if model_scene:
		for child in model.get_children():
			model.remove_child(child)
			child.free()
		var shown := model_scene.instantiate() as Node3D
		model.add_child(shown)
		animator = CharacterAnimator.new()
		animator.name = "Animator"
		animator.body = self
		animator.model = shown
		animator.anim_set = anim_set
		add_child(animator)
	_meshes.clear()
	for node in model.find_children("*", "GeometryInstance3D", true, false):
		_meshes.append(node as GeometryInstance3D)
