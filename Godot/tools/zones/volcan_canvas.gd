extends RefCounted
## La Plaine Volcanique (chapter 8): the map painter shared by the plans of its five zones
## (tools/zones/volcan_champs.gd, volcan_forges.gd, volcan_coulees.gd, volcan_sanctuaire.gd,
## volcan_porte.gd). A zone is painted tile by tile (1 tile = 1 m), then turned into a Region
## (to_region): its ground, its relief (height_data) and its cover layers, saved next to the scene
## (regions/volcan/).
##
## THE LAVA (the chapter's mechanic B; the contract of the agent MÉCANIQUES: actors/lava.gd, Lava): its
## tiles are « rock » ground (the only « rock » tiles of these zones), sunk LAVA_SINK under their banks
## (no cliff: the step stays walkable), and listed in the Region's meta LAVA_META: an Image (FORMAT_L8,
## one pixel a tile, 255 lava, 0 not), saved as regions/volcan/<zone>_lave.res. Nothing here keeps
## Chloé out of it: Lava (actors/lava_field.gd) reads that meta (she crosses only on the back of a
## stone or fire dino). THE LAVA THAT GOES BACK (the crater path, « lave_retiree »): ordinary ground
## under it, listed in the meta RETREAT_META (same format): nobody crosses it until the flag is set.
## Their picture: a cover layer of lava (LAVE_TEX) on both, over the « rock » tiles' own (warm). The
## ground: black rock (the plain ground, ROCHE_TEX), ash over it (the first cover layer, CENDRE_TEX; its
## trodden paths CENDRE_CHEMIN_TEX), the cooled crust by the flows (CROUTE_TEX).

const B := preload("res://tools/zone_builder.gd")
const GROUND_INDEX := {"grass": 0, "path": 1, "tall_grass": 2, "water": 3, "forest": 4, "sand": 5, "mud": 6, "rock": 7}
## The lava: its ground, how far under its banks (m), the Region meta that lists its tiles.
const LAVA_GROUND := "rock"
const LAVA_SINK := 0.25
const LAVA_META := &"lave"
const RETREAT_META := &"lave_retrait"
## Two tiles further than this in height cannot be walked between (Region.CLIFF_STEP).
const STEP := 0.75
## The pictures (the contract's names first, the stand-ins after; « » = none yet: that layer waits).
const ROCHE_TEX := ["res://assets/art/ground/roche_noire.png", "res://assets/art/ground/grotte_sol.png"]
const CENDRE_TEX := ["res://assets/art/ground/cendre.png", "res://assets/art/ground/neige_chemin.png"]
const CENDRE_CHEMIN_TEX := ["res://assets/art/ground/cendre_chemin.png", "res://assets/art/ground/roche_noire.png",
	"res://assets/art/ground/grotte_sol.png"]
const LAVE_TEX := ["res://assets/art/ground/lave.png"]
const CROUTE_TEX := ["res://assets/art/ground/croute_refroidie.png"]
const OBSIDIENNE_TEX := ["res://assets/art/ground/obsidienne.png", "res://assets/art/ground/grotte_sol.png"]
const DIRS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## Rolls of the open ground (m, at most), none within ROLL_FADE tiles of a level tile or a step.
const ROLL := 0.3
const ROLL_FADE := Vector2(1.0, 4.0)
## How far (tiles) a layer laid over an ellipse thins out beyond it.
const FRINGE := 2.0

var w := 0
var h := 0
var ground := PackedStringArray()
var height := PackedFloat32Array()
## The cover layers' doses (0-1): the ash, the cooled crust; the lava's (1 on its tiles).
var ash := PackedFloat32Array()
var crust := PackedFloat32Array()
var lava := PackedByteArray()
## Tiles of the lava that goes back (1): ordinary ground, blocked until « lave_retiree ».
var retreat := PackedByteArray()
## Tiles kept level (paths, ramps, the places, the lava and its banks): no rolling there.
var level := PackedByteArray()
## Moves the noise from one zone to the next.
var salt := 0.0


func _init(width: int, depth: int, base_height: float, noise_salt: float) -> void:
	w = width
	h = depth
	salt = noise_salt
	var n := w * h
	ground.resize(n)
	ground.fill("grass")
	height.resize(n)
	height.fill(base_height)
	ash.resize(n)
	crust.resize(n)
	lava.resize(n)
	retreat.resize(n)
	level.resize(n)


# ------------------------------------------------------------------ noise

