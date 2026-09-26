class_name MapScreen
extends CanvasLayer
## The map, opened from the map button or M (the game is paused meanwhile). Two levels:
##   the island (IslandMap): every region, the visited ones coloured; a tap opens one;
##   a zone (ZoneMap): its detailed map, to move around and zoom (zoom out past it: the
##   island again), with Chloé, the objectives, the places found, the people, the fires.
## Beside the map, the objectives (Objectives): a tap on one shows where it is.

signal closed

const LAYER := 80
const TILE := 48.0
const GOLD := Color(1, 0.86, 0.5)
const CREAM := Color(1, 0.97, 0.9)
const SIDE_WIDTH := 300.0
## The zones with a detailed map (outdoors).
const DETAILED := [&"plaines", &"port_ambre", &"havre_dore"]

var _zones := {}            # zone id -> scene path (world.gd ZONES)
var _here: Region           # Chloé's zone (the one being played)
var _here_layers := {}
var _chloe := Vector2.INF   # tiles, in _here
var _shown: StringName      # the zone on screen (&"" = the island)
var _preview: Region        # another zone, loaded to be drawn
var _was_paused := false
var _title: Label
var _stats: HBoxContainer
var _island_button: Button
var _body: Control
var _map: Control
var _list: VBoxContainer
var _zoom_buttons: VBoxContainer


## Opens the map over `parent`'s scene: the detailed map of `region` (Chloé at `chloe_tile`,
## drawn from `layers`: WorldView.map_layers), or the island when it has none (indoors).
static func open(parent: Node, region: Region, layers: Dictionary, chloe_tile: Vector2, zones: Dictionary) -> MapScreen:
	var map := MapScreen.new()
	map._here = region
	map._here_layers = layers
	map._chloe = chloe_tile
	map._zones = zones
	parent.get_tree().root.add_child(map)
	return map


## Adds the round « map » button under the menu button of a HUD layer.
static func add_open_button(hud: CanvasLayer, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.name = "MapButton"
	button.custom_minimum_size = Vector2(76, 76)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Carte (M)"
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, SettingsMenu._box(Color(SettingsMenu.INK, 0.7 if state == "normal" else 0.9), 38, 2))
	var icon := Control.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.draw.connect(_draw_icon.bind(icon))
	button.add_child(icon)
	hud.add_child(button)
	var place := func() -> void:
		var inset := SafeArea.insets(button.get_viewport())
		var screen := button.get_viewport().get_visible_rect().size
		button.position = Vector2(screen.x - inset.x - button.custom_minimum_size.x, inset.y + 86.0)
	place.call()
	button.get_viewport().size_changed.connect(place)
	button.pressed.connect(on_pressed)
	return button


## A folded map, three panels.
static func _draw_icon(icon: Control) -> void:
	for i in 3:
		var x := 20.0 + i * 12.0
		var up := 24.0 + (i % 2) * 4.0
		var down := 28.0 - (i % 2) * 4.0
		icon.draw_colored_polygon(PackedVector2Array([Vector2(x, up), Vector2(x + 12.0, down),
			Vector2(x + 12.0, down + 26.0), Vector2(x, up + 26.0)]), Color(SettingsMenu.CREAM, 1.0 if i % 2 == 0 else 0.72))
	icon.draw_circle(Vector2(40, 36), 4.5, ZoneMap.CHLOE)


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	_build()
	if _here and _here.region_id in DETAILED:
		_show_zone(_here.region_id)
	else:
		_show_island()


func _exit_tree() -> void:
	if _preview and is_instance_valid(_preview):
		_preview.free()


