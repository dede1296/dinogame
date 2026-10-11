extends SceneTree
## Les images par seconde avec les ombres aplaties, contre l'ombre-carte du soleil d'avant
## (world/view3d/ombre_aplatie.gd), sans vsync, qualité Haute (ou `level=`), à midi, temps clair,
## à trois endroits : la Prairie (lisière d'arbres), la Forêt (carrefour), Port-Ambre (le quai).
## Les deux réglages se suivent en alternance au même endroit (A B A B…), plusieurs fois : ce qui
## tourne à côté sur la machine (l'éditeur, un autre jeu) pèse autant sur l'un que sur l'autre.
##   godot --path Godot --script res://tools/perf_ombres.gd --resolution 1600x900 -- [rounds=4] [level=2]

const WORLD := "res://world/world.tscn"
const FLAT := "res://world/view3d/ombre_aplatie.gd"
const CAPTION := "Images/s : ombres aplaties contre l'ombre-carte d'avant, en alternance, sans vsync"
const FLAGS := ["prologue_done", "tuto_commandes", "sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee"]
const PLACES := [["Prairie", &"plaines", Vector2(47.0, 70.0)], ["Forêt", &"foret", Vector2(62.5, 57.5)], ["Port", &"port_ambre", Vector2(20.0, 15.0)]]
const SETTLE_S := 1.5
const MEASURE_S := 3.0

var _rounds := 4
var _level := 2
var _flat: GDScript


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("rounds="):
			_rounds = int(arg.substr(7))
		elif arg.begins_with("level="):
			_level = int(arg.substr(6))
	root.get_node("Save").set("path", "user://perf_ombres.json")
	var game := root.get_node("Game")
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	for f in FLAGS:
		game.call("set_flag", StringName(f))
	game.set("region_id", &"plaines")
	game.set("arrival", &"DepuisPort")
	_flat = load(FLAT)
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	await create_timer(1.5).timeout
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var quality := root.get_node("Quality")
	var saved: int = quality.get("level")
	quality.call("set_level", _level)
	Engine.max_fps = 0
	print("GPU : ", RenderingServer.get_video_adapter_name(), " ; rendu : ", RenderingServer.get_current_rendering_method(), " ; qualité ", quality.call("level_name"))
	for place in PLACES:
		await _goto(place[1], place[2])
		var fps := {0: [], 1: []}
		var calls := {0: 0, 1: 0}
		for r in _rounds:
			for mode in [0, 1]:
				_flat.set("forced", mode)
				current_scene.get("_view").call("_apply_quality")
				_quiet()
				await create_timer(SETTLE_S).timeout
				var f0 := Engine.get_frames_drawn()
				var t0 := Time.get_ticks_usec()
				await create_timer(MEASURE_S).timeout
				fps[mode].append((Engine.get_frames_drawn() - f0) / ((Time.get_ticks_usec() - t0) / 1e6))
				calls[mode] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var before := _mean(fps[0])
		var after := _mean(fps[1])
		print("PERF %-8s ombre-carte %6.1f im/s (%s) | aplaties %6.1f im/s (%s) | écart %+.1f %% | appels de dessin %d -> %d" % [
			place[0], before, _list(fps[0]), after, _list(fps[1]), (after - before) / before * 100.0, calls[0], calls[1]])
	_flat.set("forced", -1)
	quality.call("set_level", saved)
	banner.queue_free()
	quit()


func _goto(zone: StringName, at: Vector2) -> void:
	if root.get_node("Game").get("region_id") != zone:
		current_scene.call("goto_zone", zone)
		await create_timer(2.0).timeout
	for n in current_scene.get("region").get_node("Entities").get_children():
		if n.has_method("calm_down"):
			n.call("calm_down", 900.0)
	current_scene.get("player").call("teleport", at * 48.0)
	current_scene.get("companion").call("stand_beside", at * 48.0)
	root.get_node("Game").set("clock", 12.5 * 60.0)
	await create_timer(1.5).timeout
	_quiet()


func _quiet() -> void:
	root.get_node("Game").call("set_weather", &"clear")
	root.get_node("Game").set("clock", 12.5 * 60.0)
	var view: Node = current_scene.get("_view")
	for key in ["_rain_amount", "_storm_amount", "_mist_amount", "_sand_amount"]:
		view.set(key, 0.0)


func _mean(values: Array) -> float:
	var total := 0.0
	for v in values:
		total += v
	return total / maxf(values.size(), 1.0)


func _list(values: Array) -> String:
	return " ".join(values.map(func(v: float) -> String: return "%.0f" % v))
