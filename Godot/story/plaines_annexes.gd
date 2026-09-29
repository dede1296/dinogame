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
## Chipie's level when she joins, a hatchling's out of its egg (as big as a dino of that level).
const CHIPIE_LEVEL := 6
const HATCH_LEVEL := 3
const GLASS := preload("res://assets/audio/sfx/glass.wav")
const RUSTLE := preload("res://assets/audio/sfx/feuillage.mp3")
const CHIME := preload("res://assets/audio/sfx/galet.mp3")
const LATCH := preload("res://assets/audio/sfx/latch.wav")
## An amber glow as the 3D view can show it: the picture tinted amber (colours above white do
## not show there) and a warm light on it.
const AMBER_TINT := Color(1.0, 0.8, 0.45)
const AMBER_LIGHT := Color(1.0, 0.72, 0.3)
const AMBER_FLASH := Color(1.0, 0.8, 0.4, 0.4)
## Where Chipie hides in the tall grass before her theft (tiles).
const CHIPIE_HIDE := Vector2(59.2, 47.2)
## In the Cabinet (tiles): the potted fern in the corner Roc talks to, the incubator, the
## drawer of his desk.
const FERN := Vector2(0.9, 9.6)
const INCUBATOR := Vector2(13.8, 3.6)
const DRAWER := Vector2(4.6, 4.1)
## In front of Roc's workbench (tiles), where he makes the lantern.
const WORKBENCH := Vector2(10.9, 3.0)
## Chloé's shoulder, above her feet (px), for Chipie climbing up there.
const SHOULDER := Vector2(7, -32)
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
	var chipie = S.actor("Chipie")
	# The grass stirs where she hides, then her mocking little cry.
	await S.say([_cue({"text": "Un froissement dans les herbes hautes… puis un petit cri moqueur."},
		func() -> void: _rustle(chipie))])
	Game.set_flag(&"chipie_etape", 0)
	Game.set_flag(&"boussole_volee")   # Chipie appears (FleeingDino)
	if chipie and maia_npc:
		var start: Vector2 = chipie.global_position
		chipie.global_position = S.at(CHIPIE_HIDE.x, CHIPIE_HIDE.y)
		await chipie.walk_to(maia_npc.global_position + Vector2(-26, 14), 260.0)
		chipie.cry(&"attaque")
		# Snatched! Maïa jumps.
		Stage.emote(maia_npc as Node2D, "!")
		Stage.hop(maia_npc, 1, 10.0)
		await S.wait(0.2)
		await chipie.walk_to(start, 260.0)
		chipie.sprite.flip_h = false
	await S.say([
		_cue({"who": MAIA, "text": "Hé ! HÉ ! Ma boussole ! Enfin… la boussole de maman. Elle va me tuer."},
			func() -> void: _face(maia_npc, chipie)),
		# The thief, over there, very pleased with herself.
		_cue({"who": MAIA, "text": "C'est une compso : ça chaparde tout ce qui brille, et ça cache tout dans un nid."},
			func() -> void:
				Stage.cry(chipie, &"neutre")
				Stage.emote(chipie, "♪")
				Stage.hop(chipie, 2, 6.0)),
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
		_cue({"text": "Chloé écarte les branches. Au fond du nid, un vrai trésor de pirate :"},
			func() -> void:
				Audio.play_sfx(RUSTLE, -4.0)
				Stage.bow(Stage.chloe(), 0.8)
				Stage.tremble(bush, 0.7, 2.5)),
		{"text": "une cuillère, trois boutons, un bouchon de bouteille, un bout de ruban bleu, deux galets d'ambre…"},
		{"text": "…des lunettes rondes rafistolées au ruban adhésif (le Professeur Roc a exactement les mêmes ; enfin, avait)…"},
		_cue({"text": "…et la boussole de Maïa !"}, func() -> void: _sparkles(bush.global_position, 10)),
	])
	# She springs out of the bush, then looks at the compass, at Chloé, at the compass.
	var chipie := DinoNpc.new()
	chipie.species_id = &"compsognathus"
	chipie.level = CHIPIE_LEVEL
	chipie.position = bush.position + Vector2(8, 4)
	chipie.modulate.a = 0.0
	bush.get_parent().add_child(chipie)
	await S.say([_cue({"text": "La propriétaire des lieux jaillit du buisson. Elle fixe la boussole. Puis Chloé. Puis la boussole."},
		func() -> void: _springs_out(chipie, bush))])
	var pick := await Dialogue.choose("", "Que fait Chloé ?", ["Lui offrir un bouton brillant", "Reprendre la boussole sans rien dire"])
	var acted := {"done": false}
	if pick == 0:
		await S.say([_cue({"text": "Chloé pose le plus brillant des boutons devant elle. La compso le renifle, le fait tourner, le range dans le nid… puis grimpe sur son épaule."},
			func() -> void: _run(func() -> void: await _takes_the_button(chipie, bush), acted))])
	else:
		await S.say([_cue({"text": "Chloé reprend la boussole. La compso pousse un cri outré… puis la suit quand même, à trois pas, en boudant. Tu es visiblement son nouveau trésor."},
			func() -> void: _run(func() -> void: await _sulks(chipie), acted))])
	await _finish(acted)
	for f in NEST_PEBBLES:
		Game.set_flag(f)
	Game.set_flag(&"boussole_trouvee")
	Game.set_flag(&"lunettes_trouvees")
	var in_party := Game.add_caught(Dino.create(&"compsognathus", CHIPIE_LEVEL, "Chipie"))
	await S.say([
		{"text": "Chipie rejoint l'équipe !" if in_party else "Chipie rejoint le Cabinet, où elle attend avec impatience."},
		{"text": "Elle a du Flair : elle sent ce qui est enfoui. La terre remuée de la Prairie ne lui échappera pas."},
	])
	await Stage.fade_out(chipie, 0.4, true)
	Toast.say(S.world().get_tree(), "Galets d'ambre : +2 (%d / 30)" % Game.pebbles_found("plaines"))
	Game.award_team_xp(XP_QUEST)
	Save.save_game()
	S.lock(false)


