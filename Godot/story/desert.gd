class_name Desert
## Chapter 4, the Désert Aride (docs/histoire.md, ch. 4), out in the sand: arriving where the
## Marais dries up (cracked mud, a salt lake, mirages) on the tracks of Brac's cart; Tante
## Sirocco, an old fossil hunter who knew Hélène, at the edge of the Cimetière des Géants (she
## saw Brac pass with the chained Carnotaurus, warns about the storms, asks for five of the six
## buried fossils); the Vieux Rempart, Hélène's old Ankylosaurus, in the walled canyon (Bastion's
## mother: a reunion and the Ancien's page when he is Chloé's); Maïa's fourth challenge at the
## oasis (Caillou has become a Triceratops); at dusk, a boat without a lantern towards the Côte.
## The sanctuary, Brac, the chase and the Carnotaurus are in story/desert_sanctuaire.gd.
## Flags: desert_arrivee, sirocco_vue, fossiles_rendus, rempart_vu (DialogueDesert),
## rempart_rencontre, found_journal_ancien_rempart, rempart_bastion_reconnu, maia_oasis_vue,
## maia_defi_4, cote_annonce, roc_sceau_desert; sirocco_n, rempart_n (lines).
## (rempart_ouvert: the fallen rocks, an Obstacle. Fossils: fossile_1 … 6, DigSpots. Pages 17
## to 20: Pickups, DialogueDesert page_17 … page_20.)

const S := preload("res://story/story.gd")
const P := preload("res://story/desert_places.gd")
const A := preload("res://story/desert_ask.gd")
const GESTES := preload("res://story/foret_gestes.gd")   # (stand_in: a dino of her party, out for a scene)
const CHLOE := "Chloé"
const SIROCCO := "Tante Sirocco"
const MAIA := "Maïa"
const ROC := "Prof. Roc"
const CRY := "res://assets/audio/cries/%s-%s.mp3"
## The Vieux Rempart's voice: an armoured dino's call, old and very deep.
const OLD_PITCH := 0.62
## What the arrival shows as its lines speak of it (tiles): the Lac de sel, the dunes northwards.
const LAC_DE_SEL := Vector2(79.0, 88.0)
const DUNES_NORD := Vector2(100.0, 83.0)
## The mouth of the walled canyon, its fallen rocks marked by the tail club (tiles).
const EBOULIS := Vector2(28.5, 57.5)
## The dust a snort, a sigh or a fall raises (_puff): pale, to be seen on the sand.
const SAND_BITS: Array[Color] = [Color(1.0, 0.97, 0.9), Color(0.93, 0.87, 0.76), Color(0.78, 0.68, 0.55)]
## The wind turning at dusk (chapter 5): puffs of sand streaming from Chloé's feet towards the sea.
const WIND_TRACK := 8
## Amber light, in sparks (_sparkle).
const AMBER_BITS: Array[Color] = [Color(1.0, 0.86, 0.4), Color(1.0, 0.7, 0.2), Color(1.0, 0.97, 0.8)]
## Tante Sirocco's gift for the fossils (and the old brush, when ItemsDB has it).
const REWARD_COINS := 300
const REWARD_FERNS := 2
## Maïa's fourth challenge (checked by simulation, scratchpad/sim_desert.gd): Pouce the
## Iguanodon, her own hatchling, then Caillou — a Triceratops now. Moustique stays under the
## palms (he does not like sand).
const MAIA_LEVELS := {"pouce": 24, "starter": 24, "caillou": 24}
const XP_SIROCCO := 30
const XP_FOSSILS := 60
const XP_REMPART := 60
const XP_ANCIEN := 30
const XP_MAIA := 90
const XP_ANNONCE := 20
## The Ancien's page, kept warm under the Vieux Rempart for a year (Bastion's mother).
const REMPART_PAGE := [
	"Le Vieux Rempart",
	"Mon troisième réveil : une Ankylosaurus pas plus grande qu'une brouette, qui s'est couchée devant la porte du Cabinet et a refusé d'en bouger pendant trois jours. Anselme a dû passer par la fenêtre. Il l'a appelée « le Rempart ». « Vieux » est venu plus tard, tout seul.",
	"Chez les Ankylosaurus, c'est la mère qui couve : elle s'assoit sur son œuf, et elle ne bouge plus. Des semaines. Celui-ci, elle me l'a donné un matin en se levant, comme on ouvre une porte.",
	"Si elle te laisse la gratter sous le menton, c'est qu'elle t'a adoptée. Il faut monter sur une pierre. Ça vaut le coup.",
]
## The Vieux Rempart once she knows Chloé: with her little one at Chloé's side ("%s"), or not.
const REMPART_AGAIN_BASTION := [
	"Le Vieux Rempart ouvre un œil, voit %s, et le referme. Tout va bien.",
	"%s se couche contre sa mère, à l'ombre de sa carapace. Ils ronflent tous les deux. Sur la même note.",
	"Le Vieux Rempart souffle un petit nuage de sable sur %s. Il éternue. Elle a l'air très contente d'elle.",
	"Chloé grimpe sur une pierre pour gratter le Vieux Rempart sous le menton. Elle ne bouge pas d'une écaille.",
]
const REMPART_AGAIN := [
	"Le Vieux Rempart ouvre un œil, reconnaît Chloé, et le referme.",
	"Chloé s'adosse à la vieille carapace. Elle est tiède, comme une pierre restée au soleil.",
	"Le Vieux Rempart bâille. Ça dure longtemps. Très longtemps.",
	"Chloé a encore failli s'asseoir dessus. Le Vieux Rempart ne lui en veut pas : tout le monde le fait.",
]
## Tante Sirocco when there is nothing new (the next one each time).
const SIROCCO_AGAIN := [
	"Tu sais pourquoi on l'appelle le Cimetière des Géants ? Parce que « le Tas d'Os », ça faisait moins joli sur le panneau.",
	"Bois, ma caille. Dans le Désert, on boit avant d'avoir soif, et on rit avant d'avoir envie. Après, c'est trop tard pour les deux.",
	"Hélène perdait un chapeau par semaine, ici. J'en ai retrouvé dix. Le onzième, c'est un Oviraptor qui dort dedans.",
	"Ton Anselme est passé par ici le mois dernier, en pleine nuit, avec sa lanterne. Il m'a demandé si le Carnotaurus allait bien. Drôle de question, à minuit.",
	"Le sable, c'est de la montagne qui a pris son temps. Moi aussi, je prends mon temps. C'est pour ça que je suis encore là.",
]


# ------------------------------------------------------------------ arriving

## The first time in the Désert: the marsh dries up, heat and mirages, the tracks of a cart and
## of a big dino that did not want to walk (Brac), and Maïa's boots beside huge round prints.
## Afterwards: the dusk scene, if Maïa's challenge is over and it has not played.
static func arrival() -> void:
	if Game.flag(&"desert_arrivee"):
		if Game.flag(&"maia_defi_4") and not Game.flag(&"cote_annonce"):
			await annonce()
		elif Game.flag(&"cote_annonce") and not Game.flag(&"cote_ouverte"):
			Game.set_flag(&"cote_ouverte")   # a game saved before chapter 5: the wind has turned
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	await S.wait(0.8)
	var chloe := Stage.chloe()
	var dino = _companion()
	await S.say([
		_cue({"text": "Au bout du chemin, le Marais s'arrête d'un coup. L'eau a disparu : il ne reste qu'une boue craquelée, en carreaux, comme un vieux carrelage. Plus loin, un lac de sel brille si fort qu'il faut plisser les yeux."},
			func() -> void: Stage.look_at(S.at(LAC_DE_SEL.x, LAC_DE_SEL.y))),
		_cue({"text": "Et puis le sable. Des dunes à perte de vue, rouges, orange, dorées. L'air tremble de chaleur. Au loin, un lac bleu flotte au-dessus des dunes… et disparaît dès qu'on le regarde trop."},
			func() -> void: Stage.look_at(S.at(DUNES_NORD.x, DUNES_NORD.y), 1.2)),
		_cue({"who": CHLOE, "text": "(Un mirage… Le Désert fait des tours de magie.)"}, func() -> void: Stage.look_back()),
	])
	var lead := Game.lead_dino()
	if lead:
		await S.say([_heat(lead)])
	var tracks := func() -> void:
		Stage.bow(chloe, 1.3)
		_sniff(dino)
	var lines: Array = [
		_cue({"text": "Dans la boue séchée, des traces. Deux sillons de roues cerclées de fer, profonds. Et à côté, d'énormes empreintes à trois doigts, qui traînent, comme si la bête avançait à contrecœur."}, tracks),
		{"who": CHLOE, "text": "(Un chariot… et un très gros dino, qui ne voulait pas avancer.)"},
	]
	if Game.flag(&"papiers_brac_lus"):
		lines.append({"who": CHLOE, "text": "(« Le Carnotaurus Rouge, dans le Désert : LE PROCHAIN. » Brac est passé par ici.)"})
	else:
		lines.append({"who": CHLOE, "text": "(« Le Désert est grand, et là-bas, j'ai des amis. Des amis avec des DENTS. » Brac est passé par ici.)"})
	lines.append_array([
		{"text": "Par-dessus, plus fraîches, des traces de petites bottes. Chloé les connaît : ce sont celles de Maïa. Mais à côté d'elles marchent des empreintes rondes, larges comme des assiettes."},
		_cue({"who": CHLOE, "text": "(Maïa est passée par là. Mais avec qui ? Caillou n'a pas des pattes aussi grosses…)"}, func() -> void: Stage.emote(chloe, "?")),
	])
	var bastion: Dino = bastion_dino()
	if bastion and str(Game.flag(&"starter")) == "ankylosaurus" and Game.flag(&"found_journal_6"):
		var here := "On y est, %s." if Game.party.has(bastion) else "On y est. Si %s voyait ça."   # (else at the Cabinet)
		lines.append({"who": CHLOE, "text": ("(« Sa mère, le Vieux Rempart, garde un canyon du Désert. » " + here + ")") % bastion.nickname})
	lines.append({"flag": &"desert_arrivee"})
	await S.say(lines)
	_companion_back()
	Save.save_game()
	S.lock(false)


