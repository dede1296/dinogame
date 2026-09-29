class_name MontsGrottes
## Chapter 6, the Monts Gelés, the ice caves (zone grottes_glace; docs/histoire.md, ch. 6,
## points 1 and 2): everything blue, stalactites dripping; in the walls, little dinos asleep
## standing in blocks of ice, and eggs: Hélène's secret reserve. Dame Suie is at work among them
## (pipette, thermometer, her sled of vials, Mandragore harnessed): she means to wake them « with
## a drop » for the Masque's army. A battle (Mandragore, Ciguë, then Aconit, a corrupted
## Nanuqsaurus who no longer sleeps: calmed, he falls asleep at once). Dame Suie doubts — she
## takes off her glasses: « Ils sont… parfaits. Sans une goutte. » — lets Chloé go, and gives
## her the clue: « Le Masque veut tous les Cœurs d'un coup. Les Cieux. » Then Chloé wakes three
## of the little ones with the Cœurs' warmth (they go to wait at the Cabinet: Roc exchanges
## them); the fourth, and the eggs, sleep on: they are not ready.
## Flags: grottes_glace_arrivee, suie_monts_vue, suie_monts_battue, suie_monts_partie,
## suie_indice, aconit_garde, dormeurs_reveilles; dormeur_n, oeufs_n (lines).

const S := preload("res://story/story.gd")
const P := preload("res://story/monts_places.gd")
const MS := preload("res://story/monts_stage.gd")
const CS := preload("res://story/cote_stage.gd")
const CHLOE := "Chloé"
const SUIE := "Dame Suie"
## Dame Suie's team (poison plants, as in the Marais), to check by simulation with the chapter's
## levels (scratchpad ch6/sim_monts.gd, docs/histoire.md § 6); Aconit is corrupted (calmed).
const SUIE_TEAM := [[&"therizinosaurus", 34, "Mandragore"], [&"koolasuchus", 34, "Ciguë"]]
const ACONIT := [&"nanuqsaurus", 35, "Aconit"]
## The name Chloé gives the calmed Nanuqsaurus (« Aconit » is a poison).
const ACONIT_NAME := "Flocon"
const ACONIT_NODE := "AconitScene"
## The three little ones who wake up (the first three sleepers: their species, their level as
## they join the Cabinet's reserve), and the fourth, who sleeps on.
const WAKERS := [[&"brachiosaurus", 12], [&"stegosaurus", 12], [&"psittacosaurus", 12]]
## The four asleep in the ice (placed at each entry: _place_sleepers): their species (the first
## three wake up), how young (DinoSize.GROWN_LEVEL is grown), where behind their block (px: a
## little north, so the block's clear ice shows them), their pale ice-blue.
const SLEEPERS := [&"brachiosaurus", &"stegosaurus", &"psittacosaurus", &"ankylosaurus"]
const SLEEPER_LEVEL := 6
const BEHIND_BLOCK := Vector2(0.0, -8.0)
const ASLEEP_TINT := Color(0.78, 0.9, 1.1)
const XP_ARRIVEE := 20
const XP_SUIE := 90
const XP_DORMEURS := 60
const SLEEPER_AGAIN := [
	"Le petit Ankylosaure dort toujours dans la glace, un demi-sourire au coin de la gueule. Chloé le laisse dormir.",
	"Dans le dernier bloc, une bulle d'air bouge un tout petit peu à chaque respiration. Il dort bien.",
]
const EGGS_AGAIN := [
	"Trois œufs, blancs et tachetés, pris dans la glace. Chloé n'y touche pas. (Pas encore. Hélène saura quand.)",
	"Les œufs dorment. La glace autour est lisse comme un miroir : personne n'y a touché. Tant mieux.",
]


# ------------------------------------------------------------------ arriving

