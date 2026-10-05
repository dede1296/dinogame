extends SceneTree
## The Terrain3D ground, the base of the 3D relief (docs/migration-3d.md, phase 4, « Terrain3D »),
## checked in the Prairie before other agents build on it — on a zone NOT remodelled, the ground every
## zone gets until its plan's relief replaces the 2.5D's: the Prairie built with the default edits
## (TerrainRelief.DEFAULT_EDITS, through ZoneTerrain.edits_override), as the 2.5D had it, since its own
## file is now its plan's relief (tools/test_relief_plaines.gd checks that one) —
## - its heights: Terrain3DData.get_height is ZoneTerrain.height_at; the 2.5D's (ZoneSource, what
##   the rules read) at every untouched vertex; within the smoothing's reach elsewhere; exactly the
##   2.5D's within reach of a cliff or of the shore (Blockers3D's walls, the water's edge);
## - the water still reads the 2.5D's bed and meets the same shore; the sea is deeper than the pond;
## - Chloé walks on it, a cliff stops her; the dinos and the people stand on it, the dinos walk;
##   their navigation covers as much ground as the old mesh's;
## - ZoneTerrain's face is unchanged: height_at, material (grass_tint, the rain), bed_look, water;
## - the authoring API (TerrainRelief): hills, valleys, flattening, ramps, painting, protection of
##   the rules' heights, the zone's edits file; the regions saved and read back (hand retouches);
##   the zone placed elsewhere in a shared world;
## - and, once at the end, the old mesh against Terrain3D in this same run: build times, frames per
##   second from the same views, memory (no pictures: the look was validated on 04/10).
##   godot --path Godot --script res://tools/test_terrain3d.gd -- out=<folder> [mesures=non]
## Not --headless: it renders. Prints PASS / FAIL / MESURE, quits with 1 on any failure.
## (Game classes are reached through nodes and load(): this script is compiled before the autoloads.)

const ZONE := "res://world3d/zone3d/zone_3d.tscn"
const ZONE_TERRAIN := "res://world3d/zone3d/zone_terrain.gd"
const RELIEF := "res://world3d/zone3d/terrain3d_relief.gd"
const GROUND := "res://world3d/zone3d/terrain3d_ground.gd"
const CAPTION := "Terrain3D — sol de la Prairie : style cartoon, relief, falaises, mer"
const MESH := 0          # ZoneTerrain.Kind
const TERRAIN3D := 1
const HOUR := 10.0       # every view at the same hour, for both grounds
const LOW_SUN_HOUR := 18.3
## Chloé's capsule rests on the collision's triangles, the reference is bilinear: a few cm apart on
## a slope, plus the body's safe margin.
const FEET_M := 0.08
const FPS_SECONDS := 2.0
const WATER_LEVEL := -0.425    # HeightMap.WATER_LEVEL
const OFFSET := Vector2(640.0, -320.0)   # a place in a shared world (m), for the open-world check

var _out := "user://test_terrain3d"
var _failed := 0
var _zone: Node
var _player: Node3D
var _pivot: Node3D
var _terrain: Node3D
var _src: RefCounted
var _views: Array[Dictionary] = []   # [{name, at, yaw, pitch, dist, hour}]
var _measures := {}                  # kind → {build, terrain, views: {name: fps}, memory…}
var _timed := true                   # mesures=non: no frames per second (a check of the rules only)


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg == "mesures=non":
			_timed = false
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://capture_save.json")   # never the player's save
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://capture_save.json"))
	ShotCaption.show_on(self, CAPTION)   # one caption for the whole run, left up
	_run()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _open(TERRAIN3D)
	var ground3d: Node = _terrain.get("ground3d")
	_check("the ground is Terrain3D (Forward+, extension loaded)", ground3d != null and int(_terrain.get("kind")) == TERRAIN3D, "%s" % [_terrain.get("kind")])
	if ground3d == null:
		_done()
		return
	if _terrain.call("is_remodelled"):
		print("SKIP  tout le test : la zone est remodelée (son relief n'est plus celui du 2,5D ; voir tools/test_relief_plaines.gd)")
		_done()
		return
	_find_views()
	var relief: RefCounted = _terrain.get("relief")
	_check_heights(ground3d, relief)
	_check_untouched_near_rules(relief)
	_check_water(relief)
	_check_face()
	await _walk_check(TERRAIN3D)
	await _cliff_check(TERRAIN3D)
	await _dinos_check()
	_people_check()
	await _navigation_check(TERRAIN3D)
	_authoring_check()
	await _saved_regions_check(ground3d)
	await _offset_check()
	if _timed:   # once, at the end: the old mesh, then Terrain3D again, from the same views
		await _open(MESH)
		await _navigation_check(MESH)
		await _measure(MESH)
		await _open(TERRAIN3D)
		await _measure(TERRAIN3D)
		_compare_navigation()
		_report()
	_done()


