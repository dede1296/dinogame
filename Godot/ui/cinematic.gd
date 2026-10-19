class_name Cinematic
extends CanvasLayer
## Une cinématique d'Ambrelune, « livre illustré animé » joué dans le moteur (docs/cinematiques.md §
## Format commun) : une SÉQUENCE décrite par un dictionnaire (story/cinematiques.gd) — des plans, chacun
## une grande image (ui/cinematic_plan.gd : sa caméra lente, ses calques animés ; un fond uni si l'image
## manque), une phrase en bas dans un bandeau lisible, sa musique et ses bruits ; fondus enchaînés entre
## les plans, au noir au début et à la fin. Le dernier plan peut être les crédits (ui/credits.gd).
##
## Le temps de lire (Greg, 19/10 : « assez lent pour un enfant ») : chaque phrase reste entièrement
## affichée au moins READING_MIN_S, ou un mot par 1/READING_WORDS_PER_S seconde (14 mots : 6,3 s), après
## son fondu d'entrée ; un plan prévu plus court est prolongé (sa caméra dérive plus lentement). Les
## durées prévues restent le tempo si le joueur ne touche à rien.
##
## Passer, à tout moment (ui/cinematic_skip.gd) : deux appuis sur Échap, B (ou toute touche qui
## n'avance pas), Échap ou B maintenu HOLD_S, ou un clic sur « Passer », en bas à droite, la touche
## dessinée dessous ; le premier appui allume le bouton et dit en petit ce qui se passe. A, Espace,
## Entrée, E ou un clic sur l'image : « suivant », en douceur — si la phrase n'est pas encore toute
## là, elle finit d'apparaître (pas de saut par mégarde) ; si elle est là, l'image suivante (dans les
## crédits : pause). Le jeu est en pause pendant le film.
##
##   var film := Cinematic.play(self, Cinematiques.intro_sequence())
##   await film.finished
##
## La séquence : {"plans": [...], "flag": &"…" (posé à la fin, passée ou non), "end": "black" (le rideau
## du Router reste fermé : la suite enchaîne au noir) ou "reveal" (on retrouve ce qu'il y avait dessous),
## "restore_music": la musique d'avant revient à la fin, "fade_in", "fade_out"}.
## Un plan : {"id", "image", "image_or", "secs", "fade" (fondu qui l'amène), "camera", "text", "layers",
## "music" (une piste qui commence à ce plan ; absente : titre.ogg, ou le silence si "music_fallback"
## = ""), "music_loop", "loops" (ambiances en boucle pendant le plan), "sfx" ([[à s, chemin, dB]]),
## "kind": "card" (un carton : « title ») ou "credits"}.
## Rien ici ne vient d'addons/ (l'export ne l'emporte pas).

signal finished(skipped: bool)

const LAYER := 102                 # over the Router's curtain (100) and Epilogue.card (101)
const BLACK := Color(0.02, 0.018, 0.016)
const TEXT_COLOR := Color(0.98, 0.9, 0.72)   # Epilogue.card's cream
const TEXT_OUTLINE := Color(0.1, 0.07, 0.04)
const TEXT_SIZE := 32
const TEXT_DELAY := 0.4            # the phrase comes this long after its picture, and goes this long before the next fade
const TEXT_RAMP := 0.35
const TEXT_SIDE := 190.0           # it keeps clear of the « Passer » button
const BAND := Color(0.02, 0.02, 0.03, 0.55)
const FADE := 0.8
const EDGE_FADE := 1.5
const SKIP_FADE := 0.5
const REVEAL_FADE := 0.6
const ADVANCE_AFTER := 1.0         # a plan without a phrase (a card) shows this long before A turns the page
## The pace of reading: words per second (0.45 s a word), and never less than READING_MIN_S, the
## phrase wholly on screen (after its fade in, before its fade out).
const READING_WORDS_PER_S := 1.0 / 0.45
const READING_MIN_S := 3.0
const HOLD_S := 0.8                # Échap / B held this long: skipped
const MAX_STEP_S := 0.25
const MUSIC_FADE := 2.0
const LOOP_DB := -8.0
const LOOP_FADE := 1.5
const FALLBACK_MUSIC := "res://assets/audio/music/titre.ogg"

## Tests (GdUnit4): false, the tree is not paused (a paused tree stops the test runner).
static var pause_tree := true
## The film playing (one at a time), for the tests and the capture tool.
static var current: Cinematic
## The last film's plans as they were shown: [{"id", "ms"}] (real time; its end: id "fin du film").
static var last_timeline: Array[Dictionary] = []
static var _said := {}

