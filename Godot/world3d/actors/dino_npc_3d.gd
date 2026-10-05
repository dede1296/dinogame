class_name DinoNpc3D
extends CharacterBody3D
## A dino of the story standing in the 3D world (docs/migration-3d.md, « Npc/DinoNpc → Npc3D »): the
## 2.5D's DinoNpc — the Grand Voyageur at the crossroads, the Alpha of the Grand Crâne… —
## DinoNpc3D.create(DinoNpc3D.read(source)[i]), put down by Npcs3D with the people.
## - Data: everything comes from the `DinoNpc` of the 2.5D zone (its species, size, the way it faces,
##   its story flags and scene, where it stands): nothing is written down twice.
## - Body: its species' 3D model (Species3D) at its adult size × the DinoNpc's own size (the Alpha
##   1.2, the Grand Voyageur 1.6), younger if it has a level; the cartoon look; standing with the
##   generic CharacterAnimator; solid for Chloé (the dinos' layer); its cry now and then.
## - No brain: it stands where the story puts it, neither met nor running off.
## - Its story scene (`event`, Story.run in the 2.5D) is not played from here yet: as for the people,
##   that waits for the scenes on 3D actors (Stage 3D). Nothing to use on it meanwhile.
## - Scenes: face(), go_to() / arrived() (StoryWorld3D.walk_actor), cry().

const DINO_NPC_SCRIPT := preload("res://actors/dino_npc.gd")
const TOON := preload("res://world3d/render/toon_style.gd")
const ARRIVED := 0.1          # (m) close enough to where it was walking
const FALL_LIMIT := -30.0
const TURN := 4.0
const CRY_EVERY_S := Vector2(14.0, 30.0)
## The 2.5D draws a dino facing right; `flip` turns it to the left (DinoNpc.flip).
const FACING_RIGHT := Vector3(1, 0, 0)

var species: Species3D
var event: StringName = &""
## Its size against an adult of its species (the DinoNpc's size_scale × its growth).
var share := 1.0
## Its length, height and the radius of its body as shown (m).
var length_m := 0.0
var height_m := 0.0
var radius := 0.5
var animator: CharacterAnimator
var model: Node3D
## True while a scene walks it about.
var walking := false

var _holder: Node3D
var _voice: AudioStreamPlayer3D
var _cry_in := 0.0
var _gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _target := Vector3.INF
var _speed := 1.0
var _look := Vector3.INF
var _facing := FACING_RIGHT
var _level := 0
var _size_scale := 1.0


## The story's dinos of `src` the story puts there now (DinoNpc's show_flag / hide_flag):
## [{name, species_id, event, facing (Vector3), size_scale, level, at (Vector3, on the 2.5D's relief)}].
static func read(src: ZoneSource) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if src == null or src.region == null:
		return out
	for node in src.region.entities.get_children():
		if node.get_script() != DINO_NPC_SCRIPT:
			continue
		var show: StringName = node.get(&"show_flag")
		var hide: StringName = node.get(&"hide_flag")
		if (show != &"" and not Game.flag(show)) or (hide != &"" and Game.flag(hide)):   # DinoNpc._ready's rule
			continue
		out.append({
			"name": String(node.name),
			"species_id": node.get(&"species_id") as StringName,
			"event": node.get(&"event") as StringName,
			"facing": -FACING_RIGHT if bool(node.get(&"flip")) else FACING_RIGHT,
			"size_scale": float(node.get(&"size_scale")),
			"level": int(node.get(&"level")),
			"at": src.to_3d(NpcSource._zone_position(node)),
		})
	return out


## The dino of one entry of read(), or null when its species has no 3D sheet yet. Add it to the tree,
## then place it (`place_on`).
static func create(data: Dictionary) -> DinoNpc3D:
	var sheet := Species3D.of(data.get("species_id", &""))
	if sheet == null:
		return null
	var d := DinoNpc3D.new()
	d.species = sheet
	d.name = String(data.get("name", "DinoNpc"))
	d.event = data.get("event", &"")
	d._facing = data.get("facing", FACING_RIGHT)
	d._size_scale = float(data.get("size_scale", 1.0))
	d._level = int(data.get("level", 0))
	return d


