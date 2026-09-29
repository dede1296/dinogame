class_name Doors
extends RefCounted
## The houses one goes into, in the 3D view (docs/direction-artistique.md « Bâtiments
## assemblés », « Portes animées »). A kind of building may have a variant with its door apart,
## assets/models/volumes/portes/<kind>.glb (tools/modeles3d/maisons.py): the body, with a real
## opening and a room behind it, and its leaf `porte` (or two: `porte_g`, `porte_d`), each with
## its origin on its hinges, closed; glTF extras on a leaf: `ouverture` (degrees, signed: it
## opens inwards) and `seuil` (x, z in metres: the ground just behind the door), in the kind's
## frame (origin: the middle of the facade's foot, the facade towards +z).
## The view stands such a building as that body, apart (not in its kind's MultiMesh), and its
## leaves apart, each turning on its hinges (the body's RELIEF materials, normal map included,
## mirrored with the building): when a 2D node needs it (a StoryProp: a shop; a building a
## ZoneExit starts at: the Cabinet). The game's own glb stays one closed mesh, for the rest.
## Low quality (pictures, no models): no leaves, only the door's sound; where the door is (its
## threshold, its steps) is still known, for those who go through it (story/doorway.gd).

const PATH := "res://assets/models/volumes/portes/%s.glb"
const PX := HeightMap.PX
const OPEN_S := 0.4
const OPEN_SFX := preload("res://assets/audio/sfx/door_open.wav")
const OPEN_DB := -6.0
## Closing: the same creak, lower and duller.
const CLOSE_DB := -11.0
const CLOSE_PITCH := 0.72
## A leaf whose extras say nothing opens this far (degrees), inwards.
const DEFAULT_ANGLE := 100.0
## Where one stands to open a door: this far in front of the facade (m), past its steps.
const FRONT_M := 0.6
## Out of sight inside: this far past the threshold (m).
const DEEP_M := 0.3
## The steps up to a raised door begin this far in front of the facade (m).
const STEPS_M := 0.4
## A threshold whose extras say nothing: this far behind the facade (m).
const DEFAULT_SEUIL_Z := -0.45
## A ZoneExit starts at a building when the front of its door is this close to it (px).
const EXIT_REACH := 30.0

## kind -> what its door model says ({} when it has none): "body" (Mesh), "leaves" ([{"mesh",
## "rest": its closed transform, "angle": radians}]), "threshold" (Vector2, m), "sill" (m: its
## floor above the ground), "height", "width" (m: the opening). Read once.
static var _infos := {}
## "kind#details" -> {"body": Mesh, "leaves": Array of Mesh (in the body's frame)}, painted once.
static var _painted := {}

## The zone's buildings that stand with their door apart -> {"pivots": Array[Node3D], "rests",
## "angles", "parts": the body and the leaves (GeometryInstance3D), "open": bool,
## "tween"}. Registered when the zone is built (no pivots: pictures, or not shown yet).
var houses := {}


## Has the kind of building a variant with its door apart?
static func has_model(kind: String) -> bool:
	return not info(kind).is_empty()


static func info(kind: String) -> Dictionary:
	if not _infos.has(kind):
		_infos[kind] = _read(kind)
	return _infos[kind]


static func _read(kind: String) -> Dictionary:
	var path := PATH % kind
	if kind == "" or not ResourceLoader.exists(path):
		return {}
	var scene := (load(path) as PackedScene).instantiate()
	var body: MeshInstance3D = null
	var leaves: Array[MeshInstance3D] = []
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		if String(n.name).begins_with("porte"):
			leaves.append(n)
		elif body == null or String(n.name) == kind:
			body = n
	if body == null or leaves.is_empty():
		push_warning("%s: no body or no door leaf in %s" % [kind, path])
		scene.free()
		return {}
	var out := {"body": body.mesh, "leaves": [], "sill": INF, "height": 0.0}
	var lo := INF
	var hi := -INF
	var seuil := Vector2.INF
	for leaf in leaves:
		var rest := _in_scene(leaf, scene)
		var box := leaf.mesh.get_aabb()
		var extras: Dictionary = leaf.get_meta(&"extras", {})
		# (no extras: it opens away from the side its hinges are on)
		var angle := float(extras.get("ouverture", DEFAULT_ANGLE * (1.0 if box.get_center().x > 0.0 else -1.0)))
		out["leaves"].append({"mesh": leaf.mesh, "rest": rest, "angle": deg_to_rad(angle)})
		var closed := rest * box
		lo = minf(lo, closed.position.x)
		hi = maxf(hi, closed.end.x)
		out["sill"] = minf(out["sill"], closed.position.y)
		out["height"] = maxf(out["height"], closed.size.y)
		var s: Variant = extras.get("seuil")
		if s is Array and (s as Array).size() >= 2:
			seuil = Vector2(float(s[0]), float(s[1]))
	out["width"] = hi - lo
	out["threshold"] = seuil if seuil != Vector2.INF else Vector2((lo + hi) * 0.5, DEFAULT_SEUIL_Z)
	scene.free()
	return out


