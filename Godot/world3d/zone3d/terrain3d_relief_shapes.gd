extends RefCounted
## (no class_name: reached through TerrainRelief.SHAPES, a preload; nothing to register in the editor)
## The zone plans' relief modifiers (docs/conception-zones-3d.md § Format, the `relief.modifiers` of a
## docs/zones-3d/<zone>-layout.json), as TerrainRelief operations: a remodelled zone's relief is written
## as its plan writes it, and comes out as the plan's own tool computes it
## (docs/zones-3d/plaines-plan-outil.py: same formulas, same order, same waves of noise), so the 3D
## ground is the plan's target field while each piece of it stays an edit one can read and change.
##
## The operations (TerrainRelief.apply hands them here), coordinates [x, z] in metres of the zone; the
## plan's add | max | set is "mode":
##   layout      what the others read: the noise's waves, the plan's paths and clearings
##   level       the whole ground at `height_m` (the plan's base_m): the 2.5D's relief is replaced
##   dome        an ellipse raised (or sunk) by `height`, flat over `flat` of its radius
##   plateau     a polygon or an ellipse brought to `level` (mode max | set), its edge `edge_m` wide, wobbled
##   ridge       a crest along `points` (`absolute`: to `height`, else raised by it), `falloff_m` down
##   gradient    rising along x or z from [coord, h] to [coord, h] (mode max): the mountains
##   water_basin a polygon dug from `level` to `level` − `depth` over `inner_m`, its banks `outer_m`
##   carve       a strip planed along `points`: from `levels` [h0, h1], or the ground's own smoothed
##               profile (`follow_ground`, + `offset_m`, going down only): the notches, a brook's bed;
##               or the bed of an earlier carve (`bed_of`: its id, the same points) cut again
##   noise       ripples of `amplitude_m` (`wavelength_m`), none near the paths and in the clearings
##   pond        a pond dug in its ellipse (`level`, `depth`)
##   islet       an ellipse brought to `level` after the water (the plan's plateau_ellipse_after_water)
##   shoal       a rectangle raised to `level` after the water (the plan's rect_after_water: the ford)
##   paths       every path of the layout planed: its smoothed profile (`smooth_samples` m, 9 by
##               default), its grade held under its maximum
##   soften      the ground round `at` blurred (a box `kernel_m` wide), fading out to `radius_m`: where
##               two planed paths meet and their profiles disagree
## Each takes "protect" as TerrainRelief's own edits do (true by default: a remodelled zone sets it to
## false on purpose, and says why in its file).
## The rows of an operation are worked on the cores (WorkerThreadPool), each writing its own samples.

const PATH_SAMPLE_M := 1.0     # the profiles along a line: a sample per metre
const PATH_SMOOTH := 9         # samples in a path's running mean (9 m)
const FOLLOW_SMOOTH := 15      # samples in a follow_ground carve's running mean
const PATH_BLEND_M := 2.0      # a planed path fades into the ground over this, beyond its edge
const PATH_RELAX_ROUNDS := 400
const POND_BANK_M := 4.0
const POND_INNER_MIN_M := 2.0
const NOISE_PATH_FROM_M := 1.0   # the ripples start this far from a path's edge…

var relief: TerrainRelief
## The waves of the noise by seed ("7": [[angle, phase] × 6]); which seed the ripples and the wobble use.
var waves := {}
var noise_seed := "7"
var wobble_seed := "11"
var wobble_wavelength := 14.0
## The plan's paths ({id, kind, width_m, grade_max_deg, points}) and clearings ({id, center, radius}).
var paths: Array = []
var clearings: Array = []
## What the planed paths came to: id → {"points": PackedVector2Array (a sample per metre), "heights":
## PackedFloat32Array}: the tests read their grades from it.
var profiles := {}
## The water the relief digs: [{id, kind ("sea" | "pond"), level, polygon | ellipse}]; and the beds
## carved along the ground: id → {"points", "heights" (its bed, a sample per metre), "width_m", and
## "brook" ({width_m, depth_m, to_sea_m}) when water runs in it}.
var waters: Array[Dictionary] = []
var beds := {}

