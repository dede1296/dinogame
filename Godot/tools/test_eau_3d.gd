extends SceneTree
## The water of the 3D Prairie (docs/migration-3d.md, phase 4), checked in the real engine (it needs
## a window to render, so not --headless):
##   godot --path Godot --script res://tools/test_eau_3d.gd -- out=<folder> [etats=nom=<fichier.gdshader>,…]
## `etats=` adds older versions of water.gdshader, read from files outside the project, shot from
## the same spot and joined to the new one in one picture — the only way to judge a change.
## Opens the Prairie, stands Chloé on the shore of the sea then of the pond, holds the game's clock
## at four moments of the day (noon, dusk, night, dawn), and at each one measures and photographs
## the water three ways, one right after the other and from the very same spot:
##   - with the real reflections (a mirrored camera in a small viewport);
##   - with the painted sky instead (the way back, and what a modest machine runs);
##   - with the water sheet hidden, to see what it costs at all.
## Measuring the three back to back is the only fair way: the zone is alive and other work on the
## project changes what else is on screen.
## Prints PASS / FAIL per check, quits with 1 on any failure.

const ZONE := "res://world3d/zone3d/zone_3d.tscn"
const MOMENTS := [["midi", 13.0], ["crepuscule", 19.6]]
const CAPTION := "Eau de la Prairie 3D — reflet miroir, vagues, écume au rivage et autour des obstacles, fond visible, couleur selon l'heure ; aucune ligne claire en travers"
const SETTLE_S := 5.5        # the sky, the shadows, the auto exposure and the weather clearing
const MEASURE_S := 1.6
## ZoneWater.Reflections, by number: the test never names the class, so it stays compilable
## before the autoloads (this script runs with --script, like tools/test_world3d.gd).
const SKY := 0
const MIRROR := 1
const WATER_BUDGET_MS := 1.0    # the sheet itself
const MIRROR_BUDGET_MS := 2.5   # what the real reflections add on top (Greg, 04/10)

var _out := "user://test_eau_3d"
var _states: Array[Array] = []   # [name, ShaderMaterial] for each older version to compare
var _failed := 0
var _zone: Node3D
var _player: Node3D
var _pivot: Node3D
var _water: Node3D
var _caption: CanvasLayer
var _rows: Array[Array] = []   # [spot, moment, fps mirror, fps painted sky, fps no water]


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("etats="):
			for one in arg.substr(6).split(",", false):
				var cut := one.find("=")
				if cut > 0:
					_states.append([one.substr(0, cut), one.substr(cut + 1)])
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://capture_eau.json")   # never the player's save
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://capture_eau.json"))
	change_scene_to_file(ZONE)
	_run()


