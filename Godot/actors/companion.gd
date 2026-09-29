class_name Companion
extends Node2D
## The lead dino of the party, walking in Chloé's footsteps (it follows her trail, so it
## goes around obstacles the way she did). Looks like the party's lead dino.
## It senses what is hidden nearby (group "secret": a tree or a stone hiding an amber pebble,
## buried earth): a "!" over its head, a little cry when it first notices. Glad when found.
## It also reacts to the places it comes to (see REACTIONS): the water, a fire, a cave.
## Each step together makes its Lien grow (Game.grow_bond): a "♥" over it at a new heart.
## When Chloé rides (Player.mount), it is her mount instead: under her, carrying her (Saddle).
## In deep water (Player.swimmer), the swimmer of the party carries her the same way, half
## under the water (the view sinks them both: WorldView).
## Its size: its species', as grown as its level (DinoSize); it keeps behind her as far as it
## is long. Carrying her, a big one is shown smaller (DinoSize.MOUNT_MAX_M): it shrinks as she
## climbs on and grows back as she gets down (RESIZE_S), as it grows when it levels up.
## Through a door (Doorway), it goes in after her if it fits, or waits outside (`outside`).

const CATCH_UP := 7.0        # how fast it closes the gap
const RESIZE_S := 0.45       # a change of size (mounting, getting down, growing up)
const BESIDE := Vector2(-34, 8)   # placed beside Chloé: at least this far on her left (px)
const KEEP_ROOM := 12.0           # px between her feet and its tail end, at the closest
const IDLE_CRY_CHANCE := 0.12
const HINT_RANGE := 150.0    # px (about 3 tiles)
const HINT_CHECK_S := 0.4
const REJOICE_DELAY_S := 0.7   # the pebble's chime first, then the dino's cry
## A place it reacts to -> [what it shows over its head, how near (px)].
const REACTIONS := {&"water": ["~", 90.0], &"fire": ["♥", 110.0], &"cave": ["?", 260.0]}
## The same kind of place does not make it react again before this long (s).
const REACT_AGAIN_S := 40.0
const SWIM := preload("res://world/swim.gd")

var player: Player
var dino: Dino

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var cry_player: AudioStreamPlayer2D = $Cry

var _idle_time := 0.0
var _idle_anim: StringName = &"idle"
var _shadow: Sprite2D
## Something hidden is near (the view shows a "!").
var hint := false
var _hint_timer := 0.0
var _last_reaction := {}   # kind -> time (s) of its last reaction
var _saddle: Saddle   # while Chloé rides
var _follow_gap := DinoSize.FOLLOW_MIN   # trail points it walks behind Chloé
var _keep := 24.0     # px: it never stands closer to her feet than this (half its length and a bit)
var _shown: Dino      # the dino it looks like (its size changes smoothly while it stays)
var _resize: Tween
var _shadow_width := 0.0   # its shadow's width at sprite scale 1
## Waiting outside a door too small for it (Doorway): not in the zone Chloé went into (hidden,
## not following her) until she comes out again.
var outside := false:
	set(value):
		outside = value
		visible = dino != null and not outside


func _ready() -> void:
	add_to_group(&"companion")
	_shadow = Shadow.make(self)
	Game.party_changed.connect(refresh)
	if player:
		player.stepped.connect(_on_step)
		player.swim_changed.connect(func(_swimming: bool) -> void: refresh())
	refresh()


## A step at Chloé's side (or carrying her): the Lien grows. A new heart: a "♥" and a cry.
func _on_step(_surface: StringName) -> void:
	if dino == null or player.busy:
		return
	if Game.grow_bond(dino, Game.BOND_STEP) > 0:
		cry(&"neutre")
		var view := get_tree().get_first_node_in_group(&"world_view") as WorldView
		if view:
			view.emote(self, "♥")


