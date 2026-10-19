extends Control
## Title screen. The first tap also unlocks audio in web browsers.

const WORLD := "res://world/world.tscn"
## The title theme of the web version (tools/render-phaser-music.mjs titre 1): harp, flute.
const MUSIC := preload("res://assets/audio/music/titre.ogg")

@onready var continue_button: Button = %Continue
@onready var new_button: Button = %NewGame
@onready var settings_button: Button = %Settings
@onready var credits_button: Button = %Credits
@onready var version_label: Label = %Version


func _ready() -> void:
	continue_button.visible = Save.has_save()
	continue_button.pressed.connect(_on_continue)
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
	(continue_button if continue_button.visible else new_button).grab_focus()
	Audio.play_music(MUSIC, 2.0)


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
	if Save.load_game():
		Router.go_to(WORLD)
	else:
		continue_button.text = "Sauvegarde illisible"
		continue_button.disabled = true


## A new game (and a Nouvelle partie+ the same way) opens on the intro (story/cinematiques.gd), which
## ends on black: then the quay of Port-Ambre.
func _on_new_game() -> void:
	Game.new_game()
	await Cinematiques.new_game_intro(self)
	Router.go_to(WORLD)


## The credits alone, then back here.
func _on_credits() -> void:
	await Cinematiques.play_credits(self).finished
	if is_inside_tree() and Prompts.navigating:
		credits_button.grab_focus()

