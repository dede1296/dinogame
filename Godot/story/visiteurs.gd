extends RefCounted
## « Les visiteurs » (docs/histoire.md « Clins d'œil », docs/lore.md): a little group come by boat to
## Havre-Doré, winks at the heroes of a famous dinosaur film (their look, never a face or a name of
## the film): each one a short scene, funny and tender. M. Hamon dreams of a park (Havre-Doré); Ivan
## Malcombe, mathematician, shows the chaos with a drop of water and quotes « a certain Hélène »
## (Havre-Doré, the quay); the Pr Granit digs with Tante Sirocco (the Désert) and shows a raptor's
## claw; Élise Sablier, botanist, looks after a sick Triceratops in the Plaines (a little quest: a
## berry). Their characters and props are placed by tools/zones/{havre_dore,desert,plaines}.gd once
## their sheets are drawn. No class_name: loaded by Story.visiteurs() when they play.
## Flags: hamon_vu, hamon_n, malcombe_vu, malcombe_n, granit_vu, granit_n, elise_vue, elise_fini,
## elise_n, elise_tri_n, elise_pile_n (the _n: lines said after).

const S := preload("res://story/story.gd")
const D := preload("res://story/desert.gd")
const CS := preload("res://story/cote_stage.gd")
const GESTES := preload("res://story/foret_gestes.gd")
const Act := preload("res://story/marais_stage.gd")
const CLINS := preload("res://story/clins_doeil.gd")
const CHLOE := "Chloé"
const HAMON := "M. Hamon"
const MALCOMBE := "Ivan Malcombe"
const GRANIT := "Pr Granit"
const SIROCCO := "Tante Sirocco"
const ELISE := "Élise Sablier"
## Their node names in the zones (tools/zones/*.gd).
const NODE_HAMON := "Hamon"
const NODE_MALCOMBE := "Malcombe"
const NODE_GRANIT := "Granit"
const NODE_ELISE := "Elise"
const NODE_TRICERATOPS := "TriceratopsMalade"
const NODE_PILE := "CrottesTriceratops"
## A drop of water on Chloé's hand; the berry's reward.
const DROP: Array[Color] = [Color(0.75, 0.9, 1.0), Color(0.9, 0.97, 1.0), Color(0.6, 0.82, 0.98)]
const FERNS_GIVEN := 2
const XP_ELISE := 60
const HAMON_AGAIN := [
	"Je me suis assis sur un banc, ce matin, face à l'île. Un Parasaurolophus est passé. Il m'a dit bonjour. Enfin, je crois.",
	"Ma canne ? Un cadeau d'Hélène. Elle en avait offert une autre à un certain Anselme. Il doit toujours la faire tourner en marchant.",
	"Je n'ai lésiné sur rien ! … Sauf sur le banc. Il est un peu dur.",
]
const MALCOMBE_AGAIN := [
	"Tu as remarqué ? Les vagues ne reviennent jamais deux fois au même endroit. Le chaos, partout. C'est magnifique.",
	"Hamon veut faire un parc. Je lui ai dit : « Un parc ? Ici ? » Il m'a regardé comme si j'avais marché sur son chapeau.",
	"Je m'habille en noir parce que ça va avec tout. Même avec le chaos.",
]
const GRANIT_AGAIN := [
	"Un bon pinceau, de la patience, et le soleil dans la nuque. La paléontologie, c'est ça. Pas des machines.",
	"Sirocco dit que j'ai tort. J'ai raison. Mais je la laisse croire le contraire : c'est plus calme.",
	"Des nouvelles de ce vieil Anselme ? Il a toujours ma griffe de raptor ? … Sur son bureau ? Je le savais.",
]
const TRICERATOPS_AGAIN := [
	"Le Tricératops broute tranquillement. Il ne touche plus au lilas des falaises. Enfin, pas devant Élise.",
	"Le Tricératops pousse Chloé du bout du museau, tout doucement. C'est sa façon de dire merci. Ou de réclamer une autre baie.",
]
const PILE_AGAIN := [
	"La pile de crottes. Une mouche tourne autour, très satisfaite de sa journée.",
	"Élise dit que c'est un livre ouvert. Chloé préfère les livres avec des pages.",
	"Chloé respire par la bouche. Très discrètement. Par politesse.",
]
const ELISE_AGAIN := [
	"Il va très bien ! Il ne mange plus de lilas des falaises. Enfin, presque plus.",
	"Les crottes, c'est de la science ! … Mais je me lave les mains trois fois, après.",
	"Hélène Varenne m'a appris quarante fougères en une après-midi. Et à ne jamais porter de chaussures blanches sur cette île.",
]