func _done() -> void:
	load(ZONE_TERRAIN).set(&"edits_override", null)
	print("TEST terrain3d : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


## The relief edits of a zone that is not remodelled (the default: smoothed, the sea dug).
func _edits() -> Array:
	return load(RELIEF).get_script_constant_map()["DEFAULT_EDITS"]


## Builds the Prairie with that ground (a fresh scene each time), the game quietened.
func _open(kind: int) -> void:
	load(ZONE_TERRAIN).set(&"kind_override", kind)
	load(ZONE_TERRAIN).set(&"edits_override", _edits())
	var game := root.get_node("Game")
	game.set("weather", &"clear")
	game.set("clock", HOUR * 60.0)
	change_scene_to_file(ZONE)
	await process_frame
	await process_frame
	await create_timer(1.5).timeout
	_zone = current_scene
	_player = _zone.get("player")
	_pivot = _player.get("pivot")
	_terrain = _zone.get("terrain")
	_src = _zone.get("source")
	_quiet()


func _quiet() -> void:
	var enc: Node = _zone.get("session").get("encounters")
	enc.set_physics_process(false)
	for d in _zone.get("dinos"):
		d.call("calm_down", 9999.0)


# --- views and measures --------------------------------------------------------------------------

## The views both grounds are timed from: the arrival, a cliff, the beach and the sea (from the
## shore and from above), a dirt path, the ground close up, the relief under a low sun.
func _find_views() -> void:
	var s: float = _src.get("scale")
	var arrival: Vector3 = _src.call("spawn", &"DepuisPort")
	_views.append({"name": "01_arrivee", "at": arrival, "yaw": 0.0, "pitch": -22.0, "dist": 4.5})
	var foot := _cliff_foot()
	if foot.x >= 0:
		_views.append({"name": "02_falaise", "at": Vector3((foot.x + 0.5) * s, 0, (foot.y + 3.5) * s), "yaw": 0.0, "pitch": -12.0, "dist": 7.0})
	var shore := _shore_view()
	if not shore.is_empty():
		_views.append({"name": "03_plage_mer", "at": shore["at"], "yaw": shore["yaw"], "pitch": -12.0, "dist": 6.0})
		_views.append({"name": "04_mer_vue_haute", "at": shore["at"], "yaw": shore["yaw"], "pitch": -42.0, "dist": 22.0})
	var trail := _path_view()
	if not trail.is_empty():
		_views.append({"name": "05_chemin", "at": trail["at"], "yaw": trail["yaw"], "pitch": -28.0, "dist": 6.5})
	_views.append({"name": "06_sol_de_pres", "at": arrival + Vector3(3.0, 0, -6.0), "yaw": 30.0, "pitch": -58.0, "dist": 2.4})
	var hills := _hills_view()
	if hills != Vector3.INF:
		_views.append({"name": "07_relief_soleil_bas", "at": hills, "yaw": 135.0, "pitch": -24.0, "dist": 16.0, "hour": LOW_SUN_HOUR})


## The frames per second from each view; the build times and the memory of the zone.
func _measure(kind: int) -> void:
	var m: Dictionary = _measures.get_or_add(kind, {})
	m["build"] = int(_zone.get("build_ms"))
	m["terrain"] = int(_terrain.get("build_ms"))
	m["views"] = {}
	var game := root.get_node("Game")
	for v in _views:
		var hour: float = v.get("hour", HOUR)
		if absf(float(game.get("clock")) - hour * 60.0) > 1.0:
			game.set("clock", hour * 60.0)
			await create_timer(1.0).timeout
		await _look(v)
		m["views"][v["name"]] = await _fps()
	game.set("clock", HOUR * 60.0)
	await create_timer(0.8).timeout
	m["memoire_mo"] = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	m["video_mo"] = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	await _look(_views[0])
	m["triangles"] = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	m["appels"] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	m["ecart_regles"] = _rules_gap()


func _look(v: Dictionary) -> void:
	await _clear_sky()
	var at: Vector3 = v["at"]
	at.y = float(_terrain.call("height_at", at.x, at.z)) + 0.05
	_player.call("place_at", at, deg_to_rad(float(v["yaw"]) + 180.0))
	_pivot.call("set_view", v["yaw"], v["pitch"], v["dist"])
	_pivot.call("snap")
	await create_timer(0.9).timeout


## Every view in clear weather: the game rolls its weather each new hour (setting the clock
## crosses hours), and the sky and the ground ease into it over a few seconds.
func _clear_sky() -> void:
	var game := root.get_node("Game")
	var weather: Node = _zone.get("weather")
	if game.get("weather") == &"clear" and _calm(weather):
		return
	game.call("set_weather", &"clear")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 12000 and not _calm(weather):
		await process_frame
	await create_timer(2.0).timeout   # (the sky eases at about the same pace)


func _calm(weather: Node) -> bool:
	return float(weather.get("rain_amount")) < 0.01 and float(weather.get("mist_amount")) < 0.01 and float(weather.get("storm_amount")) < 0.01


func _fps() -> float:
	var frames := 0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + FPS_SECONDS * 1000.0:
		await process_frame
		frames += 1
	return frames / FPS_SECONDS


# --- checks on the Terrain3D ground ----------------------------------------------------------------

## Terrain3D's heights are ZoneTerrain's; ZoneSource's at every untouched vertex; within the
## smoothing's reach of them where the relief was smoothed (and only lower out at sea).
func _check_heights(ground3d: Node, relief: RefCounted) -> void:
	var data: Object = ground3d.get("terrain").get("data")
	var size: Vector2 = _src.call("size_m")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var worst_plugin := 0.0
	var worst_smoothed := 0.0
	var smoothed := 0
	var dug := 0
	var same := 0
	for i in 6000:
		var x := rng.randf_range(-15.0, size.x + 15.0)
		var z := rng.randf_range(-15.0, size.y + 15.0)
		var h: float = _terrain.call("height_at", x, z)
		# (within 1 cm of a vertex, get_height hands back the vertex's own height, not the
		# interpolated one: those points are left out, the gap there is the plugin's choice)
		var nearest := Vector2(snappedf(x, 0.5), snappedf(z, 0.5))
		if nearest.distance_to(Vector2(x, z)) >= 0.012:
			worst_plugin = maxf(worst_plugin, absf(float(data.call("get_height", Vector3(x, 0, z))) - h))
		var base: float = relief.call("base_height_at", x, z)
		if base < WATER_LEVEL:
			dug += 1 if h < base - 0.001 else 0
		elif absf(h - base) > 0.0005:
			worst_smoothed = maxf(worst_smoothed, absf(h - base))
			smoothed += 1
		else:
			same += 1
	_check("Terrain3D's height (Terrain3DData.get_height) is ZoneTerrain.height_at's", worst_plugin < 0.001, "écart max %.5f m" % worst_plugin)
	# At the vertices of the ground and of its collision, untouched ground is exactly ZoneSource's;
	# in between, both are interpolated (see _rules_gap).
	var samples: Vector2i = relief.get("samples")
	var origin: Vector2 = relief.get("origin")
	var step: float = relief.get("step")
	var worst_node := 0.0
	var nodes := 0
	for i in 6000:
		var x := origin.x + rng.randi_range(0, samples.x - 1) * step
		var z := origin.y + rng.randi_range(0, samples.y - 1) * step
		var h: float = _terrain.call("height_at", x, z)
		if absf(h - float(relief.call("base_height_at", x, z))) > 0.0005:
			continue
		worst_node = maxf(worst_node, absf(h - float(_src.call("height_at", x, z))))
		nodes += 1
	_check("…the 2.5D's (ZoneSource.height_at) at its vertices, where untouched", worst_node < 0.001, "écart max %.4f m sur %d sommets" % [worst_node, nodes])
	var allowed: float = load(RELIEF).get_script_constant_map()["SMOOTH_MAX_M"]
	_check("…within %.2f m of it where smoothed" % allowed, worst_smoothed <= allowed + 0.001, "écart max %.3f m sur %d points" % [worst_smoothed, smoothed])
	print("INFO  points tirés : %d intacts, %d lissés (%.0f %%), %d creusés (mer)" % [same, smoothed, 100.0 * smoothed / 6000.0, dug])


## How far the walked ground is from the 2.5D's heights (ZoneSource.height_at, what the rules
## read), on dry ground, between the vertices too: [max, mean] over the same points for both grounds.
func _rules_gap() -> Vector2:
	var size: Vector2 = _src.call("size_m")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var worst := 0.0
	var total := 0.0
	var count := 0
	for i in 6000:
		var x := rng.randf_range(0.0, size.x)
		var z := rng.randf_range(0.0, size.y)
		var rule: float = _src.call("height_at", x, z)
		if rule < WATER_LEVEL:
			continue
		var gap := absf(float(_terrain.call("height_at", x, z)) - rule)
		worst = maxf(worst, gap)
		total += gap
		count += 1
	return Vector2(worst, total / maxf(count, 1.0))


## By a cliff (the walls of Blockers3D) and along the shore, the heights are exactly the 2.5D's: the
## walls, the cliff test and the water's edge stand where they stood.
func _check_untouched_near_rules(relief: RefCounted) -> void:
	var tiles: Vector2i = _src.get("tiles")
	var s: float = _src.get("scale")
	var worst := 0.0
	var count := 0
	for y in tiles.y:
		for x in tiles.x:
			var t := Vector2i(x, y)
			if not (_cliff_tile(t) or _src.call("surface", t) == &"water" and _land_next_to(t)):
				continue
			for k in 9:
				var px := (x + 0.1 + 0.4 * (k % 3)) * s
				var pz := (y + 0.1 + 0.4 * floorf(k / 3.0)) * s
				if _src.call("surface", t) == &"water" and float(relief.call("base_height_at", px, pz)) < WATER_LEVEL:
					continue   # (out in the water the sea may be dug: only its edge is held)
				worst = maxf(worst, absf(float(_terrain.call("height_at", px, pz)) - float(relief.call("base_height_at", px, pz))))
				count += 1
	_check("by the cliffs and the shore, the ground is the 2.5D's", worst < 0.0005, "écart max %.4f m sur %d points" % [worst, count])


## The water still reads the 2.5D's bed (its look is unchanged); wherever it does not draw (the
## 2.5D's ground above it), the new ground is above it too (no dry pit under the water level);
## the sea is deeper than the pond.
func _check_water(relief: RefCounted) -> void:
	var water: Node = _terrain.get("water")
	_check("the zone has its water sheet", water != null, "")
	if water == null:
		return
	var heights: RefCounted = _src.get("heights")
	var bed: Texture2D = water.get("material").get_shader_parameter("ground_height")
	_check("…which reads the 2.5D's bed, as before (its look unchanged)", bed == heights.call("height_texture")["texture"], "")
	var samples: Vector2i = relief.get("samples")
	var origin: Vector2 = relief.get("origin")
	var step: float = relief.get("step")
	var s: float = _src.get("scale")
	var pits := 0
	for iz in range(0, samples.y, 2):
		for ix in range(0, samples.x, 2):
			var x := origin.x + ix * step
			var z := origin.y + iz * step
			var old: float = heights.call("height", Vector2(x, z) / s)
			if old > WATER_LEVEL + 0.02 and float(_terrain.call("height_at", x, z)) < WATER_LEVEL:
				pits += 1
	_check("…and meets the same shore (no dry ground sunk under the water level)", pits == 0, "%d points" % pits)
	var bodies := _water_bodies()
	if bodies.size() >= 2:
		var deepest := []
		for body in bodies.slice(0, 2):
			var low := INF
			for t: Vector2i in body["tiles"]:
				low = minf(low, float(_terrain.call("height_at", (t.x + 0.5) * s, (t.y + 0.5) * s)))
			deepest.append(low)
		var sea_i := 0 if bodies[0]["edge"] else 1
		_check("the sea is deeper than the pond", deepest[sea_i] < deepest[1 - sea_i] - 1.0,
			"fond de la mer %.2f m, de la mare %.2f m" % [deepest[sea_i], deepest[1 - sea_i]])


## ZoneTerrain's face, as the rest of the zone uses it: the rain's grass_tint goes through
## `material` and comes back, bed_look gives the bed's tint and shade, height_at answers.
func _check_face() -> void:
	var mat: Object = _terrain.get("material")
	var before: Variant = mat.call("get_shader_parameter", &"grass_tint")
	mat.call("set_shader_parameter", &"grass_tint", Color(0.74, 0.82, 0.86))
	var wet: Variant = mat.call("get_shader_parameter", &"grass_tint")
	mat.call("set_shader_parameter", &"grass_tint", before if before != null else Color.WHITE)
	var bed: Dictionary = load(ZONE_TERRAIN).call("bed_look", &"plaines")
	var masks_ok: bool = mat.call("get_shader_parameter", &"mask_a") != null and mat.call("get_shader_parameter", &"tile_m") == _src.get("scale")
	_check("ZoneTerrain's face: material (grass_tint, the rain), bed_look, the painting's parameters",
		wet is Color and (wet as Color).is_equal_approx(Color(0.74, 0.82, 0.86)) and bed.has("tint") and bed.has("shade") and masks_ok,
		"grass_tint %s, fond %s" % [wet, bed])


## Chloé walks from the arrival for a few seconds: her feet stay on the ground (the height the
## game reads).
func _walk_check(kind: int) -> void:
	await _look(_views[0])
	var worst := 0.0
	var frames := 0
	Input.action_press(&"move_up")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 5000:
		await physics_frame
		var at := _player.global_position
		if _player.call("is_on_floor"):
			worst = maxf(worst, absf(at.y - float(_terrain.call("height_at", at.x, at.z))))
			frames += 1
	Input.action_release(&"move_up")
	_check("Chloé walks on the ground, neither floating nor sinking", worst < FEET_M and frames > 100, "écart max %.3f m sur %d images au sol" % [worst, frames])
	_measures.get_or_add(kind, {})["pieds_m"] = worst


## The cliff of the zone's test (a grass tile at the foot of a cliff rising north): she cannot get up.
func _cliff_check(_kind: int) -> void:
	var foot := _cliff_foot()
	if foot.x < 0:
		print("SKIP  pas de falaise dans la zone")
		return
	var s: float = _src.get("scale")
	var x := (foot.x + 0.5) * s
	var z := (foot.y + 1.5) * s
	_player.call("place_at", Vector3(x, float(_terrain.call("height_at", x, z)) + 0.2, z), PI)
	_pivot.call("set_view", 0.0, -25.0, 4.5)
	await create_timer(0.5).timeout
	Input.action_press(&"move_up")
	await create_timer(2.0).timeout
	Input.action_press(&"jump")
	await create_timer(0.3).timeout
	Input.action_release(&"jump")
	await create_timer(0.6).timeout
	Input.action_release(&"move_up")
	await create_timer(0.6).timeout
	var low: float = _src.call("tile_height", foot)
	_check("a cliff stops her: no climbing, no jumping up", _player.global_position.y < low + 0.4, "y %.2f (pied %.2f)" % [_player.global_position.y, low])


## The dinos, let loose, stand on the ground (the plugin's collision holds them) and walk about
## (their navigation leads them over it).
func _dinos_check() -> void:
	var dinos: Array = _zone.get("dinos").filter(func(d: Node) -> bool: return is_instance_valid(d))
	var start := {}
	for d: Node3D in dinos:
		d.call("calm_down", 0.0)
		start[d] = d.global_position
	var walked := 0
	var worst := 0.0
	var fell := 0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 12000:
		await create_timer(0.5).timeout
		for d: Node3D in dinos:
			if not is_instance_valid(d):
				continue
			var at := d.global_position
			var ground: float = _terrain.call("height_at", at.x, at.z)
			if at.y < ground - 0.5:
				fell += 1
			worst = maxf(worst, absf(at.y - ground))
	for d: Node3D in dinos:
		if is_instance_valid(d) and d.global_position.distance_to(start[d]) > 1.0:
			walked += 1
	_check("the dinos stand on the ground (none fell through)", fell == 0 and dinos.size() > 0 and worst < 0.3,
		"%d dinos, écart max %.2f m au sol en 12 s" % [dinos.size(), worst])
	print("INFO  laissés à eux-mêmes, %d dinos sur %d ont bougé de plus d'un mètre en 12 s (ils broutent et se reposent aussi)" % [walked, dinos.size()])
	_quiet()
	# sent somewhere 12 m off, along their navigation mesh, their own minds held still (Chloé far off,
	# their brain's timer stopped): they make their way there at about their walking pace
	var sent := 0
	var on_pace := 0
	var start_at := {}
	var goals := {}
	var far_off: Array = dinos.filter(func(d: Node) -> bool: return is_instance_valid(d) and (d as Node3D).global_position.distance_to(_player.global_position) > 30.0)
	for d: Node3D in far_off.slice(0, 4):
		var goal: Vector3 = d.call("walkable_point", d.global_position + Vector3(12.0, 0.0, 0.0).rotated(Vector3.UP, sent * 1.7))
		goals[d] = goal
		start_at[d] = d.global_position
		d.get("brain").set("_timer", 1.0e9)
		d.call("go_to", goal, float(d.call("walk_speed")))
		sent += 1
	var secs := 10.0
	await create_timer(secs).timeout
	var report := []
	for d: Node3D in goals:
		if not is_instance_valid(d):
			continue
		var was: float = (start_at[d] - goals[d]).slide(Vector3.UP).length()
		var left: float = (d.global_position - goals[d]).slide(Vector3.UP).length()
		var expected := minf(was, float(d.call("walk_speed")) * secs) * 0.6
		report.append("%.1f m sur %.1f" % [was - left, was])
		on_pace += 1 if was - left >= expected else 0
	_check("…and walk where they are sent, over it", sent > 0 and on_pace * 4 >= sent * 3, "%d sur %d à leur pas (parcouru %s)" % [on_pace, sent, ", ".join(report)])
	_quiet()


## The people of the zone (Npcs3D) stand on the ground.
func _people_check() -> void:
	var npcs: Node = _zone.get("npcs")
	var people: Array = npcs.get("people") if npcs else []
	var worst := 0.0
	for p: Node3D in people:
		var at := p.global_position
		worst = maxf(worst, absf(at.y - float(_terrain.call("height_at", at.x, at.z))))
	if people.is_empty():
		print("SKIP  pas de PNJ dans la zone")
		return
	_check("the people stand on the ground", worst < 0.1, "%d PNJ, écart max %.3f m" % [people.size(), worst])


## The dinos' navigation mesh is baked over the whole ground; its walkable area is kept to
## compare the two grounds (_compare_navigation).
func _navigation_check(kind: int) -> void:
	var region: NavigationRegion3D = _zone.get("navigation")
	var t0 := Time.get_ticks_msec()
	while region.is_baking() and Time.get_ticks_msec() < t0 + 30000:
		await process_frame
	var nm := region.navigation_mesh
	var v := nm.get_vertices()
	var area := 0.0
	for i in nm.get_polygon_count():
		var poly := nm.get_polygon(i)
		for j in range(1, poly.size() - 1):
			area += 0.5 * (v[poly[j]] - v[poly[0]]).cross(v[poly[j + 1]] - v[poly[0]]).length()
	_measures.get_or_add(kind, {})["navigation_m2"] = area
	_measures[kind]["navigation_polygones"] = nm.get_polygon_count()
	if kind == TERRAIN3D:
		_check("the navigation is baked over the ground", area > 40000.0, "%.0f m² en %d polygones" % [area, nm.get_polygon_count()])


## As much walkable ground for the dinos as the old mesh gave, give or take 5 %.
func _compare_navigation() -> void:
	var before: float = _measures.get(MESH, {}).get("navigation_m2", 0.0)
	var now: float = _measures.get(TERRAIN3D, {}).get("navigation_m2", 0.0)
	_check("…as much of it as on the old ground", before > 0.0 and absf(now - before) < before * 0.05, "%.0f m² (ancien sol : %.0f m²)" % [now, before])


## The authoring API on a fresh relief of the zone: each edit does what it says, the rules' heights
## are protected, the painting lands on its tiles, and the zone's edits are read from its file.
func _authoring_check() -> void:
	var R: GDScript = load(RELIEF)
	var relief: RefCounted = R.call("from_source", _src)
	var hill := _calm_spot()
	var before: float = relief.call("height_at", hill.x, hill.y)
	var by_cliff := _by_a_cliff()
	var cliff_before: float = relief.call("height_at", by_cliff.x, by_cliff.y)
	relief.call("apply", [
		{"op": "hill", "at": [hill.x, hill.y], "radius_m": 10, "height_m": 1.5},
		{"op": "hill", "at": [by_cliff.x, by_cliff.y], "radius_m": 6, "height_m": 3.0},
		{"op": "paint", "ground": "sand", "at": [hill.x, hill.y], "radius_m": 4},
	])
	var risen: float = float(relief.call("height_at", hill.x, hill.y)) - before
	_check("TerrainRelief: a hill rises where the ground is free", absf(risen - 1.5) < 0.05, "+%.2f m (1,5 demandé)" % risen)
	var kept: float = float(relief.call("height_at", by_cliff.x, by_cliff.y)) - cliff_before
	_check("…and leaves a cliff's foot alone (protect)", absf(kept) < 0.001, "%+.3f m au pied d'une falaise" % kept)
	var s: float = _src.get("scale")
	var tile := Vector2i(int(hill.x / s), int(hill.y / s))
	var sand: float = (relief.get("mask_b") as Image).get_pixelv(tile).r
	_check("…the painting lands on its tiles (visual only: the rules' tiles do not change)", sand > 0.9 and _src.call("surface", tile) != &"sand",
		"sable %.2f sur la case %s (%s pour les règles)" % [sand, tile, _src.call("surface", tile)])
	var level: float = relief.call("height_at", hill.x + 30.0, hill.y)
	relief.call("apply", [{"op": "flatten", "at": [hill.x, hill.y], "radius_m": 10, "height_m": level},
		{"op": "valley", "at": [hill.x, hill.y], "radius_m": 6, "depth_m": 0.5},
		{"op": "ramp", "from": [hill.x - 8.0, hill.y], "to": [hill.x + 8.0, hill.y], "width_m": 3, "from_h": level, "to_h": level + 1.0}])
	var mid: float = relief.call("height_at", hill.x, hill.y)
	_check("…flatten, valley and ramp (applied in order)", absf(mid - (level + 0.5)) < 0.05, "%.2f m au milieu de la rampe (%.2f attendu)" % [mid, level + 0.5])
	var edits: Array = R.call("edits_of", &"plaines")
	_check("…the zone's edits: its file, else the default (smooth, then dig the sea)", edits.size() >= 1,
		"%s" % [edits.map(func(e: Dictionary) -> String: return String(e.get("op", "?")))])


## The zone's regions saved as Terrain3D's files, then read back by a second ground as the game
## does with hand retouches (ZoneGroundTerrain3D.saved_regions): the same heights.
func _saved_regions_check(ground3d: Node) -> void:
	var dir := "user://test_terrain3d_regions/plaines"
	DirAccess.make_dir_recursive_absolute(dir)
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))
	var err: Error = ground3d.call("save", dir)
	var files: int = load(GROUND).call("saved_files", dir)
	_check("the regions save as Terrain3D's own files (to retouch in the editor)", err == OK and files > 0, "%d fichiers dans %s" % [files, dir])
	var again := await _second_ground(Vector2.ZERO, dir)
	var worst := _worst_gap(again, Vector2.ZERO)
	_check("…and read back to the same heights", worst < 0.001, "écart max %.5f m" % worst)
	again.queue_free()


