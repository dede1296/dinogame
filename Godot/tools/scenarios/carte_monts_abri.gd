extends RefCounted
## Visual check of Bertille's shelter dug into her knoll (a notch, its dark hollow), her fire, crates
## and barrel in front: seen from the front and from aside, by day and at dusk.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/carte_monts_abri.gd

const FLAGS := ["sceau_plaines", "maia_defi_1", "found_journal_6", "havre_arrive", "selle", "monts_ouverts", "monts_arrivee",
	"bertille_vue", "glacier_arrivee"]

const STEPS := [
	[0.8, "flags", FLAGS], [0.85, "talk", true], [0.9, "calm", 900.0], [0.9, "clock", 11.0], [0.95, "weather", &"clear"],
	[1.0, "zone", &"monts"], [3.4, "weather", &"clear"], [3.5, "calm", 900.0], [3.6, "tp", Vector2(20.5, 61.5)],
	[3.7, "face", Vector2(0, -1)], [6.0, "shot", "abri_face"],
	[6.2, "tp", Vector2(27.5, 60.5)], [6.3, "face", Vector2(-1, 0)], [8.5, "shot", "abri_biais_est"],
	[8.7, "tp", Vector2(13.5, 60.5)], [8.8, "face", Vector2(1, 0)], [11.0, "shot", "abri_biais_ouest"],
	[11.2, "clock", 19.3], [11.3, "tp", Vector2(20.5, 61.5)], [11.4, "face", Vector2(0, -1)], [14.0, "shot", "abri_soir"],
	[14.2, "state", null],
]
