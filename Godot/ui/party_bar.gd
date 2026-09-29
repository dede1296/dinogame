class_name PartyBar
extends Control
## The party at a glance, top-left of the exploration screen: a round portrait per dino
## (the lead one bigger), an HP ring, an XP bar and the level. Experience gains pop up next
## to the portrait ("+12 xp", "Niv. 6 !"), and so does the Lien ("+1 ♥"). Tapping a portrait
## opens its menu (with its Lien, in hearts): make it the lead dino, give it a berry, or see
## its card. The game is paused while a menu is open. A portrait dragged onto another one
## (finger or mouse: DexTile, DinoDrag) swaps their places: onto the first, it leads, and the
## dino following Chloé changes. Not during a scene or a battle.

const LEAD_SIZE := 84.0
const SIZE := 62.0
const GAP := 12.0
const RING := 5.0
const REDRAW_S := 0.25
## Between two pop-ups of the same wave ("+12 xp", then "Niv. 6 !", "+1 ♥"), so each is read.
const POP_GAP_S := 0.45
const INK := Color(0.106, 0.122, 0.157, 0.92)
const CREAM := Color(1, 0.97, 0.9)
const AMBER := Color(0.98, 0.76, 0.35)
const XP_BLUE := Color(0.45, 0.75, 1.0)
const MENU_LAYER := 50   # over the HUD (quest tracker, buttons), under the settings

var _slots: Array[Control] = []
var _pending: Array = []   # [dino, text, colour] shown once the game runs again
var _redraw := 0.0
var _pop_wait := 0.0
var _menu: Control
var _menu_layer: CanvasLayer
var _drag: DinoDrag


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	var drag_layer := CanvasLayer.new()   # the carried portrait, over the whole HUD
	drag_layer.layer = MENU_LAYER
	add_child(drag_layer)
	_drag = DinoDrag.new()
	_drag.lift = 0.7   # (under the finger: the bar is at the top of the screen)
	drag_layer.add_child(_drag)
	Game.party_changed.connect(_rebuild)
	Game.xp_awarded.connect(_on_xp)
	Game.bond_changed.connect(_on_bond)
	get_viewport().size_changed.connect(_rebuild)
	_rebuild()


func _process(delta: float) -> void:
	_redraw += delta
	if _redraw >= REDRAW_S:
		_redraw = 0.0
		for s in _slots:
			s.queue_redraw()
	_pop_wait -= delta
	if _pop_wait <= 0.0 and not get_tree().paused and not _pending.is_empty():
		_pop_wait = POP_GAP_S
		var p: Array = _pending.pop_front()
		_popup(p[0], p[1], p[2])


func _rebuild() -> void:
	for s in _slots:
		s.queue_free()
	_slots.clear()
	_drag.clear_targets()
	var inset := SafeArea.insets(get_viewport())
	var x := inset.x
	for i in Game.party.size():
		var d: Dino = Game.party[i]
		var slot := Slot.new()
		slot.dino = d
		slot.lead = i == 0
		var size := LEAD_SIZE if i == 0 else SIZE
		slot.size = Vector2(size, size + 10.0)
		slot.position = Vector2(x, inset.y + (0.0 if i == 0 else (LEAD_SIZE - SIZE) * 0.5))
		slot.add_to_group(&"touch_blockers")
		slot.tapped.connect(_open_menu.bind(i))
		slot.draggable = true
		slot.drag = _drag
		slot.payload = {"kind": "party", "index": i}
		slot.picture = portrait(d.species())
		slot.can_drag = _can_reorder
		add_child(slot)
		_slots.append(slot)
		_drag.add_target(slot, func(p: Dictionary) -> bool: return p.get("index", -1) != i, _dropped_on.bind(i))
		x += size + GAP


## A portrait may be dragged: two dinos at least, no menu, no scene, no battle (paused).
func _can_reorder() -> bool:
	if Game.party.size() < 2 or _menu or get_tree().paused:
		return false
	var player = get_tree().get_first_node_in_group(&"player")
	return player == null or not player.get("busy")


## Portrait `payload` dropped on portrait `i`: they swap places.
func _dropped_on(payload: Dictionary, i: int) -> void:
	var lead := Game.lead_dino()
	if Game.swap_party(payload["index"], i) and Game.lead_dino() != lead:
		Toast.say(get_tree(), "%s passe en tête !" % Game.lead_dino().nickname)


func _slot_of(d: Dino) -> Control:
	for s in _slots:
		if s.dino == d:
			return s
	return null


# ------------------------------------------------------------------ gains

func _on_xp(d: Dino, amount: int, levels: int) -> void:
	_pending.append([d, "+%d xp" % amount, XP_BLUE])
	if levels > 0:
		_pending.append([d, "Niv. %d !" % d.level, AMBER])


