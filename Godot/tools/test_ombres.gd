extends SceneTree
## Les ombres aplaties (11/10, world/view3d/ombre_aplatie.gd) : chaque image jette sa silhouette au
## sol, à l'opposé du soleil. Vérifie :
##  (a) les genres qui n'avaient pas d'ombre (clôture, hautes herbes) en ont une, qui s'allonge et
##      tourne avec l'heure (7 h, 12 h 30, 18 h 30) ;
##  (b) la nuit, pas d'ombre (au plus un léger halo sous la lune) ;
##  (c) sous la pluie, plus pâle et plus douce ;
##  (d) qualité Basse : l'ombre de contact seule ;
##  (e) stabilité : l'ombre d'un PNJ à midi ne vibre pas plus qu'avec l'ombre-carte du soleil ;
##  (f) l'ombre suit l'animation (un dino qui marche : l'image courante) et le vent ;
##  (g) l'ombre part du pied : écart pied → début de l'ombre ≤ 2 px à l'écran (1600 × 900), pour
##      des décors (buisson, rocher, fougères, clôture, hautes herbes, arbre, pieu) et Chloé, Vif,
##      un PNJ, à trois heures ; mesuré aussi avec l'ancienne ombre-carte, pour comparer.
##   godot --path Godot --script res://tools/test_ombres.gd --resolution 1600x900 -- out=<dossier>
## Écrit PASS / FAIL, enregistre les captures, sort en 1 au moindre échec. Il faut une fenêtre.

const WORLD := "res://world/world.tscn"
## (Ces scripts lisent les autoloads : ce script est compilé avant eux, on les charge à l'exécution.)
const FLAT := "res://world/view3d/ombre_aplatie.gd"
const KINDS := "res://world/view3d/shadow_kinds.gd"
const MOTION := "res://world/view3d/sprite_motion.gd"
const CAPTION := "Ombres aplaties : clôtures et herbes ont une ombre qui suit l'heure, la nuit, la pluie, l'animation, le vent ; Basse = contact seul ; stable ; partant du pied (≤ 2 px)"
const FLAGS := ["prologue_done", "tuto_commandes", "sceau_plaines", "havre_arrive", "met_maia", "found_journal_1", "selle", "foret_arrivee"]
## L'écart pied → ombre toléré (px à 1600 × 900).
const GAP_MAX := 2.0
## Le diagnostic des ombres qui vibrent (tools/diag_ombres.gd) : sa fenêtre et sa boîte.
const DIAG_FRAMES := 90
const DIAG_CROP := 220
const DIAG_BOX := Rect2i(290, 165, 60, 40)
## Ce qui change d'une capture à l'autre, en niveaux de 255 : une ombre, une silhouette.
const SHADE_STEP := 3
const SILHOUETTE_STEP := 10
const SEARCH := 14   # px : au-delà, « pas d'ombre au pied »

