class_name DesertAsk
## Chapter 4, the Désert Aride: the questions Chloé may ask there (« Une question… », like
## story/ask.gd): how to find the fossils, how to get through the fallen rocks, the
## sandstorms, calming the Carnotaurus, and, to Tante Sirocco, Hélène. Sirocco has her own menu
## (menu, sirocco_topics); Roc and Maïa get the chapter's questions through Ask.story_topics()
## (story_topics), answered by answer() (Ask.answer falls back on it).

const S := preload("res://story/story.gd")
const P := preload("res://story/desert_places.gd")
const TOPICS := {
	&"fossiles": "Comment trouver les fossiles ?",
	&"eboulis": "Comment passer les éboulis ?",
	&"tempete": "Et les tempêtes de sable ?",
	&"carnotaurus": "Comment apaiser le Carnotaurus ?",
	&"helene_desert": "Vous connaissiez Hélène ?",
}


## The question's words (Ask's topics or the Désert's).
static func label(topic: StringName) -> String:
	return Ask.TOPICS.get(topic, TOPICS.get(topic, String(topic)))


## Ask.menu, for the Désert's questions too: `prompt` said by `speaker`, then `action` (when
## given), the `topics`, « Au revoir ». True when Chloé picked the action.
static func menu(npc: StringName, speaker: String, prompt: String, topics: Array, action := "") -> bool:
	var asked := {}
	while true:
		var options: Array = []
		if action != "":
			options.append(action)
		var shown := topics.filter(func(t: StringName) -> bool: return not asked.has(t))
		for t: StringName in shown:
			options.append(label(t))
		options.append(Ask.GOODBYE)
		var pick := await Dialogue.choose(speaker, prompt, options)
		if action != "" and pick == 0:
			return true
		var i := pick - (1 if action != "" else 0)
		if i < 0 or i >= shown.size():
			return false
		var topic: StringName = shown[i]
		asked[topic] = true
		await S.say([{"who": "Chloé", "text": label(topic)}])
		var said := answer(npc, speaker, topic)
		await S.say(said if not said.is_empty() else Ask.answer(npc, speaker, topic))
		if asked.size() == topics.size() and action == "":
			return false
		prompt = Ask.AGAIN
	return false


## The Désert's questions of the moment, for Roc and Maïa (added to Ask.story_topics()).
static func story_topics() -> Array:
	var out: Array = []
	if Game.flag(&"sirocco_vue") and not Game.flag(&"fossiles_rendus") and P.fossils_found() < P.FOSSILS_WANTED:
		out.append(&"fossiles")
	if Game.flag(&"desert_arrivee") and not Game.flag(&"rempart_ouvert"):
		out.append(&"eboulis")
	if Game.flag(&"brac_desert_vu") and not Game.flag(&"brac_desert_battu"):
		out.append(&"tempete")
	if Game.flag(&"brac_desert_battu") and not Game.flag(&"sceau_desert"):
		out.append(&"carnotaurus")
	return out


## What Chloé may ask Tante Sirocco.
static func sirocco_topics() -> Array:
	var out: Array = []
	if Objectives.main_hint() != "":
		out.append(&"suite")
	if not Game.flag(&"fossiles_rendus"):
		out.append(&"fossiles")
	if not Game.flag(&"rempart_ouvert"):
		out.append(&"eboulis")
	if not Game.flag(&"sceau_desert"):
		out.append(&"tempete")
	if Game.flag(&"brac_desert_battu") and not Game.flag(&"sceau_desert"):
		out.append(&"carnotaurus")
	out.append(&"helene_desert")
	return out


## The answer to one of the Désert's questions, [] for any other (Ask answers those).
static func answer(npc: StringName, speaker: String, topic: StringName) -> Array:
	match topic:
		&"suite":
			if npc == &"sirocco":
				var hint := Objectives.main_hint()
				return [{"who": speaker, "text": "Mon gros orteil me dit… " + hint if hint != ""
					else "Rien ne presse, ma caille. Le Désert attend depuis soixante-six millions d'années : il attendra bien que tu boives un verre d'eau."}]
		&"fossiles":
			return [{"who": speaker, "text": _fossils(npc)}]
		&"eboulis":
			return [{"who": speaker, "text": _rocks(npc)}]
		&"tempete":
			return [{"who": speaker, "text": _storm(npc)}]
		&"carnotaurus":
			return [{"who": speaker, "text": _calm_carno(npc)}]
		&"helene_desert":
			return [
				{"who": speaker, "text": "Hélène ? Elle arrivait avec un chapeau trop grand et repartait sans : le vent adore les chapeaux. Elle disait « bonjour » aux squelettes, « pardon » aux dunes et « chut » au vent. Et le vent l'écoutait, en plus !"},
				{"who": speaker, "text": "Elle venait souvent avec son amie, la petite marin… Isaure. Pieds nus dans le sable brûlant, toujours à rire. Elles se disputaient la dernière datte, et c'est Isaure qui gagnait."},
				{"who": speaker, "text": "Et une fois, avec Anselme. Il a attrapé un coup de soleil sur le crâne en forme de fougère. Hélène a ri pendant trois jours. … Ça fait longtemps que je ne les ai pas vus rire ensemble, ces trois-là."},
			]
	return []


