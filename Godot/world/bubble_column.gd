@tool
class_name BubbleColumn
extends Node2D
## A column of bubbles (la Plongée, chapter 5) rising from a fissure at the foot of a high
## plateau (`top`, tiles of the zone) that is otherwise too high to swim up to. Swimming into the
## fissure (`size` tiles from the node's position) carries Chloé and her diver up in the bubbles:
## they rise, then settle on the plateau at `landing` (tiles). To come back down, she only swims
## on over the plateau's edge where the floor lies below: they sink down gently beside it.
## Rising and sinking are shown by the view (WorldView.dive_sink, as for a dive); the column is
## seen (SeaFeatures: big bubbles, a pale shaft of light) and heard (SOUND, a soft rumble); the
## first one met is shown by her diver (SeaLessons). Placed with BubbleColumn.place().

const TILE := 48.0
const RISE_S := 1.7
const SETTLE_S := 0.5
const OVERSHOOT_M := 0.35   # they rise a little above the plateau, then settle on it
const DOWN_S := 1.1
## Pushing against the plateau's edge this long (s) takes her down; this much lower (m) at least.
const PUSH_S := 0.22
const DROP_MIN := 1.0
const SOUND := "res://assets/audio/sfx/colonne_bulles.mp3"
const HEAR_PX := 420.0
const SOUND_DB := -8.0
const LESSONS := preload("res://world/sea_lessons.gd")
const TEACH_PX := 190.0
const BUBBLES: Array[Color] = [Color(0.88, 0.97, 1.0), Color(0.72, 0.9, 1.0)]

@export var size := Vector2(2, 2):
	set(value):
		size = value
		queue_redraw()
## Where it sets Chloé down, on top (tiles of the zone).
@export var landing := Vector2.ZERO
## The high plateau it reaches (tiles of the zone): she comes down by its edges.
@export var top := Rect2()

var _sound: AudioStreamPlayer2D
var _push := 0.0
var _moving := false


## A column rising from `cells` (tiles) of zone `root` up to plateau `plateau` (tiles), setting
## Chloé down at `at` (tiles). `opts`: name ("Colonne…").
static func place(root: Node, cells: Rect2, plateau: Rect2, at: Vector2, opts := {}) -> Node2D:
	var c: Node2D = load("res://world/bubble_column.gd").new()
	c.name = String(opts.get("name", "Colonne"))
	c.position = cells.position * TILE
	c.size = cells.size
	c.top = plateau
	c.landing = at
	root.add_child(c, true)
	return c


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group(&"bubble_column")
	if ResourceLoader.exists(SOUND):
		var stream: AudioStream = load(SOUND)
		if "loop" in stream:
			stream.set(&"loop", true)
		_sound = AudioStreamPlayer2D.new()
		_sound.stream = stream
		_sound.bus = &"SFX"
		_sound.volume_db = SOUND_DB
		_sound.max_distance = HEAR_PX
		_sound.position = size * TILE / 2.0
		add_child(_sound)
		_sound.play()


## The fissure's area in world pixels.
func area() -> Rect2:
	return Rect2(global_position if is_inside_tree() else position, size * TILE)


## The plateau in world pixels.
func top_px() -> Rect2:
	return Rect2(top.position * TILE, top.size * TILE)


func landing_px() -> Vector2:
	return landing * TILE


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _moving:
		return
	var chloe := get_tree().get_first_node_in_group(&"player") as Player
	if chloe == null or not chloe.is_swimming() or not chloe.can_move():
		_push = 0.0
		return
	if area().has_point(chloe.global_position):
		rise(chloe)
	elif top_px().has_point(chloe.global_position):
		_watch_edge(chloe, delta)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var chloe := get_tree().get_first_node_in_group(&"player") as Player
	if chloe and chloe.is_swimming() and area().get_center().distance_to(chloe.global_position) < TEACH_PX:
		LESSONS.column(self)


