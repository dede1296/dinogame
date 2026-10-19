class_name CinematicPlan
extends Control
## Un plan d'une cinématique (ui/cinematic.gd ; le format : docs/cinematiques.md § Format commun) :
## - sa peinture 16:9 (« image », sinon la première de « image_or » qui existe) ; si aucune n'existe, un
##   fond uni (« color », ou un dégradé « gradient » [haut, bas]) : tout se joue avant que les peintures
##   existent, et un plan sans image ne plante jamais ;
## - un seul mouvement de caméra lent, en douceur : « camera » = [zoom de départ, point visé de départ,
##   zoom d'arrivée, point visé d'arrivée] (points en coordonnées de l'image, 0..1) ; l'image couvre
##   toujours l'écran, on n'en voit jamais le bord ;
## - ses calques animés (« layers »), posés en coordonnées de l'image et qui suivent la caméra :
##   « image » (un calque détouré par-dessus : pulse, flicker, drift, bob, sway, fade_in), « reveal »
##   (un dessin qui apparaît trait par trait, ui/cinematic_reveal.gdshader), « glow » (un halo : lampe,
##   lune, ambre), « particles » (brume, fumée, poussière, cendre, vapeur, étoiles…, CPUParticles2D),
##   « sprite » (une planche du jeu qui passe : un Ptéranodon, des Compsognathus), « notes » (les notes
##   d'Écho), « tint » (une teinte qui change : la nuit qui tombe). Un calque dont l'image manque est
##   sauté, sans bruit.
## - un carton (« kind » = « card ») : un titre (« title ») au centre, sur le noir.
## Rien ici ne vient d'addons/ (l'export ne l'emporte pas).

const BASE := Vector2(1280, 720)
const BLACK := Color(0.02, 0.018, 0.016)
const FALLBACK_COLOR := Color(0.16, 0.2, 0.24)
const TITLE_SIZE := 84
const TITLE_COLOR := Color(1, 0.86, 0.5)        # boot.tscn's « Ambrelune »
const TITLE_OUTLINE := Color(0.22, 0.12, 0.04)
const REVEAL_SHADER := preload("res://ui/cinematic_reveal.gdshader")
const SWAY_SHADER := preload("res://world/shaders/sway.gdshader")
const NOTE_EVERY := 0.7
const NOTE_LIFE := 2.4

static var _dot: Texture2D

var plan: Dictionary
## Seconds since the plan began to show; `span`: its whole time on screen (camera from start to end).
var t := 0.0
var span := 1.0
var has_picture := false
## The picture shown ("" when none: the plain background).
var shown_path := ""
## The frame the camera moves: the picture and its layers, in BASE coordinates.
var frame: Control
var fallback: Control
var title: Label
var _layers: Array[Dictionary] = []
var _by_id := {}


static func create(p: Dictionary, seconds: float) -> CinematicPlan:
	var node := CinematicPlan.new()
	node.plan = p
	node.span = maxf(seconds, 0.1)
	node._build()
	return node


## A picture, taken from the thread that loaded it ahead (Cinematic._prefetch) when there is one.
static func picture(path: String) -> Texture2D:
	if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		return ResourceLoader.load_threaded_get(path) as Texture2D
	return load(path) as Texture2D


## The first picture of the plan that exists ("" when none does).
static func picture_of(p: Dictionary) -> String:
	var paths: Array = [p.get("image", "")]
	paths.append_array(p.get("image_or", []))
	for path in paths:
		if String(path) != "" and ResourceLoader.exists(String(path)):
			return String(path)
	return ""


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var black := ColorRect.new()
	black.color = BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	frame = Control.new()
	frame.name = "Frame"
	frame.size = BASE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	if plan.get("kind", "") == "card":
		_title(String(plan.get("title", "")))
		return
	shown_path = picture_of(plan)
	if shown_path != "":
		var painting := TextureRect.new()
		painting.name = "Picture"
		painting.texture = picture(shown_path)
		painting.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		painting.stretch_mode = TextureRect.STRETCH_SCALE
		painting.size = BASE
		painting.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(painting)
		has_picture = true
	else:
		fallback = _plain()
		frame.add_child(fallback)
	for def: Dictionary in plan.get("layers", []):
		_add_layer(def)
	if plan.has("title"):
		_title(String(plan["title"]))
	_camera()


