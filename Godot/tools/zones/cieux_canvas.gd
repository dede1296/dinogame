extends RefCounted
## Les Cieux Éternels (chapter 7): the map painter shared by the plans of the three zones
## (tools/zones/cieux.gd, nids_geants.gd, arche_du_vent.gd). A zone is painted tile by tile (1 tile
## = 1 m), then turned into a Region (to_region): its ground, its relief (height_data) and its
## cover layers, all saved next to the scene (regions/cieux/).
##
## The void between the pitons is the SEA OF CLOUDS, lower down: ordinary ground (« grass ») several
## metres under the plateaus, painted as clouds by the zone's first cover layer (CLOUDS_TEX, dose 1).
## On foot, the cliffs stop Chloé at its edge (Region._add_cliffs, like the Monts' crevasses); in
## flight one goes over it (the flight ignores the cliffs, as everywhere); one never lands there: the
## Region's meta « vol_vide_sous » (m, read by story/vol.gd) says which tiles are the void.
## The pitons are plateaus (ellipses with ragged edges), at levels climbing towards the north (the
## camera looks north: their faces look south, towards it); the liana bridges are bands of ground
## two tiles wide at the plateaus' level (they may climb gently from one to the next), their deck in
## planks (the third cover layer), their sides cliffs down to the clouds.

const B := preload("res://tools/zone_builder.gd")

## The sea of clouds of the Cieux (m) and how much it billows; below VOID_BELOW, a tile is the void
## (each zone may have its own: the nests and the Arche, higher up, have theirs; where two zones
## meet, the clouds rise or sink to meet at the edge: edge_clouds). By the liana bridges the clouds
## rise in banks (banks): BANK_GAP under the deck by its side, then down BANK_STEP a tile (a gentle
## slope: no rock face in the clouds) over BANK_REACH tiles, never above BANK_UNDER under the void's
## height (still the void).
const CLOUDS := 8.4
const BILLOW := 0.3
const VOID_BELOW := 10.0
const BANK_GAP := 1.2
const BANK_STEP := 0.32
const BANK_REACH := 5
const BANK_UNDER := 0.15
## Where the Cieux meet the nests (the Cieux' north edge, the nests' south edge), both seas of clouds
## are this high.
const EDGE_CLOUDS := 9.8
## Two tiles further than this in height cannot be walked between (Region.CLIFF_STEP).
const STEP := 0.75
## Tufts of the summits (encounters hidden in them), the trails.
const GROUND_INDEX := {"grass": 0, "path": 1, "tall_grass": 2, "water": 3, "forest": 4, "sand": 5, "mud": 6, "rock": 7}
## The pictures (the contract's names; the stand-ins while they are not drawn).
const CLOUDS_TEX := ["res://assets/art/ground/nuages.png", "res://assets/art/ground/neige.png"]
const STONE_TEX := ["res://assets/art/ground/pierre_cieux.png", "res://assets/art/ground/grotte_sol.png"]
const SNOW_TEX := ["res://assets/art/ground/neige.png"]
const SNOW_PATH_TEX := ["res://assets/art/ground/neige_chemin.png", "res://assets/art/ground/neige.png"]
const PLANKS_TEX := ["res://assets/art/ground/pont_lianes.png", "res://assets/art/ground/plancher.png"]
const NEST_TEX := ["res://assets/art/ground/nid.png", "res://assets/art/ground/sous_bois.png"]
const DIRS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## The snow under a walkable field of clouds (over 0.5: the steps crunch, Player._on_snow).
const FIELD_SNOW := 0.62
## How far (tiles) a layer laid over an ellipse (a nest's straw, a field of clouds) thins out beyond it,
## and how much of the clouds wisps over the field's rim.
const FRINGE := 2.0
const RIM_WISPS := 0.5
## The snow lies thicker higher up: from SNOW_LOW (m, the least) to SNOW_HIGH (the most).
const SNOW_LOW := 10.8
const SNOW_HIGH := 17.4

