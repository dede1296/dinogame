@tool
class_name StoryProp
extends Prop
## A piece of scenery that starts a story scene when Chloé interacts with it (the Grand
## Crâne and its locks…): `event` is played by Story.run.

@export var event: StringName
## Only there once this story flag is set (Maïa's boat, once she and Chloé are a team).
@export var show_flag: StringName
## Gone once this story flag is set (a door that has been opened).
@export var hide_flag: StringName
## Another picture once this story flag is set (the turtles' nest, empty once they are gone).
@export var after_flag: StringName
@export var after_kind := ""


func _ready() -> void:
	if not Engine.is_editor_hint() and after_flag != &"" and after_kind != "" and Game.flag(after_flag):
		kind = after_kind
	super()
	if not Engine.is_editor_hint() and _absent():
		queue_free()
		return
	if not Engine.is_editor_hint() and event != &"":
		add_to_group(&"interactable")
		set_meta(&"reach_bonus", 40.0)


## Not there in this state of the story (its show_flag not set yet, or its hide_flag set).
func _absent() -> bool:
	return (show_flag != &"" and not Game.flag(show_flag)) or (hide_flag != &"" and Game.flag(hide_flag))


func interact(player: Player) -> void:
	player.face_towards(global_position)
	await preload("res://story/story.gd").run(event, self)
