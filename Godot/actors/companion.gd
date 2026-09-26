class_name Companion
extends Node2D
## The lead dino of the party, walking in Chloé's footsteps (it follows her trail, so it
## goes around obstacles the way she did). Looks like the party's lead dino.

const FOLLOW_GAP := 8        # trail points behind Chloé (~48 px)
const CATCH_UP := 7.0        # how fast it closes the gap
const IDLE_CRY_CHANCE := 0.12

var player: Player
var dino: Dino

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var cry_player: AudioStreamPlayer2D = $Cry

var _idle_time := 0.0
var _idle_anim: StringName = &"idle"
var _shadow: Sprite2D


func _ready() -> void:
	add_to_group(&"companion")
	_shadow = Shadow.make(self)
	Game.party_changed.connect(refresh)
	refresh()


func refresh() -> void:
	dino = Game.lead_dino()
	visible = dino != null
	if dino == null:
		return
	var species := dino.species()
	sprite.sprite_frames = SheetFrames.dino(species)
	sprite.scale = Vector2.ONE * species.world_scale
	var h := species.sheet.get_height() / float(species.sheet_rows)
	sprite.offset = Vector2(0, -h * 0.46)
	Shadow.fit(_shadow, species.sheet.get_width() / float(species.sheet_columns) * species.world_scale * 0.55)
	sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	if player == null or dino == null:
		return
	var trail := player.trail
	var target := trail[maxi(0, trail.size() - 1 - FOLLOW_GAP)]
	var before := global_position
	global_position = global_position.lerp(target, 1.0 - exp(-CATCH_UP * delta))
	var step := global_position - before
	if step.length() > 0.4:
		if absf(step.x) > 0.2:
			sprite.flip_h = step.x < 0.0
		var anims: Array = SheetFrames.dino_anims(sprite.sprite_frames, step)
		_idle_anim = anims[1]
		sprite.play(anims[0])
		sprite.speed_scale = clampf(step.length() / (delta * 120.0), 0.6, 1.5)
		_idle_time = 0.0
	else:
		sprite.play(_idle_anim)
		sprite.speed_scale = 1.0
		_idle_time += delta
		if _idle_time > 5.0:
			_idle_time = 0.0
			if randf() < IDLE_CRY_CHANCE:
				cry(&"neutre")


func teleport(pos: Vector2) -> void:
	global_position = pos
	reset_physics_interpolation()


func cry(kind: StringName) -> void:
	var stream := dino.species().cry(kind)
	if stream:
		cry_player.stream = stream
		cry_player.pitch_scale = randf_range(1.05, 1.18)   # a young dino: slightly higher
		cry_player.play()


## Short "action" pose (using an ability): lunge towards `point` and back.
func perform_at(point: Vector2) -> void:
	sprite.flip_h = point.x < global_position.x
	sprite.play(&"attack")
	cry(&"attaque")
	var home := global_position
	var t := create_tween()
	t.tween_property(self, "global_position", home.lerp(point, 0.6), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(self, "global_position", home, 0.3).set_trans(Tween.TRANS_SINE)
	await t.finished
	sprite.play(&"idle")
