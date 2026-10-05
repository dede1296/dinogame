extends SceneTree
## The 2.5D mobile game still starts (docs/migration-3d.md: world3d/ is additive, the 2.5D must not
## move). Loads the real main scene (scenes/boot/boot.tscn), starts a new game, and lets the Port
## d'Ambre play a few seconds — which runs the story's scenes and Stage's moves on the 2.5D.
##   godot --path Godot --script res://tools/test_boot_25d.gd -- out=<folder> [secs=8]
## Prints PASS / FAIL, saves screenshots, quits with 1 on any failure. A window is needed.
## (Game classes are used through the nodes only: this script is compiled before the autoloads.)

const BOOT := "res://scenes/boot/boot.tscn"
## Written on every picture of the run: what the whole test checks.
const CAPTION := "Le 2,5D mobile démarre toujours — écran titre, nouvelle partie, scènes du Port d'Ambre (Stage inchangé)"

var _out := "user://test_boot_25d"
var _secs := 8.0
var _failed := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("secs="):
			_secs = float(arg.substr(5))
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_boot_25d.json")   # never the player's save
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_boot_25d.json"))
	change_scene_to_file(BOOT)
	_run()


func _run() -> void:
	# one banner for the whole run (Greg, 04/10: what is checked, in general, left up)
	var banner := ShotCaption.show_on(self, CAPTION)
	await create_timer(1.0).timeout
	var boot := current_scene
	_check("the title screen opens", boot != null and boot.name == "Boot", "%s" % [boot])
	await _shot("boot_00_ecran_titre")
	var new_game: Button = boot.get_node("%NewGame") if boot else null
	_check("its « Nouvelle partie » button is there", new_game != null, "%s" % [new_game])
	if new_game:
		new_game.pressed.emit()
	await create_timer(_secs).timeout
	var world := current_scene
	_check("a new game opens the 2.5D world", world != null and world.get("region") != null, "%s" % [world])
	var player: Node2D = world.get("player") if world else null
	_check("Chloé stands in it", player != null and player.global_position != Vector2.ZERO,
		"%s" % [player.global_position if player else null])
	await _shot("boot_01_monde_25d")
	banner.queue_free()
	print("TEST boot 2,5D : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


## A picture of the test, under the banner put up for the whole run.
func _shot(file_name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(file_name + ".png"))
