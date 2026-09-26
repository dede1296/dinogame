class_name DialogueDB
## The game's lines, by id. A script is an Array of steps:
##   {"who": "Maïa", "text": "…"}   a line (no "who" = narration)
##   {"flag": &"met_maia"}           sets a story flag
##   {"text_fn": callable}           a line worked out when shown
##   {"voice": "res://…mp3"}         plays a recorded voice over the next line
##   {"letter": [paragraphs], "sign": "— H.", "voice": "res://…mp3"}
##                                  a handwritten page (first paragraph = its title)
## `lines(id)` picks the version that fits the current story flags.

const CHLOE := "Chloé"
const MAIA := "Maïa"


static func lines(id: StringName) -> Array:
	match id:
		&"maia":
			if not Game.flag(&"met_maia"):
				return [
					{"who": MAIA, "text": "Te voilà enfin ! Tu en as mis, du temps. Tu as entendu, pour le petit volé cette nuit ? Tout le port en parle."},
					{"who": CHLOE, "text": "Ma grand-mère venait souvent ici ?"},
					{"who": MAIA, "text": "Tout le temps ! Avant de partir vers le volcan, elle allait au vieux bosquet, à l'ouest."},
					{"who": MAIA, "text": "Mais un gros tronc est tombé en travers du sentier. Il faudrait des griffes bien affûtées pour le trancher…"},
					{"who": MAIA, "text": "Ton Velociraptor a l'air d'en avoir, des griffes. Et méfie-toi des hautes herbes : les dinos sauvages adorent s'y cacher !"},
					{"flag": &"met_maia"},
				]
			if Game.flag(&"found_journal_1"):
				return [{"who": MAIA, "text": "Un fragment d'ambre et une page du journal ?! Montre ça au Professeur Roc. Et la prochaine fois, c'est toi contre moi !"}]
			return [{"who": MAIA, "text": "Le vieux bosquet est à l'ouest, derrière le tronc. Ton raptor devrait pouvoir s'en charger !"}]
		&"panneau_carrefour":
			return [{"text": "Nord : Grotte des Échos.  Nord-est : les Falaises.  Est : l'étang, puis le Grand Crâne.  Ouest : le vieux bosquet.  Sud : Port-Ambre."}]
		&"isaure":
			return [{"who": "Isaure", "text": "La pêche est maigre, ces temps-ci… Mais toi, va ! L'île t'attend. Et garde un œil sur ma fille, d'accord ?"}]
		&"port_bloque":
			return [{"text": "Le Professeur Roc t'attend au Cabinet, la grande maison couverte de lierre à l'est du village."}]
		&"cabinet_bloque":
			return [{"who": "Prof. Roc", "text": "Où vas-tu comme ça ? Les petits sont sur les socles, à droite : choisis d'abord ton compagnon !"}]
		&"panneau_plaines":
			return [{"text": "Nord : les Plaines des Fougères.  Est : le Cabinet du Professeur Roc."}]
		&"panneau_port":
			return [{"text": "Sud : Port-Ambre et le Cabinet du Professeur Roc."}]
		&"panneau_debarcadere":
			return [{"text": "Nord : le carrefour des Plaines. Sud : Port-Ambre. Attention, dinos dans les herbes hautes !"}]
		&"panneau_grotte":
			return [{"text": "Grotte des Échos — entrée fermée par un éboulement."}]
		&"tronc_bloque":
			return [{"text": "Un gros tronc moussu barre le sentier. Des griffes acérées pourraient le trancher…"}]
		&"rocher_bloque":
			return [{"text": "Un énorme rocher bloque le chemin de la grotte. Il faudrait un dino à la tête solide pour l'enfoncer…"},
				{"text": "Les Protoceratops des hautes herbes ont justement une tête bien dure."}]
		&"ambre_proto":
			return [
				{"text": "Tu as trouvé un fragment d'ambre ! Un minuscule Protoceratops y est figé depuis 66 millions d'années."},
				{"text": "Une page de journal, pliée en quatre, est glissée dessous…"},
				{"letter": ["Le premier réveil",
					"12 mars. Il a ouvert les yeux ce matin. Trente-deux ans de recherche, et un petit Protoceratops me regarde comme si j'étais sa mère. L'Ambre-Mère ne ment pas : l'ADN est intact. Anselme a pleuré. Moi aussi, un peu.",
					"Je dois garder le secret. Si l'on apprend ce que l'île contient, ils viendront tous."],
					"sign": "— H.", "voice": "res://assets/audio/voices/journal-1.mp3"},
				{"flag": &"found_journal_1"},
				{"flag": &"amber_protoceratops"},
				{"text": "Au fond de la cachette brille autre chose : une écaille d'ambre, tiède comme une pierre au soleil."},
				{"flag": &"ecaille_bosquet"},
				{"text_fn": ecailles_text},
			]
		&"ecaille_grotte":
			return [{"text": "Une écaille d'ambre, coincée entre deux cristaux. Elle pulse doucement, comme un cœur."},
				{"flag": &"ecaille_grotte"}, {"text_fn": ecailles_text}]
		&"ecaille_falaises":
			return [{"text": "Une écaille d'ambre, posée sur la table du vieux poste d'observation. Hélène l'a laissée là exprès."},
				{"flag": &"ecaille_falaises"}, {"text_fn": ecailles_text}]
		&"page_3":
			return [
				{"text": "Une page du journal d'Hélène, glissée sous une pierre plate."},
				{"letter": ["La barque",
					"Je n'aurais jamais trouvé Ambrelune sans I. Elle avait dix-neuf ans, une barque trop petite et un courage trop grand. Elle a traversé la brume pour moi sans poser de questions.",
					"Quand l'île est apparue, elle a ri : « Tu vois, Hélène ? Les légendes, ça se trouve. » Je lui dois tout."],
					"sign": "— H."},
				{"flag": &"found_journal_3"},
			]
		&"page_4":
			return [
				{"text": "Une page du journal, roulée dans une fissure de la roche."},
				{"letter": ["Ce qui ne dort pas",
					"J'ai voulu forcer l'ambre. Réveiller un dino sans attendre qu'il soit prêt. Ce qui est sorti de la pierre n'était pas vivant comme les autres : des veines violettes, des yeux troubles, une peur qui ne s'éteignait jamais.",
					"J'ai tout arrêté. J'ai brûlé mes notes… presque toutes."],
					"sign": "— H."},
				{"flag": &"found_journal_4"},
			]
		&"page_5":
			return [
				{"letter": ["Le premier Alpha",
					"Le grand Tricératops m'a chargée trois fois avant de s'arrêter. Puis il a posé sa tête contre ma main. Je n'avais rien fait, rien dit : j'avais seulement refusé d'avoir peur de lui.",
					"C'est ça, le Lien. Pas un ordre : une confiance. Je l'écris ici pour ne jamais l'oublier."],
					"sign": "— H."},
				{"flag": &"found_journal_5"},
			]
		&"porte_ambre_bloquee":
			return [{"text": "Une porte d'ambre, éteinte et froide, scellée dans la roche. Une fougère est gravée dessus."},
				{"text": "On raconte que l'ambre répond au chant… Une crête qui résonne pourrait peut-être la réveiller."}]
		&"panneau_falaises":
			return [{"text": "Poste d'observation d'H. Varenne. Nids de Dimorphodons : ne pas déranger !"}]
		&"panneau_crane":
			return [{"text": "Le Grand Crâne. Dans sa grotte dort le gardien des Plaines."}]
		&"antre_gardien":
			if Game.flag(&"sceau_plaines"):
				return [{"text": "Du fond du tunnel monte une respiration lente et profonde… Le gardien dort."},
					{"text": "Mieux vaut ne pas le déranger."}]
			return [{"text": "Le tunnel sent le gardien, mais il est vide. Le Tricératops Alpha t'attend dehors, devant le crâne."}]
		&"panneau_grotte_int":
			return [{"text": "Quelqu'un a gravé une flèche dans la roche, vers le nord. Et, dessous : « H. »"}]
	push_error("Dialogue inconnu : %s" % id)
	return []


## How many of the three amber scales Chloé has, said after finding one.
static func ecailles_text() -> String:
	var n := ecailles()
	if n >= 3:
		return "Chloé a les trois écailles d'ambre ! Le Grand Crâne, au sud-est des Plaines, attend."
	return "Écailles d'ambre : %d sur 3." % n


static func ecailles() -> int:
	var n := 0
	for f: StringName in [&"ecaille_bosquet", &"ecaille_grotte", &"ecaille_falaises"]:
		if Game.flag(f):
			n += 1
	return n