func refresh() -> void:
	if player and player.mount and not Game.party.has(player.mount):   # sent to the Cabinet meanwhile
		player.mount = null
	if player and player.swimmer and not Game.party.has(player.swimmer):   # another swimmer, if any
		player.swimmer = SWIM.swimmer()
	dino = player.carried_by() if carrying() else Game.lead_dino()
	visible = dino != null and not outside
	if dino == null:
		return
	var species := dino.species()
	var was_carrying := _saddle != null
	_seat_rider(species)
	var walking := DinoSize.world_scale(dino)
	var size := DinoSize.mount_scale(species, walking, swimming()) if carrying() else walking
	_follow_gap = DinoSize.follow_gap(species, walking)
	_keep = DinoSize.length_px(species, walking) * 0.5 + KEEP_ROOM
	sprite.sprite_frames = SheetFrames.dino(species)
	var h := species.sheet.get_height() / float(species.sheet_rows)
	sprite.offset = Vector2(0, -h * 0.46)
	_shadow_width = species.sheet.get_width() / float(species.sheet_columns) * 0.55
	if dino != _shown:
		_set_size(walking)   # another dino (the mount of the party taking her): from its own size
	_resize_to(size, dino == _shown or carrying() != was_carrying)
	_shown = dino
	_shadow.visible = not swimming()   # (under the water, no shadow on the ground)
	sprite.play(&"idle")


## How near Chloé it stands at the closest (px from her feet to its middle: half its length and
## a bit), for the scenes that place it beside her.
func keep_px() -> float:
	return _keep


