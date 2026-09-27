class_name DebugMenu
extends CanvasLayer
## Test panel (hold the clock badge, or F2): time of day and its speed, weather, any dino at
## the head of the party or as a wild opponent, healing, experience, items, zones, the
## performance overlay. The game is paused while it is open.

const LAYER := 85
const CREAM := Color(1, 0.97, 0.9)
const AMBER := Color(0.98, 0.76, 0.35)
const INK := Color(0.106, 0.122, 0.157, 0.97)
const HOURS := [["Aube", 6.0], ["Midi", 12.0], ["Crépuscule", 19.0], ["Nuit", 23.0]]
const SPEEDS := [1.0, 10.0, 60.0]
const WEATHER_NAMES := {&"clear": "Beau temps", &"rain": "Pluie", &"mist": "Brume", &"storm": "Orage", &"sandstorm": "Sable"}

var _was_paused := false
var _species_ids: Array = []
var _species_index := 0
var _level := 5
var _species_label: Label
var _level_label: Label
var _status: Label
var _message := ""


static func open(from: Node) -> void:
	if from.get_tree().root.find_children("*", "DebugMenu", false, false).size() > 0:
		return
	from.get_tree().root.add_child(DebugMenu.new())


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_species_ids = SpeciesDB.all_ids()
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var inset := SafeArea.insets(get_viewport())
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, int(inset.x + 60))
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, int(inset.y + 8))
	add_child(margin)
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = INK
	box.border_color = Color(0.79, 0.54, 0.16)
	box.set_border_width_all(3)
	box.set_corner_radius_all(18)
	box.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", box)
	margin.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	scroll.add_child(col)

	var head := HBoxContainer.new()
	head.add_child(_label("Débogage", 30, AMBER, true))
	var close := _button("Fermer", _close)
	close.custom_minimum_size.x = 160
	head.add_child(close)
	col.add_child(head)
	_status = _label("", 17, Color(CREAM, 0.75))
	col.add_child(_status)

	col.add_child(_label("Heure", 22, CREAM))
	var hours := _row(col)
	for h: Array in HOURS:
		hours.add_child(_button("%s (%dh)" % [h[0], h[1]], _set_hour.bind(h[1])))
	hours.add_child(_button("+1 h", func() -> void: Game.clock = fmod(Game.clock + 60.0, 1440.0)))
	var speeds := _row(col)
	for s: float in SPEEDS:
		speeds.add_child(_button("Temps ×%d" % s, func() -> void: Game.time_scale = s))

	col.add_child(_label("Météo", 22, CREAM))
	var weather := _row(col)
	for w: StringName in Game.WEATHERS:
		weather.add_child(_button(WEATHER_NAMES[w], Game.set_weather.bind(w)))

	col.add_child(_label("Dinos", 22, CREAM))
	var pick := _row(col)
	pick.add_child(_button("◀", _cycle_species.bind(-1)))
	_species_label = _label("", 22, CREAM, true)
	_species_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick.add_child(_species_label)
	pick.add_child(_button("▶", _cycle_species.bind(1)))
	pick.add_child(_button("Niv. −", _change_level.bind(-1)))
	_level_label = _label("", 22, CREAM)
	pick.add_child(_level_label)
	pick.add_child(_button("Niv. +", _change_level.bind(1)))
	var act := _row(col)
	act.add_child(_button("Mettre en tête", _lead_dino))
	act.add_child(_button("Combattre", _fight))
	act.add_child(_button("Soigner l'équipe", func() -> void:
		Game.heal_party()
		Game.party_changed.emit()
		_say("Équipe soignée.")))
	# The level above is the one of a new dino; these change the party's own dinos.
	var team := _row(col)
	team.add_child(_label("Mon équipe :", 22, CREAM))
	for step: int in [-1, 1, 5]:
		team.add_child(_button("Niv. %+d" % step, _party_level.bind(step)))
	act.add_child(_button("+100 xp", func() -> void:
		for d in Game.party:
			Game.award_xp(d, 100)
		_say("+100 xp pour l'équipe.")))

	col.add_child(_label("Objets", 22, CREAM))
	var items := _row(col)
	items.add_child(_button("+5 colliers", _give.bind("collier")))
	items.add_child(_button("+5 baies", _give.bind("baie")))
	items.add_child(_button("Gilet de nage", func() -> void:
		Game.give_item("gilet_nage")
		_say("Gilet de nage reçu : avec un dino nageur (Baryonyx…), Chloé peut nager.")))

	var world := _world()
	if world:
		col.add_child(_label("Zones", 22, CREAM))
		var zones := _row(col)
		for id: StringName in world.ZONES:
			zones.add_child(_button(String(id), _goto.bind(id)))

	col.add_child(_label("Affichage", 22, CREAM))
	var view := _row(col)
	view.add_child(_button("Performances (FPS)", func() -> void: Debug.visible = not Debug.visible))
	_refresh()


