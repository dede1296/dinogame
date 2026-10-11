extends CanvasLayer
## Battle screen, shown over the paused world. `var result := await battle.run(wild)`.
## The rules are in BattleEngine; this plays its events with animations and sounds. The panels,
## the message band and the action wheel are BattleHud's.

signal _action_chosen(action: Dictionary)
signal _tapped

## The default backdrop (a zone may have its own: Region.battle_backdrop, rules "backdrop").
const BACKDROP := preload("res://assets/art/battle/plaines.jpg")
## Underground (a cave zone), the same platforms in a cave lit by amber crystals.
const CAVE_BACKDROP := preload("res://assets/art/battle/grotte.jpg")
const COLLAR := preload("res://assets/art/ui/collier.webp")
const MUSIC := preload("res://assets/audio/music/sauvage.ogg")
const VICTORY := preload("res://assets/audio/music/victoire.ogg")
const CAPTURE := preload("res://assets/audio/music/capture.ogg")
const HIT_SFX: Array[AudioStream] = [preload("res://assets/audio/sfx/hit_0.wav"), preload("res://assets/audio/sfx/hit_1.wav")]
const LATCH_SFX := preload("res://assets/audio/sfx/latch.wav")
const BREAK_SFX := preload("res://assets/audio/sfx/glass.wav")
const ITEM_SFX := preload("res://assets/audio/sfx/item.wav")
## Where the platforms are in the backdrop image (fractions of its size).
const PLAYER_SPOT := Vector2(0.3, 0.7)
const FOE_SPOT := Vector2(0.78, 0.49)
const PLAYER_SCALE := 1.2
const FOE_SCALE := 0.95
const AMBER := Color(0.98, 0.72, 0.28)
const CALM := Color(0.98, 0.84, 0.45)     # its calm gauge, golden
const BOND_PINK := Color(0.96, 0.45, 0.58)   # the Lien (hearts)
const CALM_SFX := preload("res://assets/audio/sfx/item.wav")
## La matière des deux combattants : respiration, coup encaissé, disparition, ambre noir.
const FIGHTER := preload("res://battle/fighter.gdshader")
## Un coup encaissé : trois éclats, de cette durée chacun (allumage puis retour).
const FLASH_ON := 0.05
const FLASH_OFF := 0.07
## Le ressort de la mollesse : combien il écrase/étire, la vitesse des rebonds et leur amortissement.
const JELLY_S := 0.55
const JELLY_SPEED := 22.0
const JELLY_DAMPING := 7.0
const JELLY_HIT := 0.22        # un coup encaissé : écrasé
const JELLY_LUNGE := -0.16     # un bond : étiré
const JELLY_FAINT := 0.35      # un K.O. : il s'affaisse
## Les images fantômes du bond : combien, à quel rythme, leur transparence et leur effacement.
const GHOSTS := 3
const GHOST_EVERY_S := 0.05
const GHOST_ALPHA := 0.45
const GHOST_FADE_S := 0.22
## Une disparition (K.O., rappel, capture) et une apparition.
const DISSOLVE_S := 0.5
const APPEAR_S := 0.35
## Under the sea (rule "underwater"): the water's rules and look.
const UNDERWATER_ENGINE := preload("res://battle/underwater_engine.gd")
const UNDERWATER_LOOK := preload("res://battle/battle_underwater.gd")
## In the Cieux (rule "cieux", or a battle in one of SkyEngine.ZONES): the wind's rules and look.
const SKY_ENGINE := preload("res://battle/sky_engine.gd")
const SKY_LOOK := preload("res://battle/battle_sky.gd")
const HUD := preload("res://battle/battle_hud.gd")
const AMBIENCE_IN_BATTLE_DB := -18.0   # below its normal level
const HEAL_GREEN := Color(0.55, 0.95, 0.5)

var engine: BattleEngine
var _rules := {}

