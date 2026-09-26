extends SceneTree
## Smoke test with screenshots: starts a new game, plays a scripted scenario, saves
## screenshots, prints checks, then quits. Needs a window (not --headless) to render.
##   godot --path Godot --script res://tools/capture.gd -- out=<folder> [scenario=monde|story|…]
## A step: [time (s), command, argument]. Commands:
##   hold <action>   keep an input action pressed ("" releases)
##   press <action>  one press event (like a key or the A button)
##   shot <name>     screenshot
##   tp <Vector2>    teleport Chloé (tile coordinates) and her dino
##   check           print flags and test save → load
##   quality <0-2>   graphics level (restored when the test ends)
##   settings        open Paramètres ("cancel" closes it)

const TILE := 48.0
const SCENARIOS := {
	"title": [[2.0, "shot", "00_titre"]],
	"walk": [
		[1.5, "shot", "01_arrivee"], [1.6, "hold", "move_up"], [3.0, "hold", "move_left"],
		[4.2, "shot", "02_marche"], [4.3, "hold", ""], [5.0, "hold", "move_up"], [6.5, "hold", ""],
		[7.0, "shot", "03_carrefour"], [7.1, "audio", null],
	],
	"dirs": [
		[1.0, "tp", Vector2(47.0, 70.0)], [1.2, "hold", "move_down"], [2.6, "shot", "08_vers_le_bas"],
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
		[1.0, "tp", Vector2(47.0, 70.0)], [4.0, "audio", null],
		[4.1, "battle", [&"protoceratops", 2]], [5.0, "auto", true], [30.0, "auto", false],
		[30.5, "shot", "18_apres_victoire"], [30.6, "party", null], [30.7, "audio", null],
	],
	"quality": [
		[1.5, "quality", 0], [2.5, "shot", "20_qualite_basse"], [2.6, "quality", 1], [3.6, "shot", "21_qualite_moyenne"],
		[3.7, "quality", 2], [4.7, "shot", "22_qualite_haute"], [4.8, "settings", null], [5.5, "shot", "23_parametres"],
		[5.6, "press", "cancel"], [6.2, "shot", "24_retour_jeu"],
	],
	"raccords": [
		[1.0, "tp", Vector2(60.0, 88.4)], [2.2, "shot", "b0_sortie_port"],
		[2.3, "zone", &"port_ambre"], [3.4, "tp", Vector2(17.0, 4.0)], [4.6, "shot", "b1_port_route_nord"],
	],
	"plaines2": [
		[0.9, "calm", 120.0], [1.0, "tp", Vector2(104.0, 63.3)], [2.4, "shot", "a0_crane"],
		[2.5, "flags", ["ecaille_bosquet", "ecaille_grotte", "ecaille_falaises"]], [2.6, "level", 16],
		[2.7, "hold", "move_up"], [2.8, "hold", ""], [3.0, "press", "interact"],
		[3.2, "auto", true], [6.0, "shot", "a0b_sortie"], [7.0, "shot", "a0c_sortie"], [8.0, "shot", "a0d_sortie"], [15.0, "auto", false], [15.2, "shot", "a1_alpha"], [15.3, "state", null],
		[15.5, "tp", Vector2(105.6, 63.8)], [15.6, "hold", "move_right"], [15.7, "hold", ""], [16.0, "press", "interact"], [16.1, "pick", 0],
		[17.0, "auto", true], [61.0, "auto", false], [61.2, "state", null], [61.3, "party", null],
		[61.35, "tp", Vector2(104.0, 65.0)], [62.4, "shot", "a1b_apres_alpha"], [62.6, "zone", &"grotte_echos"], [64.5, "shot", "a2_grotte"], [65.0, "tp", Vector2(12.0, 3.0)], [66.5, "shot", "a3_grotte_haut"],
		[67.0, "zone", &"plaines"], [68.5, "tp", Vector2(93.0, 33.0)], [70.0, "shot", "a4_falaises"],
		[70.1, "tp", Vector2(96.0, 14.0)], [71.5, "shot", "a5_falaises_haut"], [71.6, "state", null],
	],
	"antre": [
		[0.9, "calm", 120.0], [1.0, "flags", ["crane_ouvert", "sceau_plaines"]],
		[1.2, "tp", Vector2(104.0, 59.4)], [2.6, "shot", "d0_devant_antre"],
		[2.7, "hold", "move_up"], [3.6, "hold", ""], [5.0, "state", null], [5.1, "shot", "d1_antre"],
		[5.2, "hold", "move_up"], [7.6, "hold", ""], [8.4, "shot", "d2_tunnel_gardien"],
		[8.5, "press", "interact"], [8.9, "press", "interact"], [9.3, "press", "interact"], [9.8, "shot", "d3_apres_message"], [9.85, "press", "interact"],
		[10.3, "hold", "move_down"], [13.4, "hold", ""], [14.8, "state", null], [14.9, "shot", "d4_retour_plaines"],
	],
	"ambiance": [
		[3.0, "audio", null], [3.1, "tp", Vector2(26.0, 67.0)], [8.0, "audio", null],
		[8.1, "zone", &"port_ambre"], [12.0, "audio", null],
		[12.1, "zone", &"grotte_echos"], [16.0, "audio", null],
		[16.1, "zone", &"cabinet"], [20.0, "audio", null],
	],
	"fouille": [
		[0.9, "calm", 300.0],
		[1.0, "tp_secret", "arbre"], [2.4, "shot", "f0_arbre_indice"], [2.5, "hold", "move_up"], [2.6, "hold", ""],
		[2.8, "press", "interact"], [3.1, "shot", "f1_secoue"], [4.0, "shot", "f2_galet_arbre"],
		[4.4, "tp_secret", "cailloux"], [5.8, "hold", "move_up"], [5.9, "hold", ""], [6.1, "press", "interact"],
		[6.4, "shot", "f3_pierre"], [7.3, "shot", "f3b_galet_pierre"],
		[7.6, "give", "compsognathus"], [7.7, "tp_secret", "monticule"], [9.2, "shot", "f4_monticule"],
		[9.3, "hold", "move_up"], [9.4, "hold", ""], [9.6, "press", "interact"], [10.3, "shot", "f5_creuse"], [11.8, "shot", "f5b_galet_creuse"],
		[12.2, "tp_secret", "galet"], [13.6, "shot", "f6_galet_visible"], [13.7, "hold", "move_up"], [13.8, "hold", ""],
		[14.0, "press", "interact"], [15.0, "shot", "f7_galet_ramasse"],
		[15.4, "tp_secret", "arbre_vide"], [16.8, "hold", "move_up"], [16.9, "hold", ""], [17.1, "press", "interact"], [17.5, "shot", "f8_arbre_vide"],
		[18.6, "map", null], [19.3, "shot", "f9_carte"], [19.4, "press", "cancel"],
		[19.8, "check", null],
	],
	"repos": [
		[0.9, "calm", 300.0], [1.0, "clock", 21.5], [1.1, "tp_prop", ["feu_camp", Vector2(0, 150)]], [3.0, "shot", "r0_feu_nuit"], [3.1, "audio", null],
		[3.2, "hold", "move_up"], [4.1, "hold", ""], [4.3, "press", "interact"], [5.2, "shot", "r1_choix"], [5.3, "pick", 2],
		[9.5, "shot", "r2_reveil_au_feu"], [9.6, "state", null], [9.7, "audio", null], [11.0, "audio", null], [12.5, "audio", null],
		[16.0, "tp_prop", ["banc", Vector2(0, 56)]], [17.4, "hold", "move_up"], [17.5, "hold", ""], [17.7, "press", "interact"], [17.8, "pick", 0],
		[22.0, "shot", "r3_banc"], [22.1, "state", null], [30.0, "audio", null],
	],
	"vie": [
		[0.9, "calm", 300.0], [0.95, "weather", &"clear"], [1.0, "clock", 11.0], [1.1, "tp", Vector2(60.0, 62.0)], [3.5, "shot", "v0_papillons"],
		[3.6, "tp", Vector2(58.0, 27.5)], [4.6, "shot", "v1_grotte_reaction"],
		[4.7, "tp", Vector2(79.0, 51.9)], [5.7, "shot", "v2_eau_reaction"],
		[5.8, "clock", 22.5], [5.9, "weather", &"clear"], [6.0, "tp", Vector2(60.0, 62.0)], [9.0, "shot", "v3_lucioles"], [9.1, "perf", "nuit_lucioles"],
	],
	"orage": [
		[0.9, "calm", 300.0], [1.0, "clock", 15.0], [1.05, "tp", Vector2(60.0, 62.0)], [1.1, "weather", &"rain"], [7.0, "shot", "o0_pluie_fine"],
		[7.1, "weather", &"storm"], [13.0, "shot", "o1_orage"], [13.1, "flash", null], [13.17, "shot", "o2_eclair"], [13.3, "audio", null], [15.0, "audio", null],
		[15.2, "battle", [&"protoceratops", 3]], [18.2, "shot", "o3_combat_orage"],
		[17.1, "auto", true], [30.0, "auto", false],
		[30.5, "give", "compsognathus"], [30.6, "card", 1], [31.3, "shot", "o4_fiche_compso"], [31.4, "close", null], [31.5, "card", 0], [32.2, "shot", "o5_fiche_vif"],
	],
	"prologue": [
		[1.6, "shot", "90_arrivee"], [1.7, "auto", true], [9.0, "shot", "91_maia_ponton"], [16.0, "auto", false],
		[16.5, "state", null], [16.6, "shot", "92_port"],
		[17.0, "tp", Vector2(31.5, 9.9)], [17.2, "hold", "move_up"], [17.8, "hold", ""], [19.0, "state", null],
		[19.5, "auto", true], [22.0, "shot", "93_roc"], [40.0, "auto", false], [40.2, "shot", "94_cabinet"],
		[40.5, "tp", Vector2(13.9, 7.4)], [40.6, "hold", "move_up"], [40.7, "hold", ""], [41.0, "press", "interact"],
		[44.0, "shot", "95_choix"], [44.1, "pick", 0], [46.0, "auto", true], [47.0, "shot", "96_maia_bebe"],
		[58.0, "shot", "97_nuit"], [75.0, "auto", false], [75.2, "shot", "98_matin"], [75.3, "state", null], [75.4, "party", null],
	],
	"ui_combat": [
		[1.0, "tp", Vector2(60.0, 62.0)], [1.1, "weather", &"rain"], [1.2, "battle", [&"protoceratops", 3]],
		[3.2, "press", "interact"], [4.2, "press", "interact"], [5.2, "press", "interact"], [6.2, "shot", "80_actions"],
		[6.3, "moves", null], [6.8, "shot", "81_attaques"], [6.9, "audio", null],
	],
	"combat_brume": [
		[1.0, "tp", Vector2(60.0, 62.0)], [1.1, "weather", &"mist"], [1.2, "battle", [&"velociraptor", 3]], [4.5, "shot", "74_combat_brume"],
	],
	"combat_meteo": [
		[1.0, "tp", Vector2(60.0, 62.0)], [1.1, "clock", 22.0], [1.2, "battle", [&"protoceratops", 3]], [4.5, "shot", "70_combat_nuit"],
		[4.6, "auto", true], [16.0, "auto", false],
		[16.5, "clock", 12.0], [16.6, "weather", &"rain"], [16.7, "battle", [&"parasaurolophus", 3]], [20.0, "shot", "71_combat_pluie"],
		[20.1, "auto", true], [32.0, "auto", false],
		[32.5, "weather", &"mist"], [32.6, "state", null], [32.7, "battle", [&"velociraptor", 3]], [36.0, "shot", "72_combat_brume"],
		[36.1, "auto", true], [48.0, "auto", false],
		[48.5, "weather", &"rain"], [54.0, "shot", "73_exploration_pluie"],
	],
	"debug": [
		[1.5, "debug", null], [1.7, "debug_call", ["_cycle_species", [1]]], [1.8, "debug_call", ["_lead_dino", []]],
		[1.9, "debug_call", ["_close", []]], [2.2, "party", null],
		[2.3, "call", ["goto_zone", [&"plaines"]]], [3.5, "state", null], [3.6, "shot", "66_debug_zone"],
	],
	"meteo": [
		[1.4, "tp", Vector2(60.0, 62.0)], [1.5, "clock", 8.5], [2.8, "shot", "60_matin"],
		[2.9, "clock", 16.5], [4.0, "shot", "61_apres_midi"],
		[4.1, "weather", &"rain"], [9.5, "shot", "62_pluie"],
		[9.6, "weather", &"mist"], [15.5, "shot", "63_brume"],
		[15.6, "weather", &"clear"], [15.7, "clock", 23.0], [21.0, "shot", "64_nuit"],
		[21.1, "debug", null], [21.8, "shot", "65_debug"],
	],
	"zones": [
		[1.8, "state", null], [1.9, "shot", "30_arrivee"],
		[5.5, "clock", 19.2], [6.2, "state", null], [6.3, "shot", "32_crepuscule"],
		[6.4, "clock", 23.0], [7.2, "state", null], [7.3, "shot", "33_nuit"],
		[7.4, "clock", 10.0], [7.5, "xp", 25], [8.0, "shot", "34_xp"], [8.2, "tap", 0], [8.6, "shot", "35_menu_portrait"],
		[8.7, "close", null],
	],
	"story": [
		[1.0, "tp", Vector2(61.0, 44.6)], [1.3, "hold", "move_right"], [1.4, "hold", ""],
		[1.8, "press", "interact"], [2.6, "shot", "04_maia"],
		[3.0, "press", "interact"], [3.3, "press", "interact"], [3.6, "press", "interact"], [3.9, "press", "interact"],
		[4.2, "press", "interact"], [4.5, "press", "interact"], [4.8, "press", "interact"], [5.1, "press", "interact"],
		[5.4, "press", "interact"], [5.7, "press", "interact"], [6.0, "press", "interact"], [6.3, "press", "interact"],
		[7.0, "tp", Vector2(20.0, 42.4)], [7.2, "hold", "move_up"], [7.35, "hold", ""],
		[7.8, "press", "interact"], [8.6, "shot", "05_tranche"], [8.8, "press", "interact"], [9.1, "press", "interact"],
		[9.5, "shot", "06_tronc_tranche"],
		[11.0, "tp", Vector2(15.6, 28.6)], [11.2, "hold", "move_up"], [11.3, "hold", ""],
		[11.7, "press", "interact"], [12.2, "press", "interact"], [12.6, "press", "interact"], [13.0, "press", "interact"],
		[13.4, "press", "interact"], [15.5, "shot", "07_journal"],
		[15.8, "press", "interact"], [16.2, "press", "interact"], [16.6, "press", "interact"], [17.0, "press", "interact"],
		[17.4, "press", "interact"], [17.8, "press", "interact"],
		[18.6, "check", null], [19.5, "audio", null],
	],
	"monde": [
		[1.9, "calm", 60.0], [2.0, "state", null], [2.1, "shot", "c0_arrivee_port"],
		[2.2, "tp", Vector2(60.0, 60.0)], [3.6, "shot", "c1_prairie"],
		[3.7, "tp", Vector2(60.0, 47.0)], [5.1, "shot", "c2_carrefour"],
		[5.2, "tp", Vector2(58.0, 27.6)], [6.6, "shot", "c3_grotte"],
		[6.7, "tp", Vector2(93.0, 40.5)], [8.1, "shot", "c4_porte_falaises"],
		[8.2, "tp", Vector2(99.0, 11.0)], [9.6, "shot", "c5_falaises_haut"],
		[9.7, "tp", Vector2(104.0, 65.5)], [11.1, "shot", "c6_crane"],
		[11.2, "tp", Vector2(26.0, 64.0)], [12.6, "shot", "c7_anse"],
		[12.7, "tp", Vector2(20.0, 44.5)], [14.1, "shot", "c8_bosquet"],
		[14.2, "tp", Vector2(80.0, 42.0)], [15.6, "shot", "c9_etang"], [15.7, "state", null],
		[15.8, "map", null], [16.4, "shot", "c10_carte"], [16.5, "press", "cancel"], [17.0, "shot", "c11_carte_fermee"], [17.2, "tp", Vector2(97.0, 15.6)], [17.5, "hold", "move_up"], [18.8, "hold", ""], [19.8, "shot", "c12_pied_falaise"],
	],
	"perf": [
		[0.5, "vsync", false],
		[4.0, "perf", "arrivee"], [4.1, "tp", Vector2(60.0, 47.0)], [7.0, "perf", "carrefour"],
		[7.1, "tp", Vector2(93.0, 40.5)], [10.0, "perf", "porte_falaises"], [10.1, "tp", Vector2(20.0, 44.5)], [13.0, "perf", "bosquet"],
		[13.1, "tp", Vector2(80.0, 42.0)], [16.0, "perf", "etang"], [16.1, "quality", 0], [19.0, "perf", "etang_basse"],
		[19.1, "quality", 2], [22.0, "perf", "etang_haute"],
	],
}

