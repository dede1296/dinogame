class_name StoryWorld3D
extends Node
## The exploration screen of the 3D version as the story's scenes expect it (docs/migration-3d.md,
## phase 5): the stand-in for world.gd. `Story.world()` gives this instead of world.gd once the 3D
## version plays, with the members the scenes read — `player`, `companion`, `region`, `_battle()` —
## and it owns the zone's pixel ↔ metre conversion (ZoneSource) and the moves (Stage3D).
##
## The two versions answer the same questions, each its own way (the common « world » of the story):
##   is_3d()                 true here, absent from world.gd
##   player / companion      Chloé and her lead dino, as StoryActor3D handles (pixel positions)
##   actor(node_name)        a character or a dino of the zone, by node name
##   region                  the 2.5D zone's data (the 3D zone is built from the very same one)
##   to_3d(px) / to_px(m)    the conversion, through ZoneSource.to_3d (never another scale)
##   lock_player(on)         takes the controls away during a scene, and the camera back after
##   _battle(foe, rules)     a battle of the game (Encounters3D)
##   moves                   the moves of this version (Stage3D)
##
## It is built by itself the first time a scene asks for it, under the Zone3D, so nothing of the 3D
## version needs to know the story exists.

const PX := ZoneSource.PX
## The group Story looks it up by.
const GROUP := &"story_world"

## The 3D zone it plays in.
var zone: Node3D
## The moves of the 3D version (Stage's, on 3D actors).
var moves: Stage3D
## Where the handles and the 2D-only characters a scene brings along live.
var actors: Node2D

var _handles := {}   # 3D actor → StoryActor3D


## Chloé, as the scenes hold her.
var player: StoryActor3D:
	get: return handle(zone.get("player")) if is_instance_valid(zone) else null

## Her lead dino walking with her, null when she has none in 3D.
var companion: StoryActor3D:
	get:
		var session: Node = zone.get("session") if is_instance_valid(zone) else null
		var lead: Node3D = session.get("companion") if session else null
		return handle(lead) if lead else null

## The 2.5D zone the 3D one was built from: its tiles, heights, props and habitats.
var region: Region:
	get:
		var src := source()
		return src.region if src else null


func _init() -> void:
	name = "StoryWorld"


func _ready() -> void:
	add_to_group(GROUP)
	actors = Node2D.new()
	actors.name = "Actors"
	add_child(actors)
	moves = Stage3D.new()
	moves.world = self


## The 3D version is the one playing (world.gd has no such method: that is how Story tells them apart).
func is_3d() -> bool:
	return true


## The zone's data source (ZoneSource), null before the zone is built.
func source() -> ZoneSource:
	return zone.get("source") if is_instance_valid(zone) else null


## A 2.5D position (pixels of the zone) in metres, on the ground — the one conversion (ZoneSource)
## for the place; the height is the ground the zone is drawn with (ZoneTerrain.height_at), not the
## 2.5D's: on a remodelled relief the two are metres apart.
func to_3d(px: Vector2) -> Vector3:
	var src := source()
	if src == null:
		return Vector3.ZERO
	var at := src.to_3d(px)
	var ground := zone.get("terrain") as ZoneTerrain
	if ground:
		at.y = ground.height_at(at.x, at.z)
	return at


## A place of the 3D zone (metres) back in the 2.5D's pixels.
func to_px(at: Vector3) -> Vector2:
	var src := source()
	return Vector2(at.x, at.z) / src.scale * PX if src else Vector2.ZERO


## The handle the scenes hold an actor by (the same one every time).
func handle(of_node) -> StoryActor3D:
	if of_node == null or not is_instance_valid(of_node) or not of_node is Node3D:
		return null
	var known = _handles.get(of_node)
	if known != null and is_instance_valid(known):
		return known
	var made := StoryActor3D.wrap(of_node, self)
	_handles[of_node] = made
	actors.add_child(made)
	return made


## A character or a dino of the zone, by node name (null when there is none): the 3D actors first,
## then the 2D-only people a scene brought along (Story.stranger).
func actor(node_name: String):
	if is_instance_valid(zone):
		var found := zone.get_node_or_null(NodePath(node_name)) as Node3D
		if found:
			return handle(found)
		for group: StringName in [&"dino3d", &"npc3d"]:
			for node in get_tree().get_nodes_in_group(group):
				if node.name == node_name:
					return handle(node as Node3D)
	return actors.get_node_or_null(NodePath(node_name))


## Puts a character only a scene needs into the zone (Story.stranger). In 3D it has no model yet:
## it stands where the scene puts it, unseen, and its moves do nothing rather than fail.
func add_actor(node: Node) -> void:
	actors.add_child(node)


## Takes the controls away from Chloé during a scene, and gives them back with the camera (world.gd).
func lock_player(on: bool) -> void:
	var chloe: Node3D = zone.get("player") if is_instance_valid(zone) else null
	if chloe:
		chloe.set(&"busy", on)
		chloe.set(&"velocity", Vector3.ZERO)
	if not on and moves:   # the scene is over: the camera comes back to her (Stage.look_at)
		moves.look_back(0.0)


## Chloé is on her feet for a scene (no mount in the 3D version yet).
func dismount() -> void:
	pass


## A battle of the game against `foe` (Story.duel, a scene's own battle): the 3D version's, which
## pauses the zone as world.gd does. "" when no battle can run.
func _battle(foe: Dino, rules := {}) -> String:
	var session: Node = zone.get("session") if is_instance_valid(zone) else null
	var encounters: Node = session.get("encounters") if session else null
	if encounters == null:
		return ""
	return await encounters.call(&"battle", foe, rules)


## An actor walks to a point (world pixels), `speed` in pixels a second (0: its own walking speed).
## Awaitable. Only a 3D actor really walks; a 2D-only one is simply put there.
func walk_actor(who, target: Vector2, speed := 0.0) -> void:
	var node := moves.node_of(who)
	if node == null:
		if who is Node2D:
			(who as Node2D).global_position = target
		return
	if not node.has_method(&"go_to"):
		return
	var pace := speed / PX if speed > 0.0 else _own_walk(node)
	node.call(&"go_to", to_3d(target), maxf(pace, 0.4))
	while is_instance_valid(node) and not bool(node.call(&"arrived")):
		await get_tree().process_frame


## An actor's own walking speed (m/s): a dino's, else Chloé's.
func _own_walk(node: Node3D) -> float:
	return float(node.call(&"walk_speed")) if node.has_method(&"walk_speed") else Player3D.WALK
