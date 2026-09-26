class_name DialogueDB
## The game's lines, by id. A script is an Array of steps:
##   {"who": "Maïa", "text": "…"}   a line (no "who" = narration)
##   {"flag": &"met_maia"}           sets a story flag
##   {"voice": "res://…mp3"}         plays a recorded voice over the next line
## `lines(id)` picks the version that fits the current story flags.

const CHLOE := "Chloé"
const MAIA := "Maïa"


static func lines(id: StringName) -> Array:
	match id:
		&"maia":
			if not Game.flag(&"met_maia"):
				return [
					{"who": MAIA, "text": "Hé ! Toi, tu es la petite-fille d'Hélène, non ? Tout le port ne parle que de toi."},
					{"who": MAIA, "text": "Moi, c'est Maïa. Ma mère est la capitaine du port… et moi, je connais les Plaines mieux que personne !"},
					{"who": CHLOE, "text": "Tu connaissais ma grand-mère ?"},
					{"who": MAIA, "text": "Tout le monde la connaissait. Avant de partir vers le volcan, elle venait souvent au vieux bosquet, à l'ouest."},
					{"who": MAIA, "text": "Mais un gros tronc est tombé en travers du sentier. Il faudrait des griffes bien affûtées pour le trancher…"},
					{"who": MAIA, "text": "Ton Velociraptor a l'air d'en avoir, des griffes. Et méfie-toi des hautes herbes : les dinos sauvages adorent s'y cacher !"},
					{"flag": &"met_maia"},
				]
			if Game.flag(&"found_journal_1"):
				return [{"who": MAIA, "text": "Un fragment d'ambre et une page du journal ?! Montre ça au Professeur Roc. Et la prochaine fois, c'est toi contre moi !"}]
			return [{"who": MAIA, "text": "Le vieux bosquet est à l'ouest, derrière le tronc. Ton raptor devrait pouvoir s'en charger !"}]
		&"panneau_carrefour":
			return [{"text": "Nord : Grotte des Échos.  Est : l'étang.  Ouest : le vieux bosquet."}]
		&"panneau_grotte":
			return [{"text": "Grotte des Échos — entrée fermée par un éboulement."}]
		&"tronc_bloque":
			return [{"text": "Un gros tronc moussu barre le sentier. Des griffes acérées pourraient le trancher…"}]
		&"rocher_bloque":
			return [{"text": "Un énorme rocher bloque le chemin de la grotte. Il faudrait un dino à la tête solide pour l'enfoncer…"},
				{"text": "(Charge : greffer une tête de cératopsien au Cabinet — prochaine étape du prototype.)"}]
		&"ambre_proto":
			return [
				{"text": "Tu as trouvé un fragment d'ambre ! Un minuscule Protoceratops y est figé depuis 66 millions d'années."},
				{"text": "Une page de journal, pliée en quatre, est glissée dessous…"},
				{"voice": "res://assets/audio/voices/journal-1.mp3"},
				{"who": "Hélène", "text": "« Le premier réveil. 12 mars. Il a ouvert les yeux ce matin. Trente-deux ans de recherche, et un petit Protoceratops me regarde comme si j'étais sa mère. »"},
				{"who": "Hélène", "text": "« L'Ambre-Mère ne ment pas : l'ADN est intact. Anselme a pleuré. Moi aussi, un peu. »"},
				{"who": "Hélène", "text": "« Je dois garder le secret. Si l'on apprend ce que l'île contient, ils viendront tous. »"},
				{"flag": &"found_journal_1"},
				{"flag": &"amber_protoceratops"},
			]
	push_error("Dialogue inconnu : %s" % id)
	return []
