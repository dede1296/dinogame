class_name Minimap
extends Control
## La mini-carte, en bas à droite de l'écran d'exploration : la carte de la zone (ZoneMap en version
## compacte : sol, relief, objectifs numérotés, sorties, personnages, feux ; papier blanc là où Chloé
## n'est pas encore allée) dans une fenêtre ronde centrée sur Chloé, qui la suit. Le nord en haut,
## comme sur la carte et à l'écran (la caméra inclinée regarde toujours vers le nord) ; ce que l'écran
## montre du sol, en trapèze clair (MinimapMath.footprint) ; Chloé, une pointe dans le sens de sa marche ;
## l'objectif suivi entouré ; les objectifs hors de la fenêtre, et la sortie à prendre quand l'objectif
## suivi est dans une autre zone (ZoneRoutes.heading), en pointes sur le bord.
## Tab (la croix ↓ de la manette ; action « minimap », remappable) : petite → grande → masquée ; un clic :
## petite ↔ grande ; + / − (les gâchettes, la molette sur elle) : le zoom. Retenus dans les réglages
## (Paramètres → Affichage : visible ou masquée). Jamais sur la colonne de boutons de droite (elle se
## réduit), masquée dans les zones fermées (grottes, maisons), pendant les scènes, les dialogues, les
## combats et les menus (le jeu en pause).
## Coût (mesuré : tools/scenarios/minimap_perf.gd) : la carte est dessinée dans une texture (un SubViewport,
## une marge autour de la fenêtre) une fois par seconde ou quand Chloé a fait quelques pas ; entre deux, la
## texture glisse sous la fenêtre (minimap.gdshader). Le cadre, Chloé, le trapèze et les pointes ne sont
## redessinés que quand ils ont bougé (chaque dessin coûte, même petit).

const ACTION := &"minimap"
const ZOOM_IN := &"minimap_zoom_in"
const ZOOM_OUT := &"minimap_zoom_out"
const PREF_SECTION := "hud"
const PREF_MODE := "minimap"
const PREF_ZOOM := "minimap_zoom"
const SHADER := preload("res://ui/minimap.gdshader")
const TILE := 48.0
## The window's diameters, before the computer's HUD scale (HudHint.scale_pc).
const SMALL_PX := 240.0
const LARGE_PX := 430.0
const MARGIN_PX := 48.0     # the cached picture goes past the window by this much all round
const REFRESH_S := 1.0      # drawn again at least this often (what was seen, the people, the goals)
const RIM_EVERY_S := 1.0 / 15.0   # the layers on top (footprint, points on the rim, Chloé) follow this often
const MOVED_PX := 0.6       # a layer is drawn again once something on it moved this much
const FADE_PER_S := 6.0
const EDGE_GAP := 10.0      # from the screen's edges (more than the safe area)
const STACK_BELOW := 5      # under the right-hand column of round buttons: menu, carte, Dinodex, selle, harnais
const MARK_SCALE := 0.55    # the map's marks, smaller than on the big map
const RIM_INSET := 9.0
const BACK := Color(0.1, 0.085, 0.07, 0.86)
const RIM := Color(0.79, 0.54, 0.16)
const CREAM := Color(1, 0.97, 0.9)
const INK := Color(0.2, 0.13, 0.07)
const SIDE_GOAL := Color(0.35, 0.72, 0.95)

## Measures (tools/scenarios/minimap_perf.gd): time spent in it (µs: its process, the picture, its drawings),
## frames, pictures drawn, the last zone's setup.
static var cost_us := 0
static var render_us := 0
static var draw_us := 0
static var frames := 0
static var renders := 0
static var setup_us := 0

var region: Region
var player: Node2D
var view: WorldView
var _mode: int = MinimapMath.Mode.SMALL
var _zoom := MinimapMath.ZOOM_DEFAULT
var _sub: SubViewport
var _map: ZoneMap
var _halo: Control              # in the picture, over the map: the followed objective and the way out ringed
var _picture: TextureRect
var _view_layer: Control        # the camera's footprint
var _rim_layer: Control         # the points on the rim
var _frame: Control             # the rim, the north, Chloé
var _drawn_at := Vector2.ZERO   # the tile at the middle of the cached picture
var _shift := Vector2.INF
var _age := 0.0
var _rim_age := 0.0
var _goals: Array[Dictionary] = []
var _followed: Dictionary = {}
var _way: Dictionary = {}       # ZoneRoutes.heading of the followed objective
var _quad := PackedVector2Array()   # the footprint drawn (window px, from its middle)
var _rim_marks: Array = []          # [at, dir, colour, followed] drawn
var _facing := Vector2.DOWN
var _k := 1.0                   # canvas px per tile
var _radius := 100.0
var _render_k := 1.0            # screen px per canvas px (the picture is drawn sharp)
var _latched := {}              # zoom actions held (a trigger sends many events)


