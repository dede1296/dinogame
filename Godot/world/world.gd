extends Node2D
## The exploration screen: runs the current zone in 2D (Chloé, her lead dino, collisions,
## exits, encounters, saves) and shows it in 2.5D through a WorldView; sets the music and
## ambience, spawns the dinos of the zone's habitats, handles what the zone reports.
## The 2D nodes are not drawn; the 2D camera still follows Chloé for positional sounds.

const ZONES := {
	&"port_ambre": "res://regions/port/port_ambre.tscn",
	&"cabinet": "res://regions/port/cabinet.tscn",
	&"plaines": "res://regions/plaines/plaines.tscn",
	&"grotte_echos": "res://regions/plaines/grotte_echos.tscn",
	&"antre_crane": "res://regions/plaines/antre_crane.tscn",
	&"havre_dore": "res://regions/havre/havre_dore.tscn",
}
const PLAYER := preload("res://actors/player.tscn")
const COMPANION := preload("res://actors/companion.tscn")
## The sea is heard from this far (tiles), louder as Chloé comes closer; a fire, from this far.
const SEA_HEAR_TILES := 16.0
const FIRE_HEAR_TILES := 7.0
const BATTLE := preload("res://battle/battle_scene.gd")
## Tall grass: chance of a hidden dino per step (Chloé's steps are 38 px), and calm steps
## after a battle. When the lead dino is far above the zone, weak dinos keep away.
const ENCOUNTER_RATE := 0.03
const CALM_STEPS := 6
const OUTLEVELED_BY := 5
const OUTLEVELED_RATE := 0.25
## Experience for the whole party when a species is met for the first time.
const XP_NEW_SPECIES := 10
const COMPANION_OFFSET := Vector2(-34, 8)
const MOUNT_SFX := preload("res://assets/audio/sfx/latch.wav")   # the saddle buckled
const ZONE_FADE := 0.3
const RAIN_SOUND := preload("res://assets/audio/ambience/pluie.mp3")
const RAIN_DB := -7.0   # a light rain, under the zone's ambience
const STORM_SOUND := preload("res://assets/audio/ambience/orage.mp3")
const STORM_DB := -4.0
## The map: Chloé sees this far around her (tiles), checked this often (s).
const EXPLORE_RADIUS := 11.0
const EXPLORE_EVERY := 0.25
var region: Region
var player: Player
var companion: Companion

@onready var region_holder: Node2D = $RegionHolder
@onready var hud: CanvasLayer = $Hud

## Per tile of the zone: distance (tiles) to the nearest sea water (see _find_sea).
var _sea_distance := PackedFloat32Array()
var _steps_since_battle := 0
var _changing_zone := false
var _view: WorldView
var _banner: ZoneBanner
var _map_button: Button
var _ride_button: RideButton
var _tracker: QuestTracker
var _explore_timer := 0.0


func _ready() -> void:
	# Only the 3D view is drawn; the 2D world keeps playing underneath.
	region_holder.visible = false
	$CloudShadows.visible = false
	_view = WorldView.new()
	add_child(_view)
	$Hud/Banner.queue_free()
	_banner = ZoneBanner.new()
	hud.add_child(_banner)
	if not Game.in_game:   # scene launched on its own (F6 in the editor)
		Game.new_game()
		Game.give_starter(&"velociraptor")
		Game.set_flag(&"prologue_done")
	player = PLAYER.instantiate()
	player.stepped.connect(_on_player_stepped)
	companion = COMPANION.instantiate()
	companion.player = player
	var id := Game.region_id
	var pos := Game.player_position if Game.has_position else Vector2.INF
	_enter_zone(id, Game.arrival if Game.arrival != &"" else &"Depart", pos)
	Game.arrival = &""
	_view.camera.touch_controls = $TouchControls
	Game.phase_changed.connect(_on_phase_changed)
	Game.weather_changed.connect(func(_w: StringName) -> void: _weather_sound())
	_weather_sound()
	SettingsMenu.add_open_button(hud)
	_map_button = MapScreen.add_open_button(hud, _open_map)
	_ride_button = RideButton.add(hud, toggle_ride)
	hud.add_child(PartyBar.new())
	hud.add_child(ClockBadge.new())
	hud.add_child(PurseBadge.new())
	_tracker = QuestTracker.new()
	_tracker.player = player
	_tracker.zone = region.region_id
	hud.add_child(_tracker)
	Save.enabled = true
	Save.before_save = _store_position