# ------------------------------------------------------------------ M. Hamon (Havre-Doré)

## M. Hamon on the square: his dream of a park; Chloé answers with Hélène's rule, « chacun chez
## soi »; he ends up touched. Afterwards, a line each time.
static func hamon(who: Node) -> void:
	if Game.flag(&"hamon_vu"):
		await S.say([{"who": HAMON, "text": ForetCamp.next_line(&"hamon_n", HAMON_AGAIN)}])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var dreams := func() -> void:   # arms wide, at the hills (the island), the sea
		Stage.turn_to(who, at + Vector2(0.0, -200.0))
		await Stage.rear(who, 1.2)
		Stage.turn_to(who, chloe.global_position)
	var taps := func() -> void:   # his cane on the paving stones, very pleased
		Stage.hop(who, 3, 5.0)
		Stage.emote(who, "!")
	var silent := func() -> void:
		Stage.bow(who, 1.6)
		Stage.emote(who, "…")
	await S.say([
		_cue({"text": "Un vieux monsieur tout en blanc, chapeau de paille et barbe de neige, s'appuie sur une canne. Le pommeau est un œuf d'ambre… avec un moustique dedans."},
			func() -> void:
				Stage.look_at(at.lerp(chloe.global_position, 0.4), 0.9)
				Stage.turn_to(chloe, at)),
		{"who": CHLOE, "text": "(La même canne que le professeur Roc !)"},
		_cue({"who": HAMON, "text": "Bienvenue, bienvenue ! Hamon. Arrivé par le bateau de mardi, avec quelques amis très savants."},
			func() -> void:
				Stage.turn_to(who, chloe.global_position)
				Stage.emote(who, "♥")),
		_cue({"who": HAMON, "text": "J'ai un rêve, mademoiselle. Un parc ! Un grand parc, ici, sur cette île, pour que tout le monde puisse voir les dinos."}, dreams),
		_cue({"who": HAMON, "text": "Des allées, des barrières, des petites voitures qui roulent toutes seules… Je n'ai lésiné sur rien !"}, taps),
		{"who": CHLOE, "text": "Mais les dinos, ils sont déjà chez eux, ici."},
		{"who": CHLOE, "text": "Ma grand-mère disait : « Chacun chez soi. » Les dinos dans leurs forêts, et nous, on vient leur rendre visite. En disant bonjour."},
		_cue({"text": "M. Hamon ouvre la bouche. La referme. Il regarde longtemps le bout de sa canne."}, silent),
		{"who": HAMON, "text": "Hélène Varenne… Tu es sa petite-fille, n'est-ce pas ? Elle m'avait dit exactement la même chose. Il y a trente ans."},
		{"who": HAMON, "text": "Mon tout premier spectacle, c'était un cirque de puces. Des puces imaginaires. Les gens riaient quand même. J'aime quand les gens s'émerveillent."},
		_cue({"who": HAMON, "text": "Chacun chez soi… Bon. Alors mon parc, ce sera un banc. Un banc face à l'île. Et on dira bonjour."},
			func() -> void:
				Stage.emote(who, "~")
				Stage.look_back()),
		{"flag": &"hamon_vu"},
	])
	S.lock(false)


# ------------------------------------------------------------------ Ivan Malcombe (Havre-Doré)

