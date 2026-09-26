class_name IslandMap
extends Control
## The whole of Ambrelune, on its atlas (tools/maps/gen-atlas.mjs, AtlasDB). The regions Chloé
## has been to are clear and named (a tap opens their detailed map: `zone_picked`); the
## others stay in the mist, with only the level of their wild dinos. Chloé's region wears her
## marker, and the regions with something to do, a gold dot.

signal zone_picked(zone: StringName)

const ATLAS := preload("res://assets/art/ui/atlas_ile.png")
const REGION_IDS := preload("res://assets/art/ui/atlas_regions.png")
const SHADER := preload("res://ui/island.gdshader")
const INK := Color(0.2, 0.13, 0.07)
const LIGHT := Color(1, 0.95, 0.85, 0.85)
const CHLOE := Color(0.86, 0.33, 0.16)
const GOAL := Color(0.95, 0.66, 0.12)
## The open sea (as tools/maps/gen-atlas.mjs paints it far from the coast).
const SEA := Color8(105, 148, 166)

var here: StringName              # Chloé's zone
var chloe_tile := Vector2.INF     # where she is in it (tiles), and its size
var zone_size := Vector2.ONE
var goals: Array[Dictionary] = [] # (see Objectives)
var _paper: ColorRect
var _marks: Control
var _ids: Image
var _visited: Array[bool] = []
var _time := 0.0
var _me := Vector2.INF   # Chloé on the atlas (0–1)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_ids = REGION_IDS.get_image()
	var bg := ColorRect.new()
	bg.color = SEA
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_paper = ColorRect.new()
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("atlas", ATLAS)
	mat.set_shader_parameter("regions", REGION_IDS)
	mat.set_shader_parameter("noise_tex", WorldNoise.texture())
	mat.set_shader_parameter("sea", SEA)
	var flags := PackedFloat32Array()
	flags.resize(16)
	for i in AtlasDB.REGIONS.size():
		_visited.append(_region_visited(AtlasDB.REGIONS[i]))
		flags[i] = 1.0 if _visited[i] else 0.0
	mat.set_shader_parameter("visited", flags)
	_paper.material = mat
	add_child(_paper)
	_marks = Control.new()
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marks.set_anchors_preset(Control.PRESET_FULL_RECT)
	_marks.draw.connect(_draw_marks)
	add_child(_marks)
	resized.connect(_place)
	_place()


func _process(delta: float) -> void:
	_time += delta
	_marks.queue_redraw()


## The atlas's square on screen.
func _frame() -> Rect2:
	var s := minf(size.x, size.y)
	return Rect2((size - Vector2(s, s)) / 2.0, Vector2(s, s))


func _place() -> void:
	var f := _frame()
	_paper.position = f.position
	_paper.size = f.size


func _at(p: Vector2) -> Vector2:
	var f := _frame()
	return f.position + p * f.size


func _region_visited(region: Dictionary) -> bool:
	for z: StringName in region["zones"]:
		if z == here or Game.explored.has(String(z)) or _place_visited(z):
			return true
	return false


## A place with no map of its own (indoors) was visited: the story says so.
static func _place_visited(zone: StringName) -> bool:
	match zone:
		&"cabinet":
			return Game.flag(&"met_roc")
		&"grotte_echos":
			return Game.flag(&"rocher_grotte_brise")
		&"antre_crane":
			return Game.flag(&"crane_ouvert")
	return false


