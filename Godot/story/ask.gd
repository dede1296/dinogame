class_name Ask
## « Une question… » : after a character's line, Chloé can ask them what a player wonders
## about (how to earn coins, get a saddle, which dino can carry her). The answers follow the
## story: each character knows its part (Ferréol buys amber, Pervenche berries…), and the
## saddle's answer is the next step Chloé really has to take.

const S := preload("res://story/story.gd")
const TOPICS := {
	&"pieces": "Comment gagner des pièces ?",
	&"selle": "Comment avoir une selle ?",
	&"monter": "Quel dino peut me porter ?",
	# The questions the story raises (story_topics), from chapter 2 on.
	&"suite": "Où dois-je aller ?",
	&"mur": "Comment passer le mur fissuré ?",
	&"apaiser": "Comment apaiser un dino ?",
	&"masque": "Qui est le Masque ?",
	# Chapter 3, the Marais Brumeux.
	&"nage": "Comment nager dans le Marais ?",
	&"chanter": "Comment ouvrir la porte d'ambre ?",
	&"voix": "Qui est la Voix du Marais ?",
	&"temple": "Qu'y a-t-il dans le temple englouti ?",
	&"suie": "Qui est la dame en gris ?",
	&"roc_nuit": "Où va Roc, la nuit ?",
}
## The same question, asked to someone else in other words (npc -> topic -> words).
const TOPICS_FOR := {&"roc": {&"roc_nuit": "Où allez-vous, la nuit ?"}}
const GOODBYE := "Au revoir"
const AGAIN := "Autre chose ?"


## `prompt` said by `speaker`, then a menu: `action` first when given (« Voir la boutique »),
## the `topics` (TOPICS keys), « Au revoir ». Chloé may ask several questions in a row.
## Returns true when she picked the action.
static func menu(npc: StringName, speaker: String, prompt: String, topics: Array, action := "") -> bool:
	var asked := {}
	while true:
		var options: Array = []
		if action != "":
			options.append(action)
		var shown := topics.filter(func(t: StringName) -> bool: return not asked.has(t))
		for t: StringName in shown:
			options.append(label(npc, t))
		options.append(GOODBYE)
		var pick := await Dialogue.choose(speaker, prompt, options)
		if action != "" and pick == 0:
			return true
		var i := pick - (1 if action != "" else 0)
		if i < 0 or i >= shown.size():
			return false
		var topic: StringName = shown[i]
		asked[topic] = true
		await S.say([{"who": "Chloé", "text": label(npc, topic)}])
		await S.say(answer(npc, speaker, topic))
		if asked.size() == topics.size() and action == "":
			return false
		prompt = AGAIN
	return false


static func answer(npc: StringName, speaker: String, topic: StringName) -> Array:
	match topic:
		&"pieces":
			return [{"who": speaker, "text": _coins(npc)}]
		&"selle":
			var lead := "Pas chez moi ! Les selles, c'est Joss, le sellier. " if npc == &"rosalie" else ""
			return [{"who": speaker, "text": lead + saddle_step()}]
		&"monter":
			return [{"who": speaker, "text": "Seul un grand dino adulte (niveau %d) peut porter quelqu'un : un Tricératops, un Parasaurolophus, un Ankylosaurus, un Iguanodon… Pas un raptor, ni un petit. " % Abilities.ADULT_LEVEL + _party_mount()}]
		&"suite":
			return [{"who": speaker, "text": _next_step(npc)}]
		&"mur":
			return [{"who": speaker, "text": _cracked_wall(npc)}]
		&"apaiser":
			return [{"who": speaker, "text": _calming(npc)}]
		&"masque":
			return [{"who": speaker, "text": _the_mask(npc)}]
		&"nage":
			return [{"who": speaker, "text": _swim(npc)}]
		&"chanter":
			return [{"who": speaker, "text": _sing(npc)}]
		&"voix":
			return [{"who": speaker, "text": _voice(npc)}]
		&"temple":
			return [{"who": speaker, "text": _temple(npc)}]
		&"suie":
			return [{"who": speaker, "text": _lady(npc)}]
		&"roc_nuit":
			return [{"who": speaker, "text": _roc_night(npc)}]
	return DesertAsk.answer(npc, speaker, topic)   # chapter 4 (story/desert_ask.gd)


