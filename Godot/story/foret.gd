class_name Foret
## Chapter 2, the Forêt Jurassique, step 1 (docs/histoire.md, ch. 2): arriving under the giant
## ferns while the raptors call each other and no one answers (the pack has lost its leader);
## Griffe-Grise, Hélène's old Velociraptor, in his hidden ravine: Vif's father when Chloé chose
## Vif (a reunion, and the Ancien's page), otherwise a wary old friend of Hélène's who ends up
## trusting her and shows a clue (a poacher's trap, torn open, smelling of ash); both times he
## looks towards the clearing of the giant ferns. That clearing is empty: a ring of stakes, cut
## ropes, ash, a piece of bone mask, drag marks going west (step 2: Brac, the camp, the Alpha,
## in story/foret_camp.gd and story/foret_fin.gd). Once the leader is free: the pack's voice
## back in the Forêt, Griffe-Grise at peace, the clearing no longer empty; and when the stolen
## hatchling was a Velociraptor, Griffe-Grise knows his little one (the Ancien's page).
## Flags: foret_arrivee, griffe_grise_vu, found_journal_ancien, clairiere_vue; griffe_grise_n,
## clairiere_n (visits since, for the next line), griffe_apres_clairiere, griffe_apres_sceau,
## griffe_vole_reconnu, meute_revenue.
## (Pages 7 to 10 are Pickups placed by the zone: DialogueDB page_7 … page_10.)

const S := preload("res://story/story.gd")
const GESTES := preload("res://story/foret_gestes.gd")
const CHLOE := "Chloé"
const RAPTOR_CRY := "res://assets/audio/cries/raptor-%s.mp3"
const LATCH := preload("res://assets/audio/sfx/latch.wav")
const LEAVES := preload("res://assets/audio/sfx/feuillage.mp3")
## Griffe-Grise's voice: a raptor's cry, but old and deep.
const OLD_PITCH := 0.72
## Where the calls come from (directions): Griffe-Grise's ravine, the clearing of the pack.
const SOUTH_WEST := Vector2(-0.7, 0.7)
const NORTH_WEST := Vector2(-0.7, -0.7)
## Griffe-Grise dozing on his rock (how low: see ForetGestes.lie_down).
const DOZING := 0.8
## The three Deinonychus watching from the ferns round the empty clearing (tiles from Chloé).
const WATCHERS := [Vector2(-4.4, -2.4), Vector2(4.3, -2.8), Vector2(-3.0, 2.6)]
const XP_GRIFFE := 50
const XP_ANCIEN := 30   # the Ancien's page, on top (Vif's father)
const XP_CLAIRIERE := 40
## The first lines under the trees: it rains, or the ferns are still dripping.
const RAIN_NOW := "La pluie crépite sur les fougères géantes. Sous les arbres, elle tombe en retard : chaque feuille la garde un moment, puis la laisse filer, goutte à goutte."
const RAIN_AFTER := "Une averse vient de passer. Sous les arbres géants, il pleut encore : chaque fougère égoutte l'averse, goutte à goutte, bien après les nuages."
## The Ancien's page, left in Griffe-Grise's ravine a year ago (only with Vif).
const ANCIEN_PAGE := [
	"Griffe-Grise",
	"Mon deuxième réveil : un Velociraptor pas plus gros qu'un chat, qui m'a mordu le pouce puis s'est endormi dessus. Une griffe grise comme un galet : son nom s'est trouvé tout seul.",
	"Chez les raptors, c'est souvent le père qui couve. Il a veillé cet œuf un mois sans fermer l'œil, puis il l'a poussé vers moi du bout du museau. Il savait pour qui.",
	"S'il t'a laissée approcher, gratte-le sous le menton. Il fait semblant de détester ça.",
]
## Griffe-Grise once he knows Chloé: with Vif at her side ("%s" = Vif's name), or not.
const AGAIN_VIF := [
	"Griffe-Grise ouvre un œil, voit %s, et le referme. Tout va bien.",
	"%s et Griffe-Grise se reniflent longuement. Chloé a un peu l'impression de déranger.",
	"Griffe-Grise bondit sur son rocher, sans élan. %s essaie de faire pareil et atterrit à côté. Son père fait semblant de n'avoir rien vu.",
	"Chloé gratte Griffe-Grise sous le menton. Il grogne. Il ne bouge pas d'un poil.",
]
const AGAIN := [
	"Griffe-Grise ouvre un œil, reconnaît Chloé, et le referme.",
	"Le vieux raptor renifle la sacoche de Chloé, pour vérifier. Oui : ça sent toujours Hélène.",
	"Griffe-Grise bâille. Il lui manque deux dents, et visiblement, il s'en fiche.",
	"Il regarde vers le nord-ouest, comme la dernière fois. Il attend des nouvelles de la meute.",
]
const CLEARING_AGAIN := [
	"La clairière est toujours vide. Les fougères écrasées commencent à peine à se redresser.",
	"Les sillons partent toujours vers l'ouest. C'est par là qu'on a emmené le chef de la meute.",
	"Entre les fougères, un Deinonychus te regarde passer. Il ne gronde même pas. Il attend.",
	"Chloé ramasse un bout de corde. Coupée net, d'un seul coup de lame. Ceux qui ont fait ça avaient l'habitude.",
]
## The clearing once its leader is back (the Sceau de la Forêt).
const CLEARING_BACK := [
	"Au milieu des fougères qui se redressent, la meute s'est roulée en boule. Le Chef de Meute ouvre un œil, reconnaît Chloé, et le referme.",
	"Les pieux de Brac ont été arrachés, un par un, et jetés dans le ruisseau. Les raptors ont fait le ménage.",
	"Un jeune Deinonychus trottine jusqu'à Chloé, la renifle, et repart en courant rejoindre les autres. Le chef le suit des yeux : il compte les siens.",
	"Le Chef de Meute dort, le museau posé sur une fougère géante. Pour la première fois depuis longtemps, personne n'appelle dans le vide.",
]


# ------------------------------------------------------------------ arriving

