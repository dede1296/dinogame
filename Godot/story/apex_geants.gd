class_name ApexGeants
## Post-game, les géants du cratère (docs/post-game-plan.md § 1, post-game-scenes.md § G) : le réveil doux de la
## page 40. Un à un, dans l'ordre 4 → 2 → 1 → 3 (les bulles comptent « Un… Quatre », G5 suit le ronfleur) :
## G1 l'œil s'ouvre à son heure (le 4 tout de suite, le 2 à la pleine lune, le 1 au crépuscule, le 3 la nuit),
## on examine le bloc (bloc) ; G2 Hélène dit avec qui s'asseoir (helene) ; G3 « S'asseoir à côté », le bon dino
## en tête (right_lead : nage, herbivore, Tranche, Résonance), à l'heure qu'elle a dite (le 1 le soir ou la nuit,
## le 3 la nuit) : un temps regardé (~25 s), cinq bulles, +1 cœur, le Dinodex (wake), le géant résident
## (on_terre) ; G4 Hélène après ; G5 et la région `apex` complète (Roc). Pas de combat, pas de capture. Les mots :
## data/dialogue_geants.gd ; la scène G3 : story/apex_geants_reveil.gd ; branché par scratchpad
## postgame/patch_A.md ; remplace actors/apex_giants.gd (ApexGiants), jamais branché. Drapeaux : FLAGS,
## plume_rendue, geants_reveilles ; objet plume_helene. En attendant le lot A' (expected_art) : STAND_INS, les
## blocs de toujours (pâlis une fois vides), pas de fougères.

const S := preload("res://story/story.gd")
const CS := preload("res://story/cote_stage.gd")
const A := preload("res://story/apex.gd")
const DG := preload("res://data/dialogue_geants.gd")

## The order they wake in (their block's number), one at a time; each one's species.
const ORDER: Array[int] = [4, 2, 1, 3]
const SPECIES := {4: &"deinocheirus", 2: &"argentinosaurus", 1: &"therizinosaurus_geant", 3: &"dacentrurus"}
## Each giant's flags, spelled out (the table's test looks for them in the code).
const FLAGS := {
	1: {"oeil": &"geant_1_oeil", "conseil": &"geant_1_conseil", "reveille": &"geant_1_reveille", "lien": &"geant_1_lien", "raconte": &"geant_1_raconte"},
	2: {"oeil": &"geant_2_oeil", "conseil": &"geant_2_conseil", "reveille": &"geant_2_reveille", "lien": &"geant_2_lien", "raconte": &"geant_2_raconte"},
	3: {"oeil": &"geant_3_oeil", "conseil": &"geant_3_conseil", "reveille": &"geant_3_reveille", "lien": &"geant_3_lien", "raconte": &"geant_3_raconte"},
	4: {"oeil": &"geant_4_oeil", "conseil": &"geant_4_conseil", "reveille": &"geant_4_reveille", "lien": &"geant_4_lien", "raconte": &"geant_4_raconte"},
}
const ALL_AWAKE := &"geants_reveilles"
## Hélène's feather, the bookmark of block 4 (« Garde-la »).
const PLUME := "plume_helene"
## « Son heure »: when its eye opens (&"": at once; the full moon; else a phase of Game.phase()).
const FULL_MOON := &"pleine_lune"
const EYE_HOURS := {4: &"", 2: FULL_MOON, 1: &"dusk", 3: &"night"}
## When Chloé may sit by it, as Hélène said ([]: any time).
const SIT_HOURS := {4: [], 2: [], 1: [&"dusk", &"night"], 3: [&"night"]}
## Who must lead (G2): an ability of Abilities.DEFS, or &"herbivore" (its head's diet, DexFacts).
const NEEDS := {4: &"nage", 2: &"herbivore", 1: &"tranche", 3: &"resonance"}
## A block's states.
const ASLEEP := &"dort"         # not its turn, or before the post-game: its chapter 9 line (Apex.bloc)
const CLOSED := &"ferme"        # its turn, its eye not open yet (not its hour)
const EYE := &"oeil"            # its eye open now, not seen yet (G1)
const TELL := &"helene"         # seen; Hélène not told yet
const NOT_NOW := &"pas_heure"   # Hélène said when, and it is not now
const READY := &"pret"          # « S'asseoir à côté »
const AWAKE := &"reveille"
## The species shown while the A' sheets are not in: a known one, its shape close.
const STAND_INS := {&"deinocheirus": &"therizinosaurus", &"argentinosaurus": &"brachiosaurus",
	&"therizinosaurus_geant": &"therizinosaurus", &"dacentrurus": &"stegosaurus"}