var _h := PackedFloat32Array()   # the heights being worked on (relief.heights, owned during an operation)
var _op := {}                    # the operation being applied, read by the row workers
var _kind := ""
# What the row workers read, worked out once per operation:
var _f := PackedFloat32Array()   # the operation's numbers (see _prepare)
var _prof := PackedFloat32Array()
var _prof_s := PackedFloat32Array()   # the distance along the line at each sample of _prof
var _snap := PackedFloat32Array()     # soften: the ground before it
var _segs := PackedVector2Array()   # its polyline
var _cum := PackedFloat32Array()    # the distance along it at each point
var _poly := PackedVector2Array()   # its polygon
var _ring := PackedVector2Array()   # the polygon closed (its edge as a polyline)
var _noise := PackedFloat32Array()  # the ripples' waves: [cos, sin, frequency, phase, amplitude] × n, then the total
var _wob := PackedFloat32Array()    # the wobble's
var _path_lines: Array[PackedVector2Array] = []
var _path_reach: Array[Rect2] = []
var _path_halves := PackedFloat32Array()
var _clear := PackedFloat32Array()  # clearings: [x, z, radius] × n


func _init(of: TerrainRelief) -> void:
	relief = of


## Applies one plan operation; false if `edit` is not one of them.
func apply(edit: Dictionary) -> bool:
	match String(edit.get("op", "")):
		"layout": _layout(edit)
		"level", "dome", "plateau", "ridge", "gradient", "water_basin", "carve", "noise", "pond", "islet", "shoal", "soften":
			_run(edit)
		"paths":
			for p: Dictionary in paths:
				_run(edit.merged({"op": "path", "path": p}, true))
		_:
			return false
	return true


func _layout(edit: Dictionary) -> void:
	waves = edit.get("waves", {})
	noise_seed = str(int(edit.get("noise_seed", 7)))   # (JSON numbers come as floats: "7", not "7.0")
	wobble_seed = str(int(edit.get("wobble_seed", 11)))
	wobble_wavelength = float(edit.get("wobble_wavelength_m", 14.0))
	paths = edit.get("paths", [])
	clearings = edit.get("clearings", [])
	_wob = _waves_of(wobble_seed, wobble_wavelength)
	_path_lines.clear()
	_path_reach.clear()
	_path_halves.clear()
	for p: Dictionary in paths:
		var line := _points(p["points"])
		_path_lines.append(line)
		_path_halves.append(float(p["width_m"]) * 0.5)
		_path_reach.append(_bounds(line))
	_clear.clear()
	for c: Dictionary in clearings:
		_clear.append_array([float(c["center"][0]), float(c["center"][1]), float(c["radius"])])


# --- running an operation over its area -----------------------------------------------------------

## Prepares the operation (its numbers, polyline, profile, area), then works its rows on the cores.
func _run(edit: Dictionary) -> void:
	_op = edit
	_kind = String(edit["op"])
	var reach := _prepare(edit)
	if bool(edit.get("protect", true)):
		relief.freedom(edit, 0.0, 0.0)   # (fills the relief's protection map before the threads read it)
	var box := _box(reach)
	if box.size.x <= 0 or box.size.y <= 0:
		return
	_h = relief.heights
	_h.set(0, _h[0])   # this copy is ours now, before the threads write into it
	var task := WorkerThreadPool.add_group_task(_row.bind(box), box.size.y, -1, true, "TerrainRelief : %s" % _kind)
	WorkerThreadPool.wait_for_group_task_completion(task)
	relief.heights = _h
	_h = PackedFloat32Array()
	_snap = PackedFloat32Array()
	if _kind == "level":
		relief.remodelled = true


## The samples within `reach` (metres of the zone; an empty Rect2: all of them).
func _box(reach: Rect2) -> Rect2i:
	var samples := relief.samples
	if reach.size == Vector2.ZERO:
		return Rect2i(Vector2i.ZERO, samples)
	var lo := ((reach.position - relief.origin) / relief.step).floor()
	var hi := ((reach.end - relief.origin) / relief.step).ceil()
	var a := Vector2i(clampi(int(lo.x), 0, samples.x), clampi(int(lo.y), 0, samples.y))
	var b := Vector2i(clampi(int(hi.x) + 1, 0, samples.x), clampi(int(hi.y) + 1, 0, samples.y))
	return Rect2i(a, b - a)


