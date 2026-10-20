class_name ApexGeantsReveil
## Post-game, les géants du cratère : G3, s'asseoir à côté (docs/post-game-scenes.md § G3), la scène jouée par
## story/apex_geants.gd (ApexGeants : la logique, les blocs, le cratère) quand Chloé choisit « S'asseoir à côté »
## avec le bon dino en tête, à la bonne heure. Chloé s'assoit dos au bloc, le dino en tête se couche contre elle
## (accroupi : un dino éveillé reste debout) ; un temps regardé sans texte (~25 s, pas de musique : les veines
## respirent de plus en plus lentement, un craquement, l'ambre se fend en étoile puis « comme une noix », un long
## souffle grave, le géant sort) ; cinq bulles, chacune avec ce qu'elle dit fait à l'écran ; +1 cœur au dino en
## tête dans la bulle du « +♥ » (ApexGeants.wake) ; le Dinodex ; on se relève. Le ronfleur : le dino chante
## d'abord, et le ronflement ralentit puis s'arrête. Les mots : data/dialogue_geants.gd.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const A := preload("res://story/apex.gd")
const AG := preload("res://story/apex_geants.gd")
const DG := preload("res://data/dialogue_geants.gd")
## The watched waking: no music; the veins breathe slower and slower (s), then the crack.
const SILENCE_DB := -40.0
const BREATHS: Array[float] = [1.6, 2.0, 2.5, 3.0]
const CRACK := "res://assets/audio/sfx/ambre-craque.ogg"
## Where Chloé sits (px from the block); a giant's head, high above its feet (px), for the camera.
const SIT_SPOT := Vector2(0.0, 46.0)
const HEAD_UP := Vector2(0.0, -150.0)
## The lead lies down at her side, a little behind (px from her): she stays in sight.
const LEAD_BESIDE := Vector2(76.0, -10.0)
## The giant getting up (lot A' : <id>_leve.png, 3×2, lying or sitting → standing, a yawn), played once.
const RISE_SHEET := "res://assets/art/dinos/%s_leve.png"
const RISE_FPS := 2.2


## G3 at block `who` (ApexGeants._offer, after « S'asseoir à côté »): the whole scene; the giant strolls after.
static func sit_scene(n: int, who: Node) -> void:
	S.lock(true)
	var c := cast_for(n, who)
	await waking(n, c)
	var giant = c.get("giant")
	if giant is DinoNpc:
		AG.stroll(giant, c["home"])
	Save.save_game()
	S.lock(false)


## Sitting down, watched, the five lines, the waking (if a cue missed it), getting up; the music back.
static func waking(n: int, c: Dictionary) -> void:
	AG.hush(true)
	await _sit_down(c)
	await _watch(n, c)
	await S.say(_wake_lines(n, c))
	if not AG.flag(n, "reveille"):
		AG.wake(n)
	_dex_toast(n)
	await _stand_up(c)
	Audio.duck(0.0, 2.0)
	AG.hush(false)


## Who and where: the block (px), Chloé's spot (in front of it), the giant's home, the lead and its name.
static func cast_for(n: int, who: Node) -> Dictionary:
	var at := A.px_of(who, Vector2(0.0, -2.0 * S.CELL))
	var lead := Game.lead_dino()
	return {"n": n, "block": who, "at": at, "spot": S.ground_near(at + SIT_SPOT, 2),
		"home": S.ground_near(at + AG.HOME[n] * S.CELL, 3), "lead": CS.lead(), "name": lead.nickname if lead else "ton dino"}


## Chloé sits with her back to the block; the lead lies down against her (a crouch: dinos stand up awake).
static func _sit_down(c: Dictionary) -> void:
	var spot: Vector2 = c["spot"]
	await CS.chloe_walk(spot, 90.0)
	var chloe := Stage.chloe()
	Stage.turn_to(chloe, spot + Vector2(0.0, 60.0))
	CS.sit(chloe)
	var lead = c.get("lead")
	if lead:
		await CS.lead_walk(spot + LEAD_BESIDE, 70.0)
		Stage.turn_to(lead, c["at"])
		CS.crouch(lead, 0.22, 0.8)
	Stage.look_at(c["at"].lerp(spot, 0.5), 1.2)


