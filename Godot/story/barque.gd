class_name Barque
## Maïa's boat, the second way to travel fast (docs/histoire.md « La barque de Maïa »): once Maïa
## and Chloé are a team (maia_alliee, end of chapter 6: « Ma barque est à toi »), her boat waits at
## the landing of each place by the water (QUAYS: a StoryProp « BarqueMaia », event &"barque_maia",
## show_flag maia_alliee, and the « Embarcadere » spawn on the quay beside it, tools/zones/*.gd).
## Chloé uses it: the landing is noted for good, then she picks another landing she knows (the
## Grand Voyageur's screen, VoyageScreen, with its own title). A short crossing: she jumps in, the
## boat glides off, the time passes; it comes in at the other landing and she jumps ashore; the
## place's own arrival scene plays as usual. The very first time, Maïa's note is in the boat.
## The Grand Voyageur (story/voyage.gd) goes everywhere, slowly; the boat only along the shore,
## from the end of chapter 6. The Vol (chapter 7) will come on top of both.
## Flags: barque_maia_prete, quai_<zone> (see QUAYS); barque_n (Chloé's thoughts, in turn).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const CHLOE := "Chloé"
## Where Chloé lands, on the quay beside the boat (a spawn of each zone of QUAYS).
const SPAWN := &"Embarcadere"
## The boat's node in each of those zones.
const BOAT := "BarqueMaia"
## How long the crossing lasts, in game minutes (the Grand Voyageur's slow ride: 90).
const CROSSING_MINUTES := 60.0
## The destination screen's words.
const TITLE := "Où met-on le cap ?"
const SUBTITLE := "Maïa connaît tous les chemins de la mer."
## How the boat moves on screen: px/s gliding; Chloé's stand-in sitting on its bench (a little in
## front of the boat's middle, raised that high above the water: checked on captures, 11/10); her
## hop into it and out of it, the boat rocking under her.
const GLIDE_SPEED := 55.0
const SEAT_OFFSET := Vector2(0.0, 3.0)
const SEAT_DECK_M := 0.35
const HOP_HEIGHT := 14.0
const ROCK_HEIGHT := 3.0
const FADE_S := 0.25
const SPLASH_BITS := 10
## A scene of the zone (its arrival) is still playing: look again this often (s). The boat waits
## at most this long for Chloé to be aboard before it glides off.
const SCENE_POLL_S := 0.1
const BOARD_WAIT_S := 1.0

## Every landing, around the island: its zone, the flag set once Chloé has used the boat there,
## the region's name (AtlasDB), what one sees from there (the list), where the boat comes in and
## what Chloé jumps onto (the arrival lines), which way open water lies from the boat (tiles: it
## glides off that way, and comes in from there).
const QUAYS := [
	{"zone": &"port_ambre", "flag": &"quai_port_ambre", "region": "Port-Ambre",
		"sight": "Le vieux ponton et les maisons du village.", "landing": "au vieux ponton de Port-Ambre",
		"ashore": "sur le ponton", "out": Vector2(4.0, 0.4)},
	{"zone": &"havre_dore", "flag": &"quai_havre_dore", "region": "Havre-Doré",
		"sight": "Les lanternes du port et le marché.", "landing": "au ponton des pêcheurs de Havre-Doré",
		"ashore": "sur le ponton", "out": Vector2(3.5, 1.5)},
	{"zone": &"cote", "flag": &"quai_cote", "region": "Côte Préhistorique",
		"sight": "La plage aux tortues et la Cale des Anciens.", "landing": "au pied de la Cale des Anciens",
		"ashore": "sur le sable", "out": Vector2(2.5, -3.5)},
	{"zone": &"marais", "flag": &"quai_marais", "region": "Marais Brumeux",
		"sight": "Le débarcadère de Joss, dans la brume.", "landing": "au débarcadère de Joss",
		"ashore": "sur les planches", "out": Vector2(0.0, -4.5)},
]
## Maïa's note, in the boat the first time: read out line by line (not on the letters' paper,
## which is Hélène's, with her fern and her seal).
const NOTE := [
	"« Pour Chloé. Elle est à toi. Enfin, à nous. Tu la trouveras au port, au Havre, à la Cale des Anciens sur la Côte, et au débarcadère de Joss dans le Marais. »",
	"« Ne t'éloigne jamais de la côte. Et si la brume tombe, chante : maman dit que la mer aime ça. Elle chante faux, maman. La mer aime quand même. »",
	"« PS : Moustique a mangé la corde de rechange. Ne la cherche pas. — Maïa »",
]
## What Chloé thinks on the way, one after the other from one crossing to the next.
const THOUGHTS := [
	"(« Ne t'éloigne jamais de la côte. » D'accord, Maïa. Promis.)",
	"(Ramer, c'est comme marcher. Avec les bras. Et de l'eau partout.)",
	"(Je me demande si Hélène prenait la mer, elle aussi. Sûrement. Elle prenait tout.)",
]

