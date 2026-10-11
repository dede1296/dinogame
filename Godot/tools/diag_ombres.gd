extends SceneTree
## Diagnostic (11/10) : « les ombres des sprites en journée vibrent ». Chloé immobile à midi : on
## enregistre N images de suite autour d'elle et on mesure ce qui change d'une image à l'autre. Une
## scène immobile ne doit presque pas changer ; une ombre qui vibre change à chaque image.
##   godot --path Godot --script res://tools/diag_ombres.gd -- out=<dossier> variant=<nom> [hour=12.5]
## Variantes : base, sans_soleil (ombres du soleil coupées), sans_sprites (les sprites ne projettent
## plus), sans_flou, sans_pc (SSAO + brouillard volumétrique coupés), sans_respiration.

const WORLD := "res://world/world.tscn"
const FRAMES := 90
const CROP := 220

var _out := "user://diag_ombres"
var _variant := "base"
var _hour := 12.5


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("variant="):
			_variant = arg.substr(8)
		elif arg.begins_with("hour="):
			_hour = float(arg.substr(5))
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://diag_ombres.json")
	var game := root.get_node("Game")
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	game.call("set_flag", &"prologue_done")
	game.call("set_flag", &"tuto_commandes")
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	var banner := ShotCaption.show_on(self, "Diagnostic ombres : variante « %s », midi, Chloé immobile" % _variant)
	await create_timer(1.5).timeout
	var game := root.get_node("Game")
	var world := current_scene
	var view: Node = world.get("_view")
	game.call("set_weather", &"clear")
	game.set("clock", _hour * 60.0)
	_apply_variant(view)
	await create_timer(3.0).timeout
	var player: Node2D = world.get("player")
	var camera: Camera3D = view.get("camera")
	var feet: Vector3 = view.get("heights").call("to_3d", player.global_position)
	var centre := camera.unproject_position(feet)
	var rect := Rect2i(Vector2i(centre) - Vector2i(CROP, CROP), Vector2i(CROP * 2, CROP * 2))
	var previous: Image = null
	var series: PackedFloat32Array = []   # luminosité moyenne de l'ombre d'un PNJ, image par image
	var diffs: PackedFloat32Array = []
	var peaks: PackedFloat32Array = []
	for i in FRAMES:
		await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_viewport().get_texture().get_image().get_region(rect)
		shot.convert(Image.FORMAT_L8)
		series.append(_box_mean(shot, Rect2i(290, 165, 60, 40)))
		if previous != null:
			var mean := 0.0
			var peak := 0
			var data := shot.get_data()
			var before := previous.get_data()
			for j in data.size():
				var d := absi(int(data[j]) - int(before[j]))
				mean += d
				peak = maxi(peak, d)
			diffs.append(mean / data.size())
			peaks.append(peak)
		if i == 20 or i == 21:
			shot.save_png("%s/%s_f%d.png" % [_out, _variant, i])
		previous = shot
	var total := 0.0
	var worst := 0.0
	for d in diffs:
		total += d
	for p in peaks:
		worst = maxf(worst, p)
	var flips := 0
	for i in range(2, series.size()):
		if (series[i] - series[i - 1]) * (series[i - 1] - series[i - 2]) < -0.0001:
			flips += 1
	print("   ombre du PNJ : min %.2f max %.2f ; %d changements de sens sur %d images" % [_min(series), _max(series), flips, series.size()])
	print("DIAG %-18s écart moyen par image %.4f / 255 ; pic %d" % [_variant, total / diffs.size(), int(worst)])
	banner.queue_free()
	quit()


func _box_mean(image: Image, box: Rect2i) -> float:
	var total := 0.0
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			total += image.get_pixel(x, y).r
	return total / (box.size.x * box.size.y) * 255.0


func _min(values: PackedFloat32Array) -> float:
	var lowest := 1000.0
	for v in values:
		lowest = minf(lowest, v)
	return lowest


func _max(values: PackedFloat32Array) -> float:
	var highest := -1000.0
	for v in values:
		highest = maxf(highest, v)
	return highest


func _apply_variant(view: Node) -> void:
	var sun: DirectionalLight3D = view.get("_sun")
	var env: Environment = view.get("_env")
	match _variant:
		"sans_soleil":
			sun.shadow_enabled = false
		"sans_flou":
			sun.shadow_blur = 0.0
		"filtre_dur":   # le filtre de bord des ombres du soleil (bruit) coupé
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
		"ortho":
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		"un_seul_decoupage":
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			sun.directional_shadow_split_1 = 0.99
		"biais":
			sun.shadow_bias = 0.08
			sun.shadow_normal_bias = 2.0
		"sans_msaa":
			root.msaa_3d = Viewport.MSAA_DISABLED
		"alpha_discard":   # le découpage d'alpha de l'image qui projette l'ombre
			for proxy: Dictionary in view.get("_proxies"):
				var vis := proxy.get("vis") as SpriteBase3D
				if vis:
					vis.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		"alpha_hash":
			for proxy: Dictionary in view.get("_proxies"):
				var vis := proxy.get("vis") as SpriteBase3D
				if vis:
					vis.alpha_cut = SpriteBase3D.ALPHA_CUT_HASH
		"sans_mipmaps":
			for proxy: Dictionary in view.get("_proxies"):
				var vis := proxy.get("vis") as SpriteBase3D
				if vis:
					vis.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		"res_distance":   # la 1re zone d'ombre couvre ce qu'on voit (le jeu : 4,5 m puis 45 m)
			sun.directional_shadow_max_distance = 26.0
			sun.directional_shadow_split_1 = 0.5
		"res_8192":
			sun.directional_shadow_max_distance = 26.0
			sun.directional_shadow_split_1 = 0.5
			RenderingServer.directional_shadow_atlas_set_size(8192, true)
		"res_4splits":
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			sun.directional_shadow_max_distance = 30.0
			sun.directional_shadow_split_1 = 0.2
			sun.directional_shadow_split_2 = 0.45
			sun.directional_shadow_split_3 = 0.75
			RenderingServer.directional_shadow_atlas_set_size(8192, true)
		"sans_pc":
			env.ssao_enabled = false
			env.volumetric_fog_enabled = false
		"sans_sprites":
			for proxy: Dictionary in view.get("_proxies"):
				var vis: GeometryInstance3D = proxy.get("vis")
				if vis:
					vis.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		"sans_respiration":
			root.get_node("Quality").set_meta(&"x", 1)
			var motion := load("res://world/view3d/sprite_motion.gd")
			motion.set("enabled", false)
