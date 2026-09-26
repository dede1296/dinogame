@tool
class_name Pickup
extends Prop
## Something to pick up (amber fragment, journal page…): glows softly, then shows its
## lines (which set the story flags) and disappears for good.

const ITEM_SFX := preload("res://assets/audio/sfx/item.wav")

## Story flag meaning "already picked up".
@export var taken_flag: StringName
@export var dialogue_id: StringName

var _glow: PointLight2D


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	if taken_flag != &"" and Game.flag(taken_flag):
		queue_free()
		return
	add_to_group(&"interactable")
	_add_glow()


func _add_glow() -> void:
	_glow = PointLight2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.75, 0.3, 1))
	g.set_color(1, Color(1, 0.6, 0.2, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	_glow.texture = tex
	_glow.energy = 0.9
	_glow.position = Vector2(0, -16)
	add_child(_glow)
	var t := create_tween().set_loops()
	t.tween_property(_glow, "energy", 0.35, 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(_glow, "energy", 0.9, 1.1).set_trans(Tween.TRANS_SINE)


func interact(player: Player) -> void:
	player.face_towards(global_position)
	Audio.play_sfx(ITEM_SFX)
	remove_from_group(&"interactable")
	var t := create_tween().set_parallel(true)
	t.tween_property(sprite, "position:y", sprite.position.y - 26.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.3)
	await Dialogue.run(DialogueDB.lines(dialogue_id))
	if taken_flag != &"":
		Game.set_flag(taken_flag)
	Save.save_game()
	queue_free()
