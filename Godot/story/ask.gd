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
}
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
			options.append(TOPICS[t])
		options.append(GOODBYE)
		var pick := await Dialogue.choose(speaker, prompt, options)
		if action != "" and pick == 0:
			return true
		var i := pick - (1 if action != "" else 0)
		if i < 0 or i >= shown.size():
			return false
		var topic: StringName = shown[i]
		asked[topic] = true
		await S.say([{"who": "Chloé", "text": TOPICS[topic]}])
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
	return []


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
