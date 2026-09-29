class_name Doorway
## Going in and out through the doors of the houses (WorldView.door, world/view3d/doors.gd;
## docs/direction-artistique.md « Portes animées »). Someone walks to the door and faces it, the
## door opens, they step up onto the threshold and on into the dark, fading out there (the
## jambs and the lintel hide them: the scenery turns see-through as if they still stood at the
## front of the door, WorldView.occlusion_px); coming out, the
## reverse, and the door closes behind them.
## Chloé walks on her own feet (her collisions with the house off meanwhile), her dino after her
## if it fits through the door; one too tall for it waits outside, beside it, and joins her as
## she comes out (Companion.outside while she is in another zone: the Cabinet). A character (an
## Npc) walks its walk. Used by the world (World.goto_zone: the Cabinet of Port-Ambre) and by
## the scenes (the shops of Havre-Doré, Ferréol's warehouse at night, Roc leaving the Cabinet, a
## raptor opening its door: story/clins_doeil.gd).
## All awaitable; at their end (or whatever cut them short: settle) everything is as it was.

const S := preload("res://story/story.gd")
const PX := HeightMap.PX
const WALK_SPEED := 115.0      # px/s: Chloé to the door, and out
const IN_SPEED := 85.0         # px/s: through the door
const KEEPER_SPEED := 140.0    # px/s: a shopkeeper to their door and back
const DINO_SPEED := 95.0       # px/s: her dino through the door, or aside
const FADE_S := 0.45           # into the dark inside, or out of it
const DARK := Color(0.16, 0.14, 0.13, 0.0)
## Out of a shop, Chloé steps this far past the front of the door (px), making way.
const STEP_OUT := 32.0
## Before a shopkeeper goes to their door, Chloé makes way if she stands this close to it (px).
const MAKE_WAY := 44.0
## A dino waits beside the door, this far past its jamb (px), a little in front.
const ASIDE := Vector2(10.0, 10.0)
## Her dino goes in this long after her (s).
const DINO_BEHIND_S := 0.35
## A dino fits through a door that is this much taller than it (m).
const HEADROOM := 0.05
## A walk gives up after this long (s): never stuck on a door.
const WALK_MAX_S := 2.5

## The house Chloé is going through (her collisions with it are off meanwhile).
static var _through: Node2D = null


# ------------------------------------------------------------------ Chloé

## Chloé goes into `house`: to its door, which opens, then inside, out of sight; her dino goes
## in after her, or waits beside the door if it is too tall for it (on side `aside`: -1 left, 1
## right; 0: the side it comes from). True if it waits outside.
static func chloe_in(house: Node2D, aside := 0.0) -> bool:
	var w = S.world()
	var d := _door(house)
	if w == null or d.is_empty():
		return false
	var chloe: Player = w.player
	var dino: Companion = w.companion
	w.dismount()
	await _walk(chloe, d["front"], WALK_SPEED, d)
	chloe.face_towards(d["threshold"])
	var view := _view()
	view.occlusion_px = d["front"]   # (the house never turns see-through: its jambs hide her)
	await view.open_door(house)
	_through = house
	chloe.add_collision_exception_with(house)
	var waits := _has_dino(dino) and not fits(dino, d)
	var token := {}
	if waits:
		_run(func() -> void: await _wait_beside(dino, d, aside), token)
	elif _has_dino(dino):   # it goes in a step behind her (_dino_in), not in her tracks
		dino.set_physics_process(false)
		_run(func() -> void:
			await S.wait(DINO_BEHIND_S)
			await _dino_in(dino, d), token)
	_fade(chloe, DARK, FADE_S, _to_facade(IN_SPEED))
	await _walk(chloe, d["inside"], IN_SPEED, d)
	await _finish(token)
	return waits


## Chloé stands inside `house`, in the dark (arriving through its door: after the fade, she
## comes out with chloe_out); the door open, her dino inside too, or waiting beside the door
## (Companion.outside).
static func place_inside(house: Node2D) -> void:
	var w = S.world()
	var d := _door(house)
	if w == null or d.is_empty():
		return
	var chloe: Player = w.player
	var dino: Companion = w.companion
	var view := _view()
	view.set_door(house, true)
	view.occlusion_px = d["front"]
	_through = house
	chloe.add_collision_exception_with(house)
	chloe.teleport(d["inside"])
	chloe.face_towards(d["front"])
	_set_modulate(chloe, DARK)
	_lift(chloe, d)
	if not _has_dino(dino) and not dino.outside:
		return
	dino.set_physics_process(false)
	if dino.outside:   # it waited outside: there, beside the door
		dino.outside = false
		dino.teleport(_beside(dino, d, -1.0))
		_face(dino, d["front"])
	else:
		dino.teleport(d["inside"])
		dino.set_meta(&"doorway_in", true)
		_set_modulate(dino, DARK)
		_lift(dino, d)


