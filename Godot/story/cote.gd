class_name Cote
## Chapter 5, the Côte Préhistorique (docs/histoire.md, ch. 5), out on the coast: arriving over
## the bay (the sea at last, the sleeping Archelons, the reef and its blue glow, the Pteranodons
## and Moustique); Gustave and Firmin, fishermen now, who tell of the boat without a lantern;
## Maïa on the cliffs, at the top of her form (challenge n° 5 « with the sea behind me », the tin
## box of Hélène's lookout « we'll open together »); the first night: the boat slips through the
## reef and into the cliff, and a little light goes out on the lookout; Roc at the Cabinet (the
## Sceau, the map, « surtout pas à Isaure »). The lagoon is in story/cote_lagon.gd, the caves in
## cote_grottes.gd, the reef in cote_recif.gd, the end in cote_fin.gd.
## Flags: cote_arrivee, pecheurs_vus, maia_falaises_vue, barque_nuit_vue, roc_sceau_cote,
## roc_carte_intacte, roc_isaure; pecheurs_n, maia_falaises_n (lines).

const S := preload("res://story/story.gd")
const P := preload("res://story/cote_places.gd")
const CS := preload("res://story/cote_stage.gd")
const A := preload("res://story/cote_ask.gd")
const FIN := preload("res://story/cote_fin.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ROC := "Prof. Roc"
const GUSTAVE := "Gustave"
const FIRMIN := "Firmin"
const XP_ARRIVEE := 20
const XP_PECHEURS := 30
const XP_MAIA := 30
const XP_NUIT := 30
## The light of the reef's heart seen from the dune, and Maïa's little lantern on the lookout.
const REEF_BLUE := Color(0.45, 0.75, 1.0)
const REEF_SPARKS: Array[Color] = [Color(0.55, 0.85, 1.0), Color(0.75, 0.95, 1.0), Color(0.4, 0.7, 1.0)]
## Sitting on the sand (a squash of the picture, Desert._crouch).
const SITTING := 0.26
## How far below the dune the lead dino goes looking for the sea (tiles).
const SEA_REACH := 10
## Pteranodons wheeling over the cliffs when Chloé first sees them.
const FLOCK := 5
## The colony's nests (their picture once the Côte's decor has it), around Maïa on the cliffs (px).
const NEST := "nid_pteranodon"
const NEST_STAND_IN := "nid_oviraptor"
const NEST_SPOTS := [Vector2(-200.0, -60.0), Vector2(60.0, -150.0), Vector2(230.0, -120.0)]
const LANTERN := Color(1.0, 0.78, 0.45)
## Gustave and Firmin afterwards (the next one each time): [speaker, line].
const PECHEURS_AGAIN := [
	[GUSTAVE, "Les sardines reviennent, on dirait. Ou alors ce sont les mêmes, qui font des allers-retours pour nous faire plaisir."],
	[FIRMIN, "J'ai trouvé du sable dans mon oreiller. Je vis au bord de la mer, et j'ai du sable dans mon OREILLER."],
	[GUSTAVE, "Les tortues pondent là-haut, dans le sable sec. Les petits sortent au crépuscule… et les Masiakasaurus aussi. Ces voleurs-là ont les dents qui poussent vers l'avant, exprès pour les œufs."],
	[FIRMIN, "Gustave a peur des poules. Moi, j'ai peur des tortues. Elles te regardent comme si elles savaient ce que t'as fait l'été dernier."],
]


# ------------------------------------------------------------------ arriving

## The first time on the Côte: from the last dune, the sea; the turtles, the reef and its blue
## glow (the Cœurs answer it), the Pteranodons and Moustique; the lead dino meets the sea.
## Afterwards: Moustique once the third Cœur is Chloé's, or the night's boat.
static func arrival() -> void:
	if Game.flag(&"cote_arrivee"):
		if Game.flag(&"coeur_3") and not Game.flag(&"moustique_vu"):
			await FIN.moustique()
		elif Game.phase() == &"night":
			await night()
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var to_the_dune := func() -> void:
		var top := S.at(P.DUNE_MER.x, P.DUNE_MER.y)
		w.player.teleport(top)
		w.companion.stand_beside(top)
		w.player.face_towards(top + Vector2(0.0, -200.0))
		await S.wait(0.3)
	await S.fade_through(to_the_dune, 0.7)
	var chloe := Stage.chloe()
	var dark: bool = Game.phase() == &"night"
	var bay := S.at(P.PLAGE_TORTUES.x, P.PLAGE_TORTUES.y)
	var turtle := CS.stand_in(&"archelon", S.ground_near(bay + Vector2(96.0, -40.0), 4), "TortueArrivee")
	var lines: Array = [
		CS.cue({"text": "Les dunes descendent, descendent… et s'arrêtent d'un coup. Devant Chloé, la mer. Immense. Pour la première fois depuis Port-Ambre, Chloé l'entend respirer."},
			func() -> void:
				CS.chloe_walk(chloe.global_position + Vector2(0.0, -30.0), 60.0, 0.8)
				Stage.look_at(chloe.global_position.lerp(bay, 0.5), 1.4)),
		CS.cue({"text": "Sur la plage, de gros rochers ronds sont posés sur le sable. L'un d'eux ouvre un œil. Puis il bâille."},
			func() -> void: _turtle_yawns(turtle)),
		CS.cue({"who": CHLOE, "text": "Des tortues ! Grandes comme des barques !"}, func() -> void: Stage.emote(chloe, "!")),
	]
	lines.append_array(_reef_lines(dark))
	lines.append_array(_cliff_lines(dark))
	var lead := Game.lead_dino()
	if lead:
		lines.append(_meets_the_sea(lead))
	lines.append({"flag": &"cote_arrivee"})
	await S.say(lines)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)


