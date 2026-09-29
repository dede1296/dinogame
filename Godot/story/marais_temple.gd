class_name MaraisTemple
## Chapter 3, the sunken temple of the Marais (zone temple_englouti; docs/histoire.md, ch. 3):
## opened by the Voix du Marais's song. Its galleries are flooded to the ceiling: three stone
## sluices, turned one after the other (the lead dino helps), drain the west gallery, then the
## east one, then the stairs to the great hall (Flood nodes: dry_flag temple_vanne_1 … 3).
## Three frescoes of the island's first people, who wore bone masks to honour the sleeping
## giants (the Ombre Noire stole the symbol); page 12 (a Pickup). In the great hall, the
## Spinosaure Ancestral: a battle of honour, then the Sceau du Marais and the first Heart.
## Flags: temple_arrive, temple_vanne_1 … 3, fresque_1_vue … 3_vue, fresques_vues,
## spinosaure_parle, spinosaure_battu, sceau_marais, coeur_1; fresque_n (lines).
## The lines are acted out (story/stage.gd, story/marais_stage.gd): the camera shows the
## flooded galleries, each one draining, the altar where the Heart beats; the Spinosaure
## surges from its pool, roars, bows, sinks back.

const S := preload("res://story/story.gd")
const Act := preload("res://story/marais_stage.gd")
const CHLOE := "Chloé"
const ALPHA_MUSIC := "res://assets/audio/music/alpha.ogg"
const GATES := preload("res://assets/audio/sfx/rock_heavy.wav")
## Where a lost battle takes Chloé back to: the temple's way in.
const TEMPLE_SPAWN := &"DepuisMarais"
## The Spinosaure Ancestral: level checked by simulation (scratchpad/sim_marais.gd).
const SPINO_LEVEL := 22
## Its size, share of an adult Spinosaurus (its DinoNpc in the temple: tools/zones/temple_englouti.gd).
const SPINO_SIZE := 1.25
const SPINO_NAME := "Spinosaure Ancestral"
## Its voice: a spinosaurid's call, very deep.
const SPINO_PITCH := 0.7
## The flood drains in Flood.DRAIN_S (2.8 s): the scene lets it be seen.
const DRAIN_WAIT := 1.6
const XP_ARRIVE := 20
const XP_VANNE := 25
const XP_FRESQUE := 15
const XP_FRESQUES := 40
const XP_SPINO := 100
## What each sluice says once it has been turned (by number).
const VANNE_DONE := {
	1: "La première vanne est grande ouverte. Dans la galerie ouest, il ne reste que des flaques.",
	2: "La deuxième vanne est ouverte. L'eau gargouille quelque part, très loin sous les dalles.",
	3: "La dernière vanne est ouverte. L'escalier de la grande salle est à sec.",
}
const FRESQUE_AGAIN := [
	"Chloé passe le doigt sur la peinture ocre. Elle est là depuis si longtemps qu'elle fait partie de la pierre.",
	"Dans la lumière de l'eau, les masques d'os de la fresque ont l'air de sourire.",
	"Tout en bas de la fresque, une toute petite main peinte en noir. Quelqu'un a signé, il y a très, très longtemps.",
]
## Places the camera shows (tiles; tools/zones/temple_englouti.gd): the middle of each flood
## (Crue1 the west gallery's way, Crue2 the east one's, Crue3 the stairs), the second sluice,
## the top of the stairs (the great hall's door), the altar.
const FLOOD_AT := {1: Vector2(8.0, 20.0), 2: Vector2(32.0, 20.0), 3: Vector2(20.0, 13.0)}
const HALL_DOOR := Vector2(20.0, 10.0)
const ALTAR := Vector2(19.5, 3.1)
## Air rising through the flooded stairs (bubbles): their colours, how high the water is (m).
const BUBBLES: Array[Color] = [Color(0.8, 0.95, 1.0), Color(0.62, 0.86, 0.95)]
const FLOOD_TOP := 1.15
## The dinos drink at the pool this far from its water (px).
const POOL_EDGE := 34.0
const HEART_GOLD := Color(1.0, 0.86, 0.45, 0.85)
## The Spinosaure goes back down into its pool in this long (s).
const SINK_S := 2.4


