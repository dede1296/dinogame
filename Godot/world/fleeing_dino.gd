class_name FleeingDino
extends DinoNpc
## A dino that runs away from Chloé along `waypoints` (tiles): when she comes near, it dashes
## to the next one, stops, looks back and mocks her. At the last one it slips into its hiding
## place and sets `arrived_flag`. Where it stands is kept in the story flag `stage_flag`, so
## the chase resumes after a reload. Until `appear_flag` is set, it is not there at all.

const NEAR := 150.0   # px: closer than this, it runs
const SPEED := 230.0

@export var waypoints: PackedVector2Array = []
@export var stage_flag: StringName
@export var arrived_flag: StringName
@export var appear_flag: StringName

var _running := false


func _ready() -> void:
	super()
	if is_queued_for_deletion() or waypoints.is_empty():
		return
	position = waypoints[mini(_stage(), waypoints.size() - 1)] * 48.0
	if appear_flag != &"" and not Game.flag(appear_flag):
		_absent(true)
		Game.flag_changed.connect(_on_flag_changed)


func _on_flag_changed(id: StringName, _value: Variant) -> void:
	if id == appear_flag:
		_absent(false)


func _absent(on: bool) -> void:
	visible = not on
	collision_layer = 0 if on else 1
	set_physics_process(not on)


func _stage() -> int:
	return int(Game.flag(stage_flag)) if stage_flag != &"" else 0


func _physics_process(_delta: float) -> void:
	if _running or waypoints.is_empty():
		return
	var player := get_tree().get_first_node_in_group(&"player") as Player
	# (Not during a scene: the story moves it then.)
	if player and not player.busy and player.global_position.distance_to(global_position) < NEAR:
		_run_on()


func _run_on() -> void:
	_running = true
	var next := _stage() + 1
	cry(&"attaque")
	if next >= waypoints.size():
		# Home: into the hiding place.
		Game.set_flag(arrived_flag)
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.4)
		await t.finished
		queue_free()
		return
	Game.set_flag(stage_flag, next)
	await walk_to(waypoints[next] * 48.0, SPEED)
	# It turns round, pleased with itself.
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player:
		sprite.flip_h = player.global_position.x < global_position.x
	await get_tree().create_timer(0.35).timeout
	cry(&"neutre")
	var view := get_tree().get_first_node_in_group(&"world_view") as WorldView
	if view:
		view.emote(self, "♪" if randf() < 0.5 else "!")
	_running = false
