class_name Examine
## What Chloé says about the things around her that are not part of a quest (a closed house,
## a barrel, a crate, the Cabinet's furniture…): A in front of one shows a line; talking to
## the same thing again gives the next one, so nothing repeats straight away. A line is
## "text", or [text, flag] shown only once that story flag is set, or [text, "!" + flag]
## only while it is not.

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
	"filet": ["Un filet troué. Les trous ont la forme d'un gros poisson qui n'avait pas envie d'être pêché."],
	"casiers": ["Des casiers à homards. Vides. Même les homards sont partis."],
	"cordage": ["Un cordage enroulé avec un soin maniaque. Quelqu'un ici tient encore à ses nœuds."],
	"sechoir": ["Un séchoir à poissons, sans poissons. Le vent y fait sécher des idées noires."],
	"ancre": ["Une ancre énorme, couverte de coquillages. Elle ne retient plus rien, sauf les enfants qui grimpent dessus."],
	"bitte": ["Une bitte d'amarrage. Maïa affirme qu'elle a sauté par-dessus, un jour. D'une traite."],
	"lanterne": ["Une lanterne de rue. L'huile sent l'ambre : au port, on éclaire les rues avec des éclats trop petits pour être vendus."],
	"bac_fleurs": ["Des fleurs arrosées avec soin, malgré tout. Quelqu'un croit encore au printemps."],
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
		["La couveuse ronronne doucement. Elle est vide, mais elle garde la chaleur, au cas où.", "starter"],
	],
	"fauteuil": ["Le fauteuil d'Hélène, creusé à sa forme. Roc ne s'y assoit jamais."],
	"lampe": ["Une lampe à abat-jour d'ambre. La lumière qu'elle donne a la couleur des fins d'après-midi."],
	"etabli": ["Des fioles, un alambic, et une étiquette : « NE PAS BOIRE (Anselme, c'est pour toi) »."],
	"fougere_pot": [
		["Une fougère en pot, bien verte.", "!lunettes_rendues"],
		["La fougère à qui Roc parlait quand il avait perdu ses lunettes. Elle a l'air vexée qu'il ait arrêté.", "lunettes_rendues"],
	],
	# The Plaines and the caves.
	"rocher": [
		"Un gros rocher. Il n'a rien à dire, et il le dit très bien.",
		"Quelqu'un a gravé dessus « H + A ». Hélène et Anselme ? Ou quelqu'un d'autre, qui sait.",
	],
	"souche": ["Une vieille souche. Des champignons y ont fondé un village."],
	"stalagmite": ["Une stalagmite. Elle grandit d'un doigt tous les cent ans. Elle a donc tout son temps."],
	"cristaux": ["Des cristaux d'ambre pris dans la roche. Ils pulsent, très lentement, comme s'ils respiraient."],
	"rocher_grotte": ["Un bloc tombé du plafond. Mieux vaut ne pas se demander quand."],
}
## Reach for the big ones (px from their origin, the middle of their foot).
const REACH := {"maison_blanche": 90.0, "maison_jaune": 90.0, "maison_port": 90.0, "barque": 40.0}

## Lines already shown, per thing (zone + position): the next one comes next time.
static var _seen := {}


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
	await Dialogue.run([{"text": line if line is String else line[0]}])


static func _allowed(line: Variant) -> bool:
	if line is String:
		return true
	var cond: String = line[1]
	return not Game.flag(StringName(cond.substr(1))) if cond.begins_with("!") else bool(Game.flag(StringName(cond)))
