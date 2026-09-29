class_name CoteAsk
## Chapter 5, the Côte Préhistorique: the questions Chloé may ask there (« Une question… », like
## story/ask.gd): how to dive, the boat without a lantern, what is under the cliffs, how to get
## through the reef, who guards it, the turtles' nests, Hélène. Gustave and Joss have their own
## lists (pecheurs_topics, joss_topics); Roc and Maïa get the chapter's questions through
## Ask.story_topics() (story_topics), answered by answer() (Ask.answer falls back on it).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const TOPICS := {
	&"plongee": "Comment plonger ?",
	&"barque_nuit": "Et la barque sans lanterne ?",
	&"grottes": "Qu'y a-t-il sous les falaises ?",
	&"recif": "Comment passer le récif ?",
	&"mosasaure": "Qui garde le récif ?",
	&"tortues": "Et les nids de tortues ?",
	&"helene_cote": "Vous connaissiez Hélène ?",
}
const TIP := " (Les attaques du Vent le touchent fort.)"


## The question's words (Ask's, the Désert's or the Côte's).
static func label(npc: StringName, topic: StringName) -> String:
	if TOPICS.has(topic):
		return TOPICS[topic]
	return Ask.label(npc, topic)


## Ask.menu, for the Côte's questions too: `prompt` said by `speaker`, then `action` (when
## given), the `topics`, « Au revoir ». True when Chloé picked the action.
static func menu(npc: StringName, speaker: String, prompt: String, topics: Array, action := "") -> bool:
	if topics.is_empty() and action == "":
		await S.say([{"who": speaker, "text": prompt}])
		return false
	var asked := {}
	while true:
		var options: Array = []
		if action != "":
			options.append(action)
		var shown := topics.filter(func(t: StringName) -> bool: return not asked.has(t))
		for t: StringName in shown:
			options.append(label(npc, t))
		options.append(Ask.GOODBYE)
		var pick := await Dialogue.choose(speaker, prompt, options)
		if action != "" and pick == 0:
			return true
		var i := pick - (1 if action != "" else 0)
		if i < 0 or i >= shown.size():
			return false
		var topic: StringName = shown[i]
		asked[topic] = true
		await S.say([{"who": "Chloé", "text": label(npc, topic)}])
		var said := answer(npc, speaker, topic)
		await S.say(said if not said.is_empty() else Ask.answer(npc, speaker, topic))
		if asked.size() == topics.size() and action == "":
			return false
		prompt = Ask.AGAIN
	return false


## The Côte's questions of the moment, for Roc and Maïa (added to Ask.story_topics()).
static func story_topics() -> Array:
	var out: Array = []
	if not Game.flag(&"cote_arrivee") or Game.flag(&"maia_enfuie"):
		return out
	if not Game.flag(&"cache_vue"):
		out.append(&"plongee")
	if (Game.flag(&"pecheurs_vus") or Game.flag(&"barque_nuit_vue")) and not Game.flag(&"barque_isaure_vue"):
		out.append(&"barque_nuit")
	if Game.flag(&"passe_recif") and not Game.flag(&"sceau_cote"):
		out.append(&"mosasaure")
	elif not Game.flag(&"sceau_cote"):
		out.append(&"recif")
	return out


## What Chloé may ask Gustave and Firmin.
static func pecheurs_topics() -> Array:
	var out: Array = []
	if Objectives.main_hint() != "":
		out.append(&"suite")
	if not Game.flag(&"barque_isaure_vue"):
		out.append(&"barque_nuit")
	if not Game.flag(&"cache_vue"):
		out.append(&"grottes")
	if not Game.flag(&"sceau_cote"):
		out.append(&"recif" if not Game.flag(&"passe_recif") else &"mosasaure")
	if not Game.flag(&"tortues_sauvees"):
		out.append(&"tortues")
	out.append(&"helene_cote")
	return out


## What Chloé may ask Joss, on the Côte.
static func joss_topics() -> Array:
	var out: Array = []
	if Objectives.main_hint() != "":
		out.append(&"suite")
	if not Game.flag(&"cache_vue"):
		out.append(&"plongee")
		out.append(&"grottes")
	if not Game.flag(&"sceau_cote"):
		out.append(&"recif" if not Game.flag(&"passe_recif") else &"mosasaure")
	if (Game.flag(&"pecheurs_vus") or Game.flag(&"barque_nuit_vue")) and not Game.flag(&"barque_isaure_vue"):
		out.append(&"barque_nuit")
	return out


## The answer to one of the Côte's questions, [] for any other (Ask answers those).
static func answer(npc: StringName, speaker: String, topic: StringName) -> Array:
	match topic:
		&"suite":
			if npc == &"gustave":
				var hint := Objectives.main_hint()
				return [{"who": speaker, "text": "Si j'étais toi… mais je suis pas toi, j'ai peur des poules. " + hint if hint != ""
					else "Rien ne presse. La mer, elle, elle attend toujours."}]
		&"plongee":
			return [{"who": speaker, "text": _dive(npc)}]
		&"barque_nuit":
			return [{"who": speaker, "text": _boat(npc)}]
		&"grottes":
			return [{"who": speaker, "text": _caves(npc)}]
		&"recif":
			return [{"who": speaker, "text": _reef(npc)}]
		&"mosasaure":
			return [{"who": speaker, "text": _guardian(npc)}]
		&"tortues":
			return [{"who": speaker, "text": "Les Archelons pondent en haut de la plage, dans le sable sec. Les petits sortent au crépuscule et courent à la mer… et les Masiakasaurus les attendent au bord des rochers. Si tu passes par là le soir, jette un œil au nid."}]
		&"helene_cote":
			return [
				{"who": speaker, "text": "Ta grand-mère ? Elle venait ici avec la capitaine, avant. Elles pêchaient à la main, dans le lagon, en riant tellement fort que les poissons se sauvaient."},
				{"who": speaker, "text": "Et puis un jour, elles sont plus venues ensemble. Chacune de son côté. Et après, plus du tout."},
			]
	return []


