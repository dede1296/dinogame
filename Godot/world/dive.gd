class_name Dive
extends RefCounted
## La Plongée (Côte, chapter 5). With Joss's diving mask (item "masque_plongee", or the story
## flag of the same name) and a grown diver in the party (Abilities "plongee": the sea reptiles
## that dive, Plesiosaurus, Ichthyosaurus, Elasmosaurus), Chloé, swimming over deep water marked
## for it (DiveSpot), dives: the diver takes her on its back, they sink under the surface, the
## screen goes deep blue, and she comes down where the spot leads: an underwater zone (Region
## "underwater", explored freely), or another pool where she comes back up (a flooded passage).
## Under the water her diver carries her the whole time (Player.diving). « Remonter » takes her
## back up where she dived (RETURN_FLAG), on its back, coming out of the water with a splash.
## No breath to watch: the mask and the diver are enough (a walk, not a race, on a phone).
## The view: world/view3d/underwater.gd (WorldView.dive_sink); the battles: battle/underwater_engine.gd.

const ITEM := "masque_plongee"
const FLAG := &"masque_plongee"
const ABILITY := &"plongee"
const SWIM := preload("res://world/swim.gd")
const PROP_SCRIPT := preload("res://world/prop.gd")
## Where « Remonter » takes Chloé: "zone|spawn|x|y" (a story flag, so it is saved; no spawn:
## the place, in pixels). Cleared once she is back up.
const RETURN_FLAG := &"plongee_retour"
## Said once, the first time under the water.
const TOLD_FLAG := &"plongee_expliquee"
const FIRST_TIME := "Sous l'eau ! Nage où tu veux : le bouton de la surface te ramène en haut quand tu veux."
## The dive in the view (WorldView.dive_sink, m): the pair sinks this deep under the surface, in
## this long; arriving under the water, they come down from this high above their place.
const SINK_M := 1.6
const SINK_S := 0.9
const DROP_M := 2.6
const ARRIVE_S := 1.2
## The screen, going down (deep blue) or up (the light of the surface).
const DEEP_BLUE := Color(0.02, 0.1, 0.17)
const SURFACE_LIGHT := Color(0.62, 0.84, 0.9)
const FADE_S := 0.45
## A flooded passage: the crossing under the rock, in the blue, this long (s).
const CROSSING_S := 1.1
const PLUNGE_SFX := "res://assets/audio/sfx/plongee.mp3"
const SURFACE_SFX := "res://assets/audio/sfx/remontee.mp3"
const BUBBLE := Color(0.86, 0.96, 1.0)
const BUBBLES: Array[Color] = [Color(0.86, 0.96, 1.0), Color(0.7, 0.9, 1.0)]


# ------------------------------------------------------------------ rules

static func has_mask() -> bool:
	if Game.item_count(ITEM) > 0:
		return true
	return true if Game.flag(FLAG) else false


## The dino who dives with Chloé (the first grown diver of the party), or null (no mask, or no
## grown diver).
static func diver() -> Dino:
	if not has_mask():
		return null
	return Game.ability_user(ABILITY)


static func can_dive() -> bool:
	return diver() != null


## Why Chloé cannot dive (said when she tries).
static func blocked_reason() -> String:
	var young: Dino = null
	for d in Game.party:
		if Abilities.has(d, ABILITY):
			young = d
			break
	if not has_mask():
		if young and Abilities.usable(young, ABILITY):
			return "%s plongerait volontiers, mais sans masque de plongée, Chloé ne peut pas le suivre sous l'eau." % young.nickname
		if young:
			return "Sans masque de plongée, impossible de descendre… et %s est encore trop jeune pour plonger avec toi (adulte au niv. %d)." % [young.nickname, Abilities.ADULT_LEVEL]
		return "Pour descendre là-dessous, il faudrait un masque de plongée… et un dino qui sache plonger."
	if young:
		return "%s est encore trop jeune pour plonger avec toi sur le dos : il faut qu'il soit adulte (niv. %d)." % [young.nickname, Abilities.ADULT_LEVEL]
	return "Avec le masque, il te faut aussi un dino plongeur adulte (un Plésiosaure, par exemple) pour descendre."