## Chloé, inside `house` (chloe_in, place_inside), comes out to `to_px` (default: just past the
## front of the door); her dino after her, or it comes to her from beside the door; the door
## closes behind them (unless `close` is false: someone else is still to come out).
static func chloe_out(house: Node2D, to_px := Vector2.INF, close := true) -> void:
	var w = S.world()
	var d := _door(house)
	if w == null or d.is_empty():
		settle()
		return
	var chloe: Player = w.player
	var dino: Companion = w.companion
	var out: Vector2 = to_px if to_px != Vector2.INF else d["front"] + Vector2(0, STEP_OUT)
	_fade(chloe, Color.WHITE, FADE_S)
	await _walk(chloe, d["front"], IN_SPEED, d)
	var token := {}
	if _has_dino(dino) and dino.get_meta(&"doorway_in", false):
		_run(func() -> void:
			await S.wait(0.15)
			await _dino_out(dino, d), token)
	await _walk(chloe, out, WALK_SPEED, d)
	await _finish(token)
	_join(dino, chloe, d)
	if close:
		await _view().open_door(house, false)
	settle()


## Is `dino` (Chloé's) short enough to go through the door `d`?
static func fits(dino: Companion, d: Dictionary) -> bool:
	if dino == null or dino.dino == null:
		return true
	var tall := DinoSize.height_m(dino.dino.species(), absf(dino.sprite.scale.y))
	return tall <= float(d["height"]) - HEADROOM


# ------------------------------------------------------------------ the characters

## `who` (an Npc) goes into `house`: to its door, which opens (unless it is already), and inside,
## out of sight; the door closes behind them if `close`. False (nothing done): no door known.
static func npc_in(house: Node2D, who: Npc, speed := KEEPER_SPEED, close := true) -> bool:
	var d := _door(house)
	if d.is_empty() or not is_instance_valid(who):
		return false
	who.collision_layer = 0   # (hidden inside, it blocks nobody)
	await _npc_walk(who, d["front"], speed, d)
	_face_up(who)
	await _view().open_door(house)
	_fade(who, DARK, FADE_S, _to_facade(speed * 0.6))
	await _npc_walk(who, d["inside"], speed * 0.6, d)
	if close:
		await _view().open_door(house, false)
	return true


## `who` (an Npc) comes out of `house`: in the dark on its threshold, the door opens, out to its
## front (the door stays open: close it after, or someone goes back in). False: no door known.
static func npc_out(house: Node2D, who: Npc, speed := KEEPER_SPEED) -> bool:
	var d := _door(house)
	if d.is_empty() or not is_instance_valid(who):
		return false
	who.collision_layer = 0
	who.global_position = d["inside"]
	who.reset_physics_interpolation()
	_set_modulate(who, DARK)
	_lift(who, d)
	await _view().open_door(house)
	_fade(who, Color.WHITE, FADE_S)
	await _npc_walk(who, d["front"], speed * 0.6, d)
	_unlift(who)
	if is_instance_valid(who):
		who.collision_layer = 1
	return true


# ------------------------------------------------------------------ a dino of a scene

## A dino of a scene (a DinoNpc: the raptor that opens the Cabinet's door) comes out of `house`:
## in the dark on its threshold, the door opens (unless it is already, `secs` long), out to its
## front (the door stays open). False (nothing done): no door known.
static func dino_out(house: Node2D, who: DinoNpc, speed := DINO_SPEED * 0.7, secs := Doors.OPEN_S) -> bool:
	var d := _door(house)
	if d.is_empty() or not is_instance_valid(who):
		return false
	who.collision_layer = 0
	who.global_position = d["inside"]
	who.reset_physics_interpolation()
	_set_modulate(who, DARK)
	_lift(who, d)
	await _view().open_door(house, true, secs)
	_fade(who, Color.WHITE, FADE_S)
	await _scene_dino_walk(who, d["front"], speed, d)
	_unlift(who)
	return true


## A dino of a scene goes into `house`: to its door, which opens (unless it is already), and in,
## out of sight; the door closes behind it if `close`. False (nothing done): no door known.
static func dino_in(house: Node2D, who: DinoNpc, speed := DINO_SPEED * 1.4, close := true) -> bool:
	var d := _door(house)
	if d.is_empty() or not is_instance_valid(who):
		return false
	who.collision_layer = 0
	await _scene_dino_walk(who, d["front"], speed, d)
	await _view().open_door(house)
	_fade(who, DARK, FADE_S, _to_facade(speed * 0.5))
	await _scene_dino_walk(who, d["inside"], speed * 0.5, d)
	if close:
		await _view().open_door(house, false)
	return true