## A great turtle opens an eye and yawns (it stays on the beach afterwards).
static func _turtle_yawns(turtle: DinoNpc) -> void:
	Stage.look_at(turtle.global_position if turtle else S.at(P.PLAGE_TORTUES.x, P.PLAGE_TORTUES.y), 1.2)
	if turtle == null:
		return
	await Stage.fade_in(turtle, 0.4)
	await S.wait(0.6)
	Stage.emote(turtle, "…")
	turtle.cry(&"neutre")
	Stage.rear(turtle, 1.6)


## The reef closing the lagoon; a blue light beating under the water in its middle; the Cœurs
## Chloé carries answer it.
static func _reef_lines(dark: bool) -> Array:
	var glow_at := S.at(P.LUEUR_RECIF.x, P.LUEUR_RECIF.y)
	var glows := func() -> void:
		await CS.pan(glow_at + Vector2(0.0, 3.0 * S.CELL), 1.6)
		CS.pulse(glow_at, REEF_BLUE, 3, 1.4, 5.0, 6.0)
		for i in 3:   # (seen by day too: blue sparks well up from under the water with each beat)
			CS.Act.burst(glow_at, REEF_SPARKS, 18, CS.Act.ON_WATER, 0.7)
			await S.wait(1.4)
	var lines: Array = [
		CS.cue({"text": "Au nord, un long anneau d'écume ferme le lagon : le récif. Et en son milieu, sous l'eau, une lueur bleue s'allume… s'éteint… se rallume. Lentement. Comme un cœur qui dort." if not dark
			else "Au nord, sous la lune, un long anneau d'écume ferme le lagon : le récif. Et en son milieu, sous l'eau, une lueur bleue s'allume… s'éteint… se rallume. Comme un cœur qui dort."}, glows),
	]
	if Game.flag(&"coeur_1") or Game.flag(&"coeur_2"):
		lines.append_array([
			CS.cue({"text": "Dans la sacoche de Chloé, les Cœurs lui répondent : un battement chaud, un seul, en même temps que la lueur."},
				func() -> void: CS.hearts_beat(1, 1.2)),
			{"who": CHLOE, "text": "(Le troisième Cœur… Il est là-dessous.)"},
		])
	return lines


## The cliffs white with Pteranodons; a tiny one chasing a big one for its fish: Moustique.
static func _cliff_lines(dark: bool) -> Array:
	var cliffs := S.at(P.FALAISES.x, P.FALAISES.y)
	var flock := {}
	var soar := func() -> void:
		await CS.pan(cliffs + Vector2(-2.0 * S.CELL, 3.0 * S.CELL), 1.6)
		for i in FLOCK:
			var p := CS.stand_in(&"pteranodon", cliffs + Vector2(-240.0 + 120.0 * i, 30.0 + 40.0 * (i % 2)), "PteranodonArrivee%d" % i)
			if p:
				flock[i] = p
				Stage.fade_in(p, 0.6)
				CS.circle(p, p.global_position + Vector2(40.0, 0.0), 60.0 + 15.0 * i, 3.2 + 0.3 * i, CS.FLY_HEIGHT + 20.0 * (i % 3))
	var chase := func() -> void:
		var big: DinoNpc = flock.get(0)
		var small := CS.stand_in(&"dimorphodon", cliffs + Vector2(-260.0, 120.0), "MoustiqueArrivee")
		if small == null:
			return
		flock["moustique"] = small
		Stage.fade_in(small, 0.4)
		small.cry(&"attaque")
		var to := cliffs + Vector2(-60.0, 40.0)
		if big:
			CS.fly(big, to + Vector2(80.0, -20.0), 1.4)
		await CS.fly(small, to, 1.5)
		small.cry(&"attaque")
		Stage.hop(small, 2, 6.0)
	var lines: Array = [
		CS.cue({"text": "À l'est, les falaises sont blanches d'oiseaux. Non : de Ptéranodons. Des dizaines, qui tournent dans le vent sans même battre des ailes." if not dark
			else "À l'est, sur les falaises, des ombres immenses tournent sous la lune sans battre des ailes : des Ptéranodons."}, soar),
		CS.cue({"text": "Parmi eux, un tout petit ptérosaure en poursuit un grand, qui a un poisson dans le bec. Le petit crie beaucoup plus fort que le grand."}, chase),
		{"who": CHLOE, "text": "(Moustique ! Maïa est déjà là.)"},
	]
	lines.append(CS.cue({"text": "Le poisson tombe. Aucun des deux ne l'attrape. Il fait « ploc » dans le lagon."},
		func() -> void:
			for k in flock:
				var n = flock[k]
				if is_instance_valid(n):
					Stage.fade_out(n, 1.2, true)
			CS.splash(S.at(P.LAGON.x, P.LAGON.y), 10)))
	return lines


