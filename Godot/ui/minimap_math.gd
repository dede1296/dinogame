class_name MinimapMath
extends RefCounted
## La géométrie de la mini-carte (Minimap), sans rien afficher (tests/ui/test_minimap_math.gd) : du
## monde à sa fenêtre ronde — le nord en haut et l'est à droite, comme ZoneMap et comme l'écran (la
## caméra inclinée regarde toujours vers le nord) —, les marques hors cadre sur le bord, la bascule
## petite → grande → masquée, le zoom par paliers, le sol que voit la caméra, la taille de la fenêtre.

enum Mode { HIDDEN, SMALL, LARGE }

## The zoom levels: how far (tiles, metres) the small window sees from Chloé to its edge.
const ZOOM_TILES: Array[float] = [40.0, 28.0, 20.0, 14.0]
const ZOOM_DEFAULT := 1


## Tab (the pad's ↓): small → large → hidden → small.
static func next_mode(mode: int) -> int:
	match mode:
		Mode.SMALL:
			return Mode.LARGE
		Mode.LARGE:
			return Mode.HIDDEN
	return Mode.SMALL


## Zoom level `level` moved by `step`, kept among ZOOM_TILES.
static func zoom_level(level: int, step := 0) -> int:
	return clampi(level + step, 0, ZOOM_TILES.size() - 1)


## Pixels per tile at zoom `level`, the small window's radius being `small_radius` px (the large one
## keeps the same scale: it shows more around).
static func px_per_tile(level: int, small_radius: float) -> float:
	return small_radius / ZOOM_TILES[zoom_level(level)]


## Where tile `tile` is in the window, from its middle (px), Chloé at `chloe`, `k` px per tile.
static func to_window(tile: Vector2, chloe: Vector2, k: float) -> Vector2:
	return (tile - chloe) * k


## A mark `offset` px from the middle of a round window of `radius` px: {inside, at} — or, out of the
## frame, its marker on the rim, `inset` px in, towards it: {inside: false, at, dir}.
static func rim(offset: Vector2, radius: float, inset: float) -> Dictionary:
	if offset.length() <= radius - inset:
		return {"inside": true, "at": offset}
	var dir := offset.normalized() if offset.length() > 0.001 else Vector2.UP
	return {"inside": false, "at": dir * (radius - inset), "dir": dir}


## The angle of an arrow from `from` to `to` (tiles): 0 = east, -PI/2 = north (up on the screen).
static func angle_to(from: Vector2, to: Vector2) -> float:
	return (to - from).angle()


## The ground the camera sees, in tiles: where the corners of the screen fall on the ground at height
## `ground_y` — [top left, top right, bottom right, bottom left] (3D x = tile x, 3D z = tile y, 1 m a
## tile). Empty when a corner sees the sky. `fov_deg`: the camera's vertical field (Camera3D.fov).
static func footprint(cam: Transform3D, fov_deg: float, aspect: float, ground_y: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var ty := tan(deg_to_rad(fov_deg) / 2.0)
	var tx := ty * aspect
	for corner: Vector2 in [Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var dir := cam.basis * Vector3(corner.x * tx, corner.y * ty, -1.0)
		if dir.y > -0.0001:
			return PackedVector2Array()
		var t := (ground_y - cam.origin.y) / dir.y
		if t <= 0.0:
			return PackedVector2Array()
		var p := cam.origin + dir * t
		out.append(Vector2(p.x, p.z))
	return out


## Must the cached picture of the map be drawn again? Chloé went `shift` px from where it was drawn
## (it overlaps the window by `margin` px all round), or it is `age` s old (`every`: what was seen,
## the people, the objectives change too).
static func needs_render(shift: Vector2, margin: float, age: float, every: float) -> bool:
	return shift.length() > margin * 0.5 or age >= every


## The window's diameter: `wanted` px, at most what is left between the bottom of the right-hand
## column of buttons (`top_limit`) and the bottom of the screen (`inset_y` + `gap` above it).
static func diameter(wanted: float, screen_h: float, inset_y: float, top_limit: float, gap: float) -> float:
	return clampf(minf(wanted, screen_h - inset_y - gap - top_limit), 0.0, wanted)


## Shown when the player wants it (`mode`), outdoors, and the screen is free (no scene, no dialogue).
static func should_show(mode: int, outdoor: bool, free: bool) -> bool:
	return mode != Mode.HIDDEN and outdoor and free
