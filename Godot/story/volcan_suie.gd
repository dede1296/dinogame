class_name VolcanSuie
## Chapter 8, the Plaine Volcanique, Dame Suie at the foot of the great forge (zone forges_ombre;
## docs/chapitre-8-scenes.md, scene 6): she watched it all and took notes (« Le sujet 12 a…
## réfléchi »); the captain took one vial at dawn and told her to put the forge out; she did not:
## she was watching the little one, « la fille du Masque », without a drop and without fear.
## Belladone, the sleepers, Maïa: three times, the tables are wrong (a choice: Chloé says it, or
## lets her finish). She takes off her gloves, turns the wheel: the great forge goes out « comme
## une lampe qu'on baisse »; her smoked glasses put away for good. The Ambre clair (one dose),
## then Hélène's letter « Pour Isaure » (page 37), kept a year unopened. She leaves with Mandragore
## and Hélène's notebooks, for the Cabinet; her gloves stay on the bench. Cold, curious, not cruel:
## she never says sorry (« je refais mes tables »); « Maïa » is said by Chloé only. No battle.
## Short moments (Greg, 18/10): ~9 lines in a row at most, cut by things watched (the gloves off,
## the wheel and the forge going out, the bench, the sled loaded, the sled gone) and one choice.
## Flags: suie_volcan_vue, suie_alliee, grande_forge_eteinte, antidote_ambre, found_journal_37,
## page_37, suie_partie. Items: antidote_ambre, lettre_isaure (the MÉCANIQUES agent's ItemsDB).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const MS := preload("res://story/monts_stage.gd")
const Act := preload("res://story/marais_stage.gd")
const V := preload("res://story/volcan.gd")
const CHLOE := "Chloé"
const SUIE := "Dame Suie"
const ANTIDOTE := "antidote_ambre"
const LETTER := "lettre_isaure"
const GREAT_KIND_OUT := "grande_forge_eteinte"
## Her look without the smoked glasses (Outfits.LOOKS « dame_suie », when the IMAGES agent draws it).
const NO_GLASSES := &"sans_lunettes"
## The music and the ambience held back while the great forge goes quiet (dB), and how long.
const HUSH_DB := -30.0
const HUSH_S := 3.0
## How far the sled goes before the ash hides it (tiles), how long it takes (s).
const SLED_WALK := 12.0
const SLED_LEAVES := 6.0
const XP_SUIE := 120


## What she says before Brac has lost (a line each time, `suie_volcan_n`).
const SUIE_WAITS := [
	"Finissez d'abord avec Brac, mademoiselle. Il a besoin de perdre une dernière fois : ça lui fera du bien, et j'ai besoin de le noter.",
	"Brac d'abord, mademoiselle. Je note mieux quand il a fini de crier.",
	"Toujours pas battu ? Mes tables attendent, et elles n'aiment pas ça.",
]


## Scene 6, Dame Suie (Npc « SuieVolcan », event « suie_volcan », hide_flag suie_partie): once
## Brac has lost, the whole scene, each part resumed where it stopped (its flag).
static func suie(who: Node) -> void:
	if Game.flag(&"suie_partie"):
		return
	if not Game.flag(&"brac_vaincu"):
		await S.say([{"who": SUIE, "text": ForetCamp.next_line(&"suie_volcan_n", SUIE_WAITS)}])
		return
	S.lock(true)
	var cast := {"suie": who}
	if not Game.flag(&"suie_volcan_vue"):
		await S.say(_took_your_time(who))
		await _gloves_off(who, cast)
		await S.say(_three_times(who))
		var pick := await Dialogue.choose("", "Dame Suie attend. Que dit Chloé ?", ["« Trois, c'est que les tables sont fausses. »", "La laisser finir"])
		await S.say(_tables(pick == 0))
	if not Game.flag(&"grande_forge_eteinte"):
		await _to_the_wheel(who)
		await S.say(_goes_out(who))
	if not Game.flag(&"antidote_ambre"):
		await _to_the_bench(who)
		await S.say(_antidote(who))
		if ItemsDB.ITEMS.has(ANTIDOTE) and Game.item_count(ANTIDOTE) == 0:
			Game.give_item(ANTIDOTE)
		Toast.say(S.world().get_tree(), "Objet obtenu : l'Ambre clair")
		Save.save_game()
	if not Game.flag(&"found_journal_37"):
		await S.say(_the_letter(who))
		if ItemsDB.ITEMS.has(LETTER) and Game.item_count(LETTER) == 0 and not Game.flag(&"lettre_isaure_donnee"):
			Game.give_item(LETTER)
		Toast.say(S.world().get_tree(), "Objet obtenu : la lettre pour Isaure")
		Save.save_game()
	await _loads_the_sled(who)
	await S.say(_leaves(who))
	await _sled_goes(who, cast)
	await S.say([
		{"who": CHLOE, "text": "(Froide, curieuse, pas cruelle. Elle n'a pas changé. Elle a seulement compté jusqu'à trois.)"},
		{"flag": &"suie_partie"},
	])
	Audio.duck(0.0, 2.5)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_SUIE)
	Save.save_game()
	S.lock(false)


