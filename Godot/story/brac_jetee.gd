class_name BracJetee
## Brac at the end of the jetty of Port-Ambre, from the day he left the forges to see the sea « de
## loin » (brac_parti) and on after the end (docs/post-game-scenes.md § B, post-game-plan.md § 5).
## Before the epilogue: « Le phare qui boude » (B1, once: the sandwich lifted, the three heads that
## turn, his three presented), then a line per visit; the morning of the jetty: talking to him starts
## it, like anyone of the jetty. After the end: « Le partage » (B2, by day, once: the sandwich cut in
## four), then his night watchman's lines (DialogueApex.BRAC_JETEE); his beasts and the BARC sign
## looked at (B3); by night his watchman's sheet, the lantern lit, Mastoc up by it. Everything is put by
## the code round the zone's Brac (Npc « BracJetee », show_flag brac_parti): his three before the end
## (the zone's own only come for the epilogue), Mastoc after it (the zone's leaves with the epilogue),
## the sandwich, the sign, the lantern. The words: data/dialogue_brac.gd.
## Flags: brac_jetee_vu, brac_jetee_avant_n, brac_sandwich_partage (brac_jetee_n: DialogueApex's pool).

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const A := preload("res://story/apex.gd")
const DB := preload("res://data/dialogue_brac.gd")
const BRAC := "Brac"
## The zone's Brac (tools/zones/port_ambre.gd).
const NODE := "BracJetee"
## The pictures of what the code puts on the jetty (assets/art/props/<kind>.png, known to Prop.KINDS):
## the first one there wins. The IMAGES agent's (lot A': sandwich, panneau_barc) first; a picture of
## the island stands in while Prop does not know them (the sandwich has none: the bubbles say it). The
## lantern is the jetty's big one (the port's lamp), left to Mastoc: Brac carries the small one at night.
const SANDWICH_KINDS := ["sandwich"]
const PANNEAU_KINDS := ["panneau_barc", "panneau"]
const LANTERNE_KINDS := ["lanterne"]
## His night watchman's sheet (characters/brac_gardien.png: hat, no mask, his small lantern in hand),
## worn as Outfits.LOOKS « brac » → gardien.
const NIGHT_SHEET := "brac_gardien"
const NIGHT_LOOK := &"gardien"
## Where his three and his things stand, in tiles from him (he sits at the end of the jetty, on its
## west edge: ApexPlaces.JETEE_BRAC, 18.6 × 22.3): Mastoc and the things on the planks north of him,
## away from the way to Maïa's boat (its landing two tiles east of him) and from Léonce (at the root
## of the pier); Cabosse and Grognon on the quay by the root (the pier is three tiles wide: they would
## bar it), where they look at the sea, and where they come in B2 from their places of the post-game.
const AROUND := {
	"mastoc": Vector2(-0.25, -1.3),      # beside him (standing; asleep by day after the end)
	"sandwich": Vector2(0.4, 0.1),       # on the planks beside his cage
	"panneau": Vector2(-0.45, -0.55),    # planted behind him
	"lanterne": Vector2(0.6, -0.95),     # by Mastoc's head
	"cabosse": Vector2(-1.5, -5.7),      # the quay, west of the pier's root
	"grognon": Vector2(-3.1, -5.9),
}
## Of them, what stands on the pier (the others on the quay).
const ON_PIER := ["mastoc", "sandwich", "panneau", "lanterne"]
## The things this file brings on, and Mastoc after the end (the zone's MastocJetee leaves then).
const NAMES := {"mastoc": "MastocBrac", "sandwich": "Sandwich", "panneau": "PanneauBarc", "lanterne": "LanterneBrac"}
## His three: their species; their names, the zone's nodes of the epilogue (CabosseJetee and
## GrognonJetee stay on the quay after it): before the end, the ones brought on here are named so, and
## the jetty's scene the next morning takes them as its own (ApexJetee: A.dino finds them by name).
const SPECIES := {"mastoc": &"allosaurus", "cabosse": &"stygimoloch", "grognon": &"majungasaurus"}
const ZONE_NODES := {"mastoc": "MastocJetee", "cabosse": "CabosseJetee", "grognon": "GrognonJetee"}
const BEASTS := {&"mastoc_jetee": "mastoc", &"cabosse_jetee": "cabosse", &"grognon_jetee": "grognon"}
const PANNEAU_EVENT := &"panneau_barc"
## The lantern's light at night (warm).
const LANTERN_LIGHT := Color(1.0, 0.72, 0.38)


