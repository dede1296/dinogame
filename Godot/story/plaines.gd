class_name Plaines
## Chapter 1, Plaines des Fougères: the Grand Crâne and its three amber locks, the
## Tricératops Alpha's battle of honour; then the end of the chapter (docs/histoire.md,
## steps 6 and 7): Maïa's first challenge at the foot of the skull, and back at the port at
## nightfall, Roc slipping out of the Cabinet towards the volcano, page 6 in the empty
## incubator. Flags: ecaille_bosquet / _grotte / _falaises, crane_ouvert, sceau_plaines,
## maia_defi_1, roc_parti_vu, roc_dehors (Roc away from the Cabinet until morning),
## cabinet_vide_vu, found_journal_6.

const S := preload("res://story/story.gd")
const ALPHA_LEVEL := 9
## Its size, share of an adult Triceratops (DinoNpc.size_scale; the same in its battle).
const ALPHA_SIZE := 1.2
## Where the Alpha stands once the skull is open (beside its mouth, facing the path).
const ALPHA_SPOT := Vector2(107.2, 63.8)
## The mouth of its cave, at the back of the mound's notch; and just out of the notch.
const DEN := Vector2(104.0, 58.5)
const MOUTH := Vector2(104.0, 63.2)
## Just out of the notch, behind where Chloé stands at the door: the Alpha's way out of its
## cave and back (so it does not walk over her).
const OUT_OF_NOTCH := Vector2(104.9, 62.3)
## In the cave's darkness: the Alpha comes out of it (and goes back into it) this way.
const IN_SHADOW := Color(0.08, 0.08, 0.1, 0.0)
const SHADOW_S := 1.6
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ROC := "Prof. Roc"
## Maïa runs in from the path to the west, then waits at the foot of the skull.
const MAIA_FROM := Vector2(93.0, 65.5)
## Her team: Caillou, her Protoceratops, then the hatchling she took (see Prologue).
const MAIA_LEVELS := [8, 9]
## Port-Ambre at nightfall: where Chloé watches from, the Cabinet's door, and where Roc goes
## (the old path behind the Cabinet, north, towards the volcano).
const PORT_WATCH := Vector2(26.0, 10.6)
const CABINET_DOOR := Vector2(31.5, 9.1)
const ROC_PATH := [Vector2(33.6, 9.4), Vector2(35.2, 6.0), Vector2(36.0, 3.0)]
const NIGHTFALL := 21.0
const LANTERN := Color(1.0, 0.78, 0.4)
const DOOR_SFX := preload("res://assets/audio/sfx/door_open.wav")
## The scales clicking into their hollows; the amber waking up.
const CLICK := preload("res://assets/audio/sfx/latch.wav")
## An amber glow as the 3D view can show it: the picture tinted amber (colours above white do
## not show there) and a warm light on it.
const AMBER_TINT := Color(1.0, 0.8, 0.45)
const AMBER_LIGHT := Color(1.0, 0.72, 0.3)
const AMBER_FLASH := Color(1.0, 0.8, 0.4, 0.45)
## Where the camera looks when the page of the empty Cabinet is spoken of (Roc's desk and
## lamp, the incubator; tiles).
const DESK := Vector2(7.8, 3.0)
const INCUBATOR := Vector2(13.8, 3.7)
## The middle of Roc's way up the old path (tiles), for the camera.
const ROC_PATH_MIDDLE := Vector2(34.2, 6.4)


