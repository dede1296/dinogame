extends SceneTree
## Chloé's hair and backpack springs (world3d/player/chloe_hair*.gd, assets3d_src/chloe/cheveux.md),
## checked in the real engine, in the 3D demo:
##   godot --path Godot --script res://tools/test_chloe_hair.gd -- out=<folder>
## Standing still, the ponytail, the lock and the backpack stay where she wears them (only a little
## droop); running, the ponytail swings and the backpack sways; once she stops they settle back;
## running and jumping, the ponytail never goes into her head, her back or her backpack; a teleport
## does not lash the hair across the distance. Two pictures (running, jumping), one caption.

const DEMO := "res://world3d/demo/demo_3d.tscn"
## chain → [end bone, length of its end (m)] (chloe_hair_import.gd CHAINS)
const ENDS := {&"queue": [&"hair_pony_05", 0.06], &"mèche": [&"hair_lock_03", 0.035], &"sac": [&"pack_hang", 0.25]}
const ROOTS := {&"queue": &"hair_pony_01", &"mèche": &"hair_lock_01", &"sac": &"pack_hang"}
const PONY := [&"hair_pony_02", &"hair_pony_03", &"hair_pony_04", &"hair_pony_05"]
const PONY_RADIUS := 0.025
const TOLERANCE := 0.01   # m of overlap allowed (the joints are checked once a frame)

var _out := "user://test_chloe_hair"
var _failed := 0
var _demo: Node
var _player: Node3D
var _pivot: Node3D
var _skel: Skeleton3D
var _sim: SpringBoneSimulator3D
## The poses a modifier makes are only there while it reports them (modification_processed):
## the readings of the last frame, taken then.
var _last_offsets := {}
var _last_gap := INF
var _readings := 0
var _worst_gap := INF     # the deepest the ponytail went into a collider, and which one
var _worst_with := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://capture_save.json")   # never the player's save
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://capture_save.json"))
	change_scene_to_file(DEMO)
	_run()