## The landing the boat is heading for while the screen is black (set by _cross, read by landing).
static var _heading_for := &""
## The arrival landing() set up out at sea: {boat, stand_in, moored} (empty: none).
static var _arrival := {}

## Using Maïa's boat (StoryProp « BarqueMaia »): the landing is noted, then Chloé picks where to go.
## Nothing before Maïa lends it (the boat is not even there then: its show_flag).
static func use(boat: Node) -> void:
	var quay := quay_of(Voyage.zone_now())
	if quay.is_empty() or not Game.flag(&"maia_alliee"):
		return
	S.lock(true)
	if not Game.flag(&"barque_maia_prete"):
		await S.say(_maias_note(boat))
	if not Game.flag(quay["flag"]):
		Game.set_flag(quay["flag"])
		await S.say([{"text": "Chloé note l'embarcadère sur sa carte : la barque de Maïa peut y accoster."}])
	var known := known_quays()
	if known.size() < 2:
		await S.say([
			{"who": CHLOE, "text": "(Pour l'instant, je ne connais que cet embarcadère-ci.)"},
			{"who": CHLOE, "text": "(Maïa a parlé du port, du Havre, de la Côte et du Marais. Quand j'en aurai trouvé un autre, la barque saura m'y mener.)"},
		])
		S.lock(false)
		return
	var rows := []
	for q: Dictionary in known:
		rows.append([q["zone"], q["region"], q["sight"]])
	var goes: StringName = await VoyageScreen.ask(S.world(), rows, Voyage.zone_now(), TITLE, SUBTITLE)
	if goes == &"":
		await S.say([CS.cue({"text": "La barque se balance doucement au bout de son amarre. Elle attendra."},
			func() -> void: Stage.hop(boat, 2, ROCK_HEIGHT))])
		S.lock(false)
		return
	await _cross(boat, goes)


## The first time: Maïa's note, folded under the oar.
static func _maias_note(boat: Node) -> Array:
	var chloe := Stage.chloe()
	var finds := func() -> void:
		Stage.turn_to(chloe, _at(boat, chloe))
		Stage.bow(chloe, 0.7)
	var lines: Array = [CS.cue({"text": "Dans la barque, coincé sous la rame, un papier plié en quatre. L'écriture de Maïa part dans tous les sens."}, finds)]
	for paragraph: String in NOTE:
		lines.append({"text": paragraph})
	lines.append_array([
		CS.cue({"who": CHLOE, "text": "(« Enfin, à nous. » … Merci, Maïa. Je ne la coulerai pas. Je vais essayer.)"},
			func() -> void: Stage.emote(chloe, "♥")),
		{"flag": &"barque_maia_prete"},
	])
	return lines


