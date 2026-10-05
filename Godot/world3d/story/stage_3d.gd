class_name Stage3D
extends RefCounted
## Stage's moves played in the 3D version (docs/migration-3d.md, phases 5 to 7): the same names and
## the same signatures as story/stage.gd, so the 37 story files act their scenes out in 3D without a
## line changed. Stage hands each move over to this one when StoryWorld3D is the world playing.
##
## Rules of the 3D staging:
## - a move touches the actor's MODEL (its holder under the body), its animator or the camera, never
##   where its body really stands: the physics and the story's positions stay right, and the actor is
##   put back as it was at the end (_rest / _restore);
## - every position of a scene is in the 2.5D's pixels: places go through ZoneSource.to_3d
##   (StoryWorld3D.to_3d), lengths through PX (48 px = 1 m at the actor's own size);
## - a move that has no meaning in 3D (a picture squashed, a sprite repainted) does nothing rather
##   than fail: a scene never breaks on it.

const PX := ZoneSource.PX
const CRY := &"attaque"
## Degrees the model tips forward on a bow, back on a rear.
const BOW_DEG := 16.0
const REAR_DEG := 18.0
## A 2.5D pose (Outfits.POSES) → the generic move of an AnimSet. A name that is already a clip of
## the model (sleep, eat…) is held as it is.
const POSE_MOVES := {
	&"assis": &"sit", &"accroupi": &"crouch", &"agenouille": &"crouch", &"nage": &"swim_idle",
	&"grimpe": &"climb",
}
## Height above the actor's head a little sign floats at (m), and how it is drawn (as WorldView's).
const EMOTE_ABOVE := 0.35
const EMOTE_RISE := 0.5

## The world it plays in (StoryWorld3D).
var world

var _focus: Node3D          # where the camera looks instead of Chloé (look_at), null: at her
var _wide_distance := 0.0   # the camera's distance before a close_up (0: none taken)


# ------------------------------------------------------------------ the actors

## The 3D actor behind what a scene holds (a StoryActor3D handle, or a 3D node), null for anything
## else (a 2D-only character a scene brought along: its moves do nothing).
func node_of(actor) -> Node3D:
	if actor == null or not is_instance_valid(actor):
		return null
	if actor is StoryActor3D:
		var inner := (actor as StoryActor3D).node
		return inner if is_instance_valid(inner) else null
	return actor as Node3D


## The model of an actor: the holder the moves act on (Player3D's `Model`, a dino's own). Null
## without one.
func model_of(actor) -> Node3D:
	var node := node_of(actor)
	return node.get_node_or_null(^"Model") as Node3D if node else null


## Its animator, to play a clip it has (bow, sit, sleep…). Null without one.
func animator_of(actor) -> CharacterAnimator:
	var node := node_of(actor)
	return node.get(&"animator") as CharacterAnimator if node else null


## Where an actor stands, in metres: a 3D actor's own place, a 2D-only one's converted from pixels.
## Vector3.INF when there is none.
func point_of(actor) -> Vector3:
	var node := node_of(actor)
	if node:
		return node.global_position
	if actor is Node2D and is_instance_valid(actor):
		return world.to_3d((actor as Node2D).global_position)
	return Vector3.INF


## How tall an actor is drawn (m): a dino's own height, else Chloé's.
func height_of(actor) -> float:
	var node := node_of(actor)
	if node == null:
		return Player3D.HEIGHT
	var tall := float(node.get(&"height_m")) if node.get(&"height_m") != null else 0.0
	return tall if tall > 0.0 else Player3D.HEIGHT


# ------------------------------------------------------------------ the moves on the actors