## The same ground built elsewhere in a shared world: Terrain3D's heights there are the zone's own.
func _offset_check() -> void:
	var moved := await _second_ground(OFFSET, "")
	var worst := _worst_gap(moved, OFFSET)
	_check("the zone placed elsewhere in the world (%s m): the same ground there" % OFFSET, worst < 0.001, "écart max %.5f m" % worst)
	moved.queue_free()


## A second Terrain3D ground of the zone (its relief and painting as the game makes them), at
## `offset`, from `regions_dir` if given.
func _second_ground(offset: Vector2, regions_dir: String) -> Node:
	var R: GDScript = load(RELIEF)
	var relief: RefCounted = R.call("from_source", _src)
	relief.call("apply", _edits())   # (the same as the zone's: not remodelled)
	var ground: Node3D = load(GROUND).new()
	_zone.add_child(ground)
	ground.call("build", relief, offset, _terrain.call("_material"), regions_dir)
	await process_frame
	return ground


## The worst gap between a ground's Terrain3D heights (in the world) and the zone's own ground.
func _worst_gap(ground: Node, offset: Vector2) -> float:
	var data: Object = ground.get("terrain").get("data")
	var size: Vector2 = _src.call("size_m")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var worst := 0.0
	for i in 2000:
		var x := snappedf(rng.randf_range(0.0, size.x), 0.5)
		var z := snappedf(rng.randf_range(0.0, size.y), 0.5)
		worst = maxf(worst, absf(float(data.call("get_height", Vector3(x + offset.x, 0, z + offset.y))) - float(_terrain.call("height_at", x, z))))
	return worst


