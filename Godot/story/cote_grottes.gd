class_name CoteGrottes
## Chapter 5, the Côte Préhistorique, the sea caves (zone grottes_marines; docs/histoire.md,
## ch. 5, points 7 to 11): the dry cave (tide pools, blue amber, crates dragged into the water:
## « someone goes this way, under the water »); past the flooded passage, the smugglers' cache in
## the dark (no light, ever: it is the rule); the Passeur, an old sailor with a cold pipe who
## owed Hélène his Archelon, tests Chloé, then rows away by the sea tunnel; the crates (the
## Comptoir's stamp in full, the ledger, a note from « M. »: « que personne ne la touche »);
## the boat moored at the quay (the one that brought Chloé to the island, « MAÏA » on its bow, a
## child's drawing under the bench). Page 21 is a Pickup (DialogueCote page_21: passe_recif).
## Flags: grottes_arrivee, cache_vue, passeur_parle, passeur_battu, passeur_parti,
## caisses_fouillees, barque_isaure_vue; caisses_n (lines).

const S := preload("res://story/story.gd")
const P := preload("res://story/cote_places.gd")
const CS := preload("res://story/cote_stage.gd")
const CHLOE := "Chloé"
const PASSEUR := "Le Passeur"
const OMBRE_MUSIC := "res://assets/audio/music/ombre.ogg"
## The black amber's light in the dark, the caves' blue amber.
const VIOLET := Color(0.62, 0.3, 1.0)
const BLUE_AMBER := Color(0.5, 0.8, 1.0)
## The crates' drag marks on the shingle, shown one after another (their grit).
const TRACK_MARKS := 6
const GRIT: Array[Color] = [Color(0.82, 0.78, 0.7), Color(0.66, 0.62, 0.56)]
## The Passeur's team (sea creatures, rope names; to check by simulation with the chapter's
## levels); a species missing from SpeciesDB is replaced by the one after it.
const PASSEUR_TEAM := [
	[&"archelon", 29, "Bouline"],
	[&"masiakasaurus", 29, "Grappin"],
	[&"ichthyosaurus", 30, "Amarre"],
]
const STAND_INS := {&"archelon": &"koolasuchus", &"masiakasaurus": &"compsognathus", &"ichthyosaurus": &"baryonyx"}
const XP_GROTTES := 20
const XP_CACHE := 20
const XP_PASSEUR := 80
const XP_CAISSES := 30
const XP_BARQUE := 30
const CAISSES_AGAIN := [
	"Les caisses de l'Ombre Noire. Le tampon du Comptoir, partout. Chloé ne les ouvre plus : elle sait ce qu'il y a dedans.",
	"Chloé relit le mot de « M. » : « Que personne ne la touche. » Elle le range avec les pages d'Hélène.",
]


# ------------------------------------------------------------------ the dry cave

## The first time in the caves (from the cove): the dry cave, the crates' tracks leading into the
## water, the passage flooded up to the vault.
static func arrival() -> void:
	if Game.flag(&"grottes_arrivee"):
		return
	S.lock(true)
	await S.wait(0.5)
	var chloe := Stage.chloe()
	var hall := S.at(P.GROTTES_SALLE.x, P.GROTTES_SALLE.y)
	var flooded := S.at(P.GROTTES_PLONGEE.x, P.GROTTES_PLONGEE.y)
	var drips := func() -> void:
		Stage.pose(chloe, &"grimpe", 0.9)   # (hauling herself up, when drawn)
		CS.splash(chloe.global_position, 10, 0.4, 0.3)
		Stage.tremble(chloe, 0.8, 1.2)
	var cave := func() -> void:
		Stage.look_at(hall, 1.2)
		CS.pulse(hall + Vector2(0.0, -2.0 * S.CELL), BLUE_AMBER, 2, 1.6, 2.0)
	var tracks := func() -> void:
		Stage.look_back()
		Stage.bow(chloe, 1.2)
		var dino := CS.lead()
		if dino:
			CS.D._sniff(dino)
		# The drag marks, one after another from her feet to the water: pale grit stirred up.
		for i in TRACK_MARKS:
			CS.Act.burst(chloe.global_position.lerp(flooded, (i + 1.0) / (TRACK_MARKS + 1.0)), GRIT, 6, 0.05, 0.3)
			await S.wait(0.3)
	var lines: Array = [
		CS.cue({"text": "Chloé se hisse sur les galets, ruisselante."}, drips),
		CS.cue({"text": "Une grotte : des flaques où filent de petits crabes et, au plafond, des cristaux d'ambre qui s'allument dans le noir."}, cave),
		CS.cue({"text": "Sur les galets, de longues traces : des caisses qu'on a traînées jusqu'au fond de la grotte… jusqu'à l'eau."}, tracks),
		CS.cue({"text": "Au fond, l'eau monte jusqu'à la voûte. Pas un passage, pas une marche. Seulement l'eau, noire et calme."},
			func() -> void: Stage.look_at(flooded, 1.2)),
		CS.cue({"who": CHLOE, "text": "(Quelqu'un passe par là. Sous l'eau.)"}, func() -> void: Stage.look_back()),
	]
	var diver: Dino = CS.diver()
	if diver:
		lines.append({"who": CHLOE, "text": "(Avec le masque de Joss, et %s… je peux passer, moi aussi.)" % diver.nickname})
	else:
		lines.append({"text": CS.dive_step()})
	lines.append({"flag": &"grottes_arrivee"})
	await S.say(lines)
	Game.award_team_xp(XP_GROTTES)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ the cache and the Passeur

