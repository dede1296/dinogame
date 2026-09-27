class_name Prologue
## The prologue: arriving in Port-Ambre with Isaure and Maïa, Professor Roc and Hélène's
## letter at the Cabinet, choosing one of the three hatchlings, Maïa taking hers, the third
## one stolen in the night, and Roc sending Chloé to the Plaines in the morning.
## Flags, in order: prologue_arrived, met_roc, starter (species), maia_left, egg_stolen,
## prologue_done.

const S := preload("res://story/story.gd")
const ISAURE := "Isaure"
const MAIA := "Maïa"
const CHLOE := "Chloé"
const ROC := "Prof. Roc"
## Hélène's letter, as recorded (assets/audio/voices/helene-lettre.mp3).
const LETTER := [
	"Ma chérie,",
	"Si tout s'est passé comme je le crains, je suis déjà dans la montagne.",
	"J'ai commis une erreur il y a trente ans. Une erreur qui dort sous le volcan. Je dois la réparer seule.",
	"J'ai caché les pages de mon journal sur toute l'île, pour qu'ils ne les trouvent pas. Toi, tu sauras les lire. Commence par l'endroit où tout a commencé.",
]
## What Chloé learns about each hatchling before choosing it.
const HATCHLINGS := {
	&"velociraptor": "Un petit Velociraptor au regard malin, qui ne tient pas en place. Ses griffes sauront trancher les troncs (Tranche). Type Vent.",
	&"ankylosaurus": "Un petit Ankylosaurus tout en carapace, calme et solide comme un rocher. Sa tête et sa massue enfoncent les obstacles (Charge). Type Pierre.",
	&"parasaurolophus": "Un petit Parasaurolophus à la crête corail, doux et curieux. Quand il chante, l'ambre lui répond (Résonance). Type Nature.",
}
## The name Maïa gives hers.
const MAIA_NAMES := {&"velociraptor": "Flèche", &"ankylosaurus": "Boulet", &"parasaurolophus": "Clairon"}
## Where Caillou, Maïa's Protoceratops, naps on the quay during the arrival; the Cabinet's door
## seen from the street (tiles).
const CAILLOU_AT := Vector2(21.3, 15.5)
const CABINET_FRONT := Vector2(31.5, 9.4)
## The three pedestals in the Cabinet (tiles), the door (px, the night thief's way out).
const PEDESTALS := Vector2(13.8, 6.3)
const CABINET_DOOR := Vector2(8.0, 9.4)
const DOOR_SFX := preload("res://assets/audio/sfx/door_open.wav")


# ------------------------------------------------------------------ Port-Ambre

