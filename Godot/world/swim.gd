class_name Swim
extends RefCounted
## La Nage (Marais, chapter 3): with Joss's swimming vest (item "gilet_nage", or the story
## flag of the same name) and a grown party dino able to swim (Abilities "nage": Baryonyx,
## Suchomimus, Spinosaurus, the sea reptiles), Chloé walks into deep water and swims on its
## back without pressing anything; back on land, she walks again (Player.swimmer).
## Deep water blocks the way on its own physics layer (WATER_LAYER, the terrain's water
## tiles): Chloé's collision mask drops it while she can swim, so nothing else changes
## (props, cliffs, the woods and the edges of the zone still stop her in the water).
## Without the vest or the dino, the water stays in the way, and she is told why once.

const ITEM := "gilet_nage"
const FLAG := &"gilet_nage"
const ABILITY := &"nage"
## Physics layers (project settings: 1 "monde", 5 "eau"): solid things, deep water.
const SOLID_LAYER := 1
const WATER_LAYER := 16
## × Chloé's walking speed while she swims.
const SPEED := 1.3
## How much of the swimmer's picture is under the water (its back and Chloé stay out).
const SINK := 0.42
## Its steps in the water are longer than hers on land (the footstep rhythm).
const STROKE := 1.6


static func has_vest() -> bool:
	if Game.item_count(ITEM) > 0:
		return true
	return true if Game.flag(FLAG) else false


## The dino who carries Chloé in the water (the first able one), or null (no vest, or no
## grown swimmer in the party).
static func swimmer() -> Dino:
	if not has_vest():
		return null
	return Game.ability_user(ABILITY)


static func can_swim() -> bool:
	return swimmer() != null


## Why Chloé cannot go into the water (said once when she walks against it).
static func blocked_reason() -> String:
	var young: Dino = null
	for d in Game.party:
		if Abilities.has(d, ABILITY):
			young = d
			break
	if not has_vest():
		if young and Abilities.usable(young, ABILITY):
			return "%s nagerait volontiers, mais sans gilet de nage, impossible d'aller plus loin." % young.nickname
		return "Sans gilet de nage et sans dino nageur, impossible d'aller plus loin."
	if young:
		return "%s est encore trop jeune pour nager avec toi sur le dos : il faut qu'il soit adulte (niv. %d)." % [young.nickname, Abilities.ADULT_LEVEL]
	return "Avec le gilet, il te faut aussi un dino nageur adulte (un Baryonyx, par exemple) pour aller plus loin."


## How deep (m) `swimmer` sinks, Chloé on its back: a share of its picture's height in the view
## (as big as it is shown carrying her: DinoSize.mount_scale).
static func sink(swimmer: Dino) -> float:
	var species := swimmer.species()
	var h := species.sheet.get_height() / float(species.sheet_rows)
	var scale := DinoSize.mount_scale(species, DinoSize.world_scale(swimmer), true)
	return h * scale / HeightMap.PX * WorldView.STRETCH * SINK