# ------------------------------------------------------------------ arriving

## The first time in the temple: stairs down into the half-dark, a hall of columns, flooded
## galleries on both sides, a stone wheel in the wall. Chloé understands: drain them one by one.
static func arrival() -> void:
	if Game.flag(&"temple_arrive"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.7)
	var chloe_at: Vector2 = w.player.global_position
	await S.say([
		{"text": "Derrière la grande porte, un escalier de pierre descend dans la pénombre. L'air est frais, humide, et chaque goutte qui tombe résonne longtemps, comme dans une église."},
		Act.cue({"text": "Le hall du temple. Des colonnes couvertes de coquillages, une grande statue de Spinosaure… et de l'eau. Les galeries de gauche et de droite sont noyées jusqu'au plafond."},
			func() -> void: Act.tour([_px(FLOOD_AT[1]), _px(FLOOD_AT[2])], 1.3, 0.7)),
		Act.cue({"text": "Au-dessus de l'entrée, des dizaines de petits masques d'os sont sculptés dans la pierre. Des becs, des crêtes, des cornes."},
			func() -> void:
				Stage.look_back()
				Stage.turn_to(Stage.chloe(), chloe_at + Vector2(0.0, 100.0))),
		{"who": CHLOE, "text": "(Des masques d'os… Ici aussi ?)"},
	])
	var lead := Game.lead_dino()
	if lead:
		await S.say([Act.cue({"text": "%s renifle le courant d'air qui monte de l'escalier du fond, noyé lui aussi. Là-dessous, sous l'eau, quelque chose respire. Lentement." % lead.nickname},
			func() -> void: _sniffs_the_stairs())])
	var wheel = S.actor("Vanne1")
	await S.say([
		Act.cue({"text": "Contre le mur du hall, une grande roue de pierre, à moitié mangée par la mousse. Au-dessus, des traits gravés montrent l'eau qui passe d'une salle à l'autre, comme dans des bassins."},
			func() -> void:
				if wheel:
					Stage.turn_to(Stage.chloe(), (wheel as Node2D).global_position)
					Stage.look_at_actor(wheel)
					Stage.glow(wheel, Act.AMBER_GLOW, 2, 1.2)),
		Act.cue({"who": CHLOE, "text": "(Une vanne… Si je la tourne, l'eau d'une galerie s'en ira. Trois galeries noyées : il faut les vider une par une.)"},
			func() -> void: Stage.look_back()),
		{"flag": &"temple_arrive"},
	])
	Game.award_team_xp(XP_ARRIVE)
	Save.save_game()
	S.lock(false)


## The lead dino turns to the flooded stairs and sniffs; the camera goes there: slow bubbles
## rise through the water, something breathes below.
static func _sniffs_the_stairs() -> void:
	var stairs := _px(FLOOD_AT[3])
	var c := Act.lead()
	if c:
		Stage.turn_to(c, stairs)
		Stage.bow(c, 1.4)
	await Stage.look_at(stairs, 1.0)
	for i in 2:
		Act.burst(stairs, BUBBLES, 5, FLOOD_TOP, 0.4)
		await S.wait(1.3)


# ------------------------------------------------------------------ the sluices

## Sluice `n` (StoryProp « Vanne1 » … « Vanne3 »): Chloé and her lead dino turn it; the flood it
## holds back drains before their eyes (1: the west gallery; 2: the east one; 3: the stairs).
static func vanne(n: int, who: Node) -> void:
	var flag := StringName("temple_vanne_%d" % n)
	if Game.flag(flag):
		await S.say([{"text": VANNE_DONE.get(n, "La vanne est ouverte.")}])
		return
	if n > 1 and not Game.flag(StringName("temple_vanne_%d" % (n - 1))):
		await S.say([{"text": "La roue ne bouge pas d'un pouce : de l'autre côté, l'eau pousse trop fort. Il faudrait d'abord vider la galerie d'avant."}])
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.say(_before(n, who))
	await S.say([Act.cue({"text": _push_help()}, func() -> void: _turn_wheel(who))])
	Audio.play_sfx(GATES, -2.0)
	Stage.shake(4.0, 0.6)
	await Stage.look_at(_px(FLOOD_AT[n]), 0.6)   # the camera on the flood as it drains
	Game.set_flag(flag)   # the Flood behind it drains now
	await S.wait(DRAIN_WAIT)
	await S.say(_after(n))
	Game.award_team_xp(XP_VANNE)
	Save.save_game()
	S.lock(false)