## No picture: a plain colour, a little lighter at the top (or the plan's own gradient).
func _plain() -> Control:
	var colours: Array = plan.get("gradient", [])
	var base: Color = plan.get("color", FALLBACK_COLOR)
	if colours.size() < 2:
		colours = [base.lightened(0.12), base.darkened(0.35)]
	var gradient := Gradient.new()
	gradient.set_color(0, colours[0])
	gradient.set_color(1, colours[1])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 16
	texture.height = 128
	var plain := TextureRect.new()
	plain.name = "Plain"
	plain.texture = texture
	plain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plain.stretch_mode = TextureRect.STRETCH_SCALE
	plain.size = BASE
	plain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return plain


func _title(text: String) -> void:
	title = Label.new()
	title.name = "Title"
	title.text = text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override(&"font_size", TITLE_SIZE)
	title.add_theme_color_override(&"font_color", TITLE_COLOR)
	title.add_theme_color_override(&"font_outline_color", TITLE_OUTLINE)
	title.add_theme_constant_override(&"outline_size", 16)
	add_child(title)


# ------------------------------------------------------------------ time

## How far the camera is, 0 → 1, eased in and out (a slow, soft movement).
func progress() -> float:
	var x := clampf(t / span, 0.0, 1.0)
	return 0.5 - 0.5 * cos(PI * x)


func tick(dt: float) -> void:
	t += dt
	_camera()
	for layer in _layers:
		_animate(layer)


## The frame scaled to cover the screen times the zoom, the aimed point at the screen's centre,
## held so no edge of the picture ever shows.
func _camera() -> void:
	var screen := size if size.x > 0.0 else BASE
	var cam: Array = plan.get("camera", [])
	var z0: float = cam[0] if cam.size() > 0 else 1.0
	var f0: Vector2 = cam[1] if cam.size() > 1 else Vector2(0.5, 0.5)
	var z1: float = cam[2] if cam.size() > 2 else z0
	var f1: Vector2 = cam[3] if cam.size() > 3 else f0
	var p := progress()
	var zoom := lerpf(z0, z1, p)
	var k := maxf(screen.x / BASE.x, screen.y / BASE.y) * maxf(zoom, 1.0)
	var shown := BASE * k
	var at := screen * 0.5 - f0.lerp(f1, p) * shown
	frame.scale = Vector2(k, k)
	frame.position = Vector2(clampf(at.x, screen.x - shown.x, 0.0), clampf(at.y, screen.y - shown.y, 0.0))


# ------------------------------------------------------------------ layers

func _add_layer(def: Dictionary) -> void:
	if not _over_ok(def):
		return   # (it belongs over another picture than the one shown)
	var node: Node = null
	match String(def.get("kind", "")):
		"image":
			node = _image_layer(def)
		"reveal":
			node = _reveal_layer(def)
		"glow":
			node = _glow_layer(def)
		"particles":
			node = _particles(def)
		"sprite":
			node = _sprite_layer(def)
		"notes":
			node = _notes_layer(def)
		"tint":
			node = _tint_layer(def)
	if node == null:
		return
	frame.add_child(node)
	var layer := {"node": node, "def": def}
	_layers.append(layer)
	if def.has("id"):
		_by_id[String(def["id"])] = layer
	_animate(layer)