## How the lead dino takes the sea, acted out at Chloé's side.
static func _meets_the_sea(lead: Dino) -> Dictionary:
	var dino := CS.lead()
	var chloe := Stage.chloe()
	# The water's edge below the dune: the lead dino runs down to it (the wet sand just before it).
	var sea: Vector2 = CS.Act.water_near(chloe.global_position, SEA_REACH)
	if sea == chloe.global_position:
		sea = chloe.global_position + Vector2(0.0, -140.0)
	var shore := sea.move_toward(chloe.global_position, 40.0)
	match lead.species().family:
		&"raptor":
			return CS.cue({"text": "%s renifle l'écume, éternue… et recule d'un bond quand la vague lui lèche les pattes. Mouillé ? Non merci." % lead.nickname},
				func() -> void:
					Stage.look_at(shore, 1.0)
					await CS.lead_walk(shore, 120.0)
					CS.splash(sea, 8, 0.2)
					Stage.cry(dino, &"neutre")
					await Stage.hop(dino, 1, 10.0)
					Stage.recoil(dino, sea, 20.0))
		&"armored":
			return CS.cue({"text": "%s avance sur le sable mouillé, s'y enfonce jusqu'aux chevilles… et décide de ne plus bouger. Jamais. Il est très bien là." % lead.nickname},
				func() -> void:
					Stage.look_at(shore, 1.0)
					await CS.lead_walk(shore, 90.0)
					CS.D._fresh(dino)
					CS.crouch(dino, 0.12, 1.4))
		&"hadrosaur":
			return CS.cue({"text": "%s lance un appel vers les falaises… et les falaises le lui renvoient. Un écho ! Un vrai ! Il recommence. Trois fois." % lead.nickname},
				func() -> void:
					Stage.look_back()
					for i in 3:
						Stage.cry(dino, &"neutre")
						await S.wait(0.7)
						CS.far_cry("hadrosaure", "neutre", -16.0, 1.0)
						Stage.emote(dino, "♪")
						await S.wait(0.9))
	return CS.cue({"text": "%s regarde la mer, la tête penchée, comme on regarde quelqu'un qu'on ne connaît pas encore." % lead.nickname},
		func() -> void:
			Stage.look_back()
			Stage.turn_to(dino, sea)
			Stage.emote(dino, "?"))


# ------------------------------------------------------------------ Gustave and Firmin

## Gustave and Firmin by their beached boat (Npcs « Gustave » and « Firmin », event
## « pecheurs_cote »): the meeting (they are fishermen now; Joss at the lagoon; the boat without
## a lantern; Roc's lantern one night; the harbour master's advice); then a line and questions.
static func pecheurs(_who: Node) -> void:
	var gustave = S.actor("Gustave")
	var firmin = S.actor("Firmin")
	if not Game.flag(&"pecheurs_vus"):
		S.lock(true)
		await S.say(_pecheurs_hello(gustave, firmin))
		await S.say(_pecheurs_night(gustave, firmin))
		Game.award_team_xp(XP_PECHEURS)
		Save.save_game()
		S.lock(false)
		return
	var k := int(Game.flag(&"pecheurs_n"))
	var line: Array = PECHEURS_AGAIN[k % PECHEURS_AGAIN.size()]
	if Game.flag(&"coeur_3") and not Game.flag(&"pecheurs_apres_coeur"):
		Game.set_flag(&"pecheurs_apres_coeur")
		line = [GUSTAVE, "Tu as vu ? Ce matin, tous les poissons du lagon sont remontés d'un coup, comme si quelque chose les avait réveillés, tout au fond."]
	elif Game.flag(&"caisses_fouillees") and not Game.flag(&"pecheurs_apres_cache"):
		Game.set_flag(&"pecheurs_apres_cache")
		line = [GUSTAVE, "La barque sans lanterne ? Elle n'est pas passée, cette nuit. Ni la nuit d'avant. Tu y es pour quelque chose, hein ?"]
	else:
		Game.set_flag(&"pecheurs_n", k + 1)
	await A.menu(&"gustave", line[0], line[1], A.pecheurs_topics())