## Takes sprite scale `size`: smoothly (the same dino, mounting or growing), or at once.
func _resize_to(size: float, smooth: bool) -> void:
	if _resize and _resize.is_valid():
		_resize.kill()
	if not smooth or is_equal_approx(sprite.scale.y, size):
		_set_size(size)
		return
	_resize = create_tween()
	_resize.tween_method(_set_size, sprite.scale.y, size, RESIZE_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_size(size: float) -> void:
	sprite.scale = Vector2.ONE * size
	Shadow.fit(_shadow, _shadow_width * size)
	if sprite.has_meta(&"stage_scale"):   # (a scene's move puts it back to this size)
		sprite.set_meta(&"stage_scale", sprite.scale)



func _physics_process(delta: float) -> void:
	if player == null or dino == null or outside:
		return
	_hint_timer -= delta
	if _hint_timer <= 0.0:
		_hint_timer = HINT_CHECK_S
		_sense()
	if carrying():
		_carry(delta)
		return
	var trail := player.trail
	var target := trail[maxi(0, trail.size() - 1 - _follow_gap)]
	# Never on top of her (her trail too short: she has not walked yet, or a scene pointed it
	# right beside her): it stops on its side, as far as its length asks.
	if target.distance_to(player.global_position) < _keep:
		var side := global_position - player.global_position
		target = player.global_position + (side.normalized() if side.length() > 1.0 else Vector2.LEFT) * _keep
	var before := global_position
	global_position = global_position.lerp(target, 1.0 - exp(-CATCH_UP * delta))
	var step := global_position - before
	if step.length() > 0.4:
		if absf(step.x) > 0.2:
			sprite.flip_h = step.x < 0.0
		var anims: Array = SheetFrames.dino_anims(sprite.sprite_frames, step)
		_idle_anim = anims[1]
		sprite.play(anims[0])
		sprite.speed_scale = clampf(step.length() / (delta * 120.0), 0.6, 1.5)
		_idle_time = 0.0
	else:
		sprite.play(_idle_anim)
		sprite.speed_scale = 1.0
		_idle_time += delta
		if _idle_time > 5.0:
			_idle_time = 0.0
			if randf() < IDLE_CRY_CHANCE:
				cry(&"neutre")


func _process(_delta: float) -> void:
	var view := get_tree().get_first_node_in_group(&"world_view") as WorldView
	if view:
		view.show_hint(self, hint and visible)


## Chloé on its back: in the saddle, or swimming.
func carrying() -> bool:
	return player != null and player.carried_by() != null


## Swimming with Chloé on its back (half under the water, in the view).
func swimming() -> bool:
	return player != null and player.mount == null and player.swimmer != null


## Chloé in the saddle on it, or back on her feet.
func _seat_rider(species: DinoSpecies) -> void:
	if player == null or not player.is_node_ready():
		return
	var was_riding := _saddle != null
	_saddle = Saddle.new(species, player.sprite) if carrying() else null
	# Both cut out (WorldView._sync): sorted by depth, never blended with what stands behind.
	set_meta(&"cut_out", carrying())
	player.set_meta(&"cut_out", carrying())
	var shadow := player.get_node_or_null("Shadow") as CanvasItem
	if shadow:
		shadow.visible = not carrying()
	if was_riding and not carrying():
		player.sprite.position = Vector2.ZERO
		player.face_towards(player.global_position + player.facing)


## Under Chloé, going where she goes; she sits as it is seen (Saddle.place).
func _carry(_delta: float) -> void:
	var v := player.velocity
	if absf(v.x) > 8.0:
		sprite.flip_h = v.x < 0.0
	if v.length() > 12.0:
		var anims: Array = SheetFrames.dino_anims(sprite.sprite_frames, v)
		_idle_anim = anims[1]
		sprite.play(anims[0])
		sprite.speed_scale = clampf(v.length() / 180.0, 0.8, 1.6)
	else:
		sprite.play(_idle_anim)
		sprite.speed_scale = 1.0
	# Also when it turns to look at something.
	var seat := _saddle.place(sprite.animation, sprite.flip_h, sprite.scale.y)
	global_position = player.global_position + Vector2(0, seat["depth"])
	player.sprite.position = seat["at"]
	player.sprite.play(seat["pose"])


## Is something hidden within reach? Noticing it: a little cry, a look towards it.
func _sense() -> void:
	var near: Node2D = null
	for s in get_tree().get_nodes_in_group(&"secret"):
		var n := s as Node2D
		if n and n.call(&"is_hiding") and n.global_position.distance_to(global_position) < HINT_RANGE:
			near = n
			break
	if near and not hint:
		sprite.flip_h = near.global_position.x < global_position.x
		cry(&"neutre")
	hint = near != null
	if not hint:
		_react_to_places()


## Near water, a fire or a cave: it looks, and shows what it thinks (once in a while).
func _react_to_places() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for kind: StringName in REACTIONS:
		if now - float(_last_reaction.get(kind, -INF)) < REACT_AGAIN_S:
			continue
		var at := _place_near(kind, REACTIONS[kind][1])
		if at == Vector2.INF:
			continue
		_last_reaction[kind] = now
		sprite.flip_h = at.x < global_position.x
		cry(&"neutre")
		var view := get_tree().get_first_node_in_group(&"world_view") as WorldView
		if view:
			view.emote(self, REACTIONS[kind][0])
		return


## Where the nearest place of that kind is, within `reach` px (Vector2.INF: none).
func _place_near(kind: StringName, reach: float) -> Vector2:
	match kind:
		&"water":
			if player and player.surface_at.is_valid():
				for dir: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
					var p := global_position + dir * reach
					if player.surface_at.call(p) == &"water":
						return p
		&"fire":
			for f in get_tree().get_nodes_in_group(&"fire"):
				if (f as Node2D).global_position.distance_to(global_position) < reach:
					return (f as Node2D).global_position
		&"cave":
			for m in get_tree().get_nodes_in_group(&"cave_mouth"):
				if (m as Node2D).global_position.distance_to(global_position) < reach:
					return (m as Node2D).global_position
	return Vector2.INF


## Glad (an amber pebble found): two little hops, then a cry (after the pebble's chime).
func rejoice() -> void:
	var base := sprite.position.y
	var t := create_tween()
	t.tween_interval(REJOICE_DELAY_S)
	t.tween_callback(cry.bind(&"neutre"))
	for i in 2:
		t.tween_property(sprite, "position:y", base - 10.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(sprite, "position:y", base, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func teleport(pos: Vector2) -> void:
	global_position = pos
	reset_physics_interpolation()


## Placed beside Chloé standing at `chloe_at` (entering a zone, as she gets down, after a lost
## battle): on her left, as far as its length asks, and it waits there until she walks (her
## trail starts from it).
func stand_beside(chloe_at: Vector2) -> void:
	var half := DinoSize.length_px(dino.species(), DinoSize.world_scale(dino)) * 0.5 if dino else 0.0
	var gap := maxf(absf(BESIDE.x), half + KEEP_ROOM)
	teleport(chloe_at + Vector2(-gap, BESIDE.y))
	if player:
		player.trail = PackedVector2Array([global_position, chloe_at])


func cry(kind: StringName) -> void:
	var stream := dino.species().cry(kind)
	if stream:
		cry_player.stream = stream
		cry_player.pitch_scale = randf_range(1.05, 1.18)   # a young dino: slightly higher
		cry_player.play()


## Short "action" pose (using an ability): lunge towards `point` and back.
func perform_at(point: Vector2) -> void:
	sprite.flip_h = point.x < global_position.x
	sprite.play(&"attack")
	cry(&"attaque")
	if carrying():   # Chloé on its back: it rears where it stands
		await get_tree().create_timer(0.45).timeout
		sprite.play(&"idle")
		return
	var home := global_position
	var t := create_tween()
	t.tween_property(self, "global_position", home.lerp(point, 0.6), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(self, "global_position", home, 0.3).set_trans(Tween.TRANS_SINE)
	await t.finished
	sprite.play(&"idle")
