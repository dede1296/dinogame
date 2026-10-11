extends SceneTree
## Le Vol libre (chapitre 7, décision de Greg du 11/10 : « je veux un contrôle en vol »).
## (a) les conditions refusées une à une, chacune avec son message (pas encore le droit, pas de
## harnais, pas de ptérosaure, un trop petit, un trop jeune, sous un toit, dans une grotte, sous la
## mer, interdit ici, depuis l'eau, pendant une scène) ; le bouton n'est là qu'avec le harnais ;
## (b) le décollage à la manette (X) : le ptérosaure porte Chloé, les images montent, l'ombre reste au
## sol, la caméra recule et monte, l'aide s'affiche, plus de collision ; le stick la dirige, plus vite
## qu'à pied ; (c) au-dessus de l'eau (Côte) : atterrissage refusé avec son message ; (d) au-dessus
## d'une falaise (Monts) : on la franchit ; (e) atterrissage accepté (A) sur un sol sûr : à pied, rien de
## solide sous les pieds ; (f) les sorties : une sortie de bord se franchit en vol (posée de l'autre
## côté), une entrée de grotte au milieu de la carte ne se prend pas ; (g) trois zones (ouverte, avec
## eau, avec falaises) survolées en tous sens sans jamais être arrêtée ; (h) la sûreté : la sauvegarde
## en vol garde un endroit sûr, une scène qui commence la pose, son ptérosaure parti la pose.
##   godot --path Godot --script res://tools/test_vol.gd --resolution 1600x900 -- out=<dossier>
## Écrit PASS / FAIL, enregistre les captures, sort en 1 au moindre échec. Il faut une fenêtre.
## (Script compilé avant les autoloads : le Vol, les dinos et l'histoire sont appelés par leur chemin.)

const WORLD := "res://world/world.tscn"
const VOL := "res://story/vol.gd"
const DINO := "res://game/dino.gd"
const STORY := "res://story/story.gd"
const CAPTION := "Vol libre : conditions refusées une à une ; décollage (X) ; stick ; caméra ; au-dessus de l'eau et des falaises ; se poser (refusé / A) ; sorties ; 3 zones sans faille de collision ; sûreté"
const AXIS_X := 0
const AXIS_Y := 1
const BUTTON_A := 0
const BUTTON_X := 2
const FLYER_LEVEL := 30
## L'histoire jusqu'à la fin du chapitre 6 (les scènes d'arrivée déjà vues ; voir tools/test_barque.gd).
const LATE := ["prologue_done", "prologue_arrived", "tuto_commandes", "sceau_plaines", "maia_defi_1", "roc_parti_vu",
	"found_journal_6", "havre_arrive", "selle", "barque_vue", "foret_arrivee", "griffe_grise_vu", "clairiere_vue",
	"camp_arrive", "brac_battu", "sceau_foret", "raptor_porte_vu", "masque_vu", "maia_defi_2", "marais_arrivee",
	"joss_marais_vu", "gilet_nage", "porte_voix_ouverte", "voix_rencontree", "temple_ouvert", "dame_suie_battue",
	"spinosaure_battu", "sceau_marais", "coeur_1", "voix_coeur_chant", "roc_marais_vu", "maia_defi_3",
	"desert_arrivee", "sanctuaire_entre", "coeur_2", "maia_defi_4", "cote_annonce", "cote_ouverte", "cote_arrivee",
	"pecheurs_vus", "maia_falaises_vue", "joss_cote_vu", "barque_nuit_vue", "grottes_arrivee", "cache_vue",
	"barque_isaure_vue", "recif_arrivee", "sceau_cote", "coeur_3", "moustique_vu", "maia_guet_vue", "maia_enfuie",
	"monts_ouverts", "monts_arrivee", "forges_vues", "sceau_monts", "coeur_4", "maia_monts_vue", "maia_defi_5",
	"maia_alliee", "barque_maia_prete"]
