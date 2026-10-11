extends RefCounted
## Les Cieux Éternels (chapter 7): does a piece of scenery stand on the ground, or float? (Greg, 11/10:
## « les pitons volent de part et d'autre des chemins ».) A prop is drawn upright in the 3D view
## (WorldView._add_billboards): its picture's foot is at the ground point the view gives it
## (HeightMap.to_3d: by a cliff, the tile's own level, even where the drawn ground has already dropped
## towards the void), lowered by its `foot` share, raised by the transparent rows under the drawn base.
## lift() measures, across the drawn base's width, how far that base stands above the drawn ground
## under it: over TOLERANCE, it floats. settle() moves a prop to the nearest place where it does not
## (the generators call it on every prop they place: a common rule, not a fix one by one); the test
## (tools/scenarios/vis_cieux.gd) checks the built zones with the same measure.

## Upright pictures are stretched this much (WorldView.STRETCH, the billboard shader's).
const STRETCH := 1.15
const PX := 48.0
## How far a drawn base may stand above the ground under it (m).
const TOLERANCE := 0.05
## Opaque enough to be part of the drawing (a picture's alpha).
const OPAQUE := 0.5
## The base: the lowest rows of the drawing, this share of its height, measured for its width.
const BASE_ROWS := 0.03
## Where settle() looks for a place that holds (tiles): rings this far apart, up to SEARCH tiles away.
const STEP := 0.1
const SEARCH := 1.2

## kind -> [width, height, transparent rows under the base, base's left x, base's right x] (px).
static var _bases := {}


## The drawing of `kind`, measured once: its size, the transparent rows under it, its base's width.
static func base_of(kind: String) -> Array:
	if _bases.has(kind):
		return _bases[kind]
	var img := (load(Prop.ART % kind) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var bottom := h - 1
	while bottom > 0 and not _row_opaque(img, bottom):
		bottom -= 1
	var left := w
	var right := 0
	for y in range(maxi(0, bottom - ceili(h * BASE_ROWS)), bottom + 1):
		for x in w:
			if img.get_pixel(x, y).a > OPAQUE:
				left = mini(left, x)
				right = maxi(right, x)
	_bases[kind] = [w, h, h - 1 - bottom, left, maxi(right, left)]
	return _bases[kind]


static func _row_opaque(img: Image, y: int) -> bool:
	for x in range(0, img.get_width(), 2):
		if img.get_pixel(x, y).a > OPAQUE:
			return true
	return false


## How far (m) the drawn base of a prop of `kind` at world point `at` (px) stands above the drawn
## ground under it, the most along its width (`hm`: the zone's HeightMap); <= 0: it stands or sinks.
static func lift(hm: HeightMap, kind: String, flip: bool, at: Vector2) -> float:
	if not Prop.KINDS.has(kind) or Prop.KINDS[kind].has("model"):
		return 0.0
	var def: Dictionary = Prop.KINDS[kind]
	var b := base_of(kind)
	var metres := float(def["scale"]) / PX
	var anchor := hm.to_3d(at).y
	var base := anchor + (-float(def.get("foot", 0.0)) * float(b[1]) + float(b[2])) * metres * STRETCH
	var worst := -INF
	for x: float in [float(b[3]), (b[3] + b[4]) * 0.5, float(b[4])]:
		var dx: float = (x - float(b[0]) * 0.5) * metres * (-1.0 if flip else 1.0)
		worst = maxf(worst, base - hm.height(at / PX + Vector2(dx, 0.0)))
	return worst


## Moves prop `p` (in zone `root`) to the nearest place within SEARCH tiles where its drawn base
## stands on the ground (lift <= TOLERANCE), on the same kind of ground (the void stays the void, a
## bridge's deck its deck); frees it when there is none and `may_drop` (plain scenery). Returns
## whether it now stands.
static func settle(hm: HeightMap, root: Region, p: Prop, may_drop := true) -> bool:
	if lift(hm, p.kind, p.flip, p.position) <= TOLERANCE:
		return true
	var start := p.position / PX
	var here := _ground_class(root, start)
	var r := STEP
	while r <= SEARCH + 0.001:
		var n := maxi(8, ceili(TAU * r / STEP))
		for k in n:
			var t := start + Vector2.from_angle(TAU * k / n) * r
			if _ground_class(root, t) != here:
				continue
			if lift(hm, p.kind, p.flip, t * PX) <= TOLERANCE:
				p.position = t * PX
				return true
		r += STEP
	if may_drop:
		p.get_parent().remove_child(p)
		p.free()
	return false


## What a point stands on, for settle(): the void, a path (a trail, a bridge's deck) or open ground.
static func _ground_class(root: Region, t: Vector2) -> int:
	var c := Vector2i(t.floor())
	if root.tile_height(c) < float(root.get_meta(&"vol_vide_sous", -INF)):
		return 0
	return 1 if root.surface_at(t * PX) == &"path" else 2


## Every prop of zone `root` standing on the ground: settled where it floats (plain scenery that
## cannot be is removed; the story's things, the pickups and the signs are only moved, and reported
## when they cannot be). Returns what could not be settled.
static func settle_all(root: Region) -> Array[String]:
	var hm := HeightMap.new(root, 2)
	var left: Array[String] = []
	for n in root.get_node("Entities").get_children():
		if not n is Prop:
			continue
		# (A stone hiding an amber pebble is never removed: it is counted.)
		var plain: bool = n.get_script() == Prop and (n as Prop).hidden_pebble == &""
		var name_ := "%s %s" % [n.name, ((n as Node2D).position / PX).snapped(Vector2(0.1, 0.1))]
		if not settle(hm, root, n, plain) and not plain:
			left.append(name_)
	return left
