class_name VolcanSanctuaire
## Chapter 8, the Plaine Volcanique, the lava flows and the sanctuary of Magma (zones coulees_lave
## and sanctuaire_magma; docs/chapitre-8-scenes.md, scenes 7 and 8): black rock split by red rivers
## « comme du miel trop chaud »; the lead dino and the heat; the first flow (« le cuir pour »: a
## lead dino of stone or fire carries Chloé over it, the mechanics are the MÉCANIQUES agent's);
## the crack « On n'entre pas sans frapper. Ici, c'est lui qui frappe. — H. ». The round hall of
## black glass (« Le masque d'obsidienne était fait de ça »), the basin's water trembling, the
## T-Rex de Magma who sees her very well (« Et je ne cours pas »), the Sceaux sniffed one by one, the
## hands; a battle of honour; won, it stamps the altar: the Fifth Cœur and the Sceau du Volcan; it
## lies down and smokes; the volcano rumbles and the lava draws back from the crater's path.
## Flags: coulees_arrivee, lave_franchie, sanctuaire_magma_arrivee, flaque_tremble,
## trex_magma_parle, trex_magma_battu, sceau_volcan, coeur_5, lave_retiree.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const V := preload("res://story/volcan.gd")
const CHLOE := "Chloé"
## The guardian: a battle of honour (level 48 of the scenes; the MÉCANIQUES agent's species).
const TREX := &"trex_magma"
const TREX_NAME := "T-Rex de Magma"
const TREX_NODES := ["TrexMagma"]
const TREX_LEVEL := 48
const HEART := "coeur_5"
const SEAL := "sceau_volcan"
const ALTAR_KIND_OUT := "autel_magma_fendu"
const SHELL_KIND := "coque_lave"
## How far it steps out of the wall of lava (tiles), how close it bends to Chloé (px).
const FROM_WALL := 2.5
const BENDS_TO := 70.0
const XP_COULEES := 30
const XP_SANCTUAIRE := 30
const XP_SCEAU := 150
const SPRING := "Tes dinos boivent l'eau de la source chaude. Elle a un goût d'œuf, et elle remet d'aplomb."
const WAITS := "Il attend. Il a attendu vingt-cinq ans ; il ne compte plus les jours."


# ------------------------------------------------------------------ the lava flows

## 7 a, the first time on the lava flows: black rock, red rivers, the air trembling; hot like an
## oven OPEN; the lead dino and the red; Moustique hides in her collar entirely.
static func coulees() -> void:
	if Game.flag(&"coulees_arrivee"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.4)
	var chloe := Stage.chloe()
	var flow := V.at_node(["PremiereCoulee"], V.spot("PREMIERE_COULEE", Vector2(3.0 * S.CELL, 0.0)))
	var red := func() -> void:
		await Stage.look_at(flow, 1.2)
		CS.pulse(flow, V.FIRE_RED, 3, 1.6, 2.6, 5.0)
		await S.wait(1.0)
		Stage.tremble(chloe, 0.6, 1.0)
	var smears := func() -> void:
		Stage.look_back(0.8)
		await CS.reach(chloe, chloe.global_position + Vector2(0.0, -40.0), 4.0, 0.7)
		Act.burst(chloe.global_position + Vector2(4.0, 0.0), V.ASH_BITS, 6, 1.3, 0.1)
	var lines: Array = [
		CS.cue({"text": "Les coulées. La roche est noire, et fendue de rivières rouges qui bougent lentement, comme du miel trop chaud. L'air tremble au-dessus. Ça sent le feu, et l'odeur fait tousser."}, red),
		CS.cue({"text": "Il fait chaud. Pas chaud comme un four : chaud comme un four ouvert. Chloé s'essuie le front du revers de la main : elle se barbouille de cendre. Évidemment."}, smears),
	]
	var lead := Game.lead_dino()
	if lead:
		lines.append_array(_lead_and_the_red(lead, flow))
	lines.append_array([
		CS.cue({"text": "Moustique se cache dans le col de Chloé, tout entier. Il n'en sort plus que le bout du bec."}, func() -> void: V.shoulder_peek(chloe, 0.8)),
		{"who": CHLOE, "text": "Je sais. Tu as peur du feu. Elle me l'a dit. Reste là."},
		{"who": CHLOE, "text": "(Pour passer, il faut quelqu'un qui n'a pas peur du feu. Ou qui est fait en pierre. « Le cuir pour », a dit Dame Suie. … Pas moi, en tout cas.)" if Game.flag(&"suie_partie")
			else "(Pour passer, il faut quelqu'un qui n'a pas peur du feu. Ou qui est fait en pierre. … Pas moi, en tout cas.)"},
		{"flag": &"coulees_arrivee"},
	])
	await S.say(lines)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_COULEES)
	Save.save_game()
	S.lock(false)