## Les trois zones survolées en tous sens (g) : ouverte, avec eau, avec falaises.
const SWEEP_ZONES := [&"plaines", &"cote", &"monts"]
const SWEEP_LEGS := 14
const LEG_S := 1.2
## Un bout de vol est « libre » s'il avance d'au moins cette part de ce qu'il devrait.
const FREE_SHARE := 0.8

var _out := "user://test_vol"
## `only=photo` : décollage et deux captures seulement (le reste du test dure plusieurs minutes).
var _only := ""
var _failed := 0
var _game: Node
var _vol   # (story/vol.gd)
var _dino  # (game/dino.gd)
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("only="):
			_only = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(_out)
	_rng.seed = 7
	root.get_node("Save").set("path", "user://test_vol.json")
	_game = root.get_node("Game")
	_game.call("new_game")
	_game.call("give_starter", &"velociraptor")
	for f: String in LATE:
		_game.call("set_flag", StringName(f))
	_game.set("region_id", &"plaines")
	_game.set("arrival", &"Depart")
	_game.set("clock", 11.0 * 60.0)
	_game.set("time_scale", 0.0)
	_vol = load(VOL)
	_dino = load(DINO)
	change_scene_to_file(WORLD)
	_run()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	while current_scene == null or current_scene.get("region") == null:
		await process_frame
	await _wait(1.5)
	_vol.install(current_scene)   # (sans le patch de world.gd : le test pose lui-même le bouton et l'aide)
	await _settle()
	if _only == "photo":   # juste Chloé en vol (profil, face) : pour juger un dessin ou un réglage de siège
		await _conditions()   # (c'est lui qui met le ptérosaure dans l'équipe et le harnais dans le sac)
		await _take_off_with_pad()
		await _steer_with_stick()
		banner.queue_free()
		print("TEST vol (photo) : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
		quit(1 if _failed else 0)
		return
	await _conditions()
	await _take_off_with_pad()
	await _steer_with_stick()
	await _over_water()
	await _over_cliffs()
	await _land_with_a()
	await _exits()
	for zone: StringName in SWEEP_ZONES:
		await _sweep(zone)
	await _cieux()
	await _safety()
	banner.queue_free()
	print("TEST vol : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


# ------------------------------------------------------------------ (a) les conditions

func _conditions() -> void:
	print("— (a) les conditions, une à une")
	var w := current_scene
	_check("sans vol_obtenu : « not_yet », rien n'est dit", _problem() == "not_yet" and not _vol.take_off(w) and _toasts().is_empty())
	_check("sans vol_obtenu : pas de bouton du harnais", not _button().visible)
	_game.call("set_flag", &"vol_obtenu")
	_check("sans harnais : « no_harness »", _problem() == "no_harness")
	await _refused("sans harnais", "harnais de vol de Joss")
	_game.call("give_item", "harnais_vol")
	await _wait(0.2)
	_check("avec le harnais : le bouton du harnais est là (même sans ptérosaure)", _button().visible)
	_check("sans ptérosaure : « none »", _problem() == "none")
	await _refused("sans ptérosaure", "grand ptérosaure adulte")
	var small = _join(&"dimorphodon", 30)
	_check("avec un Dimorphodon : « too_small »", _problem() == "too_small")
	await _refused("un Dimorphodon", "bien trop petit")
	_leave(small)
	var young = _join(&"pteranodon", 8)
	_check("un Pteranodon niv. 8 : « young »", _problem() == "young")
	await _refused("un Pteranodon trop jeune", "encore trop jeune")
	young.set("level", FLYER_LEVEL)
	_check("un Pteranodon adulte : rien ne l'empêche", _problem() == "", _problem())
	w.get("player").set("swimmer", young)   # (le temps d'une image : à pied hors de l'eau, elle le perd)
	_check("dans l'eau : « swimming »", _problem() == "swimming")
	_clear_toasts()
	var took: bool = _vol.take_off(w)
	await _wait(0.1)
	_check("dans l'eau : refusé avec son message (« …regagne d'abord la rive… »)", not took and not _flying()
		and _toasts().any(func(t: String) -> bool: return t.contains("regagne d'abord la rive")), str(_toasts()))
	w.get("player").set("swimmer", null)
	var region: Node = w.get("region")
	region.set_meta(&"vol_interdit", true)
	_check("zone interdite : « forbidden »", _problem() == "forbidden")
	region.remove_meta(&"vol_interdit")
	region.set("cave", true)
	_check("dans une grotte : « cave »", _problem() == "cave")
	await _refused("dans une grotte", "déployer des ailes")
	region.set("cave", false)
	region.set("indoor", true)
	_check("sous un toit : « indoor »", _problem() == "indoor")
	await _refused("sous un toit", "Pas de vol sous un toit")
	region.set("indoor", false)
	region.set_meta(&"underwater", true)
	_check("sous la mer : « underwater »", _problem() == "underwater")
	region.remove_meta(&"underwater")
	var story = load(STORY)
	story.set("playing", 1)
	w.get("player").set("busy", true)
	_clear_toasts()
	await process_frame
	_check("pendant une scène : « scene », rien n'est dit", _problem() == "scene" and not _vol.take_off(w) and _toasts().is_empty())
	_check("pendant une scène : pas de bouton", not _button().call("_shown", w.get("player")))
	story.set("playing", 0)
	w.get("player").set("busy", false)
	await _wait(0.3)
	await _shot("vol_00_bouton")


## Appuie sur la touche du Vol et vérifie que le message s'affiche (et qu'elle ne vole pas).
func _refused(what: String, words: String) -> void:
	_clear_toasts()
	_press(&"fly")
	await _wait(0.4)
	var said := _toasts().any(func(t: String) -> bool: return t.contains(words))
	_check("%s : F refuse avec son message (« …%s… »)" % [what, words], said and not _flying(), str(_toasts()))


# ------------------------------------------------------------------ (b) décoller, diriger

func _take_off_with_pad() -> void:
	print("— (b) décoller à la manette")
	var player: Node2D = _player()
	var camera: Node3D = _view().get("camera")
	var cam_before := camera.global_position.y
	var dist_before: float = camera.call("shown_distance")
	_tap(BUTTON_X)
	await _wait(0.15)
	_check("X de la manette : elle décolle", _flying())
	_check("en vol : plus aucune collision (masque et couche vides)", player.get("collision_mask") == 0 and player.get("collision_layer") == 0)
	var companion: Node2D = current_scene.get("companion")
	_check("son ptérosaure la porte (le compagnon est lui)", companion.get("dino") == player.get("flyer") and companion.call("flying"))
	await _wait(1.6)
	await _shot("vol_01_decollage")
	var sprite: Node2D = companion.get("sprite")
	_check("les images montent (le ptérosaure et Chloé)", sprite.position.y < -40.0 and (player.get("sprite") as Node2D).position.y < -40.0,
		"%.0f / %.0f px" % [sprite.position.y, (player.get("sprite") as Node2D).position.y])
	var shadow := companion.get_node_or_null("Shadow") as Node2D
	_check("l'ombre reste au sol (sous le ptérosaure)", shadow != null and shadow.position.y > -5.0)
	_check("la caméra recule (gros plan plus loin)", float(_view().get("close_up")) > dist_before + 1.0,
		"%.1f m" % float(_view().get("close_up")))
	_check("la caméra monte", camera.global_position.y > cam_before + 1.0, "%.1f → %.1f m" % [cam_before, camera.global_position.y])
	var seen := _chloe_on_screen()
	_check("Chloé en vol reste au milieu de l'écran (la vue monte avec elle)", seen.y > 0.2 and seen.y < 0.8 and seen.x > 0.2 and seen.x < 0.8,
		"%.2f, %.2f de l'écran" % [seen.x, seen.y])
	_check("l'altitude se lit pour la caméra (méta air_lift_m)", float(player.get_meta(&"air_lift_m", 0.0)) > 2.0)
	_check("l'aide en vol s'affiche", _help().visible and _help_icons() >= 3, "%d icônes" % _help_icons())
	_check("le bouton du harnais est allumé (« Se poser »)", _button().visible and _button().call("flying"))
	_check("les ailes battent (animation de vol)", String((sprite as AnimatedSprite2D).animation).begins_with("fly"))
	_check("Chloé est assise sur son dos, en tenue de vol",
		String((player.get("sprite") as AnimatedSprite2D).animation).contains("ride_"), String((player.get("sprite") as AnimatedSprite2D).animation))


func _steer_with_stick() -> void:
	print("— (b) diriger au stick")
	var player: Node2D = _player()
	var start := player.global_position
	await _stick(Vector2(1.0, 0.0), 1.0)
	var moved := player.global_position.distance_to(start)
	var walk := 165.0
	_check("au stick : elle avance, plus vite qu'à pied (> 1,5 × la marche)", moved > walk * 1.5, "%.0f px en 1 s" % moved)
	await _shot("vol_02_stick")
	var sprite: AnimatedSprite2D = current_scene.get("companion").get("sprite")
	await _stick(Vector2(0.0, 1.0), 0.6, false)
	_check("vers le bas de l'écran : vu de face", sprite.animation == &"fly_down", sprite.animation)
	var base: float = current_scene.get("companion").get("_size")
	_check("vu de face, ailes à plat, jamais plus étroit que de profil (Wings.face_back_scale)", sprite.scale.y >= base - 0.001,
		"×%.2f" % (sprite.scale.y / maxf(base, 0.001)))
	await _shot("vol_02b_face")
	await _stick(Vector2(0.0, -1.0), 0.6, false)
	_check("vers le haut de l'écran : vu de dos", sprite.animation == &"fly_up", sprite.animation)
	await _stick(Vector2.ZERO, 0.6)


# ------------------------------------------------------------------ (c) l'eau, (d) les falaises

func _over_water() -> void:
	print("— (c) au-dessus de l'eau (Côte)")
	await _goto_flying(&"cote")
	var water := _find_tile(func(c: Vector2i) -> bool: return _kind(c) == "water" and _all_around(c, "water", 2))
	_check("la Côte a de l'eau profonde", water != Vector2i(-1, -1))
	if water == Vector2i(-1, -1):
		return
	await _fly_to(_px(water))
	_check("elle survole l'eau profonde", _kind(_cell(_player().global_position)) == "water")
	await _wait(0.5)
	await _shot("vol_03_eau")
	_clear_toasts()
	_tap(BUTTON_A)
	await _wait(0.5)
	_check("se poser sur l'eau : refusé, avec son message", _flying() and _toasts().any(func(t: String) -> bool: return t.contains("eau profonde")),
		str(_toasts()))
	await _shot("vol_04_refus_eau")
	var safe: Vector2 = _player().call("save_position")
	_check("en vol au-dessus de l'eau, la sauvegarde garde un endroit sûr",
		_vol.landing_problem(current_scene.get("region"), safe, _player()) == "", str(safe))


func _over_cliffs() -> void:
	print("— (d) au-dessus d'une falaise (Monts)")
	await _goto_flying(&"monts")
	var pair := _find_cliff()
	_check("les Monts ont une falaise", not pair.is_empty())
	if pair.is_empty():
		return
	await _fly_to(_px(pair[0]))
	var low_side: Vector2 = _px(pair[1])
	await _fly_to(low_side)
	_check("elle franchit la falaise en vol (de l'autre côté)", _cell(_player().global_position) == pair[1] or
		_player().global_position.distance_to(low_side) < 30.0, "%s → %s" % [pair[0], _cell(_player().global_position)])
	await _wait(0.6)
	await _shot("vol_05_falaise")


# ------------------------------------------------------------------ (e) se poser

func _land_with_a() -> void:
	print("— (e) se poser (A)")
	var spot := _find_landing()
	_check("un sol sûr où se poser", spot != Vector2.INF)
	if spot == Vector2.INF:
		return
	await _fly_to(spot)
	_tap(BUTTON_A)
	await _wait(1.4)
	var player: Node2D = _player()
	_check("A : elle se pose", not _flying())
	_check("à pied : collisions revenues (couche et masque)", player.get("collision_layer") == 2 and int(player.get("collision_mask")) & 1 == 1,
		"%d / %d" % [player.get("collision_layer"), player.get("collision_mask")])
	_check("rien de solide sous ses pieds", not _vol.call("_blocked", player, player.global_position))
	_check("la caméra revient (plus de gros plan, plus d'altitude)", float(_view().get("close_up")) == 0.0 and not player.has_meta(&"air_lift_m"))
	_check("l'aide en vol a disparu", not _help().visible)
	_check("Chloé est debout (ses images à leur place)", (player.get("sprite") as Node2D).position.length() < 1.0)
	await _wait(0.6)
	await _shot("vol_06_pose")


# ------------------------------------------------------------------ (f) les sorties

func _exits() -> void:
	print("— (f) les sorties")
	var region: Node = current_scene.get("region")
	var mouth: Node2D = null
	for e in region.call("exits"):
		if not region.call("exit_on_edge", e):
			mouth = e
			break
	if mouth:
		await _take_off()
		var mouth_rect: Rect2 = region.call("exit_rect", mouth)
		await _fly_to(mouth_rect.get_center())
		await _wait(0.6)
		_check("au-dessus d'une entrée de grotte : on ne la prend pas en vol", _zone() == &"monts" and _flying(), str(_zone()))
	else:
		print("   (pas d'entrée de grotte dans les Monts)")
	await _closed_edge(region)
	var edge: Node2D = null
	for e in region.call("exits"):
		if region.call("exit_on_edge", e) and e.call("is_open"):
			edge = e
			break
	_check("les Monts ont une sortie de bord ouverte", edge != null)
	if edge == null:
		return
	if not _flying():
		await _take_off()
	var target: StringName = edge.get("target_zone")
	var rect: Rect2 = region.call("exit_rect", edge)
	await _fly_to(rect.get_center(), 12.0)
	for i in 30:
		if _zone() == target:
			break
		await _wait(0.2)
	await _wait(1.2)
	await _settle()
	_check("une sortie de bord se franchit en vol (%s)" % target, _zone() == target, str(_zone()))
	_check("de l'autre côté, elle est posée à pied", not _flying() and _player().get("collision_layer") == 2)
	await _shot("vol_07_sortie")


## Une sortie de bord fermée (la route des Cieux, avant cieux_ouverts) : en vol, elle la repousse, en l'air,
## avec ses mots.
func _closed_edge(region: Node) -> void:
	var closed: Node2D = null
	for e in region.call("exits"):
		if region.call("exit_on_edge", e) and not e.call("is_open"):
			closed = e
			break
	if closed == null:
		print("   (pas de sortie de bord fermée dans les Monts)")
		return
	if not _flying():
		await _take_off()
	var rect: Rect2 = region.call("exit_rect", closed)
	await _fly_to(rect.get_center(), 12.0)
	var told := false
	for i in 20:
		if root.get_node("Dialogue").get("active"):
			told = true
			break
		await _wait(0.1)
	await _shot("vol_07_sortie_fermee")
	await _settle()
	_check("une sortie fermée la repousse en vol, avec ses mots", told and _zone() == &"monts" and _flying()
		and not rect.has_point(_player().global_position))


# ------------------------------------------------------------------ (g) trois zones sans faille

func _sweep(zone: StringName) -> void:
	print("— (g) %s survolée en tous sens" % zone)
	await _goto_flying(zone)
	var region: Node = current_scene.get("region")
	var inner: Rect2 = (region.call("bounds") as Rect2).grow(-6.0 * 48.0)
	var blocked := 0
	var legs := 0
	var crossed := {"water": 0, "cliff": 0}
	for i in SWEEP_LEGS:
		var from := Vector2(_rng.randf_range(inner.position.x, inner.end.x), _rng.randf_range(inner.position.y, inner.end.y))
		_player().global_position = from   # (en vol : pas de teleport, qui la poserait)
		var dir := Vector2.from_angle(_rng.randf() * TAU)
		await _stick(Vector2.ZERO, 0.15)
		_player().set("velocity", Vector2.ZERO)   # (chaque bout part à l'arrêt)
		var start := _player().global_position
		var h0: float = region.call("tile_height", _cell(start))
		await _stick(dir, LEG_S, false)
		var end := _player().global_position
		if not _flying() or _zone() != zone:
			_check("%s : le vol continue dans la zone" % zone, false, "jambe %d" % i)
			return
		var expected: float = _top_speed() * (LEG_S - 0.4)
		var near_edge := not inner.grow(3.0 * 48.0).has_point(end)
		legs += 1
		if end.distance_to(start) < expected * FREE_SHARE and not near_edge:
			blocked += 1
			print("   arrêtée : jambe %d, %.0f px au lieu de %.0f (de %s vers %s) ; occupée %s, dialogue %s, scène %d, vitesse %s, masque %d" % [
				i, end.distance_to(start), expected, start, dir, _player().get("busy"), root.get_node("Dialogue").get("active"),
				int(load(STORY).get("playing")), _player().get("velocity"), _player().get("collision_mask")])
		if _crossed_water(start, end):
			crossed["water"] += 1
		if absf(float(region.call("tile_height", _cell(end))) - h0) > 0.75:
			crossed["cliff"] += 1
		_check_lift(zone, i)
	await _stick(Vector2.ZERO, 0.2)
	_check("%s : %d bouts de vol, jamais arrêtée par le décor, l'eau ou une falaise" % [zone, legs], blocked == 0, "%d arrêts" % blocked)
	print("   (%d bouts au-dessus de l'eau, %d d'un niveau à l'autre)" % [crossed["water"], crossed["cliff"]])
	await _shot("vol_08_%s" % zone)
	var spot := _find_landing()
	if spot != Vector2.INF:
		await _fly_to(spot)
		_tap(BUTTON_A)
		await _wait(1.4)
		_check("%s : elle se pose sur un sol sûr" % zone, not _flying() and not _vol.call("_blocked", _player(), _player().global_position))


## Les Cieux (une fois la zone branchée dans world.gd : patch de l'agent carte) : au-dessus de la mer de
## nuages, se poser est refusé (« le vide ») ; puis survolée en tous sens comme les autres.
func _cieux() -> void:
	var zones: Dictionary = current_scene.get_script().get_script_constant_map().get("ZONES", {})
	if not zones.has(&"cieux"):
		print("— (g) cieux : pas encore dans world.gd (patch de l'agent carte) : vérifié par tools/test_especes_cieux.gd")
		return
	print("— (g) les Cieux : le vide")
	_game.call("set_flag", &"cieux_ouverts")
	await _goto_flying(&"cieux")
	var region: Node = current_scene.get("region")
	var hole := _find_tile(func(c: Vector2i) -> bool: return _vol.is_void(region, c) and _all_void(region, c))
	_check("cieux : la mer de nuages est là", hole != Vector2i(-1, -1))
	if hole != Vector2i(-1, -1):
		await _fly_to(_px(hole))
		await _wait(0.5)
		await _shot("vol_09_cieux_vide")
		_clear_toasts()
		_tap(BUTTON_A)
		await _wait(0.5)
		_check("cieux : se poser dans le vide est refusé, avec son message", _flying()
			and _toasts().any(func(t: String) -> bool: return t.contains("le vide")), str(_toasts()))
	await _sweep(&"cieux")


func _all_void(region: Node, c: Vector2i) -> bool:
	for d: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2)]:
		if not _vol.is_void(region, c + d):
			return false
	return true