const STAND_IN_SIZE := 1.4
## Their size in the crater (× the species' adult size).
const SCENE_SIZE := {4: 1.3, 2: 1.5, 1: 1.3, 3: 1.4}
const DINO_ART := "res://assets/art/dinos/%s.png"
const FERN := "fougere_ambre"
const YAWN := "res://assets/audio/sfx/geant-baillement.ogg"
const STEP := "res://assets/audio/sfx/geant-pas.ogg"
const STEP_FALLBACK := "res://assets/audio/sfx/rock_heavy.wav"
const SNORE := "res://assets/audio/sfx/geant-ronfle.ogg"
const XP_WAKE := 60
## The crater's watch (s), a pulse every PULSE_EVERY watches on an open eye.
const WATCH_EVERY := 1.0
const PULSE_EVERY := 3
## The residents stroll round their block: how far (tiles), how slowly (px/s), how often (s).
const STROLL_TILES := 2.5
const STROLL_SPEED := 22.0
const STROLL_PAUSE := Vector2(5.0, 11.0)
## Where each giant stands by its block (tiles from it); the ferns round it (tiles).
const HOME := {1: Vector2(3.6, 1.4), 2: Vector2(-4.2, 1.6), 3: Vector2(-3.6, 1.4), 4: Vector2(3.0, 1.2)}
const FERNS: Array[Vector2] = [Vector2(-2.2, 1.8), Vector2(2.4, 2.6)]
## An empty block without its A' picture: dimmed, the amber gone dull.
const EMPTY_TINT := Color(0.62, 0.56, 0.5)

## The ronfleur's sitting scene has quietened him (the crater's watch leaves his snore alone): hush.
static var _hushed := false


# ------------------------------------------------------------------ the flags, the order, the hour

## What lot A' delivers (the code waits for each one, never breaks without it): the giants' sheets (profile,
## front/back, getting up), the blocks with an eye and empty, the amber fern, the feather's icon, the sounds.
static func expected_art() -> Array[String]:
	var out: Array[String] = []
	for n in ORDER:
		for suffix in ["", "_face_dos", "_leve"]:
			out.append(DINO_ART % (String(SPECIES[n]) + suffix))
	for look in ["oeil", "vide"]:
		for n in [1, 2, 3, 4]:
			out.append(Prop.ART % ("bloc_geant_%d_%s" % [n, look]))
	out.append_array([Prop.ART % FERN, ItemsDB.ICON % PLUME + ".png", YAWN, STEP, SNORE])
	return out


## A flag of giant `n` (`what`: a key of FLAGS) is set (a name counts).
static func flag(n: int, what: String) -> bool:
	if not FLAGS.has(n):
		return false
	var v: Variant = Game.flag(FLAGS[n][what])
	return (v is bool and v) or (v is String and v != "")


## The giant whose turn it is (its block), 0 before the post-game or once all four are up.
static func current() -> int:
	if not Game.flag(&"post_game"):
		return 0
	for n in ORDER:
		if not flag(n, "reveille"):
			return n
	return 0


static func all_awake() -> bool:
	return ORDER.all(func(n: int) -> bool: return flag(n, "reveille"))


## Its eye opens now (its hour: at once, the full moon, its phase).
static func eye_hour(n: int) -> bool:
	var hour: StringName = EYE_HOURS.get(n, &"")
	if hour == &"":
		return true
	if hour == FULL_MOON:
		return Game.is_full_moon()
	return Game.phase() == hour


## Chloé may sit by it now (the hour Hélène said; any when she said none).
static func sit_hour(n: int) -> bool:
	var hours: Array = SIT_HOURS.get(n, [])
	return hours.is_empty() or Game.phase() in hours