## (`wheel`: the sluice. The camera follows the line engraved from it to what it drains.)
static func _before(n: int, wheel: Node) -> Array:
	match n:
		1:
			return [
				Act.cue({"text": "La grande roue de pierre. Un trait gravé part de la roue et file vers la galerie ouest."},
					func() -> void: Act.pan(_px(FLOOD_AT[1]), 1.2)),
				Act.cue({"text": "À côté, quelqu'un a gravé une petite flèche, beaucoup plus récente. Et un « H. »."},
					func() -> void:
						Stage.look_back()
						if is_instance_valid(wheel):
							Act.lean(Stage.chloe(), (wheel as Node2D).global_position, 8.0, 1.6)),
				{"who": CHLOE, "text": "(Hélène est passée par là. Allez… on tourne !)"},
			]
		2:
			return [
				Act.cue({"text": "Au bout de la galerie ouest, une deuxième roue, plus petite. Son trait gravé repart vers l'est, de l'autre côté du hall."},
					func() -> void: Act.pan(_px(FLOOD_AT[2]), 2.0)),
				Act.cue({"who": CHLOE, "text": "(Celle-ci doit vider la galerie est.)"}, func() -> void: Stage.look_back()),
			]
	return [
		Act.cue({"text": "La troisième roue, au bout de la galerie est. Son trait gravé descend vers l'escalier de la grande salle… et s'arrête sur un dessin : un Spinosaure, la voile dressée."},
			func() -> void: Act.pan(_px(FLOOD_AT[3]), 1.6)),
		Act.cue({"who": CHLOE, "text": "(La dernière. Après, plus rien entre moi et… lui.)"}, func() -> void: Stage.look_back()),
	]


## (The camera is on the flood as it drains; then on what comes next.)
static func _after(n: int) -> Array:
	match n:
		1:
			var next = S.actor("Vanne2")
			return [
				Act.cue({"text": "Un grondement sourd roule sous les dalles. Dans la galerie ouest, l'eau se met à tourner, à gargouiller… et elle baisse ! Elle s'en va par des trous dans le sol, avec un bruit de baignoire géante."},
					func() -> void: Stage.shake(2.0, 0.8)),
				Act.cue({"who": CHLOE, "text": "(La galerie ouest est libre ! Et au bout, on dirait… une autre roue.)"},
					func() -> void:
						if next:
							Act.pan((next as Node2D).global_position, 1.4)
							Stage.glow(next, Act.AMBER_GLOW, 2, 1.2)),
			]
		2:
			return [
				Act.cue({"text": "Le grondement recommence, plus loin. De l'autre côté du hall, la galerie est se vide à son tour, dans un long glouglou."},
					func() -> void: Stage.shake(2.0, 0.8)),
				Act.cue({"who": CHLOE, "text": "(Chaque vanne vide la galerie suivante. Comme des bassins qui se passent l'eau !)"},
					func() -> void: Stage.look_back()),
			]
	var spino = S.actor("Spinosaure")
	return [
		Act.cue({"text": "Cette fois, tout le temple tremble. L'eau de l'escalier descend, marche après marche, jusqu'à découvrir une grande porte ouverte. Et derrière, un souffle. Lent. Énorme."},
			func() -> void:
				Stage.shake(5.0, 1.2)
				await S.wait(1.4)
				Act.pan(_px(HALL_DOOR), 1.4)
				if spino:
					Stage.rear(spino, 2.2)),
		Act.cue({"who": CHLOE, "text": "(Il y a quelqu'un, en bas. Quelqu'un de très grand.)"}, func() -> void: Stage.look_back()),
	]


