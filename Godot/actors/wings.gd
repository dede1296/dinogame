class_name Wings
extends RefCounted
## A pterosaur's pictures on the wing, for the Vol (Companion carrying Chloé in the air) — the rule
## of movements (docs/sprites-mouvements.md): it is seen the way it flies.
## - `<id>_vol.png`: one row of WINGBEATS wingbeats, facing right (the format story/cote_stage.gd
##   already reads for the Pteranodon) → animation FLY;
## - `<id>_vol_face_dos.png`: the same cells, row 1 flying towards the camera (FLY_DOWN), row 2 flying
##   away (FLY_UP), the same wingbeats.
## Not drawn yet: it flies with its walking pictures (walk, walk_down, walk_up), as the scenes do.
## Drawn at the scale of its walking sheet: the same sprite scale, the same picture centre.

const FLY := &"fly"
const FLY_DOWN := &"fly_down"
const FLY_UP := &"fly_up"
const SHEET := "res://assets/art/dinos/%s_vol.png"
const FACE_BACK := "res://assets/art/dinos/%s_vol_face_dos.png"
const WINGBEATS := 4
const FPS := 7.0
## A pterosaur carrying Chloé in the air is shown between these heights (m, standing): never taller
## than MAX (bigger than a mount on the ground, DinoSize.MOUNT_MAX_M: its wings spread around her),
## never smaller than MIN (a Tapejara, a Pteranodon are drawn smaller than a girl of 1.50 m: in the
## harness they grow to carry her, as a big mount shrinks).
const MOUNT_MAX_M := 3.0
const MOUNT_MIN_M := 2.3


static func drawn(species: DinoSpecies) -> bool:
	return ResourceLoader.exists(SHEET % species.id)


static func face_back_drawn(species: DinoSpecies) -> bool:
	return ResourceLoader.exists(FACE_BACK % species.id)


## One cell of its flight sheet (px), or Vector2.ZERO when it has none.
static func cell(species: DinoSpecies) -> Vector2:
	if not drawn(species):
		return Vector2.ZERO
	var sheet: Texture2D = load(SHEET % species.id)
	return Vector2(sheet.get_width() / float(WINGBEATS), sheet.get_height())


## Adds FLY, FLY_DOWN, FLY_UP to its frames (its walking pictures where the wings are not drawn).
static func add_to(frames: SpriteFrames, species: DinoSpecies) -> void:
	if frames.has_animation(FLY):
		return
	if drawn(species):
		_add_row(frames, FLY, load(SHEET % species.id), 1, 0)
	else:
		_copy(frames, &"walk", FLY)
	if face_back_drawn(species):
		var fb: Texture2D = load(FACE_BACK % species.id)
		_add_row(frames, FLY_DOWN, fb, 2, 0)
		_add_row(frames, FLY_UP, fb, 2, 1)
	else:
		_copy(frames, &"walk_down" if frames.has_animation(&"walk_down") else FLY, FLY_DOWN)
		_copy(frames, &"walk_up" if frames.has_animation(&"walk_up") else FLY, FLY_UP)


## Which wing animation fits a heading: seen from the side unless it goes mostly up or down the
## screen (like SheetFrames.dino_anims).
static func anim_for(frames: SpriteFrames, heading: Vector2) -> StringName:
	if absf(heading.y) > absf(heading.x) * 1.2:
		var anim := FLY_DOWN if heading.y > 0.0 else FLY_UP
		if frames.has_animation(anim):
			return anim
	return FLY


## Seen from the front or the back, a pterosaur is never narrower than from the side (its wings flat,
## frame GLIDE of both sheets): a face/back sheet drawn smaller than its profile one is shown bigger by
## this much (1 when they agree; measured once per species).
const GLIDE := 1
const FACE_BACK_MAX := 2.5
static var _face_back_scale := {}


static func face_back_scale(species: DinoSpecies) -> float:
	if not drawn(species) or not face_back_drawn(species):
		return 1.0
	if _face_back_scale.has(species.id):
		return _face_back_scale[species.id]
	var side: Texture2D = load(SHEET % species.id)
	var fb: Texture2D = load(FACE_BACK % species.id)
	var side_cell := Vector2(side.get_width() / float(WINGBEATS), side.get_height())
	var fb_cell := Vector2(fb.get_width() / float(WINGBEATS), fb.get_height() / 2.0)
	var side_w := SheetFrames.drawn_rect(side, Rect2(Vector2(side_cell.x * GLIDE, 0.0), side_cell)).size.x
	var fb_w := SheetFrames.drawn_rect(fb, Rect2(Vector2(fb_cell.x * GLIDE, 0.0), fb_cell)).size.x
	var k := clampf(side_w / maxf(fb_w, 1.0), 1.0, FACE_BACK_MAX)
	_face_back_scale[species.id] = k
	return k


## The sprite scale of a pterosaur carrying her in the air: as it is, between MOUNT_MIN_M and
## MOUNT_MAX_M tall.
static func mount_scale(species: DinoSpecies, walking_scale: float) -> float:
	var per_scale := DinoSize.height_m(species, 1.0)
	if per_scale <= 0.0:
		return walking_scale
	return clampf(walking_scale, MOUNT_MIN_M / per_scale, MOUNT_MAX_M / per_scale)


static func _add_row(frames: SpriteFrames, anim: StringName, sheet: Texture2D, rows: int, row: int) -> void:
	var size := Vector2(sheet.get_width() / float(WINGBEATS), sheet.get_height() / float(rows))
	frames.add_animation(anim)
	frames.set_animation_speed(anim, FPS)
	for i in WINGBEATS:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(Vector2(size.x * i, size.y * row), size)
		frames.add_frame(anim, frame)


static func _copy(frames: SpriteFrames, from: StringName, to: StringName) -> void:
	frames.add_animation(to)
	frames.set_animation_speed(to, FPS)
	for i in frames.get_frame_count(from):
		frames.add_frame(to, frames.get_frame_texture(from, i))
