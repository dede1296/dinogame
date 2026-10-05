extends RefCounted
## The brooks a remodelled zone's relief carves (TerrainRelief.shapes.beds: the follow_ground carves
## marked "brook" in terrain3d_relief/<zone>.json), as Waterways rivers (addons/waterways): a real
## current running down the bed, from its first point (the pond's outlet) to its last, then down the
## beach to the sea when the brook says so ("to_sea_m"). The water stands `depth_m` over the bed (the
## Prairie's ru: 0.3 m, one walks in it: nothing blocks). No flow map is baked (Waterways then flows
## evenly along the river): baking needs the editor's renderers and a few seconds per river.
## Reached through TerrainRelief.BROOKS (no class_name: nothing to register in the editor).
##
##   TerrainRelief.BROOKS.build(relief, ground_node)   # → the rivers, children of ground_node (zone metres)

const RIVER := preload("res://addons/waterways/river_manager.gd")
const POINT_EVERY_M := 4.0         # a curve point every this many metres of bed
const HANDLE_SHARE := 0.33         # the curve's handles, a third of the way to the next point
const SEA_LEVEL_M := 0.0
const SEA_STEP_M := 1.0            # down the beach, a look at the ground every metre
const RIVER_NAME := "Ru_%s"


## One river per brook of `relief`, added under `parent` (whose origin is the zone's corner); [] if none.
static func build(relief: TerrainRelief, parent: Node3D) -> Array[Node3D]:
	var out: Array[Node3D] = []
	if relief == null or relief.shapes == null:
		return out
	var beds: Dictionary = relief.shapes.get("beds")
	for id: String in beds:
		var bed: Dictionary = beds[id]
		if not bed.has("brook"):
			continue
		var line := surface_line(relief, bed)
		if line.size() < 2:
			continue
		out.append(_river(id, line, float(bed["brook"].get("width_m", 2.0)), parent))
	return out


## The water's surface along a brook: its bed + depth, a point every POINT_EVERY_M, then (to_sea_m)
## down the ground to the sea's level.
static func surface_line(relief: TerrainRelief, bed: Dictionary) -> PackedVector3Array:
	var brook: Dictionary = bed["brook"]
	var depth := float(brook.get("depth_m", 0.3))
	var pts: PackedVector2Array = bed["points"]
	var hs: PackedFloat32Array = bed["heights"]
	var line := PackedVector3Array()
	var every := maxi(roundi(POINT_EVERY_M), 1)
	for k in range(0, pts.size(), every):
		line.append(Vector3(pts[k].x, hs[k] + depth, pts[k].y))
	var last := pts.size() - 1
	if last % every != 0:
		line.append(Vector3(pts[last].x, hs[last] + depth, pts[last].y))
	var reach := float(brook.get("to_sea_m", 0.0))
	if reach > 0.0 and pts.size() >= 2:
		var dir := (pts[last] - pts[maxi(last - 3, 0)]).normalized()
		var walked := 0.0
		var at := pts[last]
		while walked < reach:
			walked += SEA_STEP_M
			at += dir * SEA_STEP_M
			var ground := relief.height_at(at.x, at.y)
			if ground <= SEA_LEVEL_M:
				line.append(Vector3(at.x, SEA_LEVEL_M + 0.02, at.y))
				break
			if fmod(walked, POINT_EVERY_M) < SEA_STEP_M * 0.5:
				line.append(Vector3(at.x, ground + depth * 0.5, at.y))
	return line


static func _river(id: String, line: PackedVector3Array, width: float, parent: Node3D) -> Node3D:
	var curve := Curve3D.new()
	curve.bake_interval = 0.25
	for k in line.size():
		var before := line[maxi(k - 1, 0)]
		var after := line[mini(k + 1, line.size() - 1)]
		var tangent := (after - before) * 0.5 * HANDLE_SHARE
		curve.add_point(line[k], -tangent, tangent)
	var river: Node3D = RIVER.new()
	river.name = RIVER_NAME % id
	river.set("curve", curve)
	var widths: Array[float] = []
	for k in line.size():
		widths.append(width)
	river.set("widths", widths)
	parent.add_child(river)   # (Waterways builds its mesh as it enters the tree)
	var shades: Array = WorldView.WATER_DEFAULT
	var shallow: Color = shades[0]
	var deep: Color = shades[1]
	river.call("set_materials", "albedo_color", Transform3D(Vector3(shallow.r, shallow.g, shallow.b), Vector3(deep.r, deep.g, deep.b), Vector3.ZERO, Vector3.ZERO))
	return river
