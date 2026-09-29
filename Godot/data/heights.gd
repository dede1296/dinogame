class_name Heights
## How tall the people are, as seen on screen (in the 3D view, the billboards' stretch
## included): Chloé 1.50 m; women 1.50–1.70 m; men 1.70–2.00 m, the top kept for the bosses
## and villains (Brac 2.00). Their sheets all fill their frames: each one's sprite scale comes
## from its height and how tall it is drawn (see docs/direction-artistique.md, « Échelle »).

## Sheet (assets/art/characters/<name>.png) -> [height (m), height drawn (px of the sheet:
## what is not transparent, median of its 16 pictures)].
const PEOPLE := {
	"chloe": [1.50, 172.5], "maia": [1.50, 173.5], "pervenche": [1.50, 176.0],
	"tante_sirocco": [1.55, 174.5], "marchande": [1.60, 174.0], "rosalie": [1.62, 176.0],
	"lilou": [1.62, 173.0], "joss": [1.65, 174.5], "dame_suie": [1.68, 170.0],
	"isaure": [1.70, 173.0], "masque": [1.70, 172.0], "roc": [1.72, 171.0],
	"pecheur": [1.74, 176.0], "gaspard": [1.78, 173.0], "sbire": [1.80, 172.0],
	"ferreol": [1.82, 174.5], "garde": [1.85, 176.0], "brac": [2.00, 174.0],
	# Variants (Outfits): the same scale as their base sheet (Chloé's boots, Joss's jar counted in).
	"chloe_bottes": [1.50, 173.5], "joss_bocal": [1.69, 178.5],
}
## Someone not in the table yet.
const DEFAULT := [1.70, 174.0]
## The contact shadow under someone: this wide (px of the world) per metre of height.
const SHADOW_PER_M := 20.5


## Height (m) of the one drawn on `sheet`.
static func metres(sheet: Texture2D) -> float:
	return float(_entry(sheet)[0])


## The sprite scale that shows the one drawn on `sheet` at their height.
static func sprite_scale(sheet: Texture2D) -> float:
	var e := _entry(sheet)
	return float(e[0]) * HeightMap.PX / (float(e[1]) * WorldView.STRETCH)


## Width (px) of the shadow under the one drawn on `sheet`.
static func shadow_width(sheet: Texture2D) -> float:
	return metres(sheet) * SHADOW_PER_M


static func _entry(sheet: Texture2D) -> Array:
	var key := sheet.resource_path.get_file().get_basename() if sheet else ""
	return PEOPLE.get(key, DEFAULT)