## Past the flooded passage (StoryTrigger « CacheArrivee », event « cache_arrivee »): the cache in
## the dark, the crates, the boat, and the Passeur on a crate. Then his challenge.
static func cache_arrivee(_trigger: Node) -> void:
	if Game.flag(&"cache_vue"):
		return
	var who := _passeur_npc()
	S.lock(true)
	await S.say(_cache_seen(who))
	await S.say(_passeur_hello(who))
	Game.award_team_xp(XP_CACHE)
	Save.save_game()
	S.lock(false)
	await passeur(who)


static func _cache_seen(who: Node) -> Array:
	var chloe := Stage.chloe()
	var cache := S.at(P.CACHE.x, P.CACHE.y)
	var boat := S.at(P.BARQUE.x, P.BARQUE.y)
	var diver: Dino = CS.diver()
	var surfaces := func() -> void:
		CS.splash(chloe.global_position, 18, 0.3, 0.5)
		Stage.tremble(chloe, 1.0, 1.4)
	var crates := func() -> void:
		await CS.pan(cache, 1.6)
		CS.pulse(cache, VIOLET, 3, 1.6, 2.2)
	return [
		CS.cue({"text": "Chloé ressort de l'eau de l'autre côté, agrippée au cou de %s, le cœur battant. Il fait noir. Complètement noir. Puis ses yeux s'habituent." % diver.nickname if diver
			else "Chloé ressort de l'eau de l'autre côté, le cœur battant. Il fait noir. Complètement noir. Puis ses yeux s'habituent."}, surfaces),
		CS.cue({"text": "Une grande grotte, sans une lanterne. Des caisses empilées jusqu'à la voûte. Certaines sont ouvertes : dedans, des pierres noires luisent d'une lumière violette."}, crates),
		CS.cue({"text": "Au bout, un quai de pierre. Et, amarrée au quai, une barque."},
			func() -> void: CS.pan(boat, 1.4)),
		CS.cue({"text": "Adossé à une caisse, un vieil homme attend, un masque d'os sur le visage. Entre les dents du masque, il mâchonne une pipe éteinte."},
			func() -> void:
				Stage.look_at_actor(who, 1.0)
				Stage.turn_to(who, chloe.global_position)
				CS.crouch(who, 0.1, 0.4)),
	]


static func _passeur_hello(who: Node) -> Array:
	var chloe := Stage.chloe()
	var stands := func() -> void:
		await CS.get_up(who, 0.7)
		var at: Vector2 = (who as Node2D).global_position
		if who is Npc:
			(who as Npc).walk_to(at + (chloe.global_position - at).normalized() * 30.0, "", 60.0)
	return [
		{"who": PASSEUR, "text": "Pas de lumière, ici. Jamais. C'est la règle."},
		{"who": PASSEUR, "text": "Alors c'est toi, la petite d'Hélène. T'as ses yeux. Tout le monde a dû te le dire."},
		{"who": CHLOE, "text": "Qui êtes-vous ?"},
		{"who": PASSEUR, "text": "Le Passeur. Je rame. Je pose pas de questions. J'y réponds pas non plus."},
		{"who": PASSEUR, "text": "Ta grand-mère a soigné mon Archelon, une fois. Il avait avalé un hameçon. Elle a pas voulu d'argent. Elle voulait que je lui raconte la mer."},
		CS.cue({"who": PASSEUR, "text": "Le Masque a dit : si la petite vient, laissez-la passer. Il a pas dit : sans voir ce qu'elle vaut."}, stands),
		{"flag": &"cache_vue"},
		{"flag": &"passeur_parle"},
	]


