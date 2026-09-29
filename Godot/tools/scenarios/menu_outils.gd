extends RefCounted
## Helpers of the game menu's scenario (tools/scenarios/test_menu.gd, « static » command of
## tools/capture.gd): the menu opened from the ☰ button, its pages, a volume slider moved, what
## the sound settings are, a scene playing, back to the title screen.


static func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func _menu() -> Node:
	for n in _tree().root.get_children():
		if n is SettingsMenu:
			return n
	return null


static func open() -> String:
	var button: Button = _tree().current_scene.find_child("MenuButton", true, false)
	button.pressed.emit()
	return "menu ouvert : %s, jeu en pause : %s" % [_menu() != null, _tree().paused]


static func page(id: String) -> String:
	_menu().call("_show", id)
	return "page " + id


## The volume slider of kind `i` (Audio.CATEGORIES) set to `percent`, as a finger would.
static func slide(i: int, percent: float) -> String:
	var rows: Node = _menu().get("_rows")
	var row: Node = rows.get_child(1 + i)
	(row.get_child(1) as HSlider).value = percent
	return "%s → %d %%" % [(row.get_child(0) as Label).text, int(percent)]


## Each kind of sound: the player's volume, its gain (dB), muted; where a cry, a voice, a step
## and a sound effect go.
static func report() -> String:
	var parts := []
	for c: Array in Audio.CATEGORIES:
		var idx := AudioServer.get_bus_index(c[0])
		var amp := AudioServer.get_bus_effect(idx, 0) as AudioEffectAmplify
		parts.append("%s=%.2f (%.1f dB%s)" % [c[0], Audio.volume(c[0]), amp.volume_db if amp else 999.0,
			", muet" if AudioServer.is_bus_mute(idx) else ""])
	var routes := []
	for path in ["res://assets/audio/cries/raptor-neutre.mp3", "res://assets/audio/voices/roc-1.mp3",
			"res://assets/audio/footsteps/footstep00.ogg", "res://assets/audio/sfx/item.wav"]:
		routes.append("%s→%s" % [path.get_file(), Audio.bus_for(load(path))])
	return " · ".join(parts) + " | " + ", ".join(routes)


## Chloé in a scene (as Story.lock does), or free again.
static func busy(on: bool) -> String:
	_tree().get_first_node_in_group(&"player").set("busy", on)
	return "scène en cours : %s" % on


## The page's first button whose text begins with `text` is pressed.
static func press(text: String) -> String:
	for b in _menu().find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(text):
			(b as Button).pressed.emit()
			return "bouton « %s »" % (b as Button).text
	return "pas de bouton « %s »" % text


static func where() -> String:
	var scene := _tree().current_scene
	return "scène : %s, pause : %s, dialogue : %s, ambiance : « %s », menu : %s" % [
		scene.scene_file_path if scene else "?", _tree().paused, Dialogue.active, Audio.ambience.current(), _menu() != null]


## On the title screen: « Continuer ».
static func title_continue() -> String:
	var button := _tree().current_scene.get_node_or_null("%Continue") as Button
	if button == null or not button.visible:
		return "pas de bouton Continuer"
	button.pressed.emit()
	return "Continuer"
