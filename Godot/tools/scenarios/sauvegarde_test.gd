extends RefCounted
## Les trois emplacements de sauvegarde (core/save_system.gd, ui/save_slots.gd), vus : le menu titre avec
## un emplacement rempli (« Continuer », son résumé dessous, « Charger une partie » à côté), puis avec les
## trois ; l'écran « Charger une partie » ; « Nouvelle partie » (le choix d'emplacement, puis la question
## avant d'écraser) ; « Continuer » ; en jeu, la ligne « Sauvegarde : emplacement 2 » des Paramètres,
## « Sauvegarder dans… », la question, et la ligne passée à l'emplacement 3.
## Tout se passe dans le dossier de l'outil (user://capture_save_slots), jamais la partie de Greg.
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/sauvegarde_test.gd titre="Sauvegardes : trois emplacements (titre, charger, nouvelle partie, en jeu : sauvegarder dans…)"

const S := "res://tools/scenarios/sauvegarde_test.gd"
const BOOT := "res://scenes/boot/boot.tscn"
const SLOTS_SCRIPT := "res://ui/save_slots.gd"
const DAY := 86400
## The games of the slots: [zone, starter, nickname, level, minutes played, story flags, days ago].
## (« tuto_commandes »: the controls tutorial would cover the menu.)
const GAMES := [
	[&"port_ambre", &"velociraptor", "Vif", 6, 25.0, ["tuto_commandes"], 2],
	[&"plaines", &"velociraptor", "Vif", 14, 192.0, ["tuto_commandes", "prologue_done"], 0],
	[&"port_ambre", &"parasaurolophus", "Écho", 45, 2285.0, ["tuto_commandes", "prologue_done", "fin_vue"], 1],
]

const STEPS := [
	[0.80, "flags", ["tuto_commandes"]],
	[3.00, "static", [S, "fill", 1]],
	[6.50, "shot", "01_titre_un_emplacement"],
	[6.60, "static", [S, "press", "LoadGame"]],
	[7.40, "shot", "02_charger_un_seul_emplacement"],
	[7.50, "static", [S, "back"]],
	[7.80, "static", [S, "fill", 3]],
	[11.3, "shot", "03_titre_trois_emplacements"],
	[11.4, "static", [S, "press", "LoadGame"]],
	[12.2, "shot", "04_charger_une_partie"],
	[12.3, "static", [S, "back"]],
	[12.6, "static", [S, "press", "NewGame"]],
	[13.4, "shot", "05_nouvelle_partie_quel_emplacement"],
	[13.5, "static", [S, "pick", 2]],
	[14.2, "shot", "06_nouvelle_partie_ecraser"],
	[14.3, "static", [S, "back"]],
	[14.5, "static", [S, "back"]],
	[15.0, "static", [S, "press", "Continue"]],
	[22.0, "static", [S, "menu"]],
	[23.0, "shot", "07_en_jeu_parametres_emplacement_2"],
	[23.1, "static", [S, "press_menu", "ChangeSlot"]],
	[24.0, "shot", "08_en_jeu_sauvegarder_dans"],
	[24.1, "static", [S, "pick", 3]],
	[24.9, "shot", "09_en_jeu_ecraser_emplacement_3"],
	[25.0, "static", [S, "answer", "Yes"]],
	[25.8, "shot", "10_en_jeu_parametres_emplacement_3"],
]


static func _root() -> Window:
	return (Engine.get_main_loop() as SceneTree).root


## The first `count` slots filled with GAMES (in the tool's own folder), the last one remembered as the
## game to continue, then the title screen.
static func fill(count: int) -> String:
	var save := _root().get_node("Save")
	var game := _root().get_node("Game")
	var consts: Dictionary = (save.get_script() as Script).get_script_constant_map()
	if save.get("dir") == consts["PLAYER_DIR"]:   # (only in the tool's own folder: never the player's slots)
		return "refusé : Save.path n'est pas le fichier de l'outil (tools/capture.gd)"
	save.set("before_save", Callable())   # (Chloé's place in the Plaines is no one's)
	var was_enabled: bool = save.get("enabled")
	save.set("enabled", true)   # (as in a game: the objective is written with the save)
	var now := int(Time.get_unix_time_from_system())
	for i in count:
		var g: Array = GAMES[i]
		game.call("new_game")
		var d: Dino = game.call("give_starter", g[1])
		d.nickname = g[2]
		d.level = g[3]
		game.set("region_id", g[0])
		game.set("play_time", float(g[4]) * 60.0)
		for f: String in g[5]:
			game.call("set_flag", StringName(f))
		var file: String = save.call("path_for", i + 1)
		save.set("path", file)
		save.call("save_game")
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file))
		data["saved_at"] = now - int(g[6]) * DAY - 3600 * i
		var out := FileAccess.open(file, FileAccess.WRITE)
		out.store_string(JSON.stringify(data))
		out.close()
	save.set("enabled", was_enabled)
	for n in range(count + 1, int(consts["SLOTS"]) + 1):   # (the slots after `count`: empty)
		DirAccess.remove_absolute(save.call("path_for", n))
	save.call("load_slot", 2 if count >= 2 else 1)
	_root().get_node("Router").call("go_to", BOOT)
	return "%d emplacement(s) dans %s" % [count, save.get("dir")]


## A button of the screen in front (the title's « Charger une partie », « Nouvelle partie »…) pressed.
static func press(button_name: String) -> String:
	var button := _root().get_tree().current_scene.find_child(button_name, true, false) as Button
	if button == null:
		return "pas de bouton %s" % button_name
	button.pressed.emit()
	return button.text


## The slots screen: B / Échap.
static func back() -> String:
	var screen := _slots_screen()
	if screen:
		screen.call("back")
	return "retour" if screen else "pas d'écran des emplacements"


## The slots screen: the card of slot `n` pressed.
static func pick(n: int) -> String:
	var screen := _slots_screen()
	if screen == null:
		return "pas d'écran des emplacements"
	var card: Button = screen.call("card_of", n)
	card.pressed.emit()
	return "carte %d" % n


## The slots screen's question: « Yes » or « No ».
static func answer(button_name: String) -> String:
	var screen := _slots_screen()
	var button := screen.find_child(button_name, true, false) as Button if screen else null
	if button == null:
		return "pas de réponse %s" % button_name
	button.pressed.emit()
	return button.text


## In game: the menu (☰), as the button opens it.
static func menu() -> String:
	SettingsMenu.open(_root().get_tree().current_scene, true)
	return "menu"


## A button of the in-game menu pressed.
static func press_menu(button_name: String) -> String:
	for child in _root().get_children():
		if child is SettingsMenu:
			var button := child.find_child(button_name, true, false) as Button
			if button:
				button.pressed.emit()
				return button.text
	return "pas de bouton %s dans le menu" % button_name


static func _slots_screen() -> Node:
	for child in _root().get_children():
		var script := child.get_script() as Script
		if script and script.resource_path == SLOTS_SCRIPT and not child.is_queued_for_deletion():
			return child
	return null
