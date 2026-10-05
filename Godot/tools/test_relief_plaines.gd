extends SceneTree
## The relief of the Prairie du Grand Crâne as its validated plan wants it (docs/zones-3d/plaines-plan.md,
## plaines-layout.json: « l'amphithéâtre du Crâne »), built by TerrainRelief from
## world3d/zone3d/terrain3d_relief/plaines.json — checked once, where the change touches:
## - it is the plan's target field (plaines-relief-cible.png), but for the sculpting the plan asked for;
## - the story's anchors (their `new` places) keep the plan's ground height, none on a slope one cannot
##   stand on (the steep ones are said);
## - Chloé's walk on it (climbs 46° at most, slides down anything steeper, may step off an edge and
##   fall): with the passages closed (the plan's tronc, rocher, porte, Crâne, haie, gué de lune) nothing
##   behind them is reachable, not even by a drop; open, everything is; from the porte du Crâne to each
##   passage, from the arrival to the carrefour, the parvis, the étang;
## - the paths keep their grade on the final ground (the fords of the ru aside, said), no step on them;
##   no slope over 46° in the open clearings; the pond, the ford, the islet, the ru's bed;
## - the 2.5D's rules (Blockers3D: its woods, water, cliffs, scenery — still read from the 2.5D) measured
##   against the new ground: where they stand out of it and what they cut (MESURE: they are not this
##   relief's; their move is another step);
## - then in the game: Chloé walks the route du port and the rampe des Vertèbres, and four views.
##   godot --path Godot --script res://tools/test_relief_plaines.gd -- out=<folder>
## Not --headless: it renders. Prints PASS / FAIL / MESURE / SIGNALÉ, quits with 1 on any failure.
## (Game classes are reached through load() and nodes: this script is compiled before the autoloads.)

const ZONE := "res://world3d/zone3d/zone_3d.tscn"
const ZONE_TERRAIN := "res://world3d/zone3d/zone_terrain.gd"
const ZONE_SOURCE := "res://world3d/zone3d/zone_source.gd"
const RELIEF := "res://world3d/zone3d/terrain3d_relief.gd"
const BLOCKERS := "res://world3d/zone3d/blockers_3d.gd"
const LAYOUT := "res://docs/zones-3d/plaines-layout.json"
const TARGET := "res://docs/zones-3d/plaines-relief-cible.png"
const VERIFICATION := "res://docs/zones-3d/plaines-verification.txt"
const CAPTION := "Relief de la Prairie — cuvette, Crâne sur son tertre, rempart, Seuil"
const TERRAIN3D := 1
const HOUR := 10.0
const R := 0.5                      # the grid: Terrain3D's vertices
const STAND_DEG := 46.0             # Chloé's floor_max_angle: steeper, she slides
const JUMP_M := 0.65                # her jump: a blocker standing out more stops her
const HEIGHT_TOLERANCE_M := 0.25    # an anchor's ground against the plan's
const BUILD_MS_MAX := 4000
## Ground the plan's own verification computed differently, said rather than failed.
const KNOWN_HEIGHTS := {
	"galets_arbres[5]": "un arbre au pied de la paroi de la terrasse basse : la paroi ondulée (wobble) passe à 1 m",
}
## Path stretches allowed above their grade: the ru's fords (the plan: 0.3 m of water, one walks in it).
const FORDS := [Vector2(118, 127), Vector2(79, 142), Vector2(122, 126), Vector2(148, 129)]
const FORD_GRADE_DEG := 18.0
const FORD_REACH_M := 4.5
## Clearings meant to be open ground (the others hold a wall by design: the notch, the gorge, the forecourt…).
const OPEN_CLEARINGS := ["C_port", "C_seuil", "C_carrefour", "C_voyageur", "C_elise", "C_dormeur", "C_nid",
	"C_clairiere_helene", "C_tronc", "C_crique", "C_foret", "C_oeuf"]
## What lies behind a passage (the plan tool's list): unreachable while the passages are closed.
const BEHIND := ["GueDeLune", "ilot", "Page2", "pierre_plate", "GaletIlot", "AmbreProtoceratops", "RocherGrotte",
	"EntreeGrotte", "exit_grotte_echos", "spawn_DepuisGrotte", "spawn_Falaises", "poste_banc", "panneau_falaises", "page3",
	"ecaille_falaises", "table_observation", "feu_camp_poste", "nids_dimorphodon[0]", "nids_dimorphodon[1]",
	"galets_recoins[1]", "galets_arbres[5]", "galets_arbres[6]", "AntreCrane", "exit_antre_crane", "spawn_DepuisAntre",
	"scene_crane[0]", "props_bosquet[0]", "props_bosquet[1]", "props_bosquet[2]", "props_bosquet[3]", "props_bosquet[4]"]

var _out := "user://test_relief_plaines"
var _failed := 0
var _layout := {}
var _relief: RefCounted
var _src: RefCounted
var _nx := 0
var _nz := 0
var _v := PackedFloat32Array()      # the ground at the zone's vertices (481 × 361)
var _slope := PackedFloat32Array()  # its slope (degrees)
var _free := PackedByteArray()      # 1: no water too deep, no hedge, no dense edge
var _story := PackedByteArray()     # 1: a story obstacle (closed passage)
var _zone: Node
var _player: Node3D
var _pivot: Node3D
var _terrain: Node3D


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	create_timer(600.0).timeout.connect(func() -> void:
		print("FAIL  le test n'a pas fini en 10 minutes")
		quit(1))
	root.get_node("Save").set("path", "user://capture_save.json")   # never the player's save
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://capture_save.json"))
	ShotCaption.show_on(self, CAPTION)   # one caption for the whole run, left up
	_run()


