class_name DialogueMonts
## Chapter 6, the Monts Gelés: its plain lines, by id (same steps as DialogueDB: {"who",
## "text"}, {"flag"}, {"letter", "sign"}…). DialogueDB.lines() falls back on lines() for the ids
## it does not know; chatter() adds the chapter's lines to the pools of Isaure, Roc, Maïa and
## Joss. Signs, closed ways (the ice walls, the frost door, the way up to the Cieux), pages 26 to
## 30 (Pickups in the zones; page 30 shows the first night in the valley, Monts.night).

const CHLOE := "Chloé"
const MS := preload("res://story/monts_stage.gd")


## The lines for `id`, [] when it is not one of the Monts'.
static func lines(id: StringName) -> Array:
	match id:
		&"panneau_monts_entree":
			return [{"text": "Monts Gelés. Est : la Vallée des Troupeaux. Nord : le glacier. Plus loin, à l'est : le Col des Tempêtes."},
				{"text": "Une planchette clouée dessous : « Troupeaux en liberté. Ne pas compter à voix haute : ça déconcentre la bergère. — B. »"}]
		&"panneau_vallee":
			var steps: Array = [{"text": "Vallée des Troupeaux. Soupe chaude sous le grand rocher. On paie en bois sec."}]
			if Game.flag(&"bertille_vue"):
				steps.append({"who": CHLOE, "text": "(Bertille a peint les lettres avec de la suie. Le « S » est à l'envers.)"})
			return steps
		&"panneau_glacier":
			return [{"text": "Glacier. Si la glace craque : c'est normal. Si elle s'ouvre : c'est moins normal. Courez."},
				{"text": "Dessous, d'une écriture penchée que Chloé connaît bien : « Et on ne lèche pas la glace. Même par curiosité. — H. »"}]
		&"panneau_col":
			return [{"text": "Col des Tempêtes. Par vent fort, s'abriter derrière un gros dino. Par vent très fort, derrière deux."}]
		&"monts_bloques":
			return _way_up()
		&"mur_glace_bloque":
			return _ice_wall()
		&"porte_givre_fermee":
			return [{"text": "La porte de givre est fermée. Au milieu, quatre creux ronds, grands comme un poing, attendent quelque chose."}]
		&"cieux_bloques":
			return _skies()
		&"page_26":
			return _page_26()
		&"page_27":
			return _page_27()
		&"page_28":
			return _page_28()
		&"page_29":
			return _page_29()
		&"page_30":
			return _page_30()
	return []


## The way from the Côte up to the Monts (the Côte's exit, closed until monts_ouverts), once
## chapter 5 is over: what is missing, a warm coat (where to buy it). Before: [] (the Côte's own
## lines, DialogueCote).
static func _way_up() -> Array:
	if not Game.flag(&"maia_enfuie"):
		return []
	if Monts.has_coat():   # (bought without the way opening yet: it opens now)
		return [{"text": "Chloé remonte la capuche de son manteau de duvet, et resserre son col."},
			{"who": CHLOE, "text": "(Allez. En route pour les Monts.)"},
			{"flag": &"monts_ouverts"}]
	return [
		{"text": "Le sentier grimpe vers la neige. Au premier virage, le vent qui descend des Monts transperce les habits de Chloé comme s'ils n'existaient pas."},
		{"who": CHLOE, "text": "(Brrr… Sans vêtement chaud, je ne ferai pas dix pas là-haut.)"},
		{"text": Monts.coat_step()},
	]


## An ice wall (an Obstacle for Charge): what it is, and who could break it.
static func _ice_wall() -> Array:
	var steps: Array = [{"text": "Un mur de glace bleue, épais comme une porte de château, barre le chemin. Des marques de griffes géantes le rayent de haut en bas."}]
	if Game.flag(&"glacier_arrivee"):
		steps.append({"text": "Le trou qu'elles avaient creusé s'est déjà refermé : ici, la glace repousse en une nuit."})
	var step := MS.charge_step()
	steps.append({"text": "La glace sonne creux. Un bon coup de tête, bien placé… " + (step if step != "" else "")})
	return steps


## The way north, up to the Cieux Éternels (closed until chapter 7: it takes flying).
static func _skies() -> Array:
	var steps: Array = [
		{"text": "Le sentier monte encore, puis s'arrête net, au bord du vide. Au-dessus, dans les nuages, des pitons de roche flottent presque."},
		{"who": CHLOE, "text": "(Les Cieux Éternels… Pour aller là-haut, il faudrait voler.)"},
	]
	if Game.flag(&"maia_alliee"):
		steps.append({"who": CHLOE, "text": "(Le harnais de Joss. Maïa a dit : « trois jours ». Donc une semaine.)"})
		steps.append({"text": "(La suite de l'aventure arrive bientôt !)"})
	return steps


# ------------------------------------------------------------------ pages 26 to 30

