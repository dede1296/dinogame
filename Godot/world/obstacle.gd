@tool
class_name Obstacle
extends Prop
## A prop blocking the way until a party dino uses the right exploration ability
## (Tranche on a trunk, Charge on a boulder). Once cleared, it stays gone (story flag).

const SFX := {
	&"tranche": preload("res://assets/audio/sfx/slice.wav"),
	&"charge": preload("res://assets/audio/sfx/rock_heavy.wav"),
}
const CHOP := preload("res://assets/audio/sfx/chop.wav")

@export var ability: StringName = &"tranche"
## Story flag set when cleared (must be unique in the game).
@export var cleared_flag: StringName
## Lines shown when no party dino can clear it.
@export var blocked_dialogue: StringName
## Particle colour of the debris.
@export var debris_color := Color(0.45, 0.32, 0.18)


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	if cleared_flag != &"" and Game.flag(cleared_flag):
		queue_free()
		return
	add_to_group(&"interactable")
	set_meta(&"reach_bonus", 30.0)


func interact(player: Player) -> void:
	player.face_towards(global_position)
	var user := Game.ability_user(ability)
	if user == null:
		await Dialogue.run(DialogueDB.lines(blocked_dialogue))
		return
	var ability_name := Abilities.display_name(ability)
	await Dialogue.run([{"text": "%s utilise %s !" % [user.nickname, ability_name]}])
	var companion := get_tree().get_first_node_in_group(&"companion") as Companion
	if companion:
		await companion.perform_at(global_position)
	await _break()
	if cleared_flag != &"":
		Game.set_flag(cleared_flag)
	Save.save_game()


func _break() -> void:
	Audio.play_sfx(SFX.get(ability, CHOP), 0.0, 0.05)
	remove_from_group(&"interactable")
	_shape.set_deferred(&"disabled", true)
	_spawn_debris()
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method(&"shake"):
		cam.shake(6.0, 0.25)
	var t := create_tween().set_parallel(true)
	t.tween_property(sprite, "scale", sprite.scale * Vector2(1.15, 0.2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	await t.finished
	await get_tree().create_timer(0.6).timeout
	queue_free()


func _spawn_debris() -> void:
	var p := CPUParticles2D.new()
	p.amount = 28
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.9
	p.direction = Vector2.UP
	p.spread = 70.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 260.0
	p.gravity = Vector2(0, 520)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.color = debris_color
	p.position = Vector2(0, -24)
	add_child(p)
	p.emitting = true
