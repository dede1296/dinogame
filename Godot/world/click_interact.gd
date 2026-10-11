class_name ClickInteract
extends Node
## Le clic de la souris dans le monde (ordinateur) : un clic gauche sur quelque chose d'utilisable —
## une personne, un panneau, un objet à ramasser — envoie Chloé l'utiliser : tout de suite si elle
## est à portée, sinon elle y marche d'abord. Une main remplace la flèche au-dessus de ce qu'on peut
## ainsi utiliser. Les clics sur le HUD et les menus ne passent jamais ici (ils les gardent).
##
## On vise ce que l'on voit : le point de l'écran où se dessine la cible (ses pieds, un peu au-dessus),
## pas sa position au sol — un dino ou un PNJ se clique sur le corps.

const PICK_RADIUS_PX := 64.0       # how far from the click a target can be and still be picked
const BODY_HEIGHT_M := 0.9         # where on the body the click is aimed
const MIN_MOVE_PX := 1.0

var player: Player
var view: WorldView

var _over_target := false
var _mouse := Vector2(-1.0, -1.0)   # where the mouse was last seen (from its own events)


func _ready() -> void:
	set_process(Screen.on_computer())
	set_process_unhandled_input(Screen.on_computer())


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = (event as InputEventMouseMotion).position


func _process(_delta: float) -> void:
	var free := player != null and player.can_move() and not get_tree().paused
	var hover := free and get_viewport().gui_get_hovered_control() == null \
		and pick(_mouse) != null
	if hover != _over_target:
		_over_target = hover
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover else Input.CURSOR_ARROW)


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if player == null or not player.can_move() or get_tree().paused:
		return
	var target := pick(click.position)
	if target:
		get_viewport().set_input_as_handled()
		player.go_and_interact(target)


## What is usable under `at` (a point of the screen): the nearest one whose body is drawn close enough.
func pick(at: Vector2) -> Node2D:
	if view == null or view.camera == null:
		return null
	var best: Node2D = null
	var best_px := PICK_RADIUS_PX
	for node in get_tree().get_nodes_in_group(&"interactable"):
		var target := node as Node2D
		if target == null or not target.visible:
			continue
		var on_screen := screen_point(target)
		if on_screen == Vector2.INF:
			continue
		var gap := on_screen.distance_to(at)
		if gap < best_px:
			best_px = gap
			best = target
	return best


## Where `target`'s body is drawn on the screen (INF: behind the camera).
func screen_point(target: Node2D) -> Vector2:
	var body := view.heights.to_3d(target.global_position) + Vector3(0.0, BODY_HEIGHT_M, 0.0)
	if view.camera.is_position_behind(body):
		return Vector2.INF
	return view.camera.unproject_position(body)


func _exit_tree() -> void:
	if _over_target:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
