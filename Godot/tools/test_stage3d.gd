extends SceneTree
## Stage's moves played in the 3D version (docs/migration-3d.md, phase 5; world3d/story/): the
## staging of the story files, acted out on 3D actors. Checks that the scenes' calls — written in
## the 2.5D's pixels and left unchanged — really move Chloé's model, a dino's model and the camera,
## and that the actor is put back as it was, its body never moved.
##   godot --path Godot --script res://tools/test_stage3d.gd -- out=<folder>
## Prints PASS / FAIL for each check, saves screenshots, quits with 1 on any failure.
## (A window is needed, not --headless. Stage and Story are reached with load(): this script is
## compiled before the autoloads, so their names cannot be written here. A move that waits is
## started without await and given its time with a timer.)

const ZONE := "res://world3d/zone3d/zone_3d.tscn"
const PX := 48.0   # ZoneSource.PX
## Written on every picture of the run: what the whole test checks.
const CAPTION := "Mise en scène 3D — les gestes des scènes (regard, caméra, bow, hop, poses, fondus) sur Chloé et sur un dino"

var _out := "user://test_stage3d"
var _failed := 0
var _zone: Node
var _stage                 # story/stage.gd
var _story                 # story/story.gd
var _world                 # StoryWorld3D, the 3D's stand-in for world.gd
var _chloe: Node2D         # the handle on Player3D
var _dino: Node3D


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_stage3d.json")   # never the player's save
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_stage3d.json"))
	change_scene_to_file(ZONE)
	_run()


