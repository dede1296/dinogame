class_name SheetFrames
## Builds SpriteFrames from a sheet of equal cells (nano-banana sheets processed by
## tools/process-art.mjs), so a new character or dino needs no hand-made animation file.

## `anims`: name -> {"frames": [cell indices], "fps": float, "loop": bool}.
static func build(sheet: Texture2D, columns: int, rows: int, anims: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_anims(frames, sheet, columns, rows, anims)
	return frames


static func _add_anims(frames: SpriteFrames, sheet: Texture2D, columns: int, rows: int, anims: Dictionary) -> void:
	var cell := Vector2(sheet.get_width() / float(columns), sheet.get_height() / float(rows))
	for anim_name in anims:
		var def: Dictionary = anims[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, def.get("fps", 8.0))
		frames.set_animation_loop(anim_name, def.get("loop", true))
		for i in def["frames"]:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(Vector2(i % columns, i / columns) * cell, cell)
			frames.add_frame(anim_name, atlas)


## Walking character sheet: 4 rows (down, left, right, up) x 4 walk frames. The 4 pictures
## draw one step, so they turn fast (world/view3d/sprite_motion.gd hops once a cycle).
## With its three-quarter views when drawn (`diag`, else the sheet's companion X_diag.png: see
## DIAG_SUFFIX): walk_<diagonal> and idle_<diagonal> too, for the four DIAGONALS.
static func character(sheet: Texture2D, fps := 14.0, diag: Texture2D = null) -> SpriteFrames:
	var anims := {}
	for row in 4:
		var dir: String = ["down", "left", "right", "up"][row]
		var first := row * 4
		anims["walk_" + dir] = {"frames": [first, first + 1, first + 2, first + 3], "fps": fps}
		anims["idle_" + dir] = {"frames": [first], "fps": 1.0}
	var frames := build(sheet, 4, 4, anims)
	if diag == null:
		diag = diag_sheet(sheet)
	if diag:
		_add_diagonals(frames, diag, fps)
	return frames


# ------------------------------------------------------------------ three-quarter views

## Three-quarter views of a walking sheet X.png (docs/sprites-mouvements.md § Trois-quarts de Chloé):
## X_diag.png, cells of the same size, 4 columns (the walk's 4 pictures) x 2 rows: towards the
## bottom-left corner of the screen (three-quarter front), towards the top-left one (three-quarter
## back). The right ones are not drawn: their mirror, made here once per sheet (no flip_h to keep:
## the saddle, the poses and the 3D view see ordinary pictures).
const DIAG_SUFFIX := "_diag"
const DIAGONALS: Array[StringName] = [&"down_left", &"up_left", &"down_right", &"up_right"]
## A direction is diagonal at least this far (degrees) from both axes (45: right on the diagonal)…
const DIAGONAL_DEG := 25.0
## …give or take this margin, so the view does not flicker on the edge: a diagonal shown holds down
## to DIAGONAL_DEG - margin, an axis shown gives way only from DIAGONAL_DEG + margin.
const DIAGONAL_MARGIN_DEG := 4.0
## A diagonal shown gives way to one of its two axes only once that axis has been asked this long
## (s), keys or stick held: the two keys of a diagonal are never let go on the same frame, and she
## stops in her three-quarter view rather than turning at the last moment.
const DIAGONAL_HOLD_S := 0.1

## The mirrors made (see _mirror_of): path of a _diag sheet -> its mirror image.
static var _mirrors := {}


## The path of the three-quarter sheet of the walking sheet at `sheet_path` (X.png -> X_diag.png).
static func diag_path(sheet_path: String) -> String:
	return "%s%s.%s" % [sheet_path.get_basename(), DIAG_SUFFIX, sheet_path.get_extension()]


## The three-quarter sheet of `sheet` when drawn (and imported), else null.
static func diag_sheet(sheet: Texture2D) -> Texture2D:
	if sheet == null or sheet.resource_path == "":
		return null
	var path := diag_path(sheet.resource_path)
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## walk_<diagonal>, idle_<diagonal> (its first picture) from `diag`; the right ones from its mirror,
## whose columns are reversed too (picture i of a right view: column 3 - i). None at all when the
## mirror cannot be made: the dominant axis then, on both sides alike.
static func _add_diagonals(frames: SpriteFrames, diag: Texture2D, fps: float) -> void:
	var mirror := _mirror_of(diag)
	if mirror == null:
		push_warning("SheetFrames: three-quarter views left out, %s unreadable" % diag.resource_path)
		return
	var left := {}
	var right := {}
	for row in 2:
		var dir: String = ["down", "up"][row]
		var first := row * 4
		left["walk_%s_left" % dir] = {"frames": [first, first + 1, first + 2, first + 3], "fps": fps}
		left["idle_%s_left" % dir] = {"frames": [first], "fps": 1.0}
		right["walk_%s_right" % dir] = {"frames": [first + 3, first + 2, first + 1, first], "fps": fps}
		right["idle_%s_right" % dir] = {"frames": [first + 3], "fps": 1.0}
	_add_anims(frames, diag, 4, 2, left)
	_add_anims(frames, mirror, 4, 2, right)


## `sheet` flipped left to right (a texture of its own), made once per imported sheet; null when its
## pixels cannot be read. (The 2D sheets are imported compressed: decompressed first.)
static func _mirror_of(sheet: Texture2D) -> Texture2D:
	var key := sheet.resource_path
	if key != "" and _mirrors.has(key):
		return _mirrors[key]
	var source := sheet.get_image()
	if source == null or source.is_empty():
		return null
	var image := source.duplicate() as Image   # (never the sheet's own pixels)
	if image.is_compressed() and image.decompress() != OK:
		return null
	image.flip_x()
	var mirror := ImageTexture.create_from_image(image)
	if key != "":
		_mirrors[key] = mirror
	return mirror


static func is_diagonal(name: StringName) -> bool:
	return name in DIAGONALS


## Which of 8 directions `dir` goes, on the screen (down, up, left, right, down_left, up_right…): a
## diagonal when at least DIAGONAL_DEG from both axes, else its dominant axis (as direction_name).
## `previous`: the direction shown until now (&"": none), for the margin DIAGONAL_MARGIN_DEG.
static func diagonal_name(dir: Vector2, previous: StringName = &"") -> StringName:
	if dir.is_zero_approx():
		return previous if previous != &"" else &"down"
	var from_x := rad_to_deg(atan2(absf(dir.y), absf(dir.x)))   # 0: along x, 90: along y
	var diagonal := StringName(("down" if dir.y > 0.0 else "up") + ("_left" if dir.x < 0.0 else "_right"))
	var limit := DIAGONAL_DEG
	if previous == diagonal:
		limit -= DIAGONAL_MARGIN_DEG
	elif previous != &"":
		limit += DIAGONAL_MARGIN_DEG
	if minf(from_x, 90.0 - from_x) >= limit:
		return diagonal
	if from_x < 45.0:
		return &"left" if dir.x < 0.0 else &"right"
	return &"down" if dir.y > 0.0 else &"up"


## The view among 8 directions one physics frame on. `state`: the last one ({} at first): "view" the
## direction shown, "for" the facing it was chosen for, "hold" how long (s) one of the two axes of the
## diagonal shown has been asked. `facing`: where she looks now; `steering`: a direction is held (keys,
## stick); `delta`: the frame (s). Returns the new state (never changes `state`): a diagonal gives way
## to one of its axes only once asked DIAGONAL_HOLD_S, a direction held; let go before, it stays.
static func next_view(state: Dictionary, facing: Vector2, steering: bool, delta: float) -> Dictionary:
	if not state.is_empty() and facing == state.get("for"):   # (nothing new asked: a hold is over)
		return state if state.get("hold", 0.0) == 0.0 else {"view": state["view"], "for": facing, "hold": 0.0}
	var view: StringName = state.get("view", &"")
	var wanted := diagonal_name(facing, view)
	if wanted != view and is_diagonal(view) and String(view).split("_").has(String(wanted)):
		var hold: float = state.get("hold", 0.0)
		if steering and hold + delta < DIAGONAL_HOLD_S:
			return {"view": view, "for": state.get("for"), "hold": hold + delta}
		if not steering and hold > 0.0:   # let go during the hold: the diagonal stays
			return {"view": view, "for": facing, "hold": 0.0}
	return {"view": wanted, "for": facing, "hold": 0.0}


## The direction of the walk and idle animations to play for `look` (Outfits' prefix): the view
## (next_view) when `frames` have it for that look (its sheet's three-quarter views), else the
## dominant axis of `facing`, as before.
static func walk_dir(frames: SpriteFrames, look: String, view: Dictionary, facing: Vector2) -> String:
	var name := String(view.get("view", &""))
	if name != "" and frames.has_animation(StringName(look + "walk_" + name)) and frames.has_animation(StringName(look + "idle_" + name)):
		return name
	return direction_name(facing)


## The corrupted look of a species (black amber veins), when drawn: same layout as its sheet.
const CORRUPTED := "res://assets/art/dinos/%s_corrompu.png"
## The species' walk_fps, sped up for the side view: its 3 pictures draw one step. The front
## and back views were drawn with two steps a cycle (left, together, right, together): as is.
const DINO_WALK_TEMPO := 1.5
## SpriteFrames meta: steps drawn in a cycle, per animation (1 when not listed), read by
## world/view3d/sprite_motion.gd to hop at each one.
const STEPS_META := &"steps_per_cycle"


## Dino sheets described by its species: side view (walk, idle, attack) and, when the
## species has one, front/back views (walk_down, idle_down, walk_up, idle_up).
## `corrupted`: its corrupted side view, if drawn.
## Vrai si l'espèce a une planche corrompue dessinée. Sinon, c'est le shader du combat
## (battle/fighter.gdshader, uniform « corruption ») qui montre l'ambre noir.
static func has_corrupted(species: DinoSpecies) -> bool:
	return ResourceLoader.exists(CORRUPTED % species.id)


static func dino(species: DinoSpecies, corrupted := false) -> SpriteFrames:
	var sheet := species.sheet
	if corrupted and ResourceLoader.exists(CORRUPTED % species.id):
		sheet = load(CORRUPTED % species.id)
	var frames := build(sheet, species.sheet_columns, species.sheet_rows, {
		&"walk": {"frames": species.walk_frames, "fps": species.walk_fps * DINO_WALK_TEMPO},
		&"idle": {"frames": species.idle_frames, "fps": 1.6},
		&"attack": {"frames": [species.attack_frame], "fps": 1.0, "loop": false},
	})
	if species.sleep_sheet:   # its own picture, lying down (one frame)
		frames.add_animation(&"sleep")
		frames.add_frame(&"sleep", species.sleep_sheet)
	elif species.sleep_frame >= 0:   # (lying down: asleep only, never while it waits)
		var sleep := build(sheet, species.sheet_columns, species.sheet_rows, {&"sleep": {"frames": [species.sleep_frame], "fps": 1.0}})
		frames.add_animation(&"sleep")
		frames.add_frame(&"sleep", sleep.get_frame_texture(&"sleep", 0))
	if species.face_back_sheet:
		var fb := build(species.face_back_sheet, species.face_back_columns, 2, {
			&"walk_down": {"frames": species.down_walk_frames, "fps": species.walk_fps},
			&"idle_down": {"frames": [species.down_idle_frame], "fps": 1.0},
			&"walk_up": {"frames": species.up_walk_frames, "fps": species.walk_fps},
			&"idle_up": {"frames": [species.up_idle_frame], "fps": 1.0},
		})
		frames.set_meta(STEPS_META, {&"walk_down": 2, &"walk_up": 2})
		for anim in fb.get_animation_names():
			frames.add_animation(anim)
			frames.set_animation_speed(anim, fb.get_animation_speed(anim))
			for i in fb.get_frame_count(anim):
				frames.add_frame(anim, fb.get_frame_texture(anim, i))
	return frames


## Which dino animation fits a movement: side view unless the motion is mostly vertical
## (and the species has front/back views). Returns [walk anim, idle anim].
static func dino_anims(frames: SpriteFrames, dir: Vector2) -> Array:
	if absf(dir.y) > absf(dir.x) * 1.2 and frames.has_animation(&"walk_down"):
		return [&"walk_down", &"idle_down"] if dir.y > 0.0 else [&"walk_up", &"idle_up"]
	return [&"walk", &"idle"]


## Measured frames (see drawn_rect): "sheet path:region" -> Rect2.
static var _drawn := {}


## What is drawn in the frame `region` of `sheet` (not transparent), px from the frame's
## top-left corner (the whole frame when it cannot be read). Measured once: all the frames of
## the sheet cut the same way at the same time.
static func drawn_rect(sheet: Texture2D, region: Rect2) -> Rect2:
	var name := sheet.resource_path if sheet.resource_path != "" else str(sheet.get_instance_id())
	var key := "%s:%s" % [name, region]
	if _drawn.has(key):
		return _drawn[key]
	var image := sheet.get_image()
	if image == null or region.size.x < 1.0 or region.size.y < 1.0:
		_drawn[key] = Rect2(Vector2.ZERO, region.size)
		return _drawn[key]
	if image.is_compressed():
		image.decompress()
	# The grid the region belongs to (a sheet of equal frames), from its size and place.
	var origin := Vector2(fposmod(region.position.x, region.size.x), fposmod(region.position.y, region.size.y))
	var cells := ((Vector2(image.get_size()) - origin) / region.size).floor()
	for j in int(cells.y):
		for i in int(cells.x):
			var cell := Rect2(origin + Vector2(i, j) * region.size, region.size)
			var used := image.get_region(Rect2i(cell)).get_used_rect()
			_drawn["%s:%s" % [name, cell]] = Rect2(used) if used.size.y > 0 else Rect2(Vector2.ZERO, region.size)
	if not _drawn.has(key):   # (not on the grid after all)
		var used := image.get_region(Rect2i(region)).get_used_rect()
		_drawn[key] = Rect2(used) if used.size.y > 0 else Rect2(Vector2.ZERO, region.size)
	return _drawn[key]


## What is drawn in `frame` (a picture of a sheet: an AtlasTexture, or a whole texture).
static func drawn_in(frame: Texture2D) -> Rect2:
	var atlas := frame as AtlasTexture
	if atlas and atlas.atlas:
		return drawn_rect(atlas.atlas, atlas.region)
	return drawn_rect(frame, Rect2(Vector2.ZERO, frame.get_size()))


static func direction_name(dir: Vector2) -> String:
	if absf(dir.x) > absf(dir.y):
		return "right" if dir.x > 0 else "left"
	return "down" if dir.y > 0 else "up"