static func _pecheurs_hello(gustave, firmin) -> Array:
	var chloe := Stage.chloe()
	var mending := func() -> void:
		Stage.look_at((gustave as Node2D).global_position if gustave else chloe.global_position, 0.8)
		if gustave:
			CS.step_aside(gustave, 66.0)   # beside him, not in front of him
		for man in [gustave, firmin]:   # sitting on the sand
			if man:
				CS.sit(man, SITTING, 0.5)
		if firmin:
			CS.D._puff((firmin as Node2D).global_position + Vector2(10.0, 6.0), 14, 0.2)
			Stage.bow(firmin, 0.9)
		for i in 3:
			await CS.reach(gustave, (gustave as Node2D).global_position + Vector2(0.0, 30.0) if gustave else Vector2.ZERO, 5.0, 0.6)
	var sees_her := func() -> void:
		Stage.turn_to(firmin, chloe.global_position)
		Stage.emote(firmin, "!")
		await CS.get_up(firmin, 0.3)
		Stage.hop(firmin, 1, 10.0)
	var lines: Array = [
		CS.cue({"text": "Près d'une barque échouée, deux hommes sont assis sur le sable. L'un ravaude un filet, l'aiguille entre les dents. L'autre vide sa botte : il en coule du sable. Beaucoup de sable."}, mending),
		{"who": FIRMIN, "text": "Mais d'où il sort, tout ce sable ?! On est au bord de la MER !"},
		CS.cue({"who": FIRMIN, "text": "… TOI ?!"}, sees_her),
		CS.cue({"who": GUSTAVE, "text": "La petite de la grotte ! Celle qui m'a fait démissionner !"}, func() -> void:
			Stage.turn_to(gustave, chloe.global_position)
			CS.get_up(gustave, 0.4)
			Stage.recoil(chloe, (gustave as Node2D).global_position if gustave else chloe.global_position, 10.0)),
		{"who": GUSTAVE, "text": "Merci, hein. Sincèrement. Les poissons, au moins, ils ne crient pas quand on rate."},
	]
	if Game.flag(&"poursuite_3_ok") and Game.flag(&"sbire_camp_1_vu"):
		lines.append_array([
			{"who": CHLOE, "text": "Firmin ! Vous avez trouvé la mer, finalement !"},
			{"who": FIRMIN, "text": "Tu m'avais dit : tout droit vers le sud-est, puis le Marais. Je l'ai fait. Il y a des trucs qui nagent, dans le Marais. Des GROS trucs."},
		])
	else:
		lines.append({"who": GUSTAVE, "text": "Lui, c'est mon cousin Firmin. Sbire aussi, avant. Dans le Désert. Il a encore du sable dans des endroits qu'on ne dit pas."})
	lines.append_array([
		CS.cue({"who": GUSTAVE, "text": "On est pêcheurs, maintenant. Enfin, on essaie. Voici « La Sardine ». Elle prend un peu l'eau, mais elle a bon cœur."},
			func() -> void: CS.reach(gustave, _boat_near(gustave), 12.0, 1.0)),
		{"who": GUSTAVE, "text": "On a amené le petit sellier du Havre, Joss. Malade du départ à l'arrivée. Et il a parlé tout le long quand même."},
		{"who": FIRMIN, "text": "De coutures. Il a parlé de COUTURES. Pendant deux jours."},
		CS.cue({"who": GUSTAVE, "text": "Il est au lagon, la tête dans un bocal. Il dit que c'est un masque. On ne pose plus de questions."},
			func() -> void: Stage.turn_to(gustave, S.at(P.RIVE_LAGON.x, P.RIVE_LAGON.y))),
	])
	return lines


## What they saw at night (the boat without a lantern), Roc's lantern, the harbour master.
static func _pecheurs_night(gustave, firmin) -> Array:
	var chloe := Stage.chloe()
	var looks_round := func() -> void:
		if gustave:
			var at: Vector2 = (gustave as Node2D).global_position
			for dx: float in [-100.0, 100.0]:
				Stage.turn_to(gustave, at + Vector2(dx, 0.0))
				await S.wait(0.5)
			Stage.turn_to(gustave, chloe.global_position)
	var lines: Array = [
		{"who": CHLOE, "text": "Vous pêchez la nuit, aussi ?"},
		CS.cue({"who": GUSTAVE, "text": "Plus maintenant. La nuit, il passe une barque. Sans lanterne. Elle traverse le récif, là où personne ne passe, et elle file sous les falaises."}, looks_round),
		CS.cue({"who": FIRMIN, "text": "La troisième fois, on a ramé dans l'autre sens. Très vite. Moi, j'avais pas peur. J'avais juste très envie de rentrer."},
			func() -> void: Stage.tremble(firmin, 1.0, 1.5)),
	]
	if Game.flag(&"sbire_camp_2_battu"):
		lines.append({"who": CHLOE, "text": "(« Il arrive la nuit, par la mer, sans lanterne »… C'est lui.)"})
	elif Game.flag(&"cote_annonce"):
		lines.append({"who": CHLOE, "text": "(La barque que j'ai vue depuis la dune du Désert…)"})
	lines.append_array([
		{"who": GUSTAVE, "text": "Et y a pas que la barque. Une nuit, le vieux du Cabinet est venu avec sa lanterne. Il voulait savoir si « le gros du récif » dormait bien. On sait pas qui c'est, le gros. On veut pas savoir."},
		CS.cue({"who": CHLOE, "text": "(Roc ? Ici, en pleine nuit ?)"}, func() -> void: Stage.emote(chloe, "?")),
		{"who": FIRMIN, "text": "Et la capitaine Kerval nous a dit d'aller pêcher ailleurs. Très gentiment."},
		CS.cue({"who": GUSTAVE, "text": "Trop gentiment."}, func() -> void: Stage.bow(gustave, 0.8)),
		{"flag": &"pecheurs_vus"},
	])
	return lines


## The boat nearest to `who` (their « Sardine »), else a little in front of them.
static func _boat_near(who) -> Vector2:
	var w = S.world()
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else Vector2.ZERO
	var best := at + Vector2(0.0, 60.0)
	if w == null or w.get("region") == null:
		return best
	var best_d := 6.0 * S.CELL
	for n in w.region.entities.get_children():
		if n is Prop and n.get("kind") == "barque" and (n as Node2D).global_position.distance_to(at) < best_d:
			best_d = (n as Node2D).global_position.distance_to(at)
			best = (n as Node2D).global_position
	return best


# ------------------------------------------------------------------ Maïa on the cliffs

