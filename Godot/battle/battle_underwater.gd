class_name BattleUnderwater
extends Control
## A battle under the sea (UnderwaterEngine, BattleScene rule "underwater"): the fighters float
## in blue-green water. The backdrop is the zone's (Region.battle_backdrop), else BACKDROP, else
## the given one tinted deep; over it a veil, lighter towards the surface, slow shafts of light,
## specks drifting and bubbles rising. The fighters swim, never stand on the floor (the rule of
## the game under the sea): lifted above their platforms (LIFT_PX), paddling slowly (their walk,
## PADDLE_SPEED), they bob and sway gently, their shadows small and faint on the floor below. No
## weather down there (the rain falls up above), and the battle's music is heard clearly (the
## world's sounds are muffled under the water: Underwater.hold_muffle). The first battle under
## the water tells its rules. The Mosasaure's abyss (events "abyss", abyss()): it sinks into the
## dark, surges, stays exposed.

const BACKDROP := "res://assets/art/battle/sous_marin.jpg"
const UNDERWATER_VIEW := preload("res://world/view3d/underwater.gd")
## A backdrop that is not an underwater one, seen through the water.
const DEEP_TINT := Color(0.34, 0.6, 0.76)
const WATER_LIGHT := Color(0.66, 0.88, 0.96)
const VEIL_TOP := Color(0.55, 0.9, 1.0, 0.2)
const VEIL_BOTTOM := Color(0.02, 0.18, 0.3, 0.5)
const SHAFTS := 5
const BOB_PX := 7.0
## How high the fighters swim above their platforms (screen px): Chloé's dino, the foe (farther).
const LIFT_PX: Array[float] = [72.0, 48.0]
const PADDLE_SPEED := 0.45
const SHADOW_SHRINK := 0.7
const BOB_S := 2.6
const SWAY := 0.022
const BUBBLE := Color(0.86, 0.96, 1.0)
const AMBER := Color(0.98, 0.72, 0.28)
## The first battle under the water: its rules, said after the intro.
const TOLD_FLAG := &"combat_sous_marin_vu"
const RULES_LINE := "Sous l'eau, les attaques Eau frappent plus fort, le Feu s'éteint à moitié, et les dinos qui ne savent pas nager sont plus lents."
const SHAFT_SHADER := """
shader_type canvas_item;
render_mode blend_add;
uniform float strength = 0.24;
void fragment() {
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	float a = smoothstep(0.0, 0.9, across) * (1.0 - smoothstep(0.1, 1.0, UV.y)) * strength;
	COLOR = vec4(0.78, 0.96, 1.0, a);
}
"""

var _sprites: Array[AnimatedSprite2D] = []
var _bases := {}   # sprite -> [its frames, its offset without the bob, its scale then]
var _shafts: Array[ColorRect] = []
var _dark: ColorRect
var _t := 0.0


## Puts the battle `scene` under the water (after its rules are set, before its intro).
static func apply(scene: CanvasLayer) -> Control:
	var root: Control = scene.get(&"_root")
	var backdrop: TextureRect = scene.get(&"_backdrop")
	var world: Node2D = scene.get(&"_world")
	var weather = scene.get(&"_weather")
	if weather:
		weather.queue_free()
		scene.set(&"_weather", null)
	var rules: Dictionary = scene.get(&"_rules")
	var light := BattleWeather.tint(Game.clock / 60.0, &"clear").lerp(WATER_LIGHT, 0.35)
	if rules.get("backdrop") is Texture2D:
		backdrop.modulate = light
	elif ResourceLoader.exists(BACKDROP):
		backdrop.texture = load(BACKDROP)
		backdrop.modulate = light
	else:
		backdrop.modulate = light * DEEP_TINT
	world.modulate = light.lerp(Color.WHITE, BattleWeather.FIGHTER_LIFT)
	var look = load("res://battle/battle_underwater.gd").new()
	for key: StringName in [&"_player_sprite", &"_foe_sprite"]:
		look._sprites.append(scene.get(key))
	root.add_child(look)
	root.move_child(look, world.get_index() + 1)
	scene.set_meta(&"underwater_look", look)
	if not Game.flag(TOLD_FLAG):
		Game.set_flag(TOLD_FLAG)
		var lesson: Array = (rules.get("lesson", []) as Array).duplicate()
		lesson.push_front(RULES_LINE)
		rules["lesson"] = lesson
	UNDERWATER_VIEW.hold_muffle(true)
	look.tree_exiting.connect(func() -> void: UNDERWATER_VIEW.hold_muffle(false))
	return look


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var screen := get_viewport().get_visible_rect().size
	add_child(_veil())
	var shader := Shader.new()
	shader.code = SHAFT_SHADER
	for i in SHAFTS:
		var shaft := ColorRect.new()
		shaft.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = shader
		shaft.material = mat
		shaft.size = Vector2(screen.x * randf_range(0.07, 0.13), screen.y * 1.35)
		shaft.pivot_offset = Vector2(shaft.size.x / 2.0, 0.0)
		shaft.position = Vector2(screen.x * (0.08 + 0.2 * i + randf_range(-0.05, 0.05)), -screen.y * 0.1)
		shaft.rotation = randf_range(-0.42, -0.3)
		shaft.set_meta(&"tilt", shaft.rotation)
		add_child(shaft)
		_shafts.append(shaft)
	add_child(_specks(screen))
	add_child(_bubbles(screen))
	_dark = ColorRect.new()
	_dark.color = Color(0.0, 0.03, 0.08, 0.0)
	_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dark)
	_dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_t += delta
	for i in _shafts.size():
		var shaft := _shafts[i]
		shaft.rotation = float(shaft.get_meta(&"tilt")) + sin(_t * 0.3 + i * 1.3) * 0.05
		(shaft.material as ShaderMaterial).set_shader_parameter("strength", 0.14 + 0.12 * (0.5 + 0.5 * sin(_t * 0.45 + i * 1.7)))
	# The fighters float: a slow bob and sway (their own picture's offset, kept apart from the moves).
	for k in _sprites.size():
		var s := _sprites[k]
		if not is_instance_valid(s):
			continue
		var base: Array = _bases.get(s, [])
		if base.is_empty() or base[0] != s.sprite_frames:
			base = [s.sprite_frames, s.offset, maxf(absf(s.scale.y), 0.01)]
			_bases[s] = base
			var shadow: Node2D = null
			if s.get_child_count() > 0:
				shadow = s.get_child(0) as Node2D
			if shadow:
				shadow.modulate.a = 0.35
				if not shadow.has_meta(&"swim_shrunk"):   # (once: the shadow stays, the dinos change)
					shadow.set_meta(&"swim_shrunk", true)
					shadow.scale *= SHADOW_SHRINK
		var phase := _t * TAU / BOB_S + k * PI
		# The picture rises (its offset, in its own units): the sprite's place, its shadow, stay on the floor.
		var lift: float = LIFT_PX[mini(k, LIFT_PX.size() - 1)] / float(base[2])
		s.offset = (base[1] as Vector2) + Vector2(0.0, -lift + sin(phase) * BOB_PX)
		s.rotation = sin(phase * 0.5) * SWAY
		if s.animation == &"idle" and s.sprite_frames.has_animation(&"walk"):
			s.play(&"walk")   # at rest, it paddles
		s.speed_scale = PADDLE_SPEED if s.animation == &"walk" else 1.0


