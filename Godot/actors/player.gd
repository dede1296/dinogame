class_name Player
extends CharacterBody2D
## Chloé: analog top-down movement (keyboard, gamepad or touch joystick), walk animation,
## footsteps by ground type (in the snow and on the ice too), interaction with what is in front of her. She can ride a big
## dino (Monture, with Joss's saddle): faster, sitting on its back (the companion carries her).
## With the swimming vest and a grown swimmer, she swims across deep water on its back (Swim):
## it starts by itself as she walks into the water, and ends on the shore.
## She is 1.50 m tall (Heights: her sprite's scale, her shadow). On slippery ice (Region.slippery)
## she gets going and stops slowly: she slides a little, and her mount too.
## Over the lava of the Plaine Volcanique (Lava, chapter 8), on the back of her lead dino if it is of
## Stone or Fire (lava_walker): it starts by itself as she walks on to a flow, and ends on the rock;
## near the flows, on foot, the heat rises (Heat) and she steps back to the cool rock (step_away).

signal stepped(surface: StringName)
## Chloé starts (true) or stops swimming, or another dino carries her in the water.
signal swim_changed(swimming: bool)
## Chloé climbs on (true) or off the back of the dino carrying her over the lava.
signal lava_changed(on_lava: bool)

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
## A click's errand: she stops this share of the reach from the target; a held key above this
## cancels it; moving slower than this share of her speed for this long means she is stuck.
const GOAL_ARRIVE := 0.8
const GOAL_CANCEL_INPUT := 0.2
const GOAL_STUCK_SPEED := 0.25
const GOAL_GIVE_UP_S := 1.2
const TRAIL_SPACING := 6.0
const TRAIL_LENGTH := 48
## Walking against deep water she cannot swim in, this long (s): told why (once per zone).
const WATER_TELL_S := 0.7
const WATER_PROBE := 22.0      # px ahead of her feet where the water is looked for
## The « surface » of a wingbeat in the air (stepped): nothing there to walk on, nor to hide in.
const AIR := &"air"
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
## On the volcano's ash (the Plaine Volcanique and the Terre des Apex: World.ASH_ZONES, `ashy`): dry, crunchy steps.
const ASH_STEPS: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/cendre00.ogg"), preload("res://assets/audio/footsteps/cendre01.ogg"),
	preload("res://assets/audio/footsteps/cendre02.ogg"), preload("res://assets/audio/footsteps/cendre03.ogg"),
	preload("res://assets/audio/footsteps/cendre04.ogg"), preload("res://assets/audio/footsteps/cendre05.ogg"),
]
const ICE_CRACKS: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/glace_craque00.ogg"), preload("res://assets/audio/footsteps/glace_craque01.ogg"),
	preload("res://assets/audio/footsteps/glace_craque02.ogg"),
]
const ICE_PITCH := 0.8
const CRACK_EVERY := Vector2i(4, 6)
## Step levels (dB) by kind (see step_kind): softer on grass, crisper on the path; the snow's crunch
## lasts longer, so it is played lower; a crack lower still. On a mount, MOUNT_STEP_DB louder.
const STEP_DB := {&"grass": -13.0, &"path": -8.0, &"snow": -15.0, &"ice": -11.0, &"crack": -17.0, &"ash": -13.0}
const MOUNT_STEP_DB := 4.0

## Asked for the ground type under a position (set by the world, from the region).
var surface_at: Callable
## Asked how thick the snow lies at a position (Region.snow_at: 0–1, -1 without a snow layer).
var snow_at: Callable
## Ash underfoot (the volcano's zones, set by the world): the steps are those of the ash.
var ashy := false
## A cold region (Region.cold, set by the world): steps on the ice (and in the snow without a
## cover layer); her coat (Outfits).
var cold := false
## Its ice ("sand" tiles) is slippery (Region.slippery, set by the world).
var slippery := false
## Recent positions, oldest first: the companion walks in Chloé's footsteps.
var trail: PackedVector2Array = []
var facing := Vector2.DOWN
## Where her picture looks among 8 directions (SheetFrames.next_view): used on her feet when her
## look's sheet has three-quarter views (X_diag.png), else the dominant axis of `facing`.
var _view := {}
var busy := false   # during an interaction
var _goal: Node2D            # what a click sent her to (go_and_interact)
var _goal_stuck_s := 0.0
## The dino Chloé rides (null: on foot). Set by the world (World.mount / dismount).
var mount: Dino = null
## The dino carrying her in deep water (null: not swimming). Set here, as she walks in or out.
var swimmer: Dino = null
## Under the sea (a zone played under the water): her diver carries her the whole time (Dive).
var diving := false
## The great pterosaur carrying her in the air (le Vol, story/vol.gd), and the flight's state
## (actors/flight.gd): both null on the ground. Set by Vol.
var flyer: Dino = null
var flight: Flight = null
## The dino of Stone or Fire carrying her over the lava (null: not on a flow). Set here (Lava).
var lava_walker: Dino = null