## Ivan Malcombe on the quay: a drop of water on the back of Chloé's hand rolls one way, then the
## other (« le chaos ! »); « La vie trouve toujours un chemin… C'est d'une certaine Hélène. »
static func malcombe(who: Node) -> void:
	if Game.flag(&"malcombe_vu"):
		await S.say([{"who": MALCOMBE, "text": ForetCamp.next_line(&"malcombe_n", MALCOMBE_AGAIN)}])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	await D._step_aside(who, 60.0)
	var hand := func() -> Vector2:   # the back of her hand, held out towards him
		return chloe.global_position.lerp((who as Node2D).global_position, 0.3)
	var holds_out := func() -> void:
		Stage.turn_to(chloe, (who as Node2D).global_position)
		if not Stage.pose(chloe, &"main"):
			D._reach(chloe, (who as Node2D).global_position, 10.0, 1.2)
	var rolls := func(way: float) -> void:   # the drop falls on her hand, then rolls off to one side
		GESTES.lean(who, hand.call(), 8.0, 0.8)
		await S.wait(0.4)
		Act.burst(hand.call(), DROP, 5, 0.9, 0.05)
		await S.wait(0.7)
		for i in 3:
			Act.burst(hand.call() + Vector2(way * (6.0 + 7.0 * i), 2.0 * i), DROP, 3, 0.85 - 0.12 * i, 0.03)
			await S.wait(0.25)
	await S.say([
		_cue({"text": "Au bord du quai, un grand monsieur tout en noir, veste de cuir et lunettes teintées, regarde les vagues comme s'il les comptait."},
			func() -> void: Stage.look_at((who as Node2D).global_position.lerp(chloe.global_position, 0.4), 0.9)),
		_cue({"who": MALCOMBE, "text": "Tiens. Une jeune personne. Ivan Malcombe, mathématicien. Tu veux voir un tour ?"},
			func() -> void: Stage.turn_to(who, chloe.global_position)),
		{"who": CHLOE, "text": "Un tour de magie ?"},
		_cue({"who": MALCOMBE, "text": "Mieux : un tour de mathématiques. Donne-moi ta main. À plat."}, holds_out),
		_cue({"text": "Il fait tomber une goutte d'eau sur le dos de la main de Chloé. Elle roule… vers la gauche."}, func() -> void: rolls.call(-1.0)),
		{"who": MALCOMBE, "text": "Encore une fois. Même main, même goutte, même endroit."},
		_cue({"text": "La deuxième goutte roule… vers la droite."}, func() -> void: rolls.call(1.0)),
		_cue({"who": CHLOE, "text": "Elle est partie de l'autre côté !"}, func() -> void: Stage.emote(chloe, "!")),
		_cue({"who": MALCOMBE, "text": "Le chaos ! Une toute petite chose change, et tout part ailleurs. Un poil de ta peau, un souffle de vent… Impossible à prévoir."},
			func() -> void:
				Stage.pose(chloe, &"")
				Stage.rear(who, 1.0)),
		{"who": MALCOMBE, "text": "Sur cette île, c'est pareil. On croit tout prévoir, tout ranger, tout enfermer… et puis. La vie trouve toujours un chemin."},
		_cue({"who": MALCOMBE, "text": "C'est d'une certaine Hélène. Une dame qui m'a battu aux échecs trois fois de suite. Je ne m'en suis jamais remis."},
			func() -> void:
				Stage.bow(who, 1.0)
				Stage.emote(who, "~")),
		{"who": CHLOE, "text": "(Grand-mère…)"},
		{"flag": &"malcombe_vu"},
	])
	Stage.look_back()
	S.lock(false)


# ------------------------------------------------------------------ Pr Granit (the Désert)

