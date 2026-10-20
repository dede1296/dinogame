class_name Unstick
## « Se débloquer » (the game's menu, docs/mecaniques.md « Se débloquer ») : when a scene went wrong
## and Chloé is stuck (a line that no longer answers, Chloé held after a scene, the screen left dark),
## the game is put back in a sane state:
## 1. release_all: every line, question and letter closes; the scenes playing are let go (their lines
##    skipped while they end, at most Scenes.SKIP_MAX_S), those waiting are dropped; the screen comes
##    back, the game runs again, Chloé and her dino are free and seen, the camera is on her;
## 2. the zone is set up again where she stands (its people and things as the story's flags say: what a
##    scene hid is back, what it brought on is gone), or at its entry when that spot is not safe;
## 3. the zone's scene and the time of day's play again if they are due (each checks its flags: what
##    was played is not played twice, what was missed plays).

const DONE := "Chloé est libre. Si une scène n'était pas finie, elle reprendra."

## A run is under way (a second press waits for nothing).
static var running := false


static func run(tree: SceneTree) -> void:
	if running or tree == null:
		return
	running = true
	var w := tree.current_scene
	release_all(tree)
	_hold_player(w, true)
	await let_go(tree)
	if is_instance_valid(w) and _is_world(w):
		_hold_player(w, false)
		rebuild(w)
	running = false
	Toast.say(tree, DONE)


## The same, from a scenario of tools/capture.gd (« static »: no tree to pass).
static func run_now() -> void:
	await run(Engine.get_main_loop() as SceneTree)


## Step 1 (no zone needed: the tests call it alone).
static func release_all(tree: SceneTree) -> void:
	Dialogue.abort()
	Dialogue.skip_lines = true
	Scenes.reset()
	Router.clear()
	if not _in_battle(tree.current_scene):
		tree.paused = false
	var w := tree.current_scene
	if _is_world(w):
		w.set(&"_changing_zone", false)
		_free_player(w)


## The scenes let go end (their lines skipped), at most Scenes.SKIP_MAX_S; then lines show again.
static func let_go(tree: SceneTree) -> void:
	while Scenes.stale_alive():
		await tree.process_frame
	Dialogue.skip_lines = false
	Dialogue.abort()   # (a question a scene let go asked as it ended)
	Router.clear()     # (a fade it started)
	Scenes.forget_stale()


## Steps 2 and 3: the zone again, where Chloé stands if it is safe, else at its entry; then its scenes.
static func rebuild(w: Node) -> void:
	var zone: StringName = Game.region_id
	var at := safe_spot(w)
	Doorway.settle()
	w.call(&"_enter_zone", zone, &"Depart", at, false)
	_free_player(w)
	Story.on_zone_entered(zone)
	Story.on_phase_changed(zone)


## Where Chloé can be put back: where she stands (in the air, the last safe place flown over), unless it
## is out of the zone, in water she cannot swim, on lava without her dino of fire, or inside something
## solid; then Vector2.INF (the zone's entry).
static func safe_spot(w: Node) -> Vector2:
	var player = w.get(&"player")
	var region = w.get(&"region")
	if player == null or region == null:
		return Vector2.INF
	var at: Vector2 = player.save_position()
	if not (region.bounds() as Rect2).has_point(at):
		return Vector2.INF
	if region.surface_at(at) == &"water" and not player.is_swimming() and not player.get(&"diving"):
		return Vector2.INF
	if Lava.at(region, at) and not player.is_on_lava():
		return Vector2.INF
	if _inside_solid(w, at):
		return Vector2.INF
	return at


static func _inside_solid(w: Node2D, at: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = at
	query.collision_mask = 1
	for hit: Dictionary in w.get_world_2d().direct_space_state.intersect_point(query, 8):
		var body := hit.get("collider") as Node
		if body and not body.is_in_group(&"npc") and not body.is_in_group(&"dino_actor") and not body.is_in_group(&"interactable"):
			return true   # (a wall, a rock: not someone a scene left there)
	return false


## Chloé and her dino free, seen, on their feet; the camera on her (Story.lock(false)).
static func _free_player(w: Node) -> void:
	Story.lock(false)
	for who in [w.get(&"player"), w.get(&"companion")]:
		if who is CanvasItem and is_instance_valid(who):
			(who as CanvasItem).visible = true
			(who as CanvasItem).modulate.a = 1.0
	var player = w.get(&"player")
	if player:
		player.call(&"cancel_goal")
		player.set(&"velocity", Vector2.ZERO)


## While the scenes let go end, Chloé stays where she is.
static func _hold_player(w: Node, on: bool) -> void:
	var player = w.get(&"player") if is_instance_valid(w) else null
	if player:
		player.set(&"busy", on)


static func _is_world(w: Node) -> bool:
	return w != null and w.has_method(&"_enter_zone") and w.get(&"player") != null


static func _in_battle(w: Node) -> bool:
	if w == null:
		return false
	for child in w.get_children():
		if child.has_signal(&"_action_chosen") or (child.get_script() != null and child.get_script().resource_path.ends_with("battle_scene.gd")):
			return true
	return false
