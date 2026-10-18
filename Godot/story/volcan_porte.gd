class_name VolcanPorte
## Chapter 8, the Plaine Volcanique, the crater's door (zone porte_cratere; docs/chapitre-8-scenes.md,
## scene 9): a wooden gate with two leaves between two torches; Hélène's camp (a lantern, a blanket
## folded square, a cairn) and page 38; Isaure, standing with her back to Chloé, the four Cœurs in a
## sailor's bag; Maïa on a stone, Caillou who sneezes. Isaure's bargain (« Je ne vais pas te le
## prendre… Je vais te le demander. »; « on la sortira de là ») and Chloé's « Non. », not loud;
## nothing opens before dawn. The letter: Isaure takes it without opening it. Maïa: Moustique bites
## her ear, the first laugh of the chapter; « je serai de son côté de la porte. Pas contre toi. »
## No battle. The gate does not open: « À suivre… ».
## Flags: porte_arrivee, camp_helene_vu, found_journal_38 (DialogueVolcan, page_38), isaure_porte_vue,
## marche_refuse, lettre_isaure_donnee, maia_porte_vue, apex_bloque; isaure_porte_n, maia_porte_n.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const V := preload("res://story/volcan.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ISAURE := "Isaure"
const LETTER := "lettre_isaure"
const ISAURE_NODES := ["IsaurePorte"]
const MAIA_NODES := ["MaiaPorte"]
const CAILLOU_NODES := ["CaillouPorte"]
const TORCH := Color(1.0, 0.7, 0.35)
## Where Chloé stops before Isaure (px south of her), Moustique on a shoulder (Volcan's).
const BEFORE_ISAURE := Vector2(0.0, 120.0)
const ISAURE_AGAIN := [
	"Soigne ton équipe, moussaillon. Je ne veux pas gagner contre des dinos fatigués. Je veux gagner.",
	"Le cinquième bat trop fort. Ta grand-mère disait que c'était le plus bruyant. Je ne l'ai jamais entendu de près. Je ne l'ai jamais vu, non plus : ce jour-là, je regardais ailleurs.",
	"Je ne l'ai pas lue. Je la sens contre les Cœurs. C'est déjà beaucoup.",
	"Dis à Anselme… Non. Ne lui dis rien. Je lui dirai moi-même, ou je ne lui dirai pas.",
]
const MAIA_AGAIN := [
	"Brac m'a donné une carte de visite. Il y a de la cendre dessus. Je l'ai gardée : c'est la seule personne de l'Ombre Noire qui m'ait donné quelque chose au lieu de me le prendre.",
	"La dame en gris m'a regardée passer. Elle ne m'a rien dit. Elle a juste écrit quelque chose, et puis elle a arrêté d'écrire. C'était bizarre. C'était… gentil, je crois ?",
	"Si tu vas au Havre, dis à Joss que son manteau sent toujours la colle à cuir. Et que c'est le meilleur manteau du monde. Dans cet ordre.",
	"Tu as le gros de Brac ? Fournaise ? Il dort, lui aussi ? … Tout le monde dort dans ton équipe. C'est reposant.",
]
const XP_ARRIVEE := 30
const XP_ISAURE := 100
const XP_MAIA := 40


# ------------------------------------------------------------------ arriving

