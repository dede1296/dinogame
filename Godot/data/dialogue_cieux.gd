class_name DialogueCieux
## Chapter 7, the Cieux Éternels: its plain lines, by id (same steps as DialogueDB: {"who",
## "text"}, {"flag"}, {"letter", "sign"}…). DialogueDB.lines() falls back on lines() for the ids
## it does not know; chatter() adds the chapter's lines to the pools of Isaure, Roc, Maïa and
## Joss; the chapter's questions (TOPICS, story_topics, answer) are read by Ask. Signs, closed
## ways (the way up from the Monts, the needle to the Arche, the way down to the volcano), pages
## 31 to 34 (Pickups in the zones), the fallen mask.

const CHLOE := "Chloé"
const C := preload("res://story/cieux.gd")
const TOPICS := {
	&"harnais": "Et le harnais de vol ?",
	&"ponts": "Comment on traverse les ponts ?",
	&"roi": "Qui garde les Cieux ?",
	&"arche": "Qu'y a-t-il tout en haut ?",
	&"voler": "Comment on vole ?",
}


## The lines for `id`, [] when it is not one of the Cieux's.
static func lines(id: StringName) -> Array:
	match id:
		&"panneau_cieux_entree":
			return [{"text": "Cieux Éternels. Nord : les pitons, les ponts de lianes. Plus haut : les nids géants. Plus haut encore : l'Arche du Vent."},
				{"text": "Dessous, au couteau, d'une écriture penchée : « Ne pas nourrir les ptérosaures. Ils se servent. — H. »"}]
		&"panneau_pont":
			return [{"text": "« Un pont de lianes, ça se traverse. Ça ne se regarde pas. — H. »"}]
		&"panneau_belvedere":
			return [{"text": "Belvédère. Par temps clair, on voit l'île entière. Par temps couvert, on voit des nuages. C'est joli aussi."}]
		&"panneau_nids":
			return [{"text": "« On ne grimpe pas dans les nids. Même vides. Surtout vides. — H. »"}]
		&"panneau_arche":
			return [{"text": "Arche du Vent. Par grand vent, se tenir aux lianes. Par très grand vent, se tenir à quelqu'un. — H."}]
		&"cieux_bloques":
			return way_up()
		&"arche_bloquee":
			return _needle()
		&"volcan_bloque":
			return _way_down()
		&"masque_obsidienne":
			return [{"text": "Le masque d'obsidienne, dans l'herbe rase. Personne ne l'a ramassé."}]
		&"page_31":
			return _page_31()
		&"page_32":
			return _page_32()
		&"page_33":
			return _page_33()
		&"page_34":
			return _page_34()
	return []


## The way from the Monts up to the Cieux (the Monts' exit, closed until cieux_ouverts), once
## Maïa and Chloé are a team: what is missing (the harness, a grown flyer), or the glide up.
## Before: [] (the Monts' own lines, DialogueMonts._skies).
static func way_up() -> Array:
	if not Game.flag(&"maia_alliee"):
		return []
	if C.flyer() != null:   # (ready: the way opens now, and she goes up)
		var flying: Dino = C.flyer()
		return [
			{"text": "Le sentier s'arrête net, au bord du vide. En bas, les nuages. En haut, les pitons. Et entre les deux, le vent qui monte le long de la falaise, sans s'arrêter."},
			{"text": "Chloé serre les sangles du harnais de Joss sur le dos de %s. La fougère de la sangle est contre sa poitrine." % flying.nickname},
			{"who": CHLOE, "text": "(On se penche. On ne ferme pas les yeux. … Enfin, je crois.)"},
			{"text": "%s court jusqu'au bord, et se jette. Il ne bat pas des ailes : il les ouvre, et c'est le vent qui monte. Les Monts rapetissent." % flying.nickname},
			{"flag": &"cieux_ouverts"},
		]
	return [
		{"text": "Le sentier monte encore, puis s'arrête net, au bord du vide. Au-dessus, dans les nuages, des pitons de roche flottent presque."},
		{"who": CHLOE, "text": "(Les Cieux Éternels… Pour aller là-haut, il faut voler. Enfin, planer. Enfin, se faire porter.)"},
		{"text": C.fly_step()},
	]


