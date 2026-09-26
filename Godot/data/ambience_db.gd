class_name AmbienceDB
## The sounds of each kind of place, under the music (a zone names its kind: Region.ambience_id).
##   beds:  [sound, level (0–1), follows] long recordings looped with a cross-fade;
##          `follows` ("sea", "fire"): the level also follows how close Chloé is to it.
##   calls: {ids, every: [min, max] s, vol, follows, day} short sounds now and then;
##          `day`: silent at night and in the rain (the birds sleep, or shelter).
## Sounds: assets/audio/ambience/<sound>.ogg, all at the same loudness (tools/prepare-ambience.mjs).

const PATH := "res://assets/audio/ambience/%s.ogg"
const BIRDS := ["oiseau-1", "oiseau-2", "oiseau-3"]

const AMBIENCES := {
	&"port": {
		"beds": [["village", 1.0, ""], ["vagues", 0.9, "sea"], ["feu", 1.0, "fire"]],
		"calls": [
			{"ids": ["mouettes"], "every": [12.0, 28.0], "vol": 0.45, "follows": "sea"},
			{"ids": ["oiseau-1", "oiseau-2"], "every": [14.0, 32.0], "vol": 0.3, "day": true},
		],
	},
	&"plaines": {
		"beds": [["brise", 0.45, ""], ["vagues", 0.7, "sea"], ["feu", 1.0, "fire"]],
		"calls": [
			{"ids": BIRDS, "every": [5.0, 14.0], "vol": 0.4, "day": true},
			{"ids": ["rafale"], "every": [18.0, 40.0], "vol": 0.4},
			{"ids": ["mouettes"], "every": [10.0, 24.0], "vol": 0.4, "follows": "sea"},
		],
	},
	&"grotte": {
		"beds": [["grotte", 0.75, ""], ["feu", 1.0, "fire"]],
		"calls": [{"ids": ["goutte"], "every": [4.0, 12.0], "vol": 0.45}],
	},
	&"cabinet": {"beds": [["labo", 1.0, ""]], "calls": []},
	&"maison": {"beds": [["maison", 0.9, ""]], "calls": []},
}


static func has(id: StringName) -> bool:
	return AMBIENCES.has(id)


static func get_ambience(id: StringName) -> Dictionary:
	return AMBIENCES.get(id, {"beds": [], "calls": []})


static func stream(sound: String) -> AudioStream:
	return load(PATH % sound)