var _root: Control
var _backdrop: TextureRect
var _world: Node2D
var _weather: BattleWeather
var _player_sprite: AnimatedSprite2D
var _foe_sprite: AnimatedSprite2D
var _hud: HUD
## The HUD's parts, by the names the test tools know (tools/capture.gd, tools/test_mecaniques.gd).
var _foe_panel: Dictionary
var _player_panel: Dictionary
var _message: Label
var _menu: Control          # the action wheel
var _moves_menu: Control    # the moves' list
var _calm_button: Button
var _cry: AudioStreamPlayer
var _waiting_tap := false
var _say_id := 0


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	# Warm up the particle drawing off-screen, so the first hit does not stutter.
	_burst(Vector2(-4000, -4000), Color(1, 1, 1, 0.01), 1, 1.0)


## Plays a whole wild battle. Returns "win", "lose", "run", "catch" or "calmed" (a corrupted
## dino, Dino.corrupted, calmed with Apaiser).
## `rules`: {"catch": false, "run": false} for a battle of honour (an Alpha), "intro": its
## first line, "music": its theme, "lesson": lines said after the intro (how to calm it),
## "cave": true underground (the cave backdrop, no sky), "backdrop": the picture behind the
## fighters (a Texture2D: the region's own, Region.battle_backdrop; the default: the meadow),
## "long_calm": true for a deep corruption (a calm gauge twice as long; Chloé's own hatchling
## helps calm it, see BattleEngine), "size": the foe's size, share of its species' adult (a dino
## of the story shown bigger or smaller in the world, DinoNpc.size_scale; else its level's),
## "underwater": true under the sea (UnderwaterEngine, BattleUnderwater), "abyss": true the
## Mosasaure Abyssal's rhythm (it sinks into the dark, surges, stays exposed), "cieux": true (or
## false) in the wind of the Cieux — by default, any battle in one of their zones (SkyEngine,
## BattleSky: Wind stronger, Earth weaker, the pterosaurs hovering).
func run(wild: Dino, rules := {}) -> String:
	_rules = rules
	if rules.get("backdrop") is Texture2D:
		_backdrop.texture = rules["backdrop"]
	if rules.get("cave", false):
		_go_underground()
	var starter = Game.flag(&"starter")
	var engine_rules := {
		"long_calm": rules.get("long_calm", false),
		"starter": StringName(starter) if starter is String else &"",
		"trainer": rules.get("trainer", ""),
		"abyss": rules.get("abyss", false),
	}
	if rules.get("underwater", false):   # under the sea: the water's rules, the water all around
		engine = UNDERWATER_ENGINE.new(Game.party, wild, engine_rules)
		UNDERWATER_LOOK.apply(self)
	elif SKY_ENGINE.applies(rules, Game.region_id):   # in the Cieux: the wind's rules, the flyers hovering
		engine = SKY_ENGINE.new(Game.party, wild, engine_rules)
		SKY_LOOK.apply(self)
	else:
		engine = BattleEngine.new(Game.party, wild, engine_rules)
	Game.mark_seen(wild.species().id)
	_setup_dino(_foe_sprite, wild, true)
	_setup_dino(_player_sprite, engine.player(), false)
	_hud.bind(engine, _rules)
	_layout()
	Audio.push_music(_rules.get("music", MUSIC), 0.15)
	Audio.fade_ambience(AMBIENCE_IN_BATTLE_DB)
	await _intro()
	for line: String in _rules.get("lesson", []):
		await _say(line)
	while not engine.over:
		var action := await _choose_action()
		await _play(engine.turn(action))
	return engine.result


# ------------------------------------------------------------------ intro / menus

