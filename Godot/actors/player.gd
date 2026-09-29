class_name Player
extends CharacterBody2D
## Chloé: analog top-down movement (keyboard, gamepad or touch joystick), walk animation,
## footsteps by ground type (in the snow and on the ice too), interaction with what is in front of her. She can ride a big
## dino (Monture, with Joss's saddle): faster, sitting on its back (the companion carries her).
## With the swimming vest and a grown swimmer, she swims across deep water on its back (Swim):
## it starts by itself as she walks into the water, and ends on the shore.
## She is 1.50 m tall (Heights: her sprite's scale, her shadow). On slippery ice (Region.slippery)
## she gets going and stops slowly: she slides a little, and her mount too.

signal stepped(surface: StringName)
## Chloé starts (true) or stops swimming, or another dino carries her in the water.
signal swim_changed(swimming: bool)

const SPEED := 165.0
const ACCEL := 1500.0
const SWIM_ACCEL := 360.0      # under the sea (diving): inertia, soft turns
## On slippery ice: from full speed to a stop (or back) in this long (s): she slides about a
## quarter of her speed in px (~0.9 m on foot, ~1.5 m on a mount).
const ICE_STOP_S := 0.5
const STEP_DISTANCE := 38.0
## Speeds (× SPEED), slowest to fastest: walking, in Rosalie's boots, running (B held, Shift),
## running in the boots; a mount is faster still, and gallops when B is held.
const BOOTS_SPEED := 1.2
const RUN_SPEED := 1.45
const BOOTS_RUN_SPEED := 1.7
const RIDE_SPEED := 1.9
const GALLOP_SPEED := 2.2
const RIDE_STEP := 1.7         # its steps are longer than hers
const INTERACT_REACH := 62.0
const TRAIL_SPACING := 6.0
const TRAIL_LENGTH := 48
## Walking against deep water she cannot swim in, this long (s): told why (once per zone).
const WATER_TELL_S := 0.7
const WATER_PROBE := 22.0      # px ahead of her feet where the water is looked for
const SWIM := preload("res://world/swim.gd")
const SHEET := preload("res://assets/art/characters/chloe.png")
const FOOTSTEPS: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/footstep00.ogg"), preload("res://assets/audio/footsteps/footstep01.ogg"),
	preload("res://assets/audio/footsteps/footstep02.ogg"), preload("res://assets/audio/footsteps/footstep03.ogg"),
	preload("res://assets/audio/footsteps/footstep04.ogg"), preload("res://assets/audio/footsteps/footstep05.ogg"),
]
## On snowy ground (a cold region, Region.cold): steps crunching softly in the snow; on the ice,
## the hard step played lower and duller, and every CRACK_EVERY steps or so (at random) a faint
## groan of the ice.
const SNOW_STEPS: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/neige00.ogg"), preload("res://assets/audio/footsteps/neige01.ogg"),
	preload("res://assets/audio/footsteps/neige02.ogg"), preload("res://assets/audio/footsteps/neige03.ogg"),
	preload("res://assets/audio/footsteps/neige04.ogg"), preload("res://assets/audio/footsteps/neige05.ogg"),
]
const ICE_CRACKS: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/glace_craque00.ogg"), preload("res://assets/audio/footsteps/glace_craque01.ogg"),
	preload("res://assets/audio/footsteps/glace_craque02.ogg"),
]
const ICE_PITCH := 0.8
const CRACK_EVERY := Vector2i(4, 6)
## Step levels (dB) by kind (see step_kind): softer on grass, crisper on the path; the snow's crunch
## lasts longer, so it is played lower; a crack lower still. On a mount, MOUNT_STEP_DB louder.
const STEP_DB := {&"grass": -13.0, &"path": -8.0, &"snow": -15.0, &"ice": -11.0, &"crack": -17.0}
const MOUNT_STEP_DB := 4.0

## Asked for the ground type under a position (set by the world, from the region).
var surface_at: Callable
## Asked how thick the snow lies at a position (Region.snow_at: 0–1, -1 without a snow layer).
var snow_at: Callable
## A cold region (Region.cold, set by the world): steps on the ice (and in the snow without a
## cover layer); her coat (Outfits).
var cold := false
## Its ice ("sand" tiles) is slippery (Region.slippery, set by the world).
var slippery := false
## Recent positions, oldest first: the companion walks in Chloé's footsteps.
var trail: PackedVector2Array = []
var facing := Vector2.DOWN
var busy := false   # during an interaction
## The dino Chloé rides (null: on foot). Set by the world (World.mount / dismount).
var mount: Dino = null
## The dino carrying her in deep water (null: not swimming). Set here, as she walks in or out.
var swimmer: Dino = null
## Under the sea (a zone played under the water): her diver carries her the whole time (Dive).
var diving := false

