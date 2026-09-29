class_name Grotte
## Chapter 1, the Grotte des Échos (docs/histoire.md, ch. 1, step 3): two henchmen of the
## Ombre Noire tear amber from the walls — the first battles against them —, and at the far
## end, the first corrupted dino: a Protoceratops they fed black amber to make it dig, then
## left behind, mad with fear. The game teaches Apaiser; the second amber scale was under it.
## Flags: sbire_grotte_1, sbire_grotte_2, apaiser_appris, proto_apaise, proto_suit.

const S := preload("res://story/story.gd")
const CHLOE := "Chloé"
const GUSTAVE := "Sbire masqué"
const CHEF := "Sbire à la pioche"
const TEAM_1 := [[&"compsognathus", 6], [&"troodon", 7]]
const TEAM_2 := [[&"troodon", 7], [&"velociraptor", 8]]
const PROTO_LEVEL := 9
## Where the henchmen run to (the way out, at the bottom of the cave).
const WAY_OUT := Vector2(11.9, 17.2)
## The way out along the cave's passages (tiles): from the upper chamber down the west passage
## (the walls between the chambers are rock), then across the lower chamber to the entrance.
const UPPER_CHAMBER_END := 5.0
const WEST_PASSAGE := [Vector2(5.8, 3.6), Vector2(5.8, 10.6)]
const TO_ENTRANCE := [Vector2(11.9, 12.4), Vector2(11.9, 17.2)]
## The second scale, under the corrupted Protoceratops.
const SCALE_SPOT := Vector2(18.6, 2.9)
## The rock walls the henchmen hack at with their pickaxes (tiles): west of the first one,
## north of the second.
const WALL_1 := Vector2(3.6, 10.6)
const WALL_2 := Vector2(16.2, 0.4)
## The floor of the upper chamber, between its walls (tiles, x): the Protoceratops's side step.
const FLOOR_X := Vector2(4.6, 20.4)
const PICKAXE := preload("res://assets/audio/sfx/pierre.mp3")
const CORRUPTED := Color(1.25, 0.8, 1.6)
## An amber glow as the 3D view can show it: the picture tinted amber (colours above white do
## not show there) and a warm light on it.
const AMBER_TINT := Color(1.0, 0.8, 0.45)
const AMBER_LIGHT := Color(1.0, 0.72, 0.3)
## Said in the battle the first time: how to calm a corrupted dino.
const LESSON := [
	"Ce Protoceratops est corrompu : l'ambre noir le rend fou de peur. Impossible de le capturer, et il ne tombera pas.",
	"Choisis « Apaiser » : ton dino s'approche, et Chloé lui parle tout bas. Chaque réussite remplit sa jauge de Calme.",
	"Plus il est fatigué, plus il écoute. Un dino de sa famille l'apaise plus vite. Mais chaque coup l'affole à nouveau !",
]


## Entering the cave: pickaxes in the dark, then the first henchman comes to see who is there.
static func arrival() -> void:
	if Game.flag(&"sbire_grotte_1"):
		return
	var sbire = S.actor("Sbire1")
	var w = S.world()
	if sbire == null or w == null:
		return
	S.lock(true)
	await S.wait(0.8)
	var digging := {}
	await S.say([
		# The camera shows the henchman hacking at the rock, blow after blow.
		_cue({"text": "Tac… tac… tac… Des coups de pioche résonnent dans le noir. Puis des voix."},
			func() -> void:
				Stage.look_at_actor(sbire)
				digging["loop"] = _dig(sbire, S.at(WALL_1.x, WALL_1.y))),
		{"who": "Une voix", "text": "Plus vite ! Le Masque veut ses caisses avant la pleine lune."},
		# (Both in sight: Chloé wondering, and him at his wall.)
		_cue({"who": CHLOE, "text": "(Le Masque… ?)"},
			func() -> void:
				Stage.look_at((w.player.global_position + sbire.global_position) / 2.0)
				Stage.emote(Stage.chloe(), "?")),
	])
	# He hears her: he stops, turns round, and comes to see.
	Stage.stop(sbire, digging.get("loop"))
	Stage.turn_to(sbire, w.player.global_position)
	Stage.emote(sbire, "!")
	await S.wait(0.6)
	Stage.look_back()
	await sbire.walk_to(w.player.global_position + Vector2(0, -80), "down", 150.0)
	await S.say([
		{"who": GUSTAVE, "text": "Hé ! Une gamine ! Qu'est-ce que tu fiches ici ? Cette grotte est à l'Ombre Noire, maintenant."},
		{"who": CHLOE, "text": "Cette grotte, c'est ma grand-mère qui l'a trouvée. Et l'ambre appartient à l'île."},
		{"who": GUSTAVE, "text": "Ha ! Alors viens le reprendre."},
	])
	S.lock(false)
	await _fight_gustave(sbire)