static func arrival() -> void:
	S.lock(true)
	var isaure = S.actor("IsaureQuai")
	var maia = S.actor("MaiaQuai")
	var chloe := Stage.chloe()
	var caillou := _caillou()
	await S.wait(0.8)
	await S.say([
		# « Regarde les falaises » : both look up at the island.
		_cue({"who": ISAURE, "text": "Et voilà Ambrelune, moussaillon. Regarde les falaises : l'ambre y brille encore un peu, même en plein jour."},
			func() -> void:
				_look_north(isaure)
				_look_north(chloe)),
		{"who": CHLOE, "text": "C'est ici que vivait ma grand-mère…"},
		{"who": ISAURE, "text": "Hélène… Oui. C'est moi qui l'ai amenée sur cette île, il y a bien longtemps."},
		{"who": ISAURE, "text": "Dis-moi… Elle t'a laissé quelque chose ? Une lettre, peut-être ?"},
		{"who": CHLOE, "text": "Le Professeur Roc doit me la donner."},
		{"who": ISAURE, "text": "Roc. Bien sûr. Il garde tout, celui-là."},
	])
	if maia:
		await maia.walk_path([S.at(19.8, 17.2), S.at(19.8, 19.8)], "down", 170.0)
	await S.say([
		_cue({"who": MAIA, "text": "Maman ! C'est elle ? La petite-fille d'Hélène ?"},
			func() -> void:
				Stage.hop(maia, 2, 9.0)
				_face(chloe, maia)),
		{"who": ISAURE, "text": "Chloé, voici ma fille, Maïa. Une vraie tornade."},
		# The camera shows Caillou asleep on the quay, then comes back.
		_cue({"who": MAIA, "text": "Salut ! Moi, je connais l'île par cœur. Mon Protoceratops, Caillou, fait la sieste sur le quai : il est têtu comme une pierre."},
			func() -> void: Stage.look_at_actor(caillou)),
		_cue({"who": MAIA, "text": "Le Professeur Roc t'attend au Cabinet. Viens, on t'y emmène !"},
			func() -> void: Stage.look_back()),
	])
	Game.set_flag(&"prologue_arrived")
	if maia:
		_walk_and_enter(maia, [S.at(19.8, 16.0), S.at(18.2, 15.6), S.at(18.2, 10.2), S.at(31.4, 10.2), S.at(32.0, 8.9)])
	if isaure:
		_walk_and_enter(isaure, [S.at(20.3, 16.2), S.at(18.9, 15.9), S.at(18.9, 10.5), S.at(30.6, 10.5), S.at(32.0, 8.9)])
	_trot_after(caillou, [S.at(19.8, 15.9), S.at(18.6, 15.4), S.at(18.6, 10.4), S.at(31.0, 10.4), S.at(32.0, 8.9)])
	# The camera shows the big house the line speaks of (Story.lock(false) brings it back).
	await S.say([_cue({"text": "Isaure et Maïa partent vers le Cabinet : la grande maison couverte de lierre, à l'est du village."},
		func() -> void: Stage.look_at(S.at(CABINET_FRONT.x, CABINET_FRONT.y)))])
	Save.save_game()
	S.lock(false)


## Caillou, napping on the quay while Maïa comes to meet Chloé (a scene actor: he trots
## after her to the Cabinet and is gone).
static func _caillou() -> DinoNpc:
	var w = S.world()
	if w == null or w.get("region") == null:
		return null
	var c := Sleeper.new()
	c.name = "Caillou"
	c.species_id = &"protoceratops"
	c.size_scale = 0.85
	c.flip = true
	c.position = S.at(CAILLOU_AT.x, CAILLOU_AT.y)
	w.region.entities.add_child(c)
	return c


## Caillou wakes up (at last) and trots after Maïa, then goes in with her.
static func _trot_after(dino, points: Array) -> void:
	if dino == null or not is_instance_valid(dino):
		return
	await S.wait(1.2)
	if not is_instance_valid(dino):
		return
	dino.set_process(false)   # no more « z »
	Stage.emote(dino, "!")
	dino.cry(&"neutre")
	await S.wait(0.5)
	for p: Vector2 in points:
		if not is_instance_valid(dino):
			return
		await dino.walk_to(p, 150.0)
	if is_instance_valid(dino):
		await Stage.fade_out(dino, 0.35, true)


## Walks through `points`, then goes in (fades out and leaves the zone).
static func _walk_and_enter(who: Node2D, points: Array) -> void:
	await who.walk_path(points, "up", 160.0)
	if is_instance_valid(who):
		await who.create_tween().tween_property(who, "modulate:a", 0.0, 0.35).finished
		who.queue_free()


# ------------------------------------------------------------------ the Cabinet

static func cabinet() -> void:
	_remove_gone_hatchlings()
	if not Game.flag(&"prologue_arrived") or Game.flag(&"prologue_done"):
		return
	if not Game.flag(&"met_roc"):
		await _roc_intro()
	elif Game.flag(&"starter"):
		await _after_choice()


