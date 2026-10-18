extends Control
## Un combat dans la Plaine Volcanique (chapitre 8 : dans une de ses ZONES, ou la règle « volcan ») :
## le fond `volcan.jpg` (BACKDROP), ou, tant que l'agent images ne l'a pas livré, un repli réchauffé
## (le désert sous la cendre ; la grotte rougie dans une zone sous la roche) ; par-dessus, des braises
## qui montent doucement, un voile chaud en bas de l'écran, le feu qui crépite tout bas sous la musique.
## Les règles du combat ne changent pas (pas de moteur à part : le T-Rex de Magma est déjà assez dur).
## Ici aussi l'animation de l'antidote (« Ambre clair », règle « antidote ») : la fiole lancée sur le
## dino corrompu, qui s'illumine d'or.
## Préchargé par battle_scene.gd (pas de class_name : rien à enregistrer).

const ZONES: Array[StringName] = [&"champs_cendres", &"forges_ombre", &"coulees_lave", &"sanctuaire_magma", &"porte_cratere"]
const BACKDROP := "res://assets/art/battle/volcan.jpg"
## Les replis, réchauffés (en plein air ; sous la roche ou dans le sanctuaire de verre).
const FALLBACK := "res://assets/art/battle/desert.jpg"
const FALLBACK_TINT := Color(0.86, 0.68, 0.6)
const FALLBACK_CAVE := "res://assets/art/battle/grotte.jpg"
const FALLBACK_CAVE_TINT := Color(1.0, 0.62, 0.5)
const EMBER := Color(1.0, 0.55, 0.18, 0.85)
const HAZE := Color(1.0, 0.38, 0.12, 0.22)
const CRACKLE := preload("res://assets/audio/ambience/feu.ogg")
const CRACKLE_DB := -16.0
const ANTIDOTE_GOLD := Color(1.0, 0.86, 0.42)


## Un combat livré ici est-il dans la Plaine Volcanique ?
static func applies(rules: Dictionary, zone: StringName) -> bool:
	return rules.get("volcan", zone in ZONES)


## Le fond du volcan : le sien s'il est dessiné, sinon un repli (et sa teinte).
static func backdrop(cave := false) -> Array:
	if ResourceLoader.exists(BACKDROP):
		return [load(BACKDROP), Color.WHITE]
	return [load(FALLBACK_CAVE), FALLBACK_CAVE_TINT] if cave else [load(FALLBACK), FALLBACK_TINT]


## Met le combat `scene` dans la chaleur du volcan (après ses règles, avant son intro). Le fond de la
## zone (règle « backdrop ») passe avant.
static func apply(scene: CanvasLayer) -> Control:
	var root: Control = scene.get(&"_root")
	var tex: TextureRect = scene.get(&"_backdrop")
	var world: Node2D = scene.get(&"_world")
	var rules: Dictionary = scene.get(&"_rules")
	if not rules.get("backdrop") is Texture2D:
		var pick := backdrop(rules.get("cave", false))
		tex.texture = pick[0]
		tex.modulate *= pick[1]   # (sur la teinte de l'heure, BattleWeather)
	var look = load("res://battle/battle_volcan.gd").new()
	root.add_child(look)
	root.move_child(look, world.get_index() + 1)
	return look


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var screen := get_viewport().get_visible_rect().size
	add_child(_haze(screen))
	add_child(_embers(screen))
	var fire := AudioStreamPlayer.new()
	var stream := CRACKLE.duplicate() as AudioStream
	if &"loop" in stream:
		stream.set(&"loop", true)
	fire.stream = stream
	fire.bus = &"SFX"
	fire.volume_db = CRACKLE_DB
	add_child(fire)
	fire.play()


## Des braises qui montent du bas de l'écran, lentes, qui vacillent et s'éteignent.
func _embers(screen: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = Quality.scaled(28)
	p.lifetime = 4.5
	p.preprocess = 4.5
	p.position = Vector2(screen.x * 0.5, screen.y + 10.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(screen.x * 0.55, 8.0)
	p.direction = Vector2(0.15, -1.0)
	p.spread = 18.0
	p.gravity = Vector2(6.0, -10.0)
	p.initial_velocity_min = screen.y * 0.08
	p.initial_velocity_max = screen.y * 0.2
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.texture = _dot_texture()
	var fade := Gradient.new()
	fade.set_color(0, Color(EMBER, 0.0))
	fade.add_point(0.15, EMBER)
	fade.add_point(0.7, Color(EMBER.r, EMBER.g * 0.7, EMBER.b, 0.6))
	fade.set_color(fade.get_point_count() - 1, Color(EMBER, 0.0))
	p.color_ramp = fade
	return p


## Un voile chaud qui monte du bas de l'écran (la lueur des coulées).
func _haze(screen: Vector2) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(HAZE, 0.0))
	g.set_color(1, HAZE)
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
	rect.position = Vector2(0.0, screen.y * 0.55)
	rect.size = Vector2(screen.x, screen.y * 0.45)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func _dot_texture() -> GradientTexture2D:
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


## L'antidote (événement « antidote » de BattleEngine) : la fiole d'ambre clair lancée sur le dino
## corrompu, une pluie d'or sur lui. (« calm » puis « calmed » suivent : ses veines s'effacent.)
static func antidote(scene: CanvasLayer, _e: Dictionary) -> void:
	var world: Node2D = scene.get(&"_world")
	var player: Node2D = scene.get(&"_player_sprite")
	var foe: Node2D = scene.get(&"_foe_sprite")
	var vial := Sprite2D.new()
	vial.texture = ItemsDB.icon("antidote_ambre")
	vial.scale = Vector2(0.45, 0.45)
	var start := player.position + Vector2(40.0, -120.0)
	var target := foe.position + Vector2(0.0, -90.0)
	vial.position = start
	world.add_child(vial)
	var arc := scene.create_tween()
	arc.tween_method(func(k: float) -> void:
		vial.position = start.lerp(target, k) + Vector2(0.0, -140.0 * sin(k * PI))
		vial.rotation = k * TAU, 0.0, 1.0, 0.6)
	await arc.finished
	vial.queue_free()
	scene.call(&"_burst", target, ANTIDOTE_GOLD, 46, 240.0)
	scene.call(&"_burst", target + Vector2(0.0, 40.0), Color(1, 1, 0.9), 22, 150.0)
	await scene.get_tree().create_timer(0.35).timeout