func _row(k: int, box: Rect2i) -> void:
	var iz := box.position.y + k
	var z := relief.origin.y + iz * relief.step
	var row := iz * relief.samples.x
	var guarded := bool(_op.get("protect", true))
	for ix in range(box.position.x, box.end.x):
		var x := relief.origin.x + ix * relief.step
		var i := row + ix
		var before := _h[i]
		var after := _shape(x, z, before)
		if after != before:
			_h[i] = lerpf(before, after, relief.freedom(_op, x, z)) if guarded else after


## What the operation makes of the ground `h` at (x, z).
func _shape(x: float, z: float, h: float) -> float:
	match _kind:
		"level": return _f[0]
		"dome": return _dome(x, z, h)
		"plateau": return _plateau(x, z, h)
		"ridge": return _ridge(x, z, h)
		"gradient": return _gradient(x, z, h)
		"water_basin": return _dug(h, _signed_distance(x, z), _f[0], _f[1], _f[2], _f[3])
		"carve": return _carve(x, z, h)
		"noise": return _ripples(x, z, h)
		"pond": return _dug(h, (_ellipse(x, z) - 1.0) * _f[6], _f[0], _f[1], _f[7], POND_BANK_M)
		"islet": return lerpf(h, _f[0], 1.0 - _ss(1.0, _f[1], _ellipse(x, z)))
		"shoal": return _shoal(x, z, h)
		"path": return _carve(x, z, h)
		"soften": return _soften(x, z, h)
	return h


