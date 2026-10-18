class_name VolcanSuie
## Chapter 8, the Plaine Volcanique, Dame Suie at the foot of the great forge (zone forges_ombre;
## docs/chapitre-8-scenes.md, scene 6): she watched it all and took notes (« Le sujet 12 a…
## réfléchi »); the captain took one vial at dawn and told her to put the forge out; she did not:
## she was watching the little one, « la fille du Masque », without a drop and without fear.
## Belladone, the sleepers, Maïa: three times, the tables are wrong. She takes off her gloves,
## turns the wheel: the great forge goes out « comme une lampe qu'on baisse »; her smoked glasses
## put away for good. The Ambre clair (one dose), then Hélène's letter « Pour Isaure » (page 37),
## kept a year unopened. She leaves with Mandragore and Hélène's notebooks, for the Cabinet; her
## gloves stay on the bench. Cold, curious, not cruel: she never says sorry (« je refais mes
## tables »); Chloé says five sentences; « Maïa » is said by Chloé only. No battle.
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


## Scene 6, Dame Suie (Npc « SuieVolcan », event « suie_volcan », hide_flag suie_partie): once
## Brac has lost, the whole scene in a row, each part resumed where it stopped (its flag).
static func suie(who: Node) -> void:
	if Game.flag(&"suie_partie"):
		return
	if not Game.flag(&"brac_vaincu"):
		await S.say([{"who": SUIE, "text": "Finissez d'abord avec Brac, mademoiselle. Il a besoin de perdre une dernière fois : ça lui fera du bien, et j'ai besoin de le noter."}])
		return
	S.lock(true)
	var cast := {"suie": who}
	if not Game.flag(&"suie_volcan_vue"):
		await S.say(_took_your_time(who))
		await S.say(_three_times(who, cast))
	if not Game.flag(&"grande_forge_eteinte"):
		await S.say(_goes_out(who, cast))
	if not Game.flag(&"antidote_ambre"):
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
	await S.say(_leaves(who, cast))
	Audio.duck(0.0, 2.5)
	CS.lead_back()
	Stage.look_back()
	Game.award_team_xp(XP_SUIE)
	Save.save_game()
	S.lock(false)


## 6 a, « Vous avez pris votre temps »: she finishes her line; the captain at dawn, one vial;
## she did not put it out: she watched the little one. No line for that in her tables.
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
		CS.cue({"who": SUIE, "text": "Mademoiselle Varenne. Vous avez pris votre temps."}, writes),
		{"who": SUIE, "text": "Trois forges, une barricade, et Brac. Je vous ai regardée depuis le début. J'ai pris des notes. Vous permettez que je finisse ma ligne ?"},
		CS.cue({"text": "Elle finit sa ligne. Elle pose la plume."}, pen),
		{"who": SUIE, "text": "Voilà. « Le sujet 7 a renversé sa propre forge. Le sujet 11 a arraché le soufflet. Le sujet 12 a… » Je ne sais pas comment écrire ce qu'a fait le 12. « A réfléchi », je crois. Ce n'est pas un mot de mes tables."},
		{"who": CHLOE, "text": "Vous n'avez rien fait pour les empêcher."},
		{"who": SUIE, "text": "Non. J'observais. C'est mon métier, mademoiselle : Brac chasse, le Masque veut, et moi j'observe. Et depuis ce matin, j'observe surtout que je n'ai plus de Masque."},
		CS.cue({"who": SUIE, "text": "Elle est passée à l'aube. La capitaine. Elle m'a pris une fiole : une seule, la plus pure, celle que je gardais pour… pour rien. Pour savoir si je pouvais. Elle a dit : « Vous pouvez éteindre, Dame Suie. Je n'ai plus besoin que d'une goutte. »"}, turns),
		CS.cue({"who": SUIE, "text": "Je n'ai pas éteint. Je voulais voir si elle reviendrait la chercher. Ce n'est pas la fiole que je regardais partir, mademoiselle. C'est la petite."}, eyes),
		{"who": CHLOE, "text": "Maïa."},
		{"who": SUIE, "text": "La fille du Masque. À côté de sa mère. Pas derrière : à côté. Elle avait des cendres jusqu'aux genoux, un manteau trop grand, et elle disait bonjour aux sbires. Un par un. Elle a dit bonjour à Brac."},
		{"who": SUIE, "text": "J'ai regardé ses yeux quand elle est passée devant la forge. Je regarde toujours les yeux : c'est là que l'ambre noir se voit en premier. Pas une goutte. Et pas peur."},
		{"who": SUIE, "text": "J'ai cherché dans mes tables à quoi ça correspondait. Une enfant qui marche vers un volcan, à côté de quelqu'un qui lui a menti pendant un an, sans une goutte, et sans peur."},
		{"who": SUIE, "text": "Il n'y a pas de ligne pour ça. J'ai regardé deux fois."},
		{"flag": &"suie_volcan_vue"},
	]