## How the lead dino takes the heat.
static func _heat_line(lead: Dino) -> String:
	match lead.species().family:
		&"raptor":
			return "%s tire la langue, se glisse dans l'ombre de Chloé et refuse d'en sortir." % lead.nickname
		&"armored":
			return "%s lève la tête et renifle le vent chaud, longtemps. Il n'a pas l'air d'avoir chaud du tout. Il a l'air… de rentrer à la maison." % lead.nickname
		&"hadrosaur":
			return "%s pousse un petit appel. Rien ne revient : ici, pas d'écho. Il a l'air très vexé." % lead.nickname
	return "%s halète dans la chaleur, et cherche un coin d'ombre qui n'existe pas." % lead.nickname


## The heat line, acted out by the lead dino at Chloé's side as it shows.
static func _heat(lead: Dino) -> Dictionary:
	var line := {"text": _heat_line(lead)}
	var dino = _companion()
	match lead.species().family:
		&"raptor":   # tongue out, into Chloé's shade
			var chloe := Stage.chloe()
			return _cue(line, func() -> void:
				Stage.emote(dino, "~")
				_companion_walk(chloe.global_position + Vector2(20.0, -12.0), 45.0))   # where her shadow falls
		&"armored":   # nose up to the hot wind, a long sniff
			return _cue(line, func() -> void:
				_fresh(dino)
				Stage.rear(dino, 1.8))
		&"hadrosaur":   # a call, no echo: vexed
			return _cue(line, func() -> void:
				Stage.cry(dino, &"neutre")
				_later(1.6, func() -> void: Stage.emote(dino, "…")))
	return _cue(line, func() -> void:   # panting, looking for a shade that is not there
		Stage.emote(dino, "~")
		_look_around(dino))


## The time of day changed in zone `zone` (Story.on_phase_changed): the dusk scene, when it is
## still to play and Chloé is free.
static func on_phase(zone: StringName) -> void:
	if zone != &"desert" or not Game.flag(&"maia_defi_4") or Game.flag(&"cote_annonce"):
		return
	var w = S.world()
	if w == null or w.player.busy:
		return
	await annonce()


# ------------------------------------------------------------------ Tante Sirocco

## Tante Sirocco, in front of her tent (Npc « Sirocco »): the meeting the first time (Hélène,
## Brac and the chained Carnotaurus, the storms, the fossils); her reward once Chloé has five
## fossils; otherwise a line and the questions (DesertAsk). At night, she sleeps.
static func sirocco(who: Node) -> void:
	if not Game.flag(&"sirocco_vue"):
		await _sirocco_meeting(who)
		return
	if P.fossils_found() >= P.FOSSILS_WANTED and not Game.flag(&"fossiles_rendus"):
		await _fossils_reward(who)
		return
	if Game.phase() == &"night":
		await S.say([{"text": "Tante Sirocco dort sous sa tente, un Oviraptor roulé en boule sur le ventre. Elle ronfle comme une dune qui s'écroule."}])
		return
	if await S.clins().sirocco_dilo(who):   # (a Dilophosaurus in the party: no frill, no venom… really?)
		return
	await A.menu(&"sirocco", SIROCCO, _sirocco_again(), A.sirocco_topics())


static func _sirocco_meeting(who: Node) -> void:
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var chloe := Stage.chloe()
	_sit(who, 0.1, 0.4)   # sitting cross-legged
	var dusting := func() -> void:
		var below: Vector2 = (who as Node2D).global_position + Vector2(0.0, 40.0)
		for i in 3:
			await _reach(who, below, 5.0, 0.6)
	var stands_up := func() -> void:
		await _get_up(who, 0.7)
		Stage.emote(who, "!")
	await S.say([
		_cue({"text": "Devant une tente rapiécée, une vieille dame est assise en tailleur. Un foulard couleur de sable, des lunettes de soudeur relevées sur le front, et un pinceau entre les dents."},
			func() -> void: _step_aside(who)),
		_cue({"text": "Elle époussette une vertèbre énorme, tout doucement, comme on coiffe un enfant."}, dusting),
		_cue({"who": SIROCCO, "text": "Pas un pas de plus, ma caille ! Tu marches sur un Majungasaurus."}, func() -> void: Stage.emote(chloe, "!")),
		_cue({"text": "Chloé baisse les yeux. Sous ses chaussures, dans le sable, dépasse une rangée de côtes pétrifiées, longues comme des rames."},
			func() -> void: Stage.bow(chloe, 1.4)),
		{"who": SIROCCO, "text": "Il est mort depuis soixante-six millions d'années, il ne dira rien. Mais c'est une question de politesse."},
		_cue({"text": "La vieille dame se lève, remonte ses lunettes… et s'arrête net."}, stands_up),
		{"who": SIROCCO, "text": "Ces yeux-là… Par les dents du soleil. Tu es la petite d'Hélène."},
		{"who": CHLOE, "text": "Vous connaissiez ma grand-mère ?"},
		{"who": SIROCCO, "text": "Si je la connaissais ! On a déterré la moitié de ce cimetière, elle et moi. Elle cherchait les dinos qui dorment ; moi, ceux qui ne se réveilleront jamais. On n'était jamais d'accord, et on riait tout le temps."},
		{"who": SIROCCO, "text": "Tout le monde m'appelle Tante Sirocco. Comme le vent chaud : j'arrive sans prévenir, je repars avec tout ce qui traîne, et je mets du sable partout."},
	])
	var cast := {}   # Bastion out of her party while she looks at him (cast « little »), when not her lead
	await S.say(_sirocco_rempart(who, cast))
	await _little_back(cast.get("little"))
	await S.say(_sirocco_brac())
	await S.say(_sirocco_fossils())
	Game.set_flag(&"sirocco_vue")
	Game.award_team_xp(XP_SIROCCO)
	Save.save_game()
	S.lock(false)


## Sirocco and the Vieux Rempart: she knows Bastion at a glance (his mother's shell). Bastion at
## Chloé's side, or brought out of her party for it (cast « little »).
static func _sirocco_rempart(who: Node, cast: Dictionary) -> Array:
	var bastion: Dino = bastion_dino()
	if bastion and Game.party.has(bastion):
		var stares := func() -> void:
			var dino: Node2D = _little_on_stage(bastion)
			if dino is DinoNpc:
				cast["little"] = dino
			if dino:
				Stage.turn_to(who, dino.global_position)
			_later(1.2, func() -> void: Stage.emote(who, "…"))
		return [
			_cue({"text": "Tante Sirocco se fige. Elle regarde %s. Longtemps." % bastion.nickname}, stares),
			{"who": SIROCCO, "text": "Cette carapace… ce museau têtu… Ma caille, ce petit-là, c'est un petit du Vieux Rempart. J'en mettrais mon pinceau au feu."},
			{"who": CHLOE, "text": "Sa maman ! Hélène m'a écrit qu'elle garde un canyon du Désert."},
			{"who": SIROCCO, "text": "Le canyon muré, à l'ouest. Elle y dort depuis que les rochers sont tombés, et plus personne n'y entre. Mais un petit qui charge comme sa mère… ça, ça passerait."},
		]
	var lines: Array = [
		{"who": SIROCCO, "text": "Et dans le canyon muré, à l'ouest, dort une vieille amie d'Hélène : le Vieux Rempart. Une Ankylosaurus grande comme ma tente. Des rochers sont tombés devant l'entrée ; depuis, plus personne n'y entre."},
		{"who": SIROCCO, "text": "Il faudrait un dino qui charge, pour passer. Et de la patience, pour la réveiller."},
	]
	if bastion:
		lines.append({"who": CHLOE, "text": "(Le Vieux Rempart… la maman %s !)" % French.de(bastion.nickname)})
	return lines


## What Sirocco saw: Brac and the chained Carnotaurus, going north; the storms.
static func _sirocco_brac() -> Array:
	return [
		{"who": CHLOE, "text": "Tante Sirocco… Vous n'auriez pas vu passer un grand monsieur roux ? Avec un masque d'os relevé sur le front ?"},
		{"who": SIROCCO, "text": "Le braillard au chariot ? Hier soir. Il a traversé mon cimetière sans dire bonjour aux morts. Mal élevé."},
		{"who": SIROCCO, "text": "Et dans sa cage, il y avait un grand dino rouge, avec deux cornes au-dessus des yeux. Le Carnotaurus Rouge, ma caille. Le gardien du Désert."},
		{"who": SIROCCO, "text": "Ses yeux étaient violets. Et il tremblait. Un Carnotaurus qui tremble… Soixante ans que je vis dans ce sable, je n'avais jamais vu ça."},
		{"who": CHLOE, "text": "De l'ambre noir… Ils lui en ont fait avaler."},
		{"who": SIROCCO, "text": "Ils sont partis vers le nord, vers le sanctuaire des Vents. Là où le vent chante dans la falaise."},
		{"who": SIROCCO, "text": "Et écoute bien Tante Sirocco : quand le ciel devient jaune, c'est que la tempête arrive. Alors tu restes près de tes dinos, et tu avances le nez au ras du sol. Le Désert n'aime pas qu'on se dépêche."},
	]