## Watched, no line (~25 s): no music; the veins breathe slower and slower; a crack; the amber splits in a
## star, then like a nut, in golden pieces; a long deep breath; the giant comes out. The ronfleur: the lead
## sings first, and the snore slows down and stops.
static func _watch(n: int, c: Dictionary) -> void:
	var at: Vector2 = c["at"]
	Audio.duck(SILENCE_DB, 1.5)
	if n == 3:
		await _sings(c)
	for secs in BREATHS:
		CS.pulse(at, A.AMBER, 1, secs, 2.6, 5.0)
		await S.wait(secs)
	CS.sfx(CRACK, -4.0)
	Stage.shake(2.0, 0.3)
	Act.burst(at + Vector2(0.0, -40.0), A.AMBER_BITS, 10, 1.2, 0.4)
	await S.wait(2.4)
	CS.sfx(CRACK, -2.0)
	await _split(n, c)
	await S.wait(1.2)
	CS.sfx(AG.YAWN, -6.0)
	await _comes_out(n, c)
	await S.wait(1.6)


## The lead sings three notes; the snore in the amber slows down, and stops.
static func _sings(c: Dictionary) -> void:
	var lead = c.get("lead")
	var snore := AG.snore_player(c.get("block"))
	for i in 3:
		if lead:
			Stage.emote(lead, "♪")
			Stage.cry(lead, &"neutre")
			Stage.rear(lead, 0.9)
		if snore and snore.playing:
			snore.pitch_scale = 1.0 - 0.12 * (i + 1)
			snore.volume_db -= 5.0
		await S.wait(1.7)
	if snore:
		snore.stop()
	if lead:
		CS.crouch(lead, 0.22, 0.6)
	await S.wait(0.8)


## The block splits like a nut: its empty picture (A'), else it pales; golden pieces fall.
static func _split(n: int, c: Dictionary) -> void:
	var block = c.get("block")
	var at: Vector2 = c["at"]
	Act.burst(at + Vector2(0.0, -30.0), A.AMBER_BITS, 22, 1.6, 0.9)
	Stage.shake(3.0, 0.4)
	if block is Prop:
		await AG.paint(block, n, &"vide", true)
	await S.wait(0.6)
	Act.burst(at + Vector2(0.0, -10.0), A.AMBER_BITS, 14, 0.6, 1.2)


## The giant out of the block: brought on at the block, it fades in and walks out slowly to its home.
static func _comes_out(n: int, c: Dictionary) -> void:
	var giant := AG.giant(n, c["at"] + Vector2(0.0, 10.0))
	c["giant"] = giant
	if giant == null:
		return
	giant.modulate.a = 0.0
	var rises := _rises(giant)
	await Stage.fade_in(giant, 1.4)
	if rises and giant.sprite.is_playing():
		await giant.sprite.animation_finished
	AG.step_sound(giant)
	await giant.walk_to(c["home"], AG.STROLL_SPEED * 1.5)
	Stage.turn_to(giant, c["spot"])


## Its getting-up pictures (RISE_SHEET) played once, when drawn for its species (not a stand-in's).
static func _rises(giant: DinoNpc) -> bool:
	var path := RISE_SHEET % giant.species_id
	if giant.sprite == null or not ResourceLoader.exists(path):
		return false
	var rise := SheetFrames.build(load(path), 3, 2, {&"leve": {"frames": [0, 1, 2, 3, 4, 5], "fps": RISE_FPS, "loop": false}})
	var frames := giant.sprite.sprite_frames
	if not frames.has_animation(&"leve"):
		frames.add_animation(&"leve")
		frames.set_animation_speed(&"leve", RISE_FPS)
		frames.set_animation_loop(&"leve", false)
		for i in rise.get_frame_count(&"leve"):
			frames.add_frame(&"leve", rise.get_frame_texture(&"leve", i))
	giant.sprite.play(&"leve")
	return true


## The five lines of G3, each with what it says done on screen.
static func _wake_lines(n: int, c: Dictionary) -> Array:
	var lines: Array = DG.wake(n, c["name"])
	var moves: Array = []
	match n:
		4:
			moves = _moves_moufle(c)
		2:
			moves = _moves_nuage(c)
		1:
			moves = _moves_rateau(c)
		_:
			moves = _moves_ronfleur(c)
	var out: Array = []
	for i in lines.size():
		var m = moves[i] if i < moves.size() else null
		out.append(CS.cue(lines[i], m) if m is Callable else lines[i])
	return out


