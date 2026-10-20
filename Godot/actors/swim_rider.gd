extends RefCounted
## A swimmer's pictures with Chloé already on its back, lying flat on her stomach (her vest, her bag) — the rule
## of movements (docs/sprites-mouvements.md: « Nageur »), as Wings is for the Vol. The Kronosaurus first (lot B',
## docs/direction-artistique.md § Fossiles): it has no neck to sit behind, she lies along its back.
## - `<id>_nage.png`: the cells of its walking sheet (sheet_columns × sheet_rows), facing right: its swim cycle
##   with her on it, every cell in order (the 2nd row plays the cycle again) → animation SWIM.
## Drawn: in deep water (Swim, Dive) and seen from the side, the Companion plays SWIM and her own picture is hidden
## (she is in it); from the front or the back, she sits on it as before (Saddle). Not drawn: the saddle everywhere.
## Its cells are not those of its walking sheet: fit() says how much smaller (or bigger) to show them, and how far
## to move them, so that the swimmer keeps the length and the belly line of its walking pictures (and the water
## line of Swim.sink). No class_name: preloaded (const SWIM_RIDER := preload("res://actors/swim_rider.gd")).

const SWIM := &"swim_rider"
const SHEET := "res://assets/art/dinos/%s_nage.png"
## Treading water (no stroke asked): its cycle this much slower.
const IDLE_SPEED := 0.45


static func drawn(species: DinoSpecies) -> bool:
	return species != null and ResourceLoader.exists(SHEET % species.id)


## Seen from the side (its walking sheet's animations, or SWIM itself): not walk_down, idle_up…
static func side_view(anim: StringName) -> bool:
	var name := String(anim)
	return not (name.ends_with("_down") or name.ends_with("_up"))


## Adds SWIM to its frames (once), at the tempo of its walk seen from the side; nothing when not drawn.
static func add_to(frames: SpriteFrames, species: DinoSpecies) -> void:
	if frames.has_animation(SWIM) or not drawn(species):
		return
	var sheet: Texture2D = load(SHEET % species.id)
	var cell := _cell(sheet, species)
	frames.add_animation(SWIM)
	frames.set_animation_speed(SWIM, species.walk_fps * SheetFrames.DINO_WALK_TEMPO)
	frames.set_animation_loop(SWIM, true)
	for row in species.sheet_rows:
		for column in species.sheet_columns:
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(Vector2(column * cell.x, row * cell.y), cell)
			frames.add_frame(SWIM, frame)


## How to show SWIM where its walking pictures are (`offset`: the sprite's offset, set for those): {"scale": × the
## sprite's scale, "shift": px to move the sprite at sprite scale 1, facing right}; {} when not drawn. Measured on
## what is drawn in the first cell of each (the same pose): the same length, the same bottom, the same middle.
static func fit(species: DinoSpecies, offset: Vector2) -> Dictionary:
	if not drawn(species):
		return {}
	var sheet: Texture2D = load(SHEET % species.id)
	var swim_cell := _cell(sheet, species)
	var side_cell := _cell(species.sheet, species)
	var swim := SheetFrames.drawn_rect(sheet, Rect2(Vector2.ZERO, swim_cell))
	var side := SheetFrames.drawn_rect(species.sheet, Rect2(Vector2.ZERO, side_cell))
	var k := side.size.x / maxf(swim.size.x, 1.0)
	# Where a drawn point sits in the node: offset - cell / 2 + its place in the cell (× the sprite's scale).
	var side_at := offset - side_cell / 2.0 + Vector2(side.get_center().x, side.end.y)
	var swim_at := offset - swim_cell / 2.0 + Vector2(swim.get_center().x, swim.end.y)
	return {"scale": k, "shift": side_at - swim_at * k}


static func _cell(sheet: Texture2D, species: DinoSpecies) -> Vector2:
	return Vector2(sheet.get_width() / float(species.sheet_columns), sheet.get_height() / float(species.sheet_rows))
