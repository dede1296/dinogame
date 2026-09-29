class_name MontsFin
## Chapter 6, the Monts Gelés, the end (docs/histoire.md, ch. 6, point 5): out of the sanctuary
## with the fourth Cœur, Maïa is waiting in the snow, in Joss's coat, her eyes red — not from
## the cold. She asked her mother everything; her mother did not deny; she put her cup down, very
## gently. « Je veux l'arrêter. Pas la perdre. » Her cardboard mask back (« je le lui rendrai, à
## elle »); challenge n° 5, not to win: to know if she is ready; then they team up (maia_alliee)
## and look up at the Cieux. Also Roc at the Cabinet during the chapter (thé chaud, the three
## little ones, « Toupet », Maïa), Maïa and Joss at the Havre.
## Flags: maia_monts_vue, maia_defi_5, maia_alliee, masque_rendu, roc_monts_the,
## roc_dormeurs, roc_sceau_monts, roc_maia_alliee; maia_monts_n, joss_monts_n (lines).

const S := preload("res://story/story.gd")
const P := preload("res://story/monts_places.gd")
const MS := preload("res://story/monts_stage.gd")
const CS := preload("res://story/cote_stage.gd")
const A := preload("res://story/monts_ask.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ROC := "Prof. Roc"
const JOSS := "Joss"
const ROSALIE := "Rosalie"
## Maïa's fifth challenge (checked by simulation: scratchpad ch6/sim_monts.gd, docs/histoire.md
## § 6): Pouce the Iguanodon, Moustique, her own hatchling, then Caillou the Triceratops.
const MAIA_LEVELS := {"pouce": 35, "moustique": 36, "starter": 37, "caillou": 38}
const XP_MAIA := 120
const SITTING := 0.24
## Nose to nose with Caillou: the share of their two half-lengths between their middles (a little
## under 1: the snouts meet), and the gap when a size is unknown (m).
const NOSE_SHARE := 0.85
const NOSE_GAP := 3.5
const MAIA_AGAIN := [
	"Joss coud le harnais de vol. Il a dit : « trois jours ». Ça veut dire une semaine.",
	"Moustique ne quitte plus ma capuche. Il dit qu'il fait trop froid pour être courageux.",
	"Tu sais ce qui est bizarre ? Je n'ai plus envie de gagner. J'ai envie qu'on y arrive. Toutes les deux.",
	"Caillou a essayé de charger un flocon. Il l'a eu. Enfin, il le dit.",
]
const JOSS_MONTS := [
	"Maïa a dormi chez moi trois nuits. Elle n'a presque rien dit. Elle a juste demandé mon manteau le plus chaud. Je lui ai donné. C'était mon meilleur. Regarde ces coutures… enfin, elle les a emportées.",
	"Tu montes aux Monts ? Prends des gants. Moi, j'en ai cousu une paire avec un pouce de trop. Ne me demande pas comment.",
]
const JOSS_HARNESS := [
	"Maïa m'a demandé un harnais de vol. UN HARNAIS DE VOL. Je n'ai jamais cousu de harnais de vol. … Je vais coudre un harnais de vol.",
	"Un harnais pour un ptérosaure grand comme une maison. Il me faut du cuir, des sangles, et quelqu'un pour tester. Pas moi. Surtout pas moi.",
]


# ------------------------------------------------------------------ Maïa comes back

## Maïa in front of the sanctuary (Npc « MaiaMonts », event « maia_monts », there once the fourth
## Cœur is Chloé's; played as Chloé comes out, Monts.arrival): what she asked her mother, « je
## veux l'arrêter, pas la perdre », the mask, the challenge; won, they team up. Afterwards, a line
## and the questions.
static func maia(who: Node) -> void:
	if Game.flag(&"maia_alliee"):
		var k := int(Game.flag(&"maia_monts_n"))
		Game.set_flag(&"maia_monts_n", k + 1)
		await A.menu(&"maia", MAIA, MAIA_AGAIN[k % MAIA_AGAIN.size()], Ask.story_topics())
		return
	if not Game.flag(&"coeur_4"):
		return
	var caillou = S.actor("CaillouMonts")
	if not Game.flag(&"maia_monts_vue"):
		S.lock(true)
		await S.say(_waiting(who, caillou))
		await S.say(_her_mother(who))
		await S.say(_the_mask(who))
		Game.set_flag(&"maia_monts_vue")
		Save.save_game()
		S.lock(false)
	var prompt := "Pas pour gagner. Pour savoir si je suis prête. Montre-moi." if not Game.flag(&"maia_defi_5_tente") \
		else "On recommence ? Caillou a mangé de la neige : il est en pleine forme."
	var pick := await Dialogue.choose(MAIA, prompt, ["Relever le défi", "Plus tard"])
	if pick != 0:
		await S.say([{"who": MAIA, "text": "Je t'attends ici. Je ne bouge pas. … Enfin, je bouge un peu, sinon je gèle."}])
		return
	Game.set_flag(&"maia_defi_5_tente")
	if not await S.duel(MAIA, _team(), {"lose_spawn": P.SPAWN_SANCTUAIRE}):
		await S.say([{"who": MAIA, "text": "J'ai… gagné ? Non. Ça ne compte pas. Soigne ton équipe et reviens : je veux un vrai combat, avec toi au mieux de ta forme."}])
		return
	await _beaten(who, S.actor("CaillouMonts"))


## She sits on a rock in the snow, in a coat too big for her; Caillou beside her, white with
## snow; Moustique pokes out of her hood. She gets up: her eyes are red.
static func _waiting(who: Node, caillou) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var cast := {}
	var shows := func() -> void:
		Stage.look_at(at, 1.2)
		CS.step_aside(who, 90.0, -1.0)   # (beside her, on the left: Caillou is on her right)
		CS.sit(who, SITTING, 0.5)
		if caillou:
			MS.snow_puff((caillou as Node2D).global_position, 10, 1.2, 0.4)
			MS.breath(caillou, 8)
	var calls := func() -> void:
		Stage.hop(chloe, 1, 8.0)
		await CS.chloe_walk(at + Vector2(-70.0, 30.0), 130.0, 3.0)
		Stage.turn_to(chloe, at)
	var gets_up := func() -> void:
		await CS.get_up(who, 0.5)
		Stage.turn_to(who, chloe.global_position)
		Stage.look_back(0.6)
	var moustique := func() -> void:
		var bird := CS.stand_in(&"dimorphodon", at + Vector2(0.0, -8.0), "MoustiqueCapuche")
		cast["bird"] = bird
		if bird == null:
			return
		Stage.fade_in(bird, 0.3)
		bird.cry(&"neutre")
		await CS.fly(bird, chloe.global_position + Vector2(20.0, -10.0), 0.8, 30.0)
		await CS.circle(bird, chloe.global_position, 40.0, 1.2, 30.0)
		await CS.fly(bird, at + Vector2(0.0, -8.0), 0.6, 20.0)
		Stage.fade_out(bird, 0.3, true)
	return [
		CS.cue({"text": "Devant le sanctuaire, quelqu'un attend, assis dans la neige, un grand manteau sur les épaules. À côté, un Tricératops, de la neige plein la collerette, souffle de la vapeur par les naseaux."}, shows),
		CS.cue({"who": CHLOE, "text": "Maïa !"}, calls),
		CS.cue({"text": "Maïa se lève. Elle a les yeux rouges. Pas à cause du froid."}, gets_up),
		CS.cue({"text": "De sa capuche sort une petite tête pointue : Moustique. Il voit Chloé, pousse un cri de joie et fait le tour de sa tête avant de retourner au chaud."}, moustique),
		{"who": MAIA, "text": "Joss m'a prêté son manteau. Il est trop grand. Il sent la colle à cuir."},
	]


## What she asked her mother; « elle a reposé sa tasse, très doucement »; « je veux
## l'arrêter, pas la perdre ».
static func _her_mother(who: Node) -> Array:
	var chloe := Stage.chloe()
	var lines: Array = [
		{"who": MAIA, "text": "Je suis rentrée au port. J'ai attendu maman dans la cuisine, toute la nuit, sans allumer la lampe."},
		{"who": MAIA, "text": "Quand elle est rentrée, elle avait de la cendre sur ses bottes. Alors je lui ai tout demandé. La barque. La grotte. Hélène. « I. »."},
		CS.cue({"who": MAIA, "text": "Elle n'a pas dit non."}, func() -> void: Stage.bow(who, 1.2)),
		{"who": MAIA, "text": "Elle n'a rien dit du tout. Elle a juste reposé sa tasse. Très doucement."},
	]
	if Game.flag(&"found_journal_11"):
		lines.append({"who": CHLOE, "text": "(« Elle a reposé sa tasse, très doucement, et elle est partie. Elle n'a pas claqué la porte. C'est pire. » La page d'Hélène…)"})
	lines.append_array([
		{"who": MAIA, "text": "Alors c'est moi qui suis partie. Et maintenant, je sais."},
		CS.cue({"text": "Maïa serre les poings dans ses manches trop longues."}, func() -> void: Stage.tremble(who, 1.2, 1.4)),
		{"who": MAIA, "text": "Je ne veux pas qu'elle fasse peur aux dinos. Je ne veux pas qu'elle réveille ce qu'il y a sous le volcan. Je ne veux pas qu'elle gagne."},
		{"who": MAIA, "text": "Je veux l'arrêter."},
		CS.cue({"who": MAIA, "text": "Pas la perdre."}, func() -> void: CS.later(0.6, func() -> void: Stage.emote(chloe, "…"))),
	])
	return lines


## The cardboard mask Chloé caught on the lookout: Maïa folds it into her pocket. « Je le lui
## rendrai. À elle. » Then the challenge: not to win, to know if she is ready.
static func _the_mask(who: Node) -> Array:
	var chloe := Stage.chloe()
	var lines: Array = []
	if Game.flag(&"masque_carton"):
		var gives := func() -> void:
			await CS.reach(chloe, (who as Node2D).global_position, 12.0, 1.0)
			if ItemsDB.ITEMS.has("masque_carton"):
				CS.Act.pop((who as Node2D).global_position, "masque_carton", 1.2)
			Game.items.erase("masque_carton")
		var folds := func() -> void:
			for i in 2:
				await CS.reach(who, (who as Node2D).global_position + Vector2(0.0, 20.0), 5.0, 0.5)
			Stage.bow(who, 0.8)
		lines.append_array([
			CS.cue({"who": CHLOE, "text": "Maïa… Tu avais laissé ça, au belvédère."}, gives),
			{"text": "Le masque en carton noir. L'élastique est toujours cassé."},
			{"who": MAIA, "text": "Mon masque… Je l'avais fait pour lui ressembler. « Trop stylé », je disais."},
			CS.cue({"text": "Elle le plie en deux, très soigneusement, et le glisse dans sa poche."}, folds),
			{"who": MAIA, "text": "Je le garde. Le jour où maman enlèvera le sien… je lui rendrai celui-là."},
			{"flag": &"masque_rendu"},
		])
	var squares := func() -> void:
		Stage.turn_to(who, chloe.global_position)
		Stage.rear(who, 0.8)
		var caillou = S.actor("CaillouMonts")
		if caillou:
			CS.D._snort(caillou)
	lines.append_array([
		{"who": MAIA, "text": "Mais d'abord, notre défi. Le numéro cinq. On ne l'a jamais fait."},
		CS.cue({"who": MAIA, "text": "Si je ne suis pas capable de me battre contre toi, je ne serai jamais capable de lui parler, à elle. Alors on se bat. Pour de vrai."}, squares),
	])
	return lines


## Pouce the Iguanodon, Moustique, her own hatchling, then Caillou (« pour nous »).
static func _team() -> Array:
	var team: Array = [[&"iguanodon", MAIA_LEVELS["pouce"], "Pouce"],
		[&"dimorphodon", MAIA_LEVELS["moustique"], "Moustique", {
			"before": [{"who": MAIA, "text": "Moustique ! Sors de ma capuche. … Oui, il fait froid. Oui, c'est important."}]}]]
	var mine := StringName(str(Game.flag(&"maia_starter")))
	if SpeciesDB.PATHS.has(mine):
		team.append([mine, MAIA_LEVELS["starter"], MS.maia_starter_name()])
	team.append([&"triceratops", MAIA_LEVELS["caillou"], "Caillou", {
		"before": [{"who": MAIA, "text": "Caillou… Celui-là, c'est pour maman."},
			{"who": MAIA, "text": "Non. Celui-là, c'est pour nous."},
			CS.cue({"text": "Le sol tremble. Caillou avance dans la neige, les cornes baissées, un lacet gelé qui pend de sa bouche."},
				func() -> void:
					Stage.shake(3.0, 0.8)
					var tri = S.actor("CaillouMonts")
					if tri:
						Stage.lunge(tri, Stage.chloe().global_position, 1.2)
						MS.snow_puff((tri as Node2D).global_position, 16, 0.3, 0.5))],
		"intro": "Maïa envoie Caillou, le Tricératops !",
	}])
	return team


## Five times. She laughs a little, through her tears: she does not care; she held on. They
## team up: a hand held out, Caillou and the lead dino nose to nose; Dame Suie's clue; they look
## up: the Cieux, and something huge wheeling there. « À suivre… »
static func _beaten(who: Node, caillou) -> void:
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var hands := func() -> void:
		await CS.chloe_walk(at + Vector2(-48.0, 14.0), 90.0, 1.4)
		Stage.turn_to(chloe, at)
		Stage.turn_to(who, chloe.global_position)
		CS.reach(who, chloe.global_position, 12.0, 1.6)
		await CS.reach(chloe, at, 12.0, 1.6)
		Stage.emote(who, "♥")
		Stage.emote(chloe, "♥")
	var noses := func() -> void:
		var dino := CS.lead()
		if dino and caillou is Node2D:
			# On Caillou's far side from the girls: he turns to it, away from them (never his head over them).
			var cx: Vector2 = (caillou as Node2D).global_position
			var side := 1.0 if cx.x >= chloe.global_position.x else -1.0
			await CS.lead_walk(cx + Vector2(side * _nose_gap(dino, caillou), 12.0), 160.0)
			Stage.turn_to(dino, cx)
			Stage.turn_to(caillou, dino.global_position)
			CS.Act.lean(dino, (caillou as Node2D).global_position, 10.0, 1.6)
			CS.Act.lean(caillou, dino.global_position, 10.0, 1.6)
	var up := func() -> void:
		CS.lead_back()
		var sky := S.at(P.SORTIE_CIEUX.x, P.SORTIE_CIEUX.y)
		Stage.turn_to(chloe, sky)
		Stage.turn_to(who, sky)
		await CS.pan(sky, 2.4)
		var big := CS.stand_in(&"pteranodon", sky + Vector2(-120.0, 40.0), "GeantDesCieux", 0, 1.6)
		if big:
			big.modulate = Color(0.55, 0.58, 0.68, 0.0)
			big.create_tween().tween_property(big, "modulate:a", 0.85, 1.2)
			await CS.circle(big, sky, 140.0, 5.0, CS.FLY_HEIGHT + 180.0)
			Stage.fade_out(big, 1.2, true)
	var lines: Array = [
		{"who": MAIA, "text": "Cinq. Cinq fois."},
		CS.cue({"text": "Maïa rit un peu. Elle pleure un peu aussi. Les deux en même temps."}, func() -> void:
			Stage.hop(who, 1, 6.0)
			Stage.tremble(who, 0.8, 1.0)),
		{"who": MAIA, "text": "Et tu sais quoi ? Je m'en fiche. Pour la première fois de ma vie, je m'en fiche complètement."},
		{"who": MAIA, "text": "J'ai tenu. Caillou a tenu. On n'a pas reculé. Pas une fois."},
		{"who": CHLOE, "text": "Tu es prête, Maïa."},
		{"who": MAIA, "text": "Alors on fait équipe. Toi et moi. Plus de défis."},
		{"who": MAIA, "text": "… Enfin, plus de défis pendant un moment."},
		CS.cue({"text": "Maïa tend la main. Chloé la prend."}, hands),
		CS.cue({"text": "Caillou et %s se touchent le museau. Moustique pousse un cri si fort qu'une plaque de neige glisse de la montagne, très loin." % Game.lead_dino().nickname if Game.lead_dino()
			else "Caillou pousse un grondement content. Moustique pousse un cri si fort qu'une plaque de neige glisse de la montagne, très loin."}, noses),
		{"flag": &"maia_defi_5"},
		{"flag": &"maia_alliee"},
	]
	if Game.flag(&"suie_indice"):
		lines.append_array([
			{"who": CHLOE, "text": "Dame Suie m'a dit quelque chose. Le Masque veut tous les Cœurs d'un coup. Dans les Cieux."},
			{"who": MAIA, "text": "Les Cieux… Les pitons, au-dessus des nuages ? Maman disait qu'on n'y monte pas. Qu'il faudrait voler."},
		])
	else:
		lines.append({"who": MAIA, "text": "Tu as vu ton Titan ? Il regardait le ciel en grondant. Maman dit qu'au-dessus des Monts, il y a les Cieux. Qu'on n'y monte pas. Qu'il faudrait voler."})
	lines.append_array([
		CS.cue({"text": "Elles lèvent les yeux. Au-dessus des Monts, dans les nuages, des pitons de roche flottent presque. Et quelque chose d'immense y tourne, les ailes grandes ouvertes."}, up),
		{"who": MAIA, "text": "Joss parlait d'un harnais de vol. Pour les très grands ptérosaures. Il dit que ses coutures tiendraient. Il dit toujours ça."},
		{"who": MAIA, "text": "On y va ensemble. Et cette fois, c'est moi qui te suis. … Pour une fois."},
		{"who": MAIA, "text": "Et ma barque est à toi, quand tu veux. Le port, le Havre, la Côte, le Marais : je connais tous les chemins de la mer. C'est maman qui me les a appris."},
		CS.cue({"text": "À suivre… (les Cieux Éternels)"}, func() -> void: Stage.look_back(1.2)),
	])
	await S.say(lines)
	Game.award_team_xp(XP_MAIA)
	Save.save_game()
	S.lock(false)


## Between the middles of Chloé's lead dino and Caillou (px) for their snouts to meet: from what
## is drawn of each (DinoSize.length_px, at its size in the world).
static func _nose_gap(lead: Companion, caillou) -> float:
	var halves := 0.0
	if lead and lead.dino:
		halves += DinoSize.length_px(lead.dino.species(), DinoSize.world_scale(lead.dino)) * 0.5
	if caillou is DinoNpc and (caillou as DinoNpc).species:
		var npc := caillou as DinoNpc
		halves += DinoSize.length_px(npc.species, npc.species.world_scale * npc.share()) * 0.5
	return halves * NOSE_SHARE if halves > 0.0 else NOSE_GAP * S.CELL


# ------------------------------------------------------------------ Roc, at the Cabinet

## Talking to Roc during the chapter (Story.run « roc »): tea (hot, this time) once he has told
## everything; the three little ones from the ice; « Toupet »; Maïa's hug. True if he said something.
static func roc() -> bool:
	var todo: Array = []
	if Game.flag(&"roc_innocente") and not Game.flag(&"roc_monts_the"):
		todo.append(_roc_tea())
	if Game.flag(&"dormeurs_reveilles") and not Game.flag(&"roc_dormeurs"):
		todo.append(_roc_little_ones())
	if Game.flag(&"sceau_monts") and not Game.flag(&"roc_sceau_monts"):
		todo.append(_roc_sceau())
	if Game.flag(&"maia_alliee") and not Game.flag(&"roc_maia_alliee"):
		todo.append(_roc_maia())
	if todo.is_empty():
		return false
	var prof = S.actor("Roc")
	if prof is Node2D:   # beside him, not in front of him (the camera would see only her back)
		await CS.step_aside(prof, 66.0)
		Stage.turn_to(prof, Stage.chloe().global_position)
	for lines: Array in todo:
		await S.say(lines)
	return true


static func _roc_tea() -> Array:
	var prof = S.actor("Roc")
	var pours := func() -> void:
		if prof:
			await Stage.bow(prof, 0.8)
			CS.reach(prof, Stage.chloe().global_position, 10.0, 1.0)
			CS.Act.burst((prof as Node2D).global_position + Vector2(20.0, 0.0), MS.BREATH_BITS, 8, 1.2, 0.1)
	return [
		CS.cue({"who": ROC, "text": "Tiens. Du thé. Chaud, cette fois."}, pours),
		{"who": ROC, "text": "Depuis que je t'ai tout dit, là-haut, je dors mieux. Je sors encore la nuit, remarque. Mais je dors mieux."},
		{"flag": &"roc_monts_the"},
	]


static func _roc_little_ones() -> Array:
	var prof = S.actor("Roc")
	return [
		{"who": ROC, "text": "Trois petits sont arrivés ce matin, avec le troupeau de Bertille. Un Brachiosaure, un Stégosaure, et un Psittacosaure qui a le hoquet."},
		CS.cue({"who": ROC, "text": "Le Brachiosaure a mangé ma fougère en pot. Celle à qui je parlais quand je n'avais pas mes lunettes. Je ne sais pas si je dois le gronder ou le remercier."},
			func() -> void:
				if prof:
					Stage.emote(prof, "…")),
		{"who": ROC, "text": "Hélène les a mis dans la glace il y a quinze ans. « Pour plus tard », elle disait. … Plus tard, c'est toi, apparemment."},
		{"who": ROC, "text": "Ils sont dans la réserve, avec les autres. Si tu veux en emmener un, demande-moi."},
		{"flag": &"roc_dormeurs"},
	]


static func _roc_sceau() -> Array:
	var lines: Array = [
		{"who": ROC, "text": "Le Sceau des Monts… Toupet t'a laissée approcher ?"},
		{"who": CHLOE, "text": "Toupet ?"},
		{"who": ROC, "text": "Le Cryolophosaure. C'est moi qui l'ai appelé comme ça, à cause de sa crête. Il m'a regardé comme un glaçon mal rangé. Depuis, il me regarde toujours comme ça."},
	]
	if Game.flag(&"coeur_4"):
		lines.append({"who": ROC, "text": "Quatre Cœurs… Cette nuit, toute l'île a tremblé, et la couveuse a chanté toute seule. Il n'en manque plus qu'un, Chloé. Et c'est bien ce qui m'inquiète."})
	lines.append({"flag": &"roc_sceau_monts"})
	return lines


static func _roc_maia() -> Array:
	var prof = S.actor("Roc")
	return [
		CS.cue({"who": ROC, "text": "Maïa est passée, avec son Tricératops. Elle m'a serré dans ses bras. Sans prévenir. J'ai failli lâcher la théière."},
			func() -> void:
				if prof:
					Stage.hop(prof, 1, 4.0)),
		{"who": ROC, "text": "Les Kerval reviennent toujours au port. Je te l'avais dit."},
		{"flag": &"roc_maia_alliee"},
	]


# ------------------------------------------------------------------ the warm coat

## Rosalie, before her shop (Story.run « shop_mercerie »): her coat of down in the window, the
## first time; again when Chloé needs it to go up to the Monts.
static func rosalie(_who: Node) -> void:
	if Monts.has_coat():
		return
	if not Game.flag(&"rosalie_manteau"):
		Game.set_flag(&"rosalie_manteau")
		await S.say([{"who": ROSALIE, "text": "Tu as vu mon manteau de duvet, en vitrine ? Du duvet de dinos à plumes, ramassé à la mue : pas une plume arrachée. Chaud comme un nid. C'est pour là-haut, là où il neige."}])
		return
	if Game.flag(&"maia_enfuie") and not Game.flag(&"rosalie_manteau_monts"):
		Game.set_flag(&"rosalie_manteau_monts")
		await S.say([{"who": ROSALIE, "text": "Tu montes aux Monts Gelés ? Alors il te faut mon manteau de duvet. Sans lui, tu ne passerais pas le premier virage. Je l'ai remis en vitrine exprès pour toi."}])


## Joss by the lagoon (Story.run « joss_cote »), while Chloé has no warm coat: the coats Rosalie
## gave him « pour ceux qui montent », his lines and questions, and the coats to buy. False when
## CoteLagon.joss has a scene of its own to play (the first meeting, the torn order…), or once
## Chloé has her coat: then his usual lines.
static func joss_coat(who: Node) -> bool:
	if Monts.has_coat() or not Game.flag(&"joss_cote_vu"):
		return false
	if Game.flag(&"caisses_fouillees") and not Game.flag(&"joss_ferreol"):
		return false
	if Game.flag(&"coeur_3") and not Game.flag(&"joss_apres_coeur"):
		return false
	var prompt := ""
	if not Game.flag(&"joss_manteau_vu"):
		Game.set_flag(&"joss_manteau_vu")
		await S.say([
			CS.cue({"who": JOSS, "text": "Oh, et regarde : Rosalie m'a confié ses manteaux de duvet, « pour ceux qui montent ». Du duvet de dinos à plumes, ramassé à la mue. Chaud comme un nid."},
				func() -> void: Stage.bow(who, 0.8)),
			{"who": JOSS, "text": "Les coutures, c'est moi. Évidemment. Regarde ces coutures. Non, vraiment : regarde-les."},
		])
		prompt = "Tu en veux un ? Là-haut, dans les Monts, sans manteau, on gèle avant d'avoir dit « brrr »."
	else:
		prompt = ForetCamp.next_line(&"joss_cote_n", CoteLagon.JOSS_AGAIN)
	if await CoteAsk.menu(&"joss", JOSS, prompt, CoteAsk.joss_topics(), "Voir les manteaux"):
		var screen := ShopScreen.open(S.world(), &"joss_cote")
		await screen.closed
		Monts.update_access()
		if Monts.has_coat():
			await S.say([CS.cue({"who": JOSS, "text": "Il te va comme un gant. Enfin… comme un manteau. Tu vois, les coutures ? Parfaites."},
				func() -> void:
					Stage.hop(who, 1, 5.0)
					Stage.emote(Stage.chloe(), "♥"))])
	return true


# ------------------------------------------------------------------ at the Havre

## Maïa at the Havre once they have teamed up (Story.run « maia_havre »): a line of hers.
static func maia_havre(_who: Node) -> void:
	var line: Array = DialogueDB.chatter(&"maia_havre")
	await S.say([line[0] if not line.is_empty() else {"who": MAIA, "text": "On se retrouve aux Monts !"}])


## Joss at the Havre during the chapter (Story.run « joss », once in the Monts): Maïa's nights at
## his place, then the flying harness she asked him for.
static func joss_havre() -> void:
	var pool: Array = JOSS_HARNESS if Game.flag(&"maia_alliee") else JOSS_MONTS
	var line := ForetCamp.next_line(&"joss_monts_n", pool)
	await S.say([{"who": JOSS, "text": line}])