## Open grass far from cliffs and water (the middle of the calmest stretch).
func _calm_spot() -> Vector2:
	var hills := _hills_view()
	return Vector2(hills.x, hills.z) if hills != Vector3.INF else Vector2(60, 40)


## The middle of a tile at the foot of a cliff.
func _by_a_cliff() -> Vector2:
	var foot := _cliff_foot()
	var s: float = _src.get("scale")
	return (Vector2(foot) + Vector2(0.5, 0.5)) * s


func _report() -> void:
	if not _measures.has(MESH) or not _measures.has(TERRAIN3D) or not _measures[MESH].has("views"):
		return
	var a: Dictionary = _measures[MESH]
	var b: Dictionary = _measures[TERRAIN3D]
	print("MESURE  (maillage maison → Terrain3D, dans ce même lancement)")
	print("MESURE  construction de la zone : %d → %d ms ; du sol seul : %d → %d ms" % [a["build"], b["build"], a["terrain"], b["terrain"]])
	for v in _views:
		var n: String = v["name"]
		print("MESURE  im/s %-22s %5.0f → %5.0f" % [n, a["views"][n], b["views"][n]])
	print("MESURE  mémoire (CPU) %.0f → %.0f Mo ; vidéo %.0f → %.0f Mo" % [a["memoire_mo"], b["memoire_mo"], a["video_mo"], b["video_mo"]])
	print("MESURE  à l'arrivée : triangles %d → %d, appels de dessin %d → %d" % [a["triangles"], b["triangles"], a["appels"], b["appels"]])
	print("MESURE  navigation des dinos : %.0f → %.0f m², %d → %d polygones" % [a["navigation_m2"], b["navigation_m2"], a["navigation_polygones"], b["navigation_polygones"]])
	print("MESURE  sol marché contre hauteurs du 2,5D (ZoneSource), terre ferme : max %.3f → %.3f m, moyenne %.4f → %.4f m" % [
		a["ecart_regles"].x, b["ecart_regles"].x, a["ecart_regles"].y, b["ecart_regles"].y])