## Is `region` a zone played under the water (Region.underwater, or its meta "underwater")?
static func underwater(region: Node) -> bool:
	return region != null and (region.get(&"underwater") == true or region.get_meta(&"underwater", false) == true)


## The dive spot Chloé swims over now (a DiveSpot of the zone), or null.
static func spot_at(player: Node2D) -> Node2D:
	if player == null or not player.is_inside_tree():
		return null
	for s in player.get_tree().get_nodes_in_group(&"dive_spot"):
		if (s as Node2D).call(&"area").has_point(player.global_position):
			return s
	return null


# ------------------------------------------------------------------ zones

## A zone was just entered (world.gd): under the water, the diver carries Chloé the whole time
## (no mount, no rain down there); back above it, she swims or walks as usual.
static func on_zone_entered(world: Node) -> void:
	var player = world.get(&"player")
	if player == null:
		return
	var under := underwater(world.get(&"region"))
	player.diving = under
	if not under:
		if Game.flag(RETURN_FLAG):
			Game.set_flag(RETURN_FLAG, false)   # back at the surface: nowhere to go up to
		return
	world.call(&"dismount")
	# Swimming over the scenery (rocks, bones, pillars): only the real walls stop her (the
	# relief's high cliffs, Region.cliff_step); the view lifts her over it (Underwater.swim_lift).
	var region: Node = world.get(&"region")
	for n in (region.get(&"entities") as Node).get_children():
		if n is Prop and n.get_script() == PROP_SCRIPT:
			(n as CollisionObject2D).collision_layer = 0
	var carrier := diver()
	if carrier == null:
		carrier = SWIM.swimmer()   # (no diver any more: never stuck down there, carried all the same)
	player.swimmer = carrier
	if Game.weather != &"clear":
		Game.set_weather(&"clear")   # the rain is up above
	var companion = world.get(&"companion")
	if companion:
		companion.refresh()


# ------------------------------------------------------------------ going down, coming up

## Chloé dives at `spot` (she swims over it): closed, she is told why; without a mask or a grown
## diver, what is missing. Otherwise her diver takes her, they sink, and she arrives where the
## spot leads (see _arrive).
static func plunge(spot: Node2D) -> void:
	var w = _world()
	if w == null or spot == null or _busy(w):
		return
	var player: Player = w.player
	if not spot.call(&"is_open"):
		player.busy = true
		await spot.call(&"tell_closed", player)
		player.busy = false
		return
	var carrier := diver()
	if carrier == null:
		Toast.say(w.get_tree(), blocked_reason())
		return
	player.busy = true
	player.velocity = Vector2.ZERO
	w.set(&"_changing_zone", true)
	var view = _view(w)
	if player.swimmer != carrier:   # the diver takes her from her swimmer
		player.swimmer = carrier
		w.companion.refresh()
		await w.get_tree().create_timer(0.4).timeout
	w.companion.cry(&"neutre")
	_sfx(PLUNGE_SFX)
	if view:
		view.splash(player.global_position)
		view.burst(player.global_position, BUBBLES, 14, 0.1, 0.5)
		await _sink(view, 0.0, SINK_M, SINK_S, Tween.EASE_IN)
	await Router.fade_out(FADE_S, DEEP_BLUE)
	var here: StringName = w.region.region_id
	var target: StringName = spot.get(&"target_zone")
	if target == &"":
		target = here
	var goes_under := underwater(w.region) or _zone_is_underwater(w, target)
	if goes_under and not underwater(w.region):
		var back: StringName = spot.get(&"surface_spawn")
		var at: Vector2 = (spot.call(&"area") as Rect2).get_center()
		Game.set_flag(RETURN_FLAG, "%s|%s|%.1f|%.1f" % [here, back, at.x, at.y])
	await _bubbles(w.get_tree(), CROSSING_S if not goes_under else 0.5, true)
	_go(w, target, spot.get(&"target_spawn"), Vector2.INF)
	await _arrive(w, underwater(w.region))
	if underwater(w.region) and not Game.flag(TOLD_FLAG):
		Game.set_flag(TOLD_FLAG)
		Toast.say(w.get_tree(), FIRST_TIME, Color(0.55, 0.9, 1.0))