# ------------------------------------------------------------------ what plays now

## True once Brac sits at the end of the jetty (brac_parti): his event is this file's from then on.
static func takes_over() -> bool:
	return bool(Game.flag(&"brac_parti"))


## Night, for him (the watchman's sheet, the lantern lit, no sharing: he is at work).
static func is_night() -> bool:
	return Game.phase() == &"night"


## What talking to Brac plays now: &"phare" (B1), &"avant" (a line, before the end), &"jetee" (the
## epilogue's morning: the jetty's scene), &"partage" (B2), &"gardien" (a line, after the end), &""
## (he is not on the jetty).
static func moment() -> StringName:
	if not takes_over():
		return &""
	if Game.flag(&"epilogue_fini"):
		return &"partage" if not Game.flag(&"brac_sandwich_partage") and not is_night() else &"gardien"
	if Game.flag(&"epilogue_cabinet"):
		return &"jetee"
	return &"avant" if Game.flag(&"brac_jetee_vu") else &"phare"


## The events of this file (Apex.run): Brac, his three on the jetty, the sign.
static func run(event: StringName, who: Node) -> void:
	if event == PANNEAU_EVENT:
		await S.say([{"text": DB.PANNEAU}])
	elif BEASTS.has(event):
		await beast(event, who)
	else:
		await talk(who)


## Talking to Brac (event « brac_jetee »).
static func talk(who: Node) -> void:
	match moment():
		&"phare":
			await phare(who)
		&"avant":
			await _line(who, ForetCamp.next_line(&"brac_jetee_avant_n", DB.avant_pool(bool(Game.flag(&"apex_fini")))))
		&"jetee":
			await Epilogue.jetty_event(&"brac_jetee", who)
		&"partage":
			await partage(who)
		&"gardien":
			dress_for_time(who)
			if not is_night():   # (night watchman by day: asleep on his cage, he opens an eye)
				Stage.emote(who, "z")
				await S.wait(0.7)
			await _line(who, ForetCamp.next_line(&"brac_jetee_n", DialogueApex.BRAC_JETEE))
		_:
			Stage.emote(who, "…")
			await S.wait(0.6)


## One of his three looked at (B3, after the end): its line, a cry; before it, a look (the morning of
## the jetty: the jetty's scene).
static func beast(event: StringName, who: Node) -> void:
	if Game.flag(&"epilogue_cabinet") and not Game.flag(&"epilogue_port"):
		await Epilogue.jetty_event(event, who)
		return
	var line := DB.bete(event, is_night()) if Game.flag(&"epilogue_fini") else ""
	if who is DinoNpc:
		(who as DinoNpc).cry(&"neutre")
	if line == "":
		Stage.emote(who, "…")
		await S.wait(0.8)
		return
	await S.say([CS.cue({"text": line}, _beast_moves.bind(String(BEASTS[event]), who))])


static func _beast_moves(key: String, who) -> void:
	match key:
		"mastoc":
			Stage.emote(who, "…" if is_night() else "z")
		"cabosse":
			Stage.bow(who, 1.4)   # (the head on one side, towards the sea)
		"grognon":
			Stage.tremble(who, 0.6, 1.5)
			Stage.emote(who, "~")


static func _line(who: Node, text: String) -> void:
	_faces(who)
	await S.say([{"who": BRAC, "text": text}])


# ------------------------------------------------------------------ B1, le phare qui boude

## B1 (10 lines), once: Brac on his cage, the sandwich beside him, Mastoc standing against him,
## Cabosse and Grognon on the quay looking at the sea; then he looks at the sea again.
static func phare(who: Node) -> void:
	var b := _brac_or(who)
	S.lock(true)
	var cast := place_before(b)
	await S.say(staged(DB.phare(bool(Game.flag(&"roc_brac_parti"))), _phare_cues(cast)))
	Stage.look_back()
	Save.save_game()
	S.lock(false)