var _out := "user://test_ombres"
var _failed := 0
var _flat: GDScript
var _gaps := []      # [quoi, heure, ombre aplatie (px), ombre-carte (px)]
var _banner: CanvasLayer
var _only := ""
var _ref := Vector2.ZERO   # (le point de la zone d'où l'on cherche les décors à mesurer)


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("only="):
			_only = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://test_ombres.json")
	var game := root.get_node("Game")
	game.call("new_game")
	game.call("give_starter", &"velociraptor")
	for f in FLAGS:
		game.call("set_flag", StringName(f))
	_flat = load(FLAT)
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	_banner = ShotCaption.show_on(self, CAPTION)
	var banner := _banner
	await create_timer(1.5).timeout
	var quality := root.get_node("Quality")
	var saved_level: int = quality.get("level")
	quality.call("set_level", 2)
	await create_timer(0.5).timeout
	_quiet()

	if _only != "":   # (only=<genre> : la seule mesure du pied de ce genre, pour la regarder de près)
		await _goto(&"foret" if _only in ["cloture", "hautes_herbes", "pieu_corde", "arbre_rond"] else &"plaines", Vector2(24.0, 22.0) if _only in ["cloture", "hautes_herbes", "pieu_corde", "arbre_rond"] else Vector2(47.0, 70.0))
		await _prop_feet(_only)
		_report_gaps()
		quit(1 if _failed else 0)
		return
	await _stability()            # (e) au départ du jeu, comme tools/diag_ombres.gd
	await _animation()            # (f) l'image courante
	await _proxies_feet()         # (g) un PNJ (Port-Ambre), Chloé et Vif (la Prairie)
	await _goto(&"plaines", Vector2(47.0, 70.0))
	await _sun_course()           # (a) l'heure ; (b) la nuit ; (c) la pluie
	await _wind()                 # (f) le vent
	for kind in ["buisson", "rocher", "fougeres", KINDS_TUFT()]:
		await _prop_feet(kind)
	await _goto(&"foret", Vector2(24.0, 22.0))
	_check("la clôture et les hautes herbes ont une ombre (table des genres)",
		float(_kinds().call("for_kind", "cloture")["strength"]) > 0.0 and float(_kinds().call("for_kind", "hautes_herbes")["strength"]) > 0.0)
	_check("une ombre aplatie est posée pour les clôtures de la clairière", _shadow_chunks("cloture").size() > 0, "%d paquet(s)" % _shadow_chunks("cloture").size())
	for kind in ["cloture", "hautes_herbes", "pieu_corde", "arbre_rond"]:
		await _prop_feet(kind)
	for hour in [7.0, 12.5, 18.5]:
		await _set_hour(hour)
		await _shot("a_clotures_%s" % _hour_name(hour))
	await _basse()                # (d)
	_report_gaps()

	quality.call("set_level", saved_level)
	_flat.set("forced", -1)
	banner.queue_free()
	print("TEST ombres aplaties : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


# ------------------------------------------------------------------ (a) (b) (c) le soleil

func _sun_course() -> void:
	var states := {}
	for hour in [7.0, 12.5, 18.5]:
		await _set_hour(hour)
		states[hour] = _sun()
		print("   %s : ombre de %.2f m par m de hauteur, vers (%.2f, %.2f), force %.2f, douceur %.2f" % [
			_hour_name(hour), Vector2(states[hour].x, states[hour].y).length(), states[hour].x, states[hour].y, states[hour].z, states[hour].w])
		await _shot("b_prairie_%s" % _hour_name(hour))
	var noon := Vector2(states[12.5].x, states[12.5].y)
	var morning := Vector2(states[7.0].x, states[7.0].y)
	var evening := Vector2(states[18.5].x, states[18.5].y)
	_check("à 7 h l'ombre est plus longue qu'à 12 h 30", morning.length() > noon.length() * 1.5, "%.2f > %.2f" % [morning.length(), noon.length()])
	_check("à 18 h 30 l'ombre est plus longue qu'à 12 h 30", evening.length() > noon.length() * 1.5, "%.2f > %.2f" % [evening.length(), noon.length()])
	_check("elle tourne : vers l'est le matin, vers l'ouest le soir, vers le nord (loin de la caméra) à midi",
		morning.x > 0.3 and evening.x < -0.3 and noon.y < 0.0, "x matin %.2f, x soir %.2f, z midi %.2f" % [morning.x, evening.x, noon.y])
	_check("plafonnée : jamais plus de 2,1 m par m de hauteur", maxf(morning.length(), evening.length()) <= 2.1)
	# (b) la nuit
	await _set_hour(1.0)
	var night := _sun()
	_check("la nuit : pas d'ombre, au plus un léger halo de lune (≤ 25 % du plein jour)", night.z <= 0.25 and night.w > 0.4,
		"force %.2f, douceur %.2f" % [night.z, night.w])
	await _shot("c_prairie_nuit")
	# (c) la pluie
	await _set_hour(12.5)
	var clear := _sun()
	root.get_node("Game").call("set_weather", &"rain")
	await create_timer(7.0).timeout   # (la pluie arrive en quelques secondes : WorldView.WEATHER_BLEND)
	var rain := _sun()
	_check("sous la pluie : plus pâle et plus douce", rain.z < clear.z * 0.6 and rain.w > clear.w + 0.3,
		"force %.2f < %.2f, douceur %.2f > %.2f" % [rain.z, clear.z, rain.w, clear.w])
	await _shot("d_prairie_pluie")
	await _set_hour(12.5)


func _sun() -> Vector4:
	return _view().get("flat_shadows").call("sun_state")


# ------------------------------------------------------------------ (d) Basse

func _basse() -> void:
	var quality := root.get_node("Quality")
	_flat.set("forced", -1)   # (la qualité décide)
	quality.call("set_level", 0)
	await create_timer(1.0).timeout
	var view := _view()
	var overlays := 0
	for p: Dictionary in view.get("_proxies"):
		if p["vis"] is GeometryInstance3D and (p["vis"] as GeometryInstance3D).material_overlay != null:
			overlays += 1
	var contacts := 0
	for n in view.find_children("*", "MultiMeshInstance3D", true, false):
		var mesh: Mesh = (n as MultiMeshInstance3D).multimesh.mesh if (n as MultiMeshInstance3D).multimesh else null
		if mesh is PlaneMesh and mesh.material is ShaderMaterial and String((mesh.material as ShaderMaterial).shader.resource_path).contains("contact_shadow"):
			contacts += 1
	_check("Basse : pas d'ombres aplaties", not bool(view.get("flat_shadows").get("on")) and _shadow_chunks("").is_empty() and overlays == 0,
		"%d paquets, %d images" % [_shadow_chunks("").size(), overlays])
	_check("Basse : les ombres de contact restent", contacts > 0, "%d paquets" % contacts)
	await _shot("e_basse_contact_seul")
	quality.call("set_level", 2)
	await create_timer(1.0).timeout
	_quiet()


# ------------------------------------------------------------------ (e) la stabilité

## Comme tools/diag_ombres.gd (variante « base ») : Chloé immobile à midi, 90 images de suite, la
## luminosité de l'ombre du PNJ (la même boîte) ; combien de fois elle change de sens. Avec
## l'ancienne ombre-carte (forcée), puis avec les ombres aplaties.
func _stability() -> void:
	var flips := {}
	for mode in [0, 1]:
		_flat.set("forced", mode)
		_view().call("_apply_quality")
		await create_timer(0.6).timeout
		_quiet()
		await _set_hour(12.5)
		await create_timer(1.5).timeout
		var player: Node2D = current_scene.get("player")
		var camera: Camera3D = _view().get("camera")
		var feet: Vector3 = _view().get("heights").call("to_3d", player.global_position)
		var centre := camera.unproject_position(feet)
		var rect := Rect2i(Vector2i(centre) - Vector2i(DIAG_CROP, DIAG_CROP), Vector2i(DIAG_CROP * 2, DIAG_CROP * 2))
		var series := PackedFloat32Array()
		for i in DIAG_FRAMES:
			await process_frame
			await RenderingServer.frame_post_draw
			var shot := root.get_viewport().get_texture().get_image().get_region(rect)
			shot.convert(Image.FORMAT_L8)
			series.append(_box_mean(shot, DIAG_BOX))
		var count := 0
		for i in range(2, series.size()):
			if (series[i] - series[i - 1]) * (series[i - 1] - series[i - 2]) < -0.0001:
				count += 1
		flips[mode] = count
		print("   ombre du PNJ (%s) : %d changements de sens sur %d images" % ["ombre-carte" if mode == 0 else "aplatie", count, DIAG_FRAMES])
	_check("stabilité : l'ombre aplatie ne vibre pas plus que l'ombre-carte", flips[1] <= flips[0], "%d ≤ %d changements de sens" % [flips[1], flips[0]])
	_flat.set("forced", 1)
	_view().call("_apply_quality")
	await create_timer(0.6).timeout
	_quiet()


func _box_mean(image: Image, box: Rect2i) -> float:
	var total := 0.0
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			total += image.get_pixel(x, y).r
	return total / (box.size.x * box.size.y) * 255.0


# ------------------------------------------------------------------ (f) l'animation, le vent

## Vif marche à côté de Chloé : son ombre prend l'image courante de sa marche (au moins deux images
## différentes en une seconde, et toujours celle qui est affichée).
func _animation() -> void:
	await _set_hour(17.5)
	var vif := _proxy_of(current_scene.get("companion"))
	var seen := {}
	var matches := 0
	var frames := 0
	Input.action_press("move_right")
	for i in 70:
		await process_frame
		var vis := vif["vis"] as AnimatedSprite3D
		var last: Dictionary = vif.get("flat_last", {})
		if vis == null or not last.has(&"uv_rect"):
			continue
		var frame := vis.sprite_frames.get_frame_texture(vis.animation, vis.frame) as AtlasTexture
		if frame == null:
			continue
		var sheet := frame.atlas.get_size()
		var expected := Vector4(frame.region.position.x / sheet.x, frame.region.position.y / sheet.y, frame.region.size.x / sheet.x, frame.region.size.y / sheet.y)
		frames += 1
		if (last[&"uv_rect"] as Vector4).is_equal_approx(expected):
			matches += 1
		seen[last[&"uv_rect"]] = true
		if i == 40 or i == 46:
			await _shot("f_vif_marche_%d" % i)
	Input.action_release("move_right")
	_check("l'ombre de Vif qui marche change d'image (deux images au moins)", seen.size() >= 2, "%d images de sa marche" % seen.size())
	_check("…et c'est toujours l'image affichée", frames > 0 and matches >= frames - 1, "%d / %d" % [matches, frames])


## Le vent : l'ombre d'un buisson se balance avec lui (le même balancement que son image), et ce qui
## bouge à l'écran autour de lui bouge davantage avec son ombre que sans.
func _wind() -> void:
	await _set_hour(7.0)
	var chunks := _shadow_chunks("buisson")
	if chunks.is_empty():
		_check("le vent : un paquet d'ombres de buissons", false)
		return
	var shadow: MultiMeshInstance3D = chunks[0]
	var picture := _picture_of(shadow)
	var sway: Variant = (shadow.material_override as ShaderMaterial).get_shader_parameter("sway")
	var own: Variant = ((picture.multimesh.mesh as QuadMesh).material as ShaderMaterial).get_shader_parameter("sway")
	_check("le vent : l'ombre se balance comme son image", sway != null and float(sway) > 0.0 and is_equal_approx(float(sway), float(own)), "balancement %s / %s" % [sway, own])


# ------------------------------------------------------------------ (g) l'ombre part du pied

## L'écart pied → ombre d'un décor de genre `kind` (le plus près du milieu de l'écran), aux trois
## heures, avec les ombres aplaties puis avec l'ombre-carte d'avant.
func _prop_feet(kind: String) -> void:
	await _go_near(kind)
	for hour in [7.0, 12.5, 17.5]:
		var gaps := []
		var old_anchor := INF
		for mode in [1, 0]:
			_flat.set("forced", mode)
			_view().call("_apply_quality")
			await create_timer(0.5).timeout
			_quiet()
			await _set_hour(hour)
			gaps.append(await _prop_gap(kind, mode == 1, hour))
			if mode == 1:   # (pour comparer : l'ombre ancrée comme avant le 11/10, au point au sol)
				old_anchor = await _prop_gap(kind, true, hour, true)
		_gaps.append([kind, hour, gaps[0], gaps[1], old_anchor])
		_check("%s à %s : l'ombre part du pied" % [kind, _hour_name(hour)], gaps[0] <= GAP_MAX, "écart %.1f px (ombre-carte : %.1f px)" % [gaps[0], gaps[1]])
	_flat.set("forced", 1)
	_view().call("_apply_quality")
	await create_timer(0.5).timeout
	_quiet()


func _prop_gap(kind: String, flat: bool, hour: float, old_anchor := false) -> float:
	var pick := _pick_instance(kind)
	if pick.is_empty():
		print("   (pas de %s à l'écran)" % kind)
		return INF
	var picture: MultiMeshInstance3D = pick["picture"]
	var mm := picture.multimesh
	var index: int = pick["index"]
	var shadow: MultiMeshInstance3D = pick["shadow"]
	# Seul le décor choisi reste dans son paquet ; il ne bouge pas (sans vent) le temps des captures.
	var saved := []
	var twin: MultiMesh = shadow.multimesh if shadow and shadow.multimesh != mm else null
	for i in mm.instance_count:
		saved.append(mm.get_instance_custom_data(i))
		if i != index:
			var c: Color = saved[i]
			mm.set_instance_custom_data(i, Color(c.r, 0.0, 0.0, 0.0))
			if twin:
				twin.set_instance_custom_data(i, Color(c.r, 0.0, 0.0, 0.0))
	var calm := _calm_wind([picture, shadow])
	# Le décor et son ombre, chacun montré ou pas (l'ombre-carte sans l'image : « ombre seule »).
	var state := func(pic: bool, shade: bool) -> void:
		if flat:
			picture.visible = pic
			shadow.visible = shade
		else:
			picture.visible = pic or shade
			if not shade:
				picture.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			else:
				picture.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if pic else GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	var hidden := _isolate([picture, shadow])
	var base: Variant = (shadow.material_override as ShaderMaterial).get_shader_parameter("base") if shadow else null
	if old_anchor and shadow:
		(shadow.material_override as ShaderMaterial).set_shader_parameter("base", Vector2.ZERO)
	var gap: float = await _gap(pick["screen"], state, true, "g_pied_%s_%s_%s" % [kind, _hour_name(hour), ("ancrage_avant" if old_anchor else "aplatie") if flat else "carte"])
	if old_anchor and shadow:
		(shadow.material_override as ShaderMaterial).set_shader_parameter("base", base)
	_show_again(hidden)
	for i in mm.instance_count:
		mm.set_instance_custom_data(i, saved[i])
		if twin:
			twin.set_instance_custom_data(i, saved[i])
	_restore_wind(calm)
	state.call(true, true)
	return gap


## Chloé, Vif et le PNJ le plus proche, à Port-Ambre, aux trois heures.
func _proxies_feet() -> void:
	await _goto(&"port_ambre", Vector2(14.0, 12.0))   # (dans la rue : loin de l'eau, qui bouge)
	load(MOTION).set("enabled", false)   # (sans la respiration : rien ne bouge entre les captures)
	await _go_near_npc()
	await _feet_of(["PNJ"])
	await _goto(&"plaines", Vector2(52.0, 66.0))   # (de l'herbe rase, rien devant eux)
	await _feet_of(["Chloé", "Vif"])
	load(MOTION).set("enabled", true)
	_flat.set("forced", 1)
	_view().call("_apply_quality")
	await create_timer(0.6).timeout
	_quiet()


func _feet_of(names: Array) -> void:
	for hour in [7.0, 12.5, 17.5]:
		var gaps := {}
		for mode in [1, 0]:
			_flat.set("forced", mode)
			_view().call("_apply_quality")
			await create_timer(0.6).timeout
			_quiet()
			await _set_hour(hour)
			for who: String in names:
				var p := _proxy_named(who)
				if not p.is_empty():
					gaps["%s%d" % [who, mode]] = await _proxy_gap(p, mode == 1, "g_pied_%s_%s_%s" % [who, _hour_name(hour), "aplatie" if mode == 1 else "carte"])
					if mode == 1:
						gaps["%s2" % who] = await _proxy_gap(p, true, "g_pied_%s_%s_ancrage_avant" % [who, _hour_name(hour)], true)
		for who: String in names:
			if not gaps.has(who + "1"):
				print("   (%s introuvable)" % who)
				continue
			_gaps.append([who, hour, gaps[who + "1"], gaps.get(who + "0", INF), gaps.get(who + "2", INF)])
			_check("%s à %s : l'ombre part des pieds" % [who, _hour_name(hour)], gaps[who + "1"] <= GAP_MAX,
				"écart %.1f px (ombre-carte : %.1f px)" % [gaps[who + "1"], gaps.get(who + "0", INF)])


func _proxy_gap(p: Dictionary, flat: bool, name: String, old_anchor := false) -> float:
	var vis := p["vis"] as SpriteBase3D
	var sprite := p["sprite"] as CanvasItem   # (la vue recopie sa visibilité à chaque image)
	var mat := p.get("flat") as ShaderMaterial
	var strength: Variant = mat.get_shader_parameter("strength") if mat else null
	var camera: Camera3D = _view().get("camera")
	if flat and mat == null:
		return INF
	# (Rendue transparente, pas cachée : son ombre de contact reste, elle n'est pas « l'objet ». Son
	# ombre aplatie ne se montre pas sans elle : on mesure l'ombre qu'on voit.)
	var state := func(pic: bool, shade: bool) -> void:
		sprite.self_modulate.a = 1.0 if pic else 0.0
		if flat:
			mat.set_shader_parameter("strength", strength if shade else 0.0)
		else:
			vis.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shade else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Les autres personnages sans ombre le temps de la mesure (là où les ombres se croisent, la
	# première posée garde la place : celle mesurée n'y changerait rien).
	var others := []
	for q: Dictionary in _view().get("_proxies"):
		if q == p or not q["vis"] is SpriteBase3D:
			continue
		var other_mat := q.get("flat") as ShaderMaterial
		others.append([q["vis"], other_mat, other_mat.get_shader_parameter("strength") if other_mat else null, (q["vis"] as GeometryInstance3D).cast_shadow])
		if other_mat:
			other_mat.set_shader_parameter("strength", 0.0)
		(q["vis"] as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var at := camera.unproject_position(vis.global_position)
	var hidden := _isolate([vis])
	var last: Dictionary = p.get("flat_last", {})
	if old_anchor:   # (les pieds au point au sol, comme avant le 11/10 ; FlatShadows le redonne ensuite)
		var look: Vector4 = last.get(&"look", Vector4(0.0, 0.0, 0.01, 0.0))
		vis.set_instance_shader_parameter(&"look", Vector4(0.0, 0.0, look.z, look.w))
	var gap: float = await _gap(at, state, false, name)
	if old_anchor and last.has(&"look"):
		vis.set_instance_shader_parameter(&"look", last[&"look"])
	_show_again(hidden)
	state.call(true, true)
	for o in others:
		if o[1]:
			(o[1] as ShaderMaterial).set_shader_parameter("strength", o[2])
		(o[0] as GeometryInstance3D).cast_shadow = o[3]
	return gap


## Tout le reste caché le temps d'une mesure (les autres décors et leurs ombres, les autres
## personnages) : seuls l'objet mesuré, son ombre et le sol. Rend de quoi tout remontrer.
func _isolate(keep: Array) -> Array:
	var hidden := []
	for n in _view().find_children("*", "MultiMeshInstance3D", true, false):
		var inst := n as MultiMeshInstance3D
		if inst in keep or not inst.visible or inst.multimesh == null or not inst.multimesh.mesh is QuadMesh:
			continue
		inst.visible = false
		hidden.append(inst)
	for p: Dictionary in _view().get("_proxies"):
		var sprite := p["sprite"] as CanvasItem
		if p["vis"] in keep or sprite == null or not sprite.visible:
			continue
		sprite.visible = false   # (la vue recopie cette visibilité)
		hidden.append(sprite)
	return hidden


func _show_again(hidden: Array) -> void:
	for n in hidden:
		if is_instance_valid(n):
			n.visible = true


## L'écart (px) entre le bas de la silhouette d'un objet et son ombre, autour de `near` (px).
## `state(image, ombre)` montre l'un, l'autre, les deux ou rien. La silhouette : ce qui change quand
## on enlève l'objet ; l'ombre : ce qui s'assombrit quand on la met — sans l'objet devant quand
## `alone` (l'ombre seule : son départ, même caché derrière lui), sinon celle qu'on voit. On cherche
## l'ombre la plus proche de la bande du bas de la silhouette (ses pieds).
func _gap(near: Vector2, state: Callable, alone: bool, name: String) -> float:
	Engine.time_scale = 0.0   # (rien ne bouge entre les captures : animations, pas, vent du jeu)
	var hidden := []          # (ni l'interface ni ses invites « E », qui s'allument et s'éteignent)
	for layer in root.find_children("*", "CanvasLayer", true, false):
		if layer != _banner and (layer as CanvasLayer).visible:
			(layer as CanvasLayer).visible = false
			hidden.append(layer)
	state.call(true, false)
	var picture_shot := await _capture()   # l'objet, sans son ombre
	state.call(false, false)
	var empty := await _capture()          # ni l'un ni l'autre
	state.call(not alone, true)
	var full := await _capture()           # son ombre (l'objet devant, ou l'ombre seule)
	state.call(true, true)
	for layer in hidden:
		(layer as CanvasLayer).visible = true
	Engine.time_scale = 1.0
	var bare := picture_shot if not alone else empty
	if OS.get_environment("OMBRES_DEBUG") != "" and name.contains(OS.get_environment("OMBRES_DEBUG")):
		full.save_png("%s/%s_brut_avec.png" % [_out, name])
		bare.save_png("%s/%s_brut_sans.png" % [_out, name])
		picture_shot.save_png("%s/%s_brut_objet.png" % [_out, name])
	var size := full.get_size()
	var box := Rect2i(Vector2i(near) - Vector2i(170, 230), Vector2i(340, 300)).intersection(Rect2i(Vector2i.ZERO, size))
	var a := full.get_region(box)
	var b := bare.get_region(box)
	var c := empty.get_region(box)
	var o := picture_shot.get_region(box)
	for img: Image in [a, b, c, o]:
		img.convert(Image.FORMAT_RGB8)
	var da := a.get_data()
	var db := b.get_data()
	var dc := c.get_data()
	var do_ := o.get_data()
	var w := box.size.x
	var h := box.size.y
	var shade := PackedByteArray()
	shade.resize(w * h)
	var body := PackedByteArray()
	body.resize(w * h)
	var lowest := -1
	var top := h
	# Les pieds : pas plus bas que ça sous le point de l'objet (px), et pas trop loin de côté (ce qui
	# bouge ailleurs à l'écran, l'eau, un PNJ, n'est pas l'objet).
	var feet_limit := int(near.y) - box.position.y + 45
	var side := int(near.x) - box.position.x
	for y in h:
		var in_row := 0
		for x in w:
			var i := (y * w + x) * 3
			var la := 0.2126 * da[i] + 0.7152 * da[i + 1] + 0.0722 * da[i + 2]
			var lb := 0.2126 * db[i] + 0.7152 * db[i + 1] + 0.0722 * db[i + 2]
			if lb - la >= SHADE_STEP:
				shade[y * w + x] = 1
			if maxi(maxi(absi(do_[i] - dc[i]), absi(do_[i + 1] - dc[i + 1])), absi(do_[i + 2] - dc[i + 2])) >= SILHOUETTE_STEP:
				body[y * w + x] = 1
				if y <= feet_limit and absi(x - side) < 150:
					in_row += 1
		# (Une ligne d'au moins 3 pixels : un pixel isolé, le bout d'une corde qui pend, n'est pas un pied.)
		if in_row >= 3:
			lowest = maxi(lowest, y)
			top = mini(top, y)
	_save_mask(a, shade, body, w, h, name)
	if lowest < 0:
		return INF
	var band := maxi(3, int((lowest - top) * 0.03))   # (ses dernières lignes : ses pieds)
	var best := INF
	for y in range(maxi(0, lowest - band), lowest + 1):
		for x in w:
			if body[y * w + x] == 0:
				continue
			for dy in range(-SEARCH, SEARCH + 1):
				var yy := y + dy
				if yy < 0 or yy >= h:
					continue
				for dx in range(-SEARCH, SEARCH + 1):
					var xx := x + dx
					if xx < 0 or xx >= w or shade[yy * w + xx] == 0 or (body[yy * w + xx] == 1 and not alone):
						continue
					best = minf(best, Vector2(dx, dy).length())
	# (Contre la silhouette : un pixel d'écart au plus, c'est le bord de l'objet.)
	return maxf(0.0, best - 1.0) if best < INF else INF


## La capture et, à côté, ce qui a été mesuré : en bleu l'objet, en rouge son ombre.
func _save_mask(shot: Image, shade: PackedByteArray, body: PackedByteArray, w: int, h: int, name: String) -> void:
	var marks := shot.duplicate() as Image
	for y in h:
		for x in w:
			if body[y * w + x] == 1:
				marks.set_pixel(x, y, marks.get_pixel(x, y).lerp(Color(0.2, 0.6, 1.0), 0.45))
			elif shade[y * w + x] == 1:
				marks.set_pixel(x, y, marks.get_pixel(x, y).lerp(Color(1.0, 0.2, 0.2), 0.55))
	var both := Image.create(w * 2 + 6, h, false, Image.FORMAT_RGB8)
	both.fill(Color.WHITE)
	both.blit_rect(shot, Rect2i(0, 0, w, h), Vector2i.ZERO)
	both.blit_rect(marks, Rect2i(0, 0, w, h), Vector2i(w + 6, 0))
	both.save_png("%s/%s.png" % [_out, name])


func _capture() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_viewport().get_texture().get_image()


# ------------------------------------------------------------------ trouver les choses

func _view() -> Node:
	return current_scene.get("_view")


func _kinds() -> GDScript:
	return load(KINDS)


func KINDS_TUFT() -> String:
	return String(_kinds().get("TUFT"))


## Les paquets d'ombres aplaties (de genre `kind` : leur image ; "" : tous).
func _shadow_chunks(kind: String) -> Array:
	var out := []
	for n in _view().find_children("*", "MultiMeshInstance3D", true, false):
		var mat := (n as MultiMeshInstance3D).material_override as ShaderMaterial
		if mat == null or not String(mat.shader.resource_path).contains("ombre_aplatie"):
			continue
		var picture := _picture_of(n)
		if kind == "" or (picture and _kind_of((picture.multimesh.mesh as QuadMesh).material) == kind):
			out.append(n)
	return out


## Le genre d'un paquet d'images (le matériau de ses billboards) : les touffes des cases d'herbes
## hautes (WorldView._tuft_mesh : base_shade 0,35), sinon le nom de son image.
func _kind_of(mat: Material) -> String:
	var shader_mat := mat as ShaderMaterial
	var tex := shader_mat.get_shader_parameter("tex") as Texture2D if shader_mat else null
	if tex == null:
		return ""
	var shade: Variant = shader_mat.get_shader_parameter("base_shade")
	if shade != null and float(shade) > 0.3:
		return KINDS_TUFT()
	return tex.resource_path.get_file().get_basename()


## L'image (le paquet de billboards) d'une ombre (FlatShadows.add_chunk : méta « picture »).
func _picture_of(shadow: MultiMeshInstance3D) -> MultiMeshInstance3D:
	return shadow.get_meta(&"picture") if shadow.has_meta(&"picture") else null


## Le décor de genre `kind` le plus près du milieu de l'écran : {picture, shadow, index, screen}.
func _pick_instance(kind: String) -> Dictionary:
	var camera: Camera3D = _view().get("camera")
	var size := Vector2(root.get_viewport().get_visible_rect().size)
	var best := {}
	var best_d := INF
	for n in _view().find_children("*", "MultiMeshInstance3D", true, false):
		var inst := n as MultiMeshInstance3D
		if inst.material_override != null or inst.multimesh == null or not inst.multimesh.mesh is QuadMesh:
			continue
		if _kind_of((inst.multimesh.mesh as QuadMesh).material) != kind:
			continue
		var shadow: MultiMeshInstance3D = null
		for m in _view().find_children("*", "MultiMeshInstance3D", true, false):
			if m != inst and m.has_meta(&"picture") and m.get_meta(&"picture") == inst:
				shadow = m
		for i in inst.multimesh.instance_count:
			var at := inst.multimesh.get_instance_transform(i).origin
			if camera.is_position_behind(at):
				continue
			var screen := camera.unproject_position(at)
			if screen.x < 200 or screen.y < 200 or screen.x > size.x - 200 or screen.y > size.y - 120:
				continue
			var d := screen.distance_to(size / 2.0)
			if d < best_d:
				best_d = d
				best = {"picture": inst, "shadow": shadow, "index": i, "screen": screen}
	return best


## Chloé va se poser à côté du décor de genre `kind` le plus proche d'elle (au sud-est : il est au
## milieu de la vue, elle ne le cache pas).
func _go_near(kind: String) -> void:
	var player: Node2D = current_scene.get("player")
	var here := Vector3(_ref.x, 0.0, _ref.y)   # (toujours le même point de la zone : le même choix d'une fois sur l'autre)
	var best := Vector3.INF
	var region: Node = current_scene.get("region")
	var region_size := Vector2(region.call("map_size"))
	# Tout ce qui est debout autour (sauf les touffes des herbes hautes) : un décor choisi doit être
	# seul, rien devant lui (vers la caméra) qui cacherait son pied.
	var others := []
	var candidates := []
	for n in _view().find_children("*", "MultiMeshInstance3D", true, false):
		var inst := n as MultiMeshInstance3D
		if inst.material_override != null or inst.multimesh == null or not inst.multimesh.mesh is QuadMesh:
			continue
		var own := _kind_of((inst.multimesh.mesh as QuadMesh).material)
		if own == KINDS_TUFT() and kind != KINDS_TUFT():
			continue
		for i in inst.multimesh.instance_count:
			var at := inst.multimesh.get_instance_transform(i).origin
			if own != KINDS_TUFT():
				others.append(at)
			var far := own == KINDS_TUFT() and Vector2(at.x - here.x, at.z - here.z).length() > 20.0   # (des milliers)
			if own == kind and not far and at.x > 2.0 and at.z > 2.0 and at.x < region_size.x - 3.0 and at.z < region_size.y - 4.0:
				candidates.append(at)
	var nearest := Vector3.INF   # (faute de mieux : le plus proche, même entouré)
	for at: Vector3 in candidates:
		if nearest == Vector3.INF or Vector2(at.x - here.x, at.z - here.z).length() < Vector2(nearest.x - here.x, nearest.z - here.z).length():
			nearest = at
		var ground := func(dz: float) -> StringName:
			return region.call("surface_at", Vector2(at.x, at.z + dz) * 48.0)
		# (Une touffe d'herbe haute : au bord sud de sa case, rien devant ; un autre décor : hors des herbes.)
		if (kind != KINDS_TUFT() and ground.call(0.0) == &"tall_grass") or ground.call(1.0) == &"tall_grass" or ground.call(0.0) == &"water":
			continue
		var alone := true
		for o: Vector3 in others:
			var d := Vector2(o.x - at.x, o.z - at.z)
			if d.length() > 0.05 and (d.length() < 2.0 or (absf(d.x) < 1.8 and d.y > 0.0 and d.y < 5.0)):
				alone = false
				break
		if alone and (best == Vector3.INF or Vector2(at.x - here.x, at.z - here.z).length() < Vector2(best.x - here.x, best.z - here.z).length()):
			best = at
	if best == Vector3.INF:
		best = nearest
	if best == Vector3.INF:
		print("   (pas de %s dans la zone)" % kind)
		return
	var spot := Vector2(best.x + 1.6, best.z + 2.6) * 48.0   # (elle est cachée le temps des mesures)
	print("   %s : Chloé va près de celui de (%.1f, %.1f)" % [kind, best.x, best.z])
	player.call("teleport", spot)
	current_scene.get("companion").call("stand_beside", spot + Vector2(96.0, 0.0))
	await create_timer(1.3).timeout
	_quiet()


func _proxy_of(node: Node) -> Dictionary:
	for p: Dictionary in _view().get("_proxies"):
		if p["src"] == node:
			return p
	return {}


func _proxy_named(who: String) -> Dictionary:
	match who:
		"Chloé":
			return _proxy_of(current_scene.get("player"))
		"Vif":
			return _proxy_of(current_scene.get("companion"))
	var player: Node2D = current_scene.get("player")
	var best := {}
	var best_d := INF
	for p: Dictionary in _view().get("_proxies"):
		if not _is_npc(p["src"]) or not p["vis"] is SpriteBase3D or not (p["vis"] as Node3D).visible:
			continue
		var d := (p["src"] as Node2D).global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = p
	return best


## Un PNJ (actors/npc.gd ; la classe lit les autoloads : par son chemin).
func _is_npc(node: Node) -> bool:
	return node != null and node.get_script() != null and (node.get_script() as Script).resource_path == "res://actors/npc.gd"


## Chloé va se poser au sud-est du PNJ le plus proche (il est au milieu de la vue).
func _go_near_npc() -> void:
	var p := _proxy_named("PNJ")
	if p.is_empty():
		return
	var spot: Vector2 = (p["src"] as Node2D).global_position + Vector2(2.8, 1.0) * 48.0
	current_scene.get("player").call("teleport", spot)
	current_scene.get("companion").call("stand_beside", spot + Vector2(96.0, 0.0))
	await create_timer(1.3).timeout
	_quiet()


# ------------------------------------------------------------------ le temps, la place

func _goto(zone: StringName, at: Vector2) -> void:
	_ref = at
	if root.get_node("Game").get("region_id") != zone:
		current_scene.call("goto_zone", zone)
		await create_timer(1.8).timeout
	for n in current_scene.get("region").get_node("Entities").get_children():
		if n.has_method("calm_down"):
			n.call("calm_down", 900.0)
	current_scene.get("player").call("teleport", at * 48.0)
	current_scene.get("companion").call("stand_beside", at * 48.0)
	await create_timer(1.2).timeout
	_quiet()


func _set_hour(hour: float) -> void:
	root.get_node("Game").set("clock", hour * 60.0)
	_quiet()
	await create_timer(0.4).timeout
	_quiet()


## Météo claire tout de suite (sans le fondu de la brume), sans pollen ni petites bêtes qui volent.
func _quiet() -> void:
	root.get_node("Game").call("set_weather", &"clear")
	var view := _view()
	for key in ["_rain_amount", "_storm_amount", "_mist_amount", "_sand_amount"]:
		view.set(key, 0.0)
	(view.get("_pollen") as Node3D).visible = false
	(view.get("_wildlife") as Node3D).visible = false
	# (Ni les ombres des nuages qui passent sur le sol : elles bougeraient entre deux captures.)
	for n in view.find_children("*", "MeshInstance3D", true, false):
		var mat := (n as MeshInstance3D).material_override as ShaderMaterial
		if mat and mat.shader and String(mat.shader.resource_path).ends_with("ground.gdshader"):
			mat.set_shader_parameter("clouds", false)


func _calm_wind(insts: Array) -> Array:
	var saved := []
	for inst in insts:
		var mat: ShaderMaterial = null
		if inst is MultiMeshInstance3D and (inst as MultiMeshInstance3D).material_override:
			mat = (inst as MultiMeshInstance3D).material_override
		elif inst is MultiMeshInstance3D:
			mat = ((inst as MultiMeshInstance3D).multimesh.mesh as QuadMesh).material
		if mat:
			saved.append([mat, mat.get_shader_parameter("sway"), mat.get_shader_parameter("push")])
			mat.set_shader_parameter("sway", 0.0)
			mat.set_shader_parameter("push", 0.0)
	return saved


func _restore_wind(saved: Array) -> void:
	for s in saved:
		(s[0] as ShaderMaterial).set_shader_parameter("sway", s[1] if s[1] != null else 0.0)
		(s[0] as ShaderMaterial).set_shader_parameter("push", s[2] if s[2] != null else 0.0)


func _hour_name(hour: float) -> String:
	return "%dh%02d" % [int(hour), int(round(fmod(hour, 1.0) * 60.0))]


func _report_gaps() -> void:
	print("   écart pied → ombre (px, 1600 × 900)   aplatie | ombre-carte | aplatie ancrée au point au sol (sans la base mesurée)")
	for g in _gaps:
		print("   %-14s %-6s %8.1f | %8.1f | %8.1f" % [g[0], _hour_name(g[1]), g[2], g[3], g[4] if g.size() > 4 else INF])


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, name])
