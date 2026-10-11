extends SceneTree
## The computer version's controls (Greg, 11/10: the 2.5D is now aimed at the PC):
## no on-screen A / B buttons, Échap opens the game menu instead of making Chloé run,
## F11 switches to full screen, and the Paramètres pages speak of a computer.
##   godot --path Godot --script res://tools/test_pc_controls.gd -- out=<folder>
## Prints PASS / FAIL, saves screenshots, quits with 1 on any failure. A window is needed.

const WORLD := "res://world/world.tscn"
## Written on every picture of the run: what the whole test checks.
const CAPTION := "Commandes PC : pas de boutons tactiles, Échap ouvre le menu (et ne fait plus courir), F11 plein écran"

var _out := "user://test_pc_controls"
var _failed := 0
var _banner: CanvasLayer


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_pc_controls.json")   # never the player's save
	var game := root.get_node("Game")
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	game.call("set_flag", &"prologue_done")
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	_banner = ShotCaption.show_on(self, CAPTION)
	await create_timer(1.5).timeout
	var world := current_scene
	var screen := root.get_node("Screen")
	_check("the game knows it runs on a computer", screen.call("on_computer"), OS.get_name())

	# 1. the thumb controls belong to phones
	var touch := world.get_node_or_null("TouchControls")
	_check("no on-screen joystick or A / B buttons", touch != null and not touch.visible)
	await _shot("pc_00_jeu_sans_boutons")

	# 2. Échap no longer makes Chloé run (Shift, or the pad's B, still does)
	var player: Node2D = world.get("player")
	Input.action_press(&"cancel")
	await process_frame
	_check("Échap does not make her run", not player.call("running"))
	Input.action_release(&"cancel")
	Input.action_press(&"run")
	await process_frame
	_check("Maj makes her run", player.call("running"))
	Input.action_release(&"run")

	# 3. Échap opens the game menu
	_press_key(KEY_ESCAPE)
	await create_timer(0.6).timeout
	var menu := _menu()
	_check("Échap opens the game menu", menu != null)
	await _shot("pc_01_menu_par_echap")

	# 4. its Affichage page offers full screen, and Commandes drops the finger column
	if menu:
		menu.call("_show", "affichage")
		await create_timer(0.4).timeout
		_check("the Affichage page offers « Plein écran »", _has_text(menu, "Plein écran"))
		await _shot("pc_02_affichage_plein_ecran")
		menu.call("_show", "commandes")
		await create_timer(0.4).timeout
		_check("Commandes speaks of the keyboard, not of the phone",
			_has_text(menu, "Clavier, souris, manette") and not _has_text(menu, "Sur le téléphone"))
		await _shot("pc_03_commandes_ordinateur")
		menu.call("_close")
		await create_timer(0.4).timeout

	# 5. F11 switches to full screen and back
	var before: bool = screen.call("is_fullscreen")
	_press_key(KEY_F11)
	await create_timer(0.6).timeout
	_check("F11 goes full screen", screen.call("is_fullscreen") != before)
	await _shot("pc_04_plein_ecran")
	_press_key(KEY_F11)
	await create_timer(0.6).timeout
	_check("F11 again comes back to the window", screen.call("is_fullscreen") == before)

	_banner.queue_free()
	print("TEST commandes PC : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


## The game menu, if it is open (SettingsMenu adds itself to the root).
func _menu() -> Node:
	for node in root.get_children():
		if node.get_script() != null and node.has_method("_fullscreen_text"):
			return node
	return null


func _has_text(node: Node, text: String) -> bool:
	for label in node.find_children("*", "Label", true, false):
		if text in (label as Label).text:
			return true
	for button in node.find_children("*", "Button", true, false):
		if text in (button as Button).text:
			return true
	return false


func _press_key(keycode: Key) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = keycode
		key.keycode = keycode
		key.pressed = pressed
		Input.parse_input_event(key)


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


## A picture of the test, under the banner put up for the whole run.
func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, name])
