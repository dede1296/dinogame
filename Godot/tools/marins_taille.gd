extends SceneTree
## The sea reptiles that carry Chloé in the water are sized by their LENGTH (their drawing, neck
## raised, is as high as it is long: the gabarit rule made them too small to carry a girl of
## 1.50 m). Writes world_scale in data/species/<id>.tres so that the drawn length of the
## standing picture is LENGTH_M (m). Run again when a sheet changes. Prints before / after.
##   godot --headless --path Godot --script res://tools/marins_taille.gd

const LENGTH_M := {&"plesiosaurus": 3.3, &"ichthyosaurus": 2.9, &"elasmosaurus": 4.6, &"archelon": 2.9}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var db = load("res://data/species_db.gd")
	var size = load("res://actors/dino_size.gd")
	for id: StringName in LENGTH_M:
		var sp = db.get_species(id)
		var r: Rect2 = size.drawn(sp)
		var scale: float = snappedf(LENGTH_M[id] * 48.0 / r.size.x, 0.001)
		var path := "res://data/species/%s.tres" % id
		var text := FileAccess.get_file_as_string(path)
		var re := RegEx.create_from_string("(?m)^world_scale = [0-9.]+$")
		var before: float = sp.world_scale
		text = re.sub(text, "world_scale = %s" % str(scale))
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(text)
		f.close()
		print("%s : dessin %dx%d px, world_scale %.3f -> %.3f : %.2f m de long x %.2f m de haut" % [id, r.size.x, r.size.y, before, scale,
			r.size.x * scale / 48.0, size.height_m(sp, scale)])
	quit()