@onready var sprite: AnimatedSprite2D = $Sprite

var _step_travel := 0.0
var _push_time := 0.0      # walking against water she cannot swim in (s)
var _water_told := false   # …and told why, in this zone
var _to_crack := CRACK_EVERY.x   # steps on the ice before the next crack
var _sliding := false            # gliding on over the ice, feet still (no input)


func _ready() -> void:
	add_to_group(&"player")
	sprite.scale = Vector2.ONE * Heights.sprite_scale(SHEET)
	Shadow.make(self, Heights.shadow_width(SHEET))
	sprite.sprite_frames = SheetFrames.character(SHEET, 15.0)
	Outfits.dress_chloe(sprite.sprite_frames, 15.0)   # in her walking boots, once she has them
	sprite.play(&"idle_down")
	trail.append(global_position)
	collision_mask = SWIM.SOLID_LAYER | SWIM.WATER_LAYER


func can_move() -> bool:
	return not busy and not Dialogue.active and not Router.is_busy()


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if can_move():
		input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_update_water_mask()
	# (under the sea her diver glides: slow to start, slow to stop, wide turns; on the ice she slides)
	var on_ice := _on_slippery_ice()
	var accel := SWIM_ACCEL if diving else top_speed() / ICE_STOP_S if on_ice else ACCEL
	velocity = velocity.move_toward(input * top_speed(), accel * delta)
	_sliding = on_ice and input == Vector2.ZERO and velocity.length() > 12.0
	var before := global_position
	move_and_slide()
	var moved := global_position.distance_to(before)
	_update_swim()
	_watch_water(input, moved, delta)
	_animate(input)
	_track(moved)
	RenderingServer.global_shader_parameter_set(&"player_position", global_position)


func top_speed() -> float:
	var run := running()
	if mount:
		return SPEED * (GALLOP_SPEED if run else RIDE_SPEED)
	if swimmer:
		return SPEED * SWIM.SPEED
	var boots := Game.item_count("bottes") > 0
	if run:
		return SPEED * (BOOTS_RUN_SPEED if boots else RUN_SPEED)
	return SPEED * (BOOTS_SPEED if boots else 1.0)


## B held (the touch button, Escape) or Shift: she runs, her mount gallops.
func running() -> bool:
	return Input.is_action_pressed(&"run") or Input.is_action_pressed(&"cancel")


## On slippery ice (Region.slippery: its "sand" tiles), on foot or on her mount.
func _on_slippery_ice() -> bool:
	return slippery and not diving and swimmer == null and surface_at.is_valid() and surface_at.call(global_position) == &"sand"


## The dino carrying Chloé (her mount, or her swimmer in the water), or null: on her feet.
func carried_by() -> Dino:
	return mount if mount else swimmer


func is_swimming() -> bool:
	return swimmer != null


## Deep water stops her, unless she can swim, or already stands in it (never stuck there).
func _update_water_mask() -> void:
	var free := swimmer != null or on_water() or SWIM.can_swim()
	var mask := SWIM.SOLID_LAYER | (0 if free else SWIM.WATER_LAYER)
	if collision_mask != mask:
		collision_mask = mask


## Is Chloé standing in deep water (a "water" tile; a pier or a ford's stones are not)?
func on_water() -> bool:
	return surface_at.is_valid() and surface_at.call(global_position) == &"water"


## In the water, on the back of a swimmer of her party; out of it, on her feet again.
func _update_swim() -> void:
	if diving:
		return   # under the sea, her diver (swimmer, set by Dive) carries her everywhere
	if not on_water():
		if swimmer:
			_set_swimmer(null)
		return
	var s: Dino = swimmer if swimmer and Game.party.has(swimmer) else SWIM.swimmer()
	if s != swimmer or (s and mount):
		_set_swimmer(s)


func _set_swimmer(s: Dino) -> void:
	var was := swimmer != null
	if s and mount:
		mount = null   # her mount does not swim: the swimmer takes her on its back
	swimmer = s
	if was and s == null:
		trail = [global_position]   # her dino walks behind her again, from the shore
	if was != (s != null):
		var view := get_tree().get_first_node_in_group(&"world_view") as WorldView
		if view:
			view.splash(global_position)
	swim_changed.emit(s != null)


## Walking against deep water she cannot go into: a word about why, once in the zone.
func _watch_water(input: Vector2, moved: float, delta: float) -> void:
	if _water_told or input.length() < 0.5 or collision_mask & SWIM.WATER_LAYER == 0 or not surface_at.is_valid():
		_push_time = 0.0
		return
	var ahead := global_position + input.normalized() * WATER_PROBE
	if moved < top_speed() * delta * 0.3 and surface_at.call(ahead) == &"water":
		_push_time += delta
		if _push_time >= WATER_TELL_S:
			_water_told = true
			Toast.say(get_tree(), SWIM.blocked_reason())
	else:
		_push_time = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and can_move():
		get_viewport().set_input_as_handled()
		_interact()