## A dino of a scene walks to `to` (its walk; up or down the steps of the door `d`). Not
## DinoNpc.walk_to, which hops down to the ground first (the steps' lift would be lost).
static func _scene_dino_walk(who: DinoNpc, to: Vector2, speed: float, d: Dictionary) -> void:
	if not is_instance_valid(who) or who.sprite == null:
		return
	var from := who.global_position
	var way := to - from
	if way.length() < 2.0:
		return
	var anims: Array = SheetFrames.dino_anims(who.sprite.sprite_frames, way)
	if absf(way.x) > 1.0:
		who.sprite.flip_h = way.x < 0.0
	who.sprite.play(anims[0])
	var t := who.create_tween()
	t.tween_method(func(p: Vector2) -> void:
		who.global_position = p
		_lift(who, d), from, to, way.length() / speed)
	await t.finished
	if is_instance_valid(who):
		who.sprite.play(anims[1])


# ------------------------------------------------------------------ the shops

## Into a shop (`house`): its keeper goes to the door and in first, Chloé follows (her dino too,
## or it waits outside). False when the house has no door known (then nothing moves).
static func shop_in(house: Node2D, keeper: Npc) -> bool:
	var d := _door(house)
	if d.is_empty():
		return false
	var chloe := Stage.chloe()
	if is_instance_valid(keeper):
		if not keeper.has_meta(&"doorway_home"):
			keeper.set_meta(&"doorway_home", [keeper.global_position, keeper.facing])
		# Chloé makes way, and watches them go.
		var token := {}
		if chloe and chloe.global_position.distance_to(d["front"]) < MAKE_WAY:
			var aside: Vector2 = d["front"] + Vector2(_away_from_keeper(keeper, d) * MAKE_WAY, MAKE_WAY * 0.6)
			_run(func() -> void: await _walk(chloe, aside, WALK_SPEED, d), token)
		keeper.collision_layer = 0
		await _npc_walk(keeper, d["front"], KEEPER_SPEED, d)
		await _finish(token)
		Stage.turn_to(chloe, keeper.global_position)
		_face_up(keeper)
		await _view().open_door(house)
		_run(func() -> void: await npc_in(house, keeper, KEEPER_SPEED, false), {})
		await S.wait(0.3)
	await chloe_in(house, _away_from_keeper(keeper, d))
	return true


## Out of the shop: Chloé comes out (her dino after her), its keeper sees her out, the door
## closes, and they go back to their place.
static func shop_out(house: Node2D, keeper: Npc) -> void:
	var has_keeper := is_instance_valid(keeper)
	var out := Vector2.INF
	var d := _door(house)
	if has_keeper and not d.is_empty():   # (aside, away from the keeper's place: making way for them)
		out = d["front"] + Vector2(_away_from_keeper(keeper, d) * MAKE_WAY, STEP_OUT)
	await chloe_out(house, out, not has_keeper)
	if not has_keeper:
		return
	await npc_out(house, keeper)
	var chloe := Stage.chloe()
	Stage.turn_to(chloe, keeper.global_position)
	await _view().open_door(house, false)
	var home: Array = keeper.get_meta(&"doorway_home", [keeper.global_position, keeper.facing])
	await keeper.walk_to(home[0], home[1], KEEPER_SPEED)
	if is_instance_valid(keeper):
		keeper.remove_meta(&"doorway_home")


## The side of the door away from the keeper's place (1: right, -1: left): Chloé steps out there,
## her tall dino waits there, and the keeper comes and goes on the other side.
static func _away_from_keeper(keeper: Npc, d: Dictionary) -> float:
	if not is_instance_valid(keeper):
		return 0.0
	var place: Vector2 = keeper.get_meta(&"doorway_home", [keeper.global_position])[0]
	var side := -signf(place.x - (d["front"] as Vector2).x)
	return side if side != 0.0 else 1.0


# ------------------------------------------------------------------ putting things back

