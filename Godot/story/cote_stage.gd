extends RefCounted
## Chapter 5's staging (the rules are in story/stage.gd): the Côte's lines acted out — waves
## and splashes, bubbles under the sea, a flyer crossing the sky (a Pteranodon, Moustique), the
## boat without a lantern gliding over the dark water, a Cœur beating with the swell — and what
## the chapter's files share: what Chloé still needs to dive (dive_step), the mask, Maïa's dinos,
## a dino brought on for a scene. Preloaded as `CS` by story/cote*.gd (no class_name).
## The moves change pictures and places, never the story's flags.

const S := preload("res://story/story.gd")
const D := preload("res://story/desert.gd")
const Act := preload("res://story/marais_stage.gd")
const MASK_ITEM := "masque_plongee"
const MASK_FLAG := &"masque_plongee"
const DIVE := &"plongee"
## Drops of sea water, foam, bubbles rising in the deep; the Cœurs' warm light; the deep's blue.
const SEA_BITS: Array[Color] = [Color(0.84, 0.96, 1.0), Color(0.55, 0.8, 0.9), Color(1.0, 1.0, 1.0)]
const BUBBLES: Array[Color] = [Color(0.8, 0.95, 1.0), Color(0.62, 0.86, 0.98), Color(0.95, 1.0, 1.0)]
const HEART_GLOW := Color(1.8, 1.45, 0.8)
const DEEP_GLOW := Color(0.7, 1.25, 1.8)
## How high a flyer passes over the ground (px of its picture's lift), and how much it bobs.
const FLY_HEIGHT := 70.0
const WINGBEATS := 4   # (frames of a flight sheet, dinos/<species>_vol.png)
const FLY_BOB := 6.0
## Someone standing in a boat: the deck, above the water sheet (m).
const BOAT_DECK_M := 0.2


# ------------------------------------------------------------------ lines and timing

## A line whose move starts the moment it shows (Desert._cue: deferred, never holds the line).
static func cue(line: Dictionary, action: Callable) -> Dictionary:
	return D._cue(line, action)


## Does `action` in `secs` seconds, without holding the scene.
static func later(secs: float, action: Callable) -> void:
	await S.wait(secs)
	action.call()


# ------------------------------------------------------------------ Chloé and her lead dino

static func lead() -> Companion:
	return D._companion()


static func lead_walk(px: Vector2, speed := 70.0) -> void:
	await D._companion_walk(px, speed)


static func lead_back() -> void:
	D._companion_back()


static func chloe_walk(px: Vector2, speed := 100.0, max_secs := 2.5) -> void:
	await D._chloe_walk(px, speed, max_secs)


## Chloé steps round to stand beside `who` (not in front, where the camera sees only her back).
static func step_aside(who: Node, gap := 66.0, prefer := 0.0) -> void:
	await D._step_aside(who, gap, prefer)


static func reach(actor: Node, px: Vector2, dist := 10.0, secs := 0.8) -> void:
	await D._reach(actor, px, dist, secs)


static func crouch(actor: Node, depth := 0.18, secs := 0.9) -> void:
	await D._crouch(actor, depth, secs)


## Sits down until get_up: the person's sitting picture, or a squash of `depth`. Awaitable.
static func sit(actor: Node, depth := 0.26, secs := 0.5) -> void:
	await D._sit(actor, depth, secs)


static func get_up(actor: Node, secs := 0.9) -> void:
	Stage.pose(actor, &"")   # (back on her feet from a drawn crouch)
	await D._get_up(actor, secs)


## Chloé kneels until get_up: by a net, a nest, a box. Her crouching picture (Outfits), after a
## quick squash; a squash that stays when it is not drawn.
static func kneel() -> void:
	var chloe := Stage.chloe()
	var drawn := Outfits.has_pose(chloe, &"accroupi")
	await D._crouch(chloe, 0.22, 0.25 if drawn else 0.6)
	if drawn and Stage.pose(chloe, &"accroupi"):
		# (back to her full size, the crouching picture kept: D._get_up would release the pose)
		var sprite := Stage.sprite_of(chloe)
		if sprite:
			var t := sprite.create_tween()
			t.tween_property(sprite, "scale", D._full_of(sprite), 0.15).set_trans(Tween.TRANS_SINE)
			await t.finished


# ------------------------------------------------------------------ water and light

## A splash at `px` (sea water, foam).
static func splash(px: Vector2, amount := 14, height := Act.ON_WATER, spread := 0.5) -> void:
	Act.burst(px, SEA_BITS, amount, height, spread)


## Bubbles rising at `px` (under the sea: a breath, something huge passing).
static func bubbles(px: Vector2, amount := 12, height := 0.8) -> void:
	Act.burst(px, BUBBLES, amount, height, 0.25)


## Amber sparks at `px` (a Cœur waking up).
static func sparkle(px: Vector2, height := 0.7, amount := 16, spread := 0.3) -> void:
	D._sparkle(px, height, amount, spread)