## How the lead dino meets the red (the raptor: « Pas question. »; the armoured one has the hide
## for it; the duck-bill's call does not come back: the heat eats the sounds).
static func _lead_and_the_red(lead: Dino, flow: Vector2) -> Array:
	var dino := CS.lead()
	var chloe := Stage.chloe()
	match lead.species().family:
		&"raptor":
			return [CS.cue({"text": "%s avance une patte vers le rouge, la retire, et regarde Chloé : « Pas question. »" % lead.nickname},
				func() -> void:
					if dino:
						await CS.lead_walk(flow.lerp(chloe.global_position, 0.5), 90.0)
						Stage.turn_to(dino, flow)
						await Stage.lunge(dino, flow, 0.5, false)
						Stage.recoil(dino, flow, 12.0)
						Stage.turn_to(dino, chloe.global_position)
						Stage.emote(dino, "…"))]
		&"armored":
			return [CS.cue({"text": "%s avance jusqu'au bord de la coulée, s'y arrête, et renifle. %s ne recule pas. %s a le cuir pour." % [lead.nickname, V.pronoun(lead), V.pronoun(lead)]},
				func() -> void:
					if dino:
						await CS.lead_walk(flow.lerp(chloe.global_position, 0.25), 40.0)
						Stage.turn_to(dino, flow)
						Stage.bow(dino, 1.2))]
		&"hadrosaur":
			return [CS.cue({"text": "%s recule de deux pas et lance un « tuut » long et bas, qui ne revient pas. Rien ne revient, ici : la chaleur mange les sons." % lead.nickname},
				func() -> void:
					if dino:
						Stage.recoil(dino, flow, 20.0)
						Stage.rear(dino, 1.0)
						Stage.cry(dino, &"neutre"))]
	return []


## 7 b, the first flow (StoryTrigger « PremiereCoulee » on its south bank, once_flag
## lave_franchie): without a lead dino of stone or fire, « lave_bloquee » (who could, or where to
## find one: Lava.blocked_lines). With one, nothing: the crossing itself says « lave_franchie », once
## (actors/lava.gd, the MÉCANIQUES agent's: Chloé on its back, the mechanics carry her).
static func premiere_coulee(_trigger: Node) -> void:
	if Game.flag(&"lave_franchie") or Lava.can_cross():
		return
	S.lock(true)
	var flow := V.at_node(["PremiereCoulee"], V.spot("PREMIERE_COULEE_TRAVERSEE", Vector2(0.0, -3.0 * S.CELL)))
	var lines: Array = Lava.blocked_lines()
	lines[0] = CS.cue(lines[0], func() -> void:
		Stage.look_at(flow, 1.0)
		CS.pulse(flow, V.FIRE_RED, 2, 1.4, 2.4, 4.0))
	await S.say(lines)
	Stage.look_back()
	S.lock(false)


## 7 e, the crack of the sanctuary (StoryTrigger or prop « Faille »).
static func faille(_who: Node) -> void:
	await S.say(DialogueVolcan.lines(&"faille_sanctuaire"))


# ------------------------------------------------------------------ the sanctuary of Magma

