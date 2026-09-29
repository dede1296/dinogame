@tool
class_name DarkNook
extends Node2D
## A dark nook (la Plongée, chapter 5): a corner so dark that nothing can be seen there (`size`
## tiles from the node's position). As Chloé comes near, the Cœurs d'ambre in her satchel light
## up around her, a warm amber glow, wider with each Cœur she carries (light_radius_px): what
## lies hidden there (a pebble, a fossil…, NookFind nodes with meta "recoin" = this node's name)
## shows and can be picked up only inside that light. The view darkens the nook and lights her
## glow (SeaFeatures); the first time, the scene is shown (SeaLessons). Placed with
## DarkNook.place(), what it hides with DarkNook.hide_find().

const TILE := 48.0
## The Cœurs d'ambre (items) that shine in her satchel.
const HEARTS: Array[String] = ["coeur_1", "coeur_2", "coeur_3", "coeur_4", "coeur_5"]
## The light around her (tiles): with one Cœur, then this much more with each other one.
const LIGHT_BASE := 1.7
const LIGHT_MORE := 0.8
## Her glow comes on this close to the nook (tiles).
const GLOW_NEAR := 2.5
const FIND_SFX := preload("res://assets/audio/sfx/item.wav")
const LESSONS := preload("res://world/sea_lessons.gd")
const SPARKLE: Array[Color] = [Color(1.0, 0.8, 0.4), Color(1.0, 0.93, 0.7)]

@export var size := Vector2(3, 3):
	set(value):
		size = value
		queue_redraw()

var _finds: Array[Node2D] = []
var _seen := {}   # find -> shown (to sparkle once each time it comes into the light)


## A dark nook over `cells` (tiles) of zone `root`. `opts`: name ("Recoin…").
static func place(root: Node, cells: Rect2, opts := {}) -> Node2D:
	var n: Node2D = load("res://world/dark_nook.gd").new()
	n.name = String(opts.get("name", "Recoin"))
	n.position = cells.position * TILE
	n.size = cells.size
	root.add_child(n, true)
	return n


## Something hidden in the nook named `nook_name` at tile `at`: a picture of `kind` ("galet",
## "os_dino"…), found once (`flag`; "galet_<zone>_NN" counts as an amber pebble). `opts`: item
## (an item given), line (what is said when found), name.
static func hide_find(entities: Node, nook_name: String, kind: String, at: Vector2, flag: StringName, opts := {}) -> Node2D:
	var f: Node2D = load("res://world/nook_find.gd").new()
	f.kind = kind
	f.name = String(opts.get("name", "Cache" + nook_name))
	f.position = at * TILE
	f.taken_flag = flag
	f.item_id = String(opts.get("item", ""))
	f.line = String(opts.get("line", ""))
	f.set_meta(&"recoin", nook_name)
	entities.add_child(f, true)
	return f


## How many Cœurs d'ambre shine in Chloé's satchel.
static func hearts() -> int:
	var n := 0
	for id in HEARTS:
		if Game.item_count(id) > 0:
			n += 1
	return n


## How far her glow lights around her (px): nothing without a Cœur.
static func light_radius_px() -> float:
	var h := hearts()
	return 0.0 if h == 0 else (LIGHT_BASE + LIGHT_MORE * (h - 1)) * TILE


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group(&"dark_nook")
	_collect.call_deferred()


## Its hidden finds (entities of the zone marked with its name): hidden until lit.
func _collect() -> void:
	var region := get_parent()
	while region and not region is Region:
		region = region.get_parent()
	if region == null:
		return
	for n in (region as Region).entities.get_children():
		if n is Node2D and n.get_meta(&"recoin", "") == String(name):
			_finds.append(n)
			n.visible = false


## Its area in world pixels.
func area() -> Rect2:
	return Rect2(global_position if is_inside_tree() else position, size * TILE)


## Is Chloé near enough for her Cœurs to light up (and does she carry one)?
func lit_by(chloe: Node2D) -> bool:
	return chloe != null and hearts() > 0 and area().grow(GLOW_NEAR * TILE).has_point(chloe.global_position)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var chloe := get_tree().get_first_node_in_group(&"player") as Node2D
	if chloe == null:
		return
	var lit := lit_by(chloe)
	if lit:
		LESSONS.nook(self)
	var reach := light_radius_px()
	for f in _finds:
		if not is_instance_valid(f):
			continue
		var shown := lit and f.global_position.distance_to(chloe.global_position) < reach
		if shown != f.visible:
			f.visible = shown
			if shown and not _seen.get(f, false):
				_seen[f] = true
				_sparkle(f)
		if not shown:
			_seen[f] = false


## Something comes into the light: a glint and a little chime.
func _sparkle(f: Node2D) -> void:
	var view := get_tree().get_first_node_in_group(&"world_view")
	if view:
		view.call(&"burst", f.global_position, SPARKLE, 10, 0.3, 0.25)
	Audio.play_sfx(FIND_SFX, -10.0, 0.1, 1.3)


## The hidden find nearest to `p` (null when all are found).
func nearest_find(p: Vector2) -> Node2D:
	var best: Node2D = null
	for f in _finds:
		if is_instance_valid(f) and (best == null or f.global_position.distance_to(p) < best.global_position.distance_to(p)):
			best = f
	return best


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size * TILE), Color(0.05, 0.03, 0.1, 0.6))
		draw_string(ThemeDB.fallback_font, Vector2(4, 14), "Recoin sombre", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
