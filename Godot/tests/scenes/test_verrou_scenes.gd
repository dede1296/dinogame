extends GdUnitTestSuite
## Une scène à la fois, le verrou (story/scenes.gd), sans fenêtre :
## - une interaction (parler, ramasser) pendant une scène est ignorée ; sinon elle tient le verrou, Chloé tenue,
##   et la rend à la fin — même quand la cible est libérée en route (son interact ne peut plus reprendre) ;
## - une scène automatique (la nuit qui tombe, l'entrée d'une zone) demandée pendant une scène attend sa fin, puis
##   se joue une seule fois (la même clé n'attend qu'une fois), sa condition vérifiée à ce moment-là ; celle d'une
##   zone quittée entre-temps est abandonnée (y revenir la redemande) ;
## - la fin de la dernière scène rend les commandes (Story.lock oublié) et la caméra ; Story.playing jamais < 0.

const SAVE_PATH := "user://test_gdunit_scenes_verrou.json"
const MAX_FRAMES := 900
const PLAYER_SRC := "extends Node2D\nvar busy := false\nvar velocity := Vector2.ZERO\nvar errands := 0\nfunc cancel_goal() -> void:\n\terrands += 1\n"
## Une cible : `lines` dites à l'interaction ; `free_first` : elle se libère avant de les dire (un PNJ qu'une
## scène renvoie : son interact ne reprend jamais).
const TARGET_SRC := "extends Node2D\nvar calls := 0\nvar lines: Array = [{\"text\": \"Bonjour.\"}]\nvar free_first := false\nfunc interact(_p) -> void:\n\tcalls += 1\n\tif free_first:\n\t\tqueue_free()\n\tawait Dialogue.run(lines)\n"
const VIEW_SRC := "extends Node\nvar focus_px := Vector2.ZERO\nvar close_up := 2.0\n"

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)


func after() -> void:
	_clean()
	Save.path = _saved_path
	Game.new_game()


func before_test() -> void:
	Game.new_game()
	Game.region_id = &"havre_dore"
	_clean()


func _clean() -> void:
	Dialogue.skip_lines = false
	Dialogue.abort()
	Scenes.reset()
	Scenes.forget_stale()
	Story.playing = 0


# ------------------------------------------------------------------ outils

func _make(src: String, parent := true) -> Node:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	var n: Node = s.new()
	if parent:
		add_child(auto_free(n))
	return n


func _next() -> void:
	for i in MAX_FRAMES:
		if not Dialogue.get("_typing"):
			break
		Dialogue.advance()
		await get_tree().process_frame
	Dialogue.advance()
	await get_tree().process_frame
	await get_tree().process_frame


func _until(done: Callable) -> bool:
	for i in MAX_FRAMES:
		if done.call():
			return true
		await get_tree().process_frame
	return false


## Une scène automatique de test : compte ses passages, ne joue que si `cond["ok"]` (vérifié à son tour).
func _auto(tally: Dictionary, cond: Dictionary) -> Callable:
	return func() -> void:
		await Story.hold(func() -> void:
			if not cond.get("ok", true):
				return
			tally["n"] = int(tally.get("n", 0)) + 1
			await Dialogue.run([{"text": "La nuit tombe sur le quai."}]))


# ------------------------------------------------------------------ l'interaction

func test_une_interaction_pendant_une_scene_est_ignoree() -> void:
	var player := _make(PLAYER_SRC)
	var target := _make(TARGET_SRC)
	var scene := Scenes.begin()   # (une scène joue)
	var played: bool = await Scenes.interact(target, player)
	assert_bool(played).override_failure_message("une interaction a démarré pendant une scène").is_false()
	assert_int(target.get("calls")).is_equal(0)
	assert_bool(player.get("busy")).is_false()
	Scenes.finish(scene)
	assert_bool(Scenes.busy()).is_false()
	var got := {}
	(func() -> void: got["played"] = await Scenes.interact(target, player)).call()
	assert_int(target.get("calls")).is_equal(1)
	assert_bool(player.get("busy")).override_failure_message("Chloé n'est pas tenue pendant son interaction").is_true()
	assert_bool(Scenes.busy()).is_true()
	await _next()
	assert_bool(await _until(func() -> bool: return got.has("played"))).is_true()
	assert_bool(player.get("busy")).override_failure_message("Chloé reste tenue après l'interaction").is_false()
	assert_bool(Scenes.busy()).is_false()


func test_cible_liberee_en_route_rend_quand_meme_la_main() -> void:
	var player := _make(PLAYER_SRC)
	var target := _make(TARGET_SRC)
	target.set("free_first", true)
	var got := {}
	(func() -> void: got["played"] = await Scenes.interact(target, player)).call()
	await get_tree().process_frame
	assert_bool(is_instance_valid(target)).is_false()
	assert_bool(Dialogue.active).is_true()
	assert_bool(player.get("busy")).is_true()
	await _next()
	assert_bool(await _until(func() -> bool: return got.has("played"))) \
		.override_failure_message("la cible libérée : l'interaction ne finit jamais, Chloé bloquée").is_true()
	assert_bool(player.get("busy")).is_false()
	assert_bool(Scenes.busy()).is_false()


# ------------------------------------------------------------------ les scènes automatiques