static func state(n: int) -> StringName:
	if flag(n, "reveille"):
		return AWAKE
	if current() != n:
		return ASLEEP
	if not flag(n, "oeil"):
		return EYE if eye_hour(n) else CLOSED
	if not flag(n, "conseil"):
		return TELL
	return READY if sit_hour(n) else NOT_NOW


## The block shows its open eye now (closed again out of the hour Hélène gave).
static func eye_shown(n: int) -> bool:
	var s := state(n)
	return s == EYE or s == READY or (s == TELL and sit_hour(n))


## `d` is the dino Hélène said to sit with (G2): a swimmer, a herbivore (its head), Tranche, Résonance.
static func right_lead(n: int, d: Dino) -> bool:
	if d == null:
		return false
	var need: StringName = NEEDS.get(n, &"")
	if need == &"herbivore":
		return DexFacts.INFO.get(d.part_species(&"head").id, {}).get("diet", "") == "herbivore"
	return Abilities.DEFS.has(need) and Abilities.has(d, need)


## Its species when its sheets are in (SpeciesDB, the A' picture), else its stand-in.
static func species_or(id: StringName) -> StringName:
	if SpeciesDB.PATHS.has(id) and ResourceLoader.exists(DINO_ART % id):
		return id
	return STAND_INS.get(id, &"therizinosaurus")


## The name of the dino who sat with Chloé by giant `n` (geant_<n>_lien), else the lead's.
static func lien_name(n: int) -> String:
	var said: Variant = Game.flag(FLAGS[n]["lien"]) if FLAGS.has(n) else null
	if said is String and said != "":
		return said
	var lead := Game.lead_dino()
	return lead.nickname if lead else "ton dino"


## Giant `n` gets up (G3): its flags, +1 heart for the lead (who sat with her), the Dinodex (« rencontré »),
## the feather (the 4), XP. Once. Returns the hearts gained.
static func wake(n: int) -> int:
	if not FLAGS.has(n) or flag(n, "reveille"):
		return 0
	var lead := Game.lead_dino()
	Game.set_flag(FLAGS[n]["reveille"])
	Game.set_flag(FLAGS[n]["lien"], lead.nickname if lead else "")
	var hearts := Game.add_bond(lead, 1)
	Game.mark_seen(SPECIES[n])
	if n == 4 and Game.item_count(PLUME) == 0:
		Game.give_item(PLUME)
	Game.award_team_xp(XP_WAKE)
	return hearts


# ------------------------------------------------------------------ Hélène (helene_cabinet, before her pool)

## What Hélène has to say about the giants: {"scene": &"apres" / &"conseil" / &"quatre", "n"}, {} for nothing.
static func helene_next() -> Dictionary:
	if not Game.flag(&"post_game"):
		return {}
	for n in ORDER:
		if flag(n, "reveille") and not flag(n, "raconte"):
			return {"scene": &"apres", "n": n}
	for n in ORDER:
		if flag(n, "oeil") and not flag(n, "conseil") and not flag(n, "reveille"):
			return {"scene": &"conseil", "n": n}
	if all_awake() and not Game.flag(ALL_AWAKE):
		return {"scene": &"quatre", "n": 0}
	return {}


## Her lines for `next` (helene_next): G2, G4 (followed by G5 after the fourth), or G5.
static func helene_lines(next: Dictionary) -> Array:
	var n: int = next.get("n", 0)
	match next.get("scene", &""):
		&"conseil":
			return DG.advice(n)
		&"apres":
			var lines: Array = DG.after(n, lien_name(n))
			var others_up := ORDER.all(func(m: int) -> bool: return m == n or flag(m, "reveille"))
			if others_up and flag(n, "reveille") and not Game.flag(ALL_AWAKE):
				lines.append_array(DG.four())
			return lines
		&"quatre":
			return DG.four()
	return []


## Hélène in her armchair (ApexAutour.helene): a scene of the giants when there is one. True if said.
static func helene(_who: Node) -> bool:
	var lines := helene_lines(helene_next())
	if lines.is_empty():
		return false
	await S.say(lines)
	if Game.flag(ALL_AWAKE):
		Game.mark_seen(&"souverain")   # (seen long ago: the region's count needs him)
	Save.save_game()
	return true