## Talking to the first henchman again (after a defeat).
static func gustave(who: Node) -> void:
	await S.say([{"who": GUSTAVE, "text": "Tu reviens ? T'as pas compris la première fois ?"}])
	await _fight_gustave(who)


static func _fight_gustave(who: Node) -> void:
	if not await S.duel(GUSTAVE, TEAM_1):
		return
	S.lock(true)
	await S.say([
		{"who": GUSTAVE, "text": "Aïe, aïe, aïe… Le chef va me tuer. Enfin, il va me faire porter les caisses. C'est pire."},
		{"who": GUSTAVE, "text": "Tu sais quoi ? Je démissionne. Je retourne pêcher. Au moins, les poissons ne mordent pas. Enfin, pas fort."},
		{"flag": &"sbire_grotte_1"},
	])
	if is_instance_valid(who):
		await _walk_out(who, 200.0)
	# The camera goes to the far end: the other one, and his pickaxe.
	var chief = S.actor("Sbire2")
	var digging := {}
	await S.say([_cue({"who": CHLOE, "text": "Un pêcheur de Port-Ambre ? Sous un masque d'os ?… Il y en a un autre, au fond. J'entends encore sa pioche."},
		func() -> void:
			Stage.look_at_actor(chief)
			digging["loop"] = _dig(chief, S.at(WALL_2.x, WALL_2.y)))])
	Stage.stop(chief, digging.get("loop"))
	Game.award_team_xp(30)
	Save.save_game()
	S.lock(false)


## The second henchman, at the far end, beside the dino they broke.
static func chef(who: Node) -> void:
	var proto_npc = S.actor("ProtoCorrompu")
	await S.say([
		{"who": CHEF, "text": "T'as battu Gustave ? Pas difficile, Gustave a peur des poules."},
		# He turns to the dino; it cowers, its veins glowing violet.
		_cue({"who": CHEF, "text": "Tu vois ce Protoceratops ? On lui a fait avaler de l'ambre noir, pour qu'il creuse plus fort. Il a creusé, oui. Et puis il a mordu tout le monde."},
			func() -> void:
				_face(who, proto_npc)
				_afraid(proto_npc, 2.4)),
		{"who": CHLOE, "text": "Vous lui avez fait du mal !"},
		{"who": CHEF, "text": "On lui a rendu service : il est plus fort qu'avant. Allez, dégage, ou je te montre ce que valent les dinos de l'Ombre Noire."},
	])
	if not await S.duel(CHEF, TEAM_2):
		return
	S.lock(true)
	await S.say([
		{"who": CHEF, "text": "Grr… Garde-le, ton bestiau ! De toute façon, il est fichu. L'ambre noir, ça ne s'en va jamais."},
		{"flag": &"sbire_grotte_2"},
	])
	if is_instance_valid(who):
		await _walk_out(who, 210.0)
	# Chloé looks at it: it shakes with fear.
	await S.say([_cue({"who": CHLOE, "text": "Ce n'est pas vrai. Il a juste peur… Hélène disait qu'un dino ne se dresse pas : il se rencontre."},
		func() -> void:
			_face(Stage.chloe(), proto_npc)
			_afraid(proto_npc, 1.8))])
	Game.award_team_xp(40)
	Save.save_game()
	S.lock(false)