## Everything as it was before going through a door: Chloé's colour and height, her collisions
## with the house, her dino following her again. (Also after a walk cut short.)
static func settle() -> void:
	var w = S.world()
	if w == null:
		return
	var chloe: Player = w.get("player")
	if chloe and is_instance_valid(chloe):
		_set_modulate(chloe, Color.WHITE)
		_unlift(chloe)
		if is_instance_valid(_through):
			chloe.remove_collision_exception_with(_through)
	var dino: Companion = w.get("companion")
	if dino and is_instance_valid(dino):
		_set_modulate(dino, Color.WHITE)
		_unlift(dino)
		dino.remove_meta(&"doorway_in")
		dino.set_physics_process(true)
	var view := _view()
	if view:
		view.occlusion_px = Vector2.INF
	_through = null


# ------------------------------------------------------------------ walks

## Chloé walks to `to` on her own feet (her walk, her steps; her controls are off), up or down
## the steps of the door `d`. Gives up after WALK_MAX_S.
static func _walk(chloe: Player, to: Vector2, speed: float, d: Dictionary) -> void:
	if chloe == null or not is_instance_valid(chloe):
		return
	var tree := chloe.get_tree()
	var spent := 0.0
	# (her own physics slows her down by this much each step, before moving her)
	var brake := Player.ACCEL / Engine.physics_ticks_per_second
	while is_instance_valid(chloe) and chloe.is_inside_tree() and chloe.global_position.distance_to(to) > 3.0 and spent < WALK_MAX_S:
		var dir := (to - chloe.global_position).normalized()
		chloe.facing = dir
		chloe.velocity = dir * (speed + brake)
		_lift(chloe, d)
		await tree.physics_frame
		spent += 1.0 / Engine.physics_ticks_per_second
	if is_instance_valid(chloe):
		chloe.velocity = Vector2.ZERO
		_lift(chloe, d)


## A character walks to `to` (straight, its walk; up or down the steps of the door `d`).
static func _npc_walk(who: Npc, to: Vector2, speed: float, d: Dictionary) -> void:
	if not is_instance_valid(who):
		return
	var from := who.global_position
	var way := to - from
	if way.length() < 2.0:
		return
	who.walking = true
	who.sprite.play(StringName("walk_" + SheetFrames.direction_name(way)))
	var t := who.create_tween()
	t.tween_method(func(p: Vector2) -> void:
		who.global_position = p
		_lift(who, d), from, to, way.length() / speed)
	await t.finished
	if is_instance_valid(who):
		who.walking = false
		who.sprite.play(StringName("idle_" + SheetFrames.direction_name(way)))


## Chloé's dino walks to `to` on its own (its walk; up or down the steps of the door `d`, if any).
static func _dino_walk(dino: Companion, to: Vector2, speed: float, d := {}) -> void:
	if not is_instance_valid(dino):
		return
	var from := dino.global_position
	var way := to - from
	if way.length() < 2.0:
		return
	var anims: Array = SheetFrames.dino_anims(dino.sprite.sprite_frames, way)
	if absf(way.x) > 1.0:
		dino.sprite.flip_h = way.x < 0.0
	dino.sprite.play(anims[0])
	var t := dino.create_tween()
	t.tween_method(func(p: Vector2) -> void:
		dino.global_position = p
		_lift(dino, d), from, to, way.length() / speed)
	await t.finished
	if is_instance_valid(dino):
		dino.sprite.play(anims[1])


## Her dino goes in after her: to the door, in, into the dark.
static func _dino_in(dino: Companion, d: Dictionary) -> void:
	dino.set_physics_process(false)
	await _dino_walk(dino, d["front"], DINO_SPEED * 1.4, d)
	_fade(dino, DARK, FADE_S, _to_facade(DINO_SPEED * 0.7))
	await _dino_walk(dino, d["inside"], DINO_SPEED * 0.7, d)
	if is_instance_valid(dino):
		dino.set_meta(&"doorway_in", true)


## Her dino comes out after her, out of the dark to the front of the door.
static func _dino_out(dino: Companion, d: Dictionary) -> void:
	_fade(dino, Color.WHITE, FADE_S * 0.8)
	await _dino_walk(dino, d["front"], DINO_SPEED * 0.7, d)
	if is_instance_valid(dino):
		dino.remove_meta(&"doorway_in")
		_unlift(dino)


## A dino too tall for the door steps aside and waits there, looking at the door.
static func _wait_beside(dino: Companion, d: Dictionary, aside := 0.0) -> void:
	dino.set_physics_process(false)
	var side := aside if aside != 0.0 else signf(dino.global_position.x - (d["front"] as Vector2).x)
	var spot := _beside(dino, d, side if side != 0.0 else -1.0)
	await _dino_walk(dino, spot, DINO_SPEED * 1.6)
	_face(dino, d["front"])


