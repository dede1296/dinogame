class_name BattleHud
extends Control
## The battle's screen furniture (BattleScene): the foe's panel, top left (name, level, type,
## health, its corruption and its calm gauge); Chloé's dino's, bottom left (its round portrait
## as in the party bar, health in numbers, experience, the Lien's hearts); a light message band
## along the bottom, like the zone banner; and in the bottom-right corner, under the thumb, the
## action wheel: a big round Attaquer, chosen by default, and around it Collier (with its count;
## it glows softly once the wild dino is worn out) or Apaiser (violet, against a corrupted dino),
## Sac, Dinos and Fuir. Every action is one tap. Attaquer, Sac and Dinos open their list in the
## same corner (the moves with their type, power points and a hint of how well they hit; the
## healing items; the party), with Retour. The choices come out as `chosen`, an action for
## BattleEngine.turn(). Keyboard and pad: the arrows turn around the wheel, « cancel » goes back.
## Its panels, cards and round buttons are drawn by battle/hud_parts.gd.

signal chosen(action: Dictionary)

const ICON_ATTACK := preload("res://assets/art/ui/hud_griffe.png")
const ICON_TEAM := preload("res://assets/art/ui/hud_dinos.png")
const ICON_RUN := preload("res://assets/art/ui/hud_fuir.png")
const ICON_CALM := preload("res://assets/art/ui/hud_apaiser.png")
const ICON_BAG := preload("res://assets/art/ui/sac.png")
const PARTS := preload("res://battle/hud_parts.gd")
const INK_TOP := PARTS.INK_TOP
const INK_BOTTOM := PARTS.INK_BOTTOM
const GOLD := PARTS.GOLD
const CREAM := PARTS.CREAM
const MUTED := PARTS.MUTED
const VIOLET := Color(0.62, 0.34, 0.95)   # black amber: a corrupted dino, the Apaiser action
const CALM := Color(0.98, 0.84, 0.45)     # its calm gauge
const ATTACK_RED := Color(0.84, 0.36, 0.2)
const COLLAR_AMBER := Color(0.86, 0.56, 0.18)
const BAG_GREEN := Color(0.4, 0.56, 0.28)
const TEAM_BLUE := Color(0.26, 0.5, 0.72)
const RUN_SLATE := Color(0.44, 0.5, 0.58)
const GOOD := Color(0.45, 0.85, 0.4)
const BAD := Color(0.9, 0.42, 0.34)
const STATUS := {"saigne": ["saigne", Color(0.86, 0.28, 0.26)], "etourdi": ["étourdi", Color(0.9, 0.74, 0.25)],
	"peur": ["a peur", Color(0.45, 0.62, 0.95)]}
## The wheel: its box (bottom-right corner), the big button's centre in it, the satellites' circle
## and their angles (degrees, screen axes: -90 straight up), from the top towards the left.
const WHEEL := Vector2(352, 352)
const HUB := Vector2(276, 264)
const BIG_D := 128.0
const SMALL_D := 78.0
const BACK_D := 66.0
const ORBIT := 152.0
const ANGLES := [-92.0, -126.0, -160.0, -194.0]
const CARD := PARTS.CARD
const GAP := 10.0
const BAND_H := 60.0
const FOE_W := 330.0
const MINE_W := 240.0   # the text column next to the portrait
## The wild dino is worn out (the Collier glows): at or below this share of its PV.
const WORN := 0.4
const POP_S := 0.18


var engine: BattleEngine
var rules := {}
## The panels' parts (BattleScene reads them): "box", "name", "level", "status", "hp", …
var foe := {}
var mine := {}
var message: Label
var wheel: Control
var moves_panel: Control
var bag_panel: Control
var team_panel: Control
var attack_button: PARTS.RoundButton
var collar_button: PARTS.RoundButton
var calm_button: PARTS.RoundButton
var bag_button: PARTS.RoundButton
var team_button: PARTS.RoundButton
var run_button: PARTS.RoundButton

var _band: Control
var _tap_hint: Label
var _panels: Dictionary = {}   # name -> Control
var _shown := ""
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_foe_panel()
	_build_my_panel()
	_build_band()
	say("")
	_build_wheel()
	moves_panel = _list_panel()
	bag_panel = _list_panel()
	team_panel = _list_panel()
	_panels = {"wheel": wheel, "moves": moves_panel, "bag": bag_panel, "team": team_panel}
	show_panel("")
	get_viewport().size_changed.connect(_layout)
	_layout()


