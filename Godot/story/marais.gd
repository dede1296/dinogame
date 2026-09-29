class_name Marais
## Chapter 3, the Marais Brumeux (docs/histoire.md, ch. 3), its first half: arriving in the
## mist while a deep voice sings; Joss and his swimming vests (a young Baryonyx stole the best
## one: beaten or caught, it gives it back, and La Nage opens the channels); the Voix du
## Marais, Hélène's old Parasaurolophus, behind an amber door (Écho's mother: a reunion when
## Écho is Chloé's, the Ancien's page), whose song opens the sunken temple. Dame Suie, Roc at
## night (after page 14) and Maïa's third challenge are in story/marais_suite.gd; the temple
## in story/marais_temple.gd.
## Flags: marais_arrivee, joss_marais_vu, baryonyx_gilet_vu, baryonyx_lecon, gilet_nage,
## baryonyx_gilet_capture, voix_rencontree, temple_ouvert, voix_echo_reconnu,
## found_journal_ancien_voix, voix_coeur_chant, voix_apres_coeur; voix_n, joss_havre_n (lines).
## (porte_voix_ouverte: the amber door, an Obstacle.) Pages 13 to 16 are Pickups placed by the
## zone (DialogueDB page_13 … page_16).

const S := preload("res://story/story.gd")
const Act := preload("res://story/marais_stage.gd")
const CHLOE := "Chloé"
const JOSS := "Joss"
const CRY := "res://assets/audio/cries/%s-%s.mp3"
const LATCH := preload("res://assets/audio/sfx/latch.wav")
## The Voix's voice: a Parasaurolophus's call, old and deep (never high: no shrill sounds).
const OLD_PITCH := 0.72
## Where a lost battle takes Chloé back to: the way in from the Forêt.
const MARAIS_SPAWN := &"DepuisForet"
## The young thief (wild, it can be caught) and the name Chloé gives it.
const BARYONYX_LEVEL := 16
## The young thief's size, share of an adult Baryonyx (its DinoNpc in the zone: tools/zones/marais.gd).
const BARYONYX_SIZE := 0.55
const BARYONYX_NAME := "Bouée"
const XP_JOSS := 20
const XP_GILET := 40
const XP_VOIX := 60
const XP_ANCIEN := 30
## The Ancien's page, left by the Voix du Marais a year ago (Écho's mother).
const VOIX_PAGE := [
	"La Voix",
	"Mon quatrième réveil : une Parasaurolophus qui a chanté avant même d'ouvrir les yeux. Tout le Cabinet a vibré ; Anselme en a lâché trois flacons.",
	"Elle a choisi le Marais toute seule, pour l'écho sous le temple. Chaque soir, elle chante vers lui. C'est elle qui me l'a ouvert, il y a vingt-cinq ans.",
	"Cet œuf-là, elle l'a couvé en fredonnant plus bas que d'habitude. Je crois que c'était une berceuse. Si elle te laisse approcher, chante avec elle. Faux, ça ne fait rien : elle aussi chante faux, le matin.",
]
const VOIX_AGAIN := [
	"La Voix du Marais chante tout bas, les yeux mi-clos. Les nénuphars tremblent à chaque note.",
	"La vieille Parasaurolophus renifle la sacoche de Chloé. Les pages d'Hélène sont toujours là : elle a l'air rassurée.",
	"La Voix se tourne vers le temple et fredonne une note grave, très longue. Le Marais l'écoute sans bouger.",
	"Une libellule s'est posée sur la crête de la Voix. Elle fait semblant de ne pas l'avoir remarquée.",
]
## With Écho at her side ("%s" = Écho's name).
const VOIX_AGAIN_ECHO := [
	"%s et la Voix chantent ensemble. %s chante un peu faux. Sa mère aussi, d'ailleurs.",
	"La Voix lisse la crête {de} du bout du museau. %s se laisse faire, les yeux fermés.",
	"%s s'endort contre le flanc de sa mère. Chloé attend. Rien ne presse.",
]
## How the camera looks into the mist on arriving (from Chloé, px).
const MIST_LOOK := Vector2(-230.0, -30.0)
## Where the little one stands to sing to his mother: this far beside her and in front (px).
const BESIDE := 96.0
const BESIDE_DOWN := 34.0
## The temple's stone door slides down into the ground in this long (s).
const DOOR_SLIDE_S := 3.0
## Joss, come running to the sandbank, stops this far from Chloé (px).
const JOSS_GAP := 86.0
## Where the beaten Baryonyx swims off to (from its sandbank, px).
const DIVE_OFF := Vector2(-140.0, 40.0)


# ------------------------------------------------------------------ arriving

## The first time in the Marais: mist everywhere, a deep song far away (the Voix; Écho
## answers it), then a splash and Joss shouting. Afterwards: the Voix's joyful note once the
## Heart is Chloé's; Roc's lantern, some evenings (after page 14).
static func arrival() -> void:
	if Game.flag(&"marais_arrivee"):
		await _heart_song()
		await MaraisSuite.night()
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.8)
	var here: Vector2 = w.player.global_position
	var far := here + MIST_LOOK   # along the boardwalk, into the mist
	var lines: Array = [Act.cue({"text": "La brume. Partout. Elle monte de l'eau, s'accroche aux roseaux et avale les pontons à dix pas. Ça sent la vase, la menthe sauvage et le bois mouillé."},
		func() -> void: Act.pan(far, 3.0))]
	if Game.is_raining():
		lines.append({"text": "La pluie tombe sans bruit sur l'eau noire. Ici, même la pluie chuchote."})
	lines.append(Act.cue({"text": "Quelque part, de l'eau clapote. Quelque chose de gros vient de plonger."}, func() -> void:
		var plunge := Act.water_near(far + Vector2(-40.0, -70.0))
		Act.burst(plunge, Act.SPLASH, 30, Act.ON_WATER, 0.5)
		Stage.turn_to(Stage.chloe(), plunge)))
	await S.say(lines)
	cry("hadrosaure", "neutre", -16.0, OLD_PITCH)
	await S.wait(1.2)
	var singer = S.actor("VoixDuMarais")   # far away, deep in the reeds: Chloé turns that way
	await S.say([Act.cue({"text": "Alors, du fond de la brume, monte un chant. Une seule note, grave, immense, qui fait frissonner l'eau entre les roseaux. Puis une autre. On dirait que tout le Marais respire avec elle."},
		func() -> void:
			if singer:
				Stage.turn_to(Stage.chloe(), (singer as Node2D).global_position))])
	var cast := {}   # Écho out of her party for his answer (cast « echo »), when he is not her lead
	await S.say(_echo_hears(cast))
	Act.echo_off_stage(cast.get("echo"))
	await S.say([
		Act.cue({"text": "PLOUF ! Tout près, un grand bruit d'eau. Puis une voix, beaucoup moins jolie :"}, _plouf),
		Act.cue({"who": "Une voix", "text": "Hé ! HÉ ! Reviens ici, espèce de… de sac à flotteurs ! Rends-moi ça !"}, _joss_shouts),
		Act.cue({"who": CHLOE, "text": "(Cette voix… Joss ? Le sellier du Havre ?)"}, func() -> void: Stage.look_back()),
		{"flag": &"marais_arrivee"},
	])
	Save.save_game()
	S.lock(false)