func _run() -> void:
	await create_timer(1.2).timeout
	_demo = current_scene
	_player = _demo.get("player")
	_pivot = _player.get("pivot")
	ShotCaption.show_on(self, "Chloé — cheveux et sac qui suivent ses mouvements (os à ressort)")
	_skel = _player.get("model").find_children("*", "Skeleton3D", true, false).front() as Skeleton3D
	_sim = _skel.get_node_or_null("HairSprings") as SpringBoneSimulator3D
	_check("the springs are in her model", _sim != null and _sim.setting_count == 3, "%s" % _sim)
	if _sim == null:
		_finish()
		return
	_sim.modification_processed.connect(_read)
	await create_timer(0.3).timeout
	_check("…and they run", _readings > 5, "%d lectures" % _readings)
	for i in _sim.setting_count:
		print("INFO réglage %d : %s -> %s, %d articulations" % [i, _sim.get_root_bone_name(i), _sim.get_end_bone_name(i), _sim.get_joint_count(i)])
	for name in ["Head", "UpperBack", "Shoulders", "Backpack", "LowerBack"]:
		var shape := _sim.get_node_or_null(name) as SpringBoneCollision3D
		if shape:
			print("INFO obstacle %-9s dans le squelette %s axe %s | os %s décalage %s %s" % [name, (_skel.global_transform.affine_inverse() * shape.global_transform.origin).snapped(Vector3.ONE * 0.001), shape.global_transform.basis.y.normalized().snapped(Vector3.ONE * 0.01), shape.bone_name, shape.position_offset, shape.rotation_offset])
	# standing
	_demo.call("place", &"start")
	await create_timer(2.0).timeout
	var still := await _offsets(0.5)
	_check("standing: the ponytail hangs where she wears it", still[&"queue"] < 0.06, "%.1f cm" % (still[&"queue"] * 100))
	_check("…the lock too", still[&"mèche"] < 0.015, "%.1f cm" % (still[&"mèche"] * 100))
	_check("…and the backpack", still[&"sac"] < 0.03, "%.1f cm" % (still[&"sac"] * 100))
	var gap := await _closest(0.3)
	_check("…resting on her backpack at most, not pushed into anything", gap > -TOLERANCE, "marge %.1f cm" % (gap * 100))
	# running (seen from the side)
	_pivot.call("set_view", 0.0, -8.0, 4.0)
	await create_timer(0.4).timeout
	Input.action_press(&"move_right")
	Input.action_press(&"run")
	await create_timer(0.4).timeout
	var strip := _strip_start()
	var moving := await _offsets(1.2, strip)
	_save_strip(strip, "cheveux_course")
	gap = await _closest(0.6)
	Input.action_release(&"run")
	Input.action_release(&"move_right")
	_check("running: the ponytail swings (with her strides, not streaming out)", moving[&"queue_max"] > 0.01 and moving[&"queue_max"] < 0.15, "jusqu'à %.1f cm" % (moving[&"queue_max"] * 100))
	_check("…the backpack sways a little", moving[&"sac_max"] > 0.003 and moving[&"sac_max"] < 0.10, "jusqu'à %.1f cm" % (moving[&"sac_max"] * 100))
	_check("…never into her head, back or backpack", gap > -TOLERANCE, "marge %.1f cm" % (gap * 100))
	# settling
	await create_timer(2.5).timeout
	var after := await _offsets(0.5)
	_check("stopped: it all settles back", absf(after[&"queue"] - still[&"queue"]) < 0.02 and absf(after[&"sac"] - still[&"sac"]) < 0.02,
		"queue %.1f cm (debout %.1f), sac %.1f cm" % [after[&"queue"] * 100, still[&"queue"] * 100, after[&"sac"] * 100])
	# jumping forward, seen from the side
	_demo.call("place", &"start")
	_pivot.call("set_view", 0.0, -8.0, 4.0)
	await create_timer(1.5).timeout
	Input.action_press(&"move_right")
	_press(&"jump", 0.4)
	strip = _strip_start()
	var jumping := await _offsets(1.0, strip)
	_save_strip(strip, "cheveux_saut")
	Input.action_release(&"move_right")
	gap = jumping[&"gap"]
	_check("jumping: the ponytail stays off the backpack", gap > -TOLERANCE, "marge %.1f cm, queue jusqu'à %.1f cm" % [gap * 100, jumping[&"queue_max"] * 100])
	# a teleport
	await create_timer(1.5).timeout
	_demo.call("place", &"far_away")
	var jump := await _offsets(0.3)
	_check("a teleport does not lash the hair", jump[&"queue_max"] < 0.15, "jusqu'à %.1f cm" % (jump[&"queue_max"] * 100))
	_finish()