@onready var sprite: AnimatedSprite2D = $Sprite

var _step_travel := 0.0
var _push_time := 0.0      # walking against water she cannot swim in (s)
var _water_told := false   # …and told why, in this zone
var _to_crack := CRACK_EVERY.x   # steps on the ice before the next crack
var _sliding := false            # gliding on over the ice, feet still (no input)
var _lava_push := 0.0            # walking against lava she cannot cross (s)
var _lava_told := false          # …and told why, in this zone
## Where the heat sends her back to, out of it (Heat; Vector2.INF: nowhere).
var _away_to := Vector2.INF
var _away_stuck_s := 0.0
const AWAY_ARRIVE := 14.0
var heat: Heat


func _ready() -> void:
	add_to_group(&"player")
	sprite.scale = Vector2.ONE * Heights.sprite_scale(SHEET)
	Shadow.make(self, Heights.shadow_width(SHEET))
	sprite.sprite_frames = SheetFrames.character(SHEET, 15.0)
	Outfits.dress_chloe(sprite.sprite_frames, 15.0)   # in her walking boots, once she has them
	sprite.play(&"idle_down")
	trail.append(global_position)
	collision_mask = SWIM.SOLID_LAYER | SWIM.WATER_LAYER | Lava.LAYER
	heat = Heat.new()
	heat.player = self
	add_child(heat)


func can_move() -> bool:
	return not busy and not Dialogue.active and not Router.is_busy()


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if can_move():
		input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		input = _walk_to_goal(input, delta)
	if flight:
		_fly(input, delta)
		return
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
	_update_lava()
	_watch_water(input, moved, delta)
	_watch_lava(input, moved, delta)
	_animate(input)
	_track(moved)
	RenderingServer.global_shader_parameter_set(&"player_position", global_position)


## In the air (Vol): steered freely over everything (her mask is empty), held in the zone and taken
## out of it by its edges (Flight.after_move); no input while landing. A scene starting in the air
## sets her down at once, where it is safe (Vol.set_down_safely).
func _fly(input: Vector2, delta: float) -> void:
	mount = null   # (never both: the harness, not the saddle)
	if busy and Story.playing > 0 and not flight.is_landing():
		Vol.set_down_safely(self)
		return
	if flight.is_landing():
		input = Vector2.ZERO
	velocity = velocity.move_toward(input * top_speed(), Flight.ACCEL * delta)
	var before := global_position
	move_and_slide()
	flight.after_move()
	if flight == null:   # (gone out of the zone: set down on the other side)
		return
	flight.update(delta)
	_animate(input)
	_track(global_position.distance_to(before))
	RenderingServer.global_shader_parameter_set(&"player_position", global_position)


func is_flying() -> bool:
	return flight != null


## Where the game saves her: where she stands, or in the air the last safe place flown over.
func save_position() -> Vector2:
	return flight.safe_point if flight else global_position


func top_speed() -> float:
	var run := running()
	if flight:
		return flight.top_speed(run)
	if mount:
		return SPEED * (GALLOP_SPEED if run else RIDE_SPEED)
	if swimmer:
		return SPEED * SWIM.SPEED
	if lava_walker:
		return SPEED * Lava.SPEED
	var boots := Game.item_count("bottes") > 0
	if run:
		return SPEED * (BOOTS_RUN_SPEED if boots else RUN_SPEED)
	return SPEED * (BOOTS_SPEED if boots else 1.0)


## Shift or the pad's B held: she runs, her mount gallops. On a phone, holding the B button
## (which is the « cancel » action) runs too; on a computer Échap opens the menu instead.
func running() -> bool:
	if Input.is_action_pressed(&"run"):
		return true
	return not Screen.on_computer() and Input.is_action_pressed(&"cancel")


## On slippery ice (Region.slippery: its "sand" tiles), on foot or on her mount.
func _on_slippery_ice() -> bool:
	return slippery and not diving and swimmer == null and surface_at.is_valid() and surface_at.call(global_position) == &"sand"


