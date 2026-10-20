class_name JournalWall
extends CanvasLayer
## The journal wall (docs/mecaniques.md § Le Cabinet: « les pages trouvées, rangées dans l'ordre,
## relisibles avec la voix d'Hélène »): Hélène's forty pages and the Anciens' (JournalPages), one tile each.
## A page found: its number in gold, A / a click reads it again (LetterView, with its recorded voice when it
## has one). Nouvelle partie+ (docs/post-game-scenes.md § N3): a page read in a game before and not found
## again yet: grey, with a tick, « déjà lue »; it is read again only once found again (no spoiling the game).
## A page never found: its number, dim. The line under the tiles says what the one pointed at is.
## Mouse, keys and pad alike (PadFocus): the arrows or the cross from tile to tile, A / Entrée reads,
## B / Échap closes. The game is paused meanwhile.
##   await JournalWall.open(self).closed

signal closed

const LAYER := 80   # (the pause menus' layer; the letter (LetterView, 60) is read with the wall hidden)
const COLUMNS := 10
const TILE := Vector2(66, 54)
const ANCIEN_TILE := Vector2(214, 54)
const TEXT_W := 760.0
const SCROLL_MAX_H := 600.0
const SCROLL_MARGIN_H := 300.0   # (the title, the counts, the line, the button and the keys above and below)
const TICK := "✓"
const GOLD := Color(1, 0.86, 0.5)
const CREAM := Color(1, 0.97, 0.9)
const AMBER := Color(0.79, 0.54, 0.16)
const LIGHT_AMBER := Color(0.98, 0.76, 0.35)
const INK := Color(0.106, 0.122, 0.157, 0.97)
const CARD_BG := Color(0.16, 0.18, 0.22)
const GREY := Color(0.62, 0.63, 0.66)
const DIM := Color(1, 0.97, 0.9, 0.3)
const MOVES: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]

var _was_paused := false
var _closing := false
var _detail: Label
var _keys: HBoxContainer
var _first: Control


static func open(parent: Node) -> JournalWall:
	var wall := JournalWall.new()
	parent.get_tree().root.add_child(wall)
	return wall


## Is there anything to show yet (a page found, or read in a game before)? The menus offer the wall then.
static func available() -> bool:
	return JournalPages.any()


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_build()
	Prompts.changed.connect(_fill_keys)
	PadFocus.prepare(self)
	if Prompts.navigating and _first:
		_first.grab_focus.call_deferred()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.01, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)   # (also stops clicks from reaching the game)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", SettingsMenu._box(INK, 22, 3, 26))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)
	col.add_child(_label("Le mur du journal", 38, GOLD))
	col.add_child(_label(counts_text(), 19, Color(CREAM, 0.8)))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	col.add_child(scroll)
	var sections := VBoxContainer.new()
	sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections.add_theme_constant_override("separation", 10)
	scroll.add_child(sections)
	for section in JournalPages.sections():
		_add_section(sections, section)
	# As tall as the pages (no empty band), at most what the screen leaves: then it scrolls.
	scroll.custom_minimum_size = Vector2(TEXT_W, minf(sections.get_combined_minimum_size().y, _scroll_height()))
	_detail = _label("", 18, Color(CREAM, 0.85))
	_detail.name = "Detail"
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(TEXT_W, 48)
	col.add_child(_detail)
	var close := _button("Fermer", close_wall)
	close.name = "Close"
	close.custom_minimum_size = Vector2(260, 56)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(close)
	if _first == null:
		_first = close
	_keys = HBoxContainer.new()
	_keys.alignment = BoxContainer.ALIGNMENT_CENTER
	_keys.add_theme_constant_override("separation", 10)
	col.add_child(_keys)
	_fill_keys()


## « 12 pages sur 40 », and those read in a game before still to find again.
static func counts_text() -> String:
	var helene: Array = JournalPages.sections()[0]["pages"]
	var n := JournalPages.counts(helene)
	var text := "%d page%s sur %d" % [n.x, "s" if n.x > 1 else "", n.y]
	var before := JournalPages.all().filter(func(p: Dictionary) -> bool:
		return JournalPages.state(p) == JournalPages.State.READ_BEFORE).size()
	if before > 0:
		text += "  ·  %d déjà lue%s à retrouver" % [before, "s" if before > 1 else ""]
	return text