func _ready() -> void:
	add_to_group(&"npc3d")   # a character of the story (StoryWorld3D.actor finds it by name)
	collision_layer = Layers3D.DINOS
	collision_mask = Layers3D.WORLD | Layers3D.WATER
	floor_snap_length = 0.3
	_build()
	face_direction(_facing)


## Stands it on the ground of `ground` at `at` (metres of the 3D zone; its y is ignored).
func place_on(ground: ZoneTerrain, at: Vector3) -> void:
	global_position = Vector3(at.x, ground.height_at(at.x, at.z), at.z)
	velocity = Vector3.ZERO


func face(point: Vector3) -> void:
	face_direction(point - global_position)


func face_direction(direction: Vector3) -> void:
	var flat := direction.slide(Vector3.UP)
	if flat.length() < 0.001 or _holder == null:
		return
	_facing = flat.normalized()
	_holder.rotation.y = atan2(_facing.x, _facing.z)
	_look = Vector3.INF


## Turns towards a point over the next few frames.
func look_toward(point: Vector3) -> void:
	_look = point


## Walks to `point` in a straight line at `speed` (m/s), for a scene (StoryWorld3D.walk_actor).
func go_to(point: Vector3, speed: float) -> void:
	_target = point
	_speed = maxf(speed, 0.1)
	walking = true


func arrived() -> bool:
	return not walking


func walk_speed() -> float:
	return species.walk_speed


## Its cry (DinoSpecies.cry: neutre, attaque…), heard from where it stands.
func cry(kind: StringName) -> void:
	var stream := species.sheet().cry(kind)
	if stream and _voice:
		_voice.stream = stream
		_voice.pitch_scale = randf_range(0.82, 0.92) if share > 1.0 else randf_range(0.95, 1.05)   # (a big one lower, as DinoNpc.cry)
		_voice.play()


func _physics_process(delta: float) -> void:
	_cry_in -= delta
	if _cry_in <= 0.0:
		_cry_in = randf_range(CRY_EVERY_S.x, CRY_EVERY_S.y)
		cry(&"neutre")
	var wish := Vector3.ZERO
	if _target != Vector3.INF:
		var to := (_target - global_position).slide(Vector3.UP)
		if to.length() < ARRIVED:
			_target = Vector3.INF
			walking = false
		else:
			wish = to.normalized() * _speed
	velocity.x = wish.x
	velocity.z = wish.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()
	if global_position.y < FALL_LIMIT:
		push_warning("DinoNpc3D : %s est tombé hors du monde" % name)
		set_physics_process(false)
		return
	_turn(wish, delta)


func _turn(wish: Vector3, delta: float) -> void:
	var dir := wish
	if dir.length() < 0.05:
		if _look == Vector3.INF:
			return
		dir = (_look - global_position).slide(Vector3.UP)
	if dir.length() < 0.01:
		return
	_holder.rotation.y = lerp_angle(_holder.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-TURN * delta))


## Its model at its size (as Dinosaur3D builds a wild one), its body, its animations and its voice.
func _build() -> void:
	_holder = Node3D.new()
	_holder.name = "Model"
	add_child(_holder)
	model = species.model.instantiate() as Node3D
	_holder.add_child(model)
	TOON.apply(model)
	var drawn := ModelSize.posed_box(model, species.model.resource_path).size
	share = _size_scale * (DinoSize.growth(species.sheet(), _level) if _level > 0 else 1.0)
	var scale_by := species.adult_scale(drawn) * share
	_holder.scale = Vector3.ONE * scale_by
	length_m = maxf(drawn.z, drawn.x) * scale_by
	height_m = drawn.y * scale_by
	radius = clampf(length_m * 0.16, 0.12, 2.5)
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = maxf(height_m * 0.8, radius * 2.0)
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	add_child(shape)
	animator = CharacterAnimator.new()
	animator.name = "Animator"
	animator.body = self
	animator.model = model
	animator.anim_set = species.anim_set
	animator.size_factor = share   # its AnimSet's speeds are an adult's
	add_child(animator)
	_voice = AudioStreamPlayer3D.new()
	_voice.bus = Audio.CRIES_BUS
	_voice.unit_size = 8.0
	_voice.max_distance = 70.0
	_voice.position.y = height_m * 0.7
	add_child(_voice)
	_cry_in = randf_range(3.0, CRY_EVERY_S.y)