## Each operation's numbers (_f), polyline, polygon or profile, worked out once; returns the area it
## can touch (an empty Rect2: everywhere). Ellipses: _f[2..5] = centre x, z, radii x, z; _f[8], _f[9]:
## cos and sin of the turn.
func _prepare(e: Dictionary) -> Rect2:
	_f = PackedFloat32Array()
	_f.resize(12)
	var mode := String(e.get("mode", "add"))
	_f[11] = ["add", "max", "set"].find(mode)
	match _kind:
		"level":
			_f[0] = float(e["height_m"])
		"dome":
			_set_ellipse(e["center"], e["radii"], float(e.get("rot_deg", 0.0)))
			_f[0] = float(e["height"])
			_f[1] = float(e.get("flat", 0.0))
			return _around(Vector2(_f[2], _f[3]), maxf(_f[4], _f[5]) + 0.5)
		"plateau":
			_f[0] = float(e["level"])
			_f[1] = float(e["edge_m"])
			var reach := _f[1] + absf(float(e.get("wobble_m", 0.0))) + 0.5
			if e.has("polygon"):
				_set_polygon(e["polygon"])
				_f[6] = 1.0
				return _bounds(_poly).grow(reach)
			_set_ellipse(e["center"], e["radii"], float(e.get("rot_deg", 0.0)))
			_f[7] = (_f[4] + _f[5]) * 0.5   # the plan's mean radius
			return _around(Vector2(_f[2], _f[3]), maxf(_f[4], _f[5]) * (1.0 + reach / _f[7]) + 0.5)
		"ridge":
			_line(e["points"])
			_f[0] = float(e["height"])
			_f[1] = float(e["half_width_m"])
			_f[2] = float(e["falloff_m"])
			_f[3] = 1.0 if bool(e.get("absolute", false)) else 0.0
			return _bounds(_segs).grow(_f[1] + _f[2] + absf(float(e.get("wobble_m", 0.0))) + 0.5)
		"gradient":
			var from: Array = e["from"]
			var to: Array = e["to"]
			_f[0] = 0.0 if String(e["axis"]) == "x" else 1.0
			_f[1] = float(from[0])
			_f[2] = float(from[1])
			_f[3] = float(to[0])
			_f[4] = float(to[1])
		"water_basin":
			_set_polygon(e["polygon"])
			_f[0] = float(e["level"])
			_f[1] = float(e["depth"])
			_f[2] = float(e["inner_m"])
			_f[3] = float(e["outer_m"])
			_record_water(e, "sea", {"polygon": e["polygon"]})
			return _bounds(_poly).grow(_f[3] + 0.5)
		"carve":
			_line(e["points"])
			_f[0] = float(e["width_m"]) * 0.5
			_f[1] = float(e["blend_m"])
			if e.has("levels"):
				_f[2] = float(e["levels"][0])
				_f[3] = float(e["levels"][1])
				_f[4] = 1.0
			elif beds.has(String(e.get("bed_of", ""))):   # a bed carved before, cut again (through what was laid over it since)
				_prof = beds[String(e["bed_of"])]["heights"]
				_prof_s = _arclength(_metres_along(_segs))
			else:
				_prof = _profile(_segs, FOLLOW_SMOOTH, bool(e.get("monotone_down", true)))
				_prof_s = _arclength(_metres_along(_segs))
				_f[5] = float(e.get("offset_m", 0.0))
				var bed := PackedFloat32Array()
				for v in _prof:
					bed.append(v + _f[5])
				beds[String(e.get("id", "lit"))] = {"points": _metres_along(_segs), "heights": bed, "width_m": float(e["width_m"])}
				if e.has("brook"):   # water runs in it (terrain3d_relief_brooks.gd: a Waterways river)
					beds[String(e["id"])]["brook"] = e["brook"]
			return _bounds(_segs).grow(_f[0] + _f[1] + 0.5)
		"noise":
			_noise = _waves_of(noise_seed, float(e["wavelength_m"]))
			_f[0] = float(e["amplitude_m"])
			_f[1] = float(e["clear_paths_m"])
		"pond":
			var el: Dictionary = e["ellipse"]
			_set_ellipse(el["center"], el["radii"], 0.0)
			_f[0] = float(e["level"])
			_f[1] = float(e["depth"])
			_f[6] = minf(_f[4], _f[5])
			_f[7] = maxf(POND_INNER_MIN_M, _f[6] * 0.5)
			_record_water(e, "pond", {"ellipse": el})
			return _around(Vector2(_f[2], _f[3]), maxf(_f[4], _f[5]) * (1.0 + POND_BANK_M / _f[6]) + 0.5)
		"islet":
			_set_ellipse(e["center"], e["radii"], 0.0)
			_f[0] = float(e["level"])
			_f[1] = 1.0 + float(e["edge_m"]) / minf(_f[4], _f[5])
			return _around(Vector2(_f[2], _f[3]), maxf(_f[4], _f[5]) * _f[1] + 0.5)
		"shoal":
			var rc: Array = e["rect"]
			_f[0] = float(e["level"])
			_f[1] = float(e.get("blend_m", 1.0))
			_f[2] = float(rc[0])
			_f[3] = float(rc[1])
			_f[4] = float(rc[0]) + float(rc[2])
			_f[5] = float(rc[1]) + float(rc[3])
			return Rect2(_f[2], _f[3], _f[4] - _f[2], _f[5] - _f[3]).grow(_f[1] + 0.5)
		"soften":
			_set_ellipse(e["at"], [float(e["radius_m"]), float(e["radius_m"])], 0.0)
			_f[0] = maxf(roundf(float(e.get("kernel_m", 1.0)) / relief.step), 1.0)   # the box's half-width, in samples
			_snap = relief.heights.duplicate()   # (read while the rows are written)
			return _around(Vector2(_f[2], _f[3]), _f[4] + 0.5)
		"path":
			var p: Dictionary = e["path"]
			_line(p["points"])
			_prof = _path_profile(p, int(e.get("smooth_samples", PATH_SMOOTH)))
			_prof_s = _arclength(_metres_along(_segs))
			_f[0] = float(p["width_m"]) * 0.5
			_f[1] = PATH_BLEND_M
			return _bounds(_segs).grow(_f[0] + _f[1] + 0.5)
	return Rect2()