## The needle of the nests, the way to the Arche (closed until the Vol: « arche_bloquee »). The
## liana bridge from the Grand Nid ends on its top; the ridge goes on to the Arche, but the wind
## coming down from it pins Chloé to the rock until the Roi has let her by. Then: on foot along the
## ridge, or in flight over it.
static func _needle() -> Array:
	if Game.flag(&"vol_obtenu"):
		return [{"text": "Le sommet de l'aiguille. L'arête monte vers l'Arche du Vent : on y va à pied, le vent laisse passer, maintenant. Ou en volant."}]
	return [
		{"text": "Au bout du pont de lianes, le sommet de l'aiguille. L'arête continue vers l'Arche… mais le vent en descend si fort qu'il plaque Chloé contre la roche. Pas un pas de plus."},
		{"who": CHLOE, "text": "(Le vent garde le passage. Ici, c'est le Roi des Cieux qu'il écoute. … Le Roi d'abord.)"},
	]


## The way down to the volcano (the Descente de Cendre, closed until chapter 8).
static func _way_down() -> Array:
	var steps: Array = [{"text": "La Descente de Cendre. Un sentier gris qui descend vers le volcan, en lacets, dans un vent chaud qui sent le soufre."}]
	if Game.flag(&"masque_tombe"):
		steps.append({"who": CHLOE, "text": "(Elle est passée par là. Avec les Cœurs. Sans courir.)"})
		steps.append({"who": CHLOE, "text": "(La Plaine Volcanique. Le cinquième Cœur. Et tout ce qu'Hélène y a laissé.)"})
	steps.append({"text": "(La suite de l'aventure arrive bientôt !)"})
	return steps


# ------------------------------------------------------------------ pages 31 to 34

## Page 31, on the Belvédère: the island from above; how she flew (how one flies, no key).
static func _page_31() -> Array:
	var steps: Array = [
		{"text": "Sous le banc de pierre du Belvédère, calée par un galet, une boîte en fer. Dedans, une page du journal, et un dessin : l'île, en spirale."},
		{"letter": ["D'en haut",
			"Du Belvédère, on voit l'île entière : les régions tournent autour du volcan comme les tours d'une coquille d'escargot. Je ne l'avais jamais vue comme ça. Je ne l'avais jamais vue tout court.",
			"Pour monter ici, on ne tire pas sur les sangles : on se penche du côté où on veut aller. Pour se poser, on cherche du plat. Et on ne ferme pas les yeux. Anselme ferme les yeux.",
			"I. ne monte plus avec moi. Je n'ai pas su quoi lui dire, alors je regarde l'île à sa place, et je dessine. Elle aurait trouvé ça idiot. Elle aurait eu raison."],
			"sign": "— H."},
		{"flag": &"found_journal_31"},
	]
	if Game.flag(&"vol_obtenu"):
		steps.append({"who": CHLOE, "text": "(On se penche. On ne ferme pas les yeux. … Elle l'avait écrit pour moi, en fait.)"})
	else:
		steps.append({"who": CHLOE, "text": "(« On se penche »… Elle volait. Elle a appris toute seule, et elle l'a écrit pour que quelqu'un n'ait pas à apprendre tout seul.)"})
	return steps


## Page 32, in the nests: the Souverain, found from above.
static func _page_32() -> Array:
	var steps: Array = [
		{"text": "Dans une fente de la roche, au bord d'un nid vide, roulée dans une toile cirée, une page du journal."},
		{"letter": ["Le Souverain",
			"Il est sous le volcan, dans un bloc d'ambre grand comme une maison. Je l'ai trouvé par en haut : du Grand Nid, par temps clair, on voit le fond du cratère, et quelque chose y luit qui n'est pas de la lave.",
			"Le Roi des Cieux ne descend jamais là. Il tourne au-dessus, et il crie. Son cœur bat avec le volcan : quand l'un gronde, l'autre aussi.",
			"Il est plus vieux que tous les autres. Plus grand. Je crois qu'il dort depuis le premier jour de l'île. Je crois que je vais faire une bêtise."],
			"sign": "— H."},
		{"flag": &"found_journal_32"},
		{"who": CHLOE, "text": "(« Je crois que je vais faire une bêtise. » … Elle l'a faite. Et elle a passé le reste de sa vie à la réparer.)"},
	]
	return steps


## Page 33, on the islet in the sea of clouds (in flight only): the night of the fire.
static func _page_33() -> Array:
	var steps: Array = [
		{"text": "Sur l'îlot, sous une pierre que seul un ptérosaure pouvait apporter là, une boîte en fer. Dedans, une page du journal. Le papier a jauni."},
		{"letter": ["La nuit du feu",
			"Je l'ai réveillé. Le volcan a répondu avant lui. J'ai eu les mains dans l'ambre jusqu'aux coudes pour le calmer, et il s'est rendormi en me regardant.",
			"Alors j'ai scellé le cratère avec le cœur le plus pur de l'Ambre-Mère, et j'ai brisé la clé en cinq. Cinq Cœurs, cinq gardiens, cinq régions : personne ne rouvrira ça tout seul.",
			"Pas même moi. Surtout pas moi. Je cache cette page là où je n'irai plus : mes mains ne tiennent plus les sangles."],
			"sign": "— H."},
		{"flag": &"found_journal_33"},
		{"who": CHLOE, "text": "(« Personne ne rouvrira ça tout seul. » … Elle avait tout prévu. Sauf quelqu'un qui connaissait tous ses chemins.)"},
	]
	return steps


