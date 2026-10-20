extends RefCounted
## Ce que coûte la mini-carte (Minimap), mesuré dans le jeu : juste après l'arrivée et la bascule en grande
## (comme minimap_test.gd), puis à l'arrêt et en marchant, petite, grande, masquée (la référence) — µs passées
## dans la mini-carte par image (son _process, ses dessins de la texture, ses calques), images par seconde,
## pire image. Voir tools/capture.gd :
##   godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##       scenario_file=res://tools/scenarios/minimap_perf.gd "titre=Mini-carte : ce qu'elle coûte"

const SELF := "res://tools/scenarios/minimap_perf.gd"

const STEPS := [
	[0.80, "flags", ["sceau_plaines", "met_maia", "found_journal_1", "havre_arrive", "ferreol_rencontre"]],
	[0.82, "calm", 900.0],
	[0.84, "weather", &"clear"],
	[0.86, "clock", 11.0],
	[0.88, "talk", true],
	[0.90, "static", ["res://tools/scenarios/minimap_test.gd", "reset"]],
	[0.95, "static", [SELF, "watch"]],
	[1.00, "tp", Vector2(60.0, 47.0)],
	[3.00, "static", [SELF, "mark", "arrivée (téléportée)"]],
	[3.60, "press", "minimap"],
	[4.60, "static", [SELF, "mark", "grande, sa 1re seconde"]],
	[4.70, "press", "minimap"],
	[4.80, "press", "minimap"],
	[5.00, "static", [SELF, "mark", "(retour à la petite)"]],
	[9.00, "static", [SELF, "mark", "petite, à l'arrêt"]],
	[9.05, "hold", "move_left"],
	[13.0, "hold", ""],
	[13.05, "static", [SELF, "mark", "petite, en marchant"]],
	[13.1, "press", "minimap"],
	[13.5, "static", [SELF, "mark", "(bascule)"]],
	[17.5, "static", [SELF, "mark", "grande, à l'arrêt"]],
	[17.55, "hold", "move_right"],
	[21.5, "hold", ""],
	[21.55, "static", [SELF, "mark", "grande, en marchant"]],
	[21.6, "press", "minimap"],
	[22.0, "static", [SELF, "mark", "(bascule)"]],
	[26.0, "static", [SELF, "mark", "masquée, à l'arrêt"]],
	[26.05, "hold", "move_left"],
	[30.0, "hold", ""],
	[30.05, "static", [SELF, "mark", "masquée, en marchant"]],
	[30.1, "press", "minimap"],
	[30.5, "shot", "perf_fin"],
]

static var _since := 0
static var _last_frame := 0
static var _worst_us := 0


## Every frame's length, to give the worst one between two marks.
static func watch() -> String:
	(Engine.get_main_loop() as SceneTree).process_frame.connect(func() -> void:
		var now := Time.get_ticks_usec()
		if _last_frame > 0:
			_worst_us = maxi(_worst_us, now - _last_frame)
		_last_frame = now)
	return "mesure des images"


## What it cost since the last mark: per frame, the minimap's own work (process + texture + layers).
static func mark(label: String) -> String:
	var now := Time.get_ticks_usec()
	var frames := maxi(Minimap.frames, 1)
	var seconds := (now - _since) / 1e6 if _since > 0 else 0.0
	var line := "%s : %.0f µs/image dans la mini-carte (process %.0f dont textures %.0f, dessins %.0f), %d textures, %.1f i/s, pire image %.1f ms" % [
		label, float(Minimap.cost_us + Minimap.draw_us) / frames, float(Minimap.cost_us) / frames,
		float(Minimap.render_us) / frames, float(Minimap.draw_us) / frames, Minimap.renders,
		Minimap.frames / seconds if seconds > 0.0 else 0.0, _worst_us / 1000.0]
	Minimap.cost_us = 0
	Minimap.draw_us = 0
	Minimap.render_us = 0
	Minimap.renders = 0
	Minimap.frames = 0
	_worst_us = 0
	_since = now
	return line