## The hatchlings already taken (Chloé's, Maïa's, the stolen one) are no longer there.
static func _remove_gone_hatchlings() -> void:
	for id: StringName in Game.STARTERS:
		var gone: bool = Game.flag(&"prologue_done") \
			or str(Game.flag(&"starter")) == String(id) \
			or (str(Game.flag(&"maia_starter")) == String(id) and Game.flag(&"maia_left")) \
			or (str(Game.flag(&"stolen_starter")) == String(id) and Game.flag(&"egg_stolen"))
		var baby = S.actor("Bebe_" + String(id))
		if gone and baby:
			baby.queue_free()


static func _roc_intro() -> void:
	S.lock(true)
	await S.wait(0.5)
	var roc = S.actor("Roc")
	var maia = S.actor("Maia")
	var player: Node2D = S.world().get("player")
	if roc:
		roc.face(player.global_position)
	await S.say([
		S.voice("roc-1"), _cue({"who": ROC, "text": "Chloé ! Enfin… Tu as bien grandi depuis la photo qu'Hélène gardait sur son bureau."},
			func() -> void: Stage.emote(roc, "!")),
		S.voice("roc-2"), {"who": ROC, "text": "Je suis Anselme Roc. J'ai travaillé trente ans aux côtés de ta grand-mère."},
		S.voice("roc-3"), {"who": ROC, "text": "Il y a un an, elle est partie vers le volcan avec son sac et son vieux carnet. Elle n'est jamais revenue."},
		# He comes to give it to her.
		_cue({"who": ROC, "text": "Avant de partir, elle m'a confié ceci. Pour toi."}, func() -> void: _step_to_chloe(roc)),
		{"letter": LETTER, "sign": "— H.", "voice": "res://assets/audio/voices/helene-lettre.mp3"},
		{"who": CHLOE, "text": "« Une erreur qui dort sous le volcan »… Qu'est-ce que ça veut dire ?"},
		S.voice("roc-4"), {"who": ROC, "text": "Depuis, des gens masqués rôdent sur l'île. Ils se font appeler l'Ombre Noire. Ils cherchent quelque chose… les Cœurs d'Ambre, je crois."},
		{"who": ISAURE, "text": "L'Ombre Noire… On en parle beaucoup sur le port, ces temps-ci."},
		# The camera goes to the pedestals: the three hatchlings, just hatched, stir and cry.
		S.voice("roc-5"), _cue({"who": ROC, "text": "Tu ne peux pas explorer Ambrelune sans compagnon. Hélène avait préparé trois œufs avant de partir. Ils viennent d'éclore."},
			_hatchlings_stir),
		S.voice("roc-6"), _cue({"who": ROC, "text": "Ils sont sur les socles, à droite. Approche-toi et choisis celui qui te ressemble."},
			func() -> void: Stage.turn_to(roc, S.at(PEDESTALS.x, PEDESTALS.y))),
		_cue({"who": MAIA, "text": "Trois bébés dinos ?! Je peux en avoir un, moi aussi ?"},
			func() -> void:
				Stage.look_back()
				Stage.hop(maia, 3, 9.0)),
		{"who": ROC, "text": "Chaque chose en son temps, jeune fille. Chloé choisit d'abord."},
		{"flag": &"met_roc"},
	])
	Save.save_game()
	S.lock(false)


## The camera shows the pedestals; the hatchlings hop and cry, one after the other.
static func _hatchlings_stir() -> void:
	Stage.look_at(S.at(PEDESTALS.x, PEDESTALS.y))
	await S.wait(0.5)
	for id: StringName in Game.STARTERS:
		var baby = S.actor("Bebe_" + String(id))
		if baby and is_instance_valid(baby):
			baby.cry(&"neutre")
			Stage.hop(baby, 2, 7.0)
			await S.wait(0.45)


