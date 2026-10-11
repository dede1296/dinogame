class_name BattleSky
extends Control
## A battle in the Cieux (SkyEngine, BattleScene rule "cieux"): high up in the wind. The backdrop
## is the zone's (Region.battle_backdrop), else BACKDROP (a plateau over the sea of clouds), else
## the given one, cooled. Over it, streaks of wind cross the scene, wisps of cloud drift low; the
## wind blows (a gust, low under the music). The pterosaurs never land up there: they hover over
## their platforms on their wings (Wings: their flight pictures when drawn), bobbing — the
## Quetzalcoatlus Roi first of all. The first battle in the wind tells its rules.

const BACKDROP := "res://assets/art/battle/cieux.jpg"
const COLD_TINT := Color(0.86, 0.93, 1.0)
const STREAK := Color(1.0, 1.0, 1.0, 0.55)
const WISP := Color(1.0, 1.0, 1.0, 0.32)
const WIND := preload("res://assets/audio/ambience/monts.ogg")   # (the clean low wind of the heights)
const WIND_DB := -14.0
## How high the flyers hover above their platforms (screen px): Chloé's dino, the foe (farther).
const LIFT_PX: Array[float] = [64.0, 46.0]
const BOB_PX := 9.0
const BOB_S := 1.8
const TOLD_FLAG := &"combat_cieux_vu"
const RULES_LINE := "Là-haut, dans le vent : les attaques Vent frappent plus fort, et la Terre perd de sa force."

var _sprites: Array[AnimatedSprite2D] = []
var _bases := {}   # sprite -> [its frames, its offset without the hover, its scale then, flies]
var _t := 0.0


## Puts the battle `scene` in the wind (after its rules are set, before its intro).
static func apply(scene: CanvasLayer) -> Control:
	var root: Control = scene.get(&"_root")
	var backdrop: TextureRect = scene.get(&"_backdrop")
	var world: Node2D = scene.get(&"_world")
	var rules: Dictionary = scene.get(&"_rules")
	if not rules.get("backdrop") is Texture2D:
		if ResourceLoader.exists(BACKDROP):
			backdrop.texture = load(BACKDROP)
		else:
			backdrop.modulate *= COLD_TINT
	var look = load("res://battle/battle_sky.gd").new()
	for key: StringName in [&"_player_sprite", &"_foe_sprite"]:
		look._sprites.append(scene.get(key))
	root.add_child(look)
	root.move_child(look, world.get_index() + 1)
	if not Game.flag(TOLD_FLAG):
		Game.set_flag(TOLD_FLAG)
		var lesson: Array = (rules.get("lesson", []) as Array).duplicate()
		lesson.push_front(RULES_LINE)
		rules["lesson"] = lesson
	return look


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var screen := get_viewport().get_visible_rect().size
	add_child(_wisps(screen))
	add_child(_streaks(screen))
	var wind := AudioStreamPlayer.new()
	var stream := WIND.duplicate() as AudioStream
	if &"loop" in stream:
		stream.set(&"loop", true)
	wind.stream = stream
	wind.bus = &"SFX"
	wind.volume_db = WIND_DB
	add_child(wind)
	wind.play()


func _process(delta: float) -> void:
	_t += delta
	for k in _sprites.size():
		var s := _sprites[k]
		if not is_instance_valid(s) or s.sprite_frames == null:
			continue
		var base: Array = _bases.get(s, [])
		if base.is_empty() or base[0] != s.sprite_frames:
			base = [s.sprite_frames, s.offset, maxf(absf(s.scale.y), 0.01), _wings(s, k)]
			_bases[s] = base
		if not base[3]:
			continue
		# On the wing: lifted over its platform (its offset; its shadow stays below), bobbing.
		var phase := _t * TAU / BOB_S + k * PI
		var lift: float = LIFT_PX[mini(k, LIFT_PX.size() - 1)] / float(base[2])
		s.offset = (base[1] as Vector2) + Vector2(0.0, -lift + sin(phase) * BOB_PX)
		if s.animation == &"idle":
			s.play(Wings.FLY)


## A pterosaur fighting here: its wings added to its frames (true), else false (it stands).
func _wings(s: AnimatedSprite2D, k: int) -> bool:
	var scene := get_parent().get_parent() if get_parent() else null
	var engine = scene.get(&"engine") if scene else null
	if engine == null:
		return false
	var d: Dino = engine.player() if k == 0 else engine.foe
	var species := d.species()
	if species.family != &"flyer":
		return false
	Wings.add_to(s.sprite_frames, species)
	return true


## Thin streaks of wind crossing the scene from the west.
func _streaks(screen: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = Quality.scaled(22)
	p.lifetime = 1.6
	p.preprocess = 1.6
	p.position = Vector2(-40.0, screen.y * 0.45)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(10.0, screen.y * 0.5)
	p.direction = Vector2(1.0, 0.04)
	p.spread = 2.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = screen.x * 0.6
	p.initial_velocity_max = screen.x * 0.95
	p.texture = _streak_texture()
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	p.color_ramp = _fade(STREAK)
	return p


## Soft wisps of cloud drifting low over the scene.
func _wisps(screen: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = Quality.scaled(7)
	p.lifetime = 14.0
	p.preprocess = 14.0
	p.position = Vector2(-120.0, screen.y * 0.78)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(20.0, screen.y * 0.16)
	p.direction = Vector2.RIGHT
	p.spread = 3.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = screen.x / 14.0
	p.initial_velocity_max = screen.x / 9.0
	p.texture = _wisp_texture()
	p.scale_amount_min = 2.5
	p.scale_amount_max = 5.0
	p.color_ramp = _fade(WISP)
	return p


static func _fade(colour: Color) -> Gradient:
	var fade := Gradient.new()
	fade.set_color(0, Color(colour, 0.0))
	fade.add_point(0.25, colour)
	fade.add_point(0.75, colour)
	fade.set_color(fade.get_point_count() - 1, Color(colour, 0.0))
	return fade


## A long thin line, faded at both ends.
static func _streak_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.5, Color(1, 1, 1, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 90
	tex.height = 3
	return tex


## A soft round puff (cloud).
static func _wisp_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 40
	return tex
