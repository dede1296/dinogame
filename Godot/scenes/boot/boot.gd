extends Control
## Title screen. The first tap also unlocks audio in web browsers.
## « Continuer » loads the last slot used (core/save_system.gd), its place and play time written under
## it; « Charger une partie » beside it opens the three slots (ui/save_slots.gd); « Nouvelle partie »
## first asks in which slot to create the game.

const WORLD := "res://world/world.tscn"
## The title theme of the web version (tools/render-phaser-music.mjs titre 1): harp, flute.
const MUSIC := preload("res://assets/audio/music/titre.ogg")
const SaveSlots := preload("res://ui/save_slots.gd")
const LOAD_FONT := 22
const INFO_FONT := 18

@onready var menu: VBoxContainer = $Menu
@onready var continue_button: Button = %Continue
@onready var new_button: Button = %NewGame
@onready var settings_button: Button = %Settings
@onready var credits_button: Button = %Credits
@onready var version_label: Label = %Version

var load_button: Button
## Under « Continuer »: « Prairie du Grand Crâne · 3 h 12 ».
var continue_info: Label
var _continue_slot := 0


func _ready() -> void:
	Save.migrate()   # (the save from before the slots becomes slot 1, once)
	_add_load_button()
	continue_button.pressed.connect(_on_continue)
	load_button.pressed.connect(_on_load)
	new_button.pressed.connect(_on_new_game)
	settings_button.pressed.connect(func() -> void:
		SettingsMenu.open(self).closed.connect(settings_button.grab_focus))
	credits_button.pressed.connect(_on_credits)
	version_label.text = "Ambrelune %s · Godot %s · rendu %s" % [
		ProjectSettings.get_setting("application/config/version"),
		Engine.get_version_info()["string"],
		RenderingServer.get_current_rendering_method(),
	]
	_add_quit_button()
	refresh_saves()
	(continue_button if continue_button.visible else new_button).grab_focus()
	Audio.play_music(MUSIC, 2.0)


## « Continuer » and « Charger une partie » side by side, the summary of the game to continue under them.
func _add_load_button() -> void:
	var row := HBoxContainer.new()
	row.name = "ContinueRow"
	row.add_theme_constant_override("separation", 12)
	menu.add_child(row)
	menu.move_child(row, continue_button.get_index())
	continue_button.reparent(row)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.size_flags_stretch_ratio = 1.4
	load_button = new_button.duplicate() as Button
	load_button.name = "LoadGame"
	load_button.text = "Charger une partie"
	load_button.add_theme_font_size_override("font_size", LOAD_FONT)
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(load_button)
	continue_info = Label.new()
	continue_info.name = "ContinueInfo"
	continue_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_info.add_theme_font_size_override("font_size", INFO_FONT)
	continue_info.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	continue_info.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04, 0.9))
	continue_info.add_theme_constant_override("outline_size", 6)
	menu.add_child(continue_info)
	menu.move_child(continue_info, row.get_index() + 1)


## What the saves offer now: « Continuer » (the last slot used, if it can be read), « Charger une
## partie » (as soon as a slot holds something, even damaged: it can be deleted there).
func refresh_saves() -> void:
	_continue_slot = Save.continue_slot()
	continue_button.visible = _continue_slot > 0
	continue_button.disabled = false
	continue_button.text = "Continuer"
	load_button.visible = Save.has_save()
	continue_button.get_parent().visible = continue_button.visible or load_button.visible
	continue_info.visible = continue_button.visible
	if continue_button.visible:
		continue_info.text = SaveSlots.short_line(Save.slot_summary(_continue_slot))


## On a computer, the title screen closes the game (a phone has its own Home button).
## The button is made from « Paramètres », so it keeps the screen's own look.
func _add_quit_button() -> void:
	if not Screen.on_computer():
		return
	var quit := settings_button.duplicate() as Button
	quit.name = "Quit"
	quit.text = "Quitter le jeu"
	settings_button.get_parent().add_child(quit)
	quit.pressed.connect(func() -> void: get_tree().quit())


func _on_continue() -> void:
	if Save.load_slot(_continue_slot):
		Router.go_to(WORLD)
	else:
		continue_button.text = "Sauvegarde illisible"
		continue_button.disabled = true


## The three slots: the one picked is loaded (back: the menu again, a slot may have been deleted).
func _on_load() -> void:
	var n := await _choose_slot(SaveSlots.Mode.LOAD)
	if n > 0 and Save.load_slot(n):
		Router.go_to(WORLD)
		return
	_back_to_menu(load_button)


## A new game (and a Nouvelle partie+ the same way): first the slot to create it in (asked before
## overwriting a game), then the intro (story/cinematiques.gd), which ends on black: then the quay
## of Port-Ambre.
func _on_new_game() -> void:
	# No game saved yet: nothing to choose or overwrite, the first slot (Greg, 19/10: « au mieux »).
	var n := 1 if not Save.has_save() else await _choose_slot(SaveSlots.Mode.NEW)
	if n <= 0:
		_back_to_menu(new_button)
		return
	Game.new_game()
	if not Save.start_new_game(n, true):   # (save_slots.gd asked before overwriting a game)
		new_button.text = "Sauvegarde impossible"
		_back_to_menu(new_button)
		return
	await Cinematiques.new_game_intro(self)
	Router.go_to(WORLD)


## The slots screen over the title (its menu hidden meanwhile: the pad stays on the cards).
func _choose_slot(mode: SaveSlots.Mode) -> int:
	menu.visible = false
	var screen := SaveSlots.open(self, mode) as SaveSlots
	var n: int = await screen.chosen
	return n


func _back_to_menu(focus: Button) -> void:
	menu.visible = true
	refresh_saves()
	if Prompts.navigating:
		(focus if focus.visible else new_button).grab_focus()


## The credits alone, then back here.
func _on_credits() -> void:
	await Cinematiques.play_credits(self).finished
	if is_inside_tree() and Prompts.navigating:
		credits_button.grab_focus()