static func grand_crane() -> void:
	if Game.flag(&"sceau_plaines"):
		await S.say([{"text": "Le crâne est silencieux. Quelque part dans l'ombre, le gardien des Plaines veille."}])
		return
	if Game.flag(&"crane_ouvert"):
		var waiting = S.actor("Alpha")
		if waiting:
			await alpha(waiting)
		return
	var n := DialogueDB.ecailles()
	if n < 3:
		await S.say([
			{"text": "La bouche du crâne est fermée par une porte d'ambre. Trois creux en forme d'écaille y sont gravés."},
			{"text": "Il manque encore %d écaille%s d'ambre." % [3 - n, "s" if 3 - n > 1 else ""]},
		])
		return
	S.lock(true)
	var door = S.actor("PorteCrane")
	var melted := {"done": false}
	await S.say([
		# One click and one glow per scale; then the door lights up and melts, with its line.
		_cue({"text": "Chloé pose les trois écailles d'ambre dans leurs creux. Elles s'y emboîtent parfaitement…"},
			func() -> void: _scales_in(door)),
		_cue({"text": "L'ambre s'illumine, tiédit… et la porte fond lentement, comme du miel au soleil."},
			func() -> void: _run(func() -> void: await _melt(door), melted)),
	])
	await _finish(melted)
	if is_instance_valid(door):
		door.queue_free()
	Game.set_flag(&"crane_ouvert")
	var alpha = _spawn_alpha()
	if alpha:
		alpha.modulate = IN_SHADOW
	var out := {"done": false}
	await S.say([
		# The rumble, then the Alpha comes out of the dark while its line shows.
		_cue({"text": "Un grondement monte du fond de la grotte. Un immense Tricératops sort de l'ombre, les cornes basses."},
			func() -> void: _run(func() -> void: await _emerge(alpha), out)),
		_cue({"text": "C'est le gardien des Plaines : le Tricératops Alpha. Il fixe Chloé, puis son équipe."},
			func() -> void: _face(alpha, Stage.chloe())),
	])
	await _finish(out)
	Save.save_game()
	S.lock(false)


## The three scales click into the door one after the other; each hollow lights up.
static func _scales_in(door) -> void:
	for i in 3:
		await S.wait(0.55)
		Audio.play_sfx(CLICK, -4.0, 0.1)
		if is_instance_valid(door):
			_amber(door, 1, 0.45, 2.5)


## The amber door lights up, warms… and melts like honey (it is freed afterwards).
static func _melt(door) -> void:
	if door == null or not is_instance_valid(door):
		return
	Stage.flash(AMBER_FLASH, 0.9)
	_sparkles(door.global_position, 22)
	var light := _light_at(door.global_position, AMBER_LIGHT, 5.0)
	var t: Tween = door.create_tween()
	t.tween_property(door, "modulate", AMBER_TINT, 0.9)
	if light:
		t.parallel().tween_property(light, "light_energy", 5.0, 0.9)
	t.tween_property(door, "modulate:a", 0.0, 1.8).set_trans(Tween.TRANS_SINE)
	if light:
		t.parallel().tween_property(light, "light_energy", 0.0, 1.8)
		t.tween_callback(light.queue_free)
	await t.finished


## Out of the cave's darkness: the rumble, the Alpha walks out to its spot, stamps, lowers its horns.
static func _emerge(trike) -> void:
	if trike == null or not is_instance_valid(trike):
		return
	Stage.shake(2.0, 1.4)
	Stage.look_at(S.at(MOUTH.x, MOUTH.y - 1.0))
	await S.wait(0.6)
	if not is_instance_valid(trike):
		return
	trike.cry(&"attaque")
	trike.create_tween().tween_property(trike, "modulate", Color.WHITE, SHADOW_S)
	await trike.walk_to(S.at(OUT_OF_NOTCH.x, OUT_OF_NOTCH.y), 90.0)
	Stage.look_back()
	await trike.walk_to(S.at(ALPHA_SPOT.x, ALPHA_SPOT.y), 90.0)
	Stage.shake(7.0, 0.5)
	if Stage.chloe():   # horns low, towards her
		await _head_down(trike, Stage.chloe().global_position, 1.3)


static func _spawn_alpha() -> Node:
	var w = S.world()
	if w == null or S.actor("Alpha") != null:
		return S.actor("Alpha")
	var alpha := DinoNpc.new()
	alpha.name = "Alpha"
	alpha.species_id = &"triceratops"
	alpha.event = &"alpha_plaines"
	alpha.size_scale = ALPHA_SIZE
	alpha.flip = true
	alpha.position = S.at(DEN.x, DEN.y)
	w.region.entities.add_child(alpha)
	return alpha