## The Passeur (Npc « Passeur », event « passeur »): his challenge; beaten, he says what he will
## say (« tu sais lire, non ? ») and rows away by the sea tunnel.
static func passeur(who: Node) -> void:
	if Game.flag(&"passeur_battu") or who == null:
		return
	if not Game.flag(&"passeur_parle"):
		S.lock(true)
		await S.say(_passeur_hello(who))
		S.lock(false)
	var pick := await Dialogue.choose(PASSEUR, "Trois dinos. Des marins, comme moi. Montre-moi.", ["Relever le défi", "Pas encore"])
	if pick != 0:
		await S.say([CS.cue({"who": PASSEUR, "text": "Je bouge pas. J'ai le temps. La mer aussi."},
			func() -> void: CS.crouch(who, 0.1, 0.4))])
		return
	var rules := {"lose_spawn": P.LOSE_GROTTES}
	var theme: AudioStream = ForetCamp.music_at(OMBRE_MUSIC)
	if theme:
		rules["music"] = theme
	if not await S.duel(PASSEUR, _team(), rules):
		await S.say([{"who": PASSEUR, "text": "La mer t'a pas encore dit oui. Reviens quand tes dinos auront repris leur souffle."}])
		return
	await _passeur_beaten(who)


## His team, each species replaced when SpeciesDB has not got it yet.
static func _team() -> Array:
	var team: Array = []
	for member: Array in PASSEUR_TEAM:
		var id: StringName = member[0]
		if not SpeciesDB.PATHS.has(id):
			id = STAND_INS.get(id, &"baryonyx")
		var entry: Array = [id, member[1], member[2]]
		team.append(entry)
	team[1].append({"before": [{"who": PASSEUR, "text": "Bouline tient bon. Grappin, lui, il mord. Surtout les chevilles."}]})
	team[2].append({"before": [{"who": PASSEUR, "text": "Et Amarre. Elle m'a ramené au port, une nuit de tempête. Toute seule. Moi, je dormais."}]})
	return team


static func _passeur_beaten(who: Node) -> void:
	S.lock(true)
	var chloe := Stage.chloe()
	var quay := S.at(P.QUAI.x, P.QUAI.y)
	var tunnel := S.at(P.TUNNEL_MER.x, P.TUNNEL_MER.y)
	var goes := func() -> void:
		Stage.bow(who, 0.8)
		if who is Npc:
			await (who as Npc).walk_to(quay + Vector2(-20.0, 20.0), "", 70.0)
	var nods := func() -> void:
		Stage.turn_to(who, S.at(P.BARQUE.x, P.BARQUE.y))
		Stage.bow(who, 0.6)
	var rows_away := func() -> void:
		var skiff := CS.prop("barque", quay + Vector2(0.0, -10.0), "CanotPasseur")
		if skiff:
			skiff.scale = Vector2(0.7, 0.7)
		if who is Node2D:
			(who as Node2D).global_position = quay + Vector2(0.0, -16.0)
			CS.in_boat(who)   # sitting in his skiff, on the water
		for n in [skiff, who]:
			if n is Node2D:
				CS.glide(n, [tunnel], 45.0)
				Stage.fade_out(n, 3.4, true)
		Stage.look_at(tunnel, 1.6)
	var lines: Array = [
		CS.cue({"who": PASSEUR, "text": "… Tu vaux ce qu'elle valait."}, func() -> void: Stage.turn_to(who, chloe.global_position)),
		CS.cue({"text": "Le vieil homme range sa pipe dans sa poche, et va détacher un petit canot, caché derrière les caisses."}, goes),
		{"who": CHLOE, "text": "Et la barque, au quai ? C'est la vôtre ?"},
		CS.cue({"who": PASSEUR, "text": "Elle est pas à moi. Et je dirai pas à qui. Mais tu sais lire, non ?"}, nods),
		{"who": PASSEUR, "text": "Moi, je rentre. Je suis trop vieux pour les secrets des autres."},
		CS.cue({"text": "Il s'éloigne par le tunnel de la mer, sans lanterne, en chantonnant une vieille chanson de marin. Faux. Très faux."}, rows_away),
		{"flag": &"passeur_battu"},
		{"flag": &"passeur_parti"},
	]
	await S.say(lines)
	if is_instance_valid(who):
		who.queue_free()
	Stage.look_back()
	Game.award_team_xp(XP_PASSEUR)
	Save.save_game()
	S.lock(false)


