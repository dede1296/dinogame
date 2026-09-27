extends CanvasLayer
## Battle screen, shown over the paused world. `var result := await battle.run(wild)`.
## The rules are in BattleEngine; this plays its events with animations and sounds.

signal _action_chosen(action: Dictionary)
signal _tapped

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
const VIOLET := Color(0.62, 0.34, 0.95)   # black amber: a corrupted dino, the Apaiser action
const CALM := Color(0.98, 0.84, 0.45)     # its calm gauge, golden
const CALM_SFX := preload("res://assets/audio/sfx/item.wav")
const BREATHE := preload("res://battle/breathe.gdshader")
const AMBIENCE_IN_BATTLE_DB := -18.0   # below its normal level
const PANEL_BG := Color(0.09, 0.1, 0.13, 0.84)
const CARD_BG := Color(0.14, 0.16, 0.2, 0.94)
const CREAM := Color(0.97, 0.94, 0.87)
const MUTED := Color(0.97, 0.94, 0.87, 0.62)
const MENU_BUTTON := Vector2(150, 54)
const MOVE_CARD := Vector2(236, 60)
const MENU_WIDTH := 482.0   # the moves grid: two cards and a gap
const EDGE := 16.0

var engine: BattleEngine
var _rules := {}

var _root: Control
var _backdrop: TextureRect
var _world: Node2D
var _weather: BattleWeather
var _player_sprite: AnimatedSprite2D
var _foe_sprite: AnimatedSprite2D
var _foe_panel: Dictionary
var _player_panel: Dictionary
var _message: Label
var _menu: HBoxContainer
var _collar_button: Button
var _calm_button: Button
var _run_button: Button
var _moves_menu: VBoxContainer
var _moves_grid: GridContainer
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
## "cave": true underground (the cave backdrop, no sky).
func run(wild: Dino, rules := {}) -> String:
	_rules = rules
	if rules.get("cave", false):
		_go_underground()
	engine = BattleEngine.new(Game.party, wild)
	Game.mark_seen(wild.species().id)
	_setup_dino(_foe_sprite, wild, true)
	_setup_dino(_player_sprite, engine.player(), false)
	(_foe_panel["calm"] as ProgressBar).value = 0.0
	_refresh_panel(_foe_panel, wild)
	_refresh_panel(_player_panel, engine.player())
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


func _choose_action() -> Dictionary:
	_message.text = "Que doit faire %s ?" % engine.player().nickname
	_show_menu(_menu)
	var action: Dictionary = await _action_chosen
	_show_menu(null)
	return action


func _show_menu(menu: Control) -> void:
	_menu.visible = menu == _menu
	_moves_menu.visible = menu == _moves_menu
	if menu == _menu:
		var corrupted := engine.foe.corrupted
		_collar_button.text = "Collier ×%d" % Game.item_count("collier")
		_collar_button.disabled = Game.item_count("collier") <= 0
		_collar_button.visible = _rules.get("catch", true) and not corrupted
		_calm_button.visible = corrupted
		_run_button.visible = _rules.get("run", true)
		(_calm_button if corrupted else _menu.get_child(0) as Button).grab_focus()
	elif menu == _moves_menu:
		_fill_moves()
		_moves_grid.get_child(0).grab_focus()


## One card per move (2 × 2 at most): name, type, power points, the type's colour on the side.
func _fill_moves() -> void:
	for child in _moves_grid.get_children():
		_moves_grid.remove_child(child)
		child.queue_free()
	var d := engine.player()
	for i in d.moves.size():
		var slot: Dictionary = d.moves[i]
		var move := MovesDB.move(slot["id"])
		var card := _move_card(move["name"], "%s · PP %d/%d" % [MovesDB.TYPE_NAMES[move["type"]], slot["pp"], move["pp"]],
			MovesDB.TYPE_COLORS[move["type"]])
		card.disabled = slot["pp"] <= 0
		card.modulate.a = 0.45 if card.disabled else 1.0
		card.pressed.connect(func() -> void: _action_chosen.emit({"type": "move", "index": i}))
		_moves_grid.add_child(card)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel") and _moves_menu.visible:
		_show_menu(_menu)
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not _waiting_tap:
		return
	if event.is_action_pressed(&"interact") or (event is InputEventScreenTouch and event.pressed):
		get_viewport().set_input_as_handled()
		_tapped.emit()


