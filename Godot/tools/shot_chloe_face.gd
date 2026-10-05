extends SceneTree
## Chloé's face, checked in the game's own renderer (Forward+ on PC, Ambrelune's cartoon look):
## the model before (assets3d_src/chloe/chloe_avant.glb, read at run time, it is not in the project)
## on the left, the one in the game on the right, in the same still pose (idle), front then 3/4.
##   godot --path Godot --script res://tools/shot_chloe_face.gd -- out=<folder>
## Two pictures, one caption for the whole run (ShotCaption). Also prints what the hair's spring
## bones will need (their names, their rest direction) and the meshes' automatic LODs.

const NEW_MODEL := "res://assets/models3d/characters/chloe/chloe.glb"
const OLD_MODEL := "../assets3d_src/chloe/chloe_avant.glb"   # from the project folder
const TOON := preload("res://world3d/render/toon_style.gd")
const CAPTION := "Chloé — visage retravaillé, modèle optimisé"
const SPACING := 0.19        # m from the middle: the two heads side by side
const FACE_HEIGHT := 1.37    # m, the middle of her face
const HAIR_BONES := ["hair_pony_01", "hair_pony_02", "hair_pony_03", "hair_pony_04", "hair_pony_05",
	"hair_lock_01", "hair_lock_02", "hair_lock_03", "pack_hang"]

var _out := "user://shot_chloe_face"
var _models: Array[Node3D] = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	_run()


func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	_light(stage)
	var old := _load_old()
	var fresh := (load(NEW_MODEL) as PackedScene).instantiate() as Node3D
	for pair in [[old, -SPACING], [fresh, SPACING]]:
		var model: Node3D = pair[0]
		if model == null:
			continue
		model.position = Vector3(pair[1], 0.0, 0.0)
		stage.add_child(model)
		TOON.apply(model)
		_hold_pose(model)
		_models.append(model)
	var camera := Camera3D.new()
	camera.fov = 9.0
	stage.add_child(camera)
	camera.look_at_from_position(Vector3(0.0, FACE_HEIGHT + 0.01, 2.8), Vector3(0.0, FACE_HEIGHT, 0.0))
	camera.current = true
	ShotCaption.show_on(self, CAPTION)
	_report(fresh)
	await _frames(60)   # the hair springs settle (a little droop)
	await _shot("visage_face")
	for model in _models:
		model.rotation.y = deg_to_rad(35.0)   # her right cheek (and her lock) toward the camera
	await _frames(60)
	await _shot("visage_3-4")
	quit(0)


func _load_old() -> Node3D:
	var path := ProjectSettings.globalize_path("res://").path_join(OLD_MODEL).simplify_path()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(path, state)
	if err != OK:
		push_warning("ancien modèle illisible (%s) : %s" % [error_string(err), path])
		return null
	return doc.generate_scene(state) as Node3D


func _hold_pose(model: Node3D) -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player := players[0] as AnimationPlayer
	if player.has_animation(&"idle"):
		player.play(&"idle")
		player.seek(0.5, true)
		player.pause()


func _light(stage: Node3D) -> void:
	var sky_mat := ProceduralSkyMaterial.new()   # the demo's own sky (world3d/demo/demo_3d.gd)
	sky_mat.sky_top_color = Color(0.36, 0.55, 0.82)
	sky_mat.sky_horizon_color = Color(0.86, 0.80, 0.68)
	sky_mat.ground_horizon_color = Color(0.70, 0.66, 0.56)
	sky_mat.ground_bottom_color = Color(0.30, 0.28, 0.24)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	stage.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 25.0, 0.0)   # from behind the camera, up and to the right
	sun.light_color = Color(1.0, 0.93, 0.80)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	stage.add_child(sun)


## Meshes, surfaces, triangles, automatic LODs; the new bones and the way they point at rest.
func _report(model: Node3D) -> void:
	var tris := 0
	var surfaces := 0
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var lods := []
		for s in mi.mesh.get_surface_count():
			var n := int(mi.mesh.surface_get_array_index_len(s) / 3.0)
			tris += n
			surfaces += 1
			var info: Dictionary = RenderingServer.mesh_get_surface(mi.mesh.get_rid(), s)
			lods.append((info.get("lods", []) as Array).size())
		print("MAILLAGE %-16s surfaces %d  niveaux de détail par surface %s" % [mi.name, mi.mesh.get_surface_count(), lods])
	print("TOTAL triangles %d, surfaces %d" % [tris, surfaces])
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	var skel := skeletons[0] as Skeleton3D
	print("OS %d" % skel.get_bone_count())
	for name: String in HAIR_BONES:
		var i := skel.find_bone(name)
		if i < 0:
			print("OS MANQUANT %s" % name)
			continue
		var rest := skel.get_bone_global_rest(i)
		var along := ""
		var children := skel.get_bone_children(i)
		if not children.is_empty():
			var to_child := skel.get_bone_rest(children[0]).origin
			along = "axe +Y vers l'os suivant : %.0f°" % rad_to_deg(Vector3.UP.angle_to(to_child))
		print("OS %-13s parent %-13s tête %s  %s" % [name, skel.get_bone_name(skel.get_bone_parent(i)), rest.origin.snapped(Vector3.ONE * 0.001), along])


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("CAPTURE %s" % _out.path_join(name + ".png"))
