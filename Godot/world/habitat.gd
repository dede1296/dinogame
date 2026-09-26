@tool
class_name Habitat
extends Node2D
## An area of a zone where some species live (the pond's edge, a patch of tall grass, the
## edge of the woods…). Place it in the zone scene, size it, and list its Encounters:
## hidden ones are met by walking in the tall grass inside it, visible ones roam in it
## (`roamers` at a time, at the right time of day). Drawn in the editor only.

const WILD_DINO := preload("res://actors/wild_dino.tscn")

@export var label := "":
	set(value):
		label = value
		queue_redraw()
@export var size := Vector2(480, 320):
	set(value):
		size = value
		queue_redraw()
@export var encounters: Array[Encounter] = []
## How many visible dinos roam here at once.
@export var roamers := 2

var _roaming: Array[WildDino] = []


## The area, in world coordinates.
func area() -> Rect2:
	return Rect2(global_position, size)


func has_point(p: Vector2) -> bool:
	return area().has_point(p)


## A random hidden encounter active in this part of the day, weighted, or null.
func pick_hidden(phase: StringName) -> Encounter:
	return _pick(encounters.filter(func(e: Encounter) -> bool: return e.hidden and e.active(phase)))


## Replaces the roaming dinos with ones that fit the part of the day. `can_stand(point)`
## tells if a point is free ground; `parent` is the Y-sorted node they walk in.
func spawn_roamers(phase: StringName, parent: Node2D, can_stand: Callable) -> Array[WildDino]:
	for w in _roaming:
		if is_instance_valid(w):
			w.queue_free()
	_roaming.clear()
	var visible := encounters.filter(func(e: Encounter) -> bool: return not e.hidden and e.active(phase))
	if visible.is_empty():
		return _roaming
	for i in roamers:
		var e := _pick(visible)
		var spot := _free_spot(can_stand)
		if spot == Vector2.INF:
			continue
		var w: WildDino = WILD_DINO.instantiate()
		w.species_id = e.species
		w.level_range = e.levels
		w.roam_radius = minf(size.x, size.y) * 0.35
		w.position = parent.to_local(spot)
		parent.add_child(w)
		_roaming.append(w)
	return _roaming


func _free_spot(can_stand: Callable) -> Vector2:
	var r := area()
	for attempt in 24:
		var p := r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
		if can_stand.call(p):
			return p
	return Vector2.INF


static func _pick(list: Array) -> Encounter:
	if list.is_empty():
		return null
	var total := 0
	for e: Encounter in list:
		total += e.weight
	var roll := randi_range(1, maxi(total, 1))
	for e: Encounter in list:
		roll -= e.weight
		if roll <= 0:
			return e
	return list.back()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var colour := Color(0.3, 0.9, 0.4)
	draw_rect(Rect2(Vector2.ZERO, size), Color(colour, 0.08))
	draw_rect(Rect2(Vector2.ZERO, size), Color(colour, 0.8), false, 2.0)
	var names := ", ".join(encounters.map(func(e: Encounter) -> String: return String(e.species) if e else "?"))
	draw_string(ThemeDB.fallback_font, Vector2(6, 18), "%s : %s" % [label, names], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, colour)
