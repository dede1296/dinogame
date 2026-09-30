extends RefCounted
## Check (30/09): how much video memory the game holds, zone after zone, AS THE BROWSER GETS IT
## (Quality.WEB: no 3D building models) — the web freezes with
## the music still playing, the mark of a lost graphics context, and a tab loses it when video
## memory runs out.
## godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/test_memoire.gd

const H := "res://tools/scenarios/memoire_outils.gd"
const STEPS := [
	[0.8, "flags", ["selle", "sceau_plaines", "havre_arrive", "foret_arrivee", "marais_arrivee",
		"desert_arrivee", "cote_arrivee", "monts_arrivee"]],
	[0.9, "calm", 900.0], [1.0, "clock", 11.0], [1.1, "no_help", null],
	[1.15, "static", ["res://tools/scenarios/web_outils.gd", "as_web"]],
	[1.2, "zone", &"port_ambre"], [4.0, "static", [H, "video"]],
	[4.4, "zone", &"plaines"], [7.2, "static", [H, "video"]],
	[7.6, "zone", &"foret"], [10.4, "static", [H, "video"]],
	[10.8, "zone", &"havre_dore"], [13.6, "static", [H, "video"]],
	[14.0, "zone", &"marais"], [16.8, "static", [H, "video"]],
	[17.2, "zone", &"desert"], [20.0, "static", [H, "video"]],
	[20.4, "zone", &"cote"], [23.2, "static", [H, "video"]],
	[23.6, "zone", &"monts"], [26.4, "static", [H, "video"]],
	[26.8, "zone", &"plaines"], [29.6, "static", [H, "video"]],
	[30.0, "state", null],
]
