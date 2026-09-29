class_name DialogueCote
## Chapter 5, the Côte Préhistorique: its plain lines, by id (same steps as DialogueDB: {"who",
## "text"}, {"flag"}, {"letter", "sign"}…). DialogueDB.lines() falls back on lines() for the ids
## it does not know; chatter() adds the chapter's lines to the pools of Isaure, Roc and Maïa.
## Signs, closed ways (the reef, the Monts Gelés), pages 21, 22, 24 and 25 (Pickups; page 23 is
## read with Maïa: PAGE_23, story/cote_fin.gd).

const CHLOE := "Chloé"
const MAIA := "Maïa"
## Page 23, « Marraine », found with Maïa in the tin box of Hélène's lookout.
const PAGE_23 := ["Marraine",
	"Aujourd'hui, Isaure a posé son bébé dans mes bras. Maïa. Trois kilos de colère : elle a hurlé pendant tout le baptême, puis elle s'est endormie sur mon épaule, le poing serré sur ma fougère.",
	"Isaure m'a demandé d'être sa marraine. J'ai dit oui avant qu'elle ait fini sa phrase.",
	"Ce soir, depuis mon poste de guet, je regarde leur barque rentrer au port. Isaure et son bébé.",
	"Cette semaine, mes carnets ont disparu. Je ne veux pas savoir. Pas ce soir. Ce soir, je suis marraine."]


## The lines for `id`, [] when it is not one of the Côte's.
static func lines(id: StringName) -> Array:
	match id:
		&"panneau_cote_entree":
			var steps: Array = [
				{"text": "Côte Préhistorique. Ouest : la plage aux tortues. Nord : le lagon et le récif. Est : les falaises à Ptéranodons. Sud : le Désert Aride."},
				{"text": "Une planche clouée dessous : « Baignade déconseillée, bis. — La direction. » En guise de signature, une marque de dent grande comme une main."},
			]
			if Game.flag(&"prologue_done"):
				steps.append({"who": CHLOE, "text": "(La même « direction » que la crique des Plaines. Elle a de grandes dents, la direction.)"})
			return steps
		&"panneau_plage_tortues":
			var steps: Array = [{"text": "Plage aux tortues. Tortues en sieste : ne pas s'asseoir dessus, même si ça ressemble à un rocher. — H."}]
			if Game.flag(&"rempart_rencontre"):
				steps.append({"who": CHLOE, "text": "(Trop tard, Hélène. J'ai déjà fait le coup avec le Vieux Rempart.)"})
			return steps
		&"panneau_lagon":
			return [{"text": "Lagon. Eau calme, fond de sable. Au-delà du récif : pas calme, pas de fond."},
				{"text": "Une petite affiche toute neuve, punaisée de travers : « Masques de plongée sur mesure. Voir Joss (sur la plage, ou dans l'eau). Regardez les coutures. »"}]
		&"panneau_falaises":
			return [{"text": "Falaises à Ptéranodons. Attention : chutes de poissons."},
				{"text": "Dessous, gravé au couteau, tout frais : « Et de Moustique. — Maïa »"}]
		&"recif_bloque":
			return _reef()
		&"plongee_bloquee":
			return _flooded_passage()
		&"monts_bloques":
			return _mountains()
		&"page_21":
			return _page_21()
		&"page_22":
			return [
				{"text": "Entre deux branches de corail, glissée dans une fiole de verre bouchée à la cire, une page du journal. Sèche, malgré la mer."},
				{"letter": ["Le troisième Cœur",
					"Il ne voit presque rien, en bas. Il écoute. Il a tourné autour de moi longtemps, et j'ai compris qu'il écoutait mon cœur battre, et celui que je portais.",
					"I. tenait la barre, là-haut, sans trembler. Anselme a été malade par-dessus bord. Deux fois. Minuit (c'est son nom, maintenant) a trouvé ça passionnant.",
					"Je lui ai confié le troisième Cœur. Il l'a couché dans un bénitier grand comme une baignoire, et le corail s'est refermé dessus. Il ne le rendra qu'à quelqu'un dont il connaît le battement."],
					"sign": "— H."},
				{"flag": &"found_journal_22"},
				{"who": CHLOE, "text": "(« Quelqu'un dont il connaît le battement »… Il a écouté les Cœurs dans ma sacoche. Et peut-être le mien.)" if Game.flag(&"coeur_3")
					else "(Minuit… Et I. tenait la barre. Elle savait où dort le troisième Cœur, depuis vingt-cinq ans.)"},
			]
		&"page_24":
			return [
				{"text": "Au pied des vieilles marches taillées dans la roche, coincée sous un masque d'os sculpté, une page du journal."},
				{"letter": ["Le symbole",
					"Les premiers habitants sont partis d'ici, quand le volcan a fumé. On voit encore leurs marches, taillées jusque dans l'eau, et sur chacune un masque d'os sculpté, tourné vers la mer.",
					"Hier, au port, un homme en portait un comme ceux-là. « Pour rire », m'a-t-il dit. Il ne riait pas.",
					"Les anciens promettaient de veiller sur le sommeil des géants. Quelqu'un a pris la promesse et en a fait une menace. J'ai peur de ce que ça annonce."],
					"sign": "— H."},
				{"flag": &"found_journal_24"},
				{"who": CHLOE, "text": "(Il y a dix-huit ans… Les masques d'os faisaient déjà peur. L'Ombre Noire est née bien avant moi.)"},
			]
		&"page_25":
			return [
				{"text": "Au fond du lagon, à moitié enfouie dans le sable, une bouteille bouchée à la cire. Dedans, une page roulée, parfaitement sèche."},
				{"letter": ["Ce que j'aurais dû dire",
					"Ma chère I., tu es partie sans claquer la porte, et c'était pire. Voilà ce que j'aurais dû te dire, ce soir-là.",
					"Tu n'as pas tort pour le port. Tu as tort sur le moyen. Si je vends l'ambre, ce ne sont pas les pêcheurs qui mangeront : ce sont ceux qui achètent.",
					"Reviens boire un café. Je garde ta tasse, celle qui est ébréchée.",
					"Je ne l'enverrai pas. Je la jette à la mer : c'est lâche, et c'est tout ce que j'ai."],
					"sign": "— H."},
				{"flag": &"found_journal_25"},
				{"who": CHLOE, "text": "(Elle ne l'a jamais envoyée. « I. » ne l'a jamais lue…)"},
			]
	return []