## Where a dino waits beside the door `d`, on side `side` (-1: left).
static func _beside(dino: Companion, d: Dictionary, side: float) -> Vector2:
	var reach := float(d["width"]) * 0.5 * PX + dino.keep_px() + ASIDE.x
	return (d["front"] as Vector2) + Vector2(side * reach, ASIDE.y)


## Her dino back at her side (the end of her trail pointed there), following her again.
static func _join(dino: Companion, chloe: Player, d: Dictionary) -> void:
	if not _has_dino(dino) or not is_instance_valid(chloe):
		return
	# (on her side away from the door, when she stands aside of it: the doorway stays clear)
	var off := chloe.global_position.x - (d["front"] as Vector2).x
	var side := signf(off) if absf(off) > 4.0 else signf(dino.global_position.x - chloe.global_position.x)
	var spot := chloe.global_position + Vector2((side if side != 0.0 else -1.0) * maxf(54.0, dino.keep_px()), 6.0)
	var trail := PackedVector2Array([spot, spot])
	for i in 8:
		trail.append(chloe.global_position)
	chloe.trail = trail
	_unlift(dino)
	dino.set_physics_process(true)


# ------------------------------------------------------------------ small things

static func _door(house: Node2D) -> Dictionary:
	var view := _view()
	return view.door(house) if view and house and is_instance_valid(house) else {}


static func _has_dino(dino: Companion) -> bool:
	return dino != null and is_instance_valid(dino) and dino.dino != null and dino.visible


## Up the steps of the door `d`, or on its floor inside: the picture raised (not where it stands).
static func _lift(actor: Node2D, d: Dictionary) -> void:
	var sprite: Node2D = actor.get("sprite") if is_instance_valid(actor) and not d.is_empty() else null
	if sprite == null:
		return
	if not sprite.has_meta(&"doorway_rest"):
		sprite.set_meta(&"doorway_rest", sprite.position)
	var rest: Vector2 = sprite.get_meta(&"doorway_rest")
	sprite.position = rest - Vector2(0.0, Doors.lift_m(d, actor.global_position) * PX / WorldView.STRETCH)


static func _unlift(actor: Node2D) -> void:
	var sprite: Node2D = actor.get("sprite") if is_instance_valid(actor) else null
	if sprite and sprite.has_meta(&"doorway_rest"):
		sprite.position = sprite.get_meta(&"doorway_rest")
		sprite.remove_meta(&"doorway_rest")


## Fades `node`'s colour to `to` (DARK: into the dark inside) in `secs`, after `delay`.
static func _fade(node: CanvasItem, to: Color, secs: float, delay := 0.0) -> void:
	if not is_instance_valid(node):
		return
	_stop_fade(node)
	var t := node.create_tween()
	t.tween_interval(delay)
	t.tween_property(node, "modulate", to, secs)
	node.set_meta(&"doorway_fade", t)


static func _set_modulate(node: CanvasItem, to: Color) -> void:
	if is_instance_valid(node):
		_stop_fade(node)
		node.modulate = to


static func _stop_fade(node: CanvasItem) -> void:
	if not node.has_meta(&"doorway_fade"):
		return
	var t: Variant = node.get_meta(&"doorway_fade")
	if t is Tween and (t as Tween).is_valid():
		(t as Tween).kill()
	node.remove_meta(&"doorway_fade")


## Stands looking towards `px` (side on: its standing picture, turned that way).
static func _face(dino: Companion, px: Vector2) -> void:
	if not is_instance_valid(dino):
		return
	var way := Vector2(px.x - dino.global_position.x, 0.0)
	dino.sprite.flip_h = way.x < 0.0
	dino.sprite.play(SheetFrames.dino_anims(dino.sprite.sprite_frames, way if way.x != 0.0 else Vector2.RIGHT)[1])


static func _face_up(who: Npc) -> void:
	if is_instance_valid(who):
		who.sprite.play(&"idle_up")


static func _view() -> WorldView:
	return (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view") as WorldView


## Seconds from the front of a door to its facade, walking at `speed` (px/s): the fade into the
## dark starts there, as one steps into the doorway.
static func _to_facade(speed: float) -> float:
	return Doors.FRONT_M * PX / speed


## Plays `move` (a coroutine) and marks `token` done at its end (see _finish).
static func _run(move: Callable, token: Dictionary) -> void:
	token["started"] = true
	await move.call()
	token["done"] = true


## Waits for a move started with _run (at most `max_s` seconds; none started: at once).
static func _finish(token: Dictionary, max_s := 4.0) -> void:
	if not token.has("started"):
		return
	var waited := 0.0
	while not token.get("done", false) and waited < max_s:
		await S.wait(0.05)
		waited += 0.05
