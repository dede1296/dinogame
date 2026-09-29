class_name DialogueDesert
## Chapter 4, the Désert Aride: its plain lines, by id (same steps as DialogueDB: {"who",
## "text"}, {"flag"}, {"letter", "sign"}…). DialogueDB.lines() falls back on lines() for the
## ids it does not know; chatter() adds the chapter's lines to the pools of Isaure, Roc and Maïa.
## Signs, closed ways (the Côte, the door of the Vents, the walled canyon), pages 17 to 20.

const P := preload("res://story/desert_places.gd")
const CHLOE := "Chloé"
const MAIA := "Maïa"


## The lines for `id`, [] when it is not one of the Désert's.
static func lines(id: StringName) -> Array:
	match id:
		&"panneau_desert_entree":
			return [{"text": "Désert Aride. Nord : le sanctuaire des Vents. Ouest : les canyons. Nord-est : l'oasis. Sud : le Marais Brumeux."},
				{"text": "Dessous, gravé au couteau : « Emportez de l'eau. Et un chapeau. Et un deuxième chapeau, le vent vole le premier. — S. »"}]
		&"panneau_cimetiere":
			return [{"text": "Cimetière des Géants. Les os ne mordent pas. Soyez polis quand même."},
				{"text": "Une planche clouée dessous : « Fouilles de Tante Sirocco. On ne touche pas à mes cailloux. Surtout à ceux qui ont des dents. »"}]
		&"panneau_oasis":
			return [{"text": "Oasis. Eau fraîche, ombre gratuite. Dattes : il n'y en a plus, les Ouranosaurus sont passés."}]
		&"panneau_sanctuaire":
			return [{"text": "Sanctuaire des Vents. N'entre que qui le gardien laisse entrer."},
				{"text": "Plus bas, une petite fougère gravée, et d'une écriture penchée : « Il rugit fort, mais il ronronne quand on lui gratte les cornes. — H. »"}]
		&"cote_bloquee":
			return _coast()
		&"porte_vents_fermee":
			return _door()
		&"rempart_bloque":
			return _rocks()
		&"page_17":
			return [
				{"text": "Sous une côte géante à moitié enfouie, roulée dans un morceau de cuir, une page du journal."},
				{"letter": ["Les géants",
					"Sirocco et moi avons déterré aujourd'hui une vertèbre grande comme une baignoire. Pas une goutte d'ambre autour : rien à réveiller. Ceux-là dorment pour de bon.",
					"Sirocco dit que les os se souviennent, et qu'un jour quelqu'un saura leur parler. Elle dit beaucoup de choses, Sirocco. Elle a souvent raison, et ça m'agace.",
					"Nous avons recouvert les os de sable, bien au chaud. Pour l'instant."],
					"sign": "— H."},
				{"flag": &"found_journal_17"},
				{"who": CHLOE, "text": "(« Pour l'instant »… Comme si elle savait qu'un jour, ils se réveilleraient.)"},
			]
		&"page_18":
			return [
				{"text": "Au pied d'un totem, coincée entre deux pierres pour que le vent ne l'emporte pas, une page du journal."},
				{"letter": ["Le deuxième Cœur",
					"Il m'a chargée quatre fois. La cinquième, il s'est arrêté si près que son souffle a embué mes lunettes. Je n'ai pas bougé. Je crois qu'il a trouvé ça drôle.",
					"Je lui ai confié le deuxième Cœur. Il l'a posé au fond du sanctuaire, là où le vent chante, et il s'est couché devant la porte.",
					"Elle ne s'ouvrira qu'à son rugissement. Un vrai : la peur n'ouvre rien, ici. Je l'ai voulu ainsi."],
					"sign": "— H."},
				{"flag": &"found_journal_18"},
				{"who": CHLOE, "text": "(« La peur n'ouvre rien. » Brac aurait dû lire ça avant de venir.)"},
			]
		&"page_19":
			return [
				{"text": "Sous la margelle du vieux puits, dans une boîte en fer toute rouillée, une page du journal."},
				{"letter": ["Orgueil",
					"Un an déjà depuis la nuit du feu. Mes mains me font encore mal quand il fait froid ; ici, il ne fait jamais froid. C'est pour ça que je viens.",
					"Ce soir, au bord de l'eau, Sirocco m'a demandé pourquoi j'avais fait ça. J'ai dit la vérité : j'ai voulu réveiller ce qui devait dormir. Parce que je le pouvais. Parce que j'étais la seule.",
					"C'est ça, l'orgueil : croire que pouvoir, c'est devoir. L'eau de l'oasis ne juge personne. Moi, si."],
					"sign": "— H."},
				{"flag": &"found_journal_19"},
				{"who": CHLOE, "text": "(La nuit du feu… ses mains brûlées. Qu'est-ce qu'elle a voulu réveiller, Hélène ?)"},
			]
		&"page_20":
			return [
				{"text": "Au fond du canyon muré, sous une pierre plate que le Vieux Rempart garde de son ombre, une page du journal pliée en huit." if Game.flag(&"rempart_rencontre")
					else "Au fond du canyon muré, sous une pierre plate, une page du journal pliée en huit."},
				{"letter": ["La carte",
					"Cinq Cœurs, cinq gardiens. Je les dessine ici une seule fois, puis je brûle le brouillon. Anselme en garde une copie ; personne d'autre ne doit savoir.",
					"Le Marais : sous le temple qui dort dans l'eau. Le Désert : derrière la porte des Vents. La Côte : là où le récif…"],
					"sign": "— H."},
				{"text": "La suite est effacée : le sable a tout mangé. Sur le dessin, on devine encore une vague, un flocon… et une flamme."},
				{"flag": &"found_journal_20"},
				{"who": CHLOE, "text": "(Une vague, un flocon, une flamme : trois Cœurs de plus.)"},
				{"who": CHLOE, "text": "(Et Roc a une copie de cette carte. Il sait où sont les Cœurs… depuis le début.)"},
			]
	return []