func _run() -> void:
	_layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	_build()
	_check_target()
	_check_anchors()
	_masks()
	_check_walk()
	_check_paths()
	_check_slopes()
	_check_water()
	_measure_rules()
	await _in_game()
	_src.call("close")
	print("TEST relief plaines : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


# --- the relief ------------------------------------------------------------------------------------

func _build() -> void:
	_src = load(ZONE_SOURCE).call("open", &"plaines", 2.0)
	var R_: GDScript = load(RELIEF)
	var t0 := Time.get_ticks_msec()
	_relief = R_.call("from_source", _src)
	var edits: Array = R_.call("edits_of", &"plaines")
	_relief.call("apply", edits)
	var ms := Time.get_ticks_msec() - t0
	_check("the Prairie's relief is the plan's, remodelled (a `level` base, not the 2.5D's)", bool(_relief.get("remodelled")),
		"%d opérations" % edits.size())
	_check("…built quickly", ms < BUILD_MS_MAX, "%d ms" % ms)
	_nx = 481
	_nz = 361
	_v.resize(_nx * _nz)
	for j in _nz:
		for i in _nx:
			_v[j * _nx + i] = float(_relief.call("height_at", i * R, j * R))
	_slope.resize(_v.size())
	for j in range(1, _nz - 1):
		for i in range(1, _nx - 1):
			var gx := (_v[j * _nx + i + 1] - _v[j * _nx + i - 1]) / (2.0 * R)
			var gz := (_v[(j + 1) * _nx + i] - _v[(j - 1) * _nx + i]) / (2.0 * R)
			_slope[j * _nx + i] = rad_to_deg(atan(Vector2(gx, gz).length()))


## The plan's target field (16-bit PNG, 0.5 m per pixel, value = (h + 10) × 1000) at its cell centres.
func _check_target() -> void:
	var target := _png16(TARGET)
	if target.is_empty():
		_check("the plan's target field reads", false, TARGET)
		return
	var total := 0.0
	var within := 0
	var n := target.size()
	for k in n:
		var x := (k % 480 + 0.5) * R
		var z := (k / 480 + 0.5) * R
		var gap := absf(float(_relief.call("height_at", x, z)) - (target[k] / 1000.0 - 10.0))
		total += gap
		within += 1 if gap < 0.3 else 0
	var mean := total / n
	_check("the ground is the plan's target field (plaines-relief-cible.png) but for the sculpting", mean < 0.12 and within > n * 0.95,
		"écart moyen %.3f m, %.1f %% des points à moins de 0,3 m" % [mean, 100.0 * within / n])


## A 16-bit grey PNG's values (Godot's loader keeps 8 bits): its IDAT inflated and unfiltered here.
static func _png16(path: String) -> PackedInt32Array:
	var bytes := FileAccess.get_file_as_bytes(path)
	var at := 8
	var width := 0
	var height := 0
	var packed := PackedByteArray()
	while at + 8 <= bytes.size():
		var length := bytes.decode_u32(at)
		length = ((length & 0xff) << 24) | ((length & 0xff00) << 8) | ((length >> 8) & 0xff00) | ((length >> 24) & 0xff)
		var kind := bytes.slice(at + 4, at + 8).get_string_from_ascii()
		var data := bytes.slice(at + 8, at + 8 + length)
		if kind == "IHDR":
			width = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3]
			height = (data[4] << 24) | (data[5] << 16) | (data[6] << 8) | data[7]
			if data[8] != 16 or data[9] != 0:
				return PackedInt32Array()
		elif kind == "IDAT":
			packed.append_array(data)
		at += 12 + length
	var stride := width * 2
	var raw := packed.decompress((stride + 1) * height, FileAccess.COMPRESSION_DEFLATE)
	if raw.size() != (stride + 1) * height:
		return PackedInt32Array()
	var prev := PackedByteArray()
	prev.resize(stride)
	var out := PackedInt32Array()
	out.resize(width * height)
	for y in height:
		var filter := raw[y * (stride + 1)]
		var line := raw.slice(y * (stride + 1) + 1, (y + 1) * (stride + 1))
		for i in stride:
			var a := line[i - 2] if i >= 2 else 0
			var b := prev[i]
			var c := prev[i - 2] if i >= 2 else 0
			var add := 0
			match filter:
				1: add = a
				2: add = b
				3: add = (a + b) >> 1
				4:
					var p := a + b - c
					var pa := absi(p - a)
					var pb := absi(p - b)
					var pc := absi(p - c)
					add = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
			line[i] = (line[i] + add) & 0xff
		for x in width:
			out[y * width + x] = (line[x * 2] << 8) | line[x * 2 + 1]
		prev = line
	return out


# --- the anchors -----------------------------------------------------------------------------------

func _anchors() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for a: Dictionary in _layout["anchors"]:
		if a.has("new"):
			out.append({"id": a["id"], "at": _xz(a["new"]), "kind": String(a["kind"])})
		elif a.has("new_points"):
			for k in (a["new_points"] as Array).size():
				out.append({"id": "%s[%d]" % [a["id"], k], "at": _xz(a["new_points"][k]), "kind": String(a["kind"])})
	return out