# ------------------------------------------------------------------ layout

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.01, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)   # also stops touches from reaching the game
	var inset := SafeArea.insets(get_viewport())
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = inset.x + 8.0
	panel.offset_right = -inset.x - 8.0
	panel.offset_top = inset.y
	panel.offset_bottom = -inset.y
	panel.add_theme_stylebox_override("panel", SettingsMenu._box(SettingsMenu.INK, 22, 3, 12))
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	col.add_child(head)
	_island_button = _round_button("◂ Île", 20)
	_island_button.custom_minimum_size = Vector2(96, 52)
	_island_button.pressed.connect(_show_island)
	head.add_child(_island_button)
	_title = _label("", 28, GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_stats = HBoxContainer.new()
	_stats.add_theme_constant_override("separation", 14)
	head.add_child(_stats)
	var close := _round_button("✕", 26)
	close.pressed.connect(_close)
	head.add_child(close)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(row)
	_body = Control.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.clip_contents = true
	row.add_child(_body)
	row.add_child(_side_panel())


## Right: the objectives, and what the marks mean.
func _side_panel() -> Control:
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(SIDE_WIDTH, 0)
	side.add_theme_constant_override("separation", 6)
	side.add_child(_label("Objectifs", 22, GOLD))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	var legend := Control.new()
	legend.custom_minimum_size = Vector2(SIDE_WIDTH, 92)
	legend.draw.connect(_draw_legend.bind(legend))
	side.add_child(legend)
	return side


func _draw_legend(c: Control) -> void:
	var font := c.get_theme_default_font()
	var items := [[ZoneMap.CHLOE, "Toi"], [ZoneMap.GOAL, "Objectif"], [Color(0.35, 0.72, 0.95), "Quête annexe"],
		[ZoneMap.PEOPLE, "Personnage"], [ZoneMap.REST, "Feu, banc : repos"]]
	for i in items.size():
		var p := Vector2(12 + (i % 2) * 150, 14 + floori(i / 2.0) * 26)
		c.draw_circle(p, 7.0, items[i][0])
		c.draw_string(font, p + Vector2(14, 6), items[i][1], HORIZONTAL_ALIGNMENT_LEFT, 132, 13, Color(CREAM, 0.85))


func _fill_objectives() -> void:
	for c in _list.get_children():
		c.queue_free()
	var goals := Objectives.current()
	if goals.is_empty():
		_list.add_child(_wrapped("Rien de pressé. Explore, secoue les arbres, écoute l'île.", 16, Color(CREAM, 0.7)))
	var i := 0
	for o in goals:
		i += 1
		var b := Button.new()
		var followed: bool = o["id"] == String(Game.flag(&"suivi")) if Game.flag(&"suivi") else false
		# The title; the details only for the one picked (followed on screen).
		var head := "%d. %s" % [i, o["title"]] if o["tile"] != Vector2.INF else "• %s" % o["title"]
		b.text = ("▶ " + head + "
" + String(o["text"])) if followed else head
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", GOLD if o["main"] else CREAM)
		for state in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, SettingsMenu._box(Color(0.16, 0.18, 0.22, 1.0 if state == "normal" else 0.75), 10, 1, 8,
				Color(ZoneMap.GOAL if o["main"] else Color(0.35, 0.72, 0.95), 0.8)))
		# Picked: followed on screen (QuestTracker), and shown on its map.
		b.pressed.connect(func() -> void:
			Game.set_flag(&"suivi", o["id"])
			_fill_objectives()
			_go_to(o))
		_list.add_child(b)


## An objective picked in the list: its zone's map, centred on it.
func _go_to(o: Dictionary) -> void:
	var zone: StringName = o["zone"]
	if not zone in DETAILED:
		return
	if _shown != zone:
		_show_zone(zone)
	if o["tile"] != Vector2.INF and _map is ZoneMap:
		(_map as ZoneMap).focus(o["tile"])


# ------------------------------------------------------------------ the two levels

func _show_island() -> void:
	_clear_map()
	_shown = &""
	_title.text = "Ambrelune"
	_island_button.visible = false
	_set_stats([])
	var island := IslandMap.new()
	island.here = Game.region_id
	if _here:
		island.chloe_tile = _chloe
		island.zone_size = Vector2(_here.map_size())
	island.goals = Objectives.current()
	island.set_anchors_preset(Control.PRESET_FULL_RECT)
	island.zone_picked.connect(_show_zone)
	_body.add_child(island)
	_map = island
	_fill_objectives()


func _show_zone(zone: StringName) -> void:
	var region := _here if _here and zone == _here.region_id else _load(zone)
	if region == null:
		return
	_clear_map()
	_shown = zone
	_island_button.visible = true
	var here := _here and zone == _here.region_id
	var layers := _here_layers if here else WorldView.map_layers_for(region)
	var goals: Array[Dictionary] = []
	for o in Objectives.current():
		if o["zone"] == zone:
			goals.append(o)
	var m := ZoneMap.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.setup(region, zone, layers, goals, _chloe if here else Vector2.INF)
	m.zoomed_out.connect(_show_island)
	_body.add_child(m)
	_map = m
	_zoom_controls(m)
	_title.text = region.display_name
	var stats := []
	if region.pebbles > 0:
		stats.append(["Larmes : %d / %d" % [Game.pebbles_found(String(zone)), region.pebbles], GOLD])
	stats.append([_moon_text(), Color(0.8, 0.86, 1.0)])
	stats.append(["Exploré : %d %%" % floori(m.explored_share() * 100.0), Color(CREAM, 0.8)])
	_set_stats(stats)
	_fill_objectives()


## +, − and « me » over the zone map (for a phone: no wheel; pinching works too).
func _zoom_controls(m: ZoneMap) -> void:
	_zoom_buttons = VBoxContainer.new()
	_zoom_buttons.add_theme_constant_override("separation", 6)
	_zoom_buttons.position = Vector2(10, 10)
	for b: Array in [["+", func() -> void: m.zoom_by(1.5)], ["−", func() -> void: m.zoom_by(1.0 / 1.5)],
			["◎", func() -> void: m.focus(_chloe if m.chloe != Vector2.INF else m.centre)]]:
		var button := _round_button(b[0], 24)
		button.custom_minimum_size = Vector2(52, 52)
		button.pressed.connect(b[1])
		_zoom_buttons.add_child(button)
	_body.add_child(_zoom_buttons)


func _clear_map() -> void:
	for c in _body.get_children():
		c.queue_free()
	_map = null


## Another zone than Chloé's, loaded only to draw its map.
func _load(zone: StringName) -> Region:
	if not _zones.has(zone):
		return null
	if _preview and is_instance_valid(_preview):
		if _preview.region_id == zone:
			return _preview
		_preview.free()
	_preview = Region.open_for_preview(_zones[zone])
	return _preview


func _set_stats(items: Array) -> void:
	for c in _stats.get_children():
		c.queue_free()
	for s: Array in items:
		_stats.add_child(_label(s[0], 18, s[1]))


static func _moon_text() -> String:
	if Game.is_full_moon():
		return "Pleine lune !"
	var n := Game.nights_to_full_moon()
	return "Pleine lune : cette nuit" if n == 0 else "Pleine lune : dans %d nuit%s" % [n, "s" if n > 1 else ""]


# ------------------------------------------------------------------ closing

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"map"):
		get_viewport().set_input_as_handled()
		_close()


## Android back gesture / button.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()


func _close() -> void:
	if is_queued_for_deletion():
		return
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()


func _label(text: String, font_size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	return l


func _wrapped(text: String, font_size: int, colour: Color) -> Label:
	var l := _label(text, font_size, colour)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _round_button(text: String, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(56, 56)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", CREAM)
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, SettingsMenu._box(Color(0.16, 0.18, 0.22, 1.0 if state == "normal" else 0.8), 28, 2))
	return b