## Page 34, at the cairn by the Arche: torn. She knew. The name is gone.
static func _page_34() -> Array:
	var steps: Array = [
		{"text": "Sous les pierres plates du cairn, une boîte en fer, rouillée. Dedans, une page du journal. Déchirée : le coin du bas manque."},
		{"letter": ["Je sais qui c'est",
			"Je sais qui c'est. Je le sais depuis la nuit où mes carnets ont disparu, et je crois que je le savais avant, et que j'ai fait semblant.",
			"Je ne peux pas le lui dire. Elle ne me le pardonnerait pas.",
			"Alors je l'écris ici, une fois, tout en haut, pour ne plus le porter toute seule : c'est"],
			"sign": "[Le coin de la page est arraché.]"},
		{"flag": &"found_journal_34"},
		{"flag": &"page_34"},
	]
	if Game.flag(&"masque_tombe"):
		steps.append({"who": CHLOE, "text": "(Le nom est arraché. Je n'en ai pas besoin. Je l'ai entendu dire « Pas aujourd'hui ».)"})
		steps.append({"who": CHLOE, "text": "(« Elle ne me le pardonnerait pas. » Maïa ? Ou Isaure ? … Elle savait. Et elle n'a rien dit. À personne.)"})
	else:
		steps.append({"who": CHLOE, "text": "(Le nom est arraché. Mais je le connais. Et elle le connaissait aussi. Elle n'a rien dit. À personne.)"})
	return steps


# ------------------------------------------------------------------ chatter

## The chapter's lines for someone's chatter pool (DialogueDB.chatter): a new pool, `pool` with
## them inserted (first: the most urgent) or added; or the chapter's own pool, when nothing else
## sounds right any more (Isaure, once the mask has fallen: she is not at the port; Maïa).
static func chatter(who: StringName, pool: Array) -> Array:
	var out := pool.duplicate()
	match who:
		&"isaure":
			if Game.flag(&"masque_tombe"):
				return ["…"]   # (she is gone to the volcano: the port hides her, hide_flag masque_tombe)
			if Game.flag(&"vol_obtenu"):
				return ["Tu voles, maintenant ? … Elle aussi, volait. Elle revenait avec les joues rouges et les mains gelées, et elle disait que ça valait le coup. Elle le disait de tout."]
			if Game.flag(&"harnais_vol"):
				return ["Un harnais de vol, avec une fougère… Joss fait du bon travail. Maïa aussi, quand elle demande des choses.",
					"Les Cieux, moussaillon ? Là-haut, le vent ne pardonne rien. Rien du tout."]
		&"roc":
			if Game.flag(&"masque_tombe"):
				out.insert(0, "Je sors toujours la nuit. Mais je regarde le volcan autrement, maintenant. Je compte les feux. Et je compte une personne.")
			elif Game.flag(&"vol_obtenu"):
				out.insert(0, "Tu as volé de nuit ? Non ? Hélène le faisait. Elle disait que les étoiles sont plus près. Je lui disais que le sol aussi.")
			elif Game.flag(&"harnais_vol"):
				out.insert(0, "Un harnais de vol… Hélène montait avec un vieux Ptéranodon qui louchait. Elle disait qu'il volait droit quand même. Moi, je restais en bas.")
		&"maia_havre":
			if Game.flag(&"masque_tombe"):
				return [
					"Joss m'a fait une soupe. Il ne sait pas faire la soupe. Je l'ai mangée quand même.",
					"Tu as volé de nuit ? Maman dit qu'on ne décolle jamais de nuit. … Maman dit beaucoup de choses.",
					"Il reste un Cœur. On ne la laisse pas arriver la première. Mais on ne court pas. Elle non plus, elle ne court pas.",
				]
			if Game.flag(&"vol_obtenu"):
				return [
					"Tu VOLES ? Pour de vrai ? Et moi je rame. C'est injuste. C'est très stylé, mais c'est injuste.",
					"Si tu voles au-dessus du port, ne regarde pas la cuisine. Enfin, regarde. Non. Je ne sais pas.",
				]
			if Game.flag(&"harnais_vol"):
				out.insert(0, "Tu as le harnais ? Avec la fougère ? Alors file aux Monts. Je t'attends au col. J'ai un plan.")
		&"joss":
			if Game.flag(&"masque_tombe"):
				out.insert(0, "Maïa dort chez moi, encore. Elle a dit « merci pour la soupe ». Elle n'a jamais dit ça de sa vie. Ça m'inquiète plus que le reste.")
			elif Game.flag(&"vol_obtenu"):
				out.insert(0, "Les coutures ont tenu ? … Elles ont tenu. Je le savais.")
	return out