var _lift_bad := false


func _check_lift(zone: StringName, leg: int) -> void:
	var lift := float(_player().get_meta(&"air_lift_m", -1.0))
	if (is_nan(lift) or lift < 0.5 or lift > 30.0) and not _lift_bad:
		_lift_bad = true
		_check("%s : altitude raisonnable en vol" % zone, false, "jambe %d : %.2f m" % [leg, lift])


# ------------------------------------------------------------------ (h) la sûreté

func _safety() -> void:
	print("— (h) la sûreté")
	await _goto_flying(&"cote")
	var water := _find_tile(func(c: Vector2i) -> bool: return _kind(c) == "water" and _all_around(c, "water", 2))
	if water != Vector2i(-1, -1):
		await _fly_to(_px(water))
	var story = load(STORY)
	story.set("playing", 1)
	_player().set("busy", true)
	await _wait(0.3)
	_check("une scène qui commence en vol la pose aussitôt, sur un sol sûr",
		not _flying() and _vol.landing_problem(current_scene.get("region"), _player().global_position, _player()) == "",
		str(_player().global_position))
	story.set("playing", 0)
	_player().set("busy", false)
	await _wait(0.3)
	await _take_off()
	var flyer = _player().get("flyer")
	var party: Array = _game.get("party")
	party.erase(flyer)
	_game.emit_signal("party_changed")
	await _wait(0.4)
	_check("son ptérosaure quitte l'équipe en vol : elle est posée", not _flying())
	party.append(flyer)
	_game.emit_signal("party_changed")


