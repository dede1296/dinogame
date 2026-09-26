extends Node
## All the game's sound goes through here, on separate buses (see default_bus_layout.tres):
##   Music     — one theme at a time, streamed, cross-faded when the place or situation changes;
##   Ambience  — the zone's background loop, cross-faded the same way;
##   SFX       — short one-shot sounds from a pool of players (many at once);
## Positional sounds (a dino crying nearby) use AudioStreamPlayer2D on the "SFX" bus directly.

const MUSIC_BUS := &"Music"
const AMBIENCE_BUS := &"Ambience"
const SFX_BUS := &"SFX"
const SFX_VOICES := 16
const SILENT_DB := -60.0

var _music: Array[AudioStreamPlayer] = []
var _music_active := 0
var _ambience: Array[AudioStreamPlayer] = []
var _ambience_active := 0
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _music_tween: Tween
var _ambience_tween: Tween
var _duck_tween: Tween
var _music_stack: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		_music.append(_make_player(MUSIC_BUS))
		_ambience.append(_make_player(AMBIENCE_BUS))
	for i in SFX_VOICES:
		_sfx.append(_make_player(SFX_BUS))


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


## Cross-fades to `stream` (null = silence). Does nothing if it is already playing.
## `from`: start position in seconds. `loop`: false for a jingle played once.
func play_music(stream: AudioStream, fade := 1.5, volume_db := 0.0, from := 0.0, loop := true) -> void:
	var tween := _crossfade(_music, _music_active, stream, fade, volume_db, _music_tween, from, loop)
	if tween:
		_music_tween = tween
		_music_active = 1 - _music_active


func play_ambience(stream: AudioStream, fade := 2.0, volume_db := 0.0) -> void:
	var tween := _crossfade(_ambience, _ambience_active, stream, fade, volume_db, _ambience_tween)
	if tween:
		_ambience_tween = tween
		_ambience_active = 1 - _ambience_active


## Switches to another theme (a battle) and remembers where the current one was, so
## pop_music() resumes it at the same point instead of from the start.
func push_music(stream: AudioStream, fade := 0.3) -> void:
	var current := _music[_music_active]
	_music_stack.append({"stream": current.stream if current.playing else null, "position": current.get_playback_position()})
	play_music(stream, fade)


func pop_music(fade := 1.2) -> void:
	if _music_stack.is_empty():
		return
	var previous: Dictionary = _music_stack.pop_back()
	play_music(previous["stream"], fade, 0.0, previous["position"])


## A short piece played once (victory, capture) in place of the current music.
func play_jingle(stream: AudioStream, fade := 0.2) -> void:
	play_music(stream, fade, 0.0, 0.0, false)


## Returns the new tween, or null when the requested stream was already playing.
func _crossfade(players: Array[AudioStreamPlayer], active: int, stream: AudioStream, fade: float, volume_db: float, previous: Tween, from := 0.0, loop := true) -> Tween:
	var current := players[active]
	if stream != null and current.stream == stream and current.playing:
		return null
	if stream == null and not current.playing:
		return null
	if previous and previous.is_valid():
		previous.kill()
	var next := players[1 - active]
	var tween := create_tween().set_parallel(true)
	if current.playing:
		tween.tween_property(current, "volume_db", SILENT_DB, fade)
		tween.tween_callback(current.stop).set_delay(fade)
	if stream != null:
		_set_looping(stream, loop)
		next.stream = stream
		next.volume_db = SILENT_DB
		next.play(from)
		tween.tween_property(next, "volume_db", volume_db, fade).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tween


## Music and ambience loop (whatever the import settings of the file); jingles don't.
func _set_looping(stream: AudioStream, loop: bool) -> void:
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.set(&"loop", loop)


## One-shot sound. `pitch_jitter`: random pitch spread (0.05 = ±5%), so repeats don't sound identical.
func play_sfx(stream: AudioStream, volume_db := 0.0, pitch_jitter := 0.0) -> void:
	if stream == null:
		return
	var p := _sfx[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


## Lowers the music and ambience (battle intro, dialogue with a voice line…); 0 dB restores them.
func duck(db: float, time := 0.4) -> void:
	# A new duck replaces the one in progress (two tweens on one bus would fight).
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween().set_parallel(true)
	for bus in [MUSIC_BUS, AMBIENCE_BUS]:
		var idx := AudioServer.get_bus_index(bus)
		_duck_tween.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(idx, v), AudioServer.get_bus_volume_db(idx), db, time)


## Fades the ambience bus (battles lower the birds and the wind under their music).
func fade_ambience(db: float, time := 0.5) -> void:
	var idx := AudioServer.get_bus_index(AMBIENCE_BUS)
	create_tween().tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(idx, v),
		AudioServer.get_bus_volume_db(idx), db, time)


func set_bus_volume(bus: StringName, linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(maxf(linear, 0.0001)))
