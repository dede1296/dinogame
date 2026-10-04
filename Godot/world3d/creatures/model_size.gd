class_name ModelSize
## The size a model takes up as it is drawn (docs/migration-3d.md, phase 3): its skinned meshes posed by
## their skeleton (each vertex moved by the bone that weighs most on it), in the model root's axes.
## Imported models come in any unit and any rest pose (a T-pose, a curled tail…): sizing a species
## to its real length needs what is drawn, not the rest box nor the bones (which stop short of the
## snout and the tail's tip). Measured once per model, then cached. Its size is reliable (Chloé:
## 1.51 m), its position less so (a rig node's offset may shift it): use `.size`.
## (Godot's own MeshInstance3D.bake_mesh_from_current_skeleton_pose needs a registered skin, which
## a headless run has not: this works in both.)

static var _cache := {}


## The box of `model` (an instance, in the tree or not) in its own space, as posed now.
## `key`: cache it under this name (the scene's path).
static func posed_box(model: Node3D, key := "") -> AABB:
	if key != "" and _cache.has(key):
		return _cache[key]
	var box := AABB()
	var first := true
	var to_root := model.global_transform.affine_inverse() if model.is_inside_tree() else Transform3D.IDENTITY
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D
		var mesh_to_root := _to_root(mi, model, to_root)
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES] if arrays[Mesh.ARRAY_BONES] != null else PackedInt32Array()
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS] if arrays[Mesh.ARRAY_WEIGHTS] != null else PackedFloat32Array()
			@warning_ignore("integer_division")
			var per := bones.size() / maxi(verts.size(), 1)   # bone slots per vertex (4 or 8)
			var posed := _bind_transforms(mi, skel)
			for v in verts.size():
				var p := verts[v]
				if skel and mi.skin and per > 0:
					p = _skinned(p, v, per, bones, weights, posed, skel, mi, model, to_root)
				else:
					p = mesh_to_root * p
				box = AABB(p, Vector3.ZERO) if first else box.expand(p)
				first = false
	if key != "":
		_cache[key] = box
	return box


static func _to_root(node: Node3D, model: Node3D, to_root: Transform3D) -> Transform3D:
	if model.is_inside_tree():
		return to_root * node.global_transform
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != model:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


## For each skin bind: the bone's current pose × its bind pose (skeleton space), or empty.
static func _bind_transforms(mi: MeshInstance3D, skel: Skeleton3D) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	if skel == null or mi.skin == null:
		return out
	for i in mi.skin.get_bind_count():
		var bone := mi.skin.get_bind_bone(i)
		if bone < 0:
			bone = skel.find_bone(mi.skin.get_bind_name(i))
		var pose := skel.get_bone_global_pose(bone) if bone >= 0 else Transform3D.IDENTITY
		out.append(pose * mi.skin.get_bind_pose(i))
	return out


static func _skinned(p: Vector3, v: int, per: int, bones: PackedInt32Array, weights: PackedFloat32Array,
		posed: Array[Transform3D], skel: Skeleton3D, _mi: MeshInstance3D, model: Node3D, to_root: Transform3D) -> Vector3:
	var best := 0
	var best_w := -1.0
	for k in per:
		var w := weights[v * per + k] if v * per + k < weights.size() else 0.0
		if w > best_w:
			best_w = w
			best = bones[v * per + k]
	var in_skel: Vector3 = posed[best] * p if best < posed.size() else p
	return _to_root(skel, model, to_root) * in_skel
