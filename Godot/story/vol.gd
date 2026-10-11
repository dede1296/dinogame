class_name Vol
extends RefCounted
## Le Vol (chapter 7, Greg 11/10: « je veux un contrôle en vol »). With Joss's flying harness (item
## ITEM) and the story's leave (flag FLAG, set when the Quetzalcoatlus Roi has taught her), a great
## pterosaur of the party, grown (Abilities « vol », level 12: Pteranodon, Tapejara, Tupandactylus,
## Hatzegopteryx, Quetzalcoatlus — never the little Dimorphodon), takes Chloé up: she steers it in
## the eight directions, faster than on foot, over everything, and sets down wherever the ground
## will hold her (not on deep water, not over the void between the pitons, not on a tree or a rock).
## The action ACTION (F, the pad's X; the round harness button under the saddle's: VolButton)
## takes off and lands; while she flies, a help strip says how (VolHelp).
## The flight itself (height, the zone's edges, the wind): actors/flight.gd. Not indoors, not in a
## cave nor under the sea, not where a zone forbids it (meta NO_FLIGHT_META), not during a scene,
## not from the water. A zone marks its void with a meta of VOID_METAS (the height below which its
## ground is the void).

const ITEM := "harnais_vol"
const FLAG := &"vol_obtenu"
const ABILITY := &"vol"
const ACTION := &"fly"
## Chloé's own collision layer on foot (player.tscn): she is on none in the air.
const PLAYER_LAYER := 2
const NO_FLIGHT_META := &"vol_interdit"
## The Cieux' sea of clouds: on a zone's root, the height (m) below which a tile is the void between
## the pitons (tools/zones/cieux*.gd write « vol_vide_sous »; « void_below » is read too).
const VOID_METAS: Array[StringName] = [&"vol_vide_sous", &"void_below"]
## Said once, the first time she takes off (how to steer, how to land).
const HELP_FLAG := &"vol_aide_vue"
const HELP_PHONE := "Dirige ton ptérosaure avec le joystick ; touche le bouton du harnais pour te poser."
const HELP_COMPUTER := "Dirige ton ptérosaure avec {move} ; {fly} pour te poser là où le sol est sûr."
const SKY := Color(0.55, 0.82, 1.0)
const TAKE_OFF_SFX := preload("res://assets/audio/sfx/latch.wav")   # the harness buckled
const LAND_SFX := preload("res://assets/audio/sfx/feuillage.mp3")   # wings folding, a rustle

## Why she cannot take off (TAKE_OFF_PROBLEMS keys → lines). "scene" and "not_yet" are never said:
## the button is not there then (no harness yet, a scene playing).
const SAY := {
	"not_yet": "Voler ? Il te faudrait un harnais de vol… et un grand ptérosaure pour t'emmener.",
	"no_harness": "Sans le harnais de vol de Joss, pas question de monter là-haut : il t'a fait promettre de toujours le boucler !",
	"scene": "Pas maintenant.",
	"indoor": "Pas de vol sous un toit !",
	"cave": "Sous la roche, pas la place de déployer des ailes.",
	"underwater": "Sous l'eau ? Même un ptérosaure n'y arriverait pas.",
	"forbidden": "Ici, le vent est trop fort pour décoller. Mieux vaut rester à pied.",
	"swimming": "On ne décolle pas de l'eau : regagne d'abord la rive.",
	"none": "Aucun dino de ton équipe ne peut te porter dans les airs. Il faut un grand ptérosaure adulte : un Pteranodon, un Tapejara…",
	"too_small": "%s est bien trop petit pour te porter ! Il faut un grand ptérosaure : un Pteranodon, un Tapejara…",
	"young": "%s est encore trop jeune pour te porter dans les airs : il faut qu'il soit adulte (niv. %d).",
}
## Why she cannot land here ("" : she can).
const LAND_WATER := "Pas ici : c'est de l'eau profonde ! Cherche la terre ferme."
const LAND_VOID := "En dessous, c'est le vide ! Pose-toi sur un piton."
const LAND_WOODS := "Trop d'arbres en dessous : pas la place de se poser."
const LAND_SOLID := "Pas la place de se poser ici : un peu plus loin ?"
const LAND_NARROW := "Trop étroit pour se poser : cherche un sol plat un peu plus large."
const LAND_OUT := "Pas si près du bord : reviens un peu vers l'intérieur."
## To land, the ground must be flat and open all round her (ROOM tiles each way: a 3 × 3 square).
const ROOM := 1
## Small pterosaurs: they fly, but carry nobody (for the words).
const SMALL_FLYERS := [&"dimorphodon", &"anurognathus", &"rhamphorhynchus"]
const FEET_RADIUS := 12.0   # her feet's circle (player.tscn: 11 px), for the room to land
const FEET_UP := -5.0
## When she last crossed a zone's edge in flight (Player meta, Time msec: Flight._cross), and how
## long after it an arrival scene still counts her as come flying (the fade, the zone loading).
const CROSSED_META := &"vol_bord_franchi_ms"
const CAME_FLYING_S := 15.0


