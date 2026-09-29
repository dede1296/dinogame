class_name DexScreen
extends CanvasLayer
## The Dinodex, opened from its button (under the map's) or X / the right shoulder button,
## anywhere but in a battle or a scene; the game is paused meanwhile. Tabs: all the species,
## those of each region (« ??? » until Chloé has been there), the uniques of the story, the
## reserve. Each species is a tile (a black shape and « ??? » until seen); tapped, its sheet
## (DexEntry). On the right, the team: drag one of its dinos onto another to swap them (the
## first one leads: the dino on screen follows), a dino of the reserve onto the team to bring it
## in (the one there goes to the reserve), a dino of the team onto « Réserve » to leave it there
## (never the last one). The sheets have buttons for the same (keyboard, gamepad). In the water
## nobody leaves Chloé's side: `lock` says why the team cannot change now.

signal closed

const LAYER := 80
const GOLD := Color(1, 0.86, 0.5)
const CREAM := Color(1, 0.97, 0.9)
const TEAM_WIDTH := 172.0
const SLOT_HEIGHT := 80.0
const GAP := 8
const OPEN_SFX := preload("res://assets/audio/sfx/page.wav")
const SWAP_SFX := preload("res://assets/audio/sfx/latch.wav")
const NOTE_S := 3.2
## The pages: every species, a region (its id), the uniques, the reserve.
const ALL := &"all"
const UNIQUES := &"uniques"
const RESERVE := &"reserve"
## The Dinodex's key (a keyboard, a gamepad): added to the input map by ensure_action.
const ACTION := &"dex"

## Why the team cannot change now ("": it can).
var lock := ""
var drag: DinoDrag
var _tab: StringName = ALL
var _was_paused := false
var _changed := false
var _counts: Label
var _tab_row: HBoxContainer
var _tab_buttons := {}   # page -> Button
var _main: Control
var _team: VBoxContainer
var _reserve_button: Button
var _note: Label
var _note_tween: Tween
var _entry: StringName = &""   # the species whose sheet is shown (&"": the list)
var _entry_dino: Dino          # a dino of it to show first (tapped in the team, the reserve)
var _scroll_of := {}           # page -> how far its list was scrolled
var _list_scroll: ScrollContainer
var _chooser: Control


## Opens the Dinodex over the game (`lock`: see above).
static func open(parent: Node, lock_reason := "") -> DexScreen:
	var dex := DexScreen.new()
	dex.lock = lock_reason
	parent.get_tree().root.add_child(dex)
	return dex


## The Dinodex's key: X on a keyboard, the right shoulder on a gamepad (added here, not in the
## project settings, so that it is there wherever the Dinodex can open).
static func ensure_action() -> void:
	if InputMap.has_action(ACTION):
		return
	InputMap.add_action(ACTION, 0.5)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_X
	InputMap.action_add_event(ACTION, key)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_RIGHT_SHOULDER
	InputMap.action_add_event(ACTION, pad)


## The round « Dinodex » button of a HUD layer, under the map's (MapScreen.add_open_button).
static func add_open_button(hud: CanvasLayer, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.name = "DexButton"
	button.custom_minimum_size = Vector2(76, 76)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Dinodex (X)"
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, SettingsMenu._box(Color(SettingsMenu.INK, 0.7 if state == "normal" else 0.9), 38, 2))
	var icon := Control.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.draw.connect(draw_icon.bind(icon, Vector2(38, 38), 1.0))
	button.add_child(icon)
	hud.add_child(button)
	var place := func() -> void:
		var inset := SafeArea.insets(button.get_viewport())
		var screen := button.get_viewport().get_visible_rect().size
		button.position = Vector2(screen.x - inset.x - button.custom_minimum_size.x, inset.y + 172.0)
	place.call()
	button.get_viewport().size_changed.connect(place)
	button.pressed.connect(on_pressed)
	return button