## The first time in the Forêt: rain under the ferns, raptors calling each other with no one to
## answer, then a deep cry from the south-west that silences them all (Griffe-Grise).
static func arrival() -> void:
	_griffe_dozes()
	if Game.flag(&"foret_arrivee"):
		await _pack_back()
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var chloe: Player = w.player
	await S.wait(0.8)
	await S.say([
		{"text": RAIN_NOW if Game.is_raining() else RAIN_AFTER},
		{"text": "Les troncs montent si haut qu'on n'en voit pas la cime, et les fougères dépassent Chloé d'une bonne tête. Ça sent la mousse, la terre mouillée… et quelque chose de très, très ancien."},
	])
	raptor_cry("neutre", -14.0)
	await S.wait(0.6)
	raptor_cry("neutre", -19.0, 1.1)
	await S.wait(0.35)
	raptor_cry("attaque", -17.0, 0.95)
	await S.say([
		GESTES.cue("Un cri de raptor, quelque part dans le sous-bois. Un autre lui répond, plus loin. Puis un troisième, tout de suite, trop vite. Ils s'appellent dans tous les sens.",
			func() -> void: _look_all_around(chloe, w.companion)),
		{"who": CHLOE, "text": "(On dirait qu'ils cherchent quelqu'un. Et que personne ne leur répond.)"},
	])
	await S.wait(0.4)
	raptor_cry("neutre", -8.0, OLD_PITCH)
	await S.wait(0.9)
	await S.say([GESTES.cue("Alors, venu du sud-ouest, un cri plus grave, plus lent, fait taire tous les autres. Le sous-bois retient son souffle… puis les appels reprennent, tout bas.",
		func() -> void: _all_look(chloe, w.companion, SOUTH_WEST))])
	var vif := vif_dino()
	var lead := Game.lead_dino()
	var lines: Array = []
	var buddy: DinoNpc = null   # Vif out of her party for his answer, when he is not her lead
	if vif and Game.party.has(vif):
		if lead != vif:
			buddy = GESTES.stand_in(vif)
		var raptor: Node = buddy if buddy else w.companion
		lines = [
			GESTES.cue("%s se fige, la tête tournée vers le sud-ouest. Puis il répond : un petit cri aigu, que Chloé ne lui a jamais entendu." % vif.nickname,
				func() -> void: _answers(raptor)),
			{"who": CHLOE, "text": "(« Son père, Griffe-Grise, veille encore dans la Forêt »… C'était lui ?)"},
			{"who": CHLOE, "text": "Viens, %s. On va voir qui t'appelle." % vif.nickname},
		]
	else:
		if lead:
			lines.append(GESTES.cue("%s se colle contre la jambe de Chloé, les yeux ronds." % lead.nickname,
				func() -> void: Stage.emote(w.companion, "!"); Stage.tremble(w.companion, 1.2, 1.5)))
		lines.append({"who": CHLOE, "text": "(Celui-là n'avait pas peur. Il venait d'un ravin, au sud-ouest.)"})
		if vif:   # Vif waits at the Cabinet, but Chloé read page 6
			lines.append({"who": CHLOE, "text": "(« Son père, Griffe-Grise, veille encore dans la Forêt »… Le père %s ?)" % French.de(vif.nickname)})
		lines.append({"who": CHLOE, "text": "Allez. On va voir qui peut faire taire une meute entière d'un seul cri."})
	lines.append({"flag": &"foret_arrivee"})
	await S.say(lines)
	await GESTES.stand_in_back(buddy)
	Save.save_game()
	S.lock(false)


## Chloé and her dino look this way and that (calls from everywhere in the undergrowth).
static func _look_all_around(chloe: Player, companion: Node) -> void:
	Stage.emote(companion, "?")
	for dir: Vector2 in [Vector2(-1.0, 0.3), Vector2(1.0, -0.2), Vector2(-0.4, -1.0)]:
		if not is_instance_valid(chloe):
			return
		Stage.turn_to(chloe, chloe.global_position + dir * 100.0)
		Stage.turn_to(companion, chloe.global_position + dir * 100.0)
		await S.wait(0.9)


## Both turn towards `dir` (a direction), where the sound comes from.
static func _all_look(chloe: Player, companion: Node, dir: Vector2) -> void:
	Stage.turn_to(chloe, chloe.global_position + dir * 100.0)
	Stage.turn_to(companion, chloe.global_position + dir * 100.0)
	Stage.emote(companion, "!")


## Her Velociraptor freezes towards the south-west, then answers: head up, a little high cry
## (at her side, or out of her party for it).
static func _answers(raptor: Node) -> void:
	if not is_instance_valid(raptor):
		return
	Stage.turn_to(raptor, (raptor as Node2D).global_position + SOUTH_WEST * 100.0)
	await S.wait(1.2)
	Stage.rear(raptor, 0.8)
	Stage.cry(raptor, &"neutre")


## Back in the Forêt once the leader is free (the Sceau): the pack calls, and a deep voice
## answers them. Once.
static func _pack_back() -> void:
	if not Game.flag(&"sceau_foret") or Game.flag(&"meute_revenue"):
		return
	S.lock(true)
	var w = S.world()
	await S.wait(0.6)
	raptor_cry("neutre", -15.0, 1.08)
	await S.wait(0.35)
	raptor_cry("attaque", -17.0, 0.97)
	await S.wait(0.5)
	raptor_cry("neutre", -9.0, 0.8)
	await S.say([
		GESTES.cue("La Forêt n'a plus la même voix. Les raptors s'appellent toujours, d'un bout à l'autre du sous-bois… mais maintenant, une voix grave leur répond, et ils se taisent pour l'écouter.",
			func() -> void: _look_all_around(w.player, w.companion)),
		{"who": CHLOE, "text": "(Il les compte. À chaque ruisseau.)" if Game.flag(&"found_journal_7") else "(Ils ont retrouvé leur chef.)"},
		{"flag": &"meute_revenue"},
	])
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ Griffe-Grise