## `node`'s transform in `root`'s frame.
static func _in_scene(node: Node3D, root: Node) -> Transform3D:
	var t := node.transform
	var p := node.get_parent()
	while p != root and p is Node3D:
		t = (p as Node3D).transform * t
		p = p.get_parent()
	return t


## The body and the leaves of the kind, painted to be lit like the pictures (WorldView.paint_model,
## one material shared by all: the same atlas), `with_details` or not. {} when it has none.
static func painted(kind: String, with_details: bool) -> Dictionary:
	var key := "%s#%s" % [kind, with_details]
	if not _painted.has(key):
		var i := info(kind)
		if i.is_empty():
			_painted[key] = {}
		else:
			var body := (i["body"] as Mesh).duplicate() as Mesh
			var box := body.get_aabb()
			var shared := {}
			WorldView.paint_model(body, kind, box, with_details, shared)
			var leaves: Array[Mesh] = []
			for l: Dictionary in i["leaves"]:
				var leaf := _baked(l["mesh"], l["rest"])
				WorldView.paint_model(leaf, kind, box, with_details, shared)
				leaves.append(leaf)
			_painted[key] = {"body": body, "leaves": leaves}
	return _painted[key]


## A copy of a leaf's mesh in the body's frame (its closed transform `rest` applied), so that it
## is shaded as the body around it (its darker foot is measured from the body's).
static func _baked(src: Mesh, rest: Transform3D) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in verts.size():
			verts[i] = rest * verts[i]
		arrays[Mesh.ARRAY_VERTEX] = verts
		if arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array:
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for i in normals.size():
				normals[i] = (rest.basis * normals[i]).normalized()
			arrays[Mesh.ARRAY_NORMAL] = normals
		if arrays[Mesh.ARRAY_TANGENT] is PackedFloat32Array:
			var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
			for i in range(0, tangents.size() - 3, 4):
				var t := (rest.basis * Vector3(tangents[i], tangents[i + 1], tangents[i + 2])).normalized()
				tangents[i] = t.x
				tangents[i + 1] = t.y
				tangents[i + 2] = t.z
			arrays[Mesh.ARRAY_TANGENT] = tangents
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(s, src.surface_get_material(s))
	return out


# ------------------------------------------------------------------ in the zone

## `house` (a Prop of a kind with its door apart) goes in and out through its door.
func register(house: Node2D) -> void:
	if not houses.has(house):
		houses[house] = {"pivots": [], "rests": [], "angles": [], "parts": [], "open": false}


## Stands `house`'s leaves under `body` (a MeshInstance3D showing its painted body, placed and
## mirrored as the building), each on a pivot at its hinges, open or closed as the door is.
func attach(house: Node2D, body: MeshInstance3D, meshes: Dictionary) -> void:
	register(house)
	var h: Dictionary = houses[house]
	var i := info(String(house.get("kind")))
	var pivots: Array[Node3D] = []
	var parts: Array[GeometryInstance3D] = [body]
	h["rests"] = []
	h["angles"] = []
	for k in (i["leaves"] as Array).size():
		var l: Dictionary = i["leaves"][k]
		var pivot := Node3D.new()
		pivot.transform = l["rest"]
		body.add_child(pivot)
		var leaf := MeshInstance3D.new()
		leaf.mesh = meshes["leaves"][k]
		leaf.transform = (l["rest"] as Transform3D).affine_inverse()   # (its mesh is in the body's frame)
		leaf.cast_shadow = body.cast_shadow
		leaf.visibility_range_end = body.visibility_range_end
		leaf.visibility_range_end_margin = body.visibility_range_end_margin
		leaf.visibility_range_fade_mode = body.visibility_range_fade_mode
		pivot.add_child(leaf)
		pivots.append(pivot)
		parts.append(leaf)
		h["rests"].append(l["rest"])
		h["angles"].append(l["angle"])
	h["pivots"] = pivots
	h["parts"] = parts
	_pose(h, 1.0 if h["open"] else 0.0)


