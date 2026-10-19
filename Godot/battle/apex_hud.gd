extends RefCounted
## Le dernier combat (ApexEngine) dans la roue de BattleHud : le bouton « Sceaux », à la place de Fuir (règle
## « sceaux »), et sa liste : un Sceau par carte (son image, l'Alpha qu'il appelle, ce qu'il fait), grisé une fois
## venu (« Déjà venu »). Et l'Ambre clair au Sac tant qu'il attend les deux tiers du calme (antidote_min_calm) : sa
## carte le dit (« Quand il écoute ») et la toucher ne coûte rien (Chloé range la fiole). Préchargé par battle_hud.gd.

const PARTS := preload("res://battle/hud_parts.gd")
const APEX_ENGINE := preload("res://battle/apex_engine.gd")
const COLOUR := Color(0.8, 0.56, 0.16)
const CARD_TOP := Color(0.36, 0.26, 0.08, 0.95)
const ICON := "sceau_volcan"


## Ce combat a-t-il la commande « Sceaux » ?
static func has_sceaux(engine: BattleEngine) -> bool:
	return engine is APEX_ENGINE and (engine as APEX_ENGINE).sceaux


## Peut-on appeler un Alpha maintenant ?
static func can_call_any(engine: BattleEngine) -> bool:
	return has_sceaux(engine) and (engine as APEX_ENGINE).can_call_any()


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
	var engine := hud.get(&"engine") as APEX_ENGINE
	for s: Dictionary in engine.owned_sceaux():
		grid.add_child(_card(hud, engine, s))


static func _card(hud: Control, engine: APEX_ENGINE, s: Dictionary) -> Button:
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
	var ready := engine.can_call(id)
	row.add_child(PARTS.two_lines(s["name"], s["what"] if ready else "Déjà venu"))
	card.pressed.connect(func() -> void: hud.emit_signal(&"chosen", {"type": "sceau", "id": id}))
	PARTS.enable_card(card, ready)
	return card
