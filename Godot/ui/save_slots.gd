extends CanvasLayer
## The three save slots (core/save_system.gd) as three cards: the place, the objective, the dino in the
## lead, the play time, the date of the last save, « Partie terminée »; « Vide » for a free slot,
## « Illisible » for a damaged one. Three uses (`mode`):
## - LOAD: the title's « Charger une partie »: the game to load;
## - NEW: « Nouvelle partie »: where to create it;
## - SAVE_TO: in game (Paramètres): where the game saves from now on (it is copied there at once).
## Overwriting a game and deleting one are always asked first (« Annuler » has the focus).
## Mouse, keys and pad alike (PadFocus): the arrows or the cross from card to card, A / Entrée picks,
## B / Échap goes back; on a computer the keys are drawn (Prompts). Says `chosen` once: the slot (its
## overwriting confirmed), or 0 (back). No class_name: the openers preload it —
##   var screen := SaveSlots.open(self, SaveSlots.Mode.LOAD)
##   var n: int = await screen.chosen

signal chosen(slot: int)

enum Mode { LOAD, NEW, SAVE_TO }

const SCRIPT_PATH := "res://ui/save_slots.gd"
const LAYER := 90   # over Paramètres (SettingsMenu.LAYER)
const CARD_SIZE := Vector2(300, 286)
const CARD_TEXT_W := 268.0
const GAP := 18
const QUESTION_W := 700.0
const BUTTON_H := 60.0
const SMALL_BUTTON_H := 46.0
const KEY_PX := 34.0
const GOLD := Color(1, 0.86, 0.5)
const CREAM := Color(1, 0.97, 0.9)
const AMBER := Color(0.79, 0.54, 0.16)
const LIGHT_AMBER := Color(0.98, 0.76, 0.35)
const INK := Color(0.106, 0.122, 0.157, 0.97)
const CARD_BG := Color(0.16, 0.18, 0.22)
const DAMAGED := Color(1, 0.62, 0.45)
const TITLES := {Mode.LOAD: "Charger une partie", Mode.NEW: "Nouvelle partie", Mode.SAVE_TO: "Sauvegarder dans…"}
const HINTS := {
	Mode.LOAD: "Choisis la partie à reprendre.",
	Mode.NEW: "Choisis l'emplacement de la nouvelle partie.",
	Mode.SAVE_TO: "La partie en cours y sera copiée, puis tout s'y sauvegardera.",
}
## What an empty or damaged card invites to, in each mode.
const FREE_ACTION := {Mode.LOAD: "", Mode.NEW: "Commencer ici", Mode.SAVE_TO: "Sauvegarder ici"}
const MOVES: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]

var mode: Mode = Mode.LOAD
## True while a question (overwrite, delete) is on screen instead of the cards.
var asking := false
var _done := false
var _page: VBoxContainer
var _keys: HBoxContainer
var _summaries: Array[Dictionary] = []
var _asked_slot := 0
var _default_focus: Control


## Opens the screen over everything, in `how` mode; `await screen.chosen` gives the slot (0: back).
static func open(parent: Node, how: Mode) -> CanvasLayer:
	var screen: CanvasLayer = (load(SCRIPT_PATH) as GDScript).new()
	screen.set("mode", how)
	parent.get_tree().root.add_child(screen)
	return screen


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	show_cards()
	Prompts.changed.connect(_fill_keys)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.01, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)   # (also stops clicks from reaching the screen behind)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", SettingsMenu._box(INK, 22, 3, 26))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	col.add_child(_label(TITLES[mode], 38, GOLD))
	col.add_child(_label(HINTS[mode], 19, Color(CREAM, 0.8)))
	_page = VBoxContainer.new()
	_page.add_theme_constant_override("separation", 16)
	col.add_child(_page)
	_keys = HBoxContainer.new()
	_keys.alignment = BoxContainer.ALIGNMENT_CENTER
	_keys.add_theme_constant_override("separation", 10)
	col.add_child(_keys)
	_fill_keys()


