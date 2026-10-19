class_name ApexAube
## Chapter 9, scene 1, the dawn at the crater's door (zone porte_cratere; docs/chapitre-9-scenes.md
## § 1): the direct sequel of chapter 8's door. When Chloé talks to Isaure again (Npc « IsaurePorte »,
## event « isaure_porte », taken over from VolcanPorte once Isaure and Maïa have been seen: takes_over),
## « C'est l'aube ? » (her hatchling must be in the party: « Va le chercher »); the letter of chapter 8
## first if Chloé still has it; the last demand (« Je ne redemande qu'une fois »), « Non. », the bet;
## the sailor's whistle and « les miens », four sea dinos without a violet vein (Hauban, Bouline,
## Étrave, Carène), and the egg confessed before; the duel (a choice before Carène: she hesitates);
## « Les Kerval tiennent parole »: the four Cœurs given back, « Décide, moussaillon. » (the one real
## dilemma: open together without black amber, or leave it shut; both paths meet), « tant qu'il y
## aura un autre moyen »; Chloé puts the five Cœurs in the gate herself, the torches go out, the
## leaves open, Caillou sneezes; Isaure goes through first, Maïa beside her. No music.
## Short moments (Greg, 18/10): at most a dozen lines in a row, cut by things watched, choices, the
## duel.
## Flags: apex_aube, (lettre_isaure_donnee), isaure_pari, isaure_aveu_oeuf, isaure_vaincue,
## coeurs_rendus, apex_decision (« ouvrir » / « fermee »), apex_ouvert.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const V := preload("res://story/volcan.gd")
const A := preload("res://story/apex.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ISAURE := "Isaure"
const ISAURE_NODES := ["IsaurePorte"]
const MAIA_NODES := ["MaiaPorte"]
const CAILLOU_NODES := ["CaillouPorte"]
## Her four (node names, species, their size): asleep behind the rocks along the crater's sides
## (ApexPlaces.DINOS_ISAURE_CACHES), then lined up east of her (DINOS_ISAURE_RANG), and back; round
## Isaure (px) when those places are not there (a test on another zone).
const SEA := [["Hauban", &"pteranodon", 1.0], ["Bouline", &"baryonyx", 1.0], ["Etrave", &"suchomimus", 1.0], ["Carene", &"archelon", 1.3]]
const SEA_HIDDEN := [Vector2(380.0, -40.0), Vector2(420.0, 90.0), Vector2(400.0, 230.0), Vector2(350.0, 370.0)]
const SEA_LINE := [Vector2(150.0, 50.0), Vector2(330.0, 80.0), Vector2(480.0, 180.0), Vector2(290.0, 250.0)]
## Where Chloé stops before Isaure (px south of her) when AUBE_CHLOE is not there; the dawn's hour;
## pink smoke, pale sky.
const BEFORE_ISAURE := Vector2(0.0, 120.0)
const DAWN_HOUR := 5.5
const DAWN_PINK := Color(1.0, 0.62, 0.66)
const XP_PARI := 40
const XP_ISAURE := 160
const XP_PORTE := 60


## Isaure at the door is the chapter's from the dawn on: both she and Maïa have been seen (chapter
## 8's door), and the gate is not open yet.
static func takes_over() -> bool:
	return Game.flag(&"isaure_porte_vue") and Game.flag(&"maia_porte_vue") and not Game.flag(&"apex_ouvert")


## Entering the door once the gate is open: Isaure, Maïa and Caillou went down (their nodes go;
## the zone's plan hides them too: hide_flag apex_ouvert), and the four sea dinos with them.
static func on_porte() -> void:
	if not Game.flag(&"apex_ouvert"):
		return
	for n: String in ISAURE_NODES + MAIA_NODES + CAILLOU_NODES + ["Hauban", "Bouline", "Etrave", "Carene"]:
		var a = S.actor(n)
		if a is Node:
			(a as Node).queue_free()


# ------------------------------------------------------------------ Isaure, at dawn

## 1 a to 1 e: what Isaure says when Chloé comes back to her, from the dawn to the open gate.
static func isaure(who: Node) -> void:
	var cast := _cast(who)
	S.lock(true)
	if Game.flag(&"isaure_vaincue"):   # (the duel won, the gate not open yet: a game reloaded)
		await _kept_word(who, cast)
		S.lock(false)
		return
	await S.say([CS.cue({"who": ISAURE, "text": "Ton équipe est au complet, moussaillon ? Le jour ne va pas tarder."}, func() -> void:
		_faces_chloe(who))])
	if not A.starter_in_party():
		await S.say(fetch_starter())
		S.lock(false)
		return
	if await Dialogue.choose("", "Isaure attend.", ["C'est l'aube.", "Pas encore."]) != 0:
		await S.say([{"who": ISAURE, "text": "Soigne-les, alors. Je ne bouge pas."}])
		S.lock(false)
		return
	Audio.push_music(null, 1.5)   # (no music at dawn: the wind, the torches)
	if not Game.flag(&"apex_aube"):
		await _dawn(cast)
	if VolcanPorte._has_letter():   # (chapter 8's choice first: « Lui donner la lettre » / « Pas maintenant »)
		await VolcanPorte._offer_letter(who)
	if not Game.flag(&"isaure_pari"):
		await S.say(last_demand(who, cast))
		await _whistle(who, cast)
		await S.say(her_own(who, cast))
		await _little_backs_off()
		Game.award_team_xp(XP_PARI)
		Save.save_game()
	if not await duel(who, cast):
		Audio.pop_music(1.0)
		await S.say([{"who": ISAURE, "text": DialogueApex.ISAURE_LOST}])
		S.lock(false)
		return
	Game.set_flag(&"isaure_vaincue")
	Game.award_team_xp(XP_ISAURE)
	Save.save_game()
	await _kept_word(who, cast)
	Audio.pop_music(2.0)
	S.lock(false)


## The people of the scene: Isaure, Maïa, Caillou, the gate (the zone's nodes when there).
static func _cast(who: Node) -> Dictionary:
	var at := A.px_of(who, Vector2(0.0, -3.0 * S.CELL))
	var cast := {"isaure": who, "maia": V.actor_of(MAIA_NODES), "caillou": V.actor_of(CAILLOU_NODES)}
	cast["gate"] = V.at_node(["PortailApex"], A.spot_or("PORTAIL", at + Vector2(0.0, -3.0 * S.CELL)))
	return cast


static func _faces_chloe(who) -> void:
	if who is Npc and Stage.chloe():
		(who as Npc).face(Stage.chloe().global_position)


## 1 a, her hatchling waits at the Cabinet (2 lines, back to the game).
static func fetch_starter() -> Array:
	return [
		{"who": ISAURE, "text": "Et le petit d'Hélène ? Celui qui a éclos dans ta main. Va le chercher. Ce n'est pas moi qui te le demande : c'est elle."},
		{"who": CHLOE, "text": "(Elle a raison. Pas lui, pas sans lui.)"},
	]


## Watched, no line: the sky pales behind the volcano, the torches lose their colour, the crater's
## smoke turns pink. Maïa gets up from her stone; Caillou too, sneezing.
static func _dawn(cast: Dictionary) -> void:
	var gate: Vector2 = cast["gate"]
	Game.pass_time_until(DAWN_HOUR)
	Stage.look_at(gate + Vector2(0.0, -3.0 * S.CELL), 1.6)
	await S.wait(1.0)
	CS.pulse(gate + Vector2(0.0, -4.0 * S.CELL), DAWN_PINK, 2, 2.0, 2.5, 9.0)
	VolcanPorte.torches(gate, 1)
	await S.wait(1.4)
	var maia = cast.get("maia")
	if maia:
		Stage.pose(maia, &"")
		CS.get_up(maia, 0.5)
		Stage.look_at((maia as Node2D).global_position, 0.8)
	await S.wait(1.0)
	var caillou = cast.get("caillou")
	if caillou:
		CS.get_up(caillou, 0.5)
		Stage.rear(caillou, 0.6)
		Stage.cry(caillou, &"neutre")
		Act.burst((caillou as Node2D).global_position + Vector2(0.0, -10.0), V.ASH_BITS, 12, 0.4, 0.4)
	await S.wait(1.2)
	Stage.look_back(0.8)
	Game.set_flag(&"apex_aube")
	Save.save_game()


## 1 b, the last demand (6 lines): the four Cœurs held against her, the fifth answers louder; « Je
## ne redemande qu'une fois. » « Non. » The bet of a sailor.
static func last_demand(who, cast: Dictionary) -> Array:
	var holds := func() -> void:
		var at := A.px_of(who)
		Stage.look_at(at.lerp(A.chloe_px(), 0.4), 0.8)
		await CS.chloe_walk(A.spot_or("AUBE_CHLOE", S.ground_near(at + BEFORE_ISAURE, 2)), 80.0, 2.0)
		_faces_chloe(who)
		Stage.glow(who, MS.HEART_GLOW, 3, 0.8)
		await S.wait(0.6)
		MS.hearts(3, 0.7)
		Stage.glow(Stage.chloe(), MS.HEART_GLOW, 2, 0.6)
	var stone := func() -> void:
		var maia = cast.get("maia")
		if maia:
			Stage.turn_to(maia, A.px_of(who))
			Stage.emote(maia, "…")
	return [
		CS.cue({"text": "L'aube monte. Isaure a sorti les quatre Cœurs de sa sacoche : elle les tient à deux mains, contre elle. Ils battent. Dans la sacoche de Chloé, le cinquième répond, plus fort que tous."}, holds),
		{"who": ISAURE, "text": "Je ne redemande qu'une fois. Donne-le-moi, et viens."},
		{"who": CHLOE, "text": "Non."},
		{"who": ISAURE, "text": "… Je savais. Je demandais quand même. On demande toujours une fois de trop, dans ma famille."},
		CS.cue({"who": MAIA, "text": "C'est vrai. Je l'ai demandée trois fois, la barque."}, stone),
		{"who": ISAURE, "text": "Alors je ne vais pas te le prendre, moussaillon. Je vais le gagner. Un pari de marin : si je gagne, le Cœur. Si tu gagnes, c'est toi qui décides ce qu'on fait de cette porte. Et je ferai ce que tu décides."},
		{"flag": &"isaure_pari"},
	]


## Watched, no line: she puts the Cœurs away, two fingers in her mouth, a long sailor's whistle;
## behind the rocks of the esplanade, something moves. Four things.
static func _whistle(who, cast: Dictionary) -> void:
	await Stage.bow(who, 0.6)
	Stage.emote(who, "♪")
	Stage.hop(who, 1, 4.0)
	await S.wait(1.0)
	var hidden := _hidden(who)
	Stage.look_at((hidden[1] as Vector2).lerp(hidden[2], 0.5), 1.0)
	await S.wait(0.8)
	for i in 4:
		Act.burst(hidden[i], V.ASH_BITS, 6, 0.3, 0.3)
		Stage.shake(0.6, 0.15)
		await S.wait(0.35)
	await S.wait(0.6)


## Where her four sleep, behind the rocks (px).
static func _hidden(who) -> Array:
	var at := A.px_of(who)
	var out: Array = []
	for i in SEA.size():
		out.append(A.spot_in("DINOS_ISAURE_CACHES", i, at + SEA_HIDDEN[i]))
	return out


## 1 c, « les miens » (8 lines): four dinos without a violet vein come out from behind the rocks;
## Chloé understands she has always had the Lien; the egg confessed, before; Maïa comes beside her
## mother: « Je regarde. C'est le plus dur. »
static func her_own(who, cast: Dictionary) -> Array:
	var out := func() -> void:
		var hidden := _hidden(who)
		var at := A.px_of(who)
		for i in SEA.size():
			var row: Array = SEA[i]
			var d = A.dino([row[0]], row[1], hidden[i], row[2])
			cast[row[0]] = d
			if d == null:
				continue
			if A.brought(d):
				d.modulate.a = 0.0
				Stage.fade_in(d, 0.6)
			var to := A.spot_in("DINOS_ISAURE_RANG", i, S.ground_near(at + SEA_LINE[i], 2))
			if d is DinoNpc:
				(d as DinoNpc).walk_to(to, 70.0)
			await S.wait(0.5)
		Stage.look_at(at.lerp(A.chloe_px(), 0.3) + Vector2(3.0 * S.CELL, 0.0), 1.0)
	var names := func() -> void:
		for row: Array in SEA:
			var d = cast.get(row[0])
			if d:
				Stage.cry(d, &"neutre")
				await S.wait(0.5)
	var beside := func() -> void:
		var maia = cast.get("maia")
		if maia is Npc:
			Stage.pose(maia, &"")
			await (maia as Npc).walk_to(S.ground_near(A.px_of(who) + Vector2(-46.0, 4.0), 2), "", 90.0)
			(maia as Npc).face(A.chloe_px())
	return [
		CS.cue({"text": "Quatre dinos sortent de derrière les rochers, où ils dormaient. Un Pteranodon au bec rayé de sel, un Baryonyx, un Suchomimus, et une tortue plus grande qu'une barque. Pas une veine violette. Pas une."}, out),
		CS.cue({"who": ISAURE, "text": "Hauban. Bouline. Étrave. Et Carène, qui a l'âge de ma barque. Ils suivent mon bateau depuis que Maïa est née. Je ne les ai jamais forcés. Je n'ai jamais eu besoin."}, names),
		{"who": CHLOE, "text": "(Elle l'a. Le Lien. Elle l'a toujours eu. Elle s'est juste servie d'autre chose.)"},
		{"who": ISAURE, "text": confession()},
		{"who": MAIA, "text": "… Tu ne me l'avais pas dit."},
		{"who": ISAURE, "text": "Non. Je te le dis maintenant. Avant, pas après : ta marraine disait qu'on avoue avant."},
		{"who": CHLOE, "text": "(Avant. Pour qu'il n'y ait plus rien derrière la porte, qu'elle gagne ou qu'elle perde.)"},
		CS.cue({"who": MAIA, "text": "Je suis de son côté. Je ne me bats pas. Je regarde. … C'est le plus dur, je crois."}, beside),
		{"flag": &"isaure_aveu_oeuf"},
	]


## The egg confessed: where the third little one is (in the party, or at the Cabinet).
static func confession() -> String:
	var start := "J'en avais un cinquième. Je l'ai pris sur une couveuse, une nuit, avec ma clé, et je l'ai donné à Brac. "
	if egg_in_party():
		return start + "C'est lui, là, dans ton équipe. Il ne me reconnaît pas. Tant mieux."
	return start + "C'est le petit que tu as ramené au Cabinet. Il ne me reconnaîtrait pas. Tant mieux."


## True when the third little one (the stolen egg, calmed in the Forêt) is in Chloé's party.
static func egg_in_party() -> bool:
	var little: Dino = ForetCamp.recovered()
	return little != null and Game.party.has(little)


## Watched, no line: the third little one, if it leads, growls softly and steps back.
static func _little_backs_off() -> void:
	var little: Dino = ForetCamp.recovered()
	var dino := CS.lead()
	if little == null or Game.lead_dino() != little or dino == null:
		return
	Stage.cry(dino, &"neutre")
	Stage.tremble(dino, 0.6, 1.5)
	await Stage.recoil(dino, A.chloe_px() + Vector2(0.0, -80.0), 16.0)
	await S.wait(0.6)


# ------------------------------------------------------------------ the duel

## 1 d, the duel (her four one after the other; Carène after a choice: she hesitates, ApexEngine's
## rule « hesitates »): true when Chloé wins. The MÉCANIQUES agent's team and rules (ApexBattles.
## isaure_team, isaure_rules: no music); a lost duel ends by Hélène's camp (ApexPlaces.LOSE_AUBE).
static func duel(_who, _people: Dictionary) -> bool:
	var w = S.world()
	if w == null or Game.party.is_empty():
		return false
	var members: Array = A.from_battles(&"isaure_team", [], team())
	var rules := {"lose_spawn": A.spawn("LOSE_AUBE"), "music": null, "hesitates": "Carène"}
	rules.merge(A.from_battles(&"isaure_rules", [], {}), true)
	for i in members.size():
		var member: Array = members[i]
		var options: Dictionary = (member[3] as Dictionary).duplicate() if member.size() > 3 else {}
		if i == members.size() - 1:
			var pick := await Dialogue.choose("", DialogueApex.CARENE_PROMPT, DialogueApex.CARENE_OPTIONS)
			await S.say(DialogueApex.carene_reply(pick))
		elif options.has("before"):
			await S.say(options["before"])
		var foe := Dino.create(member[0], member[1], member[2] if member.size() > 2 else "")
		var battle := {"catch": false, "run": false, "trainer": ISAURE, "intro": "%s envoie %s !" % [ISAURE, foe.nickname]}
		battle.merge(rules, true)
		for key: String in options:
			if key != "before" and key != "corrupted":
				battle[key] = options[key]
		var result: String = await w.call(&"_battle", foe, battle)
		if result != "win":
			return false
	return true


## Her four (Story.duel's format) if ApexBattles were gone: the species, levels and names of the
## plan, without their words (those are ApexBattles').
static func team() -> Array:
	return [[&"pteranodon", 47, "Hauban"], [&"baryonyx", 47, "Bouline"], [&"suchomimus", 48, "Étrave"], [&"archelon", 49, "Carène"]]


# ------------------------------------------------------------------ the Kerval keep their word

## 1 e: watched (Carène lies down, the four go back behind the rocks, the bag opens); her word kept
## (6 lines); the choice (open together / leave it shut: 3 more lines, then the same path); « tant
## qu'il y aura un autre moyen » (3 lines); watched (the five Cœurs, the torches, the leaves, Caillou
## sneezes); she goes through first (3 lines).
static func _kept_word(who, cast: Dictionary) -> void:
	await _four_go_back(who, cast)
	await S.say(word_kept(who))
	var pick := await Dialogue.choose("", "Cinq Cœurs dans une sacoche d'écolière. Que décide Chloé ?", ["Ouvrir. Ensemble. Sans ambre noir.", "Laisser la porte fermée."])
	await S.say(decision(pick == 0))
	Game.set_flag(&"apex_decision", "ouvrir" if pick == 0 else "fermee")   # (the choice made, remembered)
	await _opens(cast)
	await S.say(through(who, cast))
	hearts_in_the_door()
	await _gone_down(cast)
	A.clean_up(cast)
	Stage.look_back()
	Game.award_team_xp(XP_PORTE)
	Save.save_game()


## Watched, no line: Carène lies down; the four go back behind the rocks, not hurrying; Isaure does
## not move, then opens her sailor's bag.
static func _four_go_back(who, cast: Dictionary) -> void:
	var hidden := _hidden(who)
	var carene = cast.get("Carene", V.actor_of(["Carene"]))
	if carene:
		Stage.look_at((carene as Node2D).global_position, 0.8)
		await CS.crouch(carene, 0.2, 0.9)
		await S.wait(0.6)
	for i in SEA.size():
		var d = cast.get(SEA[i][0], V.actor_of([SEA[i][0]]))
		if d is DinoNpc and is_instance_valid(d):
			(d as DinoNpc).walk_to(hidden[i], 50.0)
			Stage.fade_out(d, 2.4, A.brought(d))
	await S.wait(1.6)
	Stage.look_at(A.px_of(who).lerp(A.chloe_px(), 0.4), 0.8)
	await S.wait(0.8)
	await Stage.bow(who, 0.8)


## Her word kept (6 lines): « J'ai perdu. » The four Cœurs into Chloé's bag: five beats, then one.
static func word_kept(who) -> Array:
	var holds_out := func() -> void:
		_faces_chloe(who)
		await CS.reach(who, A.chloe_px(), 12.0, 1.0)
	var passes := func() -> void:
		hearts_back()
		for i in 4:
			if ItemsDB.ITEMS.has("coeur_%d" % (i + 1)):
				Act.pop(A.chloe_px(), "coeur_%d" % (i + 1), 0.8 + 0.1 * i)
			await S.wait(0.25)
		MS.hearts(5, 0.25)
		await S.wait(1.4)
		Stage.glow(Stage.chloe(), MS.HEART_GLOW, 1, 1.2)
	return [
		CS.cue({"who": ISAURE, "text": "J'ai perdu. Tiens. Ils ont assez voyagé dans un sac de marin."}, holds_out),
		CS.cue({"text": "Les quatre Cœurs passent dans la sacoche de Chloé. Le cinquième les accueille : cinq battements, puis un seul."}, passes),
		{"who": ISAURE, "text": "Décide, moussaillon. Je ferai ce que tu décides. Les Kerval tiennent parole."},
		{"who": MAIA, "text": "Même les paris idiots. … Pardon. Surtout maintenant."},
		{"who": CHLOE, "text": "(Fermer. Et laisser Hélène là-dedans un an de plus. Dix. Toujours. — Ouvrir. Et il se réveille, et il a peur, et il a raison.)"},
		{"who": CHLOE, "text": "(« Ne me cherche pas tout de suite. Occupe-toi d'eux d'abord. » … Je me suis occupée d'eux. Tous. Ce n'est plus tout de suite.)"},
		{"flag": &"coeurs_rendus"},
	]


## The four Cœurs back in Chloé's bag (ApexBag; their flags coeur_1..4 never went).
static func hearts_back() -> void:
	ApexBag.return_hearts()
	Game.set_flag(&"coeurs_rendus")
	Game.party_changed.emit()


## The choice made: `open` (« Ouvrir. Ensemble. Sans ambre noir. »), else « Laisser la porte fermée »
## (3 lines first: Maïa, Isaure, the fifth Cœur that opens the bag); then the same 3 lines.
static func decision(open: bool) -> Array:
	var lines: Array = []
	if not open:
		var opens_bag := func() -> void:
			MS.hearts(3, 0.4)
			Stage.hop(Stage.chloe(), 1, 6.0)
			Stage.glow(Stage.chloe(), MS.HEART_GLOW, 2, 0.5)
		lines.append_array([
			{"who": MAIA, "text": "Elle est là-dedans depuis un an, Chloé. Toute seule, avec une bête qui a peur. … Je ne te dis pas quoi faire. Je te dis ce que je ferais."},
			{"who": ISAURE, "text": "Je ferai ce que tu décides. Je l'ai dit."},
			CS.cue({"who": CHLOE, "text": "(Il veut y aller. Elle aussi. … Moi aussi. Bon.)"}, opens_bag),
		])
	lines.append_array([
		{"who": CHLOE, "text": "On descend. Toutes les trois. Et personne ne le réveille avec une goutte : on la sort sans lui faire peur. La fiole, Isaure."},
		{"who": ISAURE, "text": "… Je ne promets pas ce que je ne sais pas tenir. Je l'ai fait une fois, à Hélène, et tu as vu où ça nous a menées."},
		{"who": ISAURE, "text": "Je ne la toucherai pas tant qu'il y aura un autre moyen. Ça, je peux le tenir."},
		{"flag": &"apex_decision"},
	])
	return lines


## Watched, no line: Chloé walks to the gate and puts the Cœurs one by one in the hollows; each
## lights up. At the fifth, the wood trembles, the two torches go out at once, and the leaves open
## inwards, slowly. A warm wind; an amber light on the other side. Caillou sneezes.
static func _opens(cast: Dictionary) -> void:
	var gate: Vector2 = cast["gate"]
	var chloe := Stage.chloe()
	Stage.look_at(gate + Vector2(0.0, 1.0 * S.CELL), 1.2)
	for k in ["isaure", "maia"]:   # (they make room: Chloé goes to the gate herself)
		var n = cast.get(k)
		if n is Npc:
			(n as Npc).walk_to(A.px_of(n) + Vector2((-1.8 if k == "isaure" else -1.2) * S.CELL, 0.8 * S.CELL), "right", 90.0)
	await S.wait(0.8)
	await CS.chloe_walk(A.spot_or("DEVANT_PORTAIL", S.ground_near(gate + Vector2(0.0, 2.2 * S.CELL), 2)), 90.0, 4.0)
	if chloe:
		Stage.turn_to(chloe, gate)
	for i in 5:
		var hollow := gate + Vector2(cos(TAU * i / 5.0 - PI / 2.0), sin(TAU * i / 5.0 - PI / 2.0)) * 26.0 + Vector2(0.0, -20.0)
		if chloe:
			CS.reach(chloe, gate, 8.0, 0.4)
		CS.sparkle(hollow, 1.2, 10, 0.1)
		CS.pulse(hollow, A.AMBER, 1, 0.6, 2.5, 3.0)
		await S.wait(0.6)
	Stage.shake(2.5, 0.8)
	_torches_out()
	await S.wait(1.0)
	var portal = S.actor("PortailApex")
	if portal:
		Stage.repaint(portal, "portail_apex_ouvert", 1.6)
	CS.pulse(gate + Vector2(0.0, -1.0 * S.CELL), A.AMBER, 3, 1.4, 4.0, 8.0)
	await S.wait(1.2)
	for i in 3:
		Act.burst(gate + Vector2(randf_range(-60.0, 60.0), 10.0), A.AMBER_BITS, 10, 0.6, 0.6)
		await S.wait(0.3)
	if chloe:
		Stage.recoil(chloe, gate, 10.0)
	var caillou = cast.get("caillou")
	if caillou:
		Stage.rear(caillou, 0.6)
		Stage.cry(caillou, &"neutre")
		Act.burst((caillou as Node2D).global_position + Vector2(0.0, -10.0), V.ASH_BITS, 12, 0.4, 0.4)
	await S.wait(1.0)


## The two torches go out at once (their picture darkens; their light, if any, goes off).
static func _torches_out() -> void:
	for n: String in ["Torche", "Torche2"]:
		var t = S.actor(n)
		if not t is Node2D:
			continue
		if Prop.KINDS.has("torche_eteinte"):
			Stage.repaint(t, "torche_eteinte", 0.3)
		else:
			(t as Node2D).create_tween().tween_property(t, "modulate", Color(0.45, 0.42, 0.4), 0.3)
		for c in (t as Node).find_children("*", "Light2D", true, false):
			(c as Light2D).visible = false   # (its light in the 3D view goes off with it)
		Act.burst((t as Node2D).global_position + Vector2(0.0, -40.0), V.ASH_BITS, 10, 1.6, 0.2)   # (a puff of smoke)


## 1 e, the end (3 lines): « c'est moi qui l'ai ouverte »; Isaure goes through first; Maïa beside
## her, Caillou behind, Moustique pulls his head into Chloé's collar.
static func through(who, cast: Dictionary) -> Array:
	var gate: Vector2 = cast.get("gate", A.px_of(who) + Vector2(0.0, -3.0 * S.CELL))
	var goes := func() -> void:
		if who is Npc:
			await (who as Npc).walk_to(S.ground_near(gate + Vector2(-20.0, 1.0 * S.CELL), 2), "up", 70.0)
	var beside := func() -> void:
		var maia = cast.get("maia")
		if maia is Npc:
			(maia as Npc).walk_to(S.ground_near(gate + Vector2(30.0, 1.2 * S.CELL), 2), "up", 80.0)
		var caillou = cast.get("caillou")
		if caillou is DinoNpc:
			(caillou as DinoNpc).walk_to(S.ground_near(gate + Vector2(10.0, 2.6 * S.CELL), 2), 70.0)
		if Stage.chloe():
			V.shoulder_peek(Stage.chloe(), 1.6)
	return [
		{"who": CHLOE, "text": "(J'ai dit que je ne la laisserais pas ouvrir cette porte. C'est vrai : c'est moi qui l'ai ouverte.)"},
		CS.cue({"who": ISAURE, "text": "… Après toi, moussaillon. Non. Devant toi. Si quelque chose doit arriver en premier, ce sera à moi."}, goes),
		CS.cue({"who": MAIA, "text": "Et à moi."}, beside),
	]


## The five Cœurs stay in the gate: they leave the bag (their flags coeur_1..5 stay true); the
## gate is open (apex_ouvert: the flag DialogueVolcan waits for, the way down opens).
static func hearts_in_the_door() -> void:
	ApexBag.hearts_in_door()
	Game.set_flag(&"apex_ouvert")
	Game.party_changed.emit()


## Watched, no line: they go through the gate and the amber light takes them (they wait below).
static func _gone_down(cast: Dictionary) -> void:
	for k in ["isaure", "maia", "caillou"]:
		var n = cast.get(k)
		if is_instance_valid(n) and n is Node2D:
			Stage.fade_out(n, 1.6, false)
	await S.wait(1.8)
	for k in ["isaure", "maia", "caillou"]:
		var n = cast.get(k)
		if is_instance_valid(n) and n is Node:
			(n as Node).queue_free()


## One of her four, examined (no line written for them: a look and a cry).
static func sea_dino(who: Node) -> void:
	Stage.turn_to(who, A.chloe_px())
	Stage.cry(who, &"neutre")
	Stage.emote(who, "…")
	await S.wait(1.0)


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): the dawn at the door on any zone (Isaure, Maïa and
## Caillou brought on before Chloé): « C'est l'aube » (the test picks 0), the last demand, the
## whistle, her own; the choice before Carène without the battles (the test picks one), then her
## word kept, the decision (the test picks one), the gate.
static func static_aube() -> void:
	S.playing += 1
	var chloe := Stage.chloe()
	var base := chloe.global_position
	Game.set_flag(&"isaure_porte_vue")
	Game.set_flag(&"maia_porte_vue")
	Game.set_flag(&"lettre_isaure_donnee")
	var isaure_npc = V.actor_of(ISAURE_NODES)   # (at the door: the zone's own; elsewhere, brought on)
	if isaure_npc == null:
		isaure_npc = S.stranger("IsaurePorte", V.sheet(A.ISAURE_SHEETS), S.ground_near(base + Vector2(0.0, -3.0 * S.CELL), 3), "up", ISAURE)
		S.stranger("MaiaPorte", V.sheet(A.MAIA_SHEETS), S.ground_near(base + Vector2(-2.6 * S.CELL, -2.4 * S.CELL), 3), "down", MAIA)
		var caillou := V.stand_in(&"triceratops", S.ground_near(base + Vector2(2.8 * S.CELL, -3.2 * S.CELL), 3), "CaillouPorte")
		if caillou:
			Stage.fade_in(caillou, 0.2)
	if isaure_npc == null:
		S.playing -= 1
		return
	var cast := _cast(isaure_npc)
	S.lock(true)
	await S.say([{"who": ISAURE, "text": "Ton équipe est au complet, moussaillon ? Le jour ne va pas tarder."}])
	await Dialogue.choose("", "Isaure attend.", ["C'est l'aube.", "Pas encore."])
	await _dawn(cast)
	await S.say(last_demand(isaure_npc, cast))
	await _whistle(isaure_npc, cast)
	await S.say(her_own(isaure_npc, cast))
	var pick := await Dialogue.choose("", DialogueApex.CARENE_PROMPT, DialogueApex.CARENE_OPTIONS)
	await S.say(DialogueApex.carene_reply(pick))
	Game.set_flag(&"isaure_vaincue")
	await _kept_word(isaure_npc, cast)
	S.lock(false)
	S.playing -= 1