## The Passeur of the zone (Npc « Passeur »), or one put by the crates when the zone has none.
static func _passeur_npc() -> Node:
	var n = S.actor("Passeur")
	if n != null:
		return n
	if Game.flag(&"passeur_parti"):
		return null
	var w = S.world()
	if w == null:
		return null
	var npc: Npc = load("res://actors/npc.tscn").instantiate()
	npc.name = "Passeur"
	npc.display_name = PASSEUR
	npc.sheet = load("res://assets/art/characters/sbire.png")
	npc.event = &"passeur"
	npc.position = S.at(P.QUAI.x - 3.0, P.QUAI.y + 1.0)
	w.region.entities.add_child(npc)
	return npc


## Before the Passeur is beaten, the cache's things are his: he says so, then his challenge.
static func _guarded() -> bool:
	if Game.flag(&"passeur_battu"):
		return false
	var who := _passeur_npc()
	if who:
		await S.say([CS.cue({"who": PASSEUR, "text": "Touche pas. Pas encore."}, func() -> void: Stage.turn_to(who, Stage.chloe().global_position))])
		await passeur(who)
	return true


# ------------------------------------------------------------------ the crates

## The crates of black amber (StoryProp « CacheContrebande », event « cache_contrebande »): the
## Comptoir's stamp, the ledger (« Reçu : F. », « masques de plongée : 10 (le sellier) »), and a
## note from « M. »: « La petite ouvrira le récif pour nous. Que personne ne la touche. »
static func caisses(who: Node) -> void:
	if await _guarded():
		return
	if Game.flag(&"caisses_fouillees"):
		await S.say([{"text": ForetCamp.next_line(&"caisses_n", CAISSES_AGAIN)}])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var opens := func() -> void:
		await CS.step_aside(who, 56.0)
		await CS.reach(chloe, at, 12.0, 1.0)
		CS.pulse(at, VIOLET, 2, 1.2, 2.4, 3.0)
	var reads := func() -> void:
		Stage.bow(chloe, 1.2)
	var leafs := func() -> void:
		Stage.show_thing("registre", at + Vector2(22.0, 16.0), "RegistrePasseur")   # (on the small crate)
		for i in 3:
			await CS.reach(chloe, at + Vector2(0.0, 20.0), 6.0, 0.5)
	var lines: Array = [
		CS.cue({"text": "Chloé soulève un couvercle. Des pierres noires, lisses, qui luisent violet dans le noir. Et une odeur de cendre froide."}, opens),
		CS.cue({"text": "Sur chaque caisse, un tampon. Entier, cette fois : « COMPTOIR D'AMBRE — HAVRE-DORÉ »."}, reads),
		{"who": CHLOE, "text": "(Sur la caisse de Brac, dans le Désert, il n'en restait que « …ptoir d'Amb… ». Le Comptoir d'Ambre. Maître Ferréol.)" if Game.flag(&"chariot_fouille")
			else "(Le Comptoir d'Ambre… Le Comptoir de Maître Ferréol ?)"},
		CS.cue({"text": "Sur une caisse plus petite, un registre de bord, tenu d'une écriture serrée. Chaque semaine, la même ligne : « Entrepôt du Comptoir : 12 caisses. Reçu : F. »"}, leafs),
		CS.cue({"text": "Et tout en bas de la dernière page : « Masques de plongée : 10 (le sellier). »"},
			func() -> void: Stage.emote(chloe, "!")),
		{"who": CHLOE, "text": "(Les « plongeurs » de Ferréol… Ce sont eux. Et Joss n'en sait rien.)" if Game.flag(&"joss_cote_vu")
			else "(Des masques de plongée… pour passer sous l'eau jusqu'ici.)"},
		CS.cue({"text": "Glissé dans le registre, un papier noir plié en deux. Encre argentée, écriture fine et droite. Le papier sent le sel."},
			func() -> void: CS.reach(chloe, at, 8.0, 1.0)),
		{"text": "« La petite ouvrira le récif pour nous. Laissez-la passer. Que personne ne la touche. — M. »"},
	]
	if Game.flag(&"chariot_fouille"):
		lines.append({"who": CHLOE, "text": "(« D'autres ouvriront les portes pour nous », disait le mot du Désert. Les autres… c'est moi.)"})
	else:
		lines.append({"who": CHLOE, "text": "(Le Masque veut que j'ouvre le récif… pour lui.)"})
	lines.append_array([
		CS.cue({"who": CHLOE, "text": "(Et « que personne ne la touche »… Pourquoi le Masque me protège-t-il ?)"},
			func() -> void: CS.later(0.6, func() -> void: Stage.emote(chloe, "?"))),
		{"flag": &"caisses_fouillees"},
	])
	await S.say(lines)
	Stage.take_thing(S.actor("RegistrePasseur"))
	Game.award_team_xp(XP_CAISSES)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ the boat