## Before they meet, Griffe-Grise dozes on his rock (the first lines find him so).
static func _griffe_dozes() -> void:
	var griffe = S.actor("GriffeGrise")
	if griffe and not Game.flag(&"griffe_grise_vu"):
		GESTES.lie_down(griffe, 0.0, DOZING)


## Talking to Griffe-Grise (`who`, the DinoNpc of his ravine): the meeting the first time, then
## a short line at each visit. He stays in his ravine.
static func griffe_grise(who: Node) -> void:
	var little: Dino = ForetCamp.recovered()
	var his_little: bool = little != null and ForetCamp.stolen_species() == &"velociraptor" and Game.party.has(little)
	if Game.flag(&"griffe_grise_vu"):
		if his_little and not Game.flag(&"griffe_vole_reconnu"):
			S.lock(true)
			await _stolen_reunion(who, little)
			Game.award_team_xp(XP_ANCIEN)
			Save.save_game()
			S.lock(false)
			return
		var cast := {}   # Vif out of her party for the line (cast « vif »), when he is not her lead
		await S.say([_griffe_again(who, cast)])
		await GESTES.stand_in_back(cast.get("vif"))
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var home: Vector2 = who.global_position
	await S.say([
		GESTES.cue("Au fond du ravin, sur un rocher couvert de mousse, un vieux Velociraptor somnole, immobile comme une statue. Museau gris, plumes ternies, et en travers du flanc, une longue éraflure à peine refermée.",
			func() -> void: Stage.emote(who, "…")),
		{"text": "Au-dessus de sa couche, quelqu'un a gravé un nom dans la roche, avec une petite fougère : « Griffe-Grise »."},
		GESTES.cue("Il ouvre un œil jaune. Puis il se redresse, beaucoup plus vite qu'un vieux dino ne devrait.",
			func() -> void: _wakes(who)),
	])
	raptor_cry("attaque", -3.0, OLD_PITCH)
	await who.walk_to(home.lerp(w.player.global_position, 0.3), 220.0)
	Stage.shake(4.0, 0.3)
	await S.say([GESTES.cue("Il gronde, les griffes plantées dans la mousse. À chaque patte, une griffe recourbée, grise comme un galet de rivière.",
		func() -> void: Stage.tremble(who, 1.4, 1.6))])
	var vif := vif_dino()
	var buddy: DinoNpc = null   # Vif, walking up to his father
	if vif:
		buddy = await _reunion(who, vif)
	elif his_little:
		await _stolen_reunion(who, little)
	else:
		await _wary(who)
	await _the_trap(who)
	await _the_pack(who, home)
	await GESTES.stand_in_back(buddy)
	Game.set_flag(&"griffe_grise_vu")
	Game.award_team_xp(XP_GRIFFE + (XP_ANCIEN if vif or his_little else 0))
	Save.save_game()
	S.lock(false)


## He opens a yellow eye, then gets up on his feet, far quicker than an old dino should.
static func _wakes(griffe: Node) -> void:
	await S.wait(0.8)
	Stage.emote(griffe, "!")
	Stage.rear(griffe, 0.5)


## Vif and his father: he knows his little one's smell. The Ancien's page, in a tin box.
## Returns Vif's stand-in, curled up against his father (null when Vif waits at the Cabinet).
static func _reunion(griffe: Node, vif: Dino) -> DinoNpc:
	var w = S.world()
	var chloe: Player = w.player
	var with_her := Game.party.has(vif)
	var name := vif.nickname
	var little: DinoNpc = GESTES.stand_in(vif) if with_her else null
	if with_her:
		await S.say([
			GESTES.cue("%s passe devant Chloé. Il ne gronde pas. Il avance tout doucement, le cou tendu, en reniflant l'air." % name,
				func() -> void: _creeps_up(little, griffe)),
			GESTES.cue("Le vieux raptor se tait d'un coup. Il baisse la tête, très bas, jusqu'à toucher le museau du petit. Et il ne bouge plus.",
				func() -> void: Stage.bow(griffe, 2.8); GESTES.lean(griffe, _px_of(little), 10.0, 2.8)),
		])
		Stage.hop(little, 2)
		GESTES.stand_in_cry(little)
	else:
		await S.say([
			GESTES.cue("Le vieux raptor s'approche de Chloé, tout près. Il renifle ses mains : celles qui caressent %s chaque soir, au Cabinet." % name,
				func() -> void: _sniffs_her(griffe, chloe)),
			{"text": "Il se tait d'un coup. Et il ne bouge plus."},
		])
	raptor_cry("neutre", -6.0, OLD_PITCH)
	var cry_line := "Griffe-Grise pousse un cri doux et grave, qu'il n'a pas dû pousser depuis longtemps."
	if with_her:
		cry_line += " %s lui répond, plus aigu, exactement sur la même note." % name
	var lines: Array = [
		{"who": CHLOE, "text": "Tu le reconnais… Tu es Griffe-Grise. Son papa." if with_her
			else "Tu sens son odeur sur moi… Tu es Griffe-Grise. Le papa %s." % French.de(name)},
		GESTES.cue(cry_line, func() -> void: _duet(griffe, little)),
	]
	if Game.flag(&"lettre_scellee"):
		lines.append_array([
			{"who": CHLOE, "text": "Hélène m'a demandé de te dire qu'elle va bien."},
			GESTES.cue("Griffe-Grise penche la tête. Il n'a pas l'air d'y croire tout à fait. Chloé non plus.",
				func() -> void: Stage.emote(griffe, "?")),
		])
	lines.append_array(_tin_box_lines(griffe, chloe))
	lines.append(GESTES.cue("Chloé gratte Griffe-Grise sous le menton. Il grogne, pour la forme… et ne bouge plus d'un poil.",
		func() -> void: _scratches_his_chin(chloe, griffe)))
	if with_her:
		lines.append(GESTES.cue("%s se roule en boule contre le flanc de son père. Pour la première fois de sa vie, il a l'air de n'avoir rien à prouver." % name,
			func() -> void: _curls_up_by(little, griffe)))
	else:
		lines.append({"who": CHLOE, "text": "Je te ramènerai %s. Promis." % name})
	await S.say(lines)
	Stage.take_thing(S.actor("BoiteGriffe"))
	Toast.say(S.world().get_tree(), "Page de l'Ancien : Griffe-Grise")
	return little