## The plan's ground heights at its anchors (its verification file, « h= »).
func _plan_heights() -> Dictionary:
	var out := {}
	for line in FileAccess.get_file_as_string(VERIFICATION).split("\n"):
		var parts := line.strip_edges().split(" ", false)
		if parts.size() > 3 and line.contains("h="):
			out[parts[0]] = float(line.split("h=")[1].strip_edges().split(" ")[0])
	return out


func _check_anchors() -> void:
	var plan := _plan_heights()
	var worst := 0.0
	var worst_id := ""
	var compared := 0
	var standing_bad: Array[String] = []
	var steep: Array[String] = []
	for a in _anchors():
		var at: Vector2 = a["at"]
		var h := float(_relief.call("height_at", at.x, at.y))
		if plan.has(a["id"]):
			var gap := absf(h - float(plan[a["id"]]))
			if KNOWN_HEIGHTS.has(a["id"]) and gap > HEIGHT_TOLERANCE_M:
				print("SIGNALÉ  ancre %s : sol %.2f m (plan %.2f) — %s" % [a["id"], h, plan[a["id"]], KNOWN_HEIGHTS[a["id"]]])
			elif gap > worst:
				worst = gap
				worst_id = a["id"]
			compared += 1
		var s := _slope_near(at, 1.0)
		if s > 30.0:
			steep.append("%s %.0f°" % [a["id"], s])
		var kind: String = a["kind"]
		if _slope_near(at, 0.3) > STAND_DEG and (kind.begins_with("npc") or kind.begins_with("sign") or kind.begins_with("spawn") or kind == "rest"):
			standing_bad.append(a["id"])
	_check("the anchors keep the plan's ground (none buried, none lifted)", worst <= HEIGHT_TOLERANCE_M and compared > 60,
		"%d ancres comparées, écart max %.2f m (%s)" % [compared, worst, worst_id])
	_check("…no one stands (people, signs, arrivals, benches) on a slope too steep to stand on", standing_bad.is_empty(), "%s" % [standing_bad])
	if not steep.is_empty():
		print("SIGNALÉ  ancres à moins d'1 m d'une pente > 30° (rives, îlot, paroi voisine) : %s" % ", ".join(steep))


func _slope_near(at: Vector2, radius: float) -> float:
	var i0 := roundi(at.x / R)
	var j0 := roundi(at.y / R)
	var k := ceili(radius / R)
	var most := 0.0
	for j in range(maxi(j0 - k, 1), mini(j0 + k, _nz - 2) + 1):
		for i in range(maxi(i0 - k, 1), mini(i0 + k, _nx - 2) + 1):
			most = maxf(most, _slope[j * _nx + i])
	return most


# --- the walk --------------------------------------------------------------------------------------

## What stops her besides the slopes: deep water, the plan's hedges, banks and dense edges (_free), and
## the story's obstacles of the closed passages (_story) — as the plan's tool draws them.
func _masks() -> void:
	_free.resize(_v.size())
	_story.resize(_v.size())
	_free.fill(1)
	_story.fill(0)
	var pond: Dictionary = (_layout["water"] as Array).filter(func(w: Dictionary) -> bool: return w["kind"] == "pond")[0]
	var el: Dictionary = pond["ellipse"]
	var c := _xz(el["center"])
	var r := _xz(el["radii"])
	for j in _nz:
		for i in _nx:
			var p := Vector2(i * R, j * R)
			var k := j * _nx + i
			var water := -99.0
			if (Vector2((p.x - c.x) / r.x, (p.y - c.y) / r.y).length() - 1.0) * minf(r.x, r.y) <= 0.3:
				water = float(pond["level"])
			elif _v[k] < 0.0:
				water = 0.0
			if water - _v[k] > 0.6 or i == 0 or j == 0 or i == _nx - 1 or j == _nz - 1:
				_free[k] = 0
	for b: Dictionary in _layout["blockers"]:
		match String(b["kind"]):
			"hedge", "bank":
				for key in ["polyline", "polyline2"]:
					if b.has(key):
						var gap: Dictionary = b.get("gap", {}) if key == "polyline" else {}
						_mark_line(_free, b[key], float(b["width_m"]) * 0.5, bool(b.get("closed", false)) and key == "polyline", gap, 0)
			"trunk":
				_mark_disc(_story, _xz(b["at"]), float(b["length_m"]) * 0.5, 1)
			"boulder":
				_mark_disc(_story, _xz(b["at"]), float(b["diameter_m"]) * 0.5 + float(b.get("eboulis_m", 2.0)), 1)
			"door":
				var at := _xz(b["at"])
				var half := Vector2(float(b["width_m"]) * 0.5 + 1.0, 2.0 if b["id"] == "grand_crane" else 1.0)
				_mark_rect(_story, Rect2(at - half, half * 2.0), 1)
			"moon_ford":
				var rc: Array = b["rect"]
				var rect := Rect2(float(rc[0]), float(rc[1]), float(rc[2]), float(rc[3]))
				_mark_rect(_story, rect, 1)
				_open_ford(rect, float(pond["level"]))
			"forest_edge":
				for key in ["polygon", "polygon2"]:
					if b.has(key):
						_mark_polygon(_free, b[key], 0)