# ------------------------------------------------------------------ outils : le Vol

func _problem() -> String:
	return _vol.take_off_problem(current_scene)


func _flying() -> bool:
	return _player().get("flight") != null


func _take_off() -> void:
	_press(&"fly")
	await _wait(1.2)


func _top_speed() -> float:
	return float(_player().call("top_speed"))


## Change de zone puis décolle (avec un Pteranodon adulte dans l'équipe).
func _goto_flying(zone: StringName) -> void:
	if _zone() != zone:
		await current_scene.goto_zone(zone, &"Depart")
		await _wait(1.5)
		await _settle()
	if not _flying():
		await _take_off()
	_check("%s : elle vole" % zone, _flying())


## Vole droit vers `to` (stick) jusqu'à y être.
func _fly_to(to: Vector2, near := 20.0) -> void:
	for i in 1500:
		var at := _player().global_position
		if at.distance_to(to) <= near or not _flying():
			break
		_hold((to - at).normalized() * minf(1.0, at.distance_to(to) / 120.0 + 0.25))
		await physics_frame
	_hold(Vector2.ZERO)
	await _wait(0.3)


func _join(species: StringName, level: int):
	var d = _dino.create(species, level)
	var party: Array = _game.get("party")
	party.append(d)
	_game.emit_signal("party_changed")
	return d


