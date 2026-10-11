extends SceneTree
## Le HUD à la souris (11/10) : au survol d'un bouton rond ou d'un portrait de l'équipe, une main,
## le bord qui s'allume, et une étiquette avec le nom et la touche (HudHint).
##   godot --path Godot --script res://tools/test_hud_souris.gd -- out=<dossier>
## Écrit PASS / FAIL, enregistre les captures, sort en 1 au moindre échec. Il faut une fenêtre.

const WORLD := "res://world/world.tscn"
const CAPTION := "HUD à la souris : main au survol, bord allumé, étiquette avec le nom et la touche"

var _out := "user://test_hud_souris"
var _failed := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_hud_souris.json")
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
	var hud: CanvasLayer = world.get("hud")
	var hint: Control = null
	for node in hud.get_children():
		if node.has_method("attach") and node.get("_plate") != null:   # (HudHint, par ses membres : ce script est compilé avant les autoloads)
			hint = node
	_check("l'étiquette de survol est dans le HUD", hint != null)
	if hint == null:
		quit(1)
		return
	var plate: Control = hint.get("_plate")
	var menu: Button = hud.get_node("MenuButton")
	var map: Button = hud.get_node("MapButton")
	_check("le bouton est une main au survol", menu.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND)
	_check("l'infobulle de Godot est remplacée", menu.tooltip_text == "")
	_check("le bord s'allume au survol", menu.has_theme_stylebox_override(&"hover"))

	# 1. le bouton Carte
	await _hover(map)
	_check("au survol, l'étiquette apparaît", plate.modulate.a > 0.9, "%.2f" % plate.modulate.a)
	_check("elle dit le nom", "Carte" in hint.get("_title").text, hint.get("_title").text)
	var icon: TextureRect = hint.get("_icon")
	_check("et la touche (M)", icon.texture != null and icon.texture.resource_path.ends_with("/m.png"),
		str(icon.texture.resource_path if icon.texture else "aucune"))
	var rect := plate.get_global_rect()
	_check("elle reste dans l'écran", get_root_rect().encloses(rect), str(rect))
	_check("elle ne cache pas le bouton", not rect.intersects(map.get_global_rect()))
	await _shot("hud_00_carte")

	# 2. on s'éloigne : elle s'éteint
	_move_mouse(Vector2(400, 700))
	await create_timer(0.5).timeout
	_check("la souris partie, l'étiquette s'éteint", plate.modulate.a < 0.05)

	# 3. un portrait de l'équipe : le nom du dino et l'aide
	var slot: Control = null
	for child in world.find_children("*", "Control", true, false):
		if child.get_script() != null and child.get("dino") != null and child.get("lead") != null:
			slot = child
			break
	_check("l'équipe a un portrait", slot != null)
	if slot:
		await _hover(slot)
		print("   portrait ", slot.get_global_rect(), " ; sous la souris : ", root.gui_get_hovered_control(), " ", root.gui_get_hovered_control().get_global_rect(), " parent ", root.gui_get_hovered_control().get_parent(), " ", root.gui_get_hovered_control().get_parent().get_parent())
		_check("le portrait donne le nom et le niveau", "Niv." in hint.get("_title").text, hint.get("_title").text)
		_check("et dit quoi faire", "menu" in hint.get("_detail").text, hint.get("_detail").text)
		await _shot("hud_01_portrait")
	_move_mouse(Vector2(400, 700))

	banner.queue_free()
	print("TEST HUD souris : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


func _hover(control: Control) -> void:
	_move_mouse(control.get_global_rect().get_center())
	await create_timer(0.9).timeout


func _move_mouse(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	Input.parse_input_event(event)


func get_root_rect() -> Rect2:
	return root.get_visible_rect()


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, name])