## Page 26, in the ice caves: Hélène's reserve, the sleepers.
static func _page_26() -> Array:
	var steps: Array = [
		{"text": "Dans une fente de la glace, roulée dans une toile cirée, une page du journal. Le froid l'a gardée comme neuve."},
		{"letter": ["Les dormeurs",
			"Aujourd'hui, j'ai mis à l'abri ce que je ne peux pas me permettre de perdre : des œufs, et quelques petits trop fragiles pour le monde d'en bas.",
			"La glace les garde comme l'ambre, sans rien forcer. Ils dormiront jusqu'à ce qu'ils soient prêts, ou jusqu'à ce que quelqu'un vienne, avec des mains chaudes et un cœur patient.",
			"La vie trouve toujours un chemin. Moi, je lui garde seulement la porte entrouverte.",
			"Bertille m'a prêté son traîneau sans poser une seule question. Elle m'a seulement demandé si j'avais pensé à mes moufles. Non."],
			"sign": "— H."},
		{"flag": &"found_journal_26"},
	]
	if Game.flag(&"malcombe_vu"):   # (Ivan Malcombe quoted her, at the Havre: story/visiteurs.gd)
		steps.append({"who": CHLOE, "text": "(« La vie trouve toujours un chemin. » M. Malcombe avait raison : c'était bien d'elle.)"})
	if Game.flag(&"dormeurs_reveilles"):
		steps.append({"who": CHLOE, "text": "(Des mains chaudes… Les Cœurs ont réchauffé les miennes. Tu avais tout prévu, hein ?)"})
	else:
		steps.append({"who": CHLOE, "text": "(« Des mains chaudes et un cœur patient. » Dans ma sacoche, les Cœurs sont tièdes…)"})
	return steps


## Page 27, in the sanctuary: the fourth Cœur and its guardian, « Toupet ».
static func _page_27() -> Array:
	var steps: Array = [
		{"text": "Au pied de la statue de glace, glissée sous une griffe sculptée, une page du journal."},
		{"letter": ["Le quatrième Cœur",
			"Le Cryolophosaure ne m'a pas chargée. Il m'a regardée trois jours sans bouger, du haut de sa paroi de glace.",
			"Le quatrième jour, il est descendu. Il a soufflé sur l'autel jusqu'à ce que la glace s'ouvre ; j'y ai posé le Cœur, et il l'a refermée de la même façon.",
			"Il a une crête toute droite en travers de la tête, comme une coiffure du dimanche. Anselme l'a appelé « Toupet ». Je crois qu'il ne le lui a jamais pardonné."],
			"sign": "— H."},
		{"flag": &"found_journal_27"},
	]
	if Game.flag(&"coeur_4"):
		steps.append({"who": CHLOE, "text": "(Toupet… Je ne l'appellerai jamais comme ça devant lui.)"})
	else:
		steps.append({"who": CHLOE, "text": "(Un Cryolophosaure qui souffle sur la glace… Il est encore là ?)"})
	return steps


## Page 28, at the col: Anselme knows (he watches the seal; he keeps quiet).
static func _page_28() -> Array:
	var steps: Array = [
		{"text": "Sous une grosse pierre plate, à l'abri du vent, une boîte en fer. Dedans, une page du journal."},
		{"letter": ["Anselme sait",
			"Ce soir, au col, j'ai tout dit à Anselme : le sceau qui s'use, le volcan qui gronde, et ce que je ferai s'il le faut.",
			"Je lui ai fait promettre : si je disparais, il surveillera le sceau, chaque nuit, et il n'en parlera à personne. Pas même à Chloé : elle aura bien assez à porter.",
			"Il a dit oui. Puis il a boudé jusqu'à la vallée, et il a mangé la moitié de ma soupe.",
			"Si tu lis ceci, Chloé, c'est qu'il a tenu parole. Ne lui en veux pas. Il ment très mal : c'est pour ça qu'il se tait."],
			"sign": "— H."},
		{"flag": &"found_journal_28"},
	]
	if Game.flag(&"roc_innocente"):
		steps.append({"who": CHLOE, "text": "(Tout ce que Roc m'a dit est vrai. Il ment très mal… c'est pour ça qu'il se taisait.)"})
	else:
		steps.append({"who": CHLOE, "text": "(Roc… Alors ses sorties de nuit, sa lanterne, la cendre sur ses chaussures… Il surveillait le sceau. Pour elle.)"})
		steps.append({"who": CHLOE, "text": "(Et moi qui l'ai soupçonné. Il faut que je le voie.)"})
	return steps