## Something big dives right by Chloé: she jumps, the camera comes back to her.
static func _plouf() -> void:
	var chloe := Stage.chloe()
	if chloe == null:
		return
	Audio.play_sfx(LATCH, -10.0)
	Stage.shake(2.0, 0.2)
	Stage.look_back(0.3)
	Act.burst(Act.water_near(chloe.global_position + Vector2(-90.0, -70.0), 3), Act.SPLASH, 40, Act.ON_WATER, 0.6)
	Stage.emote(chloe, "!")
	Stage.hop(chloe, 1, 8.0)


## Joss, on the pontoon of his stilt cabin, shouts at the thief swimming away: the camera
## shows him, stamping his feet.
static func _joss_shouts() -> void:
	var sellier = S.actor("Joss")
	if sellier == null:
		return
	var at: Vector2 = (sellier as Node2D).global_position
	var wake := Act.water_near(at + Vector2(-60.0, 70.0), 3)
	await Stage.look_at(at, 0.6)
	if not is_instance_valid(sellier):
		return
	Stage.turn_to(sellier, wake)
	Act.burst(wake, Act.SPLASH, 12, Act.ON_WATER, 0.4)
	await Stage.hop(sellier, 2, 9.0)
	if is_instance_valid(sellier):
		Stage.hop(sellier, 1, 9.0)


## What Chloé's dinos make of the song (Écho knows that voice: at her side, or brought out of
## her party for his answer, cast « echo »).
static func _echo_hears(cast: Dictionary) -> Array:
	var w = S.world()
	var echo := echo_dino()
	var lead := Game.lead_dino()
	var starter_is_echo := str(Game.flag(&"starter")) == "parasaurolophus"
	if echo and Game.party.has(echo):
		var little: Node2D = w.companion if lead == echo else Act.echo_on_stage(echo)
		if lead != echo:
			cast["echo"] = little
		var lines: Array = [Act.cue({"text": "%s relève la tête d'un coup. Sa crête vibre. Et il répond : une petite note, toute tremblante, sur le même ton." % echo.nickname},
			func() -> void: Act.little_note(little))]
		if starter_is_echo:
			lines.append({"who": CHLOE, "text": "(« Sa mère, la Voix du Marais, chante encore dans les roseaux »… C'est elle ?)"})
		else:
			lines.append({"who": CHLOE, "text": "(On dirait qu'il connaît cette voix. Comme s'il l'avait entendue… avant même d'éclore.)"})
		return lines
	var out: Array = []
	if lead:
		out.append(Act.cue({"text": "%s dresse la tête et écoute, immobile." % lead.nickname}, func() -> void:
			Stage.rear(w.companion, 1.8)
			Stage.emote(w.companion, "?")))
	if echo and starter_is_echo:
		out.append({"who": CHLOE, "text": "(« Sa mère, la Voix du Marais, chante encore dans les roseaux »… Si %s entendait ça.)" % echo.nickname})
	elif Game.flag(&"maia_defi_2"):
		out.append({"who": CHLOE, "text": "(La Voix du Marais… Maïa en parlait. Une vieille Parasaurolophus d'Hélène.)"})
	return out


## Once the first Heart is Chloé's: the Voix sings a round, joyful note (once).
static func _heart_song() -> void:
	if not Game.flag(&"coeur_1") or Game.flag(&"voix_coeur_chant"):
		return
	S.lock(true)
	await S.wait(0.6)
	var singer = S.actor("VoixDuMarais")
	await S.say([
		Act.cue({"text": "Du cœur de la roselière, la Voix du Marais chante. Pas sa note grave de tous les soirs : une note ronde, joyeuse, qui roule sur l'eau jusqu'au temple."},
			func() -> void:
				cry("hadrosaure", "neutre", -12.0, OLD_PITCH + 0.06)
				if singer:   # the camera crosses the marsh to her
					await Act.pan((singer as Node2D).global_position, 1.6)
					Act.sing(singer, -99.0)),   # (her note already heard)
		Act.cue({"text": "Contre Chloé, dans la sacoche, le Cœur d'ambre bat un peu plus fort. Comme s'il répondait."},
			func() -> void:
				Stage.look_back()
				Act.heartbeat(Stage.chloe(), 3)),
		{"flag": &"voix_coeur_chant"},
	])
	S.lock(false)


# ------------------------------------------------------------------ Joss and the vest

## Joss at his stilt cabin (Npc « Joss », event joss_marais): the stolen vest the first time,
## then a line and questions (swimming, the Voix, the temple, Dame Suie…).
static func joss(who: Node) -> void:
	if not Game.flag(&"joss_marais_vu"):
		S.lock(true)
		await S.say(_joss_hello(who))
		Game.award_team_xp(XP_JOSS)
		Save.save_game()
		S.lock(false)
		return
	var line: String = DialogueDB.chatter(&"joss")[0]["text"]
	if not Game.flag(&"gilet_nage"):
		line = "Mon gilet ! Le Baryonyx joue avec sur le banc de sable, au milieu de la roselière. Par les pontons, puis la vase : ça se fait à pied !"
	elif swim_step() != "":
		line = swim_step()
	await _menu(&"joss", JOSS, line, joss_topics())