## The moves of B1, by the "cue" of its lines.
static func _phare_cues(cast: Dictionary) -> Dictionary:
	return {"tourne": _turns_to_chloe.bind(cast.get("brac")), "leve": _lifts.bind(cast), "regardent": _watch.bind(cast.get("brac")),
		"mastoc": _head_up.bind(cast.get("mastoc")), "cabosse": _ready_to_charge.bind(cast.get("cabosse"), cast.get("brac")),
		"grognon": _grumbles.bind(cast.get("grognon")), "mer": _back_to_sea.bind(cast)}


## His three (Mastoc, Cabosse, Grognon) of a cast, null where one is missing.
static func _three(cast: Dictionary) -> Array:
	return ["mastoc", "cabosse", "grognon"].map(func(k: String): return cast.get(k))


## True for an actor or a thing still in the zone (a move played late, after a zone change, finds it
## freed: it does nothing then).
static func _live(x) -> bool:
	return is_instance_valid(x) and x is Node2D


static func _turns_to_chloe(b) -> void:
	_faces(b)
	if _live(b):
		Stage.look_at((b as Node2D).global_position.lerp(A.chloe_px(), 0.4), 0.9)


static func _watch(who) -> void:
	if _live(who):
		Stage.look_at((who as Node2D).global_position, 0.8)


## Watched: he reaches for the sandwich and lifts it; the three heads turn to him at once, with a
## start; he puts it down.
static func _lifts(cast: Dictionary) -> void:
	var b = cast.get("brac")
	var sandwich = cast.get("sandwich")
	if _live(b) and _live(sandwich):
		CS.reach(b, (sandwich as Node2D).global_position, 6.0, 0.5)
	if _live(sandwich):
		_lift(sandwich, 30.0, 1.8)
	await S.wait(0.5)
	for n in _three(cast):
		if _live(n) and _live(b):
			Stage.turn_to(n, (b as Node2D).global_position)
			Stage.emote(n, "!")


## Grognon grumbles (his cry, a shiver).
static func _grumbles(g) -> void:
	if not _live(g):
		return
	_watch(g)
	Stage.cry(g, &"neutre")
	Stage.tremble(g, 0.6, 1.5)


## He looks at the sea again; Cabosse and Grognon too.
static func _back_to_sea(cast: Dictionary) -> void:
	Stage.look_back(1.0)
	var b = cast.get("brac")
	if _live(b) and b is Npc:
		(b as Npc).face((b as Node2D).global_position + Vector2(0.0, 100.0))
	for n in _three(cast).slice(1):
		_look_at_sea(n)