## The Pr Granit at Tante Sirocco's dig: a raptor's claw held like a sickle (the one on Roc's desk
## comes from him); he does not like children, or machines… Afterwards, a line each time.
static func granit(who: Node) -> void:
	if Game.flag(&"granit_vu"):
		await S.say([{"who": GRANIT, "text": ForetCamp.next_line(&"granit_n", GRANIT_AGAIN)}])
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var sirocco = S.actor("Sirocco")
	await D._step_aside(who, 62.0)
	var at: Vector2 = (who as Node2D).global_position
	var cast := {}
	var dusts := func() -> void:
		Stage.look_at(at.lerp(chloe.global_position, 0.4), 0.9)
		for i in 2:
			await D._reach(who, at + Vector2(0.0, 40.0), 5.0, 0.6)
		Stage.turn_to(who, chloe.global_position)
	var shows := func() -> void:
		cast["claw"] = CLINS._held_up("griffe_fossile", at.lerp(chloe.global_position, 0.3), "GriffeGranit", 1.0)
	var sweeps := func() -> void:   # through the air, slowly, like a scythe through grass
		var claw = cast.get("claw")
		var sprite := Stage.sprite_of(claw)
		if sprite == null:
			return
		var rest := sprite.position
		var t := sprite.create_tween()
		for i in 2:
			t.tween_property(sprite, "position", rest + Vector2(-14.0, -8.0), 0.45).set_trans(Tween.TRANS_SINE)
			t.tween_property(sprite, "position", rest + Vector2(14.0, 6.0), 0.7).set_trans(Tween.TRANS_SINE)
		t.tween_property(sprite, "position", rest, 0.4).set_trans(Tween.TRANS_SINE)
	var lines: Array = [
		_cue({"text": "À côté de Tante Sirocco, un grand monsieur en chemise de jean, foulard rouge au cou et chapeau de feutre, époussette le sable avec un pinceau."}, dusts),
	]
	if sirocco:
		lines.append(_cue({"who": SIROCCO, "text": "Ma caille, je te présente le Pr Granit. On se dispute sur les os depuis quarante ans. Il a toujours tort."},
			func() -> void: Stage.turn_to(sirocco, chloe.global_position)))
	lines.append({"who": GRANIT, "text": "Granit. Paléontologue. Je ne suis pas très doué avec les enfants."})
	if sirocco:
		lines.append({"who": SIROCCO, "text": "Il dit ça à tous les enfants. Et après, il leur apprend tout."})
	lines.append_array([
		_cue({"who": GRANIT, "text": "Hm. Tu sais ce que c'est, ça ? Une griffe de raptor. Regarde comme elle est courbée : une vraie faucille."}, shows),
		_cue({"text": "Il la fait passer dans l'air, tout doucement, comme on fauche de l'herbe."}, sweeps),
		{"who": GRANIT, "text": "Le raptor la gardait relevée en marchant, pour ne pas l'abîmer. Comme toi, tu lèves les pieds pour ne pas salir tes chaussures neuves."},
	])
	var lead := Game.lead_dino()
	if lead and lead.species().family == &"raptor":
		lines.append_array([
			_cue({"text": "%s lève une patte et montre sa propre griffe, très fier." % lead.nickname},
				func() -> void:
					var dino := D._companion()
					if dino:
						Stage.turn_to(dino, at)
						Stage.hop(dino, 2, 8.0)
						Stage.emote(dino, "!")),
			{"who": GRANIT, "text": "… Ha ! Tu vois ? Lui, il sait. Et lui, au moins, il écoute."},
		])
	lines.append_array([
		{"who": GRANIT, "text": "J'en ai offert une toute pareille à un certain Anselme Roc, il y a longtemps. Il s'en sert de presse-papier, je parie."},
		{"who": CHLOE, "text": "Comment vous le savez ?"},
		_cue({"who": GRANIT, "text": "Tout le monde s'en sert de presse-papier. C'est un scandale."}, func() -> void: Stage.emote(who, "…")),
		{"who": GRANIT, "text": "Et ne me parle pas des machines qu'ils ont au Havre, avec leurs manivelles et leurs sonnettes. Ces machines… Un bon pinceau, voilà tout."},
		{"flag": &"granit_vu"},
	])
	await S.say(lines)
	await Stage.fade_out(cast.get("claw"), 0.4, true)
	Stage.look_back()
	S.lock(false)


# ------------------------------------------------------------------ Élise Sablier (the Plaines)

## The Plaines, entering: the sick Triceratops asleep on its side (a dino lies down only asleep)
## until Chloé brings it a berry.
static func plaines() -> void:
	var tri = S.actor(NODE_TRICERATOPS)
	if tri == null or Game.flag(&"elise_fini"):
		return
	GESTES.lie_down(tri, 0.0, 0.62)