## Her request: five of the six fossils buried in the cemetery, found with a nose (Flair).
static func _sirocco_fossils() -> Array:
	var lines: Array = [
		{"who": SIROCCO, "text": "Maintenant, un service. Mes vieux genoux ne creusent plus comme avant. Dans ce cimetière, il y a six fossiles enfouis : je les sens d'ici. Rapporte-m'en cinq, et je te ferai un cadeau digne d'Hélène."},
		{"who": CHLOE, "text": "Comment on les trouve ?"},
	]
	var nose := Game.ability_user(&"flair")
	if nose:
		lines.append({"who": SIROCCO, "text": "Avec un nez, pardi ! Et ton %s a le museau qu'il faut. Promène-le dans le cimetière : il te montrera la terre remuée." % nose.nickname})
	else:
		lines.append({"who": SIROCCO, "text": "Avec un nez, pardi ! Un dino qui a du flair : un Compsognathus, un Troodon… ou un Oviraptor. Ils nichent dans les canyons, ces petits voleurs d'œufs, et ils déterrent tout ce qui dépasse."})
		for d: Dino in Game.box:
			if Abilities.has(d, &"flair"):
				lines.append({"who": CHLOE, "text": "(Mon %s a du flair… mais il attend au Cabinet. Je peux le faire venir depuis mon Dinodex.)" % d.nickname})
				break
	lines.append({"who": SIROCCO, "text": "Et fais attention où tu mets les pieds. Politesse !"})
	return lines


## Five fossils (or six): she studies them, gives them back (« un os de l'île reste sur
## l'île »), and gives Chloé coins, ferns, her old brush and a drawing of Hélène.
static func _fossils_reward(who: Node) -> void:
	S.lock(true)
	var n := P.fossils_found()
	var chloe := Stage.chloe()
	var lays_them := func() -> void:
		await _step_aside(who)
		await Stage.bow(chloe, 0.9)
		await Stage.bow(who, 0.8)
		_reach(who, chloe.global_position, 6.0, 0.6)
	var lines: Array = [
		_cue({"text": "Chloé pose ses fossiles un à un sur la natte de Tante Sirocco. La vieille dame les prend, les tourne, les renifle, les tapote du bout de son pinceau."}, lays_them),
		_cue({"who": SIROCCO, "text": "Une griffe de Majungasaurus… une vertèbre de Stygimoloch… et ça… Par les dents du soleil ! Une dent d'œuf ! La toute petite dent qui sert à casser la coquille !"},
			func() -> void: _later(1.6, func() -> void: Stage.hop(who, 2, 8.0))),
	]
	if n > P.FOSSILS_WANTED:
		lines.append({"who": SIROCCO, "text": "Et tu les as TOUS trouvés ? Les six ?! Même celui que j'avais caché exprès pour voir ? … Ma caille, tu as le nez d'Hélène. Et ton dino aussi."})
	else:
		lines.append({"who": SIROCCO, "text": "Tu as l'œil, ma caille. Et ton nez à quatre pattes aussi."})
	var drawing := func() -> void:
		await Stage.bow(who, 1.6)
		_reach(who, chloe.global_position, 8.0, 0.8)   # gives them back
	lines.append_array([
		_cue({"text": "Elle dessine chaque fossile dans un grand cahier tout gondolé, en tirant la langue. Puis elle les rend à Chloé."}, drawing),
		{"who": SIROCCO, "text": "Tiens. Je les ai dans mon cahier : c'est tout ce qu'il me faut. Un os de l'île reste sur l'île. Anselme saura peut-être les réveiller, un jour. Ou peut-être pas : les os, ça a son caractère."},
		{"who": SIROCCO, "text": "Et voilà ton cadeau. Des pièces trouvées dans le sable : les voyageurs en perdent plein, le Désert est le plus grand porte-monnaie de l'île. Et deux fougères de Mémé Pervenche : elle me les envoie par bateau, et je ne suis jamais malade."},
	])
	var brush: bool = ItemsDB.ITEMS.has("pinceau_fouille")
	if brush:
		lines.append({"who": SIROCCO, "text": "Et mon vieux pinceau de fouille. Hélène avait le même : on les avait achetés ensemble, au marché du port, il y a trente ans. Moi, j'en ai un neuf."})
	lines.append_array([
		_cue({"text": "Enfin, elle détache une page de son cahier et la tend à Chloé. Un vieux dessin au crayon : deux femmes assises sur un crâne géant, qui rient aux éclats. L'une porte un chapeau beaucoup trop grand."},
			func() -> void: _reach(who, chloe.global_position, 10.0, 1.2)),
		{"who": SIROCCO, "text": "C'est nous. Le chapeau s'est envolé cinq minutes après. Garde-le, ma caille. Moi, je m'en souviens par cœur."},
		{"flag": &"fossiles_rendus"},
	])
	await S.say(lines)
	Game.give_item("piece", REWARD_COINS)
	Game.give_item("fougere", REWARD_FERNS)
	var got := "%d pièces et %d fougères curatives" % [REWARD_COINS, REWARD_FERNS]
	if brush:
		Game.give_item("pinceau_fouille")
		got += ", le pinceau de fouille"
	Toast.say(S.world().get_tree(), "Objets obtenus : " + got)
	Game.award_team_xp(XP_FOSSILS)
	Save.save_game()
	S.lock(false)


## Her line of the moment, then the questions.
static func _sirocco_again() -> String:
	if Game.flag(&"sceau_desert") and not Game.flag(&"sirocco_apres_sceau"):
		Game.set_flag(&"sirocco_apres_sceau")
		return "Le Carnotaurus a rugi, depuis le sanctuaire. Un vrai rugissement, grave et long : tout le cimetière a tremblé. J'ai failli pleurer. Bon, j'ai pleuré. C'était toi, hein ?"
	if Game.flag(&"rempart_rencontre") and not Game.flag(&"sirocco_apres_rempart"):
		Game.set_flag(&"sirocco_apres_rempart")
		return "Tu as réveillé la vieille Rempart ? Elle dort toujours sur le côté gauche, tu as vu ? Le droit, c'est pour les grandes occasions."
	var n := P.fossils_found()
	if not Game.flag(&"fossiles_rendus") and n > 0 and not Game.flag(StringName("sirocco_fossile_%d" % n)):
		Game.set_flag(StringName("sirocco_fossile_%d" % n))
		return "Déjà %d fossile%s ! Encore %d, et le cadeau est à toi." % [n, "s" if n > 1 else "", P.FOSSILS_WANTED - n]
	var k := int(Game.flag(&"sirocco_n"))
	Game.set_flag(&"sirocco_n", k + 1)
	return SIROCCO_AGAIN[k % SIROCCO_AGAIN.size()]


# ------------------------------------------------------------------ the Vieux Rempart

## The Vieux Rempart, at the back of the walled canyon (DinoNpc « VieuxRempart », once the
## fallen rocks are charged): Chloé nearly sits on her. A reunion with Bastion (the Ancien's
## page), else she smells Hélène on Chloé; Brac's torn net between her plates (she walled
## herself in); she looks north, where the Carnotaurus cries. Afterwards, a line at each visit
## (and the reunion, when Bastion comes along later).
static func vieux_rempart(who: Node) -> void:
	var bastion: Dino = bastion_dino()
	if Game.flag(&"rempart_rencontre"):
		if bastion and Game.party.has(bastion) and not Game.flag(&"rempart_bastion_reconnu"):
			S.lock(true)
			await _step_aside(who, _room(bastion, who))
			await _rempart_reunion(bastion, who)
			_get_up(who, 0.6)
			_companion_back()
			Game.award_team_xp(XP_ANCIEN)
			Save.save_game()
			S.lock(false)
			return
		var cast := {}   # Bastion out of her party for the line (cast « little »), when not her lead
		await S.say([_rempart_again(who, cast)])
		_companion_back()
		await _little_back(cast.get("little"))
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var wakes := func() -> void:
		Stage.cry(who, &"neutre")
		Stage.shake(3.0, 0.6)
		Stage.rear(who, 2.6)
		await Stage.recoil(chloe, at, 18.0)
		Stage.emote(chloe, "!")
	await S.say([
		_cue({"text": "Au fond du canyon muré, le vent ne souffle plus. Il fait frais, et c'est silencieux comme une église."},
			func() -> void: _step_aside(who, _room(bastion, who))),   # round to its side, so it can be seen
		_cue({"text": "Contre la paroi dort un énorme rocher couvert de lichen orange. Chloé s'approche pour s'asseoir dessus et vider le sable de sa chaussure…"},
			func() -> void: _chloe_walk(_beside(who, _room(bastion, who) - 26.0, 30.0), 60.0, 1.2)),
		_cue({"text": "Le rocher respire."}, func() -> void: _swell(who, 1.8, 0.06)),
		_cue({"text": "Le rocher se soulève. Lentement. Très lentement. Des plaques épaisses comme des portes, une queue terminée par une massue grosse comme une brouette et, tout au bout d'un long bâillement… une tête."}, wakes),
		_cue({"who": CHLOE, "text": "Pardon ! Pardon, madame ! Je vous avais prise pour un rocher !"}, func() -> void: Stage.bow(chloe, 0.6)),
		_cue({"text": "L'Ankylosaurus la regarde d'un œil jaune, lent comme un lever de soleil. Elle n'a pas l'air vexée. Elle a l'air d'avoir l'habitude."},
			func() -> void: Stage.turn_to(who, chloe.global_position)),
		{"text": "Au-dessus de sa couche, quelqu'un a gravé un nom dans la roche, avec une petite fougère : « Le Vieux Rempart »."},
		{"who": CHLOE, "text": "Le Vieux Rempart… c'est vous ? Mais vous êtes une dame !"},
		_cue({"text": "La vieille Ankylosaurus souffle par les narines : un nuage de sable. Visiblement, elle s'en fiche complètement."}, func() -> void: _snort(who)),
	])
	if bastion and Game.party.has(bastion):
		await _rempart_reunion(bastion, who)
	elif bastion:
		await _rempart_smells(bastion, who)
	else:
		await _rempart_wary(who)
	_get_up(who, 0.6)
	await _the_net(who)
	await _the_north(who)
	_companion_back()
	Game.set_flag(&"rempart_rencontre")
	Game.award_team_xp(XP_REMPART + (XP_ANCIEN if Game.flag(&"rempart_bastion_reconnu") else 0))
	Save.save_game()
	S.lock(false)