## The tin box he digs out and pushes to Chloé, and the Ancien's page in it.
static func _tin_box_lines(griffe: Node, chloe: Player) -> Array:
	return [
		GESTES.cue("Le vieux raptor gratte la mousse au pied de son rocher et en tire une boîte en fer-blanc, toute cabossée. Il la pousse vers Chloé, du bout du museau.",
			func() -> void: _digs_out(griffe, chloe)),
		{"text": "Sur le couvercle, de l'écriture penchée d'Hélène : « Pour Chloé. Il te la donnera. »"},
		{"letter": ANCIEN_PAGE, "sign": "— H."},
		{"flag": &"found_journal_ancien"},
	]


## The stolen hatchling was the Velociraptor (Chloé chose another egg), back from Brac's camp:
## Griffe-Grise's little one. He knows him at once, lies down to be at his height (page 10),
## gives Chloé the Ancien's page, then pushes the little one back to her, as he did the egg.
static func _stolen_reunion(griffe: Node, little: Dino) -> void:
	var name := little.nickname
	var chloe := Stage.chloe()
	var small := GESTES.stand_in(little)
	await S.say([
		GESTES.cue("Griffe-Grise se fige. Il ne regarde plus Chloé. Il regarde %s." % name,
			func() -> void: Stage.turn_to(griffe, _px_of(small)); Stage.emote(griffe, "!")),
		GESTES.cue("%s se cache derrière la jambe de Chloé : chez Brac, il a appris à avoir peur des grands." % name,
			func() -> void: _hides_behind(small, chloe, griffe)),
		GESTES.cue("Alors le vieux raptor fait une chose étrange. Il se couche dans la mousse, tout doucement, jusqu'à être à la hauteur du petit. Et il attend.",
			func() -> void: GESTES.lie_down(griffe, 1.8)),
		GESTES.cue("%s avance. Un pas. Puis un autre. Et il pose son museau contre celui du vieux raptor." % name,
			func() -> void: _step_by_step(small, griffe)),
	])
	raptor_cry("neutre", -6.0, OLD_PITCH)
	var lines: Array = [
		GESTES.cue("Griffe-Grise pousse un cri doux et grave. %s lui répond, plus aigu, exactement sur la même note." % name,
			func() -> void: _duet(griffe, small)),
		{"who": CHLOE, "text": "Tu le connais… C'est ton petit ?"},
	]
	if not Game.flag(&"found_journal_ancien"):
		lines.append_array(_tin_box_lines(griffe, chloe))
		lines.append({"who": CHLOE, "text": "Un mois sans dormir, pour cet œuf… Et on te l'a volé, puis on l'a gavé d'ambre noir."})
	lines.append_array([
		GESTES.cue("Griffe-Grise se relève. Du bout du museau, il pousse doucement %s vers Chloé. Comme l'œuf, il y a un an." % name,
			func() -> void: _pushes_back(griffe, small, chloe)),
		{"who": CHLOE, "text": "Tu veux qu'il reste avec moi ? … D'accord. Je veillerai sur lui. Promis."},
		{"flag": &"griffe_vole_reconnu"},
	])
	var page: bool = not Game.flag(&"found_journal_ancien")
	await S.say(lines)
	Stage.take_thing(S.actor("BoiteGriffe"))
	await GESTES.stand_in_back(small)
	Game.add_bond(little, 1)
	if page:
		Toast.say(S.world().get_tree(), "Page de l'Ancien : Griffe-Grise")


## Chloé chose another egg: he does not know her, but she smells of Hélène (the pages she carries).
static func _wary(griffe: Node) -> void:
	var chloe := Stage.chloe()
	_steps_closer(griffe, chloe, 2)   # « avance d'un pas. Puis d'un autre. »
	var pick := await Dialogue.choose("", "Griffe-Grise avance d'un pas. Puis d'un autre. Que fait Chloé ?", ["Ne pas bouger", "Reculer doucement"])
	var lines: Array = []
	if pick == 0:
		lines.append({"text": "Chloé ne bouge pas. Elle respire lentement, les mains ouvertes. Pas d'ordre, pas de cri, pas de peur : juste elle."})
	else:
		lines.append(GESTES.cue("Chloé recule d'un pas. Griffe-Grise avance d'un pas. Elle recule encore ; il avance encore. Ce n'est pas une chasse : il la renifle.",
			func() -> void: _back_and_forth(chloe, griffe)))
	lines.append_array([
		GESTES.cue("Le vieux raptor tourne autour d'elle. Il plonge le museau dans la sacoche où elle range les pages du journal… et il s'arrête net.",
			func() -> void: _circles(griffe, chloe)),
		GESTES.cue("Il reste là, les yeux fermés, à respirer le vieux papier. L'odeur du Cabinet, de l'encre et de l'ambre. L'odeur d'Hélène.",
			func() -> void: Stage.bow(griffe, 3.0)),
		{"who": CHLOE, "text": "Tu la connaissais… Tu es un de ses dinos, toi aussi."},
	])
	var lead := Game.lead_dino()
	if lead:
		var companion: Node2D = S.world().companion
		lines.append(GESTES.cue("%s s'approche, prudent. Griffe-Grise le renifle à peine et le laisse passer : l'ami d'Hélène a décidé que vous faisiez partie des siens." % lead.nickname,
			func() -> void: GESTES.lean(companion, _px_of(griffe), 10.0, 1.2); GESTES.lean(griffe, companion.global_position, 8.0, 1.0)))
	# Her own dino's mother waits elsewhere (docs/lore.md, the Anciens).
	var mine := starter()
	var home_region: String = {"ankylosaurus": "le Désert", "parasaurolophus": "le Marais"}.get(str(Game.flag(&"starter")), "")
	if mine and home_region != "":
		lines.append({"who": CHLOE, "text": "(Quelque part dans %s, la mère %s l'attend peut-être comme ça, elle aussi.)" % [home_region, French.de(mine.nickname)]})
	await S.say(lines)


