class_name Sleeper
extends DinoNpc
## A dino fast asleep: now and then a « z » rises over its head; lying down if its sheet draws
## it so (DinoSpecies.sleep_frame). Talking to it runs `event` (a different line each time: see
## PlainesAnnexes.dormeur).

const SNORE_S := Vector2(2.5, 4.5)

var _next := 1.0


func _ready() -> void:
	super()
	if sprite and sprite.sprite_frames.has_animation(&"sleep"):
		sprite.play(&"sleep")


func _process(delta: float) -> void:
	_next -= delta
	if _next > 0.0:
		return
	_next = randf_range(SNORE_S.x, SNORE_S.y)
	var view := get_tree().get_first_node_in_group(&"world_view") as WorldView
	if view:
		view.emote(self, "z")