## A question in Chloé's words, for npc (she does not ask Roc where Roc goes).
static func label(npc: StringName, topic: StringName) -> String:
	return TOPICS_FOR.get(npc, {}).get(topic, TOPICS.get(topic, DesertAsk.TOPICS.get(topic, CoteAsk.TOPICS.get(topic, String(topic)))))


## The questions of the moment (chapter 2 on): where to go, the cracked wall, calming the
## pack's leader, the Masque. For Roc and Maïa (story.gd), after their own topics.
static func story_topics() -> Array:
	var out: Array = []
	if not Game.flag(&"selle"):
		return out
	if Objectives.main_hint() != "":
		out.append(&"suite")
	if Game.flag(&"clairiere_vue") and not Game.flag(&"mur_camp_brise"):
		out.append(&"mur")
	if Game.flag(&"camp_arrive") and not Game.flag(&"sceau_foret"):
		out.append(&"apaiser")
	if Game.flag(&"clairiere_vue") and not Game.flag(&"marais_arrivee"):
		out.append(&"masque")
	# Chapter 3: only what is useful now (the menu has room for a few questions).
	if Game.flag(&"marais_arrivee"):
		if Marais.swim_step() != "":
			out.append(&"nage")
		elif not Game.flag(&"porte_voix_ouverte") and Marais.sing_step() != "":
			out.append(&"chanter")
		if not Game.flag(&"voix_rencontree"):
			out.append(&"voix")
		if Game.flag(&"temple_ouvert") and not Game.flag(&"sceau_marais"):
			out.append(&"temple")
		if Game.flag(&"gilet_nage") and not Game.flag(&"dame_suie_battue"):
			out.append(&"suie")
	if Game.flag(&"roc_marais_vu"):
		out.append(&"roc_nuit")
	# Chapter 4, the Désert Aride: the fossils, the fallen rocks, the storm, the Carnotaurus.
	if Game.flag(&"desert_arrivee"):
		out.append_array(DesertAsk.story_topics())
	# Chapter 5, the Côte: diving, the boat without a lantern, the reef, its guardian.
	if Game.flag(&"cote_arrivee"):
		out.append_array(CoteAsk.story_topics())
	return out


## The main objective, in the speaker's words.
static func _next_step(npc: StringName) -> String:
	var hint := Objectives.main_hint()
	if hint == "":
		return "Pour l'instant ? Rien ne presse. Explore, attrape, repose-toi."
	match npc:
		&"roc":
			return "Hmm. Si j'étais toi… " + hint
		&"maia":
			return "Conseil de championne : " + hint
		&"joss":
			return "Si j'ai bien compris… " + hint
	return hint


## How to get through the cracked wall: a dome-headed dino (Coup de crâne).
static func _cracked_wall(npc: StringName) -> String:
	var dome := Game.ability_user(&"coup_crane")
	if dome:
		return "Ton %s a le crâne qu'il faut ! Un bon coup de tête contre la fissure, et le mur cédera." % dome.nickname
	for d: Dino in Game.box:
		if Abilities.has(d, &"coup_crane"):
			return "Ton %s attend au Cabinet : c'est lui qu'il te faut. Le Pr Roc peut l'échanger contre un dino de ton équipe." % d.nickname
	if npc == &"roc":
		return "Un mur fissuré ? Il te faut un crâne en dôme : un Pachycephalosaurus. Ils vivent dans les clairières rocheuses, au nord-est de la Forêt, et ne sortent que le jour. Hélène disait qu'ils se disent bonjour à coups de tête. Je n'ai jamais essayé."
	return "Un Pachycephalosaurus ! Aux clairières rocheuses, au nord-est de la Forêt, le jour. Ils se cognent la tête toute la journée. Caillou a essayé une fois. Une seule."


## Calming a corrupted dino (the camp: the champion, the pack's leader).
static func _calming(npc: StringName) -> String:
	if npc == &"roc":
		return "Au combat, choisis « Apaiser » au lieu d'attaquer. Plus il est fatigué, plus il écoute ; un dino de sa famille le rassure ; et plus ton dino a de cœurs de Lien, mieux ça marche. Mais chaque coup l'affole à nouveau. Hélène disait : il faut rester plus longtemps que sa peur."
	return "Moi, d'habitude, j'attaque. Mais Hélène disait à maman qu'il faut « Apaiser » : parler doucement, ne plus taper, et avoir un dino qui a confiance en toi. Plus il a de cœurs, mieux c'est."


