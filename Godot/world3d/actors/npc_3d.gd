class_name Npc3D
extends CharacterBody3D
## A person Chloé can talk to in the 3D world (docs/migration-3d.md, « Npc/DinoNpc → Npc3D »), any
## character: Npc3D.create(NpcSource.read(source)[i]).
## - Data: everything comes from the `Npc` of the 2.5D zone — name, sheet, dialogue or story scene,
##   the way they face, where they stand (NpcSource). Nothing is written down twice.
## - Body: Chloé's model at the person's own height, in the colours of their own 2.5D sheet
##   (NpcBody), animated by the generic CharacterAnimator with her AnimSet.
## - Talking: « E : parler » when Chloé comes close (Interactable3D, her own reach as in the 2.5D),
##   then the game's dialogue box (NpcDialogue → the autoload Dialogue, unchanged). The first time,
##   a « ! » over their head, as the 2.5D does.
## - Scenes: `face()` and `walk_to()` keep the 2.5D's names, in metres, for Stage 3D later.

## Chloé just talked to them (the dialogue is over).
signal talked(player: Node3D)

const WALK_SPEED := 1.3            # m/s: a grown-up strolling (the 2.5D's 120 px/s read in 3D)
const RADIUS_AT_BASE := 0.17       # Player3D.RADIUS: the model's own waist at 1.50 m
const HINT_OVER_HEAD := 0.25       # where « E : parler » floats over them (m)
const TURN := 10.0                 # how fast they turn to look at someone
const GREET_SECONDS := 1.2         # how long the « ! » stays
const ARRIVED := 0.05              # (m) close enough to where they were walking

var display_name := ""
var sheet: Texture2D
var dialogue_id: StringName = &""
var event: StringName = &""
var tint := Color.WHITE
## How tall they are (m), from their sheet (Heights: Chloé 1.50, women 1.50–1.70, men 1.70–2.00).
var height_m := 1.7
## The radius of their body (m): Chloé's waist at their height.
var radius := RADIUS_AT_BASE
var animator: CharacterAnimator
## True while a scene walks them about: not to be turned round meanwhile (as the 2.5D's Npc).
var walking := false

var _data := {}
var _greeted := false
var _holder: Node3D
var _talk: Interactable3D
var _emote: Label3D
var _emote_left := 0.0
var _gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _target := Vector3.INF
var _speed := WALK_SPEED
var _look := Vector3.INF
var _facing := Vector3(0, 0, 1)


## A person from one entry of NpcSource.read(). Add them to the tree, then place them (`place_on`).
static func create(data: Dictionary) -> Npc3D:
	var npc := Npc3D.new()
	npc._data = data
	npc.name = String(data.get("name", "Npc"))
	npc.display_name = String(data.get("display_name", ""))
	npc.sheet = data.get("sheet")
	npc.dialogue_id = data.get("dialogue_id", &"")
	npc.event = data.get("event", &"")
	npc.tint = data.get("tint", Color.WHITE)
	npc.height_m = Heights.metres(npc.sheet)   # the 2.5D's own table of heights
	npc._facing = data.get("facing", Vector3(0, 0, 1))
	return npc


func _ready() -> void:
	add_to_group(&"npc3d")
	# the layer of what lives and moves: Chloé bumps into them, the camera does not pull in on them
	collision_layer = Layers3D.DINOS
	collision_mask = Layers3D.WORLD
	floor_snap_length = 0.3
	_build()
	face_direction(_facing)


## Stands them on the ground of `ground` at `at` (metres of the 3D zone; its y is ignored, the
## terrain's own height is taken, as Zone3D does for Chloé and the dinos).
func place_on(ground: ZoneTerrain, at: Vector3) -> void:
	global_position = Vector3(at.x, ground.height_at(at.x, at.z), at.z)
	velocity = Vector3.ZERO


## Turns them to look at a point of the world.
func face(point: Vector3) -> void:
	face_direction(point - global_position)


func face_direction(direction: Vector3) -> void:
	var flat := direction.slide(Vector3.UP)
	if flat.length() < 0.001 or _holder == null:
		return
	_facing = flat.normalized()
	_holder.rotation.y = atan2(_facing.x, _facing.z)
	_look = Vector3.INF


