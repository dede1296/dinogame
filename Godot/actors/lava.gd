class_name Lava
extends RefCounted
## La lave (chapitre 8, la Plaine Volcanique : mécanique B, docs/chapitre-8-scenes.md § 7 b). Les
## coulées arrêtent Chloé à pied ; elles se franchissent sur le dos du **dino de tête** s'il est de
## type Pierre ou Feu (capacité ABILITY « Cuir de feu » : cuirassés, pachycéphalosaures, grands
## théropodes ; adulte), comme la nage sur le dos d'un Baryonyx : rien à presser, elle avance sur la
## coulée et monte sur son dos (Player.lava_walker), elle en redescend sur la roche.
## Où est la lave : sur la racine de la zone (Region), la méta META (une Image, une case par pixel,
## blanc = lave, comme le relief), et/ou META_CELLS (des Rect2i en cases) ; META_RETREAT : de la lave
## que personne ne franchit tant que le drapeau RETREAT_FLAG (ou META_RETREAT_FLAG) est faux (le chemin
## du cratère, qui se retire « comme une marée »). Contrat : scratchpad ch8/contrat_lave.md.
## La physique (les murs de lave, la distance à la lave pour la chaleur) : LavaField, nœud LAYER_NODE
## ajouté à la zone la première fois qu'on la consulte. La chaleur légère près des coulées : Heat.

const META := &"lave"
const META_CELLS := &"lave_cases"
const META_HEAT := &"chaleur"
const META_RETREAT := &"lave_retrait"
const META_RETREAT_FLAG := &"lave_retrait_drapeau"
const RETREAT_FLAG := &"lave_retiree"
const ABILITY := &"cuir_de_feu"
const FLAG_CROSSED := &"lave_franchie"
## Couche physique 6 (« lave ») : Chloé la retire de son masque quand elle peut passer.
const LAYER := 32
const LAYER_NODE := &"Lave"
## × sa vitesse de marche sur le dos de son dino, sur la coulée : des pas prudents.
const SPEED := 0.95
const CHLOE := "Chloé"
## Les deux types qui n'ont pas peur du feu, et leurs mots.
const TYPES := {"pierre": "Pierre", "feu": "Feu"}
const NOBODY := "Les Saichania des coulées refroidies, de jour, ont le cuir pour. Et Fournaise, si on le retrouve."


## La zone a-t-elle de la lave (une des métas) ?
static func has_lava(region: Node) -> bool:
	if region == null:
		return false
	return region.has_meta(META) or region.has_meta(META_CELLS) or region.has_meta(META_RETREAT)


## La lave de la zone (construite la première fois), ou null s'il n'y en a pas.
static func field(region: Node) -> LavaField:
	if not has_lava(region):
		return null
	var f := region.get_node_or_null(NodePath(String(LAYER_NODE))) as LavaField
	if f == null:
		f = LavaField.new()
		f.name = String(LAYER_NODE)
		f.setup(region)
		region.add_child(f)
	return f


## Y a-t-il de la lave (franchissable ou non) à cette position du monde ?
static func at(region: Node, world_pos: Vector2) -> bool:
	var f := field(region)
	return f != null and f.is_lava(world_pos)


## Combien la lave est proche de cette position, pour le son (0 : à plus de LavaField.REACH_TILES
## cases ; 1 : dessus) : le crépitement du feu de l'ambiance la suit (World._hear_surroundings).
static func near(region: Node, world_pos: Vector2) -> float:
	var f := field(region)
	if f == null or f.cell_count() == 0:
		return 0.0
	return clampf(1.0 - f.distance_tiles(world_pos) / (LavaField.REACH_TILES + 1.0), 0.0, 1.0)


## Le dino qui porte Chloé sur la lave : le dino de tête s'il a le Cuir de feu (adulte), sinon null.
static func walker() -> Dino:
	var lead := Game.lead_dino()
	return lead if lead and Abilities.usable(lead, ABILITY) else null


static func can_cross() -> bool:
	return walker() != null


## « Pierre » ou « Feu » (le type de `d`, s'il est l'un des deux), sinon "".
static func type_word(d: Dino) -> String:
	return TYPES.get(d.type(), "")


## Le dialogue `lave_bloquee` : la coulée, la pensée de Chloé, puis qui pourrait (dans l'équipe, au
## Cabinet), ou à défaut les Saichania et Fournaise.
static func blocked_lines() -> Array:
	return [
		{"text": "La coulée barre tout le passage. Rouge, lente, et bien trop chaude pour qu'on l'approche."},
		{"who": CHLOE, "text": "(Il me faut un dino de pierre ou de feu en tête : un cuirassé, ou un grand théropode qui n'a pas peur du feu.)"},
		{"text": who_could()},
	]


## Qui, dans l'équipe ou au Cabinet, a le cuir pour (nom et type), et quoi faire.
static func who_could() -> String:
	var lead := Game.lead_dino()
	if lead and Abilities.has(lead, ABILITY) and not Abilities.usable(lead, ABILITY):
		return "%s a le cuir pour, mais il est encore trop jeune pour te porter : il faut qu'il soit adulte (niv. %d)." % [
			lead.nickname, Abilities.ADULT_LEVEL]
	for d in Game.party:
		if d != lead and Abilities.usable(d, ABILITY):
			return "%s (%s) a le cuir pour : mets-le en tête de l'équipe (son portrait : « Dino actif », ou le Dinodex : « En tête »)." % [
				d.nickname, type_word(d)]
	for d in Game.box:
		if Abilities.usable(d, ABILITY):
			return "%s (%s) a le cuir pour, mais il attend au Cabinet : va le chercher, et mets-le en tête." % [d.nickname, type_word(d)]
	return NOBODY


## Le dialogue `lave_franchie` (une fois) : Chloé sur le dos de `d`, la croûte qui tient.
static func crossed_lines(d: Dino) -> Array:
	var n := d.nickname
	return [
		{"text": "Chloé monte sur le dos de %s. Il avance vers le rouge sans ralentir, et pose une patte dessus : la croûte craque, siffle, et tient. Puis l'autre patte." % n},
		{"who": CHLOE, "text": "(Ne regarde pas en bas. Ne regarde pas en bas. … J'ai regardé en bas.)"},
		{"text": "La chaleur monte autour d'eux, mais %s ne la sent pas : il a le cuir pour. Chloé serre les genoux, et ils passent." % n},
		{"who": CHLOE, "text": "Merci. Non, vraiment : merci."},
	]


## Chloé pousse contre la coulée sans dino qui convienne : elle s'arrête, on lui dit pourquoi.
static func tell_blocked(player: Node) -> void:
	await _tell(player, blocked_lines())


## La toute première traversée : le drapeau, puis les mots.
static func tell_crossed(player: Node, d: Dino) -> void:
	if Game.flag(FLAG_CROSSED):
		return
	Game.set_flag(FLAG_CROSSED)
	await _tell(player, crossed_lines(d))


static func _tell(player: Node, lines: Array) -> void:
	if Dialogue.active:
		return
	player.set(&"busy", true)
	player.set(&"velocity", Vector2.ZERO)
	await Dialogue.run(lines)
	if is_instance_valid(player):
		player.set(&"busy", false)


## La méta META d'une zone depuis une image de carte (`png` : blanc = lave), sauvée à côté de la zone
## (`res`) comme son relief. Pour les générateurs tools/zones/volcan*.gd.
static func set_mask(root: Node, png: String, res: String) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(png))
	img.convert(Image.FORMAT_L8)
	ResourceSaver.save(img, res)
	root.set_meta(META, load(res))
