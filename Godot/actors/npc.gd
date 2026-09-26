class_name Npc
extends StaticBody2D
## A character Chloé can talk to. Its lines come from DialogueDB (by `dialogue_id`),
## which picks them according to the story flags.

@export var display_name := ""
@export var sheet: Texture2D
@export var dialogue_id: StringName
@export_enum("down", "left", "right", "up") var facing := "down"

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group(&"interactable")
	Shadow.make(self, 44.0)
	sprite.sprite_frames = SheetFrames.character(sheet)
	sprite.play(StringName("idle_" + facing))


func interact(player: Player) -> void:
	var to_player := player.global_position - global_position
	sprite.play(StringName("idle_" + SheetFrames.direction_name(to_player)))
	player.face_towards(global_position)
	await Dialogue.run(DialogueDB.lines(dialogue_id))
	sprite.play(StringName("idle_" + facing))