## Élise Sablier by the sleeping Triceratops (her, the Triceratops or its pile): the first time,
## she digs in its dung to find what it ate; the cure is a berry. With a berry: it gets up.
static func elise(_who: Node) -> void:
	var elise = S.actor(NODE_ELISE)
	var tri = S.actor(NODE_TRICERATOPS)
	if elise == null:
		return
	if Game.flag(&"elise_fini"):
		await S.say([{"who": ELISE, "text": ForetCamp.next_line(&"elise_n", ELISE_AGAIN)}])
		return
	if not Game.flag(&"elise_vue"):
		S.lock(true)
		await S.say(_elise_meets(elise, tri))
		S.lock(false)
	if Game.item_count("baie") == 0:
		await S.say([
			{"who": ELISE, "text": "Il lui faudrait une bonne baie bien sucrée. Ça remet l'estomac d'aplomb."},
			{"who": CHLOE, "text": "(Je n'en ai plus… Les arbres en laissent tomber quand on les secoue. Et Mémé Pervenche en vend, au Havre.)"},
		])
		return
	var pick := await Dialogue.choose(ELISE, "Une baie bien sucrée, ça lui remettrait l'estomac d'aplomb. Tu en as une ?", ["Donner une baie", "Plus tard"])
	if pick != 0:
		return
	S.lock(true)
	Game.use_item("baie")
	await S.say(_berry(elise, tri))
	Game.give_item("fougere", FERNS_GIVEN)
	Toast.say(S.world().get_tree(), "+%d fougères curatives" % FERNS_GIVEN)
	Game.award_team_xp(XP_ELISE)
	Save.save_game()
	S.lock(false)


static func _elise_meets(elise: Node, tri) -> Array:
	var chloe := Stage.chloe()
	var pile = S.actor(NODE_PILE)
	var pile_px: Vector2 = (pile as Node2D).global_position if pile is Node2D else (elise as Node2D).global_position + Vector2(-40.0, -10.0)
	var digs := func() -> void:   # her arms in the pile up to the elbows
		Stage.wide()   # (back from the sleeper's close-up)
		Stage.look_at(pile_px.lerp(chloe.global_position, 0.3), 0.8)
		Stage.turn_to(elise, pile_px)
		if not Stage.pose(elise, &"agenouille"):   # on her knees, arms in the pile
			for i in 3:
				await Stage.bow(elise, 0.7)
	var up := func() -> void:
		Stage.pose(elise, &"")
		Stage.turn_to(elise, chloe.global_position)
		Stage.emote(elise, "!")
	var finds := func() -> void:   # back in, then up with a little crumpled leaf
		Stage.pose(elise, &"agenouille")
		Stage.turn_to(elise, pile_px)
		await Stage.bow(elise, 0.8)
		await Stage.rear(elise, 0.7)
		CS.sparkle((elise as Node2D).global_position + Vector2(8.0, -4.0), 1.3, 10, 0.1)
		Stage.emote(elise, "!")
	return [
		_cue({"text": "Au milieu du pré, un Tricératops dort, couché sur le flanc. Il respire lentement, avec un petit sifflement de théière."},
			func() -> void:
				if tri:   # close on him: the whole line is about the big sleeper. A little towards
					# the pile, and not too close: Élise is just below him, and the screen cut her head.
					Stage.close_up((tri as Node2D).global_position.lerp(pile_px, 0.45), 9.5, 1.0)
					Stage.emote(tri, "…")),
		_cue({"text": "À côté, une énorme pile de crottes. Et dedans, jusqu'aux coudes, une dame en short et en bottes."}, digs),
		_cue({"who": ELISE, "text": "Oh ! Bonjour ! Ne fais pas attention, je travaille. Élise Sablier, botaniste."}, up),
		{"who": CHLOE, "text": "Vous… vous fouillez dans des crottes ?"},
		{"who": ELISE, "text": "Des crottes de Tricératops ! C'est un livre ouvert : tout ce qu'il a mangé est écrit dedans. Il suffit de savoir lire."},
		_cue({"text": "Elle replonge les bras dans la pile, fouille, fouille… et brandit une petite feuille violette, toute froissée."}, finds),
		{"who": ELISE, "text": "Du lilas des falaises ! Il en a mangé tout un buisson, le gourmand. Ce n'est pas grave, mais quel mal de ventre…"},
		{"flag": &"elise_vue"},
	]