## The dino carrying Chloé (her flyer in the air, her mount, her swimmer in the water, or her dino
## of Stone or Fire over the lava), or null: on her feet.
func carried_by() -> Dino:
	if flyer:
		return flyer
	if mount:
		return mount
	return swimmer if swimmer else lava_walker


func is_swimming() -> bool:
	return swimmer != null


## On a lava flow, on the back of her dino of Stone or Fire (Lava).
func is_on_lava() -> bool:
	return lava_walker != null


## The zone she walks in (the one the world gave her ground from), or null.
func region() -> Region:
	return surface_at.get_object() as Region if surface_at.is_valid() else null


## Deep water stops her, unless she can swim, or already stands in it (never stuck there); the
## lava too, unless her lead dino has the Cuir de feu, or she already stands on it.
func _update_water_mask() -> void:
	var free := swimmer != null or on_water() or SWIM.can_swim()
	var lava_free := lava_walker != null or Lava.can_cross() or on_lava()
	var mask := SWIM.SOLID_LAYER | (0 if free else SWIM.WATER_LAYER) | (0 if lava_free else Lava.LAYER)
	if collision_mask != mask:
		collision_mask = mask


## Is Chloé standing on lava (a flow she may cross on a dino of Stone or Fire)?
func on_lava() -> bool:
	var f := Lava.field(region())
	return f != null and f.is_crossable(global_position)


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


## On a lava flow, on the back of her lead dino of Stone or Fire (the one already carrying her, while
## it stays in the party); on the rock, on her feet again. The very first time: a few words (Lava).
func _update_lava() -> void:
	if diving or flight:
		return
	if not on_lava():
		if lava_walker:
			_set_lava_walker(null)
		return
	var w: Dino = lava_walker if lava_walker and Game.party.has(lava_walker) else Lava.walker()
	if w != lava_walker or (w and mount):
		_set_lava_walker(w)


func _set_lava_walker(w: Dino) -> void:
	var was := lava_walker != null
	if w and mount:
		mount = null   # her mount does not cross the lava: the dino of Stone or Fire takes her
	lava_walker = w
	if was and w == null:
		trail = [global_position]   # her dino walks behind her again, from the rock
	if was != (w != null):
		lava_changed.emit(w != null)
	if w and not Game.flag(Lava.FLAG_CROSSED):
		Lava.tell_crossed(self, w)


## Walking against lava she cannot cross: why, and who could, once in the zone (Lava).
func _watch_lava(input: Vector2, moved: float, delta: float) -> void:
	if _lava_told or input.length() < 0.5 or collision_mask & Lava.LAYER == 0 or not Lava.has_lava(region()):
		_lava_push = 0.0
		return
	var ahead := global_position + input.normalized() * WATER_PROBE
	if moved < top_speed() * delta * 0.3 and Lava.at(region(), ahead):
		_lava_push += delta
		if _lava_push >= WATER_TELL_S:
			_lava_told = true
			Lava.tell_blocked(self)
	else:
		_lava_push = 0.0


## Too hot (Heat): she walks back by herself to `to`, the cool rock; a key or the stick takes her back.
func step_away(to: Vector2) -> void:
	_goal = null
	_away_to = to
	_away_stuck_s = 0.0


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
		if flight:   # (nothing to talk to up there: A sets her down, like the harness's key)
			Vol.land(get_tree().current_scene)
		else:
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
	# On her feet, her three-quarter views when her look's sheet has them (SheetFrames.walk_dir).
	_view = SheetFrames.next_view(_view, facing, input.length() > 0.1, get_physics_process_delta_time())
	dir = SheetFrames.walk_dir(sprite.sprite_frames, look, _view, facing)
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
	if _step_travel >= STEP_DISTANCE * (RIDE_STEP if mount or flight or lava_walker else SWIM.STROKE if swimmer else 1.0):
		_step_travel = 0.0
		if flight:   # (a wingbeat: no footstep, and no dino hidden in the grass below reaches her)
			stepped.emit(AIR)
			return
		var surface: StringName = surface_at.call(global_position) if surface_at.is_valid() else &"grass"
		if not swimmer and not _sliding:   # (none while swimming, nor sliding on)
			_play_step(step_kind(surface, _on_snow(), cold, ashy))
		stepped.emit(surface)


## The kind of step on `surface` (Region.surface_at): &"ice" on the "sand" of a cold zone (`icy`),
## &"snow" where the snow lies (`on_snow`), else &"path" on the path, &"grass" elsewhere.
static func step_kind(surface: StringName, on_snow: bool, icy := false, ashy := false) -> StringName:
	if icy and surface == &"sand":
		return &"ice"
	if on_snow:
		return &"snow"
	if ashy and surface != &"water":
		return &"ash"
	return &"path" if surface == &"path" else &"grass"