## What he kept: a poacher's trap he tore open, smelling of ash (someone hunts in the Forêt).
static func _the_trap(griffe: Node) -> void:
	var chloe := Stage.chloe()
	await S.say([GESTES.cue("Griffe-Grise plonge la tête derrière son rocher et revient avec quelque chose entre les dents. Il le laisse tomber aux pieds de Chloé.",
		func() -> void: _fetches(griffe, chloe))])
	var seen_ash: bool = Game.flag(&"maia_defi_1") or Game.flag(&"roc_nuit_niee")
	await S.say([
		GESTES.cue("Clang. Un piège à mâchoires d'acier, arraché de sa chaîne. Les dents de fer sont tordues, écartées de force. Il a fallu des griffes terribles pour ouvrir ça.",
			func() -> void:
				Audio.play_sfx(LATCH, -2.0); Stage.shake(2.5, 0.2); Stage.emote(chloe, "!")
				Stage.show_thing("piege_machoires", chloe.global_position + Vector2(18.0, 26.0), "PiegeGriffe")),
		{"who": CHLOE, "text": "C'est ça, ta blessure… Quelqu'un pose des pièges dans la Forêt. Des braconniers."},
		{"text": "Le piège sent la cendre froide."},
		{"who": CHLOE, "text": "(De la cendre. Encore.)" if seen_ash else "(De la cendre ? Il n'y a pas le moindre feu, ici.)"},
	])
	Stage.take_thing(S.actor("PiegeGriffe"))


## He calls towards the north-west; the pack answers, and no voice leads it. The clearing.
## He goes back to his rock (`home`) with the last line.
static func _the_pack(griffe: Node, home: Vector2) -> void:
	var chloe := Stage.chloe()
	await S.say([GESTES.cue("Griffe-Grise se tourne vers le nord-ouest, lève le museau et appelle. Un long cri grave, qui roule entre les arbres.",
		func() -> void: _calls_north_west(griffe))])
	raptor_cry("neutre", -18.0, 1.08)
	await S.wait(0.3)
	raptor_cry("neutre", -20.0, 0.97)
	await S.wait(0.3)
	raptor_cry("attaque", -21.0, 1.12)
	var lines: Array = [
		GESTES.cue("Au loin, la meute répond. Des dizaines de voix qui se chevauchent… et pas une qui commande.",
			func() -> void: _all_look(chloe, S.world().companion, NORTH_WEST)),
		{"who": CHLOE, "text": "Ils avaient un chef, c'est ça ? Et quelqu'un l'a pris."},
		{"text": "Le vieux raptor ne quitte pas le nord-ouest des yeux. Par là-bas, il y a une clairière où les fougères poussent plus haut que partout ailleurs. Dans la Forêt, tout le monde sait à qui elle est."},
	]
	if Game.flag(&"clairiere_vue"):
		lines.append({"who": CHLOE, "text": "La clairière aux fougères écrasées… C'était la sienne. Le chef de la meute dormait là, et on l'a emmené de force."})
	else:
		lines.append({"who": CHLOE, "text": "C'est là-bas qu'il vivait, votre chef ? D'accord. J'y vais."})
	lines.append(GESTES.cue("Griffe-Grise ne la suit pas. Ce ravin est le sien, et il est trop vieux pour la meute. Mais il garde un œil ouvert, tourné vers la clairière.",
		func() -> void: _back_to_his_rock(griffe, home)))
	await S.say(lines)
	await GESTES.halt(griffe)   # (still on his way back)


## A short line when Chloé comes back (the next one each time), with what it says he does. Vif,
## when a line shows him, is brought out of her party for it (cast « vif », given back after).
static func _griffe_again(griffe: Node, cast: Dictionary) -> Dictionary:
	var chloe := Stage.chloe()
	var vif := vif_dino()
	if vif == null and Game.flag(&"griffe_vole_reconnu"):   # his stolen little one, back
		vif = ForetCamp.recovered()
	if Game.flag(&"sceau_foret") and not Game.flag(&"griffe_apres_sceau"):
		Game.set_flag(&"griffe_apres_sceau")
		var sigh := "Griffe-Grise renifle Chloé : elle sent le Chef de Meute. Le vieux raptor ferme les yeux et pousse un long soupir, comme quelqu'un qui va enfin pouvoir dormir."
		var with_vif: bool = vif != null and Game.party.has(vif)
		if with_vif:
			sigh += " %s se couche contre son flanc. Ils s'endorment tous les deux." % vif.nickname
		return GESTES.cue(sigh, func() -> void:
			if with_vif:   # (at her side or out of her party, he walks to his father's flank)
				cast["vif"] = GESTES.stand_in(vif)
				_curls_up_by(cast["vif"], griffe)
			await GESTES.lean(griffe, chloe.global_position, 10.0, 1.0)
			Stage.emote(griffe, "…")
			GESTES.lie_down(griffe, 1.6, DOZING))
	if Game.flag(&"camp_arrive") and not Game.flag(&"sceau_foret") and not Game.flag(&"griffe_apres_camp"):
		Game.set_flag(&"griffe_apres_camp")
		return GESTES.cue("Griffe-Grise renifle Chloé : la boue du camp, la cendre, l'ambre noir. Il retrousse les babines, et regarde vers l'ouest sans cligner des yeux.",
			func() -> void: _sniffs_then_growls_west(griffe, chloe))
	if Game.flag(&"clairiere_vue") and not Game.flag(&"griffe_apres_clairiere") and not Game.flag(&"camp_arrive"):
		Game.set_flag(&"griffe_apres_clairiere")
		return GESTES.cue("Griffe-Grise renifle Chloé : elle sent la clairière, les fougères écrasées, la cendre. Il gronde tout bas, vers l'ouest.",
			func() -> void: _sniffs_then_growls_west(griffe, chloe))
	var little: Dino = ForetCamp.recovered()
	if little and ForetCamp.stolen_species() == &"velociraptor" and not Game.flag(&"griffe_vole_reconnu"):
		return GESTES.cue("Griffe-Grise renifle les mains de Chloé, longtemps. Puis il regarde derrière elle, comme s'il cherchait quelqu'un.",
			func() -> void: _sniffs_then_looks_behind(griffe, chloe))
	if Game.phase() == &"night":
		return GESTES.cue("Griffe-Grise somnole. Même endormi, il garde un œil entrouvert : les vieux raptors ne dorment jamais tout à fait.",
			func() -> void: Stage.emote(griffe, "…"))
	var n := int(Game.flag(&"griffe_grise_n"))
	Game.set_flag(&"griffe_grise_n", n + 1)
	if vif == null:
		return GESTES.cue(AGAIN[n % AGAIN.size()], func() -> void: _again_move(griffe, chloe, n % AGAIN.size()))
	if not Game.party.has(vif):
		return GESTES.cue("Griffe-Grise renifle les mains de Chloé, puis regarde derrière elle. Il cherche %s." % vif.nickname,
			func() -> void: _sniffs_then_looks_behind(griffe, chloe))
	var i := n % AGAIN_VIF.size()
	return GESTES.cue((AGAIN_VIF[i] as String).replace("%s", vif.nickname),
		func() -> void: _again_vif_move(griffe, chloe, i, vif, cast))


