extends SceneTree
## La manette seule (11/10) : on joue sans clavier ni souris. Chaque écran se pilote avec de vrais
## événements de manette (croix, A, B, Start, Retour, gâchettes) : ce test envoie ces événements et
## regarde l'état du jeu.
##   godot --path Godot --script res://tools/test_manette.gd -- out=<dossier> [only=equipe|dex|carte|menu]
## Écrit PASS / FAIL, enregistre les captures, sort en 1 au moindre échec. Il faut une fenêtre.

const WORLD := "res://world/world.tscn"
const CAPTION := "Manette seule : équipe (changer de dino de tête), Dinodex, carte, menu — sans clavier ni souris"
const DPAD_LEFT := 13
const DPAD_RIGHT := 14
const DPAD_UP := 11
const DPAD_DOWN := 12
const BUTTON_A := 0
const BUTTON_B := 1
const BUTTON_BACK := 4
const BUTTON_START := 6
const SHOULDER_L := 9
const SHOULDER_R := 10

var _out := "user://test_manette"
var _only := ""
var _failed := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("only="):
			_only = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_manette.json")
	var game := root.get_node("Game")
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	game.call("set_flag", &"prologue_done")
	game.call("set_flag", &"tuto_commandes")   # (le tutoriel de début n'est pas l'objet de ce test)
	var party: Array = game.get("party")
	party.append(load("res://game/dino.gd").create(&"compsognathus", 5))
	party.append(load("res://game/dino.gd").create(&"psittacosaurus", 5))
	game.call("mark_caught", &"compsognathus")   # (le Dinodex ne montre « Mes dinos » que d'une espèce capturée)
	game.call("mark_caught", &"psittacosaurus")
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	await create_timer(1.5).timeout
	if _only in ["", "equipe"]:
		await _team()
	if _only in ["", "dex"]:
		await _dex()
	if _only in ["", "carte"]:
		await _map()
	if _only in ["", "menu"]:
		await _menu()
	if _only in ["", "boutique"]:
		await _shop()
	if _only in ["", "voyage"]:
		await _voyage()
	if _only in ["", "combat"]:
		await _battle()
	banner.queue_free()
	print("TEST manette : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


# ------------------------------------------------------------------ l'équipe

func _team() -> void:
	var game := root.get_node("Game")
	var bar := _find("party_bar")
	_check("la barre d'équipe est là", bar != null)
	if bar == null:
		return
	var lead_before = game.call("lead_dino")
	_check("trois dinos, le premier mène", game.get("party").size() == 3)

	# 1. la flèche gauche de la croix : on choisit un portrait
	_tap(DPAD_LEFT)
	await _wait(0.4)
	_check("◀ de la croix : le jeu attend", paused)
	var focus := root.gui_get_focus_owner()
	_check("le portrait de tête a le focus", focus != null and focus.get("lead") == true,
		str(focus))
	await _shot("manette_00_equipe_choix")

	# 2. droite : le portrait suivant
	_tap(DPAD_RIGHT)
	await _wait(0.3)
	var second := root.gui_get_focus_owner()
	_check("▶ : le deuxième portrait", second != null and second != focus and second.get("lead") == false, str(second))

	# 3. A : son menu, avec un bouton qui a le focus
	print("   ui_accept existe : ", InputMap.has_action(&"ui_accept"), " ; événements : ", InputMap.action_get_events(&"ui_accept"))
	_tap(BUTTON_A)
	await _wait(0.6)
	var button := root.gui_get_focus_owner()
	print("   menu : ", bar.get("_menu"), " ; sélection : ", bar.get("_selecting"), " ; pause : ", paused, " ; focus : ", button)
	_check("A : le menu s'ouvre, un bouton a le focus", button is Button, str(button))
	_check("le premier bouton est « Dino actif »", button is Button and (button as Button).text == "Dino actif",
		(button as Button).text if button is Button else "")
	await _shot("manette_01_equipe_menu")

	# 4. A sur « Dino actif » : il passe en tête
	_tap(BUTTON_A)
	await _wait(0.6)
	var lead_after = game.call("lead_dino")
	_check("A : le deuxième dino mène maintenant", lead_after != lead_before)
	_check("le jeu repart", not paused)

	# 5. B annule : sans rien changer
	_tap(DPAD_LEFT)
	await _wait(0.3)
	_check("on rouvre la sélection", paused)
	_tap(BUTTON_B)
	await _wait(0.3)
	_check("B : retour au jeu", not paused)
	_check("et le focus est rendu", root.gui_get_focus_owner() == null)


# ------------------------------------------------------------------ le Dinodex

func _dex() -> void:
	_tap(DPAD_UP)
	await _wait(0.8)
	var dex := _node_with("_cycle_page")
	_check("↑ de la croix : le Dinodex s'ouvre", dex != null)
	if dex == null:
		return
	_tap(DPAD_DOWN)
	await _wait(0.3)
	_check("la croix donne le focus à une vignette ou un onglet", root.gui_get_focus_owner() != null,
		str(root.gui_get_focus_owner()))
	await _shot("manette_02_dex")
	var first: StringName = dex.get("_tab")
	_tap(SHOULDER_R)
	await _wait(0.4)
	var second: StringName = dex.get("_tab")
	_check("RB : la page suivante", second != first, "%s -> %s" % [first, second])
	await _shot("manette_03_dex_page_suivante")
	_tap(SHOULDER_L)
	await _wait(0.4)
	_check("LB : la page d'avant", dex.get("_tab") == first, str(dex.get("_tab")))
	# changer de tête depuis la fiche d'un dino de l'équipe, à la manette
	var game := root.get_node("Game")
	var lead_before = game.call("lead_dino")
	var slot: Control = dex.get("_team").get_child(2)   # (0 : le titre ; 1 : le dino de tête ; 2 : le suivant)
	slot.grab_focus()
	_tap(BUTTON_A)
	await _wait(0.5)
	_check("A sur un dino de l'équipe : sa fiche s'ouvre", dex.get("_entry") != &"", str(dex.get("_entry")))
	var to_lead: Button = null
	for b in dex.find_children("*", "Button", true, false):
		if (b as Button).text == "En tête":
			to_lead = b
	_check("la fiche a un bouton « En tête » pour la manette", to_lead != null and to_lead.focus_mode == Control.FOCUS_ALL,
		"%s ; boutons : %s" % [to_lead.focus_mode if to_lead else "aucun", dex.find_children("*", "Button", true, false).map(func(b): return "%s/%d" % [b.text, b.focus_mode])])
	if to_lead:
		to_lead.grab_focus()
		await _shot("manette_03b_dex_fiche")
		_tap(BUTTON_A)
		await _wait(0.5)
		_check("A : le dino passe en tête", game.call("lead_dino") != lead_before)
	_tap(BUTTON_B)   # sort de la fiche
	await _wait(0.4)
	_tap(BUTTON_B)
	await _wait(0.5)
	_check("B : le Dinodex se ferme", not is_instance_valid(dex) or dex.is_queued_for_deletion())
	_check("le jeu repart", not paused)


# ------------------------------------------------------------------ la carte

func _map() -> void:
	_tap(BUTTON_BACK)
	await _wait(0.8)
	var map := _node_with("_pad_goals")
	_check("Retour (Select) : la carte s'ouvre", map != null)
	if map == null:
		return
	await _shot("manette_04_carte")
	var zone: Control = map.get("_map")
	var zoom_before: float = zone.get("zoom") if zone.get("zoom") != null else 1.0
	_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _wait(0.6)
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	var zoom_after: float = zone.get("zoom") if zone.get("zoom") != null else 1.0
	_check("la gâchette droite zoome", zoom_after > zoom_before, "%.2f -> %.2f" % [zoom_before, zoom_after])
	_tap(DPAD_DOWN)
	await _wait(0.3)
	_check("la croix va à la liste des objectifs", root.gui_get_focus_owner() is Button, str(root.gui_get_focus_owner()))
	_tap(BUTTON_B)
	await _wait(0.5)
	_check("B : la carte se ferme", not is_instance_valid(map) or map.is_queued_for_deletion())
	_check("le jeu repart", not paused)


# ------------------------------------------------------------------ le menu

func _menu() -> void:
	_tap(BUTTON_START)
	await _wait(0.8)
	var menu := _node_with("_fullscreen_text")
	_check("Start : le menu s'ouvre", menu != null)
	if menu == null:
		return
	var focus := root.gui_get_focus_owner()
	_check("un bouton a déjà le focus", focus is Button, str(focus))
	await _shot("manette_05_menu")
	_tap(BUTTON_A)   # « Reprendre » ou le premier bouton
	await _wait(0.5)
	_check("A : valide le bouton (le menu se ferme sur « Reprendre »)",
		not is_instance_valid(menu) or menu.is_queued_for_deletion() or menu.get("_page") != "menu")
	if is_instance_valid(menu) and not menu.is_queued_for_deletion():
		_tap(BUTTON_B)
		await _wait(0.4)
	_check("le jeu repart", not paused)


# ------------------------------------------------------------------ la boutique

func _shop() -> void:
	var game := root.get_node("Game")
	game.call("give_item", "piece", 50)
	_tap(DPAD_DOWN)   # (le joueur est à la manette : c'est ce qui lui donne le premier focus)
	await _wait(0.2)
	var coins_before: int = game.call("coins")
	var berries_before: int = game.call("item_count", "baie")
	load("res://ui/shop_screen.gd").call("open", current_scene, &"herboristerie")
	await _wait(0.8)
	var shop := _node_with("_buy")
	_check("la boutique s'ouvre", shop != null)
	if shop == null:
		return
	var focus := root.gui_get_focus_owner()
	_check("un bouton a le focus d'emblée (le premier « Acheter »)", focus is Button and (focus as Button).text == "Acheter",
		(focus as Button).text if focus is Button else str(focus))
	await _shot("manette_06_boutique")
	_tap(BUTTON_A)
	await _wait(0.5)
	_check("A : achète", game.call("coins") < coins_before and game.call("item_count", "baie") > berries_before,
		"%d -> %d pièces" % [coins_before, game.call("coins")])
	_check("le focus est resté sur un bouton après l'achat", root.gui_get_focus_owner() is Button,
		"%s ; navigating=%s ; boutons : %s" % [root.gui_get_focus_owner(), root.get_node("Prompts").get("navigating"),
			shop.find_children("*", "Button", true, false).map(func(b): return "%s/%s/%s" % [b.text, b.disabled, b.focus_mode])])
	_tap(BUTTON_B)
	await _wait(0.6)
	_check("B : la boutique se ferme", not is_instance_valid(shop) or shop.is_queued_for_deletion())
	_check("le jeu repart", not paused)


# ------------------------------------------------------------------ le Grand Voyageur

func _voyage() -> void:
	var stops := [[&"port_ambre", "Port-Ambre", "Le port"], [&"plaines", "Prairie du Grand Crâne", "Les herbes hautes"],
		[&"foret", "Forêt Jurassique", "Les fougères"]]
	var pending: Variant = load("res://ui/voyage_screen.gd").call("ask", current_scene, stops, &"plaines")
	await _wait(0.8)
	var screen := _node_with("_answer")
	_check("l'écran du Grand Voyageur s'ouvre", screen != null)
	if screen == null:
		return
	var focus := root.gui_get_focus_owner()
	_check("une destination a le focus", focus is Button, str(focus))
	await _shot("manette_07_voyage")
	_tap(DPAD_DOWN)
	await _wait(0.3)
	var moved := root.gui_get_focus_owner()
	_check("la croix change de destination", moved != focus and moved is Button, str(moved))
	_tap(BUTTON_B)
	await _wait(0.6)
	_check("B : l'écran se ferme", not is_instance_valid(screen) or screen.is_queued_for_deletion())
	_check("le jeu repart", not paused)


# ------------------------------------------------------------------ un combat

## Un combat se joue de bout en bout avec A seulement (le choix par défaut est « Combattre », puis la
## première attaque) : un petit sauvage de niveau 1 contre Vif.
func _battle() -> void:
	var game := root.get_node("Game")
	var wild = load("res://game/dino.gd").create(&"protoceratops", 1)
	var result := [""]
	var run := func() -> void:
		result[0] = await current_scene.call("_battle", wild)
	run.call()
	await _wait(2.5)
	var scene := _node_with("_hud_show_hint")
	var started := false
	for node in current_scene.get_children():
		if node.has_signal("_action_chosen"):
			started = true
	_check("le combat est à l'écran", started)
	var presses := 0
	while result[0] == "" and presses < 120:
		_tap(BUTTON_A)
		presses += 1
		await _wait(0.45)
		if presses == 14:
			await _shot("manette_08_combat")
	_check("le combat se gagne avec A seulement", result[0] == "win", "résultat « %s » après %d pressions" % [result[0], presses])
	await _wait(1.0)
	_check("le jeu repart", not paused)


# ------------------------------------------------------------------ outils

func _node_with(method: String) -> Node:
	for parent in [current_scene, root]:
		for node in parent.find_children("*", "", true, false):
			if node.get_script() != null and node.has_method(method) and not node.is_queued_for_deletion():
				return node
	return null


func _axis(axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _find(kind: String) -> Node:
	for node in current_scene.find_children("*", "Control", true, false):
		match kind:
			"party_bar":
				if node.has_method("_begin_selection"):
					return node
	return null


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