## Chloé jumps in, the boat glides off; the time passes; at the landing of `zone` the boat comes
## in (or, when that place's own scene plays first, she is simply there) and she jumps ashore.
static func _cross(boat: Node, zone: StringName) -> void:
	var from := quay_of(Voyage.zone_now())
	var w = S.world()
	if w == null:
		S.lock(false)
		return
	var cast := {}
	var home := _at(boat, Stage.chloe())
	var boards := func() -> void:
		await _board(boat, cast)
	var glides := func() -> void:
		var waited := 0.0
		while not cast.has("stand_in") and waited < BOARD_WAIT_S:   # (a line skipped before she is aboard)
			await S.wait(SCENE_POLL_S)
			waited += SCENE_POLL_S
		var stand_in = cast.get("stand_in")
		var away := _at(boat, null) + (from.get("out", Vector2.ZERO) as Vector2) * S.CELL
		Stage.look_at(away, 1.8)
		for n in [boat, stand_in]:
			if is_instance_valid(n) and n is Node2D:
				CS.glide(n, [away + (SEAT_OFFSET if n == stand_in else Vector2.ZERO)], GLIDE_SPEED)
	await S.say([
		CS.cue({"text": "Chloé détache l'amarre, saute dans la barque et s'éloigne du bord à grands coups de rame."}, boards),
		CS.cue({"text": _on_the_way()}, glides),
		{"who": CHLOE, "text": ForetCamp.next_line(&"barque_n", THOUGHTS)},
	])
	Game.pass_minutes(CROSSING_MINUTES)
	var before: int = S.playing
	_heading_for = zone
	await w.goto_zone(zone, SPAWN)
	_heading_for = &""
	if Voyage.zone_now() != zone:   # (the world refused: a zone change already under way)
		_arrival = {}
		_moor(boat, cast.get("stand_in"), home)
		_show_party(w)
		S.lock(false)
		return
	await _arrive(w, quay_of(zone), before)
	Save.save_game()
	S.lock(false)


## The zone has just been put in place, the screen still black (Story.on_zone_entered): when the
## boat is heading for its landing, it waits out at sea with Chloé sitting in it, so the picture
## that fades in already shows it coming.
static func landing(zone: StringName) -> void:
	if _heading_for == &"" or _heading_for != zone:
		return
	_heading_for = &""
	_arrival = {}
	var boat = S.actor(BOAT)
	if not boat is Node2D:
		return
	var moored: Vector2 = (boat as Node2D).global_position
	var out := moored + (quay_of(zone).get("out", Vector2.ZERO) as Vector2) * S.CELL
	(boat as Node2D).global_position = out
	_arrival = {"boat": boat, "stand_in": _seat(out), "moored": moored}
	_set_party_alpha(S.world(), 0.0)   # (still in the boat: the world's own fade-in showed her again)
	Stage.look_at(out, 0.0)


## Chloé hops into the boat: she and her lead dino leave the quay (faded out: they are aboard), a
## stand-in of her sits in the boat, which rocks and splashes. `cast` gets the stand-in.
static func _board(boat: Node, cast: Dictionary) -> void:
	var w = S.world()
	var chloe := Stage.chloe()
	if w == null or chloe == null:
		return
	var at := _at(boat, chloe)
	Stage.turn_to(chloe, at)
	await Stage.hop(chloe, 1, HOP_HEIGHT)
	_hide_party(w)
	cast["stand_in"] = _seat(at)
	CS.splash(at, SPLASH_BITS)
	Stage.hop(boat, 2, ROCK_HEIGHT)


## At the landing: the boat comes in with Chloé in it and she jumps ashore, onto the quay where the
## world put her. When the place's own scene plays first (Story.on_zone_entered), she is shown at
## once for it, it plays to its end, and only the jump ashore follows.
static func _arrive(w, quay: Dictionary, before: int) -> void:
	var set_up := _arrival
	_arrival = {}
	var boat = set_up.get("boat")
	var stand_in = set_up.get("stand_in")
	var moored: Vector2 = set_up.get("moored", _at(S.actor(BOAT), Stage.chloe()))
	if S.playing > before or set_up.is_empty():
		_moor(boat, stand_in, moored)
		_show_party(w)
		Stage.look_back(0.0)
		await _scene_over(before)
		S.lock(true)
		await S.say([{"text": "Chloé amarre la barque %s d'un nœud de marin. Enfin… d'un nœud." % quay.get("landing", "")}])
		return
	S.lock(true)
	var comes_in := func() -> void:
		Stage.look_at(moored, 1.8)
		for n in [boat, stand_in]:
			if is_instance_valid(n) and n is Node2D:
				CS.glide(n, [moored + (SEAT_OFFSET if n == stand_in else Vector2.ZERO)], GLIDE_SPEED)
	var ashore := func() -> void:
		_moor(boat, stand_in, moored)
		_show_party(w)
		var chloe := Stage.chloe()
		Stage.turn_to(chloe, moored)
		Stage.hop(chloe, 1, HOP_HEIGHT)
		CS.splash(moored, SPLASH_BITS)
		Stage.hop(boat, 2, ROCK_HEIGHT)
	await S.say([
		CS.cue({"text": "La barque accoste %s." % quay.get("landing", "")}, comes_in),
		CS.cue({"text": "Chloé saute %s et l'amarre d'un nœud de marin. Enfin… d'un nœud." % quay.get("ashore", "à terre")}, ashore),
	])
	_moor(boat, stand_in, moored)   # (the lines read faster than the boat glides)
	_show_party(w)
	Stage.look_back()


