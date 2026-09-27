@tool
class_name StoryTrigger
extends Area2D
## An invisible circle on the ground that starts a story scene when Chloé walks into it
## (the Masque seen on the footbridge…): `event` is played by Story.run, like a StoryProp,
## but without pressing anything. It waits for `required_flag` (if any), and stays quiet once
## `once_flag` is set: the scene sets that flag when it has played. While Chloé is inside and
## cannot move yet (a dialogue, another scene, a zone change), it waits for her; after a
## scene, it waits for her to step out before it can play again.

## Radius of the circle, in tiles.
@export var radius := 3.0:
	set(value):
		radius = value
		_update_shape()
		queue_redraw()
@export var event: StringName
## Only once this story flag is set (empty: always).
@export var required_flag: StringName
## Never again once this story flag is set (empty: every time Chloé walks in).
@export var once_flag: StringName

const TILE := 48.0

var _shape: CollisionShape2D
var _inside: Player
var _running := false
## False after a scene played, until Chloé leaves the circle.
var _armed := true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # Chloé
	monitorable = false
	_update_shape()
	set_process(false)
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## The scene may play now: its flags allow it and nothing else is going on.
func is_ready_to_play() -> bool:
	if event == &"" or _running or not _armed:
		return false
	if required_flag != &"" and not Game.flag(required_flag):
		return false
	if once_flag != &"" and Game.flag(once_flag):
		return false
	return _inside != null and _inside.can_move()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and body is Player:
		_inside = body
		set_process(true)


func _on_body_exited(body: Node2D) -> void:
	if body == _inside:
		_inside = null
		_armed = true
		set_process(false)


## Checked each frame while Chloé stands inside (she may be busy when she walks in).
func _process(_delta: float) -> void:
	if is_ready_to_play():
		_play()


func _play() -> void:
	_running = true
	_armed = false
	_run_scene(event, self, _inside, _scene_done)


func _scene_done() -> void:
	_running = false


## Chloé stops, the scene plays, she is free again, then `done`. Static (and not awaited):
## it ends well even if the scene takes her to another zone (this trigger is then gone with
## its zone, and `done` with it).
static func _run_scene(scene: StringName, who: Node, player: Player, done: Callable) -> void:
	player.busy = true
	player.velocity = Vector2.ZERO
	await preload("res://story/story.gd").run(scene, who)
	if is_instance_valid(player):
		player.busy = false
	if done.is_valid():
		done.call()


func _update_shape() -> void:
	if not is_inside_tree():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		add_child(_shape, false, Node.INTERNAL_MODE_BACK)   # made here, never saved
	var circle := CircleShape2D.new()
	circle.radius = radius * TILE
	_shape.shape = circle


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, radius * TILE, Color(1.0, 0.75, 0.3, 0.18))
		draw_arc(Vector2.ZERO, radius * TILE, 0.0, TAU, 48, Color(1.0, 0.75, 0.3, 0.7), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-40, 5), "▶ %s" % event, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
