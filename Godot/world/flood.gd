@tool
class_name Flood
extends Node2D
## Flood water in the sunken temple (Marais, chapter 3): water filling a passage right up,
## so nobody gets through, not even swimming (it blocks everyone, on the "monde" layer).
## It is there until the story drains it: `dry_flag` set (a sluice turned by a StoryProp);
## or, with `flooded_flag`, only while that flag is set (a sluice that can flood it again).
## When the flag changes (Game.flag_changed), the water goes down (or rises) before Chloé's
## eyes: the 3D view draws it as a block of water `depth` m high, times `fill` (WorldView).
## If it rises while Chloé stands in it, it lets her step out before it blocks the way.
## Walking up to it and pressing A: `blocked_dialogue`, or a line saying what is wrong.
## `size` in tiles, from the node's position (its top-left corner), like a Dock.

signal changed(wet: bool)

const TILE := 48.0
const DRAIN_S := 2.8
const RISE_S := 2.2
const SOUND := preload("res://assets/audio/ambience/eau.ogg")
const GATES := preload("res://assets/audio/sfx/rock_heavy.wav")
const BLOCKED_LINE := "L'eau a tout envahi : impossible de passer, même à la nage. Il faudrait trouver comment la faire baisser…"

@export var size := Vector2(4, 3):
	set(value):
		size = value
		queue_redraw()
## Once this story flag is set, the water is gone (empty: see flooded_flag).
@export var dry_flag: StringName
## If set: the water is there only while this story flag is set.
@export var flooded_flag: StringName
## Metres of water over the floor when full (the view).
@export var depth := 1.1
## Lines when Chloé looks at the water (DialogueDB id; empty: BLOCKED_LINE).
@export var blocked_dialogue: StringName

## How full it is now, 0 (drained) to 1 (full): animated as it drains or rises.
var fill := 1.0
## The water is there (or on its way up); false once it is draining.
var wet := true

var _body: StaticBody2D
var _shape: CollisionShape2D
var _bank: Bank
var _tween: Tween
var _fade: Tween
var _sound: AudioStreamPlayer
## Rising while Chloé stands in it: blocks the way once she has stepped out.
var _block_when_clear := false


## Where Chloé looks at the water from: the point of its edge nearest to her (_process).
class Bank:
	extends Node2D
	var flood   # the Flood

	func interact(player: Player) -> void:
		await flood.look(player)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group(&"flood")
	_body = StaticBody2D.new()
	_body.name = "Eau"
	_body.collision_layer = 1
	_body.collision_mask = 0
	_shape = CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size * TILE
	_shape.shape = box
	_shape.position = size * TILE / 2.0
	_body.add_child(_shape)
	add_child(_body)
	_bank = Bank.new()
	_bank.name = "Bord"
	_bank.flood = self
	_bank.set_meta(&"reach_bonus", 10.0)
	add_child(_bank)
	_sound = AudioStreamPlayer.new()
	_sound.stream = SOUND
	_sound.bus = &"SFX"
	add_child(_sound)
	wet = should_be_wet()
	fill = 1.0 if wet else 0.0
	_set_blocking(wet)
	_set_lookable(wet)
	Game.flag_changed.connect(_on_flag_changed)


## Is the water meant to be there, from the story flags?
func should_be_wet() -> bool:
	if dry_flag != &"" and Game.flag(dry_flag):
		return false
	if flooded_flag != &"":
		return true if Game.flag(flooded_flag) else false
	return true


## The water's area in world pixels.
func area() -> Rect2:
	return Rect2(global_position if is_inside_tree() else position, size * TILE)


func _on_flag_changed(id: StringName, _value: Variant) -> void:
	if id != &"" and (id == dry_flag or id == flooded_flag):
		refresh()


## Follows the story flags: drains away (or rises) if they changed.
func refresh(animated := true) -> void:
	var now := should_be_wet()
	if now == wet:
		return
	wet = now
	changed.emit(wet)
	_set_lookable(wet)
	if _tween:
		_tween.kill()
	if not animated or not is_inside_tree():
		fill = 1.0 if wet else 0.0
		_set_blocking(wet)
		return
	Audio.play_sfx(GATES, -6.0, 0.05)   # the sluice's stones grinding
	_sound.volume_db = -8.0
	_sound.play()
	if wet:
		_set_blocking(true)   # (unless Chloé stands in it: then once she is out)
	var time := (RISE_S * (1.0 - fill)) if wet else (DRAIN_S * fill)
	_tween = create_tween()
	_tween.tween_property(self, "fill", 1.0 if wet else 0.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_settled)
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_sound, "volume_db", -40.0, time + 0.6).set_ease(Tween.EASE_IN)
	_fade.tween_callback(_sound.stop)


## The water is down (the way is open at once) or up.
func _settled() -> void:
	if not wet:
		_set_blocking(false)


## The water stops everyone (or not). Rising over Chloé: once she has stepped out.
func _set_blocking(on: bool) -> void:
	_block_when_clear = on and _chloe_inside()
	_shape.set_deferred(&"disabled", not on or _block_when_clear)


## Chloé can look at the water (press A by it) while it is there.
func _set_lookable(on: bool) -> void:
	if on:
		_bank.add_to_group(&"interactable")
	else:
		_bank.remove_from_group(&"interactable")


func _chloe_inside() -> bool:
	if not is_inside_tree():
		return false
	var chloe := get_tree().get_first_node_in_group(&"player") as Node2D
	return chloe != null and area().grow(14.0).has_point(chloe.global_position)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _bank == null:
		return
	var chloe := get_tree().get_first_node_in_group(&"player") as Node2D
	if chloe == null:
		return
	if _block_when_clear and wet and not _chloe_inside():
		_set_blocking(true)
	# Chloé looks at the water from wherever she stands by it.
	var r := area()
	_bank.global_position = Vector2(clampf(chloe.global_position.x, r.position.x, r.end.x),
		clampf(chloe.global_position.y, r.position.y, r.end.y))


## Chloé looks at the water: what the story says, or that she needs to lower it.
func look(player: Player) -> void:
	player.face_towards(_bank.global_position)
	var lines: Array = DialogueDB.lines(blocked_dialogue) if blocked_dialogue != &"" else []
	if lines.is_empty():
		lines = [{"text": BLOCKED_LINE}]
	await Dialogue.run(lines)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size * TILE), Color(0.2, 0.5, 0.85, 0.4))
		draw_string(ThemeDB.fallback_font, Vector2(4, 14), "Crue", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