# --- finding places --------------------------------------------------------------------------------

## A grass tile at the foot of a cliff that rises to the north (as tools/test_world3d.gd finds it).
func _cliff_foot() -> Vector2i:
	var tiles: Vector2i = _src.get("tiles")
	for y in range(2, tiles.y - 3):
		for x in range(2, tiles.x - 2):
			var top := Vector2i(x, y)
			var foot := Vector2i(x, y + 1)
			var ht: float = _src.call("tile_height", top)
			var hf: float = _src.call("tile_height", foot)
			var behind := foot + Vector2i(0, 1)   # where she starts from: open grass on the foot's level
			if ht > hf and _src.call("is_cliff", ht, hf) and _src.call("surface", foot) == &"grass" and _src.call("surface", behind) == &"grass" \
					and absf(float(_src.call("tile_height", behind)) - hf) < 0.05 and absf(float(_src.call("tile_height", behind + Vector2i(0, 1))) - hf) < 0.05 \
					and absf(float(_src.call("tile_height", foot + Vector2i(-1, 0))) - hf) < 0.05 and absf(float(_src.call("tile_height", foot + Vector2i(1, 0))) - hf) < 0.05:
				return foot
	return Vector2i(-1, -1)


func _cliff_tile(t: Vector2i) -> bool:
	var h: float = _src.call("tile_height", t)
	for n in [t + Vector2i.LEFT, t + Vector2i.RIGHT, t + Vector2i.UP, t + Vector2i.DOWN]:
		if _src.call("is_cliff", h, _src.call("tile_height", n)):
			return true
	return false