## (`who`: Joss. The thief is shown on its sandbank, far in the reeds, while he speaks of it.)
static func _joss_hello(who: Node) -> Array:
	var chloe_at: Vector2 = Stage.chloe().global_position
	var thief = S.actor("BaryonyxGilet")
	var lines: Array = [
		Act.cue({"text": "Sur le ponton de la cabane, un garçon ruisselant essore un gilet de cuir. Il a un roseau dans les cheveux, et il ne s'en est pas aperçu."},
			func() -> void:
				if is_instance_valid(who):
					Stage.tremble(who, 1.6, 1.6)
					Act.burst((who as Node2D).global_position, Act.SPLASH, 8, 0.9, 0.2)),
		Act.cue({"who": JOSS, "text": "Chloé ! Tu tombes à pic ! … Enfin, tu tombes bien. Moi, je suis tombé à pic. Dans l'eau. Trois fois."},
			func() -> void: Stage.hop(who, 1, 9.0)),
		{"who": JOSS, "text": "Ici, c'est mon atelier d'été : une cabane sur pilotis, et le Marais tout autour. Parfait pour tester mes gilets de nage."},
		Act.cue({"who": JOSS, "text": "Cuir huilé, flotteurs en liège, double couture au point sellier. Regarde ces coutures. Non, vraiment : regarde-les."},
			func() -> void: Stage.lunge(who, chloe_at, 0.6, false)),
		{"who": CHLOE, "text": "Elles sont… très droites."},
		{"who": JOSS, "text": "MERCI. Personne ne regarde jamais les coutures."},
		{"who": JOSS, "text": "Bref. Mon plus beau gilet, celui aux flotteurs rouges, je l'avais mis à sécher sur la rambarde. Et un jeune Baryonyx me l'a chipé !"},
		Act.cue({"who": JOSS, "text": "Les Baryonyx adorent tout ce qui flotte. Celui-là fait couler mon gilet, le regarde remonter, et recommence. Depuis ce matin."},
			func() -> void:
				if thief:
					Stage.turn_to(who, (thief as Node2D).global_position)
					await Act.pan((thief as Node2D).global_position, 1.4)
					Act.dunk(thief, 3)),
		{"who": JOSS, "text": "Il l'a emporté sur un banc de sable, au milieu de la roselière. Tu peux y aller à pied : les pontons, puis la vase. Enlève tes chaussettes."},
		Act.cue({"who": JOSS, "text": "Si tu me le rapportes, il est à toi. Je l'avais taillé pour Maïa, mais elle dit que les gilets, « c'est pour les poules mouillées »."},
			func() -> void:
				Stage.look_back()
				Stage.turn_to(who, chloe_at)),
		{"who": JOSS, "text": "Elle est passée ce matin. Elle a voulu traverser un chenal à pied. Elle est ressortie verte, et elle est partie vers le nord en faisant « splotch » à chaque pas."},
	]
	var swimmer: Dino = Game.ability_user(&"nage")
	if swimmer:
		lines.append({"who": JOSS, "text": "Oh, et tu as déjà un nageur : ton %s ! Avec un gilet sur le dos, tu pourrais traverser tout le Marais sur le sien." % swimmer.nickname})
	else:
		lines.append({"who": JOSS, "text": "Et si tu arrivais à attraper ce voleur avec un collier… Un Baryonyx, ça nage comme un poisson. Avec un gilet, tu pourrais traverser tout le Marais sur son dos !"})
	lines.append({"flag": &"joss_marais_vu"})
	return lines


## The young Baryonyx on its sandbank (DinoNpc « BaryonyxGilet »): a wild battle; beaten, it
## drops the vest; caught, it joins Chloé (the first swimmer). Joss comes running: the vest.
static func baryonyx(who: Node) -> void:
	if Game.flag(&"gilet_nage"):
		return
	if not Game.flag(&"baryonyx_gilet_vu"):
		S.lock(true)
		await S.say([
			Act.cue({"text": "Sur le banc de sable, un jeune Baryonyx joue dans l'eau peu profonde. Entre ses mâchoires, un gilet de cuir aux flotteurs rouges."},
				func() -> void:
					Stage.hop(who, 2, 8.0)
					Act.burst((who as Node2D).global_position, Act.SPLASH, 10, 0.2, 0.5)),
			Act.cue({"text": "Il le fait couler. Le gilet remonte. Il le refait couler. Le gilet remonte. Il a l'air absolument ravi."},
				func() -> void: Act.dunk(who, 2)),
			Act.cue({"who": CHLOE, "text": "C'est le gilet de Joss !"}, func() -> void: Stage.emote(Stage.chloe(), "!")),
			Act.cue({"text": "Le Baryonyx serre le gilet contre lui et gronde, pour la forme. Ses yeux disent surtout : « C'est à moi. Je l'ai trouvé. »"},
				func() -> void:
					Stage.turn_to(who, Stage.chloe().global_position)
					Stage.cry(who, &"neutre")
					Stage.rear(who, 0.9)),
			{"flag": &"baryonyx_gilet_vu"},
		])
		S.lock(false)
	var pick := await Dialogue.choose("", "Le jeune Baryonyx ne lâchera pas son jouet comme ça.", ["Récupérer le gilet", "Le laisser jouer encore un peu"])
	if pick != 0:
		return
	var foe := Dino.create(&"baryonyx", BARYONYX_LEVEL)
	var rules := {"lose_spawn": MARAIS_SPAWN, "size": BARYONYX_SIZE,
		"intro": "Le Baryonyx chapardeur lâche le gilet… et fonce sur toi en éclaboussant tout !"}
	if not Game.flag(&"baryonyx_lecon"):
		rules["lesson"] = ["Ce Baryonyx est jeune et sauvage : tu peux le capturer !",
			"Affaiblis-le d'abord, puis lance un collier d'ambre. Capturé, il nagera pour toi." if Game.item_count("collier") > 0
				else "Tu n'as plus de collier d'ambre. Bats-le, et il te rendra le gilet."]
	var result: String = await S.world().call(&"_battle", foe, rules)
	Game.set_flag(&"baryonyx_lecon")
	if result == "run":
		await S.say([Act.cue({"text": "Le Baryonyx ramasse le gilet et le refait couler, tout content. Il n'a pas l'air pressé de le rendre."},
			func() -> void: Act.dunk(who, 2))])
	if result != "win" and result != "catch":
		return
	await _vest_back(who, foe if result == "catch" else null)


