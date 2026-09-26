@tool
class_name StoryProp
extends Prop
## A piece of scenery that starts a story scene when Chloé interacts with it (the Grand
## Crâne and its locks…): `event` is played by Story.run.

@export var event: StringName
## Gone once this story flag is set (a door that has been opened).
@export var hide_flag: StringName


func _ready() -> void:
	super()
	if not Engine.is_editor_hint() and hide_flag != &"" and Game.flag(hide_flag):
		queue_free()
		return
	if not Engine.is_editor_hint() and event != &"":
		add_to_group(&"interactable")
		set_meta(&"reach_bonus", 40.0)


func interact(player: Player) -> void:
	player.face_towards(global_position)
	await preload("res://story/story.gd").run(event, self)