func _near_cliff(x: float, z: float, metres: float) -> bool:
	for p in [Vector2(x, z), Vector2(x - metres, z), Vector2(x + metres, z), Vector2(x, z - metres), Vector2(x, z + metres)]:
		if _cliff_tile(_src.call("tile_at", p.x, p.y)):
			return true
	return false


func _land_next_to(t: Vector2i) -> bool:
	for n in [t + Vector2i.LEFT, t + Vector2i.RIGHT, t + Vector2i.UP, t + Vector2i.DOWN]:
		if _src.call("surface", n) != &"water":
			return true
	return false


## The bodies of water, largest first: [{tiles, edge (it reaches the zone's edge: the sea)}].
func _water_bodies() -> Array[Dictionary]:
	var tiles: Vector2i = _src.get("tiles")
	var seen := {}
	var bodies: Array[Dictionary] = []
	for y in tiles.y:
		for x in tiles.x:
			var start := Vector2i(x, y)
			if seen.has(start) or _src.call("surface", start) != &"water":
				continue
			var body: Array[Vector2i] = []
			var queue: Array[Vector2i] = [start]
			seen[start] = true
			var edge := false
			while not queue.is_empty():
				var t: Vector2i = queue.pop_back()
				body.append(t)
				edge = edge or t.x == 0 or t.y == 0 or t.x == tiles.x - 1 or t.y == tiles.y - 1
				for n: Vector2i in [t + Vector2i.LEFT, t + Vector2i.RIGHT, t + Vector2i.UP, t + Vector2i.DOWN]:
					if n.x >= 0 and n.y >= 0 and n.x < tiles.x and n.y < tiles.y and not seen.has(n) and _src.call("surface", n) == &"water":
						seen[n] = true
						queue.append(n)
			bodies.append({"tiles": body, "edge": edge})
	bodies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["tiles"].size() > b["tiles"].size())
	return bodies