## Does the snow lie under her feet? Where the zone has a cover layer, where it is thick
## (Region.snow_at over 0.5); in a cold zone without one, everywhere.
func _on_snow() -> bool:
	var cover: float = snow_at.call(global_position) if snow_at.is_valid() else -1.0
	return cover > 0.5 if cover >= 0.0 else cold


func _play_step(kind: StringName) -> void:
	var lift := MOUNT_STEP_DB if mount or lava_walker else 0.0
	match kind:
		&"snow":
			Audio.play_sfx(SNOW_STEPS.pick_random(), STEP_DB[kind] + lift, 0.08)
		&"ash":
			Audio.play_sfx(ASH_STEPS.pick_random(), STEP_DB[kind] + lift, 0.08)
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
	var best := nearest_interactable()
	if best == null:
		return
	await _interact_with(best)


func _interact_with(target: Node2D) -> void:
	busy = true
	velocity = Vector2.ZERO
	await target.interact(self)
	busy = false


## A click on something usable (WorldView → ClickInteract): in reach, Chloé uses it at once; further
## away she walks to it in a straight line, then uses it. Any key or stick movement cancels it.
func go_and_interact(target: Node2D) -> void:
	if not can_move() or target == null or not target.visible or flight:
		return
	if _in_reach(target):
		face_towards(target.global_position)
		_interact_with(target)
		return
	_goal = target
	_goal_stuck_s = 0.0


## Leaves the click's errand (a move by hand, a scene, a dialogue).
func cancel_goal() -> void:
	_goal = null


func _in_reach(target: Node2D) -> bool:
	return global_position.distance_to(target.global_position) <= INTERACT_REACH * GOAL_ARRIVE + float(target.get_meta(&"reach_bonus", 0.0))


## The direction she goes towards the click's target, or `input` (what the player holds) if none.
func _walk_to_goal(input: Vector2, delta: float) -> Vector2:
	if _away_to != Vector2.INF:
		return _walk_away(input, delta)
	if _goal == null:
		return input
	if input.length() > GOAL_CANCEL_INPUT or not is_instance_valid(_goal) or not _goal.visible:
		_goal = null
		return input
	if _in_reach(_goal):
		var target := _goal
		_goal = null
		face_towards(target.global_position)
		_interact_with(target)
		return Vector2.ZERO
	# Not getting anywhere (a wall, the water): she gives up rather than push for ever.
	_goal_stuck_s = _goal_stuck_s + delta if velocity.length() < top_speed() * GOAL_STUCK_SPEED else 0.0
	if _goal_stuck_s > GOAL_GIVE_UP_S:
		_goal = null
		return Vector2.ZERO
	return (_goal.global_position - global_position).normalized()


## Out of the heat (step_away): towards the cool rock, until there, stuck, or taken back by hand.
func _walk_away(input: Vector2, delta: float) -> Vector2:
	if input.length() > GOAL_CANCEL_INPUT or global_position.distance_to(_away_to) < AWAY_ARRIVE:
		_away_to = Vector2.INF
		return input
	_away_stuck_s = _away_stuck_s + delta if velocity.length() < top_speed() * GOAL_STUCK_SPEED else 0.0
	if _away_stuck_s > GOAL_GIVE_UP_S:
		_away_to = Vector2.INF
		return Vector2.ZERO
	return (_away_to - global_position).normalized()


## What a press of « interact » would reach now: the closest interactable in reach, preferring what
## Chloé faces. Also what the interaction prompt (ui/interact_prompt.gd) points at.
func nearest_interactable() -> Node2D:
	if flight:   # (nothing within reach up there)
		return null
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
	return best


func face_towards(point: Vector2) -> void:
	facing = (point - global_position).normalized()
	_view = {}   # (turned on purpose: no margin, no hold)
	_animate(Vector2.ZERO)


## Places Chloé (spawn, loaded game) and resets the companion trail. In the air (a way out of the
## zone taken in flight, a scene): she is set down there, on her feet.
func teleport(pos: Vector2) -> void:
	global_position = pos
	reset_physics_interpolation()
	trail = [pos]
	_water_told = false
	_lava_told = false
	_away_to = Vector2.INF
	if flight:
		Vol.set_down(self)   # (her dino beside her, where she now stands)