## At the full moon the ford's shoal is walked: free there where the water is shallow.
func _open_ford(rect: Rect2, level: float) -> void:
	for j in _nz:
		for i in _nx:
			if rect.has_point(Vector2(i * R, j * R)) and level - _v[j * _nx + i] < 0.6:
				_free[j * _nx + i] = 1


## Reachable vertices from `start`: she walks between standing places (slope ≤ 46°) up to a rise of 46°;
## with `drops`, she also steps off an edge and slides down anything steeper, to its foot.
func _reach(start: Vector2, closed: bool, drops := true, extra := PackedByteArray()) -> PackedByteArray:
	var ok := _free.duplicate()
	for k in ok.size():
		if (closed and _story[k]) or (not extra.is_empty() and extra[k]):
			ok[k] = 0
	ok = _eroded(ok)   # (passages narrower than ~1.2 m close, as in the plan's tool)
	var seen := PackedByteArray()
	seen.resize(ok.size())
	var s := _nearest_free(ok, start)
	if s < 0:
		return seen
	var climb := tan(deg_to_rad(STAND_DEG))
	var queue := PackedInt32Array([s])
	seen[s] = 1
	var head := 0
	var steps := [[1, 0, R], [-1, 0, R], [0, 1, R], [0, -1, R], [1, 1, R * 1.4142], [1, -1, R * 1.4142], [-1, 1, R * 1.4142], [-1, -1, R * 1.4142]]
	while head < queue.size():
		var k := queue[head]
		head += 1
		var i := k % _nx
		var j := k / _nx
		var steep_here := _slope[k] > STAND_DEG
		for st: Array in steps:
			var ii: int = i + st[0]
			var jj: int = j + st[1]
			if ii < 0 or jj < 0 or ii >= _nx or jj >= _nz:
				continue
			var n := jj * _nx + ii
			if seen[n] or not ok[n]:
				continue
			var rise := _v[n] - _v[k]
			var steep_there := _slope[n] > STAND_DEG
			var fine := false
			if steep_here or steep_there:
				fine = drops and rise < 0.0
			else:
				fine = rise <= climb * float(st[2]) and (drops or -rise <= climb * float(st[2]))
			if fine:
				seen[n] = 1
				queue.append(n)
	return seen


## Reached near `at`: a vertex within 3 m on about its own level (not the rim of a wall above it).
func _reached(seen: PackedByteArray, at: Vector2) -> bool:
	var i0 := roundi(at.x / R)
	var j0 := roundi(at.y / R)
	var own := _v[clampi(j0, 0, _nz - 1) * _nx + clampi(i0, 0, _nx - 1)]
	for j in range(maxi(j0 - 6, 0), mini(j0 + 6, _nz - 1) + 1):
		for i in range(maxi(i0 - 6, 0), mini(i0 + 6, _nx - 1) + 1):
			if seen[j * _nx + i] and absf(_v[j * _nx + i] - own) < 1.0 and Vector2(i - i0, j - j0).length() <= 6.0:
				return true
	return false


func _check_walk() -> void:
	var port := _xz((_layout["anchors"] as Array).filter(func(a: Dictionary) -> bool: return a["id"] == "spawn_DepuisPort")[0]["new"])
	var closed := _reach(port, true)
	var opened := _reach(port, false)
	var bypass: Array[String] = []
	var unreachable: Array[String] = []
	var before: Array[String] = []
	for a in _anchors():
		var behind: bool = a["id"] in BEHIND
		var c := _reached(closed, a["at"])
		if not _reached(opened, a["at"]):
			unreachable.append(a["id"])
		elif behind and c:
			bypass.append(a["id"])
		elif not behind and not c:
			before.append(a["id"])
	_check("passages closed, nothing behind them is reached, not even by a drop off a wall", bypass.is_empty(), "%s" % [bypass])
	_check("…and everything before them is", before.is_empty(), "%s" % [before])
	_check("passages open, every anchor is reached", unreachable.is_empty(), "%s" % [unreachable])
	# the plan's legs: from the porte du Crâne to each passage, from the arrival to the hub, the parvis, the pond
	var crane := Vector2(172, 103)
	var from_crane := _reach(crane, true)
	var legs := {"le tronc (bosquet)": Vector2(58, 89), "le rocher de Charge (Grotte)": Vector2(116, 52.5),
		"la porte d'ambre (Falaises)": Vector2(190, 67)}
	var missed: Array[String] = []
	for leg: String in legs:
		if not _reached(from_crane, legs[leg]):
			missed.append(leg)
	_check("from the porte du Crâne Chloé walks to each passage (tronc, rocher, porte)", missed.is_empty(), "manque %s" % [missed])
	var from_port := {"le carrefour (Maïa)": Vector2(117.2, 96.8), "le parvis": Vector2(165.6, 106.4), "l'étang (rive nord)": Vector2(134, 116),
		"l'étang (rive des chanteurs)": Vector2(132, 130)}
	missed.clear()
	for leg: String in from_port:
		if not _reached(closed, from_port[leg]):
			missed.append(leg)
	_check("from the arrival she walks to the carrefour, the parvis and the pond", missed.is_empty(), "manque %s" % [missed])
	var count := 0
	for k in opened.size():
		count += opened[k]
	print("MESURE  sol praticable depuis le port (passages ouverts) : %.0f %% de la zone" % (100.0 * count / opened.size()))