## A layer cut out on its own (same size as the painting, unless `rect`), drawn over it. Skipped when
## its file is missing, or when it belongs over another picture than the one shown (`over`).
func _image_layer(def: Dictionary) -> TextureRect:
	var path := String(def.get("path", ""))
	if path == "" or not ResourceLoader.exists(path) or not _over_ok(def):
		return null
	var layer := TextureRect.new()
	layer.texture = load(path)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rect: Rect2 = def.get("rect", Rect2(0, 0, 1, 1))
	layer.position = rect.position * BASE
	layer.size = rect.size * BASE
	layer.pivot_offset = (def.get("pivot", Vector2(0.5, 1.0)) as Vector2) * layer.size
	if String(def.get("anim", "")) == "sway":
		var sway := ShaderMaterial.new()
		sway.shader = SWAY_SHADER
		sway.set_shader_parameter(&"strength", float(def.get("strength", 3.0)))
		sway.set_shader_parameter(&"speed", float(def.get("speed", 1.6)))
		sway.set_shader_parameter(&"push_strength", 0.0)
		sway.set_shader_parameter(&"stiffness", float(def.get("stiffness", 1.2)))
		layer.material = sway
	layer.set_meta(&"home", layer.position)
	return layer


func _over_ok(def: Dictionary) -> bool:
	return not def.has("over") or String(def["over"]) == shown_path


## The drawing that appears over its blank page (I-05, F-09): only over that blank page.
func _reveal_layer(def: Dictionary) -> TextureRect:
	var layer := _image_layer(def)
	if layer == null:
		return null
	var reveal := ShaderMaterial.new()
	reveal.shader = REVEAL_SHADER
	reveal.set_shader_parameter(&"mode", int(def.get("mode", 0)))
	reveal.set_shader_parameter(&"span", def.get("span", Vector2(0.0, 1.0)))
	reveal.set_shader_parameter(&"origin", def.get("origin", Vector2(0.5, 0.5)))
	reveal.set_shader_parameter(&"start_angle", float(def.get("start_angle", 2.4)))
	reveal.set_shader_parameter(&"progress", 0.0)
	layer.material = reveal
	return layer


## A soft halo (a lamp, the moon, the amber of the cliffs), added over the picture.
func _glow_layer(def: Dictionary) -> Sprite2D:
	var glow := Sprite2D.new()
	glow.texture = soft_dot()
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	var radius := float(def.get("radius", 0.05)) * BASE.y
	glow.scale = Vector2.ONE * radius * 2.0 / glow.texture.get_width() * Vector2(float(def.get("wide", 1.0)), 1.0)
	glow.position = (def.get("at", Vector2(0.5, 0.5)) as Vector2) * BASE
	glow.modulate = def.get("color", Color(1, 0.8, 0.45, 0.5))
	return glow


## A planche of the game passing by: a sheet (`sheet`, `cols`, `rows`, `frames`, `fps`) or a species'
## walk (`species`); from `from` to `to` (image coordinates) between `start` and `start` + `dur`;
## `height`: the size of one picture, in the image's height. The sheets face right: going left, flipped.
func _sprite_layer(def: Dictionary) -> AnimatedSprite2D:
	var frames: SpriteFrames = null
	var anim := &"go"
	var cell_h := 1.0
	if def.has("species"):
		var species := SpeciesDB.get_species(StringName(def["species"]))
		if species == null or species.sheet == null:
			return null
		frames = SheetFrames.dino(species)
		anim = &"walk"
		cell_h = species.sheet.get_height() / float(species.sheet_rows)
	else:
		var path := String(def.get("sheet", ""))
		if path == "" or not ResourceLoader.exists(path):
			return null
		var sheet: Texture2D = load(path)
		var cols := int(def.get("cols", 1))
		var rows := int(def.get("rows", 1))
		var cells: Array = def.get("frames", range(cols * rows))
		frames = SheetFrames.build(sheet, cols, rows, {anim: {"frames": cells, "fps": float(def.get("fps", 6.0))}})
		cell_h = sheet.get_height() / float(rows)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.animation = anim
	sprite.play(anim)
	sprite.scale = Vector2.ONE * float(def.get("height", 0.08)) * BASE.y / maxf(cell_h, 1.0)
	var from: Vector2 = def.get("from", Vector2.ZERO)
	var to: Vector2 = def.get("to", from)
	sprite.flip_h = to.x < from.x
	sprite.modulate = def.get("tint", Color.WHITE)
	sprite.visible = false
	return sprite