# ------------------------------------------------------------------ the cards

## The three cards (the focus on slot `focus_slot`'s card, else the active one).
func show_cards(focus_slot := 0) -> void:
	_clear_page()
	asking = false
	_summaries.clear()
	var row := HBoxContainer.new()
	row.name = "Cards"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", GAP)
	for n in range(1, Save.SLOTS + 1):
		var summary := Save.slot_summary(n)
		_summaries.append(summary)
		row.add_child(_slot_column(summary))
	_page.add_child(row)
	var leave := _button("Retour", _finish.bind(0))
	leave.name = "Back"
	leave.custom_minimum_size = Vector2(260, BUTTON_H)
	leave.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_page.add_child(leave)
	PadFocus.prepare(self)
	var wanted := focus_slot if focus_slot > 0 else _home_slot()
	var card := card_of(wanted)
	if card == null or card.disabled:
		card = _first_card()
	_focus(card if card else leave)


## The button of slot `n`'s card (null while a question is shown).
func card_of(n: int) -> Button:
	return _page.find_child("Slot%d" % n, true, false) as Button


## The card to start on: the slot being played (in game), else the last one played.
func _home_slot() -> int:
	return Save.slot if mode == Mode.SAVE_TO else Save.remembered_slot()


func _first_card() -> Button:
	for n in range(1, Save.SLOTS + 1):
		var card := card_of(n)
		if card and not card.disabled:
			return card
	return null


## A card and, under it, « Supprimer » (or the room it takes, so the cards stay level).
func _slot_column(summary: Dictionary) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.add_child(_card(summary))
	var n := int(summary["slot"])
	if summary["state"] != Save.EMPTY and not (mode == Mode.SAVE_TO and n == Save.slot):
		var delete := _button("Supprimer", _ask_delete.bind(n), 18)
		delete.name = "Delete%d" % n
		delete.custom_minimum_size = Vector2(0, SMALL_BUTTON_H)
		column.add_child(delete)
	else:
		var room := Control.new()
		room.custom_minimum_size = Vector2(0, SMALL_BUTTON_H)
		column.add_child(room)
	return column


func _card(summary: Dictionary) -> Button:
	var n := int(summary["slot"])
	var card := Button.new()
	card.name = "Slot%d" % n
	card.custom_minimum_size = CARD_SIZE
	card.clip_contents = true
	_style_card(card)
	var body := VBoxContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 16
	body.offset_top = 14
	body.offset_right = -16
	body.offset_bottom = -14
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 6)
	card.add_child(body)
	var head := "Emplacement %d" % n
	if mode == Mode.SAVE_TO and n == Save.slot:
		head += "  ·  actuel"
	elif mode != Mode.SAVE_TO and n == Save.remembered_slot() and summary["state"] == Save.READY:
		head += "  ·  la dernière"
	body.add_child(_line(head, 19, GOLD))
	if summary["state"] == Save.READY:
		_ready_lines(body, summary)
	elif summary["state"] == Save.UNREADABLE:
		body.add_child(_line("Illisible", 30, DAMAGED))
		body.add_child(_line("Cette sauvegarde est abîmée : on peut la remplacer ou la supprimer.", 16, Color(CREAM, 0.75)))
	else:
		body.add_child(_spacer(40))
		body.add_child(_line("Vide", 34, Color(CREAM, 0.55), true))
		if FREE_ACTION[mode] != "":
			body.add_child(_line(FREE_ACTION[mode], 17, Color(CREAM, 0.75), true))
	card.disabled = not can_pick(summary)
	card.pressed.connect(_pick.bind(n))
	return card