# --- paths, slopes, water -----------------------------------------------------------------------------

func _check_paths() -> void:
	var over: Array[String] = []
	var fords: Array[String] = []
	var steep := 0
	for p: Dictionary in _layout["paths"]:
		var line := _points(p["points"])
		var at := PackedVector2Array()
		for i in line.size() - 1:
			var n := maxi(1, int(line[i].distance_to(line[i + 1])))
			for k in n:
				at.append(line[i].lerp(line[i + 1], float(k) / n))
		at.append(line[line.size() - 1])
		var worst := 0.0
		var worst_at := Vector2.ZERO
		var ford_worst := 0.0
		for k in range(1, at.size()):
			var run := at[k].distance_to(at[k - 1])
			var grade := rad_to_deg(atan(absf(float(_relief.call("height_at", at[k].x, at[k].y)) - float(_relief.call("height_at", at[k - 1].x, at[k - 1].y))) / maxf(run, 0.01)))
			if _near_ford(at[k]):
				ford_worst = maxf(ford_worst, grade)
			elif grade > worst:
				worst = grade
				worst_at = at[k]
		if worst > float(p["grade_max_deg"]) + 1.0:
			over.append("%s %.1f° (%d°) vers %s" % [p["id"], worst, p["grade_max_deg"], worst_at])
		if ford_worst > float(p["grade_max_deg"]) + 1.0:
			fords.append("%s %.1f°" % [p["id"], ford_worst])
			if ford_worst > FORD_GRADE_DEG:
				over.append("%s au gué %.1f°" % [p["id"], ford_worst])
		steep += _count_steep_along(line, float(p["width_m"]) * 0.5)
	_check("the paths keep their grade on the final ground (grade_max_deg, +1°)", over.is_empty(), "%s" % [over])
	_check("…no vertex of a path steeper than she can stand on (no step)", steep == 0, "%d sommets > 46°" % steep)
	if not fords.is_empty():
		print("SIGNALÉ  gués du ru (0,3 m d'eau, voulus) et raccords au-dessus de la pente du sentier : %s (≤ %.0f°)" % [", ".join(fords), FORD_GRADE_DEG])


func _near_ford(p: Vector2) -> bool:
	for f in FORDS:
		if p.distance_to(f) < FORD_REACH_M:
			return true
	return false


func _count_steep_along(line: PackedVector2Array, half: float) -> int:
	var box := Rect2(line[0], Vector2.ZERO)
	for p in line:
		box = box.expand(p)
	box = box.grow(half + 1.0)
	var count := 0
	for j in range(maxi(floori(box.position.y / R), 1), mini(ceili(box.end.y / R), _nz - 2) + 1):
		for i in range(maxi(floori(box.position.x / R), 1), mini(ceili(box.end.x / R), _nx - 2) + 1):
			if _slope[j * _nx + i] > STAND_DEG and _distance_to(line, Vector2(i * R, j * R)) <= half:
				count += 1
	return count


func _check_slopes() -> void:
	var bad: Array[String] = []
	for c: Dictionary in _layout["clearings"]:
		if not c["id"] in OPEN_CLEARINGS:
			continue
		var at := _xz(c["center"])
		var radius := float(c["radius"])
		var n := 0
		for j in range(maxi(floori((at.y - radius) / R), 1), mini(ceili((at.y + radius) / R), _nz - 2) + 1):
			for i in range(maxi(floori((at.x - radius) / R), 1), mini(ceili((at.x + radius) / R), _nx - 2) + 1):
				if Vector2(i * R, j * R).distance_to(at) < radius and _slope[j * _nx + i] > STAND_DEG:
					n += 1
		if n > 0:
			bad.append("%s %d" % [c["id"], n])
	_check("no slope over 46° in the open clearings (arrival, Seuil, carrefour, Élise, tronc, crique…)", bad.is_empty(), "%s" % [bad])
	var walls := 0
	for k in _slope.size():
		walls += 1 if _slope[k] > 50.0 else 0
	print("MESURE  parois (pente > 50°, peintes roche par le shader) : %.1f %% de la zone" % (100.0 * walls / _slope.size()))


func _check_water() -> void:
	var shapes: RefCounted = _relief.get("shapes")
	var pond_bed := float(_relief.call("height_at", 128.0, 123.0))
	var ford := float(_relief.call("height_at", 134.0, 119.0))
	var islet := float(_relief.call("height_at", 134.0, 124.0))
	_check("the pond (water 2.4 m): deep in the middle, the ford's shoal just under, the islet above",
		pond_bed < 1.0 and absf(ford - 2.3) < 0.1 and islet > 2.6, "fond %.2f, gué %.2f, îlot %.2f m" % [pond_bed, ford, islet])
	var beds: Dictionary = shapes.get("beds") if shapes else {}
	var worst := INF
	var dry := 0.0
	var down := true
	if beds.has("vallee_du_ru"):
		var bed: Dictionary = beds["vallee_du_ru"]
		var pts: PackedVector2Array = bed["points"]
		var hs: PackedFloat32Array = bed["heights"]
		worst = 0.0
		for k in pts.size():
			dry = maxf(dry, float(_relief.call("height_at", pts[k].x, pts[k].y)) - hs[k])
			down = down and (k == 0 or hs[k] <= hs[k - 1] + 0.001)
		worst = dry
	_check("the ru's bed runs from the pond to the crique under its 0.3 m of water, always downhill (Waterways)",
		worst < 0.2 and down, "sol au-dessus du lit : %.2f m au plus, lit %s" % [worst, "descendant" if down else "qui remonte"])
	var sea := float(_relief.call("height_at", 20.0, 170.0))
	var margin := float(_relief.call("height_at", -10.0, 195.0))
	_check("the crique: the sea's bed at -3 m, and on past the zone's edge (no dam in the margin)", sea < -2.5 and margin < -2.5,
		"fond %.2f m, dans la marge %.2f m" % [sea, margin])