static func _compass_back() -> void:
	S.lock(true)
	var maia_npc = S.actor("Maia")
	await S.say([
		_cue({"who": MAIA, "text": "Tu l'as ?! Tu l'as ! Je t'aurais bien fait un câlin, mais j'ai une réputation."},
			func() -> void: Stage.hop(maia_npc, 2, 10.0)),
		# She bends over the compass in her hands.
		_cue({"text": "Maïa ouvre la boussole pour vérifier qu'elle marche. À l'intérieur du couvercle, une petite fougère est gravée."},
			func() -> void: Stage.bow(maia_npc, 1.6)),
		{"who": CHLOE, "text": "Cette fougère… C'est le signe de ma grand-mère. Il est sur la porte d'ambre des falaises."},
		{"who": MAIA, "text": "Hein ? Plein de gens gravent des fougères. C'est une vieille habitude, par ici, je te rappelle."},
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
	var prof = S.actor("Roc")
	var fern := S.at(FERN.x, FERN.y)
	await S.say([
		# He turns away from Chloé, to the fern in the corner (the camera shows it).
		_cue({"text": "Roc est en grande conversation avec la fougère en pot, dans le coin de la pièce."},
			func() -> void:
				Stage.turn_to(prof, fern)
				_look_between(prof, fern)),
		# (Still to the fern: the dialogue box would turn him to Chloé.)
		_cue({"who": ROC, "text": "… et donc, Chloé, je disais que… Tu as drôlement verdi, dis-moi."},
			func() -> void: Stage.turn_to(prof, fern)),
		_cue({"who": CHLOE, "text": "Professeur ? Je suis là. Et j'ai vos lunettes."}, func() -> void: Stage.look_back()),
		_cue({"text": "Roc chausse les lunettes. Il regarde Chloé. Il regarde la fougère. Il ne dit rien pendant un long moment."},
			func() -> void: _glasses_on(prof, fern)),
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
		var prof = S.actor("Roc")
		var made := {"done": false}
		await S.say([
			{"who": ROC, "text": "Dix larmes ! Donne… Voyons voir."},
			# Bent over his workbench: the pebbles light up one after the other in his hands.
			_cue({"text": "Roc visse les galets un à un dans une vieille lanterne de marin. Ils s'allument, doux comme des braises."},
				func() -> void: _run(func() -> void: await _lantern_lit(prof), made)),
		])
		await _finish(made)
		await S.say([
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
			await S.say([{"who": ROC, "text": "Vingt larmes, bravo. Il ne me manque qu'un fragment avec un petit dedans. Hélène en cachait dans son bosquet, à l'ouest de la Prairie."}])
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
		# The camera shows the incubator lighting up.
		_cue({"text": "La couveuse s'illumine. Le fragment fond lentement, comme du miel au soleil… Il n'en reste qu'un œuf, tiède, qui bouge à peine."},
			func() -> void:
				Stage.look_at(S.at(INCUBATOR.x, INCUBATOR.y))
				Stage.flash(AMBER_FLASH, 1.2)
				_sparkles(S.at(INCUBATOR.x, INCUBATOR.y), 18)),
		_cue({"who": ROC, "text": "C'est… la première fois que j'y arrive sans elle."}, func() -> void: Stage.look_back()),
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
	var prof = S.actor("Roc")
	var fetched := {"done": false}
	await S.say([
		{"who": ROC, "text": "Trente ?! Toutes les larmes de la Prairie…"},
		# He goes to the drawer of his desk, unlocks it, and comes back with the envelope.
		_cue({"text": "Roc ouvre un tiroir fermé à clé et en sort une enveloppe cachetée de cire ambrée."},
			func() -> void: _run(func() -> void: await _fetch_letter(prof), fetched)),
	])
	await _finish(fetched)
	await S.say([
		{"who": ROC, "text": "Hélène me l'a confiée il y a un an. « Pour qui rapportera toutes les larmes de la Prairie. » J'ai toujours su que ce serait toi."},
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
	var chloe := Stage.chloe()
	var baby := _hatchling(StringName(egg.get("species", "protoceratops")))
	await S.say([
		_cue({"text": "Crac ! L'œuf se fend contre Chloé…"},
			func() -> void:
				Stage.shake(2.0, 0.25)
				Stage.tremble(chloe, 0.35, 2.0)),
		# The little one at her feet: out of the shell, a sneeze, a loving look.
		_cue({"text": "Un minuscule Protoceratops s'extirpe de la coquille, éternue, et te regarde comme si tu étais sa mère."},
			func() -> void: _hatches(baby)),
		_cue({"who": CHLOE, "text": "Bonjour, %s." % egg.get("name", "Pépite")}, func() -> void: _face(chloe, baby)),
		{"flag": &"pepite_nee"},
	])
	await Stage.fade_out(baby, 0.4, true)
	var d := Dino.create(StringName(egg.get("species", "protoceratops")), HATCH_LEVEL, egg.get("name", "Pépite"))
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
	"Toujours endormi. Il a trouvé le coin le plus confortable de la Prairie, et il compte bien le garder.",
]


static func sleeper() -> void:
	if Game.is_full_moon():
		await S.say([{"text": "Même la pleine lune ne le réveille pas. Il ronfle en rythme avec le chant de l'étang."}])
		return
	var n := int(Game.flag(&"dormeur_n"))
	var sleeper_npc = S.actor("Dormeur")
	await S.say([_cue({"text": SLEEPER[mini(n, SLEEPER.size() - 1)]}, func() -> void: _sleeper_stirs(sleeper_npc, n))])
	Game.set_flag(&"dormeur_n", n + 1)


## What the sleeper does as its line says it (see SLEEPER): snores, opens an eye at Chloé,
## gets a fern on its head, mumbles.
static func _sleeper_stirs(dino, line: int) -> void:
	if dino == null or not is_instance_valid(dino):
		return
	match line:
		0:
			Stage.emote(dino, "z")
		1:   # an eye opened at Chloé… and closed again
			var was: bool = dino.sprite.flip_h
			Stage.turn_to(dino, Stage.chloe().global_position)
			Stage.emote(dino, "…")
			await S.wait(1.6)
			if is_instance_valid(dino):
				dino.sprite.flip_h = was
		2:
			Stage.bow(Stage.chloe(), 0.9)
			await S.wait(0.5)
			Stage.bow(dino, 0.6)
		3:
			Stage.bow(dino, 0.8)
			Stage.emote(dino, "…")


# ------------------------------------------------------------------ what the lines show

## The tall grass stirs where Chipie hides (leaves flying, a rustle), then her mocking cry.
static func _rustle(chipie) -> void:
	var at := S.at(CHIPIE_HIDE.x, CHIPIE_HIDE.y)
	Audio.play_sfx(RUSTLE, -3.0)
	var view := _view()
	if view:
		view.burst(at, Search.LEAVES, 10, 0.3, 0.5)
	await S.wait(0.8)
	if view:
		view.burst(at + Vector2(20, -6), Search.LEAVES, 6, 0.3, 0.4)
	await S.wait(0.5)
	Stage.cry(chipie, &"neutre")


## Chipie springs out of her bush, then stares at the compass (down into the nest), at Chloé,
## at the compass again.
static func _springs_out(chipie: DinoNpc, bush: Node2D) -> void:
	Audio.play_sfx(RUSTLE, -4.0)
	Stage.tremble(bush, 0.5, 3.0)
	chipie.cry(&"attaque")
	chipie.create_tween().tween_property(chipie, "modulate:a", 1.0, 0.15)
	await chipie.walk_to(bush.position + Vector2(66, 40), 300.0)   # (out in the open, beside Chloé)
	if not is_instance_valid(chipie):
		return
	await Stage.hop(chipie, 1, 12.0)
	Stage.turn_to(chipie, bush.global_position)
	await Stage.bow(chipie, 0.7)
	if not is_instance_valid(chipie):
		return
	Stage.emote(chipie, "!")
	await Stage.rear(chipie, 0.7)
	if is_instance_valid(chipie):
		await Stage.bow(chipie, 0.7)


## The button: a sniff, a turn, into the nest… then up onto Chloé's shoulder.
static func _takes_the_button(chipie: DinoNpc, bush: Node2D) -> void:
	var chloe := Stage.chloe()
	if not is_instance_valid(chipie) or chloe == null:
		return
	await Stage.bow(chloe, 0.7)
	for i in 2:   # it sniffs the button
		if is_instance_valid(chipie):
			await Stage.bow(chipie, 0.45)
	if not is_instance_valid(chipie):
		return
	await chipie.walk_to(bush.position + Vector2(10, 10), 160.0)   # into the nest
	await S.wait(0.3)
	if not is_instance_valid(chipie):
		return
	await chipie.walk_to(chloe.global_position + Vector2(SHOULDER.x, 3), 180.0)
	if not is_instance_valid(chipie):
		return
	chipie.collision_layer = 0   # (on her shoulder: not in her way)
	chipie.sprite.flip_h = false
	var sprite := chipie.sprite
	var up := sprite.create_tween()
	up.tween_property(sprite, "position:y", SHOULDER.y - 14.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	up.tween_property(sprite, "position:y", SHOULDER.y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await up.finished
	chipie.cry(&"neutre")
	Stage.emote(chipie, "♥")


## The compass taken back: an outraged cry… then it follows her all the same, three steps away, sulking,
## its back turned.
static func _sulks(chipie: DinoNpc) -> void:
	var chloe := Stage.chloe()
	if not is_instance_valid(chipie) or chloe == null:
		return
	await Stage.bow(chloe, 0.7)
	if not is_instance_valid(chipie):
		return
	chipie.cry(&"attaque")
	Stage.emote(chipie, "!")
	await Stage.rear(chipie, 0.6)
	await S.wait(0.6)
	if not is_instance_valid(chipie):
		return
	# Three steps from her, at her side (not behind her in the tall grass, where she would vanish).
	var side := -1.0 if chipie.global_position.x < chloe.global_position.x else 1.0
	await chipie.walk_to(chloe.global_position + Vector2(side * 64.0, 4.0), 120.0)
	if not is_instance_valid(chipie):
		return
	chipie.sprite.flip_h = chloe.global_position.x > chipie.global_position.x   # back to her
	Stage.emote(chipie, "…")


## Roc puts his glasses on (a nod), looks at Chloé, at the fern, at Chloé: a long silence.
static func _glasses_on(roc_npc, fern: Vector2) -> void:
	if roc_npc == null or not is_instance_valid(roc_npc):
		return
	await Stage.bow(roc_npc, 0.6)
	var chloe := Stage.chloe()
	for look: Vector2 in [chloe.global_position, fern, chloe.global_position]:
		if not is_instance_valid(roc_npc):
			return
		Stage.turn_to(roc_npc, look)
		await S.wait(0.9)
	Stage.emote(roc_npc, "…")


## Bent over the lantern: the pebbles light up one after the other in Roc's hands.
## (At his workbench, out of Chloé's way, so it is seen; then he comes back to her.)
static func _lantern_lit(roc_npc) -> void:
	if roc_npc == null or not is_instance_valid(roc_npc):
		return
	var home: Vector2 = roc_npc.global_position
	await roc_npc.walk_to(S.at(WORKBENCH.x, WORKBENCH.y), "up", 130.0)
	if not is_instance_valid(roc_npc):
		return
	Stage.bow(roc_npc, 1.2)
	await S.wait(0.5)
	for i in 3:
		if not is_instance_valid(roc_npc):
			return
		Audio.play_sfx(CHIME, -8.0, 0.1)
		await _amber(roc_npc, 1, 0.6, 2.5)
	if not is_instance_valid(roc_npc):
		return
	await roc_npc.walk_to(home, "", 130.0)
	if is_instance_valid(roc_npc) and Stage.chloe():
		roc_npc.face(Stage.chloe().global_position)


## Roc goes to his desk's drawer, unlocks it, takes out the envelope, and comes back.
static func _fetch_letter(roc_npc) -> void:
	if roc_npc == null or not is_instance_valid(roc_npc):
		return
	var home: Vector2 = roc_npc.global_position
	await roc_npc.walk_to(S.at(DRAWER.x, DRAWER.y), "up", 120.0)
	if not is_instance_valid(roc_npc):
		return
	Audio.play_sfx(LATCH, -4.0)
	await Stage.bow(roc_npc, 0.8)
	if not is_instance_valid(roc_npc):
		return
	await roc_npc.walk_to(home, "", 120.0)
	if is_instance_valid(roc_npc) and Stage.chloe():
		roc_npc.face(Stage.chloe().global_position)


## The little one hatching at Chloé's feet (hidden until its line; a scene actor, gone when the
## scene ends). None in the water.
static func _hatchling(species: StringName) -> DinoNpc:
	var chloe := Stage.chloe()
	var w = S.world()
	if chloe == null or w == null or w.get("region") == null or chloe.is_swimming():
		return null
	var baby := DinoNpc.new()
	baby.species_id = species
	baby.level = HATCH_LEVEL
	baby.position = S.ground_near(chloe.global_position + Vector2(30, 14), 1)
	baby.modulate.a = 0.0
	w.region.entities.add_child(baby)
	return baby


## Out of the shell: it appears, sneezes (a jolt and a little cry), and looks up at Chloé with love.
static func _hatches(baby) -> void:
	if baby == null or not is_instance_valid(baby):
		return
	Stage.turn_to(baby, Stage.chloe().global_position)
	await Stage.fade_in(baby, 0.5)
	await S.wait(0.7)
	if not is_instance_valid(baby):
		return
	baby.cry(&"neutre")
	await Stage.hop(baby, 1, 5.0)
	await S.wait(0.5)
	Stage.emote(baby, "♥")


# ------------------------------------------------------------------ staging (see Stage)

## A line whose staging starts the moment it shows: `act` is called then (not awaited), so
## the move goes with its bubble, without cutting the dialogue in two.
static func _cue(line: Dictionary, act: Callable) -> Dictionary:
	var cued := line.duplicate()
	var text: String = cued["text"]
	cued.erase("text")
	cued["text_fn"] = func() -> String:
		act.call()
		return text
	return cued


## Plays `move` (a coroutine) and marks `token` done at its end (see _finish): a move that
## goes on under the lines, and that the scene waits for before going further.
static func _run(move: Callable, token: Dictionary) -> void:
	await move.call()
	token["done"] = true


## Waits for a move started with _run (at most `max_s` seconds, whatever happens).
static func _finish(token: Dictionary, max_s := 12.0) -> void:
	var waited := 0.0
	while not token.get("done", false) and waited < max_s:
		await S.wait(0.05)
		waited += 0.05


## `who` turns to look at `target` (both actors; nothing when one is missing).
static func _face(who, target) -> void:
	if who and target and is_instance_valid(who) and is_instance_valid(target):
		Stage.turn_to(who, (target as Node2D).global_position)


## The camera shows an actor and a point at once (the middle of them).
static func _look_between(who, px: Vector2) -> void:
	if who and is_instance_valid(who):
		Stage.look_at(((who as Node2D).global_position + px) / 2.0)


## A burst of amber sparkles at `px` (world pixels).
static func _sparkles(px: Vector2, amount := 14) -> void:
	var view := _view()
	if view:
		view.burst(px, Search.AMBER, amount, 0.6, 0.5)


static func _view() -> WorldView:
	return (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view") as WorldView

## An amber glow on `actor` (a scale, a seal, a page…), `times` pulses: its picture tinted
## amber and a warm light shining on it (see _light_at). Awaitable.
static func _amber(actor, times := 1, secs := 0.8, energy := 3.0) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	Stage.glow(actor, AMBER_TINT, times, secs)
	var light := _light_at((actor as Node2D).global_position, AMBER_LIGHT)
	if light == null:
		return
	var t := light.create_tween()
	for i in times:
		t.tween_property(light, "light_energy", energy, secs * 0.5).set_trans(Tween.TRANS_SINE)
		t.tween_property(light, "light_energy", 0.0, secs * 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_callback(light.queue_free)
	await t.finished


## A light of the 3D view at `px` (world pixels), a little above the ground, off (energy 0):
## the caller brightens it, then frees it. Null without the view.
static func _light_at(px: Vector2, colour: Color, reach := 3.2) -> OmniLight3D:
	var view := (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view") as WorldView
	if view == null or view.heights == null:
		return null
	var light := OmniLight3D.new()
	light.light_color = colour
	light.light_energy = 0.0
	light.omni_range = reach
	light.shadow_enabled = false
	view.add_child(light)
	light.position = view.heights.to_3d(px) + Vector3(0, 1.1, 0.5)
	return light
