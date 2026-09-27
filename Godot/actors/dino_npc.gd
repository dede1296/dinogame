class_name DinoNpc
extends StaticBody2D
## A dino standing in a scene (the hatchlings of the Cabinet, a dino belonging to someone):
## no battle, it just looks around and cries; talking to it runs `event` (Story.run).

@export var species_id: StringName = &"velociraptor"
@export var event: StringName
@export var flip := false
## Only there once this flag is set / no longer there once this one is set.
@export var show_flag: StringName
@export var hide_flag: StringName
## Size relative to the species' world scale (hatchlings are smaller).
@export var size_scale := 0.8
## Raised above the ground (px), e.g. standing on a pedestal.
@export var lift := 0.0
## Maddened by black amber: its corrupted look and a violet glow (see cleanse).
@export var corrupted := false

const CORRUPTED_GLOW := Color(0.62, 0.3, 1.0)

var sprite: AnimatedSprite2D
var species: DinoSpecies
var _cry: AudioStreamPlayer2D


func _ready() -> void:
	if (show_flag != &"" and not Game.flag(show_flag)) or (hide_flag != &"" and Game.flag(hide_flag)):
		queue_free()
		return
	species = SpeciesDB.get_species(species_id)
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	add_child(shape)
	Shadow.make(self, species.sheet.get_width() / float(species.sheet_columns) * species.world_scale * size_scale * 0.55)
	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = SheetFrames.dino(species, corrupted)
	sprite.scale = Vector2.ONE * species.world_scale * size_scale
	sprite.offset = Vector2(0, -species.sheet.get_height() / float(species.sheet_rows) * 0.46)
	sprite.position.y = -lift
	sprite.flip_h = flip
	sprite.play(&"idle")
	add_child(sprite)
	_cry = AudioStreamPlayer2D.new()
	_cry.bus = &"SFX"
	add_child(_cry)
	if event != &"":
		add_to_group(&"interactable")
	if corrupted:
		var glow := PointLight2D.new()
		glow.name = "Glow"
		glow.color = CORRUPTED_GLOW
		glow.energy = 0.9
		var g := Gradient.new()
		g.set_color(0, Color(CORRUPTED_GLOW, 1.0))
		g.set_color(1, Color(CORRUPTED_GLOW, 0.0))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		glow.texture = tex
		glow.visible = Quality.setting(&"lights")
		add_child(glow)


## The black amber lets go of it (calmed, Apaiser): its own colours come back (a white flash), the glow goes.
func cleanse() -> void:
	corrupted = false
	var glow := get_node_or_null("Glow")
	if glow:
		glow.queue_free()
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(3, 3, 3), 0.25)
	t.tween_callback(func() -> void:
		sprite.sprite_frames = SheetFrames.dino(species)
		sprite.play(&"idle"))
	t.tween_property(sprite, "modulate", Color.WHITE, 0.6)
	await t.finished


func cry(kind: StringName = &"neutre") -> void:
	var stream := species.cry(kind)
	if stream:
		_cry.stream = stream
		# A hatchling (a small one) higher; a grown dino (an Alpha, Griffe-Grise) lower.
		_cry.pitch_scale = randf_range(1.15, 1.3) if size_scale < 0.9 else randf_range(0.82, 0.92)
		_cry.play()


func interact(player: Player) -> void:
	player.face_towards(global_position)
	cry()
	await preload("res://story/story.gd").run(event, self)


## Walks to `target` (world px), then stands still.
func walk_to(target: Vector2, speed := 120.0) -> void:
	var to := target - global_position
	if to.length() < 2.0:
		return
	collision_layer = 0
	if absf(to.x) > 1.0:
		sprite.flip_h = to.x < 0.0
	sprite.play(SheetFrames.dino_anims(sprite.sprite_frames, to)[0])
	# Hop down from the pedestal first.
	if sprite.position.y < 0.0:
		await create_tween().tween_property(sprite, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_BACK).finished
	var t := create_tween()
	t.tween_property(self, "global_position", target, to.length() / speed)
	await t.finished
	sprite.play(SheetFrames.dino_anims(sprite.sprite_frames, to)[1])
	collision_layer = 1
