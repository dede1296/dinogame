class_name ZoneMap
extends Control
## The detailed map of one zone, drawn from its ground and relief (ui/map.gdshader), which
## Chloé can move around: drag to pan, wheel / pinch / buttons to zoom (zooming out past the
## whole zone asks for the island: `zoomed_out`). Marks, at a fixed size whatever the zoom:
## Chloé, the objectives (numbered), the places found (habitats), the ways out, the people,
## the places to rest (fires, benches). What has not been seen yet stays blank paper.

signal zoomed_out

const SHADER := preload("res://ui/map.gdshader")
const TILE := 48.0
const MAX_ZOOM := 4.0
const WHEEL_STEP := 1.15
const INK := Color(0.2, 0.13, 0.07)
const PAPER_LIGHT := Color(1, 0.95, 0.82, 0.88)
const CHLOE := Color(0.86, 0.33, 0.16)
const GOAL := Color(0.95, 0.66, 0.12)
const REST := Color(0.93, 0.45, 0.12)
const PEOPLE := Color(0.2, 0.45, 0.75)
## A name shows once this much of the ground under it has been seen.
const NAME_SEEN := 0.5
const PULSE_S := 1.4
## What a way out is called on the map.
const ZONE_NAMES := {
	&"port_ambre": "Port-Ambre", &"cabinet": "Cabinet du Pr Roc",
	&"plaines": "Plaines des Fougères", &"grotte_echos": "Grotte des Échos",
	&"antre_crane": "Antre du gardien", &"havre_dore": "Havre-Doré", &"foret": "Forêt Jurassique",
	&"camp_ombre": "Camp de l'Ombre Noire", &"marais": "Marais Brumeux",
	&"temple_englouti": "Temple englouti", &"desert": "Désert Aride",
	&"sanctuaire_vents": "Sanctuaire des Vents", &"cote": "Côte Préhistorique",
	&"grottes_marines": "Grottes marines", &"recif_sanctuaire": "Récif du Sanctuaire", &"monts": "Monts Gelés",
	&"grottes_glace": "Grottes de glace", &"sanctuaire_givre": "Sanctuaire de Givre", &"cieux": "Cieux Éternels",
}

var region: Region
var zone_id: StringName
var objectives: Array[Dictionary] = []   # (of this zone; see Objectives)
var chloe := Vector2.INF                 # tiles; INF: she is not in this zone

var zoom := 1.0        # 1 = the whole zone fits
var centre := Vector2.ZERO   # the tile at the middle of the view
var _paper: ColorRect
var _marks: Control
var _seen: PackedByteArray
var _cells := Vector2i.ONE
var _size := Vector2.ONE   # zone size, tiles
var _time := 0.0
var _drag_from := Vector2.INF
var _touches := {}
var _pinch := 0.0
var _people: Array[Array] = []   # [tile, name]
var _rests: Array[Vector2] = []
var _caves: Array[Vector2] = []


func setup(r: Region, id: StringName, layers: Dictionary, goals: Array[Dictionary], chloe_tile: Vector2) -> void:
	region = r
	zone_id = id
	objectives = goals
	chloe = chloe_tile
	_size = Vector2(r.map_size())
	_cells = Game.explore_cells(r.map_size())
	_seen = Game.explored_mask(id, r.map_size())
	centre = chloe if chloe != Vector2.INF else _size / 2.0
	for n in r.entities.get_children():
		if n is Npc and (n as Npc).present():
			_people.append([n.position / TILE, (n as Npc).display_name])
		elif n is Prop and (n as Prop).kind in Rest.KINDS:
			_rests.append(n.position / TILE)
		elif n is CaveMouth:
			_caves.append(n.position / TILE)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_paper = ColorRect.new()
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.material = _material(layers)
	add_child(_paper)
	_marks = Control.new()
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marks.set_anchors_preset(Control.PRESET_FULL_RECT)
	_marks.draw.connect(_draw_marks)
	add_child(_marks)
	resized.connect(_place)