## Écho's little notes going up from its crest (drawn: no font needed).
func _notes_layer(def: Dictionary) -> Control:
	var notes := Control.new()
	notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notes.position = (def.get("at", Vector2(0.5, 0.5)) as Vector2) * BASE
	notes.set_meta(&"notes", [])
	var colour: Color = def.get("color", Color(1, 0.62, 0.5))
	notes.draw.connect(func() -> void:
		for n: Dictionary in notes.get_meta(&"notes"):
			var a := clampf(minf(n["age"] / 0.3, (NOTE_LIFE - n["age"]) / 0.6), 0.0, 1.0)
			var at: Vector2 = n["at"]
			var c := Color(colour, a)
			notes.draw_circle(at, 6.0, c)
			notes.draw_line(at + Vector2(5.0, 0.0), at + Vector2(5.0, -22.0), c, 2.5)
			notes.draw_line(at + Vector2(5.0, -22.0), at + Vector2(13.0, -15.0), c, 2.5))
	return notes


## A colour laid over the picture that changes slowly (`from` → `to`): the night falling. `gradient`:
## strongest at the top of `rect`, nothing at its bottom (the sky).
func _tint_layer(def: Dictionary) -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0.0 if def.get("gradient", false) else 1.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 8
	texture.height = 64
	var tint := TextureRect.new()
	tint.texture = texture
	tint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tint.stretch_mode = TextureRect.STRETCH_SCALE
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rect: Rect2 = def.get("rect", Rect2(0, 0, 1, 1))
	tint.position = rect.position * BASE
	tint.size = rect.size * BASE
	tint.modulate = def.get("from", Color(0, 0, 0, 0))
	return tint


## Each layer at time t: where it is, how bright, how far drawn.
func _animate(layer: Dictionary) -> void:
	var node: Node = layer["node"]
	var def: Dictionary = layer["def"]
	var start := float(def.get("start", 0.0))
	var dur := float(def.get("dur", span - start))
	var lt := t - start
	var k := clampf(lt / maxf(dur, 0.001), 0.0, 1.0)
	match String(def.get("kind", "")):
		"image", "reveal":
			_animate_image(node as TextureRect, def, lt, k)
		"glow":
			_animate_glow(node as Sprite2D, def, lt, k)
		"particles":
			_animate_particles(node as CPUParticles2D, def, lt)
		"sprite":
			var sprite := node as AnimatedSprite2D
			sprite.visible = lt >= 0.0 and lt <= dur
			var from: Vector2 = def.get("from", Vector2.ZERO)
			var arc := float(def.get("arc", 0.0)) * sin(TAU * lt / maxf(float(def.get("arc_period", 2.0)), 0.1))
			sprite.position = (from.lerp(def.get("to", from), k) + Vector2(0.0, arc)) * BASE
		"notes":
			_animate_notes(node as Control, def, lt)
		"tint":
			var from_colour: Color = def.get("from", Color(0, 0, 0, 0))
			(node as CanvasItem).modulate = from_colour.lerp(def.get("to", from_colour), k)
	if def.has("carried_by"):
		_carry(node, def)


func _animate_image(layer: TextureRect, def: Dictionary, lt: float, k: float) -> void:
	var period := maxf(float(def.get("period", 3.0)), 0.1)
	var home: Vector2 = layer.get_meta(&"home", Vector2.ZERO)
	var alpha := float(def.get("alpha", 1.0))
	match String(def.get("anim", "")):
		"pulse":
			alpha = lerpf(float(def.get("min", 0.45)), float(def.get("max", 1.0)), 0.5 + 0.5 * sin(TAU * t / period))
		"flicker":
			alpha *= 0.82 + 0.09 * sin(t * 13.1) + 0.09 * sin(t * 7.3 + 1.7)
		"drift":
			var from: Vector2 = def.get("from", Vector2.ZERO)
			layer.position = home + from.lerp(def.get("to", from), k) * BASE
		"bob":
			layer.position = home + Vector2(0.0, sin(TAU * t / period) * float(def.get("amp", 0.004)) * BASE.y)
			layer.rotation = deg_to_rad(float(def.get("angle", 0.6))) * sin(TAU * t / period + 0.7)
		"fade_in":
			alpha *= k
	layer.modulate.a = alpha if lt >= 0.0 or def.get("kind") == "reveal" else 0.0
	if def.get("kind") == "reveal":
		(layer.material as ShaderMaterial).set_shader_parameter(&"progress", k * 1.1)


