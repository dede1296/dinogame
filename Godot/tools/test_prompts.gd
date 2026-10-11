extends SceneTree
## Les icônes de touches (11/10) : l'invite d'interaction flotte au-dessus de ce que Chloé peut
## utiliser, montre la touche du clavier puis, dès qu'on touche la manette, le bouton de sa famille ;
## et elle suit les touches redéfinies.
##   godot --path Godot --script res://tools/test_prompts.gd -- out=<dossier>
## Écrit PASS / FAIL, enregistre les captures, sort en 1 au moindre échec. Il faut une fenêtre.

const WORLD := "res://world/world.tscn"
const CAPTION := "Icônes : invite d'interaction (clavier puis manette Xbox / PlayStation), touches redéfinies suivies"

var _out := "user://test_prompts"
var _failed := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_prompts.json")
	var game := root.get_node("Game")
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	game.call("set_flag", &"prologue_done")
	game.call("set_flag", &"tuto_commandes")   # (le tutoriel de début n'est pas l'objet de ce test)
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	await create_timer(1.5).timeout
	var world := current_scene
	var prompts := root.get_node("Prompts")
	var player: Node2D = world.get("player")
	var prompt: Control = _find_prompt(world)
	_check("l'invite d'interaction est dans le HUD", prompt != null)
	if prompt == null:
		quit(1)
		return

	# 1. un objet utilisable : on se place à côté
	var target: Node2D = null
	for node in get_nodes_in_group(&"interactable"):
		if node is Node2D and (node as Node2D).visible:
			target = node
			break
	_check("la prairie a quelque chose à utiliser", target != null)
	player.call("teleport", target.global_position + Vector2(0, 28))
	await create_timer(0.8).timeout
	_check("à portée, l'invite apparaît", prompt.get("_plate").modulate.a > 0.5)
	var icon: TextureRect = prompt.get("_icon")
	_check("au clavier : l'icône est une touche", icon.texture != null and "/key/" in icon.texture.resource_path,
		str(icon.texture.resource_path if icon.texture else "aucune"))
	await _shot("prompts_00_clavier")

	# 2. on touche la manette : le bouton prend la place
	_press_pad(0, 0)   # manette 0, bouton A (JOY_BUTTON_A)
	await create_timer(0.6).timeout
	_check("à la manette : l'icône est un bouton", icon.texture != null and "/xbox/" in icon.texture.resource_path,
		str(icon.texture.resource_path if icon.texture else "aucune"))
	await _shot("prompts_01_manette_xbox")

	# 3. une manette PlayStation : le nom suit
	_check("« DualSense » est reconnue comme PlayStation", prompts.call("pad_family_of_name", "PS5 Controller") == &"ps5")
	_check("« Nintendo Switch Pro » est reconnue comme Switch",
		prompts.call("pad_family_of_name", "Nintendo Switch Pro Controller") == &"switch")
	_check("une manette inconnue est une Xbox", prompts.call("pad_family_of_name", "Controller (XBOX 360 For Windows)") == &"xbox")
	prompts.set("family", &"ps5")
	prompts.emit_signal("changed")
	await create_timer(0.3).timeout
	_check("PlayStation : A devient la croix", icon.texture != null and icon.texture.resource_path.ends_with("/ps5/cross.png"),
		str(icon.texture.resource_path if icon.texture else "aucune"))
	await _shot("prompts_02_playstation")

	# 4. la touche redéfinie est suivie
	prompts.set("family", &"key")
	var before: String = prompts.call("texture", &"interact").resource_path
	var event := InputEventKey.new()
	event.physical_keycode = KEY_G
	var old: Array = InputMap.action_get_events(&"interact")
	InputMap.action_erase_events(&"interact")
	InputMap.action_add_event(&"interact", event)
	var after: Texture2D = prompts.call("texture", &"interact")
	_check("une touche redéfinie change l'icône", after != null and after.resource_path != before,
		"%s -> %s" % [before.get_file(), after.resource_path.get_file() if after else "aucune"])
	InputMap.action_erase_events(&"interact")
	for e in old:
		InputMap.action_add_event(&"interact", e)

	# 4 bis. la page Commandes des Paramètres montre de vraies icônes
	prompts.set("family", &"key")
	var menu: Node = load("res://ui/settings_menu.gd").call("open", world, true)
	await create_timer(0.4).timeout
	menu.call("_show", "commandes")
	await create_timer(0.5).timeout
	var icons := 0
	for tex in menu.find_children("*", "TextureRect", true, false):
		if (tex as TextureRect).texture and "/prompts/" in (tex as TextureRect).texture.resource_path:
			icons += 1
	_check("la page Commandes dessine des touches et des boutons", icons >= 8, "%d icônes" % icons)
	await _shot("prompts_03_page_commandes")
	menu.call("_close")
	await create_timer(0.4).timeout

	# 5. loin de tout, pas d'invite
	var empty := Vector2.INF
	for x in range(100, 1400, 100):
		for y in range(100, 1000, 100):
			player.call("teleport", Vector2(x, y))
			await process_frame
			if player.call("nearest_interactable") == null:
				empty = Vector2(x, y)
				break
		if empty != Vector2.INF:
			break
	_check("la zone a un endroit où rien n'est à portée", empty != Vector2.INF)
	await create_timer(0.8).timeout
	_check("loin de tout, l'invite s'éteint", prompt.get("_plate").modulate.a < 0.05)

	banner.queue_free()
	print("TEST icônes : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


func _find_prompt(node: Node) -> Control:
	for child in node.find_children("*", "Control", true, false):
		if child.get_script() != null and child.has_method("_refresh") and child.get("_plate") != null:
			return child
	return null


func _press_pad(device: int, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, name])
