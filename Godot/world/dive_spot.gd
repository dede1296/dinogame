@tool
class_name DiveSpot
extends Node2D
## Deep water where one can dive (la Plongée, Dive): a patch of a zone's water, `size` tiles from
## the node's position (its top-left corner), like a Dock. Swimming over it, Chloé dives with the
## dive button (or A): she goes down to `target_zone` (empty: this zone) at its `target_spawn`,
## an underwater zone, or a pool elsewhere where she comes back up (a flooded passage). Closed
## until `required_flag` is set: `blocked_dialogue` says why (or CLOSED_LINE). « Remonter », from
## an underwater zone reached here, brings her back up at `surface_spawn` (empty: right here).
## The 3D view marks it: the water darker, bubbles breaking the surface (Underwater.build).
## Placed by a zone's plan with DiveSpot.place().

const TILE := 48.0
const DIVE := preload("res://world/dive.gd")
const CLOSED_LINE := "L'eau est noire, là-dessous… Chloé n'ose pas descendre sans savoir où passer."

@export var size := Vector2(3, 3):
	set(value):
		size = value
		queue_redraw()
@export var target_zone: StringName
@export var target_spawn: StringName = &"Depart"
@export var required_flag: StringName
@export var blocked_dialogue: StringName
@export var surface_spawn: StringName

var _edge: Edge


## Where Chloé dives from with A: follows her while she swims over the spot.
class Edge:
	extends Node2D
	var spot: Node2D

	func interact(player: Player) -> void:
		player.busy = false   # (the dive holds her itself)
		await DIVE.plunge(spot)


## A dive spot over `cells` (tiles) of zone `root`, leading to `target_zone` / `target_spawn`.
## `opts`: name ("Plongee…"), required_flag, blocked_dialogue, surface_spawn.
static func place(root: Node, cells: Rect2, to_zone: StringName, to_spawn: StringName, opts := {}) -> Node2D:
	var spot: Node2D = load("res://world/dive_spot.gd").new()
	spot.name = String(opts.get("name", "Plongee"))
	spot.position = cells.position * TILE
	spot.size = cells.size
	spot.target_zone = to_zone
	spot.target_spawn = to_spawn
	spot.required_flag = StringName(opts.get("required_flag", &""))
	spot.blocked_dialogue = StringName(opts.get("blocked_dialogue", &""))
	spot.surface_spawn = StringName(opts.get("surface_spawn", &""))
	root.add_child(spot, true)
	return spot


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group(&"dive_spot")
	_edge = Edge.new()
	_edge.name = "Bord"
	_edge.spot = self
	add_child(_edge)


func is_open() -> bool:
	return required_flag == &"" or bool(Game.flag(required_flag))


## The spot's area, in world pixels.
func area() -> Rect2:
	return Rect2(global_position if is_inside_tree() else position, size * TILE)


## Chloé swims over it (she can dive here).
func has_chloe(chloe: Player) -> bool:
	return chloe != null and chloe.is_swimming() and area().has_point(chloe.global_position)


## Closed: what Chloé says about it.
func tell_closed(player: Player) -> void:
	player.face_towards(area().get_center())
	var lines: Array = DialogueDB.lines(blocked_dialogue) if blocked_dialogue != &"" else []
	if lines.is_empty():
		lines = [{"text": CLOSED_LINE}]
	await Dialogue.run(lines)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _edge == null:
		return
	var chloe := get_tree().get_first_node_in_group(&"player") as Player
	var over := has_chloe(chloe)
	if over != _edge.is_in_group(&"interactable"):
		if over:
			_edge.add_to_group(&"interactable")
		else:
			_edge.remove_from_group(&"interactable")
	if over:
		_edge.global_position = chloe.global_position


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size * TILE), Color(0.05, 0.2, 0.55, 0.45))
		draw_string(ThemeDB.fallback_font, Vector2(4, 14), "Plongée → %s (%s)" % [target_zone, target_spawn],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
