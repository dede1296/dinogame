extends SceneTree
## The little life of the 3D zones (world3d/zone3d/wildlife_3d.gd), checked in the real engine (it
## needs a window to render, so not --headless):
##   godot --path Godot --script res://tools/test_wildlife_3d.gd -- out=<folder> [zones=plaines,foret,desert]
## For each zone (built in 3D from the 2.5D one): the kinds of its kind of place (WildlifeDB) are
## there, as many as the 2.5D's times Wildlife3D.DENSITY; by day, in clear weather, those of the day
## come out, not those of the night; on foot they stand on the ground (none buried, none floating),
## out of the water and off the paths; the flyers above the ground. In the Prairie: in the rain they
## shelter; at night the fireflies are lit and the butterflies gone; the frames per second with the
## life and without it. In the woods, the mosquitoes come round Chloé's head. A picture of each zone
## by day and one close up on its own animal (one caption for the whole run).
## (Game classes are reached through the nodes only: this script is compiled before the autoloads.)

const ZONE := "res://world3d/zone3d/zone_3d.tscn"
const DB := "res://data/wildlife_db.gd"
const CAPTION := "Petite faune 3D — espèces du milieu, au sol, hors de l'eau et des sentiers, jour, pluie et nuit"
## The zones: the animal looked at close up, the ground Chloé starts on (one of its arrival points on
## it; none listed: its first arrival point).
const ZONES := {&"plaines": [&"papillon", []], &"foret": [&"moustique", [&"forest"]], &"desert": [&"scorpion", [&"sand"]],
	&"marais": [&"grenouille", [&"mud"]]}
const DENSITY := 2.0          # Wildlife3D.DENSITY
const MAX_SWARMS := 16        # Wildlife3DLooks.MAX_SWARMS
const WET_M := 0.03
const FLY_CLEAR_M := 0.15
const LOOK_HEIGHT := 1.2      # CameraPivot.LOOK_HEIGHT: it looks this far above its target
const HEAD_M := 1.35          # Wildlife3D.PESTER_HEAD_M

var _out := "user://test_wildlife_3d"
var _zones: Array = ZONES.keys()
var _failed := 0
var _zone: Node3D
var _player: Node3D
var _pivot: Node3D
var _life: Node3D
var _spawn: StringName


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("zones="):
			_zones = Array(arg.substr(6).split(",")).map(func(s: String) -> StringName: return StringName(s))
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://capture_save.json")   # never the player's save
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://capture_save.json"))
	_run()


