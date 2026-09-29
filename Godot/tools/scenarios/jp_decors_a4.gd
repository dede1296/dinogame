extends RefCounted
## Clins d'œil à Jurassic Park — agent A, gros plan (0,6 case) sur les deux plus petits décors
## (griffe_fossile ~0,25 m, creme_raser ~0,2 m), trop petits pour bien se voir à 1 case dans
## jp_decors_a3.gd. Même segment dégagé (x=58-66, y=70).
##   godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/jp_decors_a4.gd

const ST := "res://story/stage.gd"

const STEPS := [
	[0.85, "vsync", false], [0.86, "talk", true],
	[1.0, "zone", &"plaines"], [1.1, "calm", 900.0], [1.2, "weather", &"clear"], [1.3, "clock", 11.0],
	[2.5, "static", [ST, "show_thing", "griffe_fossile", Vector2(58.0, 70.0), "D_griffe_fossile"]],
	[2.6, "static", [ST, "show_thing", "creme_raser", Vector2(62.0, 70.0), "D_creme_raser"]],
	[3.6, "tp", Vector2(58.0, 70.6)], [3.7, "face", Vector2(0, -1)], [4.1, "shot", "jp_griffe_fossile"],
	[4.3, "tp", Vector2(62.0, 70.6)], [4.4, "face", Vector2(0, -1)], [4.8, "shot", "jp_creme_raser"],
	[5.1, "state", null],
]