func _on_bond(d: Dino, hearts: int) -> void:
	_pending.append([d, "+%d ♥" % hearts, DinoCard.BOND_PINK])


func _popup(d: Dino, text: String, colour: Color) -> void:
	var slot := _slot_of(d)
	if slot == null:
		return
	var pill := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(INK, 0.9)
	box.border_color = colour
	box.set_border_width_all(2)
	box.set_corner_radius_all(16)
	box.set_content_margin_all(6)
	box.content_margin_left = 12
	box.content_margin_right = 12
	pill.add_theme_stylebox_override("panel", box)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", colour)
	pill.add_child(label)
	add_child(pill)
	pill.position = slot.position + Vector2(slot.size.x + 6.0, slot.size.x * 0.3)
	pill.scale = Vector2(0.6, 0.6)
	var t := create_tween().set_parallel(true)
	t.tween_property(pill, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(pill, "position:y", pill.position.y - 22.0, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(pill, "modulate:a", 0.0, 0.5).set_delay(0.9)
	t.chain().tween_callback(pill.queue_free)
	if text.begins_with("Niv.") or text.ends_with("♥"):
		var bounce := create_tween()
		bounce.tween_property(slot, "scale", Vector2(1.18, 1.18), 0.12)
		bounce.tween_property(slot, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


# ------------------------------------------------------------------ menus

func _open_menu(index: int) -> void:
	if _menu or index >= Game.party.size():
		return
	var d: Dino = Game.party[index]
	var slot := _slots[index]
	_menu = _overlay()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	var panel := _panel(col)
	col.add_child(_title(d.nickname, "%s · niv. %d · %d/%d PV" % [d.species_name(), d.level, d.hp, d.max_hp()]))
	col.add_child(_bond_line(d))
	if index > 0:
		_menu_button(col, "Dino actif", Game.set_lead.bind(index))
	var berries := Game.item_count("baie")
	var heal := _menu_button(col, "Soigner (baie ×%d)" % berries if berries > 0 else "Pas de baie", _heal.bind(d))
	heal.disabled = berries <= 0 or d.hp >= d.max_hp()
	var ferns := Game.item_count("fougere")
	if ferns > 0:
		var fern := _menu_button(col, "Soin complet (fougère ×%d)" % ferns, _heal_fully.bind(d))
		fern.disabled = d.hp >= d.max_hp()
	_menu_button(col, "Fiche", _open_card.bind(d))
	_menu_button(col, "Fermer", func() -> void: pass)
	_menu.add_child(panel)
	panel.reset_size()
	var screen := get_viewport().get_visible_rect().size
	panel.position = Vector2(clampf(slot.position.x, 8.0, screen.x - panel.size.x - 8.0), slot.position.y + slot.size.y + 10.0)


## A menu button: closes the menu, then does `action`.
func _menu_button(col: Control, text: String, action: Callable) -> Button:
	var button := _button(text)
	button.pressed.connect(func() -> void:
		_close_menu()
		action.call())
	col.add_child(button)
	return button


func _heal(d: Dino) -> void:
	if Game.feed_berry(d):
		_popup(d, "+%d PV" % Game.BERRY_HP, Color(0.5, 0.9, 0.45))


func _heal_fully(d: Dino) -> void:
	var gained := Game.feed_fern(d)
	if gained > 0:
		_popup(d, "+%d PV" % gained, Color(0.5, 0.9, 0.45))


func _open_card(d: Dino) -> void:
	_menu = _overlay()
	var card := DinoCard.make(d)
	card.closed.connect(_close_menu)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(card)
	_menu.add_child(center)


## A full-screen layer over the whole HUD that pauses the game; a tap outside the panel
## closes it.
func _overlay() -> Control:
	get_tree().paused = true
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = MENU_LAYER
	_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu_layer)
	var layer := ColorRect.new()
	layer.color = Color(0, 0, 0, 0.3)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_menu())
	_menu_layer.add_child(layer)
	return layer


func _close_menu() -> void:
	if _menu:
		_menu.queue_free()
		_menu = null
	if _menu_layer:
		_menu_layer.queue_free()
		_menu_layer = null
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if _menu and event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		_close_menu()


func _panel(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = INK
	box.border_color = Color(0.79, 0.54, 0.16)
	box.set_border_width_all(3)
	box.set_corner_radius_all(18)
	box.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(300, 0)
	panel.add_child(content)
	return panel


func _title(text: String, sub: String) -> Control:
	var col := VBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", AMBER)
	col.add_child(l)
	var s := Label.new()
	s.text = sub
	s.add_theme_font_size_override("font_size", 17)
	s.add_theme_color_override("font_color", Color(CREAM, 0.8))
	col.add_child(s)
	return col


## "Lien" and its hearts (DinoCard.hearts).
func _bond_line(d: Dino) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = "Lien"
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Color(CREAM, 0.8))
	row.add_child(l)
	var h := DinoCard.hearts(d.bond, 20.0)
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(h)
	return row


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.45, 0.29, 0.08) if state == "pressed" else Color(0.16, 0.18, 0.22, 0.5 if state == "disabled" else 1.0)
		box.border_color = Color(0.79, 0.54, 0.16, 0.4 if state == "disabled" else 1.0)
		box.set_border_width_all(2)
		box.set_corner_radius_all(12)
		box.set_content_margin_all(10)
		b.add_theme_stylebox_override(state, box)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_disabled_color", Color(CREAM, 0.4))
	return b


