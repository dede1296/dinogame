extends RefCounted
## Chapter 3's staging (docs: story/stage.gd): the lines of the Marais and of its temple acted
## out on screen — the Voix du Marais singing, Écho walking up to his mother, the young
## Baryonyx sinking the vest… — and a few helpers the three files of the chapter share
## (story/marais.gd, marais_suite.gd, marais_temple.gd preload this file as `Act`): a line whose
## move plays with its bubble (cue), a slow camera travel (pan), the lead dino leaving
## Chloé's side (walk_lead / lead_back), a dino brought on for a scene (stand_in), splashes
## and sparks (burst), an item's picture (pop), something beating (heartbeat), a lean (lean).
## Candidates for story/stage.gd. The moves change pictures and places, never the story's flags.

const S := preload("res://story/story.gd")
## Drops of water, sparks of amber, the amber glow (of the Voix's island, of a Heart).
const SPLASH: Array[Color] = [Color(0.86, 0.95, 1.0), Color(0.62, 0.82, 0.92), Color(1.0, 1.0, 1.0)]
const SPARKS: Array[Color] = [Color(1.0, 0.82, 0.38), Color(1.0, 0.94, 0.66), Color(0.96, 0.62, 0.18)]
const AMBER_GLOW := Color(1.7, 1.4, 0.8)
## A splash on water is lifted this high (m): the water is dug below the ground (HeightMap).
const ON_WATER := 0.6
## How many directions way_from tries around someone; how far from any scenery it stops (px).
const WAY_DIRECTIONS := 16
const PROP_ROOM := 34.0


# ------------------------------------------------------------------ the Voix, acted out (story/marais.gd)

## The Voix sings a note: she lifts her crest, a « ♪ » over her, her island's amber lights up
## (her glow, a few sparks); `cry_db`: her call (none under -60 dB).
static func sing(singer: Node, cry_db := -8.0, pitch := Marais.OLD_PITCH) -> void:
	if not is_instance_valid(singer):
		return
	if cry_db > -60.0:
		Marais.cry("hadrosaure", "neutre", cry_db, pitch)
	Stage.emote(singer, "♪")
	Stage.glow(singer, AMBER_GLOW, 1, 1.4)
	burst((singer as Node2D).global_position, SPARKS, 8, 0.4, 1.4)
	await Stage.rear(singer, 1.2)


## She sings on (a note every few seconds) while `song["on"]`.
static func keep_singing(singer: Node, song: Dictionary) -> void:
	song["on"] = true
	while song["on"] and is_instance_valid(singer):
		sing(singer, -14.0)
		await S.wait(3.2)


## A little one's note (Écho): head up, a « ♪ », his call high and trembling.
static func little_note(little: Node) -> void:
	if not is_instance_valid(little):
		return
	Marais.cry("hadrosaure", "neutre", -10.0, 1.25)
	Stage.emote(little, "♪")
	await Stage.rear(little, 0.9)
	Stage.tremble(little, 0.9, 1.2)


## The young Baryonyx sinks the vest and watches it come back up, again and again.
static func dunk(thief: Node, times: int) -> void:
	for i in times:
		if not is_instance_valid(thief):
			return
		await Stage.bow(thief, 0.7)
		if not is_instance_valid(thief):
			return
		burst((thief as Node2D).global_position, SPLASH, 10, 0.2, 0.4)
		await S.wait(0.45)
	Stage.hop(thief, 1, 8.0)


## Écho for the scene: Chloé's lead dino when he is it, else brought on at her side (a stand-in
## that goes away with echo_off_stage).
static func echo_on_stage(echo: Dino) -> Node2D:
	var w = S.world()
	if Game.lead_dino() == echo and lead() != null:
		return w.companion
	var at := S.ground_near(w.player.global_position + Vector2(-46.0, 26.0), 2)
	var little := stand_in(echo.build[&"head"], at, "EchoScene")
	if little:
		Stage.turn_to(little, w.player.global_position + Vector2(0.0, -60.0))
		Stage.fade_in(little, 0.5)
	return little


## He walks up to his mother (between Chloé and her), faces her, and sings his little note.
static func echo_sings(little: Node2D, spot: Vector2, her_at: Vector2) -> void:
	if not is_instance_valid(little):
		return
	var to := spot
	if not clear_way(little.global_position, to):   # (never into the water: a step nearer)
		to = little.global_position.lerp(spot, 0.5)
		if not clear_way(little.global_position, to):
			to = little.global_position
	if little is Companion:
		await walk_lead(to, 80.0)
	else:
		await (little as DinoNpc).walk_to(to, 80.0)
	if not is_instance_valid(little):
		return
	Stage.turn_to(little, her_at)
	little_note(little)