## 8 a, the first time in the sanctuary (6 lines): the round hall of black glass, the altar, the
## wall where the lava flows like sand in an hourglass; the basin's water trembles, « boum »; Chloé
## does not move. The T-Rex de Magma comes in through the wall of lava (watched, no line). Then
## 8 b at once (7 lines, up to the roar and the choice).
static func arrival() -> void:
	var guardian = V.actor_of(TREX_NODES)
	if Game.flag(&"sceau_volcan"):
		if guardian is Node2D:
			if V.has_place("TREX_COUCHE"):
				(guardian as Node2D).global_position = V.px("TREX_COUCHE")
			CS.crouch(guardian, 0.3, 0.1)   # (it sleeps by the altar, and smokes)
		return
	if Game.flag(&"sanctuaire_magma_arrivee"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.4)
	var chloe := Stage.chloe()
	var altar := V.at_node(["AutelMagma"], V.spot("AUTEL_MAGMA", Vector2(0.0, -5.0 * S.CELL)))
	var wall := V.spot_or("LAVE_PAROI", altar + Vector2(0.0, -4.0 * S.CELL))
	var basin := V.at_node(["Vasque", "VasqueSource"], V.spot("VASQUE", Vector2(-2.0 * S.CELL, -1.0 * S.CELL)))
	if guardian == null:
		guardian = V.stand_in(TREX, wall, "TrexMagmaScene", 0, 1.4)
	if guardian:
		guardian.modulate.a = 0.0
		if guardian is DinoNpc:
			(guardian as Node2D).global_position = S.ground_near(wall + Vector2(0.0, FROM_WALL * S.CELL), 3)
	var glass := func() -> void:
		for i in 3:
			CS.pulse(chloe.global_position + Vector2(-160.0 + 160.0 * i, -120.0), V.FIRE_RED, 2, 1.4, 1.8, 5.0)
		Stage.turn_to(chloe, chloe.global_position + Vector2(-60.0, 0.0))
		await S.wait(1.0)
		Stage.turn_to(chloe, chloe.global_position + Vector2(60.0, 0.0))
	var altar_wall := func() -> void:
		await Stage.look_at(altar, 1.0)
		await S.wait(0.8)
		await Stage.look_at(wall, 1.0)
		CS.pulse(wall, V.FIRE_RED, 3, 2.0, 2.0, 5.0)
	var trembles := func() -> void:
		Stage.look_back(0.8)
		var dino := CS.lead()
		if dino:
			CS.lead_walk(chloe.global_position + Vector2(-26.0, 10.0), 60.0)
		await S.wait(1.2)
		await Stage.close_up(basin, 4.0, 1.2)
		var water := Stage.puddle(basin, 0.5)
		for i in 3:
			if water:
				water.impact()
			Stage.shake(1.4, 0.3)
			CS.sfx(V.BLOW, -16.0)
			await S.wait(1.1)
		if water:
			water.queue_free()
	var still := func() -> void:
		Stage.wide()
		Stage.look_back(0.6)
		Stage.turn_to(chloe, wall)
	var lines: Array = [
		CS.cue({"text": "La faille s'ouvre sur une salle ronde. Les murs sont noirs et brillants : du verre. De l'obsidienne. Dessous, la lave les éclaire en rouge, et on se voit dedans, en rouge, partout."}, glass),
		{"who": CHLOE, "text": "(Le masque. Le masque d'obsidienne était fait de ça. De cette pierre-là.)"},
		CS.cue({"text": "Au centre, un autel de roche noire, vide. Au fond, une paroi de verre où la lave coule, à l'intérieur, lentement, comme du sable dans un sablier."}, altar_wall),
		CS.cue({"text": "C'est calme. Trop calme : le dino de tête se colle contre la jambe de Chloé. Puis, dans la vasque, des cercles à la surface de l'eau. Un « boum », tout bas, qui monte par les pieds. Encore des cercles."}, trembles),
		{"who": CHLOE, "text": "(Il arrive. … « Un T-Rex ne voit pas ce qui ne bouge pas. » Roc a dit : une légende. Cours.)" if Game.flag(&"roc_trex_legende") else "(Il arrive.)"},
		CS.cue({"text": "Chloé ne bouge pas. Le dino de tête ne bouge pas. Moustique, dans le col, ne respire plus."}, still),
		{"flag": &"sanctuaire_magma_arrivee"},
		{"flag": &"flaque_tremble"},
	]
	await S.say(lines)
	await _comes_in(guardian, wall)
	Game.award_team_xp(XP_SANCTUAIRE)
	Save.save_game()
	S.lock(false)
	if guardian:
		await trex(guardian)