var sequence: Dictionary
var done := false
var skipped := false
var index := -1
var _plans: Array = []
var _t := 0.0
var _len := 0.0
var _fade := 0.0
var _stage: Control
var _old: Control
var _ending := false
var _end_t := 0.0
var _end_len := 0.0
var _root: Control
var _stages: Control
var _black: ColorRect
var _band: TextureRect
var _caption: Label
var _skip: CinematicSkip
var _was_paused := false
var _ambience_before: StringName = &""
var _music_pushed := false
var _loops := {}
var _sfx_done := {}
## « Suivant » pressed before the phrase was all there: the picture and the phrase shown at once.
var _forced := false
var _held := 0.0
var _timeline: Array[Dictionary] = []
## The film's own time (the sum of what advance() was given).
var _clock := 0.0


## Plays `seq` over everything (the root of `parent`'s tree). Await `finished`.
static func play(parent: Node, seq: Dictionary) -> Cinematic:
	if is_instance_valid(current) and not current.done:
		current._finish_now()
	var film := Cinematic.new()
	film.sequence = seq
	parent.get_tree().root.add_child(film)
	return film


## The music of a cue: the track, or `fallback` (titre.ogg) when it is not there yet — said once in
## the log, soberly; null = silence.
static func music_stream(path: String, fallback := FALLBACK_MUSIC) -> AudioStream:
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	if path != "" and not _said.has(path):
		_said[path] = true
		print("Cinématique : %s absente, %s à la place." % [path.get_file(), fallback.get_file() if fallback != "" else "silence"])
	if fallback != "" and ResourceLoader.exists(fallback):
		return load(fallback)
	return null


## The words of a phrase, as docs/cinematiques.md counts them (« : », « « » » are not words).
static func word_count(text: String) -> int:
	var n := 0
	for word in text.split(" ", false):
		if word.strip_edges().lstrip("«»:;,.!?…-–").rstrip("«»:;,.!?…-–") != "":
			n += 1
	return n


## How long a phrase must stay wholly on screen to be read (0 without a phrase).
static func reading_secs(text: String) -> float:
	if text.strip_edges() == "":
		return 0.0
	return maxf(READING_MIN_S, word_count(text) / READING_WORDS_PER_S)


## A plan's real time on screen, from the start of the fade that brings it (`fade`) to the start of
## the next one: its planned `secs`, made longer when its phrase needs it (fade in, the phrase's delay
## and ramps, its reading time). The credits: their own time (see CreditsRoll).
static func plan_length(plan: Dictionary, fade: float) -> float:
	var planned := float(plan.get("secs", 6.0))
	var reading := reading_secs(String(plan.get("text", "")))
	if reading <= 0.0:
		return planned
	return maxf(planned, fade + 2.0 * (TEXT_DELAY + TEXT_RAMP) + reading)


## A sequence's real time if nobody touches anything, from its fade in to the black at its end (the
## credits plan: only its opening card).
static func sequence_length(seq: Dictionary) -> float:
	var plans: Array = seq.get("plans", [])
	var total := 0.0
	for i in plans.size():
		var fade := float(plans[i].get("fade", FADE)) if i > 0 else float(seq.get("fade_in", EDGE_FADE))
		total += plan_length(plans[i], fade)
	var last_is_credits: bool = not plans.is_empty() and plans[-1].get("kind", "") == "credits"
	return total + (0.0 if last_is_credits else float(seq.get("fade_out", EDGE_FADE)))


func _ready() -> void:
	current = self
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	if pause_tree:
		get_tree().paused = true
	_plans = sequence.get("plans", [])
	_build()
	_ambience_before = Audio.ambience.current() if Audio.ambience else &""
	Audio.play_ambience(&"")
	if _plans.is_empty():
		_begin_end(0.01)
		return
	_start(0)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP   # nothing under the film is clicked
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	_stages = Control.new()
	_stages.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stages)
	_band = _make_band()
	_root.add_child(_band)
	_caption = Label.new()
	_caption.name = "Caption"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_left = TEXT_SIDE
	_caption.offset_right = -TEXT_SIDE
	_caption.offset_top = -112.0
	_caption.offset_bottom = -26.0
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.add_theme_font_size_override(&"font_size", TEXT_SIZE)
	_caption.add_theme_color_override(&"font_color", TEXT_COLOR)
	_caption.add_theme_color_override(&"font_outline_color", TEXT_OUTLINE)
	_caption.add_theme_constant_override(&"outline_size", 10)
	_caption.modulate.a = 0.0
	_root.add_child(_caption)
	_black = ColorRect.new()
	_black.color = Color(BLACK, 0.0)
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_black)
	_skip = CinematicSkip.new()
	_skip.skip_requested.connect(skip)
	_skip.pause_requested.connect(_toggle_pause)
	_root.add_child(_skip)