## On the beach, facing the open sea: the walkable shore tile with the longest run of sea ahead.
func _shore_view() -> Dictionary:
	var tiles: Vector2i = _src.get("tiles")
	var s: float = _src.get("scale")
	var bodies := _water_bodies()
	var sea := {}
	for body in bodies:
		if body["edge"]:
			for t in body["tiles"]:
				sea[t] = true
	var best := {}
	var best_run := 0
	for y in tiles.y:
		for x in tiles.x:
			var t := Vector2i(x, y)
			if not _src.call("surface", t) in [&"sand", &"grass"]:
				continue
			for dir: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var run := 0
				while sea.has(t + dir * (run + 1)):
					run += 1
				if run > best_run and _flat_behind(t, dir):
					best_run = run
					var at := Vector3((x + 0.5 - dir.x) * s, 0, (y + 0.5 - dir.y) * s)
					best = {"at": at, "yaw": rad_to_deg(atan2(-dir.x, -dir.y))}
	return best


## Open, level ground behind a shore tile (the camera stands there, it must not bump into a dune).
func _flat_behind(t: Vector2i, dir: Vector2i) -> bool:
	var h: float = _src.call("tile_height", t)
	for k in range(1, 7):
		var b := t - dir * k
		if not _src.call("surface", b) in [&"sand", &"grass", &"path"] or absf(float(_src.call("tile_height", b)) - h) > 0.25:
			return false
	return true