## The keys: Tab and the pad's ↓ (cycle); +, − and the triggers (zoom). Added here, like the Dinodex's
## (DexScreen.ensure_action), before the saved remaps (KeyRemap.apply_saved).
static func ensure_action() -> void:
	if not InputMap.has_action(ACTION):
		InputMap.add_action(ACTION, 0.5)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_TAB
		InputMap.action_add_event(ACTION, key)
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_DPAD_DOWN
		InputMap.action_add_event(ACTION, pad)
	_ensure_zoom(ZOOM_IN, [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD], JOY_AXIS_TRIGGER_RIGHT)
	_ensure_zoom(ZOOM_OUT, [KEY_MINUS, KEY_KP_SUBTRACT], JOY_AXIS_TRIGGER_LEFT)


## (The keys by what is written on them: « + » and « − » on any keyboard layout.)
static func _ensure_zoom(action: StringName, keys: Array, axis: JoyAxis) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.5)
	for code: Key in keys:
		var key := InputEventKey.new()
		key.keycode = code
		InputMap.action_add_event(action, key)
	var pull := InputEventJoypadMotion.new()
	pull.axis = axis
	pull.axis_value = 1.0
	InputMap.action_add_event(action, pull)


## Puts the minimap on the exploration HUD (world.gd), with its hover tag (computer).
static func install(hud: CanvasLayer, hint: HudHint) -> Minimap:
	ensure_action()
	var minimap := Minimap.new()
	minimap.name = "Minimap"
	hud.add_child(minimap)
	if hint:
		hint.attach(minimap, "Mini-carte", ACTION, "Clic : plus grande, plus petite · molette : zoom")
	return minimap


## The mode the player chose (settings.cfg); by default small on a computer, hidden on a phone.
static func pref_mode() -> int:
	var fallback: int = MinimapMath.Mode.SMALL if Screen.on_computer() else MinimapMath.Mode.HIDDEN
	var mode := int(Quality.pref(PREF_SECTION, PREF_MODE, -1))
	if mode == -1:
		return fallback
	return mode if mode in MinimapMath.Mode.values() else MinimapMath.Mode.SMALL


static func set_pref_mode(mode: int, save := true) -> void:
	Quality.set_pref(PREF_SECTION, PREF_MODE, mode, save)


static func pref_zoom() -> int:
	return MinimapMath.zoom_level(int(Quality.pref(PREF_SECTION, PREF_ZOOM, MinimapMath.ZOOM_DEFAULT)))


static func set_pref_zoom(level: int, save := true) -> void:
	Quality.set_pref(PREF_SECTION, PREF_ZOOM, MinimapMath.zoom_level(level), save)


## Nothing else holds the screen: no scene, no dialogue, no fade; Chloé (`p`, if any) free to move.
static func screen_free(p: Node) -> bool:
	if Story.playing > 0 or Dialogue.active or Scenes.busy() or Router.is_busy():
		return false
	return p == null or bool(p.call(&"can_move"))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # (to fade out while the game is paused: a menu, a battle)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(&"touch_blockers")
	_mode = pref_mode()
	_zoom = pref_zoom()
	modulate.a = 0.0
	visible = false
	_sub = SubViewport.new()
	_sub.disable_3d = true
	_sub.transparent_bg = true
	_sub.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_sub)
	_halo = _layer(_draw_halo)
	_sub.add_child(_halo)
	_picture = TextureRect.new()
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_SCALE
	_picture.texture = _sub.get_texture()
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	_picture.material = mat
	add_child(_picture)
	_view_layer = _layer(_draw_view)
	_rim_layer = _layer(_draw_rim_marks)
	_frame = _layer(_draw_frame)
	for layer in [_view_layer, _rim_layer, _frame]:
		add_child(layer)
	get_viewport().size_changed.connect(_place)
	_place()