## A dark band at the bottom, fading upwards, under the phrase: it reads on any picture.
func _make_band() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(BAND, 0.0))
	gradient.set_color(1, BAND)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 8
	texture.height = 64
	var band := TextureRect.new()
	band.texture = texture
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -150.0
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.modulate.a = 0.0
	return band


# ------------------------------------------------------------------ the plans

func _start(i: int) -> void:
	index = i
	var plan: Dictionary = _plans[i]
	_fade = float(plan.get("fade", FADE)) if i > 0 else float(sequence.get("fade_in", EDGE_FADE))
	_t = 0.0
	_len = plan_length(plan, _fade)
	_forced = false
	if is_instance_valid(_old):
		_old.queue_free()
	_old = _stage
	_stage = _make_stage(plan, _len + _next_fade(i))
	_stage.modulate.a = 0.0
	_stages.add_child(_stage)
	_caption.text = String(plan.get("text", ""))
	_caption.modulate.a = 0.0
	_sfx_done.clear()
	_cue_music(plan)
	_cue_loops(plan)
	_skip.set_credits(plan.get("kind", "") == "credits")
	_skip.set_paused(false)
	_prefetch(i + 1)
	_timeline.append({"id": String(plan.get("id", "")), "ms": Time.get_ticks_msec(), "film": _clock})


func _next_fade(i: int) -> float:
	if i + 1 < _plans.size():
		return float(_plans[i + 1].get("fade", FADE))
	return float(sequence.get("fade_out", EDGE_FADE))


func _make_stage(plan: Dictionary, seconds: float) -> Control:
	if plan.get("kind", "") == "credits":
		return CreditsRoll.create(plan)
	return CinematicPlan.create(plan, seconds)


## The pictures of the next plan start loading now (in a thread), not when it shows.
func _prefetch(i: int) -> void:
	if i >= _plans.size():
		return
	var path := CinematicPlan.picture_of(_plans[i])
	if path != "" and not ResourceLoader.has_cached(path):
		ResourceLoader.load_threaded_request(path)


## A frame never moves the film more than MAX_STEP_S: a freeze (a long load, a screenshot of the test
## tool) makes a plan last longer, never shorter — its phrase always keeps its reading time.
func _process(delta: float) -> void:
	advance(minf(delta, MAX_STEP_S))


## The film moves on by `dt` seconds (each frame; the tests call it by hand).
func advance(dt: float) -> void:
	if done:
		return
	_clock += dt
	_skip.tick(dt)
	_tick_loops(dt)
	_tick_stages(dt)
	_held = _held + dt if Input.is_action_pressed(&"cancel") else 0.0
	if _held >= HOLD_S and not skipped:
		skip()
	if _ending:
		_end_t += dt
		if _end_t < _end_len:
			_black.color.a = _end_t / _end_len
			return
		_black.color.a = 1.0
		if String(sequence.get("end", "black")) == "reveal":
			var r := (_end_t - _end_len) / REVEAL_FADE
			_root.modulate.a = 1.0 - clampf(r, 0.0, 1.0)
			if r < 1.0:
				return
		_finish()
		return
	_t += dt
	_stage.modulate.a = 1.0 if _forced else clampf(_t / maxf(_fade, 0.001), 0.0, 1.0)
	if is_instance_valid(_old) and _stage.modulate.a >= 1.0:
		_old.queue_free()
		_old = null
	_caption.modulate.a = _caption_alpha()
	_band.modulate.a = move_toward(_band.modulate.a, 1.0 if _caption.text != "" else 0.0, dt * 2.0)
	_fire_sfx()
	var over := _t >= _len
	if _stage is CreditsRoll:
		over = (_stage as CreditsRoll).done
	if over:
		var spill := maxf(_t - _len, 0.0) if not _stage is CreditsRoll else 0.0
		_next()
		if not _ending:
			_t = spill   # (the frame's leftover goes to the next plan: the film keeps its time exactly)