## Watched, no line: in the wall of glass, behind the lava, a shadow rises, huge; the wall opens
## like a curtain of lava and the T-Rex de Magma comes in. A foot: the ground shakes. The other.
## It bends its head down to Chloé.
static func _comes_in(guardian, wall: Vector2) -> void:
	if guardian == null:
		await S.wait(1.0)
		return
	var chloe := Stage.chloe()
	await Stage.look_at(wall, 0.8)
	CS.pulse(wall, V.FIRE_RED, 1, 1.0, 3.5, 6.0)
	await Stage.fade_in(guardian, 1.0)
	var to := S.ground_near(chloe.global_position + Vector2(0.0, -BENDS_TO - 40.0), 3)
	if guardian is DinoNpc:
		var from: Vector2 = (guardian as Node2D).global_position
		for k in 2:
			await (guardian as DinoNpc).walk_to(from.lerp(to, 0.5 * (k + 1)), 50.0)
			Stage.shake(2.2, 0.35)
			CS.sfx(V.BLOW, -8.0)
	Stage.look_at(chloe.global_position.lerp((guardian as Node2D).global_position, 0.5), 0.8)
	Stage.turn_to(guardian, chloe.global_position)
	await CS.Act.lean(guardian, chloe.global_position, 18.0, 2.0)
	MS.breath(guardian, 10)
	await S.wait(0.6)


# ------------------------------------------------------------------ the T-Rex de Magma

## 8 b to 8 d, the guardian (DinoNpc « TrexMagma », event « trex_magma »): the Sceaux and the
## bag, the hands, the roar; a battle of honour; won, the Cœur and the Sceau. Asleep afterwards.
static func trex(who: Node) -> void:
	if Game.flag(&"sceau_volcan"):
		await S.say([{"text": "Le T-Rex de Magma dort, et il fume. Hélène l'avait écrit. Chloé ne le réveille pas." if Game.flag(&"found_journal_35")
			else "Le T-Rex de Magma dort, et il fume. Chloé ne le réveille pas."}])
		return
	if not Game.flag(&"trex_magma_battu"):
		if not Game.flag(&"trex_magma_parle"):
			S.lock(true)
			await S.say(_sniffs(who))
			S.lock(false)
		var prompt := "(Un combat d'honneur. Le dernier. Le plus dur. Il veut savoir si je peux tenir.)" if not Game.flag(&"trex_magma_tente") else WAITS
		if await Dialogue.choose("", prompt, ["Relever le défi", "Pas encore"]) != 0:
			return
		Game.set_flag(&"trex_magma_tente")
		await MS.rested(SPRING, func() -> void:
			var dino := CS.lead()
			if dino:
				Stage.bow(dino, 0.8))
		var foe = V.from_battles(&"trex", [], null)
		if not foe is Dino:
			foe = Dino.create(V.species_or(TREX), TREX_LEVEL, TREX_NAME)
		var rules := {"catch": false, "run": false, "lose_spawn": V.spawn("SPAWN_COULEES"),
			"intro": "Le T-Rex de Magma rugit, et toute la salle de verre chante avec lui ! (Combat d'honneur : pas de collier, pas de fuite.)",
			"lesson": lesson(foe)}
		var theme: AudioStream = MS.music(MS.ALPHA_MUSIC)
		if theme:
			rules["music"] = theme
		rules.merge(V.from_battles(&"trex_rules", [], {}), true)   # (the MÉCANIQUES agent's rules win)
		var result: String = await S.world().call(&"_battle", foe, rules)
		if result != "win":
			if result == "lose":
				await S.say([{"text": WAITS}])
			return
		Game.set_flag(&"trex_magma_battu")
		Save.save_game()
	await _gives_heart(who)


