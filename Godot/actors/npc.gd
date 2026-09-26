class_name Npc
extends StaticBody2D
## A character Chloé can talk to. Its lines come from DialogueDB (by `dialogue_id`), which
## picks them according to the story flags; or `event` runs a scene of the story instead
## (Story.run). `show_flag` / `hide_flag` place it according to the story. Scenes move it
## with walk_to().

@export var display_name := ""
@export var sheet: Texture2D
@export var dialogue_id: StringName
## A story scene run when Chloé talks to it (see story/story.gd); overrides dialogue_id.
@export var event: StringName
@export_enum("down", "left", "right", "up") var facing := "down"
## Only there once this flag is set / no longer there once this one is set.
@export var show_flag: StringName
@export var hide_flag: StringName
## Tints the sheet (a provisional character drawn with another one's sheet).
@export var tint := Color.WHITE

const WALK_SPEED := 120.0   # px/s

## Already greeted this session (the first time Chloé comes to talk: a « ! »).
var _greeted := false

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	if not Engine.is_editor_hint() and not present():
		queue_free()
		return
	add_to_group(&"interactable")
	add_to_group(&"npc")
	Shadow.make(self, 44.0)
	sprite.sprite_frames = SheetFrames.character(sheet)
	sprite.self_modulate = tint
	sprite.play(StringName("idle_" + facing))


## Should it be in the zone, given the story flags?
func present() -> bool:
	return (show_flag == &"" or Game.flag(show_flag)) and (hide_flag == &"" or not Game.flag(hide_flag))


func interact(player: Player) -> void:
	face(player.global_position)
	player.face_towards(global_position)
	if not _greeted:
		_greeted = true
		var view := get_tree().get_first_node_in_group(&"world_view") as WorldView
		if view:
			view.emote(self, "!")
	if event != &"":
		await preload("res://story/story.gd").run(event, self)
	elif dialogue_id != &"":
		await Dialogue.run(DialogueDB.lines(dialogue_id))
	else:
		await Dialogue.run([{"who": display_name, "text": "Oh, bonjour Chloé !"}])
	sprite.play(StringName("idle_" + facing))


## Turns to look at a point.
func face(point: Vector2) -> void:
	sprite.play(StringName("idle_" + SheetFrames.direction_name(point - global_position)))


## Walks to `target` (world px) in a straight line, then stands facing `end_facing`.
func walk_to(target: Vector2, end_facing := "", speed := WALK_SPEED) -> void:
	var to := target - global_position
	if to.length() < 2.0:
		return
	collision_layer = 0   # don't block Chloé on the way
	sprite.play(StringName("walk_" + SheetFrames.direction_name(to)))
	var t := create_tween()
	t.tween_property(self, "global_position", target, to.length() / speed)
	await t.finished
	collision_layer = 1
	if end_facing != "":
		facing = end_facing
	sprite.play(StringName("idle_" + (end_facing if end_facing != "" else SheetFrames.direction_name(to))))


## Walks through `points` one after another.
func walk_path(points: Array, end_facing := "", speed := WALK_SPEED) -> void:
	for i in points.size():
		await walk_to(points[i], end_facing if i == points.size() - 1 else "", speed)