## How far to one side of the Vieux Rempart (`who`) Chloé stands (px): further when her little one
## is with her (at her side, or out of her party for the scene), to leave room for him between
## them, at his mother's snout (as long as he is, DinoSize).
static func _room(bastion: Dino, who: Node) -> float:
	if bastion == null or not Game.party.has(bastion):
		return 96.0
	var snout := absf(_head_of(who).x - (who as Node2D).global_position.x)
	return maxf(170.0, snout + _bastion_length(bastion) * 0.8 + 30.0)


## How long Bastion is (px), as he walks at Chloé's side.
static func _bastion_length(bastion: Dino) -> float:
	return DinoSize.length_px(bastion.species(), DinoSize.world_scale(bastion))


## A place beside the Vieux Rempart (on Chloé's side of her, `dx` along, `dy` in front), where
## Chloé stands without hiding her from view.
static func _beside(who: Node, dx: float, dy: float) -> Vector2:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var side := -1.0 if chloe.global_position.x <= at.x else 1.0
	return at + Vector2(side * dx, dy)


## Bastion and his mother: nose to nose, the same deep rumble. When he is Chloé's own
## hatchling, the Ancien's page (in a tin box she kept warm under her, like an egg); when he is
## the stolen one, she lies down to his height until he stops being afraid. +1 heart of Lien.
## (Bastion at Chloé's side, or brought out of her party for the scene: _little_on_stage.)
static func _rempart_reunion(bastion: Dino, who: Node) -> void:
	var w = S.world()
	var mine := str(Game.flag(&"starter")) == "ankylosaurus"
	var name := bastion.nickname
	var dino := _little_on_stage(bastion)
	await S.say(_reunion_meet(bastion, who, dino))
	var rumble := func() -> void:
		cry("cuirasse", "neutre", -4.0, OLD_PITCH)
		Stage.shake(1.2, 0.9)
		await S.wait(0.5)
		cry("cuirasse", "neutre", -8.0, 0.9)
		Stage.hop(dino, 1, 6.0)
	var after: Array = [
		_cue({"text": "Au fond de sa gorge, la vieille Ankylosaurus fait un bruit grave, comme un tonnerre très loin. %s lui répond : le même bruit, en plus petit, exactement sur la même note." % name}, rumble),
		{"who": CHLOE, "text": "Vous le reconnaissez… C'est votre petit. Vous êtes sa maman."},
	]
	if not mine:
		after.append({"who": CHLOE, "text": "On vous l'avait volé, et nourri à l'ambre noir. Mais il est là, maintenant."})
	if Game.flag(&"lettre_scellee"):
		after.append_array([
			{"who": CHLOE, "text": "Hélène m'a demandé de vous dire qu'elle va bien."},
			_cue({"text": "Le Vieux Rempart cligne des yeux, une fois, très lentement. Elle n'y croit pas tout à fait. Chloé non plus."},
				func() -> void: Stage.emote(who, "…")),
		])
	if not Game.flag(&"found_journal_ancien_rempart"):
		after.append_array(_ancien_page(who))
	after.append(_cue({"text": "Chloé grimpe sur une pierre pour gratter le Vieux Rempart sous le menton. La vieille dame ferme les yeux. On dirait qu'elle sourit."},
		func() -> void: _chin_scratch(who)))
	if mine:
		var nestles := func() -> void:
			if dino == null:
				return
			await _little_walk(dino, (who as Node2D).global_position + Vector2(-14.0, 30.0), 40.0)
			if is_instance_valid(dino):
				_fresh(dino)
				_crouch(dino, 0.14, 1.0)
		after.append(_cue({"text": "%s s'installe contre le flanc de sa mère, à l'ombre de sa carapace. Pour une fois, c'est lui qui est protégé." % name}, nestles))
	else:
		var nudges := func() -> void:
			await _reach(who, Stage.chloe().global_position, 14.0, 1.0)
			_companion_back()
			_little_back(dino)
		after.append_array([
			_cue({"text": "Du bout du museau, le Vieux Rempart pousse doucement %s vers Chloé. Comme on ouvre une porte." % name}, nudges),
			{"who": CHLOE, "text": "Vous voulez qu'il reste avec moi ? … D'accord. Je veillerai sur lui. Promis."},
		])
	after.append({"flag": &"rempart_bastion_reconnu"})
	var page: bool = not Game.flag(&"found_journal_ancien_rempart")
	await S.say(after)
	await _little_back(dino)
	Game.add_bond(bastion, 1)
	if page:
		Toast.say(w.get_tree(), "Page de l'Ancien : le Vieux Rempart")


## How Bastion and his mother meet, acted out by `dino` (at Chloé's side, or out of her party for
## the scene): her own hatchling goes up to her snout; the stolen one hides first, and she lies
## down for him.
static func _reunion_meet(bastion: Dino, who: Node, dino: Node2D) -> Array:
	var name := bastion.nickname
	var chloe := Stage.chloe()
	var snout := _head_of(who)
	var side: float = signf(snout.x - (who as Node2D).global_position.x)
	var meet := snout + Vector2(side * maxf(44.0, _bastion_length(bastion) * 0.4), 10.0)   # nose to nose
	var goes := func() -> void:
		if dino:
			await _little_walk(dino, meet, 38.0)
			Stage.turn_to(dino, snout)   # (nose to nose, whichever side it came from)
	if str(Game.flag(&"starter")) == "ankylosaurus":
		return [
			_cue({"text": "%s passe devant Chloé. Il ne court pas : un Ankylosaurus ne court jamais. Il avance, pas à pas, jusqu'au museau de la vieille dame." % name}, goes),
			_cue({"text": "Le Vieux Rempart baisse sa tête immense jusqu'à lui. Ils se touchent le bout du nez. Et ils ne bougent plus."},
				func() -> void: _crouch(who, 0.1, 1.4)),
		]
	var hides := func() -> void:
		if dino == null:
			return
		await _little_walk(dino, chloe.global_position + Vector2(-12.0, 16.0), 110.0)
		Stage.tremble(dino, 1.6, 2.0)
	var steps := func() -> void:
		if dino == null:
			return
		await _little_walk(dino, chloe.global_position.lerp(meet, 0.45), 35.0)
		await S.wait(0.8)
		await _little_walk(dino, meet, 35.0)
		Stage.turn_to(dino, snout)
	return [
		_cue({"text": "Le Vieux Rempart se fige. Elle ne regarde plus Chloé. Elle regarde %s." % name},
			func() -> void: Stage.turn_to(who, dino.global_position if dino else chloe.global_position)),
		_cue({"text": "%s se cache derrière la jambe de Chloé : chez Brac, il a appris à avoir peur des grands." % name}, hides),
		_cue({"text": "Alors la vieille dame se couche dans le sable, tout doucement, jusqu'à poser son menton par terre, à la hauteur du petit. Et elle attend. Attendre, c'est ce qu'elle sait faire de mieux."},
			func() -> void: _crouch(who, 0.24, 2.4)),
		_cue({"text": "%s avance d'un pas. Puis d'un autre. Et il pose son museau contre le sien." % name}, steps),
	]


## Chloé climbs on a stone to scratch the old lady under the chin; she closes her eyes.
static func _chin_scratch(who: Node) -> void:
	var chloe := Stage.chloe()
	await Stage.hop(chloe, 1, 14.0)
	Stage.pose(chloe, &"grimpe", 2.4)   # (up on a stone, when drawn)
	await _reach(chloe, _head_of(who), 10.0, 1.4)
	Stage.emote(who, "♥")


## The Ancien's page: she stands up — for the first time in a long while — and there, in the
## warm sand where she lay, a round tin box.
static func _ancien_page(who: Node) -> Array:
	var stands := func() -> void:
		await _get_up(who, 1.2)
		Stage.rear(who, 1.6)
		for i in 2:
			_puff((who as Node2D).global_position + Vector2(randf_range(-30.0, 30.0), 4.0), 18, 0.3)
			await S.wait(0.5)
	return [
		_cue({"text": "Alors la vieille dame fait une chose étonnante : elle se lève. Complètement. Du sable tombe de son ventre, comme d'un sablier."}, stands),
		_cue({"text": "Là où elle était couchée, dans le sable tiède, il y a une boîte en fer-blanc toute ronde, toute chaude. Elle l'a couvée comme un œuf."},
			func() -> void:
				Stage.show_thing("boite_ronde", (who as Node2D).global_position + Vector2(0.0, 40.0), "BoiteRempart")   # (just out from under her)
				Stage.bow(Stage.chloe(), 1.2)),
		_cue({"text": "Sur le couvercle, de l'écriture penchée d'Hélène : « Pour Chloé. Elle te la donnera. »"},
			func() -> void: Stage.take_thing(S.actor("BoiteRempart"))),
		{"letter": REMPART_PAGE, "sign": "— H."},
		{"flag": &"found_journal_ancien_rempart"},
	]


