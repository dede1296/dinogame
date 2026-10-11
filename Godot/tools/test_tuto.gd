extends SceneTree
## Le tutoriel des commandes (11/10) : il s'ouvre tout seul au début de la partie quand Chloé est
## libre, montre les touches puis les boutons de la manette dès qu'on la touche, se feuillette à la
## souris, au clavier ou à la manette, ne s'ouvre qu'une fois et se rouvre depuis le menu.
##   godot --path Godot --script res://tools/test_tuto.gd -- out=<dossier>
## Écrit PASS / FAIL, enregistre les captures, sort en 1 au moindre échec. Il faut une fenêtre.

const WORLD := "res://world/world.tscn"
const CAPTION := "Tutoriel des commandes : ouverture au début, touches puis manette, pages, une seule fois, rejouable"
const BUTTON_A := 0
const BUTTON_B := 1
const SHOULDER_R := 10
const DPAD_RIGHT := 14

var _out := "user://test_tuto"
var _failed := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_tuto.json")
	var game := root.get_node("Game")
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	game.call("set_flag", &"prologue_done")
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	var game := root.get_node("Game")
	await _wait(1.0)
	_check("avant : le tutoriel n'a pas encore été vu", not game.call("flag", &"tuto_commandes"))
	# (Chloé doit être libre 1,5 s : on attend, au plus 40 s, que les premières scènes du Port finissent)
	var waited := 0.0
	while _tutorial() == null and waited < 40.0:
		await _wait(0.5)
		waited += 0.5
		if int(waited * 2) % 10 == 0:
			var player = current_scene.get("player")
			print("   t=%.0f s : peut bouger %s ; dialogue %s ; pause %s" % [waited, player.call("can_move") if player else "?",
				root.get_node("Dialogue").get("active"), paused])
	print("   le tutoriel s'est ouvert après %.1f s" % waited)
	var tuto := _tutorial()
	_check("il s'ouvre tout seul quand Chloé est libre", tuto != null)
	if tuto == null:
		quit(1)
		return
	_check("le jeu attend pendant qu'on le lit", paused)
	_check("page 1 sur 3", tuto.get("_page") == 0)
	await _shot("tuto_00_clavier_page1")

	# la manette : les images changent d'elles-mêmes
	var keys := _icons(tuto)
	_tap(DPAD_RIGHT)   # (un bouton de manette : le joueur la tient)
	await _wait(0.5)
	var pad := _icons(tuto)
	_check("la page change de ◀ ▶ : page 2", tuto.get("_page") == 1, str(tuto.get("_page")))
	_check("une touche de manette a remplacé le clavier", keys != pad, "%d images -> %d" % [keys.size(), pad.size()])
	_check("la page dit « À la manette »", _has_text(tuto, "À la manette"))
	await _shot("tuto_01_manette_page2")

	# RB : page 3 ; A sur « C'est parti ! » : fini
	_tap(SHOULDER_R)
	await _wait(0.4)
	_check("RB : page 3", tuto.get("_page") == 2)
	_check("le dernier bouton dit « C'est parti ! »", _has_text(tuto, "C'est parti !"))
	await _shot("tuto_02_manette_page3")
	_tap(BUTTON_A)
	await _wait(0.6)
	_check("A : il se ferme", not is_instance_valid(tuto) or tuto.is_queued_for_deletion())
	_check("le jeu repart", not paused)
	_check("le drapeau est posé : on ne le reverra pas", game.call("flag", &"tuto_commandes"))

	# il ne revient pas
	await _wait(3.0)
	_check("il ne se rouvre pas tout seul", _tutorial() == null)

	# on peut le rejouer ; B le passe
	load("res://ui/controls_tutorial.gd").call("open", root)
	await _wait(0.6)
	var again := _tutorial()
	_check("rejouable depuis le menu", again != null)
	if again:
		_tap(BUTTON_B)
		await _wait(0.5)
		_check("B : on le passe", not is_instance_valid(again) or again.is_queued_for_deletion())
	_check("le jeu repart", not paused)

	banner.queue_free()
	print("TEST tutoriel : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


func _tutorial() -> Node:
	for parent in [root, current_scene]:
		for node in parent.get_children():
			if node.get_script() != null and node.has_method("_wait_until_free") and node.get("_panel") != null \
					and not node.is_queued_for_deletion():
				return node
	return null


## Les chemins des images dessinées sur la page (pour voir qu'elles changent).
func _icons(tuto: Node) -> Array:
	var paths := []
	for tex in tuto.find_children("*", "TextureRect", true, false):
		if (tex as TextureRect).texture:
			paths.append((tex as TextureRect).texture.resource_path)
	return paths


func _has_text(node: Node, text: String) -> bool:
	for label in node.find_children("*", "Label", true, false):
		if text in (label as Label).text:
			return true
	for button in node.find_children("*", "Button", true, false):
		if text in (button as Button).text:
			return true
	return false


func _tap(button: int) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
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