## Chloé's stand-in, sitting in the boat at `boat_px` (the player herself would swim there).
static func _seat(boat_px: Vector2) -> Node2D:
	var n = S.stranger("ChloeBarque", "chloe", boat_px + SEAT_OFFSET, "down")
	if n == null:
		return null
	n.remove_from_group(&"npc")   # (not turned towards whoever speaks)
	CS.in_boat(n, SEAT_DECK_M)
	Stage.pose(n, &"assis")
	return n


## The boat at its mooring, the stand-in gone: what the glides were heading for.
static func _moor(boat, stand_in, moored: Vector2) -> void:
	if is_instance_valid(boat) and boat is Node2D:
		_stop_glide(boat)
		(boat as Node2D).global_position = moored
	if is_instance_valid(stand_in) and not (stand_in as Node).is_queued_for_deletion():
		_stop_glide(stand_in)
		(stand_in as Node).queue_free()


static func _stop_glide(n: Node) -> void:
	var t = n.get_meta(&"glide") if n.has_meta(&"glide") else null
	if t is Tween and (t as Tween).is_valid():
		(t as Tween).kill()


## Chloé and her lead dino out of sight (aboard), or back in it.
static func _hide_party(w) -> void:
	for n in [w.get("player"), w.get("companion")]:
		if n is Node2D:
			Stage.fade_out(n, FADE_S)


static func _show_party(w) -> void:
	_set_party_alpha(w, 1.0)


static func _set_party_alpha(w, alpha: float) -> void:
	if w == null:
		return
	for n in [w.get("player"), w.get("companion")]:
		if n is CanvasItem:
			(n as CanvasItem).modulate.a = alpha


## Waits for the scene the zone started (S.playing back to what it was before the zone changed).
static func _scene_over(before: int) -> void:
	while S.playing > before:
		await S.wait(SCENE_POLL_S)


## The crossing, by the weather and the hour: rain, mist (Maïa's advice), night, else a calm day.
static func _on_the_way() -> String:
	if Game.is_raining():
		return "La pluie crépite sur l'eau. Chloé rame vite, les cheveux trempés : au moins, la mer ne peut pas la mouiller davantage."
	if Game.weather == &"mist":
		return "La brume tombe. Chloé chante, comme Maïa l'a dit. Faux. La mer a l'air d'aimer quand même."
	if Game.phase() == &"night":
		return "La barque glisse sur l'eau noire. Les étoiles tremblent dans son sillage."
	return "La barque glisse le long de la côte. Chloé rame en cadence : un, deux… un, deux…"


## Where the boat is (world px), or near Chloé when there is none (a test, a scene without it).
static func _at(boat, chloe) -> Vector2:
	if is_instance_valid(boat) and boat is Node2D:
		return (boat as Node2D).global_position
	return (chloe as Node2D).global_position + Vector2(0.0, S.CELL) if chloe is Node2D else Vector2.ZERO


## The landings Chloé has used the boat at (in the island's order), her own included.
static func known_quays() -> Array:
	return QUAYS.filter(func(q: Dictionary) -> bool: return Game.flag(q["flag"]))


## The landing of a zone (empty when that zone has none).
static func quay_of(zone: StringName) -> Dictionary:
	for q: Dictionary in QUAYS:
		if q["zone"] == zone:
			return q
	return {}
