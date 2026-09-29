class_name WildlifeDB
## The little life of each kind of place (a zone names its kind: Region.ambience_id), shown by
## Wildlife around Chloé: butterflies over the meadows, mosquitoes and dragonflies in the woods,
## frogs in the marsh, lizards and scorpions in the desert, crabs on the beaches and fish leaping
## in the sea (never an insect over the sea), glow-worms in the caves… and already the places to
## come (the snowy Monts, the Cieux, the volcano, the Terre des Apex).
##
## KINDS — the animals, each a picture: one row of `frames` cells drawn facing right
## (assets/art/fauna/<id>.png; a kind whose picture is not there yet is left out):
##   width   metres across one cell (about twice the real size: seen on a phone)
##   fps     cells per second (walkers: while they move)
##   motion  flutter (wandering flight), dart (hovers, then darts), swarm (a cloud of specks),
##           walk, hop, leap (a fish out of the water and back), soar (crosses the sky high up),
##           circle (circles over the water), fall (a leaf), swim, drift (under the sea, or
##           floating on it with `surface`)
##   speed   m/s (run: fleeing);  height [min, max] m above the ground (the water, the sea floor)
##   when    DAY, NIGHT, DUSK bits;  rain  still out in the rain (or the sandstorm)
##   on      ground it may be over (Region.surface_at; empty: any);  near / far {surface: m}:
##           within / beyond that distance of it (&"land": any ground that is not water)
##   flee    m: runs (swims, hops) away when Chloé comes this close;  wait [min, max] s resting
##   glow    lit from within (unshaded, this tint);  tints  colours picked from at random
##   seen    only placed where the camera sees it (a fish leaping, a bird over the sea)
##   surface floating on the water (not under it)
## EFFECTS — particles, no picture: fireflies, plankton, glow-worms, drops, snow, embers…
##   emit    box (around Chloé), water (on the water near her), walls (on the cave's walls)
## PLACES — what lives where: {kind: how many} (at the best graphics; Quality.scaled lowers it),
## or {kind: {count, and what differs here}}; "effects": {effect: what differs here}.

const DAY := 1
const NIGHT := 2
const DUSK := 4
const ALWAYS := DAY | NIGHT | DUSK

const PATH := "res://assets/art/fauna/%s.png"
const LAND: Array[StringName] = [&"grass", &"path", &"tall_grass", &"forest", &"sand", &"mud", &"rock"]
const DRY: Array[StringName] = [&"grass", &"path", &"tall_grass", &"forest", &"sand", &"rock"]
const GREEN: Array[StringName] = [&"grass", &"path", &"tall_grass", &"forest"]
const WATER: Array[StringName] = [&"water"]
## Out at night and seen all the same: not lit by the dark scene, tinted the moonlight's blue
## (in the snow, its white).
const NIGHT_LIGHT := Color(0.58, 0.64, 0.86)
const SNOW_LIGHT := Color(0.92, 0.94, 1.0)