## 6 b, Belladone, the sleepers, and Maïa: three times. Her gloves off, one finger after the
## other, laid on the bench (at the Monts, her glasses; here, the gloves: she is going to touch
## something). She goes to the iron wheel of the great forge's draught.
static func _three_times(who: Node, cast: Dictionary) -> Array:
	var at: Vector2 = _px(who)
	var bench := _bench_px(at)
	var wheel := _wheel_px(at)
	var gloves := func() -> void:
		Stage.turn_to(who, bench)
		for i in 5:
			CS.reach(who, at + Vector2(0.0, -10.0), 3.0, 0.3)
			await S.wait(0.35)
		await CS.reach(who, bench, 8.0, 0.8)
		var g := Stage.show_thing("gants_gris", V.spot_or("GANTS", bench + Vector2(-20.0, 8.0)), "GantsSuieScene")
		cast["gloves"] = g
	var walks := func() -> void:
		if who is Npc:
			await (who as Npc).walk_to(S.ground_near(wheel, 2), "", 60.0)
			(who as Npc).face(wheel)
		Stage.look_at(wheel.lerp(Stage.chloe().global_position, 0.4), 1.0)
	return [
		CS.cue({"who": SUIE, "text": "Je vais vous dire où j'en suis, mademoiselle Varenne, parce que vous êtes la seule personne de cette île à qui ça puisse servir."}, gloves),
		{"who": SUIE, "text": "Au Marais, vous avez calmé Belladone sans une goutte. J'ai noté : « exception ». Aux Monts, les dormeurs de votre grand-mère étaient parfaits sans une goutte. J'ai noté : « à vérifier ». Ce matin, la fille du Masque. Je n'ai rien noté. Je n'avais plus de colonne."},
		{"who": SUIE, "text": "Une exception, c'est une exception. Deux, c'est une erreur de mesure. Trois…"},
		{"who": CHLOE, "text": "Trois, c'est que les tables sont fausses."},
		{"who": SUIE, "text": "… Vous avez les yeux de votre grand-mère. Ils finissent mes phrases avant moi."},
		{"who": SUIE, "text": "Trois, c'est que le dosage n'a jamais été la question. « La peur n'est qu'un problème de dosage. » Je l'ai écrit en tête de chaque carnet pendant douze ans. Il manquait un mot. La peur n'est pas un problème de dosage : c'est un problème. Point."},
		CS.cue({"who": SUIE, "text": "Brac donnait l'ambre noir à la pelle. Je le lui ai assez reproché. Mais une pelle ou une pipette, mademoiselle, ça reste de l'ambre noir, et j'ai mis douze ans à le mesurer."}, walks),
	]


