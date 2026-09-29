extends RefCounted
## Helpers of the fast travel scenarios (« static » command of tools/capture.gd): the Grand
## Voyageur talked to without one standing there (the scene takes a null dino), the stops Chloé
## has found, the destination screen answered as a finger would.


static func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func _screen() -> Node:
	for n in _tree().root.get_children():
		if n is VoyageScreen:
			return n
	return null


## Talks to the Grand Voyageur of the zone Chloé stands in (no dino needed for the test).
static func talk() -> String:
	Voyage.talk(null)
	return "on parle au Grand Voyageur (zone %s)" % Voyage.zone_now()


## Stops noted, and the one Chloé stands at.
static func report() -> String:
	var found := []
	for stop: Dictionary in Voyage.STOPS:
		if Game.flag(stop["flag"]):
			found.append(stop["region"])
	return "escales connues : %s | ici : %s | rencontré : %s | heure %.1f jour %d" % [found,
		Voyage.zone_now(), Game.flag(&"voyageur_rencontre"), Game.clock / 60.0, Game.day]


## The destination screen: its rows, and which ones can be picked.
static func rows() -> String:
	var screen := _screen()
	if screen == null:
		return "pas d'écran de voyage"
	var out := []
	for b in screen.find_children("*", "Button", true, false):
		var label := b.find_children("*", "Label", true, false)
		var text: String = (label[0] as Label).text if not label.is_empty() else (b as Button).text
		out.append("%s%s" % [text, " (grisé)" if (b as Button).disabled else ""])
	return "écran : " + ", ".join(out)


## Presses the destination screen's row whose name begins with `text` (« Rester » closes it).
static func press(text: String) -> String:
	var screen := _screen()
	if screen == null:
		return "pas d'écran de voyage"
	for b in screen.find_children("*", "Button", true, false):
		var label := b.find_children("*", "Label", true, false)
		var name_shown: String = (label[0] as Label).text if not label.is_empty() else (b as Button).text
		if name_shown.begins_with(text) and not (b as Button).disabled:
			(b as Button).pressed.emit()
			return "choisi : %s" % name_shown
	return "pas de ligne « %s »" % text


## Marks stops as already found (their flags), to test the list without walking the island.
static func know(regions: Array) -> String:
	for stop: Dictionary in Voyage.STOPS:
		if regions.has(String(stop["zone"])):
			Game.set_flag(stop["flag"])
	return report()


## Talks to Roc (his whole chain of scenes, the Grands Voyageurs among them).
static func roc() -> String:
	var prof = _tree().current_scene.get("region").entities.get_node_or_null("Roc")
	Story.run(&"roc", prof)
	return "on parle à Roc (%s)" % ("trouvé" if prof else "absent")


## The questions Chloé can ask (Ask.story_topics), in her words.
static func topics() -> String:
	var out := []
	for t: StringName in Ask.story_topics():
		out.append(Ask.label(&"roc", t))
	return "questions : " + ", ".join(out)
