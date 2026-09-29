@tool
class_name NookFind
extends Pickup
## Something hidden in a dark nook (DarkNook): seen and picked up only in the light of Chloé's
## Cœurs d'ambre. An amber pebble ("galet_…" flag) is counted as any other; anything else gives
## its item and says its `line` (no entry of DialogueDB needed).

## What is said when it is found (an item, a fossil…).
@export var line := ""


func interact(player: Player) -> void:
	if String(taken_flag).begins_with("galet_") or line == "":
		await super(player)
		return
	player.face_towards(global_position)
	Audio.play_sfx(ITEM_SFX)
	remove_from_group(&"interactable")
	var t := create_tween().set_parallel(true)
	t.tween_property(sprite, "position:y", sprite.position.y - 26.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.3)
	if item_id != "":
		Game.give_item(item_id)
	await Dialogue.run([{"text": line}])
	if taken_flag != &"":
		Game.set_flag(taken_flag)
	Game.award_team_xp(XP_FOUND)
	Save.save_game()
	queue_free()