## Turns to look at `px` (world pixels). A dino turns by itself (its own slow look); Chloé's model
## is turned at once, as the 2.5D turns her picture.
func turn_to(actor, px: Vector2) -> void:
	var node := node_of(actor)
	if node == null:
		return
	var to: Vector3 = world.to_3d(px)
	if node.has_method(&"look_toward"):
		node.call(&"look_toward", to)
		return
	var model := model_of(actor)
	var flat := (to - node.global_position).slide(Vector3.UP)
	if model and flat.length() > 0.01:
		model.rotation.y = atan2(flat.x, flat.z)


## A little sign over someone's head: "!" (surprise), "?" (doubt), "♥", "…", "~" — the 2.5D's, as a
## Label3D that rises and fades.
func emote(actor, text: String) -> void:
	var at := point_of(actor)
	if at == Vector3.INF or not is_instance_valid(world.zone):
		return
	var label := Label3D.new()
	label.text = text
	label.font_size = 84
	label.outline_size = 26
	label.modulate = WorldView.EMOTE_COLOURS.get(text, Color(0.26, 0.14, 0.05))
	label.outline_modulate = Color(1.0, 0.95, 0.85)
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 10
	world.zone.add_child(label)
	label.global_position = at + Vector3(0.25, height_of(actor) + EMOTE_ABOVE, 0.0)
	var t := label.create_tween().set_parallel(true)
	t.tween_property(label, "global_position", label.global_position + Vector3(0, EMOTE_RISE, 0), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(1.3)
	t.tween_property(label, "outline_modulate:a", 0.0, 0.5).set_delay(1.3)
	t.chain().tween_callback(label.queue_free)


## Lowers its head (a bow, trust, sadness, sniffing the ground): its own nod when the model has one,
## else the model tips forward and comes back up. Awaitable.
func bow(actor, secs := 0.9) -> void:
	var played := _act(actor, &"nod", secs)
	if played > 0.0:
		await _wait(played)
		return
	var model := model_of(actor)
	if model == null:
		return
	var rest := _rest(model)
	var t := model.create_tween()
	t.tween_property(model, "rotation:x", rest["rotation"].x + deg_to_rad(BOW_DEG), secs * 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_interval(secs * 0.2)
	t.tween_property(model, "rotation:x", rest["rotation"].x, secs * 0.4).set_trans(Tween.TRANS_SINE)
	await t.finished


## Rears up, towering (a roar, a threat, pride): the model tips back and lifts, then comes down.
## Awaitable.
func rear(actor, secs := 0.8) -> void:
	var model := model_of(actor)
	if model == null:
		return
	var rest := _rest(model)
	var lift: Vector3 = rest["position"] + Vector3(0.0, height_of(actor) * 0.08, 0.0)
	var t := model.create_tween()
	t.tween_property(model, "rotation:x", rest["rotation"].x - deg_to_rad(REAR_DEG), secs * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(model, "position", lift, secs * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(secs * 0.3)
	t.tween_property(model, "rotation:x", rest["rotation"].x, secs * 0.35).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(model, "position", rest["position"], secs * 0.35).set_trans(Tween.TRANS_SINE)
	await t.finished


## Little jumps: joy, surprise, impatience (`times` hops of `height` pixels of the 2.5D, 48 px = 1 m).
## Awaitable.
func hop(actor, times := 2, height := 10.0) -> void:
	var model := model_of(actor)
	if model == null:
		return
	var rest := _rest(model)
	var up: float = rest["position"].y + height / PX
	var t := model.create_tween()
	for i in times:
		t.tween_property(model, "position:y", up, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(model, "position:y", rest["position"].y, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished


## Shivers with fear or cold, `secs` seconds (quick small shakes sideways, `amount` pixels of the
## 2.5D). Awaitable.
func tremble(actor, secs := 1.2, amount := 2.5) -> void:
	var model := model_of(actor)
	if model == null:
		return
	var rest := _rest(model)
	var step := amount / PX
	var t := model.create_tween()
	for i in int(secs / 0.08):
		t.tween_property(model, "position:x", rest["position"].x + (step if i % 2 == 0 else -step), 0.04)
		t.tween_property(model, "position:x", rest["position"].x, 0.04)
	await t.finished


## Throws itself at `toward_px` (world pixels) and comes back: a blow, a charge against bars, a
## threat. `strength` 1: a jolt; 2: bursting out. With its cry. Awaitable.
func lunge(actor, toward_px: Vector2, strength := 1.0, with_cry := true) -> void:
	var model := model_of(actor)
	if model == null:
		return
	var rest := _rest(model)
	var dir := _toward(actor, toward_px) * (18.0 / PX) * strength
	if with_cry:
		cry(actor)
	var t := model.create_tween()
	t.tween_property(model, "position", rest["position"] + dir, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void: shake(3.0 * strength, 0.25))
	t.tween_property(model, "position", rest["position"], 0.4).set_trans(Tween.TRANS_SINE)
	await t.finished


## Throws itself at `toward_px` again and again (a caged, maddened dino) until stop(). Returns the
## looping tween (null without a model).
func rage(actor, toward_px: Vector2, every := 1.0) -> Tween:
	var model := model_of(actor)
	if model == null:
		return null
	var rest := _rest(model)
	var dir := _toward(actor, toward_px) * (16.0 / PX)
	var t := model.create_tween().set_loops()
	t.tween_interval(every)
	t.tween_property(model, "position", rest["position"] + dir, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void: shake(2.5, 0.15))
	t.tween_property(model, "position", rest["position"], 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_interval(randf_range(0.3, 0.9))
	return t


## Someone steps back from `from_px`, startled (Chloé before a roar…): it turns that way, and its
## model takes a step back (`px` pixels of the 2.5D) and comes back — its body never moves.
## Awaitable.
func recoil(actor, from_px: Vector2, px := 14.0) -> void:
	var model := model_of(actor)
	if model == null:
		return
	turn_to(actor, from_px)
	var rest := _rest(model)
	var back := -_toward(actor, from_px) * (px / PX)
	var t := model.create_tween()
	t.tween_property(model, "position", rest["position"] + back, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(model, "position", rest["position"], 0.5).set_trans(Tween.TRANS_SINE)
	await t.finished


## Sits down (Outfits.POSES &"assis" in the 2.5D, the model's sit clip here), until pose(actor, &"").
## False when the model has no such clip: nothing changes. Awaitable.
func sit(actor, secs := 0.3) -> bool:
	var animator := animator_of(actor)
	if animator == null or not animator.has_move(&"sit"):
		return false
	var down := _act(actor, &"sit_down", secs)
	if down > 0.0:
		await _wait(down * 0.6)
	return animator.hold(&"sit")


## Holds a pose the model has (POSE_MOVES: &"accroupi" crouching, &"nage" swimming, or a clip's own
## name), for `secs` (0: until pose(actor, &"")). False when it has no such clip: nothing changes.
func pose(actor, pose_name: StringName, secs := 0.0) -> bool:
	var animator := animator_of(actor)
	if animator == null:
		return false
	if pose_name == &"":
		animator.release()
		return true
	var move: StringName = POSE_MOVES.get(pose_name, pose_name)
	if not animator.hold(move):
		return false
	var token := Time.get_ticks_usec()
	var node := node_of(actor)
	node.set_meta(&"pose3d_token", token)
	if secs > 0.0:
		_release_later(node, animator, token, secs)
	return true


## Ends a looping move (rage, tremble…) and puts the model back as it was.
func stop(actor, loop: Tween) -> void:
	if loop and loop.is_valid():
		loop.kill()
	_restore(model_of(actor))
	var animator := animator_of(actor)
	if animator:
		animator.release()


## Its cry (a dino of the scene, the companion): `kind` attaque, neutre, degat, ko.
func cry(actor, kind: StringName = CRY) -> void:
	var node := node_of(actor)
	if node and node.has_method(&"cry"):
		node.call(&"cry", kind)


## Appears (someone stepping out of the mist, of the dark…). Awaitable.
func fade_in(actor, secs := 0.6) -> void:
	await _fade(actor, 1.0, 0.0, secs, false)


## Vanishes (into the mist, the dark…); with `free`, gone for good. Awaitable.
func fade_out(actor, secs := 0.6, free := false) -> void:
	await _fade(actor, 0.0, -1.0, secs, free)


## A glow on someone or something (amber waking up, a Sceau given, veins fading): a light of that
## colour pulses on it, `times` times. Awaitable.
func glow(actor, colour := Color(1.8, 1.45, 0.8), times := 1, secs := 0.7, energy := 2.5) -> void:
	var at := point_of(actor)
	if at == Vector3.INF:
		return
	var hue := colour / maxf(maxf(colour.r, colour.g), maxf(colour.b, 0.001))
	var here: Vector2 = world.to_px(at)
	var light := light_at(here, Color(hue, 1.0))
	if light == null:
		await _wait(secs * times)
		return
	light.position.y += height_of(actor) * 0.6
	var t := light.create_tween()
	for i in times:
		t.tween_property(light, "light_energy", energy, secs * 0.5).set_trans(Tween.TRANS_SINE)
		t.tween_property(light, "light_energy", 0.0, secs * 0.5).set_trans(Tween.TRANS_SINE)
	await t.finished
	light.queue_free()


## A light at `px` (world pixels), a little above the ground, off (energy 0): the caller brightens
## it, then frees it. Null without a zone.
func light_at(px: Vector2, colour: Color, reach := 3.2) -> OmniLight3D:
	if not is_instance_valid(world.zone):
		return null
	var light := OmniLight3D.new()
	light.light_color = colour
	light.light_energy = 0.0
	light.omni_range = reach
	light.shadow_enabled = false
	world.zone.add_child(light)
	var ground: Vector3 = world.to_3d(px)
	light.global_position = ground + Vector3(0.0, 1.1, 0.0)
	return light


# ------------------------------------------------------------------ the camera

## The camera shakes (a blow, a roar, a door of stone…): the view is jolted, the camera itself is
## not moved (the spring arm places it).
func shake(strength := 4.0, secs := 0.3) -> void:
	var camera := _camera()
	if camera == null:
		return
	var amplitude := strength / PX
	var steps := maxi(int(secs / 0.05), 1)
	var t := camera.create_tween()
	for i in steps:
		var left := (1.0 - float(i) / float(steps)) * amplitude
		t.tween_callback(func() -> void:
			camera.h_offset = randf_range(-left, left)
			camera.v_offset = randf_range(-left, left))
		t.tween_interval(0.05)
	t.tween_callback(func() -> void:
		camera.h_offset = 0.0
		camera.v_offset = 0.0)


## The camera leaves Chloé to show `px` (world pixels: someone or something the lines speak of),
## until look_back() or the end of the scene. Awaitable: the time for the camera to get there.
func look_at(px: Vector2, secs := 0.9) -> void:
	var pivot := _pivot()
	if pivot == null:
		await _wait(secs)
		return
	if _focus == null or not is_instance_valid(_focus):
		_focus = Node3D.new()
		_focus.name = "StoryFocus"
		world.zone.add_child(_focus)
	_focus.global_position = world.to_3d(px)
	pivot.set(&"target", _focus)
	await _wait(secs)


## A close-up on something small at `px` (world pixels): the camera glides there and comes down to
## `metres` away, until wide(), look_back() or the end of the scene. Awaitable.
func close_up(px: Vector2, metres := 5.0, secs := 1.4) -> void:
	var pivot := _pivot()
	if pivot:
		if _wide_distance <= 0.0:
			_wide_distance = float(pivot.call(&"distance"))
		pivot.call(&"set_distance", metres, false)
	await look_at(px, secs)


## The camera goes back up to the player's distance (after close_up), wherever it looks.
func wide() -> void:
	var pivot := _pivot()
	if pivot and _wide_distance > 0.0:
		pivot.call(&"set_distance", _wide_distance, false)
	_wide_distance = 0.0


## The camera comes back to Chloé. Awaitable.
func look_back(secs := 0.7) -> void:
	var pivot := _pivot()
	wide()
	if pivot:
		pivot.set(&"target", world.zone.get("player"))
	if is_instance_valid(_focus):
		_focus.queue_free()
	_focus = null
	await _wait(secs)


# ------------------------------------------------------------------ inside

## Where the model rests (position, scale, rotation), remembered the first time so a move can put it
## back exactly as it was.
func _rest(model: Node3D) -> Dictionary:
	if not model.has_meta(&"stage3d_rest"):
		model.set_meta(&"stage3d_rest", {"position": model.position, "scale": model.scale, "rotation": model.rotation})
	return model.get_meta(&"stage3d_rest")


func _restore(model: Node3D) -> void:
	if model == null or not model.has_meta(&"stage3d_rest"):
		return
	var rest: Dictionary = model.get_meta(&"stage3d_rest")
	model.position = rest["position"]
	model.scale = rest["scale"]
	model.rotation.x = rest["rotation"].x
	model.rotation.z = rest["rotation"].z


## The way from an actor to a point of the zone (world pixels), on the ground, in the frame its
## model's position is written in (its body's, which never turns).
func _toward(actor, px: Vector2) -> Vector3:
	var from := point_of(actor)
	if from == Vector3.INF:
		return Vector3.ZERO
	var at: Vector3 = world.to_3d(px)
	var to := (at - from).slide(Vector3.UP)
	return to.normalized() if to.length() > 0.001 else Vector3.ZERO


## Plays a one-off clip of the model over the rest; its length (s), 0 when it has none or when it is
## longer than `at_most` would allow (the move is better mimed then).
func _act(actor, move: StringName, at_most := 0.0) -> float:
	var animator := animator_of(actor)
	if animator == null or not animator.has_move(move):
		return 0.0
	var length: float = animator.act(move)
	return length if at_most <= 0.0 or length <= at_most * 2.5 else 0.0


func _release_later(node: Node, animator: CharacterAnimator, token: int, secs: float) -> void:
	await _wait(secs)
	if is_instance_valid(node) and is_instance_valid(animator) and node.get_meta(&"pose3d_token", -1) == token:
		animator.release()


## Fades an actor's model in or out: `to` is the share of it still seen, `from` where it starts
## (-1: where it is). With `free`, the actor is gone for good.
func _fade(actor, to: float, from: float, secs: float, free: bool) -> void:
	var meshes := _meshes_of(actor)
	if meshes.is_empty():
		await _wait(secs)
		if free:
			_free(actor)
		return
	if from >= 0.0:
		for mesh in meshes:
			mesh.transparency = 1.0 - from
	var t := meshes[0].create_tween().set_parallel(true)
	for mesh in meshes:
		t.tween_property(mesh, "transparency", 1.0 - to, secs)
	await t.finished
	if free:
		_free(actor)


func _meshes_of(actor) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	var model := model_of(actor)
	if model == null:
		return out
	for node in model.find_children("*", "GeometryInstance3D", true, false):
		out.append(node as GeometryInstance3D)
	return out


func _free(actor) -> void:
	var node := node_of(actor)
	if node:
		node.queue_free()
	if actor is StoryActor3D and is_instance_valid(actor):
		(actor as StoryActor3D).queue_free()


func _pivot() -> Node:
	var chloe: Node = world.zone.get("player") if is_instance_valid(world.zone) else null
	return chloe.get(&"pivot") if chloe else null


func _camera() -> Camera3D:
	var pivot := _pivot()
	return pivot.get(&"camera") as Camera3D if pivot else null


func _wait(secs: float) -> void:
	await world.get_tree().create_timer(maxf(secs, 0.0)).timeout