## The vest back: the thief leaves (or joins Chloé as « Bouée »), Joss comes running and gives
## it to her, and explains La Nage.
static func _vest_back(who: Node, caught: Dino) -> void:
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	if caught:
		caught.nickname = BARYONYX_NAME
		Game.party_changed.emit()
		Game.set_flag(&"baryonyx_gilet_capture")
		await S.say([
			Act.cue({"text": "Le jeune Baryonyx s'ébroue, renifle Chloé… et va chercher le gilet pour le lui apporter. Il le pose à ses pieds, très fier."},
				func() -> void: _brings_vest(who)),
			{"who": CHLOE, "text": "Toi, tu aimes tout ce qui flotte. Je vais t'appeler %s." % BARYONYX_NAME},
		])
		await _fade_away(who, Vector2.ZERO)
	else:   # (it dives off while the line is read)
		await S.say([Act.cue({"text": "Le jeune Baryonyx lâche le gilet, pousse un grognement vexé et plonge dans le chenal. Plus loin, dans les roseaux, d'autres Baryonyx pêchent : il file les rejoindre."},
			func() -> void: _dives_off(who))])
	await S.say([Act.cue({"text": "Chloé repêche le gilet. Il est un peu mâchouillé. Sur une poche, une belle marque de dents."},
		func() -> void: Stage.bow(Stage.chloe(), 1.0))])
	# Joss comes running (he heard the splashes), on firm ground all the way: from a few steps
	# away on Chloé's own sandbank, else he is simply there, out of the mist, at her side.
	var chloe_at: Vector2 = w.player.global_position
	var start := Act.way_from(chloe_at, Vector2(-1.0, 0.3), 3.5, 5.5)
	var spot := S.ground_near(chloe_at + Vector2(-86.0, 22.0), 2)
	if start != Vector2.INF:
		spot = chloe_at + (start - chloe_at).normalized() * JOSS_GAP
	var helper := S.stranger("JossBanc", "joss", start if start != Vector2.INF else spot, "right")
	helper.modulate.a = 0.0
	Stage.fade_in(helper, 0.4)
	if start != Vector2.INF:
		await helper.walk_to(spot, "", 190.0)
	if is_instance_valid(helper):
		helper.face(chloe_at)
	var lines: Array = []
	if not Game.flag(&"joss_marais_vu"):
		lines.append_array([
			Act.cue({"who": JOSS, "text": "Chloé ?! Qu'est-ce que tu fais au Marais ? Tu as vu ? Tu l'as… MON GILET !"},
				func() -> void: Stage.hop(helper, 2, 10.0)),
			{"who": JOSS, "text": "J'ai une cabane sur pilotis, à l'entrée du Marais : j'y teste mes gilets de nage. Et ce petit voleur m'a chipé le plus beau."},
			{"flag": &"joss_marais_vu"},
		])
	else:
		lines.append(Act.cue({"who": JOSS, "text": "Tu l'as ! MON GILET ! J'ai couru sur tous les pontons en entendant le bruit !"},
			func() -> void: Stage.hop(helper, 2, 10.0)))
	lines.append_array([
		{"who": JOSS, "text": "Une marque de dents sur la poche… Bah. Ça lui donne du caractère."},
		{"who": JOSS, "text": "Garde-le. Il est à ta taille, et tu en auras plus besoin que Maïa. Elle, de toute façon, elle nage comme une enclume."},
		Act.cue({"text": "Chloé reçoit le gilet de nage de Joss !"}, func() -> void: Act.pop(w.player.global_position, "gilet_nage", 1.2)),
		{"flag": &"gilet_nage"},
	])
	await S.say(lines)
	Game.give_item("gilet_nage")
	Toast.say(w.get_tree(), "Objet obtenu : le gilet de nage")
	# While he speaks of them, the camera shows the Voix on her island, then Dame Suie on hers.
	var singer = S.actor("VoixDuMarais")
	var suie = S.actor("DameSuie")
	await S.say(_swim_lesson(caught) + [
		Act.cue({"who": JOSS, "text": "Au cœur de la roselière, sur un îlot, chante une vieille Parasaurolophus. Le soir, toutes mes aiguilles vibrent dans leur boîte. Mais une porte d'ambre ferme son îlot."},
			func() -> void:
				if singer:
					await Act.pan((singer as Node2D).global_position, 1.8)
					Act.sing(singer, -16.0)),
		Act.cue({"who": JOSS, "text": "Et sur l'îlot aux racines, il y a une dame très polie, en gris, avec une voilette, qui vient en barque cueillir des racines. Elle m'a demandé si je faisais des gilets pour Suchomimus."},
			func() -> void:
				if suie:
					Act.pan((suie as Node2D).global_position, 1.8)),
		Act.cue({"who": JOSS, "text": "J'ai dit que je réfléchissais. … Elle sent la cheminée froide, Chloé. Je n'aime pas trop."},
			func() -> void: Stage.look_back()),
		{"who": JOSS, "text": "Bon ! Je retourne à ma cabane. Si le gilet se découd, tu sais où me trouver. Il ne se découdra pas. Mais tu sais où me trouver."},
	])
	if start != Vector2.INF:   # back the way he came
		var fade: Tween = helper.create_tween()
		fade.tween_interval(0.4)
		fade.tween_property(helper, "modulate:a", 0.0, 0.6)
		await helper.walk_to(start, "", 160.0)
	else:
		await Stage.fade_out(helper, 0.6)
	if is_instance_valid(helper):
		helper.queue_free()
	Game.award_team_xp(XP_GILET)
	Save.save_game()
	S.lock(false)