## Maïa at the Pteranodons' colony (Npc « MaiaFalaises », with « CaillouFalaises »): Moustique
## tries to impress a Pteranodon; she came as soon as the wind turned; from here one sees
## everything; Hélène's lookout and its tin box; challenge n° 5 once the third Cœur is found;
## tonight she watches for her mother's boat. Afterwards, a line and the questions.
static func maia_falaises(who: Node) -> void:
	if Game.flag(&"maia_falaises_vue"):
		var pool := ["Défi numéro cinq : quand tu auras ton troisième Cœur. Au belvédère, avec la mer derrière moi !",
			"Moustique a retenté sa chance avec les Ptéranodons. Il est dans ma capuche. Il boude.",
			"Ce soir, je guette. Si la barque de maman passe, je saurai enfin où elle va."]
		var k := int(Game.flag(&"maia_falaises_n"))
		Game.set_flag(&"maia_falaises_n", k + 1)
		await A.menu(&"maia", MAIA, pool[k % pool.size()], Ask.story_topics())
		return
	S.lock(true)
	await S.say(_colony(who))
	await S.say(_lookout(who))
	_colony_gone()
	Game.award_team_xp(XP_MAIA)
	Save.save_game()
	S.lock(false)


## A flyer wheels over the cliffs `turns` times (not awaited by the scene).
static func _wheel(p: DinoNpc, turns: int, radius: float) -> void:
	var centre := p.global_position + Vector2(50.0, 0.0)
	for turn in turns:
		await CS.circle(p, centre, radius, 3.4, CS.FLY_HEIGHT + 60.0)


## The scene's colony (nests, the perched one, the wheeling ones) leaves with it: the zone keeps
## its own nests.
static func _colony_gone() -> void:
	var w = S.world()
	if w == null or w.get("region") == null:
		return
	for n in w.region.entities.get_children():
		var id := String(n.name)
		if id.begins_with("NidColonie") or id.begins_with("PteranodonNid") or id.begins_with("PteranodonPlane"):
			Stage.fade_out(n, 1.2, true)