func _material(layers: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	for key: String in layers:
		mat.set_shader_parameter(key, layers[key])
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	var fog := Image.create_from_data(_cells.x, _cells.y, false, Image.FORMAT_L8, _seen)
	mat.set_shader_parameter("fog", ImageTexture.create_from_image(fog))
	mat.set_shader_parameter("fog_scale", _size / Vector2(_cells * Game.EXPLORE_CELL))
	return mat


func _process(delta: float) -> void:
	_time += delta
	_marks.queue_redraw()


# ------------------------------------------------------------------ view

## Pixels per tile at the current zoom.
func scale_px() -> float:
	return minf(size.x / _size.x, size.y / _size.y) * zoom


## Screen position (in this control) of a tile.
func to_screen(tile: Vector2) -> Vector2:
	return size / 2.0 + (tile - centre) * scale_px()


func _place() -> void:
	var k := scale_px()
	# Keep the zone on screen: centred when smaller than the view, never scrolled off.
	var half := size / 2.0 / k
	for i in 2:
		if _size[i] <= half[i] * 2.0:
			centre[i] = _size[i] / 2.0
		else:
			centre[i] = clampf(centre[i], half[i], _size[i] - half[i])
	_paper.position = to_screen(Vector2.ZERO)
	_paper.size = _size * k


## Zooms by `factor` keeping the tile under `at` (screen) in place.
func zoom_by(factor: float, at := Vector2.INF) -> void:
	if at == Vector2.INF:
		at = size / 2.0
	var before := centre + (at - size / 2.0) / scale_px()
	var next := zoom * factor
	if next < 0.98 and zoom <= 1.001:
		zoomed_out.emit()
		return
	zoom = clampf(next, 1.0, MAX_ZOOM)
	centre = before - (at - size / 2.0) / scale_px()
	_place()


## Moves the view to a tile (an objective picked in the list), zooming in a little.
func focus(tile: Vector2) -> void:
	zoom = maxf(zoom, 2.0)
	centre = tile
	_place()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		if b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(WHEEL_STEP, b.position)
		elif b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0 / WHEEL_STEP, b.position)
		elif b.button_index == MOUSE_BUTTON_LEFT:
			_drag_from = b.position if b.pressed else Vector2.INF
		accept_event()
	elif event is InputEventMouseMotion and _drag_from != Vector2.INF and _touches.size() < 2:
		var m := event as InputEventMouseMotion
		centre -= m.relative / scale_px()
		_place()
		accept_event()
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touches[t.index] = t.position
		else:
			_touches.erase(t.index)
		_pinch = _spread()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_touches[d.index] = d.position
		if _touches.size() == 2:
			var now := _spread()
			if _pinch > 0.0 and now > 0.0:
				zoom_by(now / _pinch, _middle())
			_pinch = now
		accept_event()


func _spread() -> float:
	if _touches.size() != 2:
		return 0.0
	var p: Array = _touches.values()
	return (p[0] as Vector2).distance_to(p[1])


func _middle() -> Vector2:
	var p: Array = _touches.values()
	return ((p[0] as Vector2) + (p[1] as Vector2)) / 2.0


# ------------------------------------------------------------------ marks