func _run() -> void:
	await create_timer(1.2).timeout
	_zone = current_scene
	_player = _zone.get("player")
	_pivot = _player.get("pivot")
	_quiet()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_caption = ShotCaption.show_on(self, CAPTION)
	var src: RefCounted = _zone.get("source")
	var terrain: Node3D = _zone.get("terrain")
	_water = terrain.get("water")
	_check("the zone has a water sheet", _water != null, "%s" % [_water])
	print("INFO  reflets par défaut : %s" % ["ciel calculé" if _water.get("reflections") == SKY else "vrai miroir"])
	if _water == null:
		_done()
		return
	_load_states()
	var bodies := _water_bodies(src)
	_check("the zone has a sea and a pond", bodies.size() >= 2, "%d corps d'eau" % bodies.size())
	if bodies.size() < 2:
		_done()
		return
	# [name, the body of water, how far the camera dives (°), how far back it stands (m)]. The last
	# one is crouched by the pond: that is where a reflection really shows, the others are the
	# game's usual over-the-shoulder view.
	var spots := [["mer", bodies[0], -14.0, 11.0], ["etang", bodies[1], -14.0, 11.0],
		["etang_rive", bodies[1], -5.0, 4.0]]
	for spot: Array in spots:
		var spot_name: String = spot[0]
		var view: Dictionary = _shore_view(src, terrain, spot[1])
		if view.is_empty():
			print("SKIP  pas de rive trouvée pour %s" % spot_name)
			continue
		view["pitch"] = spot[2]
		view["back"] = spot[3]
		for moment: Array in MOMENTS:
			await _look(view, float(moment[1]))
			_water.call("set_reflections", MIRROR)
			await create_timer(0.8).timeout
			var with_mirror := await _measure()
			var shot_mirror := await _shot("eau_%s_%s_reflet-miroir_%dims" % [spot_name, moment[0], roundi(with_mirror)])
			_water.call("set_reflections", SKY)
			await create_timer(0.8).timeout
			var sky_only := await _measure()
			var shot_sky := await _shot("eau_%s_%s_cielcalcule_%dims" % [spot_name, moment[0], roundi(sky_only)])
			_water.call("set_reflections", MIRROR)
			await create_timer(0.6).timeout
			var live: ShaderMaterial = _water.get("material")
			var now: Shader = live.shader
			var sheet: Array[Image] = []
			var names := PackedStringArray()
			for state: Array in _states:
				live.shader = state[1]   # same material, so it keeps getting the hour and the mirror
				await create_timer(0.6).timeout
				sheet.append(await _shot("etat_%s_%s_%s" % [state[0], spot_name, moment[0]]))
				names.append(state[0])
			live.shader = now
			await create_timer(0.6).timeout
			sheet.append(shot_mirror)
			names.append("nouveau")
			_side_by_side(sheet, "comparaison_%s_%s_%s" % [spot_name, moment[0], "-puis-".join(names)])
			_water.visible = false
			await create_timer(0.5).timeout
			var without := await _measure()
			_water.visible = true
			_rows.append([spot_name, moment[0], with_mirror, sky_only, without])
			_check("%s à %s : la nappe coûte moins de %.1f ms" % [spot_name, moment[0], WATER_BUDGET_MS],
				_ms(sky_only, without) < WATER_BUDGET_MS, "%.2f ms" % _ms(sky_only, without))
			print("INFO  %s à %s : le vrai miroir ajouterait %.2f ms (budget %.1f ms)"
				% [spot_name, moment[0], _ms(with_mirror, sky_only), MIRROR_BUDGET_MS])
	_done()


## Milliseconds per frame that `slow` costs over `fast`.
static func _ms(slow: float, fast: float) -> float:
	return 1000.0 / maxf(slow, 1.0) - 1000.0 / maxf(fast, 1.0)


func _done() -> void:
	if _caption:
		_caption.queue_free()
	print("--- images/s (vrai miroir / ciel calculé, celui par défaut / sans la nappe) ---")
	for row: Array in _rows:
		print("%-10s %-11s  %5.0f  %5.0f  %5.0f   (nappe %.2f ms, miroir +%.2f ms)"
			% [row[0], row[1], row[2], row[3], row[4], _ms(row[3], row[4]), _ms(row[2], row[3])])
	print("TEST eau 3D : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


## No battle, no HUD and no debug overlay over the water, and always the same weather.
func _quiet() -> void:
	var session: Node = _zone.get("session")
	var enc: Node = session.get("encounters")
	if enc:
		enc.set_physics_process(false)
	for d in _zone.get("dinos"):
		d.call("calm_down", 9999.0)
	for child in session.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false


## The zone's bodies of water, biggest first: {"box": Rect2i (tiles), "count": int}.
func _water_bodies(src: RefCounted) -> Array[Dictionary]:
	var tiles: Vector2i = src.get("tiles")
	var seen := {}
	var bodies: Array[Dictionary] = []
	for y in tiles.y:
		for x in tiles.x:
			var start := Vector2i(x, y)
			if seen.has(start) or src.call("surface", start) != &"water":
				continue
			var queue: Array[Vector2i] = [start]
			seen[start] = true
			var box := Rect2i(start, Vector2i.ONE)
			var count := 0
			while not queue.is_empty():
				var t: Vector2i = queue.pop_back()
				count += 1
				box = box.expand(t).expand(t + Vector2i.ONE)
				for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n: Vector2i = t + step
					if n.x < 0 or n.y < 0 or n.x >= tiles.x or n.y >= tiles.y or seen.has(n):
						continue
					if src.call("surface", n) != &"water":
						continue
					seen[n] = true
					queue.append(n)
			bodies.append({"count": count, "box": box})
	bodies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["count"] > b["count"])
	return bodies


