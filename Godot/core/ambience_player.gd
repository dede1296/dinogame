class_name AmbiencePlayer
extends Node
## The sounds of the current place (see AmbienceDB), on the Ambience bus: its beds looped
## with a cross-fade (two passes of a recording overlap, so the seam is never heard) and
## its calls now and then. Changing place fades one set out while the next fades in.
## Owned by the Audio autoload (runs during pauses too: maps, battles).

const BUS := &"Ambience"
const XFADE_S := 2.5      # overlap of two passes of a bed
const FADE_S := 1.5       # change of place
const MIX_RATE := 0.8     # how fast "sea" / "fire" levels follow Chloé (per second)
const CALL_VOICES := 4
const CALL_PITCH := 0.06  # calls: ± this much pitch, so repeats never sound the same
const SILENT := 0.0001

## Places playing: the current one (target 1) and those fading out (target 0).
## A set: {id, fade, target, beds: [bed], calls: [{def, wait}]}.
## A bed: {level, follows, players: [2 AudioStreamPlayer], active, fresh: [bool, bool]}.
var _sets: Array[Dictionary] = []
var _mix := {"sea": 0.0, "fire": 0.0}
var _mix_target := {"sea": 0.0, "fire": 0.0}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0


func _ready() -> void:
	for i in CALL_VOICES:
		_voices.append(_player())


## Fades to the ambience `id` (AmbienceDB; &"" = silence). Nothing happens if it already plays.
func play(id: StringName) -> void:
	if not _sets.is_empty() and _sets[-1]["id"] == id and _sets[-1]["target"] == 1.0:
		return
	for s in _sets:
		s["target"] = 0.0
	if id == &"" or not AmbienceDB.has(id):
		return
	var def := AmbienceDB.get_ambience(id)
	var place := {"id": id, "fade": 0.0, "target": 1.0, "beds": [], "calls": []}
	for b: Array in def["beds"]:
		place["beds"].append(_start_bed(b))
	for c: Dictionary in def["calls"]:
		place["calls"].append({"def": c, "wait": _wait(c)})
	_sets.append(place)


## How close Chloé is to what a bed or call follows ("sea", "fire"): 0 far … 1 there.
func set_mix(key: String, level: float) -> void:
	_mix_target[key] = clampf(level, 0.0, 1.0)


## The id of the place playing (tests).
func current() -> StringName:
	return _sets[-1]["id"] if not _sets.is_empty() and _sets[-1]["target"] == 1.0 else &""


func _process(delta: float) -> void:
	for key: String in _mix:
		_mix[key] = move_toward(_mix[key], _mix_target[key], MIX_RATE * delta)
	for s in _sets.duplicate():
		s["fade"] = move_toward(s["fade"], s["target"], delta / FADE_S)
		if s["target"] == 0.0 and s["fade"] == 0.0:
			_stop(s)
			continue
		for bed: Dictionary in s["beds"]:
			_update_bed(bed, s["fade"])
		if s["target"] == 1.0:
			for call: Dictionary in s["calls"]:
				call["wait"] -= delta
				if call["wait"] <= 0.0:
					call["wait"] = _wait(call["def"])
					_play_call(call["def"])


# ------------------------------------------------------------------ beds

func _start_bed(b: Array) -> Dictionary:
	var stream := AmbienceDB.stream(b[0])
	stream.set(&"loop", false)   # the passes cross-fade instead
	var players: Array[AudioStreamPlayer] = [_player(), _player()]
	for p in players:
		p.stream = stream
		p.volume_db = linear_to_db(SILENT)
	# Beds never start in sync: the first pass begins somewhere inside the recording.
	players[0].play(randf() * maxf(0.0, stream.get_length() - XFADE_S * 2.0))
	return {"level": float(b[1]), "follows": String(b[2]), "players": players, "active": 0, "fresh": [false, true]}


func _update_bed(bed: Dictionary, fade: float) -> void:
	var players: Array[AudioStreamPlayer] = bed["players"]
	var level: float = bed["level"] * fade * (_mix[bed["follows"]] if bed["follows"] != "" else 1.0)
	# Not heard at all here (no fire nearby…): paused, rather than decoded for nothing.
	for p in players:
		p.stream_paused = level <= SILENT
	if level <= SILENT:
		return
	var cur := players[bed["active"]]
	var length := cur.stream.get_length()
	# Near the end of a pass, the next one starts and they overlap.
	if cur.playing and length - cur.get_playback_position() <= XFADE_S and not players[1 - bed["active"]].playing:
		bed["active"] = 1 - bed["active"]
		bed["fresh"][bed["active"]] = true
		players[bed["active"]].play(0.0)
	for i in 2:
		var p := players[i]
		if not p.playing:
			continue
		var pos := p.get_playback_position()
		var pass_gain := clampf((length - pos) / XFADE_S, 0.0, 1.0)
		if bed["fresh"][i]:
			pass_gain *= clampf(pos / XFADE_S, 0.0, 1.0)
		p.volume_db = linear_to_db(maxf(level * pass_gain, SILENT))


# ------------------------------------------------------------------ calls

func _play_call(def: Dictionary) -> void:
	var level: float = _mix[def["follows"]] if def.has("follows") else 1.0
	if level <= 0.05:
		return
	if def.get("day", false) and (Game.phase() == &"night" or Game.weather == &"rain"):
		return
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = AmbienceDB.stream(def["ids"].pick_random())
	p.pitch_scale = 1.0 + randf_range(-CALL_PITCH, CALL_PITCH)
	p.volume_db = linear_to_db(maxf(float(def["vol"]) * level * randf_range(0.6, 1.0), SILENT))
	p.play()


static func _wait(def: Dictionary) -> float:
	return randf_range(def["every"][0], def["every"][1])


# ------------------------------------------------------------------ players

func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = BUS
	add_child(p)
	return p


func _stop(s: Dictionary) -> void:
	for bed: Dictionary in s["beds"]:
		for p: AudioStreamPlayer in bed["players"]:
			p.queue_free()
	_sets.erase(s)
