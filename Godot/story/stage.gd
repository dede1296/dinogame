class_name Stage
## Staging for the story's scenes: what the description bubbles say, acted out on screen (a
## dino throws itself at its bars, cowers, hops for joy; the camera shakes; someone steps
## back; an amber light flares…). Rule of the project: when a scene chains description
## bubbles, the actors act them out, in step with the text (start the move just before or with
## its bubble).
## Actors: Npc, DinoNpc, the Companion (their `sprite`), Chloé (the Player). Plain scenery is
## drawn in batches by the 3D view and cannot move; story props (StoryProp, Obstacle) can.
## The moves change the actor's picture (its sprite's position, scale, colour), never where
## it stands, and put it back as it was: the physics and the story's positions stay right.
## Most helpers start and return at once (the lines go on while they play); those marked
## « awaitable » can be awaited to wait for their end.

const S := preload("res://story/story.gd")
const CRY := &"attaque"


## The picture of an actor (null when there is none).
static func sprite_of(actor) -> Node2D:
	if actor == null or not is_instance_valid(actor):
		return null
	var s = actor.get("sprite")
	return s if s is Node2D else null


## Where the actor's picture rests (remembered the first time, to put it back after a move).
static func _rest(sprite: Node2D) -> Vector2:
	if not sprite.has_meta(&"stage_rest"):
		sprite.set_meta(&"stage_rest", sprite.position)
	return sprite.get_meta(&"stage_rest")


## The camera shakes (a blow, a roar, a door of stone…).
static func shake(strength := 4.0, secs := 0.3) -> void:
	var w = S.world()
	if w and w.get("player"):
		w.player.get_node("Camera").call(&"shake", strength, secs)


## The actor throws itself at `toward_px` (world pixels) and comes back: a blow, a charge
## against bars, a threat. `strength` 1: a jolt; 2: bursting out. With its cry. Awaitable.
static func lunge(actor, toward_px: Vector2, strength := 1.0, with_cry := true) -> void:
	var sprite := sprite_of(actor)
	if sprite == null:
		return
	var rest := _rest(sprite)
	var dir: Vector2 = (toward_px - (actor as Node2D).global_position).normalized() * 18.0 * strength
	if with_cry:
		cry(actor)
	var t := sprite.create_tween()
	t.tween_property(sprite, "position", rest + dir, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void: shake(3.0 * strength, 0.25))
	t.tween_property(sprite, "position", rest, 0.4).set_trans(Tween.TRANS_SINE)
	await t.finished