## The battle's engine and rules ("catch", "run"…), before the intro.
func bind(battle: BattleEngine, battle_rules: Dictionary) -> void:
	engine = battle
	rules = battle_rules
	(foe["calm"] as PARTS.Gauge).max_value = engine.calm_full
	(foe["calm"] as PARTS.Gauge).value = engine.calm
	refresh(foe, engine.foe)
	refresh(mine, engine.player())


func _process(delta: float) -> void:
	_t += delta
	_tap_hint.modulate.a = 0.45 + 0.55 * absf(sin(_t * 3.0)) if _tap_hint.visible else 0.0
	if collar_button and wheel.visible and collar_button.visible and engine:
		collar_button.pulse = not collar_button.disabled and engine.foe.hp <= engine.foe.max_hp() * WORN


# ------------------------------------------------------------------ messages

## Shows a line in the band; `waiting`: a little ▼ says a tap goes on.
func say(text: String, waiting := false) -> void:
	message.text = text
	_band.visible = text != ""
	_tap_hint.visible = waiting


func stop_waiting() -> void:
	_tap_hint.visible = false


# ------------------------------------------------------------------ panels of the fighters

## Shows dino `d` in `panel` (foe or mine).
func refresh(panel: Dictionary, d: Dino) -> void:
	panel["level"].text = "Niv. %d" % d.level
	_set_status(panel["status"], d)
	(panel["hp"] as PARTS.Gauge).max_value = d.max_hp()
	(panel["hp"] as PARTS.Gauge).value = d.hp
	if panel == foe:
		panel["name"].text = d.species_name()
		panel["name"].add_theme_color_override("font_color", Color(0.84, 0.7, 1.0) if d.corrupted else CREAM)
		var type_colour: Color = MovesDB.TYPE_COLORS.get(d.type(), CREAM)
		panel["type"].get_child(0).text = MovesDB.TYPE_NAMES.get(d.type(), d.type())
		(panel["type"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = type_colour
		(panel["box"].material as ShaderMaterial).set_shader_parameter("edge", VIOLET.lightened(0.15) if d.corrupted else GOLD)
		panel["calm_row"].visible = d.corrupted or (engine != null and engine.calm > 0 and d == engine.foe)
	else:
		panel["name"].text = d.nickname
		panel["hp_text"].text = "%d / %d PV" % [d.hp, d.max_hp()]
		(panel["xp"] as PARTS.Gauge).max_value = Dino.xp_to_next(d.level)
		(panel["xp"] as PARTS.Gauge).value = d.xp
		(panel["hearts"] as PARTS.Hearts).bond = d.bond
		(panel["portrait"] as PARTS.Portrait).dino = d
		panel["portrait"].queue_redraw()
	_layout()


func tween_hp(panel: Dictionary, hp: int, max_hp: int) -> void:
	var bar: PARTS.Gauge = panel["hp"]
	bar.max_value = max_hp
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		bar.value = v
		if panel.has("hp_text"):
			panel["hp_text"].text = "%d / %d PV" % [roundi(v), max_hp], bar.value, float(hp), 0.5)
	await t.finished


func tween_xp(d: Dino) -> void:
	var bar: PARTS.Gauge = mine["xp"]
	bar.max_value = Dino.xp_to_next(d.level)
	await create_tween().tween_property(bar, "value", float(d.xp), 0.6).finished


func tween_calm(calm: int) -> void:
	foe["calm_row"].visible = true
	await create_tween().tween_property(foe["calm"], "value", float(calm), 0.45).finished


func _set_status(chip: PanelContainer, d: Dino) -> void:
	var what: Array = ["corrompu", VIOLET] if d.corrupted else STATUS.get(d.status, [])
	chip.visible = not what.is_empty()
	if chip.visible:
		chip.get_child(0).text = what[0]
		(chip.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = what[1]


func _build_foe_panel() -> void:
	var box := PARTS.frame(INK_TOP, INK_BOTTOM, GOLD, 16.0, Vector4(16, 10, 16, 12))
	box.custom_minimum_size = Vector2(FOE_W, 0)
	add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	box.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	col.add_child(top)
	var name_label := PARTS.label("", 22, CREAM)
	top.add_child(name_label)
	var type_pill := PARTS.pill("", 14, CREAM, Color(0.1, 0.08, 0.05))
	type_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(type_pill)
	top.add_child(PARTS.spacer())
	var level := PARTS.label("", 17, GOLD)
	top.add_child(level)
	var hp := PARTS.Gauge.new()
	hp.custom_minimum_size = Vector2(0, 13)
	col.add_child(hp)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	var status := PARTS.pill("", 13, VIOLET, CREAM)
	row.add_child(status)
	var calm_row := HBoxContainer.new()
	calm_row.add_theme_constant_override("separation", 8)
	calm_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calm_row.visible = false
	calm_row.add_child(PARTS.label("Calme", 14, CALM))
	var calm := PARTS.Gauge.new()
	calm.kind = "calm"
	calm.max_value = BattleEngine.CALM_FULL
	calm.custom_minimum_size = Vector2(0, 9)
	calm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	calm_row.add_child(calm)
	row.add_child(calm_row)
	foe = {"box": box, "name": name_label, "type": type_pill, "level": level, "hp": hp, "status": status,
		"calm": calm, "calm_row": calm_row}


func _build_my_panel() -> void:
	var box := PARTS.frame(INK_TOP, INK_BOTTOM, GOLD, 18.0, Vector4(12, 10, 16, 10))
	add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var face := PARTS.Portrait.new()
	face.custom_minimum_size = Vector2(84, 84)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(face)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(MINE_W, 0)
	col.add_theme_constant_override("separation", 5)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	col.add_child(top)
	var name_label := PARTS.label("", 22, CREAM)
	top.add_child(name_label)
	var status := PARTS.pill("", 13, VIOLET, CREAM)
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(status)
	top.add_child(PARTS.spacer())
	var level := PARTS.label("", 17, GOLD)
	top.add_child(level)
	var hp := PARTS.Gauge.new()
	hp.custom_minimum_size = Vector2(0, 13)
	col.add_child(hp)
	var mid := HBoxContainer.new()
	col.add_child(mid)
	var hearts := PARTS.Hearts.new()
	hearts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(hearts)
	mid.add_child(PARTS.spacer())
	var hp_text := PARTS.label("", 16, CREAM)
	mid.add_child(hp_text)
	var xp := PARTS.Gauge.new()
	xp.kind = "xp"
	xp.custom_minimum_size = Vector2(0, 6)
	col.add_child(xp)
	mine = {"box": box, "portrait": face, "name": name_label, "level": level, "status": status, "hp": hp,
		"hp_text": hp_text, "xp": xp, "hearts": hearts}


## The message band: a golden strip, a dark band fading to the right (as the zone banner).
func _build_band() -> void:
	_band = Control.new()
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_band)
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.06, 0.055, 0.05, 0.86))
	g.add_point(0.62, Color(0.06, 0.055, 0.05, 0.62))
	g.set_color(g.get_point_count() - 1, Color(0.06, 0.055, 0.05, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 64
	tex.height = 4
	shade.texture = tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(shade)
	var strip := ColorRect.new()
	strip.color = GOLD
	strip.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	strip.offset_right = 4
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(strip)
	message = PARTS.label("", 22, CREAM)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	message.add_theme_constant_override("shadow_offset_y", 2)
	message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message.offset_left = 20
	message.offset_right = -70
	_band.add_child(message)
	_tap_hint = PARTS.label("▼", 18, GOLD)
	_tap_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_tap_hint.offset_left = -58
	_tap_hint.offset_right = -40
	_tap_hint.visible = false
	_band.add_child(_tap_hint)


# ------------------------------------------------------------------ the wheel

func _build_wheel() -> void:
	wheel = Control.new()
	wheel.size = WHEEL
	wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wheel)
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.05, 0.04, 0.03, 0.42))
	g.add_point(0.55, Color(0.05, 0.04, 0.03, 0.22))
	g.set_color(g.get_point_count() - 1, Color(0.05, 0.04, 0.03, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	shade.texture = tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.size = Vector2.ONE * (ORBIT + SMALL_D) * 2.3
	shade.position = HUB - shade.size / 2.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wheel.add_child(shade)
	attack_button = PARTS.round_button(ATTACK_RED, ICON_ATTACK, "Attaquer", BIG_D, "attaquer")
	attack_button.pressed.connect(func() -> void: show_panel("moves"))
	collar_button = PARTS.round_button(COLLAR_AMBER, ItemsDB.icon("collier"), "Collier", SMALL_D, "collier")
	collar_button.pressed.connect(func() -> void:
		if Game.use_item("collier"):
			chosen.emit({"type": "catch"}))
	calm_button = PARTS.round_button(VIOLET, ICON_CALM, "Apaiser", SMALL_D, "apaiser")
	calm_button.visible = false
	calm_button.pressed.connect(func() -> void: chosen.emit({"type": "calm"}))
	bag_button = PARTS.round_button(BAG_GREEN, ICON_BAG, "Sac", SMALL_D, "sac")
	bag_button.pressed.connect(func() -> void: show_panel("bag"))
	team_button = PARTS.round_button(TEAM_BLUE, ICON_TEAM, "Dinos", SMALL_D, "dinos")
	team_button.pressed.connect(func() -> void: show_panel("team"))
	run_button = PARTS.round_button(RUN_SLATE, ICON_RUN, "Fuir", SMALL_D, "fuir")
	run_button.pressed.connect(func() -> void: chosen.emit({"type": "run"}))
	for b: PARTS.RoundButton in [collar_button, calm_button, bag_button, team_button, run_button, attack_button]:
		wheel.add_child(b)


## The satellites of this battle, from the top towards the left: Collier (or Apaiser) first, the
## farthest from the thumb last (Fuir). Places them, and the arrows go round them.
func _fill_wheel() -> void:
	var corrupted := engine.foe.corrupted
	collar_button.visible = rules.get("catch", true) and not corrupted
	calm_button.visible = corrupted
	run_button.visible = rules.get("run", true)
	collar_button.badge = Game.item_count("collier")
	collar_button.enable(Game.item_count("collier") > 0)
	var heals := 0
	for id: String in BattleEngine.HEAL_ITEMS:
		heals += Game.item_count(id)
	bag_button.badge = heals
	bag_button.enable(heals > 0)
	var others := 0
	for i in engine.team.size():
		if engine.can_switch_to(i):
			others += 1
	team_button.enable(others > 0)
	attack_button.position = HUB - attack_button.size / 2.0
	var ring: Array[PARTS.RoundButton] = [attack_button]
	var k := 0
	for b: PARTS.RoundButton in [collar_button, calm_button, bag_button, team_button, run_button]:
		if not b.visible:
			continue
		var a := deg_to_rad(ANGLES[k])
		k += 1
		b.set_meta(&"home", HUB + Vector2(cos(a), sin(a)) * ORBIT - b.size / 2.0)
		if not b.disabled:
			ring.append(b)
	for i in ring.size():
		var b := ring[i]
		var next := b.get_path_to(ring[(i + 1) % ring.size()])
		var back := b.get_path_to(ring[(i - 1 + ring.size()) % ring.size()])
		b.focus_neighbor_left = next
		b.focus_neighbor_top = next
		b.focus_next = next
		b.focus_neighbor_right = back
		b.focus_neighbor_bottom = back
		b.focus_previous = back


## The satellites come out of the big button.
func _open_wheel() -> void:
	var i := 0
	for b in wheel.get_children():
		if b == attack_button or not b.visible or not b is PARTS.RoundButton:
			continue
		var home: Vector2 = b.get_meta(&"home")
		b.position = HUB - b.size / 2.0
		b.modulate.a = 0.0
		var t := create_tween().set_parallel(true)
		t.tween_property(b, "position", home, 0.22).set_delay(i * 0.03).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(b, "modulate:a", 1.0, 0.12).set_delay(i * 0.03)
		i += 1
	_pop(attack_button, 0.9)


# ------------------------------------------------------------------ the lists

## Shows one of "wheel", "moves", "bag", "team" ("": none, while the lines play).
func show_panel(which: String) -> void:
	_shown = which
	for key: String in _panels:
		_panels[key].visible = key == which
	match which:
		"wheel":
			_fill_wheel()
			_open_wheel()
			attack_button.grab_focus()
		"moves", "bag", "team":
			_fill_list(which)
			_place_list(_panels[which])
			_pop(_panels[which], 0.92)
			var grid: GridContainer = _panels[which].get_meta(&"grid")
			var first := _first_enabled(grid)
			(first if first else _panels[which].get_meta(&"back") as Control).grab_focus()


## Is Chloé choosing (the wheel or a list on screen)?
func is_open() -> bool:
	return _shown != ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel") and _shown in ["moves", "bag", "team"]:
		get_viewport().set_input_as_handled()
		show_panel("wheel")


## Presses the button `id` on screen, as a tap would (the test tool: tools/capture.gd
## « hud_tap »): "attaquer", "collier", "apaiser", "sac", "dinos", "fuir", "retour", "move:0",
## "item:baie", "dino:1". Returns false when it is not there, or cannot be pressed.
func tap(id: String) -> bool:
	for b: BaseButton in find_children("*", "BaseButton", true, false):
		if b.is_visible_in_tree() and not b.disabled and String(b.get_meta(&"tap_id", "")) == id:
			b.pressed.emit()
			return true
	return false


## A list in the wheel's corner: its title and Retour above, its cards below (two columns).
func _list_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 6)
	add_child(panel)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_END
	panel.add_child(head)
	var title := PARTS.label("", 21, GOLD)
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04, 0.95))
	title.add_theme_constant_override("outline_size", 7)
	title.size_flags_vertical = Control.SIZE_SHRINK_END
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var back := PARTS.round_button(RUN_SLATE, null, "Retour", BACK_D, "retour", "◀")
	back.pressed.connect(func() -> void: show_panel("wheel"))
	var holder := Control.new()   # (the round button keeps its own size and bounce)
	holder.custom_minimum_size = back.size + Vector2(0, 6)
	holder.add_child(back)
	head.add_child(holder)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	panel.add_child(grid)
	panel.set_meta(&"title", title)
	panel.set_meta(&"grid", grid)
	panel.set_meta(&"back", back)
	return panel


