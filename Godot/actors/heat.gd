class_name Heat
extends CanvasLayer
## La chaleur légère près des coulées (chapitre 8 : la mécanique B, « avec un peu de A »,
## docs/chapitre-8-scenes.md § 7 b). À pied, à moins de RANGE_TILES cases de la lave (Lava), une
## petite jauge monte (plus vite tout contre), en haut de l'écran, et ses bords rougeoient doucement ;
## pleine : « Trop chaud ! », et Chloé recule d'elle-même vers la roche fraîche (Player.step_away),
## sans jamais perdre de PV. Sur le dos d'un dino de pierre ou de feu (Player.lava_walker), en selle
## sur lui, en vol, pendant une scène ou un dialogue : elle ne monte pas, et redescend. Une zone règle
## sa vitesse avec la méta Lava.META_HEAT (0 : pas de jauge). Rien à presser : clavier, manette et
## souris sont égaux devant elle.

const RANGE_TILES := 3.0
## Tout contre la lave (à une case), la jauge est pleine en FILL_S / (1 − 1/RANGE_TILES) s ≈ 10 s.
const FILL_S := 7.0
const COOL_S := 4.0
## Elle recule jusqu'à au moins cette distance de la lave (cases), cherchée jusqu'à SEARCH_TILES.
const BACK_TILES := 3.5
const SEARCH_TILES := 7
## La jauge une fois reculée, et jusqu'où elle redescend avant qu'on la dise de nouveau.
const AFTER_BACK := 0.6
const SHOW_FROM := 0.03
const FIRST_FROM := 0.2
const TINT := Color(1.0, 0.42, 0.1)
const TINT_MAX := 0.3
const BAR_W := 150.0
const BAR_H := 12.0
const TOP := 12.0
const LAYER := 9
const SAY_HOT := "Trop chaud ! Chloé recule à l'ombre, le temps de souffler."
const SAY_FIRST := "Il fait chaud près des coulées : la jauge de chaleur monte. Sur le dos d'un dino de pierre ou de feu, elle ne bouge plus."
const FIRST_FLAG := &"chaleur_aide_vue"
const FLAME := Color(1.0, 0.55, 0.15)
const INK := Color(0.12, 0.08, 0.07, 0.82)
const CREAM := Color(1, 0.95, 0.86)

var player: Node2D
## 0 (frais) à 1 (trop chaud).
var level := 0.0
var _vignette: TextureRect
var _gauge: Control
var _hot_told := false


func _ready() -> void:
	layer = LAYER
	_vignette = TextureRect.new()
	_vignette.texture = _edge_texture()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate = Color(TINT, 0.0)
	add_child(_vignette)
	_gauge = Gauge.new()
	_gauge.heat = self
	add_child(_gauge)
	_show()


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var warm := warmth()
	if warm > 0.0:
		level = minf(1.0, level + warm * delta / FILL_S)
	else:
		level = maxf(0.0, level - delta / COOL_S)
	if level < AFTER_BACK - 0.1:
		_hot_told = false
	if warm > 0.0 and level >= FIRST_FROM and not Game.flag(FIRST_FLAG):
		Game.set_flag(FIRST_FLAG)
		Toast.say(get_tree(), SAY_FIRST, FLAME)
	if level >= 1.0 and not _hot_told:
		_too_hot()
	_show()


## Combien la chaleur la gagne là où elle est (0 : rien ; 1 : tout contre la lave), selon la zone.
func warmth() -> float:
	if not _exposed():
		return 0.0
	var region: Node = player.call(&"region")
	var f := Lava.field(region)
	var rate := float(region.get_meta(Lava.META_HEAT, 1.0)) if region else 0.0
	if f == null or rate <= 0.0:
		return 0.0
	var d := f.distance_tiles(player.global_position)
	return clampf(1.0 - d / RANGE_TILES, 0.0, 1.0) * rate


## À pied, libre de ses mouvements (pas portée par un dino, pas en vol, pas dans une scène).
func _exposed() -> bool:
	if player.get(&"busy") or Dialogue.active or player.get(&"flight") != null or player.get(&"diving"):
		return false
	return player.call(&"carried_by") == null