## The level of the water the relief dug over (x, z) — its sea's polygon, its ponds' ellipses (and their
## first 0.3 m of bank) — or -INF where there is none.
func water_level_at(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var best := -INF
	for w: Dictionary in waters:
		var level := float(w["level"])
		if w.has("ellipse"):
			var c := Vector2(float(w["ellipse"]["center"][0]), float(w["ellipse"]["center"][1]))
			var r := Vector2(float(w["ellipse"]["radii"][0]), float(w["ellipse"]["radii"][1]))
			if (Vector2((p.x - c.x) / r.x, (p.y - c.y) / r.y).length() - 1.0) * minf(r.x, r.y) <= 0.3:
				best = maxf(best, level)
		elif w.has("polygon") and Geometry2D.is_point_in_polygon(p, _points(w["polygon"])):
			best = maxf(best, level)
	return best


func _record_water(e: Dictionary, kind: String, shape: Dictionary) -> void:
	waters = waters.filter(func(w: Dictionary) -> bool: return w["id"] != String(e.get("id", kind)))
	waters.append({"id": String(e.get("id", kind)), "kind": kind, "level": float(e["level"])}.merged(shape))


# --- the shapes (plaines-plan-outil.py, « relief ») ------------------------------------------------

func _dome(x: float, z: float, h: float) -> float:
	return h + _f[0] * (1.0 - _ss(_f[1], 1.0, _ellipse(x, z)))


func _plateau(x: float, z: float, h: float) -> float:
	var w := 0.0
	if _f[6] > 0.0:
		w = 1.0 - _ss(0.0, _f[1], _signed_distance(x, z) + _wobble(x, z))
	else:
		w = 1.0 - _ss(1.0, 1.0 + _f[1] / _f[7], _ellipse(x, z) + _wobble(x, z) / _f[7])
	return _blend(h, _f[0], w)


func _ridge(x: float, z: float, h: float) -> float:
	var w := 1.0 - _ss(_f[1], _f[1] + _f[2], _line_distance(x, z).x + _wobble(x, z))
	return _blend(h, _f[0], w) if _f[3] > 0.0 else h + _f[0] * w


func _gradient(x: float, z: float, h: float) -> float:
	var along := (x if _f[0] == 0.0 else z) + _wobble(x, z)
	var u := (along - _f[1]) / (_f[3] - _f[1])
	if int(_f[11]) != 1 or u <= 0.0:   # (max only, as the plan's tool)
		return h
	return maxf(h, lerpf(_f[2], _f[4], clampf(u, 0.0, 1.0)))


## Water dug at signed distance `sd` from its edge (< 0 inside): from `level` at the edge down to
## `level` − `depth` at `inner` m in; the ground outside drawn to `level` over `outer` m.
static func _dug(h: float, sd: float, level: float, depth: float, inner: float, outer: float) -> float:
	var target := level
	if sd <= -inner:
		target = level - depth
	elif sd <= 0.0:
		target = level - depth * (-sd / inner)
	var w := 1.0 if sd <= 0.0 else 1.0 - _ss(0.0, outer, sd)
	return lerpf(h, target, w)


## carve and path: the ground brought to the line's levels or profile, fading out beyond its half-width.
func _carve(x: float, z: float, h: float) -> float:
	var dt := _line_distance(x, z)
	var w := 1.0 - _ss(_f[0], _f[0] + _f[1], dt.x)
	if w <= 0.0:
		return h
	var target := lerpf(_f[2], _f[3], dt.y) if _f[4] > 0.0 else _at_profile(dt.y) + _f[5]
	return lerpf(h, target, w)


func _ripples(x: float, z: float, h: float) -> float:
	for c in range(0, _clear.size(), 3):
		var dx := x - _clear[c]
		var dz := z - _clear[c + 1]
		if dx * dx + dz * dz < _clear[c + 2] * _clear[c + 2]:
			return h
	var near := INF
	var p := Vector2(x, z)
	for k in _path_lines.size():
		if _path_reach[k].grow(_f[1] + _path_halves[k]).has_point(p):
			near = minf(near, _distance_to(_path_lines[k], x, z) - _path_halves[k])
	var mask := _ss(NOISE_PATH_FROM_M, _f[1], near)
	if mask <= 0.0:
		return h
	return h + _fbm(_noise, x, z) * _f[0] * mask


func _soften(x: float, z: float, h: float) -> float:
	var w := 1.0 - _ss(0.4, 1.0, _ellipse(x, z))
	if w <= 0.0:
		return h
	var k := int(_f[0])
	var ix := roundi((x - relief.origin.x) / relief.step)
	var iz := roundi((z - relief.origin.y) / relief.step)
	var sum := 0.0
	var n := 0
	for dz in range(-k, k + 1):
		var row := clampi(iz + dz, 0, relief.samples.y - 1) * relief.samples.x
		for dx in range(-k, k + 1):
			sum += _snap[row + clampi(ix + dx, 0, relief.samples.x - 1)]
			n += 1
	return lerpf(h, sum / n, w)


func _shoal(x: float, z: float, h: float) -> float:
	var sd := maxf(maxf(_f[2] - x, x - _f[4]), maxf(_f[3] - z, z - _f[5]))
	var w := 1.0 - _ss(0.0, _f[1], sd)
	return maxf(h, lerpf(h, _f[0], w)) if w > 0.0 else h


func _blend(h: float, target: float, w: float) -> float:
	match int(_f[11]):
		0: return h + target * w
		1: return maxf(h, lerpf(h, target, w)) if w > 0.0 else h
	return lerpf(h, target, w)


# --- profiles along a line -------------------------------------------------------------------------

## The ground's profile along `line`, a sample per metre, smoothed by a running mean of `span`
## samples; going down only if `down` (the plan's follow_ground carve: a brook's bed).
func _profile(line: PackedVector2Array, span: int, down: bool) -> PackedFloat32Array:
	var prof := PackedFloat32Array()
	for p in _metres_along(line):
		prof.append(relief.height_at(p.x, p.y))
	prof = _running_mean(prof, span)
	if down:
		for i in range(1, prof.size()):
			prof[i] = minf(prof[i], prof[i - 1])
	return prof


## A path's planed profile: the ground's, smoothed over `span` m (the plan's 9; 1: as it is), then
## relaxed until no metre of it is steeper than the path's grade_max_deg (the plan tool's 400 rounds).
func _path_profile(p: Dictionary, span: int) -> PackedFloat32Array:
	var at := _metres_along(_points(p["points"]))
	var prof := PackedFloat32Array()
	for q in at:
		prof.append(relief.height_at(q.x, q.y))
	prof = _running_mean(prof, maxi(span, 1))
	var most := tan(deg_to_rad(float(p["grade_max_deg"])))
	var gaps := PackedFloat32Array()
	for i in range(1, at.size()):
		gaps.append(at[i].distance_to(at[i - 1]))
	var fixes := PackedFloat32Array()
	fixes.resize(gaps.size())
	for _round in PATH_RELAX_ROUNDS:
		var over := false
		for i in gaps.size():
			var dh := prof[i + 1] - prof[i]
			var lim := most * gaps[i]
			fixes[i] = (absf(dh) - lim) * signf(dh) * 0.5 if absf(dh) > lim else 0.0
			over = over or absf(dh) > lim
		if not over:
			break
		for i in gaps.size():
			prof[i] += fixes[i]
		for i in gaps.size():
			prof[i + 1] -= fixes[i]
	profiles[String(p["id"])] = {"points": at, "heights": prof}
	return prof


## The points of `line` a metre apart along each segment (as the plan tool samples: int(length)
## steps per segment), and its last point.
static func _metres_along(line: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in line.size() - 1:
		var n := maxi(1, int(line[i].distance_to(line[i + 1]) / PATH_SAMPLE_M))
		for k in n:
			out.append(line[i].lerp(line[i + 1], float(k) / n))
	out.append(line[line.size() - 1])
	return out


## A running mean of `span` samples, the ends held (numpy's convolve over an edge-padded profile).
static func _running_mean(prof: PackedFloat32Array, span: int) -> PackedFloat32Array:
	var half := span / 2
	var out := PackedFloat32Array()
	out.resize(prof.size())
	var last := prof.size() - 1
	for i in prof.size():
		var sum := 0.0
		for k in range(-half, half + 1):
			sum += prof[clampi(i + k, 0, last)]
		out[i] = sum / span
	return out


## The profile at `t` (0–1 along the line), read at that distance along it. (The plan's tool takes its
## sample int(t × (n − 1)): on a line of many segments that index drifts behind, metres by the end, and
## on a slope the path was planed to the height of a few metres back: its grade broken by steps.)
func _at_profile(t: float) -> float:
	var last := _prof.size() - 1
	var s := t * _prof_s[last]
	var k := _prof_s.bsearch(s)
	if k <= 0:
		return _prof[0]
	if k > last:
		return _prof[last]
	return lerpf(_prof[k - 1], _prof[k], (s - _prof_s[k - 1]) / maxf(_prof_s[k] - _prof_s[k - 1], 1e-6))


## The distance along the line at each of its profile's points.
static func _arclength(points: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array([0.0])
	for i in range(1, points.size()):
		out.append(out[i - 1] + points[i].distance_to(points[i - 1]))
	return out


# --- geometry --------------------------------------------------------------------------------------

func _line(points: Array) -> void:
	_segs = _points(points)
	_cum = PackedFloat32Array([0.0])
	for i in range(1, _segs.size()):
		_cum.append(_cum[i - 1] + _segs[i].distance_to(_segs[i - 1]))


func _set_polygon(points: Array) -> void:
	_poly = _points(points)
	_ring = _poly.duplicate()
	_ring.append(_poly[0])


func _set_ellipse(center: Array, radii: Array, rot_deg: float) -> void:
	_f[2] = float(center[0])
	_f[3] = float(center[1])
	_f[4] = float(radii[0])
	_f[5] = float(radii[1])
	_f[8] = cos(deg_to_rad(rot_deg))
	_f[9] = sin(deg_to_rad(rot_deg))


## The plan's ellipse distance (1 on its edge) to the operation's ellipse.
func _ellipse(x: float, z: float) -> float:
	var dx := x - _f[2]
	var dz := z - _f[3]
	var u := (dx * _f[8] + dz * _f[9]) / _f[4]
	var v := (-dx * _f[9] + dz * _f[8]) / _f[5]
	return sqrt(u * u + v * v)


## Distance to the operation's polyline (x) and where along it the nearest point is (y: 0–1 of its length).
func _line_distance(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best := INF
	var along := 0.0
	for i in _segs.size() - 1:
		var a := _segs[i]
		var ab := _segs[i + 1] - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best:
			best = d
			along = _cum[i] + t * ab.length()
	return Vector2(best, along / maxf(_cum[_cum.size() - 1], 1e-9))


static func _distance_to(line: PackedVector2Array, x: float, z: float) -> float:
	var p := Vector2(x, z)
	var best := INF
	for i in line.size() - 1:
		var a := line[i]
		var ab := line[i + 1] - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


## Signed distance to the operation's polygon edge: negative inside.
func _signed_distance(x: float, z: float) -> float:
	var d := _distance_to(_ring, x, z)
	return -d if Geometry2D.is_point_in_polygon(Vector2(x, z), _poly) else d


## The waves of seed `seed` at `wavelength` m: [cos, sin, frequency, phase, amplitude] each, then
## the amplitudes' total (the plan tool's fbm: frequencies 1 + 0.6 k, amplitudes 1 / (1 + 0.7 k)).
func _waves_of(seed: String, wavelength: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var total := 0.0
	var k := 0
	for wave: Array in waves.get(seed, []):
		var a := 1.0 / (1.0 + 0.7 * k)
		out.append_array([cos(float(wave[0])), sin(float(wave[0])), TAU * (1.0 + 0.6 * k) / wavelength, float(wave[1]), a])
		total += a
		k += 1
	out.append(total)
	return out


## The plan tool's smooth noise (fbm), between −1 and 1.
static func _fbm(w: PackedFloat32Array, x: float, z: float) -> float:
	var n := w.size() - 1
	if n <= 0:
		return 0.0
	var out := 0.0
	for i in range(0, n, 5):
		out += w[i + 4] * sin(w[i + 2] * (x * w[i] + z * w[i + 1]) + w[i + 3])
	return out / w[n]


## The wobble of an edge (m), the plan tool's wob: its 14 m noise, `wobble_m` strong.
func _wobble(x: float, z: float) -> float:
	var strength := float(_op.get("wobble_m", 0.0))
	return _fbm(_wob, x, z) * strength if strength != 0.0 else 0.0


## The plan tool's smoothstep (clipped, from a to b).
static func _ss(a: float, b: float, t: float) -> float:
	var k := clampf((t - a) / (b - a), 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


static func _points(list: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Variant in list:
		out.append(Vector2(float(p[0]), float(p[1])))
	return out


static func _bounds(points: PackedVector2Array) -> Rect2:
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	return r


static func _around(center: Vector2, reach: float) -> Rect2:
	return Rect2(center - Vector2.ONE * reach, Vector2.ONE * reach * 2.0)
