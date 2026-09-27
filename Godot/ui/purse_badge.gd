class_name PurseBadge
extends PanelContainer
## What Chloé carries, at a glance, under the clock: coins, amber tears (the pebbles found and
## not sold), collars and berries. A number that changes bounces, gold when it went up.

const ITEMS := ["piece", "larmes", "collier", "baie"]   # "larmes": Game.tears()
## The coins have no shop entry; the tears look like the pebbles found in the world.
const ICONS := {"piece": preload("res://assets/art/ui/piece.png"), "larmes": preload("res://assets/art/props/galet.png")}
const ICON_SIZE := 30.0
const GAP_UNDER_CLOCK := 8.0
const UP := Color(1, 0.86, 0.5)
const CREAM := Color(1, 0.97, 0.9)

var _labels := {}   # item -> Label
var _shown := {}    # item -> the count on screen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(&"touch_blockers")
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.106, 0.122, 0.157, 0.72)
	box.border_color = Color(0.79, 0.54, 0.16)
	box.set_border_width_all(2)
	box.set_corner_radius_all(20)
	box.content_margin_left = 10
	box.content_margin_right = 14
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	for id: String in ITEMS:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 3)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = ICONS[id] if ICONS.has(id) else ItemsDB.icon(id)
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(icon)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", CREAM)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(label)
		row.add_child(chip)
		_labels[id] = label
	tooltip_text = "Pièces · larmes d'ambre · colliers · baies"
	_refresh(false)
	get_viewport().size_changed.connect(_place)
	_place.call_deferred()


## Under the clock, same right edge.
func _place() -> void:
	var inset := SafeArea.insets(get_viewport())
	var screen := get_viewport().get_visible_rect().size
	reset_size()
	var clock := get_parent().find_children("*", "ClockBadge", false, false)
	var top := inset.y + 14.0 + 48.0
	if not clock.is_empty():
		top = (clock[0] as Control).position.y + (clock[0] as Control).size.y
	position = Vector2(screen.x - inset.x - ClockBadge.RIGHT_OF_MENU - size.x, top + GAP_UNDER_CLOCK)


func _process(_delta: float) -> void:
	_refresh(true)


func _refresh(animate: bool) -> void:
	var resized := false
	for id: String in ITEMS:
		var n: int = Game.tears() if id == "larmes" else Game.item_count(id)
		if _shown.get(id, -1) == n:
			continue
		var went_up := n > int(_shown.get(id, n))
		resized = resized or str(n).length() != str(_shown.get(id, "")).length()
		_shown[id] = n
		var label: Label = _labels[id]
		label.text = str(n)
		if animate:
			_bounce(label, went_up)
	if resized:
		_place.call_deferred()


func _bounce(label: Label, went_up: bool) -> void:
	label.pivot_offset = label.size / 2.0
	label.add_theme_color_override("font_color", UP if went_up else CREAM)
	var t := create_tween()
	t.tween_property(label, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void: label.add_theme_color_override("font_color", CREAM)).set_delay(0.6)
