extends RefCounted
## Le dernier combat (ApexEngine) dans la roue de BattleHud : le bouton « Sceaux », à la place de Fuir (règle
## « sceaux »), et sa liste : un Sceau par carte (son image, l'Alpha qu'il appelle, ce qu'il fait), grisé une fois
## venu (« Déjà venu »). Et l'Ambre clair au Sac tant qu'il attend les deux tiers du calme (antidote_min_calm) : sa
## carte le dit (« Quand il écoute ») et la toucher ne coûte rien (Chloé range la fiole). Préchargé par battle_hud.gd.
## Après la fin, les Sceaux libres (BattleEngine.libres, ApexEngine.Libres : mêmes questions) : le bouton à la place de
## Fuir dans un combat sans fuite (dresseurs, Alphas) ; dans un combat sauvage, Fuir reste et les Sceaux sont au Sac
## (une carte « Sceaux » qui ouvre leur liste : la roue n'a que quatre places).

const PARTS := preload("res://battle/hud_parts.gd")
const APEX_ENGINE := preload("res://battle/apex_engine.gd")
const COLOUR := Color(0.8, 0.56, 0.16)
const CARD_TOP := Color(0.36, 0.26, 0.08, 0.95)
const ICON := "sceau_volcan"


## Ce combat a-t-il la commande « Sceaux » ? (le dernier combat ; après la fin, tout combat où un Sceau s'est éveillé)
static func has_sceaux(engine: BattleEngine) -> bool:
	return (engine is APEX_ENGINE and (engine as APEX_ENGINE).sceaux) or engine.get(&"libres") != null


## Le bouton rond, à la place de Fuir : au dernier combat, et dans les combats sans fuite.
static func on_wheel(engine: BattleEngine, rules: Dictionary) -> bool:
	return has_sceaux(engine) and (engine.get(&"libres") == null or not rules.get("run", true))


## Dans un combat sauvage (Fuir reste) : les Sceaux au Sac.
static func in_bag(engine: BattleEngine, rules: Dictionary) -> bool:
	return has_sceaux(engine) and not on_wheel(engine, rules)


## Qui tient la liste : les Sceaux libres, sinon le dernier combat (mêmes questions : owned_sceaux, can_call, why_not).
static func _source(engine: BattleEngine) -> Object:
	var libres = engine.get(&"libres")
	return libres if libres != null else engine


## Peut-on appeler un Alpha maintenant ?
static func can_call_any(engine: BattleEngine) -> bool:
	return has_sceaux(engine) and _source(engine).can_call_any()


## L'Ambre clair est-il au Sac, prêt ou pas encore (au dernier combat) ?
static func antidote_shown(engine: BattleEngine) -> bool:
	if engine is APEX_ENGINE:
		return (engine as APEX_ENGINE).antidote_waits()
	return engine.can_use_antidote()


## Le dessous de sa carte : prêt, ou pas encore.
static func antidote_detail(engine: BattleEngine) -> String:
	return "Efface ses veines" if engine.can_use_antidote() else "Quand il écoute"


static func button() -> PARTS.RoundButton:
	return PARTS.round_button(COLOUR, ItemsDB.icon(ICON), "Sceaux", 78.0, "sceaux")


## La liste des Sceaux de Chloé (`grid` du panneau `panel` de `hud`, le BattleHud : son signal « chosen »).
static func fill(hud: Control, panel: Control, grid: GridContainer) -> void:
	panel.get_meta(&"title").text = "Appeler un Alpha"
	var source := _source(hud.get(&"engine"))
	for s: Dictionary in source.owned_sceaux():
		grid.add_child(_card(hud, source, s))


## Au Sac d'un combat sauvage : une carte « Sceaux » qui ouvre leur liste.
static func bag_card(hud: Control) -> Button:
	var card := PARTS.card_button(CARD_TOP, PARTS.INK_BOTTOM, PARTS.GOLD, "sac_sceaux")
	var row: HBoxContainer = card.get_meta(&"row")
	var icon := TextureRect.new()
	icon.texture = ItemsDB.icon(ICON)
	icon.custom_minimum_size = Vector2(54, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var ready := can_call_any(hud.get(&"engine"))
	row.add_child(PARTS.two_lines("Sceaux", "Appeler un Alpha" if ready else "Reviennent demain"))
	card.pressed.connect(func() -> void: hud.call(&"show_panel", "sceaux"))
	PARTS.enable_card(card, ready)
	return card


static func _card(hud: Control, engine: Object, s: Dictionary) -> Button:
	var id: String = s["id"]
	var card := PARTS.card_button(CARD_TOP, PARTS.INK_BOTTOM, PARTS.GOLD, "sceau:%s" % id)
	var row: HBoxContainer = card.get_meta(&"row")
	var icon := TextureRect.new()
	icon.texture = ItemsDB.icon(id)
	icon.custom_minimum_size = Vector2(54, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var ready: bool = engine.can_call(id)
	row.add_child(PARTS.two_lines(s["name"], s["what"] if ready else engine.why_not(id)))
	card.pressed.connect(func() -> void: hud.emit_signal(&"chosen", {"type": "sceau", "id": id}))
	PARTS.enable_card(card, ready)
	return card