## The battle's lesson, from its type (never a cheat: what the type chart says): what hits it
## hard; what it shrugs off (« L'Eau et la Pierre le touchent fort ; le Feu et le Vent, lui, les
## traverse. » for the scenes' intended fire type).
static func lesson(foe: Dino) -> Array:
	var type := foe.type()
	var weak := MS.weak_to(type)
	var shrugs: Array = []
	for attacker: String in MovesDB.TYPE_CHART:
		if float(MovesDB.TYPE_CHART[attacker].get(type, 1.0)) < 1.0:
			shrugs.append(attacker)
	if weak == "":
		return []
	var line := "%s le touche%s fort" % [weak.substr(0, 1).to_upper() + weak.substr(1), "nt" if " et " in weak else ""]
	if not shrugs.is_empty():
		line += " ; %s, lui, les traverse." % MS.words(shrugs)
	else:
		line += "."
	return [line]


## It looks her in the eyes: it sees her very well (« Et je ne cours pas »). It sniffs the Sceaux
## one by one (the Désert: an old neighbour; the Côte: the fish; the Monts: too cold; the Cieux: it
## looks up), then the empty bag, and growls; Chloé holds out both hands, as on page 10; it blows
## on them: warm, not burning; it backs to the altar and roars.
static func _sniffs(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else chloe.global_position + Vector2(0.0, -120.0)
	var altar := V.at_node(["AutelMagma"], V.spot_or("AUTEL_MAGMA", at + Vector2(0.0, -2.0 * S.CELL)))
	var basin := V.at_node(["Vasque", "VasqueSource"], V.spot_or("VASQUE", chloe.global_position + Vector2(-2.0 * S.CELL, 0.0)))
	var seals := func() -> void:
		for i in 2:
			await CS.Act.lean(who, chloe.global_position, 14.0, 0.8)
		MS.breath(who, 12)
		await S.wait(0.6)
		await CS.Act.lean(who, chloe.global_position, 10.0, 0.6)
		Stage.recoil(who, chloe.global_position, 10.0)
		await S.wait(0.6)
		Stage.rear(who, 1.6)
	var bag := func() -> void:
		for i in 2:
			await CS.Act.lean(who, chloe.global_position + Vector2(10.0, 0.0), 16.0, 0.7)
		Stage.cry(who, &"neutre")
		Stage.shake(0.8, 0.5)
	var hands := func() -> void:
		Stage.turn_to(chloe, at)
		CS.reach(chloe, at, 12.0, 1.4)
	var roars := func() -> void:
		await CS.Act.lean(who, chloe.global_position, 16.0, 1.0)
		MS.breath(who, 8)
		await S.wait(0.8)
		if who is DinoNpc:
			await (who as DinoNpc).walk_to(S.ground_near(altar + Vector2(0.0, 60.0), 2), 50.0)
		Stage.turn_to(who, chloe.global_position)
		Stage.rear(who, 1.6)
		Stage.cry(who, &"attaque")
		Stage.shake(3.0, 1.2)
		CS.pulse(altar, V.FIRE_RED, 2, 1.0, 3.0, 6.0)
		var water := Stage.puddle(basin, 0.5)
		if water:
			for i in 3:
				water.impact()
				await S.wait(0.4)
			water.queue_free()
	var eyes := func() -> void:
		Stage.look_at(chloe.global_position.lerp(at, 0.5), 0.8)
		Stage.turn_to(who, chloe.global_position)
		MS.breath(who, 6)
	return [
		CS.cue({"text": "Le T-Rex de Magma la regarde. Droit dans les yeux. Il la voit très bien."}, eyes),
		{"who": CHLOE, "text": "(Une légende. … Roc avait raison. Et je ne cours pas.)" if Game.flag(&"roc_trex_legende") else "(… Et je ne cours pas.)"},
		CS.cue({"text": "Il renifle les Sceaux, un par un. Le Désert : un grand souffle chaud, comme on salue un vieux voisin. La Côte : il fronce les naseaux. Les Monts : il recule la tête. Les Cieux : il lève les yeux vers la voûte, longtemps."}, seals),
		CS.cue({"text": "Puis la sacoche. Il renifle, cherche, renifle encore. Il gronde, tout bas."}, bag),
		{"who": CHLOE, "text": "Je les avais. Les quatre. On me les a pris, là-haut. Ils sont devant la porte, et ils vont servir à ouvrir ce qu'elle a fermé."},
		CS.cue({"who": CHLOE, "text": "Je sais que vous ne comprenez pas les mots. Elle disait que vous compreniez les mains."}, hands),
		CS.cue({"text": "Il souffle sur ses mains. Chaud. Pas brûlant. Puis il recule jusqu'à l'autel, et il rugit, et toute la salle de verre chante avec lui."}, roars),
		{"flag": &"trex_magma_parle"},
	]


## 8 d, won: it stamps the altar once; the glass cracks in a star, lava rises, sets black, cracks
## open like a nut: the Fifth Cœur, and the Sceau du Volcan beside it. It lies down at last and
## smokes; Chloé's hand on its muzzle; the volcano rumbles: the lava draws back (lave_retiree).
## Also played by the altar if the scene was cut short after the battle.
static func _gives_heart(who: Node) -> void:
	if Game.flag(&"sceau_volcan"):
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else chloe.global_position + Vector2(0.0, -120.0)
	var altar_node = V.actor_of(["AutelMagma"])
	var altar := V.at_node(["AutelMagma"], V.spot_or("AUTEL_MAGMA", at + Vector2(0.0, 60.0)))
	var stamps := func() -> void:
		Stage.look_at(altar.lerp(chloe.global_position, 0.3), 0.8)
		await Stage.lunge(who, altar, 2.0)
		CS.sfx(V.BLOW, -2.0)
		Stage.shake(4.0, 0.8)
		CS.pulse(altar, V.FIRE_RED, 2, 1.2, 4.0, 5.0)
		if altar_node:
			Stage.repaint(altar_node, ALTAR_KIND_OUT)
		var shell := Stage.show_thing(SHELL_KIND, altar + Vector2(0.0, 14.0), "CoqueLave")
		if shell:
			shell.set_meta(&"scene_thing", true)
		for i in 3:
			Act.burst(altar, V.EMBER_BITS, 10, 0.3, 0.3)
			await S.wait(0.4)
	var heart := func() -> void:
		await CS.chloe_walk(altar + Vector2(-30.0, 36.0), 90.0, 2.0)
		Stage.turn_to(chloe, altar)
		await CS.reach(chloe, altar, 12.0, 0.8)
		if ItemsDB.ITEMS.has(HEART):
			CS.Act.pop(chloe.global_position, HEART, 0.9)
		MS.hearts(3, 0.5)
	var seal := func() -> void:
		CS.sparkle(altar, 0.6, 16, 0.3)
		if ItemsDB.ITEMS.has(SEAL):
			CS.Act.pop(chloe.global_position + Vector2(10.0, 0.0), SEAL, 1.0)
	var lies := func() -> void:
		if who is DinoNpc and V.has_place("TREX_COUCHE"):
			await (who as DinoNpc).walk_to(V.px("TREX_COUCHE"), 50.0)
		var head: Vector2 = (who as Node2D).global_position if who is Node2D else at
		CS.crouch(who, 0.3, 1.6)
		for i in 3:
			MS.breath(who, 8)
			await S.wait(0.7)
		await CS.chloe_walk(head + Vector2(-50.0, 40.0), 80.0, 2.0)
		Stage.turn_to(chloe, head)
		CS.reach(chloe, head, 10.0, 1.2)
	var rumbles := func() -> void:
		Stage.shake(3.0, 2.4)
		CS.sfx(MS.RUMBLE, -2.0)
		await S.wait(2.4)
		CS.sfx(V.STONE, -6.0)
		await S.wait(0.8)
		MS.hearts(2, 1.4)
	await S.say([
		CS.cue({"text": "Il frappe l'autel du pied. Une fois. Le verre se fend en étoile, et sous l'autel, de la lave monte, rouge, et se fige, noire, et craque : au milieu, dans une coque de lave ouverte comme une noix, le Cinquième Cœur."}, stamps),
		CS.cue({"text": "Il est chaud comme du pain qui sort du four. Il bat fort, vite, comme s'il avait couru. Comme s'il savait qu'il est le dernier."}, heart),
		CS.cue({"text": "Dans la coque, à côté, un disque d'ambre rouge sombre : une flamme, et la fougère d'Hélène. Le Sceau du Volcan."}, seal),
		{"who": CHLOE, "text": "(Un Cœur. Un seul. Elle en a quatre, et moi un, et il faut les cinq. Alors elle a besoin de moi. Et moi d'elle. … C'est bête, mais ça me rassure.)"},
		{"flag": &"coeur_5"},
		{"flag": &"sceau_volcan"},
		CS.cue({"text": "Il se couche, et il fume, doucement, par les naseaux. Chloé pose la main sur son museau : chaud comme une pierre au soleil."}, lies),
		{"who": CHLOE, "text": "Elle vous appelait comment ? … Elle vous appelait sûrement quelque chose."},
		CS.cue({"text": "Dehors, le volcan gronde, long, fort ; la salle tremble ; puis un grand bruit de pierre qui coule, et plus rien. Le Cœur, contre Chloé, bat plus calme."}, rumbles),
		{"who": CHLOE, "text": "(Quelque chose a bougé, dehors. Un chemin, peut-être.)"},
		{"flag": &"lave_retiree"},
	])
	if ItemsDB.ITEMS.has(HEART) and Game.item_count(HEART) == 0:
		Game.give_item(HEART)
	if ItemsDB.ITEMS.has(SEAL) and Game.item_count(SEAL) == 0:
		Game.give_item(SEAL)
	Game.party_changed.emit()
	Toast.say(S.world().get_tree(), "Objets obtenus : le Sceau du Volcan et le Cinquième Cœur d'ambre")
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_SCEAU)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ the altar, the basin