func _draw_marks() -> void:
	var font := get_theme_default_font()
	for i in AtlasDB.REGIONS.size():
		var region: Dictionary = AtlasDB.REGIONS[i]
		var mid := _at(region["label"])
		var levels: Vector2i = region["levels"]
		if not _visited[i]:
			# Not found yet: no name, just how strong its dinos are (towns: nothing).
			if levels.y > 1:
				var text := "Niv. %d–%d" % [levels.x, levels.y] if levels.x != levels.y else "Niv. %d" % levels.x
				_text(font, mid, text, 15, Color(INK, 0.7), Color(1, 1, 1, 0.45))
			continue
		if here in region["zones"]:
			if _me == Vector2.INF:
				_me = _chloe_on_atlas(i)
			if _at(_me).distance_to(mid) < 40.0:
				mid = _at(_me) + Vector2(0, 34)
		_text(font, mid, region["name"], 17, INK, LIGHT)
		var half_w := font.get_string_size(region["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x / 2.0 + 14.0
		if levels.y > 1:
			_text(font, mid + Vector2(0, 18), "Niv. %d–%d" % [levels.x, levels.y], 13, Color(INK, 0.8), LIGHT)
		if goals.any(func(o: Dictionary) -> bool: return o["zone"] in region["zones"]):
			var g := mid + Vector2(-half_w, 0)
			_marks.draw_circle(g, 7.0 + sin(_time * 4.0), GOAL)
			_marks.draw_arc(g, 8.0, 0.0, TAU, 16, INK, 1.5)
		if here in region["zones"]:
			var me := _at(_me)
			var ring := fmod(_time, 1.4) / 1.4
			_marks.draw_arc(me, 8.0 + ring * 14.0, 0.0, TAU, 32, Color(CHLOE, 1.0 - ring), 3.0)
			_marks.draw_circle(me, 8.0, Color.WHITE)
			_marks.draw_circle(me, 6.0, CHLOE)
	for place: Array in AtlasDB.PLACES:
		if _place_visited(place[0]) or Game.explored.has(String(place[0])):
			var p := _at(place[2])
			_marks.draw_circle(p, 4.0, INK)
			_text(font, p + Vector2(0, 13), place[1], 12, INK, LIGHT)


## Where Chloé is on the atlas (0–1): her place in her zone's detailed map, laid over its
## region (and kept inside it); in a place with no map, that place; else the region's name.
func _chloe_on_atlas(index: int) -> Vector2:
	var region: Dictionary = AtlasDB.REGIONS[index]
	if here == region["zones"][0] and chloe_tile != Vector2.INF:
		var b: Rect2 = region["bounds"]
		return _inside(b.position + (chloe_tile / zone_size).clamp(Vector2.ZERO, Vector2.ONE) * b.size, index)
	for place: Array in AtlasDB.PLACES:
		if place[0] == here:
			return place[2]
	return region["label"]


## The nearest point of region `index` to `p` (0–1), on the region map.
func _inside(p: Vector2, index: int) -> Vector2:
	var w := _ids.get_width()
	var h := _ids.get_height()
	var c := Vector2i(p * Vector2(w, h))
	for r in 80:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var q := c + Vector2i(dx, dy) * 2
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
					continue
				if roundi(_ids.get_pixel(q.x, q.y).r * 255.0 / 16.0) == index:
					return Vector2(q) / Vector2(w, h)
	return p


func _text(font: Font, at: Vector2, text: String, font_size: int, colour: Color, outline: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := at + Vector2(-w / 2.0, font_size * 0.35)
	_marks.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, outline)
	_marks.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


## Which region is at a point of this control (index in AtlasDB.REGIONS, -1: the sea).
func _region_at(p: Vector2) -> int:
	var f := _frame()
	var uv := (p - f.position) / f.size
	if uv.x < 0.0 or uv.y < 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
		return -1
	var raw := roundi(_ids.get_pixel(int(uv.x * _ids.get_width()), int(uv.y * _ids.get_height())).r * 255.0)
	return -1 if raw >= 250 else roundi(raw / 16.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		(_paper.material as ShaderMaterial).set_shader_parameter("hover", _region_at((event as InputEventMouseMotion).position))
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var i := _region_at((event as InputEventMouseButton).position)
		if i >= 0 and _visited[i]:
			zone_picked.emit(AtlasDB.REGIONS[i]["zones"][0])
		accept_event()
