@tool
class_name Sign
extends Prop
## A prop that shows a text when Chloé interacts with it (signposts, notices…).

@export var dialogue_id: StringName


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		add_to_group(&"interactable")


func interact(player: Player) -> void:
	player.face_towards(global_position)
	await Dialogue.run(DialogueDB.lines(dialogue_id))
