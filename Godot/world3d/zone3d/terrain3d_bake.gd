extends SceneTree
## Saves a zone's Terrain3D ground so it can be retouched by hand in the Godot editor
## (docs/migration-3d.md, phase 4, « Terrain3D : écrire le relief »):
##   godot --path Godot --script res://world3d/zone3d/terrain3d_bake.gd -- zone=plaines [out=<folder>]
## It builds the zone's relief as the game does (TerrainRelief: the 2.5D's heights, then its edits,
## terrain3d_relief/<zone>.json), then writes into <folder> (default ZoneGroundTerrain3D.DATA_DIR +
## zone id):
## - Terrain3D's region files (terrain3d_XX_YY.res): from then on the game reads the zone's heights
##   from them (ZoneGroundTerrain3D.saved_regions), and so does the editor;
## - edit_<zone>.tscn: a Terrain3D node on that folder, painted as in the game, to open in the editor
##   and sculpt with Terrain3D's tools (raise, smooth, flatten…); saving the scene saves the regions.
## Delete the folder to go back to the relief built by script (and bake again after editing the
## .json: a bake overwrites the hand retouches). Writing into res:// adds resources to the project:
## take the import lock first (mkdir C:\Users\Greg\Dinogame\.lock-import, rmdir after).
## (Game classes are reached through load(): this script is compiled before the autoloads.)

const SOURCE := "res://world3d/zone3d/zone_source.gd"
const RELIEF := "res://world3d/zone3d/terrain3d_relief.gd"
const GROUND := "res://world3d/zone3d/terrain3d_ground.gd"
const ZONE_TERRAIN := "res://world3d/zone3d/zone_terrain.gd"

var _zone := &"plaines"
var _out := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("zone="):
			_zone = StringName(arg.substr(5))
		elif arg.begins_with("out="):
			_out = arg.substr(4)
	_run.call_deferred()


func _run() -> void:
	var ground_script: GDScript = load(GROUND)
	if not ground_script.call(&"available"):
		push_error("terrain3d_bake : Terrain3D indisponible (extension absente, ou rendu autre que Forward+)")
		quit(1)
		return
	var dir := _out if _out != "" else String(ground_script.get(&"DATA_DIR")) + String(_zone)
	var source: RefCounted = load(SOURCE).call(&"open", _zone)
	if source == null:
		quit(1)
		return
	var relief: RefCounted = load(RELIEF).call(&"from_source", source)
	relief.call(&"apply", load(RELIEF).call(&"edits_of", _zone))
	# the painting, as ZoneTerrain sets it up for the game
	var looks: Node3D = load(ZONE_TERRAIN).new()
	looks.set(&"source", source)
	var mat: ShaderMaterial = looks.call(&"_material")
	var masks: Array = relief.call(&"mask_textures")
	mat.set_shader_parameter("mask_a", masks[0])
	mat.set_shader_parameter("mask_b", masks[1])
	looks.free()
	var ground: Node3D = ground_script.new()
	root.add_child(ground)
	ground.call(&"build", relief, Vector2.ZERO, mat)
	var err: Error = ground.call(&"save", dir)
	print("terrain3d_bake : %d régions écrites dans %s (%s)" % [ground_script.call(&"saved_files", dir), dir, error_string(err)])
	err = _save_edit_scene(ground, mat, dir)
	print("terrain3d_bake : scène d'édition %s (%s)" % [dir.path_join("edit_%s.tscn" % _zone), error_string(err)])
	source.call(&"close")
	quit(0 if err == OK else 1)


## A scene with one Terrain3D node reading `dir`, set up as the game's ground (vertex spacing,
## regions, shader override and its painting), to retouch the relief in the editor.
func _save_edit_scene(ground: Node3D, mat: ShaderMaterial, dir: String) -> Error:
	var built: Node3D = ground.get(&"terrain")
	var node: Node3D = ClassDB.instantiate(&"Terrain3D")
	node.name = "Terrain3D_%s" % _zone
	node.set(&"vertex_spacing", built.get(&"vertex_spacing"))
	node.set(&"mesh_size", built.get(&"mesh_size"))
	node.set(&"mesh_lods", built.get(&"mesh_lods"))
	var material: Object = ClassDB.instantiate(&"Terrain3DMaterial")
	material.set(&"world_background", 0)
	material.set(&"shader_override", load("res://world3d/zone3d/terrain3d_ground.gdshader"))
	material.set(&"shader_override_enabled", true)
	node.set(&"material", material)
	node.set(&"assets", ground_script_assets())
	node.set(&"free_editor_textures", false)
	root.add_child(node)
	node.set(&"region_size", built.get(&"region_size"))
	node.set(&"data_directory", ProjectSettings.localize_path(dir))
	for uniform: Dictionary in mat.shader.get_shader_uniform_list():
		var value: Variant = mat.get_shader_parameter(uniform["name"])
		if value != null:
			material.call(&"set_shader_param", StringName(uniform["name"]), value)
	var scene := PackedScene.new()
	var err := scene.pack(node)
	if err != OK:
		return err
	return ResourceSaver.save(scene, dir.path_join("edit_%s.tscn" % _zone))


func ground_script_assets() -> Object:
	return load(GROUND).call(&"placeholder_assets")
