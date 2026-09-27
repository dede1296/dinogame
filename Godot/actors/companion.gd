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

const FOLLOW_GAP := 8        # trail points behind Chloé (~48 px)
const CATCH_UP := 7.0        # how fast it closes the gap
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
	visible = dino != null
	if dino == null:
		return
	var species := dino.species()
	_seat_rider(species)
	var size := species.world_scale * (Saddle.SCALE if carrying() else 1.0)
	sprite.sprite_frames = SheetFrames.dino(species)
	sprite.scale = Vector2.ONE * size
	var h := species.sheet.get_height() / float(species.sheet_rows)
	sprite.offset = Vector2(0, -h * 0.46)
	Shadow.fit(_shadow, species.sheet.get_width() / float(species.sheet_columns) * size * 0.55)
	_shadow.visible = not swimming()   # (under the water, no shadow on the ground)
	sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	if player == null or dino == null:
		return
	_hint_timer -= delta
	if _hint_timer <= 0.0:
		_hint_timer = HINT_CHECK_S
		_sense()
	if carrying():
		_carry(delta)
		return
	var trail := player.trail
	var target := trail[maxi(0, trail.size() - 1 - FOLLOW_GAP)]
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
	var seat := _saddle.place(sprite.animation, sprite.flip_h)
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