func _refresh() -> void:
	var species := SpeciesDB.get_species(_species_ids[_species_index])
	_species_label.text = species.display_name
	_level_label.text = "nouveau : niv. %d" % _level
	var minutes := int(Game.clock)
	_status.text = (_message + "   " if _message != "" else "") + "%02d:%02d · %s · temps ×%d · zone %s · équipe : %s" % [
		floori(minutes / 60.0), minutes % 60, WEATHER_NAMES.get(Game.weather, "?"), Game.time_scale,
		Game.region_id, ", ".join(Game.party.map(func(d: Dino) -> String: return "%s niv.%d" % [d.nickname, d.level]))]


func _say(text: String) -> void:
	_message = text
	_refresh()


func _set_hour(hour: float) -> void:
	Game.clock = hour * 60.0
	_refresh()


func _cycle_species(step: int) -> void:
	_species_index = posmod(_species_index + step, _species_ids.size())
	_refresh()


func _change_level(step: int) -> void:
	_level = clampi(_level + step * (5 if _level >= 10 else 1), 1, Dino.MAX_LEVEL)
	_refresh()


## Every dino of the party goes up (learning its moves on the way) or down `step` levels.
func _party_level(step: int) -> void:
	for d: Dino in Game.party:
		for i in absi(step):
			if step > 0 and d.level < Dino.MAX_LEVEL:
				d.gain_xp(Dino.xp_to_next(d.level) - d.xp)
			elif step < 0 and d.level > 1:
				d.level -= 1
				d.xp = 0
				d.hp = mini(d.hp, d.max_hp())
	Game.party_changed.emit()
	_say("Équipe : " + ", ".join(Game.party.map(func(d: Dino) -> String: return "%s niv.%d" % [d.nickname, d.level])))


## The chosen dino joins at the head of the party (the last one goes to the box if full).
func _lead_dino() -> void:
	var d := Dino.create(_species_ids[_species_index], _level)
	Game.mark_caught(d.species().id)
	Game.party.insert(0, d)
	while Game.party.size() > Game.PARTY_MAX:
		Game.box.append(Game.party.pop_back())
	Game.party_changed.emit()
	_say("%s niv.%d en tête." % [d.nickname, d.level])


func _fight() -> void:
	var world := _world()
	if world == null:
		_say("Pas de monde chargé.")
		return
	var wild := Dino.create(_species_ids[_species_index], _level)
	_close()
	world.call(&"_battle", wild)


func _give(item: String) -> void:
	Game.items[item] = Game.item_count(item) + 5
	_say("%s : %d." % [item, Game.item_count(item)])


func _goto(id: StringName) -> void:
	var world := _world()
	_close()
	if world:
		world.call(&"goto_zone", id)


func _world() -> Node:
	var scene := get_tree().current_scene
	return scene if scene and "ZONES" in scene else null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()


func _close() -> void:
	if is_queued_for_deletion():
		return
	get_tree().paused = _was_paused
	queue_free()


func _row(parent: Control) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	parent.add_child(row)
	return row


func _label(text: String, font_size: int, colour: Color, expand := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if expand:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.45, 0.29, 0.08) if state == "pressed" else Color(0.16, 0.18, 0.22)
		s.border_color = Color(0.79, 0.54, 0.16)
		s.set_border_width_all(2)
		s.set_corner_radius_all(10)
		s.content_margin_left = 16
		s.content_margin_right = 16
		b.add_theme_stylebox_override(state, s)
	b.add_theme_color_override("font_color", CREAM)
	b.pressed.connect(func() -> void:
		action.call()
		if is_instance_valid(self) and not is_queued_for_deletion():
			_refresh())
	return b