func _layer(drawing: Callable) -> Control:
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.draw.connect(func() -> void:
		var t0 := Time.get_ticks_usec()
		drawing.call()
		draw_us += Time.get_ticks_usec() - t0)
	return layer


## A new zone (world.gd, _enter_zone): its map, outdoors only (indoors the minimap stays hidden).
func show_zone(r: Region, p: Node2D, v: WorldView) -> void:
	region = r
	player = p
	view = v
	if _map:
		_map.queue_free()
		_map = null
	if r == null or r.indoor or v == null:
		return
	var t0 := Time.get_ticks_usec()
	_map = ZoneMap.new()
	_map.compact = true
	_map.setup(r, r.region_id, v.map_layers(), _zone_goals(), Vector2.INF)
	_sub.add_child(_map)
	_sub.move_child(_halo, -1)
	_place()
	setup_us = Time.get_ticks_usec() - t0


func _zone_goals() -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	for o in Objectives.current():
		if o["zone"] == region.region_id:
			goals.append(o)
	return goals


# ------------------------------------------------------------------ place, picture

## Bottom right, under the right-hand column of buttons (the window shrinks rather than climb on it).
func _place() -> void:
	var vp := get_viewport()
	if vp == null or _sub == null:
		return
	var screen := vp.get_visible_rect().size
	var inset := SafeArea.insets(vp)
	var hud := HudHint.scale_pc()
	var wanted := (LARGE_PX if _mode == MinimapMath.Mode.LARGE else SMALL_PX) * hud
	var d := MinimapMath.diameter(wanted, screen.y, inset.y, inset.y + HudHint.stack_y(STACK_BELOW), EDGE_GAP)
	size = Vector2(d, d)
	position = screen - inset - Vector2.ONE * (EDGE_GAP + d)
	_radius = d / 2.0
	_k = MinimapMath.px_per_tile(_zoom, SMALL_PX * hud / 2.0)
	for layer: Control in [_picture, _view_layer, _rim_layer, _frame]:
		layer.size = size
	_render_k = clampf(vp.get_final_transform().get_scale().x, 0.5, 3.0)
	var picture := d + 2.0 * MARGIN_PX
	_sub.size = Vector2i((Vector2.ONE * maxf(picture, 8.0) * _render_k).ceil())
	_halo.size = Vector2(_sub.size)
	(_picture.material as ShaderMaterial).set_shader_parameter("inner", d / maxf(picture, 1.0))
	if _map:
		_map.size = Vector2(_sub.size)
		_map.mark_scale = MARK_SCALE * _render_k
	_quad = PackedVector2Array()
	_rim_marks = []
	_shift = Vector2.INF
	_render()
	queue_redraw()
	_frame.queue_redraw()


## The map drawn again in the cached picture, centred on Chloé: what was seen, the people, the goals.
func _render() -> void:
	if _map == null or player == null or region == null:
		return
	var t0 := Time.get_ticks_usec()
	var chloe := player.global_position / TILE
	_goals = _zone_goals()
	_followed = Objectives.followed(region.region_id, chloe)
	_way = ZoneRoutes.heading(_followed, region.region_id, region, chloe)
	_map.objectives = _goals
	_map.centre = chloe
	var base := _map.scale_px() / maxf(_map.zoom, 0.0001)
	if base <= 0.0:
		return
	_map.zoom = _k * _render_k / base
	_map.refresh()
	_halo.queue_redraw()
	_sub.render_target_update_mode = SubViewport.UPDATE_ONCE
	_drawn_at = chloe
	_age = 0.0
	renders += 1
	render_us += Time.get_ticks_usec() - t0


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	var paused := get_tree().paused
	if paused:
		_follow_settings()
	var outdoor := region != null and not region.indoor and _map != null
	var shown := MinimapMath.should_show(_mode, outdoor, not paused and screen_free(player))
	modulate.a = move_toward(modulate.a, 1.0 if shown else 0.0, FADE_PER_S * delta)
	visible = modulate.a > 0.0
	if visible and player:
		_follow(delta)
	cost_us += Time.get_ticks_usec() - t0
	frames += 1


