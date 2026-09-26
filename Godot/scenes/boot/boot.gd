extends Control
## Title screen. The first tap also unlocks audio in web browsers.

const WORLD := "res://world/world.tscn"

@onready var continue_button: Button = %Continue
@onready var new_button: Button = %NewGame
@onready var version_label: Label = %Version


func _ready() -> void:
	continue_button.visible = Save.has_save()
	continue_button.pressed.connect(_on_continue)
	new_button.pressed.connect(_on_new_game)
	version_label.text = "Prototype Godot %s · %s · rendu %s" % [
		ProjectSettings.get_setting("application/config/version"),
		Engine.get_version_info()["string"],
		RenderingServer.get_current_rendering_method(),
	]
	(continue_button if continue_button.visible else new_button).grab_focus()


func _on_continue() -> void:
	if Save.load_game():
		Router.go_to(WORLD)
	else:
		continue_button.text = "Sauvegarde illisible"
		continue_button.disabled = true


func _on_new_game() -> void:
	Game.new_game()
	Router.go_to(WORLD)