# --- the 2.5D's rules against the new ground ------------------------------------------------------------

## Blockers3D as the game builds it (from the 2.5D's tiles): where its boxes stand out of the new ground
## more than a jump, what they cut. Measured, not failed: the rules are not this relief's.
func _measure_rules() -> void:
	var blockers: Node3D = load(BLOCKERS).new()
	blockers.call("build", _src)
	var wall := PackedByteArray()
	wall.resize(_v.size())
	var counts := {"bois": 0, "eau": 0, "falaise": 0, "décor": 0}
	var buried := 0
	for body: Node in [blockers.get("solid"), blockers.get("water")]:
		for shape: CollisionShape3D in body.get_children():
			if shape.shape is BoxShape3D and maxf((shape.shape as BoxShape3D).size.x, (shape.shape as BoxShape3D).size.z) > 170.0:
				continue   # the zone's edges (its ways out come later)
			var what := _blocker_kind(body == blockers.get("water"), shape)
			var out := _rasterise(shape, wall)
			if out == 0:
				buried += 1
			counts[what] += out
	blockers.free()
	print("MESURE  règles du 2,5D (Blockers3D) qui dépassent le nouveau sol de plus d'un saut : %d sommets (bois %d, eau %d, falaises %d, décor %d) ; %d formes enterrées dessous" % [
		counts.values().reduce(func(a: int, b: int) -> int: return a + b), counts["bois"], counts["eau"], counts["falaise"], counts["décor"], buried])
	var walls := PackedVector2Array()
	for k in wall.size():
		if wall[k]:
			walls.append(Vector2((k % _nx) * R, (k / _nx) * R))
	var cut: Array[String] = []
	for p: Dictionary in _layout["paths"]:
		var line := _points(p["points"])
		var half := float(p["width_m"]) * 0.5
		var box := Rect2(line[0], Vector2.ZERO)
		for q in line:
			box = box.expand(q)
		box = box.grow(half)
		var n := 0
		var first := Vector2.INF
		for w in walls:
			if box.has_point(w) and _distance_to(line, w) <= half:
				n += 1
				if first == Vector2.INF:
					first = w
		if n > 0:
			cut.append("%s (%d, vers %s)" % [p["id"], n, first])
	print("MESURE  sentiers du plan coupés par ces règles : %s" % (", ".join(cut) if not cut.is_empty() else "aucun"))
	var port := Vector2(120, 176.4)
	var with_rules := _reach(port, false, true, wall)
	var lost: Array[String] = []
	for a in _anchors():
		if not _reached(with_rules, a["at"]):
			lost.append(a["id"])
	print("MESURE  avec ces règles, passages ouverts, ancres que Chloé n'atteint plus : %d %s" % [lost.size(), lost])


func _blocker_kind(water: bool, shape: CollisionShape3D) -> String:
	if water:
		return "eau"
	if shape.shape is CylinderShape3D:
		return "décor"
	var size: Vector3 = (shape.shape as BoxShape3D).size
	if minf(size.x, size.z) < 0.5:
		return "falaise"
	return "décor" if size.y < 2.6 else "bois"


## Marks the vertices under a blocker that stands out of the ground there by more than a jump (and not
## above her head); returns how many.
func _rasterise(holder: CollisionShape3D, wall: PackedByteArray) -> int:
	var at := holder.position
	var half := Vector2.ZERO
	var bottom := 0.0
	var top := 0.0
	var round_r := 0.0
	if holder.shape is BoxShape3D:
		var size: Vector3 = (holder.shape as BoxShape3D).size
		half = Vector2(size.x, size.z) * 0.5
		bottom = at.y - size.y * 0.5
		top = at.y + size.y * 0.5
	elif holder.shape is CylinderShape3D:
		var cyl := holder.shape as CylinderShape3D
		round_r = cyl.radius
		half = Vector2.ONE * cyl.radius
		bottom = at.y - cyl.height * 0.5
		top = at.y + cyl.height * 0.5
	var n := 0
	for j in range(maxi(floori((at.z - half.y) / R), 0), mini(ceili((at.z + half.y) / R), _nz - 1) + 1):
		for i in range(maxi(floori((at.x - half.x) / R), 0), mini(ceili((at.x + half.x) / R), _nx - 1) + 1):
			var p := Vector2(i * R, j * R)
			if round_r > 0.0 and p.distance_to(Vector2(at.x, at.z)) > round_r:
				continue
			if absf(p.x - at.x) > half.x + R * 0.5 or absf(p.y - at.z) > half.y + R * 0.5:
				continue
			var g := _v[j * _nx + i]
			if top > g + JUMP_M and bottom < g + 1.4:
				if not wall[j * _nx + i]:
					n += 1
				wall[j * _nx + i] = 1
	return n