## Page 21, under « H. + I. » carved in the cave's rock: the pass through the reef. Chloé now
## knows where to go through (passe_recif).
static func _page_21() -> Array:
	var steps: Array = [
		{"text": "Dans la roche, au-dessus des caisses, deux initiales gravées et une petite fougère : « H. + I. » Juste dessous, roulée dans une fiole de verre, une page du journal."},
		{"letter": ["Le passage",
			"I. dit qu'aucun bateau ne passe le récif. Puis elle m'y a fait passer, un soir de grande marée, en chantant faux pour que je n'aie pas peur.",
			"Il faut regarder où pêchent les Ptéranodons : là, la mer est plus sombre. C'est la passe. Personne d'autre ne connaît ce chemin ; elle me l'a donné comme on donne un secret.",
			"Nous avons dormi dans cette grotte, trempées, à rire de tout. Elle a gravé nos initiales avec la pointe de mon scalpel. Je lui ai dit que c'était du vandalisme. Elle m'a dit que c'était de l'histoire."],
			"sign": "— H."},
		{"flag": &"found_journal_21"},
		{"flag": &"passe_recif"},
	]
	if Game.flag(&"barque_isaure_vue"):
		steps.append({"who": CHLOE, "text": "(« I. » connaissait la passe. Et c'est la barque d'Isaure qui dort ici, amarrée au milieu des caisses.)"})
	else:
		steps.append({"who": CHLOE, "text": "(« I. » connaissait le chemin. Et quelqu'un le prend encore, toutes les nuits.)"})
	if Game.flag(&"chariot_fouille"):
		steps.append({"who": CHLOE, "text": "(« Rapporte-moi le Cœur avant la grande marée », disait le mot du Désert. La grande marée : le soir où l'on passe le récif.)"})
	steps.append({"who": CHLOE, "text": "(Là où pêchent les Ptéranodons… Maintenant, je sais où passer.)"})
	return steps


## The reef (a closed ZoneExit until page 21: the pass; the lagoon's pass and the cave's sea
## tunnel alike).
static func _reef() -> Array:
	var steps: Array = [{"text": "Au-delà, le récif : un labyrinthe de corail et de rochers noirs, où l'écume gronde. Sans connaître la passe, on s'y perdrait."}]
	if Game.flag(&"barque_nuit_vue") or Game.flag(&"pecheurs_vus"):
		steps.append({"who": CHLOE, "text": "(Pourtant, la barque sans lanterne passe par là, la nuit. Quelqu'un connaît le chemin…)"})
	else:
		steps.append({"who": CHLOE, "text": "(Quelque part, il doit y avoir un passage. Mais où ?)"})
	return steps