## Talking to a hatchling: learn about it, then take it or look at the others.
static func choose_starter(baby: Node) -> void:
	if Game.flag(&"starter") or not Game.flag(&"met_roc"):
		return
	var id: StringName = baby.species_id
	var nickname: String = Game.STARTERS[id]
	var pick := await Dialogue.choose("", HATCHLINGS[id] + " Il s'appelle %s." % nickname,
		["Je choisis %s !" % nickname, "Je regarde les autres"])
	if pick != 0:
		return
	S.lock(true)
	var w = S.world()
	w.companion.teleport(baby.global_position)
	Game.give_starter(id)
	baby.queue_free()
	await S.say([
		_cue({"text": "%s se blottit contre Chloé. On dirait qu'il l'a choisie, lui aussi." % nickname},
			func() -> void:
				Stage.companion_joy()
				Stage.emote(w.companion, "♥")),
		{"who": ROC, "text": "Hélène aurait adoré voir ça."},
	])
	Save.save_game()
	await _after_choice()


## Maïa takes hers and leaves with Isaure; then the night, then the morning.
static func _after_choice() -> void:
	S.lock(true)
	if not Game.flag(&"maia_left"):
		await _maia_takes_hers()
	if not Game.flag(&"egg_stolen"):
		await _night()
	await _morning()
	S.lock(false)


static func _maia_takes_hers() -> void:
	var maia = S.actor("Maia")
	var isaure = S.actor("Isaure")
	var roc = S.actor("Roc")
	var maia_id := StringName(str(Game.flag(&"maia_starter")))
	var hers = S.actor("Bebe_" + String(maia_id))
	var stolen = S.actor("Bebe_" + str(Game.flag(&"stolen_starter")))
	await S.say([
		_cue({"who": MAIA, "text": "À moi ! À moi !"}, func() -> void: Stage.hop(maia, 3, 9.0)),
		_cue({"who": ROC, "text": "Pour toi, Maïa, celui-ci. Hélène t'aimait beaucoup, tu sais."}, func() -> void: _face(roc, hers)),
	])
	if hers and maia:
		await hers.walk_to(maia.global_position + Vector2(44, 8))
		_landed(hers)
		hers.cry()
	await S.say([
		_cue({"who": MAIA, "text": "Je vais t'appeler %s ! Toi et moi, on va battre Chloé à plate couture." % MAIA_NAMES.get(maia_id, "Caillou")},
			func() -> void:
				Stage.hop(maia, 2, 9.0)
				Stage.hop(hers, 2, 6.0)),
	])
	if isaure and stolen:
		isaure.face(stolen.global_position)
	await S.say([
		# The camera shows Isaure and the hatchling she stares at.
		_cue({"text": "Isaure regarde longuement le troisième petit, sans rien dire."},
			func() -> void:
				_look_between(isaure, stolen)
				Stage.emote(isaure, "…")),
		{"who": ISAURE, "text": "Il se fait tard. Maïa, on rentre."},
		_cue({"who": MAIA, "text": "Rendez-vous aux Plaines demain, Chloé ! La première qui trouve une page du journal d'Hélène a gagné !"},
			func() -> void: Stage.look_back()),
	])
	var door: Vector2 = S.at(8.0, 10.2)
	for who: Node2D in [maia, isaure]:
		if who:
			_walk_and_enter(who, [door])
	if hers:
		_walk_and_leave(hers, door)
	await S.wait(2.2)
	Game.set_flag(&"maia_left")
	Save.save_game()


static func _walk_and_leave(dino: Node2D, target: Vector2) -> void:
	await dino.walk_to(target)
	if is_instance_valid(dino):
		await dino.create_tween().tween_property(dino, "modulate:a", 0.0, 0.3).finished
		dino.queue_free()