# ------------------------------------------------------------------ who, what

static func has_harness() -> bool:
	return Game.item_count(ITEM) > 0


## Did she just come into this zone in flight, over its edge (not on foot)? For the arrival scenes
## (CieuxArche.arrival: the Arche du Vent is reached on foot by the needle, or in flight).
static func came_flying(player: Node) -> bool:
	if player == null or not player.has_meta(CROSSED_META):
		return false
	return Time.get_ticks_msec() - int(player.get_meta(CROSSED_META)) < CAME_FLYING_S * 1000.0


## The story gave her the harness and the leave to fly: the button is there.
static func available() -> bool:
	return bool(Game.flag(FLAG)) and has_harness()


## The great pterosaur who takes her up (the first grown one of the party), or null.
static func flyer() -> Dino:
	return Game.ability_user(ABILITY)


## Why she cannot take off now, as a key of SAY ("" : she can). One reason, the first that applies.
static func take_off_problem(world: Node) -> String:
	if not Game.flag(FLAG):
		return "not_yet"
	if not has_harness():
		return "no_harness"
	var player: Player = world.get(&"player")
	var region: Region = world.get(&"region")
	if player == null or region == null or player.busy or Dialogue.active or Story.playing > 0 \
			or world.get(&"_changing_zone") or world.get_tree().paused:
		return "scene"
	if region.indoor:
		return "indoor"
	if region.cave:
		return "cave"
	if region.is_underwater():
		return "underwater"
	if region.get_meta(NO_FLIGHT_META, false):
		return "forbidden"
	if player.is_swimming():
		return "swimming"
	if flyer() == null:
		return _no_flyer_kind()
	return ""


## The words for a reason of take_off_problem (the dino's name and level filled in).
static func say(problem: String) -> String:
	var line: String = SAY.get(problem, "")
	match problem:
		"too_small":
			return line % _party_member(func(d: Dino) -> bool: return d.species().id in SMALL_FLYERS).nickname
		"young":
			return line % [_party_member(func(d: Dino) -> bool: return Abilities.has(d, ABILITY)).nickname, Abilities.ADULT_LEVEL]
	return line


static func _no_flyer_kind() -> String:
	if _party_member(func(d: Dino) -> bool: return Abilities.has(d, ABILITY)):
		return "young"
	if _party_member(func(d: Dino) -> bool: return d.species().id in SMALL_FLYERS):
		return "too_small"
	return "none"


static func _party_member(test: Callable) -> Dino:
	for d in Game.party:
		if test.call(d):
			return d
	return null


## Why she cannot set down at `at` ("" : she can): deep water, the void, the woods, too narrow
## (a vine bridge, a ledge: not flat and open all round), something solid (a tree, a rock, a
## house, a cliff's wall), the very edge of the zone.
static func landing_problem(region: Region, at: Vector2, chloe: Node2D = null) -> String:
	if not region.bounds().grow(-region.tile_size().x).has_point(at):
		return LAND_OUT
	var cell := Vector2i((at / region.tile_size()).floor())
	var ground := region.surface_at(at)
	if ground == &"water":
		return LAND_WATER
	if is_void(region, cell):
		return LAND_VOID
	if ground == &"forest":
		return LAND_WOODS
	if not _roomy(region, cell):
		return LAND_NARROW
	if chloe and _blocked(chloe, at):
		return LAND_SOLID
	return ""


## Is the tile `cell` the void (lower than the zone's VOID_METAS height)?
static func is_void(region: Region, cell: Vector2i) -> bool:
	for meta in VOID_METAS:
		if region.has_meta(meta):
			return region.tile_height(cell) < float(region.get_meta(meta))
	return false


## Flat and open ground all round `cell` (ROOM tiles each way): no water, void or woods, no cliff.
static func _roomy(region: Region, cell: Vector2i) -> bool:
	var here := region.tile_height(cell)
	var tile := region.tile_size()
	for dy in range(-ROOM, ROOM + 1):
		for dx in range(-ROOM, ROOM + 1):
			var c := cell + Vector2i(dx, dy)
			var kind := region.surface_at((Vector2(c) + Vector2(0.5, 0.5)) * tile)
			if kind == &"water" or kind == &"forest" or is_void(region, c):
				return false
			if absf(region.tile_height(c) - here) > region.cliff_step():
				return false
	return true


## Something solid where her feet would be (the world's layer: trees, rocks, walls, cliffs).
static func _blocked(chloe: Node2D, at: Vector2) -> bool:
	if not chloe.is_inside_tree():
		return false
	var circle := CircleShape2D.new()
	circle.radius = FEET_RADIUS
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, at + Vector2(0.0, FEET_UP))
	query.collision_mask = Swim.SOLID_LAYER
	query.collide_with_areas = false
	return not chloe.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