## What he does with each of the lines of AGAIN (by its index).
static func _again_move(griffe: Node, chloe: Player, i: int) -> void:
	match i:
		0:   # he opens an eye, knows her, closes it
			Stage.emote(griffe, "…")
		1:   # he sniffs her bag
			await GESTES.lean(griffe, chloe.global_position, 10.0, 0.9)
			GESTES.lean(griffe, chloe.global_position, 10.0, 0.9)
		2:   # a yawn
			Stage.rear(griffe, 1.1)
		3:   # he looks north-west
			Stage.turn_to(griffe, _px_of(griffe) + NORTH_WEST * 100.0)


## What he (and Vif) do with each of the lines of AGAIN_VIF (by its index): Vif at her side (her
## lead), or brought out of her party for the lines that show him (cast « vif »).
static func _again_vif_move(griffe: Node, chloe: Player, i: int, vif: Dino, cast: Dictionary) -> void:
	var companion: Node2D = S.world().companion if Game.lead_dino() == vif else null
	if companion == null and i != 3:   # (the chin scratch is Chloé's alone)
		companion = GESTES.stand_in(vif)
		cast["vif"] = companion
	match i:
		0:   # he opens an eye, sees Vif, closes it
			Stage.emote(griffe, "…")
		1:   # they sniff each other at length
			if companion:
				GESTES.lean(companion, _px_of(griffe), 10.0, 1.6)
			GESTES.lean(griffe, companion.global_position if companion else chloe.global_position, 10.0, 1.6)
		2:   # he jumps on his rock; Vif tries and lands beside it
			await Stage.hop(griffe, 1, 26.0)
			if is_instance_valid(companion):
				Stage.hop(companion, 1, 14.0)
		3:   # Chloé scratches his chin; he grumbles
			_scratches_his_chin(chloe, griffe)


## Where someone stands (world px), or Chloé's place when it is not there.
static func _px_of(actor) -> Vector2:
	if is_instance_valid(actor) and actor is Node2D:
		return (actor as Node2D).global_position
	var chloe := Stage.chloe()
	return chloe.global_position if chloe else Vector2.ZERO


## Vif creeps up towards his father, slowly, his neck stretched out, sniffing the air.
static func _creeps_up(little: DinoNpc, griffe: Node) -> void:
	if little == null or not is_instance_valid(griffe):
		return
	var to := _px_of(griffe).lerp(little.global_position, 0.5)
	await little.walk_to(to, 45.0)
	GESTES.lean(little, _px_of(griffe), 8.0, 1.2)


## The old raptor comes up close to Chloé and sniffs her hands.
static func _sniffs_her(griffe: Node, chloe: Player) -> void:
	if not is_instance_valid(griffe):
		return
	await griffe.walk_to(_px_of(griffe).lerp(chloe.global_position, 0.5), 90.0)
	await GESTES.lean(griffe, chloe.global_position, 10.0, 1.0)
	GESTES.lean(griffe, chloe.global_position, 10.0, 1.0)


## Griffe-Grise's deep call, then the little one's answer on the same note.
static func _duet(griffe: Node, little: DinoNpc) -> void:
	Stage.rear(griffe, 1.2)
	if little == null:
		return
	await S.wait(1.1)
	Stage.rear(little, 0.8)
	GESTES.stand_in_cry(little)


## He scratches the moss at the foot of his rock, pulls out the tin box and nudges it to Chloé.
static func _digs_out(griffe: Node, chloe: Player) -> void:
	if not is_instance_valid(griffe):
		return
	Stage.turn_to(griffe, _px_of(griffe) + Vector2(-100.0, 20.0))
	await Stage.bow(griffe, 0.5)
	await Stage.tremble(griffe, 1.0, 2.0)
	if is_instance_valid(griffe):
		Stage.show_thing("boite_fer_blanc", _px_of(griffe).lerp(chloe.global_position, 0.45), "BoiteGriffe")
		Stage.turn_to(griffe, chloe.global_position)
		GESTES.lean(griffe, chloe.global_position, 12.0, 0.9)


## Chloé scratches him under the chin; he grumbles for form's sake.
static func _scratches_his_chin(chloe: Player, griffe: Node) -> void:
	GESTES.lean(chloe, _px_of(griffe), 8.0, 1.4)
	await S.wait(0.6)
	raptor_cry("neutre", -12.0, OLD_PITCH)
	Stage.emote(griffe, "♥")


## Vif curls up against his father's flank.
static func _curls_up_by(little: DinoNpc, griffe: Node) -> void:
	if little == null or not is_instance_valid(griffe):
		return
	var side := 1.0 if little.global_position.x >= _px_of(griffe).x else -1.0
	await little.walk_to(_px_of(griffe) + Vector2(side * 30.0, 10.0), 50.0)
	Stage.turn_to(little, _px_of(griffe))
	GESTES.lie_down(little, 1.2)
	Stage.emote(little, "♥")