## 6 a (9 lines), « Vous avez pris votre temps »: she finishes her line; the captain at dawn, one
## vial; she did not put it out: she watched the little one. No line for that in her tables.
static func _took_your_time(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = _px(who)
	var bench := _bench_px(at)
	var great := _great_px(at)
	var writes := func() -> void:
		Stage.look_at(at.lerp(chloe.global_position, 0.4), 0.8)
		await CS.chloe_walk(at + Vector2(-30.0, 110.0), 90.0, 2.0)
		Stage.turn_to(chloe, at)
		Stage.turn_to(who, bench)
		for i in 3:
			await CS.reach(who, bench, 4.0, 0.5)
	var pen := func() -> void:
		await CS.reach(who, bench, 6.0, 0.8)
		Stage.turn_to(who, chloe.global_position)
	var turns := func() -> void:
		Stage.turn_to(who, great)
		await Stage.look_at(great + Vector2(0.0, -2.0 * S.CELL), 1.2)
		CS.pulse(great, MS.VIOLET, 2, 1.4, 3.0, 6.0)
	var eyes := func() -> void:
		Stage.look_back(0.8)
		Stage.turn_to(who, chloe.global_position)
	return [
		CS.cue({"who": SUIE, "text": "Mademoiselle Varenne. Vous avez pris votre temps. Trois forges, une barricade, et Brac : j'ai tout regardé, et j'ai pris des notes. Vous permettez que je finisse ma ligne ?"}, writes),
		CS.cue({"who": SUIE, "text": "Voilà. « Le sujet 7 a renversé sa propre forge. Le sujet 11 a arraché le soufflet. Le sujet 12 a… réfléchi. » Ce n'est pas un mot de mes tables."}, pen),
		{"who": CHLOE, "text": "Vous n'avez rien fait pour les empêcher."},
		{"who": SUIE, "text": "Non. J'observais. C'est mon métier : Brac chasse, le Masque veut, et moi j'observe. Et depuis ce matin, j'observe surtout que je n'ai plus de Masque."},
		CS.cue({"who": SUIE, "text": "La capitaine est passée à l'aube. Elle m'a pris une fiole, la plus pure, et elle a dit : « Vous pouvez éteindre, Dame Suie. Je n'ai plus besoin que d'une goutte. »"}, turns),
		CS.cue({"who": SUIE, "text": "Je n'ai pas éteint. Ce n'est pas la fiole que je regardais partir, mademoiselle. C'est la petite."}, eyes),
		{"who": CHLOE, "text": "Maïa."},
		{"who": SUIE, "text": "La fille du Masque. À côté de sa mère, pas derrière, de la cendre jusqu'aux genoux, et elle disait bonjour aux sbires. Un par un. Elle a dit bonjour à Brac."},
		{"who": SUIE, "text": "Je regarde toujours les yeux : c'est là que l'ambre noir se voit en premier. Pas une goutte. Et pas peur. Il n'y a pas de ligne pour ça dans mes tables. J'ai regardé deux fois."},
		{"flag": &"suie_volcan_vue"},
	]


## Watched, no line: her gloves off, one finger after the other, laid on the bench (at the Monts,
## her glasses; here, the gloves: she is going to touch something).
static func _gloves_off(who: Node, cast: Dictionary) -> void:
	var at: Vector2 = _px(who)
	var bench := _bench_px(at)
	Stage.turn_to(who, bench)
	for i in 5:
		CS.reach(who, at + Vector2(0.0, -10.0), 3.0, 0.3)
		await S.wait(0.35)
	await CS.reach(who, bench, 8.0, 0.8)
	var g := Stage.show_thing("gants_gris", V.spot_or("GANTS", bench + Vector2(-20.0, 8.0)), "GantsSuieScene")
	cast["gloves"] = g
	Stage.turn_to(who, Stage.chloe().global_position)
	await S.wait(0.6)


## 6 b (3 lines), Belladone, the sleepers, and Maïa: « Une exception, c'est une exception. Deux,
## c'est une erreur de mesure. Trois… » (then the choice).
static func _three_times(who: Node) -> Array:
	var counts := func() -> void:
		for i in 3:
			Stage.hop(who, 1, 3.0)
			await S.wait(0.9)
	return [
		{"who": SUIE, "text": "Je vais vous dire où j'en suis, mademoiselle Varenne, parce que vous êtes la seule personne de cette île à qui ça puisse servir."},
		CS.cue({"who": SUIE, "text": "Au Marais, Belladone, sans une goutte : j'ai noté « exception ». Aux Monts, les dormeurs de votre grand-mère : « à vérifier ». Ce matin, la fille du Masque : je n'avais plus de colonne."}, counts),
		{"who": SUIE, "text": "Une exception, c'est une exception. Deux, c'est une erreur de mesure. Trois…"},
	]


## After the choice (3 lines; `said`: Chloé finished her sentence, else Dame Suie finished it
## herself): the tables are wrong; the word that was missing.
static func _tables(said: bool) -> Array:
	var lines: Array = []
	if said:
		lines.append_array([
			{"who": CHLOE, "text": "Trois, c'est que les tables sont fausses."},
			{"who": SUIE, "text": "… Vous avez les yeux de votre grand-mère. Ils finissent mes phrases avant moi."},
		])
	else:
		lines.append_array([
			{"who": SUIE, "text": "Trois, c'est que les tables sont fausses."},
			{"who": SUIE, "text": "… Vous l'avez pensé avant moi, et vous ne l'avez pas dit. Vous avez les yeux de votre grand-mère, mademoiselle : ils finissent mes phrases."},
		])
	lines.append({"who": SUIE, "text": "« La peur n'est qu'un problème de dosage. » Je l'ai écrit en tête de chaque carnet pendant douze ans. Il manquait un mot. La peur n'est pas un problème de dosage : c'est un problème. Point."})
	return lines


## Watched, no line: she goes to the iron wheel of the great forge's draught and turns it; it
## grinds; the red goes down like a lamp blown out slowly, the violet smoke whitens and stops;
## silence, the first in twelve years; Mandragore lifts its head, surprised, and lays it down.
static func _to_the_wheel(who: Node) -> void:
	var at: Vector2 = _px(who)
	var great := _great_px(at)
	var wheel := _wheel_px(at)
	var forge = V.actor_of(["GrandeForge"])
	if who is Npc:
		await (who as Npc).walk_to(S.ground_near(wheel, 2), "", 60.0)
		(who as Npc).face(wheel)
	Stage.look_at(wheel.lerp(Stage.chloe().global_position, 0.4), 1.0)
	await CS.reach(who, wheel, 8.0, 1.0)
	CS.sfx(V.TINKLE, -6.0)
	Stage.tremble(who, 1.2, 1.5)
	Audio.duck(HUSH_DB, HUSH_S)
	Stage.look_at(great + Vector2(0.0, -2.0 * S.CELL), 1.2)
	CS.pulse(great, V.FIRE_RED, 1, HUSH_S, 2.0, 6.0)
	for i in 3:
		Act.burst(great + Vector2(0.0, -60.0), MS.BREATH_BITS, 10, 2.4, 0.3)
		await S.wait(0.8)
	if forge:
		Stage.repaint(forge, GREAT_KIND_OUT, 1.6)
	var mandragore = V.actor_of(["Mandragore"])
	if mandragore:
		Stage.rear(mandragore, 0.8)
		await S.wait(1.2)
		Stage.bow(mandragore, 1.0)
	await S.wait(0.8)


## 6 c (4 lines), the great forge out: « Douze ans. Ça fait moins de bruit que je pensais. »; her
## smoked glasses in her pocket, for good.
static func _goes_out(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = _px(who)
	var glasses := func() -> void:
		Stage.look_back(0.8)
		if who is Npc:
			(who as Npc).face(chloe.global_position)
		await CS.reach(who, at + Vector2(0.0, -30.0), 5.0, 0.8)
		Stage.dress(who, NO_GLASSES)
	return [
		{"text": "La grande forge s'éteint. Pas d'un coup : comme une lampe qu'on baisse. Le rouge devient rose, puis gris. Et puis, plus rien. Le silence. Le vrai : on entend le vent, et Moustique qui respire."},
		{"who": SUIE, "text": "Voilà. Douze ans. Ça fait moins de bruit que je pensais."},
		CS.cue({"who": SUIE, "text": "Elles étaient contre la lueur. Il n'y a plus de lueur."}, glasses),
		{"who": CHLOE, "text": "(Elle a des yeux gris. Je ne les avais jamais vus. Ils ont l'air… fatigués. Et curieux.)"},
		{"flag": &"grande_forge_eteinte"},
	]


## Watched, no line: back to the bench; she opens a small wooden box.
static func _to_the_bench(who: Node) -> void:
	var at: Vector2 = _px(who)
	var bench := _bench_px(at)
	if who is Npc:
		await (who as Npc).walk_to(S.ground_near(bench + Vector2(0.0, 40.0), 2), "", 60.0)
		(who as Npc).face(bench)
	await CS.reach(who, bench, 8.0, 0.8)
	CS.pulse(bench, Color(1.0, 0.85, 0.45), 2, 1.2, 1.8, 2.5)
	await S.wait(0.6)


## 6 d (7 lines), the antidote: a vial of clear amber, warm. One dose. « La première ligne de la
## nouvelle, c'est vous. »
static func _antidote(who: Node) -> Array:
	var chloe := Stage.chloe()
	var gives := func() -> void:
		if who is Npc:
			(who as Npc).face(chloe.global_position)
		await CS.reach(who, chloe.global_position, 14.0, 1.0)
		if ItemsDB.ITEMS.has(ANTIDOTE):
			CS.Act.pop(chloe.global_position, ANTIDOTE, 0.9)
		Stage.glow(chloe, Color(1.5, 1.3, 0.8), 1, 1.0)
	return [
		{"text": "Dans le coffret, une fiole : de l'ambre liquide, clair, presque doré, qui luit un peu dans le gris. Étiquette fine : « Ambre clair. Une goutte. Pas une de plus. — S. »"},
		{"who": SUIE, "text": "On ne fabrique pas un poison sans fabriquer son contraire. C'est la première règle. Je l'ai mis au point la nuit, aux Monts, après Aconit. Par curiosité : je voulais savoir si ça se défaisait."},
		{"who": CHLOE, "text": "Et ça se défait ?"},
		{"who": SUIE, "text": "Une goutte sur un dino corrompu, et les veines s'effacent. D'un coup. Sans parler, sans Lien : de la chimie. Vous n'en aurez pas besoin ici : vous faites mieux que moi, et plus lentement."},
		CS.cue({"who": SUIE, "text": "Mais la capitaine a une fiole, la plus pure, et elle va s'en servir sur quelque chose de très grand, qui dort. Ce jour-là, vous n'aurez pas le temps de parler. Une dose. Choisissez votre moment."}, gives),
		{"who": CHLOE, "text": "Pourquoi vous me la donnez ?"},
		{"who": SUIE, "text": "Parce que je refais mes tables, et que la première ligne de la nouvelle, c'est vous."},
		{"flag": &"suie_alliee"},
		{"flag": &"antidote_ambre"},
	]


## 6 e (7 lines, then page 37 in the LetterView), the letter: she hesitates (it is rare); the drawer
## of the bench, a thick envelope folded in two, « Pour Isaure ». Hélène put it on her bench a year
## ago, one night. Not sealed: folded. Chloé reads it, and will take it to Isaure.
static func _the_letter(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = _px(who)
	var bench := _bench_px(at)
	var drawer := func() -> void:
		Stage.emote(who, "…")
		await S.wait(1.0)
		await CS.reach(who, bench, 8.0, 1.0)
	var takes := func() -> void:
		if who is Npc:
			(who as Npc).face(chloe.global_position)
		await CS.reach(who, chloe.global_position, 14.0, 0.9)
		if ItemsDB.ITEMS.has(LETTER):
			CS.Act.pop(chloe.global_position, LETTER, 0.9)
		Stage.bow(chloe, 0.8)
	var lines: Array = [
		CS.cue({"who": SUIE, "text": "Il y a autre chose. Ce n'est pas à moi, et je l'ai gardée un an. Ça fait deux fautes."}, drawer),
		{"text": "Elle ouvre le tiroir de l'établi et en sort une enveloppe de papier épais, pliée en deux, jaunie par la chaleur. Dessus, une écriture qu'on connaît : « Pour Isaure »."},
		{"who": SUIE, "text": "Votre grand-mère est venue ici, il y a un an, une nuit. Elle a traversé le camp comme on traverse sa cuisine, elle a posé ça sur mon établi, elle m'a regardée, et elle est repartie vers les coulées."},
		{"who": SUIE, "text": "Elle m'a regardée comme on regarde une élève qui a bien travaillé sur un mauvais sujet. … Je n'ai pas aimé. J'y repense souvent."},
		{"who": SUIE, "text": "Je ne lis pas le courrier des autres : j'ai des défauts, pas celui-là. Je la gardais pour la lui donner. Elle est passée ce matin, et je ne l'ai pas fait."},
		{"who": SUIE, "text": "Parce que si elle l'avait lue, elle ne serait peut-être pas montée. Et je voulais voir ce qui se passe quand on monte. … Troisième faute. Je vous la laisse corriger : vous allez là où elle va."},
		CS.cue({"who": CHLOE, "text": "(Pliée, pas fermée. Elle voulait que quelqu'un la lise, si Isaure ne venait pas. … Je la lis. Et je la lui porte.)"}, takes),
	]
	lines.append_array(DialogueVolcan.page_37(false))
	return lines


## Watched, no line: her notebook put away, not her gloves; Mandragore harnessed to the sled on
## wheels, full of crates: Hélène's notebooks.
static func _loads_the_sled(who: Node) -> void:
	var mandragore = V.actor_of(["Mandragore"])
	var sled = V.actor_of(["TraineauSuie", "Traineau"])
	if mandragore is Node2D:
		Stage.look_at((mandragore as Node2D).global_position, 1.0)
		if who is Npc:
			await (who as Npc).walk_to(S.ground_near((mandragore as Node2D).global_position + Vector2(-50.0, 20.0), 2), "", 70.0)
		Stage.hop(mandragore, 1, 4.0)
		await S.wait(0.8)
	if sled is Node2D:
		CS.reach(who, (sled as Node2D).global_position, 8.0, 0.8)
		await S.wait(0.8)
	if who is Npc:
		(who as Npc).face(Stage.chloe().global_position)
	await S.wait(0.5)


## 6 f (7 lines), she goes: the notebooks back to the Cabinet (« Il fera du thé. »); the lava flows
## are that way (« le cuir pour »); « Merci », the second today; « Nous nous reverrons. Là où il
## fait bon, cette fois. »
static func _leaves(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = _px(who)
	var coulees := V.spot_or("SORTIE_COULEES", at + Vector2(8.0 * S.CELL, 0.0))
	var away := V.spot_or("ENTREE_FORGES", at + Vector2(0.0, 12.0 * S.CELL))
	var points := func() -> void:
		if who is Npc:
			CS.reach(who, coulees, 10.0, 1.2)
		Stage.look_at(coulees, 1.0)
	var back := func() -> void:
		Stage.look_back(0.6)
		if who is Npc:
			(who as Npc).face(chloe.global_position)
	var step := func() -> void:
		if who is Npc:
			var dir: Vector2 = (away - at).normalized() if away.distance_to(at) > 1.0 else Vector2(0.0, 1.0)
			await (who as Npc).walk_to(S.ground_near(at + dir * S.CELL, 2), "", 50.0)
	return [
		{"who": SUIE, "text": "Les carnets de votre grand-mère. Ceux de l'ambre forcé, ceux qu'on m'a donnés il y a douze ans « pour travailler ». J'ai travaillé. Je les rends."},
		{"who": CHLOE, "text": "À qui ?"},
		{"who": SUIE, "text": "Au Cabinet. À votre professeur Roc, qui a une clé, du thé, et une couveuse qu'il regarde comme si elle allait lui répondre. Je lui dirai que je refais mes tables. Il ne comprendra pas. Il fera du thé."},
		CS.cue({"who": SUIE, "text": "Les coulées sont par là, mademoiselle. Pour les franchir, il vous faut un dino qui a le cuir pour : de la pierre, ou du feu. Brac en avait un. Il l'a laissé choisir : la première chose intelligente qu'il ait faite, et il ne le sait pas."}, points),
		CS.cue({"who": CHLOE, "text": "Dame Suie. … Merci."}, back),
		{"who": SUIE, "text": "… C'est la deuxième fois aujourd'hui qu'on me dit ça dans ce camp. La première, c'était la petite Kerval, pour un sbire qui lui avait tenu une cage ouverte. Je commence à croire que c'est contagieux."},
		CS.cue({"who": SUIE, "text": "Nous nous reverrons. Là où il fait bon, cette fois. J'aimerais bien."}, step),
	]


## Watched, no line: the sled goes off towards the fields, Mandragore at a trot. She does not turn
## round. On the bench, her pearl-grey gloves, side by side.
static func _sled_goes(who: Node, cast: Dictionary) -> void:
	var chloe := Stage.chloe()
	var at: Vector2 = _px(who)
	var away := V.spot_or("ENTREE_FORGES", at + Vector2(0.0, 12.0 * S.CELL))
	var walkers: Array = [who, V.actor_of(["Mandragore"]), V.actor_of(["TraineauSuie", "Traineau"])]
	for wk in walkers:
		if not is_instance_valid(wk):
			continue
		var from: Vector2 = (wk as Node2D).global_position
		var dir: Vector2 = (away - from).normalized() if away.distance_to(from) > 1.0 else Vector2(0.0, 1.0)
		var to := from + dir * SLED_WALK * S.CELL
		Stage.fade_out(wk, SLED_LEAVES, false)
		if wk is Npc:
			(wk as Npc).walk_to(to, "", 90.0)
		elif wk is DinoNpc:
			(wk as DinoNpc).walk_to(to, 90.0)
		else:
			(wk as Node2D).create_tween().tween_property(wk, "global_position", to, SLED_LEAVES)
	Stage.look_at(away.lerp(chloe.global_position, 0.5), 2.0)
	await S.wait(SLED_LEAVES * 0.6)
	var g = cast.get("gloves")
	Stage.look_back(1.0)
	if is_instance_valid(g):
		Stage.turn_to(chloe, (g as Node2D).global_position)
	await S.wait(1.0)


# ------------------------------------------------------------------ the bench, the great forge

## The great forge (StoryProp « GrandeForge »): too hot to come near; then cold, ticking.
static func grande_forge(_who: Node) -> void:
	if Game.flag(&"grande_forge_eteinte"):
		await S.say([{"text": "La grande forge, froide. La brique noire craque encore un peu en refroidissant. Douze ans, et ça fait ce bruit-là : tic, tic."}])
		return
	await S.say([{"text": "La grande forge. On ne peut pas s'en approcher : la chaleur repousse."}])


## Dame Suie's bench (StoryProp « Etabli »): her vials, her balance; once she has gone, her gloves.
static func etabli(_who: Node) -> void:
	if Game.flag(&"suie_partie"):
		await S.say([{"text": "L'établi de Dame Suie. Des fioles en rang, une balance, et une paire de gants gris perle, posés côte à côte. Elle ne les a pas oubliés."}])
		return
	await S.say([{"text": "Un établi impeccable : des fioles étiquetées en rang, une balance, un carnet ouvert, une plume."}])


# ------------------------------------------------------------------ helpers

static func _px(who) -> Vector2:
	if who is Node2D and is_instance_valid(who):
		return (who as Node2D).global_position
	var chloe := Stage.chloe()
	return chloe.global_position + Vector2(0.0, -110.0) if chloe else Vector2.ZERO


## Her bench (the zone's « Etabli », else beside her).
static func _bench_px(at: Vector2) -> Vector2:
	return V.at_node(["Etabli"], V.spot_or("ETABLI", at + Vector2(-50.0, -10.0)))


## The great forge (the zone's « GrandeForge », else behind her).
static func _great_px(at: Vector2) -> Vector2:
	return V.at_node(["GrandeForge"], V.spot_or("GRANDE_FORGE", at + Vector2(40.0, -4.0 * S.CELL)))


## The iron wheel of its draught, at the forge's foot.
static func _wheel_px(at: Vector2) -> Vector2:
	return _great_px(at) + Vector2(-60.0, 70.0)


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): Dame Suie brought on beside Chloé (Brac beaten),
## the whole scene on any zone (the test picks « Trois, c'est que les tables sont fausses. »).
static func static_suie() -> void:
	S.playing += 1
	var chloe := Stage.chloe()
	Game.set_flag(&"brac_vaincu")
	var who := S.stranger("SuieVolcan", V.sheet(["dame_suie"]), S.ground_near(chloe.global_position + Vector2(0.0, -2.4 * S.CELL), 3), "down", SUIE)
	if who:
		await suie(who)
	S.playing -= 1