## Shows a line; continues on a tap or after a reading delay.
func _say(text: String) -> void:
	_message.text = text
	_waiting_tap = true
	_say_id += 1
	var my_id := _say_id
	var timer := get_tree().create_timer(0.9 + text.length() * 0.028)
	timer.timeout.connect(func() -> void:
		if my_id == _say_id and _waiting_tap:
			_tapped.emit())
	await _tapped
	_waiting_tap = false


# ------------------------------------------------------------------ events

func _play(events: Array) -> void:
	for e: Dictionary in events:
		match e["type"]:
			"move":
				_message.text = e["text"]
				await _attack_anim(e["side"], e.get("fx", "charge"), e.get("move_type", "neutre"))
			"damage":
				await _hit(e)
				if e.has("text"):
					await _say(e["text"])
			"miss":
				await _dodge(e["side"])
				await _say(e["text"])
			"heal":
				var panel := _player_panel if e["side"] == "player" else _foe_panel
				await _tween_hp(panel, e["hp"], e["max_hp"])
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
	await t2.finished
	s.play(&"idle")


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
	# Flash white, then shake sideways.
	var t := create_tween()
	for i in 3:
		t.tween_property(s, "modulate", Color(3, 3, 3), 0.05)
		t.tween_property(s, "modulate", Color.WHITE, 0.07)
	var home := s.position
	var t2 := create_tween()
	for i in 4:
		t2.tween_property(s, "position:x", home.x + (10.0 if i % 2 == 0 else -10.0), 0.04)
	t2.tween_property(s, "position:x", home.x, 0.04)
	await _tween_hp(panel, e["hp"], e["max_hp"])


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
	t.tween_property(s, "position:y", s.position.y + 60, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(s, "modulate:a", 0.0, 0.5)
	await t.finished


func _switch_in() -> void:
	_setup_dino(_player_sprite, engine.player(), false)
	_refresh_panel(_player_panel, engine.player())
	_layout()
	_player_sprite.modulate.a = 0.0
	await create_tween().tween_property(_player_sprite, "modulate:a", 1.0, 0.3).finished
	_cry_of(engine.player(), "neutre")


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
	back.tween_property(_foe_sprite, "scale", Vector2(-FOE_SCALE, FOE_SCALE) * engine.foe.species().world_scale / 0.5, 0.3)
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


## In a cave: its backdrop, and no hour nor weather (no sky down there).
func _go_underground() -> void:
	_backdrop.texture = CAVE_BACKDROP
	_backdrop.modulate = Color.WHITE
	_world.modulate = Color.WHITE
	if _weather:
		_weather.queue_free()
		_weather = null


# ------------------------------------------------------------------ calming a corrupted dino

## The calm gauge fills (or empties): golden sparkles around the foe when it rises.
func _calm_anim(calm: int) -> void:
	var bar: ProgressBar = _foe_panel["calm"]
	var rising := calm > bar.value
	if rising:
		Audio.play_sfx(CALM_SFX, -4.0, 0.1)
		_burst(_foe_sprite.position + Vector2(0, -70), CALM, 18, 120.0)
	await create_tween().tween_property(bar, "value", float(calm), 0.45).finished


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


func _stat_particles(side: String, up: bool) -> void:
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
	p.color = Color(1.0, 0.55, 0.3) if up else Color(0.45, 0.65, 1.0)
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


# ------------------------------------------------------------------ panels

func _refresh_panel(panel: Dictionary, d: Dino) -> void:
	var status: String = {"saigne": "  · saigne", "etourdi": "  · étourdi", "peur": "  · a peur"}.get(d.status, "")
	if d.corrupted:
		status = "  · corrompu"
	if panel.has("calm"):
		(panel["calm_row"] as Control).visible = d.corrupted or (engine != null and engine.calm > 0 and d == engine.foe)
		panel["name"].add_theme_color_override("font_color", Color(0.82, 0.66, 1.0) if d.corrupted else CREAM)
	panel["name"].text = "%s   Niv. %d%s" % [d.nickname if panel == _player_panel else d.species_name(), d.level, status]
	var bar: ProgressBar = panel["hp"]
	bar.max_value = d.max_hp()
	bar.value = d.hp
	_color_hp(bar)
	if panel.has("hp_text"):
		panel["hp_text"].text = "%d / %d PV" % [d.hp, d.max_hp()]
	if panel.has("xp"):
		panel["xp"].max_value = Dino.xp_to_next(d.level)
		panel["xp"].value = d.xp


func _tween_hp(panel: Dictionary, hp: int, max_hp: int) -> void:
	var bar: ProgressBar = panel["hp"]
	bar.max_value = max_hp
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		bar.value = v
		_color_hp(bar)
		if panel.has("hp_text"):
			panel["hp_text"].text = "%d / %d PV" % [roundi(v), max_hp], bar.value, float(hp), 0.5)
	await t.finished


