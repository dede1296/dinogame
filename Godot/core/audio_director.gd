extends Node
## All the game's sound goes through here, on separate buses (see default_bus_layout.tres):
##   Music     — one theme at a time, streamed, cross-faded when the place or situation changes;
##   Ambience  — the sounds of the place (AmbiencePlayer: layered loops and calls, see
##               AmbienceDB), and the weather's (rain) on top of them;
##   SFX       — short one-shot sounds from a pool of players (many at once);
##   Cries, Voices, Steps — the dinos' cries, the recorded voices, Chloé's steps: play_sfx sends
##               a sound there by the folder it comes from (FOLDER_BUS); players of their own
##               (a dino crying nearby: AudioStreamPlayer2D) are set on them.
## The player sets each one's volume (Paramètres → Sons: CATEGORIES), on a gain of its own
## (an Amplify effect), apart from the ducks and fades this node plays on the buses' volume.

const MUSIC_BUS := &"Music"
const AMBIENCE_BUS := &"Ambience"
const SFX_BUS := &"SFX"
const CRIES_BUS := &"Cries"
const VOICE_BUS := &"Voices"
const STEPS_BUS := &"Steps"
## The kinds of sound the player sets apart (Paramètres → Sons): [bus, name shown]; Master: all.
const CATEGORIES := [
	[&"Master", "Général"], [MUSIC_BUS, "Musique"], [AMBIENCE_BUS, "Ambiance"], [CRIES_BUS, "Cris des dinos"],
	[VOICE_BUS, "Voix"], [SFX_BUS, "Bruitages"], [STEPS_BUS, "Pas"],
]
## Where play_sfx sends a sound, by the folder it comes from (the others: SFX_BUS).
const FOLDER_BUS := {"/audio/cries/": CRIES_BUS, "/audio/voices/": VOICE_BUS, "/audio/footsteps/": STEPS_BUS}
const SFX_VOICES := 16
const SILENT_DB := -60.0

var _music: Array[AudioStreamPlayer] = []
var _music_active := 0
var ambience: AmbiencePlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _music_tween: Tween
var _weather: Array[AudioStreamPlayer] = []
var _weather_active := 0
var _weather_tween: Tween
var _duck_tween: Tween
var _music_stack: Array = []
## Each bus's normal level (default_bus_layout.tres): ducks and fades are relative to it.
var _base_db := {}
## bus -> AudioEffectAmplify: the player's volume for it (set_volume).
var _gain := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in [MUSIC_BUS, AMBIENCE_BUS, SFX_BUS]:
		_base_db[bus] = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))
	for i in 2:
		_music.append(_make_player(MUSIC_BUS))
		_weather.append(_make_player(AMBIENCE_BUS))
	for i in SFX_VOICES:
		_sfx.append(_make_player(SFX_BUS))
	ambience = AmbiencePlayer.new()
	add_child(ambience)
	for category: Array in CATEGORIES:
		var amplify := AudioEffectAmplify.new()
		AudioServer.add_bus_effect(AudioServer.get_bus_index(category[0]), amplify, 0)
		_gain[category[0]] = amplify
		set_volume(category[0], volume(category[0]), false)


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


## The sounds of a kind of place (AmbienceDB id; &"" = silence), faded in over the previous.
func play_ambience(id: StringName) -> void:
	ambience.play(id)


## The weather's loop over the ambience (rain…); null fades it out.
func play_weather(stream: AudioStream, fade := 3.0, volume_db := 0.0) -> void:
	var tween := _crossfade(_weather, _weather_active, stream, fade, volume_db, _weather_tween)
	if tween:
		_weather_tween = tween
		_weather_active = 1 - _weather_active


## Switches to another theme (a battle) and remembers where the current one was, so
## pop_music() resumes it at the same point instead of from the start.
## `loop`: false for a tune played once over the place (resting), then pop_music().
func push_music(stream: AudioStream, fade := 0.3, loop := true) -> void:
	var current := _music[_music_active]
	_music_stack.append({"stream": current.stream if current.playing else null, "position": current.get_playback_position()})
	play_music(stream, fade, 0.0, 0.0, loop)


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


## One-shot sound. `pitch_jitter`: random pitch spread (0.05 = ±5%), so repeats don't sound identical;
## `pitch`: lower (< 1) or higher (a door closing: its creak, lower and duller); `bus`: where it
## goes, for a sound made in the game (no folder: see bus_for).
func play_sfx(stream: AudioStream, volume_db := 0.0, pitch_jitter := 0.0, pitch := 1.0, bus := &"") -> void:
	if stream == null:
		return
	var p := _sfx[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx.size()
	p.stream = stream
	p.bus = bus if bus != &"" else bus_for(stream)
	p.volume_db = volume_db
	p.pitch_scale = pitch + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


## Lowers the music and ambience by db below their normal level (a voice line…); 0 restores them.
func duck(db: float, time := 0.4) -> void:
	# A new duck replaces the one in progress (two tweens on one bus would fight).
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween().set_parallel(true)
	for bus in [MUSIC_BUS, AMBIENCE_BUS]:
		var idx := AudioServer.get_bus_index(bus)
		_duck_tween.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(idx, v), AudioServer.get_bus_volume_db(idx), _base_db[bus] + db, time)


## Fades the ambience by db below its normal level (battles lower the birds and the wind
## under their music); 0 restores it.
func fade_ambience(db: float, time := 0.5) -> void:
	var idx := AudioServer.get_bus_index(AMBIENCE_BUS)
	create_tween().tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(idx, v),
		AudioServer.get_bus_volume_db(idx), _base_db[AMBIENCE_BUS] + db, time)


## The bus a one-shot sound goes to (FOLDER_BUS).
func bus_for(stream: AudioStream) -> StringName:
	for folder: String in FOLDER_BUS:
		if stream.resource_path.contains(folder):
			return FOLDER_BUS[folder]
	return SFX_BUS


## The player's volume for a kind of sound (CATEGORIES), 0 to 1 (settings.cfg; 1 by default).
func volume(bus: StringName) -> float:
	return clampf(float(Quality.pref("audio", String(bus), 1.0)), 0.0, 1.0)


## `linear`: the slider's share, squared into a gain (half-way sounds half as loud, not nearly
## as loud). `save` false: kept in memory (a slider being dragged); Quality.save_prefs() writes it.
func set_volume(bus: StringName, linear: float, save := true) -> void:
	linear = clampf(linear, 0.0, 1.0)
	Quality.set_pref("audio", String(bus), linear, save)
	var amplify: AudioEffectAmplify = _gain.get(bus)
	if amplify:
		amplify.volume_db = maxf(linear_to_db(maxf(linear * linear, 0.0001)), -80.0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), linear <= 0.001)
