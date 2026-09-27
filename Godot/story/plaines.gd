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
## Where the Alpha stands once the skull is open (beside its mouth, facing the path).
const ALPHA_SPOT := Vector2(107.2, 63.8)
## The mouth of its cave, at the back of the mound's notch; and just out of the notch.
const DEN := Vector2(104.0, 58.5)
const MOUTH := Vector2(104.0, 63.2)
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
	await S.say([
		{"text": "Chloé pose les trois écailles d'ambre dans leurs creux. Elles s'y emboîtent parfaitement…"},
		{"text": "L'ambre s'illumine, tiédit… et la porte fond lentement, comme du miel au soleil."},
	])
	var door = S.actor("PorteCrane")
	if door:
		var t: Tween = door.create_tween()
		t.tween_property(door, "modulate", Color(2.2, 1.7, 0.9), 0.6)
		t.tween_property(door, "modulate:a", 0.0, 0.9)
		await t.finished
		door.queue_free()
	Game.set_flag(&"crane_ouvert")
	var alpha = _spawn_alpha()
	if alpha:
		alpha.cry(&"attaque")
		alpha.modulate = IN_SHADOW
		alpha.create_tween().tween_property(alpha, "modulate", Color.WHITE, SHADOW_S)
		await alpha.walk_to(S.at(MOUTH.x, MOUTH.y), 90.0)
		await alpha.walk_to(S.at(ALPHA_SPOT.x, ALPHA_SPOT.y), 90.0)
		S.world().get("player").get_node("Camera").call(&"shake", 7.0, 0.5)
	await S.say([
		{"text": "Un grondement monte du fond de la grotte. Un immense Tricératops sort de l'ombre, les cornes basses."},
		{"text": "C'est le gardien des Plaines : le Tricératops Alpha. Il fixe Chloé, puis son équipe."},
	])
	Save.save_game()
	S.lock(false)


static func _spawn_alpha() -> Node:
	var w = S.world()
	if w == null or S.actor("Alpha") != null:
		return S.actor("Alpha")
	var alpha := DinoNpc.new()
	alpha.name = "Alpha"
	alpha.species_id = &"triceratops"
	alpha.event = &"alpha_plaines"
	alpha.size_scale = 1.35
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
		"catch": false, "run": false,
		"intro": "Le Tricératops Alpha se dresse devant toi ! (Combat d'honneur : pas de collier, pas de fuite.)",
	})
	if result != "win":
		return
	S.lock(true)
	await S.say([
		{"text": "Le Tricératops Alpha s'ébroue… puis baisse lentement la tête devant Chloé, comme un salut."},
		{"text": "Il pose le bout de sa corne dans la main de Chloé. Elle est tiède, et il y a quelque chose dessus : un sceau d'ambre."},
		{"text": "Chloé reçoit le Sceau des Plaines !"},
		{"flag": &"sceau_plaines"},
		{"text": "Sous le sceau, une page du journal d'Hélène, soigneusement pliée…"},
	])
	await Dialogue.run(DialogueDB.lines(&"page_5"))
	Game.award_team_xp(60)
	if is_instance_valid(who):
		await who.walk_to(S.at(MOUTH.x, MOUTH.y), 80.0)
		# Into the cave: the darkness swallows it as it reaches the mouth.
		var fade: Tween = who.create_tween()
		fade.tween_interval(0.9)
		fade.tween_property(who, "modulate", IN_SHADOW, SHADOW_S)
		await who.walk_to(S.at(DEN.x, DEN.y), 80.0)
		who.queue_free()
	await S.say([{"text": "Le gardien retourne dans sa grotte, au fond du crâne."}])
	Save.save_game()
	S.lock(false)
	await maia_arrives()


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
		await S.say([{"who": MAIA, "text": "HA ! Caillou et moi, on est les meilleurs ! … Reviens quand tu veux : je t'attends au pied du Crâne."}])
		return
	S.lock(true)
	await S.say([
		{"who": MAIA, "text": "Non, non, non… J'étais à ça. À ÇA !"},
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
		w.companion.teleport(S.at(PORT_WATCH.x - 0.8, PORT_WATCH.y + 0.2))
		w.player.face_towards(S.at(CABINET_DOOR.x, CABINET_DOOR.y))
		await S.wait(0.4))
	await S.say([{"text": "Le soir est tombé quand Chloé arrive enfin au village. Les lanternes s'allument une à une."}])
	var roc := S.stranger("RocNuit", "roc", S.at(CABINET_DOOR.x, CABINET_DOOR.y), "down")
	_lantern(roc)
	Audio.play_sfx(DOOR_SFX, -8.0)
	await S.wait(0.6)
	await S.say([
		{"who": CHLOE, "text": "(Le professeur ? À cette heure-ci ?)"},
		{"who": ROC, "text": "… trente ans. Trente ans, Hélène. Et tu crois que je vais rester assis à attendre ?"},
	])
	for p: Vector2 in ROC_PATH:
		await roc.walk_to(S.at(p.x, p.y), "up", 95.0)
	var fade := roc.create_tween()
	fade.tween_property(roc, "modulate:a", 0.0, 1.2)
	await fade.finished
	roc.queue_free()
	await S.say([
		{"who": CHLOE, "text": "Il prend le vieux sentier, derrière le Cabinet… vers le nord. Vers le volcan ?"},
		{"who": CHLOE, "text": "Et il a laissé la porte du Cabinet ouverte."},
		{"flag": &"roc_parti_vu"},
		{"flag": &"roc_dehors"},
	])
	Save.save_game()
	S.lock(false)


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
		{"text": "Le Cabinet est silencieux. La lampe du bureau brûle encore, mais le fauteuil de Roc est vide, et sa vieille lanterne a disparu du crochet."},
		{"text": "Dans la couveuse vide, là où dormaient les trois œufs, quelque chose brille doucement."},
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
