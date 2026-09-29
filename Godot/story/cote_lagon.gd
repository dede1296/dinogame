class_name CoteLagon
## Chapter 5, the Côte Préhistorique, the lagoon (docs/histoire.md, ch. 5, points 5 and 18):
## Joss comes out of the water with a jar sewn to a leather collar on his head (prototype n° 7),
## an ammonite on the glass; Ferréol ordered ten diving masks « for his divers »; a young
## Plesiosaurus caught in an old net of the Ombre Noire by the flat rock: Chloé calms it, cuts the
## meshes with Joss's saddler scissors; free, it dives… and comes back, and will not leave:
## Nessie joins her. Joss gives her the real mask (La Plongée). Afterwards, Joss's lines, his
## anger at Ferréol once Chloé has read the cache's ledger; Joss at the Havre. The turtles' nest
## at dusk (a side quest): the hatchlings, the Masiakasaurus, the one on its back.
## Flags: joss_cote_vu, filet_coupe, nessie, masque_plongee, joss_ferreol, tortues_sauvees;
## joss_cote_n, joss_havre_cote_n (lines).

const S := preload("res://story/story.gd")
const P := preload("res://story/cote_places.gd")
const CS := preload("res://story/cote_stage.gd")
const A := preload("res://story/cote_ask.gd")
const CHLOE := "Chloé"
const JOSS := "Joss"
## Nessie, the young Plesiosaurus freed from the net (checked with the chapter's levels: a
## little below the party, a diver from the start).
const NESSIE := "Nessie"
const NESSIE_LEVEL := 26
const XP_JOSS := 30
## Joss wading out of the lagoon backwards (px/s).
const JOSS_WADE := 40.0
const XP_NESSIE := 60
const XP_TORTUES := 40
const TURTLE_FERNS := 2
## The turtles' hatchlings, and how far they run to the sea.
const HATCHLINGS := 4
## Paper torn to bits (Ferréol's order).
const PAPER: Array[Color] = [Color(1.0, 0.98, 0.92), Color(0.93, 0.9, 0.82), Color(0.85, 0.82, 0.74)]
const JOSS_AGAIN := [
	"Nessie te suit partout ? Les Plesiosaurus sont fidèles comme des chiens. Des chiens très, très longs.",
	"Je teste le prototype neuf dans le lagon. Si tu entends « blub », c'est normal. Si tu entends « BLUB », viens me chercher.",
	"Gustave veut un masque pour Firmin. Firmin n'en veut pas. Il dit que la mer, c'est comme le Désert, mais mouillé.",
	"Un masque de plongée, c'est une question de joint. Le joint, c'est une question de gomme. La gomme, c'est une question de fougère. Tout est une question de fougère, en fait.",
]
const JOSS_HAVRE_AGAIN := [
	"Je fais l'aller-retour avec La Sardine. Gustave rame, Firmin chante, et moi, je suis malade. C'est une bonne équipe.",
	"Des masques de plongée, des gilets, des selles… Un jour, je ferai un harnais pour voler. Mais d'abord, je vais m'asseoir. Sur la terre ferme.",
]


# ------------------------------------------------------------------ Joss by the lagoon

## Joss on the lagoon's south shore (Npc « JossCote », event « joss_cote »): the first time,
## the jar, the net, Nessie and the mask; after the cache's ledger, Ferréol's order torn up;
## otherwise a line and the questions.
static func joss(who: Node) -> void:
	if not Game.flag(&"joss_cote_vu"):
		S.lock(true)
		await S.say(_jar(who))
		Game.set_flag(&"joss_cote_vu")
		await _the_net(who)
		await _the_mask(who)
		Game.award_team_xp(XP_JOSS)
		Save.save_game()
		S.lock(false)
		return
	if Game.flag(&"caisses_fouillees") and not Game.flag(&"joss_ferreol"):
		S.lock(true)
		await S.say(_torn_order(who))
		Save.save_game()
		S.lock(false)
		return
	var line: String
	if Game.flag(&"coeur_3") and not Game.flag(&"joss_apres_coeur"):
		Game.set_flag(&"joss_apres_coeur")
		line = "Tu es descendue jusqu'au récif ?! Avec MON masque ? … Je vais le raconter à tout le Havre. Deux fois."
	else:
		var k := int(Game.flag(&"joss_cote_n"))
		Game.set_flag(&"joss_cote_n", k + 1)
		line = JOSS_AGAIN[k % JOSS_AGAIN.size()]
	await A.menu(&"joss", JOSS, line, A.joss_topics())