var w := 0
var h := 0
var ground := PackedStringArray()
var height := PackedFloat32Array()
## The cover layers' doses (0-1): the clouds, the snow (or, in the nests, the straw), the planks of
## the bridges (the third layer).
var clouds := PackedFloat32Array()
var snow := PackedFloat32Array()
var straws := PackedFloat32Array()
var third := PackedFloat32Array()
## Tiles kept level (paths, bridges, the places): no rolling there.
var level := PackedByteArray()
var bridges := PackedByteArray()
## Tiles of a hollow full of clouds one walks on (cloud_field).
var fields := PackedByteArray()
## Moves the noise from one zone to the next (they are not the same sky).
var salt := 0.0
## This zone's sea of clouds and the height under which a tile is the void (m).
var clouds_h := CLOUDS
var void_below := VOID_BELOW


func _init(width: int, depth: int, noise_salt: float, sea := CLOUDS, void_height := VOID_BELOW) -> void:
	w = width
	h = depth
	salt = noise_salt
	clouds_h = sea
	void_below = void_height
	var n := w * h
	ground.resize(n)
	ground.fill("grass")
	height.resize(n)
	clouds.resize(n)
	snow.resize(n)
	straws.resize(n)
	third.resize(n)
	level.resize(n)
	bridges.resize(n)
	fields.resize(n)
	for y in h:
		for x in w:
			var i := y * w + x
			height[i] = clouds_h + (fbm(x * 0.17 + salt, y * 0.17) - 0.5) * 2.0 * BILLOW
			clouds[i] = 1.0


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


func is_void(x: int, y: int) -> bool:
	return height[at(x, y)] < void_below


func ground_at(x: int, y: int) -> String:
	return ground[at(x, y)]


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


# ------------------------------------------------------------------ painting

## A piton's top: the ellipse at height `top` (m), plain ground, no clouds.
func plateau(c: Vector2, r: Vector2, top: float, wobble := 0.5) -> void:
	for y in range(floori(c.y - r.y - 2), ceili(c.y + r.y + 2)):
		for x in range(floori(c.x - r.x - 2), ceili(c.x + r.x + 2)):
			if inside(x, y) and in_ellipse(x, y, c, r, wobble):
				_land(x, y, top)


## A rectangle of ground at height `top` (the gully's walls, a level square).
func block(rect: Rect2i, top: float, flat := true) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if inside(x, y):
				_land(x, y, top)
				level[y * w + x] = 1 if flat else level[y * w + x]


## A ramp over `rect` from height `from` to `to`, climbing along `axis` ("x": eastwards, "-x":
## westwards, "y": southwards, "-y": northwards); the steps between its rows stay walkable.
func ramp(rect: Rect2i, axis: String, from: float, to: float) -> void:
	var n := rect.size.x if axis.ends_with("x") else rect.size.y
	for j in rect.size.y:
		for i in rect.size.x:
			var k := i if axis == "x" else (rect.size.x - 1 - i if axis == "-x" else (j if axis == "y" else rect.size.y - 1 - j))
			var x := rect.position.x + i
			var y := rect.position.y + j
			if inside(x, y):
				_land(x, y, from + (to - from) * (k + 1.0) / (n + 1.0))
				ground[y * w + x] = "path"
				level[y * w + x] = 1


## A liana bridge along `pts` (tile points), `width` tiles wide, from height `from` to `to`: over
## the void only (where it meets a plateau, the plateau's trail goes on); its deck in planks.
## `planks` false: a ridge of bare rock instead (a path over it, no deck, no banks of clouds).
func bridge(pts: Array, from: float, to: float, width := 2.0, planks := true) -> void:
	var box := Rect2(pts[0], Vector2.ZERO)
	for p: Vector2 in pts:
		box = box.expand(p)
	box = box.grow(width + 1.0)
	for y in range(floori(box.position.y), ceili(box.end.y)):
		for x in range(floori(box.position.x), ceili(box.end.x)):
			if not inside(x, y):
				continue
			var d := to_polyline(x, y, pts)
			if d.x >= width * 0.5:
				continue
			var i := y * w + x
			if not is_void(x, y) and bridges[i] == 0:
				if planks:
					third[i] = maxf(third[i], 0.6)   # (a few planks onto the plateau: the bridge's landing)
				continue
			_land(x, y, lerpf(from, to, d.y))
			ground[i] = "path"
			level[i] = 1
			if planks:
				third[i] = 1.0
				bridges[i] = 1


