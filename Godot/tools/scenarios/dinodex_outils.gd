extends RefCounted
## Helpers of the Dinodex scenarios (called with the « static » command of tools/capture.gd):
## a team and a reserve, species seen or not, the Dinodex opened, its pages and sheets, a dino
## dragged with the mouse (the Dinodex) or a finger (the party bar), what changed printed.


static func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func _dex() -> Node:
	for n in _tree().root.get_children():
		if n.get_script() == load("res://ui/dex_screen.gd"):
			return n
	return null


## Five in the team, three in the reserve; a few species only seen; the Forêt known (on the
## map), the Marais not.
static func setup() -> String:
	var game := _tree().root.get_node("Game")
	var dino: GDScript = load("res://game/dino.gd")
	for s: Array in [[&"compsognathus", 7, "Chipie"], [&"protoceratops", 6, "Pépite"], [&"dimorphodon", 7, ""], [&"troodon", 8, ""],
			[&"velociraptor", 6, "Griffou"], [&"stegosaurus", 12, "Plaquette"], [&"ankylosaurus", 9, ""]]:
		game.call("add_caught", dino.create(s[0], s[1], s[2]))
	for id: StringName in [&"psittacosaurus", &"deinonychus", &"triceratops", &"allosaurus"]:
		game.call("mark_seen", id)
	var explored: Dictionary = game.get("explored")
	explored["foret"] = PackedByteArray([255])
	return report()


static func open() -> String:
	_tree().current_scene.call("_open_dex")
	return "ouvert : %s" % (_dex() != null)


static func page(id: String) -> String:
	_dex().call("_show_page", StringName(id))
	return "page " + id


static func entry(id: String) -> String:
	_dex().call("_open_entry", StringName(id), null)
	return "fiche " + id


## The sheet's list scrolled down by `px`.
static func scroll_entry(px: int) -> String:
	for s in _dex().find_children("*", "ScrollContainer", true, false):
		if s.get_parent() is HBoxContainer:
			(s as ScrollContainer).scroll_vertical += px
			return "défilé : %d" % (s as ScrollContainer).scroll_vertical
	return "pas de liste"


## The team's place `i` in the Dinodex.
static func _slot(i: int) -> Control:
	for n in (_dex().get("_team") as Node).get_children():
		if n is DexTile and n.get("index") == i and not n.is_queued_for_deletion():
			return n
	return null


## The `i`-th tile of a dino of Chloé's on the page (the reserve, a sheet's list).
static func _owned_tile(i: int) -> Control:
	var tiles := (_dex().get("_main") as Node).find_children("*", "", true, false).filter(func(n: Node) -> bool:
		return n is DexTile and n.get("dino") != null and not n.is_queued_for_deletion())
	return tiles[i] if i < tiles.size() else null