# ------------------------------------------------------------------ taking off, landing

## The action « fly »: up if she is on the ground, down if she flies.
static func toggle(world: Node) -> void:
	var player: Player = world.get(&"player")
	if player == null:
		return
	if player.flight:
		await land(world)
	else:
		take_off(world)


## Takes her up, or says why not (nothing said before she has the harness, nor during a scene).
static func take_off(world: Node) -> bool:
	var problem := take_off_problem(world)
	if problem != "":
		if not problem in ["not_yet", "scene"]:
			Toast.say(world.get_tree(), say(problem), SKY)
		return false
	var player: Player = world.get(&"player")
	player.mount = null   # (from the saddle to the harness)
	player.flyer = flyer()
	player.flight = Flight.new(player, world.get(&"region"))
	player.collision_layer = 0   # over everything: no way out, no trigger, no wild dino reaches her
	player.collision_mask = 0
	player.cancel_goal()
	var companion: Companion = world.get(&"companion")
	companion.refresh()
	companion.cry(&"neutre")
	Audio.play_sfx(TAKE_OFF_SFX, -4.0, 0.05)
	_camera_back(world, true)
	if not Game.flag(HELP_FLAG):
		Game.set_flag(HELP_FLAG)
		Toast.say(world.get_tree(), Prompts.say(HELP_PHONE, HELP_COMPUTER.replace("{move}", _move_words())), SKY)
	return true


## Sets her down where she flies, if the ground there will hold her (else says why). Awaitable.
static func land(world: Node) -> bool:
	var player: Player = world.get(&"player")
	if player == null or player.flight == null or not player.flight.is_up():
		return false
	var problem := landing_problem(world.get(&"region"), player.global_position, player)
	if problem != "":
		Toast.say(world.get_tree(), problem, SKY)
		return false
	player.busy = true
	player.flight.start_landing()
	while is_instance_valid(player) and player.flight and not player.flight.landed():
		await player.get_tree().physics_frame
	if is_instance_valid(player) and player.flight:
		set_down(player)
		Audio.play_sfx(LAND_SFX, -10.0, 0.08, 0.7)
	if is_instance_valid(player):
		player.busy = false
	return true


## Her feet on the ground at once, where she is (no landing to watch): the flight is over.
static func set_down(player: Player) -> void:
	if player.flight:
		player.flight.finish()
	player.flight = null
	player.flyer = null
	player.collision_layer = PLAYER_LAYER   # (her mask comes back by itself: Player._update_water_mask)
	if not player.is_inside_tree():
		return
	var world := player.get_tree().current_scene
	_camera_back(world, false)
	var companion := player.get_tree().get_first_node_in_group(&"companion") as Companion
	if companion:
		companion.sprite.position = Vector2.ZERO
		companion.refresh()
		companion.stand_beside(player.global_position)


## A scene starts while she flies (or her flyer left): she is set down at the last safe place
## flown over, at once.
static func set_down_safely(player: Player) -> void:
	if player.flight == null:
		return
	player.teleport(player.flight.safe_point)   # (Player.teleport sets her down there: set_down)


static func _camera_back(world: Node, up: bool) -> void:
	var view := world.get(&"_view") as WorldView if world else null
	if view == null:
		return
	view.close_up = view.camera.distance() + Flight.CAMERA_BACK_M if up else 0.0


## The movement keys, for the help (« ZQSD » on an AZERTY, the stick on a pad).
static func _move_words() -> String:
	if Prompts.family != Prompts.KEYBOARD:
		return "le stick"
	var keys := ""
	for action in [&"move_up", &"move_left", &"move_down", &"move_right"]:
		keys += Prompts.label(action, "key")
	return keys if keys.length() == 4 else "les flèches"


# ------------------------------------------------------------------ the HUD

## Its key (F, the pad's X), added to the input map like the Dinodex's (DexScreen.ensure_action).
static func ensure_action() -> void:
	if InputMap.has_action(ACTION):
		return
	InputMap.add_action(ACTION, 0.5)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F
	InputMap.action_add_event(ACTION, key)
	var pad := InputEventJoypadButton.new()
	pad.device = -1   # (any pad)
	pad.button_index = JOY_BUTTON_X
	InputMap.action_add_event(ACTION, pad)


## Puts the harness button and the help strip on the world's HUD (world.gd, _ready).
static func install(world: Node) -> void:
	ensure_action()
	var hud: CanvasLayer = world.get(&"hud")
	if hud.get_node_or_null("VolButton"):
		return   # (already there)
	var button := VolButton.new()
	button.world = world
	hud.add_child(button)
	var help := VolHelp.new()
	help.world = world
	hud.add_child(help)
	for child in hud.get_children():
		if child is HudHint:
			(child as HudHint).attach(button, func() -> String: return "Se poser" if button.flying() else "Voler", ACTION)
