class_name Interactable3D
extends Node3D
## Something Chloé can use in the 3D world (a sign, a person, a pickup…): she finds the nearest
## one in reach in front of her (Player3D.nearest_interactable) and, with the interact button,
## calls `interact`. While it is the one she would use, a hint floats above it.
## By default it reads `lines` out in the game's dialogue box (the 2.5D Dialogue, unchanged);
## something else connects `used` or overrides `interact`.

signal used(player: Node3D)

## Shown above it while it is in reach, after the key: « E : <verb> ».
@export var verb := "examiner"
## Dialogue steps, as DialogueDB gives them ({"who": …, "text": …}).
@export var lines: Array[Dictionary] = []
## Height of the hint above its origin (m).
@export var hint_height := 1.6
## Chloé can use it from this far (m); 0: her own reach (Player3D.INTERACT_REACH, as the 2.5D).
## A dino is observed from afar.
@export var reach := 0.0

var _hint: Label3D


func _ready() -> void:
	add_to_group(&"interactable3d")
	_hint = Label3D.new()
	_hint.text = "E : %s" % verb
	_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint.no_depth_test = true
	_hint.font_size = 40
	_hint.pixel_size = 0.004
	_hint.outline_size = 10
	_hint.position = Vector3(0.0, hint_height, 0.0)
	_hint.visible = false
	add_child(_hint)


## Shows or hides the hint (Player3D, as it comes in or out of reach).
func set_hinted(on: bool) -> void:
	if _hint:
		_hint.visible = on


func interact(player: Node3D) -> void:
	used.emit(player)
	if not lines.is_empty():
		await Dialogue.run(lines)