func _tick_stages(dt: float) -> void:
	for stage in [_stage, _old]:
		if is_instance_valid(stage):
			(stage as Control).call(&"tick", dt)


func _next() -> void:
	if index + 1 < _plans.size():
		_start(index + 1)
	else:
		_begin_end(float(sequence.get("fade_out", EDGE_FADE)))


## The phrase: 0.4 s after the picture is fully there, gone 0.4 s before the next fade.
func _caption_alpha() -> float:
	if _caption.text == "":
		return 0.0
	var shown_at := _fade + TEXT_DELAY
	var gone_at := _len - TEXT_DELAY
	var coming := 1.0 if _forced else (_t - shown_at) / TEXT_RAMP
	return clampf(minf(coming, (gone_at - _t) / TEXT_RAMP), 0.0, 1.0)


## The phrase is wholly on screen (or already going): « suivant » may turn the page.
func phrase_read() -> bool:
	return _caption.text == "" or _forced or _t >= _fade + TEXT_DELAY + TEXT_RAMP


func _fire_sfx() -> void:
	var cues: Array = _plans[index].get("sfx", [])
	for i in cues.size():
		var cue: Array = cues[i]
		if _sfx_done.has(i) or _t < float(cue[0]):
			continue
		_sfx_done[i] = true
		var path := String(cue[1])
		if ResourceLoader.exists(path):
			Audio.play_sfx(load(path), float(cue[2]) if cue.size() > 2 else 0.0)


# ------------------------------------------------------------------ input

func _input(event: InputEvent) -> void:
	if done:
		return
	var what := _kind_of(event)
	if what == "":
		return
	if what == "look":   # (the mouse moving: the button lights up, the hover still works)
		_skip.reveal()
		return
	get_viewport().set_input_as_handled()
	match what:
		"reveal":
			_skip.reveal()
		"next":
			_skip.reveal()
			go_on()
		"skip":
			press_skip()


## What an input means here: "" (not ours: F11, a click on the buttons…), "look", "reveal", "next"
## (A, Espace, Entrée, E, a click on the picture) or "skip" (any other key or button).
func _kind_of(event: InputEvent) -> String:
	if event is InputEventMouseMotion:
		return "look" if (event as InputEventMouseMotion).relative.length() > 2.0 else ""
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if not click.pressed:
			return ""
		if _skip.covers(click.position):
			_skip.reveal()
			return ""   # the button's own click
		return "next" if click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT] else "reveal"
	if event is InputEventJoypadMotion:
		return "reveal" if absf((event as InputEventJoypadMotion).axis_value) > 0.5 else ""
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return ""
		if key.keycode == KEY_F11 or (key.alt_pressed and key.keycode in [KEY_ENTER, KEY_KP_ENTER]):
			return ""   # (Screen: full screen)
		if key.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]:
			return "reveal"
	elif event is InputEventJoypadButton:
		if not (event as InputEventJoypadButton).pressed:
			return ""
	else:
		return ""
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept"):
		return "next"
	return "skip"


## A press that may skip: the first lights « Passer », the second (while lit) skips.
func press_skip() -> void:
	if not done:
		_skip.press()


## A, a click: « suivant », gently. The phrase not all there yet: it finishes appearing (with its
## picture), nothing is skipped by mistake; once it is there: the next picture. A card (no phrase):
## the next picture once it has shown ADVANCE_AFTER. In the credits: pause.
func go_on() -> void:
	if done or _ending:
		return
	if _stage is CreditsRoll:
		_toggle_pause()
		return
	if _caption.text == "":
		if _t >= ADVANCE_AFTER:
			_len = minf(_len, _t)
		return
	if not phrase_read():
		_forced = true
		_caption.modulate.a = _caption_alpha()
		_stage.modulate.a = 1.0
		return
	_len = minf(_len, _t)


func _toggle_pause() -> void:
	if _stage is CreditsRoll:
		var roll := _stage as CreditsRoll
		roll.toggle_pause()
		_skip.set_paused(roll.paused)


## Skips the whole film, its fade to black included.
func skip() -> void:
	if done or (_ending and skipped):
		return
	skipped = true
	var black := _black.color.a
	_ending = true
	_end_len = SKIP_FADE
	_end_t = black * SKIP_FADE
	_fade_loops()


func _begin_end(seconds: float) -> void:
	_ending = true
	_end_t = 0.0
	_end_len = maxf(seconds, 0.01)
	_fade_loops()