## He trembles; she lowers her head to him and hums a lullaby, low, again and again.
static func lullaby(singer: Node, little: Node2D) -> void:
	if is_instance_valid(little):
		Stage.tremble(little, 2.8, 2.0)
		if is_instance_valid(singer):
			Stage.turn_to(singer, little.global_position)
	await S.wait(0.5)
	if not is_instance_valid(singer):
		return
	Stage.bow(singer, 2.6)
	for i in 2:
		Marais.cry("hadrosaure", "neutre", -18.0, Marais.OLD_PITCH)
		Stage.emote(singer, "♪")
		await S.wait(1.4)


## She lays her crest against his, and stays so: both lean in, warm light, hearts.
static func crest_to_crest(singer: Node, little: Node2D) -> void:
	if not is_instance_valid(singer) or not is_instance_valid(little):
		return
	Stage.turn_to(singer, little.global_position)
	Stage.turn_to(little, (singer as Node2D).global_position)
	lean(singer, little.global_position, 12.0, 3.2)
	lean(little, (singer as Node2D).global_position, 8.0, 3.2)
	Stage.glow(singer, Color(1.35, 1.2, 0.95), 1, 2.6)
	Stage.glow(little, Color(1.35, 1.2, 0.95), 1, 2.6)
	await S.wait(0.9)
	if is_instance_valid(little):
		Stage.emote(little, "♥")


## She pushes him gently back to Chloé with her muzzle; he goes (the lead dino to its place).
static func nudged_back(singer: Node, little: Node2D) -> void:
	if not is_instance_valid(little):
		return
	if is_instance_valid(singer):
		await Stage.lunge(singer, little.global_position, 0.6, false)
	if little is Companion:
		lead_back()
	elif is_instance_valid(little):
		var chloe_at: Vector2 = Stage.chloe().global_position
		await (little as DinoNpc).walk_to(S.ground_near(chloe_at + Vector2(-46.0, 20.0), 2), 70.0)
		if is_instance_valid(little):
			Stage.turn_to(little, chloe_at)
			Stage.hop(little, 1, 8.0)


## Écho's part is over: the lead dino follows Chloé again, a stand-in fades away.
static func echo_off_stage(little: Node2D) -> void:
	if little is Companion:
		lead_back()
	elif is_instance_valid(little):
		Stage.fade_out(little, 0.8, true)


## Her head under the water lilies (a splash), then the copper tube dropped at Chloé's feet.
static func fishes_tube(singer: Node) -> void:
	if not is_instance_valid(singer):
		return
	Stage.bow(singer, 1.4)
	await S.wait(0.5)
	if not is_instance_valid(singer):
		return
	burst((singer as Node2D).global_position, SPLASH, 14, 0.3, 0.6)
	await S.wait(1.0)
	if is_instance_valid(singer):
		Stage.lunge(singer, Stage.chloe().global_position, 0.7, false)


## She stretches her muzzle to Chloé and sniffs, long.
static func sniffs(singer: Node, secs: float) -> void:
	if not is_instance_valid(singer):
		return
	await lean(singer, Stage.chloe().global_position, 12.0, secs)


## A low note, then she looks behind Chloé, one side then the other: someone is missing.
static func looks_for_him(singer: Node) -> void:
	if not is_instance_valid(singer):
		return
	sing(singer, -16.0)
	await S.wait(1.4)
	var chloe_at: Vector2 = Stage.chloe().global_position
	for side: float in [-1.0, 1.0]:
		if not is_instance_valid(singer):
			return
		Stage.turn_to(singer, chloe_at + Vector2(side * 140.0, 60.0))
		await S.wait(0.7)
	if is_instance_valid(singer):
		Stage.emote(singer, "?")
		Stage.turn_to(singer, chloe_at)


## Chloé's lead dino comes a few steps nearer, shy; she breathes on it, softly; it's a yes.
static func shy_hello(singer: Node) -> void:
	var c := lead()
	if c == null or not is_instance_valid(singer):
		return
	var her_at: Vector2 = (singer as Node2D).global_position
	await walk_lead(c.global_position.lerp(her_at, 0.4), 60.0)
	Stage.bow(c, 1.0)
	await S.wait(0.7)
	if not is_instance_valid(singer):
		return
	await Stage.lunge(singer, c.global_position, 0.5, false)
	Stage.emote(c, "♥")
	Stage.hop(c, 1, 6.0)


# ------------------------------------------------------------------ staging helpers
# (Used by the three files of chapter 3; to move into story/stage.gd one day.)

## A line of a scene whose `action` plays the moment it shows (its move in step with its
## bubble, without cutting the scene's lines in several say()): Dialogue's « text_fn ».
static func cue(line: Dictionary, action: Callable) -> Dictionary:
	var text: String = line["text"]
	var step := {"text_fn": func() -> String:
		action.call()
		return text}
	if line.has("who"):
		step["who"] = line["who"]
	return step