## Opens (or closes) `house`'s door in `secs` s, with its sound. Awaitable (without leaves shown:
## the sound, and the time it takes).
func open(house: Node2D, on: bool, secs := OPEN_S) -> void:
	var h: Dictionary = houses.get(house, {})
	if h.is_empty() or h["open"] == on:
		return
	h["open"] = on
	if on:
		Audio.play_sfx(OPEN_SFX, OPEN_DB, 0.05)
	else:
		Audio.play_sfx(OPEN_SFX, CLOSE_DB, 0.03, CLOSE_PITCH)
	var tree := Engine.get_main_loop() as SceneTree
	var pivots: Array = h["pivots"].filter(func(p) -> bool: return is_instance_valid(p) and (p as Node3D).is_inside_tree())
	if pivots.is_empty():
		await tree.create_timer(secs).timeout
		return
	_end_tween(h)
	var t := tree.create_tween()   # (not bound to a leaf: its end always comes)
	h["tween"] = t
	var from: float = h.get("amount", 0.0 if on else 1.0)
	t.tween_method(func(f: float) -> void: _pose(h, f), from, 1.0 if on else 0.0, secs) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT if on else Tween.EASE_IN)
	await t.finished


## Shown open (or closed) at once, without a sound.
func set_open(house: Node2D, on: bool) -> void:
	var h: Dictionary = houses.get(house, {})
	if h.is_empty():
		return
	_end_tween(h)
	h["open"] = on
	_pose(h, 1.0 if on else 0.0)


func is_open(house: Node2D) -> bool:
	return houses.get(house, {}).get("open", false)


## Its leaves fade with its body (a StoryProp's `opacity`, WorldView._sync_model).
func set_opacity(house: Node2D, alpha: float) -> void:
	var parts: Array = houses.get(house, {}).get("parts", [])
	for k in range(1, parts.size()):
		if is_instance_valid(parts[k]):
			(parts[k] as GeometryInstance3D).set_instance_shader_parameter(&"opacity", alpha)


## A turn still going on ends at once (whoever waits for it goes on).
static func _end_tween(h: Dictionary) -> void:
	var t: Variant = h.get("tween")
	if t is Tween and (t as Tween).is_valid() and (t as Tween).is_running():
		(t as Tween).custom_step(OPEN_S * 4.0)
	h.erase("tween")


## The leaves turned `f` of the way (0 closed, 1 open) on their hinges.
static func _pose(h: Dictionary, f: float) -> void:
	h["amount"] = f
	var pivots: Array = h["pivots"]
	for k in pivots.size():
		if is_instance_valid(pivots[k]):
			var rest: Transform3D = h["rests"][k]
			(pivots[k] as Node3D).basis = rest.basis * Basis(Vector3.UP, float(h["angles"][k]) * f)


# ------------------------------------------------------------------ in the 2D world

## The door of `house` in the 2D world ({} when its kind has none): "threshold" (px: the ground
## just inside), "inside" (px: further in, out of sight), "front" (px: where one stands to open
## it), "facade_y" (px), "sill" (m: its floor above the ground), "height", "width" (m: the opening).
static func door_2d(house: Node2D) -> Dictionary:
	var i := info(String(house.get("kind")))
	if i.is_empty():
		return {}
	var sx := -1.0 if house.get("flip") else 1.0
	var foot := house.global_position
	var t: Vector2 = i["threshold"]
	var x := foot.x + t.x * sx * PX
	return {"threshold": Vector2(x, foot.y + t.y * PX), "inside": Vector2(x, foot.y + (t.y - DEEP_M) * PX),
		"front": Vector2(x, foot.y + FRONT_M * PX), "facade_y": foot.y, "sill": i["sill"],
		"height": i["height"], "width": i["width"]}


## How high (m) someone at `p` (2D) stands on the steps of the door `d` (door_2d), or on its
## floor past the facade.
static func lift_m(d: Dictionary, p: Vector2) -> float:
	if absf(p.x - (d["threshold"] as Vector2).x) > (float(d["width"]) * 0.5 + STEPS_M) * PX:
		return 0.0   # (along the facade, beside the steps)
	var z := (p.y - float(d["facade_y"])) / PX
	return float(d["sill"]) * clampf(1.0 - z / STEPS_M, 0.0, 1.0)