func _intro() -> void:
	_player_panel["box"].modulate.a = 0.0
	_foe_panel["box"].modulate.a = 0.0
	var foe_home := _foe_sprite.position
	var player_home := _player_sprite.position
	_foe_sprite.position.x += 700
	_player_sprite.position.x -= 700
	_root.modulate.a = 0.0
	await create_tween().tween_property(_root, "modulate:a", 1.0, 0.35).finished
	var t := create_tween().set_parallel(true)
	t.tween_property(_foe_sprite, "position", foe_home, 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await t.finished
	_cry_of(engine.foe, "neutre")
	create_tween().tween_property(_foe_panel["box"], "modulate:a", 1.0, 0.3)
	await _say(_rules.get("intro", "Un %s sauvage apparaît !" % engine.foe.species_name()))
	var t2 := create_tween()
	t2.tween_property(_player_sprite, "position", player_home, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t2.finished
	_cry_of(engine.player(), "neutre")
	create_tween().tween_property(_player_panel["box"], "modulate:a", 1.0, 0.3)
	await _say("Vas-y, %s !" % engine.player().nickname)


## The player's choice. After a knock-out (BattleEngine.must_switch): who takes over, from the
## party's list, without Retour.
func _choose_action() -> Dictionary:
	if engine.must_switch:
		_hud.say("%s ne peut plus se battre. Qui prend le relais ?" % engine.player().nickname)
		_hud.show_panel("relief")
	else:
		_hud.say("Que doit faire %s ?" % engine.player().nickname)
		_show_menu(_menu)
	var action: Dictionary = await _action_chosen
	_show_menu(null)
	return action


## The wheel (`_menu`), a list (`_moves_menu`, or the HUD's bag_panel, team_panel), or nothing.
func _show_menu(menu: Control) -> void:
	var names := {_menu: "wheel", _moves_menu: "moves", _hud.bag_panel: "bag", _hud.team_panel: "team"}
	_hud.show_panel(names.get(menu, ""))


func _input(event: InputEvent) -> void:
	if not _waiting_tap:
		return
	if event.is_action_pressed(&"interact") or (event is InputEventScreenTouch and event.pressed):
		get_viewport().set_input_as_handled()
		_tapped.emit()


## Shows a line; continues on a tap or after a reading delay.
func _say(text: String) -> void:
	_hud.say(text, true)
	_waiting_tap = true
	_say_id += 1
	var my_id := _say_id
	var timer := get_tree().create_timer(0.9 + text.length() * 0.028)
	timer.timeout.connect(func() -> void:
		if my_id == _say_id and _waiting_tap:
			_tapped.emit())
	await _tapped
	_waiting_tap = false
	_hud.stop_waiting()


# ------------------------------------------------------------------ events

func _play(events: Array) -> void:
	for e: Dictionary in events:
		match e["type"]:
			"move":
				_hud.say(e["text"])
				await _attack_anim(e["side"], e.get("fx", "charge"), e.get("move_type", "neutre"))
			"damage":
				await _hit(e)
				if e.has("text"):
					await _say(e["text"])
			"miss":
				await _dodge(e["side"])
				await _say(e["text"])
			"heal":
				if e.get("dino", engine.dino(e["side"])) == engine.dino(e["side"]):
					var panel := _player_panel if e["side"] == "player" else _foe_panel
					await _tween_hp(panel, e["hp"], e["max_hp"])
					_refresh_panel(panel, engine.dino(e["side"]))   # (an item: its Lien may have grown)
				else:   # an item for a dino of the party that waits beside Chloé
					_float_number(_player_panel["box"].position + Vector2(40, -30), "+%d PV" % e["amount"], HEAL_GREEN)
				await _say(e["text"])
			"stat":
				_stat_particles(e["side"], e["delta"] > 0)
				await _say(e["text"])
			"status":
				_refresh_panel(_player_panel if e["side"] == "player" else _foe_panel, engine.dino(e["side"]))
				if e.has("text"):
					await _say(e["text"])
			"faint":
				await _faint(e["side"])
				await _say(e["text"])
			"item":   # Chloé gives it to a dino of the party ("heal" follows)
				_hud.say(e["text"])
				await _item_anim(e["id"], e.get("dino", engine.player()) == engine.player())
			"recall":   # it comes back to Chloé ("switch" follows)
				_hud.say(e["text"])
				await _recall()
			"switch":
				await _switch_in()
				await _say(e["text"])
			"catch":
				await _say(e["text"])
				await _catch_anim(e["shakes"], e["success"])
			"calm":
				await _calm_anim(e["calm"])
				await _say(e["text"])
			"calmed":
				await _calmed_anim()
				await _say(e["text"])
			"abyss":   # under the sea, the Mosasaure sinks into the dark, surges, is exposed
				await UNDERWATER_LOOK.abyss(self, e)
				await _say(e["text"])
			"bond_hold":   # a full Lien: it holds on at 1 PV
				_refresh_panel(_player_panel, engine.player())
				_burst(_player_sprite.position + Vector2(0, -60), BOND_PINK, 26, 200.0)
				_float_number(_player_sprite.position + Vector2(0, -150), "♥", BOND_PINK)
				await _say(e["text"])
			"bond":
				if e["dino"] == engine.player():
					_burst(_player_sprite.position + Vector2(0, -60), BOND_PINK, 20, 160.0)
				await _say(e["text"])
			"xp":
				if e["dino"] == engine.player():
					await _tween_xp(e["dino"])
				await _say(e["text"])
			"level":
				if e["dino"] == engine.player():
					_refresh_panel(_player_panel, engine.player())
					Audio.play_sfx(ITEM_SFX)
				await _say(e["text"])
			"run":
				await _say(e["text"])
			"end":
				await _outro(e["result"])
			_:
				if e.has("text"):
					await _say(e["text"])


func _sprite(side: String) -> AnimatedSprite2D:
	return _player_sprite if side == "player" else _foe_sprite


func _attack_anim(side: String, fx: String, move_type: String) -> void:
	var s := _sprite(side)
	var target := _sprite("foe" if side == "player" else "player")
	_cry_of(engine.dino(side), "attaque")
	if fx == "roar" or fx == "shield":
		var t := create_tween()
		t.tween_property(s, "scale", s.scale * 1.12, 0.12)
		t.tween_property(s, "scale", s.scale, 0.2)
		_burst(s.position + Vector2(0, -60), MovesDB.TYPE_COLORS[move_type], 20, 160.0)
		await t.finished
		await get_tree().create_timer(0.25).timeout
		return
	s.play(&"attack")
	var home := s.position
	var lunge := home.lerp(target.position, 0.35 if fx == "charge" else 0.22)
	var t2 := create_tween()
	t2.tween_property(s, "position", lunge, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t2.tween_property(s, "position", home, 0.28).set_trans(Tween.TRANS_SINE)
	_ghosts(s, MovesDB.TYPE_COLORS.get(move_type, Color.WHITE))
	_jelly(s, JELLY_LUNGE)
	await t2.finished
	s.play(&"idle")


## Des images fantômes derrière le bond : elles disent la vitesse là où le sprite, dessiné en
## trois images, ne peut pas la dire. Posées une par une pendant l'élan, elles s'effacent seules.
func _ghosts(s: AnimatedSprite2D, tint: Color) -> void:
	for i in GHOSTS:
		if not is_instance_valid(s):
			return
		var frame := s.sprite_frames.get_frame_texture(s.animation, s.frame)
		if frame == null:
			return
		var ghost := Sprite2D.new()
		ghost.texture = frame
		ghost.position = s.position
		ghost.scale = s.scale
		ghost.offset = s.offset
		ghost.modulate = Color(tint.lightened(0.3), GHOST_ALPHA)
		ghost.show_behind_parent = true
		_world.add_child(ghost)
		_world.move_child(ghost, 0)
		var fade := create_tween()
		fade.tween_property(ghost, "modulate:a", 0.0, GHOST_FADE_S)
		fade.tween_callback(ghost.queue_free)
		await get_tree().create_timer(GHOST_EVERY_S).timeout


func _hit(e: Dictionary) -> void:
	var side: String = e["side"]
	var s := _sprite(side)
	var panel := _player_panel if side == "player" else _foe_panel
	if not e.get("bleed", false):
		Audio.play_sfx(HIT_SFX.pick_random(), 0.0, 0.08)
		_burst(s.position + Vector2(0, -50), MovesDB.TYPE_COLORS.get(e.get("move_type", "neutre"), Color.WHITE), 26, 260.0)
		if e.get("crit", false) or e.get("eff", 1.0) > 1.0:
			_shake(10.0, 0.3)
	_cry_of(engine.dino(side), "degat")
	_float_number(s.position + Vector2(0, -130), "-%d" % e["amount"], Color(1, 0.9, 0.8) if not e.get("crit", false) else AMBER)
	# Il vire vers la couleur du type de l'attaque, puis il est secoué de côté.
	var tint: Color = MovesDB.TYPE_COLORS.get(e.get("move_type", "neutre"), Color.WHITE)
	# Un éclat blanc franc : un blanc « teinté du type » se confondait avec la peau des dinos de la
	# même couleur (essayé sur un Protoceratops de type terre). Le type, lui, se lit dans les étincelles.
	_skin(s).set_shader_parameter("flash_color", Color.WHITE.lerp(tint, 0.08))
	_jelly(s, JELLY_HIT * (1.4 if e.get("crit", false) else 1.0))
	var t := create_tween()
	for i in 3:
		t.tween_method(_flash.bind(s), 0.0, 1.0, FLASH_ON)
		t.tween_method(_flash.bind(s), 1.0, 0.0, FLASH_OFF)
	var home := s.position
	var t2 := create_tween()
	for i in 4:
		t2.tween_property(s, "position:x", home.x + (10.0 if i % 2 == 0 else -10.0), 0.04)
	t2.tween_property(s, "position:x", home.x, 0.04)
	await _tween_hp(panel, e["hp"], e["max_hp"])


## Un ressort : le combattant est écrasé (`amplitude` > 0) ou étiré (< 0) d'un coup, puis revient
## en rebondissant, de moins en moins fort (battle/fighter.gdshader, uniform « squash »).
func _jelly(s: AnimatedSprite2D, amplitude: float) -> void:
	var material := _skin(s)
	var spring := create_tween()
	spring.tween_method(func(t: float) -> void:
		if is_instance_valid(s):
			material.set_shader_parameter("squash", amplitude * exp(-JELLY_DAMPING * t) * cos(JELLY_SPEED * t)),
		0.0, JELLY_S, JELLY_S)


## La matière d'un combattant (battle/fighter.gdshader).
func _skin(s: AnimatedSprite2D) -> ShaderMaterial:
	return s.material as ShaderMaterial


## Combien il vire vers la couleur du coup (0 à 1).
func _flash(value: float, s: AnimatedSprite2D) -> void:
	_skin(s).set_shader_parameter("flash", value)


## Combien sa peinture est consumée (0 entier, 1 disparu).
func _dissolve(value: float, s: AnimatedSprite2D) -> void:
	_skin(s).set_shader_parameter("dissolve", value)


func _dodge(attacker_side: String) -> void:
	var s := _sprite("foe" if attacker_side == "player" else "player")
	var home := s.position
	var t := create_tween()
	t.tween_property(s, "position:x", home.x + 40, 0.12).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "position:x", home.x, 0.2).set_trans(Tween.TRANS_SINE)
	await t.finished


func _faint(side: String) -> void:
	var s := _sprite(side)
	_cry_of(engine.dino(side), "ko")
	var t := create_tween().set_parallel(true)
	t.tween_property(s, "position:y", s.position.y + 60, DISSOLVE_S).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_method(_dissolve.bind(s), 0.0, 1.0, DISSOLVE_S)
	_jelly(s, JELLY_FAINT)
	t.tween_property(s, "modulate:a", 0.0, DISSOLVE_S)   # (son ombre, qui suit le modulate)
	await t.finished


func _switch_in() -> void:
	_setup_dino(_player_sprite, engine.player(), false)
	_refresh_panel(_player_panel, engine.player())
	_layout()
	_player_sprite.modulate.a = 0.0
	_dissolve(1.0, _player_sprite)
	var t := create_tween().set_parallel(true)
	t.tween_property(_player_sprite, "modulate:a", 1.0, APPEAR_S)
	t.tween_method(_dissolve.bind(_player_sprite), 1.0, 0.0, APPEAR_S)
	await t.finished
	_cry_of(engine.player(), "neutre")


## Called back, the dino in battle turns to light and shrinks away towards Chloé (off the left).
func _recall() -> void:
	var s := _player_sprite
	var t := create_tween().set_parallel(true)
	t.tween_property(s, "modulate", Color(2.2, 1.8, 1.2, 0.0), 0.4)
	t.tween_method(_dissolve.bind(s), 0.0, 1.0, 0.4)
	t.tween_property(s, "scale", s.scale * 0.35, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(s, "position:x", s.position.x - 120.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished


## The item (its picture) is tossed from Chloé's side to the dino in battle (`on_field`), then
## sparkles; for one waiting beside Chloé, it only rises and sparkles over her side of the screen.
func _item_anim(id: String, on_field := true) -> void:
	var item := Sprite2D.new()
	item.texture = ItemsDB.icon(id)
	item.scale = Vector2(0.45, 0.45)
	var start := Vector2(-40.0, _player_sprite.position.y - 40.0)
	var target := _player_sprite.position + Vector2(0, -90) if on_field else Vector2(150.0, _player_sprite.position.y - 150.0)
	item.position = start
	_world.add_child(item)
	var arc := create_tween()
	arc.tween_method(func(k: float) -> void:
		item.position = start.lerp(target, k) + Vector2(0, -120 * sin(k * PI))
		item.rotation = k * TAU, 0.0, 1.0, 0.5)
	await arc.finished
	Audio.play_sfx(ITEM_SFX)
	item.queue_free()
	_burst(target, HEAL_GREEN, 26, 200.0)
	if on_field:
		_stat_particles("player", true, HEAL_GREEN)
	await get_tree().create_timer(0.25).timeout


## The amber collar flies to the wild dino, draws it in, falls and wobbles `shakes` times.
func _catch_anim(shakes: int, success: bool) -> void:
	var collar := Sprite2D.new()
	collar.texture = COLLAR
	collar.scale = Vector2(0.5, 0.5)
	var start := _player_sprite.position + Vector2(40, -120)
	var target := _foe_sprite.position + Vector2(0, -70)
	collar.position = start
	_world.add_child(collar)
	var arc := create_tween()
	arc.tween_method(func(k: float) -> void:
		collar.position = start.lerp(target, k) + Vector2(0, -160 * sin(k * PI))
		collar.rotation = k * TAU * 1.5, 0.0, 1.0, 0.55)
	await arc.finished
	Audio.play_sfx(ITEM_SFX)
	_burst(target, AMBER, 30, 220.0)
	var suck := create_tween().set_parallel(true)
	suck.tween_property(_foe_sprite, "modulate", Color(2.2, 1.6, 0.6, 0.0), 0.35)
	suck.tween_method(_dissolve.bind(_foe_sprite), 0.0, 1.0, 0.35)
	suck.tween_property(_foe_sprite, "scale", _foe_sprite.scale * 0.2, 0.35)
	await suck.finished
	var ground := _foe_sprite.position + Vector2(0, -20)
	var fall := create_tween()
	fall.tween_property(collar, "position", ground, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	fall.parallel().tween_property(collar, "rotation", 0.0, 0.3)
	await fall.finished
	for i in shakes:
		await get_tree().create_timer(0.35).timeout
		Audio.play_sfx(LATCH_SFX, -2.0, 0.05)
		var wob := create_tween()
		wob.tween_property(collar, "rotation", 0.35, 0.1)
		wob.tween_property(collar, "rotation", -0.35, 0.14)
		wob.tween_property(collar, "rotation", 0.0, 0.1)
		await wob.finished
	await get_tree().create_timer(0.4).timeout
	if success:
		_burst(ground, AMBER, 40, 300.0)
		_burst(ground, Color(1, 1, 0.85), 20, 180.0)
		Audio.play_jingle(CAPTURE)
		await get_tree().create_timer(0.6).timeout
		return
	Audio.play_sfx(BREAK_SFX)
	_burst(ground, AMBER, 24, 260.0)
	collar.queue_free()
	var back := create_tween().set_parallel(true)
	back.tween_property(_foe_sprite, "modulate", Color.WHITE, 0.3)
	back.tween_property(_foe_sprite, "scale", Vector2(-1.0, 1.0) * _size(engine.foe, true), 0.3)
	await back.finished
	_cry_of(engine.foe, "neutre")


func _outro(result: String) -> void:
	match result:
		"win":
			Audio.play_jingle(VICTORY)
			await get_tree().create_timer(1.2).timeout
		"catch":
			await _say("%s rejoint ton équipe !" % engine.foe.species_name() if Game.party.size() < Game.PARTY_MAX else
				"%s est envoyé au Cabinet." % engine.foe.species_name())
		"calmed":
			Audio.play_jingle(VICTORY)
			await get_tree().create_timer(1.2).timeout
		"lose":
			await get_tree().create_timer(0.6).timeout
	await create_tween().tween_property(_root, "modulate:a", 0.0, 0.4).finished


## In a cave: its backdrop (unless the zone has its own), and no hour nor weather (no sky
## down there).
func _go_underground() -> void:
	if not _rules.get("backdrop") is Texture2D:
		_backdrop.texture = CAVE_BACKDROP
	_backdrop.modulate = Color.WHITE
	_world.modulate = Color.WHITE
	if _weather:
		_weather.queue_free()
		_weather = null


# ------------------------------------------------------------------ calming a corrupted dino

## The calm gauge fills (or empties): golden sparkles around the foe when it rises.
func _calm_anim(calm: int) -> void:
	var rising: bool = calm > _foe_panel["calm"].value
	if rising:
		Audio.play_sfx(CALM_SFX, -4.0, 0.1)
		_burst(_foe_sprite.position + Vector2(0, -70), CALM, 18, 120.0)
	await _hud.tween_calm(calm)


## The veins fade: a white flash, its own colours come back, a burst of gold.
func _calmed_anim() -> void:
	var t := create_tween()
	t.tween_property(_foe_sprite, "modulate", Color(3, 3, 3), 0.3)
	await t.finished
	_setup_dino(_foe_sprite, engine.foe, true)
	_foe_sprite.modulate = Color(3, 3, 3)
	_burst(_foe_sprite.position + Vector2(0, -60), CALM, 40, 260.0)
	_burst(_foe_sprite.position + Vector2(0, -60), Color(1, 1, 0.9), 20, 160.0)
	await create_tween().tween_property(_foe_sprite, "modulate", Color.WHITE, 0.8).finished
	_refresh_panel(_foe_panel, engine.foe)
	_cry_of(engine.foe, "neutre")


# ------------------------------------------------------------------ effects

func _burst(pos: Vector2, color: Color, amount: int, speed: float) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = Quality.scaled(amount)
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.7
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 300)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 8.0
	p.color = color
	var fade := Gradient.new()
	fade.set_color(0, color)
	fade.set_color(1, Color(color, 0.0))
	p.color_ramp = fade
	_world.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _stat_particles(side: String, up: bool, tint := Color(0, 0, 0, 0)) -> void:
	var s := _sprite(side)
	var p := CPUParticles2D.new()
	p.position = s.position + Vector2(0, -40)
	p.amount = Quality.scaled(18)
	p.one_shot = true
	p.lifetime = 0.8
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(60, 30)
	p.direction = Vector2.UP if up else Vector2.DOWN
	p.spread = 5.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 140.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 6.0
	p.color = tint if tint.a > 0.0 else Color(1.0, 0.55, 0.3) if up else Color(0.45, 0.65, 1.0)
	_world.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _float_number(pos: Vector2, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.03))
	l.add_theme_constant_override("outline_size", 8)
	l.position = pos - Vector2(30, 0)
	_root.add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", pos.y - 50, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.45)
	t.chain().tween_callback(l.queue_free)


func _shake(strength: float, duration: float) -> void:
	var t := create_tween()
	var steps := int(duration / 0.04)
	for i in steps:
		t.tween_property(_world, "position", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength, 0.04)
	t.tween_property(_world, "position", Vector2.ZERO, 0.04)


func _cry_of(d: Dino, kind: String) -> void:
	var stream := d.species().cry(kind)
	if stream:
		_cry.stream = stream
		_cry.pitch_scale = randf_range(0.97, 1.05)
		_cry.play()


# ------------------------------------------------------------------ panels (BattleHud)

func _refresh_panel(panel: Dictionary, d: Dino) -> void:
	_hud.refresh(panel, d)


func _tween_hp(panel: Dictionary, hp: int, max_hp: int) -> void:
	await _hud.tween_hp(panel, hp, max_hp)


func _tween_xp(d: Dino) -> void:
	await _hud.tween_xp(d)


# ------------------------------------------------------------------ building

func _setup_dino(s: AnimatedSprite2D, d: Dino, is_foe: bool) -> void:
	var species := d.species()
	s.sprite_frames = SheetFrames.dino(species, d.corrupted)
	var k := _size(d, is_foe)
	s.scale = Vector2(-k if is_foe else k, k)
	var h := species.sheet.get_height() / float(species.sheet_rows)
	s.offset = Vector2(0, -h * 0.46)
	s.modulate = Color.WHITE
	_dissolve(0.0, s)
	_flash(0.0, s)
	_skin(s).set_shader_parameter("squash", 0.0)
	_skin(s).set_shader_parameter("body_height", h * 0.9)
	# Les cinq espèces qui ont leur planche corrompue la montrent ; les autres passent par le shader.
	_skin(s).set_shader_parameter("corruption",
		1.0 if d.corrupted and not SheetFrames.has_corrupted(species) else 0.0)
	s.play(&"idle")


## The sprite scale of `d` on its platform: its species' battle size (DinoSpecies.battle_scale),
## a young one smaller as in the world (the foe: as the rule "size" says, if any), softened the
## same way (the square root of its size in the world).
func _size(d: Dino, is_foe: bool) -> float:
	var species := d.species()
	var size := DinoSize.growth(species, d.level)
	if is_foe and _rules.has("size"):
		size = float(_rules["size"])
	return (FOE_SCALE if is_foe else PLAYER_SCALE) * species.battle_scale / 0.5 * sqrt(size)


## Places the sprites on the backdrop's platforms, whatever the screen's shape.
func _layout() -> void:
	if _backdrop == null:
		return
	var view := get_viewport().get_visible_rect().size
	var tex := Vector2(_backdrop.texture.get_size())
	var cover := maxf(view.x / tex.x, view.y / tex.y)
	var shown := tex * cover
	var origin := (view - shown) / 2.0
	_player_sprite.position = origin + PLAYER_SPOT * shown
	_foe_sprite.position = origin + FOE_SPOT * shown


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_backdrop = TextureRect.new()
	_backdrop.texture = BACKDROP
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_backdrop)

	_world = Node2D.new()
	_root.add_child(_world)
	for is_foe in [true, false]:
		var s := AnimatedSprite2D.new()
		var shadow := Sprite2D.new()
		shadow.texture = Shadow.texture()
		shadow.scale = Vector2(3.4, 1.1) if is_foe else Vector2(3.8, 1.25)
		shadow.show_behind_parent = true
		s.add_child(shadow)
		var skin := ShaderMaterial.new()
		skin.shader = FIGHTER
		skin.set_shader_parameter("amount", SpriteMotion.BREATH)
		skin.set_shader_parameter("period", SpriteMotion.BREATH_S)
		skin.set_shader_parameter("phase", PI if is_foe else 0.0)
		s.material = skin
		_world.add_child(s)
		if is_foe:
			_foe_sprite = s
		else:
			_player_sprite = s
	# Same sky as the exploration: hour and weather.
	_weather = BattleWeather.apply(_root, _backdrop, _world)

	_cry = AudioStreamPlayer.new()
	_cry.bus = Audio.CRIES_BUS
	add_child(_cry)

	# The panels, the message band and the action wheel, over the fighters and the weather.
	_hud = HUD.new()
	_root.add_child(_hud)
	_hud.chosen.connect(func(action: Dictionary) -> void: _action_chosen.emit(action))
	_foe_panel = _hud.foe
	_player_panel = _hud.mine
	_message = _hud.message
	_menu = _hud.wheel
	_moves_menu = _hud.moves_panel
	_calm_button = _hud.calm_button