static func _moves_moufle(c: Dictionary) -> Array:
	var g = c.get("giant")
	var lead = c.get("lead")
	var rises := func() -> void:
		Stage.look_at(_px(g, c["at"]) + HEAD_UP, 1.4)
		Stage.rear(g, 1.6)
	var finger := func() -> void:
		Stage.turn_to(g, _px(lead, c["spot"]))
		Stage.bow(g, 1.8)
	var rubs := func() -> void:
		Stage.look_back(1.0)
		await CS.get_up(lead)
		if lead:
			await CS.reach(lead, A.chloe_px(), 6.0, 0.6)
			Stage.emote(lead, "♥")
		AG.wake(4)
		Act.pop(A.chloe_px(), AG.PLUME, 0.9)
		Stage.bow(Stage.chloe(), 0.6)
	return [rises, finger, null, rubs, null]


static func _moves_nuage(c: Dictionary) -> Array:
	var g = c.get("giant")
	var lead = c.get("lead")
	var neck := func() -> void:
		Stage.look_at(_px(g, c["at"]) + HEAD_UP * 1.4, 1.6)
		Stage.rear(g, 2.0)
	var chewing := func() -> void:
		Stage.hop(lead, 3, 2.0)
		await S.wait(1.0)
		Stage.hop(g, 2, 3.0)
		Stage.hop(lead, 3, 2.0)
	var head_down := func() -> void:
		Stage.look_back(1.2)
		await Stage.bow(g, 2.2)
		AG.fern_at(_px(lead, c["spot"]) + Vector2(18.0, 10.0), "FougereNuage")
	var heart := func() -> void:
		AG.wake(2)
		if lead:
			Stage.emote(lead, "♥")
		Stage.look_at(_px(g, c["at"]) + HEAD_UP, 1.2)
	return [neck, chewing, head_down, null, heart]


static func _moves_rateau(c: Dictionary) -> Array:
	var g = c.get("giant")
	var lead = c.get("lead")
	var blades := func() -> void:
		Stage.look_at(_px(g, c["at"]), 1.0)
		Stage.rear(g, 1.4)
	var nobody := func() -> void:
		Stage.turn_to(g, _px(lead, c["spot"]))
		Stage.turn_to(lead, _px(g, c["at"]))
	var fern := func() -> void:
		if g:
			await CS.reach(g, A.chloe_px(), 22.0, 1.4)
		AG.fern_at(A.chloe_px() + Vector2(0.0, 16.0), "FougereRateau")
		var chloe := Stage.chloe()
		if chloe:
			Stage.recoil(chloe, _px(g, c["at"]), S.CELL)
	var heart := func() -> void:
		AG.wake(1)
		if lead:
			Stage.emote(lead, "♥")
	return [blades, nobody, fern, null, heart]


static func _moves_ronfleur(c: Dictionary) -> Array:
	var g = c.get("giant")
	var lead = c.get("lead")
	var finds := func() -> void:
		Stage.look_at(_px(g, c["at"]), 1.0)
		Stage.turn_to(g, _px(lead, c["spot"]))
	var yawns := func() -> void:
		CS.sfx(AG.YAWN, -8.0)
		Stage.rear(g, 2.2)
	var sings := func() -> void:
		if lead:
			Stage.emote(lead, "♪")
			Stage.cry(lead, &"neutre")
		await S.wait(0.8)
		Stage.bow(g, 2.6)
	var heart := func() -> void:
		AG.wake(3)
		if lead:
			Stage.emote(lead, "♥")
	return [finds, yawns, sings, null, heart]


## Where `who` stands (px), else `fallback` (a scene without its actor: the tests).
static func _px(who, fallback: Vector2) -> Vector2:
	if is_instance_valid(who) and who is Node2D:
		return (who as Node2D).global_position
	return fallback


## Chloé gets up, the lead too, back at her heels; the camera comes back.
static func _stand_up(c: Dictionary) -> void:
	var chloe := Stage.chloe()
	var lead = c.get("lead")
	if lead:
		CS.get_up(lead)
	await CS.get_up(chloe)
	CS.lead_back()
	Stage.look_back()


## « Nouveau dans le Dinodex » when the species is in it (else the stand-in's name would lie).
static func _dex_toast(n: int) -> void:
	var id: StringName = AG.SPECIES[n]
	var tree := Engine.get_main_loop() as SceneTree
	if tree and SpeciesDB.PATHS.has(id):
		Toast.say(tree, "Nouveau dans le Dinodex : %s !" % SpeciesDB.get_species(id).display_name)