## Along a straight dirt path (six path tiles in a row northwards).
func _path_view() -> Dictionary:
	var tiles: Vector2i = _src.get("tiles")
	var s: float = _src.get("scale")
	var arrival: Vector3 = _src.call("spawn", &"DepuisPort")
	var best := {}
	var best_d := INF
	for y in range(6, tiles.y):
		for x in tiles.x:
			var ok := true
			for k in 6:
				if _src.call("surface", Vector2i(x, y - k)) != &"path":
					ok = false
					break
			var at := Vector3((x + 0.5) * s, 0, (y + 0.5) * s)
			var d := at.distance_to(arrival)
			if ok and d > 40.0 and d < best_d:
				best_d = d
				best = {"at": at, "yaw": 0.0}
	return best


## Rolling grass (tiles between 0.4 and 1.6 m high, none a cliff), far from the water.
func _hills_view() -> Vector3:
	var tiles: Vector2i = _src.get("tiles")
	var s: float = _src.get("scale")
	var best := Vector3.INF
	var best_score := 0
	for y in range(4, tiles.y - 4, 2):
		for x in range(4, tiles.x - 4, 2):
			var score := 0
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var t := Vector2i(x + dx, y + dy)
					var h: float = _src.call("tile_height", t)
					if h > 0.4 and h < 1.6 and _src.call("surface", t) == &"grass" and not _cliff_tile(t):
						score += 1
			if score > best_score:
				best_score = score
				best = Vector3((x + 0.5) * s, 0, (y + 0.5) * s)
	return best


# --- helpers ---------------------------------------------------------------------------------------

func _check(what: String, ok: bool, detail: String) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", what, detail])
	if not ok:
		_failed += 1

