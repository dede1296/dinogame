@tool
extends EditorScenePostImport
## Import script of assets/models3d/characters/chloe/chloe.glb: adds the node that makes her
## ponytail, front lock and backpack follow her moves (HairSprings, a SpringBoneSimulator3D with
## chloe_hair.gd, under her Skeleton3D). Its chains and colliders are set up by chloe_hair.gd when
## the model enters the game — tune them there, no reimport needed. The bones were made for it in
## Blender (assets3d_src/chloe/scripts/rig_v2.py, cheveux.md).

const HAIR := preload("res://world3d/player/chloe_hair.gd")
const BONES := ["hair_pony_01", "hair_pony_05", "hair_lock_01", "hair_lock_03", "pack_hang"]


func _post_import(scene: Node) -> Object:
	var skeletons := scene.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		push_error("chloe_hair_import : pas de Skeleton3D dans %s" % get_source_file())
		return scene
	var skeleton := skeletons[0] as Skeleton3D
	for bone: String in BONES:
		if skeleton.find_bone(bone) < 0:
			push_error("chloe_hair_import : os manquant %s (refaire rig_v2 dans Blender)" % bone)
			return scene
	var sim := SpringBoneSimulator3D.new()
	sim.name = "HairSprings"
	sim.set_script(HAIR)
	skeleton.add_child(sim)
	sim.owner = scene
	print("chloe_hair_import : HairSprings ajouté à %s" % get_source_file())
	return scene