## Caught, the young Baryonyx shakes the water off, then brings the vest to Chloé's feet, proud.
static func _brings_vest(who: Node) -> void:
	var chloe := Stage.chloe()
	if not is_instance_valid(who) or chloe == null:
		return
	Stage.tremble(who, 0.7, 2.5)
	Act.burst((who as Node2D).global_position, Act.SPLASH, 12, 0.8, 0.4)
	await S.wait(0.8)
	if not is_instance_valid(who):
		return
	var from_her: Vector2 = ((who as Node2D).global_position - chloe.global_position).normalized()
	await who.walk_to(chloe.global_position + from_her * 52.0, 90.0)
	if not is_instance_valid(who):
		return
	await Stage.bow(who, 0.8)
	Act.pop(chloe.global_position, "gilet_nage", 0.1)
	Stage.hop(who, 2, 8.0)


## Beaten, it drops the vest with a vexed grunt, walks into the channel, dives (a splash) and
## swims off to the other Baryonyx, fading away.
static func _dives_off(who: Node) -> void:
	if not is_instance_valid(who):
		return
	Stage.cry(who, &"neutre")
	await Stage.rear(who, 0.7)
	if not is_instance_valid(who):
		return
	var at: Vector2 = (who as Node2D).global_position
	var dive := Act.water_near(at + DIVE_OFF * 0.5, 2)
	if dive == at + DIVE_OFF * 0.5:   # (no water near: it just goes)
		dive = at + DIVE_OFF * 0.3
	await who.walk_to(dive, 90.0)
	if not is_instance_valid(who):
		return
	Act.burst(dive, Act.SPLASH, 40, Act.ON_WATER, 0.6)
	await _fade_away(who, dive - at)


## Joss explains La Nage, and who can carry Chloé in the water.
static func _swim_lesson(caught: Dino) -> Array:
	var lines: Array = [{"who": JOSS, "text": "Pour nager, il te faut aussi un dino nageur, adulte : niveau %d au moins. Tu avances dans l'eau profonde, et il te prend sur son dos. Tout seul. Toi, tu n'as qu'à ne pas lâcher." % Abilities.ADULT_LEVEL}]
	var swimmer: Dino = Game.ability_user(&"nage")
	if caught and Game.party.has(caught):
		lines.append({"who": JOSS, "text": "Et tu as %s ! Il est assez grand. Essaie donc : avance dans le chenal." % caught.nickname})
	elif caught:
		lines.append({"who": JOSS, "text": "%s est parti au Cabinet ? Ton équipe était pleine… Le professeur Roc peut te l'échanger contre un autre dino." % caught.nickname})
	elif swimmer:
		lines.append({"who": JOSS, "text": "Ton %s nage très bien, lui. Essaie : avance dans le chenal." % swimmer.nickname})
	else:
		lines.append({"who": JOSS, "text": "Les Baryonyx pêchent dans les roseaux, le jour. Un collier, un peu de patience… et tu auras ton nageur."})
	return lines


## A dino of the scene leaves: it moves by `by` (px) while it fades, then it is gone.
static func _fade_away(who: Node, by: Vector2) -> void:
	if not is_instance_valid(who):
		return
	var fade: Tween = who.create_tween()
	fade.tween_property(who, "modulate:a", 0.0, 0.8)
	if by != Vector2.ZERO:
		await who.walk_to((who as Node2D).global_position + by, 150.0)
	if fade.is_running():   # (a finished tween never sends « finished » again)
		await fade.finished
	if is_instance_valid(who):
		who.queue_free()


## What still keeps Chloé out of the deep water ("" when she can swim): the vest, a grown
## swimmer (in the party, or waiting at the Cabinet).
static func swim_step() -> String:
	if not Swim.has_vest():
		if Game.flag(&"joss_marais_vu"):
			return "Il te faut le gilet de Joss : le jeune Baryonyx joue avec, sur le banc de sable de la roselière."
		return "Il te faut un gilet de nage. Joss en coud justement, dans sa cabane sur pilotis, à l'entrée du Marais."
	if Swim.can_swim():
		return ""
	for d: Dino in Game.party:
		if Abilities.has(d, &"nage"):
			return "Ton %s est encore trop jeune pour te porter dans l'eau : il doit être adulte (niveau %d)." % [d.nickname, Abilities.ADULT_LEVEL]
	for d: Dino in Game.box:
		if Abilities.usable(d, &"nage"):
			return "Ton %s attend au Cabinet : lui te porterait dans l'eau. Le Pr Roc peut l'échanger contre un dino de ton équipe." % d.nickname
	return "Avec le gilet, il te faut un dino nageur adulte : les Baryonyx pêchent dans les roseaux du Marais, le jour. Affaiblis-en un, puis un collier !"


## Who could open the amber door of the Voix's islet ("" when a party dino can).
static func sing_step() -> String:
	if Game.ability_user(&"resonance"):
		return ""
	for d: Dino in Game.box:
		if Abilities.has(d, &"resonance"):
			return "Ton %s attend au Cabinet : sa crête ferait chanter l'ambre. Le Pr Roc peut te l'échanger." % d.nickname
	return "Il faut un dino dont la crête chante : un Corythosaurus de la roselière, un Iguanodon des rives, ou un Parasaurolophus."


# ------------------------------------------------------------------ the Voix du Marais

