extends SceneTree
## The five forest dinos of the Quaternius family (allosaurus, brachiosaurus, deinonychus,
## microraptor, troodon), checked in the real engine after their pose fix (05/10). Needs a window:
##   godot --path Godot --script res://tools/test_dinos_foret_3d.gd -- out=<folder>
## On the flat meadow of the 3D demo, each one stands in idle, side on, next to Chloé (1.50 m):
## one picture per species, one caption for the whole run. Prints its shown size and the lowest
## point of its posed model against the ground (feet on the floor, nothing under it).
## (Game classes are reached through load(): this script is compiled before the autoloads.)

const DEMO := "res://world3d/demo/demo_3d.tscn"
const DINO := "res://world3d/creatures/dinosaur_3d.gd"
const SIZE := "res://world3d/creatures/model_size.gd"
const SPECIES: Array[StringName] = [&"allosaurus", &"brachiosaurus", &"deinonychus", &"microraptor", &"troodon"]
const CAPTION := "Forêt — finition des cinq dinos Quaternius : pose et taille"
const LEVEL := 20                      # grown (DinoSize.GROWN_LEVEL 14)
const AT := Vector3(-4.0, 0.0, 24.0)   # flat meadow, away from the ramps, the wall and the raptors
const GROUND_TOLERANCE := 0.03         # m, shown size

var _out := "user://test_dinos_foret_3d"
var _failed := 0
var _demo: Node
var _player: Node3D
var _pivot: Node3D


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
	_quiet_demo()
	var caption := ShotCaption.show_on(self, CAPTION)
	for id in SPECIES:
		await _one(id)
	caption.queue_free()
	print("TEST dinos forêt 3D : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


## The demo's own line of controls and its two raptors out of the pictures.
func _quiet_demo() -> void:
	for child in _demo.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
	for r: Node3D in _demo.get("raptors"):
		r.process_mode = Node.PROCESS_MODE_DISABLED
		r.visible = false


func _one(id: StringName) -> void:
	var sheet: Resource = load("res://world3d/creatures/species/%s.tres" % id)
	var d: CharacterBody3D = load(DINO).call("create", sheet, LEVEL)
	d.position = AT
	d.set("home", AT)
	_demo.add_child(d)
	await process_frame
	d.set_physics_process(false)   # held still, in idle: it is its pose that is looked at
	d.velocity = Vector3.ZERO
	d.global_position = AT
	for child in d.get_children():   # no « E : observer » over its head in the picture
		if child is Node3D and child.get_script() != null and "lines" in child and "verb" in child:
			child.queue_free()
	var holder: Node3D = d.get("model").get_parent()
	holder.rotation.y = PI * 0.5   # side on, facing +X
	var length: float = d.get("length_m")
	var height: float = d.get("height_m")
	# Chloé in front of its head, a little nearer the camera, facing it
	var chloe_at := AT + Vector3(length * 0.5 + 0.9, 0.0, 0.9)
	_player.call("place_at", chloe_at, -PI * 0.5)
	_player.set_physics_process(false)
	var focus := Node3D.new()
	focus.name = "Focus"
	_demo.add_child(focus)
	focus.global_position = Vector3(AT.x + 0.45, maxf(height * 0.5, 0.9) - 1.2, AT.z)
	_pivot.set("target", focus)
	var span := maxf(length + 2.0, height * 1.5)
	_pivot.call("set_view", 0.0, -7.0, clampf(span * 1.05, 3.0, 14.0))
	_pivot.call("snap")
	await create_timer(1.0).timeout
	# the lowest point of the posed model, against its body's feet (the ground here)
	var box: AABB = load(SIZE).call("posed_box", d.get("model"))
	var low := (box.position.y) * holder.scale.y
	var shown := "%.2f m de long, %.2f m de haut" % [length, height]
	_check("%s stands on the ground in idle (lowest point %+.3f m, %s)" % [id, low, shown],
		absf(low) <= GROUND_TOLERANCE, "%+.3f m" % low)
	await _shot("%s_pose_et_taille" % id)
	_pivot.set("target", _player)
	_player.set_physics_process(true)
	focus.queue_free()
	d.queue_free()
	await process_frame


func _check(what: String, ok: bool, detail: String) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", what, detail])
	if not ok:
		_failed += 1


func _shot(name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
