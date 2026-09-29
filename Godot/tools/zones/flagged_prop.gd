@tool
class_name FlaggedProp
extends Prop
## A static Prop shown or hidden by a story flag, checked once at `_ready()` (the zone's scene
## is re-instanced each time it is entered, so this re-reads the flag every visit): same idea as
## StoryProp's `hide_flag` and Pickup's `show_flag`, combined, for a piece of scenery with no
## event of its own (the Cabinet's lantern/empty hook: tools/zones/cabinet.gd).

## Only there once this story flag is set (absent so long as it is false).
@export var show_flag: StringName
## Gone once this story flag is set.
@export var hide_flag: StringName


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	if show_flag != &"" and not Game.flag(show_flag):
		queue_free()
		return
	if hide_flag != &"" and Game.flag(hide_flag):
		queue_free()