# --- in the game -------------------------------------------------------------------------------------

func _in_game() -> void:
	load(ZONE_TERRAIN).set(&"kind_override", TERRAIN3D)
	var game := root.get_node("Game")
	game.set("weather", &"clear")
	game.set("clock", HOUR * 60.0)
	change_scene_to_file(ZONE)
	await process_frame
	await process_frame
	await create_timer(1.5).timeout
	_zone = current_scene
	_player = _zone.get("player")
	_pivot = _player.get("pivot")
	_terrain = _zone.get("terrain")
	var enc: Node = _zone.get("session").get("encounters")
	enc.set_physics_process(false)
	for d in _zone.get("dinos"):
		d.call("calm_down", 9999.0)
	var same := 0.0
	for p in [Vector2(120, 160), Vector2(172, 108), Vector2(134, 123), Vector2(116, 30), Vector2(190, 60)]:
		same = maxf(same, absf(float(_terrain.call("height_at", p.x, p.y)) - float(_relief.call("height_at", p.x, p.y))))
	_check("in the game, the Prairie stands on this relief (ZoneTerrain.height_at)", same < 0.001, "écart %.4f m" % same)
	await _brooks()
	var route_port: Array = _path_points("route_port")
	await _walk("the route du port: from the arrival over the Seuil and the ru's ford to the carrefour", route_port.slice(1))
	var rampe: Array = [Vector2(115, 101), Vector2(124, 103), Vector2(136, 106), Vector2(148, 108), Vector2(160, 109), Vector2(165.6, 106.4)]
	await _walk("the rampe des Vertèbres: from the carrefour up onto the parvis", rampe, true)
	await _views()


## The relief's brooks as Waterways rivers (TerrainRelief.BROOKS), as the game built them with the zone
## (ZoneTerrain.brooks): the ru from the pond to the crique, the source's rill.
func _brooks() -> void:
	var brooks: GDScript = load(RELIEF).get_script_constant_map()["BROOKS"]
	var relief: RefCounted = _terrain.get("relief")
	var rivers: Array = _terrain.get("brooks")
	await process_frame
	var beds: Dictionary = relief.get("shapes").get("beds")
	var line: PackedVector3Array = brooks.call("surface_line", relief, beds["vallee_du_ru"])
	var over := INF
	var under := 0.0
	for p in line:
		var ground := float(_terrain.call("height_at", p.x, p.z))
		if p.y > 0.05:
			over = minf(over, p.y - ground)
		under = maxf(under, ground - p.y)
	var meshed := rivers.filter(func(r: Node) -> bool:
		var m: MeshInstance3D = r.get("mesh_instance")
		return m != null and m.mesh != null and m.mesh.get_surface_count() > 0)
	_check("the ru runs as a Waterways river from the pond to the crique (and the source's rill)", rivers.size() == 2 and meshed.size() == 2 and under < 0.01,
		"%d rivières, ru de %d points jusqu'à %.2f m, eau de %.2f m au moins au-dessus du sol" % [rivers.size(), line.size(), line[line.size() - 1].y, over])


## Chloé runs along `points` (the camera turned towards the next one): she gets to each, on the ground.
func _walk(what: String, points: Array, from_first := false) -> void:
	var start: Vector2 = points[0] if from_first else Vector2(120, 176.4)
	_player.call("place_at", Vector3(start.x, float(_terrain.call("height_at", start.x, start.y)) + 0.3, start.y), 0.0)
	await create_timer(0.4).timeout
	Input.action_press(&"run")
	Input.action_press(&"move_up")
	var reached := 0
	var stuck_at := Vector3.INF
	var t0 := Time.get_ticks_msec()
	var walked := 0.0
	var last := _player.global_position
	for target: Vector2 in points.slice(1 if from_first else 0):
		var leg_t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - leg_t0 < 25000:
			var here := _player.global_position
			var to := target - Vector2(here.x, here.z)
			if to.length() < 1.6:
				break
			_pivot.call("set_view", rad_to_deg(atan2(-to.x, -to.y)), -18.0, 5.0)
			await physics_frame
			walked += (_player.global_position - last).slide(Vector3.UP).length()
			last = _player.global_position
		var at := _player.global_position
		if (target - Vector2(at.x, at.z)).length() >= 1.6:
			stuck_at = at
			break
		reached += 1
	Input.action_release(&"move_up")
	Input.action_release(&"run")
	await create_timer(0.3).timeout
	var total := points.size() - (1 if from_first else 0)
	var feet := absf(_player.global_position.y - float(_terrain.call("height_at", _player.global_position.x, _player.global_position.z)))
	_check(what, reached == total and feet < 0.2, "%d points sur %d en %.1f s (%.0f m)%s" % [reached, total, (Time.get_ticks_msec() - t0) / 1000.0, walked,
		"" if stuck_at == Vector3.INF else ", arrêtée en (%.1f, %.1f)" % [stuck_at.x, stuck_at.z]])