## An open book with a dino's footprint on its right page, centred on `c`.
static func draw_icon(ci: CanvasItem, c: Vector2, k := 1.0) -> void:
	var cream := SettingsMenu.CREAM
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array([c + Vector2(0, -11) * k, c + Vector2(17 * side, -15) * k,
			c + Vector2(17 * side, 13) * k, c + Vector2(0, 16) * k])
		ci.draw_colored_polygon(pts, Color(cream, 1.0 if side > 0 else 0.78))
	ci.draw_line(c + Vector2(0, -11) * k, c + Vector2(0, 16) * k, Color(0.5, 0.36, 0.16), 2.0 * k)
	var foot := c + Vector2(9, 3) * k
	var amber := Color(0.79, 0.54, 0.16)
	ci.draw_circle(foot + Vector2(0, 3) * k, 3.2 * k, amber)
	for toe: Vector2 in [Vector2(-4, -3), Vector2(0, -5), Vector2(4, -3)]:
		ci.draw_line(foot, foot + toe * k, amber, 2.2 * k, true)
	for i in 3:
		ci.draw_line(c + Vector2(-14, -6 + i * 6) * k, c + Vector2(-4, -5 + i * 6) * k, Color(0.5, 0.36, 0.16, 0.6), 1.5 * k)


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	Audio.play_sfx(OPEN_SFX, -8.0, 0.05)
	_build()
	# Opened in a region with species: its page first.
	var here := DexDB.region_of_zone(Game.region_id)
	_show_page(here if _tab_buttons.has(here) and DexDB.region_known(here) else ALL)
	note(lock)   # (in the water: why the team stays as it is)


# ------------------------------------------------------------------ layout

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.01, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)   # also stops touches from reaching the game
	var inset := SafeArea.insets(get_viewport())
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = inset.x + 8.0
	panel.offset_right = -inset.x - 8.0
	panel.offset_top = inset.y
	panel.offset_bottom = -inset.y
	panel.add_theme_stylebox_override("panel", SettingsMenu._box(SettingsMenu.INK, 22, 3, 12))
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", GAP)
	panel.add_child(col)
	col.add_child(_head())
	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 6)
	col.add_child(_tab_row)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	_main = Control.new()
	_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main.clip_contents = true
	body.add_child(_main)
	_team = VBoxContainer.new()
	_team.custom_minimum_size = Vector2(TEAM_WIDTH, 0)
	_team.add_theme_constant_override("separation", 6)
	body.add_child(_team)
	_note = Label.new()
	_note.add_theme_font_size_override("font_size", 20)
	_note.add_theme_color_override("font_color", CREAM)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_stylebox_override("normal", SettingsMenu._box(Color(0.08, 0.07, 0.05, 0.92), 12, 2, 10))
	_note.visible = false
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_note)
	drag = DinoDrag.new()
	add_child(drag)
	_fill_tabs()


func _head() -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.draw.connect(func() -> void: draw_icon(icon, icon.size / 2.0, 1.1))
	head.add_child(icon)
	head.add_child(ui_label("Dinodex", 28, GOLD))
	_counts = ui_label("", 18, Color(CREAM, 0.85))
	_counts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_counts)
	var close := ui_button("✕", 26, Vector2(56, 52))
	close.pressed.connect(_close)
	head.add_child(close)
	return head


func _fill_tabs() -> void:
	for c in _tab_row.get_children():
		c.queue_free()
	_tab_buttons.clear()
	var pages: Array = [[ALL, "Tous"]]
	for r in DexDB.regions():
		pages.append([r["id"], r["short"] if r["known"] else "???"])
	pages.append([UNIQUES, "★ Uniques"])
	pages.append([RESERVE, "Réserve"])
	for p: Array in pages:
		var b := ui_button(p[1], 18, Vector2(0, 44))
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_show_page.bind(p[0]))
		_tab_row.add_child(b)
		_tab_buttons[p[0]] = b


func _update_counts() -> void:
	var n := DexDB.counts(DexDB.order())
	var met := DexDB.counts(DexDB.uniques()).x
	_counts.text = "Vues : %d   ·   Possédées : %d   ·   sur %d espèces   ·   Uniques : %d / %d" % [n.x, n.y, DexDB.order().size(),
		met, DexDB.uniques().size()]


# ------------------------------------------------------------------ the team, on the right

func _fill_team() -> void:
	for c in _team.get_children():
		c.queue_free()
	drag.clear_targets()
	_team.add_child(ui_label("Mon équipe", 20, GOLD))
	for i in Game.PARTY_MAX:
		var slot := DexTiles.TeamSlot.new()
		slot.index = i
		slot.dino = Game.party[i] if i < Game.party.size() else null
		slot.drag = drag
		slot.custom_minimum_size = Vector2(TEAM_WIDTH, SLOT_HEIGHT)
		if slot.dino:
			slot.tapped.connect(_open_entry.bind(slot.dino.species().id, slot.dino))
		_team.add_child(slot)
		drag.add_target(slot, _slot_accepts.bind(i), _dropped_on_slot.bind(i))
	_reserve_button = ui_button("Réserve : %d" % Game.box.size(), 18, Vector2(TEAM_WIDTH, 46))
	_reserve_button.pressed.connect(_show_page.bind(RESERVE))
	_team.add_child(_reserve_button)
	drag.add_target(_reserve_button, _reserve_accepts, _dropped_in_reserve)