## Her pool (helene_cabinet_n) once the four are up: « they will wake one by one » goes, G5's line comes.
static func helene_pool(pool: Array) -> Array:
	if not Game.flag(ALL_AWAKE):
		return pool
	var out := pool.duplicate()
	out.erase(DialogueApex.HELENE_CABINET[0])
	out.append(DG.HELENE_POOL_APRES)
	return out


# ------------------------------------------------------------------ the objective (« Les géants du cratère »)

## What to do now: {text, zone, node (in that zone's scene), tile (fallback)}.
static func objective() -> Dictionary:
	for m in ORDER:
		if flag(m, "reveille") and not flag(m, "raconte"):
			return _goal(DG.obj_tell(m), A.CABINET, "Fauteuil")
	var n := current()
	if n == 0:
		return _goal(DG.obj_wait(4), A.TERRE, "BlocGeant4")
	match state(n):
		EYE:
			return _goal(DG.obj_look(n), A.TERRE, "BlocGeant%d" % n)
		TELL:
			return _goal(DG.obj_helene(n), A.CABINET, "Fauteuil")
		READY, NOT_NOW:
			return _goal(DG.obj_sit(n), A.TERRE, "BlocGeant%d" % n)
	return _goal(DG.obj_wait(n, _moon_note(n)), A.TERRE, "BlocGeant%d" % n)


static func _goal(text: String, zone: StringName, node: String) -> Dictionary:
	var tile := A.place("CABINET_HELENE")
	if zone == A.TERRE:
		var blocks := A.places("BLOCS_GEANTS")
		var i := int(node.right(1)) - 1
		tile = blocks[i] if i >= 0 and i < blocks.size() else A.place("FOND")
	return {"text": text, "zone": zone, "node": node, "tile": tile}


## « (ce soir) », « (dans 3 nuits) » for the full moon's giant, else "".
static func _moon_note(n: int) -> String:
	if EYE_HOURS.get(n, &"") != FULL_MOON:
		return ""
	var nights := Game.nights_to_full_moon()
	if nights == 0:
		return " (ce soir)"
	return " (dans %d nuit%s)" % [nights, "s" if nights > 1 else ""]


# ------------------------------------------------------------------ the blocks (events bloc_geant_1..4)

## A block of the giants examined in the post-game: G1, the thought without advice, the hour, the wrong
## dino, « S'asseoir à côté ». False when it is not the giants' business (Apex.bloc: its chapter 9 line).
static func bloc(n: int, who: Node) -> bool:
	match state(n):
		ASLEEP, CLOSED:
			return false
		AWAKE:
			_greets(n)
		EYE:
			await _eye(n, who)
		TELL:
			await S.say(DG.no_advice())
		NOT_NOW:
			CS.pulse(A.px_of(who), A.AMBER, 1, 1.0, 1.2, 3.0)
			await S.say(DG.not_now(n))
		READY:
			await _offer(n, who)
	return true


## G1 (2 lines): the eye in the amber; the ronfleur's is round the other side (Chloé walks round).
static func _eye(n: int, who: Node) -> void:
	var at := A.px_of(who, Vector2(0.0, -2.0 * S.CELL))
	var look := func() -> void:
		Stage.look_at(at.lerp(A.chloe_px(), 0.3), 0.8)
		CS.pulse(at, A.AMBER, 2, 1.4, 2.6, 5.0)
		if n == 3:
			CS.chloe_walk(S.ground_near(at + Vector2(-3.0 * S.CELL, S.CELL), 3), 90.0)
	var lines: Array = DG.eye(n)
	lines[0] = CS.cue(lines[0], look)
	await S.say(lines)
	Stage.look_back()
	Save.save_game()


## Right dino in the lead: « S'asseoir à côté » / « Pas maintenant »; the wrong one: a line, out.
static func _offer(n: int, who: Node) -> void:
	var lead := Game.lead_dino()
	if not right_lead(n, lead):
		await S.say(DG.wrong_lead(n, lead.nickname if lead else "Mon dino"))
		return
	if await Dialogue.choose("", DG.ASSEOIR_TEXTE, DG.ASSEOIR_CHOIX) != 0:
		return
	await ApexGeantsReveil.sit_scene(n, who)


## Its giant, awake, looks round from its stroll (the empty block: no line).
static func _greets(n: int) -> void:
	var g = S.actor("Geant%d" % n)
	if g:
		Stage.turn_to(g, A.chloe_px())
		Stage.cry(g, &"neutre")
	await S.wait(0.6)