## Page 29, on the glacier: her burnt hands, the ice, the Cryolophosaure standing by her.
static func _page_29() -> Array:
	var steps: Array = [
		{"text": "Coincée entre deux blocs de glace bleue, dans une fiole bouchée, une page du journal."},
		{"letter": ["Brûlures",
			"Un mois après la nuit du feu, mes mains brûlent encore. Rien ne les calme, sauf la glace.",
			"Alors je monte ici et je les pose à plat sur le glacier, jusqu'à ne plus les sentir. Anselme dit que je vais les perdre. Je lui réponds que je les ai déjà presque perdues.",
			"Hier, un grand Cryolophosaure est descendu me regarder faire. Il est resté debout à côté de moi toute la nuit, face au vent, comme un mur.",
			"Je crois qu'il voulait que j'aie moins froid. Personne ne le lui avait demandé."],
			"sign": "— H."},
		{"flag": &"found_journal_29"},
	]
	if Game.flag(&"bertille_vue"):
		steps.append({"who": CHLOE, "text": "(Ses mains… Bertille m'a dit qu'elle avait toujours froid aux mains. Toujours.)"})
	else:
		steps.append({"who": CHLOE, "text": "(« La nuit du feu »… Ses mains ne s'en sont jamais remises.)"})
	return steps


## Page 30, in the valley, the first clear night: the forges at the foot of the volcano.
static func _page_30() -> Array:
	var steps: Array = [
		{"text": "Au bord du chemin, à demi enfouie dans la neige, une boîte en fer, et dedans une page du journal."},
		{"letter": ["Les forges",
			"Cette nuit, depuis l'abri de Bertille, j'ai compté les feux au pied du volcan. Sept. L'hiver dernier, il y en avait trois.",
			"Ce ne sont pas des feux de bergers : personne ne garde de troupeaux sur la cendre. Ce sont des forges. On y brûle l'ambre, et je sais trop bien ce qui en sort.",
			"Quelqu'un refait ce que j'ai brûlé, en plus grand. Demain, je descends voir de plus près.",
			"Bertille dit que je suis folle. Elle m'a tricoté une troisième paire de moufles."],
			"sign": "— H."},
		{"flag": &"found_journal_30"},
		{"who": CHLOE, "text": "(Sept feux, il y a deux ans… Combien, aujourd'hui ?)"},
	]
	if Game.flag(&"sbire_camp_2_battu"):
		steps.append({"who": CHLOE, "text": "(Le sbire à la lanterne, dans la Forêt : « des bottes pleines de cendre des forges du volcan ». Les forges de l'Ombre Noire.)"})
	return steps


# ------------------------------------------------------------------ chatter

## The chapter's lines for someone's chatter pool (DialogueDB.chatter): a new pool, `pool` with
## them inserted (first: the most urgent) or added; or the chapter's own pool, when nothing
## else sounds right any more (Isaure and Maïa, once Maïa has asked her mother).
static func chatter(who: StringName, pool: Array) -> Array:
	var out := pool.duplicate()
	match who:
		&"isaure":
			if not Game.flag(&"monts_arrivee"):
				return out
			var own: Array = [
				"Maïa est rentrée, l'autre nuit. Elle m'a attendue dans la cuisine, avec des questions plein les yeux. … Je n'ai pas su y répondre.",
				"Les Monts Gelés ? Couvre-toi, moussaillon. Là-haut, le froid ne prévient pas.",
				"La mer est calme, ce soir. Je voudrais pouvoir en dire autant de tout le reste.",
			]
			if Game.flag(&"maia_alliee"):
				own = [
					"Maïa est passée prendre son bonnet. Elle m'a dit bonjour. Juste bonjour. … C'est déjà ça.",
					"Il paraît que vous faites équipe, toutes les deux. Prends soin d'elle, moussaillon. Elle a mon courage. Et pas assez de prudence.",
				]
			if Game.flag(&"sceau_monts"):
				own.insert(0, "Quatre Cœurs, déjà… Prends garde aux hauteurs, moussaillon. Plus on monte, plus on tombe de haut.")
			return own
		&"roc":
			if Game.flag(&"monts_arrivee") and not Game.flag(&"roc_innocente"):
				out.insert(0, "Les Monts Gelés ? Prends des baies. Et une écharpe. Surtout une écharpe.")
			if Game.flag(&"roc_innocente"):
				out.insert(0, "Tu me regardes autrement, depuis le col. Ça me fait drôle. Ça me fait du bien, aussi.")
				out.append("Je sors encore la nuit, tu sais. Mais maintenant, quand je rentre, je te laisse un mot sur la table. C'est plus poli.")
			if Game.flag(&"coeur_4"):
				out.insert(0, "Quatre Cœurs dans la même sacoche… Garde-la contre toi, Chloé. Même quand tu dors. Surtout quand tu dors.")
		&"maia_havre":
			if Game.flag(&"maia_alliee"):
				return [
					"Je repars aux Monts. Joss m'a cousu un manteau à ma taille. Il dit que c'est son meilleur. Il dit ça à chaque fois.",
					"Caillou a mangé mon bonnet. Le deuxième. Je crois qu'il a froid aux cornes.",
					"Toi et moi, dans les Cieux. Ça va être le défi le plus stylé de toute l'histoire. Sauf que ce n'est pas un défi. C'est mieux.",
				]
	return out
