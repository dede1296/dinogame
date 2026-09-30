extends RefCounted
## Helpers of the Élise scenario (« static » command of tools/capture.gd): why her crouch does
## or does not hold, and where she and her Triceratops stand.


static func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func _elise():
	return _tree().current_scene.get("region").entities.get_node_or_null("Elise")


## Her crouch, asked for straight: who the game thinks she is, whether the pose is drawn for her,
## and whether it took.
static func crouch() -> String:
	var elise = _elise()
	if elise == null:
		return "Élise absente"
	var took: bool = Stage.pose(elise, &"accroupi")
	var sprite := Stage.sprite_of(elise) as AnimatedSprite2D
	return "personne=« %s » pose dessinée=%s prise=%s animation=%s" % [Outfits.person(elise),
		Outfits.has_pose(elise, &"accroupi"), took, sprite.animation if sprite else "?"]


static func stand() -> String:
	var elise = _elise()
	return "debout : %s" % (Stage.pose(elise, &"") if elise else "absente")
