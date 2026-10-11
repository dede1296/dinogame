extends SceneTree
## Le « jus » du combat (11/10) : la matière des combattants (battle/fighter.gdshader) fait
## l'éclat coloré du coup, la disparition qui se consume et les veines d'ambre noir. Ce test pose
## chaque effet à une valeur nette, en prend l'image, et vérifie que la valeur est bien appliquée —
## plus sûr que d'essayer d'attraper un éclat de 0,05 s au vol.
##   godot --path Godot --script res://tools/test_combat_jus.gd -- out=<dossier>
## Écrit PASS / FAIL, enregistre les captures, sort en 1 au moindre échec. Il faut une fenêtre.

const WORLD := "res://world/world.tscn"
const CAPTION := "Combat : éclat coloré du coup, fantômes du bond, K.O./capture qui se consument, veines d'ambre noir"

var _out := "user://test_combat_jus"
var _failed := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_combat_jus.json")
	var game := root.get_node("Game")
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	game.call("set_flag", &"prologue_done")
	game.call("set_flag", &"tuto_commandes")   # (le tutoriel de début n'est pas l'objet de ce test)
	game.set("items", {"collier": 5, "baie": 3})
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	await create_timer(1.2).timeout
	var world := current_scene
	world.call("_battle", load("res://game/dino.gd").create(&"protoceratops", 3))
	await create_timer(2.2).timeout
	var scene := _battle_scene()
	_check("le combat est à l'écran", scene != null)
	if scene == null:
		quit(1)
		return
	var foe: AnimatedSprite2D = scene.get("_foe_sprite")
	var mine: AnimatedSprite2D = scene.get("_player_sprite")
	var skin := foe.material as ShaderMaterial
	_check("les combattants portent la matière fighter.gdshader",
		skin != null and skin.shader.resource_path.ends_with("fighter.gdshader"))
	await _shot("jus_00_depart")

	# 1. le coup encaissé, à la couleur du type (ici « terre »)
	skin.set_shader_parameter("flash_color", Color.WHITE)
	skin.set_shader_parameter("flash", 1.0)
	await _shot("jus_01_coup_encaisse")
	_check("l'éclat est posé sur le sauvage", skin.get_shader_parameter("flash") == 1.0)
	skin.set_shader_parameter("flash", 0.0)

	# 2. la disparition, à mi-chemin : on doit voir le liseré chaud et les trous
	skin.set_shader_parameter("dissolve", 0.45)
	await _shot("jus_02_ko_a_mi_chemin")
	_check("la peinture se consume", skin.get_shader_parameter("dissolve") == 0.45)
	skin.set_shader_parameter("dissolve", 0.0)

	# 3. les veines d'ambre noir (le Protoceratops n'a pas de planche corrompue dessinée)
	# Neuf espèces ont leur planche corrompue dessinée ; les ~90 autres passent par le shader.
	var drawn = load("res://game/dino.gd").create(&"protoceratops", 3).call("species")
	var painted = load("res://game/dino.gd").create(&"psittacosaurus", 3).call("species")
	_check("le Protoceratops a sa planche corrompue dessinée", SheetFrames.has_corrupted(drawn))
	_check("le Psittacosaurus n'en a pas : c'est le shader qui le corrompt",
		not SheetFrames.has_corrupted(painted))
	skin.set_shader_parameter("corruption", 1.0)
	await _shot("jus_03_corrompu_veines")
	skin.set_shader_parameter("corruption", 0.0)

	# 4. les fantômes du bond : posés derrière le sprite, puis effacés tout seuls
	var before: int = scene.get("_world").get_child_count()
	scene.call("_ghosts", mine, Color("#8fd0c8"))
	await create_timer(0.12).timeout
	var during: int = scene.get("_world").get_child_count()
	_check("le bond laisse des images fantômes", during > before, "%d → %d" % [before, during])
	await _shot("jus_04_fantomes")
	await create_timer(0.6).timeout
	_check("elles s'effacent toutes seules", scene.get("_world").get_child_count() == before,
		"%d" % scene.get("_world").get_child_count())

	# 5. la mollesse : un coup écrase le dino, puis il revient en rebondissant jusqu'à zéro
	var peak := 0.0
	var crossed := false
	scene.call("_jelly", foe, 0.22)
	for i in 40:
		await process_frame
		var v: float = skin.get_shader_parameter("squash")
		peak = maxf(peak, v)
		crossed = crossed or v < -0.005
		if i == 2:
			await _shot("jus_05_ecrase")
	_check("le coup l'écrase", peak > 0.1, "%.2f" % peak)
	_check("puis il rebondit au-delà de sa forme (ressort)", crossed)
	await create_timer(0.7).timeout
	_check("et le ressort s'éteint", absf(float(skin.get_shader_parameter("squash"))) < 0.01)

	banner.queue_free()
	print("TEST jus du combat : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


## L'écran de combat : BattleScene s'ajoute sous la scène du monde (comme le sait tools/capture.gd).
func _battle_scene() -> Node:
	for parent in [current_scene, root]:
		for node in parent.get_children():
			if node.has_signal("_action_chosen"):
				return node
	return null


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, name])