## The road north to the Côte: Maïa first; once she is beaten, the track is lost under the
## sand until the wind turns (the Côte is not built yet).
static func _coast() -> Array:
	var steps: Array = [{"text": "Au nord, les dunes descendent vers la mer. Mais la piste disparaît sous le sable : chaque nuit, le vent la redessine ailleurs."}]
	if Game.flag(&"maia_defi_4"):
		steps.append({"who": CHLOE, "text": "(Il faudra attendre que le vent tourne. Maïa dit qu'il tourne au crépuscule : du haut de la grande dune, au nord de l'oasis, je verrai où passe la piste.)"})
	elif Game.flag(&"sceau_desert"):
		steps.append({"who": MAIA, "text": "HÉ ! Pas si vite, championne ! Avant la Côte, il y a moi. Viens me voir à l'oasis !"})
	else:
		steps.append({"who": CHLOE, "text": "(Sans quelqu'un qui connaît ces dunes par cœur, je me perdrais. Et le Désert n'a pas fini de me parler.)"})
	return steps


## The door of the sanctuary des Vents (a closed ZoneExit): only its guardian's roar opens it.
static func _door() -> Array:
	var steps: Array = [{"text": "Une grande porte de pierre, taillée dans la falaise et couverte de spirales de vent. Au milieu, une empreinte de patte immense, et une inscription : « Au gardien sans peur, la porte s'ouvre. »"}]
	if Game.flag(&"brac_desert_battu"):
		steps.append({"who": CHLOE, "text": "(Le gardien, c'est le Carnotaurus Rouge. Il faut d'abord le libérer de sa peur.)"})
	elif Game.flag(&"brac_desert_vu"):
		steps.append({"who": CHLOE, "text": "(Le gardien, c'est le Carnotaurus Rouge. Et Brac l'a emmené dans le canyon des Vents, à l'ouest.)"})
	return steps