## The Masque: nobody knows (Roc knows more than he says).
static func _the_mask(npc: StringName) -> String:
	if npc == &"roc":
		if Game.flag(&"masque_vu"):
			return "Un masque d'obsidienne… Du verre de volcan. On en trouve sur les plages noires, au nord. On n'y va qu'en bateau. … Je n'en sais pas plus. Vraiment."
		return "Le chef de l'Ombre Noire ? Personne ne l'a jamais vu sans son masque. Et si je savais… Non. Je ne sais pas."
	if Game.flag(&"masque_vu"):
		return "Personne ne sait ! C'est ça qui est stylé. Tu crois qu'il a un nom normal, sous son masque ? Genre… Gérard ?"
	return "Le chef de l'Ombre Noire. Il paraît que son masque est tout noir, et qu'il ne parle jamais fort. Trop stylé. Enfin, trop méchant. Mais stylé."


## La Nage: what Chloé still needs (the vest, a grown swimmer), or how it works.
static func _swim(npc: StringName) -> String:
	var step := Marais.swim_step()
	if step == "":
		step = "Tu as tout ce qu'il faut : avance dans l'eau profonde, et ton nageur te prendra sur son dos. Pour ressortir, nage jusqu'à la rive."
	match npc:
		&"joss":
			return "Mes gilets, c'est ma spécialité ! " + step
		&"roc":
			return "Hmm. Hélène traversait le Marais sur le dos d'un Baryonyx, avec un gilet de liège. " + step
		&"maia":
			return "Moi, je nage comme une enclume. Mais bon : " + step
	return step


## The amber door of the Voix's islet (Résonance).
static func _sing(npc: StringName) -> String:
	var step := Marais.sing_step()
	if step == "":
		var singer: Dino = Game.ability_user(&"resonance")
		step = "Approche ton %s de la porte d'ambre : sa crête fera le reste." % singer.nickname if singer else "Une crête qui chante, et la porte s'ouvre."
	if npc == &"roc":
		return "Hélène disait que l'ambre écoute les crêtes. " + step
	return step


## The Voix du Marais: Hélène's old Parasaurolophus (Écho's mother).
static func _voice(npc: StringName) -> String:
	var echo: Dino = Marais.echo_dino()
	match npc:
		&"roc":
			var mother := " C'est la mère %s, tu sais." % French.de(echo.nickname) if echo else ""
			return "La vieille Parasaurolophus d'Hélène. Elle a chanté avant même d'ouvrir les yeux : j'en ai lâché trois flacons. Elle vit au cœur de la roselière, derrière une porte d'ambre." + mother
		&"joss":
			return "Je l'entends chanter depuis ma cabane, le soir : mes aiguilles vibrent dans leur boîte. Elle vit au cœur de la roselière, sur un îlot, derrière une porte d'ambre."
	return "Maman dit qu'elle chante le soir, dans la brume, et qu'on l'entendait jusqu'au port, autrefois. Maman sait plein de choses sur Hélène. Trop, des fois."


## The sunken temple.
static func _temple(npc: StringName) -> String:
	match npc:
		&"roc":
			return "Le temple englouti… Hélène y descendait avec une bougie et un carnet. L'eau passe d'une galerie à l'autre par des vannes : tourne-les dans l'ordre, et le temple s'assèche. Moi, j'y ai perdu une chaussure."
		&"joss":
			return "Personne n'y entrait. Mais les soirs de brume, on voit de la lumière derrière les fenêtres noyées. Moi, je reste dans ma cabane."
	return "Un temple SOUS L'EAU ?! Il y a sûrement un trésor. Ou un monstre. Ou un monstre qui garde un trésor. J'espère les deux."


## The lady in grey who picks roots on the islet (Dame Suie).
static func _lady(npc: StringName) -> String:
	match npc:
		&"roc":
			return "Une dame en gris qui cueille des racines ? Je ne connais pas de dame en gris. Mais si elle sent la cendre, reste loin d'elle, Chloé. Ou alors, emmène tous tes dinos."
		&"joss":
			return "Très polie. Des gants gris, une voilette, des petits ciseaux d'argent. Elle vient en barque cueillir des racines sur l'îlot aux racines. On n'y va qu'à la nage."
	return "Une dame en gris avec une voilette ? Brr. On dirait une maîtresse d'école qui ne rit jamais."