static func _hash(x: int, y: int) -> float:
	var v := (x * 374761393 + y * 668265263) & 0xFFFFFFFF
	v = ((v ^ (v >> 13)) * 1274126177) & 0xFFFFFFFF
	return float((v ^ (v >> 16)) & 0xFFFFFFFF) / 4294967295.0


static func noise(x: float, y: float) -> float:
	var xi := floori(x)
	var yi := floori(y)
	var fx := x - xi
	var fy := y - yi
	var sx := fx * fx * (3.0 - 2.0 * fx)
	var sy := fy * fy * (3.0 - 2.0 * fy)
	var a := _hash(xi, yi)
	var b := _hash(xi + 1, yi)
	var c := _hash(xi, yi + 1)
	var d := _hash(xi + 1, yi + 1)
	return a + (b - a) * sx + (c - a) * sy + (a - b - c + d) * sx * sy


static func fbm(x: float, y: float) -> float:
	return noise(x, y) * 0.6 + noise(x * 2.1 + 17.0, y * 2.1 + 5.0) * 0.3 + noise(x * 4.3 + 3.0, y * 4.3 + 29.0) * 0.1


# ------------------------------------------------------------------ reading

func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func at(x: int, y: int) -> int:
	return clampi(y, 0, h - 1) * w + clampi(x, 0, w - 1)


func height_at(x: int, y: int) -> float:
	return height[at(x, y)]


func ground_at(x: int, y: int) -> String:
	return ground[at(x, y)]


func is_lava(x: int, y: int) -> bool:
	return inside(x, y) and lava[y * w + x] == 1