## The altar (StoryProp « AutelMagma »): the Cœur if the scene was cut short after the battle.
static func autel(_who: Node) -> void:
	if Game.flag(&"trex_magma_battu") and not Game.flag(&"sceau_volcan"):
		await _gives_heart(V.actor_of(TREX_NODES))
		return
	if Game.flag(&"sceau_volcan"):
		await S.say([{"text": "L'autel, fendu en étoile. Dans la coque de lave ouverte comme une noix, la place du Cœur est vide."}])
		return
	await S.say([{"text": "Au centre, un autel de roche noire, vide."}])


## The basin of hot water at the way in (StoryProp « Vasque »): its circles; the party drinks it,
## like before each try (« un goût d'œuf, et elle remet d'aplomb »).
static func vasque(_who: Node) -> void:
	var tired := Game.party.any(func(d: Dino) -> bool: return d.hp < d.max_hp())
	if tired:
		Game.heal_party()
		Game.party_changed.emit()
		await S.say([{"text": SPRING}])
		return
	await S.say([{"text": "La vasque. Des cercles à la surface de l'eau."}])


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): the lava flows' arrival and the first flow (without a
## dino of stone or fire: « lave_bloquee »), on any zone.
static func static_coulees() -> void:
	S.playing += 1
	await coulees()
	await premiere_coulee(null)
	await faille(null)
	S.playing -= 1


## For the tests: the sanctuary on any zone (a stand-in T-Rex): the arrival and 8 b; the challenge
## put off (« Pas encore »: the test picks it), then the battle skipped (trex_magma_battu) and 8 d.
static func static_sanctuaire() -> void:
	S.playing += 1
	await arrival()
	Game.set_flag(&"trex_magma_battu")
	await _gives_heart(V.actor_of(["TrexMagmaScene"] + TREX_NODES))
	S.playing -= 1
