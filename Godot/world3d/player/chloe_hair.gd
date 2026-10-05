extends SpringBoneSimulator3D
## Chloé's ponytail, front lock and backpack follow her moves (assets3d_src/chloe/cheveux.md).
## This node is added under her Skeleton3D at import (chloe_hair_import.gd, the import script of
## characters/chloe/chloe.glb), so every scene that shows chloe.glb has it — Player3D, the people
## of NpcBody — without a line of their own. It sets itself up when it enters the game (_ready):
## its three chains and the colliders that keep the ponytail off her head, back and backpack, and
## the backpack off her back. (Done here and not at import: a collider's offset from its bone is
## only kept once the bone is found, in the tree.)
## The springs work in the space of her model (_carrier). If they ever run in world space (a model
## without owner), after a teleport it puts them back at rest, or the hair would lash across the
## whole distance; it looks before the skeleton runs its modifiers.

## One chain each: root bone, end bone, length of the end (m), joint radius (m), stiffness, drag,
## gravity, rotation axis, colliders it meets (COLLIDERS names).
const CHAINS := [
	["hair_pony_01", "hair_pony_05", 0.06, 0.025, 1.5, 0.4, 0.3, SkeletonModifier3D.ROTATION_AXIS_ALL,
		["Head", "UpperBack", "Shoulders", "Backpack"]],
	["hair_lock_01", "hair_lock_03", 0.035, 0.004, 2.5, 0.5, 0.2, SkeletonModifier3D.ROTATION_AXIS_ALL, []],
	["pack_hang", "pack_hang", 0.25, 0.04, 4.0, 0.7, 0.15, SkeletonModifier3D.ROTATION_AXIS_X, ["LowerBack"]],
]
## Colliders, written in the skeleton's own space at rest (m; Y up, +Z in front of her):
## name, bone it rides on, from, to (the same point: a sphere), radius.
const COLLIDERS := [
	["Head", "Head", Vector3(0.0, 1.395, 0.005), Vector3(0.0, 1.395, 0.005), 0.10],
	["UpperBack", "spine_03", Vector3(0.0, 1.10, -0.02), Vector3(0.0, 1.26, -0.03), 0.075],
	["Shoulders", "spine_03", Vector3(-0.12, 1.19, -0.02), Vector3(0.12, 1.19, -0.02), 0.06],
	["Backpack", "pack_hang", Vector3(0.0, 1.11, -0.125), Vector3(0.0, 0.96, -0.125), 0.062],
	["LowerBack", "spine_02", Vector3(0.0, 0.95, -0.01), Vector3(0.0, 1.12, -0.01), 0.06],
]
## Moved further than this since the last look: a teleport, not a run (5.85 m/s ≈ 0.1 m a frame).
const TELEPORT_M := 1.0
const FIRST := -1000

var _last := Vector3.INF


func _ready() -> void:
	process_priority = FIRST
	process_physics_priority = FIRST
	var skeleton := get_skeleton()
	if skeleton == null:
		push_warning("chloe_hair : pas de Skeleton3D au-dessus de %s" % name)
		return
	for spec: Array in COLLIDERS:
		_add_collider(skeleton, spec)
	var body := _carrier()
	setting_count = CHAINS.size()
	for i in CHAINS.size():
		var c: Array = CHAINS[i]
		set_root_bone_name(i, c[0])
		set_end_bone_name(i, c[1])
		set_extend_end_bone(i, true)
		set_end_bone_direction(i, SkeletonModifier3D.BONE_DIRECTION_PLUS_Y)
		set_end_bone_length(i, c[2])
		set_radius(i, c[3])
		set_stiffness(i, c[4])
		set_drag(i, c[5])
		set_gravity(i, c[6])
		set_rotation_axis(i, c[7])
		if body:
			set_center_from(i, SpringBoneSimulator3D.CENTER_FROM_NODE)
			set_center_node(i, get_path_to(body))
		set_enable_all_child_collisions(i, false)
		var hits: Array = c[8]
		set_collision_count(i, hits.size())
		for k in hits.size():
			set_collision_path(i, k, NodePath(hits[k]))
	reset()


func _process(_delta: float) -> void:
	_watch()


func _physics_process(_delta: float) -> void:
	_watch()


func _watch() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	var at := skeleton.global_position
	if _last != Vector3.INF and at.distance_to(_last) > TELEPORT_M:
		reset()
	_last = at


## The springs work in the space of her model itself (the root of chloe.glb, which goes and turns
## with her, for Player3D as for Npc3D): her animated moves swing them — the bounce of a stride, a
## jump, a nod — not her travel. Tried and dropped (05/10, tools/test_chloe_hair.gd): world space
## (at a run the ponytail lay flat behind her like a flag, 24 cm off) and the space of the body
## that carries her (a sharp turn whipped the ponytail through her neck, 9 cm into it).
func _carrier() -> Node3D:
	return owner as Node3D


## A sphere (from == to) or a capsule from `from` to `to`, placed on its bone at rest.
func _add_collider(skeleton: Skeleton3D, spec: Array) -> void:
	var bone := skeleton.find_bone(spec[1])
	if bone < 0:
		push_warning("chloe_hair : os %s introuvable" % spec[1])
		return
	var from: Vector3 = spec[2]
	var to: Vector3 = spec[3]
	var radius: float = spec[4]
	var shape: SpringBoneCollision3D
	var along := Vector3.UP
	if from.is_equal_approx(to):
		var sphere := SpringBoneCollisionSphere3D.new()
		sphere.radius = radius
		shape = sphere
	else:
		var capsule := SpringBoneCollisionCapsule3D.new()
		capsule.radius = radius
		capsule.height = from.distance_to(to) + 2.0 * radius
		shape = capsule
		along = (to - from).normalized()
	shape.name = spec[0]
	add_child(shape)
	shape.bone_name = spec[1]
	var rest := skeleton.get_bone_global_rest(bone)
	shape.position_offset = rest.affine_inverse() * ((from + to) * 0.5)
	shape.rotation_offset = (rest.basis.orthonormalized().inverse() * Basis(_turn(Vector3.UP, along))).get_rotation_quaternion()


static func _turn(a: Vector3, b: Vector3) -> Quaternion:
	if a.is_equal_approx(b):
		return Quaternion.IDENTITY
	if a.is_equal_approx(-b):
		return Quaternion(Vector3.RIGHT, PI)
	return Quaternion(a, b)
