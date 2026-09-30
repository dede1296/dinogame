class_name Sleeper
extends DinoNpc
## A dino fast asleep: now and then a « z » rises over its head; lying down when it has a picture
## for it (DinoSpecies.sleep_sheet / sleep_frame). Without one it keeps its standing picture, but
## STILL: a sleeper never plays its waiting animation, whose two frames would keep its head
## moving. Talking to it runs `event` (a different line each time: see PlainesAnnexes.dormeur).

## Already on its feet again (the story woke it): it stands and lives like any other dino.
@export var awake_flag: StringName

const SNORE_S := Vector2(2.5, 4.5)

var _next := 1.0


func _ready() -> void:
	super()
	if sprite == null:
		return
	if awake_flag != &"" and Game.flag(awake_flag):
		set_process(false)   # up again: no lying picture, no « z »
		return
	if sprite.sprite_frames.has_animation(&"sleep"):
		sprite.play(&"sleep")
	sprite.pause()   # asleep: one picture, held (its waiting animation would wag its head)


## The story wakes it: back on its feet, moving again (no more « z »).
func wake() -> void:
	set_process(false)
	if sprite:
		sprite.play(&"idle")


func _process(delta: float) -> void:
	_next -= delta
	if _next > 0.0:
		return
	_next = randf_range(SNORE_S.x, SNORE_S.y)
	var view := get_tree().get_first_node_in_group(&"world_view") as WorldView
	if view:
		view.emote(self, "z")