## The clouds rising in banks along the bridges (BANK_GAP under the deck by its side, BANK_STEP
## lower a tile farther): the deck skims over them, its sides short (still the void: no landing).
func banks() -> void:
	for y in h:
		for x in w:
			if not is_void(x, y):
				continue
			var top := -INF
			for dy in range(-BANK_REACH, BANK_REACH + 1):
				for dx in range(-BANK_REACH, BANK_REACH + 1):
					if inside(x + dx, y + dy) and bridges[(y + dy) * w + x + dx] == 1:
						var d := maxi(absi(dx), absi(dy))
						top = maxf(top, height_at(x + dx, y + dy) - BANK_GAP - BANK_STEP * (d - 1))
			if top > -INF:
				height[y * w + x] = maxf(height[y * w + x], minf(top, void_below - BANK_UNDER))


## Where this zone meets another along an edge ("north" / "south"), its clouds rise or sink to
## `edge_h` at the edge, gently (BANK_STEP a tile): the two seas of clouds meet without a step.
func edge_clouds(edge: String, edge_h: float) -> void:
	for y in h:
		for x in w:
			if not is_void(x, y):
				continue
			var d := y if edge == "north" else h - 1 - y
			var i := y * w + x
			var target := edge_h + signf(height[i] - edge_h) * BANK_STEP * d
			if (edge_h > height[i] and target > height[i]) or (edge_h < height[i] and target < height[i]):
				height[i] = minf(target, void_below - BANK_UNDER)


## A trail along `pts` over the plateaus (never over the void, never over a bridge's deck: it is a
## path already), `width` tiles wide.
func trail(pts: Array, width := 2.0) -> void:
	_stroke(pts, width, func(x: int, y: int) -> void:
		var i := y * w + x
		if not is_void(x, y) and bridges[i] == 0:
			ground[i] = "path"
			level[i] = 1)


