@tool
class_name SeaCurrent
extends Node2D
## A current (la Plongée, chapter 5): water that carries Chloé and her diver along `direction`
## while she swims in it (`size` tiles from the node's position, its top-left corner). It never
## hurts: it only carries her along, and it drops her where it ends. Some help (a one-way
## shortcut: `helps`), some are in the way (stronger than her swimming: she goes round them, or
## from one rock to the next: just downstream of a rock or a crest, SHELTER_PX, the water is calm).
## The 3D view shows it (SeaFeatures: streaks and bubbles rushing along); it is heard (SOUND,
## louder as she comes near); the first one met is shown by her diver (SeaLessons).
## Placed by a zone's plan with SeaCurrent.place().

const TILE := 48.0
## Chloé swims at Player.SPEED × Swim.SPEED ≈ 215 px/s: a current stronger than that carries her
## even against her strokes.
const SWIM_PX := 214.5
## A rock or a crest this close upstream (px): calm water behind it.
const SHELTER_PX := 120.0
const SOLID_LAYER := 1
const SOUND := "res://assets/audio/sfx/courant.mp3"
const HEAR_PX := 520.0
const SOUND_DB := -9.0
const LESSONS := preload("res://world/sea_lessons.gd")
## The first explanation plays this near (px).
const TEACH_PX := 150.0

@export var size := Vector2(3, 8):
	set(value):
		size = value
		queue_redraw()
## Where it flows (normalized in use).
@export var direction := Vector2.UP:
	set(value):
		direction = value
		queue_redraw()
## How fast it carries Chloé (px/s).
@export var strength := 160.0
## A current that helps (a shortcut), or one in the way: only what the first explanation says.
@export var helps := true

var _sound: AudioStreamPlayer2D
## The rocks in its way (scenery solid on land: under the water one swims over them, but the
## water stays calm behind them): [position, half size (px)].
var _rocks: Array = []


## A current over `cells` (tiles) of zone `root`, flowing `dir` at `px_s` px/s.
## `opts`: name ("Courant…"), helps (true).
static func place(root: Node, cells: Rect2, dir: Vector2, px_s: float, opts := {}) -> Node2D:
	var c: Node2D = load("res://world/sea_current.gd").new()
	c.name = String(opts.get("name", "Courant"))
	c.position = cells.position * TILE
	c.size = cells.size
	c.direction = dir.normalized()
	c.strength = px_s
	c.helps = opts.get("helps", true)
	root.add_child(c, true)
	return c


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group(&"sea_current")
	_collect_rocks.call_deferred()
	if ResourceLoader.exists(SOUND):
		var stream: AudioStream = load(SOUND)
		if "loop" in stream:
			stream.set(&"loop", true)
		_sound = AudioStreamPlayer2D.new()
		_sound.stream = stream
		_sound.bus = &"SFX"
		_sound.volume_db = SOUND_DB
		_sound.max_distance = HEAR_PX
		_sound.attenuation = 1.6
		add_child(_sound)
		_sound.play()


## Its area in world pixels.
func area() -> Rect2:
	return Rect2(global_position if is_inside_tree() else position, size * TILE)


func flow() -> Vector2:
	return direction.normalized() if direction != Vector2.ZERO else Vector2.UP


## Is `p` in the lee of a rock or a crest (a wall, or a rock of the scenery, just upstream)?
func sheltered(p: Vector2, except: Array[RID] = []) -> bool:
	var query := PhysicsRayQueryParameters2D.create(p, p - flow() * SHELTER_PX, SOLID_LAYER, except)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		return true
	var f := flow()
	var side := f.orthogonal()
	for rock: Array in _rocks:
		var to: Vector2 = rock[0] - p
		var half: Vector2 = rock[1]
		var deep := absf(f.x) * half.x + absf(f.y) * half.y     # its size along the flow…
		var wide := absf(side.x) * half.x + absf(side.y) * half.y   # …and across it
		var upstream := -to.dot(f)
		if upstream > -deep and upstream < SHELTER_PX + deep and absf(to.dot(side)) < wide + 6.0:
			return true
	return false


func _collect_rocks() -> void:
	var n: Node = get_parent()
	while n and not n is Region:
		n = n.get_parent()
	if n == null:
		return
	var reach := area().grow(SHELTER_PX)
	for e in (n as Region).entities.get_children():
		if not e is Prop or not reach.has_point((e as Node2D).global_position):
			continue
		var solid = Prop.KINDS.get((e as Prop).kind, {}).get("solid", 0.0)
		var half: Vector2 = solid * 0.5 if solid is Vector2 else Vector2.ONE * float(solid)
		if half.x > 0.0:
			_rocks.append([(e as Node2D).global_position, half])


## Does it carry Chloé now (she swims in it, free to move, not sheltered)?
func carries(chloe: Player) -> bool:
	return chloe != null and chloe.is_swimming() and chloe.can_move() and area().has_point(chloe.global_position) \
		and not sheltered(chloe.global_position, [chloe.get_rid()])


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var chloe := get_tree().get_first_node_in_group(&"player") as Player
	if carries(chloe):
		chloe.move_and_collide(flow() * strength * delta)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var chloe := get_tree().get_first_node_in_group(&"player") as Player
	if chloe == null:
		return
	var r := area()
	var near := Vector2(clampf(chloe.global_position.x, r.position.x, r.end.x), clampf(chloe.global_position.y, r.position.y, r.end.y))
	if _sound:
		_sound.global_position = near
	if near.distance_to(chloe.global_position) < TEACH_PX and chloe.is_swimming():
		LESSONS.current(self)


func _draw() -> void:
	if Engine.is_editor_hint():
		var r := Rect2(Vector2.ZERO, size * TILE)
		draw_rect(r, Color(0.2, 0.75, 0.9, 0.3))
		var c := r.get_center()
		draw_line(c - flow() * 40.0, c + flow() * 40.0, Color.WHITE, 3.0)
		draw_circle(c + flow() * 40.0, 6.0, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(4, 14), "Courant %s" % ("(aide)" if helps else "(gêne)"),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