func test_scene_automatique_attend_la_fin_puis_joue_une_fois() -> void:
	var tally := {}
	var scene := Scenes.begin()   # (Chloé parle à Joss)
	Scenes.request("phase:havre_dore", &"havre_dore", _auto(tally,{}))
	Scenes.request("phase:havre_dore", &"havre_dore", _auto(tally,{}))   # (la même, redemandée)
	assert_int(Scenes.waiting()).override_failure_message("la même scène attend deux fois").is_equal(1)
	assert_int(int(tally.get("n", 0))).override_failure_message("la nuit a joué pendant la conversation").is_equal(0)
	Scenes.finish(scene)
	assert_int(int(tally.get("n", 0))).override_failure_message("la nuit ne joue pas à la fin de la conversation").is_equal(1)
	assert_bool(Scenes.busy()).is_true()
	assert_int(Story.playing).is_equal(1)
	assert_str(Dialogue.shown_text()).is_equal("La nuit tombe sur le quai.")
	await _next()
	assert_bool(await _until(func() -> bool: return not Scenes.busy())).is_true()
	assert_int(int(tally.get("n", 0))).is_equal(1)
	assert_int(Scenes.waiting()).is_equal(0)
	assert_int(Story.playing).is_equal(0)


func test_rien_ne_joue_la_scene_automatique_part_tout_de_suite() -> void:
	var tally := {}
	Scenes.request("zone:havre_dore", &"havre_dore", _auto(tally,{}))
	assert_int(int(tally.get("n", 0))).is_equal(1)
	await _next()
	assert_bool(await _until(func() -> bool: return not Scenes.busy())).is_true()


func test_sa_condition_est_verifiee_a_son_tour() -> void:
	var tally := {}
	var cond := {"ok": true}
	var scene := Scenes.begin()
	Scenes.request("phase:havre_dore", &"havre_dore", _auto(tally,cond))
	cond["ok"] = false   # (le jour s'est levé pendant la conversation)
	Scenes.finish(scene)
	await get_tree().process_frame
	assert_int(int(tally.get("n", 0))).override_failure_message("joue alors que sa condition n'est plus remplie").is_equal(0)
	assert_bool(Scenes.busy()).is_false()


func test_la_scene_d_une_zone_quittee_est_abandonnee() -> void:
	var tally := {}
	var scene := Scenes.begin()
	Scenes.request("zone:havre_dore", &"havre_dore", _auto(tally,{}))
	Game.region_id = &"plaines"   # (Chloé est partie)
	Scenes.finish(scene)
	assert_int(int(tally.get("n", 0))).is_equal(0)
	assert_int(Scenes.waiting()).is_equal(0)


func test_deux_scenes_automatiques_l_une_apres_l_autre() -> void:
	var a := {}
	var b := {}
	var scene := Scenes.begin()
	Scenes.request("zone:havre_dore", &"havre_dore", _auto(a, {}))
	Scenes.request("phase:havre_dore", &"havre_dore", _auto(b, {}))
	Scenes.finish(scene)
	assert_int(int(a.get("n", 0))).is_equal(1)
	assert_int(int(b.get("n", 0))).override_failure_message("la seconde joue en même temps que la première").is_equal(0)
	await _next()
	assert_bool(await _until(func() -> bool: return int(b.get("n", 0)) == 1)).is_true()
	await _next()
	assert_bool(await _until(func() -> bool: return not Scenes.busy())).is_true()


# ------------------------------------------------------------------ la main rendue

func test_fin_de_scene_rend_les_commandes_et_la_camera() -> void:
	var view := _make(VIEW_SRC)
	view.add_to_group(&"world_view")
	var scene := Scenes.begin()
	Story.lock(true)   # (la scène prend Chloé… et sort tôt sans la rendre)
	assert_bool(Scenes.holds_player()).is_true()
	Scenes.finish(scene)
	assert_bool(Scenes.holds_player()).override_failure_message("la scène finie, Chloé reste tenue").is_false()
	assert_vector(view.get("focus_px")).is_equal(Vector2.INF)
	assert_float(view.get("close_up")).is_equal(0.0)


func test_une_scene_commencee_annule_la_course_d_un_clic() -> void:
	var player := _make(PLAYER_SRC)
	player.add_to_group(&"player")
	var scene := Scenes.begin()
	assert_int(player.get("errands")).is_equal(1)
	Scenes.finish(scene)


## Les scripts que le verrou a touchés se compilent (autoloads présents).
func test_les_scripts_touches_se_compilent() -> void:
	for path in ["res://story/scenes.gd", "res://story/unstick.gd", "res://story/story.gd", "res://ui/dialogue.gd",
			"res://ui/settings_menu.gd", "res://world/world.gd", "res://actors/player.gd", "res://story/plaines_annexes.gd",
			"res://story/epilogue.gd", "res://story/volcan.gd", "res://story/objectives.gd", "res://core/scene_router.gd"]:
		var s := load(path) as GDScript
		assert_bool(s != null and s.can_instantiate()).override_failure_message("%s ne se compile pas" % path).is_true()


func test_playing_jamais_negatif() -> void:
	Story.playing = 0
	Story.playing -= 1
	assert_int(Story.playing).is_equal(0)


func test_une_scene_dans_une_scene_garde_le_verrou() -> void:
	var outer := Scenes.begin()
	var inner := Scenes.begin()
	Scenes.finish(inner)
	assert_bool(Scenes.busy()).override_failure_message("la scène intérieure finie a rendu le verrou de l'autre").is_true()
	Scenes.finish(outer)
	assert_bool(Scenes.busy()).is_false()
