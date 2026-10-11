extends SceneTree
## La lumière du PC (11/10) : brouillard volumétrique, occlusion ambiante et flou de profondeur
## (world/view3d/pc_light.gd). Vérifie qu'ils s'allument à qualité Haute en Forward+, qu'ils
## s'éteignent aux autres niveaux, que le brouillard disparaît la nuit et à l'intérieur, et que le
## flou suit la distance de la caméra.
##   godot --path Godot --script res://tools/test_lumiere_pc.gd -- out=<dossier>
## Écrit PASS / FAIL, enregistre les captures, sort en 1 au moindre échec. Il faut une fenêtre.

const WORLD := "res://world/world.tscn"
## (PcLight lit l'autoload Quality : ce script est compilé avant les autoloads, donc on le charge à l'exécution.)
const PC_LIGHT := "res://world/view3d/pc_light.gd"
const CAPTION := "Lumière PC : brouillard volumétrique et SSAO à Haute seulement, nuit sans rayons, flou calé sur la caméra"

var _out := "user://test_lumiere_pc"
var _failed := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_lumiere_pc.json")
	var game := root.get_node("Game")
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	game.call("set_flag", &"prologue_done")
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	await create_timer(1.5).timeout
	var quality := root.get_node("Quality")
	var game := root.get_node("Game")
	var view: Node = current_scene.get("_view")
	var env: Environment = view.get("_env")
	var camera: Camera3D = view.get("camera")
	var saved_level: int = quality.get("level")
	var pc_light: GDScript = load(PC_LIGHT)

	_check("le rendu est Forward+ (le PC)", pc_light.call("available"), RenderingServer.get_current_rendering_method())

	# 1. qualité Haute en plein jour
	quality.call("set_level", 2)
	game.set("clock", 7.0 * 60.0)
	await create_timer(0.8).timeout
	_check("Haute : le brouillard volumétrique est allumé", env.volumetric_fog_enabled)
	_check("Haute : l'occlusion ambiante est allumée", env.ssao_enabled)
	_check("à l'aube, l'air a de l'épaisseur", env.volumetric_fog_density > 0.005, "%.4f" % env.volumetric_fog_density)
	var dawn := env.volumetric_fog_density
	await _shot("lum_00_haute_aube")

	# 2. soleil haut : plus fin qu'à l'aube
	game.set("clock", 12.5 * 60.0)
	await create_timer(0.8).timeout
	_check("à midi l'air est plus fin qu'à l'aube", env.volumetric_fog_density < dawn,
		"%.4f < %.4f" % [env.volumetric_fog_density, dawn])

	# 3. la nuit : pas de soleil, pas de rayons
	game.set("clock", 1.0 * 60.0)
	await create_timer(0.8).timeout
	_check("la nuit, plus de brouillard éclairé", env.volumetric_fog_density < 0.001, "%.5f" % env.volumetric_fog_density)
	await _shot("lum_01_nuit")
	game.set("clock", 7.0 * 60.0)

	# 4. les autres niveaux éteignent tout
	for level in [0, 1]:
		quality.call("set_level", level)
		await create_timer(0.5).timeout
		_check("niveau %d : brouillard volumétrique éteint" % level, not env.volumetric_fog_enabled)
		_check("niveau %d : occlusion ambiante éteinte" % level, not env.ssao_enabled)

	# 5. le flou suit la caméra
	quality.call("set_level", 2)
	await create_timer(0.5).timeout
	var attributes := camera.attributes as CameraAttributesPractical
	_check("Haute : le flou de profondeur est allumé", attributes.dof_blur_far_enabled)
	await process_frame
	await process_frame   # (le flou est mis à jour après la caméra : une image de retard possible)
	var shown: float = camera.call("shown_distance")
	print("   distance de la caméra : ", shown, " ; flou net jusqu'à ", attributes.dof_blur_far_distance)
	_check("la netteté s'étend au-delà de la caméra",
		is_equal_approx(attributes.dof_blur_far_distance, shown + float(pc_light.get("DOF_MARGIN"))),
		"%.1f vs %.1f" % [attributes.dof_blur_far_distance, shown + float(pc_light.get("DOF_MARGIN"))])
	var wide := attributes.dof_blur_amount
	pc_light.call("update_dof", attributes, 6.0)   # un gros plan de scène
	_check("en gros plan, le fond se défait davantage", attributes.dof_blur_amount > wide,
		"%.3f > %.3f" % [attributes.dof_blur_amount, wide])

	quality.call("set_level", saved_level)
	banner.queue_free()
	print("TEST lumière PC : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, name])