func _leave(d) -> void:
	var party: Array = _game.get("party")
	party.erase(d)
	_game.emit_signal("party_changed")


## Où Chloé (en vol, sa tête) se voit à l'écran (0–1 de chaque côté).
func _chloe_on_screen() -> Vector2:
	var view := _view()
	var at: Vector3 = view.get("heights").call("to_3d", _player().global_position)
	at.y += float(_player().get_meta(&"air_lift_m", 0.0)) + 1.0
	var camera: Camera3D = view.get("camera")
	return camera.unproject_position(at) / root.get_viewport().get_visible_rect().size


func _button() -> Control:
	return current_scene.get("hud").get_node("VolButton")


func _help() -> Control:
	return current_scene.get("hud").get_node("VolHelp")


func _help_icons() -> int:
	return _help().find_children("*", "TextureRect", true, false).size()


func _toasts() -> Array:
	var toast := root.get_node_or_null("Toast")
	if toast == null:
		return []
	return toast.find_children("*", "Label", true, false).filter(func(l: Label) -> bool: return not l.is_queued_for_deletion()).map(
		func(l: Label) -> String: return l.text)


func _clear_toasts() -> void:
	var toast := root.get_node_or_null("Toast")
	if toast:
		for l in toast.find_children("*", "PanelContainer", true, false):
			l.queue_free()