func _exit_tree() -> void:
	Save.enabled = false
	Audio.play_weather(null, 0.8)


# ------------------------------------------------------------------ zones

## Shows zone `id` with Chloé at `pos` (Vector2.INF: at the `spawn` marker).
func _enter_zone(id: StringName, spawn: StringName, pos := Vector2.INF) -> void:
	if not ZONES.has(id):
		push_error("Zone inconnue : %s — retour au départ" % id)
		id = Game.START_REGION
		pos = Vector2.INF
	var previous := region
	if previous:
		for actor in [player, companion]:
			actor.get_parent().remove_child(actor)
		region_holder.remove_child(previous)
		previous.queue_free()
	region = load(ZONES[id]).instantiate()
	region_holder.add_child(region)
	Game.region_id = id
	Game.zone_level = roundi((region.levels.x + region.levels.y) / 2.0)
	Game.climate = {"rain": region.rain_chance, "mist": region.mist_chance, "storm": region.storm_chance}

	if region.indoor:   # no riding under a roof
		dismount()
	if pos == Vector2.INF:
		pos = region.spawn_point(spawn)
	region.entities.add_child(player)
	region.entities.add_child(companion)
	player.surface_at = region.surface_at
	player.teleport(pos)
	companion.teleport(pos + COMPANION_OFFSET)

	(player.get_node("Camera") as Camera2D).call(&"fit_to", region.bounds())

	for node in region.entities.get_children():
		if node is WildDino:
			node.encountered.connect(_on_encountered)
	for exit in region.exits():
		exit.taken.connect(_on_exit_taken)
	_spawn_roamers()
	_view.show_zone(region, player, ZONES)
	if _tracker:
		_tracker.zone = id
	_explore()
	# The story may have something to play here (the prologue…).
	Story.on_zone_entered.call_deferred(id)

	Audio.play_music(region.music)
	_find_sea()
	Audio.play_ambience(region.ambience_id)
	_show_banner(region.zone_name if region.zone_name != "" else region.display_name,
		region.display_name if region.zone_name != "" else "")


func _on_exit_taken(exit: ZoneExit) -> void:
	if player.busy or _changing_zone:
		return
	if not exit.is_open():
		player.busy = true
		player.velocity = Vector2.ZERO
		# Step back out of the exit, towards the middle of the zone.
		var back := (region.bounds().get_center() - player.global_position).normalized() * 40.0
		player.teleport(player.global_position + back)
		await Dialogue.run(DialogueDB.lines(exit.blocked_dialogue))
		player.busy = false
		return
	goto_zone(exit.target_zone, exit.target_spawn)


## Goes to another zone with a fade (an exit, or the debug panel).
func goto_zone(id: StringName, spawn: StringName = &"Depart") -> void:
	if _changing_zone or not ZONES.has(id):
		return
	_changing_zone = true
	player.busy = true
	await Router.fade_out(ZONE_FADE)
	_enter_zone(id, spawn)
	Save.save_game()
	await Router.fade_in(ZONE_FADE)
	player.busy = false
	_changing_zone = false


## The habitats' roaming dinos for the current part of the day.
func _spawn_roamers() -> void:
	if region == null:
		return
	var phase := Game.phase()
	for h in region.habitats():
		for w in h.spawn_roamers(phase, region.entities, _can_stand):
			w.encountered.connect(_on_encountered)


## Free ground for a dino: grass or path, nothing solid there, away from Chloé.
func _can_stand(p: Vector2) -> bool:
	if region.surface_at(p) == &"water" or p.distance_to(player.global_position) < 200.0:
		return false
	var query := PhysicsPointQueryParameters2D.new()
	query.position = p
	query.collision_mask = 1
	return get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()


func _weather_sound() -> void:
	match Game.weather:
		&"rain":
			Audio.play_weather(RAIN_SOUND, 3.0, RAIN_DB)
		&"storm":
			Audio.play_weather(STORM_SOUND, 3.0, STORM_DB)
		_:
			Audio.play_weather(null, 3.0)


func _store_position() -> void:
	if player:
		Game.player_position = player.global_position
		Game.has_position = true


# ------------------------------------------------------------------ ambience

func _process(delta: float) -> void:
	_ride_button.show_state(Game.flag(&"selle") and region != null and not region.indoor, player.mount != null)
	_explore_timer -= delta
	if _explore_timer <= 0.0:
		_explore_timer = EXPLORE_EVERY
		_explore()
		_hear_surroundings()


