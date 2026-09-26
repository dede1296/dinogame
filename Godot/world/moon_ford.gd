@tool
class_name MoonFord
extends Dock
## A ford of amber stones across water, there only on full-moon nights (Game.is_full_moon):
## the Parasaurolophus gather on the shore and sing, the stones light up, the water cells of
## the ford can be walked on until dawn. Paint its cells as water; `islet` is the land it
## leads to (the ford never closes under Chloé's feet or while she is out there).
## The 3D view draws the stones (NightMagic); Dock makes her stand on them.

const WATER := Vector2i(3, 0)
const STONES := Vector2i(5, 0)   # a walkable tile (sand) laid over the water cells
const SINGER_CRY_S := Vector2(2.5, 6.0)

## The land the ford leads to (tiles).
@export var islet := Rect2()
## Where the singers stand on the shore (tiles).
@export var singer_spots: PackedVector2Array = []

var open := false
var _singers: Array[Node2D] = []
var _next_cry := 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var moon := Game.is_full_moon()
	if moon and not open:
		_open()
	elif not moon and open and not _chloe_out_there():
		_close()
	if open:
		_sing(delta)


func _open() -> void:
	open = true
	_set_cells(STONES)
	var parent: Node = _region().entities if _region() else get_parent()
	for i in singer_spots.size():
		var singer := DinoNpc.new()
		singer.name = "Chanteur%d" % i
		singer.species_id = &"parasaurolophus"
		singer.size_scale = 1.0
		singer.position = singer_spots[i] * 48.0
		singer.flip = singer_spots[i].x > position.x / 48.0
		parent.add_child(singer)
		_singers.append(singer)


func _close() -> void:
	open = false
	_set_cells(WATER)
	for s in _singers:
		if is_instance_valid(s):
			s.queue_free()
	_singers.clear()


## One of the singers calls, the others answer a moment later; a note rises over them.
func _sing(delta: float) -> void:
	_next_cry -= delta
	if _next_cry > 0.0 or _singers.is_empty():
		return
	_next_cry = randf_range(SINGER_CRY_S.x, SINGER_CRY_S.y)
	var view := get_tree().get_first_node_in_group(&"world_view") as WorldView
	for i in _singers.size():
		var s := _singers[i]
		if not is_instance_valid(s):
			continue
		var ref: WeakRef = weakref(s)   # (the singers may be gone when the timer fires: dawn)
		get_tree().create_timer(i * 0.45).timeout.connect(func() -> void:
			var singer: Node2D = ref.get_ref()
			if singer:
				singer.call(&"cry")
				if view:
					view.emote(singer, "♪"))


func _set_cells(tile: Vector2i) -> void:
	var region := _region()
	if region == null:
		return
	var cells := area()
	var first := Vector2i((cells.position / 48.0).round())
	for y in int(size.y):
		for x in int(size.x):
			region.terrain.set_cell(first + Vector2i(x, y), 0, tile)


func _region() -> Region:
	var n := get_parent()
	while n and not n is Region:
		n = n.get_parent()
	return n as Region


func _chloe_out_there() -> bool:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return false
	var t := player.global_position / 48.0
	return islet.grow(0.2).has_point(t) or Rect2(area().position / 48.0, size).grow(0.2).has_point(t)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size * 48.0), Color(1.0, 0.75, 0.3, 0.4))
		draw_string(ThemeDB.fallback_font, Vector2(4, 14), "Gué de lune", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