func _views() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _clear_sky()
	var views := [
		{"name": "01_seuil_revelation", "at": Vector2(120, 162), "look": Vector2(0.15, -1), "pitch": -26.0, "dist": 18.0},
		{"name": "02_carrefour_vers_crane", "at": Vector2(113, 100), "look": Vector2(1, 0.05), "pitch": -12.0, "dist": 7.0},
		{"name": "03_parvis_vers_etang", "at": Vector2(155, 112), "look": Vector2(-0.89, 0.45), "pitch": -32.0, "dist": 11.0},
		{"name": "04_porte_ambre", "at": Vector2(190, 70), "look": Vector2(0, -1), "pitch": -10.0, "dist": 7.0},
	]
	for v: Dictionary in views:
		var at: Vector2 = v["at"]
		var look: Vector2 = v["look"]
		var yaw := rad_to_deg(atan2(-look.x, -look.y))
		_player.call("place_at", Vector3(at.x, float(_terrain.call("height_at", at.x, at.y)) + 0.05, at.y), deg_to_rad(yaw + 180.0))
		_pivot.call("set_view", yaw, v["pitch"], v["dist"])
		_pivot.call("snap")
		await create_timer(1.2).timeout
		var path := _out.path_join("%s.png" % v["name"])
		root.get_viewport().get_texture().get_image().save_png(path)
		print("IMAGE  %s" % ProjectSettings.globalize_path(path))


## Every view in clear weather at the test's hour: the game rolls its weather each new hour, and the sky
## and the ground ease into it over a few seconds (as tools/test_terrain3d.gd waits for it).
func _clear_sky() -> void:
	var game := root.get_node("Game")
	game.set("clock", HOUR * 60.0)
	game.call("set_weather", &"clear")
	var weather: Node = _zone.get("weather")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 12000 and not (float(weather.get("rain_amount")) < 0.01 and float(weather.get("mist_amount")) < 0.01 and float(weather.get("storm_amount")) < 0.01):
		await process_frame
	await create_timer(2.0).timeout


# --- helpers -------------------------------------------------------------------------------------------

func _path_points(id: String) -> Array:
	for p: Dictionary in _layout["paths"]:
		if p["id"] == id:
			var out := []
			for q: Variant in p["points"]:
				out.append(_xz(q))
			return out
	return []


## Sets `value` in `mask` over a disc, a rectangle (or what `inside` keeps of it), a polyline's band, a polygon.
func _mark_disc(mask: PackedByteArray, at: Vector2, radius: float, value: int) -> void:
	_mark_rect(mask, Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), value, func(p: Vector2) -> bool: return p.distance_to(at) < radius)


func _mark_rect(mask: PackedByteArray, rect: Rect2, value: int, inside := Callable()) -> void:
	for j in range(maxi(floori(rect.position.y / R), 0), mini(ceili(rect.end.y / R), _nz - 1) + 1):
		for i in range(maxi(floori(rect.position.x / R), 0), mini(ceili(rect.end.x / R), _nx - 1) + 1):
			var p := Vector2(i * R, j * R)
			if (inside.is_valid() and inside.call(p)) or (not inside.is_valid() and rect.has_point(p)):
				mask[j * _nx + i] = value


func _mark_line(mask: PackedByteArray, points: Array, half: float, closed: bool, gap: Dictionary, value: int) -> void:
	var line := _points(points)
	if closed:
		line.append(line[0])
	var box := Rect2(line[0], Vector2.ZERO)
	for p in line:
		box = box.expand(p)
	var gap_at := _xz(gap["at"]) if gap.has("at") else Vector2.INF
	var gap_r := float(gap.get("width_m", 0.0)) * 0.5 + 0.5
	_mark_rect(mask, box.grow(half + 0.5), value, func(p: Vector2) -> bool:
		return _distance_to(line, p) < half and p.distance_to(gap_at) >= gap_r)


func _mark_polygon(mask: PackedByteArray, points: Array, value: int) -> void:
	var poly := _points(points)
	var box := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		box = box.expand(p)
	_mark_rect(mask, box, value, func(p: Vector2) -> bool: return Geometry2D.is_point_in_polygon(p, poly))


## A vertex stays open only if its eight neighbours are (passages narrower than ~1.2 m close).
func _eroded(mask: PackedByteArray) -> PackedByteArray:
	var out := mask.duplicate()
	for j in _nz:
		for i in _nx:
			if not mask[j * _nx + i]:
				continue
			for dj in [-1, 0, 1]:
				for di in [-1, 0, 1]:
					var jj: int = clampi(j + dj, 0, _nz - 1)
					var ii: int = clampi(i + di, 0, _nx - 1)
					if not mask[jj * _nx + ii]:
						out[j * _nx + i] = 0
	return out


func _nearest_free(ok: PackedByteArray, at: Vector2) -> int:
	var i0 := roundi(at.x / R)
	var j0 := roundi(at.y / R)
	for r in 12:
		for j in range(j0 - r, j0 + r + 1):
			for i in range(i0 - r, i0 + r + 1):
				if i >= 0 and j >= 0 and i < _nx and j < _nz and ok[j * _nx + i] and _slope[j * _nx + i] <= STAND_DEG:
					return j * _nx + i
	return -1


static func _distance_to(line: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for i in line.size() - 1:
		var a := line[i]
		var ab := line[i + 1] - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


static func _points(list: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Variant in list:
		out.append(_xz(p))
	return out


static func _xz(value: Variant) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


func _check(what: String, ok: bool, detail: String) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", what, detail])
	if not ok:
		_failed += 1