## Lava within `r` tiles of tile (x, y) (a square).
func near_lava(x: int, y: int, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if is_lava(x + dx, y + dy):
				return true
	return false


## Does tile (x, y) lie in the ellipse of centre `c`, radii `r` (tiles), its edge ragged by `wobble`?
func in_ellipse(x: int, y: int, c: Vector2, r: Vector2, wobble := 0.0) -> bool:
	var dx := (x + 0.5 - c.x) / r.x
	var dy := (y + 0.5 - c.y) / r.y
	return dx * dx + dy * dy < 1.0 + wobble * (fbm(x * 0.35 + salt, y * 0.35) - 0.5)


## Distance (tiles) from the middle of tile (x, y) to a polyline, and where along it (0-1) the
## nearest point lies.
static func to_polyline(x: int, y: int, pts: Array) -> Vector2:
	var total := 0.0
	for k in pts.size() - 1:
		total += (pts[k] as Vector2).distance_to(pts[k + 1])
	var best := INF
	var best_t := 0.0
	var run := 0.0
	var p := Vector2(x + 0.5, y + 0.5)
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best:
			best = d
			best_t = (run + ab.length() * t) / maxf(total, 0.0001)
		run += ab.length()
	return Vector2(best, best_t)


## Steps (tiles) from each tile to the nearest one passing `test` (x, y) -> bool.
func distance_to(test: Callable) -> PackedInt32Array:
	var d := PackedInt32Array()
	d.resize(w * h)
	d.fill(9999)
	var queue: Array[Vector2i] = []
	for y in h:
		for x in w:
			if test.call(x, y):
				d[y * w + x] = 0
				queue.append(Vector2i(x, y))
	var i := 0
	while i < queue.size():
		var c := queue[i]
		i += 1
		for dir in DIRS:
			var n := c + dir
			if inside(n.x, n.y) and d[n.y * w + n.x] > d[c.y * w + c.x] + 1:
				d[n.y * w + n.x] = d[c.y * w + c.x] + 1
				queue.append(n)
	return d


# ------------------------------------------------------------------ painting the relief

## An ellipse of ground at height `top` (m).
func plateau(c: Vector2, r: Vector2, top: float, wobble := 0.5) -> void:
	for y in range(floori(c.y - r.y - 2), ceili(c.y + r.y + 2)):
		for x in range(floori(c.x - r.x - 2), ceili(c.x + r.x + 2)):
			if inside(x, y) and in_ellipse(x, y, c, r, wobble):
				height[y * w + x] = top


## A rectangle of ground at height `top` (`flat`: kept level).
func block(rect: Rect2i, top: float, flat := true) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if inside(x, y):
				height[y * w + x] = top
				level[y * w + x] = 1 if flat else level[y * w + x]


## Ground at height `top`, ragged: every tile where `test` (x, y) -> bool, plus `jitter` m of noise
## (out of reach masses: the volcano's flank, the rims).
func mass(test: Callable, top: float, jitter := 0.0) -> void:
	for y in h:
		for x in w:
			if test.call(x, y):
				height[y * w + x] = top + (fbm(x * 0.21 + salt, y * 0.21 + 3.0) - 0.5) * 2.0 * jitter


## A ramp over `rect` from height `from` to `to`, climbing along `axis` ("x": eastwards, "-x":
## westwards, "y": southwards, "-y": northwards); a path (`as_path`), level across.
func ramp(rect: Rect2i, axis: String, from: float, to: float, as_path := true) -> void:
	var n := rect.size.x if axis.ends_with("x") else rect.size.y
	for j in rect.size.y:
		for i in rect.size.x:
			var k := i if axis == "x" else (rect.size.x - 1 - i if axis == "-x" else (j if axis == "y" else rect.size.y - 1 - j))
			var x := rect.position.x + i
			var y := rect.position.y + j
			if inside(x, y):
				height[y * w + x] = from + (to - from) * (k + 1.0) / (n + 1.0)
				level[y * w + x] = 1
				if as_path:
					ground[y * w + x] = "path"


## A hillside: from row `top_row` (height `top`) to row `foot_row` (height `foot`), every tile of
## those rows over the columns `cols` (x from, x to excluded) set on that even slope (no step: the
## camera, looking north, sees over a slope that goes down northwards when it is gentler than its own
## sight line).
func hillside(cols: Vector2i, top_row: int, top: float, foot_row: int, foot: float) -> void:
	var lo := mini(top_row, foot_row)
	var hi := maxi(top_row, foot_row)
	for y in range(lo, hi + 1):
		var k := float(y - top_row) / float(foot_row - top_row)
		for x in range(cols.x, cols.y):
			if inside(x, y):
				height[y * w + x] = lerpf(top, foot, k)


## A gentle mound (or hollow, `rise` < 0) over an ellipse: its middle `rise` m higher, its sides
## sloping softly to nothing at its rim (a dune of ash, a swell of old lava; no step).
func mound(c: Vector2, r: Vector2, rise: float) -> void:
	for y in range(floori(c.y - r.y), ceili(c.y + r.y)):
		for x in range(floori(c.x - r.x), ceili(c.x + r.x)):
			if not inside(x, y) or level[y * w + x] == 1:
				continue
			var d := Vector2((x + 0.5 - c.x) / r.x, (y + 0.5 - c.y) / r.y).length_squared()
			if d < 1.0:
				height[y * w + x] += rise * (1.0 - d) * (1.0 - d)


## A trail along `pts` (tiles), `width` tiles wide: path, level (never over the lava).
func trail(pts: Array, width := 2.0) -> void:
	_stroke(pts, width, func(x: int, y: int) -> void:
		var i := y * w + x
		if lava[i] == 0:
			ground[i] = "path"
			level[i] = 1)


## A level place (a scene's square, a camp, a fire): no rolling, no tufts.
func keep_level(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if inside(x, y):
				level[y * w + x] = 1


## Tufts (tall grass: the hidden encounters; drawn as ferns of ash once the view knows the zone)
## over a ragged ellipse, on plain open ground only.
func tufts(c: Vector2, r: Vector2) -> void:
	for y in range(floori(c.y - r.y - 1), ceili(c.y + r.y + 1)):
		for x in range(floori(c.x - r.x - 1), ceili(c.x + r.x + 1)):
			if inside(x, y) and in_ellipse(x, y, c, r, 0.6) and ground[y * w + x] == "grass" and level[y * w + x] == 0 \
					and not near_lava(x, y, 1):
				ground[y * w + x] = "tall_grass"


# ------------------------------------------------------------------ the lava

## A river of lava along `pts` (tiles), about `width` tiles wide (its banks ragged by the noise),
## sunk LAVA_SINK under the ground it runs over. Paint it once the relief is done (it follows it).
func lava_river(pts: Array, width: float) -> void:
	var box := Rect2(pts[0], Vector2.ZERO)
	for p: Vector2 in pts:
		box = box.expand(p)
	box = box.grow(width + 2.0)
	for y in range(floori(box.position.y), ceili(box.end.y)):
		for x in range(floori(box.position.x), ceili(box.end.x)):
			if not inside(x, y):
				continue
			var d := to_polyline(x, y, pts)
			var half := width * 0.5 * (0.85 + 0.3 * fbm(x * 0.4 + salt, y * 0.4 + 11.0))
			if d.x < half:
				_set_lava(x, y)


## A lake of lava over a ragged ellipse; `island`: [centre, radii] of the rock left in it (none: []).
func lava_pool(c: Vector2, r: Vector2, island := []) -> void:
	for y in range(floori(c.y - r.y - 2), ceili(c.y + r.y + 2)):
		for x in range(floori(c.x - r.x - 2), ceili(c.x + r.x + 2)):
			if not inside(x, y) or not in_ellipse(x, y, c, r, 0.35):
				continue
			if not island.is_empty() and in_ellipse(x, y, island[0], island[1], 0.0):
				continue
			_set_lava(x, y)


## Lava on every tile where `test` (x, y) -> bool (a ring along a hall's walls).
func lava_where(test: Callable) -> void:
	for y in h:
		for x in w:
			if test.call(x, y):
				_set_lava(x, y)


## The lava that goes back on every tile where `test` (x, y) -> bool: the ground stays as it is (it is
## walked on once the lava has gone), painted as lava, no ash, no crust.
func lava_retreat(test: Callable) -> void:
	for y in h:
		for x in w:
			if test.call(x, y) and lava[y * w + x] == 0:
				retreat[y * w + x] = 1


func _set_lava(x: int, y: int) -> void:
	var i := y * w + x
	if lava[i] == 1:
		return
	lava[i] = 1
	ground[i] = LAVA_GROUND
	height[i] -= LAVA_SINK
	level[i] = 1


## The cooled crust (the third cover layer) on the banks of the lava, `reach` tiles wide, thinning
## out (the mechanics' « coulées refroidies » are also crust: crust_field).
func crust_banks(reach: int) -> void:
	var d := distance_to(func(x: int, y: int) -> bool: return lava[y * w + x] == 1)
	for i in w * h:
		if lava[i] == 0 and d[i] <= reach:
			var x := i % w
			var y := floori(float(i) / w)
			crust[i] = maxf(crust[i], clampf(1.15 - float(d[i]) / (reach + 1.0) - 0.3 * fbm(x * 0.5 + salt, y * 0.5), 0.0, 1.0))


## A field of cooled crust (old flows, walkable: the Saichania's ground) over a ragged ellipse.
func crust_field(c: Vector2, r: Vector2, dose := 1.0) -> void:
	for y in range(floori(c.y - r.y - FRINGE - 1), ceili(c.y + r.y + FRINGE + 1)):
		for x in range(floori(c.x - r.x - FRINGE - 1), ceili(c.x + r.x + FRINGE + 1)):
			if inside(x, y) and lava[y * w + x] == 0:
				crust[y * w + x] = maxf(crust[y * w + x], dose * _fringe(x, y, c, r))


## How much of an ellipse's layer lies on tile (x, y): all of it inside, thinning out over FRINGE
## tiles beyond its ragged edge, in irregular wisps.
func _fringe(x: int, y: int, c: Vector2, r: Vector2) -> float:
	var d := Vector2((x + 0.5 - c.x) / r.x, (y + 0.5 - c.y) / r.y).length()
	var edge := 1.0 + 0.35 * (fbm(x * 0.35 + salt, y * 0.35) - 0.5)
	if d < edge:
		return 1.0
	var out := (d - edge) * minf(r.x, r.y) / FRINGE
	return clampf(1.0 - out, 0.0, 1.0) * (0.45 + 0.55 * fbm(x * 0.6 + 13.0 + salt, y * 0.6 + 5.0))


# ------------------------------------------------------------------ finishing

## Gentle rolls on the open ground (never a step), none by a level tile or a step; then the ash: `dose`
## everywhere (in patches where `patchy` > 0: the noise takes that much of it away), none on the lava
## and thin on its banks, under the crust.
func finish(dose: float, patchy := 0.0) -> void:
	var hard := distance_to(func(x: int, y: int) -> bool: return level[y * w + x] == 1 or _cliff(x, y))
	for y in h:
		for x in w:
			var i := y * w + x
			if level[i] == 1:
				continue
			var fade := smoothstep(ROLL_FADE.x, ROLL_FADE.y, float(hard[i]))
			height[i] += minf(ROLL, maxf(0.0, fbm(x * 0.13 + 41.0 + salt, y * 0.13 + 7.0) - 0.42) * 0.8 * fade)
	var by_lava := distance_to(func(x: int, y: int) -> bool: return lava[y * w + x] == 1 or retreat[y * w + x] == 1)
	for y in h:
		for x in w:
			var i := y * w + x
			if lava[i] == 1 or retreat[i] == 1:
				ash[i] = 0.0
				crust[i] = 0.0   # (the crust layer lies over the lava's: none on it)
				continue
			var n := fbm(x * 0.11 + 90.0 + salt, y * 0.11 + 30.0)
			var a := dose * (1.0 - patchy * smoothstep(0.35, 0.65, n))
			a *= smoothstep(0.0, 3.0, float(by_lava[i]))   # (the heat: no ash right by the lava)
			ash[i] = clampf(a * (1.0 - 0.7 * crust[i]), 0.0, 1.0)


## A step higher than STEP to a neighbour of tile (x, y).
func _cliff(x: int, y: int) -> bool:
	for dir in DIRS:
		if inside(x + dir.x, y + dir.y) and absf(height_at(x + dir.x, y + dir.y) - height_at(x, y)) > STEP:
			return true
	return false


func _stroke(pts: Array, width: float, paint: Callable) -> void:
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var n := ceili(a.distance_to(b) * 3.0)
		for s in n + 1:
			var p := a.lerp(b, float(s) / maxf(n, 1))
			for dy in ceili(width):
				for dx in ceili(width):
					var x := floori(p.x - width / 2.0 + dx + 0.5)
					var y := floori(p.y - width / 2.0 + dy + 0.5)
					if inside(x, y):
						paint.call(x, y)


# ------------------------------------------------------------------ the region

## The zone `id` as a Region: its ground, its relief, its cover layers (the ash with its trodden
## paths; the lava and the crust), the lava's metas; saved in `res_dir`. `floor_tex`: the plain ground's
## pictures (black rock; the sanctuary's obsidian); `path_tex`: the trails' (black rock trodden through the
## ash of the fields; ash trodden onto the bare rock of the coulées).
func to_region(id: StringName, region_name: String, zone_name: String, levels: Vector2i, res_dir: String,
		floor_tex := ROCHE_TEX, path_tex := CENDRE_CHEMIN_TEX) -> Region:
	var plan: Array = []
	for y in h:
		plan.append(".".repeat(w))
	var root := B.region(id, region_name, zone_name, levels, plan)
	var terrain: TileMapLayer = root.get_node("Terrain")
	for y in h:
		for x in w:
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(GROUND_INDEX[ground[y * w + x]], 0))
	root.terrain = terrain
	var relief := Image.create_empty(w, h, false, Image.FORMAT_RF)
	for y in h:
		for x in w:
			relief.set_pixel(x, y, Color(height[y * w + x], 0, 0))
	root.height_data = _saved(relief, "%s/%s_relief.res" % [res_dir, id])
	root.ground_tex = load(first(floor_tex))
	root.path_tex = load(first(path_tex))
	if _any(ash):
		root.cover_tex = load(first(CENDRE_TEX))
		root.cover_path_tex = load(first(path_tex))
		root.cover_data = _saved(_dose_image(ash), "%s/%s_cendre.res" % [res_dir, id])
		root.cover_snow = false
	var lava_dose := PackedFloat32Array()
	var painted := PackedFloat32Array()   # (the lava's picture: the lava, and the lava that goes back)
	var going := PackedFloat32Array()
	lava_dose.resize(w * h)
	painted.resize(w * h)
	going.resize(w * h)
	for i in w * h:
		lava_dose[i] = float(lava[i])
		going[i] = float(retreat[i])
		painted[i] = maxf(lava_dose[i], going[i])
	if first(LAVE_TEX) != "" and _any(painted):
		root.cover_layers.append({"tex": load(first(LAVE_TEX)), "data": _saved(_dose_image(painted), "%s/%s_couche_lave.res" % [res_dir, id]),
			"snow": false})
	if first(CROUTE_TEX) != "" and _any(crust):
		root.cover_layers.append({"tex": load(first(CROUTE_TEX)), "data": _saved(_dose_image(crust), "%s/%s_croute.res" % [res_dir, id]),
			"snow": false})
	root.set_meta(LAVA_META, _saved(_dose_image(lava_dose), "%s/%s_lave.res" % [res_dir, id]))
	if _any(going):
		root.set_meta(RETREAT_META, _saved(_dose_image(going), "%s/%s_lave_retrait.res" % [res_dir, id]))
	return root


static func _any(dose: PackedFloat32Array) -> bool:
	for v in dose:
		if v > 0.0:
			return true
	return false


func _dose_image(dose: PackedFloat32Array) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_L8)
	for y in h:
		for x in w:
			var v := clampf(dose[y * w + x], 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	return img


static func _saved(img: Image, path: String) -> Image:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	ResourceSaver.save(img, path)
	return load(path)


## The first of `paths` that exists ("" when none does).
static func first(paths: Array) -> String:
	for p: String in paths:
		if ResourceLoader.exists(p):
			return p
	return ""
