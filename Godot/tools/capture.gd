extends SceneTree
## Smoke test with screenshots: starts a new game, plays a scripted scenario, saves
## screenshots, prints checks, then quits. Needs a window (not --headless) to render.
##   godot --path Godot --script res://tools/capture.gd -- out=<folder> [scenario=walk|story]
## A step: [time (s), command, argument]. Commands:
##   hold <action>   keep an input action pressed ("" releases)
##   press <action>  one press event (like a key or the A button)
##   shot <name>     screenshot
##   tp <Vector2>    teleport Chloé (tile coordinates) and her dino
##   check           print flags and test save → load

const TILE := 48.0
const SCENARIOS := {
	"title": [[2.0, "shot", "00_titre"]],
	"walk": [
		[1.5, "shot", "01_arrivee"], [1.6, "hold", "move_up"], [3.0, "hold", "move_left"],
		[4.2, "shot", "02_marche"], [4.3, "hold", ""], [5.0, "hold", "move_up"], [6.5, "hold", ""],
		[7.0, "shot", "03_carrefour"], [7.1, "audio", null],
	],
	"dirs": [
		[1.0, "tp", Vector2(21.0, 5.0)], [1.2, "hold", "move_down"], [2.6, "shot", "08_vers_le_bas"],
		[2.7, "hold", "move_up"], [4.4, "shot", "09_vers_le_haut"], [4.5, "hold", ""], [5.5, "shot", "10_repos_dos"],
	],
	"battle": [
		[1.0, "battle", [&"protoceratops", 3]], [2.6, "shot", "11_combat_intro"],
		[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"], [6.0, "shot", "12_menu"],
		[6.1, "act", {"type": "move", "index": 0}], [6.45, "shot", "13_attaque"],
		[7.5, "press", "interact"], [8.5, "press", "interact"], [9.5, "press", "interact"], [10.5, "press", "interact"],
		[11.5, "press", "interact"], [12.3, "shot", "14_apres_tour"],
		[12.4, "act", {"type": "catch"}], [13.4, "press", "interact"], [14.05, "shot", "15_collier"],
		[15.5, "press", "interact"], [16.5, "press", "interact"], [17.5, "press", "interact"], [18.5, "press", "interact"],
		[19.5, "press", "interact"], [20.5, "press", "interact"], [21.0, "shot", "16_fin"], [21.5, "press", "interact"],
		[22.5, "press", "interact"], [23.5, "shot", "17_retour"], [23.6, "party", null], [23.7, "audio", null],
	],
	"fight": [
		[1.0, "tp", Vector2(21.0, 5.0)], [4.0, "audio", null],
		[4.1, "battle", [&"protoceratops", 2]], [5.0, "auto", true], [30.0, "auto", false],
		[30.5, "shot", "18_apres_victoire"], [30.6, "party", null], [30.7, "audio", null],
	],
	"story": [
		[1.0, "tp", Vector2(28.4, 17.1)], [1.3, "hold", "move_right"], [1.4, "hold", ""],
		[1.8, "press", "interact"], [2.6, "shot", "04_maia"],
		[3.0, "press", "interact"], [3.3, "press", "interact"], [3.6, "press", "interact"], [3.9, "press", "interact"],
		[4.2, "press", "interact"], [4.5, "press", "interact"], [4.8, "press", "interact"], [5.1, "press", "interact"],
		[5.4, "press", "interact"], [5.7, "press", "interact"], [6.0, "press", "interact"], [6.3, "press", "interact"],
		[7.0, "tp", Vector2(4.6, 12.6)], [7.2, "hold", "move_up"], [7.35, "hold", ""],
		[7.8, "press", "interact"], [8.6, "shot", "05_tranche"], [8.8, "press", "interact"], [9.1, "press", "interact"],
		[9.5, "shot", "06_tronc_tranche"],
		[11.0, "tp", Vector2(4.4, 4.5)], [11.2, "hold", "move_up"], [11.3, "hold", ""],
		[11.7, "press", "interact"], [12.2, "press", "interact"], [12.6, "press", "interact"], [13.0, "press", "interact"],
		[13.4, "press", "interact"], [15.5, "shot", "07_journal"],
		[15.8, "press", "interact"], [16.2, "press", "interact"], [16.6, "press", "interact"], [17.0, "press", "interact"],
		[17.4, "press", "interact"], [17.8, "press", "interact"],
		[18.6, "check", null],
	],
}

var _out := "user://captures"
var _steps: Array = []
var _time := 0.0
var _step := 0
var _held := ""
var _auto := false
var _auto_timer := 0.0


func _initialize() -> void:
	var scenario := "walk"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("scenario="):
			scenario = arg.substr(9)
	_steps = SCENARIOS[scenario]
	DirAccess.make_dir_recursive_absolute(_out)
	if scenario == "title":   # the real main scene, as the game starts
		change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
		return
	root.get_node("Game").call("new_game")
	change_scene_to_file("res://world/world.tscn")


func _process(delta: float) -> bool:
	_time += delta
	if _auto:
		_auto_timer += delta
		if _auto_timer > 0.35:
			_auto_timer = 0.0
			_auto_step()
	while _step < _steps.size() and _time >= _steps[_step][0]:
		_run(_steps[_step][1], _steps[_step][2])
		_step += 1
	if _step >= _steps.size():
		root.get_node("Save").set("enabled", false)
		print("CAPTURE_DONE")
		quit()
	return false


func _run(command: String, arg: Variant) -> void:
	match command:
		"hold":
			if _held != "":
				Input.action_release(_held)
			_held = arg
			if _held != "":
				Input.action_press(_held)
		"press":
			for pressed in [true, false]:
				var ev := InputEventAction.new()
				ev.action = arg
				ev.pressed = pressed
				Input.parse_input_event(ev)
		"shot":
			var path: String = _out.path_join(arg + ".png")
			root.get_viewport().get_texture().get_image().save_png(path)
			print("capture: ", arg, " fps=", Engine.get_frames_per_second())
		"tp":
			var world := current_scene
			var pos: Vector2 = arg * TILE
			world.get("player").call("teleport", pos)
			world.get("companion").call("teleport", pos + Vector2(-34, 8))
		"audio":
			for p in root.get_node("Audio").get_children():
				if p is AudioStreamPlayer and p.playing:
					print("audio: ", p.bus, " ", p.stream.resource_path.get_file(), " pos=%.1fs vol=%.1fdB" % [p.get_playback_position(), p.volume_db])
		"battle":
			current_scene.call("_battle", load("res://game/dino.gd").create(arg[0], arg[1]))
		"act":
			for n in current_scene.get_children():
				if n.has_signal("_action_chosen"):
					n.emit_signal("_action_chosen", arg)
		"party":
			var game := root.get_node("Game")
			for d in game.get("party"):
				print("équipe: ", d.nickname, " niv.", d.level, " PV ", d.hp, "/", d.max_hp(), " xp ", d.xp, " attaques ", d.moves.map(func(m): return m["id"]))
			print("colliers: ", game.call("item_count", "collier"), " dex capturés: ", game.get("dex_caught").keys())
		"auto":
			_auto = arg
		"check":
			var game := root.get_node("Game")
			print("flags: ", game.get("flags"))
			var save := root.get_node("Save")
			print("save: ", save.call("save_game"), " load: ", save.call("load_game"), " flags après chargement: ", game.get("flags"))
			print("position sauvegardée: ", game.get("player_position"))


## Plays a battle by itself: first move when the menu is shown, otherwise taps.
func _auto_step() -> void:
	for n in current_scene.get_children():
		if n.has_signal("_action_chosen"):
			if n.get("_menu").visible:
				n.emit_signal("_action_chosen", {"type": "move", "index": 0})
				return
	_run("press", "interact")