## The camera travels slowly from where it looks to `to_px` (a song crossing the marsh, a far
## place spoken of). Awaitable; stops (false) as soon as something else moves the camera
## (Stage.look_at / look_back, the end of the scene).
static func pan(to_px: Vector2, secs := 2.0) -> bool:
	var view := _view()
	var w = S.world()
	if view == null or w == null:
		return false
	var from: Vector2 = view.focus_px if view.focus_px != Vector2.INF else (w.player as Node2D).global_position
	var tree := view.get_tree()
	var last := from
	var t := 0.0
	view.focus_px = from
	while t < secs:
		await tree.process_frame
		if not is_instance_valid(view) or view.focus_px != last:
			return false
		t += view.get_process_delta_time()
		last = to_px if t >= secs else from.lerp(to_px, smoothstep(0.0, 1.0, t / secs))
		view.focus_px = last
	return true


## The camera travels from one place to the next (a hall shown from side to side), `hold`
## seconds on each; it stops if something else moves the camera meanwhile. Awaitable.
static func tour(places: Array, secs_each := 1.4, hold := 0.6) -> void:
	for place: Vector2 in places:
		if not await pan(place, secs_each):
			return
		await S.wait(hold)
		var view := _view()
		if view == null or view.focus_px != place:
			return


## Chloé's lead dino at her side (null when there is none, or when she rides or swims on it).
static func lead() -> Companion:
	var w = S.world()
	var c = w.get("companion") if w else null
	if c is Companion and (c as Companion).visible and (c as Companion).dino != null and not (c as Companion).carrying():
		return c
	return null


## Chloé's lead dino leaves her side and walks to `px` (to sniff someone, to sing to its
## mother…), and waits there until lead_back(). Awaitable: the time to get there.
static func walk_lead(px: Vector2, speed := 110.0) -> void:
	var c := lead()
	if c == null:
		return
	lead_back()
	c.set_physics_process(false)   # (no longer following Chloé's trail)
	var to: Vector2 = px - c.global_position
	if absf(to.x) > 1.0:
		c.sprite.flip_h = to.x < 0.0
	var anims: Array = SheetFrames.dino_anims(c.sprite.sprite_frames, to)
	c.sprite.play(anims[0])
	var secs := to.length() / speed
	var t := c.create_tween()
	t.tween_property(c, "global_position", px, secs)
	t.tween_callback(c.sprite.play.bind(anims[1]))
	c.set_meta(&"stage_walk", t)
	await S.wait(secs)


## …and back to following Chloé (it walks back to her by itself).
static func lead_back() -> void:
	var w = S.world()
	var c = w.get("companion") if w else null
	if not c is Companion or not is_instance_valid(c):
		return
	if c.has_meta(&"stage_walk"):
		var t = c.get_meta(&"stage_walk")
		if t is Tween and (t as Tween).is_valid():
			(t as Tween).kill()
		c.remove_meta(&"stage_walk")
	c.set_physics_process(true)


## A dino brought on for a scene (a party dino that is not the lead, a trainer's dino let
## out of its crate): standing at `at_px`, not to be talked to; Stage.fade_out(…, true) ends it.
static func stand_in(species_id: StringName, at_px: Vector2, node_name: String, corrupted := false) -> DinoNpc:
	var w = S.world()
	if w == null or w.get("region") == null or not SpeciesDB.PATHS.has(species_id):
		return null
	var d := DinoNpc.new()
	d.name = node_name
	d.species_id = species_id
	d.size_scale = 1.0
	d.corrupted = corrupted
	d.position = at_px
	d.modulate.a = 0.0
	w.region.entities.add_child(d)
	return d


## A burst of little bits at `px` (world pixels): drops of water, sparks of amber (WorldView.burst).
static func burst(px: Vector2, colours: Array[Color], amount := 14, height := 0.3, spread := 0.5) -> void:
	var view := _view()
	if view:
		view.burst(px, colours, amount, height, spread)


## An item's picture rising and fading at `px` (a vest brought back, a Sceau detached…).
static func pop(px: Vector2, item_id: String, height := 0.3) -> void:
	var view := _view()
	if view:
		view.pop_up(px, ItemsDB.icon(item_id), height)


## Something that beats (an amber Heart in Chloé's bag, on an altar): double amber pulses.
static func heartbeat(actor: CanvasItem, beats := 3, every := 1.0) -> void:
	for i in beats:
		for pulse in 2:
			if actor == null or not is_instance_valid(actor):
				return
			await Stage.glow(actor, AMBER_GLOW, 1, 0.28)
		await S.wait(maxf(0.1, every - 0.56))


