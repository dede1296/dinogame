class_name OsEnfoui
extends DigSpot
## A bone of one of the three legendary skeletons (the post-game, story/fossiles.gd): a mound like any
## other (DigSpot: only a party dino with Flair finds it), there only once the page of its beast is given
## (`show_flag`: Tante Sirocco's notebook for the land, Isaure's bet for the sea). Dug up, it says how
## many are left (« Un os du Titanosaure d'Or ! Il en reste 3. ») and, the first bone of its beast, what
## Chloé thinks of it. Put in the zones' scenes by tools/zones/os_legendaires.gd (`pebble`: the bone's
## flag, os_<beast>_<n>; `item_id`: os_<beast>).

const FOSSILES := preload("res://story/fossiles.gd")

## The page of its beast: the bone shows once this story flag is set (and the game is over).
@export var show_flag: StringName


func _ready() -> void:
	super()
	if is_queued_for_deletion():
		return
	Game.flag_changed.connect(_on_flag_changed)


## Seen only with Flair in the party, once its page is given (the game over).
func _refresh() -> void:
	visible = Game.ability_user(&"flair") != null and Game.flag(&"post_game") and (show_flag == &"" or Game.flag(show_flag))


func _on_flag_changed(id: StringName, _value: Variant) -> void:
	if id == show_flag or id == &"post_game":
		_refresh()


## Dug up: it pops out, the count, the companion's joy; then (not waited for: the mound goes) the
## thought of the first bone of its beast.
func _found_item(view: WorldView, companion: Companion) -> void:
	remove_from_group(&"secret")
	Audio.play_sfx(FOSSILES.found_sound())
	if view:
		view.pop_up(global_position, ItemsDB.icon(item_id), 0.3)
	var digger := Game.ability_user(&"flair")
	var first: bool = FOSSILES.dig(pebble)
	Toast.say(get_tree(), FOSSILES.toast(pebble))
	if companion:
		companion.rejoice()
	Save.save_game()
	FOSSILES.after_find(pebble, first, digger.nickname if digger else "")