## The Voix du Marais (DinoNpc « VoixDuMarais », behind the amber door): the meeting (a
## reunion with Écho when he is Chloé's), then her song opens the sunken temple. Afterwards,
## a line at each visit (and the reunion, when Écho comes along later).
static func voix(who: Node) -> void:
	var echo := echo_dino()
	if Game.flag(&"voix_rencontree"):
		if echo and Game.party.has(echo) and not Game.flag(&"voix_echo_reconnu"):
			S.lock(true)
			await _voix_reunion(echo, who)
			Game.award_team_xp(XP_ANCIEN)
			Save.save_game()
			S.lock(false)
			return
		var cast := {}   # Écho out of her party for the line (cast « echo »), when he is not her lead
		await S.say([_voix_again(who, cast)])
		Act.echo_off_stage(cast.get("echo"))
		Act.lead_back()
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var song := {"on": false}   # she sings, a note now and then, until « Le chant s'arrête »
	await S.say([
		Act.cue({"text": "Au milieu de l'îlot, entre des nénuphars larges comme des tables, une très vieille Parasaurolophus chante, les yeux fermés."},
			func() -> void: Act.keep_singing(who, song)),
		{"text": "Sa crête est longue, pâlie comme du vieux cuivre. Ses écailles ont la couleur des roseaux en hiver. À chaque note, l'eau tremble, et les pierres d'ambre de l'îlot s'allument, tout doucement."},
		{"text": "Sur une pierre plate, quelqu'un a gravé un nom, avec une petite fougère : « La Voix »."},
		Act.cue({"text": "Le chant s'arrête. La vieille Parasaurolophus ouvre un œil."},
			func() -> void:
				song["on"] = false
				Stage.turn_to(who, w.player.global_position)),
	])
	song["on"] = false
	cry("hadrosaure", "neutre", -4.0, OLD_PITCH)
	if echo and Game.party.has(echo):
		await _voix_reunion(echo, who)
	elif echo:
		await _voix_smells_echo(echo, who)
	else:
		await _voix_wary(who)
	await _voix_opens_temple(who)
	Game.set_flag(&"voix_rencontree")
	Game.award_team_xp(XP_VOIX)
	Save.save_game()
	S.lock(false)


## Écho and his mother: the same note, sung together. When he is Chloé's own hatchling, the
## Ancien's page (in a copper tube, under the water lilies); when he is the stolen one, a
## lullaby until he stops trembling. +1 heart of Lien. (Écho walks up to her: Chloé's lead
## dino, or brought on for the scene when he is not her lead.)
static func _voix_reunion(echo: Dino, singer: Node) -> void:
	var w = S.world()
	var mine := str(Game.flag(&"starter")) == "parasaurolophus"
	var name := echo.nickname
	var little := Act.echo_on_stage(echo)
	var chloe_at: Vector2 = w.player.global_position
	var her_at: Vector2 = (singer as Node2D).global_position if is_instance_valid(singer) else chloe_at + Vector2(0.0, -90.0)
	# He stands before her head, on the side away from Chloé: face to face, Chloé looking on.
	var spot := her_at + Vector2(-BESIDE if chloe_at.x >= her_at.x else BESIDE, BESIDE_DOWN)
	var lines: Array = [
		Act.cue({"text": "%s passe devant Chloé. Il avance dans l'eau jusqu'aux genoux, lève sa crête… et chante. Une petite note, toute tremblante." % name},
			func() -> void: Act.echo_sings(little, spot, her_at)),
		Act.cue({"text": "La vieille Parasaurolophus se fige. Puis elle répond. La même note, exactement, mais plus grave, plus ronde, comme si elle l'enveloppait."},
			func() -> void:
				await S.wait(0.9)   # (frozen, first)
				if is_instance_valid(singer) and is_instance_valid(little):
					Stage.turn_to(singer, little.global_position)
				Act.sing(singer, -6.0)),
	]
	if not mine:
		lines.append(Act.cue({"text": "%s se met à trembler. Chez Brac, on ne lui a jamais chanté que des ordres. Alors la Voix baisse la tête jusqu'à lui et fredonne tout bas, une berceuse, encore et encore, jusqu'à ce qu'il arrête de trembler." % name},
			func() -> void: Act.lullaby(singer, little)))
	lines.append_array([
		Act.cue({"text": "Elle pose sa crête contre celle %s. Et elle ne bouge plus." % French.de(name)},
			func() -> void: Act.crest_to_crest(singer, little)),
		{"who": CHLOE, "text": "Tu le reconnais… C'est ton petit. Tu es sa maman."},
	])
	await S.say(lines)
	if little is Companion:
		(little as Companion).rejoice()
	elif is_instance_valid(little):
		Stage.hop(little, 2, 10.0)
	cry("hadrosaure", "neutre", -6.0, OLD_PITCH)
	cry("hadrosaure", "neutre", -9.0, 1.0)
	var after: Array = []
	if not mine:
		after.append({"who": CHLOE, "text": "On te l'avait volé. Nourri à l'ambre noir, loin de tout. Mais il est là, maintenant."})
	if not Game.flag(&"found_journal_ancien_voix"):
		after.append_array(_ancien_page(singer))
	after.append_array([
		Act.cue({"text": "Du bout du museau, la Voix pousse doucement %s vers Chloé. Il a une maman qui chante ; il a aussi une Chloé." % name},
			func() -> void: Act.nudged_back(singer, little)),
		{"who": CHLOE, "text": "Je veillerai sur lui. Promis. Et on reviendra chanter avec toi."},
		{"flag": &"voix_echo_reconnu"},
	])
	await S.say(after)
	Act.echo_off_stage(little)
	Game.add_bond(echo, 1)


## The Ancien's page: a copper tube sealed with wax, fished out from under the water lilies.
static func _ancien_page(singer: Node) -> Array:
	return [
		Act.cue({"text": "La Voix plonge la tête sous les nénuphars et en ressort un petit tube de cuivre, tout vert de vieillesse, bouché à la cire. Elle le laisse tomber aux pieds de Chloé."},
			func() -> void: Act.fishes_tube(singer)),
		Act.cue({"text": "Sur la cire, de l'écriture penchée d'Hélène : « Pour Chloé. Elle te la donnera. »"},
			func() -> void:
				var tube = S.actor("TubeVoix")
				if tube:
					Stage.take_thing(tube)   # (she picks it up)
				else:
					Stage.bow(Stage.chloe(), 1.0)),
		{"letter": VOIX_PAGE, "sign": "— H."},
		{"flag": &"found_journal_ancien_voix"},
	]