var _out := "user://captures"
var _steps: Array = []
var _time := 0.0
var _step := 0
var _held := ""
var _auto := false
var _auto_timer := 0.0
var _quality_before := -1
var _pick := -1


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
	var game := root.get_node("Game")
	game.call("new_game")
	# Past the prologue with Vif, unless the scenario plays the prologue.
	if not scenario.begins_with("prologue"):
		game.call("give_starter", &"velociraptor")
		game.call("set_flag", &"prologue_done")
		game.set("items", {"collier": 5, "baie": 3})
		# In the Plaines, at the south entrance (coming from the port).
		if game.get("region_id") == &"port_ambre":
			game.set("region_id", &"plaines")
			game.set("arrival", &"DepuisPort")
	change_scene_to_file("res://world/world.tscn")


func _process(delta: float) -> bool:
	_time += delta
	if _pick >= 0:
		var buttons := root.get_node("Dialogue").find_children("*", "Button", true, false)
		if buttons.size() > _pick:
			(buttons[_pick] as Button).pressed.emit()
			_pick = -1
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
		if _quality_before >= 0:
			root.get_node("Quality").call("set_level", _quality_before)
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
			print("capture: ", arg, " fps=", Engine.get_frames_per_second(), " pause=", paused)
		"tp":
			var world := current_scene
			var pos: Vector2 = arg * TILE
			world.get("player").call("teleport", pos)
			world.get("companion").call("teleport", pos + Vector2(-34, 8))
		"audio":
			for bus in ["Music", "Ambience", "SFX"]:
				print("bus ", bus, " %.1f dB" % AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)))
			var audio := root.get_node("Audio")
			print("ambiance : ", audio.get("ambience").call("current"), " mer=%.2f" % audio.get("ambience").get("_mix")["sea"])
			for p in audio.find_children("*", "AudioStreamPlayer", true, false):
				if p.playing:
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
		"quality":
			var quality := root.get_node("Quality")
			if _quality_before < 0:
				_quality_before = quality.get("level")
			quality.call("set_level", arg)
			print("qualité: ", quality.call("level_name"), " max_fps=", Engine.max_fps, " objets=", current_scene.get_tree().get_node_count())
		"settings":
			load("res://ui/settings_menu.gd").open(current_scene)
		"call":
			current_scene.callv(arg[0], arg[1])
		"weather":
			root.get_node("Game").call("set_weather", arg)
		"moves":
			for n in current_scene.get_children():
				if n.has_signal("_action_chosen"):
					n.call("_show_menu", n.get("_moves_menu"))
		"flags":
			for f in arg:
				root.get_node("Game").call("set_flag", StringName(f))
		"level":
			for d in root.get_node("Game").get("party"):
				d.level = arg
				d.heal()
		"zone":
			current_scene.call("goto_zone", arg)
		"pick":
			_pick = arg   # pressed as soon as the question's buttons are shown
		"debug_call":
			for n in root.get_children():
				if n.get_script() == load("res://ui/debug_menu.gd"):
					n.callv(arg[0], arg[1])
		"debug":
			load("res://ui/debug_menu.gd").open(current_scene)
		"clock":
			root.get_node("Game").set("clock", float(arg) * 60.0)
		"xp":
			root.get_node("Game").call("award_team_xp", arg)
		"tap":
			current_scene.find_children("*", "PartyBar", true, false)[0].call("_open_menu", arg)
		"close":
			current_scene.find_children("*", "PartyBar", true, false)[0].call("_close_menu")
		"calm":   # the wild dinos keep away for `arg` seconds
			for n in current_scene.get("region").get_node("Entities").get_children():
				if n.has_method("calm_down"):
					n.call("calm_down", arg)
		"tp_secret":   # next to (just south of) a hiding place of an amber pebble, facing it
			var found: Node2D = null
			for n in current_scene.get("region").get_node("Entities").get_children():
				var k: String = n.get("kind") if "kind" in n else ""
				var hides: bool = n.has_method("is_hiding") and n.call("is_hiding")
				var ok := false
				match arg:
					"arbre": ok = k in ["arbre_rond", "fougere_arbre", "araucaria"] and hides
					"arbre_vide": ok = k == "arbre_rond" and not hides and n.get_script() == load("res://world/prop.gd")
					"cailloux": ok = k == "cailloux" and hides
					"monticule": ok = n.get_script() == load("res://world/dig_spot.gd")
					"galet": ok = k == "galet"
				if ok:
					found = n
					break
			if found == null:
				print("tp_secret : rien pour ", arg)
			else:
				print("tp_secret ", arg, " : ", (found.global_position / TILE).snapped(Vector2(0.1, 0.1)))
				var pos := found.global_position + Vector2(-40, 56)
				current_scene.get("player").call("teleport", pos)
				current_scene.get("companion").call("teleport", pos + Vector2(-34, 8))
		"tp_prop":   # [kind, offset (px)]: next to the first prop of that kind
			for n in current_scene.get("region").get_node("Entities").get_children():
				if n.get("kind") == arg[0]:
					print("tp_prop ", arg[0], " : ", (n.global_position / TILE).snapped(Vector2(0.1, 0.1)))
					var pos: Vector2 = n.global_position + arg[1]
					current_scene.get("player").call("teleport", pos)
					current_scene.get("companion").call("teleport", pos + Vector2(-34, 8))
					break
		"flash":   # a lightning flash now
			current_scene.get("_view").set("_next_lightning", 0.0)
		"card":   # the sheet of party dino #arg
			var bar: Node = current_scene.find_children("*", "PartyBar", true, false)[0]
			bar.call("_open_card", root.get_node("Game").get("party")[arg])
		"give":
			root.get_node("Game").call("add_caught", load("res://game/dino.gd").create(StringName(arg), 6))
		"map":
			current_scene.call("_open_map")
		"vsync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if arg else DisplayServer.VSYNC_DISABLED)
			Engine.max_fps = 0
		"perf":
			print("perf %s : %d im/s, %d appels de dessin, %d objets, %d k triangles" % [arg, Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000])
		"state":
			var game := root.get_node("Game")
			var zone: Node = current_scene.get("region")
			var wild := zone.get_node("Entities").get_children().filter(func(n: Node) -> bool: return n.has_signal("encountered"))
			print("zone=", game.get("region_id"), " moment=", game.call("phase"), " météo=", game.get("weather"), " pause=", paused, " dinos visibles=", wild.map(func(n: Node) -> String: return "%s niv.%s" % [n.get("species_id"), n.get("level_range")]),
				" jour=", game.get("day"), " heure=%.1f" % (float(game.get("clock")) / 60.0), " joueur=", (current_scene.get("player").global_position / TILE).round(), " fps=", Engine.get_frames_per_second(), " drapeaux=", game.get("flags").keys())
		"auto":
			_auto = arg
		"check":
			var game := root.get_node("Game")
			print("flags: ", game.get("flags"))
			var save := root.get_node("Save")
			print("save: ", save.call("save_game"), " load: ", save.call("load_game"), " flags après chargement: ", game.get("flags"))
			print("position sauvegardée: ", game.get("player_position"))
			print("galets trouvés : ", game.call("pebbles_found", "plaines"), "  baies : ", game.call("item_count", "baie"), "  jour : ", game.get("day"))
			var explored: Dictionary = game.get("explored")
			for id: String in explored:
				var seen: PackedByteArray = explored[id]
				print("carte %s après chargement : %d cases, %d vues" % [id, seen.size(), Array(seen).filter(func(v: int) -> bool: return v > 0).size()])


## Plays a battle by itself: first move when the menu is shown, otherwise taps.
func _auto_step() -> void:
	for n in current_scene.get_children():
		if n.has_signal("_action_chosen"):
			if n.get("_menu").visible:
				n.emit_signal("_action_chosen", {"type": "move", "index": 0})
				return
	_run("press", "interact")