## A game: the place, its objective, the dino in the lead, the time played, the date, the end seen.
func _ready_lines(body: VBoxContainer, summary: Dictionary) -> void:
	body.add_child(_line(String(summary["region_name"]), 24, CREAM))
	if String(summary["objective"]) != "" and not summary["finished"]:
		var objective := _line("« %s »" % summary["objective"], 17, Color(GOLD, 0.9))
		objective.max_lines_visible = 2
		body.add_child(objective)
	if String(summary["lead_name"]) != "":
		body.add_child(_line("%s · niveau %d" % [summary["lead_name"], summary["lead_level"]], 18, Color(CREAM, 0.9)))
	body.add_child(_line("%s de jeu" % time_text(float(summary["play_time"])), 18, Color(CREAM, 0.9)))
	var when := date_text(int(summary["saved_at"]))
	if when != "":
		body.add_child(_line("Sauvegardée %s" % when, 15, Color(CREAM, 0.6)))
	if summary["finished"]:
		body.add_child(_line("✦ Partie terminée", 17, GOLD))


## Can this card be picked in this mode? A game to load; any slot for a new game; any other slot
## than the current one to save in.
func can_pick(summary: Dictionary) -> bool:
	if mode == Mode.LOAD:
		return summary["state"] == Save.READY
	if mode == Mode.SAVE_TO:
		return int(summary["slot"]) != Save.slot
	return true


func _pick(n: int) -> void:
	var summary: Dictionary = _summaries[n - 1]
	if mode == Mode.LOAD or summary["state"] == Save.EMPTY:
		_finish(n)
		return
	var question := "Écraser la partie de l'emplacement %d ?" % n
	if summary["state"] == Save.UNREADABLE:
		question = "Remplacer la sauvegarde abîmée de l'emplacement %d ?" % n
	var after := "Elle sera remplacée par la nouvelle partie." if mode == Mode.NEW \
		else "La partie en cours la remplacera."
	_ask(n, question, "%s\n%s" % [short_line(summary), after], "Oui, écraser", _finish.bind(n))


func _ask_delete(n: int) -> void:
	_ask(n, "Supprimer la partie de l'emplacement %d ?" % n, "%s\nElle sera effacée." % short_line(_summaries[n - 1]),
		"Oui, supprimer", func() -> void:
			Save.delete_slot(n, true)
			show_cards(n))


# ------------------------------------------------------------------ a question

## The cards give way to a question: « yes » does `on_yes`, « Annuler » (focused) comes back.
func _ask(n: int, question: String, details: String, yes_text: String, on_yes: Callable) -> void:
	_clear_page()
	asking = true
	_asked_slot = n
	var q := _label(question, 28, CREAM)
	q.custom_minimum_size = Vector2(QUESTION_W, 0)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page.add_child(q)
	var more := _label(details, 19, Color(CREAM, 0.75))
	more.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page.add_child(more)
	var row := HBoxContainer.new()
	row.name = "Answers"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var yes := _button(yes_text, on_yes)
	yes.name = "Yes"
	var no := _button("Annuler", show_cards.bind(n))
	no.name = "No"
	for b: Button in [yes, no]:
		b.custom_minimum_size = Vector2(240, BUTTON_H)
		row.add_child(b)
	_page.add_child(row)
	PadFocus.prepare(self)
	_focus(no)


# ------------------------------------------------------------------ going back

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		back()
	elif get_viewport().gui_get_focus_owner() == null and MOVES.any(func(a: StringName) -> bool: return event.is_action_pressed(a)):
		# Opened with the mouse (nothing focused), then the arrows or the cross: on the card to start on.
		get_viewport().set_input_as_handled()
		_focus(_default_focus)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()


## B / Échap: from a question back to the cards, from the cards out (0).
func back() -> void:
	if asking:
		show_cards(_asked_slot)
	else:
		_finish(0)


func _finish(n: int) -> void:
	if _done:
		return
	_done = true
	chosen.emit(n)
	queue_free()


# ------------------------------------------------------------------ words

## « 3 h 12 », « 12 min », « moins d'une minute ».
static func time_text(seconds: float) -> String:
	var minutes := floori(seconds / 60.0)
	if minutes < 1:
		return "moins d'une minute"
	if minutes < 60:
		return "%d min" % minutes
	return "%d h %02d" % [floori(minutes / 60.0), minutes % 60]