# ------------------------------------------------------------------ questions

## The chapter's questions of the moment, for Roc and Maïa (added to Ask.story_topics()).
static func story_topics() -> Array:
	var out: Array = []
	if not Game.flag(&"maia_alliee"):
		return out
	if not Game.flag(&"cieux_ouverts"):
		out.append(&"harnais")
	if Game.flag(&"cieux_arrivee") and not Game.flag(&"nids_arrivee"):
		out.append(&"ponts")
	if Game.flag(&"cieux_arrivee") and not Game.flag(&"sceau_cieux"):
		out.append(&"roi")
	if Game.flag(&"vol_obtenu"):
		out.append(&"voler")
	if Game.flag(&"cieux_arrivee") and not Game.flag(&"masque_tombe"):
		out.append(&"arche")
	return out


## The question's words, "" when it is not one of the Cieux's.
static func label(topic: StringName) -> String:
	return TOPICS.get(topic, "")


## The answer to one of the Cieux's questions, [] for any other.
static func answer(npc: StringName, speaker: String, topic: StringName) -> Array:
	match topic:
		&"harnais":
			var step := C.fly_step()
			match npc:
				&"roc":
					return [{"who": speaker, "text": "Un harnais de vol ? Joss te l'a cousu ? Alors il te faut quelqu'un pour le porter. " + step}]
				&"maia":
					return [{"who": speaker, "text": "Joss a dit « trois jours ». " + ("Il a fini ! Va le voir au Havre." if not C.has_harness() else step)}]
			return [{"who": speaker, "text": step}]
		&"ponts":
			match npc:
				&"roc":
					return [{"who": speaker, "text": "Les ponts de lianes ? On regarde les lianes, pas le vide. Hélène disait ça. Moi, je regardais mes pieds. C'est entre les deux."}]
				&"maia":
					return [{"who": speaker, "text": "Un pont qui balance au-dessus des nuages ? Je veux le voir. Non : je ne veux pas le voir. Si. Non."}]
			return [{"who": speaker, "text": "On s'accroche aux lianes et on avance. On ne regarde pas en bas."}]
		&"roi":
			var tip := CieuxObjectives._tip()
			match npc:
				&"roc":
					return [{"who": speaker, "text": "Le Quetzalcoatlus Roi. Grand comme une maison, avec un bec comme une barque. Hélène montait sur son dos, et moi je priais en bas. Ce sera un combat d'honneur : pas de collier, pas de fuite." + tip}]
				&"maia":
					return [{"who": speaker, "text": "Le Roi des Cieux ! Celui qui tournait au-dessus de nous, aux Monts ? Il a l'air de tout voir, de là-haut. Même ce qu'on fait dans les cuisines." + tip}]
			return [{"who": speaker, "text": "Le Quetzalcoatlus Roi, au bord du Grand Nid. Un combat d'honneur." + tip}]
		&"arche":
			match npc:
				&"roc":
					return [{"who": speaker, "text": "L'Arche du Vent. Hélène y avait un cairn, « son poste d'en haut ». Elle disait qu'on y voyait tout. Elle n'a jamais dit quoi."}]
				&"maia":
					return [{"who": speaker, "text": "Tout en haut ? Une arche où le vent chante, dit maman. Elle en parlait comme d'un endroit où on va seule. … Je ne la laisserai pas y aller seule."}]
			return [{"who": speaker, "text": "L'Arche du Vent, le sommet des Cieux, au bout de l'aiguille des Nids. Le vent n'y laisse pas passer n'importe qui : à pied ou en volant."}]
		&"voler":
			match npc:
				&"roc":
					return [{"who": speaker, "text": "Comment on vole ? Tu me demandes ça à moi ? Hélène disait : « on se penche, et on ne ferme pas les yeux ». " + C.vol_howto()}]
				&"maia":
					return [{"who": speaker, "text": "Comme en barque, mais en l'air, et sans rame. Tu te penches, il va. Tu cherches du plat, il se pose. " + C.vol_howto()}]
			return [{"who": speaker, "text": C.vol_howto()}]
	return []