# ------------------------------------------------------------------ the crater (terre_apex)

## The ronfleur's snore left alone (his sitting scene: story/apex_geants_reveil.gd), or watched again.
static func hush(on: bool) -> void:
	_hushed = on


## On entering the Terre des Apex in the post-game (Apex.on_zone): the giants up are there, strolling round
## their empty blocks; amber ferns on the veins; the blocks watched (an eye opens at its hour, the snore).
static func on_terre() -> void:
	if not Game.flag(&"post_game"):
		return
	var w = S.world()
	if w == null or w.get("region") == null or w.has_method(&"is_3d"):
		return
	_ferns()
	for n in ORDER:
		if flag(n, "reveille"):
			var g := giant(n, S.ground_near(_block_px(n) + HOME[n] * S.CELL, 3))
			if g:
				stroll(g, g.global_position)
	_watch_crater(w.region)


## Every WATCH_EVERY s while the zone is there: each block's picture (an open eye pulses), the snore.
static func _watch_crater(region: Node) -> void:
	var shown := {}
	var tick := 0
	while is_instance_valid(region) and region.is_inside_tree():
		for n in ORDER:
			var block = S.actor("BlocGeant%d" % n)
			if not block is Prop:
				continue
			var look := _look(n)
			if shown.get(n, &"?") != look:
				paint(block, n, look, shown.has(n))
				shown[n] = look
			if look == &"oeil" and tick % PULSE_EVERY == 0 and S.playing == 0:
				CS.pulse((block as Node2D).global_position + Vector2(0.0, -2.0 * S.CELL), A.AMBER, 1, 2.4, 2.2, 4.5)
		_snore(S.actor("BlocGeant3"))
		tick += 1
		await S.wait(WATCH_EVERY)


## &"vide" (awake), &"oeil" (open now), &"" (asleep).
static func _look(n: int) -> StringName:
	if flag(n, "reveille"):
		return &"vide"
	return &"oeil" if eye_shown(n) else &""


## The block's picture for `look` (bloc_geant_<n>[_oeil|_vide] when A' drew it); empty without its picture:
## dimmed (EMPTY_TINT: the 3D view cuts props out, a see-through block would not show), and no longer examined. Faded when `fade`. Awaitable.
static func paint(block: Prop, n: int, look: StringName, fade := false) -> void:
	var kind := "bloc_geant_%d" % n + ("_" + String(look) if look != &"" else "")
	if not _art(kind):
		kind = "bloc_geant_%d" % n
	if block.kind != kind:
		if fade:
			await Stage.repaint(block, kind, 1.0)
		else:
			block.kind = kind
	var empty := look == &"vide"
	block.modulate = EMPTY_TINT if empty and not _art("bloc_geant_%d_vide" % n) else Color.WHITE
	if empty and block.is_in_group(&"interactable"):
		block.remove_from_group(&"interactable")


## A prop's picture is drawn and known (Prop.KINDS + the file): never build one without it.
static func _art(kind: String) -> bool:
	return Prop.KINDS.has(kind) and ResourceLoader.exists(Prop.ART % kind)


## The block's place (px): its node, else ApexPlaces' BLOCS_GEANTS.
static func _block_px(n: int) -> Vector2:
	var block = S.actor("BlocGeant%d" % n)
	if block is Node2D:
		return (block as Node2D).global_position
	return A.spot_in("BLOCS_GEANTS", n - 1, A.chloe_px())


## The ronfleur snores in his block at night (a soft loop on the block, when A' made it).
static func _snore(block) -> void:
	var player := snore_player(block)
	if player == null or _hushed:
		return
	var on := Game.phase() == &"night" and not flag(3, "reveille") and state(3) != EYE
	if on and not player.playing:
		player.play()
	elif not on and player.playing:
		player.stop()


