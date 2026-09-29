extends SceneTree
## Generates a zone scene from its plan in tools/zones/<id>.gd (see ZoneBuilder). Once
## generated, the scene is edited in Godot; rebuilding it needs --force and loses those edits.
##   godot --headless --path Godot --script res://tools/build_zone.gd -- <id> [--force]
## (Scripts are loaded at run time: the game's classes need the autoloads, which a
## --script main loop only gets after it is compiled.)


func _initialize() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var ids := args.filter(func(a: String) -> bool: return not a.begins_with("--"))
	if ids.is_empty():
		push_error("Usage : --script res://tools/build_zone.gd -- <id> [--force]")
		quit(1)
		return
	var plan: GDScript = load("res://tools/zones/%s.gd" % ids[0])
	if plan == null:
		quit(1)
		return
	var builder: GDScript = load("res://tools/zone_builder.gd")
	var zone: Node = plan.build()
	var path: String = plan.PATH
	var err: Error = builder.save(zone, path, "--force" in args)
	print("Zone : ", path, " -> ", error_string(err))
	zone.free()
	if err == OK:   # its habitats may have changed: the Dinodex's hints follow (data/dex_places.gd)
		print(load("res://tools/gen_dex.gd").write())
	quit(0 if err == OK else 1)