## 6 c, the great forge goes out: the wheel grinds, the red goes down like a lamp blown out
## slowly, the violet smoke whitens and stops; silence, the first in twelve years; Mandragore
## lifts its head, surprised, and lays it down. Her smoked glasses in her pocket, for good.
static func _goes_out(who: Node, cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = _px(who)
	var great := _great_px(at)
	var forge = V.actor_of(["GrandeForge"])
	var turns := func() -> void:
		await CS.reach(who, _wheel_px(at), 8.0, 1.0)
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
	var glasses := func() -> void:
		Stage.look_back(0.8)
		if who is Npc:
			(who as Npc).face(chloe.global_position)
		await CS.reach(who, at + Vector2(0.0, -30.0), 5.0, 0.8)
		Stage.dress(who, NO_GLASSES)
	return [
		CS.cue({"text": "La grande forge s'éteint. Pas d'un coup : comme une lampe qu'on baisse. Le rouge devient rose, puis gris. La fumée blanchit. Et puis, plus rien. Le silence. Le vrai : on entend le vent, et Moustique qui respire."}, turns),
		{"who": SUIE, "text": "Voilà. Douze ans. Ça fait moins de bruit que je pensais."},
		CS.cue({"who": SUIE, "text": "Elles étaient contre la lueur. Il n'y a plus de lueur."}, glasses),
		{"who": CHLOE, "text": "(Elle a des yeux gris. Je ne les avais jamais vus. Ils ont l'air… fatigués. Et curieux.)"},
		{"flag": &"grande_forge_eteinte"},
	]


## 6 d, the antidote: a small wooden box on the bench, a vial of clear amber, warm. One dose.
static func _antidote(who: Node) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = _px(who)
	var bench := _bench_px(at)
	var box := func() -> void:
		if who is Npc:
			await (who as Npc).walk_to(S.ground_near(bench + Vector2(0.0, 40.0), 2), "", 60.0)
			(who as Npc).face(bench)
		await CS.reach(who, bench, 8.0, 0.8)
		CS.pulse(bench, Color(1.0, 0.85, 0.45), 2, 1.2, 1.8, 2.5)
	var gives := func() -> void:
		if who is Npc:
			(who as Npc).face(chloe.global_position)
		await CS.reach(who, chloe.global_position, 14.0, 1.0)
		if ItemsDB.ITEMS.has(ANTIDOTE):
			CS.Act.pop(chloe.global_position, ANTIDOTE, 0.9)
		Stage.glow(chloe, Color(1.5, 1.3, 0.8), 1, 1.0)
	return [
		CS.cue({"text": "Elle ouvre un petit coffret de bois, sur l'établi, et en sort une fiole : de l'ambre liquide, clair, presque doré, qui luit un peu dans le gris. Étiquette fine : « Ambre clair. Une goutte. Pas une de plus. — S. »"}, box),
		{"who": SUIE, "text": "On ne fabrique pas un poison sans fabriquer son contraire. C'est la première règle. Brac ne l'a jamais apprise ; je l'ai apprise avant d'avoir des gants."},
		{"who": SUIE, "text": "Je l'ai mis au point la nuit, aux Monts, après Aconit. Je me disais : par prudence. Je me mentais : c'était par curiosité. Je voulais savoir si ça se défaisait."},
		{"who": CHLOE, "text": "Et ça se défait ?"},
		{"who": SUIE, "text": "Une goutte sur un dino corrompu, et les veines s'effacent. D'un coup. Sans parler, sans Lien, sans rien : de la chimie. Vous n'en aurez pas besoin pour les corrompus d'ici : vous faites mieux que moi, et plus lentement."},
		{"who": SUIE, "text": "Mais la capitaine a une fiole. La plus pure. Et elle va s'en servir sur quelque chose de très grand, qui dort. Ce jour-là, mademoiselle, vous n'aurez pas le temps de parler."},
		CS.cue({"text": "Elle tend la fiole. Chloé la prend. Elle est tiède."}, gives),
		{"who": SUIE, "text": "Une dose. Je n'ai pas eu le temps d'en faire deux : la nuit est courte, au pied d'une forge. Choisissez votre moment."},
		{"who": CHLOE, "text": "Pourquoi vous me la donnez ?"},
		{"who": SUIE, "text": "Parce que je refais mes tables, et que la première ligne de la nouvelle, c'est vous."},
		{"flag": &"suie_alliee"},
		{"flag": &"antidote_ambre"},
	]


## 6 e, the letter: she hesitates (it is rare); the drawer of the bench, a thick envelope folded in
## two, « Pour Isaure ». Hélène put it on her bench a year ago, one night. Not sealed: folded.
## Chloé reads it (page 37), and will take it to Isaure.
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
		{"who": SUIE, "text": "Votre grand-mère est venue ici. Il y a un an. Une nuit. Personne ne l'a vue ; moi, je l'ai vue, parce que je ne dors pas beaucoup. Elle a traversé le camp comme on traverse sa cuisine, elle a posé ça sur mon établi, à côté de mes fioles, elle m'a regardée, et elle est repartie vers les coulées."},
		{"who": CHLOE, "text": "Elle vous a regardée ?"},
		{"who": SUIE, "text": "Comme on regarde une élève qui a bien travaillé sur un mauvais sujet. … Je n'ai pas aimé. J'y repense souvent."},
		{"who": SUIE, "text": "Je ne lis pas le courrier des autres, mademoiselle. J'ai des défauts ; pas celui-là. Je l'ai gardée pour la lui donner. Elle est passée ce matin, et je ne l'ai pas fait."},
		{"who": CHLOE, "text": "Pourquoi ?"},
		{"who": SUIE, "text": "Parce que si elle l'avait lue, elle ne serait peut-être pas montée. Et je voulais voir ce qui se passe quand on monte. … Troisième faute. Je vous la laisse corriger : vous allez là où elle va."},
		CS.cue({"text": "Chloé prend l'enveloppe. Elle n'est pas scellée : juste pliée. Hélène écrivait tout, et ne cachetait rien."}, takes),
		{"who": CHLOE, "text": "(Pliée, pas fermée. Elle voulait qu'on la lise. Elle voulait que quelqu'un la lise, si Isaure ne venait pas.)"},
		{"who": CHLOE, "text": "(… Je la lis. Et je la lui porte.)"},
	]
	lines.append_array(DialogueVolcan.page_37(false))
	return lines


