extends RefCounted
## Chapter 6's staging (the rules are in story/stage.gd): the Monts' lines acted out — breath
## and snow puffs, ice that drips and melts, a lantern walking in the blizzard, the Cœurs' warmth
## against the cold — and what the chapter's files share: a species or its stand-in while its
## sheet is not there yet, what Chloé still needs to break the ice walls (charge_step), what hits
## a guardian hard (weak_to), a battle of honour fought rested. Preloaded as `MS` by
## story/monts*.gd (no class_name). The moves change pictures and places, never the flags.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const D := preload("res://story/desert.gd")
const Act := preload("res://story/marais_stage.gd")
const P := preload("res://story/monts_places.gd")
## Snow thrown up, a breath in the cold, drops of melting ice, frost; the Cœurs' warm light; the
## cold blue of the ice; a lantern's glow; black amber's violet.
const SNOW_BITS: Array[Color] = [Color(1.0, 1.0, 1.0), Color(0.9, 0.94, 1.0), Color(0.8, 0.87, 0.96)]
const BREATH_BITS: Array[Color] = [Color(0.96, 0.97, 1.0), Color(0.88, 0.9, 0.95)]
const DRIP_BITS: Array[Color] = [Color(0.75, 0.9, 1.0), Color(0.9, 0.97, 1.0), Color(0.6, 0.82, 0.98)]
const ICE_BLUE := Color(0.7, 1.15, 1.7)
const HEART_GLOW := CS.HEART_GLOW
const LANTERN := Color(1.0, 0.78, 0.45)
const VIOLET := Color(0.62, 0.3, 1.0)
const ICE_SOUND := "res://assets/audio/sfx/glass.wav"
const RUMBLE := "res://assets/audio/sfx/rock_heavy.wav"
const ALPHA_MUSIC := "res://assets/audio/music/alpha.ogg"
const OMBRE_MUSIC := "res://assets/audio/music/ombre.ogg"
## The chapter's species and what stands in for them while their sheets are not in SpeciesDB.
const STAND_INS := {
	&"pachyrhinosaurus": &"triceratops", &"edmontosaurus": &"parasaurolophus", &"leaellynasaura": &"compsognathus",
	&"minmi": &"ankylosaurus", &"nanuqsaurus": &"allosaurus", &"cryolophosaure_titan": &"allosaurus",
}
## French names of the types, in the lines (« le Feu », « l'Eau »…).
const TYPE_WORDS := {"feu": "le Feu", "eau": "l'Eau", "terre": "la Terre", "vent": "le Vent", "pierre": "la Pierre",
	"nature": "la Nature"}
const TYPE_OF := {"feu": "du Feu", "eau": "de l'Eau", "terre": "de la Terre", "vent": "du Vent", "pierre": "de la Pierre",
	"nature": "de la Nature", "neutre": "neutre"}


# ------------------------------------------------------------------ species

## `id` when SpeciesDB has it, else its stand-in (a scene never breaks for a missing sheet).
static func species_or(id: StringName) -> StringName:
	if SpeciesDB.PATHS.has(id):
		return id
	return STAND_INS.get(id, &"velociraptor")


## A dino only a scene needs (CS.stand_in), its species or its stand-in; invisible at first.
static func stand_in(id: StringName, at_px: Vector2, node_name: String, level := 0, size := 1.0) -> DinoNpc:
	return CS.stand_in(species_or(id), at_px, node_name, level, size)


# ------------------------------------------------------------------ cold and ice

## A breath in the cold air: a little white cloud at `actor`'s head (a person: her face).
static func breath(actor: Node, amount := 8) -> void:
	if not actor is Node2D or not is_instance_valid(actor):
		return
	var at: Vector2 = D._head_of(actor) if actor is DinoNpc or actor is Companion else (actor as Node2D).global_position
	var height := 0.9 if actor is DinoNpc or actor is Companion else 1.35
	Act.burst(at, BREATH_BITS, amount, height, 0.15)


## Snow thrown up at `px` (a charge, a fall, something landing).
static func snow_puff(px: Vector2, amount := 14, height := 0.2, spread := 0.4) -> void:
	Act.burst(px, SNOW_BITS, amount, height, spread)


## Drops of melting ice at `px`, `times` times (not awaited).
static func drips(px: Vector2, times := 3, every := 0.35, height := 1.0) -> void:
	for i in times:
		Act.burst(px + Vector2(randf_range(-14.0, 14.0), 0.0), DRIP_BITS, 6, height, 0.12)
		await S.wait(every)


## Ice cracks, far below or close by: a low sound, the camera shakes a little.
static func crack(strength := 2.0) -> void:
	CS.sfx(ICE_SOUND, -8.0)
	Stage.shake(strength, 0.4)