func _slot_accepts(payload: Dictionary, i: int) -> bool:
	if payload.get("kind") == "party":
		return i < Game.party.size() and i != payload["index"]
	if payload.get("kind") == "box":
		return lock == "" and (i < Game.party.size() or Game.party.size() < Game.PARTY_MAX)
	return false


func _reserve_accepts(payload: Dictionary) -> bool:
	return payload.get("kind") == "party" and lock == "" and Game.party.size() > 1


func _dropped_on_slot(payload: Dictionary, i: int) -> void:
	if payload["kind"] == "party":
		swap(payload["index"], i)
	else:
		bring_in(payload["index"], i)


func _dropped_in_reserve(payload: Dictionary) -> void:
	send_to_reserve(payload["index"])


# ------------------------------------------------------------------ changing the team

## Party dinos `a` and `b` swap places.
func swap(a: int, b: int) -> void:
	var lead := Game.lead_dino()
	if not Game.swap_party(a, b):
		return
	_after_change("%s passe en tête !" % Game.lead_dino().nickname if Game.lead_dino() != lead else "Changement de place !")


## Makes party dino `i` the lead.
func make_lead(i: int) -> void:
	swap(i, 0)


## The reserve's dino `box_index` joins the team: at place `party_index` (who was there goes to
## the reserve), at the end if that place is free. -1: the team chooses (free place, or asks who
## leaves when it is full).
func bring_in(box_index: int, party_index := -1) -> void:
	if lock != "" or box_index < 0 or box_index >= Game.box.size():
		note(lock)
		return
	if party_index < 0:
		if Game.party.size() < Game.PARTY_MAX:
			party_index = Game.party.size()
		else:
			_choose_leaver(box_index)
			return
	var incoming: Dino = Game.box[box_index]
	var leaving: Dino = Game.party[party_index] if party_index < Game.party.size() else null
	if not Game.from_box(box_index, party_index):
		return
	_after_change("%s rejoint ton équipe !%s" % [incoming.nickname, " %s va dans la réserve." % leaving.nickname if leaving else ""])


## Party dino `i` goes to the reserve (never the last one).
func send_to_reserve(i: int) -> void:
	if lock != "":
		note(lock)
		return
	if Game.party.size() <= 1:
		note("Il faut au moins un dino avec toi !")
		return
	var d: Dino = Game.party[i]
	if Game.to_box(i):
		_after_change("%s va dans la réserve, au Cabinet." % d.nickname)


func _after_change(text: String) -> void:
	_changed = true
	Audio.play_sfx(SWAP_SFX, -6.0, 0.05)
	_refresh_page()
	note(text)