func _finish() -> void:
	print("INFO plus près d'un obstacle : %.1f cm (%s)" % [_worst_gap * 100, _worst_with])
	print("TEST cheveux : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


## Over `secs`: per chain, the mean and the largest distance between the end of the chain and
## where a rigid one would be (the parent's pose and the rest of each bone), and the smallest gap
## between the ponytail and the colliders. `strip`: frames to grab on the way.
func _offsets(secs: float, strip: Dictionary = {}) -> Dictionary:
	var sums := {}
	var out := {&"gap": INF}
	var frames := 0
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	var next_grab := Time.get_ticks_msec()
	while Time.get_ticks_msec() < end:
		await process_frame
		frames += 1
		for chain: StringName in ENDS:
			var d: float = _last_offsets.get(chain, 0.0)
			if not is_finite(d):
				_check("finite pose (%s)" % chain, false, "NaN")
				d = 1.0
			sums[chain] = float(sums.get(chain, 0.0)) + d
			out[StringName(chain + "_max")] = maxf(float(out.get(StringName(chain + "_max"), 0.0)), d)
		out[&"gap"] = minf(out[&"gap"], _last_gap)
		if not strip.is_empty() and Time.get_ticks_msec() >= next_grab and (strip.frames as Array).size() < 10:
			_grab(strip)
			next_grab += 100
	for chain: StringName in ENDS:
		out[chain] = float(sums[chain]) / maxi(frames, 1)
	return out


func _closest(secs: float) -> float:
	var gap := INF
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame
		gap = minf(gap, _last_gap)
	return gap


func _read() -> void:
	_readings += 1
	for chain: StringName in ENDS:
		_last_offsets[chain] = _offset(chain)
	_last_gap = _gap()


func _offset(chain: StringName) -> float:
	var end_bone := _skel.find_bone(ENDS[chain][0])
	var length: float = ENDS[chain][1]
	var root_bone := _skel.find_bone(ROOTS[chain])
	var t := Transform3D.IDENTITY
	var b := end_bone
	while true:
		t = _skel.get_bone_rest(b) * t
		if b == root_bone:
			break
		b = _skel.get_bone_parent(b)
	var rigid := _skel.get_bone_global_pose(_skel.get_bone_parent(root_bone)) * t * Vector3(0.0, length, 0.0)
	var real := _skel.get_bone_global_pose(end_bone) * Vector3(0.0, length, 0.0)
	return rigid.distance_to(real)


## Smallest distance between a ponytail joint (or its tip) and the colliders it meets, less their radii.
func _gap() -> float:
	var points: Array[Vector3] = []
	for name: StringName in PONY:
		points.append(_skel.global_transform * _skel.get_bone_global_pose(_skel.find_bone(name)).origin)
	points.append(_skel.global_transform * (_skel.get_bone_global_pose(_skel.find_bone(&"hair_pony_05")) * Vector3(0.0, 0.06, 0.0)))
	var best := INF
	var worst_name := ""
	for name in ["Head", "UpperBack", "Shoulders", "Backpack"]:
		var shape := _sim.get_node_or_null(name) as SpringBoneCollision3D
		if shape == null:
			continue
		# from this frame's pose (the node itself is moved a frame later: 8 cm at a run)
		var at := _skel.global_transform * _skel.get_bone_global_pose(_skel.find_bone(shape.bone_name)) \
			* Transform3D(Basis(shape.rotation_offset), shape.position_offset)
		var radius: float = shape.get(&"radius")
		var half := 0.0
		if shape is SpringBoneCollisionCapsule3D:
			half = maxf(0.0, (shape as SpringBoneCollisionCapsule3D).height * 0.5 - radius)
		var axis := at.basis.y.normalized()
		var inv := _skel.global_transform.affine_inverse()
		for k in points.size():
			var p := points[k]
			var s := clampf((p - at.origin).dot(axis), -half, half)
			var g := p.distance_to(at.origin + axis * s) - radius - PONY_RADIUS
			if g < best:
				best = g
				worst_name = "%s, point %d en %s, obstacle en %s axe %s" % [name, k, (inv * p).snapped(Vector3.ONE * 0.001),
					(inv * at.origin).snapped(Vector3.ONE * 0.001), (inv.basis * axis).normalized().snapped(Vector3.ONE * 0.01)]
	if best < _worst_gap:
		_worst_gap = best
		_worst_with = "%s, image %d" % [worst_name, Engine.get_process_frames()]
	return best


func _strip_start() -> Dictionary:
	return {"frames": []}


func _grab(strip: Dictionary) -> void:
	var full := root.get_viewport().get_texture().get_image()
	var w := int(full.get_width() * 0.22)
	(strip.frames as Array).append(full.get_region(Rect2i(int(full.get_width() * 0.5 - w * 0.5), int(full.get_height() * 0.12), w, int(full.get_height() * 0.62))))


func _save_strip(strip: Dictionary, name: String) -> void:
	var frames: Array = strip.frames
	if frames.is_empty():
		return
	var first: Image = frames[0]
	var sheet := Image.create(first.get_width() * frames.size(), first.get_height(), false, first.get_format())
	for i in frames.size():
		sheet.blit_rect(frames[i], Rect2i(Vector2i.ZERO, first.get_size()), Vector2i(i * first.get_width(), 0))
	sheet.save_png(_out.path_join(name + ".png"))


func _press(action: StringName, hold := 0.05) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await create_timer(hold).timeout
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _check(what: String, ok: bool, detail: String) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", what, detail])
	if not ok:
		_failed += 1