## The sea and the fires sound louder as Chloé comes near them.
func _hear_surroundings() -> void:
	if region == null:
		return
	var tile := Vector2i(player.global_position / region.tile_size())
	var size := region.map_size()
	var sea := 0.0
	if not _sea_distance.is_empty():
		var c := tile.clamp(Vector2i.ZERO, size - Vector2i.ONE)
		sea = clampf(1.0 - _sea_distance[c.y * size.x + c.x] / SEA_HEAR_TILES, 0.0, 1.0)
	var fire := 0.0
	for f in get_tree().get_nodes_in_group(&"fire"):
		var d := (f as Node2D).global_position.distance_to(player.global_position) / region.tile_size().x
		fire = maxf(fire, clampf(1.0 - d / FIRE_HEAR_TILES, 0.0, 1.0))
	Audio.ambience.set_mix("sea", sea)
	Audio.ambience.set_mix("fire", fire)


## The sea: the water touching the edge of the zone, and all the water joined to it (a pond
## is not the sea). Stores each tile's distance to it, for _hear_surroundings.
func _find_sea() -> void:
	_sea_distance = PackedFloat32Array()
	if region.indoor:
		return
	var size := region.map_size()
	var t := region.tile_size()
	var is_water := func(c: Vector2i) -> bool: return region.surface_at((Vector2(c) + Vector2(0.5, 0.5)) * t) == &"water"
	var sea := {}
	var queue: Array[Vector2i] = []
	for x in size.x:
		for y in [0, size.y - 1]:
			queue.append(Vector2i(x, y))
	for y in size.y:
		for x in [0, size.x - 1]:
			queue.append(Vector2i(x, y))
	queue = queue.filter(func(c: Vector2i) -> bool: return is_water.call(c))
	for c in queue:
		sea[c] = true
	var i := 0
	while i < queue.size():
		var c := queue[i]
		i += 1
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := c + d
			if n.x >= 0 and n.y >= 0 and n.x < size.x and n.y < size.y and not sea.has(n) and is_water.call(n):
				sea[n] = true
				queue.append(n)
	if sea.is_empty():
		return
	# Distance to it, spreading out from its tiles (in tiles, by steps).
	_sea_distance.resize(size.x * size.y)
	_sea_distance.fill(INF)
	var front: Array[Vector2i] = []
	for c: Vector2i in sea:
		_sea_distance[c.y * size.x + c.x] = 0.0
		front.append(c)
	i = 0
	while i < front.size():
		var c := front[i]
		i += 1
		var here := _sea_distance[c.y * size.x + c.x]
		if here >= SEA_HEAR_TILES:
			continue
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := c + d
			if n.x >= 0 and n.y >= 0 and n.x < size.x and n.y < size.y and _sea_distance[n.y * size.x + n.x] > here + 1.0:
				_sea_distance[n.y * size.x + n.x] = here + 1.0
				front.append(n)


## What Chloé sees around her appears on the map.
func _explore() -> void:
	if region and not region.indoor:
		Game.explore(Game.region_id, region.map_size(), player.global_position / region.tile_size(), EXPLORE_RADIUS)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"map"):
		get_viewport().set_input_as_handled()
		_open_map()
	elif event.is_action_pressed(&"ride"):
		get_viewport().set_input_as_handled()
		toggle_ride()


# ------------------------------------------------------------------ riding

## Chloé climbs on the dino of her party able to carry her (Monture), or gets down.
func toggle_ride() -> void:
	if player.busy or _changing_zone or get_tree().paused or not Game.flag(&"selle") or region.indoor:
		return
	if player.mount:
		dismount()
		return
	var steed := Game.ability_user(&"monture")
	if steed == null:
		Toast.say(get_tree(), _no_mount_reason())
		return
	player.mount = steed
	companion.refresh()
	companion.cry(&"neutre")
	Audio.play_sfx(MOUNT_SFX, -4.0, 0.05)


## Chloé gets down; her dino walks behind her again.
func dismount() -> void:
	if player == null or player.mount == null:
		return
	player.mount = null
	companion.refresh()
	companion.teleport(player.global_position + COMPANION_OFFSET)
	player.trail = [player.global_position]


