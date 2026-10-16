extends RefCounted
## Le cache des reliefs (HeightMap.of) : le même relief que HeightMap.new, mesuré une seule fois.
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/relief_cache_test.gd titre="Cache des reliefs : mêmes hauteurs, mesure unique"

const SELF := "res://tools/scenarios/relief_cache_test.gd"
const ZONES := ["res://regions/cieux/cieux.tscn", "res://regions/cieux/nids_geants.tscn", "res://regions/monts/monts.tscn"]
const PROBES: Array[Vector2] = [Vector2(300, 300), Vector2(1200, 900), Vector2(2000, 1500), Vector2(55, 2500)]

const STEPS := [
	[0.60, "flags", ["prologue_done", "tuto_commandes"]], [0.70, "static", [SELF, "mesurer", ""]], [2.0, "state", null],
]


static func mesurer(_arg: String) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var maps: GDScript = load("res://world/view3d/height_map.gd")
	var failed := 0
	var report := ""
	for path: String in ZONES:
		var region: Node = (load(path) as PackedScene).instantiate()
		tree.root.add_child(region)
		var t0 := Time.get_ticks_usec()
		var fresh = maps.new(region, 4)
		var t_new := (Time.get_ticks_usec() - t0) / 1000.0
		t0 = Time.get_ticks_usec()
		var first = maps.call("of", region, 4)
		var t_first := (Time.get_ticks_usec() - t0) / 1000.0
		t0 = Time.get_ticks_usec()
		var again = maps.call("of", region, 4)
		var t_again := (Time.get_ticks_usec() - t0) / 1000.0
		var same := true
		for p in PROBES:
			same = same and is_equal_approx(fresh.call("to_3d", p).y, again.call("to_3d", p).y) \
				and is_equal_approx(fresh.call("to_3d", p).y, first.call("to_3d", p).y)
		failed += 0 if same else 1
		report += "RELIEF %s : new %.0f ms, of 1re %.0f ms, of 2e %.0f ms, mêmes hauteurs : %s\n" % [path.get_file(), t_new, t_first, t_again, same]
		region.queue_free()
	report += "TEST relief : %s (%d échec(s))" % ["OK" if failed == 0 else "ÉCHEC", failed]
	print(report)
	return report
