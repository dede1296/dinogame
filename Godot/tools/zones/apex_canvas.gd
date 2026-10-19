extends "res://tools/zones/volcan_canvas.gd"
## La Terre des Apex (chapter 9): the map painter of its two zones (tools/zones/apex_terre.gd,
## apex_coeur.gd). The Plaine Volcanique's painter (volcan_canvas.gd: the relief, the trails, the ramps,
## the rolls; tile by tile, 1 tile = 1 m) without its lava and its ash: the crater is black rock, « pas
## de lave », and in it VEINS OF AMBER that glow on their own: a cover layer dosed tile by tile
## (VEINES_TEX, drawn by the agent IMAGES; the layer waits until it is), saved next to the scene
## (regions/apex/<zone>_veines.res). The plans scatter amber crystals (lit) along them, so the glow is
## there before the picture.

## The pictures (the contract's names first, then the stand-ins already drawn; « » = none yet).
const ROCHE_APEX_TEX := ["res://assets/art/ground/roche_apex.png", "res://assets/art/ground/roche_noire.png"]
## The fond's floor (coeur_apex): darker.
const ROCHE_FOND_TEX := ["res://assets/art/ground/roche_apex_fond.png", "res://assets/art/ground/roche_apex.png",
	"res://assets/art/ground/roche_noire.png"]
## The trails: trodden smooth, darker (the fond's rock) on the crater's; on the fond's floor, the crater's.
const CHEMIN_APEX_TEX := ["res://assets/art/ground/chemin_apex.png", "res://assets/art/ground/roche_apex_fond.png",
	"res://assets/art/ground/cendre.png"]
const CHEMIN_FOND_TEX := ["res://assets/art/ground/chemin_apex.png", "res://assets/art/ground/roche_apex.png",
	"res://assets/art/ground/cendre.png"]
const VEINES_TEX := ["res://assets/art/ground/veines_ambre.png"]
const VEINS_META := &"veines"

## The veins' dose (0-1) on each tile.
var veins := PackedFloat32Array()


func _init(width: int, depth: int, base_height: float, noise_salt: float) -> void:
	super(width, depth, base_height, noise_salt)
	veins.resize(w * h)


## Height `height_of` (x, y) -> float on every tile where `test` (x, y) -> bool; `flat`: kept level.
func shape(test: Callable, height_of: Callable, flat := false) -> void:
	for y in h:
		for x in w:
			if test.call(x, y):
				height[y * w + x] = height_of.call(x, y)
				if flat:
					level[y * w + x] = 1


## A vein of amber along `pts` (tiles), about `width` tiles wide, its edges ragged by the noise.
func vein(pts: Array, width: float) -> void:
	var box := Rect2(pts[0], Vector2.ZERO)
	for p: Vector2 in pts:
		box = box.expand(p)
	box = box.grow(width + 2.0)
	for y in range(floori(box.position.y), ceili(box.end.y)):
		for x in range(floori(box.position.x), ceili(box.end.x)):
			if not inside(x, y):
				continue
			var d := to_polyline(x, y, pts).x
			var half := width * 0.5 * (0.7 + 0.6 * fbm(x * 0.5 + salt, y * 0.5 + 23.0))
			if d < half + 1.0:
				veins[y * w + x] = maxf(veins[y * w + x], clampf(1.0 - maxf(0.0, d - half), 0.0, 1.0))


## The zone `id` as a Region: its ground, its relief, the veins' layer (once drawn); saved in `res_dir`.
## `floor_tex`, `path_tex`: the pictures of the plain ground and of the trails.
func apex_region(id: StringName, region_name: String, zone_name: String, levels: Vector2i, res_dir: String,
		floor_tex := ROCHE_APEX_TEX, path_tex := CHEMIN_APEX_TEX) -> Region:
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
	# The veins: their dose is kept (meta), and laid as the first cover layer once their picture exists.
	var dose := _saved(_dose_image(veins), "%s/%s_veines.res" % [res_dir, id])
	root.set_meta(VEINS_META, dose)
	if first(VEINES_TEX) != "" and _any(veins):
		root.cover_tex = load(first(VEINES_TEX))
		root.cover_path_tex = root.cover_tex
		root.cover_data = dose
		root.cover_snow = false
	return root