## The picture slides under the window as Chloé walks; drawn again when she went far enough. The
## layers on top are drawn again only when what they show moved.
func _follow(delta: float) -> void:
	_age += delta
	_rim_age += delta
	var chloe := player.global_position / TILE
	var shift := (chloe - _drawn_at) * _k
	if MinimapMath.needs_render(shift, MARGIN_PX, _age, REFRESH_S):
		_render()
		shift = (chloe - _drawn_at) * _k
	if shift != _shift:
		_shift = shift
		(_picture.material as ShaderMaterial).set_shader_parameter("shift", shift / maxf(size.x + 2.0 * MARGIN_PX, 1.0))
	if _rim_age >= RIM_EVERY_S:
		_rim_age = 0.0
		_follow_view(chloe)
		_follow_rim(chloe)
		_follow_facing()


## Paramètres (the game paused) may have changed the mode: taken from the settings.
func _follow_settings() -> void:
	var mode := pref_mode()
	if mode != _mode:
		_mode = mode
		_place()


func set_mode(mode: int) -> void:
	_mode = mode
	set_pref_mode(mode)
	_place()


func zoom_by(step: int) -> void:
	var level := MinimapMath.zoom_level(_zoom, step)
	if level == _zoom:
		return
	_zoom = level
	set_pref_zoom(level)
	_place()


func current_mode() -> int:
	return _mode


func current_zoom() -> int:
	return _zoom


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or region == null or region.indoor or not screen_free(player):
		return
	if event.is_action_pressed(ACTION):
		get_viewport().set_input_as_handled()
		set_mode(MinimapMath.next_mode(_mode))
		return
	var step := _zoom_step(event)
	if step != 0 and _mode != MinimapMath.Mode.HIDDEN:
		get_viewport().set_input_as_handled()
		zoom_by(step)


## +1 / −1 when a zoom key or trigger is pressed down (once: held, it does not repeat).
func _zoom_step(event: InputEvent) -> int:
	var step := 0
	for pair: Array in [[ZOOM_IN, 1], [ZOOM_OUT, -1]]:
		var action: StringName = pair[0]
		if not event.is_action(action):
			continue
		var down := event.is_action_pressed(action)
		if down and not _latched.get(action, false):
			step = pair[1]
		_latched[action] = down
	return step


## The mouse: the wheel zooms, a click makes it larger or smaller.
func _gui_input(event: InputEvent) -> void:
	var b := event as InputEventMouseButton
	if b == null or not b.pressed:
		return
	match b.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			zoom_by(1)
		MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(-1)
		MOUSE_BUTTON_LEFT:
			set_mode(MinimapMath.Mode.SMALL if _mode == MinimapMath.Mode.LARGE else MinimapMath.Mode.LARGE)
		_:
			return
	accept_event()


## Round: the corners of its square are the game's.
func _has_point(point: Vector2) -> bool:
	return point.distance_to(size / 2.0) <= _radius


# ------------------------------------------------------------------ what moves on top

## The camera's footprint, from the window's middle (px); drawn again when it moved.
func _follow_view(chloe: Vector2) -> void:
	var quad := PackedVector2Array()
	if view and view.camera:
		var cam := view.camera
		var screen := get_viewport().get_visible_rect().size
		for p in MinimapMath.footprint(cam.global_transform, cam.fov, screen.x / maxf(screen.y, 1.0), cam.target.y):
			quad.append(MinimapMath.to_window(p, chloe, _k))
	if _moved(quad, _quad):
		_quad = quad
		_view_layer.queue_redraw()


## The zone's objectives out of the window and the way out to take: their points on the rim.
func _follow_rim(chloe: Vector2) -> void:
	var marks: Array = []
	var followed_id := String(_followed.get("id", ""))
	for o in _goals:
		if o["tile"] != Vector2.INF:
			_rim_mark(marks, o["tile"], chloe, ZoneMap.GOAL if o["main"] else SIDE_GOAL, o["id"] == followed_id)
	if _way.get("via", &"") != &"" and _way.get("tile", Vector2.INF) != Vector2.INF:
		_rim_mark(marks, _way["tile"], chloe, ZoneMap.CHLOE, true)
	var moved := marks.size() != _rim_marks.size()
	for i in mini(marks.size(), _rim_marks.size()):
		moved = moved or (marks[i][0] as Vector2).distance_to(_rim_marks[i][0]) > MOVED_PX
	if moved:
		_rim_marks = marks
		_rim_layer.queue_redraw()