## Talking to the Alpha: a battle of honour (no collar, no running away).
static func alpha(who: Node) -> void:
	if Game.party.is_empty():
		return
	var pick := await Dialogue.choose("", "Le Tricératops Alpha frappe le sol du sabot. Il veut voir ce que vaut ton équipe.",
		["Relever le défi", "Pas encore"])
	if pick != 0:
		return
	var foe := Dino.create(&"triceratops", ALPHA_LEVEL, "Tricératops Alpha")
	var result: String = await S.world().call(&"_battle", foe, {
		"catch": false, "run": false, "size": ALPHA_SIZE,
		"intro": "Le Tricératops Alpha se dresse devant toi ! (Combat d'honneur : pas de collier, pas de fuite.)",
	})
	if result != "win":
		return
	S.lock(true)
	var chloe := Stage.chloe()
	await S.say([
		_cue({"text": "Le Tricératops Alpha s'ébroue… puis baisse lentement la tête devant Chloé, comme un salut."},
			func() -> void: _salute(who)),
		# The horn comes to her hand; the amber on it glows.
		_cue({"text": "Il pose le bout de sa corne dans la main de Chloé. Elle est tiède, et il y a quelque chose dessus : un sceau d'ambre."},
			func() -> void: _horn_to_hand(who)),
		_cue({"text": "Chloé reçoit le Sceau des Plaines !"},
			func() -> void:
				_amber(chloe, 2, 0.9)
				Stage.companion_joy()),
		{"flag": &"sceau_plaines"},
		{"text": "Sous le sceau, une page du journal d'Hélène, soigneusement pliée…"},
	])
	await Dialogue.run(DialogueDB.lines(&"page_5"))
	Game.award_team_xp(60)
	# It goes back into its cave while its line shows.
	var home := {"done": false}
	await S.say([_cue({"text": "Le gardien retourne dans sa grotte, au fond du crâne."},
		func() -> void: _run(func() -> void: await _back_to_den(who), home))])
	await _finish(home)
	Save.save_game()
	S.lock(false)
	await maia_arrives()


## The Alpha shakes itself, then slowly lowers its head before Chloé.
static func _salute(trike) -> void:
	if trike == null or not is_instance_valid(trike):
		return
	_face(trike, Stage.chloe())
	await Stage.tremble(trike, 0.5, 3.0)
	await S.wait(0.2)
	if Stage.chloe():
		await _head_down(trike, Stage.chloe().global_position, 2.4)


## The tip of its horn in Chloé's hand: it leans towards her, the amber seal glows on it.
static func _horn_to_hand(trike) -> void:
	var chloe := Stage.chloe()
	if trike == null or not is_instance_valid(trike) or chloe == null:
		return
	await _lean(trike, chloe.global_position, 16.0, 1.4)


## Back into its cave: the darkness swallows it as it reaches the mouth; then it is gone.
static func _back_to_den(trike) -> void:
	if trike == null or not is_instance_valid(trike):
		return
	await trike.walk_to(S.at(OUT_OF_NOTCH.x, OUT_OF_NOTCH.y), 80.0)
	if not is_instance_valid(trike):
		return
	var fade: Tween = trike.create_tween()
	fade.tween_interval(0.9)
	fade.tween_property(trike, "modulate", IN_SHADOW, SHADOW_S)
	await trike.walk_to(S.at(DEN.x, DEN.y), 80.0)
	if is_instance_valid(trike):
		trike.queue_free()


# ------------------------------------------------------------------ Maïa's challenge

## Right after the Sceau: Maïa runs in, too late, and wants her challenge at once.
static func maia_arrives() -> void:
	var w = S.world()
	if w == null or Game.flag(&"maia_defi_1"):
		return
	S.lock(true)
	var maia = S.actor("MaiaDefi")
	if maia == null:
		maia = S.stranger("MaiaDefi", "maia", S.at(MAIA_FROM.x, MAIA_FROM.y), "right")
		maia.display_name = MAIA
		maia.event = &"maia_defi"
		maia.add_to_group(&"interactable")
	await maia.walk_to(w.player.global_position + Vector2(-90, 12), "right", 200.0)
	await S.say([
		{"who": MAIA, "text": "Chloé ! J'ai entendu le Tricératops rugir jusqu'à l'étang ! Ne me dis pas que…"},
		{"who": CHLOE, "text": "Le Sceau des Plaines. Il me l'a donné."},
		{"who": MAIA, "text": "… Bon. D'accord. Bravo. MAIS. Un Sceau, ça se défend. Toi et moi, ici, maintenant."},
	])
	S.lock(false)
	await maia_duel(maia, false)


