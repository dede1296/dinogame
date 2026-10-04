class_name Encounters3D
extends Node
## The 2.5D's meetings with the wild dinos, played in a 3D zone (docs/migration-3d.md, phase 5) —
## the same rules, the same battle (BattleScene, over the paused world), the same outcomes, as
## world.gd (_on_encountered, _on_player_stepped, _battle, _spot_dinos):
## - walking into a wild dino starts a battle; won or caught, it is gone; else it calms down a while;
## - steps in the tall grass of a habitat may start a battle with one of its hidden dinos (fewer
##   when the lead dino is far above the zone's levels);
## - each step, the party gets a little of its strength back;
## - a species seen close by for the first time goes in the Dinodex (and the party learns a little);
## - lost: the party is healed, Chloé is back at the zone's arrival point.
## The steps are the 2.5D's (38 px = 0.8 tile), on the wider map: one per 0.8 tile, so a patch of
## tall grass gives as many chances as in the 2.5D.

const WORLD := preload("res://world/world.gd")   # its rules: ENCOUNTER_RATE, CALM_STEPS…
const STEP_TILES := 38.0 / 48.0                 # Player.STEP_DISTANCE, in tiles
const LEFT_CALM_S := 5.0                        # a dino left after a battle is not met again so soon
const SPOT_EVERY_S := 0.25                      # world.gd EXPLORE_EVERY

var zone: Zone3D
var player: Player3D
## What the last battle gave ("win", "catch", "run", "lose"…), for the tests.
var last_result := ""

var _walked := 0.0
var _last_at := Vector3.INF
var _steps_since_battle := 0
var _spot_timer := 0.0


func _ready() -> void:
	player = zone.player
	for d in zone.dinos:
		watch(d)


## A wild dino of the zone: Chloé may meet it.
func watch(dino: Dinosaur3D) -> void:
	if not dino.encountered.is_connected(_on_encountered):
		dino.encountered.connect(_on_encountered)


func _physics_process(delta: float) -> void:
	if player == null or get_tree().paused:
		return
	var at := player.global_position
	if _last_at != Vector3.INF and player.is_on_floor():
		_walked += (at - _last_at).slide(Vector3.UP).length()
	_last_at = at
	var step := STEP_TILES * zone.source.scale
	while _walked >= step:
		_walked -= step
		_stepped()
	_spot_timer -= delta
	if _spot_timer <= 0.0:
		_spot_timer = SPOT_EVERY_S
		_spot_dinos()


func _on_encountered(wild: Dinosaur3D) -> void:
	if player.busy or get_tree().paused:
		return
	wild.cry(&"neutre")
	var result := await battle(Dino.create(wild.species.id, wild.dino.level))
	if not is_instance_valid(wild):
		return
	if result in ["win", "catch"]:
		zone.dinos.erase(wild)
		wild.queue_free()   # back next time the zone is loaded
	else:
		wild.calm_down(LEFT_CALM_S)


## A step: the party rests a little; in the tall grass of a habitat, maybe a hidden dino.
func _stepped() -> void:
	_steps_since_battle += 1
	for d in Game.party:
		d.hp = mini(d.max_hp(), d.hp + 1)
	var tile := zone.source.tile_at(player.global_position.x, player.global_position.z)
	if zone.source.surface(tile) != &"tall_grass" or _steps_since_battle < WORLD.CALM_STEPS or player.busy:
		return
	var habitat := _habitat_at(player.global_position)
	if habitat.is_empty():
		return
	var rate := WORLD.ENCOUNTER_RATE
	var lead := Game.lead_dino()
	if lead and lead.level >= zone.source.region.levels.y + WORLD.OUTLEVELED_BY:
		rate *= WORLD.OUTLEVELED_RATE
	if randf() >= rate:
		return
	var e: Encounter = habitat["node"].pick_hidden(Game.phase())
	if e:
		battle(Dino.create(e.species, e.roll_level()))


func _habitat_at(at: Vector3) -> Dictionary:
	for h in zone.source.habitats():
		if (h["area"] as Rect2).has_point(Vector2(at.x, at.z)):
			return h
	return {}


## Dinos seen close by: a species new to Chloé goes in the Dinodex.
func _spot_dinos() -> void:
	var reach := WORLD.SIGHT_TILES * zone.source.scale
	for d in zone.dinos:
		if not is_instance_valid(d) or d.companion_of:
			continue
		if d.global_position.distance_to(player.global_position) > reach:
			continue
		var id := d.species.id
		if not SpeciesDB.PATHS.has(id) or not Game.mark_seen(id):
			continue
		Game.award_team_xp(WORLD.XP_NEW_SPECIES)
		if not player.busy:
			Toast.say(get_tree(), "Nouveau dans le Dinodex : %s !" % SpeciesDB.get_species(id).display_name)


## A wild battle over the paused zone, then its outcome — world.gd _battle, in 3D.
func battle(wild: Dino, rules := {}) -> String:
	var region := zone.source.region
	if region.battle_backdrop and not rules.has("backdrop"):
		rules = rules.merged({"backdrop": region.battle_backdrop})
	player.busy = true
	player.velocity = Vector3.ZERO
	var first_sighting := not Game.dex_seen.has(String(wild.species().id))
	await Router.battle_flash()
	get_tree().paused = true
	var scene: CanvasLayer = WORLD.BATTLE.new()
	add_child(scene)
	Router.end_transition(0.25)
	var result: String = await scene.run(wild, rules)
	scene.queue_free()
	get_tree().paused = false
	Audio.pop_music()
	Audio.fade_ambience(0.0, 1.5)
	_steps_since_battle = 0
	match result:
		"catch":
			var in_party := Game.add_caught(wild)
			wild.heal()
			await Dialogue.run([{"text": "%s rejoint ton équipe !" % wild.nickname if in_party else "%s est envoyé au Cabinet." % wild.nickname}])
		"lose":
			Game.heal_party()
			zone.place(rules.get("lose_spawn", zone.arrival))
			await Dialogue.run([{"text": "Chloé ramène son équipe épuisée à l'entrée de la zone. Après un peu de repos, tout le monde va mieux."}])
	if first_sighting and result != "lose":
		Game.award_team_xp(WORLD.XP_NEW_SPECIES)
	last_result = result
	if Save.enabled:
		Save.save_game()
	player.busy = false
	return result