static func snore_player(block) -> AudioStreamPlayer2D:
	if not block is Node2D or not is_instance_valid(block) or not ResourceLoader.exists(SNORE):
		return null
	var player := (block as Node).get_node_or_null("Ronflement") as AudioStreamPlayer2D
	if player == null:
		player = AudioStreamPlayer2D.new()
		player.name = "Ronflement"
		var stream: AudioStream = load(SNORE)
		if "loop" in stream:
			stream.set("loop", true)
		player.stream = stream
		player.bus = Audio.SFX_BUS
		player.volume_db = -12.0
		player.max_distance = 700.0
		(block as Node).add_child(player)
	return player


## Giant `n`, standing (never lying: it is awake), to be talked to (event geant_<n>): its species, or
## its stand-in a little bigger; null without a world.
static func giant(n: int, at_px: Vector2) -> DinoNpc:
	var there = S.actor("Geant%d" % n)
	if there is DinoNpc:
		return there
	var id: StringName = SPECIES[n]
	var shown := species_or(id)
	var d := CS.stand_in(shown, at_px, "Geant%d" % n, 0, SCENE_SIZE[n] if shown == id else STAND_IN_SIZE, StringName("geant_%d" % n))
	if d == null:
		return null
	d.modulate.a = 1.0
	d.collision_layer = 1
	if shown != id:
		d.remove_from_group(&"dino_actor")   # (the stand-in's species is not « seen » here)
	return d


## A dull step when a giant moves off (geant-pas, else a heavy rock), heard near it only.
static func step_sound(d: Node) -> void:
	var path := STEP if ResourceLoader.exists(STEP) else STEP_FALLBACK
	if d == null or not is_instance_valid(d) or not ResourceLoader.exists(path):
		return
	var steps := d.get_node_or_null("Pas") as AudioStreamPlayer2D
	if steps == null:
		steps = AudioStreamPlayer2D.new()
		steps.name = "Pas"
		steps.stream = load(path)
		steps.bus = Audio.SFX_BUS
		steps.volume_db = -10.0
		steps.max_distance = 600.0
		d.add_child(steps)
	steps.pitch_scale = randf_range(0.8, 0.95)
	steps.play()


## A resident strolls slowly round `home`, a few steps now and then (not while a scene plays).
static func stroll(d: DinoNpc, home: Vector2) -> void:
	while is_instance_valid(d) and d.is_inside_tree():
		await S.wait(randf_range(STROLL_PAUSE.x, STROLL_PAUSE.y))
		if not is_instance_valid(d) or not d.is_inside_tree():
			return
		if S.playing > 0:
			continue
		var to := S.ground_near(home + Vector2.from_angle(randf() * TAU) * randf_range(0.6, STROLL_TILES) * S.CELL, 2)
		step_sound(d)
		await d.walk_to(to, STROLL_SPEED)


## The amber ferns on the veins, round the blocks (from the post-game on: what the giants eat).
static func _ferns() -> void:
	if not _art(FERN):
		return
	for n in ORDER:
		var at := _block_px(n)
		for i in FERNS.size():
			fern_at(S.ground_near(at + FERNS[i] * S.CELL, 2), "FougereAmbre%d_%d" % [n, i])


static func fern_at(px: Vector2, node_name: String) -> void:
	if _art(FERN):
		Stage.show_thing(FERN, px, node_name)


## A giant awake, talked to (event geant_<n>): its line, and what it says it does.
static func resident(n: int, who: Node) -> void:
	var does := func() -> void:
		Stage.turn_to(who, A.chloe_px())
		match n:
			4, 1:
				Stage.bow(who, 1.4)
			2:
				Stage.rear(who, 1.6)
			3:
				Stage.emote(who, "♪")
	await S.say([CS.cue({"text": DG.resident(n)}, does)])


# ------------------------------------------------------------------ for the tests

## For the tests (tools/capture.gd « static »): giant `n`'s loop on any zone (the ones before it up): the
## eye (G1), Hélène's advice (G2), the waking (G3, watched, the giant brought on round Chloé), Hélène after (G4).
static func static_geant(n: int) -> void:
	S.playing += 1
	Game.set_flag(&"post_game")
	for m in ORDER:
		if m == n:
			break
		wake(m)
		Game.set_flag(FLAGS[m]["raconte"])
	await S.say(DG.eye(n))
	await S.say(DG.advice(n))
	await ApexGeantsReveil.waking(n, ApexGeantsReveil.cast_for(n, null))
	await S.say(helene_lines(helene_next()))
	S.playing -= 1
