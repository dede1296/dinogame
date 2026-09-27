class_name SheetFrames
## Builds SpriteFrames from a sheet of equal cells (nano-banana sheets processed by
## tools/process-art.mjs), so a new character or dino needs no hand-made animation file.

## `anims`: name -> {"frames": [cell indices], "fps": float, "loop": bool}.
static func build(sheet: Texture2D, columns: int, rows: int, anims: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
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
	return frames


## Walking character sheet: 4 rows (down, left, right, up) x 4 walk frames. The 4 pictures
## draw one step, so they turn fast (world/view3d/sprite_motion.gd hops once a cycle).
static func character(sheet: Texture2D, fps := 14.0) -> SpriteFrames:
	var anims := {}
	for row in 4:
		var dir: String = ["down", "left", "right", "up"][row]
		var first := row * 4
		anims["walk_" + dir] = {"frames": [first, first + 1, first + 2, first + 3], "fps": fps}
		anims["idle_" + dir] = {"frames": [first], "fps": 1.0}
	return build(sheet, 4, 4, anims)


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
static func dino(species: DinoSpecies, corrupted := false) -> SpriteFrames:
	var sheet := species.sheet
	if corrupted and ResourceLoader.exists(CORRUPTED % species.id):
		sheet = load(CORRUPTED % species.id)
	var frames := build(sheet, species.sheet_columns, species.sheet_rows, {
		&"walk": {"frames": species.walk_frames, "fps": species.walk_fps * DINO_WALK_TEMPO},
		&"idle": {"frames": species.idle_frames, "fps": 1.6},
		&"attack": {"frames": [species.attack_frame], "fps": 1.0, "loop": false},
	})
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


static func direction_name(dir: Vector2) -> String:
	if absf(dir.x) > absf(dir.y):
		return "right" if dir.x > 0 else "left"
	return "down" if dir.y > 0 else "up"