## Écho is Chloé's but waits at the Cabinet: she smells him on Chloé's hands (the page too).
static func _voix_smells_echo(echo: Dino, singer: Node) -> void:
	var lines: Array = [
		Act.cue({"text": "La vieille Parasaurolophus s'approche de Chloé et renifle ses mains, longtemps. Celles qui caressent %s chaque soir." % echo.nickname},
			func() -> void: Act.sniffs(singer, 1.8)),
		Act.cue({"text": "Elle chante une note, tout bas. Puis elle regarde derrière Chloé, comme si elle cherchait quelqu'un."},
			func() -> void: Act.looks_for_him(singer)),
		{"who": CHLOE, "text": "Tu sens son odeur sur moi… Tu es la maman %s. Il est au Cabinet, bien au chaud. Je te le ramènerai." % French.de(echo.nickname)},
	]
	if str(Game.flag(&"starter")) == "parasaurolophus" and not Game.flag(&"found_journal_ancien_voix"):
		lines.append_array(_ancien_page(singer))
	await S.say(lines)


## No Écho with Chloé: the Voix does not know her, but she smells of Hélène (the pages).
static func _voix_wary(singer: Node) -> void:
	var chloe_at: Vector2 = Stage.chloe().global_position
	var lines: Array = [
		Act.cue({"text": "La Voix baisse la tête vers Chloé. Ses naseaux frémissent. Elle ne gronde pas : elle écoute, comme si Chloé était une note qu'elle ne connaissait pas encore."},
			func() -> void:
				Stage.bow(singer, 1.6)
				Stage.tremble(singer, 1.0, 1.0)),
		Act.cue({"text": "Puis elle plonge le museau dans la sacoche aux pages du journal, et ferme les yeux. Le vieux papier, l'encre, l'ambre. L'odeur d'Hélène."},
			func() -> void: Act.lean(singer, chloe_at, 10.0, 1.8)),
		{"who": CHLOE, "text": "Tu la connaissais… Tu es un de ses dinos, toi aussi. La Voix du Marais."},
	]
	var lead := Game.lead_dino()
	if lead:
		lines.append(Act.cue({"text": "%s s'approche, un peu intimidé. La Voix lui souffle dessus, doucement, comme on souffle sur une soupe trop chaude. C'est un oui." % lead.nickname},
			func() -> void: Act.shy_hello(singer)))
	var mine: Dino = Foret.starter()
	if mine and str(Game.flag(&"starter")) == "ankylosaurus":
		lines.append({"who": CHLOE, "text": "(La mère %s, le Vieux Rempart, attend quelque part dans le Désert. Elle aussi, elle reconnaîtra son petit ?)" % French.de(mine.nickname)})
	await S.say(lines)
	Act.lead_back()


## She turns towards the sunken temple and sings: the note crosses the marsh (the camera with
## it), far away the temple's great stone door glows and fades (the flag, at the end, opens it
## for good; see regions/marais/porte_temple.gd).
static func _voix_opens_temple(who: Node) -> void:
	var temple = S.actor("PorteTemple")
	var door_at: Vector2 = (temple as Node2D).global_position if temple else S.at(30.0, 11.6)
	if is_instance_valid(who):   # towards the temple (on the map, west of her island)
		who.sprite.flip_h = door_at.x < (who as Node2D).global_position.x
	await S.say([Act.cue({"text": "La Voix se détourne, vers l'endroit où la brume est la plus épaisse : là-bas, dans l'eau, dort le temple englouti. Elle gonfle sa gorge, lève sa crête… et chante."},
		func() -> void:
			Stage.rear(who, 1.6)
			await S.wait(0.7)
			Act.sing(who, 0.0))])
	await S.say([Act.cue({"text": "La note roule sur l'eau, traverse la roselière et va se cogner, très loin, contre des murs de pierre. Le Marais entier retient son souffle."},
		func() -> void:
			cry("hadrosaure", "neutre", -6.0, OLD_PITCH - 0.04)
			Act.pan(door_at, 3.2))])
	var lines: Array = [
		Act.cue({"text": "Puis, du fond de la brume, un grondement lui répond : le bruit d'une énorme porte de pierre qui glisse, lentement, lentement."},
			func() -> void: _door_opens(temple)),
		Act.cue({"who": CHLOE, "text": "Le temple englouti… Tu viens de l'ouvrir. Pour moi ?"}, func() -> void: Stage.look_back()),
		Act.cue({"text": "La Voix baisse sa crête vers Chloé. Il y a longtemps, elle a sûrement chanté ce chant-là pour Hélène."},
			func() -> void:
				Stage.turn_to(who, Stage.chloe().global_position)
				Stage.bow(who, 1.4)),
	]
	if Game.flag(&"found_journal_13"):
		lines.append({"who": CHLOE, "text": "(« Le Spinosaure… le premier Cœur. » Il est là-dessous, alors.)"})
	lines.append({"flag": &"temple_ouvert"})
	await S.say(lines)


## The temple's door, far away, answers the song: a rumble, and it glows and fades away.
static func _door_opens(temple: Node) -> void:
	Audio.play_sfx(preload("res://assets/audio/sfx/rock_heavy.wav"), -8.0)
	Stage.shake(3.0, 0.8)
	if temple == null or not is_instance_valid(temple):
		return
	await Stage.look_at((temple as Node2D).global_position, 0.8)   # (there, even if the line before was hurried)
	if not is_instance_valid(temple):
		return
	await Stage.glow(temple, Act.AMBER_GLOW, 1, 1.0)
	Act.sink(temple, DOOR_SLIDE_S, true)   # it slides down into the ground, slowly
	for i in 3:
		await S.wait(DOOR_SLIDE_S / 3.0)
		Stage.shake(1.5, 0.4)


