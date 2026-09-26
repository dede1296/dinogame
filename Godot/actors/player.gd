class_name Player
extends CharacterBody2D
## Chloé: analog top-down movement (keyboard, gamepad or touch joystick), walk animation,
## footsteps by ground type, interaction with what is in front of her.

signal stepped(surface: StringName)

const SPEED := 165.0
const ACCEL := 1500.0
const STEP_DISTANCE := 38.0
const INTERACT_REACH := 62.0
const TRAIL_SPACING := 6.0
const TRAIL_LENGTH := 48
const SHEET := preload("res://assets/art/characters/chloe.png")
const FOOTSTEPS: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/footstep00.ogg"), preload("res://assets/audio/footsteps/footstep01.ogg"),
	preload("res://assets/audio/footsteps/footstep02.ogg"), preload("res://assets/audio/footsteps/footstep03.ogg"),
	preload("res://assets/audio/footsteps/footstep04.ogg"), preload("res://assets/audio/footsteps/footstep05.ogg"),
]

## Asked for the ground type under a position (set by the world, from the region).
var surface_at: Callable
## Recent positions, oldest first: the companion walks in Chloé's footsteps.
var trail: PackedVector2Array = []
var facing := Vector2.DOWN
var busy := false   # during an interaction

@onready var sprite: AnimatedSprite2D = $Sprite

var _step_travel := 0.0


func _ready() -> void:
	Shadow.make(self, 44.0)
	sprite.sprite_frames = SheetFrames.character(SHEET, 9.0)
	sprite.play(&"idle_down")
	trail.append(global_position)


func can_move() -> bool:
	return not busy and not Dialogue.active and not Router.is_busy()


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if can_move():
		input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = velocity.move_toward(input * SPEED, ACCEL * delta)
	var before := global_position
	move_and_slide()
	var moved := global_position.distance_to(before)
	_animate(input)
	_track(moved)
	RenderingServer.global_shader_parameter_set(&"player_position", global_position)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and can_move():
		get_viewport().set_input_as_handled()
		_interact()


func _animate(input: Vector2) -> void:
	var speed := velocity.length()
	if input.length() > 0.1:
		facing = input
	var dir := SheetFrames.direction_name(facing)
	if speed > 12.0:
		sprite.play(StringName("walk_" + dir))
		sprite.speed_scale = clampf(speed / SPEED, 0.5, 1.2)
	else:
		sprite.play(StringName("idle_" + dir))


func _track(moved: float) -> void:
	if moved <= 0.01:
		return
	if global_position.distance_to(trail[trail.size() - 1]) >= TRAIL_SPACING:
		trail.append(global_position)
		if trail.size() > TRAIL_LENGTH:
			trail.remove_at(0)
	_step_travel += moved
	if _step_travel >= STEP_DISTANCE:
		_step_travel = 0.0
		var surface: StringName = surface_at.call(global_position) if surface_at.is_valid() else &"grass"
		# Softer, lower steps on grass; crisper on the dirt path.
		var on_path := surface == &"path"
		Audio.play_sfx(FOOTSTEPS.pick_random(), -8.0 if on_path else -13.0, 0.08)
		stepped.emit(surface)


## Interacts with the closest interactable in front of Chloé (group "interactable",
## method interact(player) which may be a coroutine).
func _interact() -> void:
	var best: Node2D = null
	var best_score := INF
	for node in get_tree().get_nodes_in_group(&"interactable"):
		var target := node as Node2D
		if target == null or not target.is_visible_in_tree():
			continue
		var to := target.global_position - global_position
		var dist := to.length()
		if dist > INTERACT_REACH + target.get_meta(&"reach_bonus", 0.0):
			continue
		# Prefer what Chloé faces.
		var score := dist - facing.normalized().dot(to.normalized()) * 30.0
		if score < best_score:
			best_score = score
			best = target
	if best == null:
		return
	busy = true
	velocity = Vector2.ZERO
	await best.interact(self)
	busy = false


func face_towards(point: Vector2) -> void:
	facing = (point - global_position).normalized()
	_animate(Vector2.ZERO)


## Places Chloé (spawn, loaded game) and resets the companion trail.
func teleport(pos: Vector2) -> void:
	global_position = pos
	reset_physics_interpolation()
	trail = [pos]
