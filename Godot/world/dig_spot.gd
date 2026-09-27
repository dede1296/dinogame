class_name DigSpot
extends Node2D
## Freshly turned earth where an amber pebble is buried — or, with `item_id`, something else
## (a fossil in the Désert…). Only a party dino with Flair notices it: without one it is not
## there at all (hidden, not interactable); with one, the mound shows, the companion senses
## it, and digging brings the pebble (or the item) up.

const PICTURE := preload("res://assets/art/props/monticule.png")
const SCALE := 0.14
const DIG_SFX := preload("res://assets/audio/sfx/creuser.mp3")
const ITEM_SFX := preload("res://assets/audio/sfx/item.wav")
const EARTH: Array[Color] = [Color(0.45, 0.3, 0.17), Color(0.36, 0.24, 0.13), Color(0.58, 0.42, 0.26)]
## Experience for the whole party when an item is dug up (a pebble: Search.XP_PEBBLE).
const XP_ITEM := 30

## The spot's story flag, set once dug up: "galet_<zone>_<n>" for an amber pebble (counted
## as one), any unique flag for an item ("fossile_desert_01").
@export var pebble: StringName
## What is buried instead of a pebble (ItemsDB id: "fossile"…); empty: an amber pebble.
@export var item_id := ""

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
	if item_id == "":
		await Search.found_pebble(self, pebble, global_position)
	else:
		_found_item(view, companion)
	queue_free()


## An item dug up: it pops out of the earth, Chloé keeps it, the party learns something.
func _found_item(view: WorldView, companion: Companion) -> void:
	remove_from_group(&"secret")
	Audio.play_sfx(ITEM_SFX)
	if view:
		view.pop_up(global_position, ItemsDB.icon(item_id), 0.3)
	Toast.say(get_tree(), dig_up(item_id, pebble))
	if companion:
		companion.rejoice()
	Save.save_game()


## Chloé gets `item_id` (flag `flag` set: found), the party some experience. Returns what
## the message says (« Fossile ! Tu en as 3. »).
static func dig_up(item: String, flag: StringName) -> String:
	if flag != &"":
		Game.set_flag(flag)
	Game.give_item(item)
	Game.award_team_xp(XP_ITEM)
	var item_name: String = ItemsDB.item(item)["name"]
	var count := Game.item_count(item)
	return "%s ! Tu en as %d." % [item_name, count] if count > 1 else "%s !" % item_name