## The Mosasaure's abyss, played for event `e` of the battle `scene`: it sinks into the dark
## (the water darkens), it surges (a jolt, a burst of bubbles), it stays exposed (a golden glint).
static func abyss(scene: CanvasLayer, e: Dictionary) -> void:
	var look = scene.get_meta(&"underwater_look", null)
	var foe: AnimatedSprite2D = scene.get(&"_foe_sprite")
	match String(e.get("kind", "")):
		"hide":
			foe.set_meta(&"abyss_home", foe.position)
			var t := scene.create_tween().set_parallel(true)
			t.tween_property(foe, "position:y", foe.position.y + 90.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			t.tween_property(foe, "modulate:a", 0.12, 0.9)
			if look:
				t.tween_property(look._dark, "color:a", 0.4, 0.9)
			scene.call(&"_burst", foe.position + Vector2(0, -50), Color(BUBBLE, 0.8), 22, 140.0)
			await t.finished
		"surge":
			var home: Vector2 = foe.get_meta(&"abyss_home", foe.position)
			var t := scene.create_tween().set_parallel(true)
			t.tween_property(foe, "position", home, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(foe, "modulate:a", 1.0, 0.18)
			if look:
				t.tween_property(look._dark, "color:a", 0.0, 0.3)
			await t.finished
			scene.call(&"_shake", 14.0, 0.35)
			scene.call(&"_burst", home + Vector2(0, -60), BUBBLE, 34, 320.0)
		"exposed":
			scene.call(&"_burst", foe.position + Vector2(0, -70), AMBER, 24, 180.0)


## Lighter towards the surface (the top), deeper below.
func _veil() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, VEIL_TOP)
	g.set_color(1, VEIL_BOTTOM)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 128
	var veil := TextureRect.new()
	veil.texture = tex
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return veil


## Specks drifting slowly in the water.
func _specks(screen: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = Quality.scaled(40)
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.position = screen / 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = screen * 0.55
	p.direction = Vector2(1.0, -0.2)
	p.spread = 180.0
	p.gravity = Vector2(4.0, -2.0)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 14.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	var fade := Gradient.new()
	fade.set_color(0, Color(0.85, 0.96, 1.0, 0.0))
	fade.add_point(0.3, Color(0.85, 0.96, 1.0, 0.45))
	fade.add_point(0.7, Color(0.85, 0.96, 1.0, 0.45))
	fade.set_color(fade.get_point_count() - 1, Color(0.85, 0.96, 1.0, 0.0))
	p.color_ramp = fade
	return p


## Bubbles rising from the bottom of the scene.
func _bubbles(screen: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = Quality.scaled(26)
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.position = Vector2(screen.x / 2.0, screen.y + 20.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(screen.x * 0.5, 10.0)
	p.direction = Vector2.UP
	p.spread = 10.0
	p.gravity = Vector2(0.0, -14.0)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 95.0
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.65
	p.texture = preload("res://world/dive.gd").ring_texture()
	p.color = Color(BUBBLE, 0.7)
	return p
