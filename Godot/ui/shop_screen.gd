class_name ShopScreen
extends CanvasLayer
## A shop of Havre-Doré (ItemsDB.SHOPS): buy, and sell what can be sold (the Comptoir also
## buys amber tears). Pièces at the top, one row per article: its picture, name, what it does,
## how many Chloé has, the price and a button. The game is paused meanwhile, to the shop tune.

signal closed

const LAYER := 80
const GOLD := Color(1, 0.86, 0.5)
const CREAM := Color(1, 0.97, 0.9)
const PANEL_WIDTH := 820.0
const ROW_HEIGHT := 78.0
const COINS_SFX := preload("res://assets/audio/sfx/coins.wav")
const BUMP_SFX := preload("res://assets/audio/sfx/bump.wav")
const TUNE := preload("res://assets/audio/music/boutique.ogg")
const COIN := preload("res://assets/art/ui/piece.png")

var shop_id: StringName
var _was_paused := false
var _selling := false
var _coins: Label
var _keeper: Label   # the shopkeeper's name, then what they say after a sale
var _rows: VBoxContainer
var _tabs: Array[Button] = []


static func open(parent: Node, id: StringName) -> ShopScreen:
	var shop := ShopScreen.new()
	shop.shop_id = id
	parent.get_tree().root.add_child(shop)
	return shop


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	Audio.push_music(TUNE, 0.4)
	_build()
	_fill()


func _build() -> void:
	var shop: Dictionary = ItemsDB.SHOPS[shop_id]
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.01, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.add_theme_stylebox_override("panel", SettingsMenu._box(SettingsMenu.INK, 22, 3, 18))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	col.add_child(head)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(_label(shop["name"], 28, GOLD))
	_keeper = _label(shop["keeper"], 16, Color(CREAM, 0.7))
	titles.add_child(_keeper)
	head.add_child(titles)
	var purse := HBoxContainer.new()
	purse.add_theme_constant_override("separation", 6)
	var coin := TextureRect.new()
	coin.texture = COIN
	coin.custom_minimum_size = Vector2(40, 40)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	purse.add_child(coin)
	_coins = _label("", 24, GOLD)
	purse.add_child(_coins)
	head.add_child(purse)
	var close := _button("✕", 26, Vector2(52, 52))
	close.pressed.connect(_close)
	head.add_child(close)

	if shop.get("sells", false):
		var tabs := HBoxContainer.new()
		tabs.add_theme_constant_override("separation", 8)
		for t: Array in [["Acheter", false], ["Vendre", true]]:
			var b := _button(t[0], 20, Vector2(160, 46))
			b.toggle_mode = true
			b.button_pressed = t[1] == _selling
			b.pressed.connect(func() -> void:
				_selling = t[1]
				for other in _tabs:
					other.button_pressed = other == b
				_fill())
			tabs.add_child(b)
			_tabs.append(b)
		col.add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 8)
	scroll.add_child(_rows)


func _fill() -> void:
	_coins.text = "%d pièces" % Game.coins()
	for r in _rows.get_children():
		r.queue_free()
	var shop: Dictionary = ItemsDB.SHOPS[shop_id]
	if not _selling:
		for id: String in shop["stock"]:
			var it := ItemsDB.item(id)
			var owned := Game.item_count(id)
			var kept: bool = it["kind"] == "cle" and owned > 0
			_rows.add_child(_row(ItemsDB.icon(id), it["name"], it["desc"], owned, it["price"], "Acheté" if kept else "Acheter",
				not kept and Game.coins() >= int(it["price"]), _buy.bind(id)))
		return
	var any := false
	if shop.get("tears", false) and Game.tears() > 0:
		any = true
		_rows.add_child(_row(load("res://assets/art/props/galet.png"), "Larme de l'île",
			"De l'Ambre-Mère. Ferréol en offre un bon prix… mais Roc les attend aussi.", Game.tears(), ItemsDB.TEAR_PRICE, "Vendre", true, _sell_tear))
	for id: String in ItemsDB.ITEMS:
		var it := ItemsDB.item(id)
		if int(it["sell"]) > 0 and Game.item_count(id) > 0:
			any = true
			_rows.add_child(_row(ItemsDB.icon(id), it["name"], it["desc"], Game.item_count(id), it["sell"], "Vendre", true, _sell.bind(id)))
	if not any:
		_rows.add_child(_label("Rien à vendre pour l'instant.", 18, Color(CREAM, 0.6)))


func _row(icon: Texture2D, title: String, desc: String, owned: int, price: int, action: String, enabled: bool, on_press: Callable) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	panel.add_theme_stylebox_override("panel", SettingsMenu._box(Color(0.16, 0.18, 0.22), 14, 1, 8, Color(SettingsMenu.AMBER, 0.5)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var pic := TextureRect.new()
	pic.texture = icon
	pic.custom_minimum_size = Vector2(60, 60)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	var name_row := HBoxContainer.new()
	name_row.add_child(_label(title, 20, CREAM))
	if owned > 0:
		name_row.add_child(_label("   ×%d" % owned, 16, Color(CREAM, 0.6)))
	text.add_child(name_row)
	var d := _label(desc, 14, Color(CREAM, 0.7))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(d)
	row.add_child(text)
	row.add_child(_label("%d p." % price, 20, GOLD))
	var b := _button(action, 18, Vector2(130, 52))
	b.disabled = not enabled
	b.pressed.connect(on_press)
	row.add_child(b)
	return panel


func _buy(id: String) -> void:
	var it := ItemsDB.item(id)
	if not Game.pay(int(it["price"])):
		Audio.play_sfx(BUMP_SFX)
		_say("Il te manque quelques pièces…")
		return
	Game.give_item(id)
	Audio.play_sfx(COINS_SFX)
	_say("« %s ? Bon choix. Merci ! »" % it["name"])
	_fill()


func _sell(id: String) -> void:
	if not Game.use_item(id):
		return
	Game.give_item("piece", int(ItemsDB.item(id)["sell"]))
	Audio.play_sfx(COINS_SFX)
	_say("« Marché conclu. »")
	_fill()


func _sell_tear() -> void:
	if Game.tears() <= 0:
		return
	Game.give_item("larmes_vendues")
	Game.give_item("piece", ItemsDB.TEAR_PRICE)
	Audio.play_sfx(COINS_SFX)
	_say("« Une larme d'ambre… Excellent. Rapporte-m'en d'autres. »")
	_fill()


## The shopkeeper answers under the shop's name.
func _say(text: String) -> void:
	_keeper.text = "%s : %s" % [ItemsDB.SHOPS[shop_id]["keeper"], text]
	_keeper.add_theme_color_override("font_color", GOLD)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()


func _close() -> void:
	if is_queued_for_deletion():
		return
	Audio.pop_music(0.6)
	Save.save_game()
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()


func _label(text: String, font_size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	return l


func _button(text: String, font_size: int, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_disabled_color", Color(CREAM, 0.35))
	b.add_theme_stylebox_override("normal", SettingsMenu._box(Color(0.2, 0.22, 0.27), 12, 2))
	b.add_theme_stylebox_override("hover", SettingsMenu._box(Color(0.25, 0.27, 0.32), 12, 2))
	b.add_theme_stylebox_override("pressed", SettingsMenu._box(Color(0.45, 0.29, 0.08), 12, 3, 0, Color(0.98, 0.76, 0.35)))
	b.add_theme_stylebox_override("disabled", SettingsMenu._box(Color(0.14, 0.15, 0.18), 12, 1, 0, Color(SettingsMenu.AMBER, 0.3)))
	return b
