extends SceneTree
## Le clic dans le monde (11/10) : un clic gauche sur quelque chose d'utilisable envoie Chloé
## l'utiliser — tout de suite à portée, après y avoir marché sinon — ; une touche de déplacement
## annule ; un clic dans le vide ne fait rien ; une main remplace la flèche au-dessus d'un objet.
##   godot --path Godot --script res://tools/test_clic.gd -- out=<dossier>
## Écrit PASS / FAIL, enregistre les captures, sort en 1 au moindre échec. Il faut une fenêtre.

const WORLD := "res://world/world.tscn"
const CAPTION := "Clic dans le monde : utiliser ce qu'on clique (à portée, ou en y marchant), annuler, main au survol"
const REACH := 62.0

var _out := "user://test_clic"
var _failed := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_clic.json")
	var game := root.get_node("Game")
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	game.call("set_flag", &"prologue_done")
	game.call("set_flag", &"tuto_commandes")
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	await _wait(1.5)
	var world := current_scene
	var player: Node2D = world.get("player")
	var clicks: Node = null
	for node in world.get_children():
		if node.has_method("screen_point") and node.has_method("pick"):
			clicks = node
	_check("le clic est branché sur le monde", clicks != null)
	if clicks == null:
		quit(1)
		return

	# 1. une cible : la première chose utilisable, visible, de la zone
	# (au milieu des choses utilisables : loin des bords, où la caméra ne peut plus suivre)
	var usable: Array[Node2D] = []
	var centre := Vector2.ZERO
	for node in get_nodes_in_group(&"interactable"):
		if node is Node2D and (node as Node2D).visible:
			usable.append(node)
			centre += (node as Node2D).global_position
	_check("la zone a quelque chose d'utilisable", not usable.is_empty())
	centre /= maxf(usable.size(), 1)
	player.call("teleport", centre)
	await _wait(3.0)   # (la caméra rattrape Chloé en glissant : il faut la laisser se poser)
	# la cible : à l'écran (marge de 140 px), hors de portée de Chloé, la plus proche
	var target: Node2D = null
	for node in usable:
		var p_screen: Vector2 = clicks.call("screen_point", node)
		var inside := p_screen != Vector2.INF and Rect2(140, 140, 1320, 620).has_point(p_screen)
		var gap: float = node.global_position.distance_to(player.global_position)
		if inside and gap > REACH + 20.0 and (target == null or gap < target.global_position.distance_to(player.global_position)):
			target = node
	_check("une cible à l'écran, hors de portée", target != null)
	if target == null:
		quit(1)
		return
	var start: Vector2 = player.global_position
	await _wait(0.6)
	var far: float = player.global_position.distance_to(target.global_position)
	_check("Chloé est hors de portée", far > REACH, "%.0f px" % far)

	# 2. la main au survol
	var at: Vector2 = clicks.call("screen_point", target)
	_check("la cible se projette à l'écran", at != Vector2.INF and get_root_rect().has_point(at), str(at))
	_move_mouse(at)
	await _wait(0.4)
	_check("on vise bien cette cible", clicks.call("pick", at) == target)
	_check("une main remplace la flèche au-dessus", clicks.get("_over_target") == true,
		"sous la souris : %s" % root.gui_get_hovered_control())
	await _shot("clic_00_survol")

	# 3. le clic : elle marche vers la cible, puis l'utilise
	_click(at)
	await _wait(0.5)
	var mid: float = player.global_position.distance_to(target.global_position)
	_check("après le clic, elle s'approche", mid < far - 10.0, "%.0f -> %.0f px" % [far, mid])
	await _shot("clic_01_marche")
	var used := false
	for i in 40:
		await _wait(0.2)
		if player.get("busy") or root.get_node("Dialogue").get("active"):
			used = true
			break
	_check("arrivée, elle l'utilise", used, "%.0f px de la cible" % player.global_position.distance_to(target.global_position))
	await _shot("clic_02_utilise")
	for i in 12:   # (on referme ce que l'objet a ouvert)
		Input.action_press(&"interact")
		await _wait(0.1)
		Input.action_release(&"interact")
		await _wait(0.7)
		if not player.get("busy") and not root.get_node("Dialogue").get("active"):
			break

	# 4. un clic dans le vide ne fait rien
	player.call("teleport", start)
	await _wait(0.6)
	var before: Vector2 = player.global_position
	_click(Vector2(60, 860))
	await _wait(0.8)
	_check("un clic dans le vide ne bouge pas Chloé", player.global_position.distance_to(before) < 4.0)

	# 5. une touche de déplacement annule la course vers la cible
	_click(at)
	await _wait(0.4)
	Input.action_press(&"move_down")
	await _wait(0.6)
	Input.action_release(&"move_down")
	var cancelled_at: Vector2 = player.global_position
	await _wait(0.8)
	_check("une touche de déplacement annule le clic", player.global_position.distance_to(cancelled_at) < 16.0,
		"%.1f px" % player.global_position.distance_to(cancelled_at))

	# 6. un clic sur un bouton du HUD reste au HUD
	var map_button: Button = world.get("hud").get_node("MapButton")
	player.call("teleport", target.global_position + Vector2(0, 30))
	await _wait(0.5)
	_click(map_button.get_global_rect().get_center())
	await _wait(0.8)
	_check("un clic sur le bouton Carte ouvre la carte (et pas l'objet derrière)", paused)

	banner.queue_free()
	print("TEST clic : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


func get_root_rect() -> Rect2:
	return root.get_visible_rect()


func _move_mouse(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	Input.parse_input_event(event)


func _click(at: Vector2) -> void:
	_move_mouse(at)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
	Input.flush_buffered_events()


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, name])