## The corrupted Protoceratops: calming it (a battle, with the lesson the first time).
static func proto(who: Node) -> void:
	if not Game.flag(&"sbire_grotte_2"):
		var chef_npc = S.actor("Sbire2")
		await S.say([{"who": CHEF, "text": "Touche pas à notre bestiole, la gamine !"}])
		if chef_npc:
			await chef(chef_npc)
		return
	_afraid(who, 3.0)   # it trembles, its veins pulse (the question below says so)
	var pick := await Dialogue.choose("", "Le Protoceratops tremble dans le noir. Des veines violettes pulsent sous sa peau, et ses yeux brillent d'une lueur qui n'est pas la sienne.",
		["L'approcher doucement", "Pas maintenant"])
	if pick != 0:
		return
	var foe := Dino.create(&"protoceratops", PROTO_LEVEL)
	foe.corrupted = true
	var result: String = await S.world().call(&"_battle", foe, {
		"catch": false, "size": 1.0,   # (grown, as in the cave)
		"intro": "Le Protoceratops corrompu charge, fou de peur !",
		"lesson": [] if Game.flag(&"apaiser_appris") else LESSON,
	})
	Game.set_flag(&"apaiser_appris")
	if result != "calmed":
		return
	S.lock(true)
	if is_instance_valid(who):
		await who.cleanse()
	var stepped := {"done": false}
	await S.say([
		_cue({"text": "Le Protoceratops cligne des yeux, longtemps. Puis il regarde Chloé comme s'il la voyait pour la première fois."},
			func() -> void: _blinks(who)),
		# It steps aside: the scale it was lying on shows, and pulses.
		_cue({"text": "Il fait un pas de côté. Sous lui, coincée entre deux cristaux, une écaille d'ambre pulse doucement."},
			func() -> void: _run(func() -> void: await _step_aside(who), stepped)),
		{"flag": &"proto_apaise"},
	])
	await _finish(stepped)
	_drop_scale()
	_come_close(who)   # it comes to rub against her leg (the question says so)
	var join := await Dialogue.choose("", "Le Protoceratops se frotte contre la jambe de Chloé. Il ne veut plus rester seul dans le noir.",
		["Viens avec moi !", "Retourne aux Plaines"])
	if join == 0:
		var d := Dino.create(&"protoceratops", PROTO_LEVEL)
		var in_party := Game.add_caught(d)
		Game.set_flag(&"proto_suit")
		if is_instance_valid(who):
			Stage.companion_joy()
			Stage.fade_out(who, 0.5, true)
		await S.say([{"text": "%s rejoint ton équipe !" % d.nickname if in_party else "%s part attendre au Cabinet." % d.nickname}])
	else:
		# Its little cry, and it trots off towards the way out while the line shows.
		var gone := {"done": false}
		await S.say([_cue({"text": "Le Protoceratops pousse un petit cri, presque un merci, et trottine vers la sortie. Vers le soleil."},
			func() -> void: _run(func() -> void: await _trots_off(who), gone))])
		await _finish(gone)
	Save.save_game()
	S.lock(false)


## The scale it was lying on (also placed by the zone once calmed, see tools/zones).
## The zone's own scale shows as soon as the dino has stepped off it (it can be taken once
## proto_apaise is set, right after); `glow`: it pulses (« une écaille d'ambre pulse doucement »).
static func _drop_scale(glow := false) -> void:
	var w = S.world()
	if w == null or Game.flag(&"ecaille_grotte"):
		return
	var scale = S.actor("Ecaille")
	if scale == null:
		scale = Pickup.new()
		scale.name = "Ecaille"
		scale.kind = "ecaille"
		scale.taken_flag = &"ecaille_grotte"
		scale.dialogue_id = &"ecaille_grotte"
		scale.position = S.at(SCALE_SPOT.x, SCALE_SPOT.y)
		w.region.entities.add_child(scale)
	scale.visible = true
	if glow:
		_amber(scale, 3, 1.1, 2.0)


# ------------------------------------------------------------------ what the lines show

## A henchman hacks at the rock with his pickaxe, again and again (a blow, a clink, the
## ground trembling a little) until Stage.stop. Null without him.
static func _dig(actor, wall_px: Vector2) -> Tween:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return null
	Stage.turn_to(actor, wall_px)
	var rest: Vector2 = sprite.get_meta(&"stage_rest", sprite.position)
	sprite.set_meta(&"stage_rest", rest)
	var dir: Vector2 = (wall_px - (actor as Node2D).global_position).normalized() * 10.0
	var t := sprite.create_tween().set_loops()
	t.tween_property(sprite, "position", rest - dir * 0.5 + Vector2(0, -4), 0.25).set_trans(Tween.TRANS_SINE)   # raised
	t.tween_property(sprite, "position", rest + dir, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)   # the blow
	t.tween_callback(func() -> void:
		Audio.play_sfx(PICKAXE, -9.0, 0.15)
		Stage.shake(1.2, 0.1))
	t.tween_property(sprite, "position", rest, 0.25).set_trans(Tween.TRANS_SINE)
	t.tween_interval(0.25)
	return t