## Chloé pushes, her lead dino pulls or pushes with her (its move, its cry), the wheel shakes.
static func _turn_wheel(wheel: Node) -> void:
	if not is_instance_valid(wheel):
		return
	var at: Vector2 = (wheel as Node2D).global_position
	var c := Act.lead()
	if c:
		c.perform_at(at)
	Stage.lunge(Stage.chloe(), at, 0.8, false)
	await S.wait(0.35)
	if is_instance_valid(wheel):
		Stage.tremble(wheel, 1.4, 2.0)


## How the lead dino helps turn the wheel, by what it is.
static func _push_help() -> String:
	var lead := Game.lead_dino()
	if lead == null:
		return "Chloé pousse de toutes ses forces. La roue grince… et tourne !"
	match lead.species().family:
		&"raptor":
			return "%s bondit sur un rayon de la roue et tire de tout son poids. Avec Chloé qui pousse, la roue grince… et tourne !" % lead.nickname
		&"armored":
			return "%s cale sa tête contre la roue et pousse, pousse… La pierre grince, et la roue tourne !" % lead.nickname
		&"hadrosaur":
			return "%s appuie son épaule contre la roue. Chloé pousse avec lui. Un, deux… trois ! La roue tourne !" % lead.nickname
		&"spino":
			return "%s attrape un rayon entre ses mâchoires et tire, comme un pêcheur sur sa ligne. La roue tourne !" % lead.nickname
	return "%s pousse avec Chloé. La roue grince… et tourne !" % lead.nickname


# ------------------------------------------------------------------ the frescoes

## Fresco `n` (StoryProp « Fresque1 » … « Fresque3 »), one per room: the first people of the
## island, their bone masks, the giant they honoured. Once all three are seen, Chloé
## understands: the Ombre Noire stole their symbol.
static func fresque(n: int, who: Node) -> void:
	var seen := StringName("fresque_%d_vue" % n)
	if Game.flag(seen):
		var k := int(Game.flag(&"fresque_n"))
		Game.set_flag(&"fresque_n", k + 1)
		await S.say([_fresco_again(k % FRESQUE_AGAIN.size(), who)])
		return
	S.lock(true)
	var lines: Array = _fresco_lines(n, who)
	lines.append({"flag": seen})
	await S.say(lines)
	Game.award_team_xp(XP_FRESQUE)
	if _frescoes_seen() == 3 and not Game.flag(&"fresques_vues"):
		var end: Array = [
			{"who": CHLOE, "text": "(Pour les gens du temple, un masque d'os, c'était une promesse : « nous veillons sur vous ». Une façon de dire merci aux géants endormis.)"},
			{"who": CHLOE, "text": "(Et l'Ombre Noire porte les mêmes masques… pour faire peur. Pour voler les dinos. Ils ont volé le symbole.)"},
		]
		if Game.flag(&"found_journal_12"):
			end.append({"who": CHLOE, "text": "(« Ce ne sont pas des souvenirs : ce sont des promesses », écrivait Hélène.)"})
		end.append({"flag": &"fresques_vues"})
		await S.say(end)
		Game.award_team_xp(XP_FRESQUES)
	Save.save_game()
	S.lock(false)