## The caves' blue pool without Joss's mask (the flooded passage, DiveSpot « PlongeeAller »).
static func _flooded_passage() -> Array:
	var steps: Array = [
		{"text": "La roche plonge dans une eau bleue, si claire qu'on voit les traces des caisses continuer sur le fond… puis disparaître sous la paroi."},
		{"who": CHLOE, "text": "(Ça passe par là. Sous l'eau. Mais je ne retiendrai jamais mon souffle jusque de l'autre côté.)"},
	]
	if Game.flag(&"pecheurs_vus"):
		steps.append({"who": CHLOE, "text": "(Gustave a dit que Joss était au lagon, « la tête dans un bocal »… Un bocal pour respirer sous l'eau ?)"})
	else:
		steps.append({"who": CHLOE, "text": "(Il me faudrait de quoi respirer là-dessous. Et un dino qui nage sous l'eau comme un poisson.)"})
	return steps


## The way east, up to the Monts Gelés (not built yet).
static func _mountains() -> Array:
	var steps: Array = [{"text": "À l'est, les falaises montent vers la neige. Le vent qui en descend est si froid qu'il pique les yeux."}]
	if Game.flag(&"maia_enfuie"):
		steps.append({"who": CHLOE, "text": "(Les Monts Gelés… Le quatrième Cœur m'attend là-haut. Et Maïa ? Où est-elle partie ?)"})
		steps.append({"text": "(La suite de l'aventure arrive bientôt !)"})
	else:
		steps.append({"who": CHLOE, "text": "(Pas encore. La Côte garde un Cœur, et Maïa m'attend pour notre défi.)"})
	return steps


## The chapter's lines for someone's chatter pool (DialogueDB.chatter): a new pool, `pool`
## with them inserted (first: the most urgent) or added. Once Maïa has run away, Isaure and
## Maïa have only the chapter's lines: nothing else sounds right any more.
static func chatter(who: StringName, pool: Array) -> Array:
	var out := pool.duplicate()
	match who:
		&"isaure":
			if Game.flag(&"maia_enfuie"):
				return [
					"Maïa n'est pas rentrée hier soir. Joss dit qu'elle dort chez lui, au Havre. Elle ne veut pas me voir. … Tu sais pourquoi, toi, moussaillon ?",
					"Si tu la vois, dis-lui… Non. Ne lui dis rien. Dis-lui juste de manger.",
					"La mer est calme, ce soir. Moi pas.",
				]
			if Game.flag(&"cote_arrivee"):
				out.insert(0, "Tu as vu les tortues de la Côte ? Hélène leur donnait des noms. Elles répondaient. Enfin, elle le disait.")
			if Game.flag(&"coeur_3"):
				out.insert(0, "Trois Cœurs… Tu as les yeux de ta grand-mère, moussaillon. Et sa chance. Garde-les près de toi.")
		&"roc":
			if Game.flag(&"maia_enfuie"):
				out.insert(0, "Maïa… Laisse-lui du temps. Et toi, mange quelque chose. Tu as une tête de poisson oublié au soleil.")
			if Game.flag(&"cote_arrivee") and not Game.flag(&"sceau_cote"):
				out.insert(0, "La Côte… Hélène y passait des nuits entières à regarder la mer. Moi, j'y ai surtout passé des nuits à être malade.")
			if Game.flag(&"nessie"):
				out.append("Un Plesiosaurus ! Hélène disait qu'il faut leur gratter le dessous du cou. Je n'ai jamais pu vérifier : ils ont le cou très long, et moi les bras très courts.")
		&"maia_havre":
			if Game.flag(&"maia_enfuie"):
				return ["…", "Laisse-moi, Chloé. S'il te plaît.", "Je ne suis pas là. Je ne sais pas où je suis."]
			if Game.flag(&"cote_ouverte") and not Game.flag(&"maia_falaises_vue"):
				out.insert(0, "La Côte ! Il y a des Ptéranodons GRANDS COMME DES BARQUES. Moustique va leur montrer qui est le chef. Je t'attends aux falaises !")
			if Game.flag(&"maia_falaises_vue") and not Game.flag(&"coeur_3"):
				out.insert(0, "Défi numéro cinq : au belvédère, avec la mer derrière moi. Dépêche-toi d'avoir ton troisième Cœur !")
	return out