func _fill_list(which: String) -> void:
	var panel: Control = _panels[which]
	var grid: GridContainer = panel.get_meta(&"grid")
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var d := engine.player()
	match which:
		"moves":
			panel.get_meta(&"title").text = "Attaques de %s" % d.nickname
			for i in d.moves.size():
				grid.add_child(_move_card(i))
		"bag":
			panel.get_meta(&"title").text = "Soigner %s" % d.nickname
			for id: String in BattleEngine.HEAL_ITEMS:
				if Game.item_count(id) > 0:
					grid.add_child(_item_card(id))
		"team":
			panel.get_meta(&"title").text = "Changer de dino"
			for i in engine.team.size():
				grid.add_child(_dino_card(i))
	var cards := grid.get_children()
	for i in cards.size():   # the arrows stay in the list, then reach Retour
		var card: Control = cards[i]
		if i < 2:
			card.focus_neighbor_top = card.get_path_to(panel.get_meta(&"back"))


func _place_list(panel: Control) -> void:
	panel.reset_size()
	var view := get_viewport_rect().size
	var inset := SafeArea.insets(get_viewport())
	panel.position = view - inset - panel.size
	panel.pivot_offset = panel.size


## A move: its name, its type and power points on its type's colour; on a tag at its corner, how
## well it would hit the foe (▲ fort, ▼ faible), or that it cannot reach the foe hidden in the abyss.
## Under the sea, what the water does to it (▲ ▼ sous l'eau).
func _move_card(i: int) -> Button:
	var slot: Dictionary = engine.player().moves[i]
	var move := MovesDB.move(slot["id"])
	var colour: Color = MovesDB.TYPE_COLORS.get(move["type"], CREAM)
	var card := PARTS.card_button(Color(colour.darkened(0.42), 0.95), Color(colour.darkened(0.7), 0.95), GOLD, "move:%d" % i)
	var detail := "%s · PP %d/%d" % [MovesDB.TYPE_NAMES.get(move["type"], ""), slot["pp"], move["pp"]]
	var water := ""
	if engine is UnderwaterEngine:
		water = (engine as UnderwaterEngine).mark(move["type"]).strip_edges()
	if water != "":
		detail += "  %s sous l'eau" % water
	var row: HBoxContainer = card.get_meta(&"row")
	row.add_child(PARTS.gem(colour))
	row.add_child(PARTS.two_lines(move["name"], detail))
	var hint := engine.move_hint(i)
	if engine is UnderwaterEngine and (engine as UnderwaterEngine).out_of_reach(i):
		_corner_tag(card, PARTS.pill("hors d'atteinte", 13, Color(0.16, 0.2, 0.32), CREAM))
	elif hint != 0:
		_corner_tag(card, PARTS.pill("▲ fort" if hint > 0 else "▼ faible", 13, GOOD.darkened(0.35) if hint > 0 else BAD.darkened(0.3), CREAM))
	card.pressed.connect(func() -> void: chosen.emit({"type": "move", "index": i}))
	PARTS.enable_card(card, slot["pp"] > 0)
	return card