## (`fresco`: the painted wall, whose amber shines when the lines speak of it.)
static func _fresco_lines(n: int, fresco: Node) -> Array:
	match n:
		1:
			return [
				{"text": "Une fresque peinte sur la pierre, en ocre et en noir. Des gens assis en cercle autour d'un énorme bloc d'ambre. Dedans, une silhouette de géant dort, roulée en boule."},
				Act.cue({"text": "Tous portent des masques d'os taillés en têtes de dinos : un bec, une crête, des cornes. Au-dessus d'eux, la lune est pleine, et le bloc d'ambre brille."},
					func() -> void: Stage.glow(fresco, Act.AMBER_GLOW, 2, 1.3)),
				{"who": CHLOE, "text": "(Des masques d'os… comme l'Ombre Noire. Mais eux, ils ne font pas peur. On dirait qu'ils… veillent.)"},
			]
		2:
			var lines: Array = [
				{"text": "Toute la paroi est peinte. Un squelette immense, une voile d'épines sur le dos, couché au fond d'un bassin. Autour, les gens du temple déposent des poissons et des fleurs d'eau."},
				{"text": "Un enfant, avec un tout petit masque de Spinosaure, pose sa main sur un os. Doucement. Comme on caresse un chien qui dort."},
				{"who": CHLOE, "text": "(Ils ont bâti le temple autour de lui… pour qu'il dorme tranquille.)"},
			]
			var lead := Game.lead_dino()
			if lead and lead.species().family == &"spino":
				lines.append(Act.cue({"text": "%s regarde la fresque longtemps, sans bouger. Le grand dino à voile a un air de famille." % lead.nickname},
					func() -> void:
						var c := Act.lead()
						if c and is_instance_valid(fresco):
							Stage.turn_to(c, (fresco as Node2D).global_position)
							Stage.emote(c, "…")))
			return lines
	return [
		{"text": "La dernière fresque. Le volcan crache une longue fumée noire. Les gens du temple montent dans des barques et partent sur la mer."},
		{"text": "Sur les marches du temple, ils ont laissé leurs masques d'os, tous tournés vers le bassin du géant. Comme pour dire : « On ne vous oublie pas. »"},
		{"who": CHLOE, "text": "(Ils sont partis… mais ils ont laissé leurs masques aux géants.)"},
	]


## A fresco seen again: FRESQUE_AGAIN[k], acted out (a finger on the paint, the water's light).
static func _fresco_again(k: int, fresco: Node) -> Dictionary:
	return Act.cue({"text": FRESQUE_AGAIN[k]}, _looks_again.bind(k, fresco))


static func _looks_again(k: int, fresco: Node) -> void:
	if not is_instance_valid(fresco):
		return
	match k:
		0:
			Act.lean(Stage.chloe(), (fresco as Node2D).global_position, 10.0, 1.4)
		1:
			Stage.glow(fresco, Color(1.2, 1.35, 1.5), 1, 1.6)


static func _frescoes_seen() -> int:
	var n := 0
	for i in [1, 2, 3]:
		if Game.flag(StringName("fresque_%d_vue" % i)):
			n += 1
	return n


# ------------------------------------------------------------------ the Spinosaure Ancestral

## The Spinosaure Ancestral in the great hall (DinoNpc « Spinosaure »): not corrupted, it tests
## Chloé (a battle of honour: no collar, no running away). Won: it bows its sail, gives the
## Sceau du Marais, then pushes the first Heart of amber to her from the altar.
static func spinosaure(who: Node) -> void:
	if Game.flag(&"sceau_marais"):
		return
	if not Game.flag(&"spinosaure_battu"):
		if not Game.flag(&"spinosaure_parle"):
			S.lock(true)
			await _spino_rises(who)
			Game.set_flag(&"spinosaure_parle")
			S.lock(false)
		var pick := await Dialogue.choose("", "Le Spinosaure Ancestral attend, sa voile dressée au-dessus de l'eau. Il veut voir ce que vaut l'héritière d'Hélène.",
			["Relever le défi", "Pas encore"])
		if pick != 0:
			return
		await _drink()
		var foe := Dino.create(&"spinosaurus", SPINO_LEVEL, SPINO_NAME)
		var rules := {"catch": false, "run": false, "lose_spawn": TEMPLE_SPAWN, "size": SPINO_SIZE,
			"intro": "Le Spinosaure Ancestral se dresse de toute sa hauteur ! (Combat d'honneur : pas de collier, pas de fuite.)",
			"lesson": ["Le Spinosaure est un dino de l'Eau : les attaques du Vent le touchent fort. Ses crocs brûlants, eux, font mal aux dinos Nature et Vent."]}
		var theme: AudioStream = ForetCamp.music_at(ALPHA_MUSIC)
		if theme:
			rules["music"] = theme
		var result: String = await S.world().call(&"_battle", foe, rules)
		if result != "win":
			return
		Game.set_flag(&"spinosaure_battu")
	await _trust(who)