func _run() -> void:
	await create_timer(1.5).timeout
	_zone = current_scene
	_stage = load("res://story/stage.gd")
	_story = load("res://story/story.gd")
	# one banner for the whole run (Greg, 04/10: what is checked, in general, left up)
	var banner := ShotCaption.show_on(self, CAPTION)
	await _world_and_actors()
	if _chloe != null:
		await _camera_moves()
		await _chloe_moves()
		await _dino_moves()
		await _poses_and_fades()
	banner.queue_free()
	print("TEST stage3d : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


## The common world: Story.world() gives the 3D's stand-in for world.gd, Chloé as a handle whose
## place is in the 2.5D's pixels, and the zone's actors by name.
func _world_and_actors() -> void:
	_world = _story.call(&"world")
	_check("Story.world() is the 3D's stand-in for world.gd", _world != null and _world.has_method(&"is_3d"), "%s" % [_world])
	if _world == null or not _world.has_method(&"is_3d"):
		return
	_chloe = _stage.call(&"chloe")
	var body: Node3D = _zone.get("player")
	_check("Stage.chloe() gives a handle on Player3D", _chloe != null and _chloe.get("node") == body, "%s" % [_chloe])
	var zone_scale: float = _zone.get("source").get("scale")
	var want := Vector2(body.global_position.x, body.global_position.z) / zone_scale * PX
	_check("…her place, in the 2.5D's pixels", _chloe.global_position.distance_to(want) < 1.0,
		"%s ≈ %s" % [_chloe.global_position, want])
	_check("Stage.chloe() gives the same handle every time", _stage.call(&"chloe") == _chloe)
	_check("no sprite on a 3D actor (the picture moves then do nothing)", _stage.call(&"sprite_of", _chloe) == null)
	var dinos: Array = _zone.get("dinos")
	_dino = dinos.front() if not dinos.is_empty() else null
	_check("a dino of the zone to act with", _dino != null, "%s" % [_dino])
	_check("Story.actor() finds it by name", _story.call(&"actor", String(_dino.name)) != null if _dino else false)
	_story.call(&"lock", true)
	_check("Story.lock() takes the controls from Chloé", bool(body.get("busy")))
	await create_timer(0.3).timeout
	await _shot("stage_00_scene_verrouillee")


## The camera: it leaves Chloé for a place of the zone, comes down for a close-up, goes back.
func _camera_moves() -> void:
	var body: Node3D = _zone.get("player")
	var pivot: Node = body.get("pivot")
	var camera: Camera3D = pivot.get("camera")
	var away := _chloe.global_position + Vector2(240.0, 0.0)   # 5 tiles of the 2.5D away
	_stage.call(&"look_at", away, 1.0)
	await create_timer(1.2).timeout
	_check("Stage.look_at() sends the camera off Chloé", pivot.get("target") != body, "cible %s" % [pivot.get("target")])
	await _shot("stage_01_look_at")
	var wide: float = pivot.call(&"distance")
	_stage.call(&"close_up", away, 3.0, 0.8)
	await create_timer(1.1).timeout
	_check("Stage.close_up() brings it in close", absf(float(pivot.call(&"distance")) - 3.0) < 0.3,
		"%.2f m" % pivot.call(&"distance"))
	await _shot("stage_02_close_up")
	_stage.call(&"wide")
	_check("Stage.wide() puts it back where it was", absf(float(pivot.call(&"distance")) - wide) < 0.1,
		"%.2f m (était %.2f)" % [pivot.call(&"distance"), wide])
	_stage.call(&"shake", 8.0, 0.4)
	await create_timer(0.12).timeout
	_check("Stage.shake() jolts the view", absf(camera.h_offset) + absf(camera.v_offset) > 0.001,
		"décalage %.3f / %.3f" % [camera.h_offset, camera.v_offset])
	await create_timer(0.8).timeout
	_check("…and leaves it straight again", absf(camera.h_offset) + absf(camera.v_offset) < 0.0001,
		"%.4f / %.4f" % [camera.h_offset, camera.v_offset])
	_stage.call(&"look_back", 0.6)
	await create_timer(0.8).timeout
	_check("Stage.look_back() brings it back to Chloé", pivot.get("target") == body)


## Chloé: she turns, hops, shivers, steps back — her model moves, her body does not, and it is put
## back as it was.
func _chloe_moves() -> void:
	var body: Node3D = _zone.get("player")
	var model: Node3D = body.get_node("Model")
	var rest: Vector3 = model.position
	var stood := body.global_position
	var target := _chloe.global_position + Vector2(96.0, 96.0)

	_stage.call(&"turn_to", _chloe, target)
	await create_timer(0.1).timeout
	var want: Vector3 = _world.call(&"to_3d", target)
	var to := (want - body.global_position).slide(Vector3.UP)
	_check("Stage.turn_to() turns her model that way",
		absf(angle_difference(model.rotation.y, atan2(to.x, to.z))) < 0.2,
		"%.1f° au lieu de %.1f°" % [rad_to_deg(model.rotation.y), rad_to_deg(atan2(to.x, to.z))])

	_stage.call(&"hop", _chloe, 2, 14.0)
	var lifted := await _watch(model, rest, 30)
	_check("Stage.hop() lifts her model off the ground", lifted.y > 0.1, "montée %.2f m" % lifted.y)
	await create_timer(0.5).timeout
	_check("…and puts it back", model.position.distance_to(rest) < 0.01, "%s" % [model.position - rest])

	_stage.call(&"tremble", _chloe, 0.6, 4.0)
	var shivered := await _watch(model, rest, 30)
	_check("Stage.tremble() shivers it sideways", shivered.x > 0.02 or shivered.z > 0.02,
		"écart %.3f / %.3f m" % [shivered.x, shivered.z])
	await create_timer(0.5).timeout

	_stage.call(&"recoil", _chloe, target, 20.0)
	var stepped := await _watch(model, rest, 20)
	_check("Stage.recoil() steps her model back", stepped.length() > 0.2, "pas de %.2f m" % stepped.length())
	_check("…her body never left its place", body.global_position.distance_to(stood) < 0.05,
		"%s" % [body.global_position - stood])
	await create_timer(0.7).timeout

	_stage.call(&"emote", _chloe, "!")
	await create_timer(0.2).timeout
	_check("Stage.emote() floats a sign over her head", _zone.find_children("*", "Label3D", true, false).size() > 0)
	await _shot("stage_03_chloe_hop_emote")

	_stage.call(&"glow", _chloe, Color(1.8, 1.45, 0.8), 1, 0.6)
	await create_timer(0.3).timeout
	var lights := _zone.find_children("*", "OmniLight3D", true, false)
	_check("Stage.glow() lights her with that colour", lights.size() > 0, "%d lumière(s)" % lights.size())
	await create_timer(0.8).timeout


## A dino of the zone: it bows, rears, throws itself at Chloé and cries, and is put back as it was.
func _dino_moves() -> void:
	if _dino == null:
		return
	var handle: Node2D = _world.call(&"handle", _dino)
	var model: Node3D = _dino.get_node("Model")
	var rest: Vector3 = model.position
	var rest_pitch: float = model.rotation.x
	var stood := _dino.global_position
	_dino.set_physics_process(false)   # (its own life aside: only Stage's move shows on the picture)
	_dino.get("animator").call(&"release")   # (standing, not grazing)
	_stage.call(&"close_up", handle.global_position, 4.0, 1.0)
	await create_timer(1.3).timeout

	_stage.call(&"bow", handle, 0.9)
	await create_timer(0.35).timeout
	_check("Stage.bow() tips the dino's model forward", absf(model.rotation.x - rest_pitch) > 0.05,
		"%.1f°" % rad_to_deg(model.rotation.x - rest_pitch))
	await _shot("stage_04_dino_bow")
	await create_timer(0.9).timeout
	_check("…and puts it back up", absf(model.rotation.x - rest_pitch) < 0.01,
		"%.2f°" % rad_to_deg(model.rotation.x - rest_pitch))

	_stage.call(&"rear", handle, 1.0)
	await create_timer(0.35).timeout
	_check("Stage.rear() rears it up", model.rotation.x - rest_pitch < -0.05 and model.position.y > rest.y + 0.004,
		"%.1f°, +%.3f m" % [rad_to_deg(model.rotation.x - rest_pitch), model.position.y - rest.y])
	await _shot("stage_05_dino_rear")
	await create_timer(1.1).timeout

	_stage.call(&"lunge", handle, _chloe.global_position, 1.5, true)
	var thrown := await _watch(model, rest, 15)
	_check("Stage.lunge() throws its model at Chloé", thrown.length() > 0.1, "élan de %.2f m" % thrown.length())
	_check("…its body never left its place", _dino.global_position.distance_to(stood) < 0.05,
		"%s" % [_dino.global_position - stood])
	await create_timer(0.7).timeout

	var raging: Tween = _stage.call(&"rage", handle, _chloe.global_position, 0.2)
	_check("Stage.rage() starts a looping move", raging != null and raging.is_valid())
	await create_timer(0.6).timeout
	_stage.call(&"stop", handle, raging)
	_check("Stage.stop() ends it and puts the model back",
		(raging == null or not raging.is_valid()) and model.position.distance_to(rest) < 0.01,
		"%s" % [model.position - rest])
	_dino.set_physics_process(true)
	_stage.call(&"look_back", 0.5)
	await create_timer(0.7).timeout

	var lead = _world.get("companion")
	var companion: Node3D = lead.get("node") if lead else null
	var lead_model: Node3D = companion.get_node("Model") if companion else null
	_check("Chloé's lead dino is there to act too", companion != null, "%s" % [companion])
	if lead_model == null:
		return
	_stage.call(&"companion_joy")
	var jumped := await _watch(lead_model, Vector3.ZERO, 25)
	_check("Stage.companion_joy() makes it jump for joy", jumped.y > 0.1, "montée %.2f m" % jumped.y)
	await create_timer(0.6).timeout
	_stage.call(&"companion_to", _chloe.global_position)
	var ran := await _watch(lead_model, Vector3.ZERO, 15)
	_check("Stage.companion_to() sends it at a point…", ran.length() > 0.1, "élan de %.2f m" % ran.length())
	await create_timer(0.7).timeout
	_check("…and brings it back", lead_model.position.length() < 0.01, "%s" % [lead_model.position])


## Poses held and fades: the clips of the model instead of the 2.5D's drawn poses.
func _poses_and_fades() -> void:
	var body: Node3D = _zone.get("player")
	var animator: Node = body.get("animator")
	var crouching := bool(_stage.call(&"pose", _chloe, &"accroupi"))
	await create_timer(0.6).timeout
	_check("Stage.pose(&\"accroupi\") holds her crouch clip", crouching and bool(animator.call(&"holding")))
	await _shot("stage_06_chloe_accroupie")
	_stage.call(&"pose", _chloe, &"")
	await create_timer(0.5).timeout
	_check("…and Stage.pose(&\"\") stands her up again", not bool(animator.call(&"holding")))
	_stage.call(&"sit", _chloe, 0.3)
	await create_timer(1.2).timeout
	_check("Stage.sit() sits her down", bool(animator.call(&"holding")))
	await _shot("stage_07_chloe_assise")
	_stage.call(&"pose", _chloe, &"")
	_check("Stage.dress() does nothing in 3D rather than fail", not bool(_stage.call(&"dress", _chloe, &"bocal")))
	_check("Stage.show_thing() gives no prop it cannot show",
		_stage.call(&"show_thing", "caisse", Vector2(1000.0, 1000.0), "Caisse") == null)

	var meshes := body.get_node("Model").find_children("*", "GeometryInstance3D", true, false)
	_stage.call(&"fade_out", _chloe, 0.4)
	await create_timer(0.7).timeout
	_check("Stage.fade_out() makes her vanish", float(meshes.front().transparency) > 0.9,
		"%.2f" % meshes.front().transparency)
	await _shot("stage_08_chloe_fondue")
	_stage.call(&"fade_in", _chloe, 0.4)
	await create_timer(0.7).timeout
	_check("Stage.fade_in() brings her back", float(meshes.front().transparency) < 0.1,
		"%.2f" % meshes.front().transparency)
	_story.call(&"lock", false)
	_check("the end of a scene gives the camera back to Chloé", body.get("pivot").get("target") == body)
	_check("…and the controls too", not bool(body.get("busy")))
	await _shot("stage_09_fin_de_scene")


## Watches a model while a move plays: how far it got from `rest` on each axis (the biggest gap).
func _watch(model: Node3D, rest: Vector3, frames: int) -> Vector3:
	var most := Vector3.ZERO
	for i in frames:
		await process_frame
		var gap := (model.position - rest).abs()
		most = Vector3(maxf(most.x, gap.x), maxf(most.y, gap.y), maxf(most.z, gap.z))
	return most


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


## A picture of the test, under the banner put up for the whole run.
func _shot(file_name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(file_name + ".png"))