## Talking to Maïa at the foot of the skull (she waits there until she has had her duel).
static func maia_duel(who: Node, again := true) -> void:
	var prompt := "Alors, ce défi ? Caillou s'est échauffé toute la matinée. Enfin, il a dormi. Mais il a dormi FORT." if again \
		else "Deux dinos chacune. Et pas de pitié, hein ?"
	var pick := await Dialogue.choose(MAIA, prompt, ["Relever le défi", "Plus tard"])
	if pick != 0:
		if not again:
			await S.say([{"who": MAIA, "text": "Poule mouillée ! … Je t'attends ici. Soigne ton équipe : je veux une vraie victoire."}])
		return
	var mine := StringName(str(Game.flag(&"maia_starter")))
	var team := [[&"protoceratops", MAIA_LEVELS[0], "Caillou"]]
	if SpeciesDB.PATHS.has(mine):
		team.append([mine, MAIA_LEVELS[1], Prologue.MAIA_NAMES.get(mine, "")])
	if not await S.duel(MAIA, team):
		await S.say([_cue({"who": MAIA, "text": "HA ! Caillou et moi, on est les meilleurs ! … Reviens quand tu veux : je t'attends au pied du Crâne."},
			func() -> void: Stage.hop(who, 2, 10.0))])
		return
	S.lock(true)
	await S.say([
		# She stamps her feet.
		_cue({"who": MAIA, "text": "Non, non, non… J'étais à ça. À ÇA !"}, func() -> void: Stage.hop(who, 3, 5.0)),
		{"who": MAIA, "text": "La prochaine fois, c'est moi. Je vais m'entraîner au Havre, au Relais des Dresseurs. Et il paraît que Joss fait des selles, maintenant."},
		{"who": CHLOE, "text": "Ta mère ne va pas s'inquiéter, si tu pars au Havre ?"},
		{"who": MAIA, "text": "Maman ? Elle rentre tard, ces temps-ci. Avec des bottes pleines de cendre. Elle dit qu'elle répare le vieux phare."},
		{"who": MAIA, "text": "… Il n'y a pas de cendre, au phare."},
		{"who": MAIA, "text": "Bref ! Rentre au port raconter tout ça à Roc. Moi, je file. Rendez-vous au Havre, championne !"},
		{"flag": &"maia_defi_1"},
	])
	Game.award_team_xp(50)
	if is_instance_valid(who):
		await who.walk_to(S.at(MAIA_FROM.x, MAIA_FROM.y), "left", 220.0)
		who.queue_free()
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ back at the port

## Coming back to Port-Ambre after Maïa's challenge: nightfall, and Roc slipping out of the
## Cabinet with a lantern, north, towards the volcano (a false lead).
static func back_to_port() -> void:
	var w = S.world()
	if w == null or not Game.flag(&"maia_defi_1") or Game.flag(&"roc_parti_vu"):
		return
	S.lock(true)
	await S.fade_through(func() -> void:
		if Game.phase() != &"night":
			Game.pass_time_until(NIGHTFALL)
		w.player.teleport(S.at(PORT_WATCH.x, PORT_WATCH.y))
		w.companion.stand_beside(S.at(PORT_WATCH.x, PORT_WATCH.y))
		w.player.face_towards(S.at(CABINET_DOOR.x, CABINET_DOOR.y))
		await S.wait(0.4))
	await S.say([_cue({"text": "Le soir est tombé quand Chloé arrive enfin au village. Les lanternes s'allument une à une."},
		_light_lanterns)])
	var roc := S.stranger("RocNuit", "roc", S.at(CABINET_DOOR.x, CABINET_DOOR.y), "down")
	_lantern(roc)
	Stage.look_at(S.at(CABINET_DOOR.x - 1.5, CABINET_DOOR.y + 0.8))   # the Cabinet's door, and Chloé
	# He comes out of the Cabinet: its door opens (and stays open, Chloé says); unknown: its creak.
	if await Doorway.npc_out(S.actor("Cabinet"), roc, 90.0):
		await roc.walk_to(S.at(CABINET_DOOR.x, CABINET_DOOR.y), "down", 90.0)
	else:
		Audio.play_sfx(DOOR_SFX, -8.0)
		await S.wait(0.6)
	await S.say([
		_cue({"who": CHLOE, "text": "(Le professeur ? À cette heure-ci ?)"}, func() -> void: Stage.emote(Stage.chloe(), "?")),
		# He looks up north, towards the volcano.
		_cue({"who": ROC, "text": "… trente ans. Trente ans, Hélène. Et tu crois que je vais rester assis à attendre ?"},
			func() -> void: Stage.turn_to(roc, roc.global_position + Vector2(0, -200))),
	])
	Stage.look_at(S.at(ROC_PATH_MIDDLE.x, ROC_PATH_MIDDLE.y))   # the camera follows him up the path
	for p: Vector2 in ROC_PATH:
		await roc.walk_to(S.at(p.x, p.y), "up", 95.0)
	var fade := roc.create_tween()
	fade.tween_property(roc, "modulate:a", 0.0, 1.2)
	await fade.finished
	roc.queue_free()
	await S.say([
		{"who": CHLOE, "text": "Il prend le vieux sentier, derrière le Cabinet… vers le nord. Vers le volcan ?"},
		_cue({"who": CHLOE, "text": "Et il a laissé la porte du Cabinet ouverte."},
			func() -> void: Stage.look_at(S.at(CABINET_DOOR.x, CABINET_DOOR.y))),
		{"flag": &"roc_parti_vu"},
		{"flag": &"roc_dehors"},
	])
	Save.save_game()
	S.lock(false)