## Up in the bubbles: to the middle of the column, up above the plateau, set down on it.
func rise(chloe: Player) -> void:
	var view = _view()
	var region := _region()
	if view == null or region == null:
		return
	_moving = true
	chloe.busy = true
	chloe.velocity = Vector2.ZERO
	var companion = get_tree().get_first_node_in_group(&"companion")
	if companion:
		companion.cry(&"neutre")
	var foot := area().get_center()
	# From the height she is shown at now (the floor, or what the swim lifts her over) up to the top.
	var shown: float = maxf(view.heights.to_3d(foot).y, _swim_height(view, -INF))
	var lift: float = view.heights.to_3d(landing_px()).y - shown
	view.burst(foot, BUBBLES, 22, 0.4, 0.6)
	var t := create_tween()
	t.tween_property(chloe, "global_position", foot, 0.3).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(view, "dive_sink", -(lift + OVERSHOOT_M), RISE_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	# On top: she is there now (the same height, seen from its new ground), and settles.
	chloe.teleport(landing_px())   # (her diver, carrying her, follows at once)
	view.dive_sink = -OVERSHOOT_M
	var s := create_tween()
	s.tween_property(view, "dive_sink", 0.0, SETTLE_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await s.finished
	chloe.busy = false
	_moving = false


## On the plateau, pushing on over an edge where the floor lies well below: she goes down.
func _watch_edge(chloe: Player, delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if input.length() < 0.5 or chloe.get_real_velocity().length() > 30.0:
		_push = 0.0
		return
	var dir := input.normalized()
	var region := _region()
	var ahead := chloe.global_position + dir * TILE
	if region == null or top_px().has_point(ahead):
		_push = 0.0
		return
	var here_h := region.tile_height(Vector2i((chloe.global_position / TILE).floor()))
	var there_h := region.tile_height(Vector2i((ahead / TILE).floor()))
	var foot_h := region.tile_height(Vector2i((area().get_center() / TILE).floor()))
	if here_h - there_h < DROP_MIN or there_h > foot_h + 0.5:
		_push = 0.0   # (not a drop to the floor: a wall, or level ground)
		return
	_push += delta
	if _push >= PUSH_S:
		_push = 0.0
		descend(chloe, dir)


## Down beside the plateau: she is set just beyond its edge, shown still up there, and sinks.
func descend(chloe: Player, dir: Vector2) -> void:
	var view = _view()
	var region := _region()
	if view == null or region == null:
		return
	_moving = true
	chloe.busy = true
	chloe.velocity = Vector2.ZERO
	var from := chloe.global_position
	var to := _floor_beyond(region, from, dir)
	var drop: float = view.heights.to_3d(from).y - view.heights.to_3d(to).y
	chloe.teleport(to)
	view.burst(to, BUBBLES, 12, drop, 0.4)
	if _swim_height(view, INF) == INF:   # (else the swim eases her down itself: Underwater.swim_lift)
		view.dive_sink = -drop
		var t := create_tween()
		t.tween_property(view, "dive_sink", 0.0, DOWN_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t.finished
	else:
		await get_tree().create_timer(DOWN_S).timeout
	chloe.busy = false
	_moving = false


## The first free point of the floor past the plateau's edge, going `dir` from `from`.
func _floor_beyond(region: Region, from: Vector2, dir: Vector2) -> Vector2:
	var top_rect := top_px()
	var p := from
	for i in 12:
		p += dir * TILE * 0.5
		if top_rect.has_point(p):
			continue
		var q := PhysicsPointQueryParameters2D.new()
		q.position = p + dir * TILE * 0.4
		q.collision_mask = 1
		if get_world_2d().direct_space_state.intersect_point(q, 1).is_empty():
			return p + dir * TILE * 0.4
	return from + dir * TILE * 1.5


## The height Chloé swims at under the sea (Underwater.swim_lift keeps it, eased over the
## floor and the rocks), or `none` when the view has no such thing.
func _swim_height(view, none: float) -> float:
	var under = view.get(&"_underwater")
	if under == null or not under.has_method(&"swim_lift"):
		return none
	var pair = under.get(&"_pair")
	return float(pair.get(&"swim_y", none)) if pair is Dictionary else none


func _view():
	return get_tree().get_first_node_in_group(&"world_view")


func _region() -> Region:
	var n: Node = get_parent()
	while n and not n is Region:
		n = n.get_parent()
	return n as Region


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size * TILE), Color(0.7, 0.9, 1.0, 0.45))
		draw_rect(Rect2(top.position * TILE - position, top.size * TILE), Color(0.7, 0.9, 1.0, 0.8), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(4, 14), "Colonne de bulles", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