## The little one hides behind Chloé's leg, trembling (on her far side from the old raptor).
static func _hides_behind(small: DinoNpc, chloe: Player, griffe: Node) -> void:
	if small == null or chloe == null:
		return
	var away := 1.0 if chloe.global_position.x >= _px_of(griffe).x else -1.0
	await small.walk_to(chloe.global_position + Vector2(away * 26.0, -8.0), 110.0)
	Stage.turn_to(small, _px_of(griffe))
	Stage.tremble(small, 2.0, 1.5)


## « Un pas. Puis un autre. »: the little one goes up to the old raptor in two steps.
static func _step_by_step(small: DinoNpc, griffe: Node) -> void:
	if small == null or not is_instance_valid(griffe):
		return
	var from := small.global_position
	var to := _px_of(griffe).lerp(from, 0.35)
	await small.walk_to(from.lerp(to, 0.5), 40.0)
	await S.wait(0.7)
	if is_instance_valid(small):
		await small.walk_to(to, 40.0)
		GESTES.lean(small, _px_of(griffe), 8.0, 1.4)


## He gets up, and nudges the little one back towards Chloé.
static func _pushes_back(griffe: Node, small: DinoNpc, chloe: Player) -> void:
	await Stage.rear(griffe, 0.9)
	if small == null or not is_instance_valid(small):
		return
	GESTES.lean(griffe, small.global_position, 12.0, 0.9)
	await S.wait(0.4)
	if is_instance_valid(small):
		small.walk_to(GESTES.beside_chloe(small, -1.0, 8.0, 30.0), 60.0)


## He steps closer to her, `steps` times.
static func _steps_closer(griffe: Node, chloe: Player, steps: int) -> void:
	for i in steps:
		if not is_instance_valid(griffe):
			return
		await griffe.walk_to(_px_of(griffe).move_toward(chloe.global_position, 14.0), 40.0)
		await S.wait(0.6)


## She steps back; he steps forward; again.
static func _back_and_forth(chloe: Player, griffe: Node) -> void:
	for i in 2:
		if not is_instance_valid(griffe):
			return
		await Stage.recoil(chloe, _px_of(griffe), 14.0)
		await S.wait(0.3)
		await griffe.walk_to(_px_of(griffe).move_toward(chloe.global_position, 14.0), 45.0)
		await S.wait(0.5)


## He walks round her, then plunges his snout into her bag, and stops dead.
static func _circles(griffe: Node, chloe: Player) -> void:
	if not is_instance_valid(griffe):
		return
	var start := _px_of(griffe)
	var centre := chloe.global_position
	var r := maxf(46.0, start.distance_to(centre))
	var angle := (start - centre).angle()
	var round_trip: Array = []
	for k in range(1, 5):
		round_trip.append(centre + Vector2.from_angle(angle + k * TAU / 4.0) * r)
	await GESTES.walk(griffe, round_trip, 90.0)
	if is_instance_valid(griffe):
		Stage.turn_to(griffe, centre)
		GESTES.lean(griffe, centre, 12.0, 1.6)
		Stage.emote(griffe, "!")


## He dives behind his rock and comes back with something in his jaws, which he drops at her feet.
static func _fetches(griffe: Node, chloe: Player) -> void:
	if not is_instance_valid(griffe):
		return
	Stage.turn_to(griffe, _px_of(griffe) + Vector2(-100.0, -20.0))
	await GESTES.lean(griffe, _px_of(griffe) + Vector2(-100.0, 0.0), 16.0, 1.2)
	if is_instance_valid(griffe):
		Stage.turn_to(griffe, chloe.global_position)
		await S.wait(0.3)
		GESTES.lean(griffe, chloe.global_position, 12.0, 0.8)


## He turns to the north-west, raises his snout and calls.
static func _calls_north_west(griffe: Node) -> void:
	Stage.turn_to(griffe, _px_of(griffe) + NORTH_WEST * 100.0)
	raptor_cry("neutre", -2.0, OLD_PITCH)
	Stage.rear(griffe, 1.6)


## He goes back to his rock, one eye on the clearing (north-west).
static func _back_to_his_rock(griffe: Node, home: Vector2) -> void:
	if not is_instance_valid(griffe):
		return
	await griffe.walk_to(home, 110.0)
	if is_instance_valid(griffe):
		Stage.turn_to(griffe, home + NORTH_WEST * 100.0)


## He sniffs Chloé, then growls low towards the west (the camp).
static func _sniffs_then_growls_west(griffe: Node, chloe: Player) -> void:
	await GESTES.lean(griffe, chloe.global_position, 10.0, 1.0)
	if not is_instance_valid(griffe):
		return
	Stage.turn_to(griffe, _px_of(griffe) + Vector2(-100.0, 0.0))
	raptor_cry("neutre", -12.0, OLD_PITCH)
	Stage.tremble(griffe, 1.2, 1.5)


## He sniffs her hands at length, then looks behind her, as if for someone.
static func _sniffs_then_looks_behind(griffe: Node, chloe: Player) -> void:
	await GESTES.lean(griffe, chloe.global_position, 10.0, 1.4)
	if is_instance_valid(griffe) and chloe:
		Stage.turn_to(griffe, chloe.global_position + (chloe.global_position - _px_of(griffe)))
		Stage.emote(griffe, "?")


# ------------------------------------------------------------------ the empty clearing

