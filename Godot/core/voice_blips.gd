class_name VoiceBlips
## The characters' little "voices" while their lines are typed (like Animal Crossing or
## Pokémon): a short tone per few letters, with a pitch and timbre per character. Each voice
## is synthesised once (oscillator → soft low-pass → vowel peak → quick envelope), brought to
## the same loudness, and kept; each blip is then played slightly detuned.

const RATE := 22050
const BLIP_S := 0.06
const TARGET_RMS := 0.07
const DETUNE := 0.12
## pitch (Hz), wave, formant (the vowel colour, Hz), every: one blip per this many letters.
const PROFILES := {
	"Prof. Roc": {"pitch": 150.0, "wave": "saw", "formant": 900.0, "every": 4},
	"Roc": {"pitch": 150.0, "wave": "saw", "formant": 900.0, "every": 4},
	"Maïa": {"pitch": 360.0, "wave": "square", "formant": 1700.0, "every": 3},
	"Chloé": {"pitch": 300.0, "wave": "square", "formant": 1500.0, "every": 3},
	"Hélène": {"pitch": 250.0, "wave": "triangle", "formant": 1100.0, "every": 4},
	"Isaure": {"pitch": 230.0, "wave": "triangle", "formant": 1000.0, "every": 4},
	"Pêcheur": {"pitch": 130.0, "wave": "saw", "formant": 800.0, "every": 4},
}
## Anyone else (villagers, masked grunts…): a neutral middle voice.
const DEFAULT := {"pitch": 200.0, "wave": "saw", "formant": 1100.0, "every": 3}

static var _cache: Dictionary = {}


static func profile(speaker: String) -> Dictionary:
	return PROFILES.get(speaker, DEFAULT)


static func every(speaker: String) -> int:
	return profile(speaker)["every"]


## Plays one blip for `speaker` (narration, with no speaker, has none).
static func blip(speaker: String, volume_db := -9.0) -> void:
	if speaker == "":
		return
	if not _cache.has(speaker):
		_cache[speaker] = _synth(profile(speaker))
	Audio.play_sfx(_cache[speaker], volume_db, DETUNE)


static func _synth(p: Dictionary) -> AudioStreamWAV:
	var n := int(RATE * (BLIP_S + 0.01))
	var samples := PackedFloat32Array()
	samples.resize(n)
	var low := _biquad_lowpass(p["formant"] * 2.2, 0.707)
	var vowel := _biquad_peak(p["formant"], 1.4, 10.0)
	var ls := [0.0, 0.0, 0.0, 0.0]
	var vs := [0.0, 0.0, 0.0, 0.0]
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase = fmod(phase + p["pitch"] / RATE, 1.0)
		var x := _wave(p["wave"], phase)
		x = _run(low, ls, x)
		x = _run(vowel, vs, x)
		# 6 ms attack, then an exponential fall to silence at BLIP_S.
		var env := t / 0.006 if t < 0.006 else pow(0.0001, (t - 0.006) / (BLIP_S - 0.006))
		samples[i] = x * (env if t < BLIP_S else 0.0)
	var sum := 0.0
	for v in samples:
		sum += v * v
	var rms := sqrt(sum / n)
	var gain := TARGET_RMS / rms if rms > 0.0 else 1.0
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, clampi(roundi(samples[i] * gain * 32767.0), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


static func _wave(kind: String, ph: float) -> float:
	match kind:
		"square":
			return 1.0 if ph < 0.5 else -1.0
		"triangle":
			return 4.0 * absf(ph - 0.5) - 1.0
	return 2.0 * ph - 1.0   # saw


## RBJ biquads: [b0, b1, b2, a1, a2] normalised; state = [x1, x2, y1, y2].
static func _biquad_lowpass(f: float, q: float) -> Array:
	var w := TAU * f / RATE
	var alpha := sin(w) / (2.0 * q)
	var a0 := 1.0 + alpha
	var c := cos(w)
	return [(1.0 - c) / 2.0 / a0, (1.0 - c) / a0, (1.0 - c) / 2.0 / a0, -2.0 * c / a0, (1.0 - alpha) / a0]


static func _biquad_peak(f: float, q: float, gain_db: float) -> Array:
	var a := pow(10.0, gain_db / 40.0)
	var w := TAU * f / RATE
	var alpha := sin(w) / (2.0 * q)
	var c := cos(w)
	var a0 := 1.0 + alpha / a
	return [(1.0 + alpha * a) / a0, -2.0 * c / a0, (1.0 - alpha * a) / a0, -2.0 * c / a0, (1.0 - alpha / a) / a0]


static func _run(k: Array, s: Array, x: float) -> float:
	var y: float = k[0] * x + k[1] * s[0] + k[2] * s[1] - k[3] * s[2] - k[4] * s[3]
	s[1] = s[0]
	s[0] = x
	s[3] = s[2]
	s[2] = y
	return y