## Each time in the ice caves: the little ones asleep in the ice (placed here, behind their
## blocks). The first time: the first hall, all blue, dripping; far in, a violet glint. The
## reserve itself is shown when Chloé comes near it (StoryTrigger « DeclencheurReserve », event
## « grottes_glace_reserve »), or right away when the zone has no such trigger.
static func arrival() -> void:
	_place_sleepers()
	if Game.flag(&"grottes_glace_arrivee"):
		return
	S.lock(true)
	await S.wait(0.5)
	var chloe := Stage.chloe()
	var reserve := S.at(P.RESERVE.x, P.RESERVE.y)
	var blue := func() -> void:
		Stage.look_at(chloe.global_position + Vector2(0.0, -3.0 * S.CELL), 1.2)
		CS.pulse(chloe.global_position + Vector2(0.0, -2.0 * S.CELL), MS.ICE_BLUE, 2, 2.0, 1.6, 5.0)
		MS.drips(chloe.global_position + Vector2(50.0, -40.0), 4, 0.5, 2.2)
	var glint := func() -> void:
		await CS.pan(reserve, 2.0)
		CS.pulse(reserve, MS.VIOLET, 2, 1.2, 1.2, 3.0)
	await S.say([
		CS.cue({"text": "Dans les grottes, la lumière passe à travers la glace : tout est bleu. Des stalactites pendent du plafond, et de chacune tombe une goutte, très lentement."}, blue),
		CS.cue({"text": "Tout au fond, au bout d'un couloir de glace, une petite lueur violette clignote. Et on entend tinter des fioles."}, glint),
		{"who": CHLOE, "text": "(La dame en gris… Elle est là.)"},
		{"flag": &"grottes_glace_arrivee"},
	])
	Stage.look_back()
	Game.award_team_xp(XP_ARRIVEE)
	Save.save_game()
	S.lock(false)
	if S.actor("DeclencheurReserve") == null:
		await reserve_seen(null)


## Near the reserve (StoryTrigger « DeclencheurReserve », event « grottes_glace_reserve »): the
## sleepers in their blocks, the eggs; a violet glow and a polite voice: Dame Suie. Then her.
static func reserve_seen(_trigger: Node) -> void:
	var suie = S.actor("DameSuieMonts")
	if Game.flag(&"suie_monts_vue") or Game.flag(&"suie_monts_battue"):
		return
	S.lock(true)
	var sleepers := _sleepers_px()
	var middle: Vector2 = sleepers[1].lerp(sleepers[2], 0.5)
	var eggs := S.at(P.OEUFS.x, P.OEUFS.y)
	var shapes := func() -> void:
		await CS.pan(middle, 1.8)
		for p: Vector2 in sleepers:
			CS.pulse(p, MS.ICE_BLUE, 1, 1.4, 1.2, 2.2)
	var little_ones := func() -> void:
		for i in range(1, 5):
			var d = S.actor("DormeurDino%d" % i)
			if d:
				Stage.glow(d, Color(0.85, 1.1, 1.5), 1, 1.2)
	var lines: Array = [
		CS.cue({"text": "Dans l'épaisseur des murs, des formes sombres. Chloé s'approche."}, shapes),
		CS.cue({"text": "Des dinos. Des tout petits. Pris dans des blocs de glace transparents, les yeux fermés, debout, comme s'ils s'étaient endormis en marchant."}, little_ones),
		CS.cue({"text": "Et au milieu, dans une niche, des œufs. Trois, blancs et tachetés, pris dans la glace eux aussi."},
			func() -> void: Stage.look_at(eggs, 1.2)),
		{"who": CHLOE, "text": "(Ils ne sont pas morts… Ils dorment. Comme dans l'ambre.)"},
	]
	if suie is Node2D:
		lines.append_array([
			CS.cue({"text": "Alors, entre les blocs, une lueur violette. Et une voix, polie comme une vitre."},
				func() -> void:
					Stage.look_at_actor(suie, 1.0)
					CS.pulse((suie as Node2D).global_position + Vector2(-20.0, 0.0), MS.VIOLET, 2, 1.2, 1.8, 2.5)),
			{"who": SUIE, "text": "Ne touchez à rien, je vous prie, mademoiselle Varenne. Ils dorment. Pour l'instant."},
		])
	await S.say(lines)
	S.lock(false)
	if suie is Node2D:
		await dame_suie(suie)
	else:
		Game.set_flag(&"suie_monts_vue")


## The little ones asleep in the ice, just behind their blocks (not the three once awake): a
## DinoNpc each, young, pale blue, not to be talked to (the zone's plan puts the blocks).
static func _place_sleepers() -> void:
	var w = S.world()
	if w == null or w.get("region") == null:
		return
	var blocks := _sleepers_px()
	for i in SLEEPERS.size():
		var node_name := "DormeurDino%d" % (i + 1)
		if S.actor(node_name) != null or (i < WAKERS.size() and Game.flag(&"dormeurs_reveilles")):
			continue
		var id: StringName = SLEEPERS[i]
		if not SpeciesDB.PATHS.has(id):
			continue
		var d := DinoNpc.new()
		d.name = node_name
		d.species_id = id
		d.level = SLEEPER_LEVEL
		d.flip = i >= 2   # (facing the middle of the reserve)
		d.position = blocks[i] + BEHIND_BLOCK
		w.region.entities.add_child(d)
		d.collision_layer = 0
		d.modulate = ASLEEP_TINT