## Sinks into the ground, slowly (a stone door sliding down, a giant going back to the bottom
## of its pool): its picture goes down by its own height (the ground hides it bit by bit);
## with `free`, gone for good at the end. Awaitable.
static func sink(actor: Node, secs := 2.0, free := false, fade := false) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	var rest := Stage._rest(sprite)
	var height := 60.0
	if sprite is Sprite2D and (sprite as Sprite2D).texture:
		height = (sprite as Sprite2D).texture.get_height() * absf(sprite.scale.y)
	elif sprite is AnimatedSprite2D and (sprite as AnimatedSprite2D).sprite_frames:
		var anim := sprite as AnimatedSprite2D
		var tex := anim.sprite_frames.get_frame_texture(anim.animation, 0)
		if tex:
			height = tex.get_height() * absf(sprite.scale.y)
	var t := sprite.create_tween().set_parallel(true)
	t.tween_property(sprite, "position:y", rest.y + height, secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if fade:
		t.tween_property(actor, "modulate:a", 0.0, secs).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	if free and is_instance_valid(actor):
		actor.queue_free()


## Leans towards `toward_px` (sniffing, nuzzling, crest against crest) and stays so `secs`
## seconds, then back. Awaitable.
static func lean(actor: Node, toward_px: Vector2, px: float, secs: float) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	var rest := Stage._rest(sprite)
	var dir: Vector2 = (toward_px - (actor as Node2D).global_position).normalized() * px
	var t := sprite.create_tween()
	t.tween_property(sprite, "position", rest + dir, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_interval(maxf(0.0, secs - 0.9))
	t.tween_property(sprite, "position", rest, 0.4).set_trans(Tween.TRANS_SINE)
	await t.finished


## Ground someone can stand on at `px`: open ground or a pontoon (its planks are painted
## « path »), level with `level_px` (Chloé, by default): not water, not a cliff above her.
static func standable(px: Vector2, level_px := Vector2.INF) -> bool:
	var w = S.world()
	if w == null or w.get("region") == null:
		return true
	var region: Region = w.region
	var ref: Vector2 = level_px if level_px != Vector2.INF else (w.player as Node2D).global_position
	var c := Vector2i((px / S.CELL).floor())
	var data := region.terrain.get_cell_tile_data(c)
	if data == null or not String(data.get_custom_data("terrain")) in S.OPEN_GROUND:
		return false
	return absf(region.tile_height(c) - region.tile_height(Vector2i((ref / S.CELL).floor()))) <= 0.3


## A straight walk from `a` to `b` stays on such ground all the way (no wading, no cliff).
static func clear_way(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / 12.0))
	for i in steps + 1:
		if not standable(a.lerp(b, float(i) / steps), a):
			return false
	return true


## A place `min_tiles` to `max_tiles` from `from_px` that can be walked to in a straight line
## from there (the same pontoon, the same island), as far as possible and as near as possible
## to the direction `prefer`; Vector2.INF when there is none (someone arriving or leaving by it
## never walks on the water).
static func way_from(from_px: Vector2, prefer: Vector2, min_tiles := 2.0, max_tiles := 5.0) -> Vector2:
	var best := Vector2.INF
	var best_score := -INF
	var wanted := prefer.normalized() if prefer != Vector2.ZERO else Vector2.RIGHT
	for k in WAY_DIRECTIONS:
		var dir := Vector2.RIGHT.rotated(TAU * k / WAY_DIRECTIONS)
		var d := max_tiles
		while d >= min_tiles:
			var to := from_px + dir * d * S.CELL
			if clear_way(from_px, to) and free_of_props(to):
				var score := dir.dot(wanted) * 2.0 + d / max_tiles
				if score > best_score:
					best_score = score
					best = to
				break
			d -= 0.5
	return best


## No scenery stands at `px` (a lamp post, a crate…): someone stopping there is seen.
static func free_of_props(px: Vector2, radius := PROP_ROOM) -> bool:
	var w = S.world()
	if w == null or w.get("region") == null:
		return true
	for n in w.region.entities.get_children():
		if n is Prop and (n as Node2D).global_position.distance_to(px) < radius:
			return false
	return true


## The open water nearest to `px`, within `max_tiles` (a splash, something diving); `px` when none.
static func water_near(px: Vector2, max_tiles := 4) -> Vector2:
	var w = S.world()
	if w == null or w.get("region") == null:
		return px
	var region: Region = w.region
	var start := Vector2i((px / S.CELL).floor())
	for r in max_tiles + 1:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var at := (Vector2(start + Vector2i(dx, dy)) + Vector2(0.5, 0.5)) * S.CELL
				if region.surface_at(at) == &"water":
					return at
	return px


static func _view() -> WorldView:
	return (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view") as WorldView
