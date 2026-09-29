extends RefCounted
## The Forêt's staging helpers (chapter 2: story/foret.gd, foret_camp.gd, foret_fin.gd), on top
## of Stage: what Stage does not do yet (proposed for it). A line that starts a move the moment
## it shows (cue), the camera showing several places in turn (look), a gentle lean (sniffing,
## a nudge of the snout), lying down and getting up, Chloé walking by herself during a scene,
## and a dino of her party the scene can walk anywhere (stand_in).
## Preloaded (no class_name): `const GESTES := preload("res://story/foret_gestes.gd")`.

const S := preload("res://story/story.gd")
## (The actors are untyped: a scene may hand over someone who has just left, already freed; a
## typed parameter would stop the scene right there. Each helper checks is_instance_valid.)
## How fast Chloé walks when a scene moves her (px/s; her own pace is 165).
const CHLOE_WALK := 140.0
## How long a character may take to finish a step before a scene gives up waiting (s).
const HALT_MAX := 3.0

## The camera's moves in a scene, counted: a sweep still going gives way to a newer move.
static var _camera_moves := 0


## A line that starts `action` (a Callable; a coroutine is not waited for) the moment it shows:
## the move goes with its own bubble, without cutting the scene's lines into several boxes.
static func cue(text: String, action: Callable, who := "") -> Dictionary:
	var shown := func() -> String:
		action.call()
		return text
	return {"who": who, "text_fn": shown}


## The camera shows `points` (world px) one after the other, `hold` seconds each, while the
## lines go on; Vector2.INF: back to Chloé. A later move (look, look_back) takes over.
static func look(points: Array, hold := 2.6) -> void:
	_camera_moves += 1
	var mine := _camera_moves
	for i in points.size():
		if i > 0:
			await S.wait(hold)
			if mine != _camera_moves or not in_scene():
				return
		var px: Vector2 = points[i]
		if px == Vector2.INF:
			Stage.look_back(0.0)
		else:
			Stage.look_at(px, 0.0)


## The camera comes back to Chloé (and stops any sweep still going).
static func look_back() -> void:
	_camera_moves += 1
	Stage.look_back(0.0)


static func in_scene() -> bool:
	var chloe := Stage.chloe()
	return chloe != null and chloe.busy


