class_name StoryActor3D
extends Node2D
## A 3D actor (Chloé, a dino, a person) as the story's scenes expect one (docs/migration-3d.md,
## phase 5): a Node2D whose `global_position` is where it stands in the 2.5D's pixels, so the
## choreographies of story/ — written in pixels, 2 483 calls — play unchanged over a 3D zone.
## StoryWorld3D keeps one handle per actor, so the same actor is always the same object (a move
## started on it can be stopped on it).
## It has no `sprite`: the moves that only work on a picture (Stage.sprite_of) find none and do
## nothing, as they must. In 3D the moves act on `node` instead (Stage3D).

const PX := ZoneSource.PX

## The actor itself in the 3D world (Player3D, Dinosaur3D…).
var node: Node3D
## The zone it stands in (StoryWorld3D), for the pixel ↔ metre conversion.
var world
## During a scene: no walking of its own (Story.lock sets it on Chloé, as world.gd does).
var busy := false:
	set(value):
		busy = value
		if is_instance_valid(node) and node.get(&"busy") != null:
			node.set(&"busy", value)
## The scenes zero it on Chloé when they take over; the 3D body has its own, in metres.
var velocity := Vector2.ZERO


## A handle on `of_node`, reading its place from `of_world` (a StoryWorld3D).
static func wrap(of_node: Node3D, of_world) -> StoryActor3D:
	var handle := StoryActor3D.new()
	handle.node = of_node
	handle.world = of_world
	handle.name = of_node.name + "Handle"
	handle.visible = false   # nothing of it is drawn: its 3D model is
	return handle


func _ready() -> void:
	_follow()


func _process(_delta: float) -> void:
	_follow()


## Turns to look at a point (world pixels) — the Npc and DinoNpc move the scenes call.
func face(point: Vector2) -> void:
	if world:
		world.moves.turn_to(self, point)


## The same, under Chloé's name (Player.face_towards).
func face_towards(point: Vector2) -> void:
	face(point)


## Its cry (attaque, neutre, degat, ko), heard from where it stands.
func cry(kind: StringName) -> void:
	if is_instance_valid(node) and node.has_method(&"cry"):
		node.call(&"cry", kind)


## Walks to a point (world pixels), at `speed` in pixels a second when given (the Npc and DinoNpc
## signatures both end with it). Awaitable: it comes back once it is there or cannot get there.
func walk_to(target: Vector2, arg1 = null, arg2 = null) -> void:
	var speed: float = 0.0
	for arg in [arg1, arg2]:
		if arg is float or arg is int:
			speed = float(arg)
	if world:
		await world.walk_actor(self, target, speed)


## Chloé's lead dino runs at a point, does its bit and comes back (Companion.perform_at). Awaitable.
func perform_at(point: Vector2) -> void:
	if world:
		await world.moves.lunge(self, point, 1.0, true)


## Chloé's lead dino jumps for joy (Companion.rejoice).
func rejoice() -> void:
	if world:
		world.moves.hop(self, 2, 10.0)
		cry(&"neutre")


## Where it stands in metres (its 3D place), Vector3.INF once it is gone.
func point_3d() -> Vector3:
	return node.global_position if is_instance_valid(node) else Vector3.INF


## Keeps its 2.5D place (pixels) on the 3D actor's, every frame.
func _follow() -> void:
	if not is_instance_valid(node) or world == null:
		return
	position = world.to_px(node.global_position)
