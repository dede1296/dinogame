class_name CoteFin
## Chapter 5, the Côte Préhistorique, the end (docs/histoire.md, ch. 5, points 14, 15 and 18):
## back on the coast with the third Cœur, Moustique swoops on Chloé and leads her to the
## cliffs; on Hélène's lookout, Maïa has seen everything — her mother's boat going into the
## cliff, a caped figure in a black mask; Chloé tells or keeps silent; they open the tin box
## together (Caillou's horn): page 23, « Marraine », « Isaure et son bébé »; Maïa understands,
## refuses, will not fight, runs away; her cardboard mask stays with Chloé. The saddest moment of
## the game: no music, only the wind and the sea. Also Maïa at the Havre afterwards, and the
## Comptoir's warehouse (Ferréol, a side quest once the crates are read).
## Flags: moustique_vu, maia_guet_vue, found_journal_23, maia_enfuie, masque_carton,
## entrepot_ferreol.

const S := preload("res://story/story.gd")
const P := preload("res://story/cote_places.gd")
const CS := preload("res://story/cote_stage.gd")
const DC := preload("res://data/dialogue_cote.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const FERREOL := "Maître Ferréol"
const RUST: Array[Color] = [Color(0.62, 0.36, 0.2), Color(0.48, 0.3, 0.2), Color(0.8, 0.55, 0.35)]
const VIOLET := Color(0.62, 0.3, 1.0)
const XP_FIN := 60
const XP_ENTREPOT := 30
## Sitting at the edge, chin on her knees (a squash of the picture).
const SITTING := 0.26


# ------------------------------------------------------------------ Moustique

## Back on the Côte with the third Cœur (Cote.arrival): Maïa's Dimorphodon swoops on Chloé,
## circles her crying, tugs at her sleeve, flies off to the cliffs and back, and waits.
static func moustique() -> void:
	if Game.flag(&"moustique_vu"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.6)
	var chloe := Stage.chloe()
	var lookout := S.at(P.BELVEDERE.x, P.BELVEDERE.y)
	var from: Vector2 = chloe.global_position.lerp(lookout, 0.35)
	var bird := CS.stand_in(&"dimorphodon", from, "MoustiqueRetour")
	var swoops := func() -> void:
		if bird == null:
			return
		Stage.fade_in(bird, 0.3)
		bird.cry(&"attaque")
		await CS.fly(bird, chloe.global_position + Vector2(40.0, -10.0), 1.0, 40.0)
		await CS.circle(bird, chloe.global_position, 50.0, 1.6, 40.0)
		CS.reach(bird, chloe.global_position, 10.0, 0.5)
		CS.reach(chloe, chloe.global_position + Vector2(20.0, -10.0), 6.0, 0.5)
	var back_and_forth := func() -> void:
		if bird == null:
			return
		var mid: Vector2 = chloe.global_position.lerp(lookout, 0.3)
		await CS.fly(bird, mid, 1.0)
		await CS.fly(bird, chloe.global_position + Vector2(30.0, -20.0), 0.9)
		Stage.turn_to(bird, lookout)
		Stage.turn_to(chloe, lookout)
	await S.say([
		CS.cue({"text": "Un cri perçant tombe du ciel. Un tout petit ptérosaure fond sur Chloé, tourne autour d'elle en criant, et tire sur sa manche avec son bec."}, swoops),
		CS.cue({"who": CHLOE, "text": "Moustique ?! Qu'est-ce que tu fais là ? Où est Maïa ?"}, func() -> void: Stage.emote(chloe, "!")),
		CS.cue({"text": "Moustique file vers les falaises, revient, repart. Il ne crie plus. Il attend."}, back_and_forth),
		{"who": CHLOE, "text": "(Le belvédère… Maïa est là-haut. Il s'est passé quelque chose.)"},
		{"flag": &"moustique_vu"},
	])
	if bird:
		CS.fly(bird, lookout, 2.4)
		Stage.fade_out(bird, 2.4, true)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ Maïa has seen everything

## Maïa on the lookout (Npc « MaiaGuet », event « maia_guet »; with « CaillouGuet »): the end of
## the chapter. Once it has played, she is gone (hide_flag maia_enfuie).
static func maia(who: Node) -> void:
	if Game.flag(&"maia_enfuie") or not Game.flag(&"coeur_3"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	Audio.push_music(null, 2.5)
	var caillou = S.actor("CaillouGuet")
	Game.set_flag(&"maia_guet_vue")
	await S.say(_what_she_saw(who, caillou))
	await S.say(await _tell_or_not(who, caillou))
	await S.say(_the_box(who, caillou))
	await S.say(_page_23(who))
	await S.say(_refuses(who, caillou))
	await S.say(_the_mask_left())
	Audio.pop_music(3.0)
	Game.award_team_xp(XP_FIN)
	Save.save_game()
	S.lock(false)


## The tin box of the lookout (StoryProp « BoiteHelene », event « boite_helene »): shut by rust
## before; with Maïa there after the third Cœur, the end; afterwards, empty.
static func boite(who: Node) -> void:
	if Game.flag(&"found_journal_23"):
		await S.say([{"text": "La boîte d'Hélène, vide, le couvercle tordu par la corne de Caillou. Chloé la referme, comme on referme une porte."}])
		return
	if Game.flag(&"coeur_3") and not Game.flag(&"maia_enfuie"):
		var maia_npc = S.actor("MaiaGuet")
		if maia_npc:
			await maia(maia_npc)
			return
	var tries := func() -> void:
		await CS.reach(Stage.chloe(), (who as Node2D).global_position, 10.0, 0.8)
		Stage.tremble(who, 0.5, 2.0)
	var lines: Array = [CS.cue({"text": "Une boîte en fer, au fond d'une niche de la roche. Soudée par la rouille et le sel : impossible de l'ouvrir."}, tries)]
	if Game.flag(&"maia_falaises_vue"):
		lines.append({"who": CHLOE, "text": "(« On l'ouvrira ensemble, après notre défi. » Promis, Maïa.)"})
	await S.say(lines)


## She sits at the edge, chin on her knees, looking at the cove; she does not turn round. Last
## night she saw her mother's boat, and someone in a cape and a black mask in it.
static func _what_she_saw(who: Node, caillou) -> Array:
	var chloe := Stage.chloe()
	var cove := S.at(P.ANSE_GROTTES.x, P.ANSE_GROTTES.y)
	var comes := func() -> void:
		Stage.turn_to(who, cove)   # her back to Chloé: she looks down at the cove, and does not turn round
		CS.sit(who, SITTING, 0.6)
		if caillou:
			Stage.bow(caillou, 1.4)
			CS.crouch(caillou, 0.05, 1.0)
		await CS.step_aside(who, 62.0)
		Stage.turn_to(chloe, (who as Node2D).global_position)
	var lines: Array = [
		CS.cue({"text": "Au belvédère, Maïa est assise tout au bord, le menton sur les genoux. Elle regarde la crique, en bas. Caillou se tient debout à côté d'elle, la tête basse."}, comes),
		CS.cue({"text": "Elle ne se retourne pas."}, func() -> void: CS.later(1.0, func() -> void: Stage.emote(who, "…"))),
		{"who": MAIA, "text": "Cette nuit, j'étais ici. J'ai éteint ma lanterne, pour qu'on ne me voie pas."},
	]
	if Game.flag(&"barque_nuit_vue"):
		lines.append({"who": CHLOE, "text": "(La petite lumière qui s'est éteinte, sur la falaise… C'était elle.)"})
	if not Game.flag(&"maia_falaises_vue"):
		lines.append({"who": MAIA, "text": "C'est le poste de guet d'Hélène, ici. J'ai trouvé une vieille boîte, dans la roche. Je voulais l'ouvrir avec toi. Après notre défi."})
	lines.append_array([
		{"who": MAIA, "text": "J'ai vu la barque de maman. Je la reconnaîtrais entre mille : c'est moi qui ai repeint la rayure bleue, l'été dernier."},
		CS.cue({"who": MAIA, "text": "Elle est passée par le récif, sans lanterne. Et elle est entrée dans la falaise, là. Comme si la falaise l'avalait."},
			func() -> void: Stage.look_at(cove, 1.2)),
		{"who": MAIA, "text": "Et dedans, il y avait quelqu'un. Debout. Avec une cape. Et un masque noir."},
		CS.cue({"who": MAIA, "text": "Et ce matin, toi, tu es sortie de l'eau, là-bas, avec une lumière dans les mains."},
			func() -> void: Stage.look_at(S.at(P.PASSE.x, P.PASSE.y), 1.2)),
		CS.cue({"who": MAIA, "text": "Il l'a volée, hein ? Le Masque. Il a volé la barque de maman. Dis-moi que c'est ça."},
			func() -> void:
				Stage.look_back()
				Stage.turn_to(who, chloe.global_position)),
	])
	return lines


## Chloé tells what she saw in the cave (when she saw the boat), or does not know what to say,
## or keeps silent. Maïa will not hear it either way.
static func _tell_or_not(who: Node, caillou) -> Array:
	var chloe := Stage.chloe()
	var seen: bool = Game.flag(&"barque_isaure_vue")
	var options: Array = ["Lui dire ce qu'elle a vu dans la grotte", "Ne rien dire"] if seen else ["« Je ne sais pas, Maïa. »", "Ne rien dire"]
	var pick := await Dialogue.choose("", "Maïa attend. Que répond Chloé ?", options)
	var jumps_up := func() -> void:
		await CS.get_up(who, 0.3)
		Stage.hop(who, 1, 8.0)
		if caillou:
			CS.get_up(caillou, 0.4)
			Stage.shake(2.0, 0.4)
	if pick == 0 and seen:
		return [
			{"who": CHLOE, "text": "Maïa… Je l'ai vue, la barque. Dans la grotte, sous la falaise. Amarrée au milieu des caisses d'ambre noir."},
			{"who": CHLOE, "text": "Il y a ton nom, sur la proue."},
			CS.cue({"who": MAIA, "text": "Tu mens."}, jumps_up),
			{"who": MAIA, "text": "Tu MENS !"},
		]
	if pick == 0:
		return [
			{"who": CHLOE, "text": "Je ne sais pas, Maïa."},
			CS.cue({"who": MAIA, "text": "Si. Tu sais. Tu fais la même tête que maman, quand elle ne veut pas répondre."}, jumps_up),
		]
	return [
		CS.cue({"text": "Chloé ne dit rien. Elle n'y arrive pas."}, func() -> void: Stage.bow(chloe, 1.2)),
		CS.cue({"who": MAIA, "text": "Tu ne dis rien. Tu ne dis RIEN !"}, jumps_up),
	]


## The box: « after the challenge », they said; she opens it before. It will not budge; Caillou's
## horn: CLAC. Inside, in oilcloth, a page.
static func _the_box(who: Node, caillou) -> Array:
	var chloe := Stage.chloe()
	var box = S.actor("BoiteHelene")
	var box_at: Vector2 = (box as Node2D).global_position if box is Node2D else S.at(P.BELVEDERE.x + 1.5, P.BELVEDERE.y - 1.0)
	var to_the_box := func() -> void:
		if who is Npc:
			await (who as Npc).walk_to(box_at + Vector2(-34.0, 16.0), "", 90.0)
		Stage.turn_to(who, box_at)
		CS.crouch(who, 0.12, 0.4)
	var pulls := func() -> void:
		for i in 3:
			await CS.reach(who, box_at, 10.0, 0.5)
			if box:
				Stage.tremble(box, 0.3, 2.0)
	var horn := func() -> void:
		if caillou is DinoNpc:
			await (caillou as DinoNpc).walk_to(box_at + Vector2(46.0, 20.0), 70.0)
			Stage.turn_to(caillou, box_at)
			await Stage.bow(caillou, 0.6)
			Stage.lunge(caillou, box_at, 0.6, false)
		CS.sfx("res://assets/audio/sfx/latch.wav", -2.0)
		CS.Act.burst(box_at, RUST, 16, 0.3, 0.4)
	var page := func() -> void:
		await CS.reach(who, box_at, 12.0, 0.9)
		CS.sparkle(box_at, 0.4, 8, 0.15)
	var sits_by_her := func() -> void:
		await CS.chloe_walk(box_at + Vector2(-80.0, 20.0), 110.0, 3.5)
		Stage.turn_to(chloe, box_at)
		CS.sit(chloe)
	return [
		CS.cue({"who": MAIA, "text": "La boîte. On avait dit : après le défi. … On l'ouvre avant. J'ai besoin d'autre chose. N'importe quoi d'autre."}, to_the_box),
		CS.cue({"text": "Elle tire sur le couvercle. Il ne bouge pas. Elle tire encore, de toutes ses forces. Rien."}, pulls),
		CS.cue({"text": "Caillou s'approche. Il baisse la tête, cale une corne sous le couvercle… et CLAC : le couvercle saute."}, horn),
		CS.cue({"text": "Dedans, roulée dans une toile cirée, une page du journal."}, page),
		{"who": MAIA, "text": "C'est l'écriture d'Hélène… Lis, toi. Moi, je… Lis."},
		CS.cue({"text": "Chloé s'assoit à côté d'elle. Elles lisent ensemble."}, sits_by_her),
	]


static func _page_23(_who: Node) -> Array:
	return [
		{"letter": DC.PAGE_23, "sign": "— H."},
		{"flag": &"found_journal_23"},
	]


## She understands on her own (« I. »), refuses it, will not fight, runs away; Caillou hesitates,
## then follows her; Moustique flies after them without a cry.
static func _refuses(who: Node, caillou) -> Array:
	var chloe := Stage.chloe()
	var lines: Array = [
		CS.cue({"text": "Maïa ne bouge plus. Le vent agite la page… non : c'est sa main qui tremble."}, func() -> void: Stage.tremble(who, 2.0, 1.2)),
		{"who": MAIA, "text": "Sa… marraine. Hélène était ma marraine."},
		{"who": MAIA, "text": "Maman ne me l'a jamais dit. Jamais. Elle disait juste : « On a été amies. Il y a longtemps. »"},
		CS.cue({"who": MAIA, "text": "« Isaure et son bébé. » … « I. »"}, func() -> void: Stage.emote(who, "!")),
	]
	if Game.flag(&"maia_defi_3"):
		lines.append({"who": MAIA, "text": "Tu cherchais « I. ». Depuis le Marais. « I. », qui avait la clé du Cabinet. Et moi, je te disais : « Irène, la poissonnière ? »"})
	else:
		lines.append({"who": MAIA, "text": "« I. »… L'amie de la barque, dans les pages d'Hélène. Celle qui avait la clé du Cabinet."})
	var steps_back := func() -> void:
		await CS.get_up(who, 0.3)
		Stage.recoil(who, chloe.global_position, 22.0)
	var flees := func() -> void:
		var at: Vector2 = (who as Node2D).global_position
		var away := CS.Act.way_from(at, S.at(P.TERRASSE.x, P.TERRASSE.y) - at, 3.0, 6.0)
		if away == Vector2.INF:
			away = at + Vector2(0.0, 5.0 * S.CELL)
		if who is Npc:
			(who as Npc).walk_to(away, "", 200.0)
		Stage.fade_out(who, 1.4, false)
	var caillou_goes := func() -> void:
		if caillou == null:
			return
		Stage.turn_to(caillou, chloe.global_position)
		await S.wait(0.9)
		await Stage.bow(caillou, 1.0)
		var at: Vector2 = (caillou as Node2D).global_position
		var away := CS.Act.way_from(at, S.at(P.TERRASSE.x, P.TERRASSE.y) - at, 3.0, 6.0)
		if caillou is DinoNpc and away != Vector2.INF:
			(caillou as DinoNpc).walk_to(away, 110.0)
		Stage.fade_out(caillou, 2.0, false)
	var bird_goes := func() -> void:
		var at: Vector2 = (who as Node2D).global_position if is_instance_valid(who) else chloe.global_position
		var bird := CS.stand_in(&"dimorphodon", at + Vector2(0.0, -20.0), "MoustiqueFuite")
		if bird:
			bird.modulate.a = 1.0
			CS.fly(bird, at + Vector2(-60.0, 5.0 * S.CELL), 2.0)
			Stage.fade_out(bird, 2.0, true)
	lines.append_array([
		{"who": MAIA, "text": "Non."},
		{"who": MAIA, "text": "Non, non, non."},
		{"who": MAIA, "text": "Maman, elle recoud les filets des autres quand ils sont trop fatigués. Elle chante des chansons de marin toutes fausses, exprès, pour me faire rire. Elle…"},
		{"who": MAIA, "text": "Elle n'a pas de masque."},
		CS.cue({"text": "Elle se relève d'un coup, et recule d'un pas."}, steps_back),
		{"who": CHLOE, "text": "Maïa… Notre défi. Le numéro cinq. Tu avais dit : ici, avec la mer derrière toi."},
		CS.cue({"who": MAIA, "text": "Je ne me bats pas. Pas contre toi. Pas aujourd'hui."}, func() -> void: Stage.tremble(who, 0.8, 1.5)),
		{"who": MAIA, "text": "Je ne veux plus gagner. Je veux juste que ce soit pas vrai."},
		CS.cue({"text": "Et elle s'enfuit en courant, par le sentier des falaises."}, flees),
		CS.cue({"text": "Caillou ne bouge pas tout de suite. Il regarde Chloé. Il regarde la boîte. Puis il suit Maïa, au petit trot, la tête basse."}, caillou_goes),
		CS.cue({"text": "Moustique s'envole derrière eux, sans un cri."}, bird_goes),
		{"flag": &"maia_enfuie"},
	])
	return lines


## Her cardboard mask, fallen from her bag: the wind pushes it to the edge, Chloé catches it.
## The Pteranodons wheel without a cry. « Hélène… Tu savais. »
static func _the_mask_left() -> Array:
	var chloe := Stage.chloe()
	var edge: Vector2 = S.at(P.BELVEDERE.x - 1.7, P.BELVEDERE.y - 0.8)   # the terrace's west lip, over the cove
	var sea: Vector2 = S.at(P.BELVEDERE.x - 8.0, P.BELVEDERE.y + 1.5)    # the cove's water, below
	var looks := func() -> void:
		CS.get_up(chloe, 0.5)
		Stage.bow(chloe, 1.0)
	var catches := func() -> void:
		await CS.chloe_walk(edge, 200.0, 0.8)
		Stage.hop(chloe, 1, 8.0)
		Stage.emote(chloe, "!")
		if ItemsDB.ITEMS.has("masque_carton"):
			Game.give_item("masque_carton")
			CS.Act.pop(chloe.global_position, "masque_carton", 0.9)
	var wheel := func() -> void:
		Stage.look_at(sea, 1.4)
		for i in 2:
			var radius := 120.0 + 40.0 * i
			var phase := PI * i
			var start: Vector2 = sea + Vector2(cos(phase), sin(phase) * 0.55) * radius
			var p := CS.stand_in(&"pteranodon", start, "PteranodonSilence%d" % i)
			if p:
				Stage.fade_in(p, 1.0)
				CS.circle(p, sea, radius, 4.0, CS.FLY_HEIGHT + 60.0, phase)
				CS.later(4.2, func() -> void: Stage.fade_out(p, 1.2, true))
	return [
		CS.cue({"text": "Sur la roche, là où Maïa était assise, quelque chose est tombé de son sac : le masque en carton noir qu'elle s'était fabriqué après la Forêt. L'élastique est cassé."}, looks),
		CS.cue({"text": "Le vent le pousse vers le bord. Chloé se jette dessus, et le rattrape juste avant le vide."}, catches),
		{"flag": &"masque_carton"},
		CS.cue({"text": "Au-dessus de la mer, les Ptéranodons tournent, sans un cri."}, wheel),
		CS.cue({"who": CHLOE, "text": "(Hélène… Tu savais. Depuis le début, tu savais.)"}, func() -> void: Stage.look_back(1.2)),
		{"who": CHLOE, "text": "(Maïa, je te le rendrai. Promis.)"},
		{"text": "(La suite de l'aventure arrive bientôt !)"},
	]


# ------------------------------------------------------------------ afterwards

## Maïa at the Havre once she has run away (Story.run « maia_havre »): she sits on a crate, Caillou
## against her; she does not look up. A line of hers (DialogueCote.chatter), no questions.
static func maia_havre(who: Node) -> void:
	var caillou = S.actor("Caillou")
	var line: Array = DialogueDB.chatter(&"maia_havre")
	await S.say([
		CS.cue({"text": "Maïa ne lève pas les yeux. Caillou pose sa grosse tête contre son épaule, et ne bouge plus."},
			func() -> void:
				Stage.bow(who, 1.2)
				if caillou:
					Stage.bow(caillou, 1.4)),
		line[0] if not line.is_empty() else {"who": MAIA, "text": "…"},
	])


## The Comptoir's warehouse at the Havre (Story.run « entrepot », once the cache's crates are
## read): the same crates through a crack, a bone mask on a nail; Ferréol behind Chloé, calm.
## False when there is nothing of the chapter to play (the warehouse's usual lines then).
static func entrepot(who: Node) -> bool:
	if not Game.flag(&"caisses_fouillees"):
		return false
	if Game.flag(&"entrepot_ferreol"):
		await S.say([{"text": "L'entrepôt du Comptoir. Par la fente, la lueur violette. Maître Ferréol n'est pas loin. Il n'est jamais loin."}])
		return true
	var w = S.world()
	if w == null:
		return false
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else chloe.global_position + Vector2(0.0, -80.0)
	var behind: Vector2 = chloe.global_position + Vector2(-70.0, 60.0)
	var ferreol := S.stranger("FerreolEntrepot", "ferreol", behind, "up")
	ferreol.modulate.a = 0.0
	var peeks := func() -> void:
		Stage.turn_to(chloe, at)
		await Stage.bow(chloe, 1.2)
	var glows := func() -> void:
		CS.pulse(at + Vector2(0.0, 20.0), VIOLET, 2, 1.4, 1.8, 3.5)
	var appears := func() -> void:
		Stage.fade_in(ferreol, 0.6)
		ferreol.face(chloe.global_position)
		Stage.turn_to(chloe, ferreol.global_position)
		Stage.recoil(chloe, ferreol.global_position, 12.0)
		Stage.emote(chloe, "!")
	var leaves := func() -> void:
		Stage.bow(ferreol, 0.6)
		await ferreol.walk_to(ferreol.global_position + Vector2(-220.0, 60.0), "", 70.0)
		Stage.fade_out(ferreol, 0.6, true)
	var lines: Array = [
		CS.cue({"text": "Chloé colle un œil à une fente, entre deux planches. Dedans, des caisses. Les mêmes que dans la grotte, avec le même tampon."}, peeks),
		CS.cue({"text": "Une lueur violette filtre entre les couvercles. Et, pendu à un clou, un masque d'os."}, glows),
		CS.cue({"who": FERREOL, "text": "Belle vue, n'est-ce pas ?"}, appears),
		{"who": FERREOL, "text": "Le Comptoir achète, le Comptoir vend. Ce que les gens font de ce qu'ils achètent ne regarde personne. Pas même une Varenne."},
		{"who": CHLOE, "text": "C'est de l'ambre noir. Il rend les dinos fous de peur."},
		{"who": FERREOL, "text": "Je vends des caisses, mademoiselle. Je ne les ouvre pas. C'est ce qui fait de moi un excellent commerçant."},
		{"who": CHLOE, "text": "Et qui vous les apporte, la nuit, sans lanterne ?"},
		CS.cue({"who": FERREOL, "text": "La capitaine Kerval ? Une excellente cliente. Une amie, même. Demandez-lui : elle adore les questions."},
			func() -> void: Stage.hop(ferreol, 1, 4.0)),
	]
	if Game.flag(&"joss_ferreol"):
		lines.append({"who": FERREOL, "text": "Et dites à ce jeune Joss que je compte toujours sur mes neuf masques. Tout le monde finit par vendre, mademoiselle. Même les coutures."})
	else:
		lines.append({"who": FERREOL, "text": "Tout le monde finit par vendre, mademoiselle. Tout. Même les souvenirs."})
	lines.append_array([
		CS.cue({"text": "Il soulève son chapeau, et s'en va d'un pas tranquille. Il n'a même pas peur."}, leaves),
		{"who": CHLOE, "text": "(Il sait que je n'ai rien contre lui. Pas encore.)"},
		{"flag": &"entrepot_ferreol"},
	])
	await S.say(lines)
	if is_instance_valid(ferreol):
		ferreol.queue_free()
	Game.award_team_xp(XP_ENTREPOT)
	Save.save_game()
	S.lock(false)
	return true