# ------------------------------------------------------------------ outils : la zone

func _settle() -> void:
	for i in 60:
		if int(load(STORY).get("playing")) == 0 and not root.get_node("Dialogue").get("active") and not _player().get("busy"):
			break
		if root.get_node("Dialogue").get("active"):
			_press(&"interact")
		await _wait(0.4)
	for n in current_scene.get("region").get("entities").get_children():
		if n.has_method("calm_down"):
			n.call("calm_down", 900.0)


func _zone() -> StringName:
	return current_scene.get("region").get("region_id")


func _player() -> Node2D:
	return current_scene.get("player")


func _view() -> Node:
	return current_scene.get("_view")


func _cell(p: Vector2) -> Vector2i:
	return Vector2i((p / 48.0).floor())


func _px(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * 48.0


func _kind(c: Vector2i) -> String:
	return String(current_scene.get("region").call("surface_at", _px(c)))


func _all_around(c: Vector2i, kind: String, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if _kind(c + Vector2i(dx, dy)) != kind:
				return false
	return true


## Une case qui passe `test`, la plus proche de Chloé (Vector2i(-1, -1) : aucune).
func _find_tile(test: Callable) -> Vector2i:
	var region: Node = current_scene.get("region")
	var size: Vector2i = region.call("map_size")
	var here := _cell(_player().global_position)
	var best := Vector2i(-1, -1)
	var best_d := INF
	for y in range(3, size.y - 3, 2):
		for x in range(3, size.x - 3, 2):
			var c := Vector2i(x, y)
			var d := Vector2(c - here).length()
			if d < best_d and test.call(c):
				best = c
				best_d = d
	return best


## Deux cases voisines séparées par une falaise : [la haute, la basse] ([] : aucune).
func _find_cliff() -> Array:
	var region: Node = current_scene.get("region")
	var high := _find_tile(func(c: Vector2i) -> bool:
		var h: float = region.call("tile_height", c)
		var low: float = region.call("tile_height", c + Vector2i(0, 3))
		return h - low > 2.0 and _kind(c) != "water" and _kind(c + Vector2i(0, 3)) != "water")
	return [] if high == Vector2i(-1, -1) else [high, high + Vector2i(0, 3)]


## Un point où se poser, le plus proche de Chloé (Vector2.INF : aucun).
func _find_landing() -> Vector2:
	var region: Node = current_scene.get("region")
	var found := _find_tile(func(c: Vector2i) -> bool: return _vol.landing_problem(region, _px(c), _player()) == "")
	return Vector2.INF if found == Vector2i(-1, -1) else _px(found)


func _crossed_water(a: Vector2, b: Vector2) -> bool:
	for i in 9:
		if _kind(_cell(a.lerp(b, i / 8.0))) == "water":
			return true
	return false


# ------------------------------------------------------------------ outils : entrées

## Tient le stick dans `dir` pendant `secs` de temps du jeu (des images de physique : la mesure ne
## dépend pas de la vitesse de la machine), puis le relâche si `release`.
func _stick(dir: Vector2, secs: float, release := true) -> void:
	for i in roundi(secs * Engine.physics_ticks_per_second):
		_hold(dir)   # (tenu à chaque image : une fenêtre qui perd le focus relâche tout, Godot.release_pressed_events)
		await physics_frame
	if release:
		_hold(Vector2.ZERO)


func _hold(dir: Vector2) -> void:
	for axis: Array in [[AXIS_X, dir.x], [AXIS_Y, dir.y]]:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axis[0] as JoyAxis
		ev.axis_value = axis[1]
		Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _press(action: StringName) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _tap(button: int) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button as JoyButton
		event.pressed = pressed
		Input.parse_input_event(event)
	Input.flush_buffered_events()


# ------------------------------------------------------------------ outils : test

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


func _shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