static func _night() -> void:
	var w = S.world()
	var roc = S.actor("Roc")
	var stolen = S.actor("Bebe_" + str(Game.flag(&"stolen_starter")))
	await S.say([{"who": ROC, "text": "Tu dois être épuisée, après ce voyage. Tu dormiras ici cette nuit : le vieux fauteuil est plus confortable qu'il n'en a l'air."}])
	await Router.fade_out(0.9)
	Game.clock = 23.0 * 60.0 + 40.0
	w.player.teleport(S.at(9.6, 4.3))
	w.player.face_towards(S.at(12.0, 6.0))
	w.companion.teleport(S.at(8.9, 4.6))
	if roc:
		roc.visible = false
	var shadow: Npc = load("res://actors/npc.tscn").instantiate()
	shadow.name = "Silhouette"
	shadow.display_name = "???"
	shadow.sheet = load("res://assets/art/characters/isaure.png")
	shadow.position = S.at(8.0, 9.9)
	w.region.entities.add_child(shadow)
	shadow.remove_from_group(&"interactable")
	shadow.sprite.modulate = Color(0.05, 0.05, 0.07)
	await S.wait(0.3)
	await Router.fade_in(0.9)
	var chloe := Stage.chloe()
	var stolen_at: Vector2 = stolen.global_position if stolen else S.at(PEDESTALS.x, PEDESTALS.y)
	# The door creaks: Chloé starts awake and turns; the camera shows the dark figure there.
	await S.say([_cue({"text": "Au milieu de la nuit, un grincement réveille Chloé…"},
		func() -> void:
			Audio.play_sfx(DOOR_SFX, -6.0)
			Stage.emote(chloe, "!")
			Stage.hop(chloe, 1, 8.0)
			_face(chloe, shadow)
			Stage.look_at(chloe.global_position.lerp(shadow.global_position, 0.62)))])
	if stolen:
		await shadow.walk_to(stolen.global_position + Vector2(-44, 6), "right", 90.0)
		stolen.cry(&"degat")
		await Stage.tremble(stolen, 0.4, 2.0)
		await Stage.fade_out(stolen, 0.3, true)
	# Chloé's cry: the figure freezes and looks at her, then runs.
	await S.say([_cue({"who": CHLOE, "text": "Hé ! Qui est là ?!"},
		func() -> void:
			_face(shadow, chloe)
			Stage.emote(shadow, "!"))])
	await shadow.walk_to(S.at(8.0, 10.4), "down", 240.0)
	await shadow.create_tween().tween_property(shadow, "modulate:a", 0.0, 0.25).finished
	shadow.queue_free()
	Stage.look_back()
	if roc:
		roc.global_position = S.at(3.0, 8.5)
		roc.visible = true
		await roc.walk_to(S.at(8.4, 5.6), "right", 170.0)
	await S.say([
		_cue({"who": ROC, "text": "Qu'est-ce que c'est que ce vacarme ?! … Le troisième petit ! Il a disparu !"},
			func() -> void:
				Stage.turn_to(roc, stolen_at)
				Stage.emote(roc, "!")),
		_cue({"who": CHLOE, "text": "Quelqu'un avec un masque d'os… Il s'est enfui par la porte !"},
			func() -> void:
				Stage.turn_to(chloe, S.at(CABINET_DOOR.x, CABINET_DOOR.y))
				Stage.turn_to(roc, S.at(CABINET_DOOR.x, CABINET_DOOR.y))),
		# He goes to look at the lock, then comes back to her.
		_cue({"who": ROC, "text": "Par la porte ? Mais je l'avais fermée à clé… Il n'y a pas la moindre trace d'effraction."},
			func() -> void: _check_the_door(roc)),
		{"who": ROC, "text": "Quelqu'un avait une clé du Cabinet. L'Ombre Noire…"},
		{"flag": &"egg_stolen"},
	])
	Save.save_game()


## Roc hurries to the door (the camera goes with him), looks at the lock, and comes back
## towards Chloé.
static func _check_the_door(roc) -> void:
	if roc == null or not is_instance_valid(roc):
		return
	Stage.look_at(S.at(CABINET_DOOR.x, CABINET_DOOR.y - 1.6))
	await roc.walk_to(S.at(CABINET_DOOR.x, CABINET_DOOR.y - 0.3), "down", 150.0)
	await S.wait(0.8)
	if not is_instance_valid(roc):
		return
	Stage.emote(roc, "?")
	await S.wait(0.7)
	if not is_instance_valid(roc) or Stage.chloe() == null:
		return
	Stage.look_back()
	await _step_to_chloe(roc, 80.0)