## A battle of honour is fought rested: it waits while Chloé's dinos drink at its pool (the
## party is healed, when it needs to be). Her lead dino goes to drink, then comes back.
static func _drink() -> void:
	var tired := Game.party.any(func(d: Dino) -> bool: return d.hp < d.max_hp())
	if not tired:
		return
	Game.heal_party()
	Game.party_changed.emit()
	await S.say([Act.cue({"text": "Le Spinosaure attend, immobile, pendant que tes dinos boivent l'eau claire de son bassin. Un combat d'honneur se livre reposé."},
		func() -> void: _drinks_at_pool())])
	Act.lead_back()


## Chloé's lead dino walks to the edge of the nearest pool and laps at it.
static func _drinks_at_pool() -> void:
	var c := Act.lead()
	if c == null:
		return
	var water := Act.water_near(c.global_position, 8)
	if water == c.global_position:
		return
	var edge := water + (c.global_position - water).normalized() * POOL_EDGE
	if not Act.clear_way(c.global_position, edge):
		return
	await Act.walk_lead(edge, 110.0)
	Stage.turn_to(c, water)
	for i in 2:
		if Act.lead() == null:
			return
		await Stage.bow(c, 0.8)
		Act.burst(water, Act.SPLASH, 5, Act.ON_WATER, 0.2)


## It rises from its pool: a sail, a head as long as a boat, calm golden eyes. It knows the
## Sceaux she carries; it wants to see what she is worth.
static func _spino_rises(who: Node) -> void:
	var chloe := Stage.chloe()
	var altar = S.actor("Autel")
	var lines: Array = [
		Act.cue({"text": "La grande salle. Par une coupole fendue, un rayon de jour tombe sur un bassin d'eau claire. Au fond, sur un autel de pierre, quelque chose bat doucement, comme un cœur. Une lumière d'ambre."},
			func() -> void:
				Stage.look_at(_px(ALTAR))
				if altar:
					Act.heartbeat(altar, 3, 1.2)),
		Act.cue({"text": "L'eau du bassin se soulève. Une voile immense en sort, couverte d'algues et de vieilles cicatrices. Puis une tête, longue comme une barque."},
			func() -> void: _surges(who)),
		Act.cue({"text": "Le Spinosaure Ancestral. Si grand que Chloé doit renverser la tête pour le voir en entier. Ses yeux sont dorés, calmes, très anciens. Pas une veine violette : lui n'a peur de rien."},
			func() -> void:
				Stage.look_back()
				if is_instance_valid(who):
					Stage.turn_to(chloe, (who as Node2D).global_position)),
		Act.cue({"text": "Il baisse le museau vers la sacoche de Chloé et renifle. Le Sceau des Plaines, le Sceau de la Forêt… Il connaît ces odeurs."},
			func() -> void:
				Stage.bow(who, 2.2)
				Act.lean(who, chloe.global_position, 14.0, 2.2)),
		{"who": CHLOE, "text": "Je m'appelle Chloé. Je suis la petite-fille d'Hélène. L'Ombre Noire cherche les Cœurs d'ambre : je dois les protéger avant elle."},
		Act.cue({"text": "Le Spinosaure la regarde longtemps, son œil à la hauteur du sien. Puis il se redresse, déploie sa voile… et rugit. Ce n'est pas de la colère. C'est une question."},
			func() -> void: _roars(who)),
	]
	if Game.flag(&"found_journal_13"):
		lines.append({"who": CHLOE, "text": "(« Jusqu'à ce que quelqu'un vienne avec mes yeux et ma confiance »… C'est ça, l'épreuve.)"})
	else:
		lines.append({"who": CHLOE, "text": "(Il veut savoir si j'en suis digne.)"})
	await S.say(lines)