## Where to stand and which way to look to see a body of water: {"at": Vector3, "yaw": float}.
## Chloé stands on the walkable tile nearest the water's centre, facing it.
func _shore_view(src: RefCounted, terrain: Node3D, body: Dictionary) -> Dictionary:
	var scale: float = src.get("scale")
	var tiles: Vector2i = src.get("tiles")
	var box: Rect2i = body["box"]
	var centre := Vector2(box.get_center()) * scale
	var best := Vector2.INF
	var best_d := INF
	for y in tiles.y:
		for x in tiles.x:
			if not src.call("surface", Vector2i(x, y)) in [&"grass", &"path", &"sand", &"tall_grass"]:
				continue
			var at := (Vector2(x, y) + Vector2(0.5, 0.5)) * scale
			var d := at.distance_to(centre)
			if d < best_d:
				best_d = d
				best = at
	if best == Vector2.INF:
		return {}
	var to := (centre - best).normalized()
	return {"at": Vector3(best.x, terrain.call("height_at", best.x, best.y), best.y), "yaw": rad_to_deg(atan2(-to.x, -to.y))}


## Stands Chloé there at `hour` of the game's day, the camera looking over the water, and waits for
## the sky and the auto exposure to settle.
func _look(view: Dictionary, hour: float) -> void:
	var game := root.get_node("Game")
	game.set("clock", hour * 60.0)
	# After the clock, never before: moving to a new hour rolls the weather again.
	game.call("set_weather", &"clear")   # always the same weather, or no two runs compare
	_zone.call("place_at", view["at"], float(view["yaw"]))
	_pivot.call("set_view", float(view["yaw"]), float(view["pitch"]), float(view["back"]))
	_pivot.call("snap")
	await create_timer(SETTLE_S).timeout


func _measure() -> float:
	var frames := 0
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() < t0 + int(MEASURE_S * 1e6):
		await process_frame
		frames += 1
	return frames / ((Time.get_ticks_usec() - t0) / 1e6)


func _check(what: String, ok: bool, detail: String) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", what, detail])
	if not ok:
		_failed += 1


## A picture. What the test checks is written across all of them by the caption put up in _run();
## which shot it is (the spot, the moment, how the water reflects, the frames per second) is in
## its name.
func _shot(name: String) -> Image:
	await process_frame
	var shot := root.get_viewport().get_texture().get_image()
	shot.save_png(_out.path_join(name + ".png"))
	return shot


## Several states of the water side by side in one picture, so the look can be judged at a glance.
func _side_by_side(shots: Array[Image], name: String) -> void:
	if shots.is_empty():
		return
	var one := shots[0].get_size()
	var sheet := Image.create_empty(one.x * shots.size(), one.y, false, shots[0].get_format())
	for i in shots.size():
		sheet.blit_rect(shots[i], Rect2i(Vector2i.ZERO, one), Vector2i(i * one.x, 0))
	sheet.save_png(_out.path_join(name + ".png"))


## The older versions of the shader given by `etats=`, read from files outside the project. They go
## on the water's own material, one at a time, so everything else stays the same — the bed, the
## noise, the shore map, the hour, the mirror — and only the shader differs.
func _load_states() -> void:
	var kept: Array[Array] = []
	for state: Array in _states:
		if not FileAccess.file_exists(state[1]):
			print("SKIP  état %s : %s introuvable" % [state[0], state[1]])
			continue
		var shader := Shader.new()
		shader.code = FileAccess.get_file_as_string(state[1])
		kept.append([state[0], shader])
	_states = kept
