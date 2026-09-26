class_name WildDino
extends CharacterBody2D
## A wild dino roaming around its home spot: walks, stops to graze, cries now and then.
## Touching Chloé starts an encounter (the world decides what happens).

signal encountered(wild: WildDino)

@export var species_id: StringName = &"protoceratops"
@export var level_range := Vector2i(2, 4)
@export var roam_radius := 120.0
@export var speed := 48.0

var species: DinoSpecies
var home := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var cry_player: AudioStreamPlayer2D = $Cry
@onready var touch: Area2D = $Touch

var _target := Vector2.ZERO
var _wait := 0.0
var _cry_timer := 0.0
var _calm := 0.0   # seconds before it can trigger an encounter again
var _idle_anim: StringName = &"idle"


func _ready() -> void:
	species = SpeciesDB.get_species(species_id)
	sprite.sprite_frames = SheetFrames.dino(species)
	sprite.scale = Vector2.ONE * species.world_scale
	var h := species.sheet.get_height() / float(species.sheet_rows)
	sprite.offset = Vector2(0, -h * 0.46)
	Shadow.make(self, species.sheet.get_width() / float(species.sheet_columns) * species.world_scale * 0.55)
	sprite.play(&"idle")
	home = global_position
	_target = home
	_wait = randf_range(0.5, 3.0)
	_cry_timer = randf_range(6.0, 16.0)
	touch.body_entered.connect(_on_touch)


func _physics_process(delta: float) -> void:
	_calm = maxf(0.0, _calm - delta)
	_cry_timer -= delta
	if _cry_timer <= 0.0:
		_cry_timer = randf_range(10.0, 22.0)
		cry(&"neutre")
	if _wait > 0.0:
		_wait -= delta
		velocity = Vector2.ZERO
		if _wait <= 0.0:
			_target = home + Vector2.from_angle(randf() * TAU) * randf_range(20.0, roam_radius)
		return
	var to := _target - global_position
	# Arrived, or stuck against an obstacle for a moment.
	if to.length() < 6.0 or (get_slide_collision_count() > 0 and randf() < 0.03):
		_rest()
		return
	velocity = to.normalized() * speed
	move_and_slide()
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	var anims: Array = SheetFrames.dino_anims(sprite.sprite_frames, velocity)
	_idle_anim = anims[1]
	sprite.play(anims[0])


func _rest() -> void:
	velocity = Vector2.ZERO
	_wait = randf_range(1.5, 5.0)
	sprite.play(_idle_anim)


func cry(kind: StringName) -> void:
	var stream := species.cry(kind)
	if stream:
		cry_player.stream = stream
		cry_player.pitch_scale = randf_range(0.95, 1.05)
		cry_player.play()


func calm_down(seconds := 4.0) -> void:
	_calm = seconds


func _on_touch(body: Node2D) -> void:
	if body is Player and _calm <= 0.0 and not Dialogue.active:
		_calm = 999.0
		encountered.emit(self)