## Under the water, Chloé goes back up (the Remonter button): where she dived, or else by the
## zone's first way out (its first exit).
static func surface() -> void:
	var w = _world()
	if w == null or _busy(w) or not underwater(w.region):
		return
	var dest := _way_up(w)
	if dest.is_empty():
		Toast.say(w.get_tree(), "Pas de chemin vers la surface d'ici…")
		return
	var player: Player = w.player
	player.busy = true
	player.velocity = Vector2.ZERO
	w.set(&"_changing_zone", true)
	var view = _view(w)
	_sfx(SURFACE_SFX)
	_bubbles(w.get_tree(), 1.0, false)
	if view:
		view.burst(player.global_position, BUBBLES, 18, 1.4, 0.4)
		await _sink(view, 0.0, -DROP_M, 0.8, Tween.EASE_IN)
	await Router.fade_out(FADE_S, SURFACE_LIGHT)
	_go(w, dest["zone"], dest["spawn"], dest["at"])
	await _arrive(w, false)


## Where « Remonter » leads from here: {zone, spawn, at} (empty: nowhere).
static func _way_up(w) -> Dictionary:
	var back = Game.flag(RETURN_FLAG)
	if back is String:
		var parts := (back as String).split("|")
		if parts.size() == 4 and _zones(w).has(StringName(parts[0])):
			var at := Vector2(float(parts[2]), float(parts[3])) if parts[1] == "" else Vector2.INF
			return {"zone": StringName(parts[0]), "spawn": StringName(parts[1]) if parts[1] != "" else &"Depart", "at": at}
	for exit in (w.region as Region).exits():
		if _zones(w).has(exit.target_zone) and not _zone_is_underwater(w, exit.target_zone):
			return {"zone": exit.target_zone, "spawn": exit.target_spawn, "at": Vector2.INF}
	return {}


## Chloé goes to `zone` at `spawn` (or at `at`, pixels): in the same zone, only moved there.
static func _go(w, zone: StringName, spawn: StringName, at: Vector2) -> void:
	if zone == w.region.region_id:
		var p: Vector2 = at if at != Vector2.INF else w.region.spawn_point(spawn)
		w.player.teleport(p)
		w.companion.stand_beside(p)
		on_zone_entered(w)
	else:
		w.call(&"_enter_zone", zone, spawn, at)
		Save.save_game()
	_keep_diver(w)


## Coming up in the water, she is still on her diver's back (not the party's first swimmer).
static func _keep_diver(w) -> void:
	var carrier := diver()
	var player: Player = w.player
	if carrier and not player.diving and player.on_water() and player.swimmer != carrier:
		player.call(&"_set_swimmer", carrier)
		w.companion.refresh()


## The screen clears on the arrival: under the water, the pair comes down from above; at the
## surface, it comes up out of the water with a splash. Then Chloé is free again.
static func _arrive(w, under: bool) -> void:
	var view = _view(w)
	var player: Player = w.player
	if view:
		view.dive_sink = -DROP_M if under else SINK_M
	Router.fade_in(FADE_S)
	if not under:
		_keep_diver(w)
	if view:
		if not under and player.is_swimming():
			view.splash(player.global_position)
		await _sink(view, view.dive_sink, 0.0, ARRIVE_S, Tween.EASE_OUT)
	else:
		await w.get_tree().create_timer(FADE_S).timeout
	w.set(&"_changing_zone", false)
	player.busy = false


## The swimmer and Chloé shown `from` → `to` metres below their place (WorldView.dive_sink).
static func _sink(view, from: float, to: float, time: float, easing: Tween.EaseType) -> void:
	view.dive_sink = from
	var t: Tween = view.create_tween()
	t.tween_property(view, "dive_sink", to, time).set_trans(Tween.TRANS_SINE).set_ease(easing)
	await t.finished