## Turns them towards a point over the next few frames (while talking, during a scene).
func look_at_point(point: Vector3) -> void:
	_look = point


## Walks to `target` (metres of the zone) in a straight line, then faces `end_facing` (a direction,
## or Vector3.ZERO to keep looking the way they went) — the 2.5D's Npc.walk_to, in metres.
func walk_to(target: Vector3, end_facing := Vector3.ZERO, speed := WALK_SPEED) -> void:
	var to := (target - global_position).slide(Vector3.UP)
	if to.length() < ARRIVED:
		return
	walking = true
	_target = target
	_speed = speed
	var patience := to.length() / maxf(speed, 0.1) * 3.0 + 1.0   # (blocked on the way: they give up)
	while walking and patience > 0.0:
		await get_tree().physics_frame
		patience -= get_physics_process_delta_time()
	walking = false
	_target = Vector3.INF
	if end_facing != Vector3.ZERO:
		face_direction(end_facing)


## Walks through `points` one after another (the 2.5D's Npc.walk_path).
func walk_path(points: Array, end_facing := Vector3.ZERO, speed := WALK_SPEED) -> void:
	for i in points.size():
		await walk_to(points[i], end_facing if i == points.size() - 1 else Vector3.ZERO, speed)


## Holds a pose instead of standing (sit, crouch, swim…), as the 2.5D's poses do; false if the
## model has no such clip. `release_pose()` stands them up again.
func pose(move: StringName) -> bool:
	return animator != null and animator.hold(move)


func release_pose() -> void:
	if animator:
		animator.release()


## What they say, through the game's own dialogue box. Chloé's Player3D awaits it.
func talk(player: Node3D) -> void:
	face(player.global_position)
	if not _greeted:
		_greeted = true
		emote("!")
	if animator:
		animator.act(&"talk")
	await Dialogue.run(NpcDialogue.lines_for(_data))
	talked.emit(player)


## A sign over their head for a moment (« ! », « ♪ »…), as the 2.5D's WorldView.emote.
func emote(text: String) -> void:
	_emote.text = text
	_emote.visible = true
	_emote_left = GREET_SECONDS


func _physics_process(delta: float) -> void:
	_emote_left = maxf(_emote_left - delta, 0.0)
	if _emote_left == 0.0 and _emote.visible:
		_emote.visible = false
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


func _build() -> void:
	_holder = Node3D.new()
	_holder.name = "Model"
	add_child(_holder)
	var body := NpcBody.build(sheet, height_m, tint)
	_holder.add_child(body)
	radius = RADIUS_AT_BASE * NpcBody.size_factor(height_m)
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height_m
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = height_m * 0.5
	add_child(shape)
	animator = CharacterAnimator.new()
	animator.name = "Animator"
	animator.body = self
	animator.model = body
	animator.anim_set = NpcBody.ANIMS
	animator.size_factor = NpcBody.size_factor(height_m)   # shorter legs, shorter steps
	add_child(animator)
	var talk_here := Talk.new()
	talk_here.npc = self
	talk_here.name = "Talk"
	talk_here.verb = "parler"
	talk_here.hint_height = height_m + HINT_OVER_HEAD
	_talk = talk_here
	add_child(_talk)
	_emote = Label3D.new()
	_emote.name = "Emote"
	_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote.font_size = 72
	_emote.pixel_size = 0.004
	_emote.outline_size = 12
	_emote.modulate = Color(1.0, 0.92, 0.35)
	_emote.position = Vector3(0.0, height_m + HINT_OVER_HEAD, 0.0)
	_emote.visible = false
	add_child(_emote)


## What Chloé uses to talk to them: an Interactable3D (« E : parler », her own reach) whose use
## waits for the whole talk, so she stays still until the dialogue is over (Player3D._use awaits it).
class Talk extends Interactable3D:
	var npc: Npc3D

	func interact(player: Node3D) -> void:
		used.emit(player)
		await npc.talk(player)