## The team is full: who goes to the reserve to make room for the reserve's `box_index`?
func _choose_leaver(box_index: int) -> void:
	_close_chooser()
	var incoming: Dino = Game.box[box_index]
	_chooser = ColorRect.new()
	(_chooser as ColorRect).color = Color(0, 0, 0, 0.55)
	_chooser.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_chooser)
	move_child(drag, -1)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chooser.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", SettingsMenu._box(SettingsMenu.INK, 18, 3, 18))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	col.add_child(ui_label("Ton équipe est pleine.", 24, GOLD))
	col.add_child(ui_label("Qui va dans la réserve pour laisser sa place à %s ?" % incoming.nickname, 18, CREAM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	var first: Control = null
	for i in Game.party.size():
		var d: Dino = Game.party[i]
		var b := ui_button("%s\nniv. %d" % [d.nickname, d.level], 17, Vector2(128, 72))
		b.pressed.connect(func() -> void:
			_close_chooser()
			bring_in(box_index, i))
		row.add_child(b)
		if first == null:
			first = b
	var cancel := ui_button("Annuler", 18, Vector2(0, 48))
	cancel.pressed.connect(_close_chooser)
	col.add_child(cancel)
	first.grab_focus()


func _close_chooser() -> void:
	if _chooser and is_instance_valid(_chooser):
		_chooser.queue_free()
	_chooser = null


## A short line over the Dinodex, which fades after a moment.
func note(text: String) -> void:
	if text == "":
		return
	_note.text = text
	_note.visible = true
	_note.reset_size()
	var screen := get_viewport().get_visible_rect().size
	_note.position = Vector2((screen.x - _note.size.x) / 2.0, screen.y - SafeArea.insets(get_viewport()).y - _note.size.y - 18.0)
	_note.modulate.a = 1.0
	if _note_tween and _note_tween.is_valid():
		_note_tween.kill()
	_note_tween = create_tween()
	_note_tween.tween_interval(NOTE_S)
	_note_tween.tween_property(_note, "modulate:a", 0.0, 0.4)


# ------------------------------------------------------------------ pages

func _show_page(page: StringName) -> void:
	if _list_scroll and is_instance_valid(_list_scroll) and _entry == &"":
		_scroll_of[_tab] = _list_scroll.scroll_vertical
	_tab = page
	_entry = &""
	_entry_dino = null
	for p: StringName in _tab_buttons:
		(_tab_buttons[p] as Button).set_pressed_no_signal(p == page)
	_refresh_page()


## Builds the page shown again, and the team (after a change of the team, a page picked).
func _refresh_page() -> void:
	_update_counts()
	_fill_team()
	for c in _main.get_children():
		c.queue_free()
	_list_scroll = null
	if _entry != &"":
		var entry := DexEntry.new()
		entry.id = _entry
		entry.screen = self
		entry.first = _entry_dino
		entry.set_anchors_preset(Control.PRESET_FULL_RECT)
		_main.add_child(entry)
		return
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 6)
	_main.add_child(page)
	var tiles: Array[Control] = []
	match _tab:
		ALL:
			_page_head(page, "Toutes les espèces", DexDB.order(), "")
			tiles = _species_tiles(DexDB.order())
		UNIQUES:
			var met := DexDB.counts(DexDB.uniques())
			page.add_child(ui_label("Les Uniques   ·   rencontrés : %d / %d" % [met.x, DexDB.uniques().size()], 22, GOLD))
			page.add_child(ui_wrapped("Les Alphas des régions et les Anciens, les parents des œufs d'Hélène. Chacun est seul de son espèce : on ne le capture pas, on gagne sa confiance.", 15, Color(CREAM, 0.7)))
			tiles = _species_tiles(DexDB.uniques())
		RESERVE:
			page.add_child(ui_label("La réserve   ·   %d dino%s au Cabinet, avec le Pr Roc" % [Game.box.size(), "s" if Game.box.size() > 1 else ""], 22, GOLD))
			page.add_child(ui_wrapped("Glisse un dino sur ton équipe pour l'échanger, ou touche-le pour voir sa fiche." if not Game.box.is_empty()
				else "Personne pour l'instant. Les dinos capturés quand ton équipe est pleine attendent ici.", 15, Color(CREAM, 0.7)))
			tiles = _reserve_tiles()
		_:
			var region := _region(_tab)
			if region["known"]:
				_page_head(page, region["name"], region["species"], "")
			else:
				page.add_child(ui_label("Région inconnue", 22, GOLD))
				page.add_child(ui_wrapped("Tu n'es pas encore allée par là. Les espèces qui y vivent restent un mystère.", 15, Color(CREAM, 0.7)))
			tiles = _species_tiles(region["species"])
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	scroll.add_child(grid)
	for t in tiles:
		if t is DexTile:
			(t as DexTile).scroll = scroll
		grid.add_child(t)
	var fit := func() -> void:
		var cell: float = tiles[0].custom_minimum_size.x if not tiles.is_empty() else 128.0
		grid.columns = maxi(1, floori((scroll.size.x - 14.0 + GAP) / (cell + GAP)))
	scroll.resized.connect(fit)
	fit.call_deferred()
	_list_scroll = scroll
	if _tab == RESERVE:
		drag.add_target(scroll, _reserve_accepts, _dropped_in_reserve)
	var back: int = _scroll_of.get(_tab, 0)
	if back > 0:
		(func() -> void: scroll.scroll_vertical = back).call_deferred()
	if DexTile.keys_used:
		(tiles[0] if not tiles.is_empty() else _tab_buttons[_tab] as Control).grab_focus.call_deferred()


## A page's title, its counts and their bar (seen, caught).
func _page_head(page: Control, title: String, ids: Array, sub: String) -> void:
	var n := DexDB.counts(ids)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(ui_label(title, 22, GOLD))
	row.add_child(ui_label("Vues : %d / %d   ·   Possédées : %d / %d" % [n.x, ids.size(), n.y, ids.size()], 17, Color(CREAM, 0.85)))
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var total := maxf(ids.size(), 1.0)
	bar.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, bar.size)
		bar.draw_rect(r, Color(1, 1, 1, 0.08))
		bar.draw_rect(Rect2(r.position, Vector2(r.size.x * n.x / total, r.size.y)), Color(0.45, 0.75, 1.0, 0.55))
		bar.draw_rect(Rect2(r.position, Vector2(r.size.x * n.y / total, r.size.y)), Color(1, 0.86, 0.5))
		bar.draw_rect(r, Color(0, 0, 0, 0.4), false, 1.5))
	row.add_child(bar)
	page.add_child(row)
	if sub != "":
		page.add_child(ui_wrapped(sub, 15, Color(CREAM, 0.7)))


