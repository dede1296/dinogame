class_name PlainesAnnexes
## Chapter 1, off the beaten track (see docs/histoire.md, « Hors des sentiers »):
##   la chapardeuse: Chipie the Compsognathus steals Maïa's compass, Chloé chases her to her
##   nest, Chipie joins the party (Flair); the compass goes back to Maïa (a fern on its lid);
##   les larmes de l'île: Roc's glasses (found in the nest), the amber pebbles and what Roc
##   does with them (10: the amber lantern, 20: Pépite's egg, 30: Hélène's sealed letter);
##   the sleeper under the tree. (The full moon at the pond: MoonFord and DialogueDB.)
## Flags: boussole_volee, chipie_etape, chipie_au_nid, boussole_trouvee, lunettes_trouvees,
## boussole_rendue, lunettes_rendues, larmes_expliquees, lanterne, pepite_oeuf, pepite_nee,
## lettre_scellee, dormeur_n.

const S := preload("res://story/story.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"
const ROC := "Prof. Roc"
const NEST_PEBBLES: Array[StringName] = [&"galet_plaines_nid_1", &"galet_plaines_nid_2"]
const LANTERN_AT := 10
const PEPITE_AT := 20
const LETTER_AT := 30
const EGG_STEPS := 300
const EGG_STIRS := 60   # steps left when it starts moving
const XP_QUEST := 40
const GLASS := preload("res://assets/audio/sfx/glass.wav")
## The parent of each starter's egg (one of Hélène's Anciens): who, and where.
const PARENTS := {
	&"velociraptor": "Griffe-Grise, un grand raptor au museau gris, qui règne sur les sous-bois de la Forêt Jurassique",
	&"ankylosaurus": "le Vieux Rempart, un Ankylosaurus vieux comme les canyons du Désert",
	&"parasaurolophus": "la Voix du Marais, dont le chant fait trembler les roseaux",
}


# ------------------------------------------------------------------ Maïa and Chipie

static func maia(who: Node) -> void:
	if not Game.flag(&"met_maia"):
		await S.say(DialogueDB.lines(&"maia"))
		await _theft(who)
		return
	if Game.flag(&"boussole_trouvee") and not Game.flag(&"boussole_rendue"):
		await _compass_back()
		return
	if not Game.flag(&"boussole_volee"):   # games saved before the compass went missing
		await _theft(who)
		return
	await S.say(DialogueDB.lines(&"maia"))


## A Compsognathus darts out of the grass and snatches the compass off Maïa's belt.
static func _theft(maia_npc: Node) -> void:
	S.lock(true)
	await S.say([{"text": "Un froissement dans les herbes hautes… puis un petit cri moqueur."}])
	Game.set_flag(&"chipie_etape", 0)
	Game.set_flag(&"boussole_volee")   # Chipie appears (FleeingDino)
	var chipie = S.actor("Chipie")
	if chipie and maia_npc:
		var start: Vector2 = chipie.global_position
		chipie.global_position = S.at(59.2, 47.2)
		await chipie.walk_to(maia_npc.global_position + Vector2(-26, 14), 260.0)
		chipie.cry(&"attaque")
		await S.wait(0.2)
		await chipie.walk_to(start, 260.0)
		chipie.sprite.flip_h = false
	await S.say([
		{"who": MAIA, "text": "Hé ! HÉ ! Ma boussole ! Enfin… la boussole de maman. Elle va me tuer."},
		{"who": MAIA, "text": "C'est une compso : ça chaparde tout ce qui brille, et ça cache tout dans un nid."},
		{"who": MAIA, "text": "Tu veux bien la rattraper ? Moi, dès que je cours, Caillou croit que c'est un jeu et il me fonce dedans."},
		{"who": CHLOE, "text": "Je m'en occupe."},
		{"who": MAIA, "text": "T'es la meilleure. Enfin, la deuxième meilleure. Après moi."},
	])
	Save.save_game()
	S.lock(false)


## The nest, at the edge of the little wood north-west of the crossroads.
static func nest(bush: Node) -> void:
	if not Game.flag(&"boussole_volee"):
		await S.say([{"text": "Un buisson touffu. Quelqu'un en a tapissé le creux de brindilles et de mousse, très soigneusement."}])
		return
	if Game.flag(&"boussole_trouvee"):
		await S.say([{"text": "Le nid de Chipie. Elle y a laissé sa collection, au cas où. On ne sait jamais."}])
		return
	if not Game.flag(&"chipie_au_nid"):
		await S.say([{"text": "Un nid plein de choses qui brillent… mais la voleuse n'est pas encore rentrée."}])
		return
	S.lock(true)
	await S.say([
		{"text": "Chloé écarte les branches. Au fond du nid, un vrai trésor de pirate :"},
		{"text": "une cuillère, trois boutons, un bouchon de bouteille, un bout de ruban bleu, deux galets d'ambre…"},
		{"text": "…des lunettes rondes rafistolées au ruban adhésif (le Professeur Roc a exactement les mêmes ; enfin, avait)…"},
		{"text": "…et la boussole de Maïa !"},
	])
	var chipie := DinoNpc.new()
	chipie.species_id = &"compsognathus"
	chipie.size_scale = 0.8
	chipie.position = bush.position + Vector2(40, 30)
	bush.get_parent().add_child(chipie)
	chipie.cry(&"attaque")
	await S.say([{"text": "La propriétaire des lieux jaillit du buisson. Elle fixe la boussole. Puis Chloé. Puis la boussole."}])
	var pick := await Dialogue.choose("", "Que fait Chloé ?", ["Lui offrir un bouton brillant", "Reprendre la boussole sans rien dire"])
	if pick == 0:
		await S.say([{"text": "Chloé pose le plus brillant des boutons devant elle. La compso le renifle, le fait tourner, le range dans le nid… puis grimpe sur son épaule."}])
	else:
		await S.say([{"text": "Chloé reprend la boussole. La compso pousse un cri outré… puis la suit quand même, à trois pas, en boudant. Tu es visiblement son nouveau trésor."}])
	chipie.queue_free()
	for f in NEST_PEBBLES:
		Game.set_flag(f)
	Game.set_flag(&"boussole_trouvee")
	Game.set_flag(&"lunettes_trouvees")
	var in_party := Game.add_caught(Dino.create(&"compsognathus", 6, "Chipie"))
	await S.say([
		{"text": "Chipie rejoint l'équipe !" if in_party else "Chipie rejoint le Cabinet, où elle attend avec impatience."},
		{"text": "Elle a du Flair : elle sent ce qui est enfoui. La terre remuée des Plaines ne lui échappera pas."},
	])
	Toast.say(S.world().get_tree(), "Galets d'ambre : +2 (%d / 30)" % Game.pebbles_found("plaines"))
	Game.award_team_xp(XP_QUEST)
	Save.save_game()
	S.lock(false)


static func _compass_back() -> void:
	S.lock(true)
	await S.say([
		{"who": MAIA, "text": "Tu l'as ?! Tu l'as ! Je t'aurais bien fait un câlin, mais j'ai une réputation."},
		{"text": "Maïa ouvre la boussole pour vérifier qu'elle marche. À l'intérieur du couvercle, une petite fougère est gravée."},
		{"who": CHLOE, "text": "Cette fougère… C'est le signe de ma grand-mère. Il est sur la porte d'ambre des falaises."},
		{"who": MAIA, "text": "Hein ? Plein de gens gravent des fougères. On est dans les Plaines des Fougères, je te rappelle."},
		{"who": MAIA, "text": "Maman ne s'en sépare jamais. Elle dit qu'on la lui a offerte « quand elle savait encore où elle allait »."},
		{"who": MAIA, "text": "… Je ne sais jamais ce que ça veut dire, quand elle parle comme ça."},
		{"who": MAIA, "text": "Bon ! Tiens, prends ça, j'en ai plein. Et au fait : maman dit que les soirs de pleine lune, l'étang chante."},
		{"who": MAIA, "text": "Moi, j'ai jamais osé y aller la nuit. Si tu y vas… tu me raconteras ?"},
		{"flag": &"boussole_rendue"},
	])
	Game.give_item("collier", 3)
	Toast.say(S.world().get_tree(), "+3 colliers d'ambre")
	Game.award_team_xp(XP_QUEST)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ Roc and the island's tears

## After Roc has looked after the party (Prologue.talk_roc).
## Returns whether Roc had something new to say (otherwise he just chats: DialogueDB.chatter).
static func roc() -> bool:
	if not Game.flag(&"prologue_done"):
		return false
	var said := false
	if Game.flag(&"lunettes_trouvees") and not Game.flag(&"lunettes_rendues"):
		await _glasses_back()
		said = true
	elif not Game.flag(&"lunettes_rendues") and not Game.flag(&"roc_myope"):
		await S.say([
			{"text": "Roc te fixe en plissant les yeux, avec un temps de retard."},
			{"who": ROC, "text": "Ah, c'est toi. Pardon : j'ai égaré mes lunettes. Il y a… trois semaines. Je vois le monde comme à travers une soupe."},
			{"flag": &"roc_myope"},
		])
		said = true
	var count := Game.tears()
	if not Game.flag(&"larmes_expliquees"):
		if count == 0 and not Game.flag(&"amber_protoceratops"):
			return said
		await _tears_explained()
		said = true
	return await _milestones(Game.tears()) or said


static func _glasses_back() -> void:
	await S.say([
		{"text": "Roc est en grande conversation avec la fougère en pot, dans le coin de la pièce."},
		{"who": ROC, "text": "… et donc, Chloé, je disais que… Tu as drôlement verdi, dis-moi."},
		{"who": CHLOE, "text": "Professeur ? Je suis là. Et j'ai vos lunettes."},
		{"text": "Roc chausse les lunettes. Il regarde Chloé. Il regarde la fougère. Il ne dit rien pendant un long moment."},
		{"who": ROC, "text": "Trois semaines. J'ai rangé le sel dans la couveuse et salé mon café. Où étaient-elles ?"},
		{"who": CHLOE, "text": "Dans un nid de compsognathus."},
		{"who": ROC, "text": "… Évidemment. Tiens, des baies, pour la peine. Je les avais rangées dans le tiroir à chaussettes."},
		{"flag": &"lunettes_rendues"},
	])
	Game.give_item("baie", 5)
	Toast.say(S.world().get_tree(), "+5 baies")
	Save.save_game()


static func _tears_explained() -> void:
	var lines: Array = [
		{"who": ROC, "text": "Qu'est-ce que tu as là ? Fais voir… Des larmes de l'île !"},
		{"who": ROC, "text": "C'est ainsi qu'Hélène appelait ces galets d'ambre. De l'Ambre-Mère que l'île recrache un peu partout. Trop petits pour qu'un dino y dorme… mais pleins de lumière."},
		{"who": ROC, "text": "Elle en semait derrière elle comme le Petit Poucet, pour retrouver ses cachettes. Sauf que les siens brillent, les soirs de pleine lune."},
		{"who": ROC, "text": "Et la couveuse s'en nourrit. Rapporte-m'en : avec %d, je te fabrique quelque chose d'utile." % LANTERN_AT},
	]
	if Game.flag(&"amber_protoceratops"):
		lines.append({"who": ROC, "text": "Avec %d… je pourrais réveiller le petit qui dort dans ton fragment d'ambre. Comme elle, autrefois." % PEPITE_AT})
	else:
		lines.append({"who": ROC, "text": "Avec %d, si tu me trouves un fragment où quelqu'un dort, je pourrais le réveiller. Comme elle, autrefois." % PEPITE_AT})
	lines.append({"flag": &"larmes_expliquees"})
	await S.say(lines)


static func _milestones(count: int) -> bool:
	var said := false
	if count >= LANTERN_AT and not Game.flag(&"lanterne"):
		await S.say([
			{"who": ROC, "text": "Dix larmes ! Donne… Voyons voir."},
			{"text": "Roc visse les galets un à un dans une vieille lanterne de marin. Ils s'allument, doux comme des braises."},
			{"who": ROC, "text": "La lanterne d'ambre. La nuit, et sous la terre, elle t'éclaire… et les larmes encore cachées scintillent autour de toi."},
			{"flag": &"lanterne"},
		])
		Toast.say(S.world().get_tree(), "Objet obtenu : la lanterne d'ambre")
		Save.save_game()
		said = true
	if count >= PEPITE_AT and not Game.flag(&"pepite_oeuf"):
		if Game.flag(&"amber_protoceratops"):
			await _wake_pepite()
		else:
			await S.say([{"who": ROC, "text": "Vingt larmes, bravo. Il ne me manque qu'un fragment avec un petit dedans. Hélène en cachait dans son bosquet, à l'ouest des Plaines."}])
		said = true
	if count >= LETTER_AT and not Game.flag(&"lettre_scellee"):
		await _sealed_letter()
		said = true
	# The count so far, when it has changed since he last said it.
	var n := Game.tears()
	if n != int(Game.flag(&"larmes_annoncees")):
		Game.set_flag(&"larmes_annoncees", n)
		said = await _next_goal(n) or said
	return said


static func _wake_pepite() -> void:
	S.lock(true)
	await S.say([{"who": ROC, "text": "Vingt larmes. Et ton fragment… Voyons si la couveuse se souvient de ce qu'elle sait faire."}])
	await S.fade_through(func() -> void:
		Audio.play_sfx(GLASS, -2.0)
		await S.wait(1.0))
	await S.say([
		{"text": "La couveuse s'illumine. Le fragment fond lentement, comme du miel au soleil… Il n'en reste qu'un œuf, tiède, qui bouge à peine."},
		{"who": ROC, "text": "C'est… la première fois que j'y arrive sans elle."},
		{"who": ROC, "text": "Garde-le contre toi. Il éclora quand il sera prêt. Marche, parle-lui : il t'entend déjà."},
		{"flag": &"pepite_oeuf"},
	])
	Game.egg = {"species": "protoceratops", "name": "Pépite", "steps": EGG_STEPS}
	Toast.say(S.world().get_tree(), "Objet obtenu : l'œuf de Pépite")
	Save.save_game()
	S.lock(false)


static func _sealed_letter() -> void:
	S.lock(true)
	var parent: String = PARENTS.get(StringName(Game.flag(&"starter")), PARENTS[&"velociraptor"])
	await S.say([
		{"who": ROC, "text": "Trente ?! Toutes les larmes des Plaines…"},
		{"text": "Roc ouvre un tiroir fermé à clé et en sort une enveloppe cachetée de cire ambrée."},
		{"who": ROC, "text": "Hélène me l'a confiée il y a un an. « Pour qui rapportera toutes les larmes des Plaines. » J'ai toujours su que ce serait toi."},
		{"letter": ["Pour toi, qui as tout ramassé",
			"Si tu lis ceci, tu as secoué chaque arbre, soulevé chaque pierre et attendu la lune au bord de l'étang. Tu es bien ma petite-fille.",
			"Je te dois un secret. L'œuf que je t'ai laissé ne vient pas de nulle part : son parent vit encore. C'est %s. Je l'ai réveillé il y a trente ans, et il ne m'a jamais oubliée." % parent,
			"Il reconnaîtra l'odeur de son petit. Quand tu le trouveras, dis-lui que je vais bien. Même si ce n'est pas tout à fait vrai."],
			"sign": "— H."},
		{"flag": &"lettre_scellee"},
	])
	Game.award_team_xp(XP_QUEST * 2)
	Save.save_game()
	S.lock(false)


## Roc tells how many tears the next thing needs (false when there is nothing left).
static func _next_goal(count: int) -> bool:
	for goal: Array in [[LANTERN_AT, &"lanterne", "la lanterne"], [PEPITE_AT, &"pepite_oeuf", "réveiller ton fragment"], [LETTER_AT, &"lettre_scellee", "… ça, c'est une surprise"]]:
		if not Game.flag(goal[1]) and count < goal[0]:
			await S.say([{"who": ROC, "text": "Tu as %d larme%s de l'île. À %d : %s." % [count, "s" if count > 1 else "", goal[0], goal[2]]}])
			return true
	return false


## The egg hatches (world.gd, when its last step is walked).
static func hatch() -> void:
	var egg := Game.egg
	Game.egg = {}
	S.lock(true)
	await S.say([
		{"text": "Crac ! L'œuf se fend contre Chloé…"},
		{"text": "Un minuscule Protoceratops s'extirpe de la coquille, éternue, et te regarde comme si tu étais sa mère."},
		{"who": CHLOE, "text": "Bonjour, %s." % egg.get("name", "Pépite")},
		{"flag": &"pepite_nee"},
	])
	var d := Dino.create(StringName(egg.get("species", "protoceratops")), 3, egg.get("name", "Pépite"))
	var in_party := Game.add_caught(d)
	Toast.say(S.world().get_tree(), "%s rejoint l'équipe !" % d.nickname if in_party else "%s rejoint le Cabinet." % d.nickname)
	Save.save_game()
	S.lock(false)


# ------------------------------------------------------------------ the sleeper

const SLEEPER := [
	"Un Protoceratops dort à poings fermés sous l'arbre. Il ronfle comme une vieille barque.",
	"Il ouvre un œil, te fixe… et le referme. Visiblement, tu ne fais pas partie de son rêve.",
	"Chloé lui pose une fougère sur la tête. Il ne se réveille pas. Ça lui va plutôt bien.",
	"Il marmonne quelque chose qui ressemble à « encore cinq minutes ».",
	"On ne réveille pas un dino qui dort. Ça, même Chloé le sait.",
	"Toujours endormi. Il a trouvé le coin le plus confortable des Plaines, et il compte bien le garder.",
]


static func sleeper() -> void:
	if Game.is_full_moon():
		await S.say([{"text": "Même la pleine lune ne le réveille pas. Il ronfle en rythme avec le chant de l'étang."}])
		return
	var n := int(Game.flag(&"dormeur_n"))
	await S.say([{"text": SLEEPER[mini(n, SLEEPER.size() - 1)]}])
	Game.set_flag(&"dormeur_n", n + 1)
