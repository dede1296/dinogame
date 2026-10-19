extends Control
## Un combat dans la Terre des Apex (chapitre 9 : dans une de ses ZONES, ou la règle « apex ») : le fond `apex.jpg`
## (BACKDROP : la salle ronde, les veines d'ambre), ou, tant que l'agent images ne l'a pas livré, un repli : la grotte
## éclairée de cristaux d'ambre, réchauffée ; par-dessus, des grains d'ambre qui montent lentement et une lueur dorée
## qui respire au ras du sol (les veines). Ici aussi ce qu'ApexEngine raconte en plus (play) : un Alpha appelé par
## son Sceau qui paraît à côté du dino de Chloé et s'efface (Minuit n'a pas d'image : son chant monte du sol, en
## ondes) ; Caillou qui se met devant ; le dernier geste du dino de départ ; le sol qui tremble ; l'équipe qui se
## relève. Préchargé par battle_scene.gd (pas de class_name).

const ZONES: Array[StringName] = [&"terre_apex", &"coeur_apex"]
const BACKDROP := "res://assets/art/battle/apex.jpg"
const FALLBACK := "res://assets/art/battle/grotte.jpg"
const FALLBACK_TINT := Color(1.0, 0.84, 0.62)
const AMBER := Color(1.0, 0.76, 0.32)
const GLOW := Color(1.0, 0.62, 0.2, 0.2)
const VIOLET := Color(0.62, 0.3, 1.0)
const ASH := Color(0.62, 0.6, 0.58)
const FROST := Color(0.75, 0.92, 1.0)
const WATER := Color(0.45, 0.7, 1.0)
## Caillou (le Tricératops de Maïa) quand il se met devant.
const CAILLOU := &"triceratops"
## Les Alphas sans image en combat (le Mosasaure : il n'entre pas, sa voix monte par les veines d'ambre).
const VOICE_ONLY: Array[StringName] = [&"mosasaure_abyssal"]
## Cheminée se couche à côté du Souverain (près de lui, pas de Chloé).
const BY_THE_FOE: Array[StringName] = [&"trex_magma"]
const ALPHA_META := &"apex_alpha"


## Un combat livré ici est-il dans la Terre des Apex ?
static func applies(rules: Dictionary, zone: StringName) -> bool:
	return rules.get("apex", zone in ZONES)


## Le fond des Apex : le sien s'il est dessiné, sinon le repli (et sa teinte).
static func backdrop() -> Array:
	if ResourceLoader.exists(BACKDROP):
		return [load(BACKDROP), Color.WHITE]
	return [load(FALLBACK), FALLBACK_TINT]


## Met le combat `scene` au fond du cratère (après ses règles, avant son intro). Le fond de la zone (règle
## « backdrop ») passe avant.
static func apply(scene: CanvasLayer) -> Control:
	var root: Control = scene.get(&"_root")
	var tex: TextureRect = scene.get(&"_backdrop")
	var world: Node2D = scene.get(&"_world")
	var rules: Dictionary = scene.get(&"_rules")
	if not rules.get("backdrop") is Texture2D:
		var pick := backdrop()
		tex.texture = pick[0]
		tex.modulate *= pick[1]   # (sur la teinte de l'heure, BattleWeather)
	var look = load("res://battle/battle_apex.gd").new()
	root.add_child(look)
	root.move_child(look, world.get_index() + 1)
	return look


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var screen := get_viewport().get_visible_rect().size
	var glow := _glow(screen)
	add_child(glow)
	var breathe := create_tween().set_loops()
	breathe.tween_property(glow, "modulate:a", 0.45, 2.4).set_trans(Tween.TRANS_SINE)
	breathe.tween_property(glow, "modulate:a", 1.0, 2.4).set_trans(Tween.TRANS_SINE)
	add_child(_motes(screen))