## Pleine : on le dit, et elle recule vers la roche fraîche la plus proche.
func _too_hot() -> void:
	_hot_told = true
	Toast.say(get_tree(), SAY_HOT, FLAME)
	var to := cool_spot()
	if to != Vector2.INF:
		player.call(&"step_away", to)
	level = AFTER_BACK


## La case sûre la plus proche, à au moins BACK_TILES cases de la lave, qu'elle atteint en ligne
## droite sans rien heurter (ni rocher, ni lave) ; Vector2.INF s'il n'y en a pas.
func cool_spot() -> Vector2:
	var region: Node = player.call(&"region")
	var f := Lava.field(region)
	if f == null:
		return Vector2.INF
	var here := f.cell_of(player.global_position)
	var best := Vector2.INF
	var best_d := INF
	for dy in range(-SEARCH_TILES, SEARCH_TILES + 1):
		for dx in range(-SEARCH_TILES, SEARCH_TILES + 1):
			var at := f.cell_center(here + Vector2i(dx, dy))
			var d := at.distance_to(player.global_position)
			if d >= best_d or f.distance_tiles(at) < BACK_TILES or not _open(region, at):
				continue
			best = at
			best_d = d
	return best


## Du sol où marcher, et le chemin pour y aller sans rien heurter.
func _open(region: Node, at: Vector2) -> bool:
	var kind: StringName = region.call(&"surface_at", at)
	if kind == &"water" or kind == &"forest":
		return false
	if not player.is_inside_tree():
		return true
	var ray := PhysicsRayQueryParameters2D.create(player.global_position, at, 1 | Lava.LAYER)
	return player.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func _show() -> void:
	_vignette.modulate.a = TINT_MAX * smoothstep(0.15, 1.0, level)
	_gauge.visible = level > SHOW_FROM
	_gauge.queue_redraw()


## Les bords de l'écran qui rougeoient : transparent au milieu, la couleur sur les bords.
static func _edge_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.55, Color(1, 1, 1, 0))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 1))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 0.5)
	tex.width = 256
	tex.height = 256
	return tex


## La petite jauge en haut au milieu de l'écran : une flamme, la barre, « Chaleur ».
class Gauge extends Control:
	var heat: Heat

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_viewport().size_changed.connect(_place)
		_place()

	func _place() -> void:
		var k := HudHint.scale_pc()
		var screen := get_viewport().get_visible_rect().size
		var inset := SafeArea.insets(get_viewport())
		size = Vector2(BAR_W + 100.0, 30.0) * k
		position = Vector2((screen.x - size.x) * 0.5, inset.y + TOP * k)

	func _draw() -> void:
		var k := size.y / 30.0
		draw_rect(Rect2(Vector2.ZERO, size), INK, true)
		_flame(Vector2(15, 15) * k, k)
		var bar := Rect2(Vector2(30, 9) * k, Vector2(BAR_W, BAR_H) * k)
		draw_rect(bar, Color(1, 1, 1, 0.15), true)
		var fill := Color(1.0, 0.85, 0.3).lerp(Color(1.0, 0.3, 0.1), heat.level)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * heat.level, bar.size.y)), fill, true)
		draw_rect(bar, CREAM, false, 1.5 * k)
		var font := get_theme_default_font()
		draw_string(font, Vector2(36.0 + BAR_W, 20.0) * k, "Chaleur", HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 * k), CREAM)

	func _flame(c: Vector2, k: float) -> void:
		var pts := PackedVector2Array([c + Vector2(0, -11) * k, c + Vector2(6, -2) * k, c + Vector2(7, 4) * k,
			c + Vector2(3, 9) * k, c + Vector2(-3, 9) * k, c + Vector2(-7, 4) * k, c + Vector2(-5, -3) * k,
			c + Vector2(-2, 0) * k])
		draw_colored_polygon(pts, FLAME)
		draw_circle(c + Vector2(0, 4) * k, 3.2 * k, Color(1.0, 0.9, 0.45))