func _finish() -> void:
	if done:
		return
	done = true
	_restore()
	if String(sequence.get("end", "black")) == "black":
		await Router.fade_out(0.0)   # the curtain closes under the film: what is below never shows through
	finished.emit(skipped)
	queue_free()


## Another film starts over this one: it stops at once.
func _finish_now() -> void:
	if done:
		return
	done = true
	_restore()
	finished.emit(true)
	queue_free()


## The flag, the game's pause, its music and ambience: as they were (or as the sequence says).
func _restore() -> void:
	_timeline.append({"id": "fin du film", "ms": Time.get_ticks_msec(), "film": _clock})
	last_timeline = _timeline
	if _timeline.size() > 1:
		print("Cinématique « %s » : %.1f s à l'écran%s." % [sequence.get("id", "?"),
			(_timeline[-1]["ms"] - _timeline[0]["ms"]) / 1000.0, ", passée" if skipped else ""])
	for path: String in _loops:
		(_loops[path]["player"] as AudioStreamPlayer).stop()
	_loops.clear()
	var flag := StringName(sequence.get("flag", &""))
	if flag != &"":
		Game.set_flag(flag)
	if _music_pushed:
		Audio.pop_music(1.2)
	if _ambience_before != &"":
		Audio.play_ambience(_ambience_before)
	if pause_tree and is_inside_tree():
		get_tree().paused = _was_paused
	if current == self:
		current = null


# ------------------------------------------------------------------ sound

func _cue_music(plan: Dictionary) -> void:
	if not plan.has("music"):
		return
	var fallback := String(plan.get("music_fallback", FALLBACK_MUSIC))
	var path := String(plan["music"])
	var stream := music_stream(path, fallback)
	var loop := bool(plan.get("music_loop", false)) or not ResourceLoader.exists(path)
	var fade := float(plan.get("music_fade", MUSIC_FADE))
	if bool(sequence.get("restore_music", true)) and not _music_pushed:
		_music_pushed = true
		Audio.push_music(stream, fade, loop)
	else:
		Audio.play_music(stream, fade, 0.0, 0.0, loop)


## The plan's ambiences (looped while it shows): the ones going on keep playing, the others fade out.
func _cue_loops(plan: Dictionary) -> void:
	var wanted: Array = plan.get("loops", [])
	for path: String in _loops:
		_loops[path]["target"] = 1.0 if wanted.has(path) else 0.0
	for path in wanted:
		if _loops.has(path) or not ResourceLoader.exists(String(path)):
			continue
		var stream := (load(String(path)) as AudioStream).duplicate() as AudioStream   # (its own copy: loop set here only)
		if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
			stream.set(&"loop", true)
		var player := AudioStreamPlayer.new()
		player.bus = Audio.AMBIENCE_BUS
		player.stream = stream
		player.volume_db = Audio.SILENT_DB
		add_child(player)
		player.play()
		_loops[String(path)] = {"player": player, "level": 0.0, "target": 1.0}


func _tick_loops(dt: float) -> void:
	for path: String in _loops.keys():
		var loop: Dictionary = _loops[path]
		loop["level"] = move_toward(loop["level"], loop["target"], dt / LOOP_FADE)
		var player: AudioStreamPlayer = loop["player"]
		player.volume_db = linear_to_db(maxf(loop["level"], 0.0001)) + LOOP_DB
		if loop["level"] <= 0.0 and loop["target"] <= 0.0:
			player.queue_free()
			_loops.erase(path)


func _fade_loops() -> void:
	for path: String in _loops:
		_loops[path]["target"] = 0.0


# ------------------------------------------------------------------ for the tests and the capture tool

## Straight to plan `i` (no fade), as if it had just begun.
func seek(i: int) -> void:
	if done or i < 0 or i >= _plans.size():
		return
	_ending = false
	_black.color.a = 0.0
	_start(i)
	_fade = 0.01
	if is_instance_valid(_old):
		_old.queue_free()
		_old = null


## The plan on screen.
func plan_now() -> Dictionary:
	return _plans[index] if index >= 0 and index < _plans.size() else {}


func stage_now() -> Control:
	return _stage


func caption_text() -> String:
	return _caption.text


func caption_alpha() -> float:
	return _caption.modulate.a


func skip_control() -> CinematicSkip:
	return _skip


## The plans shown so far, with when each began (real time, ms).
func timeline() -> Array[Dictionary]:
	return _timeline