## A corrupted dino afraid: it trembles, and its violet veins pulse.
static func _afraid(dino, secs: float) -> void:
	if dino == null or not is_instance_valid(dino):
		return
	Stage.tremble(dino, secs, 2.0)
	Stage.glow(dino, CORRUPTED, int(ceil(secs / 1.2)), 1.2)
	var glow = dino.get_node_or_null("Glow")   # its violet light (DinoNpc), shown by the view
	if glow is PointLight2D:
		var base: float = glow.energy
		var t := (glow as Node).create_tween()
		for i in int(ceil(secs / 1.2)):
			t.tween_property(glow, "energy", base * 2.6, 0.6).set_trans(Tween.TRANS_SINE)
			t.tween_property(glow, "energy", base, 0.6).set_trans(Tween.TRANS_SINE)


## Calmed: it blinks for a long time, then looks at Chloé as if seeing her for the first time.
static func _blinks(dino) -> void:
	if dino == null or not is_instance_valid(dino):
		return
	await S.wait(1.3)
	if is_instance_valid(dino) and Stage.chloe():
		Stage.turn_to(dino, Stage.chloe().global_position)
		Stage.emote(dino, "?")


## A step aside, away from Chloé (staying on the chamber's floor): the scale under it shows.
static func _step_aside(dino) -> void:
	var chloe := Stage.chloe()
	if dino == null or not is_instance_valid(dino) or chloe == null:
		return
	var side := 1.0 if dino.global_position.x >= chloe.global_position.x else -1.0
	var to: Vector2 = dino.global_position + Vector2(side * S.CELL, 8.0)
	if to.x > FLOOR_X.y * S.CELL or to.x < FLOOR_X.x * S.CELL:
		to.x = dino.global_position.x - side * S.CELL
	await dino.walk_to(to, 70.0)
	_drop_scale(true)


## It comes to Chloé and rubs against her leg.
static func _come_close(dino) -> void:
	var chloe := Stage.chloe()
	if dino == null or not is_instance_valid(dino) or chloe == null:
		return
	var from_her: Vector2 = (dino.global_position - chloe.global_position).normalized()
	await dino.walk_to(chloe.global_position + from_her * 40.0, 90.0)
	if not is_instance_valid(dino):
		return
	Stage.turn_to(dino, chloe.global_position)
	Stage.emote(dino, "♥")
	await Stage.bow(dino, 0.8)
	if is_instance_valid(dino):
		await Stage.tremble(dino, 0.4, 1.5)


## A little cry, almost a thank-you, and it trots off to the way out, towards the sun.
static func _trots_off(dino) -> void:
	if dino == null or not is_instance_valid(dino):
		return
	dino.cry(&"neutre")
	await Stage.hop(dino, 1, 6.0)
	if not is_instance_valid(dino):
		return
	await _walk_out(dino, 150.0)


## Someone leaves the cave by its passages, and is gone: from the upper chamber, out of sight
## down the west passage (fading as it goes in); from the lower one, to the entrance.
static func _walk_out(actor, speed: float) -> void:
	var upper: bool = (actor as Node2D).global_position.y < UPPER_CHAMBER_END * S.CELL
	var points: Array = WEST_PASSAGE if upper else TO_ENTRANCE
	for i in points.size():
		if not is_instance_valid(actor):
			return
		var to := S.at(points[i].x, points[i].y)
		if upper and i == points.size() - 1:   # into the passage: the dark swallows it
			(actor as Node2D).create_tween().tween_property(actor, "modulate:a", 0.0, 0.9)
		if actor is Npc:
			await (actor as Npc).walk_to(to, "down", speed)
		else:
			await actor.walk_to(to, speed)
	if is_instance_valid(actor):
		actor.queue_free()


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