func _animate(input: Vector2) -> void:
	var speed := velocity.length()
	if input.length() > 0.1:
		facing = input
	if carried_by():   # in the saddle, or swimming on a dino's back: her pose is its (Saddle)
		return
	var dir := SheetFrames.direction_name(facing)
	if has_meta(&"pose"):   # a pose of a scene (Stage.pose), held, turned where she looks
		sprite.play(Outfits.pose_anim(get_meta(&"pose"), dir, get_meta(&"pose_look", "")))
		return
	var look := Outfits.walk_look(self)   # (her accessories: Outfits)
	if speed > 12.0 and not _sliding:
		sprite.play(StringName(look + "walk_" + dir))
		# Quicker steps when faster, but less than the speed (running: longer strides, not a flurry).
		sprite.speed_scale = clampf(sqrt(speed / SPEED), 0.5, 1.3)
	else:
		sprite.play(StringName(look + "idle_" + dir))


func _track(moved: float) -> void:
	if moved <= 0.01:
		return
	if global_position.distance_to(trail[trail.size() - 1]) >= TRAIL_SPACING:
		trail.append(global_position)
		if trail.size() > TRAIL_LENGTH:
			trail.remove_at(0)
	_step_travel += moved
	if _step_travel >= STEP_DISTANCE * (RIDE_STEP if mount else SWIM.STROKE if swimmer else 1.0):
		_step_travel = 0.0
		var surface: StringName = surface_at.call(global_position) if surface_at.is_valid() else &"grass"
		if not swimmer and not _sliding:   # (none while swimming, nor sliding on)
			_play_step(step_kind(surface, _on_snow(), cold))
		stepped.emit(surface)


## The kind of step on `surface` (Region.surface_at): &"ice" on the "sand" of a cold zone (`icy`),
## &"snow" where the snow lies (`on_snow`), else &"path" on the path, &"grass" elsewhere.
static func step_kind(surface: StringName, on_snow: bool, icy := false) -> StringName:
	if icy and surface == &"sand":
		return &"ice"
	if on_snow:
		return &"snow"
	return &"path" if surface == &"path" else &"grass"


## Does the snow lie under her feet? Where the zone has a cover layer, where it is thick
## (Region.snow_at over 0.5); in a cold zone without one, everywhere.
func _on_snow() -> bool:
	var cover: float = snow_at.call(global_position) if snow_at.is_valid() else -1.0
	return cover > 0.5 if cover >= 0.0 else cold


func _play_step(kind: StringName) -> void:
	var lift := MOUNT_STEP_DB if mount else 0.0
	match kind:
		&"snow":
			Audio.play_sfx(SNOW_STEPS.pick_random(), STEP_DB[kind] + lift, 0.08)
		&"ice":
			Audio.play_sfx(FOOTSTEPS.pick_random(), STEP_DB[kind] + lift, 0.05, ICE_PITCH)
			_to_crack -= 1
			if _to_crack <= 0:
				_to_crack = randi_range(CRACK_EVERY.x, CRACK_EVERY.y)
				Audio.play_sfx(ICE_CRACKS.pick_random(), STEP_DB[&"crack"] + lift, 0.08)
		_:
			Audio.play_sfx(FOOTSTEPS.pick_random(), STEP_DB[kind] + lift, 0.08)


## Interacts with the closest interactable in front of Chloé (group "interactable",
## method interact(player) which may be a coroutine).
func _interact() -> void:
	var best: Node2D = null
	var best_score := INF
	for node in get_tree().get_nodes_in_group(&"interactable"):
		var target := node as Node2D
		# `visible`, not is_visible_in_tree(): the 2D world is not drawn (the 3D view shows it).
		if target == null or not target.visible:
			continue
		var to := target.global_position - global_position
		var dist := to.length()
		if dist > INTERACT_REACH + target.get_meta(&"reach_bonus", 0.0):
			continue
		# Prefer what Chloé faces.
		var score := dist - facing.normalized().dot(to.normalized()) * 30.0
		if score < best_score:
			best_score = score
			best = target
	if best == null:
		return
	busy = true
	velocity = Vector2.ZERO
	await best.interact(self)
	busy = false


func face_towards(point: Vector2) -> void:
	facing = (point - global_position).normalized()
	_animate(Vector2.ZERO)


## Places Chloé (spawn, loaded game) and resets the companion trail.
func teleport(pos: Vector2) -> void:
	global_position = pos
	reset_physics_interpolation()
	trail = [pos]
	_water_told = false