## Bastion is Chloé's but waits at the Cabinet: she smells him on her hands (the page too).
static func _rempart_smells(bastion: Dino, who: Node) -> void:
	var chloe := Stage.chloe()
	var sighs := func() -> void:
		_puff(_head_of(who), 10, 0.4)
		Stage.bow(who, 1.6)
	var lines: Array = [
		_cue({"text": "Le Vieux Rempart tend son museau, gros comme un seau, vers les mains de Chloé. Celles qui grattent %s sous le menton, chaque soir." % bastion.nickname},
			func() -> void: _reach(who, chloe.global_position, 14.0, 2.0)),
		_cue({"text": "Elle ferme les yeux, et pousse un long soupir. Comme quelqu'un qui reçoit enfin une lettre."}, sighs),
		{"who": CHLOE, "text": "Vous sentez son odeur sur moi… Vous êtes la maman %s. Il est au Cabinet, bien au chaud. Je vous le ramènerai." % French.de(bastion.nickname)},
	]
	if str(Game.flag(&"starter")) == "ankylosaurus" and not Game.flag(&"found_journal_ancien_rempart"):
		lines.append_array(_ancien_page(who))
	await S.say(lines)


## No little one of hers with Chloé: she does not know her, but Chloé smells of Hélène.
static func _rempart_wary(who: Node) -> void:
	var chloe := Stage.chloe()
	var pick := await Dialogue.choose("", "Le Vieux Rempart tourne lentement la tête vers Chloé. Que fait-elle ?", ["Lui dire bonjour", "Attendre sans bouger"])
	var lines: Array = []
	if pick == 0:
		lines.append_array([
			{"who": CHLOE, "text": "Bonjour, madame Rempart. Je m'appelle Chloé."},
			_cue({"text": "La vieille Ankylosaurus la regarde longtemps. Très longtemps. Chloé commence à se demander si elle s'est rendormie."},
				func() -> void: _later(1.8, func() -> void: Stage.emote(chloe, "…"))),
		])
	else:
		lines.append(_cue({"text": "Chloé attend sans bouger. La vieille Ankylosaurus attend aussi. Au bout d'un moment, Chloé comprend qu'à ce jeu-là, elle ne gagnera jamais."},
			func() -> void: _later(1.8, func() -> void: Stage.emote(who, "…"))))
	var sniffs := func() -> void:
		await _reach(who, chloe.global_position, 12.0, 1.2)
		await _reach(who, chloe.global_position, 12.0, 1.2)
	lines.append_array([
		_cue({"text": "Puis le Vieux Rempart tend son museau, gros comme un seau, vers la sacoche aux pages du journal. Elle renifle, longuement."}, sniffs),
		_cue({"text": "Le vieux papier, l'encre, l'ambre. L'odeur d'Hélène. La vieille dame ferme les yeux."}, func() -> void: Stage.bow(who, 1.6)),
		{"who": CHLOE, "text": "Vous la connaissiez… Vous êtes un de ses dinos, vous aussi."},
	])
	var lead := Game.lead_dino()
	if lead:
		var greets := func() -> void:
			var dino := _companion()
			if dino == null:
				return
			await _companion_walk(dino.global_position.lerp(_head_of(who), 0.4), 30.0)
			_puff(dino.global_position + Vector2(0.0, -6.0), 12, 0.5)
			Stage.cry(dino, &"neutre")
		lines.append(_cue({"text": "%s s'approche, prudent. Le Vieux Rempart lui souffle dessus : un petit nuage de sable. C'est sa façon de dire bonjour." % lead.nickname}, greets))
	match str(Game.flag(&"starter")):
		"velociraptor":
			if Game.flag(&"griffe_grise_vu"):
				lines.append({"who": CHLOE, "text": "(Griffe-Grise veille sur la Forêt, et vous sur le Désert… Hélène vous a tous mis à l'abri.)"})
		"parasaurolophus":
			if Game.flag(&"voix_rencontree"):
				lines.append({"who": CHLOE, "text": "(Comme la Voix du Marais, dans ses roseaux… Hélène vous a tous mis à l'abri.)"})
	await S.say(lines)


## What she kept between her plates: a torn net of the Ombre Noire, smelling of ash. The
## fallen rocks bear the marks of her tail club: she walled herself in.
static func _the_net(who: Node) -> void:
	var chloe := Stage.chloe()
	var at: Vector2 = (who as Node2D).global_position
	var rocks := S.at(EBOULIS.x, EBOULIS.y)
	# (She turns to the way in, far behind her: the camera stays, the rocks are out of sight.)
	var looks := func() -> void: Stage.turn_to(chloe, rocks)
	var back := func() -> void: Stage.turn_to(chloe, at)
	var yawns := func() -> void:
		Stage.cry(who, &"neutre")
		Stage.rear(who, 1.8)
	await S.say([
		_cue({"text": "Entre deux plaques de sa carapace, quelque chose est coincé. Chloé le décroche : un morceau de filet, épais, coupé net. Sur un nœud, une petite plaque d'os gravée d'un masque."},
			func() -> void: _reach(chloe, at, 12.0, 1.0)),
		{"text": "Le filet sent la cendre froide."},
		{"who": CHLOE, "text": "(L'Ombre Noire… Ils ont essayé de l'attraper, elle aussi !)"},
		_cue({"text": "Chloé regarde les éboulis de l'entrée. Sur les gros rochers, partout, des marques rondes. Des coups de massue."}, looks),
		_cue({"who": CHLOE, "text": "C'est vous qui avez fait tomber les rochers ? Pour vous enfermer, et qu'ils ne reviennent plus ?"}, back),
		_cue({"text": "Le Vieux Rempart bâille. C'est sans doute un oui."}, yawns),
		{"who": CHLOE, "text": "(Elle s'est murée toute seule. Pour se protéger… et pour garder ce qu'Hélène lui a confié.)" if not Game.flag(&"found_journal_20")
			else "(Elle s'est murée toute seule. Pour se protéger… et pour garder la carte d'Hélène.)"},
	])


## She looks north, where the Carnotaurus cries (or roars, at home, once free).
static func _the_north(who: Node) -> void:
	var chloe := Stage.chloe()
	var north := chloe.global_position + Vector2(0.0, -400.0)
	if Game.flag(&"sceau_desert"):
		var home := func() -> void:
			cry("tyran", "attaque", -14.0, 0.72)
			Stage.turn_to(chloe, north)
			await S.wait(1.4)
			_puff(_head_of(who), 10, 0.4)
			_crouch(who, 0.16, 1.6)
		await S.say([
			_cue({"text": "Au loin, vers le nord, un rugissement grave roule sur les dunes : le Carnotaurus, chez lui. Le Vieux Rempart soupire d'aise et se recouche."}, home),
			{"text": "Elle ne suit pas Chloé. Ce canyon est le sien. Mais elle garde un œil ouvert, tourné vers le nord."},
		])
		return
	var far_cry := func() -> void:
		cry("tyran", "attaque", -16.0, 0.8)
		Stage.turn_to(chloe, north)
	var looks_up := func() -> void:
		Stage.rear(who, 1.4)
		await S.wait(0.6)
		_face_north(who)
	var lines: Array = [
		_cue({"text": "Au loin, vers le nord, un rugissement monte… puis se casse, comme un sanglot."}, far_cry),
		_cue({"text": "Le Vieux Rempart relève la tête et regarde vers le nord. Vers le sanctuaire des Vents."}, looks_up),
	]
	if Game.flag(&"brac_desert_battu"):
		lines.append({"who": CHLOE, "text": "(Le Carnotaurus Rouge… Il a encore peur. Il faut que je l'aide.)"})
	else:
		lines.append({"who": CHLOE, "text": "(Le Carnotaurus Rouge… Il a peur. Et Brac le traîne vers le sanctuaire.)"})
	lines.append({"text": "Le Vieux Rempart ne suit pas Chloé. Ce canyon est le sien, et elle est trop vieille pour courir. Mais elle garde un œil ouvert, tourné vers le nord."})
	await S.say(lines)


## A short line when Chloé comes back (the next one each time), with what it shows. Bastion,
## when a line shows him, is brought out of her party for it (cast « little », given back after).
static func _rempart_again(who: Node, cast: Dictionary) -> Dictionary:
	var bastion: Dino = bastion_dino()
	var chloe := Stage.chloe()
	if Game.flag(&"sceau_desert") and not Game.flag(&"rempart_apres_sceau"):
		Game.set_flag(&"rempart_apres_sceau")
		return _cue({"text": "Le Vieux Rempart renifle Chloé : elle sent le Carnotaurus, le vent, le sanctuaire. La vieille dame souffle longuement, comme quelqu'un qui va enfin pouvoir dormir sur le côté droit."},
			func() -> void:
				await _reach(who, chloe.global_position, 12.0, 1.2)
				_puff(_head_of(who), 12, 0.4))
	if Game.phase() == &"night":
		return {"text": "Le Vieux Rempart dort. Ou alors elle fait semblant, et elle écoute le Désert. Avec elle, c'est difficile à dire."}
	var n := int(Game.flag(&"rempart_n"))
	Game.set_flag(&"rempart_n", n + 1)
	if bastion and Game.party.has(bastion) and Game.flag(&"rempart_bastion_reconnu"):
		var k := n % REMPART_AGAIN_BASTION.size()
		var line := {"text": (REMPART_AGAIN_BASTION[k] as String).replace("%s", bastion.nickname)}
		if k == 3:
			return _cue(line, func() -> void: _chin_scratch(who))
		return _cue(line, func() -> void: _with_bastion_again(who, k, bastion, cast))
	if bastion and not Game.party.has(bastion):
		return _cue({"text": "Le Vieux Rempart renifle les mains de Chloé, puis regarde derrière elle. Elle cherche %s." % bastion.nickname},
			func() -> void:
				await _reach(who, chloe.global_position, 12.0, 1.0)
				_look_around(who))
	var plain := {"text": REMPART_AGAIN[n % REMPART_AGAIN.size()]}
	if n % REMPART_AGAIN.size() == 2:   # the long yawn
		return _cue(plain, func() -> void:
			Stage.cry(who, &"neutre")
			Stage.rear(who, 2.6))
	return plain