func _rim_mark(marks: Array, tile: Vector2, chloe: Vector2, colour: Color, followed: bool) -> void:
	var r := MinimapMath.rim(MinimapMath.to_window(tile, chloe, _k), _radius, RIM_INSET)
	if not r["inside"]:
		marks.append([r["at"], r["dir"], colour, followed])


## Chloé's wedge turns with her (the frame is drawn again then only).
func _follow_facing() -> void:
	var facing: Variant = player.get(&"facing")
	if facing is Vector2 and (facing as Vector2).length() > 0.01 \
			and absf((facing as Vector2).angle_to(_facing)) > 0.2:
		_facing = (facing as Vector2).normalized()
		_frame.queue_redraw()


static func _moved(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() != b.size():
		return true
	for i in a.size():
		if a[i].distance_to(b[i]) > MOVED_PX:
			return true
	return false


# ------------------------------------------------------------------ drawing

## Under the picture: a dark disc (beyond the zone's edges), with a soft shadow.
func _draw() -> void:
	draw_circle(size / 2.0, _radius + 2.0, Color(0, 0, 0, 0.3), true, -1.0, true)
	draw_circle(size / 2.0, _radius, BACK, true, -1.0, true)


func _draw_view() -> void:
	if _quad.size() != 4:
		return
	var c := size / 2.0
	var poly := PackedVector2Array()
	for p in _quad:
		poly.append(c + p)
	for part in Geometry2D.intersect_polygons(poly, _disc(c, _radius - 2.0)):
		_view_layer.draw_colored_polygon(part, Color(1, 1, 1, 0.1))
		_view_layer.draw_polyline(part + PackedVector2Array([part[0]]), Color(CREAM, 0.45), 1.2, true)


func _draw_rim_marks() -> void:
	var c := size / 2.0
	for m: Array in _rim_marks:
		var dir: Vector2 = m[1]
		var big := 7.5 if m[3] else 5.0
		var tip: Vector2 = c + (m[0] as Vector2) + dir * 3.0
		var side := dir.orthogonal() * big
		var arrow := PackedVector2Array([tip, tip - dir * big * 1.7 + side, tip - dir * big * 1.7 - side])
		_rim_layer.draw_colored_polygon(arrow, m[2])
		_rim_layer.draw_polyline(arrow + PackedVector2Array([arrow[0]]), INK, 1.2, true)


## In the picture (its own pixels): the followed objective ringed, and the way out to take.
func _draw_halo() -> void:
	if _map == null:
		return
	var r := 10.0 * _render_k
	var tile: Vector2 = _followed.get("tile", Vector2.INF)
	if _followed.get("zone", &"") == region.region_id and tile != Vector2.INF:
		_halo.draw_arc(_map.to_screen(tile), r, 0.0, TAU, 24, Color(CREAM, 0.95), 2.0 * _render_k, true)
	var way: Vector2 = _way.get("tile", Vector2.INF)
	if _way.get("via", &"") != &"" and way != Vector2.INF:
		_halo.draw_arc(_map.to_screen(way), r, 0.0, TAU, 24, Color(ZoneMap.CHLOE, 0.95), 2.0 * _render_k, true)


## The rim, the north at the top, Chloé in the middle with a wedge the way she faces.
func _draw_frame() -> void:
	var c := size / 2.0
	var side := _facing.orthogonal() * 5.0
	_frame.draw_colored_polygon(PackedVector2Array([c + _facing * 12.0, c + side + _facing * 2.0, c - side + _facing * 2.0]), Color.WHITE)
	_frame.draw_circle(c, 6.5, Color.WHITE, true, -1.0, true)
	_frame.draw_circle(c, 4.8, ZoneMap.CHLOE, true, -1.0, true)
	_frame.draw_arc(c, _radius - 1.0, 0.0, TAU, 72, Color(RIM, 0.95), 2.5, true)
	var n := c + Vector2(0.0, -_radius + 2.0)
	_frame.draw_circle(n, 9.0, BACK, true, -1.0, true)
	_frame.draw_arc(n, 9.0, 0.0, TAU, 20, Color(RIM, 0.95), 1.5, true)
	var font := get_theme_default_font()
	var w := font.get_string_size("N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	_frame.draw_string(font, n + Vector2(-w / 2.0, 4.5), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CREAM)


static func _disc(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 32:
		out.append(c + Vector2.from_angle(TAU * i / 32.0) * r)
	return out