func _animate_glow(glow: Sprite2D, def: Dictionary, lt: float, k: float) -> void:
	var colour: Color = def.get("color", Color(1, 0.8, 0.45, 0.5))
	var alpha := colour.a
	var period := maxf(float(def.get("period", 3.0)), 0.1)
	if def.has("pulse"):
		alpha *= lerpf(float(def["pulse"]), 1.0, 0.5 + 0.5 * sin(TAU * t / period))
	if def.get("flicker", false):
		alpha *= 0.8 + 0.1 * sin(t * 17.0) + 0.1 * sin(t * 9.1 + 2.0)
	if def.get("fade_in", false):
		alpha *= k
	if def.has("to"):
		var from: Vector2 = def.get("at", Vector2(0.5, 0.5))
		glow.position = from.lerp(def["to"], k) * BASE
	glow.modulate = Color(colour, alpha if lt >= 0.0 else 0.0)


func _animate_particles(fx: CPUParticles2D, def: Dictionary, lt: float) -> void:
	if fx.one_shot:
		if lt >= 0.0 and not fx.has_meta(&"fired"):
			fx.set_meta(&"fired", true)
			fx.restart()
			fx.emitting = true
		return
	var on := lt >= 0.0 and lt <= float(def.get("stop", 1.0e9)) - float(def.get("start", 0.0))
	if def.has("breath"):   # breathed out now and then (the Souverain's breath lifting the ash)
		var period := maxf(float(def["breath"]), 0.5)
		on = on and fmod(maxf(lt, 0.0), period) < period * 0.35
	if fx.emitting != on:
		fx.emitting = on


func _animate_notes(notes: Control, def: Dictionary, lt: float) -> void:
	var list: Array = notes.get_meta(&"notes")
	var dt := lt - float(notes.get_meta(&"last", lt))
	notes.set_meta(&"last", lt)
	for n: Dictionary in list:
		n["age"] += dt
		n["at"] += Vector2(sin(n["age"] * 3.0 + n["seed"]) * 0.6, -26.0 * dt)
	list = list.filter(func(n: Dictionary) -> bool: return n["age"] < NOTE_LIFE)
	var wait := float(notes.get_meta(&"wait", 0.0)) - dt
	if lt >= 0.0 and wait <= 0.0:
		wait = float(def.get("every", NOTE_EVERY))
		list.append({"age": 0.0, "at": Vector2(randf_range(-10.0, 10.0), 0.0), "seed": randf() * TAU})
	notes.set_meta(&"wait", wait)
	notes.set_meta(&"notes", list)
	notes.queue_redraw()


## Mastoc takes the lantern: from `carried_by`'s start on, the layer goes with that sprite.
func _carry(node: Node, def: Dictionary) -> void:
	var carrier: Dictionary = _by_id.get(String(def["carried_by"]), {})
	if carrier.is_empty() or not (carrier["node"] as CanvasItem).visible:
		return
	var at: Vector2 = (carrier["node"] as Node2D).position / BASE + (def.get("carry_offset", Vector2.ZERO) as Vector2)
	if node is Node2D:
		(node as Node2D).position = at * BASE
	elif node is Control:
		(node as Control).position = (node as Control).get_meta(&"home", Vector2.ZERO) + (at - (def.get("at", Vector2(0.5, 0.5)) as Vector2)) * BASE


# ------------------------------------------------------------------ particles

## A soft white dot (no picture file: drawn by a gradient), for halos and particles.
static func soft_dot() -> Texture2D:
	if _dot == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.45, Color(1, 1, 1, 0.55))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 64
		texture.height = 64
		_dot = texture
	return _dot


