class_name DexTiles
## The tiles of the Dinodex (DexTile: tapped, dragged) and the pictures of a species they
## show: a species of the list (its number, its picture, its name; a black shape and « ??? »
## until Chloé has seen it; the amber collar once she has one), one of Chloé's dinos (the
## reserve, the dinos of a species), a place of the team (a dino, or free).

const CARD := Color(0.16, 0.18, 0.22)
const CREAM := Color(1, 0.97, 0.9)
const GOLD := Color(1, 0.86, 0.5)
const AMBER := Color(0.98, 0.76, 0.35)
const BORDER := Color(0.79, 0.54, 0.16)
## A species not seen yet: only its shape, in the dark.
const SHADOW := Color(0.05, 0.06, 0.09, 0.92)
const COLLAR := preload("res://assets/art/ui/collier.webp")
## Of a front view's cell, the middle part kept (the dino stands in the middle of a wide cell).
const FACE_CROP := 0.7
## A long name gets this small at most before being cut.
const MIN_FONT := 11

static var _side := {}
static var _face := {}


# ------------------------------------------------------------------ pictures

## The species standing still, seen from the side (the first still picture of its sheet).
@warning_ignore("integer_division")
static func side(sp: DinoSpecies) -> Texture2D:
	if not _side.has(sp.id):
		var cell := Vector2(sp.sheet.get_width() / float(sp.sheet_columns), sp.sheet.get_height() / float(sp.sheet_rows))
		var i: int = sp.idle_frames[0] if not sp.idle_frames.is_empty() else 0
		var t := AtlasTexture.new()
		t.atlas = sp.sheet
		t.region = Rect2(Vector2(i % sp.sheet_columns, i / sp.sheet_columns) * cell, cell)
		_side[sp.id] = t
	return _side[sp.id]


## The species seen from the front, standing still (the middle of its cell), or null.
@warning_ignore("integer_division")
static func face(sp: DinoSpecies) -> Texture2D:
	if sp.face_back_sheet == null:
		return null
	if not _face.has(sp.id):
		var sheet := sp.face_back_sheet
		var cell := Vector2(sheet.get_width() / float(sp.face_back_columns), sheet.get_height() / 2.0)
		var i := sp.down_idle_frame
		var at := Vector2(i % sp.face_back_columns, i / sp.face_back_columns) * cell
		var t := AtlasTexture.new()
		t.atlas = sheet
		t.region = Rect2(at + Vector2(cell.x * (1.0 - FACE_CROP) / 2.0, 0.0), Vector2(cell.x * FACE_CROP, cell.y))
		_face[sp.id] = t
	return _face[sp.id]


## Draws `tex` as big as it fits in `box`, standing at the bottom middle, its shape kept.
static func draw_fit(ci: CanvasItem, tex: Texture2D, box: Rect2, tint := Color.WHITE) -> void:
	if tex == null:
		return
	var s := tex.get_size()
	var k := minf(box.size.x / s.x, box.size.y / s.y)
	var fit := s * k
	ci.draw_texture_rect(tex, Rect2(Vector2(box.position.x + (box.size.x - fit.x) / 2.0, box.end.y - fit.y), fit), false, tint)


static func card_box(fill: Color, border: Color, width := 2, radius := 14) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(radius)
	return b


