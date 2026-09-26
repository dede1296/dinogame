@tool
class_name Pickup
extends Prop
## Something to pick up (amber fragment, journal page…): glows softly, then shows its
## lines (which set the story flags) and disappears for good.

const ITEM_SFX := preload("res://assets/audio/sfx/item.wav")
## Experience for the whole party: exploring pays as much as fighting.
const XP_FOUND := 30

## Story flag meaning "already picked up".
@export var taken_flag: StringName
@export var dialogue_id: StringName
## Only there once this story flag is set (something a quest sends Chloé to find).
@export var show_flag: StringName
## An item it gives (Game.items), besides its lines.
@export var item_id: String

var _glow: PointLight2D


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	if (taken_flag != &"" and Game.flag(taken_flag)) or (show_flag != &"" and not Game.flag(show_flag)):
		queue_free()
		return
	add_to_group(&"interactable")
	_add_glow()
	Quality.changed.connect(_apply_quality)
	_apply_quality()


func _apply_quality() -> void:
	_glow.visible = Quality.setting(&"lights")


func _add_glow() -> void:
	_glow = PointLight2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.75, 0.3, 1))
	g.set_color(1, Color(1, 0.6, 0.2, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	_glow.texture = tex
	_glow.energy = 0.9
	_glow.position = Vector2(0, -16)
	add_child(_glow)
	var t := create_tween().set_loops()
	t.tween_property(_glow, "energy", 0.35, 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(_glow, "energy", 0.9, 1.1).set_trans(Tween.TRANS_SINE)


func interact(player: Player) -> void:
	player.face_towards(global_position)
	# (An amber pebble has its own chime, played by Search.found_pebble.)
	if not String(taken_flag).begins_with("galet_"):
		Audio.play_sfx(ITEM_SFX)
	remove_from_group(&"interactable")
	var t := create_tween().set_parallel(true)
	t.tween_property(sprite, "position:y", sprite.position.y - 26.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.3)
	# An amber pebble: no lines, just counted (see Search).
	if String(taken_flag).begins_with("galet_"):
		await Search.found_pebble(self, taken_flag, global_position)
		queue_free()
		return
	if item_id != "":
		Game.give_item(item_id)
	await Dialogue.run(DialogueDB.lines(dialogue_id))
	if taken_flag != &"":
		Game.set_flag(taken_flag)
	Game.award_team_xp(XP_FOUND)
	Save.save_game()
	queue_free()