static func _mouse(pressed: bool, at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	e.position = at
	e.global_position = at
	Input.parse_input_event(e)


static func _motion(at: Vector2, rel: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.button_mask = MOUSE_BUTTON_MASK_LEFT
	m.position = at
	m.global_position = at
	m.relative = rel
	Input.parse_input_event(m)


## The mouse takes tile `tile` of the page (a dino: the reserve, a sheet's list) to the
## team's place `slot`, and holds it there (drag_end lets go).
static func drag_begin(tile: int, slot: int) -> String:
	var from := _owned_tile(tile).get_global_rect().get_center()
	var to := _slot(slot).get_global_rect().get_center()
	_mouse(true, from)
	var steps := 4
	for k in range(1, steps + 1):
		_motion(from.lerp(to, k / float(steps)), (to - from) / steps)
	return "glisse %s -> %s" % [from, to]


static func drag_end(slot: int) -> String:
	_mouse(false, _slot(slot).get_global_rect().get_center())
	return report()


## Dropped nowhere (the middle of the page): nothing changes.
static func drag_nowhere(tile: int) -> String:
	var from := _owned_tile(tile).get_global_rect().get_center()
	var to := from + Vector2(-60, 40)
	_mouse(true, from)
	_motion(to, to - from)
	_mouse(false, to)
	return report()


## The sheet's first button whose text begins with `text` is pressed.
static func press(text: String) -> String:
	for b in _dex().find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(text) and (b as Button).is_visible_in_tree():
			(b as Button).pressed.emit()
			return "bouton « %s »" % (b as Button).text.replace("\n", " ")
	return "pas de bouton « %s »" % text


## The chooser (a full team): Chloé picks who goes to the reserve.
static func pick_leaver(i: int) -> String:
	var chooser: Node = _dex().get("_chooser")
	var buttons := chooser.find_children("*", "Button", true, false)
	(buttons[i] as Button).pressed.emit()
	return report()


# ------------------------------------------------------------------ the Dinodex with a finger

## (Input.use_accumulated_input off: each event handled at once and on its own, in order, as a real
## finger's moves come frame after frame — not merged into one.)
static func _finger(pressed: bool, at: Vector2) -> void:
	Input.use_accumulated_input = false
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = pressed
	t.position = at
	Input.parse_input_event(t)


static func _finger_to(from: Vector2, to: Vector2, steps: int) -> void:
	for k in range(1, steps + 1):
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = from.lerp(to, k / float(steps))
		d.relative = (to - from) / steps
		Input.parse_input_event(d)


## A finger takes tile `tile` of the page to the team's place `slot` as a thumb does on a phone:
## its first move (fx, fy px: e.g. a little more up than sideways), then to (ax, ay) px from the
## place's middle (the finger below it: it aims with the portrait drawn above it), and holds it
## there (finger_drop lets go; the input is only handled at the next frame).
static func finger_drag(tile: int, slot: int, fx: float, fy: float, ax: float, ay: float) -> String:
	var from := _owned_tile(tile).get_global_rect().get_center()
	var place := _slot(slot)
	var to := place.get_global_rect().get_center() + Vector2(ax, ay)
	_finger(true, from)
	_finger_to(from, from + Vector2(fx, fy), 3)
	_finger_to(from + Vector2(fx, fy), to, 6)
	_finger_at = to
	return "doigt %s -> %s (place %s)" % [from, to, place.get_global_rect()]


static var _finger_at := Vector2.ZERO


## What the finger carries and the place lit under it, then it lets go.
static func finger_drop() -> String:
	var drag := _dex().get("drag") as Node
	var said := "porté=%s survol=%d au doigt=%s" % [drag.call("active"), drag.get("_hover"), drag.get("_by_touch")]
	_finger(false, _finger_at)
	return said


# ------------------------------------------------------------------ the party bar (a finger)

static func _bar_slot(i: int) -> Control:
	var bar: Node = _tree().current_scene.find_children("*", "PartyBar", true, false)[0]
	return bar.get("_slots")[i]


static func _touch(pressed: bool, at: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = pressed
	t.position = at
	Input.parse_input_event(t)


static func bar_drag_begin(from_i: int, to_i: int) -> String:
	var from := _bar_slot(from_i).get_global_rect().get_center()
	var to := _bar_slot(to_i).get_global_rect().get_center()
	_touch(true, from)
	for k in range(1, 5):
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = from.lerp(to, k / 4.0)
		d.relative = (to - from) / 4.0
		Input.parse_input_event(d)
	return "doigt %s -> %s" % [from, to]


## A thumb takes portrait `from_i` of the party bar to portrait `to_i`, its tip (ax, ay) px from
## that one's middle (a thumb presses below the row), and holds it there (bar_drop lets go).
static func bar_thumb(from_i: int, to_i: int, ax: float, ay: float) -> String:
	var from := _bar_slot(from_i).get_global_rect().get_center()
	var to := _bar_slot(to_i).get_global_rect().get_center() + Vector2(ax, ay)
	_finger(true, from)
	_finger_to(from, from + Vector2(0.0, 20.0), 2)
	_finger_to(from + Vector2(0.0, 20.0), to, 6)
	_finger_at = to
	return "pouce %s -> %s (portrait visé %s)" % [from, to, _bar_slot(to_i).get_global_rect()]


static func bar_drop() -> String:
	var bar: Node = _tree().current_scene.find_children("*", "PartyBar", true, false)[0]
	var drag := bar.get("_drag") as Node
	var said := "porté=%s survol=%d à côté=%s pris en %s" % [drag.call("active"), drag.get("_hover"), drag.get("_beside"), drag.get("_origin")]
	_finger(false, _finger_at)
	return said


static func bar_drag_end(to_i: int) -> String:
	var modes := []
	for i in 5:
		modes.append(_bar_slot(i).get("_mode"))
	_touch(false, _bar_slot(to_i).get_global_rect().get_center())
	return "états des portraits %s, souris %d · %s" % [modes, Input.get_mouse_button_mask(), report()]


## The Dinodex opened as in the water (the team cannot change).
static func open_locked() -> String:
	load("res://ui/dex_screen.gd").open(_tree().current_scene, "Dans l'eau, on garde son équipe : reviens sur la terre ferme pour la changer.")
	return "ouvert (verrouillé) : %s" % (_dex() != null)


static func close() -> String:
	_dex().call("_close")
	return "fermé"


## The rules of the Dinodex's data and of the team, checked one by one (OK / ÉCHEC).
static func logic() -> String:
	var game := _tree().root.get_node("Game")
	var db: GDScript = load("res://data/dex_db.gd")
	var out: Array[String] = []
	var check := func(what: String, ok: bool) -> void: out.append("%s %s" % ["OK" if ok else "ÉCHEC", what])
	check.call("un Unique pas vu d'une région inconnue : personne n'en parle",
		db.call("hints", &"cryolophosaure_titan") == [db.get_script_constant_map()["NOBODY"]])
	check.call("une espèce pas vue d'une région connue : une rumeur de la région seulement",
		String(db.call("hints", &"parasaurolophus")[0]).contains("Prairie du Grand Crâne") and not String(db.call("hints", &"parasaurolophus")[0]).contains("étang"))
	check.call("une espèce vue : ses lieux précis", String(db.call("hints", &"psittacosaurus")[0]).contains("carrefour"))
	check.call("une espèce du Marais pas vue : rien (région inconnue)", db.call("hints", &"koolasuchus") == [db.get_script_constant_map()["NOBODY"]])
	check.call("39 espèces + 9 uniques", db.call("order").size() == 39 and db.call("uniques").size() == 9)
	check.call("chaque espèce a sa fiche et un lieu", db.call("order").all(func(id: StringName) -> bool:
		return not db.call("facts", id).is_empty() and not db.call("places", id).is_empty()))
	check.call("chaque unique a sa fiche", db.call("uniques").all(func(id: StringName) -> bool: return not db.call("facts", id).is_empty()))
	var party: Array = game.get("party")
	var box: Array = game.get("box")
	var n_party := party.size()
	check.call("pas d'échange hors limites", not game.call("swap_party", 0, 9) and not game.call("from_box", 99, 0) and not game.call("to_box", 9))
	check.call("équipe pleine : pas d'ajout au bout", n_party < 5 or not game.call("from_box", 0, 5))
	# Chloé in a scene: the Dinodex does not open.
	var player: Node = _tree().current_scene.get("player")
	player.set("busy", true)
	_tree().current_scene.call("_open_dex")
	check.call("pas de Dinodex pendant une scène", _dex() == null)
	player.set("busy", false)
	check.call("réserve intacte", box.size() == (game.get("box") as Array).size())
	return "\n".join(out)


## `n` more species caught (the first ones not caught yet), for Roc's rewards.
static func catch_more(n: int) -> String:
	var game := _tree().root.get_node("Game")
	for id: StringName in load("res://data/dex_db.gd").call("order"):
		if n <= 0:
			break
		if game.call("mark_caught", id):
			n -= 1
	return "récompenses en attente : " + str(load("res://data/dex_db.gd").call("pending_rewards").map(func(r: Dictionary) -> String: return String(r["flag"])))


## A key of the keyboard pressed and let go (physical code: KEY_X, KEY_RIGHT…).
static func key(code: int) -> String:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.physical_keycode = code as Key
		e.keycode = code as Key
		e.pressed = pressed
		Input.parse_input_event(e)
	return "touche %s" % OS.get_keycode_string(code)


# ------------------------------------------------------------------ what changed

static func report() -> String:
	var game := _tree().root.get_node("Game")
	var names := func(list: Array) -> String: return ", ".join(list.map(func(d: RefCounted) -> String: return "%s(%s)" % [d.get("nickname"), d.call("species").id]))
	var world := _tree().current_scene
	var companion: Node = world.get("companion") if world else null
	var follows: String = String(companion.get("dino").nickname) if companion and companion.get("dino") else "?"
	return "équipe=[%s] réserve=[%s] compagnon=%s vus=%d possédés=%d" % [names.call(game.get("party")), names.call(game.get("box")), follows,
		(game.get("dex_seen") as Dictionary).size(), (game.get("dex_caught") as Dictionary).size()]


static func seen(id: String) -> String:
	var game := _tree().root.get_node("Game")
	return "%s vu=%s où=%s" % [id, (game.get("dex_seen") as Dictionary).has(id), (game.get("dex_where") as Dictionary).get(id, "-")]