## REMPART_AGAIN_BASTION[k] acted out, Bastion at Chloé's side (her lead) or brought out of her
## party for the line (cast « little »): seen; asleep against his mother; a puff of sand on him,
## and he sneezes.
static func _with_bastion_again(who: Node, k: int, bastion: Dino, cast: Dictionary) -> void:
	var dino := _little_on_stage(bastion)
	if dino is DinoNpc:
		cast["little"] = dino
	match k:
		1:   # against his mother, in the shade of her shell
			if dino and is_instance_valid(who):
				await _little_walk(dino, (who as Node2D).global_position + Vector2(-14.0, 30.0), 40.0)
				if is_instance_valid(dino):
					_fresh(dino)
					_crouch(dino, 0.14, 1.0)
		2:   # a puff of sand on him: he sneezes
			_puff(dino.global_position if dino else _head_of(who), 12, 0.5)
			_later(0.6, func() -> void: Stage.cry(dino, &"neutre"))


# ------------------------------------------------------------------ Maïa at the oasis

## Maïa at the oasis (Npc « MaiaOasis », there once the Sceau du Désert is Chloé's): Caillou has
## become a Triceratops; her fourth challenge, at the top of her form; beaten, she talks of the
## Côte (her mother goes there at night, by boat), then the dusk scene.
static func maia(who: Node) -> void:
	if Game.flag(&"maia_defi_4"):
		return
	var first: bool = not Game.flag(&"maia_oasis_vue")
	var caillou = _caillou_at(who)
	if first:
		S.lock(true)
		await S.say(_maia_hello(who, caillou))
		Game.set_flag(&"maia_oasis_vue")
		S.lock(false)
	var prompt := "Trois dinos. Et le dernier, tu le connais. Enfin… tu le connaissais plus petit." if first \
		else "Alors, ce défi numéro quatre ? Caillou a bu la moitié de l'oasis en t'attendant."
	var pick := await Dialogue.choose(MAIA, prompt, ["Relever le défi", "Plus tard"])
	if pick != 0:
		await S.say([{"who": MAIA, "text": "Je t'attends ici, à l'ombre. Caillou aussi. Enfin, Caillou FAIT de l'ombre."}])
		return
	if not await S.duel(MAIA, _maia_team(), {"lose_spawn": P.LOSE_MAIA}):
		await S.say([{"who": MAIA, "text": "HA ! ENFIN ! Enfin, enfin, ENFIN ! … Bon. Soigne ton équipe et reviens : je veux gagner encore, pour être sûre que ce n'était pas un coup de chance."}])
		return
	await _maia_beaten(who, _caillou_at(who))


static func _maia_hello(who: Node, caillou) -> Array:
	var starter_name := _maia_starter_name()
	var drinks := func() -> void:
		Stage.hop(who, 3, 9.0)
		for i in 2:
			await Stage.bow(caillou, 1.0)
	var looks_up := func() -> void:
		Stage.cry(caillou, &"neutre")
		Stage.rear(caillou, 1.2)
	var lines: Array = [
		_cue({"who": MAIA, "text": "CHLOÉ ! Par ici ! Viens voir ! VIENS VOIR !"}, func() -> void: _step_aside(who, 60.0, -1.0)),   # (Caillou is on her right)
		_cue({"text": "Au bord de l'oasis, les pieds dans l'eau, Maïa saute sur place. Derrière elle, quelque chose d'énorme boit à grandes gorgées : trois cornes, une collerette grande comme une table…"}, drinks),
		{"who": CHLOE, "text": "C'est… un Tricératops ?"},
		{"who": MAIA, "text": "C'est CAILLOU !"},
	]
	lines.append_array([
		_cue({"text": "Le Tricératops relève la tête. Il a une tache en forme de caillou sur le museau. Et il mâchonne un lacet."}, looks_up),
		_cue({"who": CHLOE, "text": "Caillou ?! Mais il était grand comme un chien !"}, func() -> void: Stage.emote(Stage.chloe(), "!")),
		{"who": MAIA, "text": "Il a traversé le marais, il a mangé tous les roseaux, il a dormi trois jours dans le sable chaud… et PAF. Trois cornes. Maman dit que c'est l'âge."},
		{"who": CHLOE, "text": "(Je ne suis pas sûre que ça marche comme ça.)"},
		{"who": MAIA, "text": "Chez Caillou, si."},
		{"who": MAIA, "text": "Et toi, il paraît que tu as apaisé le Carnotaurus Rouge. LE Carnotaurus Rouge. Celui qui fait peur aux Majungasaurus. On l'a entendu rugir jusqu'ici."},
	])
	if Game.flag(&"coeur_2"):
		lines.append_array([
			{"who": MAIA, "text": "Et tu as DEUX Cœurs, maintenant ? Fais voir… Ils brillent ! Ensemble, ils brillent plus fort ! C'est… Bon. C'est stylé. Très stylé."},
		])
	lines.append_array([
		{"who": MAIA, "text": "Mais aujourd'hui, c'est MON jour. Je le sens. Caillou le sent. Même %s le sent." % starter_name},
		{"who": MAIA, "text": "Moustique garde nos sacs, là-bas sous le palmier : il n'aime pas le sable, il dit que ça gratte. Alors ce sera Pouce, %s… et Caillou." % starter_name},
		{"who": MAIA, "text": "Défi numéro QUATRE. Au sommet de ma forme."},
	])
	return lines


## Pouce the Iguanodon, her own hatchling, then Caillou the Triceratops (last, the surprise).
static func _maia_team() -> Array:
	var team: Array = [[&"iguanodon", MAIA_LEVELS["pouce"], "Pouce"]]
	var mine := StringName(str(Game.flag(&"maia_starter")))
	if SpeciesDB.PATHS.has(mine):
		team.append([mine, MAIA_LEVELS["starter"], _maia_starter_name()])
	team.append([&"triceratops", MAIA_LEVELS["caillou"], "Caillou", {
		"before": [{"who": MAIA, "text": "Pas mal ! Mais maintenant… LA SURPRISE. Caillou, à toi !"},
			_cue({"text": "Le sol tremble. Caillou avance, les cornes baissées, un lacet qui pend encore de sa bouche."}, func() -> void: _caillou_charges())],
		"intro": "Maïa envoie Caillou… le Tricératops !",
	}])
	return team


## Caillou comes on, horns down, and the ground shakes (between two battles, in the world).
static func _caillou_charges() -> void:
	var chloe := Stage.chloe()
	var tri = S.actor("Caillou")
	Stage.shake(3.0, 0.8)
	if tri and chloe:
		Stage.lunge(tri, chloe.global_position, 1.2)


static func _maia_starter_name() -> String:
	return Prologue.MAIA_NAMES.get(StringName(str(Game.flag(&"maia_starter"))), "Flèche")


static func _maia_beaten(who: Node, caillou) -> void:
	S.lock(true)
	var mine: Dino = Foret.starter()
	var lines: Array = [
		{"who": MAIA, "text": "QUATRE fois. Quatre. J'ai compté. Deux fois, même."},
	]
	if mine and Game.party.has(mine):
		lines.append({"who": MAIA, "text": "… Mais tu as vu Caillou ? Il a tenu tête à %s ! Il est devenu ÉNORME. Et moi aussi, un peu. À l'intérieur." % mine.nickname})
	else:
		lines.append({"who": MAIA, "text": "… Mais tu as vu Caillou ? Il est devenu ÉNORME. Et moi aussi, un peu. À l'intérieur."})
	lines.append_array([
		{"who": MAIA, "text": "Bon. Tu sais ce qu'il y a après le Désert ? La Côte. Au nord, les dunes finissent en plages : des tortues grandes comme des barques, des falaises pleines de Pteranodons, des grottes où la mer chante…"},
		{"who": MAIA, "text": "Maman connaît la Côte par cœur. Elle y va souvent, la nuit, en barque. « Pour le port », elle dit. Elle ne veut jamais m'emmener."},
		{"who": MAIA, "text": "Mais la piste du nord est perdue sous le sable : chaque nuit, le vent la redessine ailleurs. Il faut attendre qu'il tourne."},
		{"who": MAIA, "text": "Moi, j'attends ici, et je m'entraîne. La prochaine fois, c'est MOI qui gagne. Pour de vrai de vrai."},
		{"flag": &"maia_defi_4"},
	])
	await S.say(lines)
	Game.award_team_xp(XP_MAIA)
	for node in [who, caillou]:
		if node == null or not is_instance_valid(node):
			continue
		var fade: Tween = node.create_tween()
		fade.tween_interval(0.6)
		fade.tween_property(node, "modulate:a", 0.0, 0.6)
	if is_instance_valid(caillou) and caillou is DinoNpc:
		caillou.walk_to(S.at(P.MAIA_AWAY.x + 1.0, P.MAIA_AWAY.y), 150.0)
	if is_instance_valid(who):
		await who.walk_to(S.at(P.MAIA_AWAY.x, P.MAIA_AWAY.y), "right", 180.0)
	for node in [who, caillou]:
		if node != null and is_instance_valid(node):
			node.queue_free()
	Save.save_game()
	S.lock(false)
	await annonce()


## Caillou the Triceratops next to Maïa: the zone's own DinoNpc « Caillou » when it is there,
## else one made for the scene (not to be talked to).
static func _caillou_at(maia_npc: Node):
	var tri = S.actor("Caillou")
	if tri != null or not is_instance_valid(maia_npc):
		return tri
	var w = S.world()
	if w == null:
		return null
	tri = DinoNpc.new()
	tri.name = "Caillou"
	tri.species_id = &"triceratops"
	tri.size_scale = 0.95
	tri.flip = true
	tri.position = (maia_npc as Node2D).position + Vector2(70.0, -24.0)
	w.region.entities.add_child(tri)
	return tri