## A gentle lean of the picture sideways towards `toward_px` and back, the head dipping a
## little: sniffing, a nudge of the snout, pointing with the chin; `px` < 0 shies away. Awaitable.
static func lean(actor, toward_px: Vector2, px := 10.0, secs := 0.8) -> void:
	if not is_instance_valid(actor):
		return
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	if not sprite.has_meta(&"stage_rest"):
		sprite.set_meta(&"stage_rest", sprite.position)
	var rest: Vector2 = sprite.get_meta(&"stage_rest")
	var side := signf(toward_px.x - (actor as Node2D).global_position.x)
	if side == 0.0:
		side = 1.0
	var t := sprite.create_tween()
	t.tween_property(sprite, "position", rest + Vector2(side * px, absf(px) * 0.25), secs * 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_interval(secs * 0.2)
	t.tween_property(sprite, "position", rest, secs * 0.4).set_trans(Tween.TRANS_SINE)
	await t.finished


## Lies down (exhausted, curled up, making itself small; `height` 0.9: sits down) and stays so
## until it gets up (stand_up, or Stage.rear to rise tall). `secs` 0: at once. Awaitable.
## Where a dino of the scene (`actor`) stands at Chloé's side: on her right (`side` 1) or left
## (-1), as far as its length asks (its body never over her feet), `dy` px nearer the camera.
static func beside_chloe(actor: Node2D, side := 1.0, dy := 8.0, at_least := 24.0) -> Vector2:
	var chloe := Stage.chloe()
	var sprite := Stage.sprite_of(actor)
	var half := at_least
	if actor is DinoNpc and sprite:
		half = maxf(at_least, DinoSize.length_px((actor as DinoNpc).species, absf(sprite.scale.x)) * 0.5 + 12.0)
	return chloe.global_position + Vector2(side * half, dy)


static func lie_down(actor, secs := 0.8, height := 0.7) -> void:
	if not is_instance_valid(actor):
		return
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	var full := _full_scale(sprite)
	var low := full * Vector2(1.0 + (1.0 - height) * 0.35, height)
	if secs <= 0.0:
		sprite.scale = low
		return
	var t := sprite.create_tween()
	t.tween_property(sprite, "scale", low, secs).set_trans(Tween.TRANS_SINE)
	await t.finished


## Gets up again after lie_down (quietly; Stage.rear rises tall). Awaitable.
static func stand_up(actor, secs := 0.5) -> void:
	if not is_instance_valid(actor):
		return
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	Stage.pose(actor, &"")   # (up from a drawn pose: sitting…)
	var t := sprite.create_tween()
	t.tween_property(sprite, "scale", _full_scale(sprite), secs).set_trans(Tween.TRANS_SINE)
	await t.finished


static func _full_scale(sprite: Node2D) -> Vector2:
	if not sprite.has_meta(&"stage_scale"):
		sprite.set_meta(&"stage_scale", sprite.scale)
	return sprite.get_meta(&"stage_scale")


## Looks here and there: turns towards each of `points` in turn, `every` seconds apart. Awaitable.
static func look_around(actor, points: Array, every := 0.9) -> void:
	for px: Vector2 in points:
		if not is_instance_valid(actor):
			return
		Stage.turn_to(actor, px)
		await S.wait(every)


## Chloé's dino comes to her side (`offset` px from her: it follows her trail, which the scene
## points there); when she walks again, it follows her as always.
static func companion_to_side(offset: Vector2) -> void:
	var chloe := Stage.chloe()
	if chloe:
		chloe.trail = PackedVector2Array([chloe.global_position + offset])


## Chloé walks to `to_px` (world px) on her own feet during a scene (her controls are off):
## her walk and her steps, her dino behind her; she stops against what is in the way. Awaitable.
static func chloe_walk(to_px: Vector2, max_secs := 4.0) -> void:
	var chloe := Stage.chloe()
	if chloe == null:
		return
	var tree := chloe.get_tree()
	var spent := 0.0
	while is_instance_valid(chloe) and chloe.global_position.distance_to(to_px) > 5.0 and spent < max_secs:
		var dir := (to_px - chloe.global_position).normalized()
		chloe.facing = dir
		chloe.velocity = dir * CHLOE_WALK   # (her physics slows it down a little, then moves her)
		await tree.physics_frame
		spent += 1.0 / Engine.physics_ticks_per_second
	if is_instance_valid(chloe):
		chloe.velocity = Vector2.ZERO


## Someone walking (Npc.walk_to, DinoNpc.walk_to, Stage.pace) finishes the step it is taking:
## `pacing` (Stage.pace's token, or {}) is stopped first. Awaitable (HALT_MAX at most).
static func halt(actor, pacing := {}) -> void:
	if not pacing.is_empty():
		Stage.stop_pacing(pacing)
	var spent := 0.0
	# (walk_to lets Chloé through while it walks: its collision layer is 0 until it stops)
	while is_instance_valid(actor) and actor is CollisionObject2D and (actor as CollisionObject2D).collision_layer == 0 and spent < HALT_MAX:
		await S.wait(0.05)
		spent += 0.05


## Waits until `node` is gone (someone leaving, started by a line's cue), `max_s` s at most.
static func until_gone(node, max_s := 6.0) -> void:
	var spent := 0.0
	while is_instance_valid(node) and not (node as Node).is_queued_for_deletion() and spent < max_s:
		await S.wait(0.1)
		spent += 0.1


## Walks `actor` (an Npc or a DinoNpc) through `points` (world px). Awaitable.
static func walk(actor, points: Array, speed := 120.0) -> void:
	for px: Vector2 in points:
		if not is_instance_valid(actor):
			return
		if actor is Npc:
			await (actor as Npc).walk_to(px, "", speed)
		elif actor is DinoNpc:
			await (actor as DinoNpc).walk_to(px, speed)


## Backs away to `to_px` without turning round (a frightened little one coming out of its cage
## « à reculons »): it walks one way and keeps facing the other. Awaitable.
static func back_away(actor, to_px: Vector2, secs := 1.4) -> void:
	if not is_instance_valid(actor) or not actor is DinoNpc:
		return
	actor.sprite.flip_h = to_px.x > actor.global_position.x   # facing away from where it goes
	actor.sprite.play(&"walk")
	actor.sprite.speed_scale = 0.6
	var t: Tween = actor.create_tween()
	t.tween_property(actor, "global_position", to_px, secs).set_trans(Tween.TRANS_SINE)
	await t.finished
	if is_instance_valid(actor):
		actor.sprite.speed_scale = 1.0
		actor.sprite.play(&"idle")


## Someone's colours change in turn (Brac going pale, red, then violet), `each` s per colour,
## then back to normal. Awaitable.
static func colours(actor, tints: Array, each := 0.8) -> void:
	if not is_instance_valid(actor) or not actor is CanvasItem:
		return
	var t: Tween = actor.create_tween()
	for c: Color in tints:
		t.tween_property(actor, "modulate", c, each * 0.5).set_trans(Tween.TRANS_SINE)
		t.tween_interval(each * 0.5)
	t.tween_property(actor, "modulate", Color.WHITE, 0.5)
	await t.finished


# ------------------------------------------------------------------ a dino of Chloé's party

## A dino of Chloé's party as an actor the scene can walk anywhere (the companion itself only
## follows her trail): her lead dino (`d` null, or the lead) takes the form of a DinoNpc in its
## very place, the companion hidden meanwhile; another of her party appears next to her.
## Null when there is none. Give it back with stand_in_back.
static func stand_in(d: Dino = null) -> DinoNpc:
	var w = S.world()
	if w == null or w.get("region") == null:
		return null
	var lead := Game.lead_dino()
	if d == null:
		d = lead
	if d == null:
		return null
	var companion = w.get("companion")
	var for_companion: bool = d == lead and companion != null and companion.visible
	var actor := DinoNpc.new()
	actor.name = "Doublure"
	actor.species_id = d.species().id
	actor.level = d.level   # as big as it is
	actor.position = companion.global_position if for_companion else w.player.global_position + Vector2(38.0, 8.0)
	actor.set_meta(&"for_companion", for_companion)
	w.region.entities.add_child(actor)
	actor.collision_layer = 0   # never in Chloé's way
	if for_companion:
		actor.sprite.flip_h = companion.sprite.flip_h
		companion.visible = false
	else:
		actor.sprite.flip_h = true
		Stage.fade_in(actor, 0.5)
	return actor


## Its cry: the lead's own voice (younger, higher) when it stands in for the companion.
static func stand_in_cry(actor, kind: StringName = &"neutre") -> void:
	if not is_instance_valid(actor):
		return
	var w = S.world()
	if actor.get_meta(&"for_companion", false) and w and w.get("companion"):
		w.companion.cry(kind)
	else:
		actor.cry(kind)


## The stand-in walks back to Chloé's side and gives the companion its place back, or (another
## of her party) walks up to her and fades away. Awaitable.
static func stand_in_back(actor) -> void:
	if not is_instance_valid(actor) or not actor is DinoNpc:
		return
	Stage.stop(actor, null)   # on its feet, the picture as it was
	actor.collision_layer = 0
	var w = S.world()
	var companion = w.get("companion") if w else null
	if actor.get_meta(&"for_companion", false) and companion:
		await actor.walk_to(companion.global_position, 150.0)
		actor.collision_layer = 0
		if is_instance_valid(actor):
			companion.sprite.flip_h = actor.sprite.flip_h
			actor.queue_free()
		companion.visible = companion.dino != null
		return
	if w:
		await actor.walk_to(w.player.global_position + Vector2(30.0, 6.0), 150.0)
	await Stage.fade_out(actor, 0.4, true)