## The presets: [amount, lifetime, scale min, scale max, colour, direction, spread (°), speed min,
## speed max, gravity, preprocess (s: already there when the plan shows)].
const PRESETS := {
	"mist": [10, 9.0, 5.0, 9.0, Color(1, 1, 1, 0.1), Vector2(1, 0), 8.0, 8.0, 18.0, Vector2.ZERO, 9.0],
	"smoke": [16, 5.0, 0.6, 1.6, Color(0.6, 0.57, 0.55, 0.32), Vector2(0.2, -1), 12.0, 10.0, 20.0, Vector2(4, -2), 5.0],
	"dust": [36, 7.0, 0.06, 0.12, Color(1, 0.93, 0.72, 0.55), Vector2(1, 0), 180.0, 2.0, 6.0, Vector2.ZERO, 7.0],
	"ash": [40, 6.0, 0.05, 0.1, Color(0.78, 0.75, 0.72, 0.6), Vector2(0.4, -1), 40.0, 8.0, 20.0, Vector2.ZERO, 6.0],
	"steam": [10, 2.6, 0.4, 1.2, Color(1, 1, 1, 0.22), Vector2(0, -1), 15.0, 10.0, 18.0, Vector2.ZERO, 2.6],
	"sparkle": [26, 1.4, 0.05, 0.11, Color(1, 0.95, 0.75, 0.9), Vector2(1, 0), 180.0, 0.0, 2.0, Vector2.ZERO, 1.4],
	"stars": [70, 120.0, 0.04, 0.09, Color(1, 1, 0.94, 0.95), Vector2(1, 0), 180.0, 0.0, 0.0, Vector2.ZERO, 0.0],
	"bubbles": [5, 2.2, 0.12, 0.22, Color(0.85, 0.95, 1, 0.5), Vector2(0.3, -1), 20.0, 14.0, 22.0, Vector2.ZERO, 0.0],
	"pollen": [24, 6.0, 0.04, 0.07, Color(1, 0.9, 0.4, 0.7), Vector2(1, 0), 180.0, 3.0, 8.0, Vector2.ZERO, 6.0],
	"embers": [14, 2.5, 0.05, 0.1, Color(1, 0.6, 0.2, 0.9), Vector2(0, -1), 25.0, 15.0, 35.0, Vector2.ZERO, 2.5],
	"splash": [36, 1.1, 0.07, 0.14, Color(0.9, 0.97, 1, 0.85), Vector2(0, -1), 55.0, 120.0, 220.0, Vector2(0, 420), 0.0],
	"sneeze": [30, 1.6, 0.5, 1.2, Color(0.72, 0.62, 0.48, 0.45), Vector2(-1, -0.3), 35.0, 60.0, 140.0, Vector2.ZERO, 0.0],
}
## The bursts: fired once, at `start`.
const BURSTS := ["splash", "sneeze"]


## Particles of a preset over `rect` (image coordinates; a point when its size is zero). `amount`,
## `life`, `color` override the preset.
func _particles(def: Dictionary) -> CPUParticles2D:
	var preset: Array = PRESETS.get(String(def.get("preset", "")), [])
	if preset.is_empty():
		return null
	var fx := CPUParticles2D.new()
	fx.texture = soft_dot()
	fx.amount = int(def.get("amount", preset[0]))
	fx.lifetime = float(def.get("life", preset[1]))
	fx.scale_amount_min = preset[2]
	fx.scale_amount_max = preset[3]
	fx.color = def.get("color", preset[4])
	fx.direction = preset[5]
	fx.spread = preset[6]
	fx.initial_velocity_min = preset[7]
	fx.initial_velocity_max = preset[8]
	fx.gravity = preset[9]
	fx.preprocess = preset[10]
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.15, Color.WHITE)
	fade.add_point(0.75, Color.WHITE)
	fx.color_ramp = fade
	var rect: Rect2 = def.get("rect", Rect2(0.5, 0.5, 0, 0))
	fx.position = rect.get_center() * BASE
	if rect.size != Vector2.ZERO:
		fx.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		fx.emission_rect_extents = rect.size * BASE * 0.5
	if String(def["preset"]) in BURSTS:
		fx.one_shot = true
		fx.explosiveness = 0.92
		fx.damping_min = 40.0
		fx.damping_max = 60.0
	fx.emitting = false
	return fx