# ------------------------------------------------------------------ at dusk, towards the Côte

## After Maïa: dusk falls (time passes if it is still day); from the top of a dune, far away, a
## boat without a lantern slips towards the Côte. The chapter's playable end.
static func annonce() -> void:
	if Game.flag(&"cote_annonce"):
		return
	var w = S.world()
	if w == null:
		return
	S.lock(true)
	var phase := Game.phase()
	var dusk: bool = phase != &"night"
	var to_the_dune := func() -> void:
		if phase == &"day" or phase == &"dawn":
			Game.pass_time_until(19.0)
		if P.DUNE != Vector2.INF:
			w.player.teleport(S.at(P.DUNE.x, P.DUNE.y))
			w.companion.stand_beside(S.at(P.DUNE.x, P.DUNE.y))
		w.player.face_towards(S.at(P.SORTIE_COTE.x, P.SORTIE_COTE.y))
		await S.wait(0.6)
	await S.fade_through(to_the_dune, 0.9)
	var sea := S.at(P.SORTIE_COTE.x, P.SORTIE_COTE.y)
	var lines: Array = [
		{"text": "Le soleil descend sur les dunes et les colore de rose. Chloé grimpe tout en haut de la plus grande, au nord de l'oasis, pour regarder le chemin de demain." if dusk
			else "La nuit est tombée sur les dunes. Chloé grimpe tout en haut de la plus grande, au nord de l'oasis, pour regarder le chemin de demain."},
		_cue({"text": "Au loin, le sable descend vers la mer. On devine une longue ligne blanche : des vagues. La Côte Préhistorique."},
			func() -> void: Stage.look_at(w.player.global_position.lerp(sea, 0.55), 1.2)),   # the way down to the sea
		{"text": "Et sur la mer, une barque. Toute petite. Elle file vers la Côte… sans lanterne."},
	]
	var lead := Game.lead_dino()
	if lead:
		var points := func() -> void:
			Stage.look_back(0.8)
			var dino := _companion()
			Stage.turn_to(dino, sea)
			Stage.emote(dino, "!")
			_fresh(dino)
			Stage.rear(dino, 1.4)
		lines.append(_cue({"text": "%s pointe le museau vers la mer, et ne bouge plus." % lead.nickname}, points))
	lines.append(_cue({"who": CHLOE, "text": "(Qui navigue la nuit, sans lanterne ?)"}, func() -> void: Stage.look_back(0.8)))
	if Game.flag(&"sbire_camp_2_battu"):
		lines.append({"who": CHLOE, "text": "(« Il arrive la nuit, par la mer, sans lanterne », disait le sbire à la lanterne…)"})
	lines.append_array([
		{"text": "La barque disparaît derrière une falaise. Il ne reste que le vent qui fait chanter les dunes."},
		{"who": CHLOE, "text": "(La Côte. C'est là que j'irai. Dès que le vent aura tourné.)"},
		_cue({"text": "Et le vent tourne. Sous les pieds de Chloé, le sable glisse, glisse… et découvre une piste qui descend vers la mer. Pour une fois, le vent l'a redessinée au bon endroit."},
			func() -> void:
				# (Chloé in sight, and the sand streaming away from her feet towards the sea: the track)
				var from: Vector2 = w.player.global_position
				Stage.look_at(from.lerp(sea, 0.18), 1.2)
				Stage.tremble(w.player, 0.6, 1.2)
				for i in WIND_TRACK:
					_puff(from.lerp(sea, 0.03 + 0.05 * i) + Vector2(0.0, 10.0), 26, 0.15)
					await S.wait(0.22)),
		_cue({"who": CHLOE, "text": "(Le vent a tourné. En route pour la Côte !)"}, func() -> void: Stage.look_back(0.8)),
		{"flag": &"cote_annonce"},
		{"flag": &"cote_ouverte"},
	])
	await S.say(lines)
	Game.award_team_xp(XP_ANNONCE)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ Roc, at the Cabinet

## Talking to Roc once the Sceau du Désert is Chloé's (Story.run « roc »). True if he said it.
static func roc() -> bool:
	if not Game.flag(&"sceau_desert") or Game.flag(&"roc_sceau_desert"):
		return false
	var lines: Array = [
		{"who": ROC, "text": "Le Sceau du Désert… Le Carnotaurus Rouge t'a laissée approcher ? Hélène l'appelait « Piment ». Il l'a chargée cinq fois, le premier jour."},
	]
	if Game.flag(&"sirocco_vue"):
		lines.append_array([
			{"who": CHLOE, "text": "Tante Sirocco vous passe le bonjour."},
			{"who": ROC, "text": "Sirocco ?! Cette vieille bique vit encore ? … Elle me doit un chapeau. Depuis vingt-deux ans."},
			{"text": "Mais il sourit, en le disant."},
		])
	if Game.flag(&"found_journal_20"):
		lines.append_array([
			{"who": CHLOE, "text": "Professeur… Hélène a écrit que vous gardiez une copie de la carte des sanctuaires."},
			{"text": "Roc se raidit. Il enlève ses lunettes, les essuie longtemps, les remet."},
			{"who": ROC, "text": "… Elle a écrit ça ? Hmm. Une copie. Oui. Rangée. Très bien rangée. Personne ne doit la voir, Chloé. Pas même toi. Surtout pas maintenant."},
			{"who": CHLOE, "text": "(Il sait où sont les Cœurs. Depuis le début.)"},
		])
	if Game.flag(&"coeur_2"):
		lines.append({"who": ROC, "text": "Deux Cœurs… Fais attention à eux, Chloé. Et à toi. Surtout à toi."})
	lines.append({"flag": &"roc_sceau_desert"})
	await S.say(lines)
	return true


# ------------------------------------------------------------------ helpers

## Chloé's Ankylosaurus from the Cabinet (the Vieux Rempart's little one): her own hatchling
## when she chose Bastion, or the stolen one, found again in the Forêt; null otherwise.
static func bastion_dino() -> Dino:
	if str(Game.flag(&"starter")) == "ankylosaurus":
		return Foret.starter()
	if ForetCamp.stolen_species() == &"ankylosaurus":
		return ForetCamp.recovered()
	return null


## A dino's call, not tied to anyone on screen (the Carnotaurus far away…): `prefix` is the
## cries' family (cuirasse, tyran…), quieter when far, lower when old or big.
static func cry(prefix: String, kind: String, volume_db: float, pitch := 1.0) -> void:
	var w = S.world()
	var path := CRY % [prefix, kind]
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


# ------------------------------------------------------------------ staging
# What Stage (story/stage.gd) has not got yet, for the Désert's scenes (desert_sanctuaire.gd
# uses them too). Candidates for Stage.

## A line that sets something going the moment it shows, so that a move and its bubble go
## together without cutting S.say in two: `line` as for S.say (with its "text"), `action` a
## Callable (a coroutine too: it is not awaited). Deferred, so that nothing in it can ever hold
## up or break the line itself.
static func _cue(line: Dictionary, action: Callable) -> Dictionary:
	var text: String = line["text"]
	var cued := line.duplicate()
	cued.erase("text")
	cued["text_fn"] = func() -> String:
		action.call_deferred()
		return text
	return cued


## Does `action` in `secs` seconds, without holding the scene.
static func _later(secs: float, action: Callable) -> void:
	await S.wait(secs)
	action.call()


## Chloé's lead dino at her side (null when she has none).
static func _companion() -> Companion:
	var w = S.world()
	var dino = w.get("companion") if w else null
	return dino if dino is Companion and (dino as Companion).visible else null


## A dino of Chloé's party a scene shows (Bastion before his mother…): her lead dino at her side
## when it is it (_companion), else brought out of her party beside her (a stand-in, given back
## with _little_back).
static func _little_on_stage(d: Dino) -> Node2D:
	if d == null:
		return null
	if Game.lead_dino() == d:
		return _companion()
	var actor := GESTES.stand_in(d)
	var chloe := Stage.chloe()
	if actor and chloe:   # (a grown one stands clear of her, not over her)
		var gap := maxf(38.0, DinoSize.length_px(d.species(), DinoSize.world_scale(d)) * 0.55)
		actor.global_position = S.ground_near(chloe.global_position + Vector2(gap, 8.0), 2)
	return actor


## It walks to `px`: the lead dino (its own walk, until _companion_back) or its stand-in (never
## in Chloé's way). Awaitable.
static func _little_walk(actor, px: Vector2, speed := 70.0) -> void:
	if not is_instance_valid(actor):
		return
	if actor is Companion:
		await _companion_walk(px, speed)
	elif actor is DinoNpc:
		await (actor as DinoNpc).walk_to(px, speed)
		if is_instance_valid(actor):
			(actor as DinoNpc).collision_layer = 0


## A stand-in (_little_on_stage) goes back into her party: it walks up to Chloé and fades away.
## (The lead dino follows her again with _companion_back.) Awaitable.
static func _little_back(actor) -> void:
	if is_instance_valid(actor) and actor is DinoNpc:
		await GESTES.stand_in_back(actor)


## The companion's picture changes size when the lead changes (Companion.refresh), and Stage
## keeps the size it first saw: forget it before a move that squashes or stretches it.
static func _fresh(actor: Node) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite and actor is Companion:
		sprite.remove_meta(&"stage_scale")


## Where an actor's picture rests and its full size, kept as Stage keeps them (Stage.stop puts
## them back).
static func _rest_of(sprite: Node2D) -> Vector2:
	if not sprite.has_meta(&"stage_rest"):
		sprite.set_meta(&"stage_rest", sprite.position)
	return sprite.get_meta(&"stage_rest")