## A thing's picture goes up `px`, stays `hold` seconds, comes back down. Awaitable.
static func _lift(thing, px: float, hold: float) -> void:
	var sprite := Stage.sprite_of(thing)
	if sprite == null:
		return
	var rest := sprite.position
	var t := sprite.create_tween()
	t.tween_property(sprite, "position:y", rest.y - px, 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_interval(hold)
	t.tween_property(sprite, "position:y", rest.y, 0.4).set_trans(Tween.TRANS_SINE)
	await t.finished


## Mastoc raises his head (he stands against Brac: a dino lies down only to sleep).
static func _head_up(mastoc) -> void:
	if not _live(mastoc):
		return
	_watch(mastoc)
	await Stage.rear(mastoc, 1.2)


## Cabosse lowers his head, ready to charge Chloé; Brac: « Non. Pas maintenant. » (a hop of his hand).
static func _ready_to_charge(cabosse, b) -> void:
	if not _live(cabosse):
		return
	_watch(cabosse)
	Stage.turn_to(cabosse, A.chloe_px())
	await Stage.bow(cabosse, 1.6)
	if _live(b):
		Stage.hop(b, 1, 4.0)


# ------------------------------------------------------------------ B2, le partage

## B2 (6 lines), after the end, by day, once: Brac asleep on his cage opens an eye; Cabosse and
## Grognon come along the pier; the sandwich cut in four; then they go back to the quay.
static func partage(who: Node) -> void:
	var b := _brac_or(who)
	S.lock(true)
	dress_for_time(b)
	var cast := place_after(b)
	Stage.emote(b, "z")
	await S.wait(1.0)
	await S.say(staged(DB.partage(), _partage_cues(cast)))
	await _back_to_quay(cast)
	Stage.look_back()
	Save.save_game()
	S.lock(false)


## The moves of B2, by the "cue" of its lines.
static func _partage_cues(cast: Dictionary) -> Dictionary:
	return {"reveil": _wakes.bind(cast), "regarde": _looks_round.bind(cast), "partage": _shares.bind(cast),
		"content": _pleased.bind(cast)}


## He opens an eye, turns to Chloé; Cabosse and Grognon come for the sandwich.
static func _wakes(cast: Dictionary) -> void:
	var b = cast.get("brac")
	if _live(b):
		Stage.emote(b, "…")
		_faces(b)
	_come_for_it(cast)


## Cut in four with his rope knife: the sandwich is gone, a part for each (they bow), one for him.
static func _shares(cast: Dictionary) -> void:
	var b = cast.get("brac")
	var s = cast.get("sandwich")
	if _live(b) and _live(s):
		CS.reach(b, (s as Node2D).global_position, 8.0, 0.6)
	await S.wait(0.4)
	if _live(s):
		Stage.fade_out(s, 0.6, true)
	for n in _three(cast) + [b]:
		if _live(n):
			Stage.bow(n, 0.9)


## « Le meilleur sandwich du monde »: a little hop; Mastoc's heart.
static func _pleased(cast: Dictionary) -> void:
	if _live(cast.get("brac")):
		Stage.hop(cast.get("brac"), 1, 4.0)
	if _live(cast.get("mastoc")):
		Stage.emote(cast.get("mastoc"), "♥")


## Watched while he speaks: Cabosse and Grognon come along the quay to the root of the pier, and look
## at him.
static func _come_for_it(cast: Dictionary) -> void:
	var b = cast.get("brac")
	if not _live(b):
		return
	var at: Vector2 = (b as Node2D).global_position
	for k in ["cabosse", "grognon"]:
		var n = cast.get(k)
		if not (_live(n) and n is DinoNpc):
			continue
		cast[k + "_depuis"] = (n as Node2D).global_position
		_walk(n, [spot(k, at)], at)


## « Il regarde le sandwich. Puis Mastoc. Puis Cabosse et Grognon. » They all look at him.
static func _looks_round(cast: Dictionary) -> void:
	var b = cast.get("brac")
	for target in [cast.get("sandwich")] + _three(cast):
		if _live(b) and _live(target):
			Stage.turn_to(b, (target as Node2D).global_position)
			await S.wait(0.6)
	for n in _three(cast):
		if _live(n) and _live(b):
			Stage.turn_to(n, (b as Node2D).global_position)


## After B2: Cabosse and Grognon go back where they were (the zone's places on the quay).
static func _back_to_quay(cast: Dictionary) -> void:
	for k in ["cabosse", "grognon"]:
		var n = cast.get(k)
		var home = cast.get(k + "_depuis")
		if _live(n) and n is DinoNpc and home is Vector2:
			_walk(n, [home])
	await S.wait(0.6)


## A dino walks through `points`; then turns to `look_px` (when given).
static func _walk(dino: DinoNpc, points: Array, look_px = null) -> void:
	for p: Vector2 in points:
		if not is_instance_valid(dino):
			return
		await dino.walk_to(p, 90.0)
	if is_instance_valid(dino) and look_px is Vector2:
		Stage.turn_to(dino, look_px)


# ------------------------------------------------------------------ on the jetty (entering Port-Ambre)

## Entering Port-Ambre (Epilogue.port): round the zone's Brac, his three and the sandwich before the
## end; after it, the sign, Mastoc by the lantern, and his night look. Nothing on the morning of the
## jetty (the epilogue's own people), nothing before he has come. Safe to call twice.
static func on_port() -> void:
	if not takes_over() or (Game.flag(&"epilogue_cabinet") and not Game.flag(&"epilogue_fini")):
		return
	var b = _alive([NODE])
	if not b is Node2D:
		return
	if Game.flag(&"epilogue_fini"):
		dress_for_time(b)
		place_after(b)
	else:
		place_before(b)


## Before the end: Mastoc standing against him, Cabosse and Grognon on the quay looking at the sea,
## the sandwich.
static func place_before(b: Node2D) -> Dictionary:
	var at := A.px_of(b)
	var cast := {"brac": b}
	for k in ["mastoc", "cabosse", "grognon"]:
		cast[k] = _beast(k, at)
	if _live(cast["mastoc"]):
		Stage.turn_to(cast["mastoc"], at)
	for k in ["cabosse", "grognon"]:
		_look_at_sea(cast[k])
	cast["sandwich"] = _thing("sandwich", SANDWICH_KINDS, at)
	return cast


## After the end: the BARC sign, the lantern with Mastoc by it (asleep by day, up by night), the
## lantern lit at night, the sandwich by day until it is shared; Cabosse and Grognon on the quay.
static func place_after(b: Node2D) -> Dictionary:
	var at := A.px_of(b)
	var cast := {"brac": b}
	cast["panneau"] = _thing("panneau", PANNEAU_KINDS, at, PANNEAU_EVENT)
	var lantern = _thing("lanterne", LANTERNE_KINDS, at)
	cast["lanterne"] = lantern
	var m = _mastoc_after(at)
	cast["mastoc"] = m
	if m and lantern is Node2D:
		Stage.turn_to(m, (lantern as Node2D).global_position)
	if is_night():
		_light(lantern)
	elif not Game.flag(&"brac_sandwich_partage"):
		cast["sandwich"] = _thing("sandwich", SANDWICH_KINDS, at)
	for k in ["cabosse", "grognon"]:
		cast[k] = _alive([ZONE_NODES[k]])
	return cast


## Mastoc after the end: the zone's (still there right after the jetty's scene) or one brought on,
## by the lantern, to be looked at (« mastoc_jetee »); lying down by day only: he sleeps.
static func _mastoc_after(at: Vector2) -> Node2D:
	var m = _alive([ZONE_NODES["mastoc"], NAMES["mastoc"]])
	if m == null:
		m = A.stand_in(SPECIES["mastoc"], at + AROUND["mastoc"] * S.CELL, NAMES["mastoc"])
		if m:
			m.modulate.a = 1.0
	if not m is DinoNpc:
		return null
	(m as Node2D).global_position = at + AROUND["mastoc"] * S.CELL
	if (m as DinoNpc).event == &"":
		(m as DinoNpc).event = &"mastoc_jetee"
		(m as Node).add_to_group(&"interactable")
	if not is_night():
		CS.crouch(m, 0.22, 0.1)
	return m


## His night watchman's look at night (when drawn: standing, the sheet brac_gardien), back on his cage
## by day.
static func dress_for_time(b) -> void:
	if not (_live(b) and b is Npc):
		return
	var npc := b as Npc
	var dressed: bool = npc.get_meta(&"base_sheet", npc.sheet) != npc.sheet
	var can: bool = Outfits.drawn(NIGHT_SHEET) and (Outfits.LOOKS.get(Outfits.person(npc), {}) as Dictionary).has(NIGHT_LOOK)
	if is_night() and not dressed and can:
		Stage.pose(npc, &"")
		Stage.dress(npc, NIGHT_LOOK)
	elif not is_night() and dressed:
		Stage.dress(npc, &"")
		Stage.pose(npc, &"assis")


# ------------------------------------------------------------------ helpers

## Steps of `lines` with their moves: a step's "cue" (a key of `cues`) becomes the move played when
## it shows (CS.cue); the key never reaches the dialogue box.
static func staged(lines: Array, cues: Dictionary) -> Array:
	var out: Array = []
	for step: Dictionary in lines:
		var plain := step.duplicate()
		var key: String = plain.get("cue", "")
		plain.erase("cue")
		out.append(CS.cue(plain, cues[key]) if cues.has(key) and plain.has("text") else plain)
	return out


## The first of `kinds` whose picture is drawn and known to Prop, "" when none.
static func thing_kind(kinds: Array) -> String:
	for k: String in kinds:
		if Prop.KINDS.has(k) and ResourceLoader.exists(Prop.ART % k):
			return k
	return ""


## Where `key` stands, Brac being at `brac_px` (px).
static func spot(key: String, brac_px: Vector2) -> Vector2:
	return brac_px + AROUND[key] * S.CELL


## A thing by Brac (already there, or shown now), to be looked at when `event` is given.
static func _thing(key: String, kinds: Array, brac_px: Vector2, event := &"") -> Node2D:
	var there = _alive([NAMES[key]])
	if there is Node2D:
		return there
	var kind := thing_kind(kinds)
	if kind == "":
		return null
	var p := Stage.show_thing(kind, spot(key, brac_px), NAMES[key])
	if p and event != &"":
		p.set("event", event)
		p.add_to_group(&"interactable")
		p.set_meta(&"reach_bonus", 12.0)
	return p


## One of his three before the end (the zone's only come for the epilogue): brought on by him, under
## the name of the epilogue's (the zone's own, gone with its show_flag, gives the name up).
static func _beast(key: String, brac_px: Vector2) -> Node2D:
	var node_name: String = ZONE_NODES[key]
	var d = _alive([node_name])
	if d is Node2D:
		return d
	var leaving = S.actor(node_name)
	if leaving is Node and is_instance_valid(leaving):
		(leaving as Node).name = node_name + "_parti"
	d = A.stand_in(SPECIES[key], spot(key, brac_px), node_name)
	if d:
		d.modulate.a = 1.0
	return d


## The lantern lit (a warm light the view turns into a lamp).
static func _light(lantern) -> void:
	if not lantern is Node2D or (lantern as Node).has_node("Lumiere"):
		return
	var glow := PointLight2D.new()
	glow.name = "Lumiere"
	glow.color = LANTERN_LIGHT
	glow.energy = 1.1
	var g := Gradient.new()
	g.set_color(0, Color(LANTERN_LIGHT, 1.0))
	g.set_color(1, Color(LANTERN_LIGHT, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	glow.texture = tex
	(lantern as Node).add_child(glow)


## A dino turned to the sea west of the pier.
static func _look_at_sea(n) -> void:
	if _live(n):
		Stage.turn_to(n, (n as Node2D).global_position + Vector2(-100.0, 0.0))


## The first of `names` in the zone that is not on its way out (a node gone with its hide_flag).
static func _alive(names: Array):
	for n: String in names:
		var a = S.actor(n)
		if a is Node and is_instance_valid(a) and not (a as Node).is_queued_for_deletion():
			return a
	return null


## Brac: the one talked to, else the zone's, else one brought on below Chloé (a test elsewhere).
static func _brac_or(who) -> Node2D:
	if _live(who):
		return who
	var b = _alive([NODE])
	if b is Node2D:
		return b
	var brought := A.person([NODE], ["brac"], A.chloe_px() + Vector2(0.0, 2.5 * S.CELL), "down", BRAC)
	if brought:
		Stage.sit(brought)
	return brought


static func _faces(who) -> void:
	if _live(who) and who is Npc and Stage.chloe():
		(who as Npc).face(Stage.chloe().global_position)


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): B1 round the zone's Brac (else one brought on), then a
## line of his pool.
static func static_avant() -> void:
	S.playing += 1
	Game.set_flag(&"brac_parti")
	var b := _brac_or(null)
	await phare(b)
	if _live(b):
		await talk(b)
	S.playing -= 1


## For the tests: after the end, by day: B2, then the three and the sign looked at.
static func static_partage() -> void:
	S.playing += 1
	for f in [&"brac_parti", &"epilogue_cabinet", &"epilogue_port", &"epilogue_fini", &"post_game"]:
		Game.set_flag(f)
	Game.clock = 11.0 * 60.0
	var b := _brac_or(null)
	var cast := place_after(b)
	await partage(b)
	await _look_at_all(cast)
	S.playing -= 1


## For the tests: after the end, at night: the watchman's look, the lantern lit, a line, Mastoc.
static func static_nuit() -> void:
	S.playing += 1
	for f in [&"brac_parti", &"epilogue_cabinet", &"epilogue_port", &"epilogue_fini", &"post_game", &"brac_sandwich_partage"]:
		Game.set_flag(f)
	Game.clock = 22.0 * 60.0
	var b := _brac_or(null)
	dress_for_time(b)
	var cast := place_after(b)
	await talk(b)
	if _live(cast.get("mastoc")):
		await beast(&"mastoc_jetee", cast.get("mastoc"))
	S.playing -= 1


static func _look_at_all(cast: Dictionary) -> void:
	for event: StringName in BEASTS:
		if _live(cast.get(BEASTS[event])):
			await beast(event, cast.get(BEASTS[event]))
	await run(PANNEAU_EVENT, cast.get("panneau") if _live(cast.get("panneau")) else null)
