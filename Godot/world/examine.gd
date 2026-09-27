class_name Examine
## What Chloé says about the things around her that are not part of a quest (a closed house,
## a barrel, a crate, the Cabinet's furniture…): A in front of one shows a line; talking to
## the same thing again gives the next one, so nothing repeats straight away. A line is
## "text", or [text, flag] shown only once that story flag is set, or [text, "!" + flag]
## only while it is not; several conditions joined by "&".

const LINES := {
	# Port-Ambre: the houses are shut (the port is dying: see docs/lore.md).
	"maison_blanche": [
		"La maison des Le Goff. Volets clos. Ils sont partis sur le continent l'hiver dernier, comme beaucoup.",
		"Sur la porte, un mot punaisé : « Parti pêcher. Revenu bredouille. Reparti. »",
		"Personne. Juste un vieux chat sur le rebord, qui fait semblant de ne pas te voir.",
	],
	"maison_jaune": [
		"Ça sent la soupe de poisson. Une voix derrière la porte : « C'est pas le jour des visites ! »",
		"Tu frappes. « J'AI DIT : C'EST PAS LE JOUR DES VISITES ! »",
		"Par la fenêtre, une vieille dame tricote une écharpe interminable. Elle te fait coucou. Mais elle n'ouvre pas.",
	],
	"maison_port": [
		"La maison des Kerval, avec la cloche du port. Fermée à clé : Isaure est sur le quai, et Maïa… n'importe où.",
		"Sur le seuil, une paire de bottes de marin. Les semelles sont grises de cendre.",
		"Une carte marine est punaisée derrière la vitre. Quelqu'un a tracé au crayon un chemin à travers les récifs du nord.",
	],
	"barque": [
		"Une barque de pêche. Les filets sont secs : elle n'est pas sortie depuis longtemps.",
		"Au fond de la barque, une écope, un vieux gant et un crabe qui a l'air d'avoir élu domicile.",
	],
	"caisses": [
		"Des caisses vides. Enfin, pas tout à fait : il y reste une odeur de poisson très, très ancienne.",
		"« AMBRE — FRAGILE ». La caisse est vide, et le couvercle a été forcé.",
	],
	"tonneau": ["Un tonneau d'eau de pluie. Ton reflet te fait une grimace.", "Il sonne creux. Tout sonne creux, dans ce port."],
	"filet": [
		"Un filet troué. Les trous ont la forme d'un gros poisson qui n'avait pas envie d'être pêché.",
		"Quelqu'un a commencé à le raccommoder, puis a abandonné au milieu. Le nœud attend toujours.",
	],
	"casiers": [
		"Des casiers à homards. Vides. Même les homards sont partis.",
		"Dans un casier, un petit crabe a installé ses affaires. Il te regarde comme une propriétaire.",
	],
	"cordage": [
		"Un cordage enroulé avec un soin maniaque. Quelqu'un ici tient encore à ses nœuds.",
		"Un nœud de chaise, un nœud de cabestan, un nœud… que personne ne sait défaire. Même pas son auteur.",
	],
	"sechoir": [
		"Un séchoir à poissons, sans poissons. Le vent y fait sécher des idées noires.",
		"Une seule sardine y pend encore, toute raide. Elle a l'air très fière d'avoir tenu.",
	],
	"ancre": [
		"Une ancre énorme, couverte de coquillages. Elle ne retient plus rien, sauf les enfants qui grimpent dessus.",
		"Gravé dans le métal : « Le Vaillant ». Le bateau a disparu depuis longtemps. L'ancre, elle, est restée.",
	],
	"bitte": [
		"Une bitte d'amarrage. Maïa affirme qu'elle a sauté par-dessus, un jour. D'une traite.",
		"Le métal est poli à force d'amarres. Aujourd'hui, plus rien n'y est attaché.",
	],
	"lanterne": [
		"Une lanterne de rue. L'huile sent l'ambre : au port, on éclaire les rues avec des éclats trop petits pour être vendus.",
		"Un papillon de nuit tourne autour, obstiné. Il est là tous les soirs, paraît-il.",
	],
	"bac_fleurs": [
		"Des fleurs arrosées avec soin, malgré tout. Quelqu'un croit encore au printemps.",
		"Une petite étiquette plantée dans la terre : « Ne pas manger. (Toi aussi, Caillou.) »",
	],
	# The Cabinet.
	"bureau": [
		"Le bureau de Roc : des notes en pattes de mouche, trois tasses de café froid et une loupe.",
		"Un des tiroirs est fermé à clé. Roc a posé sa main dessus, l'air de rien, quand tu t'en es approchée.",
	],
	"bibliotheque": [
		"Des carnets reliés de cuir, le nom d'Hélène sur chaque dos. Il en manque plusieurs : des trous comme des dents arrachées.",
		"« Réveils, tome 3 ». « Habitats, tome 1 ». « Idées idiotes (ne pas faire) », tome 2. Le tome 1 manque.",
	],
	"couveuse": [
		["Trois œufs dorment dans la couveuse, tièdes comme des pains sortis du four.", "!starter"],
		["Sur chaque œuf, une étiquette de la main d'Hélène : « Vif », « Bastion », « Écho ». Et, en tout petit : « pour C. »", "!starter"],
		["La couveuse ronronne doucement. Elle est vide, mais elle garde la chaleur, au cas où.", "starter"],
		["Sur la vitre, trois petites traces de museau. Personne n'a eu le cœur de les essuyer.", "starter"],
		["Un thermomètre marque « tiède ». Au crayon, dessous : « comme Hélène aimait ».", "starter"],
		["Tout au fond de la couveuse, une page pliée brille doucement.", "roc_parti_vu&!found_journal_6"],
	],
	"fauteuil": [
		"Le fauteuil d'Hélène, creusé à sa forme. Roc ne s'y assoit jamais.",
		"Sur l'accoudoir, une tache de thé. Roc a posé un napperon dessus, comme pour la garder.",
	],
	"lampe": [
		"Une lampe à abat-jour d'ambre. La lumière qu'elle donne a la couleur des fins d'après-midi.",
		"L'abat-jour est taillé dans un seul morceau d'ambre. Une minuscule fourmi y dort depuis des millions d'années.",
	],
	"etabli": [
		"Des fioles, un alambic, et une étiquette : « NE PAS BOIRE (Anselme, c'est pour toi) ».",
		"Un carnet ouvert : « Essai n° 47 : l'ambre chauffé chante. L'ambre noir, lui, crie. Ne JAMAIS recommencer. » — H.",
	],
	"fougere_pot": [
		["Une fougère en pot, bien verte.", "!lunettes_rendues"],
		["La fougère à qui Roc parlait quand il avait perdu ses lunettes. Elle a l'air vexée qu'il ait arrêté.", "lunettes_rendues"],
		"Une de ses frondes se déroule, très lentement. Elle a tout le temps : elle est plus vieille que le Cabinet.",
	],
	# The Plaines and the caves.
	"rocher": [
		"Un gros rocher. Il n'a rien à dire, et il le dit très bien.",
		"Quelqu'un a gravé dessus « H + A ». Hélène et Anselme ? Ou quelqu'un d'autre, qui sait.",
	],
	"souche": [
		"Une vieille souche. Des champignons y ont fondé un village.",
		"En collant l'oreille, on entend des insectes discuter. Ils ont l'air très occupés.",
	],
	"stalagmite": [
		"Une stalagmite. Elle grandit d'un doigt tous les cent ans. Elle a donc tout son temps.",
		"Une goutte tombe du plafond, pile dessus. Ploc. Encore cent ans de patience.",
	],
	"cristaux": [
		"Des cristaux d'ambre pris dans la roche. Ils pulsent, très lentement, comme s'ils respiraient.",
		"En approchant la main, on sent une chaleur douce. L'ambre de l'île n'est jamais tout à fait froid.",
	],
	"rocher_grotte": [
		"Un bloc tombé du plafond. Mieux vaut ne pas se demander quand.",
		"Des traces de pioche sur la roche. Récentes. Quelqu'un cherchait de l'ambre, ici.",
	],
	# La Forêt Jurassique.
	"fougere_geante": [
		"Une fougère géante, sûrement aussi vieille que la forêt elle-même. Ses frondes bruissent même sans un souffle de vent.",
		"Hélène l'avait dessinée dans un carnet, avec une seule note en marge : « Ne pas grimper dedans. » On se demande pourquoi cette précision.",
		"Un escargot minuscule fait le tour du tronc, très sérieusement. À ce rythme, il y sera encore l'an prochain.",
	],
	"tronc_mousse": [
		"Un tronc couché, tapissé de mousse. Il est tombé il y a si longtemps que la forêt a fini par le recouvrir de vert, tout doucement.",
		"En s'approchant, on entend un léger grattement à l'intérieur. Mieux vaut ne pas savoir qui a emménagé.",
		"De petits champignons ont poussé dessus, bien alignés. On dirait qu'ils attendent l'autobus.",
	],
	"champignons": [
		"Une touffe de champignons serrés les uns contre les autres. Un vrai petit village, avec leurs chapeaux en guise de toits.",
		"Hélène notait toujours leurs noms savants. Chloé préfère les siens : Gros, Penché, et Le Timide.",
		"Plus loin, d'autres poussent en cercle. Un « rond de sorcière », disent les vieux du port. Chloé trouve surtout ça joli.",
	],
	"rocher_mousse": [
		"Un rocher si couvert de mousse qu'on devine à peine la pierre en dessous. On dirait un rocher qui a simplement renoncé.",
		"Au toucher, la mousse est étonnamment douce et fraîche. Un coin de canapé, en pleine forêt.",
		"Des fourmis y ont tracé une autoroute bien nette, d'un bord à l'autre. Priorité à droite, visiblement.",
	],
	"souche_geante": [
		"Une souche immense, large comme une table. On y compterait les années, s'il y en avait le temps.",
		"L'arbre a dû être gigantesque, avant de finir ainsi. Maïa jure qu'on pourrait y faire la sieste à quatre.",
		"Sur l'écorce, quelqu'un a gravé un « H », déjà à moitié effacé par la mousse.",
	],
	"arbre_geant": [
		"Un arbre gigantesque. Il faudrait sûrement dix personnes, bras tendus, pour en faire le tour.",
		"Les racines s'enfoncent si loin qu'on dirait qu'elles tiennent toute la forêt debout. Peut-être que c'est vrai.",
		"On raconte que Griffe-Grise vient parfois s'y appuyer, pour dormir debout comme le font les très vieilles bêtes.",
	],
	"os_dino": [
		"Un vieil os, à moitié enfoui dans l'herbe. Il appartenait à quelque chose de très grand, et probablement de très ancien.",
		"Hélène aurait sûrement voulu l'examiner pendant des heures, en prenant des notes totalement illisibles.",
		"Il y en a d'autres, plus loin, du côté du ravin. Mieux vaut ne pas trop se demander à qui ils appartenaient.",
	],
}
## Reach for the big ones (px from their origin, the middle of their foot).
const REACH := {"maison_blanche": 90.0, "maison_jaune": 90.0, "maison_port": 90.0, "barque": 40.0, "arbre_geant": 60.0}