## Where the four sleepers are (their ice blocks in the zone, else MontsPlaces.DORMEURS), px.
static func _sleepers_px() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in 4:
		var block = S.actor("Dormeur%d" % (i + 1))
		var tile: Vector2 = P.DORMEURS[i] if i < P.DORMEURS.size() else P.DORMEURS[-1]
		out.append((block as Node2D).global_position if block is Node2D else S.at(tile.x, tile.y))
	return out


# ------------------------------------------------------------------ Dame Suie

## Dame Suie among the sleepers (Npc « DameSuieMonts », event « dame_suie_monts »): what she has
## come for (a drop of her « Givre » in each sleeper, for the Masque's army; a map drawn by
## someone who knew Hélène very well), the battle; calmed Aconit, her doubt, the clue, she goes.
static func dame_suie(who: Node) -> void:
	if Game.flag(&"suie_monts_battue") or who == null:
		return
	if not Game.flag(&"suie_monts_vue"):
		S.lock(true)
		await S.say(_suie_hello(who))
		S.lock(false)
	var pick := await Dialogue.choose(SUIE, "Mesurons-nous, mademoiselle Varenne. Pour la science.", ["Relever le défi", "Pas encore"])
	if pick != 0:
		await S.say([CS.cue({"who": SUIE, "text": "Prenez votre temps. Eux ont attendu quinze ans : ils attendront bien que vous vous réchauffiez les doigts."},
			func() -> void: Stage.bow(who, 0.8))])
		return
	var rules := {"lose_spawn": P.SPAWN_GROTTES_DEPUIS_MONTS}
	var theme: AudioStream = MS.music(MS.OMBRE_MUSIC)
	if theme:
		rules["music"] = theme
	if not await S.duel(SUIE, _team(who), rules):
		var aconit = S.actor(ACONIT_NODE)
		if aconit:
			aconit.queue_free()
		await S.say([{"who": SUIE, "text": "Soignez-vous, mademoiselle. Je ne bouge pas. Eux non plus : ils ne vont nulle part."}])
		return
	Game.set_flag(&"suie_monts_battue")
	Save.save_game()
	await _suie_beaten(who)