## A line at each visit, acted out (a note sung, a sniff, a look towards the temple…). Écho, when
## a line shows him, is brought out of her party for it (cast « echo »: echo_off_stage after).
static func _voix_again(singer: Node, cast: Dictionary) -> Dictionary:
	var echo := echo_dino()
	if Game.flag(&"coeur_1") and not Game.flag(&"voix_apres_coeur"):
		Game.set_flag(&"voix_apres_coeur")
		return Act.cue({"text": "La Voix renifle la sacoche de Chloé, là où bat le Cœur d'ambre. Elle chante une note ronde, joyeuse. Le Spinosaure l'a entendue, sûrement."},
			func() -> void:
				Act.heartbeat(Stage.chloe(), 2)
				await Act.sniffs(singer, 0.8)
				Act.sing(singer, -8.0, OLD_PITCH + 0.06))
	if Game.phase() == &"night":
		return Act.cue({"text": "La nuit, la Voix chante pour la lune. Tout bas. Les pierres d'ambre de l'îlot lui répondent, une à une."},
			func() -> void: Act.sing(singer, -14.0))
	var n := int(Game.flag(&"voix_n"))
	Game.set_flag(&"voix_n", n + 1)
	if echo and Game.party.has(echo) and Game.flag(&"voix_echo_reconnu"):
		var k := n % VOIX_AGAIN_ECHO.size()
		return Act.cue({"text": (VOIX_AGAIN_ECHO[k] as String).replace("{de}", French.de(echo.nickname)).replace("%s", echo.nickname)},
			func() -> void: _with_echo_again(singer, k, echo, cast))
	if echo and not Game.party.has(echo):
		return Act.cue({"text": "La Voix renifle les mains de Chloé, puis regarde derrière elle. Elle cherche %s." % echo.nickname},
			func() -> void:
				await Act.sniffs(singer, 0.8)
				Act.looks_for_him(singer))
	var j := n % VOIX_AGAIN.size()
	return Act.cue({"text": VOIX_AGAIN[j]}, func() -> void: _alone_again(singer, j))


## VOIX_AGAIN[k] acted out: singing low, sniffing the bag, a note towards the temple.
static func _alone_again(singer: Node, k: int) -> void:
	match k:
		0:
			Act.sing(singer, -14.0)
		1:
			Act.sniffs(singer, 1.2)
		2:
			if is_instance_valid(singer):
				Stage.turn_to(singer, S.at(30.0, 11.6))
			Act.sing(singer, -10.0, OLD_PITCH - 0.04)


## VOIX_AGAIN_ECHO[k] acted out, Écho at Chloé's side (her lead) or brought out of her party for
## the line (cast « echo »): singing together, a nuzzle, asleep against his mother (the lead
## comes back to Chloé after the line: lead_back).
static func _with_echo_again(singer: Node, k: int, echo: Dino, cast: Dictionary) -> void:
	var w = S.world()
	var little: Node2D = w.companion if Game.lead_dino() == echo else Act.echo_on_stage(echo)
	if not little is Companion:
		cast["echo"] = little
	match k:
		0:
			Act.sing(singer, -10.0)
			await S.wait(0.5)
			Act.little_note(little)
		1:
			if is_instance_valid(singer) and is_instance_valid(little):
				Act.lean(singer, little.global_position, 10.0, 1.4)
		2:
			if is_instance_valid(singer) and is_instance_valid(little):
				var her_at: Vector2 = (singer as Node2D).global_position
				var side := -44.0 if her_at.x > little.global_position.x else 44.0
				if little is Companion:
					await Act.walk_lead(her_at + Vector2(side, 18.0), 70.0)
				else:
					await (little as DinoNpc).walk_to(her_at + Vector2(side, 18.0), 70.0)
				if is_instance_valid(little):
					Stage.bow(little, 2.4)


# ------------------------------------------------------------------ Joss, at Havre-Doré

## Joss at his saddlery once chapter 3 is open: he goes back and forth to his cabin in the
## Marais (a line, then the questions of the moment).
static func joss_havre() -> void:
	var pool: Array = [
		"Tu vas au Marais ? J'ai une cabane sur pilotis, à l'entrée : c'est là que je teste mes gilets de nage. J'y retourne dès que j'ai fini cette sangle !",
		"Un gilet de nage, c'est du cuir huilé et du liège. Et de la patience. Surtout de la patience.",
	]
	if Game.flag(&"gilet_nage"):
		pool = [
			"Il tient bien, le gilet ? Si tu entends « couic » en nageant, c'est normal : c'est le liège qui est content.",
			"Je fais l'aller-retour entre la Sellerie et ma cabane du Marais. Mes semelles n'en peuvent plus.",
			"Un jour, je coudrai un gilet pour un Spinosaure. Il me faudra trois mois, et beaucoup de liège.",
		]
	var n := int(Game.flag(&"joss_havre_n"))
	Game.set_flag(&"joss_havre_n", n + 1)
	await _menu(&"joss", JOSS, pool[n % pool.size()], [&"monter"] + joss_topics())


## The questions Chloé may ask Joss (in the Marais and at the Havre): those of the moment
## (Ask.story_topics) that are about the Marais, and where to go.
static func joss_topics() -> Array:
	return Ask.story_topics().filter(func(t: StringName) -> bool:
		return t in [&"suite", &"nage", &"chanter", &"voix", &"temple", &"suie", &"roc_nuit"])


## A line, then the questions (just the line when there are none).
static func _menu(npc: StringName, speaker: String, line: String, topics: Array) -> void:
	if topics.is_empty():
		await S.say([{"who": speaker, "text": line}])
		return
	await Ask.menu(npc, speaker, line, topics)


# ------------------------------------------------------------------ helpers

## Chloé's Parasaurolophus from the Cabinet (the Voix's little one): her own hatchling when she
## chose Écho, or the stolen one, found again in the Forêt; null otherwise.
static func echo_dino() -> Dino:
	if str(Game.flag(&"starter")) == "parasaurolophus":
		return Foret.starter()
	if ForetCamp.stolen_species() == &"parasaurolophus":
		return ForetCamp.recovered()
	return null


## A dino's call, not tied to anyone on screen (the Voix far away…): `prefix` is the cries'
## family (hadrosaure, spino…), quieter when far, lower when old.
static func cry(prefix: String, kind: String, volume_db: float, pitch := 1.0) -> void:
	var w = S.world()
	var path := CRY % [prefix, kind]
	if w == null or not ResourceLoader.exists(path):
		return
	var p := AudioStreamPlayer.new()
	p.bus = &"SFX"
	p.stream = load(path)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	w.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
