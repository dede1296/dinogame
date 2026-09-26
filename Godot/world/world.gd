extends Node2D
## The exploration screen: loads the current region, places Chloé and her dino, sets the
## camera, music and ambience, and handles what regions report (encounters…).

const REGIONS := {
	&"plaines_sud": "res://regions/plaines/plaines_sud.tscn",
}
const PLAYER := preload("res://actors/player.tscn")
const COMPANION := preload("res://actors/companion.tscn")
const DETAIL_INTERVAL := Vector2(7.0, 18.0)   # seconds between ambience details (birds…)
const BATTLE := preload("res://battle/battle_scene.gd")
## Tall grass: chance of a wild dino per step, and calm steps after a battle.
## Phaser uses 3 % per 48 px tile; Chloé's steps here are 38 px.
const ENCOUNTER_RATE := 0.03
const CALM_STEPS := 6
## [species, min level, max level] met in the tall grass (the slice has one species).
const ENCOUNTERS := [[&"protoceratops", 2, 4]]

var region: Region
var player: Player
var companion: Companion

@onready var region_holder: Node2D = $RegionHolder
@onready var clouds: ColorRect = $CloudShadows
@onready var banner: Label = $Hud/Banner

var _detail_timer := 3.0
var _steps_since_battle := 0


func _ready() -> void:
	(clouds.material as ShaderMaterial).set_shader_parameter("noise_tex", WorldNoise.texture())
	if Game.party.is_empty():   # scene launched on its own (F6 in the editor)
		Game.new_game()
	_load_region(Game.region_id)
	_add_pollen(player.get_node("Camera"))
	Save.enabled = true
	Save.before_save = _store_position


func _exit_tree() -> void:
	Save.enabled = false


func _load_region(id: StringName) -> void:
	if not REGIONS.has(id):
		push_error("Région inconnue : %s — retour au départ" % id)
		id = Game.START_REGION
		Game.has_position = false
	region = load(REGIONS[id]).instantiate()
	region_holder.add_child(region)

	player = PLAYER.instantiate()
	region.entities.add_child(player)
	var pos := Game.player_position if Game.has_position and Game.region_id == id else region.spawn_point()
	player.teleport(pos)
	player.surface_at = region.surface_at
	player.stepped.connect(_on_player_stepped)
	Game.region_id = id

	companion = COMPANION.instantiate()
	companion.player = player
	region.entities.add_child(companion)
	companion.teleport(pos + Vector2(-34, 8))

	var bounds := region.bounds()
	(player.get_node("Camera") as Camera2D).call(&"fit_to", bounds)
	clouds.position = bounds.position - Vector2(200, 200)
	clouds.size = bounds.size + Vector2(400, 400)

	for node in region.entities.get_children():
		if node is WildDino:
			node.encountered.connect(_on_encountered)

	Audio.play_music(region.music)
	Audio.play_ambience(region.ambience, 2.5)
	_show_banner(region.display_name)


func _store_position() -> void:
	if player:
		Game.player_position = player.global_position
		Game.has_position = true


func _process(delta: float) -> void:
	_detail_timer -= delta
	if _detail_timer <= 0.0 and region and not region.ambience_details.is_empty():
		_detail_timer = randf_range(DETAIL_INTERVAL.x, DETAIL_INTERVAL.y)
		Audio.play_sfx(region.ambience_details.pick_random(), -14.0, 0.06)


## Motes of pollen drifting in the sunlight around the camera (in world space, so they
## stay put when the camera moves).
func _add_pollen(camera: Node2D) -> void:
	var p := CPUParticles2D.new()
	p.amount = 36
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(760, 440)
	p.direction = Vector2(1, -0.3)
	p.spread = 60.0
	p.gravity = Vector2(4, -3)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 14.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.z_index = 90
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 0.95, 0.7, 0))
	fade.add_point(0.2, Color(1, 0.95, 0.7, 0.75))
	fade.add_point(0.8, Color(1, 0.95, 0.7, 0.75))
	fade.set_color(fade.get_point_count() - 1, Color(1, 0.95, 0.7, 0))
	p.color_ramp = fade
	camera.add_child(p)


func _show_banner(text: String) -> void:
	banner.text = text
	banner.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.6).set_delay(0.4)
	t.tween_interval(2.2)
	t.tween_property(banner, "modulate:a", 0.0, 0.8)


## A wild dino touched Chloé.
func _on_encountered(wild: WildDino) -> void:
	wild.cry(&"neutre")
	var level := randi_range(wild.level_range.x, wild.level_range.y)
	var result := await _battle(Dino.create(wild.species.id, level))
	if not is_instance_valid(wild):
		return
	if result in ["win", "catch"]:
		wild.queue_free()   # back next time the region is loaded
	else:
		wild.calm_down(5.0)


## A step in the tall grass may start a battle (Phaser rate); a few calm steps after one.
func _on_player_stepped(surface: StringName) -> void:
	_steps_since_battle += 1
	# Resting while walking: the party slowly gets its strength back.
	for d in Game.party:
		d.hp = mini(d.max_hp(), d.hp + 1)
	if surface != &"tall_grass" or _steps_since_battle < CALM_STEPS or player.busy:
		return
	if randf() < ENCOUNTER_RATE:
		var row: Array = ENCOUNTERS.pick_random()
		_battle(Dino.create(row[0], randi_range(row[1], row[2])))


## Plays a wild battle over the paused world, then applies its outcome.
func _battle(wild: Dino) -> String:
	player.busy = true
	player.velocity = Vector2.ZERO
	await Router.battle_flash()
	get_tree().paused = true
	var battle: CanvasLayer = BATTLE.new()
	add_child(battle)
	Router.end_transition(0.25)
	var result: String = await battle.run(wild)
	battle.queue_free()
	get_tree().paused = false
	Audio.pop_music()
	Audio.fade_ambience(BATTLE.AMBIENCE_DB, 1.5)
	_steps_since_battle = 0
	match result:
		"catch":
			var in_party := Game.add_caught(wild)
			wild.heal()
			await Dialogue.run([{"text": "%s rejoint ton équipe !" % wild.nickname if in_party else "%s est envoyé au Cabinet." % wild.nickname}])
		"lose":
			Game.heal_party()
			player.teleport(region.spawn_point())
			companion.teleport(player.global_position + Vector2(-34, 8))
			await Dialogue.run([{"text": "Chloé ramène son équipe épuisée à l'entrée des Plaines. Après un peu de repos, tout le monde va mieux."}])
	Save.save_game()
	player.busy = false
	return result