func _tween_xp(d: Dino) -> void:
	var bar: ProgressBar = _player_panel["xp"]
	bar.max_value = Dino.xp_to_next(d.level)
	await create_tween().tween_property(bar, "value", float(d.xp), 0.6).finished


static func _color_hp(bar: ProgressBar) -> void:
	var r := bar.value / maxf(bar.max_value, 1.0)
	var c := Color(0.36, 0.78, 0.35) if r > 0.5 else Color(0.95, 0.75, 0.2) if r > 0.2 else Color(0.9, 0.3, 0.25)
	(bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = c


# ------------------------------------------------------------------ building

func _setup_dino(s: AnimatedSprite2D, d: Dino, is_foe: bool) -> void:
	var species := d.species()
	s.sprite_frames = SheetFrames.dino(species, d.corrupted)
	var k := (FOE_SCALE if is_foe else PLAYER_SCALE) * species.world_scale / 0.5
	s.scale = Vector2(-k if is_foe else k, k)
	var h := species.sheet.get_height() / float(species.sheet_rows)
	s.offset = Vector2(0, -h * 0.46)
	s.modulate = Color.WHITE
	s.play(&"idle")


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
		var breath := ShaderMaterial.new()
		breath.shader = BREATHE
		breath.set_shader_parameter("amount", SpriteMotion.BREATH)
		breath.set_shader_parameter("period", SpriteMotion.BREATH_S)
		breath.set_shader_parameter("phase", PI if is_foe else 0.0)
		s.material = breath
		_world.add_child(s)
		if is_foe:
			_foe_sprite = s
		else:
			_player_sprite = s
	# Same sky as the exploration: hour and weather.
	_weather = BattleWeather.apply(_root, _backdrop, _world)

	_cry = AudioStreamPlayer.new()
	_cry.bus = &"SFX"
	add_child(_cry)

	_foe_panel = _make_panel(false)
	_foe_panel["box"].position = Vector2(EDGE + 8, EDGE)
	_player_panel = _make_panel(true)
	var pbox: Control = _player_panel["box"]
	pbox.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pbox.offset_left = EDGE + 8
	pbox.offset_right = EDGE + 8
	pbox.offset_top = -112
	pbox.offset_bottom = -112

	# The message, bottom-left; the menus sit to its right.
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _accent_style(PANEL_BG, AMBER, 12))
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = EDGE
	bar.offset_right = -(MENU_WIDTH + EDGE * 2)
	bar.offset_top = -98
	bar.offset_bottom = -EDGE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 22)
	_message.add_theme_color_override("font_color", CREAM)
	bar.add_child(_message)

	_menu = HBoxContainer.new()
	_menu.add_theme_constant_override("separation", 10)
	_anchor_bottom_right(_menu, 24.0)
	_root.add_child(_menu)
	var attack := _button("Attaquer", Color(0.86, 0.38, 0.22))
	attack.pressed.connect(func() -> void: _show_menu(_moves_menu))
	_calm_button = _button("Apaiser", VIOLET)
	_calm_button.pressed.connect(func() -> void: _action_chosen.emit({"type": "calm"}))
	_collar_button = _button("Collier", AMBER)
	_collar_button.pressed.connect(func() -> void:
		if Game.use_item("collier"):
			_action_chosen.emit({"type": "catch"}))
	_run_button = _button("Fuir", Color(0.5, 0.58, 0.66))
	_run_button.pressed.connect(func() -> void: _action_chosen.emit({"type": "run"}))
	for b in [attack, _calm_button, _collar_button, _run_button]:
		_menu.add_child(b)

	# The moves grow upwards from the bottom-right corner: never cut, whatever their number.
	_moves_menu = VBoxContainer.new()
	_moves_menu.add_theme_constant_override("separation", 10)
	_anchor_bottom_right(_moves_menu, EDGE)
	_root.add_child(_moves_menu)
	var back := _button("◀  Retour", Color(0.5, 0.58, 0.66))
	back.custom_minimum_size = Vector2(150, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.add_theme_font_size_override("font_size", 17)
	back.pressed.connect(func() -> void: _show_menu(_menu))
	_moves_menu.add_child(back)
	_moves_grid = GridContainer.new()
	_moves_grid.columns = 2
	_moves_grid.add_theme_constant_override("h_separation", 10)
	_moves_grid.add_theme_constant_override("v_separation", 10)
	_moves_menu.add_child(_moves_grid)
	_show_menu(null)


func _anchor_bottom_right(c: Control, bottom: float) -> void:
	c.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	c.grow_vertical = Control.GROW_DIRECTION_BEGIN
	c.offset_left = -EDGE
	c.offset_right = -EDGE
	c.offset_top = -bottom
	c.offset_bottom = -bottom


func _make_panel(with_numbers: bool) -> Dictionary:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _accent_style(PANEL_BG, AMBER, 12))
	box.custom_minimum_size = Vector2(300, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	box.add_child(v)
	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", CREAM)
	v.add_child(name_label)
	var hp := ProgressBar.new()
	hp.show_percentage = false
	hp.custom_minimum_size = Vector2(0, 10)
	hp.add_theme_stylebox_override("background", _bar_style(Color(0, 0, 0, 0.5), 5))
	hp.add_theme_stylebox_override("fill", _bar_style(Color(0.36, 0.78, 0.35), 5))
	v.add_child(hp)
	var panel := {"box": box, "name": name_label, "hp": hp}
	if not with_numbers:   # the foe: its calm gauge, when it is corrupted
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.visible = false
		var word := Label.new()
		word.text = "Calme"
		word.add_theme_font_size_override("font_size", 14)
		word.add_theme_color_override("font_color", CALM)
		row.add_child(word)
		var calm := ProgressBar.new()
		calm.show_percentage = false
		calm.max_value = BattleEngine.CALM_FULL
		calm.custom_minimum_size = Vector2(0, 8)
		calm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		calm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		calm.add_theme_stylebox_override("background", _bar_style(Color(0.2, 0.08, 0.3, 0.7), 4))
		calm.add_theme_stylebox_override("fill", _bar_style(CALM, 4))
		row.add_child(calm)
		v.add_child(row)
		panel["calm"] = calm
		panel["calm_row"] = row
	if with_numbers:
		var hp_text := Label.new()
		hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hp_text.add_theme_font_size_override("font_size", 14)
		hp_text.add_theme_color_override("font_color", MUTED)
		v.add_child(hp_text)
		var xp := ProgressBar.new()
		xp.show_percentage = false
		xp.custom_minimum_size = Vector2(0, 4)
		xp.add_theme_stylebox_override("background", _bar_style(Color(0, 0, 0, 0.5), 2))
		xp.add_theme_stylebox_override("fill", _bar_style(Color(0.4, 0.72, 0.98), 2))
		v.add_child(xp)
		panel["hp_text"] = hp_text
		panel["xp"] = xp
	return panel


## A compact action button: dark, with the action's colour as a strip on the left.
func _button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = MENU_BUTTON
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_disabled_color", Color(CREAM, 0.35))
	b.add_theme_stylebox_override("normal", _accent_style(CARD_BG, color, 10, 5))
	b.add_theme_stylebox_override("hover", _accent_style(CARD_BG.lightened(0.08), color, 10, 5))
	b.add_theme_stylebox_override("pressed", _accent_style(color.darkened(0.45), color, 10, 5))
	b.add_theme_stylebox_override("focus", _accent_style(Color(0, 0, 0, 0), color.lightened(0.3), 10, 5, 2))
	b.add_theme_stylebox_override("disabled", _accent_style(Color(0.12, 0.12, 0.14, 0.8), Color(0.3, 0.3, 0.32), 10, 5))
	return b


## A move: its name, and below it the type and power points, smaller.
func _move_card(title: String, detail: String, color: Color) -> Button:
	var b := _button("", color)
	b.custom_minimum_size = MOVE_CARD
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18
	v.offset_right = -10
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	for line: Array in [[title, 19, CREAM], [detail, 14, MUTED]]:
		var l := Label.new()
		l.text = line[0]
		l.add_theme_font_size_override("font_size", line[1])
		l.add_theme_color_override("font_color", line[2])
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	return b


## A progress bar's part: rounded, no inner margin (so the bar keeps its thin height).
static func _bar_style(bg: Color, radius: int) -> StyleBoxFlat:
	var s := _style(bg, Color(0, 0, 0, 0), radius, 0)
	s.set_content_margin_all(0)
	return s


## Rounded box with a coloured strip on its left edge (and an optional thin outline).
static func _accent_style(bg: Color, accent: Color, radius: int, strip := 4, outline := 0) -> StyleBoxFlat:
	var s := _style(bg, accent, radius, outline)
	s.border_width_left = strip
	s.content_margin_left = 14 + strip
	return s


static func _style(bg: Color, border: Color, radius: int, border_width := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s
