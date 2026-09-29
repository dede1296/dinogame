class_name DinoSize
## How big a dino is in the world, and what follows from it: its growth, its body on the
## ground, the gap it keeps behind Chloé, the size of a mount.
## An adult is shown at its species' world_scale (docs/direction-artistique.md, « Échelle »:
## its gabarit √(height × length) true to life up to 1.5 m, compressed above). A young one is
## smaller: it hatches about as big as a cat (HATCHLING_M; a small species at HATCHLING_SHARE
## of its size, never under YOUNG_MIN_M: still readable on a phone) and grows along a gentle
## curve (slow, faster, slow) to its adult size at GROWN_LEVEL. Heights are measured on the
## pictures (what is drawn, not the frame).

const GROWN_LEVEL := 14
const HATCHLING_M := 0.45
const HATCHLING_SHARE := 0.55
const YOUNG_MIN_M := 0.4
## A dino Chloé rides (or that carries her swimming) is never taller than this (m, about 1.3 ×
## Chloé): a bigger one shrinks to it as she climbs on (Companion, Saddle).
const MOUNT_MAX_M := 1.95
## Behind Chloé, a dino keeps this much room between her feet and its tail end (px).
const FOLLOW_ROOM := 24.0
const TRAIL_SPACING := 6.0   # px between two points of Chloé's trail (Player.TRAIL_SPACING)
## Trail points, the smallest dinos (the scenes that point the trail somewhere count on it).
const FOLLOW_MIN := 8


## Share of its species' adult size a dino of `species` shows at level `lvl` (1: grown).
static func growth(species: DinoSpecies, lvl: int) -> float:
	var adult := height_m(species, species.world_scale)
	if adult <= 0.0:
		return 1.0
	var hatch := minf(minf(HATCHLING_M, maxf(adult * HATCHLING_SHARE, YOUNG_MIN_M)) / adult, 1.0)
	var t := clampf((lvl - 1) / float(GROWN_LEVEL - 1), 0.0, 1.0)
	return lerpf(hatch, 1.0, smoothstep(0.0, 1.0, t))


## The sprite scale of `dino` in the world: its species' size, as grown as its level.
static func world_scale(dino: Dino) -> float:
	var species := dino.species()
	return species.world_scale * growth(species, dino.level)


## The sprite scale of a dino carrying Chloé (in the saddle, swimming): as it walks, but
## never taller than MOUNT_MAX_M; a sea reptile carrying her in the water (`in_water`) keeps its
## size (its raised neck may rise above her: its body under her is what must read as a mount).
static func mount_scale(species: DinoSpecies, walking_scale: float, in_water := false) -> float:
	if in_water and species.family == &"marine":
		return walking_scale
	var per_scale := height_m(species, 1.0)
	return minf(walking_scale, MOUNT_MAX_M / per_scale) if per_scale > 0.0 else walking_scale


## Height (m, in the 3D view) of the species' standing picture at sprite scale `scale`.
static func height_m(species: DinoSpecies, scale: float) -> float:
	return drawn(species).size.y * scale / HeightMap.PX * WorldView.STRETCH


## Length (px of the world) of the species' standing picture (side view) at sprite scale `scale`.
static func length_px(species: DinoSpecies, scale: float) -> float:
	return drawn(species).size.x * scale


## What is drawn of the species' standing picture (side view, first idle frame), px of its sheet.
static func drawn(species: DinoSpecies) -> Rect2:
	var cell := Vector2(species.sheet.get_width() / float(species.sheet_columns),
		species.sheet.get_height() / float(species.sheet_rows))
	var i: int = species.idle_frames[0] if not species.idle_frames.is_empty() else 0
	var at := Vector2(i % species.sheet_columns, i / species.sheet_columns) * cell
	return SheetFrames.drawn_rect(species.sheet, Rect2(at, cell))


## Its body on the ground (`node`'s shape): a capsule lying along its length, a fifth as wide
## as it is long (its drawn tail and head a bit beyond), `extra` px larger all round (a touch area).
static func fit_body(node: CollisionShape2D, species: DinoSpecies, scale: float, extra := 0.0) -> void:
	var length := length_px(species, scale)
	var capsule := CapsuleShape2D.new()
	capsule.radius = clampf(length * 0.16, 7.0, 30.0) + extra
	capsule.height = maxf(capsule.radius * 2.0, length * 0.62 + extra * 2.0)
	node.shape = capsule
	node.rotation = PI / 2.0


## How many of Chloé's trail points a dino of `species` at `scale` walks behind her.
static func follow_gap(species: DinoSpecies, scale: float) -> int:
	return maxi(FOLLOW_MIN, ceili((length_px(species, scale) * 0.5 + FOLLOW_ROOM) / TRAIL_SPACING))