## Diving: what Chloé still needs (CS.dive_step), or that she has everything.
static func _dive(npc: StringName) -> String:
	var step := CS.dive_step()
	if step == "":
		var diver: Dino = CS.diver()
		step = "Tu as tout ce qu'il faut : le masque, et ton %s pour t'emmener sous l'eau, là où c'est trop profond pour nager. Au fond de la première grotte, sous les falaises, le passage noyé t'attend." % (diver.nickname if diver else "plongeur")
	match npc:
		&"joss":
			return "Les masques, c'est ma nouvelle spécialité ! " + step
		&"roc":
			return "Hélène plongeait avec une cloche de verre sur la tête. Elle ressemblait à un bocal à cornichons. " + step
		&"maia":
			return "Moi, je nage comme une enclume, alors plonger… " + step
		&"gustave":
			return "Plonger ? Moi, je reste à la surface. C'est là qu'il y a l'air. " + step
	return step


## The boat without a lantern.
static func _boat(npc: StringName) -> String:
	match npc:
		&"roc":
			return "Une barque sans lanterne ? Il y a des gens qui connaissent la mer par cœur, Chloé. Pas beaucoup. … Je n'aime pas cette question."
		&"maia":
			return "Une barque sans lanterne ? Trop stylé. Maman dit que ce sont des contrebandiers. Elle en sait des choses, sur les contrebandiers."
		&"joss":
			return "Moi, je dors comme une souche. Mais Gustave dit qu'elle passe par une brèche du récif et qu'elle file sous les falaises de l'est, vers la crique des grottes."
		&"gustave":
			return "Elle passe le récif là où personne ne passe, et elle file sous les falaises, vers la crique des grottes. Si tu veux savoir où elle va, c'est là. Moi, je veux pas savoir."
	return "Elle passe le récif la nuit, sans lanterne, et disparaît sous les falaises de l'est."


## What is under the cliffs: the cove, a cave, a flooded passage.
static func _caves(npc: StringName) -> String:
	match npc:
		&"joss":
			return "Sous les falaises de l'est, il y a une petite crique : on y va à la nage. Au fond, une grotte. Et au fond de la grotte… de l'eau jusqu'au plafond. C'est pour ça, les masques."
		&"gustave":
			return "La crique des grottes, sous les falaises. On y pêchait les crabes, avant. Maintenant on n'y va plus : ça sent la cendre."
	return "Une crique, sous les falaises de l'est, et une grotte au fond, qu'on rejoint à la nage. Plus loin, l'eau monte jusqu'à la voûte : il faut plonger."


## Through the reef: nobody knows the pass (before page 21); then where it is.
static func _reef(npc: StringName) -> String:
	if Game.flag(&"passe_recif"):
		return "Là où pêchent les Ptéranodons, la mer est plus sombre : c'est la passe. Avec ton plongeur, tu descendras jusqu'au sanctuaire."
	match npc:
		&"roc":
			return "Le récif est un piège : du corail tranchant, des courants qui tirent vers le fond. Il y a une passe, paraît-il. Hélène la connaissait. Moi, je fermais les yeux."
		&"maia":
			return "Maman dit qu'il n'y a pas de passage. Maman dit plein de choses."
		&"joss":
			return "Mes masques ne passent pas à travers le corail, ça, je te le garantis. Il faudrait connaître la passe."
		&"gustave":
			return "Il y a une passe, qu'on dit. Personne la connaît. Enfin, personne… à part la barque sans lanterne."
	return "Il y aurait une passe dans le récif. Quelqu'un la connaît : la barque sans lanterne la prend toutes les nuits."


## The reef's guardian: the Mosasaure Abyssal (a battle of honour; the tip).
static func _guardian(npc: StringName) -> String:
	match npc:
		&"roc":
			return "Un Mosasaure, grand comme une maison qui nage. Il n'y voit presque rien : il écoute. Ce sera un combat d'honneur, Chloé. Pas de collier, pas de fuite." + TIP
		&"maia":
			return "Un MOSASAURE ?! Ça, c'est encore plus stylé qu'un Masque. Bats-le, et reviens vite : on a un défi, toutes les deux !" + TIP
		&"joss":
			return "Je ne sais pas. Je sais seulement que mes masques tiennent à vingt mètres. Au-delà, je n'ai pas testé. Et je ne testerai pas."
		&"gustave":
			return "Le gros du récif ? Personne l'a jamais vu en entier. Une fois, sa queue est passée sous La Sardine. On a mis trois jours à arrêter de trembler."
	return "Le Mosasaure Abyssal, le gardien du récif. Un combat d'honneur." + TIP