## How to find the fossils: a dino with Flair (in the party, at the Cabinet, or where to find one).
static func _fossils(npc: StringName) -> String:
	var nose := Game.ability_user(&"flair")
	if nose:
		match npc:
			&"sirocco":
				var hint := P.next_fossil_hint()
				var where := " Mon gros orteil me dit qu'il y en a un %s." % hint if hint != "" else ""
				return "Ton %s a le museau qu'il faut ! Promène-le dans le Cimetière : quand il sent de la terre remuée, il te la montre, et vous creusez.%s" % [nose.nickname, where]
			&"roc":
				return "Ton %s a du flair : il sentira la terre remuée, et il creusera. Rapporte-moi un fossile, un jour. Je… j'aimerais bien en voir un de près." % nose.nickname
		return "Ton %s ! Il renifle partout, non ? Laisse-le faire, et creuse là où il gratte. Caillou, lui, creuse partout. Il ne trouve jamais rien. Il est content quand même." % nose.nickname
	for d: Dino in Game.box:
		if Abilities.has(d, &"flair"):
			return "Ton %s a du flair, mais il attend au Cabinet. Le Pr Roc peut te l'échanger contre un dino de ton équipe." % d.nickname
	match npc:
		&"sirocco":
			return "Avec un nez, ma caille ! Les Oviraptors nichent dans les canyons et sortent le jour : curieux comme des pies, ils viendront te voir tout seuls. Un Compsognathus ferait l'affaire aussi, mais il te volerait tes lacets."
		&"roc":
			return "Il te faut un dino qui a du flair : un Compsognathus, un Troodon, ou un Oviraptor, dans les canyons du Désert. Hélène en avait toujours un dans sa poche. Littéralement."
	return "Un Oviraptor ! Ils fouillent les nids des canyons, le jour. Ils volent les œufs, les os, les lacets… Moustique en a peur."


## How to break the fallen rocks of the walled canyon: a dino with Charge.
static func _rocks(npc: StringName) -> String:
	var horn := Game.ability_user(&"charge")
	if horn:
		var soft := " Doucement quand même : derrière, il y a une vieille dame qui dort." if npc == &"sirocco" else ""
		return "Ton %s sait charger ! Un bon coup de tête dans les éboulis du canyon muré, et ça passera.%s" % [horn.nickname, soft]
	for d: Dino in Game.box:
		if Abilities.has(d, &"charge"):
			return "Ton %s attend au Cabinet : lui saurait charger. Le Pr Roc peut te l'échanger contre un dino de ton équipe." % d.nickname
	match npc:
		&"sirocco":
			return "Il te faut un dino qui charge. Les Pinacosaurus des dunes foncent sur tout ce qui bouge : les rochers, les palmiers, ma tente, moi. Un Tricératops ou un Protoceratops ferait l'affaire aussi."
		&"roc":
			return "Un dino qui charge : un Protoceratops, un Tricératops… ou un Pinacosaurus, dans les dunes du Désert. Des cuirassés têtus comme des mules. Ils me rappellent quelqu'un."
	return "Caillou ! … Ah non, Caillou est à moi. Trouve-toi un Pinacosaurus, dans les dunes. Ils chargent tout. Même le vent."


## The sandstorms: nothing to fear, stay close to the dinos.
static func _storm(npc: StringName) -> String:
	match npc:
		&"sirocco":
			return "Quand le ciel devient jaune, la tempête arrive. On n'y voit plus grand-chose, mais elle ne te mangera pas : reste près de tes dinos, avance doucement, et fais confiance à leur nez. Elle finit toujours par passer. Comme les soucis."
		&"roc":
			return "Une tempête de sable ? Couvre-toi la bouche, suis ton dino, et ne cherche pas à courir. Hélène en a traversé des dizaines. Elle revenait avec du sable dans les oreilles pour une semaine."
	return "La tempête ? C'est GÉNIAL. On ne voit rien, on a du sable partout, et Caillou éternue toutes les dix secondes. Atchoum : une dune de moins."


## Calming the Carnotaurus Rouge: heal first, calm, her own hatchling in front.
static func _calm_carno(npc: StringName) -> String:
	var mine: Dino = Foret.starter()
	var help := ""
	if mine and Game.party.has(mine):
		help = " Mets %s devant : il a confiance en toi, et le Carnotaurus le sentira." % mine.nickname
	if npc == &"roc":
		return "« Rester plus longtemps que sa peur », disait Hélène. Soigne ton équipe, puis choisis « Apaiser » et ne tape plus : chaque coup l'affole. Il est bien plus fort que le chef de la meute. Il faudra du temps. Tu en as." + help
	return "Il n'est pas méchant, ma caille : il a peur. Peur de l'ambre noir qu'on lui a fait avaler. Soigne d'abord tes dinos, puis choisis « Apaiser », et ne tape plus." + help + " Et reste. Plus longtemps que sa peur."