## The village's lanterns light up one after the other, from west to east (their warm light
## in the view; the lanterns themselves are scenery drawn in one batch).
static func _light_lanterns() -> void:
	var view := _view()
	if view == null:
		return
	var lamps: Array = view.find_children("*", "OmniLight3D", true, false).filter(
		func(n: Node) -> bool: return n.has_meta(&"lamp"))
	lamps.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.global_position.x < b.global_position.x)
	var full := {}
	for lamp: OmniLight3D in lamps:
		full[lamp] = lamp.light_energy
		lamp.light_energy = 0.0
	for lamp: OmniLight3D in lamps:
		await S.wait(0.45)
		if is_instance_valid(lamp):
			lamp.create_tween().tween_property(lamp, "light_energy", full[lamp], 0.35)


## A lantern in the hand: a warm light that walks with him.
static func _lantern(who: Node2D) -> void:
	var light := PointLight2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(LANTERN, 1.0))
	g.set_color(1, Color(LANTERN, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	light.texture = tex
	light.color = LANTERN
	light.energy = 1.2
	light.position = Vector2(14, -40)
	who.add_child(light)


## The Cabinet in the dark, Roc gone: something waits in the empty incubator (page 6).
static func empty_cabinet() -> void:
	if not Game.flag(&"roc_dehors") or Game.flag(&"found_journal_6") or Game.flag(&"cabinet_vide_vu"):
		return
	S.lock(true)
	await S.wait(0.5)
	await S.say([
		# The camera shows the desk and the empty armchair, then the incubator, where the page glows.
		_cue({"text": "Le Cabinet est silencieux. La lampe du bureau brûle encore, mais le fauteuil de Roc est vide, et sa vieille lanterne a disparu du crochet."},
			func() -> void: Stage.look_at(S.at(DESK.x, DESK.y))),
		_cue({"text": "Dans la couveuse vide, là où dormaient les trois œufs, quelque chose brille doucement."},
			func() -> void:
				Stage.look_at(S.at(INCUBATOR.x, INCUBATOR.y))
				_amber(S.actor("Page6"), 3, 1.2, 2.5)),
		{"flag": &"cabinet_vide_vu"},
	])
	S.lock(false)


## Roc is back by morning (and says he never left).
static func morning() -> void:
	if Game.flag(&"roc_dehors") and Game.phase() in [&"dawn", &"day"]:
		Game.set_flag(&"roc_dehors", false)


## The first time Chloé sees Roc after that night: he never left, of course.
static func roc_denies() -> bool:
	if not Game.flag(&"roc_parti_vu") or Game.flag(&"roc_dehors") or Game.flag(&"roc_nuit_niee"):
		return false
	await S.say([
		{"who": CHLOE, "text": "Professeur… Hier soir, je vous ai vu partir. Avec une lanterne. Vers le volcan."},
		{"who": ROC, "text": "Hier soir ? J'étais… au lit. Évidemment. Où voulais-tu que je sois ?"},
		{"who": ROC, "text": "Tu as dû voir un pêcheur. Ils sont tous pareils, de dos. Allez, allez, ne reste pas plantée là : le Havre t'attend."},
		{"who": CHLOE, "text": "(Il a de la cendre sur ses chaussures…)"},
		{"flag": &"roc_nuit_niee"},
	])
	return true


# ------------------------------------------------------------------ staging (see Stage)

## A line whose staging starts the moment it shows: `act` is called then (not awaited), so
## the move goes with its bubble, without cutting the dialogue in two.
static func _cue(line: Dictionary, act: Callable) -> Dictionary:
	var cued := line.duplicate()
	var text: String = cued["text"]
	cued.erase("text")
	cued["text_fn"] = func() -> String:
		act.call()
		return text
	return cued


## Plays `move` (a coroutine) and marks `token` done at its end (see _finish): a move that
## goes on under the lines, and that the scene waits for before going further.
static func _run(move: Callable, token: Dictionary) -> void:
	await move.call()
	token["done"] = true


## Waits for a move started with _run (at most `max_s` seconds, whatever happens).
static func _finish(token: Dictionary, max_s := 12.0) -> void:
	var waited := 0.0
	while not token.get("done", false) and waited < max_s:
		await S.wait(0.05)
		waited += 0.05


## `who` turns to look at `target` (both actors; nothing when one is missing).
static func _face(who, target) -> void:
	if who and target and is_instance_valid(who) and is_instance_valid(target):
		Stage.turn_to(who, (target as Node2D).global_position)


## Leans towards `toward_px` (its picture, `px` pixels), stays there `hold` seconds with a
## glow of amber, and comes back: a horn laid in a hand. Awaitable.
static func _lean(actor, toward_px: Vector2, px := 14.0, hold := 1.0) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	var rest: Vector2 = sprite.get_meta(&"stage_rest", sprite.position)
	sprite.set_meta(&"stage_rest", rest)
	var dir: Vector2 = (toward_px - (actor as Node2D).global_position).normalized() * px
	var t := sprite.create_tween()
	t.tween_property(sprite, "position", rest + dir, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void: _amber(actor, 1, hold))
	t.tween_interval(hold)
	t.tween_property(sprite, "position", rest, 0.5).set_trans(Tween.TRANS_SINE)
	await t.finished


## Lowers its head towards `toward_px`, slowly, and raises it again (a big dino's salute, or its
## horns lowered): its picture sinks, leans and squashes. Awaitable.
static func _head_down(actor, toward_px: Vector2, secs := 2.0) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	var rest: Vector2 = sprite.get_meta(&"stage_rest", sprite.position)
	sprite.set_meta(&"stage_rest", rest)
	if not sprite.has_meta(&"stage_scale"):
		sprite.set_meta(&"stage_scale", sprite.scale)
	var full: Vector2 = sprite.get_meta(&"stage_scale")
	var lean := signf(toward_px.x - (actor as Node2D).global_position.x) * 8.0
	var t := sprite.create_tween()
	t.tween_property(sprite, "position", rest + Vector2(lean, 8.0), secs * 0.35).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(sprite, "scale", full * Vector2(1.03, 0.85), secs * 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_interval(secs * 0.3)
	t.tween_property(sprite, "position", rest, secs * 0.35).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(sprite, "scale", full, secs * 0.35).set_trans(Tween.TRANS_SINE)
	await t.finished


## A burst of amber sparkles at `px` (world pixels).
static func _sparkles(px: Vector2, amount := 14) -> void:
	var view := _view()
	if view:
		view.burst(px, Search.AMBER, amount, 0.8, 0.8)


static func _view() -> WorldView:
	return (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view") as WorldView

## An amber glow on `actor` (a scale, a seal, a page…), `times` pulses: its picture tinted
## amber and a warm light shining on it (see _light_at). Awaitable.
static func _amber(actor, times := 1, secs := 0.8, energy := 3.0) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	Stage.glow(actor, AMBER_TINT, times, secs)
	var light := _light_at((actor as Node2D).global_position, AMBER_LIGHT)
	if light == null:
		return
	var t := light.create_tween()
	for i in times:
		t.tween_property(light, "light_energy", energy, secs * 0.5).set_trans(Tween.TRANS_SINE)
		t.tween_property(light, "light_energy", 0.0, secs * 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_callback(light.queue_free)
	await t.finished


## A light of the 3D view at `px` (world pixels), a little above the ground, off (energy 0):
## the caller brightens it, then frees it. Null without the view.
static func _light_at(px: Vector2, colour: Color, reach := 3.2) -> OmniLight3D:
	var view := (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view") as WorldView
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