func _add_section(parent: VBoxContainer, section: Dictionary) -> void:
	var head := _label(String(section["title"]), 22, GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(head)
	var numbered: bool = section.get("numbered", false)
	var grid := GridContainer.new()
	grid.columns = COLUMNS if numbered else 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	for p: Dictionary in section["pages"]:
		grid.add_child(_tile(p, numbered))


## One page: found (gold, reads it), read before (grey, a tick, not readable), never found (dim).
func _tile(p: Dictionary, numbered: bool) -> Button:
	var state := JournalPages.state(p)
	var tile := Button.new()
	tile.name = "Page_" + String(p["flag"]).trim_prefix("found_journal_")
	tile.custom_minimum_size = TILE if numbered else ANCIEN_TILE
	tile.focus_mode = Control.FOCUS_ALL   # (a grey one too: the line under the tiles says what it is)
	tile.text = tile_text(p, state, numbered)
	tile.add_theme_font_size_override("font_size", 22 if numbered else 18)
	var colour: Color = {JournalPages.State.FOUND: GOLD, JournalPages.State.READ_BEFORE: GREY}.get(state, DIM)
	for key in ["font_color", "font_hover_color", "font_focus_color", "font_disabled_color"]:
		tile.add_theme_color_override(key, colour)
	var bg: Color = CARD_BG if state == JournalPages.State.FOUND else Color(0.12, 0.13, 0.16)
	tile.add_theme_stylebox_override("normal", SettingsMenu._box(bg, 10, 2, 0, Color(AMBER, 0.7 if state == JournalPages.State.FOUND else 0.25)))
	tile.add_theme_stylebox_override("hover", SettingsMenu._box(Color(0.22, 0.23, 0.27), 10, 2, 0, LIGHT_AMBER))
	tile.add_theme_stylebox_override("pressed", SettingsMenu._box(Color(0.45, 0.29, 0.08), 10, 3, 0, LIGHT_AMBER))
	tile.add_theme_stylebox_override("disabled", SettingsMenu._box(bg, 10, 1, 0, Color(AMBER, 0.2)))
	tile.add_theme_stylebox_override("focus", SettingsMenu._box(Color(0, 0, 0, 0), 10, 4, 0, GOLD))
	tile.disabled = state != JournalPages.State.FOUND
	tile.pressed.connect(_read.bind(p, tile))
	var said := detail_text(p, state)
	tile.focus_entered.connect(func() -> void: _detail.text = said)
	tile.mouse_entered.connect(func() -> void: _detail.text = said)
	if _first == null and state == JournalPages.State.FOUND:
		_first = tile
	return tile


## On a tile: « 12 », « ✓ 12 » (read before), the Ancien's name once known, « ? ».
static func tile_text(p: Dictionary, state: JournalPages.State, numbered: bool) -> String:
	var label := String(p["label"])
	if state == JournalPages.State.READ_BEFORE:
		return "%s %s" % [TICK, label]
	if state == JournalPages.State.UNKNOWN and not numbered:
		return "?"
	return label


## The line under the tiles for a page.
static func detail_text(p: Dictionary, state: JournalPages.State) -> String:
	var label := String(p["label"])
	var what := "Page %s" % label if label.is_valid_int() else label
	match state:
		JournalPages.State.FOUND:
			var title := JournalPages.title(p)
			return "%s : « %s »" % [what, title] if title != "" else what
		JournalPages.State.READ_BEFORE:
			return "%s : déjà lue à la partie précédente. Retrouve-la pour la relire." % what
	return "%s : pas encore trouvée." % what if label.is_valid_int() else "La page d'un Ancien : pas encore trouvée."


## A page read again: the wall gives way to the letter, then comes back on the same tile.
func _read(p: Dictionary, tile: Button) -> void:
	if not visible or JournalPages.state(p) != JournalPages.State.FOUND:   # (a grey page is never read: no spoiling)
		return
	var page := JournalPages.letter(p)
	if page.is_empty():
		return
	visible = false
	await LetterView.open(get_tree(), page["paragraphs"], page.get("sign", ""), page.get("voice", ""))
	if not is_inside_tree():
		return
	visible = true
	if Prompts.navigating and is_instance_valid(tile):
		tile.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"menu"):
		get_viewport().set_input_as_handled()
		close_wall()
	elif get_viewport().gui_get_focus_owner() == null and MOVES.any(func(a: StringName) -> bool: return event.is_action_pressed(a)):
		get_viewport().set_input_as_handled()   # (opened with the mouse, then the arrows: on the first page)
		_first.grab_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible:
		close_wall()


func close_wall() -> void:
	if _closing:
		return
	_closing = true
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()


func _scroll_height() -> float:
	var screen := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1600, 900)
	return clampf(screen.y - SCROLL_MARGIN_H, 200.0, SCROLL_MAX_H)


## On a computer, the keys: « [A] relire   [B] fermer », those of the keyboard or the pad held.
func _fill_keys() -> void:
	if not is_instance_valid(_keys):
		return
	for child in _keys.get_children():
		child.queue_free()
	_keys.visible = Screen.on_computer()
	for part: Array in [[&"ui_accept", "relire"], [&"cancel", "fermer"]]:
		var picture := Prompts.texture(part[0])
		if picture:
			var icon := TextureRect.new()
			icon.texture = picture
			icon.custom_minimum_size = Vector2(34, 34)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_keys.add_child(icon)
		var words := String(part[1]) if picture else "%s : %s" % [Prompts.label(part[0]), part[1]]
		_keys.add_child(_label(words + "     ", 18, Color(CREAM, 0.8)))


func _label(text: String, font_size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	return l


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_stylebox_override("normal", SettingsMenu._box(CARD_BG, 14, 2))
	b.add_theme_stylebox_override("hover", SettingsMenu._box(Color(0.2, 0.22, 0.27), 14, 2))
	b.add_theme_stylebox_override("pressed", SettingsMenu._box(Color(0.45, 0.29, 0.08), 14, 3, 0, LIGHT_AMBER))
	b.add_theme_stylebox_override("focus", SettingsMenu._box(Color(0, 0, 0, 0), 14, 3, 0, GOLD))
	b.pressed.connect(action)
	return b
