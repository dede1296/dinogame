class_name NpcPalette
extends RefCounted
## The colours of a person, read off their own 2.5D sheet (assets/art/characters/<name>.png), so a
## 3D NPC needs no table of colours written by hand: hair, skin, top, bottom and boots come from
## the drawing the 2.5D game already shows (docs/migration-3d.md, « Npc/DinoNpc → Npc3D »).
## The sheets are 4 x 4 pictures (SheetFrames.character: down, left, right, up); the first one,
## standing and facing us, is the one read. In it the figure always fills the frame the same way
## (Heights: the sheets are all drawn at the same scale), so a band of the drawn height is always
## the same part of the body.
## Read once per sheet (`of`), then kept.

## Bands of the drawn figure, top to bottom: part → [y start, y end, x half-width around the middle]
## (shares of the drawn box). Measured on the sheets of the game (see `profile`).
const BANDS := {
	&"hair": [0.02, 0.11, 0.22],
	&"skin": [0.27, 0.34, 0.18],
	&"top": [0.54, 0.64, 0.16],
	&"boots": [0.90, 0.96, 0.20],   # (not the very bottom: the drawing fades into its own outline there)
}
## Trousers and shorts are not worn at the same height by everyone (Chloé's shorts end high, Élise's
## shirt hangs over hers): the waist band is taken unless it is still the top's own colour, and then
## the one below it.
const BOTTOM_HIGH := [0.72, 0.79, 0.16]
const BOTTOM_LOW := [0.80, 0.87, 0.16]
const SAME_GARMENT := 0.25   # two colours closer than this (RGB) are one garment
## A pixel this clear of the outline and of the background is a colour of the character.
const MIN_ALPHA := 0.75
const MIN_LUMA := 0.14
## When a band reads nothing (a sheet drawn another way), these stand in.
const FALLBACK := {
	&"hair": Color(0.26, 0.16, 0.10), &"skin": Color(0.93, 0.76, 0.63), &"top": Color(0.45, 0.50, 0.42),
	&"bottom": Color(0.32, 0.30, 0.26), &"boots": Color(0.30, 0.18, 0.11),
}

static var _cache := {}

var hair := FALLBACK[&"hair"] as Color
var skin := FALLBACK[&"skin"] as Color
var top := FALLBACK[&"top"] as Color
var bottom := FALLBACK[&"bottom"] as Color
var boots := FALLBACK[&"boots"] as Color


## The colours of `sheet` (a character sheet of the 2.5D game). Read once per sheet.
static func of(sheet: Texture2D) -> NpcPalette:
	if sheet == null:
		return NpcPalette.new()
	var key := sheet.resource_path if sheet.resource_path != "" else str(sheet.get_instance_id())
	if _cache.has(key):
		return _cache[key]
	var palette := NpcPalette.new()
	palette._read(sheet)
	_cache[key] = palette
	return palette


func as_dictionary() -> Dictionary:
	return {&"hair": hair, &"skin": skin, &"top": top, &"bottom": bottom, &"boots": boots}


## A colour of the sheet darkened (a sole under a boot, an eyebrow under the hair).
static func darker(colour: Color, by := 0.55) -> Color:
	return Color(colour.r * by, colour.g * by, colour.b * by, 1.0)


func _read(sheet: Texture2D) -> void:
	var image := _image(sheet)
	if image == null:
		return
	var frame := Rect2(Vector2.ZERO, Vector2(image.get_width() / 4.0, image.get_height() / 4.0))
	var drawn := SheetFrames.drawn_rect(sheet, frame)   # the figure inside the first picture
	if drawn.size.x < 4.0 or drawn.size.y < 8.0:
		return
	for part: StringName in BANDS:
		var band: Array = BANDS[part]
		var found := _median(image, drawn, float(band[0]), float(band[1]), float(band[2]))
		if found.a > 0.0:
			set(String(part), Color(found.r, found.g, found.b, 1.0))
	var waist := _median(image, drawn, BOTTOM_HIGH[0], BOTTOM_HIGH[1], BOTTOM_HIGH[2])
	if waist.a > 0.0 and _apart(waist, top) < SAME_GARMENT:
		waist = _median(image, drawn, BOTTOM_LOW[0], BOTTOM_LOW[1], BOTTOM_LOW[2])
	if waist.a > 0.0:
		bottom = Color(waist.r, waist.g, waist.b, 1.0)


## The middle colour (by brightness) of a band of the figure: the outline, the background and the
## highlights fall away, a flat drawn garment keeps its own colour. Alpha 0: nothing was read.
func _median(image: Image, drawn: Rect2, y0: float, y1: float, half_width: float) -> Color:
	var middle := drawn.position.x + drawn.size.x * 0.5
	var x_from := int(middle - drawn.size.x * half_width)
	var x_to := int(middle + drawn.size.x * half_width)
	var found: Array[Color] = []
	for y in range(int(drawn.position.y + drawn.size.y * y0), int(drawn.position.y + drawn.size.y * y1) + 1):
		if y < 0 or y >= image.get_height():
			continue
		for x in range(maxi(x_from, 0), mini(x_to, image.get_width() - 1) + 1):
			var pixel := image.get_pixel(x, y)
			if pixel.a < MIN_ALPHA or pixel.get_luminance() < MIN_LUMA:
				continue
			found.append(pixel)
	if found.is_empty():
		return Color(0, 0, 0, 0)
	found.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
	return found[int(found.size() * 0.5)]


## How far apart two colours are (RGB).
static func _apart(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


static func _image(sheet: Texture2D) -> Image:
	var image := sheet.get_image()
	if image == null:
		return null
	if image.is_compressed():
		image.decompress()
	return image


## Prints the middle colour of `bands` slices of the figure, to place BANDS on a new set of sheets:
##   NpcPalette.profile(load("res://assets/art/characters/maia.png"))
static func profile(sheet: Texture2D, bands := 24) -> void:
	var palette := NpcPalette.new()
	var image := _image(sheet)
	if image == null:
		return
	var frame := Rect2(Vector2.ZERO, Vector2(image.get_width() / 4.0, image.get_height() / 4.0))
	var drawn := SheetFrames.drawn_rect(sheet, frame)
	print("profil %s — dessin %s dans la case %s" % [sheet.resource_path.get_file(), drawn, frame.size])
	for i in bands:
		var y0 := float(i) / bands
		var colour := palette._median(image, drawn, y0, y0 + 1.0 / bands, 0.18)
		print("  %.2f..%.2f  %s" % [y0, y0 + 1.0 / bands, colour.to_html(false) if colour.a > 0.0 else "—"])