## Bubbles rushing across the screen (over the fade): rising, or streaming up past Chloé as she
## goes down (`down`), for `time` seconds.
static func _bubbles(tree: SceneTree, time: float, down: bool) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 101   # over the router's curtain
	var p := CPUParticles2D.new()
	var screen := tree.root.get_visible_rect().size
	p.amount = Quality.scaled(46)
	p.lifetime = 1.1
	p.explosiveness = 0.25
	p.one_shot = true
	p.position = Vector2(screen.x / 2.0, screen.y * (0.75 if down else 1.05))
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(screen.x * 0.45, screen.y * 0.25)
	p.direction = Vector2.UP
	p.spread = 14.0
	p.gravity = Vector2(0, -260.0 if down else -420.0)
	p.initial_velocity_min = screen.y * 0.35
	p.initial_velocity_max = screen.y * 0.8
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.9
	p.texture = ring_texture()
	p.color = Color(BUBBLE, 0.85)
	layer.add_child(p)
	tree.root.add_child(layer)
	p.emitting = true
	await tree.create_timer(time).timeout
	tree.create_timer(p.lifetime + 0.2).timeout.connect(layer.queue_free)


static var _ring: GradientTexture2D


## A bubble: a clear round with a bright rim (particles, the dive button).
static func ring_texture() -> GradientTexture2D:
	if _ring == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.08))
		g.add_point(0.62, Color(1, 1, 1, 0.14))
		g.add_point(0.82, Color(1, 1, 1, 0.95))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		_ring = GradientTexture2D.new()
		_ring.gradient = g
		_ring.fill = GradientTexture2D.FILL_RADIAL
		_ring.fill_from = Vector2(0.5, 0.5)
		_ring.fill_to = Vector2(1.0, 0.5)
		_ring.width = 32
		_ring.height = 32
	return _ring


# ------------------------------------------------------------------ helpers

static func _world():
	var w = Engine.get_main_loop().current_scene
	return w if w != null and w.get(&"player") != null and w.get(&"region") != null else null


## The 3D view (untyped: its dive_sink, splash, burst).
static func _view(w):
	return w.get_tree().get_first_node_in_group(&"world_view")


static func _busy(w) -> bool:
	return w.player.busy or Dialogue.active or Router.is_busy() or w.get(&"_changing_zone") or w.get_tree().paused


static func _zones(w) -> Dictionary:
	return (w.get_script() as Script).get_script_constant_map().get("ZONES", {})


## Is zone `id` played under the water? (Read from its scene without opening it.)
static func _zone_is_underwater(w, id: StringName) -> bool:
	var path: String = _zones(w).get(id, "")
	if path == "" or not ResourceLoader.exists(path):
		return false
	var state := (load(path) as PackedScene).get_state()
	for p in state.get_node_property_count(0):
		if state.get_node_property_name(0, p) in [&"underwater", &"metadata/underwater"]:
			return state.get_node_property_value(0, p) == true
	return false


static func _sfx(path: String) -> void:
	if ResourceLoader.exists(path):
		Audio.play_sfx(load(path), -3.0, 0.05)


# ------------------------------------------------------------------ tests (tools/capture.gd)

## Chloé is put in the water of the spot named `spot_name` (or stays over the one she is on) and
## dives there, as if she had pressed the button.
static func debug_plunge(world: Node, spot_name: String) -> void:
	var spot: Node2D = null
	for s in world.get_tree().get_nodes_in_group(&"dive_spot"):
		if spot_name == "" or String((s as Node).name) == spot_name:
			spot = s
			break
	if spot == null:
		print("plongée : pas de point « %s »" % spot_name)
		return
	var at: Vector2 = (spot.call(&"area") as Rect2).get_center()
	world.get(&"player").teleport(at)
	world.get(&"companion").stand_beside(at)
	for i in 3:   # she swims (Player._update_swim) before she dives
		await world.get_tree().physics_frame
	await plunge(spot)


## What the dive looks like now (tools/capture.gd « dive_state »).
static func describe(world: Node) -> String:
	var player = world.get(&"player")
	var view := world.get_tree().get_first_node_in_group(&"world_view")
	var carrier: Dino = player.swimmer if player else null
	return "plongée : zone=%s sous l'eau=%s diving=%s porteuse=%s plongeur=%s masque=%s retour=%s dive_sink=%.2f" % [
		Game.region_id, underwater(world.get(&"region")), player.diving if player else false,
		carrier.nickname if carrier else "—", diver().nickname if diver() else "—", has_mask(),
		Game.flag(RETURN_FLAG), view.get(&"dive_sink") if view else 0.0]