## A healing item: its picture, what it does, how many are left. Given to the dino in battle.
func _item_card(id: String) -> Button:
	var card := PARTS.card_button(INK_TOP, INK_BOTTOM, GOLD, "item:%s" % id)
	var row: HBoxContainer = card.get_meta(&"row")
	var icon := TextureRect.new()
	icon.texture = ItemsDB.icon(id)
	icon.custom_minimum_size = Vector2(54, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var usable := engine.can_use_item(id)
	var what := "Soin complet" if id == "fougere" else "+%d PV" % Game.BERRY_HP
	row.add_child(PARTS.two_lines(String(ItemsDB.item(id)["name"]).get_slice(" ", 0), what if usable else "PV au maximum"))
	row.add_child(PARTS.label("×%d" % Game.item_count(id), 22, GOLD))
	card.pressed.connect(func() -> void: chosen.emit({"type": "item", "id": id}))
	PARTS.enable_card(card, usable)
	return card


## A dino of the party: portrait, level, health. The one in battle and the knocked-out ones
## cannot be sent in.
func _dino_card(i: int) -> Button:
	var d: Dino = engine.team[i]
	var card := PARTS.card_button(INK_TOP, INK_BOTTOM, GOLD, "dino:%d" % i)
	var row: HBoxContainer = card.get_meta(&"row")
	var face := PARTS.Portrait.new()
	face.dino = d
	face.small = true
	face.custom_minimum_size = Vector2(58, 58)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(face)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 3)
	row.add_child(col)
	col.add_child(PARTS.fitted(PARTS.label(d.nickname, 18, CREAM)))
	var hp := PARTS.Gauge.new()
	hp.max_value = d.max_hp()
	hp.value = d.hp
	hp.custom_minimum_size = Vector2(0, 8)
	col.add_child(hp)
	var bottom := HBoxContainer.new()
	var info := "K.O." if d.hp <= 0 else "Au combat" if i == engine.active else "%d / %d PV" % [d.hp, d.max_hp()]
	bottom.add_child(PARTS.fitted(PARTS.label(info, 13, BAD if d.hp <= 0 else GOLD if i == engine.active else MUTED)))
	bottom.add_child(PARTS.label("Niv. %d" % d.level, 13, GOLD))
	col.add_child(bottom)
	card.pressed.connect(func() -> void: chosen.emit({"type": "switch", "index": i}))
	PARTS.enable_card(card, engine.can_switch_to(i))
	if d.hp <= 0:
		face.modulate = Color(0.6, 0.6, 0.6)
	return card