## « Prairie du Grand Crâne · 3 h 12 »: under « Continuer », and in the questions.
static func short_line(summary: Dictionary) -> String:
	if summary.get("state") == Save.READY:
		return "%s · %s" % [summary["region_name"], time_text(float(summary["play_time"]))]
	if summary.get("state") == Save.UNREADABLE:
		return "Sauvegarde abîmée"
	return "Vide"


## « le 19/10/2026 à 14 h 32 », in the computer's time; "" when unknown.
static func date_text(unix: int) -> String:
	if unix <= 0:
		return ""
	var local_offset := Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system()) \
		- Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system(true))
	var t := Time.get_datetime_dict_from_unix_time(unix + local_offset)
	return "le %02d/%02d/%d à %d h %02d" % [t["day"], t["month"], t["year"], t["hour"], t["minute"]]


# ------------------------------------------------------------------ widgets

## On a computer, the keys: « [A] choisir   [B] retour », those of the keyboard or the pad held.
func _fill_keys() -> void:
	if not is_instance_valid(_keys):
		return
	for child in _keys.get_children():
		child.queue_free()
	_keys.visible = Screen.on_computer()
	for part: Array in [[&"ui_accept", "choisir"], [&"cancel", "retour"]]:
		var picture := Prompts.texture(part[0])
		if picture:
			var icon := TextureRect.new()
			icon.texture = picture
			icon.custom_minimum_size = Vector2(KEY_PX, KEY_PX)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_keys.add_child(icon)
		var words := String(part[1]) if picture else "%s : %s" % [Prompts.label(part[0]), part[1]]
		_keys.add_child(_label(words + "     ", 18, Color(CREAM, 0.8)))


## The focus on `control` when the keys or the pad are used (PadFocus); it is the one to start on
## either way.
func _focus(control: Control) -> void:
	_default_focus = control
	if Prompts.navigating and is_instance_valid(control):
		control.grab_focus.call_deferred()


func _clear_page() -> void:
	for child in _page.get_children():
		_page.remove_child(child)
		child.queue_free()


func _style_card(card: Button) -> void:
	card.add_theme_stylebox_override("normal", SettingsMenu._box(CARD_BG, 16, 2, 0, Color(AMBER, 0.7)))
	card.add_theme_stylebox_override("hover", SettingsMenu._box(Color(0.22, 0.23, 0.27), 16, 3, 0, LIGHT_AMBER))
	card.add_theme_stylebox_override("pressed", SettingsMenu._box(Color(0.45, 0.29, 0.08), 16, 3, 0, LIGHT_AMBER))
	card.add_theme_stylebox_override("focus", SettingsMenu._box(Color(0, 0, 0, 0), 16, 5, 0, GOLD))
	card.add_theme_stylebox_override("disabled", SettingsMenu._box(Color(0.12, 0.13, 0.16), 16, 1, 0, Color(AMBER, 0.3)))


func _line(text: String, font_size: int, colour: Color, centered := false) -> Label:
	var l := _label(text, font_size, colour)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	l.custom_minimum_size = Vector2(CARD_TEXT_W, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # (no overrun trimming: its height would drop to 0 in the column)
	return l


func _spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _label(text: String, font_size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	return l


func _button(text: String, action: Callable, font_size := 24) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, BUTTON_H)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_pressed_color", Color(1, 0.9, 0.6))
	b.add_theme_stylebox_override("normal", SettingsMenu._box(CARD_BG, 14, 2))
	b.add_theme_stylebox_override("hover", SettingsMenu._box(Color(0.2, 0.22, 0.27), 14, 2))
	b.add_theme_stylebox_override("pressed", SettingsMenu._box(Color(0.45, 0.29, 0.08), 14, 3, 0, LIGHT_AMBER))
	b.add_theme_stylebox_override("focus", SettingsMenu._box(Color(0, 0, 0, 0), 14, 3, 0, GOLD))
	b.pressed.connect(action)
	return b