## Des grains d'ambre qui montent lentement du sol, vacillent et s'éteignent.
func _motes(screen: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = Quality.scaled(22)
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.position = Vector2(screen.x * 0.5, screen.y + 10.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(screen.x * 0.55, 8.0)
	p.direction = Vector2(0.0, -1.0)
	p.spread = 12.0
	p.gravity = Vector2(0.0, -6.0)
	p.initial_velocity_min = screen.y * 0.05
	p.initial_velocity_max = screen.y * 0.12
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.texture = _dot()
	var fade := Gradient.new()
	fade.set_color(0, Color(AMBER, 0.0))
	fade.add_point(0.2, AMBER)
	fade.set_color(fade.get_point_count() - 1, Color(AMBER, 0.0))
	p.color_ramp = fade
	return p


## Une lueur dorée au ras du sol (les veines d'ambre), qui respire.
func _glow(screen: Vector2) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(GLOW, 0.0))
	g.set_color(1, GLOW)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 128
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.position = Vector2(0.0, screen.y * 0.6)
	rect.size = Vector2(screen.x, screen.y * 0.4)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func _dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 8
	tex.height = 8
	return tex


# ------------------------------------------------------------------ ce qu'ApexEngine raconte

## Joue un événement d'ApexEngine (la scène dit ensuite son texte, s'il en a un).
static func play(scene: CanvasLayer, e: Dictionary) -> void:
	match e["type"]:
		"sceau":
			await _alpha_in(scene, e["alpha"])
		"sceau_end":
			await _alpha_out(scene)
		"caillou":
			await _caillou(scene)
		"gesture":
			await _gesture(scene, String(e.get("variant", "")), int(e.get("step", 0)))
		"quake":
			scene.call(&"_shake", 12.0, 0.45)
			await scene.get_tree().create_timer(0.3).timeout
		"fear":
			await (scene.get(&"_hud") as BattleHud).tween_calm(int(e["calm"]))
		"rally":
			var player: Node2D = scene.get(&"_player_sprite")
			scene.call(&"_burst", player.position + Vector2(0.0, 10.0), AMBER, 50, 220.0)
			scene.call(&"_burst", player.position + Vector2(-120.0, 10.0), AMBER, 30, 160.0)
			await scene.get_tree().create_timer(0.5).timeout


## Un dino de l'histoire en combat, à côté de Chloé : sa planche, sa taille, sa respiration.
static func _stand_in(scene: CanvasLayer, species_id: StringName, at: Vector2, facing_right := true) -> AnimatedSprite2D:
	var species := SpeciesDB.get_species(species_id)
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SheetFrames.dino(species)
	var k: float = 0.9 * species.battle_scale / 0.5
	s.scale = Vector2(k if facing_right else -k, k)
	s.offset = Vector2(0.0, -species.sheet.get_height() / float(species.sheet_rows) * 0.46)
	s.position = at
	s.modulate.a = 0.0
	s.play(&"idle")
	var shadow := Sprite2D.new()
	shadow.texture = Shadow.texture()
	shadow.scale = Vector2(3.4, 1.1)
	shadow.show_behind_parent = true
	s.add_child(shadow)
	(scene.get(&"_world") as Node2D).add_child(s)
	return s


## L'Alpha paraît (fondu, cri) : à côté du dino de Chloé ; Cheminée à côté du Souverain ; Minuit en ondes sur le sol.
static func _alpha_in(scene: CanvasLayer, alpha: StringName) -> void:
	var player: Node2D = scene.get(&"_player_sprite")
	var foe: Node2D = scene.get(&"_foe_sprite")
	if alpha in VOICE_ONLY or not SpeciesDB.PATHS.has(alpha):
		for i in 3:
			_ripple(scene, player.position.lerp(foe.position, 0.5) + Vector2(0.0, 30.0), i * 0.35)
		_cry(scene, alpha)
		await scene.get_tree().create_timer(0.8).timeout
		return
	var near_foe := alpha in BY_THE_FOE
	var at: Vector2 = foe.position + Vector2(-330.0, 70.0) if near_foe else player.position + Vector2(-150.0, -36.0)
	var s := _stand_in(scene, alpha, at, true)   # (tourné vers le Souverain)
	scene.set_meta(ALPHA_META, s)
	var t := scene.create_tween().set_parallel(true)
	t.tween_property(s, "modulate:a", 1.0, 0.45)
	t.tween_property(s, "position:x", at.x + (20.0 if near_foe else 40.0), 0.45).from(at.x - 60.0)
	await t.finished
	_cry(scene, alpha)
	scene.call(&"_burst", s.position + Vector2(0.0, -60.0), AMBER, 22, 160.0)


## L'Alpha s'efface.
static func _alpha_out(scene: CanvasLayer) -> void:
	if not scene.has_meta(ALPHA_META):
		return
	var s = scene.get_meta(ALPHA_META)
	scene.remove_meta(ALPHA_META)
	if not is_instance_valid(s):
		return
	var t := scene.create_tween()
	t.tween_property(s, "modulate:a", 0.0, 0.5)
	await t.finished
	(s as Node).queue_free()


## Une onde qui s'élargit sur le sol (le chant de Minuit), après `delay` s.
static func _ripple(scene: CanvasLayer, at: Vector2, delay: float) -> void:
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(WATER, 0.0)
	ring.closed = true
	for i in 33:
		var a := TAU * i / 32.0
		ring.add_point(Vector2(cos(a) * 60.0, sin(a) * 18.0))
	ring.position = at
	(scene.get(&"_world") as Node2D).add_child(ring)
	var t := scene.create_tween().set_parallel(true)
	t.tween_property(ring, "default_color", Color(WATER, 0.8), 0.2).set_delay(delay)
	t.tween_property(ring, "scale", Vector2(4.0, 4.0), 1.2).from(Vector2.ONE).set_delay(delay)
	t.tween_property(ring, "default_color", Color(WATER, 0.0), 0.6).set_delay(delay + 0.6)
	t.chain().tween_callback(ring.queue_free)


static func _cry(scene: CanvasLayer, alpha: StringName) -> void:
	if SpeciesDB.PATHS.has(alpha):
		var player: AudioStreamPlayer = scene.get(&"_cry")
		var stream := SpeciesDB.get_species(alpha).cry("neutre")
		if stream:
			player.stream = stream
			player.play()


## Caillou se met devant le dino de Chloé, encaisse, et repart.
static func _caillou(scene: CanvasLayer) -> void:
	var player: Node2D = scene.get(&"_player_sprite")
	var at := player.position + Vector2(130.0, 16.0)
	var s := _stand_in(scene, CAILLOU, at - Vector2(220.0, 0.0))
	var t := scene.create_tween().set_parallel(true)
	t.tween_property(s, "modulate:a", 1.0, 0.2)
	t.tween_property(s, "position", at, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished
	scene.call(&"_burst", at + Vector2(40.0, -50.0), Color(1, 0.95, 0.8), 30, 260.0)
	scene.call(&"_shake", 8.0, 0.25)
	_cry(scene, CAILLOU)
	var back := scene.create_tween()
	back.tween_interval(1.4)
	back.tween_property(s, "modulate:a", 0.0, 0.5)
	back.tween_callback(s.queue_free)


## Le dernier geste du dino de départ : Vif bondit jusqu'au front, Bastion ne recule pas et souffle sa cendre,
## Écho chante (des notes d'or) ; « rise » : il se relève. Le geste se joue à sa première ligne (`step` 0) ; aux
## suivantes, un éclat d'or sur le Souverain (il s'arrête, il écoute).
static func _gesture(scene: CanvasLayer, variant: String, step := 0) -> void:
	var player: AnimatedSprite2D = scene.get(&"_player_sprite")
	var foe: Node2D = scene.get(&"_foe_sprite")
	if step > 0:
		scene.call(&"_burst", foe.position + Vector2(-60.0, -110.0), AMBER, 18, 120.0)
		await scene.get_tree().create_timer(0.3).timeout
		return
	match variant:
		"rise":   # (il attend à côté de Chloé : il entre juste après)
			scene.call(&"_burst", player.position + Vector2(-140.0, -40.0), Color(0.96, 0.45, 0.58), 26, 200.0)
		"vif":
			var home := player.position
			var top: Vector2 = foe.position + Vector2(-30.0, -220.0)
			var hop := scene.create_tween()
			hop.tween_method(func(k: float) -> void:
				player.position = home.lerp(top, k) + Vector2(0.0, -120.0 * sin(k * PI)), 0.0, 1.0, 0.7)
			await hop.finished
			scene.call(&"_burst", top + Vector2(0.0, 40.0), AMBER, 24, 140.0)
			await scene.get_tree().create_timer(0.6).timeout
			var down := scene.create_tween()
			down.tween_property(player, "position", home, 0.5).set_trans(Tween.TRANS_QUAD)
			await down.finished
		"bastion":
			scene.call(&"_shake", 6.0, 0.2)
			scene.call(&"_burst", player.position + Vector2(60.0, -70.0), ASH, 36, 120.0)
		"echo":
			for i in 4:
				scene.call(&"_burst", player.position + Vector2(30.0 + i * 60.0, -110.0 - i * 20.0), AMBER, 10, 90.0)
				await scene.get_tree().create_timer(0.18).timeout
			scene.call(&"_burst", foe.position + Vector2(0.0, -80.0), AMBER, 30, 160.0)
	await scene.get_tree().create_timer(0.2).timeout