## The Cœurs in Chloé's bag beat: their warm glow on her (CS.hearts_beat). Awaitable.
static func hearts(beats := 2, every := 1.0) -> void:
	await CS.hearts_beat(beats, every)


## How many Cœurs Chloé carries (the flags coeur_1 to coeur_5).
static func hearts_count() -> int:
	var n := 0
	for i in range(1, 6):
		if Game.flag(StringName("coeur_%d" % i)):
			n += 1
	return n


## A lantern's light that follows `who` (Roc in the blizzard) until `until["on"]` is false; then
## it fades. Not awaited.
static func lantern_on(who: Node2D, until: Dictionary, energy := 1.8) -> void:
	var light := Stage.light_at(who.global_position, LANTERN, 3.5)
	if light == null:
		return
	light.light_energy = energy
	var view := Stage._view()
	while until.get("on", false) and is_instance_valid(who) and is_instance_valid(light) and view and view.heights:
		light.position = view.heights.to_3d(who.global_position) + Vector3(0.3, 1.1, 0.4)
		light.light_energy = energy * (0.85 + 0.15 * sin(Time.get_ticks_msec() / 90.0))   # (the flame flickers)
		await S.wait(0.05)
	if is_instance_valid(light):
		var t := light.create_tween()
		t.tween_property(light, "light_energy", 0.0, 0.8)
		t.tween_callback(light.queue_free)


# ------------------------------------------------------------------ the ice walls (Charge)

## A dino that charges (and is there): the lead one if it can, else the first of the party.
static func charger() -> Dino:
	return Game.ability_user(&"charge")


## What still keeps Chloé from breaking the ice walls ("" when she can): a dino that charges, in
## the party or waiting at the Cabinet, or where to find one.
static func charge_step() -> String:
	if charger():
		return ""
	for d: Dino in Game.box:
		if Abilities.usable(d, &"charge"):
			return "Ton %s attend au Cabinet : lui enfoncerait la glace. Fais-le venir depuis ton Dinodex, ou demande au Pr Roc." % d.nickname
	return "Il faut un dino qui charge, la tête dure : les grands Pachyrhinosaurus de la vallée cassent la glace du lac chaque matin, d'un coup de nez. Les Minmi des grottes aussi, dit-on."


# ------------------------------------------------------------------ battles

## Which types hit a dino of type `type` hard (TYPE_CHART), in words: « l'Eau et la Terre ».
static func weak_to(type: String) -> String:
	return words(strong_against(type))


## Which types its own blows hurt badly, in words (`words(…, TYPE_OF)`: « du Vent et de la Nature »).
static func hurts(type: String, forms := TYPE_WORDS) -> String:
	var weak: Array = []
	var row: Dictionary = MovesDB.TYPE_CHART.get(type, {})
	for defender: String in row:
		if float(row[defender]) > 1.0:
			weak.append(defender)
	return words(weak, forms)


## The types whose moves hit a dino of type `type` hard.
static func strong_against(type: String) -> Array:
	var out: Array = []
	for attacker: String in MovesDB.TYPE_CHART:
		if float(MovesDB.TYPE_CHART[attacker].get(type, 1.0)) > 1.0:
			out.append(attacker)
	return out


## Types in words: « l'Eau et la Terre » (or with `forms` = TYPE_OF: « de l'Eau et de la Terre »).
static func words(types: Array, forms := TYPE_WORDS) -> String:
	var said: Array = types.map(func(t: String) -> String: return forms.get(t, t))
	if said.is_empty():
		return ""
	return said[0] if said.size() == 1 else ", ".join(said.slice(0, -1)) + " et " + said[-1]


## A battle of honour is fought rested: `line` is said while the party is healed (only when a
## dino needs it; `act` plays with it). Awaitable.
static func rested(line: String, act := Callable()) -> void:
	var tired := Game.party.any(func(d: Dino) -> bool: return d.hp < d.max_hp())
	if not tired:
		return
	Game.heal_party()
	Game.party_changed.emit()
	await S.say([CS.cue({"text": line}, act) if act.is_valid() else {"text": line}])


## A theme when its file is there.
static func music(path: String) -> AudioStream:
	return ForetCamp.music_at(path)


# ------------------------------------------------------------------ Maïa

static func maia_starter_name() -> String:
	return CS.maia_starter_name()


# ------------------------------------------------------------------ poses

## Chloé kneels (by a little one, by someone fallen) in her drawn crouching picture, held until
## stand_up; when it is not drawn, only a bow (never a squash: she would seem to shrink).
static func kneel() -> void:
	var chloe := Stage.chloe()
	if chloe and not Stage.pose(chloe, &"accroupi"):
		await Stage.bow(chloe, 0.8)


## Back on her (or their) feet from a drawn pose.
static func stand_up(actor) -> void:
	if actor and is_instance_valid(actor):
		Stage.pose(actor, &"")
