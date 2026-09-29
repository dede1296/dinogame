class_name AmbienceDB
## The sounds of each kind of place, under the music (a zone names its kind: Region.ambience_id).
##   beds:  [sound, level (0–1), follows] long recordings looped with a cross-fade;
##          `follows` ("sea", "fire"): the level also follows how close Chloé is to it.
##   calls: {ids, every: [min, max] s, vol, follows, day} short sounds now and then;
##          `day`: silent at night, in the rain and the blizzard (the birds sleep, or shelter).
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
			{"ids": ["rafale-grave"], "every": [18.0, 40.0], "vol": 0.4},
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
			{"ids": ["rafale-grave"], "every": [15.0, 35.0], "vol": 0.45},
			{"ids": ["oiseau-3"], "every": [30.0, 60.0], "vol": 0.25, "day": true},
		],
	},
	## Côte Préhistorique : the sea everywhere (louder by the water), the wind off it, gulls over
	## the shore (the Pteranodons' calls are the dinos' own), birds in the palms by day.
	&"cote": {
		"beds": [["brise", 0.4, ""], ["vagues", 1.0, "sea"], ["feu", 1.0, "fire"]],
		"calls": [
			{"ids": ["mouettes"], "every": [8.0, 20.0], "vol": 0.5, "follows": "sea"},
			{"ids": BIRDS, "every": [9.0, 22.0], "vol": 0.3, "day": true},
			{"ids": ["rafale-grave"], "every": [20.0, 45.0], "vol": 0.35},
		],
	},
	## The sea caves: the cave's hollow sound, the sea breathing in the tunnel (its pool touches the
	## edge: "sea"), drops from the roof.
	&"grotte_marine": {
		"beds": [["grotte", 0.6, ""], ["vagues", 0.7, "sea"]],
		"calls": [{"ids": ["goutte"], "every": [3.0, 9.0], "vol": 0.45}],
	},
	## The sanctuary under the sea: the water all round, the deep hum of the rock.
	&"recif": {
		"beds": [["eau", 0.8, ""], ["grotte", 0.35, ""]],
		"calls": [],
	},
	## Monts Gelés : the cold wind always (the web's monts.mp3: a clean low wind), low gusts now
	## and then (rafale-grave: rafale.mp3 without its hiss), a bird rarely by day. A blizzard lays
	## its own howl on top (the world's weather sound: blizzard.ogg). Nothing above 4 kHz.
	&"monts": {
		"beds": [["monts", 0.7, ""], ["feu", 1.0, "fire"]],
		"calls": [
			{"ids": ["rafale-grave"], "every": [10.0, 24.0], "vol": 0.45},
			{"ids": ["oiseau-3"], "every": [35.0, 70.0], "vol": 0.2, "day": true},
		],
	},
	## The ice caves: the cave's hollow hum, the wind outside heard dull through the ice, melt
	## water dripping, the ice groaning now and then (glace).
	&"grotte_glace": {
		"beds": [["grotte", 0.6, ""], ["monts", 0.25, ""]],
		"calls": [
			{"ids": ["goutte"], "every": [4.0, 11.0], "vol": 0.4},
			{"ids": ["glace"], "every": [16.0, 36.0], "vol": 0.45},
		],
	},
	## The frost sanctuary: hushed; the hum of the rock, the wind far off, the ice groaning once
	## in a while.
	&"sanctuaire_givre": {
		"beds": [["grotte", 0.5, ""], ["monts", 0.15, ""]],
		"calls": [{"ids": ["glace"], "every": [25.0, 50.0], "vol": 0.35}],
	},
}


static func has(id: StringName) -> bool:
	return AMBIENCES.has(id)


static func get_ambience(id: StringName) -> Dictionary:
	return AMBIENCES.get(id, {"beds": [], "calls": []})


static func stream(sound: String) -> AudioStream:
	return load(PATH % sound)