const KINDS := {
	&"papillon": {"pic": "res://assets/art/props/papillon.png", "frames": 1, "flap": 7.0, "width": 0.22,
		"motion": &"flutter", "speed": 0.7, "height": [0.5, 1.4], "when": DAY, "on": LAND, "far": {&"water": 4.0},
		"glow": Color.WHITE,
		"tints": [Color(1.0, 0.72, 0.1), Color(1.0, 0.45, 0.62), Color(0.35, 0.62, 1.0), Color(0.62, 0.9, 0.35)]},
	# Meganeura: a dragonfly as wide as a forearm. One drawing held (fps 0): its two cells do not
	# line up, and flicking between them showed two dragonflies; the wings are a blur anyway.
	&"libellule": {"frames": 2, "fps": 0.0, "width": 0.28, "motion": &"dart", "speed": 2.4,
		"height": [0.5, 1.5], "when": DAY | DUSK, "wait": [0.6, 2.2]},
	&"moustique": {"frames": 2, "fps": 24.0, "width": 0.14, "motion": &"swarm", "speed": 0.35,
		"height": [0.7, 1.6], "when": ALWAYS, "specks": 16},
	&"feuille": {"frames": 3, "width": 0.2, "motion": &"fall", "speed": 0.45, "height": [2.6, 4.2],
		"when": ALWAYS, "rain": true, "on": GREEN, "near": {&"forest": 3.0}, "wait": [2.0, 4.0]},
	&"crabe": {"frames": 4, "fps": 9.0, "width": 0.45, "motion": &"walk", "speed": 0.45, "run": 1.6,
		"when": ALWAYS, "rain": true, "on": [&"sand"], "near": {&"water": 8.0}, "flee": 2.2, "wait": [0.8, 3.5]},
	&"lezard": {"frames": 4, "fps": 14.0, "width": 0.6, "motion": &"walk", "speed": 1.6, "run": 3.2,
		"when": DAY | DUSK, "on": DRY, "flee": 2.6, "wait": [1.0, 4.0],
		"tints": [Color(0.8, 0.7, 0.6)]},   # (darker than the sand it lives on)
	&"scorpion": {"frames": 4, "fps": 7.0, "width": 0.36, "motion": &"walk", "speed": 0.35, "run": 1.0,
		"when": ALWAYS, "on": [&"sand", &"rock", &"path"], "flee": 1.6, "wait": [1.5, 5.0]},
	&"scarabee": {"frames": 2, "fps": 6.0, "width": 0.2, "motion": &"walk", "speed": 0.18, "run": 0.5,
		"when": DAY | DUSK, "on": [&"grass", &"path", &"sand", &"rock"], "flee": 1.2, "wait": [1.0, 4.0]},
	&"grenouille": {"frames": 3, "width": 0.32, "motion": &"hop", "speed": 1.2, "jump": [0.7, 1.1],
		"when": ALWAYS, "rain": true, "on": [&"mud", &"grass", &"tall_grass", &"path"], "near": {&"water": 5.0},
		"flee": 2.0, "wait": [1.0, 4.5]},
	# A small furry mammal of the Mesozoic (like Morganucodon), out at night.
	&"mammifere": {"frames": 4, "fps": 12.0, "width": 0.45, "motion": &"walk", "speed": 0.9, "run": 2.6,
		"when": NIGHT | DUSK, "on": DRY, "flee": 3.0, "wait": [0.8, 3.0], "glow": NIGHT_LIGHT},
	&"poisson_saut": {"frames": 4, "width": 0.45, "motion": &"leap", "height": [0.45, 0.8], "jump": [0.9, 1.4],
		"when": DAY | DUSK, "rain": true, "on": WATER, "far": {&"land": 1.5}, "seen": true, "wait": [2.0, 6.0]},
	&"banc": {"frames": 2, "fps": 4.0, "width": 1.1, "motion": &"swim", "speed": 0.6, "run": 2.2,
		"height": [0.6, 2.2], "when": ALWAYS, "flee": 2.5},
	&"meduse": {"frames": 4, "fps": 2.5, "width": 0.4, "motion": &"drift", "speed": 0.12,
		"height": [0.9, 3.0], "when": ALWAYS},
	&"ptero_vol": {"frames": 4, "fps": 5.0, "width": 1.0, "motion": &"soar", "speed": 4.2,
		"height": [2.4, 3.6], "when": DAY | DUSK, "wait": [5.0, 14.0]},
	# A woodland snail: slow, never runs; out in the rain too.
	&"escargot": {"frames": 4, "fps": 3.0, "width": 0.22, "motion": &"walk", "speed": 0.05, "run": 0.05,
		"when": ALWAYS, "rain": true, "on": [&"forest", &"grass", &"tall_grass", &"path"], "near": {&"forest": 3.0},
		"wait": [3.0, 8.0]},
	# A file of ants crossing the ground (one picture: the whole file).
	&"fourmis": {"frames": 2, "fps": 6.0, "width": 0.3, "motion": &"walk", "speed": 0.12, "run": 0.12,
		"when": DAY | DUSK, "on": GREEN, "wait": [0.5, 2.0]},
	# A small living ammonite, darting about in the shallows by the shore.
	&"ammonite": {"frames": 4, "fps": 5.0, "width": 0.3, "motion": &"drift", "surface": true, "speed": 0.25,
		"height": [0.0, 0.0], "when": DAY | DUSK, "rain": true, "on": WATER, "near": {&"land": 2.0}, "seen": true},
	# Ichthyornis: a sea bird of the time, with teeth.
	&"ichthyornis": {"frames": 4, "fps": 9.0, "width": 0.6, "motion": &"circle", "speed": 2.6,
		"height": [1.4, 3.0], "when": DAY | DUSK, "on": WATER, "far": {&"land": 1.0}, "seen": true},
}

