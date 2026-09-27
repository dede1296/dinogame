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
	## Forêt Jurassique : no sea (inland), rain layers on top automatically (Game.is_raining(),
	## see audio_director.gd) — birds fall silent then, like everywhere else with "day": true.
	# The web's forest recording is a cricket drone: made of clean sounds instead.
	&"foret": {
		"beds": [["brise", 0.3, ""], ["feu", 1.0, "fire"]],
		"calls": [
			{"ids": BIRDS, "every": [4.0, 10.0], "vol": 0.42, "day": true},
			{"ids": ["goutte"], "every": [5.0, 13.0], "vol": 0.22},   # drops falling from the ferns
		],
	},
	&"cabinet": {"beds": [["labo", 1.0, ""]], "calls": []},
	&"maison": {"beds": [["maison", 0.9, ""]], "calls": []},
	## Marais Brumeux : the web's marais.mp3 is a whistle drone (99.5 % of its energy crammed
	## into 1-3 kHz around a screaming ~2 kHz peak), unusable, like foret.mp3 above. "eau" (an
	## ElevenLabs take, the only one of four that came back clean — see prepare-ambience.mjs)
	## stands in for the calm water. No clean frog take was found in three tries (always a
	## piercing 1-2 kHz chirp instead of a low croak): the marsh leans on birds and drips
	## instead of frogs.
	&"marais": {
		"beds": [["brise", 0.35, ""], ["eau", 0.55, ""], ["feu", 1.0, "fire"]],
		"calls": [
			{"ids": BIRDS, "every": [7.0, 16.0], "vol": 0.35, "day": true},
			{"ids": ["goutte"], "every": [4.0, 10.0], "vol": 0.3},
		],
	},
	## Désert Aride : desert.mp3 (web) is clean (92.5 % of its energy below 500 Hz, only a
	## negligible ~0.1 % near 2 kHz), used as-is for the grave hot wind, no filter needed.
	&"desert": {
		"beds": [["desert", 0.6, ""], ["feu", 1.0, "fire"]],
		"calls": [
			{"ids": ["rafale"], "every": [15.0, 35.0], "vol": 0.45},
			{"ids": ["oiseau-3"], "every": [30.0, 60.0], "vol": 0.25, "day": true},
		],
	},
}


static func has(id: StringName) -> bool:
	return AMBIENCES.has(id)


static func get_ambience(id: StringName) -> Dictionary:
	return AMBIENCES.get(id, {"beds": [], "calls": []})


static func stream(sound: String) -> AudioStream:
	return load(PATH % sound)