## Roc's nights out (after Chloé confronted him).
static func _roc_night(npc: StringName) -> String:
	match npc:
		&"roc":
			return "Je te l'ai dit : je ne peux pas. Pas encore. … Fais-moi confiance, Chloé. S'il te plaît."
		&"joss":
			return "Le professeur ? Je l'ai vu passer une nuit, avec sa lanterne, vers le nord. Il m'a dit bonsoir très poliment, puis il est tombé dans la vase. Il m'a redit bonsoir, moins poliment."
	return "Roc ? Il cherche des escargots de nuit, je parie. Il est bizarre, pas méchant. Je te l'ai déjà dit, non ?"


## Where to earn coins, as each one sees it.
static func _coins(npc: StringName) -> String:
	var tear := ItemsDB.TEAR_PRICE
	var berry: int = ItemsDB.item("baie")["sell"]
	match npc:
		&"maia":
			return "Au Relais ! Gaspard et Lilou paient une prime la première fois qu'on les bat, puis ils acceptent une revanche par jour. Et le Comptoir rachète tes larmes d'ambre… mais Roc les voudrait aussi, hein."
		&"joss":
			return "Moi, mes premières pièces, je les ai gagnées au Relais : Gaspard paie bien, et il perd souvent. Sinon, Mémé Pervenche rachète les baies, et Ferréol rachète tout le reste."
		&"ferreol":
			return "Rien de plus simple : apportez-moi les larmes de l'île, ces galets d'ambre cachés partout. %d pièces chacune. Je reprends aussi les objets dont vous n'avez plus l'usage." % tear
		&"pervenche":
			return "Des baies, ma grande. Secoue les arbres des Plaines, un par jour, et apporte-les-moi : je te les reprends %d pièces. Et les dresseurs du Relais paient mieux que moi, les chenapans." % berry
		&"rosalie":
			return "Revends ce qui ne te sert plus : un collier en trop, je te le reprends. Et le Relais paie les bons dresseurs, à ce qu'on dit."
		&"marchande":
			return "Si j'avais le secret, je ne vendrais pas des pommes ! Les dresseurs du Relais s'en sortent bien, eux. Et Ferréol paie l'ambre à prix d'or."
	return "Le Relais des Dresseurs paie les victoires, et le Comptoir rachète l'ambre."


## The next thing Chloé must do for her saddle (the same steps as the quest helper).
static func saddle_step() -> String:
	if Game.flag(&"selle"):
		return "Mais tu en as déjà une ! Touche le bouton selle, avec un grand dino adulte dans ton équipe."
	if not Game.flag(&"selle_demandee"):
		return "Va voir Joss, le sellier : la grande maison à l'est de la rue, avec l'ancre sur l'enseigne."
	var todo: Array[String] = []
	if Game.item_count("cuir") == 0:
		todo.append("du cuir mué de Parasaurolophus (au bord de l'étang des Plaines)")
	if Game.item_count("boucle") == 0:
		todo.append("une boucle d'ambre (au Comptoir de Ferréol)")
	if Game.coins() < Havre.SADDLE_PRICE:
		todo.append("%d pièces pour son travail (tu en as %d)" % [Havre.SADDLE_PRICE, Game.coins()])
	if todo.is_empty():
		return "Tu as tout ce qu'il faut ! Cours voir Joss."
	return "Pour ta selle, Joss attend encore " + (", ".join(todo.slice(0, -1)) + " et " if todo.size() > 1 else "") + todo[-1] + "."


## Which dino of Chloé's party could carry her, or where to find one.
static func _party_mount() -> String:
	var ready := Game.ability_user(&"monture")
	if ready:
		return "Ton %s est assez grand : il peut te porter." % ready.nickname
	for d in Game.party:
		if Abilities.has(d, &"monture"):
			return "Ton %s pourra, une fois adulte : encore %d niveaux." % [d.nickname, Abilities.ADULT_LEVEL - d.level]
	return "Dans ton équipe, aucun ne le pourra. Des Parasaurolophus vivent au bord de l'étang des Plaines, et un Ankylosaurus rôde autour du Grand Crâne, la nuit."