## Effects. amount: at the best graphics; size: m; life: s; box: half extents (m) around Chloé,
## raised by `above` (m); speed [min, max] m/s along `dir` (spread °); gravity m/s²; glow:
## added light, blinking with `blink`; `drop`: a falling streak (taller than wide).
const EFFECTS := {
	&"lucioles": {"amount": 26, "life": 6.0, "size": 0.09, "colour": Color(0.85, 1.0, 0.45), "glow": true,
		"blink": true, "emit": &"box", "box": Vector3(10.0, 0.7, 7.0), "above": 0.8, "speed": [0.05, 0.25],
		"dir": Vector3(1, 0.2, 0), "spread": 180.0, "when": NIGHT},
	&"plancton": {"amount": 90, "life": 4.0, "size": 0.1, "colour": Color(0.3, 0.75, 1.0), "glow": true,
		"blink": true, "emit": &"water", "speed": [0.0, 0.04], "dir": Vector3(1, 0, 0), "spread": 180.0,
		"when": NIGHT, "rain": true},
	&"vers_luisants": {"amount": 60, "life": 9.0, "size": 0.11, "colour": Color(0.45, 0.95, 0.85), "glow": true,
		"blink": false, "emit": &"walls", "speed": [0.0, 0.0], "when": ALWAYS},
	&"gouttes": {"amount": 8, "life": 0.75, "size": 0.025, "drop": 3.5, "colour": Color(0.75, 0.88, 1.0, 0.8),
		"emit": &"box", "box": Vector3(7.0, 0.1, 5.0), "above": 3.0, "speed": [0.0, 0.0], "gravity": -9.0,
		"when": ALWAYS},
	&"flocons": {"amount": 140, "life": 7.0, "size": 0.06, "colour": Color(1.0, 1.0, 1.0, 0.9),
		"emit": &"box", "box": Vector3(13.0, 0.5, 10.0), "above": 6.5, "speed": [0.2, 0.5],
		"dir": Vector3(0.4, -1, 0), "spread": 25.0, "gravity": -0.4, "when": ALWAYS, "rain": true},
	&"braises": {"amount": 30, "life": 3.5, "size": 0.06, "colour": Color(1.0, 0.55, 0.15), "glow": true,
		"blink": true, "emit": &"box", "box": Vector3(10.0, 0.4, 7.0), "above": 0.3, "speed": [0.2, 0.6],
		"dir": Vector3(0.2, 1, 0), "spread": 30.0, "gravity": 0.25, "when": ALWAYS, "rain": true},
	&"cendres": {"amount": 60, "life": 7.0, "size": 0.05, "colour": Color(0.42, 0.4, 0.38, 0.85),
		"emit": &"box", "box": Vector3(13.0, 0.5, 10.0), "above": 5.5, "speed": [0.1, 0.35],
		"dir": Vector3(0.6, -1, 0), "spread": 35.0, "gravity": -0.25, "when": ALWAYS, "rain": true},
	&"duvet": {"amount": 16, "life": 8.0, "size": 0.09, "colour": Color(1.0, 0.97, 0.9, 0.9),
		"emit": &"box", "box": Vector3(11.0, 1.2, 8.0), "above": 2.0, "speed": [0.15, 0.4],
		"dir": Vector3(1, -0.1, 0), "spread": 40.0, "gravity": -0.05, "when": DAY | DUSK},
}