## The fallen rocks of the walled canyon (Obstacle, Charge): what is behind, and who could
## break through (a dino of the box, or a charger to find). Shorter once seen.
static func _rocks() -> Array:
	var steps: Array = []
	if not Game.flag(&"rempart_vu"):
		steps.append_array([
			{"text": "Des rochers énormes bouchent l'entrée du canyon, jusqu'en haut. Entre deux blocs passe un filet d'air frais… et un bruit lent, profond, régulier."},
			{"text": "Quelque chose respire, de l'autre côté. Quelque chose de très, très grand. Et de très, très calme."},
			{"flag": &"rempart_vu"},
		])
	else:
		steps.append({"text": "Les éboulis du canyon muré. De l'autre côté, la grande respiration continue, lente comme la marée."})
	for d: Dino in Game.box:
		if Abilities.has(d, &"charge"):
			steps.append({"text": "Ton %s saurait les enfoncer d'un coup de tête… mais il attend au Cabinet. Le Pr Roc peut te l'échanger contre un dino de l'équipe." % d.nickname})
			return steps
	steps.append({"text": "Il faudrait un dino qui charge. Les Pinacosaurus des dunes foncent tête baissée sur tout ce qui bouge ; un Tricératops ou un Protoceratops ferait l'affaire aussi."})
	return steps


## The chapter's lines for someone's chatter pool (DialogueDB.chatter): a new pool, `pool`
## with them inserted (first: the most urgent) or added.
static func chatter(who: StringName, pool: Array) -> Array:
	var out := pool.duplicate()
	match who:
		&"isaure":
			if Game.flag(&"desert_arrivee") and not Game.flag(&"sceau_desert"):
				out.insert(0, "Le Désert ? Hélène y passait des semaines, avec une vieille chasseuse de fossiles qui riait comme une crécelle. Sirocco. … Elle vit encore ?")
			if Game.flag(&"sirocco_vue"):
				out.append("Sirocco t'a raconté qu'Hélène et moi, on se disputait la dernière datte ? C'est vrai. Je gagnais toujours. Enfin, presque toujours.")
			if Game.flag(&"sceau_desert"):
				out.insert(0, "Deux Cœurs, déjà ? Tu vas vite, moussaillon. Plus vite que ta grand-mère. … Garde-les bien. On ne sait jamais qui regarde.")
			if Game.flag(&"cote_annonce"):
				out.append("La Côte ? Ses grottes marines sont traîtresses, moussaillon. La marée y monte plus vite qu'un cheval au galop. N'y va jamais seule.")
		&"roc":
			if Game.flag(&"desert_arrivee") and not Game.flag(&"sceau_desert"):
				out.insert(0, "Le Désert ! Bois avant d'avoir soif. Et si tu croises un Carnotaurus rouge, ne cours pas : il adore quand on court.")
			if Game.flag(&"sirocco_vue"):
				out.append("Sirocco t'a montré ses fossiles ? Elle les appelle tous par leur prénom. Le grand crâne, c'est « Gérard ».")
			if Game.flag(&"sceau_desert"):
				out.append("Le Carnotaurus… Hélène l'appelait « Piment ». Rouge, et piquant. Il ronronnait quand elle lui grattait les cornes. Je n'ai jamais osé vérifier.")
			if Game.flag(&"found_journal_20"):
				out.append("Une carte ? Quelle carte ? … Tiens, mange donc une baie.")
		&"maia_havre":
			if Game.flag(&"desert_arrivee") and not Game.flag(&"maia_defi_4"):
				out.insert(0, "Tu es au Désert ? Caillou a une surprise pour toi, à l'oasis. Je ne dis rien. Mais c'est ÉNORME. Et ça a des cornes. … J'ai rien dit !")
			if Game.flag(&"maia_defi_4"):
				out.append("Quatre défaites. QUATRE. Mais tu as vu Caillou ? Trois cornes ! Maman a failli tomber de sa barque.")
	return out