## The Cœurs in Chloé's bag beat: a warm glow on her, sparks at her side, `beats` times.
static func hearts_beat(beats := 2, every := 1.1) -> void:
	var chloe := Stage.chloe()
	if chloe == null:
		return
	Stage.glow(chloe, HEART_GLOW, beats, every)
	for i in beats:
		sparkle(chloe.global_position + Vector2(8.0, 0.0), 0.6, 10, 0.2)
		await S.wait(every)


## A light of the 3D view pulsing `times` times at `px` (the reef's heart, black amber in its
## crates, an altar waking up), then gone. Not awaited.
static func pulse(px: Vector2, colour: Color, times := 3, secs := 1.4, energy := 3.0, reach := 5.0) -> void:
	var light := Stage.light_at(px, colour, reach)
	if light == null:
		return
	var t := light.create_tween()
	for i in times:
		t.tween_property(light, "light_energy", energy, secs * 0.5).set_trans(Tween.TRANS_SINE)
		t.tween_property(light, "light_energy", energy * 0.08, secs * 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(light, "light_energy", 0.0, 0.4)
	t.tween_callback(light.queue_free)


## The camera travels slowly to `px` (Act.pan); false if something else moved it meanwhile.
static func pan(px: Vector2, secs := 2.0) -> bool:
	return await Act.pan(px, secs)


# ------------------------------------------------------------------ actors brought on

## A dino only a scene needs (Nessie in the net, Moustique, the hatchlings…), invisible at first
## (Stage.fade_in shows it); `level`: a young one's size; `talk`: an event to talk to it.
static func stand_in(species_id: StringName, at_px: Vector2, node_name: String, level := 0, size := 1.0, talk := &"") -> DinoNpc:
	var w = S.world()
	if w == null or w.get("region") == null or not SpeciesDB.PATHS.has(species_id):
		return null
	var d := DinoNpc.new()
	d.name = node_name
	d.species_id = species_id
	d.level = level
	d.size_scale = size
	d.event = talk
	d.position = at_px
	d.modulate.a = 0.0
	w.region.entities.add_child(d)
	d.collision_layer = 0
	if d.species and d.species.family == &"marine":
		afloat(d)
	return d


## Someone standing in a boat on the water (the caped figure, the Passeur in his skiff): the
## picture raised from the bottom to `deck_m` above the water sheet (its ground, where it is now).
static func in_boat(n: Node2D, deck_m: float = BOAT_DECK_M) -> void:
	var view := Stage._view()
	var sprite = n.get("sprite") if n else null
	if view == null or view.heights == null or not sprite is Node2D:
		return
	var lift_m: float = HeightMap.WATER_LEVEL + deck_m - view.heights.to_3d(n.global_position).y
	if lift_m <= 0.0:
		return
	(sprite as Node2D).position.y -= lift_m * HeightMap.PX / WorldView.STRETCH
	var shadow := n.get_node_or_null("Shadow") as CanvasItem
	if shadow:
		shadow.visible = false


## A sea reptile of a scene put in the water floats there like a swimmer (Swim.SINK of its height
## under the water sheet), not down on the bottom where the sheet hides it; no shadow on the
## bottom. On land, or under the sea (Underwater places them), nothing changes.
static func afloat(d: DinoNpc) -> void:
	var view := Stage._view()
	var w = S.world()
	if view == null or view.heights == null or d.sprite == null or w == null or Dive.underwater(w.region):
		return
	var ground: float = view.heights.to_3d(d.global_position).y
	if ground > HeightMap.WATER_LEVEL - 0.05:
		return
	var frame_px := d.species.sheet.get_height() / float(d.species.sheet_rows)
	var height_m := frame_px * absf(d.sprite.scale.y) / HeightMap.PX * WorldView.STRETCH
	var lift_m := HeightMap.WATER_LEVEL - height_m * Swim.SINK - ground
	d.lift = lift_m * HeightMap.PX / WorldView.STRETCH
	d.sprite.position.y = -d.lift
	var shadow := d.get_node_or_null("Shadow") as CanvasItem
	if shadow:
		shadow.visible = false


## A story prop only a scene needs (the net, the night's boat): a StoryProp of that kind (its
## picture from Prop.KINDS), which the 3D view can move; no event.
static func prop(kind: String, at_px: Vector2, node_name: String, flip := false) -> Node2D:
	var w = S.world()
	if w == null or w.get("region") == null:
		return null
	var p := StoryProp.new()
	p.name = node_name
	p.set("kind", kind)
	p.set("flip", flip)
	p.position = at_px
	w.region.entities.add_child(p)
	p.collision_layer = 0
	return p


## A flyer (Moustique, a Pteranodon) goes from where it is to `to_px` in `secs`, high above the
## ground and bobbing; its picture faces the way it flies. Awaitable.
static func fly(actor, to_px: Vector2, secs := 1.6, height := FLY_HEIGHT) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var sprite := Stage.sprite_of(actor) as AnimatedSprite2D
	var from: Vector2 = (actor as Node2D).global_position
	if sprite:
		sprite.position.y = -height
		if absf(to_px.x - from.x) > 1.0:
			sprite.flip_h = to_px.x < from.x
		if sprite.sprite_frames and not _on_the_wing(actor, sprite):
			sprite.play(SheetFrames.dino_anims(sprite.sprite_frames, to_px - from)[0])
		var bobs := int(secs / 0.5)
		if bobs > 0:   # (a short hop of a circle: no bob, and no empty tween)
			var bob := sprite.create_tween()
			for i in bobs:
				bob.tween_property(sprite, "position:y", -height - FLY_BOB, 0.25).set_trans(Tween.TRANS_SINE)
				bob.tween_property(sprite, "position:y", -height, 0.25).set_trans(Tween.TRANS_SINE)
	var t: Tween = (actor as Node2D).create_tween()
	t.tween_property(actor, "global_position", to_px, secs).set_trans(Tween.TRANS_SINE)
	await t.finished


## Its species' flight sheet (dinos/<species>_vol.png: one row of WINGBEATS wingbeats, facing
## right) played as a « fly » animation; false when none is drawn (it flies with its walk).
static func _on_the_wing(actor, sprite: AnimatedSprite2D) -> bool:
	var species = actor.get("species_id")
	var path := "res://assets/art/dinos/%s_vol.png" % String(species)
	if species == null or not ResourceLoader.exists(path):
		return false
	var frames := sprite.sprite_frames
	if not frames.has_animation(&"fly"):
		var sheet: Texture2D = load(path)
		var cell := Vector2(sheet.get_width() / float(WINGBEATS), sheet.get_height())
		frames.add_animation(&"fly")
		frames.set_animation_speed(&"fly", 7.0)
		for i in WINGBEATS:
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(Vector2(cell.x * i, 0.0), cell)
			frames.add_frame(&"fly", frame)
	sprite.play(&"fly")
	return true


## A flyer circles round `centre_px` once (`radius` px), then stays where it began; `phase`
## (radians) sets where on the circle it starts, to keep two flyers apart. Awaitable.
static func circle(actor, centre_px: Vector2, radius := 60.0, secs := 1.8, height := FLY_HEIGHT, phase := 0.0) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var steps := 8
	for i in steps + 1:
		var angle := phase + TAU * i / steps
		await fly(actor, centre_px + Vector2(cos(angle), sin(angle) * 0.55) * radius, secs / steps, height)


## Something glides over the water (the boat) along `points` (world px), `speed` px/s; a newer
## glide of the same thing takes over from this one. Awaitable.
static func glide(thing: Node2D, points: Array, speed := 60.0) -> void:
	if thing == null or not is_instance_valid(thing):
		return
	var old = thing.get_meta(&"glide") if thing.has_meta(&"glide") else null   # (a null default counts as none)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	var t := thing.create_tween()
	var from := thing.global_position
	for p: Vector2 in points:
		t.tween_property(thing, "global_position", p, maxf(0.05, from.distance_to(p) / speed))
		from = p
	thing.set_meta(&"glide", t)
	await t.finished


## A sound effect when the file exists (no error when it does not yet).
static func sfx(path: String, volume_db := 0.0) -> void:
	if ResourceLoader.exists(path):
		Audio.play_sfx(load(path), volume_db)


# ------------------------------------------------------------------ diving

## Joss's diving mask (the item, or the story flag of the same name).
static func has_mask() -> bool:
	return Game.item_count(MASK_ITEM) > 0 or bool(Game.flag(MASK_FLAG))


## The dino who takes Chloé under the water (a grown diver of the party), or null.
static func diver() -> Dino:
	return Game.ability_user(DIVE) if has_mask() else null


## What still keeps Chloé from diving ("" when she can): the mask, a grown diver (in the party,
## too young, or waiting at the Cabinet), or where to find one.
static func dive_step() -> String:
	if not has_mask():
		if Game.flag(&"joss_cote_vu"):
			return "Il te faut le masque de plongée de Joss : il t'attend au bord du lagon."
		return "Il te faut un masque de plongée. Joss en coud justement : il est au lagon, « la tête dans un bocal »."
	if Game.ability_user(DIVE):
		return ""
	for d: Dino in Game.party:
		if Abilities.has(d, DIVE):
			return "Ton %s est encore trop jeune pour plonger : il doit être adulte (niveau %d)." % [d.nickname, Abilities.ADULT_LEVEL]
	for d: Dino in Game.box:
		if Abilities.usable(d, DIVE):
			return "Ton %s attend au Cabinet : lui saurait plonger. Fais-le venir depuis ton Dinodex, ou demande au Pr Roc." % d.nickname
	return "Avec le masque, il te faut un dino plongeur adulte : un Plesiosaurus du lagon, ou un Ichthyosaurus, au large de la Pointe des Palmes."


# ------------------------------------------------------------------ Maïa

## The name of Maïa's own hatchling (the egg that beats Chloé's).
static func maia_starter_name() -> String:
	return Prologue.MAIA_NAMES.get(StringName(str(Game.flag(&"maia_starter"))), "Flèche")


## A dino's call not tied to anyone on screen (the Mosasaure far below…): Desert.cry.
static func far_cry(prefix: String, kind: String, volume_db: float, pitch := 1.0) -> void:
	D.cry(prefix, kind, volume_db, pitch)