static func _full_of(sprite: Node2D) -> Vector2:
	if not sprite.has_meta(&"stage_scale"):
		sprite.set_meta(&"stage_scale", sprite.scale)
	return sprite.get_meta(&"stage_scale")


## Leans towards `px` and comes back: a hand held out, a sniff, a gentle push of the snout.
## No cry, no shake. Awaitable.
static func _reach(actor: Node, px: Vector2, dist := 10.0, secs := 0.8) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	var rest := _rest_of(sprite)
	var dir: Vector2 = (px - (actor as Node2D).global_position).normalized() * dist
	var t := sprite.create_tween()
	t.tween_property(sprite, "position", rest + dir, secs * 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_interval(secs * 0.2)
	t.tween_property(sprite, "position", rest, secs * 0.4).set_trans(Tween.TRANS_SINE)
	await t.finished


## Crouches or lies down (asleep, worn out, a chin put down on the sand): a slow squash of
## `depth` of its height, which stays until _get_up. Awaitable.
static func _crouch(actor: Node, depth := 0.18, secs := 0.9) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	var full := _full_of(sprite)
	var t := sprite.create_tween()
	t.tween_property(sprite, "scale", full * Vector2(1.0 + depth * 0.3, 1.0 - depth), secs).set_trans(Tween.TRANS_SINE)
	await t.finished


## Sits down: the person's sitting picture (Stage.sit), or a squash of `depth` when it is not
## drawn for them; _get_up ends both. Awaitable.
static func _sit(actor: Node, depth := 0.26, secs := 0.5) -> void:
	if not await Stage.sit(actor):
		await _crouch(actor, depth, secs)


static func _get_up(actor: Node, secs := 0.9) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	Stage.pose(actor, &"")   # (up from a drawn pose: sitting…)
	var t := sprite.create_tween()
	t.tween_property(sprite, "scale", _full_of(sprite), secs).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished


## Swells and settles (a sleeping rock breathing, a chest filling before a roar); with `hold`,
## stays swollen (Stage.rear or _get_up ends it). Awaitable.
static func _swell(actor: Node, secs := 1.4, amount := 0.05, hold := false) -> void:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return
	var full := _full_of(sprite)
	var t := sprite.create_tween()
	t.tween_property(sprite, "scale", full * Vector2(1.0 + amount * 0.5, 1.0 + amount), secs * 0.5).set_trans(Tween.TRANS_SINE)
	if not hold:
		t.tween_property(sprite, "scale", full, secs * 0.5).set_trans(Tween.TRANS_SINE)
	await t.finished


## Pulls on something again and again (a chain, a rope): the picture leans away from
## `from_px` and back, until Stage.stop(actor, loop). Returns the looping tween (or null).
static func _tug(actor: Node, from_px: Vector2, every := 0.8, dist := 9.0) -> Tween:
	var sprite := Stage.sprite_of(actor)
	if sprite == null:
		return null
	var rest := _rest_of(sprite)
	var dir: Vector2 = ((actor as Node2D).global_position - from_px).normalized() * dist
	var t := sprite.create_tween().set_loops()
	t.tween_property(sprite, "position", rest + dir, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "position", rest + dir * 0.25, 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_interval(every)
	return t


## A little cloud of sand at `px` (world pixels), `height` metres up: a snort, a sigh, sand
## falling off a back, something landing.
static func _puff(px: Vector2, amount := 12, height := 0.5) -> void:
	var view := (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view") as WorldView
	if view:
		view.burst(px, SAND_BITS, int(amount * 1.6), height, 0.3)


## Sparks of amber light at `px` (world pixels), `height` metres up: a Cœur waking up, the door's
## footprint lighting up. (A glow above white, Stage.glow, hardly shows on the 3D view's
## sprites: their colour is clamped; these sparks do.)
static func _sparkle(px: Vector2, height := 0.7, amount := 16, spread := 0.3) -> void:
	var view := (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view") as WorldView
	if view:
		view.burst(px, AMBER_BITS, amount, height, spread)


## Where a dino's head is (world pixels): the front end of its picture, the way it faces.
static func _head_of(actor: Node) -> Vector2:
	if not actor is Node2D or not is_instance_valid(actor):
		return Vector2.ZERO
	var at: Vector2 = (actor as Node2D).global_position
	var sprite := Stage.sprite_of(actor) as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return at
	var picture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	var half: float = (picture.get_width() if picture else 100) * absf(sprite.scale.x) * 0.4
	return at + Vector2(-half if sprite.flip_h else half, 6.0)


## A snort: the head jerks, a little cloud of sand.
static func _snort(actor: Node) -> void:
	if not actor is Node2D or not is_instance_valid(actor):
		return
	var head := _head_of(actor)
	_reach(actor, head + (head - (actor as Node2D).global_position), 4.0, 0.4)
	_puff(head, 12, 0.45)


## Sniffs the ground (a dino): two quick nods.
static func _sniff(actor: Node) -> void:
	if Stage.sprite_of(actor) == null:
		return
	_fresh(actor)
	await Stage.bow(actor, 0.55)
	await Stage.bow(actor, 0.55)


## Looks left and right, searching (a dino: its picture turned back and forth).
static func _look_around(actor: Node) -> void:
	var sprite := Stage.sprite_of(actor) as AnimatedSprite2D
	if sprite == null:
		return
	var was := sprite.flip_h
	for flip: bool in [not was, was, not was, was]:
		await S.wait(0.5)
		if not is_instance_valid(sprite):
			return
		sprite.flip_h = flip


## Turns to look north, far away (its back view, when it has one).
static func _face_north(actor: Node) -> void:
	var sprite := Stage.sprite_of(actor) as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(&"idle_up"):
		sprite.play(&"idle_up")


## Chloé walks to `px` herself: her steps, her footfalls, her dino in her tracks; walls stop
## her, and she gives up after `max_secs`. Awaitable.
static func _chloe_walk(px: Vector2, speed := 110.0, max_secs := 2.5) -> void:
	var chloe := Stage.chloe()
	if chloe == null:
		return
	var tree := chloe.get_tree()
	var until := Time.get_ticks_msec() + int(max_secs * 1000.0)
	while is_instance_valid(chloe) and Time.get_ticks_msec() < until:
		var to: Vector2 = px - chloe.global_position
		if to.length() < 5.0:
			break
		# Her own _physics_process runs right after: it moves her (and slows her a little).
		chloe.facing = to.normalized()
		chloe.velocity = to.normalized() * speed
		await tree.physics_frame
	if is_instance_valid(chloe):
		chloe.velocity = Vector2.ZERO
		chloe.face_towards(chloe.global_position + chloe.facing)


## Chloé steps round to stand beside `who`, `gap` px to one side (not in front of them, where the
## camera would see only her back), by the outside; her dino ends up beside her, on the outside
## too, not in front of them. Awaitable.
static func _step_aside(who: Node, gap := 66.0, prefer := 0.0) -> void:
	var chloe := Stage.chloe()
	if chloe == null or not who is Node2D or not is_instance_valid(who):
		return
	var at: Vector2 = (who as Node2D).global_position
	var dx := chloe.global_position.x - at.x
	var side := prefer if prefer != 0.0 else (signf(dx) if absf(dx) > 12.0 else -1.0)
	if prefer == 0.0 and not _clear_way(chloe, at + Vector2(side * (gap + 50.0), 62.0), at + Vector2(side * gap, 10.0)):
		side = -side   # something in the way (a rib, a crate): the other side
	await _chloe_walk(at + Vector2(side * (gap + 50.0), 62.0), 95.0, 1.4)
	await _chloe_walk(at + Vector2(side * gap, 10.0), 80.0, 1.2)
	Stage.turn_to(chloe, at)
	# Her dino beside her, on the outside (as far as it is long): the trail it walks in, rewritten
	# to end there.
	var dino := _companion()
	var outer := chloe.global_position + Vector2(side * maxf(54.0, dino.keep_px() if dino else 0.0), 6.0)
	var trail := PackedVector2Array([outer, outer])
	for i in 8:
		trail.append(chloe.global_position)
	chloe.trail = trail


## Nothing solid (for Chloé) on the way from her to `a`, then to `b` (world pixels).
static func _clear_way(chloe: Player, a: Vector2, b: Vector2) -> bool:
	var space := chloe.get_world_2d().direct_space_state
	for leg: Array in [[chloe.global_position, a], [a, b]]:
		var ray := PhysicsRayQueryParameters2D.create(leg[0], leg[1], chloe.collision_mask, [chloe.get_rid()])
		if not space.intersect_ray(ray).is_empty():
			return false
	return true


## Chloé's lead dino leaves her side and walks to `px` (its own walk), and stays there until
## _companion_back(). Awaitable.
static func _companion_walk(px: Vector2, speed := 70.0) -> void:
	var dino := _companion()
	if dino == null:
		return
	dino.set_physics_process(false)
	var to: Vector2 = px - dino.global_position
	if to.length() < 2.0:
		return
	var anims: Array = SheetFrames.dino_anims(dino.sprite.sprite_frames, to)
	if absf(to.x) > 1.0:
		dino.sprite.flip_h = to.x < 0.0
	dino.sprite.play(anims[0])
	var t := dino.create_tween()
	t.tween_property(dino, "global_position", px, to.length() / speed)
	await t.finished
	if is_instance_valid(dino):
		dino.sprite.play(anims[1])


## Back at Chloé's side: it follows her again, its picture as it should be.
static func _companion_back() -> void:
	var dino := _companion()
	if dino == null:
		return
	dino.set_physics_process(true)
	dino.sprite.position = Vector2.ZERO
	dino.refresh()
	dino.sprite.remove_meta(&"stage_scale")
	dino.sprite.remove_meta(&"stage_rest")