func _draw_marks() -> void:
	var font := get_theme_default_font()
	# The places found, by name.
	for h in region.habitats():
		var c := h.area().get_center() / TILE
		if h.label != "" and _seen_at(c) >= NAME_SEEN:
			_text(font, to_screen(c), h.label, 17, INK, PAPER_LIGHT)
	# Places to rest (a fire, a bench), once seen.
	for t in _rests:
		if _seen_at(t) >= NAME_SEEN:
			_rest_icon(to_screen(t))
	# Cave mouths.
	for t in _caves:
		if _seen_at(t) >= NAME_SEEN:
			var p := to_screen(t)
			_marks.draw_circle(p, 7.0, Color(0.08, 0.06, 0.05))
			_marks.draw_rect(Rect2(p + Vector2(-7, 0), Vector2(14, 6)), Color(0.08, 0.06, 0.05))
	# The ways out, once seen.
	for e in region.exits():
		var at := region.exit_rect(e).get_center() / TILE
		if _seen_at(at) < NAME_SEEN:
			continue
		var where: String = ZONE_NAMES.get(e.target_zone, "")
		if region.exit_on_edge(e):
			var dir := region.exit_edge(e)
			var tip := to_screen(at) - dir * 4.0
			var side := dir.orthogonal() * 7.0
			_marks.draw_colored_polygon(PackedVector2Array([tip, tip - dir * 11.0 + side, tip - dir * 11.0 - side]), CHLOE)
			# Beside the arrow, whole inside the map (under it on a side edge, clear of whoever stands there).
			var w := font.get_string_size(where, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			var label_at := tip - dir * 26.0
			if absf(dir.x) > 0.5:
				label_at = tip - dir * (w / 2.0 + 6.0) + Vector2(0, 22)
			_text(font, label_at, where, 15, Color(SettingsMenu.CREAM), Color(0.1, 0.07, 0.04, 0.9))
		elif where != "":   # a door or a cave inside the zone: its name over it
			_text(font, to_screen(at) + Vector2(0, -18), where, 15, Color(SettingsMenu.CREAM), Color(0.1, 0.07, 0.04, 0.9))
	# People.
	for p: Array in _people:
		if _seen_at(p[0]) >= NAME_SEEN:
			var s := to_screen(p[0])
			_marks.draw_circle(s, 7.5, Color.WHITE)
			_marks.draw_circle(s, 5.5, PEOPLE)
			_text(font, s + Vector2(0, 17), p[1], 14, Color.WHITE, Color(0.08, 0.12, 0.2, 0.9))
	# The objectives: a numbered, pulsing marker.
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	var i := 0
	for o in objectives:
		i += 1
		if o["tile"] == Vector2.INF:
			continue
		var s := to_screen(o["tile"])
		var r := 12.0 + 2.0 * pulse
		var diamond := PackedVector2Array([s + Vector2(0, -r), s + Vector2(r, 0), s + Vector2(0, r), s + Vector2(-r, 0)])
		_marks.draw_colored_polygon(diamond, Color(GOAL, 0.95) if o["main"] else Color(0.35, 0.72, 0.95, 0.95))
		_marks.draw_polyline(diamond + PackedVector2Array([diamond[0]]), INK, 2.0)
		_text(font, s + Vector2(0, 1), str(i), 15, INK, Color(0, 0, 0, 0))
	# Chloé: a dot, and a ring spreading from it.
	if chloe != Vector2.INF:
		var me := to_screen(chloe)
		var ring := fmod(_time, PULSE_S) / PULSE_S
		_marks.draw_arc(me, 8.0 + ring * 16.0, 0.0, TAU, 32, Color(CHLOE, 1.0 - ring), 3.0)
		_marks.draw_circle(me, 9.0, Color.WHITE)
		_marks.draw_circle(me, 6.5, CHLOE)
	# North, and the frame.
	var n := Vector2(size.x - 26.0, 30.0)
	_marks.draw_colored_polygon(PackedVector2Array([n + Vector2(0, -14), n + Vector2(7, 6), n + Vector2(-7, 6)]), INK)
	_text(font, n + Vector2(0, 22), "N", 16, INK, PAPER_LIGHT)
	_marks.draw_rect(Rect2(Vector2.ZERO, size), Color(SettingsMenu.AMBER, 0.9), false, 2.0)


## A little campfire: three flames on logs.
func _rest_icon(p: Vector2) -> void:
	_marks.draw_line(p + Vector2(-8, 6), p + Vector2(8, 2), Color(0.35, 0.2, 0.1), 3.0)
	_marks.draw_line(p + Vector2(-8, 2), p + Vector2(8, 6), Color(0.35, 0.2, 0.1), 3.0)
	_marks.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 3), p + Vector2(0, -12), p + Vector2(6, 3)]), REST)
	_marks.draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 3), p + Vector2(0, -5), p + Vector2(3, 3)]), Color(1, 0.85, 0.3))


func _text(font: Font, at: Vector2, text: String, font_size: int, colour: Color, outline: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := at + Vector2(-w / 2.0, font_size * 0.35)
	if outline.a > 0.0:
		_marks.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, outline)
	_marks.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


func _seen_at(tile: Vector2) -> float:
	var c := Vector2i(tile / Game.EXPLORE_CELL).clamp(Vector2i.ZERO, _cells - Vector2i.ONE)
	return _seen[c.y * _cells.x + c.x] / 255.0


## Share of the walkable ground seen (woods and water do not count).
func explored_share() -> float:
	var total := 0
	var seen := 0.0
	for y in _cells.y:
		for x in _cells.x:
			var s := region.surface_at((Vector2(x, y) * Game.EXPLORE_CELL + Vector2.ONE) * TILE)
			if s == &"forest" or s == &"water" or s == &"":
				continue
			total += 1
			seen += _seen[y * _cells.x + x] / 255.0
	return seen / maxf(total, 1.0)