## Out of its pool: it ducks and surges up, water flying all round it, the ground shakes; its
## deep call.
static func _surges(who: Node) -> void:
	var sprite := Stage.sprite_of(who)
	if sprite == null:
		return
	var at: Vector2 = (who as Node2D).global_position
	await Stage.look_at(at, 0.5)
	if not is_instance_valid(who):
		return
	var rest := Stage._rest(sprite)
	var t := sprite.create_tween()
	t.tween_property(sprite, "position:y", rest.y + 26.0, 0.25).set_trans(Tween.TRANS_SINE)
	t.tween_property(sprite, "position:y", rest.y, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Act.burst(at, Act.SPLASH, 34, 0.4, 1.3)
	Marais.cry("spino", "neutre", -2.0, SPINO_PITCH)
	Stage.shake(3.0, 0.5)
	await S.wait(0.8)
	if is_instance_valid(who):
		Stage.rear(who, 1.2)


## A long look, then it rears up, spreads its sail and roars (a question, not anger).
static func _roars(who: Node) -> void:
	await S.wait(1.2)
	if not is_instance_valid(who):
		return
	Stage.rear(who, 1.4)
	Stage.cry(who, &"attaque")
	Stage.shake(4.0, 0.5)


## Won: the Sceau du Marais on its sail, the first Heart on the altar. A golden light rises
## through the dome (Maïa sees it from the reeds); it sinks back into its pool.
static func _trust(who: Node) -> void:
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var altar = S.actor("Autel")
	await S.say([
		Act.cue({"text": "Le Spinosaure Ancestral s'ébroue. L'eau vole partout. Puis, lentement, il replie sa voile et baisse la tête jusqu'aux pieds de Chloé. Un salut."},
			func() -> void: _shakes_and_bows(who)),
		Act.cue({"text": "Entre deux épines de sa voile, pris dans les algues, un disque d'ambre vert d'eau, gravé d'une vague et d'une petite fougère."},
			func() -> void: Stage.glow(who, Color(1.2, 1.6, 1.25), 2, 1.2)),
		{"who": CHLOE, "text": "La fougère d'Hélène…"},
		Act.cue({"text": "Chloé le détache, tout doucement. Le Spinosaure ne bouge pas d'une écaille."},
			func() -> void:
				if is_instance_valid(who):
					Act.lean(chloe, (who as Node2D).global_position, 10.0, 1.6)),
		Act.cue({"text": "Chloé reçoit le Sceau du Marais !"},
			func() -> void:
				Act.pop(chloe.global_position, "sceau_marais", 1.2)
				Stage.glow(chloe, Act.AMBER_GLOW, 1, 0.9)),
		{"flag": &"sceau_marais"},
	])
	Game.give_item("sceau_marais")
	Toast.say(w.get_tree(), "Objet obtenu : le Sceau du Marais")
	Marais.cry("spino", "neutre", -4.0, SPINO_PITCH)
	await S.say([
		Act.cue({"text": "Alors le Spinosaure se tourne vers l'autel. Du bout du museau, avec une douceur incroyable pour une bête de cette taille, il pousse vers Chloé ce qui bat dans la lumière."},
			func() -> void: _brings_heart(who, altar)),
		Act.cue({"text": "Une pierre d'ambre grosse comme un poing, tiède, vivante. Elle bat. Lentement, profondément, comme un cœur endormi."},
			func() -> void:
				Stage.look_back()
				Act.pop(chloe.global_position, "coeur_1", 1.0)
				Act.heartbeat(chloe, 3, 1.4)),
		{"who": CHLOE, "text": "Le premier Cœur d'ambre…"},
	])
	var lines: Array = [
		Act.cue({"text": "Très loin, sous la terre, quelque chose gronde. Le volcan. Le Cœur bat plus vite… puis se calme, contre les mains de Chloé."},
			func() -> void:
				Audio.play_sfx(GATES, -10.0)
				Stage.shake(2.0, 1.0)
				await Act.heartbeat(chloe, 4, 0.55)
				Act.heartbeat(chloe, 2, 1.4)),
		Act.cue({"text": "Un rayon doré jaillit du Cœur, monte le long des colonnes et traverse la coupole fendue, tout droit dans la brume du Marais."},
			func() -> void:
				Stage.flash(HEART_GOLD, 1.2)
				Stage.glow(chloe, Act.AMBER_GLOW, 1, 1.6)
				Act.burst(chloe.global_position, Act.SPARKS, 30, 1.2, 0.3)),
		{"text": "Chloé reçoit le premier Cœur d'ambre !"},
		{"flag": &"coeur_1"},
		{"who": CHLOE, "text": "Un sur cinq. Je le garderai mieux que personne. Promis."},
	]
	var swimmer := _spino_kin()
	var cast := {}   # the little fisher out of her party for the line (cast « kin »), when not her lead
	if swimmer:
		var at_her_side: bool = Game.lead_dino() == swimmer
		lines.append(Act.cue({"text": "Avant de replonger, le Spinosaure renifle %s, qui se fait tout petit. Un petit pêcheur dans l'équipe d'une Varenne… Il a l'air de trouver ça très bien." % swimmer.nickname},
			func() -> void:
				var c: Node2D = Act.lead() if at_her_side else Act.echo_on_stage(swimmer)
				if not at_her_side:
					cast["kin"] = c
				if c and is_instance_valid(who):
					Act.lean(who, c.global_position, 14.0, 2.0)
					Stage.bow(c, 1.8)))
	await S.say(lines)
	Act.echo_off_stage(cast.get("kin"))
	Game.give_item("coeur_1")
	Toast.say(w.get_tree(), "Objet obtenu : le premier Cœur d'ambre")
	await S.say([Act.cue({"text": "Le Spinosaure Ancestral redescend au fond de son bassin. Il garde le temple, maintenant. Plus le Cœur : sa promesse est tenue."},
		func() -> void: _sinks(who))])
	Game.award_team_xp(XP_SPINO)
	Save.save_game()
	S.lock(false)


## It shakes the water off (drops everywhere), then folds its sail and bows to Chloé's feet.
static func _shakes_and_bows(who: Node) -> void:
	if not is_instance_valid(who):
		return
	Stage.tremble(who, 0.9, 3.0)
	Act.burst((who as Node2D).global_position, Act.SPLASH, 30, 1.2, 1.3)
	await S.wait(1.1)
	if not is_instance_valid(who):
		return
	Stage.bow(who, 2.6)
	Act.lean(who, Stage.chloe().global_position, 16.0, 2.6)


## It turns to the altar, where the Heart beats (the camera there), and nudges it to Chloé.
static func _brings_heart(who: Node, altar: Node) -> void:
	if not is_instance_valid(who):
		return
	var altar_at: Vector2 = (altar as Node2D).global_position if altar else _px(ALTAR)
	Stage.turn_to(who, altar_at)
	Stage.look_at(altar_at.lerp((who as Node2D).global_position, 0.5))
	if altar:
		Act.heartbeat(altar, 2, 1.0)
	await S.wait(1.8)
	if not is_instance_valid(who):
		return
	Stage.turn_to(who, Stage.chloe().global_position)
	Act.lean(who, Stage.chloe().global_position, 14.0, 1.6)


## Back to the bottom of its pool: it sinks and fades, a last swirl of water; gone.
static func _sinks(who: Node) -> void:
	if not is_instance_valid(who):
		return
	Act.burst((who as Node2D).global_position, Act.SPLASH, 30, 0.3, 1.0)
	await Act.sink(who, SINK_S, true, true)


## A spinosaurid of Chloé's party (a Baryonyx, a Suchomimus), for the Spinosaure's last look.
static func _spino_kin() -> Dino:
	for d: Dino in Game.party:
		if d.species().family == &"spino":
			return d
	return null


## A place of the temple (tiles) in world pixels.
static func _px(tiles: Vector2) -> Vector2:
	return S.at(tiles.x, tiles.y)