static func _berry(elise: Node, tri) -> Array:
	var chloe := Stage.chloe()
	var tri_px: Vector2 = (tri as Node2D).global_position if tri is Node2D else (elise as Node2D).global_position
	var offers := func() -> void:   # to its muzzle, the berry held out
		var side := signf(chloe.global_position.x - tri_px.x)
		await D._chloe_walk(S.ground_near(tri_px + Vector2((side if side != 0.0 else 1.0) * 64.0, 16.0), 2), 100.0, 1.6)
		Stage.turn_to(chloe, tri_px)
		if not Stage.pose(chloe, &"main"):
			Stage.bow(chloe, 1.0)
	var sniffs := func() -> void:
		if tri:
			await GESTES.lean(tri, chloe.global_position, 8.0, 0.8)
			await GESTES.lean(tri, chloe.global_position, 8.0, 0.8)
			Stage.cry(tri, &"neutre")
			Stage.pose(chloe, &"")
	var gets_up := func() -> void:
		if tri:
			Stage.emote(tri, "!")
			if tri.has_method(&"wake"):   # it was lying asleep (Sleeper): back on its feet
				tri.call(&"wake")
			await GESTES.stand_up(tri, 1.2)
			Stage.shake(2.5, 0.4)
			Stage.rear(tri, 0.9)
	var nudges := func() -> void:   # a big fond push of the muzzle: Élise sits down in the pile
		if tri:
			Stage.turn_to(tri, (elise as Node2D).global_position)
			GESTES.lean(tri, (elise as Node2D).global_position, 12.0, 0.8)
		await S.wait(0.4)
		Stage.recoil(elise, tri_px, 16.0)
		if not await Stage.sit(elise):
			GESTES.lie_down(elise, 0.4, 0.85)
	return [
		_cue({"text": "Chloé s'approche tout doucement, et pose la baie juste sous le nez du Tricératops."}, offers),
		_cue({"text": "Il renifle. Une fois. Deux fois. Et hop ! La baie disparaît."}, sniffs),
		_cue({"text": "Le Tricératops ouvre un œil, puis l'autre… et il se relève, tout doucement, en faisant trembler le sol."}, gets_up),
		_cue({"who": ELISE, "text": "Il se relève ! Oh, le brave, le brave !"},
			func() -> void:
				Stage.hop(elise, 2, 8.0)
				Stage.emote(elise, "♥")),
		_cue({"text": "Le Tricératops lui donne un grand coup de museau, plein d'affection. Élise s'assoit dans la pile de crottes."}, nudges),
		_cue({"who": ELISE, "text": "… Bon. Ça, je ne l'avais pas prévu."}, func() -> void: Stage.emote(elise, "…")),
		_cue({"who": ELISE, "text": "Merci, Chloé. Tiens, de la fougère curative : toi, tu as la main verte."},
			func() -> void:
				GESTES.stand_up(elise, 0.4)
				Stage.turn_to(elise, chloe.global_position)),
		{"flag": &"elise_fini"},
	]


## The Triceratops or its pile, talked to: Élise's scene until it is up again; then a line.
static func triceratops(who: Node) -> void:
	if not Game.flag(&"elise_fini"):
		await elise(who)
		return
	var pool: Array = PILE_AGAIN if who is StoryProp else TRICERATOPS_AGAIN
	await S.say([{"text": ForetCamp.next_line(&"elise_pile_n" if who is StoryProp else &"elise_tri_n", pool)}])


# ------------------------------------------------------------------ staging

static func _cue(line: Dictionary, act: Callable) -> Dictionary:
	return CLINS._cue(line, act)
