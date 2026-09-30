extends RefCounted
## Helper of the web scenario (« static » command of tools/capture.gd): pretends the game runs in
## a browser (Quality.WEB), so the big scenery keeps its picture and no 3D model is ever loaded —
## the web export ships without assets/models.


static func as_web() -> String:
	Quality.WEB = true
	Quality.changed.emit()   # (the view re-reads the quality: glow and exposure follow)
	return "mode web : décors 3D = %s" % Quality.setting(&"relief_props")


## Which big scenery is shown as a real 3D model right now (should be none in web mode).
static func models() -> String:
	var view := (Engine.get_main_loop() as SceneTree).get_first_node_in_group(&"world_view")
	var n := 0
	for p in view.get("_proxies"):
		if p["vis"] is MeshInstance3D:
			n += 1
	return "décors affichés en 3D : %d" % n