static func _suie_hello(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var sleepers := _sleepers_px()
	var nearest: Vector2 = sleepers[0]
	for p: Vector2 in sleepers:
		if p.distance_to(at) < nearest.distance_to(at):
			nearest = p
	var measures := func() -> void:
		CS.step_aside(who, 70.0)
		Stage.turn_to(who, nearest)
		for i in 2:
			await CS.reach(who, nearest, 10.0, 0.9)
			await S.wait(0.3)
		var mandragore = S.actor("Mandragore")
		if mandragore:
			MS.breath(mandragore, 8)
	var the_vial := func() -> void:
		Stage.turn_to(who, chloe.global_position)
		await CS.reach(who, chloe.global_position, 8.0, 1.0)
		CS.pulse(at + Vector2(0.0, -10.0), MS.VIOLET, 3, 1.0, 2.0, 2.5)
	var ungloves := func() -> void:
		await Stage.bow(who, 1.6)
		Stage.turn_to(who, chloe.global_position)
	var lines: Array = [
		CS.cue({"text": "Dame Suie se tient entre les blocs de glace, une pipette dans une main, un petit thermomètre dans l'autre. Derrière elle, un traîneau chargé de caisses, et un Therizinosaurus attelé qui souffle de la vapeur."}, measures),
		{"who": SUIE, "text": "Vous tombez à pic. Regardez-les : des œufs, des petits, endormis dans la glace depuis quinze ans. Votre grand-mère avait le sens du rangement."},
		{"who": CHLOE, "text": "Qu'est-ce que vous leur faites ?"},
		{"who": SUIE, "text": "Rien encore. Je prends leur température. Elle est parfaite, d'ailleurs. C'est agaçant."},
		CS.cue({"who": SUIE, "text": "Le Masque veut une armée. Moi, je veux des résultats. Une goutte de ma formule du Givre dans chaque bloc, et ils se réveillent. Obéissants. Frais. Prêts."}, the_vial),
	]
	if Game.flag(&"dame_suie_battue"):
		lines.append({"who": CHLOE, "text": "Ils se réveilleront terrifiés ! Comme Belladone, dans le Marais !"})
		lines.append({"who": SUIE, "text": "Belladone était un premier essai. Depuis, j'ai affiné le dosage. Beaucoup."})
	else:
		lines.append({"who": CHLOE, "text": "Ils se réveilleront terrifiés, avec des veines violettes partout !"})
		lines.append({"who": SUIE, "text": "Un problème de dosage, mademoiselle. Et j'ai affiné le mien. Beaucoup."})
	lines.append_array([
		{"who": CHLOE, "text": "Comment saviez-vous qu'ils étaient là ? Hélène ne l'a dit à personne !"},
		{"who": SUIE, "text": "Une carte. Dessinée à la main, avec des petites fougères partout. Par quelqu'un qui connaissait très, très bien votre grand-mère."},
	])
	if Game.flag(&"found_journal_23"):
		lines.append(CS.cue({"who": CHLOE, "text": "(Des fougères partout… Quelqu'un qui connaissait Hélène par cœur. Isaure.)"},
			func() -> void: Stage.emote(chloe, "…")))
	else:
		lines.append(CS.cue({"who": CHLOE, "text": "(Quelqu'un qui connaissait Hélène par cœur… « I. » ?)"},
			func() -> void: Stage.emote(chloe, "?")))
	lines.append_array([
		{"who": CHLOE, "text": "Je ne vous laisserai pas les toucher."},
		CS.cue({"who": SUIE, "text": "Je m'en doutais. Vous avez les yeux de votre grand-mère : ils disent non avant la bouche."}, ungloves),
		{"text": "Elle retire ses gants gris perle, un doigt après l'autre."},
		{"flag": &"suie_monts_vue"},
	])
	return lines


## Her gardener, her swimmer, then Aconit: a young Nanuqsaurus on black amber, who no longer
## sleeps; he comes out from behind the sled as she speaks of him, rigid, and stays while the
## battle lasts.
static func _team(who: Node) -> Array:
	var team: Array = []
	for member: Array in SUIE_TEAM:
		team.append(member.duplicate())
	var aconit: Array = [MS.species_or(ACONIT[0]), ACONIT[1], ACONIT[2], {
		"corrupted": true,
		"before": [
			CS.cue({"who": SUIE, "text": "Et voici Aconit. Quatre gouttes, pour résister au froid. Il ne tremble plus jamais."},
				func() -> void: _aconit_out(who)),
			CS.cue({"text": "De derrière le traîneau sort un Nanuqsaurus, un tyran des neiges au museau court, les veines violettes sous la peau. Il ne cligne pas des yeux. Pas une seule fois."},
				func() -> void:
					var d = S.actor(ACONIT_NODE)
					if d:
						Stage.glow(d, Color(1.3, 0.9, 1.6), 2, 0.9)),
			{"who": SUIE, "text": "Il ne dort plus, non plus. Trois semaines. Un effet secondaire. Je le note."},
			{"who": CHLOE, "text": "Il ne dort plus… Il a peur de fermer les yeux."},
		],
		"intro": "Dame Suie envoie Aconit, le Nanuqsaurus corrompu !",
		"lesson": [
			"Aconit est corrompu : il ne tombera pas. Choisis « Apaiser ».",
			"Plus il est fatigué, plus il t'écoute. Mais chaque coup l'affole un peu.",
		],
	}]
	team.append(aconit)
	return team


## Aconit steps out from behind the sled (between Dame Suie and Chloé) and stands rigid.
static func _aconit_out(who: Node) -> void:
	if S.actor(ACONIT_NODE) or not is_instance_valid(who):
		return
	var sled = S.actor("TraineauSuie")
	var from: Vector2 = (sled as Node2D).global_position if sled is Node2D else (who as Node2D).global_position + Vector2(60.0, -40.0)
	var to := S.ground_near((who as Node2D).global_position.lerp(Stage.chloe().global_position, 0.45), 2)
	var d := MS.stand_in(ACONIT[0], from, ACONIT_NODE)
	if d == null:
		return
	d.corrupted = true
	Stage.fade_in(d, 0.5)
	if CS.Act.clear_way(from, to):
		await d.walk_to(to, 70.0)
	if is_instance_valid(d):
		Stage.turn_to(d, Stage.chloe().global_position)


## Calmed, Aconit yawns and falls asleep on the spot. Dame Suie does not write any more; she
## takes off her smoked glasses and looks at the sleepers, long: « parfaits, sans une goutte ».
## The clue (the Cieux); Aconit is Chloé's to keep; she packs up and goes with her sled.
static func _suie_beaten(who: Node) -> void:
	S.lock(true)
	var chloe := Stage.chloe()
	var aconit = S.actor(ACONIT_NODE)
	var sleepers := _sleepers_px()
	var sleeps := func() -> void:
		if aconit == null or not is_instance_valid(aconit):
			return
		await aconit.cleanse()
		if not is_instance_valid(aconit):
			return
		await Stage.rear(aconit, 1.2)   # a huge yawn
		await S.wait(0.4)
		for i in 3:   # (asleep standing up: its head nodding down, snoring)
			if not is_instance_valid(aconit):
				return
			await Stage.bow(aconit, 1.4)
			Stage.emote(aconit, "z")
	var stops := func() -> void:
		Stage.turn_to(who, (aconit as Node2D).global_position if aconit is Node2D else chloe.global_position)
		Stage.emote(who, "!")
	var to_the_ice := func() -> void:
		var block: Vector2 = sleepers[1]
		if who is Npc:
			await (who as Npc).walk_to(block + Vector2(-40.0, 30.0), "", 60.0)
		Stage.turn_to(who, block)
		await Stage.bow(who, 1.6)
		CS.Act.lean(who, block, 10.0, 2.4)
	var looks := func() -> void:
		for p: Vector2 in sleepers.slice(0, 3):
			await Stage.look_at(p, 0.9)
		Stage.look_back(0.8)
	await S.say([
		CS.cue({"text": "Le Nanuqsaurus cligne des yeux. Une fois. Les veines violettes pâlissent… et il bâille. Un bâillement énorme, qui n'en finit pas."}, sleeps),
		{"text": "Et là, au milieu de la grotte, il s'endort d'un coup. Debout. La tête qui dodeline. Il ronfle."},
		CS.cue({"text": "Dame Suie a arrêté d'écrire. Son stylo est resté en l'air."}, stops),
		{"who": SUIE, "text": "Il dort. Trois semaines qu'il ne dormait plus. Et vous… vous lui avez seulement parlé."},
		CS.cue({"text": "Elle va jusqu'aux blocs de glace. Et, pour la première fois, elle enlève ses lunettes fumées."}, to_the_ice),
		CS.cue({"text": "Elle regarde les dormeurs de très près. Longtemps. Le petit Brachiosaure, le petit Stégosaure, le tout petit Psittacosaure qui a le hoquet dans son sommeil."}, looks),
		{"who": SUIE, "text": "Quinze ans dans la glace. Pas une veine. Pas un tremblement. Pas une goutte."},
		{"who": SUIE, "text": "Ils sont… parfaits. Sans une goutte."},
		{"who": SUIE, "text": "Votre grand-mère n'a rien dosé du tout. Elle a seulement attendu qu'ils soient prêts."},
		{"who": CHLOE, "text": "C'est ça, le Lien. On ne force rien. On attend. On reste."},
		CS.cue({"who": SUIE, "text": "Ce n'est pas dans mes tables."}, func() -> void: Stage.bow(who, 1.0)),
		{"who": SUIE, "text": "… Il faudra peut-être que je refasse mes tables."},
	])
	await S.say(_the_clue(who))
	await _keep_aconit(aconit)
	await _suie_leaves(who)
	Game.award_team_xp(XP_SUIE)
	Save.save_game()
	S.lock(false)


## The clue, « free of charge, which is rare »: the Masque wants all the Cœurs at once. The Cieux.
static func _the_clue(who: Node) -> Array:
	var chloe := Stage.chloe()
	var glasses := func() -> void:
		Stage.turn_to(who, chloe.global_position)
		Stage.bow(who, 0.8)
	var up := func() -> void:
		Stage.turn_to(who, (who as Node2D).global_position + Vector2(0.0, -200.0))
		Stage.look_at((who as Node2D).global_position + Vector2(0.0, -4.0 * S.CELL), 1.2)
		MS.drips((who as Node2D).global_position + Vector2(0.0, -30.0), 3, 0.4, 2.4)
	var lines: Array = [
		CS.cue({"text": "Elle remet ses lunettes. Puis elle se tourne vers Chloé."}, glasses),
		{"who": SUIE, "text": "Je vais vous dire une chose, mademoiselle Varenne. Gratuitement. C'est rare : notez-le."},
		{"who": SUIE, "text": "Le Masque ne veut pas les Cœurs un par un. Il les veut tous. Le même jour, au même endroit."},
		{"who": CHLOE, "text": "Où ?"},
		CS.cue({"who": SUIE, "text": "Là où il n'y a plus de chemin. Les Cieux, mademoiselle. Levez les yeux, de temps en temps."}, up),
		{"flag": &"suie_indice"},
	]
	if MS.hearts_count() >= 3:
		lines.append(CS.cue({"who": CHLOE, "text": "(Tous les Cœurs d'un coup… Et c'est moi qui les lui apporte, un par un.)"},
			func() -> void:
				Stage.look_back(0.8)
				MS.hearts(1, 1.0)))
	return lines


## « Gardez-le. Il dort : il ne me sert plus à rien. » Chloé keeps him (named Flocon), or lets
## him go up to the col, where his kind lives in the storms.
static func _keep_aconit(aconit) -> void:
	await S.say([{"who": SUIE, "text": "Gardez-le. Un sujet qui dort ne me sert plus à rien. Et celui-là, j'ai l'impression qu'il va dormir longtemps."}])
	if not SpeciesDB.PATHS.has(ACONIT[0]):   # (his species' sheet is not there yet: he stays where he is)
		return
	var wakes := func() -> void:
		if is_instance_valid(aconit) and aconit is DinoNpc:
			await CS.get_up(aconit, 0.6)
			Stage.turn_to(aconit, Stage.chloe().global_position)
			CS.Act.lean(aconit, Stage.chloe().global_position, 10.0, 1.2)
	await S.say([CS.cue({"text": "Le Nanuqsaurus ouvre un œil, puis l'autre. Il s'ébroue, s'étire, et vient poser sa tête contre l'épaule de Chloé. Ses yeux sont gris. Clairs. Calmes."}, wakes)])
	var pick := await Dialogue.choose("", "Il ne veut plus retourner derrière le traîneau.", ["Viens avec moi !", "Tu es libre, va"])
	if pick != 0:
		var goes := func() -> void:
			if is_instance_valid(aconit) and aconit is DinoNpc:
				Stage.cry(aconit, &"neutre")
				var from: Vector2 = (aconit as Node2D).global_position
				(aconit as DinoNpc).walk_to(from + Vector2(0.0, 5.0 * S.CELL), 140.0)
				Stage.fade_out(aconit, 1.6, true)
		await S.say([CS.cue({"text": "Le Nanuqsaurus pousse un petit grondement, presque un merci, et file vers la sortie. Là-haut, au col, les siens chassent dans les tempêtes. Il les retrouvera."}, goes)])
		return
	var d := Dino.create(ACONIT[0], ACONIT[1], ACONIT_NAME)
	var in_party: bool = await ForetCamp.make_room_for(d, "%s veut rester avec toi. Mais ton équipe est pleine : qui part attendre au Cabinet ?" % ACONIT_NAME)
	Game.set_flag(&"aconit_garde")
	await S.say([
		{"who": CHLOE, "text": "« Aconit », c'est le nom d'un poison. Toi, tu t'appelleras %s." % ACONIT_NAME},
		CS.cue({"text": "%s rejoint ton équipe !" % ACONIT_NAME if in_party else "%s part attendre au Cabinet. Il dormira près de la couveuse." % ACONIT_NAME},
			func() -> void:
				if is_instance_valid(aconit) and aconit is DinoNpc:
					Stage.hop(aconit, 1, 8.0)
					Stage.fade_out(aconit, 1.2, true)),
	])
	if is_instance_valid(aconit) and aconit is Node:
		Stage.fade_out(aconit, 0.4, true)


## She puts the vial of Givre back in its case without opening it, picks up her things, and goes
## with her sled; the sled tinkles further and further away.
static func _suie_leaves(who: Node) -> void:
	var packs := func() -> void:
		await Stage.bow(who, 1.4)
		var vials = S.actor("FiolesSuie")
		if vials:
			Stage.fade_out(vials, 0.8, true)
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else Vector2.ZERO
	var exit := S.at(P.GROTTES_ENTREE.x, P.GROTTES_ENTREE.y)
	var goes := func() -> void:
		var team: Array = [who, S.actor("Mandragore"), S.actor("TraineauSuie")]
		for n in team:
			if is_instance_valid(n) and n is Node2D:
				var to: Vector2 = exit + ((n as Node2D).global_position - at) * 0.3
				if n is Npc:
					(n as Npc).walk_to(to, "", 70.0)
				elif n is DinoNpc:
					(n as DinoNpc).walk_to(to, 70.0)
				else:
					CS.glide(n, [to], 70.0)
				Stage.fade_out(n, 3.0, false)
		for i in 5:
			CS.sfx(MS.ICE_SOUND, -12.0 - 3.0 * i)
			await S.wait(0.6)
	await S.say([
		CS.cue({"text": "Elle range la fiole de Givre dans sa boîte, sans l'ouvrir, et referme le couvercle. Clic."}, packs),
		{"who": SUIE, "text": "Au revoir, mademoiselle Varenne. Nous nous reverrons. Là où il fait plus chaud, cette fois, je le crains."},
		CS.cue({"text": "Elle s'en va sans se retourner. Mandragore tire le traîneau ; les fioles tintent, de plus en plus loin, puis plus du tout."}, goes),
		{"who": CHLOE, "text": "(« Là où il fait plus chaud »… Le volcan.)"},
		{"flag": &"suie_monts_partie"},
	])
	for node_name: String in ["TraineauSuie", "Mandragore"]:
		var n = S.actor(node_name)
		if n:
			n.queue_free()
	if is_instance_valid(who):
		who.queue_free()


# ------------------------------------------------------------------ the sleepers

## Before Dame Suie is gone, the reserve is « hers »: she says so, then her challenge.
static func _guarded() -> bool:
	if Game.flag(&"suie_monts_battue"):
		return false
	var who = S.actor("DameSuieMonts")
	if who:
		await S.say([CS.cue({"who": SUIE, "text": "Pas avant que nous ayons parlé, mademoiselle."},
			func() -> void: Stage.turn_to(who, Stage.chloe().global_position))])
		await dame_suie(who)
	return true


## The sleepers in their blocks of ice (StoryProps « Dormeur1…4 », event « dormeurs »): Chloé's
## hands on the ice, the Cœurs' warmth, the ice weeps; three little ones wake up and stumble out;
## the fourth sleeps on. They go to wait at the Cabinet. Afterwards, the fourth's line.
static func dormeurs(who: Node) -> void:
	if who and String(who.name).begins_with("Oeufs"):   # (the eggs share the sleepers' event in the zone's plan)
		await oeufs(who)
		return
	if await _guarded():
		return
	if Game.flag(&"dormeurs_reveilles"):
		await S.say([{"text": ForetCamp.next_line(&"dormeur_n", SLEEPER_AGAIN)}])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var blocks := _sleepers_px()
	var littles: Array = []
	for i in 4:
		littles.append(S.actor("DormeurDino%d" % (i + 1)))
	var at: Vector2 = (who as Node2D).global_position if who is Node2D else blocks[0]
	var hands := func() -> void:
		await CS.step_aside(who, 52.0)
		await CS.reach(chloe, at, 12.0, 1.4)
		Stage.pose(chloe, &"main", 3.0)
	var warmth := func() -> void:
		await MS.hearts(2, 0.9)
		for p: Vector2 in blocks.slice(0, 3):
			CS.pulse(p, MS.HEART_GLOW, 2, 1.0, 2.0, 2.5)
	var weeps := func() -> void:
		for i in 3:
			var block = S.actor("Dormeur%d" % (i + 1))
			if block:
				Stage.tremble(block, 0.8, 1.5)
			MS.drips(blocks[i] + Vector2(0.0, -20.0), 4, 0.3, 1.1)
		await S.wait(1.0)
		if littles[0]:
			Stage.emote(littles[0], "!")
	var others := func() -> void:
		for i in [1, 2]:
			await S.wait(0.8)
			if littles[i]:
				Stage.emote(littles[i], "!")
				if i == 2:
					Stage.hop(littles[i], 1, 5.0)   # (the tiny one sneezes)
	var out := func() -> void:
		MS.crack(3.0)
		for i in 3:
			var block = S.actor("Dormeur%d" % (i + 1))
			if block:
				Stage.fade_out(block, 1.0, true)
				MS.snow_puff(blocks[i], 16, 0.4, 0.4)
		await S.wait(0.6)
		for i in 3:
			var d = littles[i]
			if d is DinoNpc:
				d.modulate = Color.WHITE
				Stage.tremble(d, 1.0, 2.0)
				(d as DinoNpc).walk_to(chloe.global_position.lerp(blocks[i], 0.45), 45.0)
	var fourth := func() -> void:
		Stage.look_at(blocks[3].lerp(S.at(P.OEUFS.x, P.OEUFS.y), 0.5), 1.2)
	var huddle := func() -> void:
		Stage.look_back(0.8)
		for i in 3:
			var d = littles[i]
			if d is DinoNpc:
				Stage.turn_to(d, chloe.global_position)
				CS.Act.lean(d, chloe.global_position, 8.0, 1.6)
				Stage.emote(d, "♥")
				await S.wait(0.3)
	var lines: Array = [
		CS.cue({"text": "Chloé pose la main sur la glace. Elle est si froide qu'elle brûle." if not Game.flag(&"moufles_helene")
			else "Chloé pose la main sur la glace. Même à travers les moufles d'Hélène, elle est si froide qu'elle brûle."}, hands),
		CS.cue({"text": "Dans la sacoche, les Cœurs se mettent à battre. Fort. Leur chaleur passe dans ses bras, dans ses mains… dans la glace."}, warmth),
		CS.cue({"text": "La glace pleure. Des gouttes coulent, de plus en plus vite. Dans le premier bloc, le petit Brachiosaure ouvre un œil."}, weeps),
		CS.cue({"text": "Puis le petit Stégosaure. Puis le tout petit Psittacosaure, qui éternue."}, others),
		CS.cue({"text": "Les blocs craquent, fondent, et les trois petits sortent de la glace en titubant, comme on sort du lit un lundi matin."}, out),
		{"who": CHLOE, "text": "Doucement… Vous avez dormi longtemps."},
		CS.cue({"text": "Le quatrième bloc ne bouge pas. Le petit Ankylosaure dort toujours, tranquille. Et les œufs aussi."}, fourth),
	]
	if Game.flag(&"found_journal_19"):
		lines.append({"who": CHLOE, "text": "(« J'ai voulu réveiller ce qui devait dormir », écrivait Hélène. Eux, ils ne sont pas prêts. Je ne force rien.)"})
	else:
		lines.append({"who": CHLOE, "text": "(Eux, ils ne sont pas prêts. On ne réveille pas ce qui doit dormir.)"})
	lines.append_array([
		CS.cue({"text": "Les trois petits se serrent contre Chloé en grelottant. Ils ont faim, ils ont froid, et ils ont tous choisi la même personne."}, huddle),
		{"who": CHLOE, "text": "Je vous emmène au Cabinet. Roc a une couveuse bien chaude. Et beaucoup de baies."},
	])
	lines.append({"text": "Bertille les descendra au port avec son troupeau : ils partent attendre au Cabinet. (Le Pr Roc peut te les échanger contre un dino de ton équipe.)" if Game.flag(&"bertille_vue")
		else "Les trois petits partent attendre au Cabinet, bien au chaud. (Le Pr Roc peut te les échanger contre un dino de ton équipe.)"})
	lines.append({"flag": &"dormeurs_reveilles"})
	await S.say(lines)
	_to_the_cabinet()
	for i in 3:
		var d = littles[i]
		if is_instance_valid(d) and d is Node:
			Stage.fade_out(d, 1.2, true)
	Stage.look_back()
	Game.award_team_xp(XP_DORMEURS)
	Save.save_game()
	S.lock(false)


## The three little ones wait in the Cabinet's reserve (Game.box): Roc exchanges them.
static func _to_the_cabinet() -> void:
	for w: Array in WAKERS:
		if not SpeciesDB.PATHS.has(w[0]):
			continue
		var d := Dino.create(w[0], w[1])
		Game.mark_caught(d.species().id)
		Game.box.append(d)
	Game.party_changed.emit()


## Dame Suie's sled (StoryProp « TraineauSuie », event « traineau_suie »): crates of vials lined
## up like soldiers, « Givre » on every label. Hers until she is gone (with it).
static func traineau(who: Node) -> void:
	if await _guarded():
		return
	var chloe := Stage.chloe()
	await S.say([CS.cue({"text": "Un traîneau chargé de caisses. Dans chaque caisse, des fioles rangées comme de petits soldats, et sur chaque étiquette, de la même écriture fine : « Givre »."},
		func() -> void:
			await CS.reach(chloe, (who as Node2D).global_position if who is Node2D else chloe.global_position, 10.0, 1.0)
			CS.sfx(MS.ICE_SOUND, -10.0))])


## The eggs in the ice (StoryProp « OeufsGlace », event « oeufs_glace »): not ready; Chloé does
## not touch them.
static func oeufs(who: Node) -> void:
	if await _guarded():
		return
	var chloe := Stage.chloe()
	await S.say([CS.cue({"text": ForetCamp.next_line(&"oeufs_n", EGGS_AGAIN)}, func() -> void:
		await CS.reach(chloe, (who as Node2D).global_position if who is Node2D else chloe.global_position, 8.0, 1.0)
		if who is Node2D:
			CS.pulse((who as Node2D).global_position, MS.ICE_BLUE, 1, 1.4, 1.2, 2.0))])