## The colony: Moustique puffs himself up in front of a Pteranodon, who yawns.
static func _colony(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var cast := {}
	var shows := func() -> void:
		CS.step_aside(who, 70.0)
		# The perched one north-west of Maïa, where Caillou (on her right) does not hide it; nests
		# around; two more wheeling overhead.
		var nest := S.ground_near(at + Vector2(-50.0, -110.0), 3)
		var kind: String = NEST if Prop.KINDS.has(NEST) else NEST_STAND_IN
		CS.prop(kind, nest + Vector2(0.0, 6.0), "NidColonie")
		for i in NEST_SPOTS.size():
			CS.prop(kind, S.ground_near(at + NEST_SPOTS[i], 3), "NidColonie%d" % i)
		var big := CS.stand_in(&"pteranodon", nest, "PteranodonNid")
		cast["big"] = big
		Stage.look_at(at.lerp(nest, 0.5), 1.0)
		if big:
			Stage.fade_in(big, 0.6)
			Stage.turn_to(big, at)
		for i in 2:
			var p := CS.stand_in(&"pteranodon", at + Vector2(-120.0 + 280.0 * i, -150.0), "PteranodonPlane%d" % i)
			if p:
				Stage.fade_in(p, 0.8)
				_wheel(p, 3, 80.0 + 30.0 * i)
	var struts := func() -> void:
		var big: DinoNpc = cast.get("big")
		var small := CS.stand_in(&"dimorphodon", at + Vector2(-20.0, -10.0), "Moustique")
		cast["small"] = small
		if small == null:
			return
		Stage.fade_in(small, 0.3)
		var before: Vector2 = big.global_position.lerp(at, 0.4) if big else at + Vector2(70.0, -30.0)
		await CS.fly(small, before, 1.0, 20.0)
		if big:
			Stage.turn_to(small, big.global_position)
		small.cry(&"attaque")
		Stage.rear(small, 0.9)
	var yawns := func() -> void:
		var big: DinoNpc = cast.get("big")
		if big:
			big.cry(&"neutre")
			Stage.rear(big, 1.8)
	var hides := func() -> void:
		var small: DinoNpc = cast.get("small")
		if small:
			await CS.fly(small, at + Vector2(0.0, -6.0), 0.6, 30.0)
			Stage.fade_out(small, 0.3, true)
		Stage.hop(who, 1, 6.0)
	return [
		CS.cue({"text": "Au sommet des falaises, le vent sent le sel et le poisson. Partout, des nids de brindilles et d'algues. Au-dessus, des Ptéranodons planent, les ailes grandes ouvertes : sept mètres, d'une pointe à l'autre."}, shows),
		CS.cue({"who": MAIA, "text": "CHLOÉ ! Tu as vu ? TU AS VU ?! Ils sont grands comme des barques ! Des barques qui VOLENT !"},
			func() -> void:
				Stage.turn_to(who, chloe.global_position)
				Stage.hop(who, 3, 9.0)),
		CS.cue({"text": "Moustique, le Dimorphodon de Maïa, se pose devant un Ptéranodon perché sur son nid. Il gonfle le jabot, déploie ses petites ailes et pousse son cri le plus terrible."}, struts),
		CS.cue({"text": "Le Ptéranodon bâille. Son bec est plus long que Moustique tout entier."}, yawns),
		CS.cue({"text": "Moustique file se cacher dans la capuche de Maïa."}, hides),
		{"who": MAIA, "text": "Il dit qu'il les a laissés gagner. Par politesse."},
		{"who": CHLOE, "text": "Tu es arrivée quand ?"},
		CS.cue({"who": MAIA, "text": "Dès que le vent a tourné ! J'ai couru toute la nuit. Enfin, Caillou a couru. Moi, j'étais dessus."},
			func() -> void:
				var caillou = S.actor("CaillouFalaises")
				if caillou:
					CS.D._snort(caillou)),
	]


## What one sees from up here; the lookout below, its tin box; challenge n° 5; her mother.
static func _lookout(who: Node) -> Array:
	var chloe := Stage.chloe()
	var tour := func() -> void:
		Stage.turn_to(who, S.at(P.PASSE.x, P.PASSE.y))
		CS.Act.tour([S.at(P.PLAGE_TORTUES.x, P.PLAGE_TORTUES.y), S.at(P.LAGON.x, P.LAGON.y), S.at(P.PASSE.x, P.PASSE.y + 2.0),
			S.at(P.ANSE_GROTTES.x, P.ANSE_GROTTES.y + 1.0)], 1.3, 0.5)
	var box := func() -> void:
		Stage.look_at(S.at(P.BELVEDERE.x, P.BELVEDERE.y), 1.2)
		Stage.turn_to(who, S.at(P.BELVEDERE.x, P.BELVEDERE.y))
	return [
		CS.cue({"who": MAIA, "text": "Et d'ici, on voit TOUT. Regarde : la plage, le lagon, la passe du récif… et la crique, sous la falaise, là où la mer rentre dans la roche."}, tour),
		CS.cue({"who": MAIA, "text": "Et là, juste en dessous, au belvédère : le vieux poste de guet d'Hélène. Une niche dans la roche, et dedans, une boîte en fer toute rouillée. Soudée par le sel : impossible de l'ouvrir."}, box),
		CS.cue({"who": MAIA, "text": "On l'ouvrira ensemble. Après notre défi. C'est la tradition."},
			func() -> void:
				Stage.look_back()
				Stage.turn_to(who, chloe.global_position)),
		{"who": CHLOE, "text": "Quelle tradition ?"},
		CS.cue({"who": MAIA, "text": "Celle que je viens d'inventer."}, func() -> void: Stage.hop(who, 1, 7.0)),
		{"who": MAIA, "text": "Défi numéro cinq : quand tu auras ton troisième Cœur. Au belvédère, avec la mer derrière moi. Ça fera une belle histoire."},
		CS.cue({"who": MAIA, "text": "Maman ne veut pas que je vienne ici. Elle dit que les grottes sont traîtresses."},
			func() -> void: Stage.turn_to(who, (who as Node2D).global_position + Vector2(0.0, -200.0))),
		{"who": MAIA, "text": "Mais la nuit, c'est ELLE qui vient. En barque. Ce soir, je reste là-haut. Je veux voir où elle va."},
		CS.cue({"text": "Chloé ouvre la bouche. Puis elle la referme. Maïa a l'air si contente."},
			func() -> void: CS.later(0.8, func() -> void: Stage.emote(chloe, "…"))),
		{"flag": &"maia_falaises_vue"},
	]


# ------------------------------------------------------------------ the first night

## The time of day changed in zone `zone` (Story.on_phase_changed): the night's boat, when it is
## still to play and Chloé is free.
static func on_phase(zone: StringName) -> void:
	if zone != &"cote" or Game.phase() != &"night":
		return
	await night()


## The first night on the Côte (before the cache is found): a boat without a lantern slips
## through the reef, crosses the lagoon and vanishes into the cliff; a figure in a cape stands in
## it. Up on the lookout, a little light goes out (Maïa, hiding her lantern).
static func night() -> void:
	if not Game.flag(&"cote_arrivee") or Game.flag(&"barque_nuit_vue") or Game.flag(&"cache_vue"):
		return
	var w = S.world()
	if w == null or w.get("region") == null or w.region.region_id != &"cote":
		return
	if w.player.busy or Dialogue.active or w.player.is_swimming():
		return
	S.lock(true)
	var gap := S.at(P.PASSE.x, P.PASSE.y)
	var cove := S.at(P.ANSE_GROTTES.x, P.ANSE_GROTTES.y)
	var cave := S.at(P.ENTREE_GROTTES.x, P.ENTREE_GROTTES.y)
	var start := gap + Vector2(-5.0, -8.0) * S.CELL
	var boat := CS.prop("barque", start, "BarqueNuit")
	var figure := S.stranger("MasqueBarque", "masque", start + Vector2(0.0, -6.0), "up", "")
	CS.in_boat(figure)   # standing in the boat, not down on the bottom
	var cast: Array = [boat, figure]
	for n in cast:
		if n:
			n.modulate = Color(0.35, 0.35, 0.45, 0.0)
	var lamp := Stage.light_at(S.at(P.BELVEDERE.x, P.BELVEDERE.y), LANTERN, 2.5)
	if lamp:
		lamp.light_energy = 1.4
	var sails := func(points: Array, speed: float) -> void:
		for n in cast:
			if n:
				var offset: Vector2 = Vector2(0.0, -6.0) if n == figure else Vector2.ZERO
				CS.glide(n, points.map(func(p: Vector2) -> Vector2: return p + offset), speed)
	var appears := func() -> void:
		for n in cast:
			if n:
				n.create_tween().tween_property(n, "modulate:a", 1.0, 1.2)
		sails.call([gap + Vector2(0.0, -2.0 * S.CELL)], 90.0)
	var lines: Array = [
		CS.cue({"text": "La nuit est tombée sur la Côte. Pas de lune, derrière les nuages ; seulement le bruit des vagues qui se brisent sur le récif."},
			func() -> void: Stage.look_at(gap + Vector2(0.0, -3.0 * S.CELL), 1.2)),
		CS.cue({"text": "Et puis, sur la mer noire, une ombre. Une barque. Pas de lanterne, pas de rames, pas un bruit."}, appears),
		CS.cue({"text": "Elle se glisse par une brèche du récif, là où personne ne passe, comme si elle connaissait chaque rocher par cœur."},
			func() -> void:
				sails.call([gap + Vector2(0.0, 1.0 * S.CELL)], 80.0)
				CS.pan(gap, 2.0)),
		CS.cue({"text": "Debout dans la barque, une silhouette en cape. Elle ne rame pas. Elle ne regarde même pas l'eau."},
			func() -> void: Stage.look_at(gap + Vector2(0.0, 1.0 * S.CELL), 0.8)),
		CS.cue({"text": "La barque traverse le lagon, longe les falaises… et disparaît sous la roche de la crique, comme avalée."},
			func() -> void:
				sails.call([gap.lerp(cove, 0.5), cove, cave], 90.0)
				await CS.pan(cove, 2.4)
				for n in cast:
					if n:
						Stage.fade_out(n, 1.0, true)),
		{"who": CHLOE, "text": "(Les grottes, sous les falaises. C'est là qu'elle va.)"},
	]
	var goes_out := func() -> void:
		Stage.look_at(S.at(P.BELVEDERE.x, P.BELVEDERE.y), 1.0)
		await S.wait(0.8)
		if lamp:
			lamp.light_energy = 0.0
			lamp.queue_free()
	if Game.flag(&"maia_falaises_vue"):
		lines.append_array([
			CS.cue({"text": "Tout en haut de la falaise, au belvédère, une petite lumière s'éteint d'un coup."}, goes_out),
			{"who": CHLOE, "text": "(Maïa… Tu l'as vue, toi aussi ?)"},
		])
	else:
		lines.append_array([
			CS.cue({"text": "Tout en haut de la falaise, une petite lumière s'éteint d'un coup. Quelqu'un d'autre regardait."}, goes_out),
			{"who": CHLOE, "text": "(Qui ?)"},
		])
	lines.append({"flag": &"barque_nuit_vue"})
	await S.say(lines)
	for n in cast:
		if n and is_instance_valid(n):
			n.queue_free()
	if lamp and is_instance_valid(lamp):
		lamp.queue_free()
	Stage.look_back()
	Game.award_team_xp(XP_NUIT)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ Roc, at the Cabinet

## Talking to Roc during the chapter (Story.run « roc »): the Sceau de la Côte (« Minuit »,
## Anselme sick over the side), his copy of the map (untouched: the Masque did not need it), and
## after page 23, the name he never said. True if he said something.
static func roc() -> bool:
	var said := false
	var to_say: bool = (Game.flag(&"sceau_cote") and not Game.flag(&"roc_sceau_cote")) \
		or (Game.flag(&"found_journal_21") and not Game.flag(&"roc_carte_intacte")) \
		or (Game.flag(&"maia_enfuie") and not Game.flag(&"roc_isaure"))
	var prof = S.actor("Roc")
	if to_say and prof is Node2D:   # beside him, not in front of him (the camera would see only her back)
		await CS.step_aside(prof, 66.0)
		Stage.turn_to(prof, Stage.chloe().global_position)
	if Game.flag(&"sceau_cote") and not Game.flag(&"roc_sceau_cote"):
		await S.say(_roc_sceau())
		said = true
	if Game.flag(&"found_journal_21") and not Game.flag(&"roc_carte_intacte"):
		await S.say(_roc_map())
		said = true
	if Game.flag(&"maia_enfuie") and not Game.flag(&"roc_isaure"):
		await S.say(_roc_isaure())
		said = true
	return said


static func _roc_sceau() -> Array:
	var lines: Array = [
		{"who": ROC, "text": "Le Sceau de la Côte… Minuit t'a laissée approcher ?"},
		{"who": CHLOE, "text": "Minuit ?"},
		{"who": ROC, "text": "Le Mosasaure. Hélène l'appelait « Minuit ». La première fois, j'étais dans la barque. J'ai été malade par-dessus bord. Deux fois."},
		{"who": ROC, "text": "Minuit a trouvé ça passionnant. Il nous a suivis jusqu'au récif, la tête hors de l'eau, pour voir si j'allais recommencer."},
	]
	if Game.flag(&"coeur_3"):
		lines.append({"who": ROC, "text": "Trois Cœurs… Le volcan a grondé jusqu'ici, cette nuit. Les flacons ont tinté sur les étagères. Fais attention, Chloé."})
	lines.append({"flag": &"roc_sceau_cote"})
	return lines


## His copy of Hélène's map: he goes to check behind the jars, and comes back relieved.
static func _roc_map() -> Array:
	var prof = S.actor("Roc")
	var at: Vector2 = (prof as Node2D).global_position if prof is Node2D else Vector2.ZERO
	var chloe := Stage.chloe()
	var shelf := S.at(3.3, 2.95)   # in front of the great shelf (Prop « etagere_bocaux », tools/zones/cabinet.gd)
	var rummages := func() -> void:
		if prof == null:
			return
		await prof.walk_to(shelf, "up", 80.0)
		for i in 3:
			await Stage.bow(prof, 0.6)
	var back := func() -> void:
		if prof == null:
			return
		await prof.walk_to(at, "", 80.0)
		prof.face(chloe.global_position)
		Stage.hop(prof, 1, 4.0)
	return [
		{"who": CHLOE, "text": "Professeur… La passe du récif. Hélène l'a écrite dans une page : seule « I. » la connaissait. Et le Masque la prend chaque nuit."},
		CS.cue({"who": ROC, "text": "La passe ? Mais elle n'est pas sur… Attends."}, func() -> void: Stage.emote(prof, "!")),
		CS.cue({"text": "Roc file jusqu'à la grande étagère, déplace trois bocaux, un crâne de Compsognathus et une théière, et fouille derrière."}, rummages),
		CS.cue({"text": "Il revient. Pour la première fois depuis longtemps, il a l'air soulagé."}, back),
		{"who": ROC, "text": "Elle est là. Ma copie de la carte. Personne n'y a touché."},
		{"who": CHLOE, "text": "(Alors le Masque n'avait pas besoin de carte. Il connaissait le chemin. Comme « I. ».)"},
		CS.cue({"text": "Roc remet ses lunettes, puis ne dit plus rien. On dirait qu'il vient de comprendre la même chose qu'elle."},
			func() -> void: Stage.emote(prof, "…")),
		{"flag": &"roc_carte_intacte"},
	]


## The Cabinet's armchair (a « fauteuil » prop within a few tiles of `prof`), or INF.
static func _armchair_near(prof: Node) -> Vector2:
	var w = S.world()
	if w == null or w.get("region") == null or not prof is Node2D:
		return Vector2.INF
	for n in w.region.entities.get_children():
		if n is Prop and n.get("kind") == "fauteuil" and (n as Node2D).global_position.distance_to((prof as Node2D).global_position) < 6.0 * S.CELL:
			return (n as Node2D).global_position
	return Vector2.INF


## After page 23: Chloé says « Isaure ». He finishes the sentence he left unsaid at the drawer.
static func _roc_isaure() -> Array:
	var prof = S.actor("Roc")
	var sits := func() -> void:
		if prof:
			var chair := _armchair_near(prof)
			if chair != Vector2.INF and prof is Npc:   # to his armchair, and down into it
				await (prof as Npc).walk_to(chair + Vector2(0.0, 10.0), "down", 90.0)
			CS.sit(prof, SITTING, 0.8)
			Stage.turn_to(Stage.chloe(), (prof as Node2D).global_position)
	var lines: Array = [
		CS.cue({"who": CHLOE, "text": "Professeur… Hélène était la marraine de Maïa. C'est écrit dans une page. Et « I. »… c'est Isaure."},
			func() -> void: CS.reach(Stage.chloe(), (prof as Node2D).global_position if prof is Node2D else Vector2.ZERO, 10.0, 1.0)),
		CS.cue({"text": "Roc s'assoit lourdement. Le fauteuil grince. Il enlève ses lunettes, et ne les essuie pas."}, sits),
		{"who": ROC, "text": "… Surtout pas à Isaure."},
	]
	if Game.flag(&"ambre_noir_tiroir"):
		lines.append({"who": ROC, "text": "C'est ce que j'allais dire, ce jour-là, devant le tiroir. « N'en parle à personne. Surtout pas à Isaure. » Je n'avais pas de preuve. Je n'en voulais pas."})
	else:
		lines.append({"who": ROC, "text": "Je le pense depuis des années. Je n'avais pas de preuve. Je n'en voulais pas."})
	if Game.flag(&"barque_isaure_vue"):
		lines.append_array([
			{"who": CHLOE, "text": "Dans la grotte, au milieu des caisses d'ambre noir, il y avait sa barque. Avec le nom de Maïa sur la proue."},
			{"who": ROC, "text": "Elle l'a repeinte le jour de la naissance de la petite. J'étais là. Au baptême aussi : je tenais le cierge. Je l'ai fait tomber."},
		])
	else:
		lines.append({"who": ROC, "text": "J'étais au baptême de la petite. Je tenais le cierge. Je l'ai fait tomber."})
	lines.append_array([
		CS.cue({"who": ROC, "text": "Maïa a hurlé pendant toute la cérémonie. Et Hélène riait, riait…"}, func() -> void: Stage.bow(prof, 1.4)),
		{"who": CHLOE, "text": "Maïa s'est enfuie. Elle ne veut plus me voir."},
		{"who": ROC, "text": "Laisse-lui du temps. Les Kerval reviennent toujours au port."},
		{"who": ROC, "text": "Et ce que tu sais, Chloé, garde-le. Pas pour Isaure : pour Maïa. C'est à elle de choisir ce qu'elle en fait."},
	])
	if Game.flag(&"masque_carton"):
		lines.append_array([
			CS.cue({"text": "Chloé sort de sa sacoche le masque en carton de Maïa, l'élastique cassé. Roc le regarde longtemps."},
				func() -> void: CS.reach(Stage.chloe(), (prof as Node2D).global_position if prof is Node2D else Vector2.ZERO, 8.0, 1.2)),
			{"who": ROC, "text": "Garde-le. Tu le lui rendras. Quand elle sera prête."},
		])
	lines.append({"flag": &"roc_isaure"})
	var gets_up := func() -> void:
		if prof:
			CS.get_up(prof, 0.8)
	lines.append(CS.cue({"text": "Roc se relève, remet ses lunettes, et va mettre de l'eau à chauffer. Il ne sait pas quoi faire d'autre."}, gets_up))
	return lines