## A little tag across the top-right corner of a card.
func _corner_tag(card: Control, tag: Control) -> void:
	card.add_child(tag)
	tag.reset_size()
	tag.position = Vector2(CARD.x - tag.size.x - 10.0, -tag.size.y * 0.45)


func _first_enabled(grid: GridContainer) -> Control:
	for c in grid.get_children():
		if c is BaseButton and not (c as BaseButton).disabled:
			return c
	return null


# ------------------------------------------------------------------ layout

func _layout() -> void:
	if wheel == null:
		return
	var view := get_viewport_rect().size
	var inset := SafeArea.insets(get_viewport())
	foe["box"].reset_size()
	foe["box"].position = inset
	var list_w := CARD.x * 2.0 + GAP
	var band_w := minf(view.x - inset.x * 2.0 - list_w - 12.0, 820.0)
	_band.position = Vector2(inset.x, view.y - inset.y - BAND_H)
	_band.size = Vector2(band_w, BAND_H)
	mine["box"].reset_size()
	mine["box"].position = Vector2(inset.x, _band.position.y - 8.0 - mine["box"].size.y)
	wheel.position = view - inset - WHEEL
	for key: String in ["moves", "bag", "team"]:
		if _panels.has(key) and _panels[key].visible:
			_place_list(_panels[key])


## Appears with a small spring (`from`: its starting scale).
func _pop(c: Control, from: float) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2.ONE * from
	var t := create_tween().set_parallel(true)
	t.tween_property(c, "modulate:a", 1.0, POP_S * 0.7)
	t.tween_property(c, "scale", Vector2.ONE, POP_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