func _species_tiles(ids: Array) -> Array[Control]:
	var out: Array[Control] = []
	for id: StringName in ids:
		var t := DexTiles.Species.new()
		t.id = id
		t.tapped.connect(_open_entry.bind(id, null))
		out.append(t)
	return out


func _reserve_tiles() -> Array[Control]:
	var out: Array[Control] = []
	for i in Game.box.size():
		var t := DexTiles.Owned.new()
		t.dino = Game.box[i]
		t.index = i
		t.drag = drag
		t.can_drag = func() -> bool: return lock == ""
		t.drag_refused.connect(func() -> void: note(lock))
		t.tapped.connect(_open_entry.bind(Game.box[i].species().id, Game.box[i]))
		out.append(t)
	return out


func _region(id: StringName) -> Dictionary:
	for r in DexDB.regions():
		if r["id"] == id:
			return r
	return {"id": id, "name": "", "known": false, "species": []}


## The sheet of species `id` (`dino`: one of Chloé's to show first).
func _open_entry(id: StringName, dino: Dino = null) -> void:
	if _list_scroll and is_instance_valid(_list_scroll) and _entry == &"":
		_scroll_of[_tab] = _list_scroll.scroll_vertical
	_entry = id
	_entry_dino = dino
	Audio.play_sfx(OPEN_SFX, -12.0, 0.1)
	_refresh_page()


func back_to_list() -> void:
	_entry = &""
	_entry_dino = null
	_refresh_page()


# ------------------------------------------------------------------ closing

## Keys or a gamepad: the tiles show which one is picked (a gold ring), and the first key
## picks one when none is; a touch hides the ring again.
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		if not DexTile.keys_used:
			DexTile.keys_used = true
			_redraw_tiles()
		if get_viewport().gui_get_focus_owner() == null and event.is_pressed():
			var first := _first_focusable(_main)
			if first:
				first.grab_focus()
	elif event is InputEventMouseButton and DexTile.keys_used:
		DexTile.keys_used = false
		_redraw_tiles()


func _redraw_tiles() -> void:
	for t in find_children("*", "DexTile", true, false):
		(t as Control).queue_redraw()


static func _first_focusable(root: Node) -> Control:
	for c in root.get_children():
		if c is Control and (c as Control).focus_mode == Control.FOCUS_ALL and (c as Control).is_visible_in_tree():
			return c
		var inner := _first_focusable(c)
		if inner:
			return inner
	return null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		_back()
	elif event.is_action_pressed(ACTION):
		get_viewport().set_input_as_handled()
		_close()


## Android back gesture / button.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


## One step back: the question, the sheet, then the Dinodex itself.
func _back() -> void:
	if _chooser:
		_close_chooser()
	elif _entry != &"":
		back_to_list()
	else:
		_close()


func _close() -> void:
	if is_queued_for_deletion():
		return
	get_tree().paused = _was_paused
	if _changed:
		Save.save_game()
	closed.emit()
	queue_free()


# ------------------------------------------------------------------ widgets

static func ui_label(text: String, font_size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	return l


static func ui_wrapped(text: String, font_size: int, colour: Color) -> Label:
	var l := ui_label(text, font_size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


## A button in the style of the game, reachable with the keyboard or a gamepad (gold ring).
static func ui_button(text: String, font_size: int, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_pressed_color", Color(0.12, 0.09, 0.04))
	b.add_theme_color_override("font_disabled_color", Color(CREAM, 0.35))
	b.add_theme_stylebox_override("normal", SettingsMenu._box(Color(0.2, 0.22, 0.27), 12, 2, 8))
	b.add_theme_stylebox_override("hover", SettingsMenu._box(Color(0.25, 0.27, 0.32), 12, 2, 8))
	b.add_theme_stylebox_override("pressed", SettingsMenu._box(Color(1, 0.86, 0.5), 12, 2, 8, Color(0.98, 0.76, 0.35)))
	b.add_theme_stylebox_override("hover_pressed", SettingsMenu._box(Color(1, 0.86, 0.5), 12, 2, 8, Color(0.98, 0.76, 0.35)))
	b.add_theme_stylebox_override("disabled", SettingsMenu._box(Color(0.14, 0.15, 0.18), 12, 1, 8, Color(SettingsMenu.AMBER, 0.3)))
	var focus := SettingsMenu._box(Color(0, 0, 0, 0), 12, 3, 8, Color(1, 0.86, 0.5))
	focus.draw_center = false
	b.add_theme_stylebox_override("focus", focus)
	return b
