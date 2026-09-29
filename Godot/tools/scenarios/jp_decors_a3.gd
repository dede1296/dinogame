extends RefCounted
## Clins d'œil à Jurassic Park — agent A, 2e reprise (jp_decors_a.gd, jp_decors_a2.gd) : les 5
## décors encore gênés (eau du Bosquet d'Hélène, jungle dense) sont resserrés à 2 cases d'écart
## sur x=58-66, y=70, le seul segment resté clairement dégagé dans les deux passes précédentes
## (cloture_brisee, banderole_fouilles y étaient nets).
##   godot --path Godot --script res://tools/capture.gd -- out=<dossier> scenario_file=res://tools/scenarios/jp_decors_a3.gd

const ST := "res://story/stage.gd"

const STEPS := [
	[0.85, "vsync", false], [0.86, "talk", true],
	[1.0, "zone", &"plaines"], [1.1, "calm", 900.0], [1.2, "weather", &"clear"], [1.3, "clock", 11.0],
	[2.5, "static", [ST, "show_thing", "griffe_fossile", Vector2(58.0, 70.0), "D_griffe_fossile"]],
	[2.6, "static", [ST, "show_thing", "creme_raser", Vector2(60.0, 70.0), "D_creme_raser"]],
	[2.7, "static", [ST, "show_thing", "coffre_comptoir", Vector2(62.0, 70.0), "D_coffre_comptoir"]],
	[2.8, "static", [ST, "show_thing", "table_cuisine", Vector2(64.0, 70.0), "D_table_cuisine"]],
	[2.9, "static", [ST, "show_thing", "flaque_ronde", Vector2(66.0, 70.0), "D_flaque_ronde"]],
	[4.0, "tp", Vector2(58.0, 71.0)], [4.1, "face", Vector2(0, -1)], [4.5, "shot", "jp_griffe_fossile"],
	[4.7, "tp", Vector2(60.0, 71.0)], [4.8, "face", Vector2(0, -1)], [5.2, "shot", "jp_creme_raser"],
	[5.4, "tp", Vector2(62.0, 71.3)], [5.5, "face", Vector2(0, -1)], [5.9, "shot", "jp_coffre_comptoir"],
	[6.1, "tp", Vector2(64.0, 71.3)], [6.2, "face", Vector2(0, -1)], [6.6, "shot", "jp_table_cuisine"],
	[6.8, "tp", Vector2(66.0, 71.2)], [6.9, "face", Vector2(0, -1)], [7.3, "shot", "jp_flaque_ronde"],
	[7.6, "state", null],
]