## A level place (a scene's square, a landing area, a fire): no rolling, no tufts.
func keep_level(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if inside(x, y):
				level[y * w + x] = 1


## Tufts (tall grass: the encounters hide there) over a ragged ellipse, on plain ground only.
func tufts(c: Vector2, r: Vector2) -> void:
	for y in range(floori(c.y - r.y - 1), ceili(c.y + r.y + 1)):
		for x in range(floori(c.x - r.x - 1), ceili(c.x + r.x + 1)):
			if inside(x, y) and in_ellipse(x, y, c, r, 0.6) and ground[y * w + x] == "grass" and not is_void(x, y) \
					and level[y * w + x] == 0:
				ground[y * w + x] = "tall_grass"


## How much of an ellipse's layer lies on tile (x, y): all of it inside, then thinning out over FRINGE
## tiles beyond its ragged edge, in irregular wisps (noise).
func _fringe(x: int, y: int, c: Vector2, r: Vector2) -> float:
	var d := Vector2((x + 0.5 - c.x) / r.x, (y + 0.5 - c.y) / r.y).length()
	var edge := 1.0 + 0.35 * (fbm(x * 0.35 + salt, y * 0.35) - 0.5)
	if d < edge:
		return 1.0
	var out := (d - edge) * minf(r.x, r.y) / FRINGE
	return clampf(1.0 - out, 0.0, 1.0) * (0.45 + 0.55 * fbm(x * 0.6 + 13.0 + salt, y * 0.6 + 5.0))


## A piton's hollow the clouds fill, one walks on them like on a frozen lake: its floor at
## `floor_h` (m, a gentle step below the rim: walkable), painted as clouds, snow under them so that
## the steps crunch (finish).
func cloud_field(c: Vector2, r: Vector2, floor_h: float) -> void:
	for y in range(floori(c.y - r.y - 1), ceili(c.y + r.y + 1)):
		for x in range(floori(c.x - r.x - 1), ceili(c.x + r.x + 1)):
			if inside(x, y) and in_ellipse(x, y, c, r, 0.35) and not is_void(x, y):
				var i := y * w + x
				height[i] = floor_h
				clouds[i] = 1.0
				level[i] = 1
				fields[i] = 1
	# Wisps of it over the rim (not a line between the clouds and the stone).
	for y in range(floori(c.y - r.y - FRINGE - 1), ceili(c.y + r.y + FRINGE + 1)):
		for x in range(floori(c.x - r.x - FRINGE - 1), ceili(c.x + r.x + FRINGE + 1)):
			if inside(x, y) and not is_void(x, y) and fields[y * w + x] == 0:
				clouds[y * w + x] = maxf(clouds[y * w + x], RIM_WISPS * _fringe(x, y, c, r))


## The straw of a nest (the nests' second layer) over a ragged ellipse, on the plateaus, thinning out
## around it over FRINGE tiles (twigs and down blown about: never a line between straw and stone).
func straw(c: Vector2, r: Vector2, dose := 1.0) -> void:
	for y in range(floori(c.y - r.y - FRINGE - 1), ceili(c.y + r.y + FRINGE + 1)):
		for x in range(floori(c.x - r.x - FRINGE - 1), ceili(c.x + r.x + FRINGE + 1)):
			if not inside(x, y) or is_void(x, y):
				continue
			var i := y * w + x
			straws[i] = maxf(straws[i], dose * _fringe(x, y, c, r))


## Gentle rolls on the plateaus' open ground (never a step), none by their edges, the paths, the
## level places; then the snow lying in patches, more of it higher up (over a trail, it is a trail of
## packed snow: the snow layer's path picture), none on the bridges' decks.
func finish(snowy := 1.0) -> void:
	var hard := distance_to(func(x: int, y: int) -> bool:
		return is_void(x, y) or level[y * w + x] == 1 or _cliff(x, y))
	var paths := distance_to(func(x: int, y: int) -> bool: return ground[y * w + x] == "path")
	for y in h:
		for x in w:
			var i := y * w + x
			if is_void(x, y) or level[i] == 1:
				continue
			var fade := smoothstep(1.0, 4.0, float(hard[i]))
			height[i] += minf(0.3, maxf(0.0, fbm(x * 0.13 + 41.0 + salt, y * 0.13 + 7.0) - 0.42) * 0.8 * fade)
	for y in h:
		for x in w:
			var i := y * w + x
			if fields[i] == 1:
				snow[i] = FIELD_SNOW
				continue
			if is_void(x, y) or bridges[i] == 1:
				continue
			var up := clampf((height[i] - SNOW_LOW) / (SNOW_HIGH - SNOW_LOW), 0.0, 1.0)
			var n := fbm(x * 0.12 + 90.0 + salt, y * 0.12 + 30.0)
			snow[i] = clampf(((n - 0.5) * 3.2 + up * 0.9 - 0.2) * snowy, 0.0, 1.0)


## Where this zone meets one without snow (the nests) or with all of it (the Monts) along an edge
## ("north" / "south"): the snow there becomes `edge_dose` at the edge, gently over `rows` rows.
func edge_snow(edge: String, edge_dose: float, rows: int) -> void:
	for y in h:
		var d := y if edge == "north" else h - 1 - y
		if d >= rows:
			continue
		var k := smoothstep(0.0, 1.0, float(d) / rows)
		for x in w:
			if not is_void(x, y):
				snow[y * w + x] = lerpf(edge_dose, snow[y * w + x], k)


## The rock tops out of reach (the Rempart): the snow covers them whole, wherever `test` (x, y)
## -> bool says so.
func rock_top_where(test: Callable) -> void:
	for y in h:
		for x in w:
			if test.call(x, y):
				snow[y * w + x] = 1.0


func _land(x: int, y: int, top: float) -> void:
	var i := y * w + x
	height[i] = top
	clouds[i] = 0.0


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

## The zone `id` as a Region: its ground, its relief and its three cover layers (the clouds; the
## snow, or in the nests the straw: `second_is_snow`; the bridges' planks), saved in `res_dir`.
func to_region(id: StringName, region_name: String, zone_name: String, levels: Vector2i, res_dir: String,
		second_tex: Array, third_tex: Array, second_is_snow: bool) -> Region:
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
	root.ground_tex = load(first(STONE_TEX))
	var cloud_data := _saved(_dose_image(clouds), "%s/%s_nuages.res" % [res_dir, id])
	var second_data := _saved(_dose_image(snow if second_is_snow else straws), "%s/%s_couche2.res" % [res_dir, id])
	if second_is_snow:
		# The snow first: the trails under it are trails of packed snow (as in the Monts, which they
		# join), the clouds over it.
		root.cover_tex = load(first(second_tex))
		root.cover_path_tex = load(first(SNOW_PATH_TEX))
		root.cover_data = second_data
		root.cover_snow = true
		root.cover_layers.append({"tex": load(first(CLOUDS_TEX)), "data": cloud_data, "snow": false})
	else:
		# No snow (the nests): the clouds first. They are never walked on, so they may say « snow »:
		# the plateaus are then not all snow underfoot (Player._on_snow, Region.snow_at).
		root.cover_tex = load(first(CLOUDS_TEX))
		root.cover_data = cloud_data
		root.cover_snow = true
		root.cover_layers.append({"tex": load(first(second_tex)), "data": second_data, "snow": false})
	if not third_tex.is_empty():
		root.cover_layers.append({"tex": load(first(third_tex)), "data": _saved(_dose_image(third), "%s/%s_couche3.res" % [res_dir, id]),
			"snow": false})
	root.set_meta(&"vol_vide_sous", void_below)
	return root


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


# ------------------------------------------------------------------ checks

## Prints the checks of a built zone: each place of `on_foot` reachable from tile `from` on foot,
## each of `by_air` NOT reachable on foot but with room to land (3 x 3 level tiles), the open
## ground nobody reaches (but the islets). Returns how many failed.
static func check(root: Region, from: Vector2i, on_foot: Dictionary, by_air: Dictionary) -> int:
	var reach: Dictionary = B._reachable(root, from)
	var failures := 0
	for place: String in on_foot:
		var c := Vector2i((on_foot[place] as Vector2).floor())
		var ok := reach.has(c)
		failures += 0 if ok else 1
		print("  %s %s %s (à pied) : %.2f m" % ["ok " if ok else "NON", place, c, root.tile_height(c)])
	for place: String in by_air:
		var c := Vector2i((by_air[place] as Vector2).floor())
		var ok := not reach.has(c) and B.is_flat(root, c, 1) and root.tile_height(c) >= float(root.get_meta(&"vol_vide_sous"))
		failures += 0 if ok else 1
		print("  %s %s %s (en vol seulement, aire de 3 x 3) : %.2f m, à pied %s" % ["ok " if ok else "NON", place, c,
			root.tile_height(c), "oui" if reach.has(c) else "non"])
	print("  sol injoignable à pied (hors vide) : %d cases" % _lost(root, reach))
	return failures


## Walkable tiles above the void that cannot be reached on foot (the islets count here).
static func _lost(root: Region, reach: Dictionary) -> int:
	var terrain: TileMapLayer = root.get_node("Terrain")
	var size := terrain.get_used_rect().end
	var lost := 0
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			var d := terrain.get_cell_tile_data(c)
			var walkable := d and String(d.get_custom_data("terrain")) in B.WALKABLE
			if walkable and root.tile_height(c) >= float(root.get_meta(&"vol_vide_sous")) and not reach.has(c):
				lost += 1
	return lost
