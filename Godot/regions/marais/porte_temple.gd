@tool
extends StoryProp
## The sunken temple's door, on its island in the Marais (tools/zones/marais.gd): a StoryProp
## gone once `hide_flag` (temple_ouvert) is set. The Voix du Marais sings it open from her own
## island, far from here: the flag may be set while the zone is shown, so the door does not wait
## for the zone to be loaded again: it glows, fades and lets Chloé through at once.

const OPEN_SFX := preload("res://assets/audio/sfx/rock_heavy.wav")


func _ready() -> void:
	super()
	if Engine.is_editor_hint() or is_queued_for_deletion():
		return
	Game.flag_changed.connect(_on_flag_changed)


func _on_flag_changed(id: StringName, _value: Variant) -> void:
	if id == hide_flag and hide_flag != &"" and Game.flag(hide_flag) and not is_queued_for_deletion():
		_open()


func _open() -> void:
	_shape.set_deferred(&"disabled", true)
	remove_from_group(&"interactable")
	if is_inside_tree() and get_viewport().get_camera_2d() and global_position.distance_to(get_viewport().get_camera_2d().global_position) < 900.0:
		Audio.play_sfx(OPEN_SFX, -6.0, 0.05)
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1.8, 1.5, 0.9), 0.5)
	t.tween_property(self, "modulate:a", 0.0, 0.9)
	t.tween_callback(queue_free)