# ------------------------------------------------------------------ portraits

static var _portraits: Dictionary = {}


## Round portrait of a species, cut from its side sheet around the head (cached).
static func portrait(species: DinoSpecies) -> Texture2D:
	if _portraits.has(species.id):
		return _portraits[species.id]
	var sheet := species.sheet.get_image()
	if sheet.is_compressed():
		sheet.decompress()
	sheet.clear_mipmaps()
	sheet.convert(Image.FORMAT_RGBA8)
	var cell := Vector2(sheet.get_width() / float(species.sheet_columns), sheet.get_height() / float(species.sheet_rows))
	var idle := species.idle_frames[0] if not species.idle_frames.is_empty() else 0
	var origin := Vector2(idle % species.sheet_columns, idle / species.sheet_columns) * cell
	# The head: top-right of a side view facing right.
	var side := int(minf(cell.x * 0.62, cell.y * 0.78))
	var from := Vector2i(origin + Vector2(cell.x - side - cell.x * 0.02, 0.0))
	var img := sheet.get_region(Rect2i(from, Vector2i(side, side)))
	var r := side / 2.0
	for y in side:
		for x in side:
			var dist := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			if dist > r - 1.0:
				var c := img.get_pixel(x, y)
				c.a *= clampf(r - dist, 0.0, 1.0)
				img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_portraits[species.id] = tex
	return tex


## One portrait of the bar.
## (A tap opens its menu; dragged, it swaps places: DexTile.)
class Slot extends DexTile:
	var dino: Dino
	var lead := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE
		pivot_offset = Vector2(size.x / 2.0, size.x / 2.0)

	func _draw() -> void:
		var d := size.x
		var c := Vector2(d, d) / 2.0
		var r := d / 2.0
		if dragging():   # carried away: only its place, faint
			draw_arc(c, r - 1.0, 0.0, TAU, 48, Color(PartyBar.AMBER, 0.6), 2.0, true)
			return
		var ko := dino.hp <= 0
		draw_circle(c + Vector2(0, 2), r, Color(0, 0, 0, 0.35))
		draw_circle(c, r, Color(0.2, 0.24, 0.2) if not ko else Color(0.2, 0.2, 0.2))
		var inner := r - PartyBar.RING - 1.0
		draw_texture_rect(PartyBar.portrait(dino.species()), Rect2(c - Vector2(inner, inner), Vector2(inner, inner) * 2.0), false,
			Color(1, 1, 1) if not ko else Color(0.45, 0.45, 0.45))
		# HP ring: full circle = full health, green → amber → red.
		var ratio := clampf(float(dino.hp) / maxf(dino.max_hp(), 1.0), 0.0, 1.0)
		var hp_colour := Color(0.4, 0.85, 0.4) if ratio > 0.5 else Color(0.95, 0.75, 0.2) if ratio > 0.2 else Color(0.92, 0.3, 0.25)
		draw_arc(c, r - PartyBar.RING / 2.0, 0.0, TAU, 48, Color(0, 0, 0, 0.55), PartyBar.RING, true)
		if ratio > 0.0:
			draw_arc(c, r - PartyBar.RING / 2.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 48, hp_colour, PartyBar.RING, true)
		if lead:
			draw_arc(c, r + 1.5, 0.0, TAU, 48, PartyBar.AMBER, 2.5, true)
		# XP bar under the portrait.
		var xp_ratio := clampf(float(dino.xp) / maxf(Dino.xp_to_next(dino.level), 1.0), 0.0, 1.0)
		var bar := Rect2(Vector2(d * 0.12, d + 4.0), Vector2(d * 0.76, 5.0))
		draw_rect(bar, Color(0, 0, 0, 0.55))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * xp_ratio, bar.size.y)), PartyBar.XP_BLUE)
		# Level badge.
		var badge := Vector2(d * 0.86, d * 0.84)
		draw_circle(badge, 13.0, PartyBar.INK)
		draw_arc(badge, 13.0, 0.0, TAU, 24, PartyBar.AMBER, 1.5, true)
		var font := get_theme_default_font()
		var text := str(dino.level)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(font, badge + Vector2(-w / 2.0, 5.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, PartyBar.CREAM)