## The jar on his head, an ammonite on the glass; Ferréol's order; the first mask for Chloé.
static func _jar(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var drips := func() -> void:
		Stage.look_at(at, 0.6)
		# He comes out of the lagoon backwards, still facing the water, dripping.
		var wet := CS.Act.water_near(at, 4)
		if wet != at and who is Npc:
			CS.step_aside(who, 66.0)   # (from where he will stand: Chloé does not hide him)
			var npc := who as Npc
			var back := SheetFrames.direction_name(wet - at)
			await Stage.fade_out(npc, 0.25, false)
			Stage.dress(npc, &"bocal")   # the jar on his head, prototype n° 7 (Outfits)
			npc.global_position = wet
			Stage.fade_in(npc, 0.3)
			CS.splash(wet, 14, CS.Act.ON_WATER, 0.4)
			npc.walk_to(at, back, JOSS_WADE)
			npc.sprite.play(StringName("walk_" + back))
			await S.wait(wet.distance_to(at) / JOSS_WADE)
		else:
			Stage.dress(who, &"bocal")
		CS.splash(at + Vector2(0.0, -30.0), 12, 0.3)
		Stage.tremble(who, 1.6, 1.6)
	var unsticks := func() -> void:
		await CS.step_aside(who, 50.0)
		await CS.reach(chloe, at + Vector2(0.0, -40.0), 10.0, 0.9)
		var puddle := CS.Act.water_near(at, 3)
		CS.splash(puddle, 5, CS.Act.ON_WATER, 0.2)
	return [
		CS.cue({"text": "Au bord du lagon, quelqu'un sort de l'eau à reculons. Sur sa tête, un bocal de verre cousu à un col de cuir. Dans le bocal, un garçon. Trempé."}, drips),
		CS.cue({"text": "Collée sur la vitre, une ammonite le regarde. Il la regarde aussi. Ça dure."},
			func() -> void: CS.later(0.6, func() -> void: Stage.emote(who, "?"))),
		CS.cue({"who": JOSS, "text": "Chloé ? C'est toi ? Il y a quelque chose sur ma vitre. Il me regarde."},
			func() -> void: Stage.turn_to(who, chloe.global_position)),
		CS.cue({"text": "Chloé décolle l'ammonite, tout doucement. Elle fait « plop », puis elle file dans une flaque."}, unsticks),
		CS.cue({"who": JOSS, "text": "Merci. … Ne dis rien sur le bocal. C'est un prototype. Le numéro sept."},
			func() -> void: Stage.bow(who, 0.8)),
		{"who": JOSS, "text": "Les six premiers, n'en parlons pas. Le cinq a coulé. Le six aussi, mais plus lentement."},
		{"who": CHLOE, "text": "Qu'est-ce que tu fais ici, Joss ?"},
		CS.cue({"who": JOSS, "text": "Des masques de plongée ! Maître Ferréol m'en a commandé dix, pour ses « plongeurs ». Je ne sais pas qui sont ses plongeurs. Il paie d'avance : je ne pose pas de questions."},
			func() -> void: Stage.hop(who, 1, 7.0)),
		{"who": JOSS, "text": "Mais le premier, le vrai, je le voulais pour toi. Maïa a dit que tu viendrais ici. Maïa dit toujours tout ce que tu vas faire. Elle se trompe rarement. Ça l'énerve."},
	]


## The young Plesiosaurus in the net, by the flat rock: calmed, freed with Joss's scissors; it
## dives, comes back, and will not leave. Nessie joins Chloé.
static func _the_net(who: Node) -> void:
	var chloe := Stage.chloe()
	var water := S.at(P.PLESIOSAURE_EAU.x, P.PLESIOSAURE_EAU.y)
	var rock := S.at(P.BORD_PLESIOSAURE.x, P.BORD_PLESIOSAURE.y)
	var nessie := CS.stand_in(&"plesiosaurus", water, "NessieFilet", NESSIE_LEVEL)
	var net := CS.prop("filet", water + Vector2(0.0, 6.0), "FiletLagon")
	var cast := {"struggle": null}
	var shows := func() -> void:
		Stage.turn_to(who, water)
		Stage.look_at(water, 1.0)
		if nessie:
			Stage.fade_in(nessie, 0.4)
			cast["struggle"] = Stage.rage(nessie, rock + Vector2(0.0, 80.0), 0.8)
			CS.splash(water, 14)
	var to_the_rock := func() -> void:
		Stage.look_back()
		(who as Npc).walk_to(rock + Vector2(70.0, 16.0), "", 100.0)
		await CS.chloe_walk(rock, 120.0, 5.0)
		Stage.turn_to(chloe, water)
	var calms := func() -> void:
		await CS.kneel()
		Stage.stop(nessie, cast["struggle"])
		if nessie:
			Stage.turn_to(nessie, chloe.global_position)
	var still := func() -> void:
		var dino := CS.lead()
		if dino:
			await CS.lead_walk(chloe.global_position + Vector2(-50.0, 34.0), 50.0)
			Stage.turn_to(dino, water)
	var cuts := func() -> void:
		for i in 4:
			await CS.reach(chloe, water, 10.0, 0.7)
			CS.splash(water + Vector2(randf_range(-20.0, 20.0), 0.0), 4, CS.Act.ON_WATER, 0.1)
			if net:
				Stage.tremble(net, 0.3, 2.0)
	var lines: Array = [
		CS.cue({"who": JOSS, "text": "Et puis, tout à l'heure, sous l'eau, j'ai vu… un monstre. Un long cou, des nageoires comme des rames. Pris dans un filet, près de la roche plate. Il s'est jeté sur ma vitre."}, shows),
		{"who": JOSS, "text": "Regarde : la marque de ses dents. Enfin… de ses sourires. Il n'avait pas l'air méchant. Il avait l'air d'avoir peur."},
		CS.cue({"text": "Sur la roche plate, Chloé se penche. Dans l'eau, un jeune Plesiosaurus se débat, le long cou pris dans un vieux filet. Chaque fois qu'il tire, les mailles serrent plus fort."}, to_the_rock),
		CS.cue({"text": "Sur les flotteurs du filet, une petite plaque d'os gravée d'un masque."},
			func() -> void:
				Stage.bow(chloe, 0.8)
				CS.later(0.8, func() -> void: Stage.emote(chloe, "!"))),
		{"who": CHLOE, "text": "(L'Ombre Noire… Un filet comme celui du Vieux Rempart.)" if Game.flag(&"rempart_rencontre") else "(Un filet de l'Ombre Noire…)"},
		CS.cue({"text": "Chloé s'agenouille au bord de la roche et lui parle tout bas, comme Hélène parlait aux dinos qui ont peur."}, calms),
	]
	var lead := Game.lead_dino()
	if lead:
		lines.append(CS.cue({"text": "Derrière elle, %s s'arrête et ne bouge plus d'une écaille. Même sa queue se tient tranquille." % lead.nickname}, still))
	lines.append_array([
		CS.cue({"text": "Le Plesiosaurus cesse de tirer. Il la regarde, le souffle court."},
			func() -> void:
				if nessie:
					Stage.emote(nessie, "…")),
		CS.cue({"who": JOSS, "text": "Tiens. Mes ciseaux de sellier. Ils coupent le cuir, la corde… et parfois mes doigts."},
			func() -> void: CS.reach(who, chloe.global_position, 12.0, 0.9)),
		CS.cue({"text": "Maille après maille, Chloé coupe le filet. Doucement. Le Plesiosaurus ne bouge pas : il a compris."}, cuts),
		CS.cue({"text": "Le dernier nœud cède. Le filet glisse au fond, avec sa plaque d'os."},
			func() -> void:
				CS.splash(water, 10)
				if net:
					CS.Act.sink(net, 1.6, true, true)),
	])
	await S.say(lines)
	await _dives_and_comes_back(who, nessie, water)
	await _nessie_joins(nessie)
	CS.lead_back()
	CS.get_up(chloe, 0.5)


## Free: it dives and is gone… then bursts up again in front of the rock, soaking Joss; it lays
## its chin on the rock at Chloé's feet.
static func _dives_and_comes_back(who: Node, nessie: DinoNpc, water: Vector2) -> void:
	var chloe := Stage.chloe()
	var dives := func() -> void:
		CS.splash(water, 16)
		if nessie:
			await CS.Act.sink(nessie, 0.9, false, true)
		CS.later(0.8, func() -> void: Stage.emote(chloe, "…"))
	var bursts_up := func() -> void:
		if nessie == null:
			return
		var sprite := Stage.sprite_of(nessie)
		if sprite:
			sprite.position = Stage._rest(sprite)
		nessie.global_position = water.lerp(chloe.global_position, 0.3)
		nessie.modulate.a = 1.0
		CS.splash(nessie.global_position, 28, CS.Act.ON_WATER, 0.9)
		CS.splash((who as Node2D).global_position, 12, 0.6, 0.3)
		nessie.cry(&"neutre")
		Stage.hop(nessie, 1, 14.0)
		Stage.tremble(who, 1.0, 2.0)
		Stage.emote(who, "!")
	var chin := func() -> void:
		if nessie == null:
			return
		Stage.turn_to(nessie, chloe.global_position)
		await CS.Act.lean(nessie, chloe.global_position, 14.0, 1.6)
		Stage.emote(nessie, "♥")
	await S.say([
		CS.cue({"text": "Le Plesiosaurus plonge d'un coup et disparaît. L'eau se referme. Plus rien."}, dives),
		{"who": CHLOE, "text": "(Il est parti…)"},
		CS.cue({"text": "Et puis la surface se bombe, juste devant la roche, et PLOUF : il ressort en éclaboussant tout. Surtout Joss, qui venait de se sécher."}, bursts_up),
		{"who": JOSS, "text": "… Merci. Vraiment. J'avais presque réussi à être sec."},
		CS.cue({"text": "Le Plesiosaurus pose le menton sur la roche, aux pieds de Chloé. Il ne veut plus partir."}, chin),
		{"who": JOSS, "text": "On dirait le monstre du loch Ness ! En plus mignon."},
		{"who": CHLOE, "text": "Alors tu t'appelleras %s." % NESSIE},
		{"flag": &"filet_coupe"},
	])


## Nessie joins the party (or waits at the Cabinet, if Chloé wants it so).
static func _nessie_joins(nessie: DinoNpc) -> void:
	var d := Dino.create(&"plesiosaurus", NESSIE_LEVEL, NESSIE)
	var in_party: bool = await ForetCamp.make_room_for(d, "%s veut venir avec toi. Mais ton équipe est pleine : qui part attendre au Cabinet ?" % NESSIE)
	Game.set_flag(&"nessie")
	var joins := func() -> void:
		if nessie:
			Stage.hop(nessie, 2, 8.0)
			Stage.fade_out(nessie, 1.0, true)
	await S.say([CS.cue({"text": "%s rejoint ton équipe !" % NESSIE if in_party else "%s part attendre au Cabinet. Roc va avoir besoin d'une plus grande baignoire." % NESSIE}, joins)])
	if is_instance_valid(nessie):
		Stage.fade_out(nessie, 0.4, true)
	Game.award_team_xp(XP_NESSIE)


## The real mask (n° 8) and La Plongée; where the caves are.
static func _the_mask(who: Node) -> void:
	var chloe := Stage.chloe()
	var takes_out := func() -> void:
		Stage.turn_to(who, chloe.global_position)
		await Stage.bow(who, 0.9)
		await CS.reach(who, chloe.global_position, 12.0, 0.9)
		if ItemsDB.ITEMS.has(CS.MASK_ITEM):
			CS.Act.pop(chloe.global_position, CS.MASK_ITEM, 0.9)
	var lines: Array = [
		CS.cue({"text": "Joss fouille dans son sac étanche et en sort un masque : du cuir huilé, une vitre taillée, un joint en gomme de fougère, une sangle large comme la main."}, takes_out),
		{"who": JOSS, "text": "Le vrai. Le numéro huit. Regarde ces coutures. … En fait, tu n'as pas besoin de regarder : tu les connais. Elles sont parfaites, comme toujours."},
		{"who": JOSS, "text": "Avec le masque et un dino plongeur adulte dans ton équipe, tu peux descendre là où c'est trop profond pour nager : les passages noyés, les grottes… et le récif, si tu trouves la passe."},
	]
	Game.give_item(CS.MASK_ITEM)
	Game.set_flag(CS.MASK_FLAG)
	var step := CS.dive_step()
	var diver: Dino = CS.diver()
	if diver and diver.nickname == NESSIE:
		lines.append({"who": JOSS, "text": "Et tu as %s ! Il nage sous l'eau comme toi dans ton lit. Il sait quand tu as besoin d'air : fais-lui confiance." % NESSIE})
	elif diver:
		lines.append({"who": JOSS, "text": "Et ton %s sait plonger. Il sait quand tu as besoin d'air : fais-lui confiance." % diver.nickname})
	elif step != "":
		lines.append({"who": JOSS, "text": step})
	var points := func() -> void:
		var cove := S.at(P.ANSE_GROTTES.x, P.ANSE_GROTTES.y)
		Stage.turn_to(who, cove)
		Stage.look_at(cove, 1.2)
	lines.append(CS.cue({"who": JOSS, "text": "Les grottes sont sous les falaises de l'est : la crique se rejoint à la nage. C'est là que Gustave voit disparaître sa barque sans lanterne." if Game.flag(&"pecheurs_vus")
		else "Les grottes sont sous les falaises de l'est : la crique se rejoint à la nage. Gustave dit qu'une barque sans lanterne y disparaît, la nuit."}, points))
	lines.append(CS.cue({"text": "Chloé reçoit le masque de plongée de Joss !"}, func() -> void:
		Stage.look_back()
		Stage.companion_joy()))
	await S.say(lines)
	Toast.say(S.world().get_tree(), "Objet obtenu : le masque de plongée")


## Once Chloé has read the cache's ledger (« masques de plongée : 10 (le sellier) »): Joss tears
## up Ferréol's order. « Il n'aura rien. Pas une couture. »
static func _torn_order(who: Node) -> Array:
	var at: Vector2 = (who as Node2D).global_position
	var tears := func() -> void:
		for i in 3:
			await CS.reach(who, at + Vector2(0.0, -20.0), 6.0, 0.4)
			CS.Act.burst(at + Vector2(0.0, -10.0), PAPER, 8, 0.8, 0.4)
	return [
		{"who": CHLOE, "text": "Joss… Dans la grotte, il y avait un registre. « Masques de plongée : 10 (le sellier). » Au milieu des caisses d'ambre noir."},
		CS.cue({"who": JOSS, "text": "Ses « plongeurs »… C'étaient des plongeurs de l'Ombre Noire ?"},
			func() -> void: Stage.emote(who, "!")),
		CS.cue({"text": "Joss sort de sa poche une commande pliée en quatre, signée d'un grand F. Il la déchire en deux. Puis en quatre. Puis en tout petits morceaux."}, tears),
		CS.cue({"who": JOSS, "text": "Il n'aura rien. Pas une couture."}, func() -> void: Stage.rear(who, 0.8)),
		{"who": JOSS, "text": "Et il peut garder son argent d'avance. Je le rendrai. En pièces de un. Une par une. En le regardant dans les yeux."},
		{"flag": &"joss_ferreol"},
	]


## Joss at the Havre during the chapter (Story.run « joss », once on the Côte): his trips on La
## Sardine; after Maïa ran away, she sleeps at his place.
static func joss_havre() -> void:
	if Game.flag(&"maia_enfuie"):
		await S.say([
			{"who": JOSS, "text": "Maïa dort chez moi. Elle ne parle pas. Elle a juste demandé si j'avais un masque… pour ne plus voir personne."},
			{"who": JOSS, "text": "Je lui ai fait un chocolat chaud. Elle ne l'a pas bu. Caillou, si."},
		])
		return
	var k := int(Game.flag(&"joss_havre_cote_n"))
	Game.set_flag(&"joss_havre_cote_n", k + 1)
	await A.menu(&"joss", JOSS, JOSS_HAVRE_AGAIN[k % JOSS_HAVRE_AGAIN.size()], A.joss_topics())


# ------------------------------------------------------------------ the turtles' nest

## A nest of the turtles' beach (StoryProp « NidTortues », event « nid_tortues »): at dusk or at
## night, the hatchlings come out and run to the sea; two Masiakasaurus come for them, the lead
## dino drives them off; the last one lies on its back and Chloé turns it over. A side quest.
static func tortues(who: Node) -> void:
	if Game.flag(&"tortues_sauvees"):
		await S.say([{"text": "Le nid est vide. Dans le sable, de minuscules traces de pattes filent toutes vers la mer."}])
		return
	var phase := Game.phase()
	if phase != &"dusk" and phase != &"night":
		await S.say([CS.cue({"text": "Le sable du nid bouge à peine, comme s'il respirait. Les petits sortiront au crépuscule, quand le sable refroidit."},
			func() -> void: Stage.tremble(who, 0.8, 1.0))])
		return
	S.lock(true)
	var nest: Vector2 = (who as Node2D).global_position
	var sea := CS.Act.water_near(nest, 12)
	if sea == nest:
		sea = nest + Vector2(0.0, -6.0 * S.CELL)
	var babies: Array = []
	for i in HATCHLINGS:
		var b := CS.stand_in(&"archelon", nest + Vector2(-36.0 + 24.0 * i, 8.0 * (i % 2)), "BebeTortue%d" % i, 1)
		if b:
			babies.append(b)
	await S.say(_hatch(nest, sea, babies))
	var lead := Game.lead_dino()
	var raiders := _raiders(nest)
	await S.say(_raid(nest, raiders, lead))
	await S.say(_last_one(sea, babies))
	for b in babies:
		if is_instance_valid(b):
			b.queue_free()
	Stage.repaint(who, "nid_tortue_vide")   # (the zone shows it so from now on: NidTortues after_kind)
	CS.lead_back()
	Game.give_item("fougere", TURTLE_FERNS)
	Toast.say(S.world().get_tree(), "Objets obtenus : %d fougères curatives (dans le nid vide)" % TURTLE_FERNS)
	Game.award_team_xp(XP_TORTUES)
	Save.save_game()
	S.lock(false)


static func _hatch(nest: Vector2, sea: Vector2, babies: Array) -> Array:
	var pops := func() -> void:
		Stage.look_at(nest, 0.8)
		for b in babies:
			Stage.fade_in(b, 0.3)
			Stage.hop(b, 1, 5.0)
			CS.D._puff(b.global_position, 6, 0.1)
			await S.wait(0.35)
	var runs := func() -> void:
		for i in babies.size():
			var b: DinoNpc = babies[i]
			if i < babies.size() - 1:
				b.walk_to(b.global_position.lerp(sea, 0.45), 40.0 + 6.0 * i)
	return [
		CS.cue({"text": "Le sable du nid se soulève. Une petite tête sort. Puis une autre. Puis encore une autre."}, pops),
		CS.cue({"text": "Les bébés Archelons filent vers la mer, en ramant de leurs petites pattes dans le sable."}, runs),
	]


## Two Masiakasaurus coming out of the rocks for the hatchlings (made for the scene).
static func _raiders(nest: Vector2) -> Array:
	var out: Array = []
	var from := CS.Act.way_from(nest, Vector2(-1.0, 0.4), 3.0, 5.0)
	if from == Vector2.INF:
		from = nest + Vector2(-4.0 * S.CELL, 1.0 * S.CELL)
	for i in 2:
		var m := CS.stand_in(&"masiakasaurus", from + Vector2(0.0, 36.0 * i), "Masiakasaurus%d" % i)
		if m:
			out.append(m)
	return out


static func _raid(nest: Vector2, raiders: Array, lead: Dino) -> Array:
	var chloe := Stage.chloe()
	var sneak := func() -> void:
		Stage.look_at(nest.lerp(raiders[0].global_position if not raiders.is_empty() else nest, 0.5), 0.8)
		for m in raiders:
			Stage.fade_in(m, 0.5)
			(m as DinoNpc).walk_to(m.global_position.lerp(nest, 0.45), 60.0)
	var guard := func() -> void:
		var dino := CS.lead()
		var between: Vector2 = nest.lerp(raiders[0].global_position, 0.5) if not raiders.is_empty() else nest
		if dino:
			await CS.lead_walk(between, 150.0)
			Stage.lunge(dino, raiders[0].global_position if not raiders.is_empty() else between, 1.4)
		else:
			await CS.chloe_walk(between, 160.0, 1.2)
			Stage.hop(chloe, 2, 8.0)
	var flee := func() -> void:
		for m in raiders:
			Stage.emote(m, "!")
			var away: Vector2 = m.global_position + (m.global_position - nest).normalized() * 200.0
			(m as DinoNpc).walk_to(away, 170.0)
			Stage.fade_out(m, 0.9, true)
	var line := "%s se jette entre eux et les petits, et pousse son cri le plus terrible." % lead.nickname if lead \
		else "Chloé court se mettre entre eux et les petits, en tapant dans ses mains de toutes ses forces."
	return [
		CS.cue({"text": "Au bord des rochers, deux Masiakasaurus sortent de l'ombre. Leurs dents poussent vers l'avant : exprès pour attraper les petits."}, sneak),
		CS.cue({"text": line}, guard),
		CS.cue({"text": "Les Masiakasaurus détalent dans les rochers, la queue basse."}, flee),
	]


## The last hatchling on its back: Chloé turns it over; it nips her finger and runs to the sea;
## far out, a great turtle lifts its head.
static func _last_one(sea: Vector2, babies: Array) -> Array:
	var chloe := Stage.chloe()
	var last: DinoNpc = babies[-1] if not babies.is_empty() else null
	var on_its_back := func() -> void:
		CS.lead_back()
		if last:
			Stage.look_at(last.global_position, 0.6)
			last.sprite.flip_v = true
			Stage.tremble(last, 1.4, 2.0)
	var turns_over := func() -> void:
		if last == null:
			return
		await CS.chloe_walk(last.global_position + Vector2(-34.0, 10.0), 110.0, 1.6)
		await CS.reach(chloe, last.global_position, 10.0, 0.8)
		last.sprite.flip_v = false
		Stage.emote(chloe, "!")
		await last.walk_to(sea, 55.0)
		CS.splash(sea, 6, CS.Act.ON_WATER, 0.2)
	var others := func() -> void:
		for b in babies:
			if is_instance_valid(b) and b != last:
				b.walk_to(sea + Vector2(randf_range(-40.0, 40.0), 0.0), 50.0)
				Stage.fade_out(b, 2.4, false)
	var mother := func() -> void:
		var far := sea + Vector2(0.0, -4.0 * S.CELL)
		var big := CS.stand_in(&"archelon", far, "GrandeTortue")
		Stage.look_at(far, 1.2)
		if big:
			await Stage.fade_in(big, 0.8)
			Stage.rear(big, 1.4)
			CS.splash(far, 10)
			await S.wait(1.4)
			CS.Act.sink(big, 1.4, true, true)
	return [
		CS.cue({"text": "Le dernier petit est tombé sur le dos. Il agite ses quatre pattes dans le vide, très vexé."}, on_its_back),
		CS.cue({"text": "Chloé le retourne, tout doucement. Il lui pince le doigt, pour la forme… et court à l'eau."},
			func() -> void:
				others.call()
				turns_over.call()),
		CS.cue({"text": "Au large, une grande tortue lève la tête hors de l'eau. Elle regarde la plage longtemps. Puis elle replonge."}, mother),
		{"who": CHLOE, "text": "(Bon voyage, les petits.)"},
		{"flag": &"tortues_sauvees"},
	]
