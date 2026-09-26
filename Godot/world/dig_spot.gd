class_name DigSpot
extends Node2D
## Freshly turned earth where an amber pebble is buried. Only a party dino with Flair notices
## it: without one it is not there at all (hidden, not interactable); with one, the mound
## shows, the companion senses it, and digging brings the pebble up.

const PICTURE := preload("res://assets/art/props/monticule.png")
const SCALE := 0.14
const DIG_SFX := preload("res://assets/audio/sfx/creuser.mp3")
const EARTH: Array[Color] = [Color(0.45, 0.3, 0.17), Color(0.36, 0.24, 0.13), Color(0.58, 0.42, 0.26)]

## The pebble's story flag ("galet_<zone>_<n>").
@export var pebble: StringName

var sprite: Sprite2D


func _ready() -> void:
	if Game.flag(pebble):
		queue_free()
		return
	sprite = Sprite2D.new()
	sprite.texture = PICTURE
	sprite.scale = Vector2.ONE * SCALE
	sprite.offset = Vector2(0, -PICTURE.get_height() * 0.4)
	add_child(sprite)
	add_to_group(&"interactable")
	add_to_group(&"secret")
	Game.party_changed.connect(_refresh)
	_refresh()


## Seen only when someone in the party has Flair.
func _refresh() -> void:
	visible = Game.ability_user(&"flair") != null


func is_hiding() -> bool:
	return visible and not Game.flag(pebble)


func interact(player: Player) -> void:
	var digger := Game.ability_user(&"flair")
	if digger == null:
		return
	player.face_towards(global_position)
	remove_from_group(&"interactable")
	Toast.say(get_tree(), "%s flaire l'endroit… On creuse !" % digger.nickname)
	var companion := get_tree().get_first_node_in_group(&"companion") as Companion
	if companion:
		await companion.perform_at(global_position)
	Audio.play_sfx(DIG_SFX, -2.0, 0.06)
	var view := get_tree().get_first_node_in_group(&"world_view") as WorldView
	if view:
		view.burst(global_position, EARTH, 22, 0.3, 0.4)
	await get_tree().create_timer(0.5).timeout
	await Search.found_pebble(self, pebble, global_position)
	queue_free()