## Lines already shown, per thing (zone + position): the next one comes next time.
static var _seen := {}
static var _last := {}   # per thing: its last line, so it never says it twice in a row


static func has(kind: String) -> bool:
	return LINES.has(kind)


static func look(prop: Prop, player: Player) -> void:
	player.face_towards(prop.global_position)
	var lines: Array = LINES[prop.kind].filter(_allowed)
	if lines.is_empty():
		return
	var key := "%s:%d:%d" % [Game.region_id, roundi(prop.position.x), roundi(prop.position.y)]
	var n: int = _seen.get(key, 0)
	_seen[key] = n + 1
	var line: Variant = lines[n % lines.size()]
	var text: String = line if line is String else line[0]
	if text == _last.get(key, "") and lines.size() > 1:   # the lines allowed have changed meanwhile
		line = lines[(n + 1) % lines.size()]
		text = line if line is String else line[0]
	_last[key] = text
	await Dialogue.run([{"text": text}])


static func _allowed(line: Variant) -> bool:
	if line is String:
		return true
	for cond: String in String(line[1]).split("&"):
		if _is_set(cond.trim_prefix("!")) == cond.begins_with("!"):
			return false
	return true


## A flag may hold a word (the starter's species) or a number: set = anything but empty.
static func _is_set(id: String) -> bool:
	var v: Variant = Game.flag(StringName(id))
	return not (v == null or (v is bool and not v) or (v is String and v == "") or (v is int and v == 0))