## 6 f, she goes: her notebook put away, not her gloves; Mandragore harnessed to the sled on
## wheels, full of Hélène's notebooks, for the Cabinet; the lava flows are that way (« le cuir
## pour »); « Merci » — the second today; « Nous nous reverrons. Là où il fait bon, cette fois. »
static func _leaves(who: Node, cast: Dictionary) -> Array:
	var chloe := Stage.chloe()
	var at: Vector2 = _px(who)
	var coulees := V.spot_or("SORTIE_COULEES", at + Vector2(8.0 * S.CELL, 0.0))
	var away := V.spot_or("ENTREE_FORGES", at + Vector2(0.0, 12.0 * S.CELL))
	var mandragore = V.actor_of(["Mandragore"])
	var sled = V.actor_of(["TraineauSuie", "Traineau"])
	var crates := func() -> void:
		if mandragore is Node2D:
			Stage.look_at((mandragore as Node2D).global_position, 1.0)
			Stage.hop(mandragore, 1, 4.0)
		if who is Npc:
			(who as Npc).face(chloe.global_position)
	var points := func() -> void:
		if who is Npc:
			CS.reach(who, coulees, 10.0, 1.2)
		Stage.look_at(coulees, 1.0)
	var back := func() -> void:
		Stage.look_back(0.6)
	var step := func() -> void:
		if who is Npc:
			var dir: Vector2 = (away - at).normalized() if away.distance_to(at) > 1.0 else Vector2(0.0, 1.0)
			await (who as Npc).walk_to(S.ground_near(at + dir * S.CELL, 2), "", 50.0)
	var goes := func() -> void:
		var walkers: Array = [who, mandragore, sled]
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
	return [
		CS.cue({"who": SUIE, "text": "Les carnets de votre grand-mère. Ceux de l'ambre forcé, ceux qu'on m'a donnés il y a douze ans « pour travailler ». J'ai travaillé. Je les rends."}, crates),
		{"who": CHLOE, "text": "À qui ?"},
		{"who": SUIE, "text": "Au Cabinet. À votre professeur Roc, qui a une clé, du thé, et une couveuse qu'il regarde comme si elle allait lui répondre. Je lui dirai que je refais mes tables. Il ne comprendra pas. Il fera du thé."},
		CS.cue({"who": SUIE, "text": "Les coulées sont par là, mademoiselle. Pour les franchir, il vous faut un dino qui a le cuir pour : de la pierre, ou du feu. Brac en avait un. Il l'a laissé choisir. C'est la première chose intelligente qu'il ait faite depuis que je le connais, et il ne le sait pas."}, points),
		CS.cue({"who": CHLOE, "text": "Dame Suie."}, back),
		{"who": SUIE, "text": "Mademoiselle ?"},
		{"who": CHLOE, "text": "Merci."},
		{"who": SUIE, "text": "… C'est la deuxième fois aujourd'hui qu'on me dit ça dans ce camp. La première, c'était la petite Kerval, pour un sbire qui lui avait tenu une cage ouverte. Je commence à croire que c'est contagieux."},
		CS.cue({"text": "Elle fait un pas, et s'arrête."}, step),
		{"who": SUIE, "text": "Nous nous reverrons. Là où il fait bon, cette fois. J'aimerais bien."},
		CS.cue({"text": "Le traîneau s'éloigne vers les champs, Mandragore au trot. Elle ne se retourne pas. Sur l'établi, ses gants gris perle, côte à côte."}, goes),
		{"who": CHLOE, "text": "(Froide, curieuse, pas cruelle. Elle n'a pas changé. Elle a seulement compté jusqu'à trois.)"},
		{"flag": &"suie_partie"},
	]


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
	return V.at_node(["RoueTirage"], _great_px(at) + Vector2(-60.0, 70.0))


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): Dame Suie brought on beside Chloé (Brac beaten),
## the whole scene on any zone.
static func static_suie() -> void:
	S.playing += 1
	var chloe := Stage.chloe()
	Game.set_flag(&"brac_vaincu")
	var who := S.stranger("SuieVolcan", V.sheet(["dame_suie"]), S.ground_near(chloe.global_position + Vector2(0.0, -2.4 * S.CELL), 3), "down", SUIE)
	if who:
		await suie(who)
	S.playing -= 1