func _run() -> void:
	await process_frame
	var caption := ShotCaption.show_on(self, CAPTION)
	for id: StringName in _zones:
		await _one_zone(id)
	caption.queue_free()
	print("TEST faune 3D : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


func _one_zone(id: StringName) -> void:
	var zone: Node = load(ZONE).instantiate()
	zone.set("zone_id", id)
	zone.set("arrival", &"Depart" if id != &"plaines" else &"DepuisPort")
	change_scene_to_node(zone)
	await create_timer(1.5).timeout
	_zone = current_scene
	_player = _zone.get("player")
	_pivot = _player.get("pivot")
	_life = _zone.get_node_or_null("Wildlife")
	_check("%s : the zone has its little life (Wildlife3D)" % id, _life != null, "")
	if _life == null:
		return
	_quiet()
	root.get_node("Game").set("clock", 11.0 * 60.0)
	await _clear_sky()
	_counts(id)
	_spawn = _spawn_on(ZONES[id][1])
	await _look_round()
	_by_day(id)
	await _shot("%s_jour" % id)
	if id == &"plaines":
		await _rain()
	if ZONES[id][0] == &"moustique":
		await _pestered(id)
	else:
		await _close_up(id, ZONES[id][0])
	if id == &"plaines":
		await _fps()
		await _night()
	await create_timer(0.5).timeout   # (the hour set back: the zone takes it in before it goes)


## No battle while the life is looked at: no hidden dinos in the tall grass, the others calm.
func _quiet() -> void:
	var enc: Node = _zone.get("session").get("encounters")
	if enc:
		enc.set_physics_process(false)
	for d in _zone.get("dinos"):
		d.call("calm_down", 9999.0)


## A clear sky (the weather rolled when the hour changed), once the rain and the mist have gone.
func _clear_sky() -> void:
	await process_frame
	await process_frame
	root.get_node("Game").call("set_weather", &"clear")
	var weather: Node = _zone.get("weather")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 12000 and (float(weather.get("mist_amount")) > 0.02 or float(weather.get("rain_amount")) > 0.02):
		await process_frame


## The first arrival point of the zone on one of `grounds` (as the life reads the ground).
func _spawn_on(grounds: Array) -> StringName:
	var fallback: StringName = _zone.get("arrival")
	if grounds.is_empty():
		return fallback
	var src: RefCounted = _zone.get("source")
	var spawns: Node = (src.get("region") as Node).get_node("Spawns")
	for marker in spawns.get_children():
		var at: Vector3 = src.call("spawn", marker.name)
		if _life.get("land").call("surface", Vector2(at.x, at.z)) in grounds:
			return StringName(marker.name)
	return fallback


## Chloé at her start, the camera behind her; a moment for each to come out after its rest.
func _look_round() -> void:
	_zone.call("place", _spawn)
	_pivot.call("set_view", 200.0, -16.0, 6.0)
	_pivot.call("snap")
	await create_timer(4.0).timeout


## The kinds of the place, as many as the 2.5D's times DENSITY (Quality.scaled).
func _counts(id: StringName) -> void:
	var place: StringName = _life.get("place")
	var counts: Dictionary = _life.call("counts")
	var quality := root.get_node("Quality")
	var wrong: Array[String] = []
	var swarms := 0
	for kind: Dictionary in load(DB).call("kinds_of", place):
		var want: int = quality.call("scaled", roundi(float(kind["count"]) * DENSITY))
		if kind["motion"] == &"swarm":
			want = mini(want, MAX_SWARMS - swarms)
			swarms += want
		if counts.get(kind["id"], -1) != want:
			wrong.append("%s %d (attendu %d)" % [kind["id"], counts.get(kind["id"], -1), want])
	print("MESURE  %s (milieu « %s ») : %s" % [id, place, counts])
	_check("%s : every kind of « %s », as many as the 2.5D's × %.0f" % [id, place, DENSITY], wrong.is_empty() and not counts.is_empty(), "%s" % [wrong])


## By day: some are out, none of the night; each where it should be.
func _by_day(id: StringName) -> void:
	var terrain: Node = _zone.get("terrain")
	var out: Array = _life.call("out_now")
	var kinds := {}
	var night: Array[String] = []
	var buried: Array[String] = []
	var wet: Array[String] = []
	var low: Array[String] = []
	for b: Dictionary in out:
		kinds[b["id"]] = kinds.get(b["id"], 0) + 1
		if b["id"] == &"mammifere":
			night.append(String(b["id"]))
		var at: Vector3 = b["at"]
		var ground := float(terrain.call("height_at", at.x, at.z))
		var water := float(terrain.call("water_level_at", at.x, at.z))
		if b["motion"] == &"walk":
			if absf(at.y - ground) > 0.02:
				buried.append("%s %+.2f m" % [b["id"], at.y - ground])
			if b["ground"] in [&"water", &"path"] or float(terrain.call("water_depth_at", at.x, at.z)) > WET_M:
				wet.append("%s sur %s" % [b["id"], b["ground"]])
		elif b["motion"] == &"hop":
			if at.y < ground - 0.02:
				buried.append("%s %+.2f m" % [b["id"], at.y - ground])
		elif b["motion"] in [&"flutter", &"dart", &"swarm"]:
			if at.y < maxf(ground, water) + FLY_CLEAR_M - 0.01:
				low.append("%s %.2f m" % [b["id"], at.y - maxf(ground, water)])
	print("MESURE  %s, 11 h, départ « %s » : dehors %s" % [id, _spawn, kinds])
	_check("%s : by day, the life of the day is out" % id, not kinds.is_empty(), "%d bêtes" % out.size())
	_check("%s : …none of the night (the small mammal)" % id, night.is_empty(), "%s" % [night])
	_check("%s : …on foot, on the ground (none buried, none floating)" % id, buried.is_empty(), "%s" % [buried])
	_check("%s : …off the water and the paths" % id, wet.is_empty(), "%s" % [wet])
	_check("%s : …the flyers above the ground and the water" % id, low.is_empty(), "%s" % [low])


## In the rain the life shelters: only the kinds out in the rain too (WildlifeDB "rain") stay out.
func _rain() -> void:
	var game := root.get_node("Game")
	game.call("set_weather", &"rain")
	await create_timer(0.5).timeout
	var kinds: Dictionary = load(DB).get_script_constant_map()["KINDS"]
	var stayed: Array[String] = []
	for b: Dictionary in _life.call("out_now"):
		if not kinds[b["id"]].get("rain", false):
			stayed.append(String(b["id"]))
	_check("plaines : in the rain, they shelter (but those out in the rain)", stayed.is_empty(), "%s" % [stayed])
	await _clear_sky()
	await create_timer(3.0).timeout


## The camera close to one of `kind` (followed a moment), Chloé a few metres off (not to scare it).
func _close_up(id: StringName, kind: StringName) -> void:
	var beast := _one_out(kind)
	if beast == null:
		print("SKIP  %s : gros plan (%s pas dehors en ce moment)" % [id, kind])
		return
	var marker := Node3D.new()
	_zone.add_child(marker)
	var pos: Vector3 = beast.get("pos")
	marker.position = pos - Vector3(0, LOOK_HEIGHT - 0.1, 0)
	_zone.call("place_at", pos + Vector3(4.5, 0.0, 4.5))
	_pivot.set("target", marker)
	_pivot.call("set_view", 200.0, -20.0, 2.4)
	_pivot.call("snap")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 1200:
		await process_frame
		marker.position = (beast.get("pos") as Vector3) - Vector3(0, LOOK_HEIGHT - 0.1, 0)
	await _shot("%s_gros_plan_%s" % [id, kind])
	_pivot.set("target", _player)
	marker.queue_free()
	_zone.call("place", _spawn)
	_pivot.call("snap")


## Chloé walks up to a swarm (2 m off): it comes round her head.
func _pestered(id: StringName) -> void:
	var swarm := _one_out(&"moustique")
	if swarm == null:
		print("SKIP  %s : moustiques (aucune nuée dehors)" % id)
		return
	var at: Vector3 = swarm.get("pos")
	_zone.call("place_at", at + Vector3(2.0, 0.0, 0.0), 90.0)
	_pivot.call("set_view", 150.0, -12.0, 2.8)
	_pivot.call("snap")
	await create_timer(2.5).timeout
	var head: Vector3 = _player.global_position + Vector3(0, HEAD_M, 0)
	var gap := (swarm.get("pos") as Vector3).distance_to(head)
	_check("%s : the mosquitoes come round Chloé's head" % id, gap < 1.0, "nuée à %.2f m de sa tête" % gap)
	await _shot("%s_gros_plan_moustiques" % id)
	_zone.call("place", _spawn)
	_pivot.call("snap")


## One animal of `kind` out now (Wildlife3D's own, to follow it), or null.
func _one_out(kind: StringName) -> Object:
	for f: Object in _life.get("_flocks"):
		if f.get("kind")["id"] != kind:
			continue
		for b: Object in f.get("beasts"):
			if b.get("out"):
				return b
	return null


## At night: the fireflies lit, the butterflies gone, the small mammal out (if its ground is near).
func _night() -> void:
	var game := root.get_node("Game")
	game.set("clock", 22.5 * 60.0)
	await _clear_sky()
	await _look_round()
	var lit: Array = _life.call("effects_on")
	var out := {}
	for b: Dictionary in _life.call("out_now"):
		out[b["id"]] = out.get(b["id"], 0) + 1
	print("MESURE  plaines, 22 h 30 : dehors %s, lumières %s" % [out, lit])
	_check("plaines : at night, the fireflies are lit", &"lucioles" in lit, "%s" % [lit])
	_check("plaines : …the butterflies are gone", not out.has(&"papillon"), "%s" % [out])
	await _shot("plaines_nuit")
	game.set("clock", 11.0 * 60.0)


## The frames per second at the arrival, vsync off, framed as test_world3d.gd's phase 4 measures them
## (Zone3D.place: the camera behind her, over the Prairie): with the life, then without it.
func _fps() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_zone.call("place", _spawn)
	await create_timer(1.0).timeout
	var with_life := await _frames_per_s()
	_life.visible = false
	_life.process_mode = Node.PROCESS_MODE_DISABLED
	await create_timer(0.5).timeout
	var without := await _frames_per_s()
	_life.visible = true
	_life.process_mode = Node.PROCESS_MODE_INHERIT
	print("MESURE  im/s à l'arrivée de la Prairie : %.0f avec la faune, %.0f sans" % [with_life, without])
	_check("plaines : the life costs next to nothing (≥ 90 % of the frames/s without it)", with_life >= without * 0.9,
		"%.0f contre %.0f im/s" % [with_life, without])
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)


func _frames_per_s() -> float:
	var frames := 0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 3000:
		await process_frame
		frames += 1
	return frames / 3.0


func _check(what: String, ok: bool, detail: String) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", what, detail])
	if not ok:
		_failed += 1


func _shot(name: String) -> void:
	await process_frame
	var path := _out.path_join(name + ".png")
	root.get_viewport().get_texture().get_image().save_png(path)
	print("IMAGE  %s" % ProjectSettings.globalize_path(path))