## Throws itself at `toward_px` again and again (a caged, maddened dino) until stop(). Returns
## the looping tween (null without an actor).
static func rage(actor, toward_px: Vector2, every := 1.0) -> Tween:
	var sprite := sprite_of(actor)
	if sprite == null:
		return null
	var rest := _rest(sprite)
	var dir: Vector2 = (toward_px - (actor as Node2D).global_position).normalized() * 16.0
	var t := sprite.create_tween().set_loops()
	t.tween_interval(every)
	t.tween_property(sprite, "position", rest + dir, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void: shake(2.5, 0.15))
	t.tween_property(sprite, "position", rest, 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_interval(randf_range(0.3, 0.9))
	return t


## Ends a looping move (rage, tremble…) and puts the picture back as it was.
static func stop(actor, loop: Tween) -> void:
	if loop and loop.is_valid():
		loop.kill()
	var sprite := sprite_of(actor)
	if sprite:
		sprite.position = _rest(sprite)
		sprite.scale = sprite.get_meta(&"stage_scale", sprite.scale)
		sprite.rotation = 0.0


## Someone steps back from `from_px`, startled (Chloé before a roar…). Moves the node itself
## (a small step, `px` pixels). Awaitable.
static func recoil(node, from_px: Vector2, px := 14.0) -> void:
	if node == null or not is_instance_valid(node):
		return
	turn_to(node, from_px)
	var back: Vector2 = (node.global_position - from_px).normalized() * px
	var t: Tween = node.create_tween()
	t.tween_property(node, "global_position", node.global_position + back, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished


## Little jumps: joy, surprise, impatience (`times` hops of `height` pixels). Awaitable.
static func hop(actor, times := 2, height := 10.0) -> void:
	var sprite := sprite_of(actor)
	if sprite == null:
		return
	var rest := _rest(sprite)
	var t := sprite.create_tween()
	for i in times:
		t.tween_property(sprite, "position:y", rest.y - height, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(sprite, "position:y", rest.y, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished


## Shivers with fear or cold, `secs` seconds (quick small shakes sideways). Awaitable.
static func tremble(actor, secs := 1.2, amount := 2.5) -> void:
	var sprite := sprite_of(actor)
	if sprite == null:
		return
	var rest := _rest(sprite)
	var t := sprite.create_tween()
	for i in int(secs / 0.08):
		t.tween_property(sprite, "position:x", rest.x + (amount if i % 2 == 0 else -amount), 0.04)
		t.tween_property(sprite, "position:x", rest.x, 0.04)
	await t.finished


## Lowers its head (a bow, trust, sadness, sniffing the ground): a slow crouch and back. Awaitable.
static func bow(actor, secs := 0.9) -> void:
	var sprite := sprite_of(actor)
	if sprite == null:
		return
	if not sprite.has_meta(&"stage_scale"):
		sprite.set_meta(&"stage_scale", sprite.scale)
	var full: Vector2 = sprite.get_meta(&"stage_scale")
	var t := sprite.create_tween()
	t.tween_property(sprite, "scale", full * Vector2(1.04, 0.9), secs * 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_interval(secs * 0.2)
	t.tween_property(sprite, "scale", full, secs * 0.4).set_trans(Tween.TRANS_SINE)
	await t.finished


## Rears up, towering (a roar, a threat, pride): a stretch up and back. Awaitable.
static func rear(actor, secs := 0.8) -> void:
	var sprite := sprite_of(actor)
	if sprite == null:
		return
	if not sprite.has_meta(&"stage_scale"):
		sprite.set_meta(&"stage_scale", sprite.scale)
	var full: Vector2 = sprite.get_meta(&"stage_scale")
	var t := sprite.create_tween()
	t.tween_property(sprite, "scale", full * Vector2(0.96, 1.12), secs * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(secs * 0.3)
	t.tween_property(sprite, "scale", full, secs * 0.35).set_trans(Tween.TRANS_SINE)
	await t.finished


## Its cry (a dino of the scene, the companion): `kind` attaque, neutre, degat, ko.
static func cry(actor, kind: StringName = CRY) -> void:
	if actor and is_instance_valid(actor) and actor.has_method(&"cry"):
		actor.call(&"cry", kind)


## A little sign over someone's head: "!" (surprise), "?" (doubt), "♥", "…", "~".
static func emote(actor, text: String) -> void:
	var view := (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view") as WorldView
	if view and actor and is_instance_valid(actor):
		view.emote(actor, text)


## Turns to look at `px` (an Npc, a DinoNpc, the companion or Chloé).
static func turn_to(actor, px: Vector2) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if actor is Player:
		(actor as Player).face_towards(px)
	elif actor is Npc and (actor as Npc).walking:
		return   # (it turns where it goes)
	elif actor.has_method(&"face"):
		actor.call(&"face", px)
	else:
		var sprite := sprite_of(actor)
		if sprite is AnimatedSprite2D:
			(sprite as AnimatedSprite2D).flip_h = px.x < (actor as Node2D).global_position.x


## Appears (someone stepping out of the mist, of the dark…). Awaitable.
static func fade_in(actor, secs := 0.6) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	actor.modulate.a = 0.0
	var t: Tween = actor.create_tween()
	t.tween_property(actor, "modulate:a", 1.0, secs)
	await t.finished


## Vanishes (into the mist, the dark…); with `free`, gone for good. Awaitable.
static func fade_out(actor, secs := 0.6, free := false) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var t: Tween = actor.create_tween()
	t.tween_property(actor, "modulate:a", 0.0, secs)
	await t.finished
	if free and is_instance_valid(actor):
		actor.queue_free()


## A glow on someone or something (amber waking up, a Sceau given, veins fading): its colour
## brightens to `colour` and back, `times` times, and a light of that colour pulses on it in
## the 3D view (the billboards clamp colours at white: without the light, a glow hardly shows).
## Awaitable.
static func glow(actor, colour := Color(1.8, 1.45, 0.8), times := 1, secs := 0.7, energy := 2.5) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var hue := colour / maxf(maxf(colour.r, colour.g), maxf(colour.b, 0.001))
	var light: OmniLight3D = light_at((actor as Node2D).global_position, Color(hue, 1.0)) if actor is Node2D else null
	var t: Tween = actor.create_tween().set_parallel(false)
	for i in times:
		t.tween_property(actor, "modulate", colour, secs * 0.5).set_trans(Tween.TRANS_SINE)
		t.tween_property(actor, "modulate", Color.WHITE, secs * 0.5).set_trans(Tween.TRANS_SINE)
	if light:
		var l := light.create_tween()
		for i in times:
			l.tween_property(light, "light_energy", energy, secs * 0.5).set_trans(Tween.TRANS_SINE)
			l.tween_property(light, "light_energy", 0.0, secs * 0.5).set_trans(Tween.TRANS_SINE)
		l.tween_callback(light.queue_free)
	await t.finished


## A light of the 3D view at `px` (world pixels), a little above the ground, off (energy 0):
## the caller brightens it, then frees it. Null without the view.
static func light_at(px: Vector2, colour: Color, reach := 3.2) -> OmniLight3D:
	var view := _view()
	if view == null or view.heights == null:
		return null
	var light := OmniLight3D.new()
	light.light_color = colour
	light.light_energy = 0.0
	light.omni_range = reach
	light.shadow_enabled = false
	view.add_child(light)
	light.position = view.heights.to_3d(px) + Vector3(0, 1.1, 0.5)
	return light


## The whole screen flashes (a burst of amber light, lightning, a great revelation). Awaitable.
static func flash(colour := Color(1.0, 0.85, 0.45, 0.8), secs := 0.6) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var layer := CanvasLayer.new()
	layer.layer = 40
	var rect := ColorRect.new()
	rect.color = colour
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	tree.root.add_child(layer)
	var t := rect.create_tween()
	t.tween_property(rect, "color:a", 0.0, secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t.finished
	layer.queue_free()


## Chloé's lead dino runs up to `px`, does its bit (a lunge, its cry) and comes back to her. Awaitable.
static func companion_to(px: Vector2) -> void:
	var w = S.world()
	var companion = w.get("companion") if w else null
	if companion:
		await companion.perform_at(px)


## Chloé's lead dino jumps for joy.
static func companion_joy() -> void:
	var w = S.world()
	var companion = w.get("companion") if w else null
	if companion:
		companion.rejoice()


## The camera leaves Chloé to show `px` (world pixels: someone or something the lines speak
## of — the henchmen by the tents, Brac by the fire, a cage), until look_back() or the end of
## the scene (Story.lock(false)). Awaitable: the time for the camera to get there.
static func look_at(px: Vector2, secs := 0.9) -> void:
	var view := _view()
	if view:
		view.focus_px = px
	await S.wait(secs)


## Shows an actor (look_at its feet).
static func look_at_actor(actor, secs := 0.9) -> void:
	if actor and is_instance_valid(actor):
		await look_at(actor.global_position, secs)


## The camera comes back to Chloé. Awaitable.
static func look_back(secs := 0.7) -> void:
	var view := _view()
	if view:
		view.focus_px = Vector2.INF
	await S.wait(secs)


## Someone walks back and forth between `a_px` and `b_px` (henchmen on guard « pacing up and
## down », a worried character…), until stop_pacing(token). Works for an Npc or a DinoNpc.
static func pace(actor, a_px: Vector2, b_px: Vector2, speed := 55.0) -> Dictionary:
	var token := {"on": true}
	_pace(actor, a_px, b_px, speed, token)
	return token


static func _pace(actor, a_px: Vector2, b_px: Vector2, speed: float, token: Dictionary) -> void:
	while token["on"] and is_instance_valid(actor) and actor.is_inside_tree():
		for to: Vector2 in [b_px, a_px]:
			if not token["on"] or not is_instance_valid(actor):
				return
			if actor is Npc:
				await (actor as Npc).walk_to(to, "", speed)
			elif actor is DinoNpc:
				await (actor as DinoNpc).walk_to(to, speed)
			else:
				return
			await S.wait(randf_range(0.2, 0.8))


static func stop_pacing(token: Dictionary) -> void:
	token["on"] = false


static func _view() -> WorldView:
	return (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view") as WorldView


## Chloé herself (for recoil, turn_to, emote…).
static func chloe() -> Player:
	var w = S.world()
	return w.player if w and w.get("player") else null