## 9 a, the first time at the door: the path still smoking, the gate between two torches; Isaure
## with her back to Chloé, Maïa on a stone, Caillou asleep, who lifts his head and sneezes.
static func arrival() -> void:
	if Game.flag(&"porte_arrivee"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.4)
	var chloe := Stage.chloe()
	var gate := V.at_node(["PortailApex"], V.spot("PORTAIL", Vector2(0.0, -7.0 * S.CELL)))
	var isaure_npc = V.actor_of(ISAURE_NODES)
	var maia_npc = V.actor_of(MAIA_NODES)
	var caillou_npc = V.actor_of(CAILLOU_NODES)
	if isaure_npc is Npc:
		(isaure_npc as Npc).face(gate)
	if maia_npc:
		Stage.sit(maia_npc)
	if caillou_npc:
		CS.crouch(caillou_npc, 0.25, 0.1)
	var up := func() -> void:
		await Stage.look_at(gate + Vector2(0.0, -2.0 * S.CELL), 1.8)
		torches(gate, 3)
	var three := func() -> void:
		for a in [isaure_npc, maia_npc, caillou_npc]:
			if a is Node2D:
				Stage.look_at((a as Node2D).global_position, 0.9)
				await S.wait(1.0)
		if caillou_npc:
			MS.breath(caillou_npc, 6)
	var sneezes := func() -> void:
		if caillou_npc:
			CS.get_up(caillou_npc, 0.4)
			Stage.rear(caillou_npc, 0.6)
			Stage.cry(caillou_npc, &"neutre")
			Act.burst((caillou_npc as Node2D).global_position + Vector2(0.0, -10.0), V.ASH_BITS, 12, 0.4, 0.4)
	var says := func() -> void:
		if maia_npc:
			Stage.look_at((maia_npc as Node2D).global_position, 0.6)
			Stage.turn_to(maia_npc, chloe.global_position)
	await S.say([
		CS.cue({"text": "Le chemin monte en lacets, et la roche fume encore là où la lave coulait tout à l'heure. En haut, le bord du cratère. Et dans la paroi, un portail de bois à deux battants, noirci, cerclé de fer, haut comme trois maisons. Deux torches, plantées dans la roche, brûlent de chaque côté."}, up),
		{"who": CHLOE, "text": "(La Terre des Apex. C'est derrière. Et elle est devant.)"},
		CS.cue({"text": "Devant le portail, le dos à Chloé, une femme debout, qui ne bouge pas. Sur une pierre à côté, une fille dans un manteau trop grand. Et derrière, couché, un Tricératops qui ronfle."}, three),
		CS.cue({"text": "Caillou lève la tête, renifle, et éternue dans la cendre."}, sneezes),
		CS.cue({"who": MAIA, "text": "Il éternue toujours quand c'est toi. Je ne sais pas pourquoi."}, says),
		{"flag": &"porte_arrivee"},
	])
	Stage.look_back()
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)


## The two torches flicker (lights of the 3D view), either side of the gate.
static func torches(gate: Vector2, times := 2) -> void:
	var placed = V._places().get("TORCHES")   # (VolcanPlaces.TORCHES: tiles)
	if placed is Array and not (placed as Array).is_empty():
		for t: Vector2 in placed:
			CS.pulse(S.at(t.x, t.y), TORCH, times, 0.9, 2.2, 3.5)
		return
	for side in [-1.0, 1.0]:
		CS.pulse(gate + Vector2(side * 2.5 * S.CELL, 0.4 * S.CELL), TORCH, times, 0.9, 2.2, 3.5)


# ------------------------------------------------------------------ Hélène's camp

## 9 b, Hélène's camp (StoryProp « CampHelene »; the page is the cairn's Pickup « page_38 »).
static func camp(_who: Node) -> void:
	if Game.flag(&"found_journal_38"):
		await S.say([{"text": "La couverture d'Hélène, pliée au carré. Chloé ne la déplie pas."}])
		return
	await S.say([DialogueVolcan.camp_line(), {"flag": &"camp_helene_vu"}])


# ------------------------------------------------------------------ Isaure

## 9 c, Isaure (Npc « IsaurePorte », event « isaure_porte »): the bargain and the « Non »; then the
## letter (9 d) and Maïa (9 e) at once. Afterwards, a line each time (the letter if still in the bag).
static func isaure(who: Node) -> void:
	if Game.flag(&"isaure_porte_vue"):
		if _has_letter():
			S.lock(true)
			await S.say(_the_letter(who))
			_letter_given()
			S.lock(false)
			return
		await S.say([CS.cue({"who": ISAURE, "text": _again()}, func() -> void:
			if who is Npc:
				(who as Npc).face(Stage.chloe().global_position))])
		return
	S.lock(true)
	await S.say(_the_bargain(who))
	Game.award_team_xp(XP_ISAURE)
	Save.save_game()
	if _has_letter():
		await S.say(_the_letter(who))
		_letter_given()
	S.lock(false)
	if not Game.flag(&"maia_porte_vue"):
		await maia(V.actor_of(MAIA_NODES))