## Why nobody can carry her: too young, or no dino of the kind.
func _no_mount_reason() -> String:
	for d in Game.party:
		if Abilities.has(d, &"monture"):
			return "%s est encore trop jeune pour te porter : il faut qu'il soit adulte (niv. %d)." % [d.nickname, Abilities.ADULT_LEVEL]
	return "Aucun dino de ton équipe n'est assez grand pour te porter. Un Parasaurolophus ou un Ankylosaurus adulte, peut-être ?"


func _open_map() -> void:
	if player.busy or _changing_zone or get_tree().paused:
		return
	# Indoors (a cave, the Cabinet): no detailed map, the island opens.
	var layers := {} if region.indoor else _view.map_layers()
	MapScreen.open(self, region, layers, player.global_position / region.tile_size(), ZONES)


func _show_banner(title: String, subtitle := "") -> void:
	_banner.show_zone(title, subtitle)


# ------------------------------------------------------------------ encounters

## A wild dino touched Chloé.
func _on_encountered(wild: WildDino) -> void:
	wild.cry(&"neutre")
	var level := randi_range(wild.level_range.x, wild.level_range.y)
	var result := await _battle(Dino.create(wild.species.id, level))
	if not is_instance_valid(wild):
		return
	if result in ["win", "catch"]:
		wild.queue_free()   # back next time the zone is loaded
	else:
		wild.calm_down(5.0)


## An egg carried along hatches after its last step (PlainesAnnexes.hatch).
func _carry_egg() -> void:
	if Game.egg.is_empty() or player.busy or _changing_zone:
		return
	Game.egg["steps"] = int(Game.egg.get("steps", 0)) - 1
	if Game.egg["steps"] == PlainesAnnexes.EGG_STIRS:
		Toast.say(get_tree(), "L'œuf de %s remue contre toi…" % Game.egg.get("name", "?"))
	elif Game.egg["steps"] <= 0:
		PlainesAnnexes.hatch()


## New dinos for the new part of the day; the full moon is announced when it rises.
func _on_phase_changed(phase: StringName) -> void:
	_spawn_roamers()
	Story.on_phase_changed.call_deferred(region.region_id if region else &"")
	if phase == &"night" and Game.is_full_moon() and region and not region.indoor:
		Toast.say(get_tree(), "La lune est pleine ce soir. L'ambre de l'île s'éveille…")


## A step in the tall grass may start a battle with a dino of the habitat there.
func _on_player_stepped(surface: StringName) -> void:
	_steps_since_battle += 1
	_carry_egg()
	# Resting while walking: the party slowly gets its strength back.
	for d in Game.party:
		d.hp = mini(d.max_hp(), d.hp + 1)
	# In the saddle, the little dinos hidden in the tall grass flee from the big one's steps.
	if surface != &"tall_grass" or _steps_since_battle < CALM_STEPS or player.busy or _changing_zone or player.mount:
		return
	var habitat := region.habitat_at(player.global_position)
	if habitat == null:
		return
	var rate := ENCOUNTER_RATE
	var lead := Game.lead_dino()
	if lead and lead.level >= region.levels.y + OUTLEVELED_BY:
		rate *= OUTLEVELED_RATE
	if randf() >= rate:
		return
	var e := habitat.pick_hidden(Game.phase())
	if e:
		_battle(Dino.create(e.species, e.roll_level()))


## Plays a wild battle over the paused world, then applies its outcome.
## `rules`: see BattleScene.run (an Alpha: no collar, no running away).
func _battle(wild: Dino, rules := {}) -> String:
	dismount()
	if region and region.cave and not rules.has("cave"):
		rules = rules.merged({"cave": true})
	player.busy = true
	player.velocity = Vector2.ZERO
	var first_sighting := not Game.dex_seen.has(String(wild.species().id))
	await Router.battle_flash()
	get_tree().paused = true
	var battle: CanvasLayer = BATTLE.new()
	add_child(battle)
	Router.end_transition(0.25)
	var result: String = await battle.run(wild, rules)
	battle.queue_free()
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
			player.teleport(region.spawn_point(rules.get("lose_spawn", &"Depart")))
			companion.teleport(player.global_position + COMPANION_OFFSET)
			await Dialogue.run([{"text": "Chloé ramène son équipe épuisée à l'entrée de la zone. Après un peu de repos, tout le monde va mieux."}])
	# Discovering a species teaches the whole party something.
	if first_sighting and result != "lose":
		Game.award_team_xp(XP_NEW_SPECIES)
	Save.save_game()
	player.busy = false
	return result