## A line of text in `width` px, made smaller (down to MIN_FONT) rather than cut when long.
static func text(ci: CanvasItem, font: Font, at: Vector2, width: float, s: String, font_size: int, colour: Color,
		align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var fs := font_size
	while fs > MIN_FONT and font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width:
		fs -= 1
	ci.draw_string(font, at, s, align, width, fs, colour, TextServer.JUSTIFICATION_NONE)


## A soft shadow on the ground under a picture, centred on `at`.
static func draw_ground(ci: CanvasItem, at: Vector2, radius: float, alpha := 0.28) -> void:
	ci.draw_set_transform(at, 0.0, Vector2(1.0, 0.22))
	ci.draw_circle(Vector2.ZERO, radius, Color(0, 0, 0, alpha))
	ci.draw_set_transform(Vector2.ZERO)


## A round portrait (PartyBar.portrait) in a ring of its type's colour.
static func draw_portrait(ci: CanvasItem, d: Dino, c: Vector2, r: float, faded := false) -> void:
	var colour: Color = MovesDB.TYPE_COLORS.get(d.type(), CREAM)
	var a := 0.35 if faded else 1.0
	ci.draw_circle(c, r, Color(colour.darkened(0.35), a))
	ci.draw_texture_rect(PartyBar.portrait(d.species()), Rect2(c - Vector2(r - 4.0, r - 4.0), Vector2(r - 4.0, r - 4.0) * 2.0), false,
		Color(1, 1, 1, a))
	ci.draw_arc(c, r, 0.0, TAU, 40, Color(AMBER, a), 2.5, true)


# ------------------------------------------------------------------ tiles

## A species in the list.
class Species extends DexTile:
	const SIZE := Vector2(128, 150)
	var id: StringName
	var _status: StringName
	var _owned := 0

	func _ready() -> void:
		custom_minimum_size = SIZE
		tooltip_text = ""
		refresh()

	func refresh() -> void:
		_status = DexDB.status(id)
		_owned = DexDB.owned(id).size()
		queue_redraw()

	func _draw() -> void:
		var sp := SpeciesDB.get_species(id)
		var font := get_theme_default_font()
		var caught := _status == DexDB.CAUGHT
		var unseen := _status == DexDB.UNSEEN
		var border: Color = GOLD if caught else Color(BORDER, 0.8) if not unseen else Color(0.45, 0.48, 0.55, 0.6)
		draw_style_box(DexTiles.card_box(CARD if not unseen else Color(0.12, 0.13, 0.16), border, 3 if caught else 2), Rect2(Vector2.ZERO, size))
		DexTiles.text(self, font, Vector2(8, 18), size.x, DexDB.number_text(id), 13, Color(CREAM, 0.6), HORIZONTAL_ALIGNMENT_LEFT)
		var pic := Rect2(8, 24, size.x - 16, 88)
		DexTiles.draw_ground(self, Vector2(size.x / 2.0, pic.end.y - 3.0), size.x * 0.36, 0.14 if unseen else 0.3)
		DexTiles.draw_fit(self, DexTiles.side(sp), pic, SHADOW if unseen else Color.WHITE)
		DexTiles.text(self, font, Vector2(4, size.y - 12), size.x - 8, "???" if unseen else sp.display_name, 15,
			Color(CREAM, 0.55) if unseen else CREAM)
		if caught:
			draw_texture_rect(COLLAR, Rect2(size.x - 34, 4, 28, 28), false)
		if _owned > 1:
			DexTiles.text(self, font, Vector2(size.x - 40, 46), 34, "×%d" % _owned, 14, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
		draw_focus_ring()


## One of Chloé's dinos: a card (the reserve) or a row (`wide`: the dinos of a species).
class Owned extends DexTile:
	const CARD_SIZE := Vector2(150, 150)
	const ROW_SIZE := Vector2(250, 64)
	var dino: Dino
	var in_party := false
	var index := 0
	var wide := false
	var highlighted := false

	func _ready() -> void:
		custom_minimum_size = ROW_SIZE if wide else CARD_SIZE
		draggable = true
		payload = {"kind": "party" if in_party else "box", "index": index}
		picture = PartyBar.portrait(dino.species())

	func _draw() -> void:
		var font := get_theme_default_font()
		var faded := dragging()
		var border := GOLD if highlighted else Color(BORDER, 0.8)
		draw_style_box(DexTiles.card_box(Color(CARD, 0.5 if faded else 1.0), border, 3 if highlighted else 2), Rect2(Vector2.ZERO, size))
		var name_colour := Color(CREAM, 0.4 if faded else 1.0)
		var sub := "niv. %d · %s" % [dino.level, dino.species_name()]
		if wide:
			DexTiles.draw_portrait(self, dino, Vector2(34, size.y / 2.0), 26.0, faded)
			DexTiles.text(self, font, Vector2(68, 28), size.x - 74, dino.nickname, 18, name_colour, HORIZONTAL_ALIGNMENT_LEFT)
			DexTiles.text(self, font, Vector2(68, 50), size.x - 74, sub, 14, Color(CREAM, 0.6), HORIZONTAL_ALIGNMENT_LEFT)
		else:
			DexTiles.draw_portrait(self, dino, Vector2(size.x / 2.0, 54), 42.0, faded)
			DexTiles.text(self, font, Vector2(4, 118), size.x - 8, dino.nickname, 17, name_colour)
			DexTiles.text(self, font, Vector2(4, 138), size.x - 8, sub, 13, Color(CREAM, 0.6))
		draw_focus_ring()


## A place of the team: its dino (the first one leads), or free.
class TeamSlot extends DexTile:
	var index := 0
	var dino: Dino

	func _ready() -> void:
		draggable = dino != null
		if dino:
			payload = {"kind": "party", "index": index}
			picture = PartyBar.portrait(dino.species())
		else:
			focus_mode = Control.FOCUS_NONE

	func _draw() -> void:
		var font := get_theme_default_font()
		var r := Rect2(Vector2.ZERO, size)
		if dino == null:
			var free := StyleBoxFlat.new()
			free.bg_color = Color(1, 1, 1, 0.03)
			free.border_color = Color(CREAM, 0.25)
			free.set_border_width_all(2)
			free.set_corner_radius_all(14)
			draw_style_box(free, r)
			DexTiles.text(self, font, Vector2(0, size.y / 2.0 + 6.0), size.x, "Place libre", 15, Color(CREAM, 0.4))
			return
		var faded := dragging()
		var lead := index == 0
		draw_style_box(DexTiles.card_box(Color(CARD, 0.5 if faded else 1.0), GOLD if lead else Color(BORDER, 0.8), 3 if lead else 2), r)
		DexTiles.draw_portrait(self, dino, Vector2(34, size.y / 2.0), 27.0, faded)
		var x := 68.0
		DexTiles.text(self, font, Vector2(x, 26), size.x - x - 4, dino.nickname, 17, Color(CREAM, 0.4 if faded else 1.0), HORIZONTAL_ALIGNMENT_LEFT)
		DexTiles.text(self, font, Vector2(x, 46), size.x - x - 4, "niv. %d" % dino.level, 14, Color(CREAM, 0.6), HORIZONTAL_ALIGNMENT_LEFT)
		if lead:
			DexTiles.text(self, font, Vector2(x, 66), size.x - x - 4, "en tête", 13, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		var ratio := clampf(float(dino.hp) / maxf(dino.max_hp(), 1.0), 0.0, 1.0)
		draw_rect(Rect2(x, size.y - 9, size.x - x - 10, 4), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(x, size.y - 9, (size.x - x - 10) * ratio, 4), Color(0.45, 0.85, 0.4) if ratio > 0.5 else Color(0.95, 0.75, 0.2))
		draw_focus_ring()