## Her next line (the letter's one only once she has it).
static func _again() -> String:
	var pool: Array = []
	for i in ISAURE_AGAIN.size():
		if i == 2 and not Game.flag(&"lettre_isaure_donnee"):
			continue
		pool.append(ISAURE_AGAIN[i])
	return ForetCamp.next_line(&"isaure_porte_n", pool)


static func _the_bargain(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = _px(who, Vector2(0.0, -3.0 * S.CELL))
	var gate := V.at_node(["PortailApex"], V.spot_or("PORTAIL", at + Vector2(0.0, -3.0 * S.CELL)))
	var maia_npc = V.actor_of(MAIA_NODES)
	var caillou_npc = V.actor_of(CAILLOU_NODES)
	var turns := func() -> void:
		Stage.look_at(at.lerp(chloe.global_position, 0.4), 0.8)
		await CS.chloe_walk(S.ground_near(at + BEFORE_ISAURE, 2), 80.0, 2.4)
		if who is Npc:
			(who as Npc).face(chloe.global_position)
		Stage.turn_to(chloe, at)
		Stage.glow(who, MS.HEART_GLOW, 2, 0.9)
	var beats := func() -> void:
		MS.hearts(3, 0.8)
		Stage.glow(who, MS.HEART_GLOW, 3, 0.8)
		torches(gate, 2)
	var a_while := func() -> void:
		Stage.emote(who, "…")
	var looks := func() -> void:
		if who is Npc:
			(who as Npc).face(gate)
			await S.wait(1.0)
			(who as Npc).face(chloe.global_position)
	var muzzles := func() -> void:
		if maia_npc:
			Stage.turn_to(maia_npc, chloe.global_position)
		if caillou_npc:
			CS.get_up(caillou_npc, 0.4)
			var dino := CS.lead()
			if dino:
				await CS.lead_walk(S.ground_near((caillou_npc as Node2D).global_position.lerp(chloe.global_position, 0.6), 2), 60.0)
				Stage.turn_to(dino, (caillou_npc as Node2D).global_position)
				Stage.turn_to(caillou_npc, dino.global_position)
	var shuts := func() -> void:
		Stage.emote(who, "…")
	var away := func() -> void:
		if who is Npc:
			(who as Npc).face(gate)
	var back := func() -> void:
		if who is Npc:
			await S.wait(0.6)
			(who as Npc).face(chloe.global_position)
	return [
		CS.cue({"text": "Isaure se retourne. Pas de masque. Les cheveux attachés, cette fois : la capitaine du port. Contre sa hanche, une sacoche de marin, et dedans quelque chose qui bat."}, turns),
		CS.cue({"text": "Le Cœur de Chloé répond. Cinq cœurs qui battent ensemble, de part et d'autre de dix pas de cendre. Les torches vacillent."}, beats),
		{"who": ISAURE, "text": "Je l'ai entendu arriver avant toi, moussaillon. Il bat fort, le dernier. Il a toujours été le plus bruyant."},
		{"who": ISAURE, "text": "Tu as traversé les forges."},
		{"who": CHLOE, "text": "Elles sont éteintes."},
		{"who": ISAURE, "text": "… Je sais. On l'a vu d'ici. Les feux, un par un, et puis le grand. Maïa a compté."},
		{"who": MAIA, "text": "Sept. Comme Bertille."},
		{"who": ISAURE, "text": "Brac ?"},
		{"who": CHLOE, "text": "Il est parti voir la mer. De loin."},
		CS.cue({"who": ISAURE, "text": "Il n'a jamais su nager. Douze ans, et je ne lui ai jamais appris. … Je ne lui ai jamais rien appris."}, a_while),
		CS.cue({"who": ISAURE, "text": "Alors voilà. Il y a cinq Cœurs sur cette île : j'en ai quatre, et tu as le dernier contre ta poitrine. Il faut les cinq. Elle a fait ça exprès, et elle a bien fait."}, looks),
		{"who": ISAURE, "text": "Je ne vais pas te le prendre, Chloé. Je l'ai fait une fois, là-haut, et je ne le referai pas devant ma fille. Je vais te le demander."},
		{"who": ISAURE, "text": "Donne-le-moi. Et viens. Ouvre cette porte avec moi, et ce qui dort là-dessous, on le tiendra à deux : toi avec ton Lien, moi avec le reste. Plus personne ne mourra de faim au port. Plus jamais. Ni au port, ni ailleurs : on aura de quoi exiger. Tu seras la petite-fille qui a fini ce que sa grand-mère n'a pas osé finir."},
		{"who": ISAURE, "text": "Et on la sortira de là. Toutes les deux. Ça, je ne te l'ai pas dit là-haut. Je te le dis ici."},
		CS.cue({"who": CHLOE, "text": "(Elle vient de le dire. Pour Hélène. Pas « je vais la chercher » : « on la sortira ». C'est presque pareil. Ce n'est pas pareil.)"}, muzzles),
		{"who": CHLOE, "text": "(Il a peur. Il a peur quand on le réveille de force. Elle veut le réveiller avec une goutte d'ambre noir et le « tenir ». Hélène a mis vingt-cinq ans et ses deux mains à ne pas faire ça.)"},
		{"who": CHLOE, "text": "Non."},
		CS.cue({"who": ISAURE, "text": "… Pas fort. Elle non plus ne disait jamais rien fort."}, shuts),
		{"who": MAIA, "text": "Tu vois. Elle a dit non. Comme Hélène."},
		{"who": ISAURE, "text": "Je vois."},
		{"who": CHLOE, "text": "Je ne vous laisserai pas ouvrir cette porte, Isaure. Mais je ne vous laisserai pas non plus là-dedans toute seule. Ni Maïa. Je ne sais pas encore comment je fais les deux."},
		{"who": ISAURE, "text": "Tu as les yeux de ta grand-mère, moussaillon. Elle non plus ne savait pas, et elle le faisait quand même."},
		CS.cue({"who": ISAURE, "text": "Je n'ouvre pas avant l'aube. Il faut du jour pour descendre là-dedans, et je ne descends pas ma fille dans le noir. Tu as jusqu'à l'aube pour changer d'avis."}, away),
		{"who": CHLOE, "text": "Vous aussi."},
		CS.cue({"who": ISAURE, "text": "… Oui. Moi aussi, je suppose."}, back),
		{"flag": &"isaure_porte_vue"},
		{"flag": &"marche_refuse"},
	]


## 9 d, the letter: she knows the handwriting before touching it, steps back half a step, takes
## it; does not open it; holds it against the Cœurs. « Si je la lis maintenant, ma tornade, je ne
## descends plus. »
static func _the_letter(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = _px(who, Vector2(0.0, -2.0 * S.CELL))
	var maia_npc = V.actor_of(MAIA_NODES)
	var holds_out := func() -> void:
		if who is Npc:
			(who as Npc).face(chloe.global_position)
		Stage.turn_to(chloe, at)
		if ItemsDB.ITEMS.has(LETTER):
			CS.Act.pop(chloe.global_position, LETTER, 0.9)
		await CS.reach(chloe, at, 12.0, 1.0)
		await Stage.recoil(who, chloe.global_position, 8.0)
		CS.reach(who, chloe.global_position, 10.0, 1.0)
	var keeps := func() -> void:
		await Stage.bow(who, 1.0)
		Stage.glow(who, MS.HEART_GLOW, 1, 1.0)
	var asks := func() -> void:
		if maia_npc:
			Stage.turn_to(maia_npc, at)
	var slips := func() -> void:
		await CS.reach(who, at + Vector2(10.0, 10.0), 6.0, 1.2)
		Stage.emote(who, "…")
	return [
		CS.cue({"who": CHLOE, "text": "Dame Suie l'a gardée un an. Hélène l'a posée sur son établi, la nuit, avant de descendre. Elle est pour vous."}, holds_out),
		CS.cue({"text": "Isaure prend l'enveloppe. Elle ne l'ouvre pas. Elle la tient contre les Cœurs, dans la sacoche."}, keeps),
		CS.cue({"who": MAIA, "text": "Lis-la."}, asks),
		{"who": ISAURE, "text": "En bas."},
		{"who": MAIA, "text": "Maman. Lis-la maintenant."},
		{"who": ISAURE, "text": "Si je la lis maintenant, ma tornade, je ne descends plus. Et il faut bien que quelqu'un descende."},
		CS.cue({"text": "Elle la glisse dans la sacoche, contre les Cœurs. Elle ne la lâche pas tout de suite."}, slips),
		{"who": ISAURE, "text": "… Elle écrivait tout. Même ce que je n'ai pas lu."},
		{"who": CHLOE, "text": "(Elle ne l'a pas lue. Mais elle ne l'a pas rendue non plus. … Jusqu'à l'aube.)"},
	]


## Chloé still has the letter for Isaure (the item, or its page read and not given yet).
static func _has_letter() -> bool:
	if Game.flag(&"lettre_isaure_donnee"):
		return false
	return Game.item_count(LETTER) > 0 or (Game.flag(&"found_journal_37") and not ItemsDB.ITEMS.has(LETTER))


## The letter leaves the bag (its page stays in the journal: found_journal_37).
static func _letter_given() -> void:
	Game.items.erase(LETTER)
	Game.set_flag(&"lettre_isaure_donnee")
	Game.party_changed.emit()
	Save.save_game()


# ------------------------------------------------------------------ Maïa, Caillou

## 9 e, Maïa (Npc « MaiaPorte », event « maia_porte »): after Isaure's bargain (before it, Isaure
## turns round first). Moustique, Roc's inkpot, « Elle attend », « Garde-le encore », the cardboard
## mask, « de son côté de la porte. Pas contre toi. », Caillou's horn. Afterwards, a line each time.
static func maia(who: Node) -> void:
	if not Game.flag(&"isaure_porte_vue"):
		var isaure_npc = V.actor_of(ISAURE_NODES)
		if isaure_npc:
			await isaure(isaure_npc)
		return
	if Game.flag(&"maia_porte_vue"):
		await S.say([{"who": MAIA, "text": _maia_again()}])
		return
	S.lock(true)
	var cast := {}
	await S.say(_moustique(who, cast))
	await S.say(_her_side(who, cast))
	var bird = cast.get("bird")
	if is_instance_valid(bird):
		Stage.fade_out(bird, 0.4, true)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_MAIA)
	Save.save_game()
	S.lock(false)


static func _maia_again() -> String:
	var pool: Array = MAIA_AGAIN.slice(0, 3)
	if Game.flag(&"fournaise_garde"):
		pool.append(MAIA_AGAIN[3])
	return ForetCamp.next_line(&"maia_porte_n", pool)


## She comes to Chloé, Joss's coat to her ankles; Moustique comes out of Chloé's collar, cries, and
## flies onto Maïa's shoulder; he nibbles her; she laughs (the first real laugh of the chapter).
static func _moustique(who: Node, cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var comes := func() -> void:
		if who is Npc:
			Stage.pose(who, &"")
			await (who as Npc).walk_to(S.ground_near(chloe.global_position + Vector2(-60.0, -8.0), 2), "", 100.0)
			(who as Npc).face(chloe.global_position)
		Stage.turn_to(chloe, _px(who, Vector2(-60.0, 0.0)))
		var bird := V.stand_in(&"dimorphodon", chloe.global_position + V.SHOULDER, "MoustiquePorte", V.MOUSTIQUE_LEVEL, 0.8)
		cast["bird"] = bird
		if bird == null:
			return
		await Stage.fade_in(bird, 0.3)
		bird.cry(&"neutre")
		await CS.fly(bird, _px(who, Vector2(-60.0, 0.0)) + Vector2(10.0, 2.0), 0.9, V.SHOULDER_UP)
		Stage.hop(bird, 2, 4.0)
	var laughs := func() -> void:
		Stage.hop(who, 2, 6.0)
		Stage.emote(who, "♥")
	return [
		CS.cue({"who": MAIA, "text": "Aïe. Oui. Moi aussi. … Aïe."}, comes),
		{"who": MAIA, "text": "Il a maigri ? Il a maigri. Tu ne lui as pas donné de l'encrier, au moins ?"},
		{"who": CHLOE, "text": "Il a mangé celui de Roc."},
		CS.cue({"who": MAIA, "text": "Il fait ça quand il s'inquiète. Roc mange des biscuits."}, laughs),
		{"who": CHLOE, "text": "C'est ce qu'il a dit."},
	]


## Serious again, looking at her mother's back: « Elle attend »; « Garde-le encore »; Moustique
## back on Chloé's shoulder (he does not cry); the cardboard mask; her side of the door; Caillou
## pushes Chloé with his horn, gently.
static func _her_side(who: Node, cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var isaure_npc = V.actor_of(ISAURE_NODES)
	var looks := func() -> void:
		if isaure_npc is Node2D:
			Stage.turn_to(who, (isaure_npc as Node2D).global_position)
	var back_to_chloe := func() -> void:
		Stage.turn_to(who, chloe.global_position)
		var bird = cast.get("bird")
		if is_instance_valid(bird):
			await CS.reach(who, chloe.global_position, 8.0, 0.6)
			await CS.fly(bird, chloe.global_position + V.SHOULDER, 0.7, V.SHOULDER_UP)
	var horn := func() -> void:
		var caillou_npc = V.actor_of(CAILLOU_NODES)
		if caillou_npc is DinoNpc:
			await (caillou_npc as DinoNpc).walk_to(S.ground_near(chloe.global_position + Vector2(70.0, -10.0), 2), 50.0)
			Stage.turn_to(caillou_npc, chloe.global_position)
			Stage.lunge(caillou_npc, chloe.global_position, 0.4, false)
		await S.wait(0.2)
		Stage.recoil(chloe, chloe.global_position + Vector2(40.0, 0.0), 10.0)
		Stage.tremble(chloe, 0.4, 2.0)
	var lines: Array = [
		CS.cue({"who": MAIA, "text": "Elle n'a pas dormi. Elle regarde la porte depuis hier soir. Elle a les Cœurs, elle a la fiole de la dame en gris, elle a tout. Et elle n'a pas ouvert."}, looks),
		{"who": CHLOE, "text": "Elle attend l'aube."},
		{"who": MAIA, "text": "Elle attend. C'est tout ce que je sais. Je suis à côté, et j'attends avec elle. C'est ce que j'ai dit que je ferais."},
		CS.cue({"who": MAIA, "text": "Je ne t'ai pas dit que je te rattraperais en marchant ? C'est toi qui m'as rattrapée. En marchant aussi. On est nulles, toutes les deux."}, func() -> void: Stage.turn_to(who, chloe.global_position)),
		{"who": CHLOE, "text": "Tu veux Moustique ?"},
		{"who": MAIA, "text": "… Non. Garde-le encore. Il a peur du feu, et ici, il n'y a que ça. Et puis s'il est avec toi, tu es obligée de revenir."},
		{"who": CHLOE, "text": "J'allais revenir."},
		CS.cue({"who": MAIA, "text": "Je sais. Mais là, tu es obligée. C'est mieux."}, back_to_chloe),
	]
	if Game.item_count("masque_carton") > 0 or Game.flag(&"masque_carton_confie"):
		lines.append_array([
			{"who": MAIA, "text": "Le masque en carton ?"},
			{"who": CHLOE, "text": "Dans la sacoche."},
			{"who": MAIA, "text": "Garde-le aussi. Elle a enlevé le sien, mais elle ne l'a pas encore… Elle n'est pas encore prête à en mettre un pour rire. Demain, peut-être."},
		])
	lines.append_array([
		{"who": MAIA, "text": "Chloé. Demain, à l'aube. Quoi qu'il arrive… je serai de son côté de la porte. Pas contre toi. De son côté. Tu comprends la différence ?"},
		{"who": CHLOE, "text": "Oui."},
		{"who": MAIA, "text": "Bien. Parce que moi, j'ai mis une nuit entière."},
		CS.cue({"who": MAIA, "text": "Et lui, il dit : « soigne tes dinos, mange quelque chose, et reviens avec ton équipe au complet ». Il dit beaucoup de choses, Caillou, quand on l'écoute."}, horn),
		{"who": CHLOE, "text": "(Elle a les yeux de sa mère. Et elle garde la porte avec elle. … Je les ramènerai. Toutes les deux. Je l'ai dit en haut ; je le redis en bas.)"},
		{"flag": &"maia_porte_vue"},
	])
	return lines


## Caillou (DinoNpc « CaillouPorte »): he sneezes.
static func caillou(who: Node) -> void:
	await S.say([CS.cue({"text": "Caillou lève la tête, renifle, et éternue dans la cendre."}, func() -> void:
		Stage.rear(who, 0.6)
		Act.burst(_px(who, Vector2.ZERO) + Vector2(0.0, -10.0), V.ASH_BITS, 12, 0.4, 0.4))])


# ------------------------------------------------------------------ the gate

## 9 f, the gate (StoryProp « PortailApex », event « portail_apex »; also the dialogue
## « apex_bloque » of a closed way through it): five round hollows in a star. « Demain, à l'aube. »
static func portail(who: Node) -> void:
	await S.say([CS.cue(DialogueVolcan.apex_bloque()[0], func() -> void:
		var at := _px(who, Vector2(0.0, -3.0 * S.CELL))
		Stage.look_at(at + Vector2(0.0, -2.0 * S.CELL), 1.0)
		torches(at, 2))] + DialogueVolcan.apex_bloque().slice(1))
	Stage.look_back()
	Save.save_game()


static func _px(who, fallback_offset: Vector2) -> Vector2:
	if who is Node2D and is_instance_valid(who):
		return (who as Node2D).global_position
	var chloe := Stage.chloe()
	return (chloe.global_position if chloe else Vector2.ZERO) + fallback_offset


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): the crater's door on any zone: Isaure, Maïa and
## Caillou brought on before Chloé; the arrival, the camp, page 38, Isaure, the letter, Maïa, the gate.
static func static_porte() -> void:
	S.playing += 1
	var chloe := Stage.chloe()
	var base := chloe.global_position
	var isaure_npc := S.stranger("IsaurePorte", V.sheet(["isaure_sans_masque", "isaure"]), S.ground_near(base + Vector2(0.0, -3.0 * S.CELL), 3), "up", ISAURE)
	var maia_npc := S.stranger("MaiaPorte", V.sheet(["maia_arche", "maia"]), S.ground_near(base + Vector2(-2.6 * S.CELL, -2.4 * S.CELL), 3), "down", MAIA)
	var caillou_npc := V.stand_in(&"triceratops", S.ground_near(base + Vector2(2.8 * S.CELL, -3.2 * S.CELL), 3), "CaillouPorte")
	if caillou_npc:
		Stage.fade_in(caillou_npc, 0.2)
	if ItemsDB.ITEMS.has(LETTER) and Game.item_count(LETTER) == 0:
		Game.give_item(LETTER)
	Game.set_flag(&"found_journal_37")
	await arrival()
	await camp(null)
	await S.say(DialogueVolcan.lines(&"page_38"))
	if isaure_npc:
		await isaure(isaure_npc)
	await portail(null)
	if maia_npc:
		await maia(maia_npc)   # (once more: her next line)
	S.playing -= 1