## The clearing of the giant ferns, where the pack's leader lived: empty, and the Ombre Noire's
## marks everywhere. A hook towards step 2.
static func clairiere_vide(_who: Node) -> void:
	if Game.flag(&"clairiere_vue"):
		var n := int(Game.flag(&"clairiere_n"))
		Game.set_flag(&"clairiere_n", n + 1)
		var pool: Array = CLEARING_BACK if Game.flag(&"sceau_foret") else CLEARING_AGAIN
		await S.say([{"text": pool[n % pool.size()]}])
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var chloe: Player = w.player
	var griffe: bool = Game.flag(&"griffe_grise_vu")
	await S.say([
		{"text": "La clairière aux fougères géantes. Elles sont si hautes qu'elles font de l'ombre aux arbres… mais au milieu, elles sont couchées, écrasées, comme si quelque chose d'énorme s'était débattu ici."},
		{"text": "Tout autour, un anneau de pieux plantés dans la terre, reliés par des cordes coupées. Une cage sans toit ni porte. Vide."},
		GESTES.cue("Dans la boue, une empreinte à deux doigts seulement : un raptor, qui marche la grande griffe relevée. Sauf que celle-ci est grande comme une bassine.",
			func() -> void: Stage.bow(chloe, 1.6)),
		GESTES.cue("Un raptor grand comme ÇA ?", func() -> void: Stage.emote(chloe, "!"); Stage.hop(chloe, 1, 12.0), CHLOE),
		{"text": "Ça sent la cendre froide, comme le piège de Griffe-Grise." if griffe else "Ça sent la cendre froide. Pourtant, aucun feu n'a brûlé ici."},
		GESTES.cue("Entre deux pieux, quelque chose de blanc dépasse de la boue. Chloé le ramasse : un morceau d'os taillé, poli, percé d'un trou pour l'œil.",
			func() -> void: Stage.bow(chloe, 0.9)),
		{"who": CHLOE, "text": "Un masque d'os… comme celui du voleur du Cabinet. L'Ombre Noire est venue jusqu'ici."},
		{"who": CHLOE, "text": "(Ceux qui ont volé le troisième œuf…)"},
	])
	var lead := Game.lead_dino()
	var furrows := "De profonds sillons partent de la cage : on a traîné quelque chose de très lourd… vers l'ouest."
	if lead:
		await S.say([GESTES.cue("%s gronde, le nez au ras du sol. %s" % [lead.nickname, furrows],
			func() -> void: _nose_to_the_ground(w.companion, chloe))])
	else:
		await S.say([GESTES.cue(furrows, func() -> void: Stage.turn_to(chloe, chloe.global_position + Vector2(-100.0, 0.0)))])
	Audio.play_sfx(LEAVES, -6.0)
	raptor_cry("neutre", -12.0, 1.05)
	var watchers := _watchers(chloe)
	await S.say([
		GESTES.cue("Entre les fougères, des yeux jaunes s'allument. Trois Deinonychus observent Chloé, sans bouger. Ils ne chassent pas. Ils attendent quelqu'un.",
			func() -> void: _eyes_in_the_ferns(watchers, chloe)),
		GESTES.cue("Puis les fougères se referment, et ils ne sont plus là.",
			func() -> void: _gone_in_the_ferns(watchers)),
		{"who": CHLOE, "text": "Le chef de la meute… Griffe-Grise avait raison : on l'a pris." if griffe else "Leur chef. C'est lui qu'on a emmené, et c'est lui qu'ils appellent."},
		{"who": CHLOE, "text": "Tiens bon, qui que tu sois. On va te retrouver."},
		{"flag": &"clairiere_vue"},
	])
	Game.award_team_xp(XP_CLAIRIERE)
	Save.save_game()
	S.lock(false)


## Her dino growls with its nose to the ground, and follows the furrows westwards with its eyes.
static func _nose_to_the_ground(companion: Node, chloe: Player) -> void:
	Stage.cry(companion)
	Stage.turn_to(companion, chloe.global_position + Vector2(-100.0, 0.0))
	await Stage.bow(companion, 1.6)
	Stage.turn_to(chloe, chloe.global_position + Vector2(-100.0, 0.0))


## The three Deinonychus in the ferns around the clearing, not seen yet (see _eyes_in_the_ferns).
static func _watchers(chloe: Player) -> Array:
	var w = S.world()
	var three: Array = []
	if w == null or w.get("region") == null:
		return three
	for i in WATCHERS.size():
		var d := DinoNpc.new()
		d.name = "Guetteur%d" % i
		d.species_id = &"deinonychus"
		d.size_scale = 0.95
		d.position = chloe.global_position + (WATCHERS[i] as Vector2) * S.CELL
		d.flip = d.position.x > chloe.global_position.x   # looking at her
		d.modulate.a = 0.0
		w.region.entities.add_child(d)
		d.collision_layer = 0
		three.append(d)
	return three


## Yellow eyes light up among the ferns: one by one, three Deinonychus appear, looking at Chloé.
static func _eyes_in_the_ferns(watchers: Array, chloe: Player) -> void:
	for d: DinoNpc in watchers:
		if not is_instance_valid(d):
			continue
		Stage.fade_in(d, 0.7)
		Stage.glow(d, Color(1.5, 1.4, 0.6), 1, 1.0)
		Stage.turn_to(chloe, d.global_position)
		await S.wait(0.6)


## The ferns close again, and they are gone.
static func _gone_in_the_ferns(watchers: Array) -> void:
	Audio.play_sfx(LEAVES, -8.0)
	for d: DinoNpc in watchers:
		Stage.fade_out(d, 0.8, true)


# ------------------------------------------------------------------ helpers

## Chloé's dino from the Cabinet (the one she chose, whatever she named it), or null: the first
## of its species in the party, then in the box.
static func starter() -> Dino:
	var id := str(Game.flag(&"starter"))
	if id == "" or id == "false":
		return null
	for d: Dino in Game.party:
		if String(d.species().id) == id:
			return d
	for d: Dino in Game.box:
		if String(d.species().id) == id:
			return d
	return null


## Vif (Chloé's Velociraptor from the Cabinet, Griffe-Grise's little one), or null when she
## chose another egg.
static func vif_dino() -> Dino:
	return starter() if Game.flag(&"starter") == "velociraptor" else null


## A raptor's call, not tied to anyone on screen (the pack in the distance, Griffe-Grise's deep
## voice): quieter when far, lower when old.
static func raptor_cry(kind: String, volume_db: float, pitch := 1.0) -> void:
	var w = S.world()
	var path := RAPTOR_CRY % kind
	if w == null or not ResourceLoader.exists(path):
		return
	var p := AudioStreamPlayer.new()
	p.bus = Audio.CRIES_BUS
	p.stream = load(path)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	w.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