const PLACES := {
	&"plaines": {"kinds": {&"papillon": 6, &"scarabee": 3, &"fourmis": 2, &"mammifere": 2,
		&"libellule": {"count": 2, "near": {&"water": 5.0}}}, "effects": {&"lucioles": {}}},
	&"foret": {"kinds": {&"moustique": 4, &"libellule": 2, &"feuille": 7, &"escargot": 3, &"fourmis": 3}, "effects": {&"lucioles": {}}},
	&"marais": {"kinds": {&"moustique": 4, &"libellule": 3, &"grenouille": 4, &"poisson_saut": 1},
		"effects": {&"lucioles": {"colour": Color(0.55, 1.0, 0.5), "amount": 32}}},
	&"desert": {"kinds": {&"lezard": 4, &"scorpion": 2, &"scarabee": 3}},
	# The sea: nothing that flutters. Jellyfish glow on the water at night.
	&"cote": {"kinds": {&"crabe": 5, &"poisson_saut": 2, &"ammonite": 2, &"ichthyornis": 2, &"ptero_vol": 1,
		&"meduse": {"count": 2, "when": NIGHT, "surface": true, "on": WATER, "far": {&"land": 2.0},
			"glow": Color(0.75, 0.9, 1.0)}}, "effects": {&"plancton": {}}},
	&"port": {"kinds": {&"crabe": 3, &"poisson_saut": 1, &"ichthyornis": 1, &"ptero_vol": 1},
		"effects": {&"plancton": {"amount": 60}}},
	&"grotte": {"effects": {&"vers_luisants": {}, &"gouttes": {}}},
	&"grotte_marine": {"kinds": {&"crabe": {"count": 3, "on": [&"sand", &"rock"], "near": {&"water": 4.0}}},
		"effects": {&"vers_luisants": {"colour": Color(0.4, 0.8, 1.0)}, &"gouttes": {}}},
	&"recif": {"kinds": {&"banc": 4, &"meduse": 3}},
	&"cabinet": {},
	# Places to come (chapters 6 to 9).
	&"neige": {"kinds": {&"mammifere": {"count": 2, "when": ALWAYS, "on": LAND, "glow": SNOW_LIGHT}},
		"effects": {&"flocons": {}}},
	&"cieux": {"kinds": {&"ptero_vol": 2}, "effects": {&"duvet": {}}},
	&"volcan": {"kinds": {&"lezard": 3, &"scarabee": 3}, "effects": {&"braises": {}, &"cendres": {}}},
	&"apex": {"kinds": {&"libellule": 3, &"moustique": 4, &"feuille": 6},
		"effects": {&"lucioles": {"colour": Color(1.0, 0.45, 0.2), "amount": 30}}},
}


## The kinds living in a place, each as its entry of KINDS with what differs there, its "id" and
## its "count".
static func kinds_of(place: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var kinds: Dictionary = PLACES.get(place, {}).get("kinds", {})
	for id: StringName in kinds:
		var here: Variant = kinds[id]
		var entry: Dictionary = KINDS[id].duplicate()
		if here is Dictionary:
			entry.merge(here, true)
		else:
			entry["count"] = here
		entry["id"] = id
		out.append(entry)
	return out


## The effects of a place, each as its entry of EFFECTS with what differs there, and its "id".
static func effects_of(place: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var effects: Dictionary = PLACES.get(place, {}).get("effects", {})
	for id: StringName in effects:
		var entry: Dictionary = EFFECTS[id].duplicate()
		entry.merge(effects[id], true)
		entry["id"] = id
		out.append(entry)
	return out


## A kind's picture, or null while it is not there.
static func picture(kind: Dictionary) -> Texture2D:
	var path: String = kind.get("pic", PATH % kind["id"])
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## The moment of the day at `hour` (0–24): DAY, NIGHT or DUSK (dawn and dusk).
static func moment(hour: float) -> int:
	if hour > 7.0 and hour < 19.0:
		return DAY
	if hour > 20.5 or hour < 4.5:
		return NIGHT
	return DUSK


## Is a kind (or an effect) out at this moment, in this much rain (0–1)?
static func is_out(entry: Dictionary, now: int, rain: float) -> bool:
	return (int(entry.get("when", ALWAYS)) & now) != 0 and (rain < 0.3 or entry.get("rain", false))