static func _morning() -> void:
	var roc = S.actor("Roc")
	await Router.fade_out(0.9)
	Game.clock = 8.0 * 60.0
	if roc:
		roc.visible = true
		roc.global_position = S.at(6.5, 4.6)
		roc.face(S.world().player.global_position)
	await S.wait(0.3)
	await Router.fade_in(0.9)
	var starter: Dino = Game.lead_dino()
	await S.say([
		{"who": ROC, "text": "Bien dormi ? Moi, je n'ai pas fermé l'œil."},
		{"who": ROC, "text": "Si l'Ombre Noire vole les dinos d'Hélène, c'est qu'elle cherche la même chose qu'elle. Il faut que tu retrouves son journal avant eux."},
		_cue({"who": ROC, "text": "Tiens : des colliers d'ambre, pour te faire d'autres compagnons, et des baies pour soigner %s." % (starter.nickname if starter else "ton dino")},
			func() -> void: _step_to_chloe(roc)),
		{"text": "Chloé reçoit 5 colliers d'ambre et 3 baies !"},
		{"who": ROC, "text": "Les Plaines des Fougères sont au nord du village. Maïa doit déjà y être. Et reviens me voir si ton équipe est fatiguée."},
	])
	Game.items["collier"] = Game.item_count("collier") + 5
	Game.items["baie"] = Game.item_count("baie") + 3
	Game.set_flag(&"prologue_done")
	Save.save_game()


## Talking to Roc outside of the scenes: a reminder, or a rest for the team.
## Returns whether Roc said something (he looks after a hurt party, or points at the eggs).
static func talk_roc() -> bool:
	if not Game.flag(&"met_roc"):
		return false
	if not Game.flag(&"starter"):
		await S.say([{"who": ROC, "text": "Les petits sont sur les socles, à droite. Approche-toi et choisis celui qui te ressemble."}])
		return true
	if Game.party.all(func(d: Dino) -> bool: return d.hp >= d.max_hp()):
		return false
	Game.heal_party()
	Game.party_changed.emit()
	await S.say([{"who": ROC, "text": "Fais-moi voir ton équipe… Là. Tout le monde est en pleine forme !"}])
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


## `who` turns to look at `target` (both actors; nothing when one is missing).
static func _face(who, target) -> void:
	if who and target and is_instance_valid(who) and is_instance_valid(target):
		Stage.turn_to(who, (target as Node2D).global_position)


## Looks up, towards the north of the island (the cliffs, the volcano).
static func _look_north(who) -> void:
	if who and is_instance_valid(who):
		Stage.turn_to(who, (who as Node2D).global_position + Vector2(0, -200))


## The camera shows two actors at once (the point between them).
static func _look_between(a, b) -> void:
	if a and b and is_instance_valid(a) and is_instance_valid(b):
		Stage.look_at(((a as Node2D).global_position + (b as Node2D).global_position) / 2.0)


## Someone (an Npc) comes up to Chloé, to give her something; stops `gap` px from her.
static func _step_to_chloe(who, gap := 64.0) -> void:
	var chloe := Stage.chloe()
	if who == null or not is_instance_valid(who) or chloe == null:
		return
	var to: Vector2 = chloe.global_position - (who as Node2D).global_position
	if to.length() > gap:
		await who.walk_to(chloe.global_position - to.normalized() * gap, "", 110.0)
	if is_instance_valid(who):
		who.face(chloe.global_position)


## A hatchling off its pedestal: Stage's moves take its picture back to the ground, not up
## where it stood.
static func _landed(dino) -> void:
	var sprite := Stage.sprite_of(dino)
	if sprite and sprite.has_meta(&"stage_rest"):
		sprite.remove_meta(&"stage_rest")