## The boat at the quay (StoryProp « BarqueIsaure », event « barque_isaure »): the knots of Maïa's
## mother, the boat that brought Chloé to the island, « MAÏA » on its bow, a child's drawing.
static func barque(who: Node) -> void:
	if await _guarded():
		return
	if Game.flag(&"barque_isaure_vue"):
		await S.say([{"text": "La barque d'Isaure. Le dessin est toujours punaisé sous le banc. Chloé n'y touche pas."}])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var looks := func() -> void:
		await CS.step_aside(who, 70.0)
		Stage.look_at(at, 1.0)
	var knots := func() -> void:
		await CS.reach(chloe, at, 12.0, 1.0)
		Stage.bow(chloe, 0.8)
	var round_the_bow := func() -> void:
		var side := signf(chloe.global_position.x - at.x)
		await CS.chloe_walk(at + Vector2(-side * 90.0, 30.0), 70.0, 2.4)
		Stage.turn_to(chloe, at)
	var the_name := func() -> void:
		Stage.recoil(chloe, at, 14.0)
		Stage.emote(chloe, "!")
	var drawing := func() -> void:
		await CS.kneel()
		await CS.reach(chloe, at, 8.0, 1.2)
	var lines: Array = [
		CS.cue({"text": "Une barque de pêche, solide, bien entretenue. Une voile rapiécée, roulée sur le mât. Une rayure bleue tout le long de la coque."}, looks),
	]
	if Game.flag(&"maia_defi_2"):
		lines.append(CS.cue({"text": "Les cordages sont noués de nœuds de marin, serrés, parfaits. Chloé les a déjà vus : au pont du Marais, quand Maïa l'a réparé « avec les nœuds de sa mère »."}, knots))
	else:
		lines.append(CS.cue({"text": "Les cordages sont noués de nœuds de marin, serrés, parfaits. Des nœuds de quelqu'un qui a grandi sur un port."}, knots))
	lines.append_array([
		{"who": CHLOE, "text": "(Cette barque… C'est elle qui m'a amenée sur l'île. Dans la brume, le premier jour.)"},
		CS.cue({"text": "Chloé fait le tour de la proue. Il y a un nom, peint en blanc, à demi effacé par le sel."}, round_the_bow),
		CS.cue({"text": "« MAÏA »."}, the_name),
		{"who": CHLOE, "text": "(La barque d'Isaure. La barque de la maman de Maïa. Au milieu des caisses d'ambre noir.)"},
		CS.cue({"text": "Sous le banc, punaisé contre le bois, un dessin d'enfant délavé par l'humidité : un dino à trois cornes, un bateau, deux bonshommes qui se tiennent la main. Dessous, en lettres de travers : « MAMAN + MAÏA + CAILLOU »."}, drawing),
		CS.cue({"text": "Chloé le laisse où il est."}, func() -> void: CS.get_up(chloe, 0.7)),
		{"who": CHLOE, "text": "(Maïa ne doit pas l'apprendre comme ça.)"},
		{"flag": &"barque_isaure_vue"},
	])
	await S.say(lines)
	Stage.look_back()
	Game.award_team_xp(XP_BARQUE)
	Save.save_game()
	S.lock(false)
